@IsTest
private class CaseCreationRuleEvaluatorActionTest {

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
        // Required by OpportunityHelper.createOpportunityShare (Country_Settings__c and
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
            Amount = 500000,
            Bypass_Validation__c = true
        );
        insert opp;
    }

    private static Opportunity getOpp() {
        return [SELECT Id, StageName, Amount, AccountId FROM Opportunity LIMIT 1];
    }

    private static Case_Creation_Rule__c makeRule(
            String stage, String caseType, String rtName, String queueName, String logicExpr) {
        Case_Creation_Rule__c r = new Case_Creation_Rule__c(
            Stage__c = stage,
            Case_Type__c = caseType,
            Record_Type_Dev_Name__c = rtName,
            Queue_Developer_Name__c = queueName,
            Logic_Expression__c = logicExpr,
            Is_Active__c = true,
            Priority__c = 1
        );
        insert r;
        return r;
    }

    private static Case_Creation_Condition__c makeCondition(
            Id ruleId, Integer num, String fieldName, String operator, String value) {
        Case_Creation_Condition__c cond = new Case_Creation_Condition__c(
            Rule__c = ruleId,
            Condition_Number__c = num,
            Field_API_Name__c = fieldName,
            Operator__c = operator,
            Value__c = value
        );
        insert cond;
        return cond;
    }

    // Doc_Type__c is a restricted picklist dependent on Doc_Category__c — every value
    // used by this test's makeDocReq() calls needs its matching category here.
    private static final Map<String, String> DOC_TYPE_TO_CATEGORY = new Map<String, String>{
        'RFP (Request for Proposal)' => 'RFx & Bid Management',
        'Standardized SOW Template'  => 'SOW & Contracts',
        'Governing Agreement'        => 'Contract & Legal'
    };

    private static Case_Creation_Doc_Requirement__c makeDocReq(
            Id ruleId, String docType, Boolean requiredToStart, Boolean requiredForCase) {
        Case_Creation_Doc_Requirement__c dr = new Case_Creation_Doc_Requirement__c(
            Rule__c = ruleId,
            Doc_Type__c = docType,
            Doc_Category__c = DOC_TYPE_TO_CATEGORY.get(docType),
            Is_Required_To_Start__c = requiredToStart,
            Is_Required_For_Case__c = requiredForCase
        );
        insert dr;
        return dr;
    }

    // ──────────────────────────────────────────────────────────
    // Tests
    // ──────────────────────────────────────────────────────────

    @IsTest
    static void testSingleRuleMatch() {
        Opportunity opp = getOpp();

        Case_Creation_Rule__c rule = makeRule('Qualification', 'RFP/Bid Management',
            'Deal_Support', 'Bid_Management_Queue', null);
        makeCondition(rule.Id, 1, 'Amount', 'GREATER_THAN', '100000');
        makeDocReq(rule.Id, 'RFP (Request for Proposal)', true, true);
        makeDocReq(rule.Id, 'Standardized SOW Template', false, true);

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].hasMatches);
        System.assertEquals(1, results[0].matchedRuleCount);
        System.assertNotEquals(null, results[0].matchedRulesJson);

        // Deserialize and verify doc requirements
        List<Object> matched = (List<Object>) JSON.deserializeUntyped(results[0].matchedRulesJson);
        System.assertEquals(1, matched.size());
        Map<String, Object> mr = (Map<String, Object>) matched[0];
        System.assertEquals('RFP/Bid Management', mr.get('caseType'));
        // requiredDocTypes should contain only Is_Required_To_Start__c docs
        System.assert(((String) mr.get('requiredDocTypes')).contains('RFP (Request for Proposal)'));
        // SOW is not Is_Required_To_Start__c
        System.assert(!((String) mr.get('requiredDocTypes')).contains('Standardized SOW Template'));
    }

    @IsTest
    static void testMultipleRulesMatch() {
        Opportunity opp = getOpp();

        Case_Creation_Rule__c rule1 = makeRule('Qualification', 'RFP/Bid Management',
            'Deal_Support', 'Bid_Queue', null);
        makeCondition(rule1.Id, 1, 'Amount', 'GREATER_THAN', '100000');

        Case_Creation_Rule__c rule2 = makeRule('Qualification', 'Legal Review',
            'Legal_Support', 'Legal_Queue', null);
        makeCondition(rule2.Id, 1, 'Amount', 'GREATER_THAN', '50000');

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].hasMatches);
        System.assertEquals(2, results[0].matchedRuleCount);
    }

    @IsTest
    static void testNoMatch_WrongStage() {
        Opportunity opp = getOpp(); // StageName = Qualification

        Case_Creation_Rule__c rule = makeRule('Proposal/Price Quote', 'RFP/Bid Management',
            'Deal_Support', 'Bid_Queue', null);
        makeCondition(rule.Id, 1, 'Amount', 'GREATER_THAN', '100000');

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(false, results[0].hasMatches);
        System.assertEquals(0, results[0].matchedRuleCount);
    }

    @IsTest
    static void testUnconditionalRule_AlwaysMatches() {
        Opportunity opp = getOpp();

        // Rule with NO conditions — always matches
        Case_Creation_Rule__c rule = makeRule('Qualification', 'General Review',
            'General_Support', 'General_Queue', null);
        // No conditions inserted

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].hasMatches);
        System.assertEquals(1, results[0].matchedRuleCount);
    }

    @IsTest
    static void testMultipleDocRequirements_SeparatedCorrectly() {
        Opportunity opp = getOpp();

        Case_Creation_Rule__c rule = makeRule('Qualification', 'RFP/Bid Management',
            'Deal_Support', 'Bid_Queue', null);
        makeCondition(rule.Id, 1, 'Amount', 'GREATER_THAN', '100000');

        // Is_Required_To_Start = true, Is_Required_For_Case = true
        makeDocReq(rule.Id, 'RFP (Request for Proposal)', true, true);
        // Is_Required_To_Start = false, Is_Required_For_Case = true
        makeDocReq(rule.Id, 'Standardized SOW Template', false, true);
        // Is_Required_To_Start = true, Is_Required_For_Case = false
        makeDocReq(rule.Id, 'Governing Agreement', true, false);

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        List<Object> matched = (List<Object>) JSON.deserializeUntyped(results[0].matchedRulesJson);
        Map<String, Object> mr = (Map<String, Object>) matched[0];

        String startDocs = (String) mr.get('requiredDocTypes');
        String caseDocs = (String) mr.get('requiredForCaseDocTypes');

        // requiredDocTypes: RFP (Request for Proposal) + Governing Agreement (Is_Required_To_Start = true)
        System.assert(startDocs.contains('RFP (Request for Proposal)'));
        System.assert(startDocs.contains('Governing Agreement'));
        System.assert(!startDocs.contains('Standardized SOW Template'));

        // requiredForCaseDocTypes: RFP (Request for Proposal) + Standardized SOW Template (Is_Required_For_Case = true)
        System.assert(caseDocs.contains('RFP (Request for Proposal)'));
        System.assert(caseDocs.contains('Standardized SOW Template'));
        System.assert(!caseDocs.contains('Governing Agreement'));
    }

    @IsTest
    static void testInactiveRuleIsIgnored() {
        Opportunity opp = getOpp();

        Case_Creation_Rule__c rule = new Case_Creation_Rule__c(
            Stage__c = 'Qualification',
            Case_Type__c = 'RFP/Bid Management',
            Record_Type_Dev_Name__c = 'Deal_Support',
            Queue_Developer_Name__c = 'Bid_Queue',
            Is_Active__c = false,
            Priority__c = 1
        );
        insert rule;

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(false, results[0].hasMatches);
    }

    @IsTest
    static void testOrLogicExpression() {
        Opportunity opp = getOpp();
        // Amount = 500000, StageName = Qualification

        Case_Creation_Rule__c rule = makeRule('Qualification', 'RFP/Bid Management',
            'Deal_Support', 'Bid_Queue', '1 OR 2');
        makeCondition(rule.Id, 1, 'StageName', 'EQUALS', 'Proposal/Price Quote'); // fails
        makeCondition(rule.Id, 2, 'Amount', 'GREATER_THAN', '100000'); // passes

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].hasMatches, 'OR logic: one passing condition should match');
    }

    // ──────────────────────────────────────────────────────────
    // ReassertCaseOwnerJob (added in the Case queue routing consolidation) — corrects
    // Case.OwnerId back to the intended queue when a caller's inherited Sforce-Auto-Assign
    // header lets the org's native Case Assignment Rule silently override it.
    // ──────────────────────────────────────────────────────────

    @IsTest
    static void testReassertCaseOwnerJob_correctsOverriddenOwner() {
        Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'Solution_Specialist_Queue' AND Type = 'Queue' LIMIT 1];
        Id contactId = [SELECT Id FROM Contact LIMIT 1].Id;

        Case c = new Case(Status = 'New', OwnerId = UserInfo.getUserId(), ContactId = contactId);
        insert c;

        Map<Id, Id> caseIdToIntendedOwnerId = new Map<Id, Id>{ c.Id => queue.Id };

        Test.startTest();
        System.enqueueJob(new CaseCreationRuleEvaluatorAction.ReassertCaseOwnerJob(caseIdToIntendedOwnerId));
        Test.stopTest();

        Case result = [SELECT OwnerId FROM Case WHERE Id = :c.Id];
        System.assertEquals(queue.Id, result.OwnerId,
            'ReassertCaseOwnerJob should correct OwnerId back to the intended queue.');
    }

    @IsTest
    static void testReassertCaseOwnerJob_noOpWhenOwnerAlreadyCorrect() {
        Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'Solution_Specialist_Queue' AND Type = 'Queue' LIMIT 1];
        Id contactId = [SELECT Id FROM Contact LIMIT 1].Id;

        Case c = new Case(Status = 'New', OwnerId = queue.Id, ContactId = contactId);
        insert c;

        Map<Id, Id> caseIdToIntendedOwnerId = new Map<Id, Id>{ c.Id => queue.Id };

        Test.startTest();
        System.enqueueJob(new CaseCreationRuleEvaluatorAction.ReassertCaseOwnerJob(caseIdToIntendedOwnerId));
        Test.stopTest();

        Case result = [SELECT OwnerId FROM Case WHERE Id = :c.Id];
        System.assertEquals(queue.Id, result.OwnerId,
            'OwnerId already matching the intended queue should be left unchanged.');
    }

    @IsTest
    static void testNullOpportunityId() {
        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = null;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].hasMatches);
    }

    // ──────────────────────────────────────────────────────────
    // MVP Support Teams Cases Logic scenarios — targeting the exact bug classes
    // caught and fixed while seeding Case_Creation_Rule__c/Condition__c from the
    // client's mapping doc, so a regression in any of them fails a test instead of
    // silently mis-routing Cases in production.
    // ──────────────────────────────────────────────────────────

    @IsTest
    static void testIsTrueOperator_MatchesRealBooleanField() {
        Opportunity opp = getOpp();
        update new Opportunity(Id = opp.Id, RFx_RFI_RFQ_RFP__c = true);

        Case_Creation_Rule__c rule = makeRule('Qualification', 'RFP/Bid Management',
            'Deal_Support', 'Bid_Management_Queue', null);
        makeCondition(rule.Id, 1, 'RFx_RFI_RFQ_RFP__c', 'IS_TRUE', null);

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].hasMatches,
            'IS_TRUE against a real Boolean field should match. Guards against a caught bug ' +
            'where Boolean fields were seeded as EQUALS \'Yes\' instead — the evaluator compares ' +
            'Boolean fields with fieldValue == true, so a string \'Yes\' never matches.');
    }

    @IsTest
    static void testAccountRelationshipBooleanCondition_Matches() {
        Opportunity opp = getOpp();
        update new Account(Id = opp.AccountId, Strategic_Account__c = true);

        Case_Creation_Rule__c rule = makeRule('Qualification', 'Solution Architects',
            'Deal_Support', 'Solution_Architects_Queue', null);
        makeCondition(rule.Id, 1, 'Account.Strategic_Account__c', 'IS_TRUE', null);

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].hasMatches,
            'A condition on Account.Strategic_Account__c should traverse the relationship (via the ' +
            'Account.<field> SELECT the evaluator builds dynamically) and match.');
    }

    @IsTest
    static void testInOperator_MatchesCommaSeparatedValue() {
        Opportunity opp = getOpp();
        update new Opportunity(Id = opp.Id, Business_Unit__c = 'ALM');

        Case_Creation_Rule__c rule = makeRule('Qualification', 'Managed Services Program',
            'Deal_Support', 'Managed_Services_Queue', null);
        makeCondition(rule.Id, 1, 'Business_Unit__c', 'IN', 'RIM,ALM');

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].hasMatches,
            'IN should match when the field value is one of the comma-separated candidates. Guards ' +
            'against a caught bug where IN value lists were joined with semicolons — the evaluator\'s ' +
            'toSet() helper splits only on commas, so a semicolon-joined list is treated as one ' +
            'unmatchable value.');
    }

    @IsTest
    static void testContainsOperator_MatchesWithinMultiSelectPicklist() {
        Opportunity opp = getOpp();
        update new Opportunity(Id = opp.Id, IM_Sales_Event__c = 'HCLS: Managed Service;Cross-Sell Campaign');

        Case_Creation_Rule__c rule = makeRule('Qualification', 'Managed Services Program',
            'Deal_Support', 'Managed_Services_Queue', null);
        makeCondition(rule.Id, 1, 'IM_Sales_Event__c', 'CONTAINS', 'HCLS: Managed Service');

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].hasMatches,
            'CONTAINS should match a single selected value even when the multipicklist field holds ' +
            'more than one. Guards against a caught bug where this was seeded as EQUALS, which only ' +
            'matches when the field\'s full semicolon-joined string equals the compare value exactly.');
    }

    @IsTest
    static void testGreaterOrEqual_MatchesPlainNumericValue() {
        Opportunity opp = getOpp(); // Amount = 500000

        Case_Creation_Rule__c rule = makeRule('Qualification', 'Remarketing',
            'Deal_Support', 'Remarketing_Queue', null);
        makeCondition(rule.Id, 1, 'Amount', 'GREATER_OR_EQUAL', '250000');

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].hasMatches,
            'GREATER_OR_EQUAL parses Value__c via Decimal.valueOf(). Guards against a caught bug ' +
            'where currency thresholds were seeded as "$250,000" / "$1mil"-style strings, which ' +
            'Decimal.valueOf() cannot parse — the evaluator catches that exception and silently ' +
            'returns false rather than matching.');
    }

    @IsTest
    static void testParenthesizedOrGroup_AppendedConditionGatesEveryBranch() {
        Opportunity opp = getOpp(); // Amount = 500000, Touch_Level__c left unset
        update new Account(Id = opp.AccountId, Strategic_Account__c = true);

        // Shape of the real seeded Solution Architects rules: an OR-group carried over from the
        // client's own logic, followed by an appended Touch Level condition that must gate the
        // WHOLE expression. Guards against a caught bug where the appended condition was tacked
        // onto a flat "1 AND 2 OR 3 AND 4" string — since the evaluator splits on OR first, that
        // form only gated the LAST OR-branch, letting condition 3 alone produce a false match.
        Case_Creation_Rule__c rule = makeRule('Qualification', 'Solution Architects',
            'Deal_Support', 'Solution_Architects_Queue', '(1 AND 2 OR 3) AND 4');
        makeCondition(rule.Id, 1, 'Business_Unit__c', 'EQUALS', 'RIM');                  // fails
        makeCondition(rule.Id, 2, 'Amount', 'GREATER_THAN', '1000000');                 // fails
        makeCondition(rule.Id, 3, 'Account.Strategic_Account__c', 'IS_TRUE', null);     // passes
        makeCondition(rule.Id, 4, 'Touch_Level__c', 'EQUALS', 'High Touch');            // fails (unset)

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(false, results[0].hasMatches,
            'Condition 4 fails and must gate the entire rule, not just the last OR-branch — under ' +
            'the buggy flat-string form, condition 3 alone (Strategic Account) would have produced ' +
            'an incorrect match here.');
    }

    @IsTest
    static void testParenthesizedOrGroup_MatchesWhenAppendedConditionAlsoPasses() {
        Opportunity opp = getOpp();
        update new Opportunity(Id = opp.Id, Touch_Level__c = 'High Touch');
        update new Account(Id = opp.AccountId, Strategic_Account__c = true);

        Case_Creation_Rule__c rule = makeRule('Qualification', 'Solution Architects',
            'Deal_Support', 'Solution_Architects_Queue', '(1 AND 2 OR 3) AND 4');
        makeCondition(rule.Id, 1, 'Business_Unit__c', 'EQUALS', 'RIM');                  // fails
        makeCondition(rule.Id, 2, 'Amount', 'GREATER_THAN', '1000000');                 // fails
        makeCondition(rule.Id, 3, 'Account.Strategic_Account__c', 'IS_TRUE', null);     // passes -> OR group true
        makeCondition(rule.Id, 4, 'Touch_Level__c', 'EQUALS', 'High Touch');            // passes

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(true, results[0].hasMatches,
            'OR-group true (via condition 3) AND condition 4 true — the whole rule should match.');
    }
}