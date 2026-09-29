public with sharing class CaseFieldMappingEngine {

    public class Request {
        @InvocableVariable(label='Case Id' required=true)
        public Id caseId;
    }

    // Only these two Case Record Types ever get field mappings applied — a deliberate
    // allow-list (not just an absence of matching Case_Field_Mapping__c rows), so a stray
    // future mapping row scoped to some other Record Type can't silently start firing.
    // Mirrors TouchLevelEvaluatorAction.TOUCH_LEVEL_ELIGIBLE_RECORD_TYPES.
    public static final Set<Id> ELIGIBLE_RECORD_TYPES = new Set<Id>{
        App_Constants.B2B_IMPLEMENTATION_CASE_RECTYPE_ID,
        App_Constants.DEAL_SUPPORT_CASE_RECTYPE_ID
    };

    // Case_Field_Mapping__c.Record_Type_Developer_Name__c values these two Record Type Ids
    // correspond to — used to bucket mappings without an extra Schema call per Case.
    private static final Map<Id, String> RECTYPE_ID_TO_DEV_NAME = new Map<Id, String>{
        App_Constants.B2B_IMPLEMENTATION_CASE_RECTYPE_ID => 'Post_Sale_Support',
        App_Constants.DEAL_SUPPORT_CASE_RECTYPE_ID => 'Deal_Support'
    };

    // Bucket key for mappings with a blank Record_Type_Developer_Name__c — applies to every
    // eligible Record Type.
    private static final String UNIVERSAL_BUCKET = '';

    // A Case_Field_Mapping__c row, resolved against the actual Opportunity/Account schema at
    // read time. Unlike the FieldPath parsers in TouchLevelEvaluatorAction /
    // CaseCreationRuleEvaluatorAction (which only ever allow a single hardcoded relationship
    // name, "Account"), this validates the relationship name dynamically against the Source
    // Object's own describe — because mappings need to reach one-hop paths other than
    // Account too (e.g. Opportunity.Billing_Country__r.Region__c). Still capped at exactly
    // one hop. A row that fails to resolve is dropped entirely (fail-closed, logged) rather
    // than risking a single bad config row breaking the shared dynamic SOQL query below.
    private class ResolvedMapping {
        public String recordTypeDevName; // '' (UNIVERSAL_BUCKET) if blank on the config row
        public String caseType;          // '' (UNIVERSAL_BUCKET) if blank on the config row — a Record
                                          // Type can span many Case Types (e.g. Deal_Support covers Bid
                                          // Management, Legal, InfoSecurity, etc.), so this narrows a
                                          // mapping to just one of them when needed.
        public String sourceObject;      // 'Opportunity' or 'Account'
        public String relationshipName;  // null => direct field on the Source Object
        public String field;
        public String targetObject;      // 'Case' or 'Case_Detail__c' — blank on the config row defaults
                                          // to 'Case' (every mapping predates this field existing).
        public String targetField;
        public String selectExpression;  // what to put in the supplemental SOQL SELECT list
    }

    private static final String TARGET_CASE = 'Case';
    private static final String TARGET_CASE_DETAIL = 'Case_Detail__c';

    @InvocableMethod(
        label='Apply Case Field Mappings'
        description='Applies active Case_Field_Mapping__c config to copy Opportunity/Account field values onto eligible Cases (B2B Implementation, Deal Support only). Intended to be called from a Case After-Insert Flow running asynchronously, not inline with Case creation.'
        category='IRM Touch Level'
    )
    public static void applyMappings(List<Request> requests) {
        if (requests == null || requests.isEmpty()) return;

        Set<Id> caseIds = new Set<Id>();
        for (Request req : requests) {
            if (req.caseId != null) caseIds.add(req.caseId);
        }
        if (caseIds.isEmpty()) return;

        List<Case> cases = [
            SELECT Id, RecordTypeId, Type, Opportunity__c, AccountId
            FROM Case
            WHERE Id IN :caseIds
              AND RecordTypeId IN :ELIGIBLE_RECORD_TYPES
              AND Opportunity__c != null
        ];
        if (cases.isEmpty()) return;

        List<Case_Field_Mapping__c> rawMappings = queryActiveMappings();
        if (rawMappings.isEmpty()) return;

        Schema.DescribeSObjectResult oppDescribe = Schema.SObjectType.Opportunity;
        Schema.DescribeSObjectResult acctDescribe = Schema.SObjectType.Account;

        List<ResolvedMapping> resolved = resolveMappings(rawMappings, oppDescribe, acctDescribe);
        if (resolved.isEmpty()) return;

        Set<Id> oppIds = new Set<Id>();
        Set<Id> acctIds = new Set<Id>();
        Set<Id> caseIdsWithOpp = new Set<Id>();
        for (Case c : cases) {
            if (c.Opportunity__c != null) oppIds.add(c.Opportunity__c);
            if (c.AccountId != null) acctIds.add(c.AccountId);
            caseIdsWithOpp.add(c.Id);
        }

        Map<Id, SObject> oppById = queryBySelectExpressions('Opportunity', oppIds, resolved);
        Map<Id, SObject> acctById = queryBySelectExpressions('Account', acctIds, resolved);

        // Case_Detail__c children of these Cases, only queried when at least one resolved
        // mapping actually targets Case_Detail__c — grouped by parent Case Id since a Case can
        // in principle have more than one Case_Detail__c child.
        Boolean anyCaseDetailTarget = false;
        for (ResolvedMapping rm : resolved) {
            if (rm.targetObject == TARGET_CASE_DETAIL) { anyCaseDetailTarget = true; break; }
        }
        Map<Id, List<Case_Detail__c>> caseDetailsByCaseId = new Map<Id, List<Case_Detail__c>>();
        if (anyCaseDetailTarget) {
            for (Case_Detail__c cd : [SELECT Id, Case__c FROM Case_Detail__c WHERE Case__c IN :caseIdsWithOpp]) {
                if (!caseDetailsByCaseId.containsKey(cd.Case__c)) caseDetailsByCaseId.put(cd.Case__c, new List<Case_Detail__c>());
                caseDetailsByCaseId.get(cd.Case__c).add(cd);
            }
        }

        List<Case> casesToUpdate = new List<Case>();
        List<Case_Detail__c> caseDetailsToUpdate = new List<Case_Detail__c>();

        for (Case c : cases) {
            String recordTypeDevName = RECTYPE_ID_TO_DEV_NAME.get(c.RecordTypeId);
            List<ResolvedMapping> applicable = new List<ResolvedMapping>();
            for (ResolvedMapping rm : resolved) {
                Boolean recordTypeMatches = rm.recordTypeDevName == UNIVERSAL_BUCKET || rm.recordTypeDevName == recordTypeDevName;
                Boolean caseTypeMatches = rm.caseType == UNIVERSAL_BUCKET || rm.caseType == c.Type;
                if (recordTypeMatches && caseTypeMatches) applicable.add(rm);
            }
            if (applicable.isEmpty()) continue;

            Case caseToUpdate = new Case(Id = c.Id);
            Boolean caseHasAnyValue = false;

            // One update sObject per related Case_Detail__c child, keyed by its Id, only
            // created the first time a Case_Detail__c-targeted mapping actually has a value.
            Map<Id, Case_Detail__c> caseDetailUpdatesById = new Map<Id, Case_Detail__c>();

            for (ResolvedMapping rm : applicable) {
                SObject sourceRecord = rm.sourceObject == 'Account' ? acctById.get(c.AccountId) : oppById.get(c.Opportunity__c);
                if (sourceRecord == null) continue;

                try {
                    Object value = rm.relationshipName == null
                        ? sourceRecord.get(rm.field)
                        : safeRelatedGet(sourceRecord, rm.relationshipName, rm.field);

                    if (rm.targetObject == TARGET_CASE_DETAIL) {
                        List<Case_Detail__c> children = caseDetailsByCaseId.get(c.Id);
                        if (children == null) continue; // no Case_Detail__c child yet — nothing to update
                        for (Case_Detail__c cd : children) {
                            if (!caseDetailUpdatesById.containsKey(cd.Id)) {
                                caseDetailUpdatesById.put(cd.Id, new Case_Detail__c(Id = cd.Id));
                            }
                            caseDetailUpdatesById.get(cd.Id).put(rm.targetField, value);
                        }
                    } else {
                        caseToUpdate.put(rm.targetField, value);
                        caseHasAnyValue = true;
                    }
                } catch (Exception e) {
                    // A bad target field name or an incompatible value/type for this one
                    // mapping — skip just this field, never the whole Case/Case_Detail__c update.
                    System.debug(LoggingLevel.WARN,
                        'CaseFieldMappingEngine: skipped mapping to ' + rm.targetObject + '.' + rm.targetField + ' for Case ' + c.Id + ' - ' + e.getMessage());
                }
            }

            if (caseHasAnyValue) casesToUpdate.add(caseToUpdate);
            if (!caseDetailUpdatesById.isEmpty()) caseDetailsToUpdate.addAll(caseDetailUpdatesById.values());
        }

        if (!casesToUpdate.isEmpty()) {
            Database.update(casesToUpdate, false);
        }
        if (!caseDetailsToUpdate.isEmpty()) {
            Database.update(caseDetailsToUpdate, false);
        }
    }

    private static Object safeRelatedGet(SObject sourceRecord, String relationshipName, String field) {
        SObject related = sourceRecord.getSObject(relationshipName);
        return related == null ? null : related.get(field);
    }

    private static List<Case_Field_Mapping__c> queryActiveMappings() {
        return [
            SELECT Id, Record_Type_Developer_Name__c, Case_Type__c, Source_Object__c, Source_Field_Path__c, Target_Object__c, Target_Field_API_Name__c
            FROM Case_Field_Mapping__c
            WHERE Is_Active__c = true
        ];
    }

    // Resolves every active Case_Field_Mapping__c row against the real Opportunity/Account
    // schema, dropping (and logging) any row whose Source_Field_Path__c or
    // Target_Field_API_Name__c doesn't actually resolve — fail-closed per row, so one typo'd
    // config record can't take down the shared dynamic SOQL query built from these results.
    private static List<ResolvedMapping> resolveMappings(
            List<Case_Field_Mapping__c> rawMappings,
            Schema.DescribeSObjectResult oppDescribe,
            Schema.DescribeSObjectResult acctDescribe) {

        Map<String, Schema.SObjectField> caseFieldMap = Schema.SObjectType.Case.fields.getMap();
        Map<String, Schema.SObjectField> caseDetailFieldMap = Schema.SObjectType.Case_Detail__c.fields.getMap();

        List<ResolvedMapping> results = new List<ResolvedMapping>();
        for (Case_Field_Mapping__c raw : rawMappings) {
            if (String.isBlank(raw.Source_Object__c) || String.isBlank(raw.Source_Field_Path__c) || String.isBlank(raw.Target_Field_API_Name__c)) {
                logInvalid(raw, 'missing Source Object, Source Field Path, or Target Field API Name');
                continue;
            }

            String targetObject = String.isBlank(raw.Target_Object__c) ? TARGET_CASE : raw.Target_Object__c.trim();
            Map<String, Schema.SObjectField> targetFieldMap = targetObject == TARGET_CASE_DETAIL ? caseDetailFieldMap : caseFieldMap;
            if (targetObject != TARGET_CASE && targetObject != TARGET_CASE_DETAIL) {
                logInvalid(raw, 'Target_Object__c "' + raw.Target_Object__c + '" must be Case or Case_Detail__c');
                continue;
            }
            if (!targetFieldMap.containsKey(raw.Target_Field_API_Name__c.toLowerCase())) {
                logInvalid(raw, 'Target_Field_API_Name__c "' + raw.Target_Field_API_Name__c + '" does not exist on ' + targetObject);
                continue;
            }

            Schema.DescribeSObjectResult sourceDescribe = raw.Source_Object__c == 'Account' ? acctDescribe : oppDescribe;
            ResolvedMapping rm = resolvePath(raw.Source_Field_Path__c.trim(), sourceDescribe);
            if (rm == null) {
                logInvalid(raw, 'Source_Field_Path__c "' + raw.Source_Field_Path__c + '" does not resolve against ' + raw.Source_Object__c);
                continue;
            }

            rm.recordTypeDevName = String.isBlank(raw.Record_Type_Developer_Name__c) ? UNIVERSAL_BUCKET : raw.Record_Type_Developer_Name__c.trim();
            rm.caseType = String.isBlank(raw.Case_Type__c) ? UNIVERSAL_BUCKET : raw.Case_Type__c.trim();
            rm.sourceObject = raw.Source_Object__c;
            rm.targetObject = targetObject;
            rm.targetField = raw.Target_Field_API_Name__c;
            results.add(rm);
        }
        return results;
    }

    private static void logInvalid(Case_Field_Mapping__c raw, String reason) {
        System.debug(LoggingLevel.WARN, 'CaseFieldMappingEngine: dropping Case_Field_Mapping__c ' + raw.Id + ' - ' + reason);
    }

    // Parses (and validates) a Source_Field_Path__c against the Source Object's real describe.
    // Zero dots => a direct field on the Source Object itself. One dot => exactly one
    // relationship hop; the relationship name is validated against the Source Object's own
    // lookup/master-detail fields, and the leaf field is validated against whatever single
    // object that relationship points to (polymorphic lookups referencing more than one
    // object are not supported — ambiguous, so dropped). More than one dot is unsupported.
    private static ResolvedMapping resolvePath(String path, Schema.DescribeSObjectResult sourceDescribe) {
        Integer dotIdx = path.indexOf('.');
        if (dotIdx < 0) {
            if (!fieldExists(sourceDescribe, path)) return null;
            ResolvedMapping rm = new ResolvedMapping();
            rm.field = path;
            rm.selectExpression = path;
            return rm;
        }
        if (path.indexOf('.', dotIdx + 1) >= 0) return null; // more than one dot — unsupported

        String relationshipName = path.substring(0, dotIdx);
        String leafField = path.substring(dotIdx + 1);

        Schema.DescribeSObjectResult relatedDescribe = describeRelatedObject(sourceDescribe, relationshipName);
        if (relatedDescribe == null || !fieldExists(relatedDescribe, leafField)) return null;

        ResolvedMapping rm = new ResolvedMapping();
        rm.relationshipName = relationshipName;
        rm.field = leafField;
        rm.selectExpression = relationshipName + '.' + leafField;
        return rm;
    }

    private static Boolean fieldExists(Schema.DescribeSObjectResult describe, String fieldName) {
        return describe.fields.getMap().containsKey(fieldName.toLowerCase());
    }

    // Finds the single sObject a relationship name (case-insensitive) points to, off the given
    // Source Object's describe. Returns null if the relationship doesn't exist, or if it's a
    // polymorphic lookup referencing more than one object (unsupported here).
    private static Schema.DescribeSObjectResult describeRelatedObject(Schema.DescribeSObjectResult sourceDescribe, String relationshipName) {
        for (Schema.SObjectField f : sourceDescribe.fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = f.getDescribe();
            if (dfr.getRelationshipName() != null && dfr.getRelationshipName().equalsIgnoreCase(relationshipName)) {
                List<Schema.SObjectType> referenceTo = dfr.getReferenceTo();
                if (referenceTo.size() != 1) return null;
                return referenceTo[0].getDescribe();
            }
        }
        return null;
    }

    // One supplemental bulk query per Source Object, built only from the select expressions
    // active mappings actually reference for that object — skipped entirely (returns an empty
    // map) if no resolved mapping sources from it. This runs post-insert/async rather than
    // inside the Opportunity trigger, so there's no Trigger.new to read from at all; both
    // direct and relationship-hop fields come from this one real, bulk-safe query with proper
    // nested relationship SObjects.
    private static Map<Id, SObject> queryBySelectExpressions(String objectName, Set<Id> ids, List<ResolvedMapping> resolved) {
        if (ids.isEmpty()) return new Map<Id, SObject>();

        Set<String> selectExpressions = new Set<String>{'Id'};
        for (ResolvedMapping rm : resolved) {
            if (rm.sourceObject == objectName) selectExpressions.add(rm.selectExpression);
        }
        if (selectExpressions.size() == 1) return new Map<Id, SObject>(); // no mapping actually sources from this object

        String soql = 'SELECT ' + String.join(new List<String>(selectExpressions), ', ')
            + ' FROM ' + objectName + ' WHERE Id IN :ids';
        Map<Id, SObject> byId = new Map<Id, SObject>();
        for (SObject record : Database.query(soql)) {
            byId.put((Id) record.get('Id'), record);
        }
        return byId;
    }

    // Config-sanity check — walks every active Case_Field_Mapping__c and reports (rather than
    // throws on) any row whose Source_Field_Path__c or Target_Field_API_Name__c doesn't
    // resolve against the real schema. Free-text config has no compile-time safety net, so
    // this is the guardrail that replaces it; call from a test against seeded data before
    // deploy, or ad hoc from anonymous Apex.
    public static List<String> validateActiveMappings() {
        List<String> problems = new List<String>();
        Schema.DescribeSObjectResult oppDescribe = Schema.SObjectType.Opportunity;
        Schema.DescribeSObjectResult acctDescribe = Schema.SObjectType.Account;
        Map<String, Schema.SObjectField> caseFieldMap = Schema.SObjectType.Case.fields.getMap();
        Map<String, Schema.SObjectField> caseDetailFieldMap = Schema.SObjectType.Case_Detail__c.fields.getMap();

        for (Case_Field_Mapping__c raw : queryActiveMappings()) {
            String targetObject = String.isBlank(raw.Target_Object__c) ? TARGET_CASE : raw.Target_Object__c.trim();
            String label = 'Case_Field_Mapping__c ' + raw.Id + ' (' + raw.Source_Object__c + '.' + raw.Source_Field_Path__c + ' -> ' + targetObject + '.' + raw.Target_Field_API_Name__c + ')';

            if (String.isBlank(raw.Source_Object__c) || String.isBlank(raw.Source_Field_Path__c) || String.isBlank(raw.Target_Field_API_Name__c)) {
                problems.add(label + ': missing a required field');
                continue;
            }

            if (targetObject != TARGET_CASE && targetObject != TARGET_CASE_DETAIL) {
                problems.add(label + ': Target Object must be Case or Case_Detail__c');
            } else {
                Map<String, Schema.SObjectField> targetFieldMap = targetObject == TARGET_CASE_DETAIL ? caseDetailFieldMap : caseFieldMap;
                Schema.SObjectField targetField = targetFieldMap.get(raw.Target_Field_API_Name__c.toLowerCase());
                if (targetField == null) {
                    problems.add(label + ': target field does not exist on ' + targetObject);
                } else {
                    Schema.DescribeFieldResult targetDescribe = targetField.getDescribe();
                    if (targetDescribe.isCalculated() || !targetDescribe.isUpdateable()) {
                        problems.add(label + ': target field is a formula/read-only field on ' + targetObject + ', not writable');
                    }
                }
            }

            Schema.DescribeSObjectResult sourceDescribe = raw.Source_Object__c == 'Account' ? acctDescribe
                : raw.Source_Object__c == 'Opportunity' ? oppDescribe : null;
            if (sourceDescribe == null) {
                problems.add(label + ': Source Object must be Opportunity or Account');
            } else if (resolvePath(raw.Source_Field_Path__c.trim(), sourceDescribe) == null) {
                problems.add(label + ': source field path does not resolve against ' + raw.Source_Object__c);
            }
        }
        return problems;
    }
}
