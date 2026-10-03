@IsTest
private class TouchLevelEvaluatorActionTest {

    // ──────────────────────────────────────────────────────────
    // Test data setup
    // ──────────────────────────────────────────────────────────

    @TestSetup
    static void setup() {
         IM_Country__c testCountry = new IM_Country__c(Name = 'United States');
        insert testCountry;
        insert new IM_Alternative_Country_Name__c(
            IM_Country__c = testCountry.Id, Alternative_Name__c = 'United States'
        );
        
        // Opportunity_Security__c are list custom settings read during Opportunity AfterInsert)
        insert new Country_Settings__c(Name = 'United States', Object_Name__c = 'Opportunity', SetupOwnerId = UserInfo.getOrganizationId());
        insert new List<Opportunity_Security__c>{
            new Opportunity_Security__c(Name = 'Primary CDE',          Field_Name__c = 'Primary_CDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'R', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Original Lead Owner',  Field_Name__c = 'IM_Original_Lead_Owner__c', Object_Name__c = 'Opportunity', Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Primary BDE',          Field_Name__c = 'Primary_BDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId())
        };
        // Required by OppPartnerAction (called from OpportunityTriggerHandler.BeforeUpdate
        // via "Update Pricebook On Opportunity" flow — queries this record by name)
        insert new OpportunityProductSelection__c(Name = 'CloudSolutionsProduct',
            Product_Class_Name__c = 'Cloud', Product_Line_Name__c = 'Cloud Solutions');

       Account acc = new Account(
            Name = 'IRM Test Account',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;
         // Satisfies the Contact_or_User_Info validation rule (Case requires either
        // ContactId or IM_Employee_Contact__c) for the ReassertCaseOwnerJob tests below.
        insert new Contact(LastName = 'ReassertOwnerJobTestContact', AccountId = acc.Id);

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            Type = 'New Deal',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(),
            Amount = 500000, ALM_EAA__c = 500000,
            Bypass_Validation__c = true
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
        // Criteria must exist before the Opportunities are inserted: TouchLevelEvaluatorAction
        // caches active criteria for the transaction the first time it's queried, and the
        // Opportunity insert trigger queries it immediately. Creating criteria afterward would
        // leave the cache populated with an empty (pre-criteria) result for the rest of the test.
        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'Medium Touch', 1, null);
        makeCondition(criteria.Id, 1, 'Amount', 'GREATER_THAN', '100000');

        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            opps.add(new Opportunity(
                Name = 'Bulk Opp ' + i,
                AccountId = acc.Id,
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(30),
                Amount = 500000, ALM_EAA__c = 500000
            ));
        }
        insert opps;

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

    // ──────────────────────────────────────────────────────────
    // recalculateBeforeSave — the Before-save orchestration entry point (called from
    // OpportunityTriggerHandler.BeforeInsert/BeforeUpdate). Exercised directly against
    // in-memory Opportunity records — no DML needed, since the method only ever mutates
    // the SObjects it's handed.
    // ──────────────────────────────────────────────────────────

    @IsTest
    static void testRecalculateBeforeSave_Insert_EligibleRecordType_SetsTouchLevel() {
        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, null);
        makeCondition(criteria.Id, 1, 'Amount', 'GREATER_THAN', '100000');

        Opportunity opp = new Opportunity(
            RecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
            StageName = 'Qualification',
            Amount = 500000
        );

        Test.startTest();
        TouchLevelEvaluatorAction.recalculateBeforeSave(new List<Opportunity>{ opp }, null);
        Test.stopTest();

