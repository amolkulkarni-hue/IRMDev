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

    @InvocableMethod(
        label='Evaluate Touch Level'
        description='Evaluates Touch Level for Opportunities against active Touch_Level_Criteria__c config.'
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

        Set<String> fieldsToQuery = deriveWatchedFields(allCriteria);
        fieldsToQuery.add('RecordTypeId');
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
    // SOQL re-query of Opportunity, no extra DML, no recursion risk).
    public static void recalculateBeforeSave(List<Opportunity> newOpps, Map<Id, Opportunity> oldMap) {
        if (newOpps == null || newOpps.isEmpty()) return;

        Boolean isInsert = (oldMap == null);
        Map<String, List<Touch_Level_Criteria__c>> criteriaByStage = null;
        Set<String> watchedFields = null;

        for (Opportunity opp : newOpps) {
            if (!TOUCH_LEVEL_ELIGIBLE_RECORD_TYPES.contains(opp.RecordTypeId)) continue;
            if (opp.Touch_Level_Override__c == true) continue;

            if (!isInsert) {
                if (watchedFields == null) {
                    List<Touch_Level_Criteria__c> allCriteria = queryActiveCriteria();
                    criteriaByStage = groupByStage(allCriteria);
                    watchedFields = deriveWatchedFields(allCriteria);
                }
                if (!hasRelevantFieldChanged(opp, oldMap.get(opp.Id), watchedFields)) continue;
            } else if (criteriaByStage == null) {
                criteriaByStage = groupByStage(queryActiveCriteria());
            }

            Result calculated = resolveTouchLevel(opp, criteriaByStage);

            // No-downgrade rule: High Touch is never automatically downgraded.
            String finalTouchLevel = calculated.touchLevel;
            if (opp.Touch_Level__c == 'High Touch' && finalTouchLevel != 'High Touch') {
                finalTouchLevel = 'High Touch';
            }

            opp.Touch_Level_Calculated__c = calculated.touchLevel;
            opp.Touch_Level__c = finalTouchLevel;
            opp.Touch_Level_Criteria_Matched__c = calculated.matchedCriteriaName;
        }
    }

    // Opportunity field API names referenced by any active Touch_Level_Condition__c, plus
    // StageName (always relevant, since which criteria apply at all is stage-scoped).
    public static Set<String> getWatchedFieldNames() {
        return deriveWatchedFields(queryActiveCriteria());
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

    private static Set<String> deriveWatchedFields(List<Touch_Level_Criteria__c> allCriteria) {
        Set<String> fields = new Set<String>{'StageName'};
        Map<String, Schema.SObjectField> oppFieldMap = Schema.SObjectType.Opportunity.fields.getMap();
        for (Touch_Level_Criteria__c c : allCriteria) {
            List<SObject> conds = c.getSObjects('Conditions__r');
            if (conds != null) {
                for (SObject cond : conds) {
                    String fn = (String) cond.get('Field_API_Name__c');
                    if (String.isNotBlank(fn) && oppFieldMap.containsKey(fn.trim().toLowerCase())) {
                        fields.add(fn.trim());
                    }
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
        String fieldName = (String) cond.get('Field_API_Name__c');
        String operator  = (String) cond.get('Operator__c');
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