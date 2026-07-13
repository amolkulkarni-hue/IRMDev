public with sharing class CaseCreationRuleEvaluatorAction {

    public class Request {
        @InvocableVariable(label='Opportunity Id' required=true)
        public Id opportunityId;
    }

    public class MatchedRule {
        @InvocableVariable(label='Rule Id')
        public Id ruleId;
        @InvocableVariable(label='Rule Name')
        public String ruleName;
        @InvocableVariable(label='Case Type')
        public String caseType;
        @InvocableVariable(label='Record Type Developer Name')
        public String recordTypeDeveloperName;
        @InvocableVariable(label='Queue Developer Name')
        public String queueDeveloperName;
        @InvocableVariable(label='Required Document Types (comma-separated)')
        public String requiredDocTypes;
        @InvocableVariable(label='Required For Case Doc Types (comma-separated)')
        public String requiredForCaseDocTypes;
    }

    public class Result {
        @InvocableVariable(label='Matched Rules JSON')
        public String matchedRulesJson;
        @InvocableVariable(label='Has Matches')
        public Boolean hasMatches;
        @InvocableVariable(label='Matched Rule Count')
        public Integer matchedRuleCount;
    }

    @InvocableMethod(
        label='Evaluate Case Creation Rules'
        description='Evaluates Case_Creation_Rule__c conditions against Opportunity fields. Returns matched rules with doc requirements.'
        category='IRM Touch Level'
    )
    public static List<Result> evaluate(List<Request> requests) {
        if (requests == null || requests.isEmpty()) return new List<Result>();

        Set<Id> oppIds = new Set<Id>();
        for (Request req : requests) {
            if (req.opportunityId != null) oppIds.add(req.opportunityId);
        }

        List<Case_Creation_Rule__c> allRules = queryActiveRules();
        Map<String, List<Case_Creation_Rule__c>> rulesByStage = groupByStage(allRules);

        Set<String> fieldsToQuery = deriveWatchedFields(allRules);
        String oppSoql = 'SELECT ' + String.join(new List<String>(fieldsToQuery), ', ')
            + ' FROM Opportunity WHERE Id IN :oppIds';
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>((List<Opportunity>) Database.query(oppSoql));

        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Opportunity opp = oppMap.get(req.opportunityId);
            if (opp == null) {
                Result empty = new Result();
                empty.hasMatches = false;
                empty.matchedRuleCount = 0;
                results.add(empty);
            } else {
                results.add(resolveMatches(opp, rulesByStage));
            }
        }
        return results;
    }

    // Orchestration entry point — called from OpportunityTriggerHandler.AfterInsert/AfterUpdate.
    // Runs in an After-context (unlike TouchLevelEvaluatorAction, which runs Before-save) because
    // it creates Document_Checklist__c records on a different object, which needs the
    // Opportunity's real Id and is a natural post-save side effect.
    public static void createEligibleChecklistsAfterSave(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        if (newOpps == null || newOpps.isEmpty()) return;

        Boolean isInsert = (oldMap == null);
        List<Case_Creation_Rule__c> allRules = null;
        Map<String, List<Case_Creation_Rule__c>> rulesByStage = null;
        Set<String> watchedFields = null;

        List<Opportunity> relevantOpps = new List<Opportunity>();
        for (Opportunity opp : newOpps) {
            if (!isInsert) {
                if (watchedFields == null) {
                    allRules = queryActiveRules();
                    rulesByStage = groupByStage(allRules);
                    watchedFields = deriveWatchedFields(allRules);
                }
                if (!hasRelevantFieldChanged(opp, oldMap.get(opp.Id), watchedFields)) continue;
            } else if (rulesByStage == null) {
                allRules = queryActiveRules();
                rulesByStage = groupByStage(allRules);
            }
            relevantOpps.add(opp);
        }
        if (relevantOpps.isEmpty()) return;

        // Collect every (Opportunity, Rule, DocType) candidate first, then dedupe in one bulk
        // query against existing Document_Checklist__c rows before inserting survivors.
        List<Document_Checklist__c> candidates = new List<Document_Checklist__c>();
        Set<Id> candidateOppIds = new Set<Id>();
        Set<Id> candidateRuleIds = new Set<Id>();

        for (Opportunity opp : relevantOpps) {
            List<Case_Creation_Rule__c> stageRules = rulesByStage.get(opp.StageName);
            if (stageRules == null || stageRules.isEmpty()) continue;

            for (Case_Creation_Rule__c rule : stageRules) {
                if (!ruleMatches(rule, opp)) continue;

                List<SObject> docReqs = rule.getSObjects('Doc_Requirements__r');
                if (docReqs == null) continue;
                for (SObject dr : docReqs) {
                    if ((Boolean) dr.get('Is_Required_To_Start__c') != true) continue;
                    Document_Checklist__c dc = new Document_Checklist__c(
                        Opportunity__c        = opp.Id,
                        Case_Creation_Rule__c  = rule.Id,
                        DocumentType__c        = (String) dr.get('Document_Type__c'),
                        Document_Category__c   = mapDocCategory((String) dr.get('Document_Category__c')),
                        Status__c              = 'Draft'
                    );
                    candidates.add(dc);
                    candidateOppIds.add(opp.Id);
                    candidateRuleIds.add(rule.Id);
                }
            }
        }
        if (candidates.isEmpty()) return;

        Set<String> existingKeys = new Set<String>();
        for (Document_Checklist__c existing : [
            SELECT Opportunity__c, Case_Creation_Rule__c, DocumentType__c
            FROM Document_Checklist__c
            WHERE Opportunity__c IN :candidateOppIds AND Case_Creation_Rule__c IN :candidateRuleIds
        ]) {
            existingKeys.add(dedupeKey(existing.Opportunity__c, existing.Case_Creation_Rule__c, existing.DocumentType__c));
        }

        List<Document_Checklist__c> toInsert = new List<Document_Checklist__c>();
        for (Document_Checklist__c dc : candidates) {
            String key = dedupeKey(dc.Opportunity__c, dc.Case_Creation_Rule__c, dc.DocumentType__c);
            if (!existingKeys.contains(key)) {
                existingKeys.add(key); // guard against duplicate candidates within this same batch
                toInsert.add(dc);
            }
        }
        if (!toInsert.isEmpty()) {
            // Partial success — a single misconfigured Doc Requirement (e.g. missing
            // Document_Category__c) fails only that row, not the whole batch.
            Database.insert(toInsert, false);
        }
    }

    // Opportunity field API names referenced by any active Case_Creation_Condition__c, plus
    // StageName (always relevant, since which rules apply at all is stage-scoped).
    public static Set<String> getWatchedFieldNames() {
        return deriveWatchedFields(queryActiveRules());
    }

    private static String dedupeKey(Id oppId, Id ruleId, String docType) {
        return oppId + '|' + ruleId + '|' + docType;
    }

    // Case_Creation_Doc_Requirement__c.Document_Category__c and Document_Checklist__c.Document_Category__c
    // are two distinct picklists with different value sets despite representing the same
    // concept (e.g. 'Scoping and Technical Documents' vs 'Scoping & Technical') — translate
    // between them rather than copying the raw value across.
    private static final Map<String, String> DOC_CATEGORY_TRANSLATION = new Map<String, String>{
        'RFx and Bid Documents'                  => 'RFx & Bid Management',
        'Scoping and Technical Documents'        => 'Scoping & Technical',
        'Statement of Work (SOW) Documents'      => 'SOW & Contracts',
        'Pricing and Financial Documents'        => 'Pricing & Financial',
        'Contract and Legal Documents'           => 'Contract & Legal',
        'Compliance, Risk and Privacy Documents' => 'Compliance, Risk & Privacy',
        'Approval and Sign-off Documents'        => 'Approvals & Sign-off',
        'Onboarding and Setup Documents'         => 'Onboarding & Setup',
        'Booking Verification Documents'         => 'Booking Verification'
    };

    private static String mapDocCategory(String docReqCategory) {
        return DOC_CATEGORY_TRANSLATION.get(docReqCategory);
    }

    private static Boolean hasRelevantFieldChanged(Opportunity newOpp, Opportunity oldOpp, Set<String> watchedFields) {
        if (oldOpp == null) return true;
        for (String fieldName : watchedFields) {
            if (newOpp.get(fieldName) != oldOpp.get(fieldName)) return true;
        }
        return false;
    }

    private static Result resolveMatches(SObject opp, Map<String, List<Case_Creation_Rule__c>> rulesByStage) {
        Result res = new Result();
        res.hasMatches = false;
        res.matchedRuleCount = 0;

        List<Case_Creation_Rule__c> stageRules = rulesByStage.get((String) opp.get('StageName'));
        if (stageRules == null || stageRules.isEmpty()) return res;

        List<MatchedRule> matched = new List<MatchedRule>();
        for (Case_Creation_Rule__c rule : stageRules) {
            if (!ruleMatches(rule, opp)) continue;

            MatchedRule mr = new MatchedRule();
            mr.ruleId = rule.Id;
            mr.ruleName = rule.Name;
            mr.caseType = rule.Case_Type__c;
            mr.recordTypeDeveloperName = rule.Record_Type_Dev_Name__c;
            mr.queueDeveloperName = rule.Queue_Developer_Name__c;

            List<String> startDocs = new List<String>();
            List<String> caseDocs  = new List<String>();
            List<SObject> docReqs = rule.getSObjects('Doc_Requirements__r');
            if (docReqs != null) {
                for (SObject dr : docReqs) {
                    String docType = (String) dr.get('Document_Type__c');
                    if ((Boolean) dr.get('Is_Required_To_Start__c')) startDocs.add(docType);
                    if ((Boolean) dr.get('Is_Required_For_Case__c'))  caseDocs.add(docType);
                }
            }
            mr.requiredDocTypes        = String.join(startDocs, ',');
            mr.requiredForCaseDocTypes = String.join(caseDocs, ',');
            matched.add(mr);
        }

        res.hasMatches       = !matched.isEmpty();
        res.matchedRuleCount = matched.size();
        res.matchedRulesJson = JSON.serialize(matched);
        return res;
    }

    private static List<Case_Creation_Rule__c> queryActiveRules() {
        // Dynamic SOQL — bypasses compile-time relationship name check so objects and
        // Apex can deploy in a single package before the schema is registered.
        String soql =
            'SELECT Id, Name, Stage__c, Case_Type__c, Record_Type_Dev_Name__c, ' +
            '       Queue_Developer_Name__c, Logic_Expression__c, Priority__c, ' +
            '(SELECT Id, Condition_Number__c, Field_API_Name__c, Operator__c, Value__c ' +
            ' FROM Conditions__r ORDER BY Condition_Number__c ASC), ' +
            '(SELECT Id, Document_Type__c, Document_Category__c, Is_Required_To_Start__c, Is_Required_For_Case__c ' +
            ' FROM Doc_Requirements__r) ' +
            'FROM Case_Creation_Rule__c ' +
            'WHERE Is_Active__c = true ' +
            'ORDER BY Stage__c ASC, Priority__c ASC NULLS LAST';
        return Database.query(soql);
    }

    private static Map<String, List<Case_Creation_Rule__c>> groupByStage(List<Case_Creation_Rule__c> allRules) {
        Map<String, List<Case_Creation_Rule__c>> rulesByStage = new Map<String, List<Case_Creation_Rule__c>>();
        for (Case_Creation_Rule__c rule : allRules) {
            String stage = rule.Stage__c;
            if (!rulesByStage.containsKey(stage)) rulesByStage.put(stage, new List<Case_Creation_Rule__c>());
            rulesByStage.get(stage).add(rule);
        }
        return rulesByStage;
    }

    private static Set<String> deriveWatchedFields(List<Case_Creation_Rule__c> allRules) {
        // 'Id' is retained here (not just in getWatchedFieldNames' change-detection use) because
        // evaluate() reuses this same set to build its Opportunity SOQL query.
        Set<String> fields = new Set<String>{ 'Id', 'StageName' };
        Map<String, Schema.SObjectField> oppFieldMap = Schema.SObjectType.Opportunity.fields.getMap();
        for (Case_Creation_Rule__c rule : allRules) {
            List<SObject> conds = rule.getSObjects('Conditions__r');
            if (conds != null) {
                for (SObject c : conds) {
                    String fn = (String) c.get('Field_API_Name__c');
                    if (String.isNotBlank(fn) && oppFieldMap.containsKey(fn.trim().toLowerCase())) {
                        fields.add(fn.trim());
                    }
                }
            }
        }
        return fields;
    }

    private static Boolean ruleMatches(Case_Creation_Rule__c rule, SObject record) {
        List<SObject> conditions = rule.getSObjects('Conditions__r');
        if (conditions == null || conditions.isEmpty()) return true; // unconditional rule

        Map<Integer, Boolean> condResults = new Map<Integer, Boolean>();
        for (SObject cond : conditions) {
            Integer num = Integer.valueOf((Decimal) cond.get('Condition_Number__c'));
            condResults.put(num, evaluateCondition(cond, record));
        }

        String logicExpr = String.isBlank(rule.Logic_Expression__c)
            ? buildDefaultAndExpression(condResults.keySet())
            : rule.Logic_Expression__c.trim();

        return evaluateLogicExpression(logicExpr, condResults);
    }

    private static Boolean evaluateCondition(SObject cond, SObject record) {
        String fieldName    = (String) cond.get('Field_API_Name__c');
        String operator     = (String) cond.get('Operator__c');
        String compareValue = (String) cond.get('Value__c');

        Object fieldValue;
        try { fieldValue = record.get(fieldName); } catch (Exception e) { return false; }

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