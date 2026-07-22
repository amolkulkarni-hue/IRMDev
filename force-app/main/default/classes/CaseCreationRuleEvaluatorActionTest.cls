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
        return [SELECT Id, StageName, Amount FROM Opportunity LIMIT 1];
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

    private static Case_Creation_Doc_Requirement__c makeDocReq(
            Id ruleId, String docType, Boolean requiredToStart, Boolean requiredForCase) {
        Case_Creation_Doc_Requirement__c dr = new Case_Creation_Doc_Requirement__c(
            Rule__c = ruleId,
            Document_Type__c = docType,
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
        makeDocReq(rule.Id, 'RFx/Bid', true, true);
        makeDocReq(rule.Id, 'SOW', false, true);

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
        System.assert(((String) mr.get('requiredDocTypes')).contains('RFx/Bid'));
        // SOW is not Is_Required_To_Start__c
        System.assert(!((String) mr.get('requiredDocTypes')).contains('SOW'));
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
        makeDocReq(rule.Id, 'RFx/Bid', true, true);
        // Is_Required_To_Start = false, Is_Required_For_Case = true
        makeDocReq(rule.Id, 'SOW', false, true);
        // Is_Required_To_Start = true, Is_Required_For_Case = false
        makeDocReq(rule.Id, 'NDA', true, false);

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

        // requiredDocTypes: RFx/Bid + NDA (Is_Required_To_Start = true)
        System.assert(startDocs.contains('RFx/Bid'));
        System.assert(startDocs.contains('NDA'));
        System.assert(!startDocs.contains('SOW'));

        // requiredForCaseDocTypes: RFx/Bid + SOW (Is_Required_For_Case = true)
        System.assert(caseDocs.contains('RFx/Bid'));
        System.assert(caseDocs.contains('SOW'));
        System.assert(!caseDocs.contains('NDA'));
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
        Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' LIMIT 1];

        Case c = new Case(Status = 'New', OwnerId = UserInfo.getUserId());
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
        Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' LIMIT 1];

        Case c = new Case(Status = 'New', OwnerId = queue.Id);
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
}