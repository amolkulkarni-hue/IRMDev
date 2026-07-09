@IsTest
private class TouchLevelEvaluatorActionTest {

    // ──────────────────────────────────────────────────────────
    // Test data setup
    // ──────────────────────────────────────────────────────────

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'IRM Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Amount = 500000
        );
        insert opp;
    }

    private static Opportunity getOpp() {
        return [SELECT Id, StageName, Amount FROM Opportunity LIMIT 1];
    }

    private static Touch_Level_Criteria__c makeCriteria(
            String stage, String touchLevel, Integer priority, String logicExpr) {
        Touch_Level_Criteria__c c = new Touch_Level_Criteria__c(
            Stage__c = stage,
            Touch_Level_Result__c = touchLevel,
            Priority__c = priority,
            Logic_Expression__c = logicExpr,
            Is_Active__c = true
        );
        insert c;
        return c;
    }

    private static Touch_Level_Condition__c makeCondition(
            Id criteriaId, Integer num, String fieldName, String operator, String value) {
        Touch_Level_Condition__c cond = new Touch_Level_Condition__c(
            Criteria__c = criteriaId,
            Condition_Number__c = num,
            Field_API_Name__c = fieldName,
            Operator__c = operator,
            Value__c = value
        );
        insert cond;
        return cond;
    }

    // ──────────────────────────────────────────────────────────
    // Tests
    // ──────────────────────────────────────────────────────────

    @IsTest
    static void testHighTouchMatch_AmountAboveThreshold() {
        Opportunity opp = getOpp();
        // opp.Amount = 500000

        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, null);
        makeCondition(criteria.Id, 1, 'Amount', 'GREATER_THAN', '100000');

        Test.startTest();
        TouchLevelEvaluatorAction.Request req = new TouchLevelEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<TouchLevelEvaluatorAction.Result> results =
            TouchLevelEvaluatorAction.evaluate(new List<TouchLevelEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('High Touch', results[0].touchLevel);
        System.assertNotEquals(null, results[0].matchedCriteriaName);
    }

    @IsTest
    static void testMediumTouchMatch_AmountBelowHighThreshold() {
        Opportunity opp = getOpp();
        // Amount = 500000 — does NOT match HIGH (GREATER_THAN 1000000)
        // Should fall through to MEDIUM

        Touch_Level_Criteria__c highCriteria = makeCriteria('Qualification', 'High Touch', 1, null);
        makeCondition(highCriteria.Id, 1, 'Amount', 'GREATER_THAN', '1000000');

        Touch_Level_Criteria__c medCriteria = makeCriteria('Qualification', 'Medium Touch', 2, null);
        makeCondition(medCriteria.Id, 1, 'Amount', 'GREATER_THAN', '100000');

        Test.startTest();
        TouchLevelEvaluatorAction.Request req = new TouchLevelEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<TouchLevelEvaluatorAction.Result> results =
            TouchLevelEvaluatorAction.evaluate(new List<TouchLevelEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals('Medium Touch', results[0].touchLevel);
    }

    @IsTest
    static void testNoTouchWhenNoMatch() {
        Opportunity opp = getOpp();
        // Criteria requires Amount > 2M but opp is only 500k

        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, null);
        makeCondition(criteria.Id, 1, 'Amount', 'GREATER_THAN', '2000000');

        Test.startTest();
        TouchLevelEvaluatorAction.Request req = new TouchLevelEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<TouchLevelEvaluatorAction.Result> results =
            TouchLevelEvaluatorAction.evaluate(new List<TouchLevelEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals('No Touch', results[0].touchLevel);
    }

    @IsTest
    static void testNoTouchWhenNoActiveCriteria() {
        Opportunity opp = getOpp();

        Touch_Level_Criteria__c criteria = new Touch_Level_Criteria__c(
            Stage__c = 'Qualification',
            Touch_Level_Result__c = 'High Touch',
            Priority__c = 1,
            Is_Active__c = false
        );
        insert criteria;

        Test.startTest();
        TouchLevelEvaluatorAction.Request req = new TouchLevelEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<TouchLevelEvaluatorAction.Result> results =
            TouchLevelEvaluatorAction.evaluate(new List<TouchLevelEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals('No Touch', results[0].touchLevel);
        System.assertEquals(null, results[0].matchedCriteriaName);
    }

    @IsTest
    static void testAndLogicExpression_BothConditionsMustPass() {
        Opportunity opp = getOpp();
        // opp.Amount = 500000, StageName = Qualification

        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, '1 AND 2');
        makeCondition(criteria.Id, 1, 'Amount', 'GREATER_THAN', '100000');
        makeCondition(criteria.Id, 2, 'StageName', 'EQUALS', 'Proposal/Price Quote'); // will fail

        Test.startTest();
        TouchLevelEvaluatorAction.Request req = new TouchLevelEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<TouchLevelEvaluatorAction.Result> results =
            TouchLevelEvaluatorAction.evaluate(new List<TouchLevelEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals('No Touch', results[0].touchLevel, 'Both conditions must pass for AND');
    }

    @IsTest
    static void testOrLogicExpression_EitherConditionSuffices() {
        Opportunity opp = getOpp();
        // Condition 1 fails (wrong stage), Condition 2 passes (amount)

        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, '1 OR 2');
        makeCondition(criteria.Id, 1, 'StageName', 'EQUALS', 'Proposal/Price Quote'); // fails
        makeCondition(criteria.Id, 2, 'Amount', 'GREATER_THAN', '100000'); // passes

        Test.startTest();
        TouchLevelEvaluatorAction.Request req = new TouchLevelEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<TouchLevelEvaluatorAction.Result> results =
            TouchLevelEvaluatorAction.evaluate(new List<TouchLevelEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals('High Touch', results[0].touchLevel, 'OR: either condition suffices');
    }

    @IsTest
    static void testBulk_200Opportunities() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            opps.add(new Opportunity(
                Name = 'Bulk Opp ' + i,
                AccountId = acc.Id,
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(30),
                Amount = 500000
            ));
        }
        insert opps;

        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'Medium Touch', 1, null);
        makeCondition(criteria.Id, 1, 'Amount', 'GREATER_THAN', '100000');

        List<TouchLevelEvaluatorAction.Request> requests = new List<TouchLevelEvaluatorAction.Request>();
        for (Opportunity opp : opps) {
            TouchLevelEvaluatorAction.Request req = new TouchLevelEvaluatorAction.Request();
            req.opportunityId = opp.Id;
            requests.add(req);
        }

        Test.startTest();
        List<TouchLevelEvaluatorAction.Result> results = TouchLevelEvaluatorAction.evaluate(requests);
        Test.stopTest();

        System.assertEquals(200, results.size());
        for (TouchLevelEvaluatorAction.Result res : results) {
            System.assertEquals('Medium Touch', res.touchLevel);
        }
    }

    @IsTest
    static void testIsNullOperator() {
        Opportunity opp = getOpp();
        // Amount is set to 500000, not null

        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, null);
        makeCondition(criteria.Id, 1, 'Amount', 'IS_NULL', null);

        Test.startTest();
        TouchLevelEvaluatorAction.Request req = new TouchLevelEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<TouchLevelEvaluatorAction.Result> results =
            TouchLevelEvaluatorAction.evaluate(new List<TouchLevelEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals('No Touch', results[0].touchLevel, 'Amount is not null so IS_NULL fails');
    }
}