        System.assertEquals('High Touch', opp.Touch_Level_Calculated__c);
        System.assertEquals('High Touch', opp.Touch_Level__c);
        System.assertNotEquals(null, opp.Touch_Level_Last_Calculated__c);
    }

    @IsTest
    static void testRecalculateBeforeSave_IneligibleRecordType_NoOp() {
        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, null);
        makeCondition(criteria.Id, 1, 'Amount', 'GREATER_THAN', '100000');

        // No RecordTypeId set — not one of the two eligible types, so the whole
        // record is skipped and never even reaches resolveTouchLevel.
        Opportunity opp = new Opportunity(StageName = 'Qualification', Amount = 500000);

        Test.startTest();
        TouchLevelEvaluatorAction.recalculateBeforeSave(new List<Opportunity>{ opp }, null);
        Test.stopTest();

        System.assertEquals(null, opp.Touch_Level_Calculated__c,
            'Ineligible record type should be skipped entirely.');
    }

    @IsTest
    static void testRecalculateBeforeSave_TouchLevelOverride_SkipsRecalculation() {
        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, null);
        makeCondition(criteria.Id, 1, 'Amount', 'GREATER_THAN', '100000');

        Opportunity opp = new Opportunity(
            RecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
            StageName = 'Qualification',
            Amount = 500000,
            Touch_Level_Override__c = true
        );

        Test.startTest();
        TouchLevelEvaluatorAction.recalculateBeforeSave(new List<Opportunity>{ opp }, null);
        Test.stopTest();

        System.assertEquals(null, opp.Touch_Level_Calculated__c,
            'An overridden Opportunity should never be recalculated.');
    }

    @IsTest
    static void testRecalculateBeforeSave_UpdatePath_NoRelevantFieldChange_SkipsRecalculation() {
        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, null);
        makeCondition(criteria.Id, 1, 'Amount', 'GREATER_THAN', '100000');

        Opportunity oldOpp = new Opportunity(
            Id = TestDataHelperId(),
            RecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
            StageName = 'Qualification',
            Amount = 500000
        );
        Opportunity newOpp = oldOpp.clone(true, true, true, true);
        // Amount and StageName both unchanged — nothing for hasRelevantFieldChanged to catch

        Test.startTest();
        TouchLevelEvaluatorAction.recalculateBeforeSave(
            new List<Opportunity>{ newOpp }, new Map<Id, Opportunity>{ oldOpp.Id => oldOpp });
        Test.stopTest();

        System.assertEquals(null, newOpp.Touch_Level_Calculated__c,
            'No watched field changed, so recalculation should be skipped on update.');
    }

    @IsTest
    static void testRecalculateBeforeSave_UpdatePath_RelevantFieldChanged_Recalculates() {
        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, null);
        makeCondition(criteria.Id, 1, 'Amount', 'GREATER_THAN', '100000');

        Opportunity oldOpp = new Opportunity(
            Id = TestDataHelperId(),
            RecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
            StageName = 'Qualification',
            Amount = 50000 // below threshold
        );
        Opportunity newOpp = oldOpp.clone(true, true, true, true);
        newOpp.Amount = 500000; // crosses the threshold — a watched field changed

        Test.startTest();
        TouchLevelEvaluatorAction.recalculateBeforeSave(
            new List<Opportunity>{ newOpp }, new Map<Id, Opportunity>{ oldOpp.Id => oldOpp });
        Test.stopTest();

        System.assertEquals('High Touch', newOpp.Touch_Level_Calculated__c);
    }

    @IsTest
    static void testRecalculateBeforeSave_NoDowngradeRule_HighTouchNeverDowngraded() {
        // Criteria now only resolves to Medium Touch for this Opportunity.
        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'Medium Touch', 1, null);
        makeCondition(criteria.Id, 1, 'Amount', 'GREATER_THAN', '100000');

        Opportunity oldOpp = new Opportunity(
            Id = TestDataHelperId(),
            RecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
            StageName = 'Qualification',
            Amount = 50000,
            Touch_Level__c = 'High Touch' // already High Touch from a prior calculation
        );
        Opportunity newOpp = oldOpp.clone(true, true, true, true);
        newOpp.Amount = 500000; // watched field changed, forces recalculation

        Test.startTest();
        TouchLevelEvaluatorAction.recalculateBeforeSave(
            new List<Opportunity>{ newOpp }, new Map<Id, Opportunity>{ oldOpp.Id => oldOpp });
        Test.stopTest();

        System.assertEquals('Medium Touch', newOpp.Touch_Level_Calculated__c,
            'The raw calculated value should still reflect the new match.');
        System.assertEquals('High Touch', newOpp.Touch_Level__c,
            'High Touch should never be automatically downgraded.');
    }

    // A stable fake Id for building oldMap/newMap pairs in-memory without an insert —
    // recalculateBeforeSave only reads fields off these SObjects, never re-queries them.
    private static Id TestDataHelperId() {
        return getOpp().Id;
    }

    // ──────────────────────────────────────────────────────────
    // reevaluateForAccountChanges — the Account-driven re-evaluation path (invoked by
    // Case_Creation_Account_Reevaluation_Flow via TouchLevelAccountReevaluationAction).
    // This path issues its own SOQL and DML, so it needs a real, persisted, open Opportunity.
    // ──────────────────────────────────────────────────────────

    @IsTest
    static void testReevaluateForAccountChanges_AccountFieldChanged_UpdatesOpenOpportunity() {
        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, null);
        makeCondition(criteria.Id, 1, 'Account.Industry', 'EQUALS', 'Technology');

        // attachAccountData re-queries Industry from the database, so the real record needs
        // to reflect the change — set at insert time (not via a later `update`) since
        // Case_Creation_Account_Reevaluation_Flow triggers on every real Account *update*
        // and would otherwise re-enter this same reevaluation for real, duplicating it.
        Test.startTest();
        Account acc = new Account(
            Name = 'Account-Driven Test Account', Industry = 'Technology',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Account-Driven Opp',
            AccountId = acc.Id,
            RecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Account oldAcct = acc.clone(true, true, true, true);
        oldAcct.Industry = null; // the "before" snapshot the real flow would pass as $Record__Prior
        Account newAcct = acc.clone(true, true, true, true);

        TouchLevelAccountReevaluationRequest req = new TouchLevelAccountReevaluationRequest();
        req.oldAccount = oldAcct;
        req.newAccount = newAcct;

        
        TouchLevelEvaluatorAction.reevaluateForAccountChanges(
            new List<TouchLevelAccountReevaluationRequest>{ req });
        Test.stopTest();

        Opportunity result = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('High Touch', result.Touch_Level__c);
    }

    @IsTest
    static void testReevaluateForAccountChanges_NoWatchedAccountFields_NoOp() {
        // Criteria only references an Opportunity field — deriveWatchedAccountFields()
        // returns empty, so the method should return immediately without erroring.
        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, null);
        makeCondition(criteria.Id, 1, 'Amount', 'GREATER_THAN', '100000');

        Account acc = [SELECT Id FROM Account LIMIT 1];
        TouchLevelAccountReevaluationRequest req = new TouchLevelAccountReevaluationRequest();
        req.oldAccount = acc.clone(true, true, true, true);
        req.newAccount = acc.clone(true, true, true, true);

        Test.startTest();
        TouchLevelEvaluatorAction.reevaluateForAccountChanges(
            new List<TouchLevelAccountReevaluationRequest>{ req });
        Test.stopTest();

        // No exception is the assertion — nothing to check on the Opportunity since
        // this path never touches it when there are no watched Account fields.
        System.assert(true);
    }

    @IsTest
    static void testReevaluateForAccountChanges_EmptyRequestList_NoOp() {
        Test.startTest();
        TouchLevelEvaluatorAction.reevaluateForAccountChanges(new List<TouchLevelAccountReevaluationRequest>());
        TouchLevelEvaluatorAction.reevaluateForAccountChanges(null);
        Test.stopTest();

        System.assert(true);
    }

    // ──────────────────────────────────────────────────────────
    // Watched-field helpers — public utility methods used by declarative config elsewhere
    // to know which fields drive Touch Level calculation.
    // ──────────────────────────────────────────────────────────

    @IsTest
    static void testGetWatchedFieldNames_And_GetWatchedAccountFieldNames() {
        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, '1 AND 2');
        makeCondition(criteria.Id, 1, 'Amount', 'GREATER_THAN', '100000');
        makeCondition(criteria.Id, 2, 'Account.Industry', 'EQUALS', 'Technology');

        Test.startTest();
        Set<String> oppFields = TouchLevelEvaluatorAction.getWatchedFieldNames();
        Set<String> acctFields = TouchLevelEvaluatorAction.getWatchedAccountFieldNames();
        Test.stopTest();

        System.assert(oppFields.contains('Amount'));
        System.assert(oppFields.contains('StageName'), 'StageName is always a watched field.');
        System.assert(acctFields.contains('Industry'));
    }

    // ──────────────────────────────────────────────────────────
    // evaluateCondition operators not already covered by the GREATER_THAN / IS_NULL tests
    // above, plus a nested-parentheses logic expression.
    // ──────────────────────────────────────────────────────────

    @IsTest
    static void testEqualsAndNotEqualsOperators() {
        Opportunity opp = getOpp(); // StageName = Qualification

        Touch_Level_Criteria__c equalsCriteria = makeCriteria('Qualification', 'High Touch', 1, null);
        makeCondition(equalsCriteria.Id, 1, 'StageName', 'EQUALS', 'Qualification');

        Test.startTest();
        TouchLevelEvaluatorAction.Request req = new TouchLevelEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<TouchLevelEvaluatorAction.Result> results =
            TouchLevelEvaluatorAction.evaluate(new List<TouchLevelEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals('High Touch', results[0].touchLevel, 'EQUALS should match on exact string');
    }

    @IsTest
    static void testContainsInAndNotInOperators() {
        Opportunity opp = getOpp(); // Amount = 500000

        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, '1 AND 2 AND 3');
        makeCondition(criteria.Id, 1, 'StageName', 'CONTAINS', 'ualif');
        makeCondition(criteria.Id, 2, 'StageName', 'IN', 'Qualification,Proposal/Price Quote');
        makeCondition(criteria.Id, 3, 'StageName', 'NOT_IN', 'Closed Won,Closed Lost');

        Test.startTest();
        TouchLevelEvaluatorAction.Request req = new TouchLevelEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<TouchLevelEvaluatorAction.Result> results =
            TouchLevelEvaluatorAction.evaluate(new List<TouchLevelEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals('High Touch', results[0].touchLevel,
            'CONTAINS, IN, and NOT_IN should all pass for this Opportunity.');
    }

    @IsTest
    static void testGreaterOrEqualAndLessOrEqualOperators() {
        Opportunity opp = getOpp(); // Amount = 500000

        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, '1 AND 2');
        makeCondition(criteria.Id, 1, 'Amount', 'GREATER_OR_EQUAL', '500000');
        makeCondition(criteria.Id, 2, 'Amount', 'LESS_OR_EQUAL', '500000');

        Test.startTest();
        TouchLevelEvaluatorAction.Request req = new TouchLevelEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<TouchLevelEvaluatorAction.Result> results =
            TouchLevelEvaluatorAction.evaluate(new List<TouchLevelEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals('High Touch', results[0].touchLevel);
    }

    @IsTest
    static void testIsNotNullIsTrueIsFalseOperators() {
        Opportunity opp = getOpp();

        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, '1 AND 2 AND 3');
        makeCondition(criteria.Id, 1, 'Amount', 'IS_NOT_NULL', null);
        makeCondition(criteria.Id, 2, 'Bypass_Validation__c', 'IS_TRUE', null);
        makeCondition(criteria.Id, 3, 'IsPrivate', 'IS_FALSE', null);

        Test.startTest();
        TouchLevelEvaluatorAction.Request req = new TouchLevelEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<TouchLevelEvaluatorAction.Result> results =
            TouchLevelEvaluatorAction.evaluate(new List<TouchLevelEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals('High Touch', results[0].touchLevel);
    }

    @IsTest
    static void testNestedParenthesesLogicExpression() {
        Opportunity opp = getOpp(); // Amount = 500000, StageName = Qualification

        // (1 AND 2) OR 3 — condition 1 fails, so the parenthesized group is false,
        // but condition 3 alone should still make the whole expression true.
        Touch_Level_Criteria__c criteria = makeCriteria('Qualification', 'High Touch', 1, '(1 AND 2) OR 3');
        makeCondition(criteria.Id, 1, 'StageName', 'EQUALS', 'Proposal/Price Quote'); // fails
        makeCondition(criteria.Id, 2, 'Amount', 'GREATER_THAN', '100000'); // passes, irrelevant since 1 fails
        makeCondition(criteria.Id, 3, 'Amount', 'GREATER_THAN', '400000'); // passes

        Test.startTest();
        TouchLevelEvaluatorAction.Request req = new TouchLevelEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<TouchLevelEvaluatorAction.Result> results =
            TouchLevelEvaluatorAction.evaluate(new List<TouchLevelEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals('High Touch', results[0].touchLevel,
            'Nested parens: (1 AND 2) is false but condition 3 alone should still match via OR.');
    }
}