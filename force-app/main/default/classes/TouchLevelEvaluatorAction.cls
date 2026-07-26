public with sharing class TouchLevelEvaluatorAction {

    public class Request {
        @InvocableVariable(label='Opportunity Id' required=true)
        public Id opportunityId;
    }

    public class Result {
        @InvocableVariable(label='Calculated Touch Level')
        public String touchLevel;

        @InvocableVariable(label='Matched Criteria Name')
        public String matchedCriteriaName;
    }

    // Touch Level calculation/recalculation only ever applies to these two Opportunity
    // record types. Every other record type is left completely untouched.
    public static final Set<Id> TOUCH_LEVEL_ELIGIBLE_RECORD_TYPES = new Set<Id>{
        App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
        App_Constants.FRAMEWORK_PARENT_OPPORTUNITY_RECTYPE_ID
    };

    // Parsed form of Touch_Level_Condition__c.Field_API_Name__c. Supports either a direct
    // Opportunity field ("Amount") or a single-level Account relationship field
    // ("Account.Industry") — matching SOQL relationship-traversal syntax. Anything else
    // (unrecognized relationship, more than one dot) is treated as invalid and dropped by
    // the callers, same fail-closed behavior already applied to unrecognized field names.
    private class FieldPath {
        public String relationship; // null => direct Opportunity field; 'Account' otherwise
        public String field;        // bare field API name
    }

    private static FieldPath parseFieldPath(String raw) {
        if (String.isBlank(raw)) return null;
        String trimmed = raw.trim();
        Integer dotIdx = trimmed.indexOf('.');
        FieldPath fp = new FieldPath();
        if (dotIdx < 0) {
            fp.field = trimmed;
            return fp;
        }
        if (trimmed.indexOf('.', dotIdx + 1) >= 0) return null; // more than one dot — unsupported
        if (!trimmed.substring(0, dotIdx).equalsIgnoreCase('Account')) return null; // only Account is supported
        fp.relationship = 'Account';
        fp.field = trimmed.substring(dotIdx + 1);
        return fp;
    }

    @InvocableMethod(
        label='Evaluate Touch Level'
        description='Evaluates Touch Level for Opportunities against active Touch_Level_Criteria__c config (Opportunity and Account fields).'
        category='IRM Touch Level'
    )
    public static List<Result> evaluate(List<Request> requests) {
        if (requests == null || requests.isEmpty()) return new List<Result>();

        Set<Id> oppIds = new Set<Id>();
        for (Request req : requests) {
            if (req.opportunityId != null) oppIds.add(req.opportunityId);
        }

        List<Touch_Level_Criteria__c> allCriteria = queryActiveCriteria();
        Map<String, List<Touch_Level_Criteria__c>> criteriaByStage = groupByStage(allCriteria);

        Set<String> fieldsToQuery = new Set<String>(deriveWatchedOpportunityFields(allCriteria));
        fieldsToQuery.add('RecordTypeId');
        for (String acctField : deriveWatchedAccountFields(allCriteria)) {
            fieldsToQuery.add('Account.' + acctField);
        }
        String oppSoql = 'SELECT Id, ' + String.join(new List<String>(fieldsToQuery), ', ')
            + ' FROM Opportunity WHERE Id IN :oppIds';
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>((List<Opportunity>) Database.query(oppSoql));

        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Opportunity opp = oppMap.get(req.opportunityId);
            results.add(opp == null ? new Result() : resolveTouchLevel(opp, criteriaByStage));
        }
        return results;
    }

    // Orchestration entry point — called from OpportunityTriggerHandler.BeforeInsert/BeforeUpdate.
    // Runs in a Before-context so results are set directly on the in-memory records (no extra
    // DML, no recursion risk). A batch Account query is still needed here (only when a Touch
    // Level condition actually references "Account.<field>") because trigger.new/old records
    // carry no related-object data — see attachAccountData.
    public static void recalculateBeforeSave(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        if (newOpps == null || newOpps.isEmpty()) return;

        Boolean isInsert = (oldMap == null);
        Map<String, List<Touch_Level_Criteria__c>> criteriaByStage = null;
        Set<String> watchedFields = null;
        Set<String> watchedAccountFields = null;

        List<Opportunity> relevantOpps = new List<Opportunity>();
        for (Opportunity opp : newOpps) {
            if (!TOUCH_LEVEL_ELIGIBLE_RECORD_TYPES.contains(opp.RecordTypeId)) continue;
            if (opp.Touch_Level_Override__c == true) continue;

            if (!isInsert) {
                if (watchedFields == null) {
                    List<Touch_Level_Criteria__c> allCriteria = queryActiveCriteria();
                    criteriaByStage = groupByStage(allCriteria);
                    watchedFields = deriveWatchedOpportunityFields(allCriteria);
                    watchedAccountFields = deriveWatchedAccountFields(allCriteria);
                }
                if (!hasRelevantFieldChanged(opp, oldMap.get(opp.Id), watchedFields)) continue;
            } else if (criteriaByStage == null) {
                List<Touch_Level_Criteria__c> allCriteria = queryActiveCriteria();
                criteriaByStage = groupByStage(allCriteria);
                watchedAccountFields = deriveWatchedAccountFields(allCriteria);
            }
            relevantOpps.add(opp);
        }
        if (relevantOpps.isEmpty()) return;

        attachAccountData(relevantOpps, watchedAccountFields);

        for (Opportunity opp : relevantOpps) {
            Result calculated = resolveTouchLevel(opp, criteriaByStage);

            // No-downgrade rule: High Touch is never automatically downgraded.
            String finalTouchLevel = calculated.touchLevel;
            if (opp.Touch_Level__c == 'High Touch' && finalTouchLevel != 'High Touch') {
                finalTouchLevel = 'High Touch';
            }

            opp.Touch_Level_Calculated__c = calculated.touchLevel;
            opp.Touch_Level__c = finalTouchLevel;
            opp.Touch_Level_Criteria_Matched__c = calculated.matchedCriteriaName;
            opp.Touch_Level_Calculation_Stage__c = opp.StageName;
            opp.Touch_Level_Last_Calculated__c = System.now();
        }
    }

    // Account-driven recompute — called from the "Reevaluate Touch Level For Account
    // Changes" invocable below, itself invoked by Case_Creation_Account_Reevaluation_Flow
    // (Account, record-triggered, after save), ahead of the Case Creation reevaluation so a
    // freshly recalculated Touch_Level__c is visible to any Case Creation condition that
    // references it. Unlike recalculateBeforeSave, this runs outside any Opportunity
    // trigger context, so results are written back with an explicit `update` — but only for
    // Opportunities whose computed value actually changed, so this never issues a no-op DML
    // that would otherwise needlessly re-enter the Opportunity trigger.
    public static void recalculateForAccountDrivenOpportunities(List<Opportunity> opps, List<Touch_Level_Criteria__c> allCriteria) {
        if (opps == null || opps.isEmpty()) return;

        Map<String, List<Touch_Level_Criteria__c>> criteriaByStage = groupByStage(allCriteria);

        List<Opportunity> toUpdate = new List<Opportunity>();
        for (Opportunity opp : opps) {
            if (!TOUCH_LEVEL_ELIGIBLE_RECORD_TYPES.contains(opp.RecordTypeId)) continue;
            if (opp.Touch_Level_Override__c == true) continue;

            Result calculated = resolveTouchLevel(opp, criteriaByStage);

            String finalTouchLevel = calculated.touchLevel;
            if (opp.Touch_Level__c == 'High Touch' && finalTouchLevel != 'High Touch') {
                finalTouchLevel = 'High Touch';
            }

            if (opp.Touch_Level__c == finalTouchLevel && opp.Touch_Level_Calculated__c == calculated.touchLevel) {
                continue; // no change — skip the DML for this Opportunity entirely
            }

            toUpdate.add(new Opportunity(
                Id                                = opp.Id,
                Touch_Level_Calculated__c         = calculated.touchLevel,
                Touch_Level__c                    = finalTouchLevel,
                Touch_Level_Criteria_Matched__c    = calculated.matchedCriteriaName,
                Touch_Level_Calculation_Stage__c  = opp.StageName,
                Touch_Level_Last_Calculated__c     = System.now()
            ));
        }
        if (!toUpdate.isEmpty()) update toUpdate;
    }

    // Callable core for Account-driven re-evaluation — exposed as a Flow action via the
    // separate TouchLevelAccountReevaluationAction class (Apex only supports one
    // @InvocableMethod being unambiguously addressable per class from Flow metadata, and
    // this class already has one — evaluate() — so the Flow-facing wrapper lives apart).
    public static void reevaluateForAccountChanges(List<TouchLevelAccountReevaluationRequest> requests) {
        if (requests == null || requests.isEmpty()) return;

        List<Touch_Level_Criteria__c> allCriteria = queryActiveCriteria();
        Set<String> watchedAccountFields = deriveWatchedAccountFields(allCriteria);
        if (watchedAccountFields.isEmpty()) return; // no criteria references an Account field — nothing to do

        Set<Id> changedAccountIds = new Set<Id>();
        for (TouchLevelAccountReevaluationRequest req : requests) {
            if (req.newAccount == null || req.newAccount.Id == null) continue;
            if (hasAccountFieldChanged(req.newAccount, req.oldAccount, watchedAccountFields)) {
                changedAccountIds.add(req.newAccount.Id);
            }
        }
        if (changedAccountIds.isEmpty()) return;

        Set<String> oppSelectFields = new Set<String>{
            'Id', 'AccountId', 'StageName', 'RecordTypeId',
            'Touch_Level__c', 'Touch_Level_Calculated__c', 'Touch_Level_Override__c'
        };
        oppSelectFields.addAll(deriveWatchedOpportunityFields(allCriteria));
        String oppSoql = 'SELECT ' + String.join(new List<String>(oppSelectFields), ', ')
            + ' FROM Opportunity WHERE AccountId IN :changedAccountIds AND IsClosed = false';
        List<Opportunity> openOpps = Database.query(oppSoql);
        if (openOpps.isEmpty()) return;

        attachAccountData(openOpps, watchedAccountFields);
        recalculateForAccountDrivenOpportunities(openOpps, allCriteria);
    }

    private static Boolean hasAccountFieldChanged(Account newAcct, Account oldAcct, Set<String> watchedFields) {
        if (oldAcct == null) return true;
        for (String fieldName : watchedFields) {
            if (newAcct.get(fieldName) != oldAcct.get(fieldName)) return true;
        }
        return false;
    }

    // Queries only the Account fields any active Touch_Level_Condition__c references (via
    // "Account.<field>") and attaches each result onto its Opportunity's in-memory
    // "Account" relationship via putSObject — letting evaluateCondition traverse it exactly
    // as it would a real SOQL relationship query, without needing to re-query Opportunity
    // itself (its own field values, whether from trigger context or a prior SOQL, must not
    // be replaced).
    private static void attachAccountData(List<Opportunity> opps, Set<String> watchedAccountFields) {
        if (watchedAccountFields == null || watchedAccountFields.isEmpty() || opps.isEmpty()) return;

        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opps) {
            if (opp.AccountId != null) accountIds.add(opp.AccountId);
        }
        if (accountIds.isEmpty()) return;

        Set<String> selectFields = new Set<String>{ 'Id' };
        selectFields.addAll(watchedAccountFields);
        String acctSoql = 'SELECT ' + String.join(new List<String>(selectFields), ', ')
            + ' FROM Account WHERE Id IN :accountIds';
        Map<Id, Account> acctById = new Map<Id, Account>((List<Account>) Database.query(acctSoql));

        for (Opportunity opp : opps) {
            Account acct = opp.AccountId == null ? null : acctById.get(opp.AccountId);
            if (acct != null) opp.putSObject('Account', acct);
        }
    }

    // Opportunity field API names referenced by any active Touch_Level_Condition__c, plus
    // StageName (always relevant, since which criteria apply at all is stage-scoped). Account
    // relationship fields (e.g. "Account.Industry") are excluded here — see getWatchedAccountFieldNames.
    public static Set<String> getWatchedFieldNames() {
        return deriveWatchedOpportunityFields(queryActiveCriteria());
    }

    // Bare Account field API names (without the "Account." prefix) referenced by any active
    // Touch_Level_Condition__c.
    public static Set<String> getWatchedAccountFieldNames() {
        return deriveWatchedAccountFields(queryActiveCriteria());
    }

    private static Boolean hasRelevantFieldChanged(Opportunity newOpp, Opportunity oldOpp, Set<String> watchedFields) {
        if (oldOpp == null) return true;
        for (String fieldName : watchedFields) {
            if (newOpp.get(fieldName) != oldOpp.get(fieldName)) return true;
        }
        return false;
    }

    private static Result resolveTouchLevel(SObject opp, Map<String, List<Touch_Level_Criteria__c>> criteriaByStage) {
        Result res = new Result();
        res.touchLevel = 'No Touch';
        res.matchedCriteriaName = null;

        if (!TOUCH_LEVEL_ELIGIBLE_RECORD_TYPES.contains((Id) opp.get('RecordTypeId'))) {
            res.touchLevel = null;
            return res;
        }

        List<Touch_Level_Criteria__c> stageCriteria = criteriaByStage.get((String) opp.get('StageName'));
        if (stageCriteria == null || stageCriteria.isEmpty()) return res;

        for (Touch_Level_Criteria__c criteria : stageCriteria) {
            if (criteriaMatches(criteria, opp)) {
                res.touchLevel = criteria.Touch_Level_Result__c;
                res.matchedCriteriaName = criteria.Name;
                break;
            }
        }
        return res;
    }

    private static List<Touch_Level_Criteria__c> queryActiveCriteria() {
        // Dynamic SOQL — bypasses compile-time relationship name check so objects and
        // Apex can deploy in a single package before the schema is registered.
        String soql =
            'SELECT Id, Name, Stage__c, Touch_Level_Result__c, Priority__c, Logic_Expression__c, ' +
            '(SELECT Id, Condition_Number__c, Field_API_Name__c, Operator__c, Value__c ' +
            ' FROM Conditions__r ORDER BY Condition_Number__c ASC) ' +
            'FROM Touch_Level_Criteria__c ' +
            'WHERE Is_Active__c = true ' +
            'ORDER BY Stage__c ASC, Priority__c ASC';
        return Database.query(soql);
    }

    private static Map<String, List<Touch_Level_Criteria__c>> groupByStage(List<Touch_Level_Criteria__c> allCriteria) {
        Map<String, List<Touch_Level_Criteria__c>> criteriaByStage = new Map<String, List<Touch_Level_Criteria__c>>();
        for (Touch_Level_Criteria__c criteria : allCriteria) {
            String stage = criteria.Stage__c;
            if (!criteriaByStage.containsKey(stage)) {
                criteriaByStage.put(stage, new List<Touch_Level_Criteria__c>());
            }
            criteriaByStage.get(stage).add(criteria);
        }
        return criteriaByStage;
    }

    private static Set<String> deriveWatchedOpportunityFields(List<Touch_Level_Criteria__c> allCriteria) {
        Set<String> fields = new Set<String>{'StageName'};
        Map<String, Schema.SObjectField> oppFieldMap = Schema.SObjectType.Opportunity.fields.getMap();
        for (Touch_Level_Criteria__c c : allCriteria) {
            List<SObject> conds = c.getSObjects('Conditions__r');
            if (conds != null) {
                for (SObject cond : conds) {
                    FieldPath fp = parseFieldPath((String) cond.get('Field_API_Name__c'));
                    if (fp == null || fp.relationship != null) continue; // Account-scoped — see deriveWatchedAccountFields
                    if (oppFieldMap.containsKey(fp.field.toLowerCase())) fields.add(fp.field);
                }
            }
        }
        return fields;
    }

    // Bare Account field API names (no "Account." prefix) referenced by any active
    // Touch_Level_Condition__c whose Field_API_Name__c is an "Account.<field>" path.
    private static Set<String> deriveWatchedAccountFields(List<Touch_Level_Criteria__c> allCriteria) {
        Set<String> fields = new Set<String>();
        Map<String, Schema.SObjectField> acctFieldMap = Schema.SObjectType.Account.fields.getMap();
        for (Touch_Level_Criteria__c c : allCriteria) {
            List<SObject> conds = c.getSObjects('Conditions__r');
            if (conds != null) {
                for (SObject cond : conds) {
                    FieldPath fp = parseFieldPath((String) cond.get('Field_API_Name__c'));
                    if (fp == null || fp.relationship == null) continue;
                    if (acctFieldMap.containsKey(fp.field.toLowerCase())) fields.add(fp.field);
                }
            }
        }
        return fields;
    }

    private static Boolean criteriaMatches(Touch_Level_Criteria__c criteria, SObject record) {
        // getSObjects() bypasses compile-time relationship name validation
        List<SObject> conditions = criteria.getSObjects('Conditions__r');
        if (conditions == null || conditions.isEmpty()) return false;

        Map<Integer, Boolean> conditionResults = new Map<Integer, Boolean>();
        for (SObject cond : conditions) {
            Integer num = Integer.valueOf((Decimal) cond.get('Condition_Number__c'));
            conditionResults.put(num, evaluateCondition(cond, record));
        }

        String logicExpr = String.isBlank(criteria.Logic_Expression__c)
            ? buildDefaultAndExpression(conditionResults.keySet())
            : criteria.Logic_Expression__c.trim();

        return evaluateLogicExpression(logicExpr, conditionResults);
    }

    private static Boolean evaluateCondition(SObject cond, SObject record) {
        String fieldApiName = (String) cond.get('Field_API_Name__c');
        String operator      = (String) cond.get('Operator__c');
        String compareValue  = (String) cond.get('Value__c');

        FieldPath fp = parseFieldPath(fieldApiName);
        Object fieldValue;
        try {
            if (fp == null) {
                fieldValue = null;
            } else if (fp.relationship == null) {
                fieldValue = record.get(fp.field);
            } else {
                SObject related = record.getSObject(fp.relationship);
                fieldValue = related == null ? null : related.get(fp.field);
            }
        } catch (Exception e) { return false; }

        if (operator == 'IS_NULL')     return fieldValue == null;
        if (operator == 'IS_NOT_NULL') return fieldValue != null;
        if (operator == 'IS_TRUE')     return fieldValue == true;
        if (operator == 'IS_FALSE')    return fieldValue == false || fieldValue == null;

        String fieldStr = fieldValue != null ? String.valueOf(fieldValue) : '';

        if (operator == 'EQUALS')     return fieldStr == compareValue;
        if (operator == 'NOT_EQUALS') return fieldStr != compareValue;
        if (operator == 'CONTAINS')   return fieldStr.containsIgnoreCase(compareValue);
        if (operator == 'IN')         return toSet(compareValue).contains(fieldStr);
        if (operator == 'NOT_IN')     return !toSet(compareValue).contains(fieldStr);

        try {
            Decimal fieldNum   = Decimal.valueOf(fieldStr);
            Decimal compareNum = Decimal.valueOf(compareValue);
            if (operator == 'GREATER_THAN')     return fieldNum > compareNum;
            if (operator == 'LESS_THAN')        return fieldNum < compareNum;
            if (operator == 'GREATER_OR_EQUAL') return fieldNum >= compareNum;
            if (operator == 'LESS_OR_EQUAL')    return fieldNum <= compareNum;
        } catch (Exception e) { return false; }

        return false;
    }

    private static Boolean evaluateLogicExpression(String expr, Map<Integer, Boolean> condResults) {
        String evaluated = expr.toUpperCase();
        for (Integer num : condResults.keySet()) {
            evaluated = evaluated.replaceAll('\\b' + num + '\\b', condResults.get(num) ? 'TRUE' : 'FALSE');
        }
        return parseBooleanExpression(evaluated);
    }

    private static Boolean parseBooleanExpression(String expr) {
        expr = expr.trim();
        while (expr.contains('(')) {
            Integer closeIdx = expr.indexOf(')');
            Integer openIdx  = expr.lastIndexOf('(', closeIdx);
            String innerStr  = expr.substring(openIdx + 1, closeIdx);
            Boolean innerResult = parseBooleanExpression(innerStr);
            expr = expr.substring(0, openIdx) + (innerResult ? 'TRUE' : 'FALSE') + expr.substring(closeIdx + 1);
        }
        if (expr.contains(' OR ')) {
            for (String part : expr.split(' OR ')) {
                if (parseBooleanExpression(part.trim())) return true;
            }
            return false;
        }
        if (expr.contains(' AND ')) {
            for (String part : expr.split(' AND ')) {
                if (!parseBooleanExpression(part.trim())) return false;
            }
            return true;
        }
        return expr.trim() == 'TRUE';
    }

    private static String buildDefaultAndExpression(Set<Integer> nums) {
        List<Integer> sorted = new List<Integer>(nums);
        sorted.sort();
        List<String> parts = new List<String>();
        for (Integer n : sorted) parts.add(String.valueOf(n));
        return String.join(parts, ' AND ');
    }

    private static Set<String> toSet(String csv) {
        Set<String> result = new Set<String>();
        if (String.isBlank(csv)) return result;
        for (String val : csv.split(',')) result.add(val.trim());
        return result;
    }
}
