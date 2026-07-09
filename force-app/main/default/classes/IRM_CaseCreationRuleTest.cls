/**
 * IRM_CaseCreationRuleTest
 * US-1136 Phase 1: CaseCreationRuleEvaluatorAction
 * Tests the Apex invocable action that evaluates Case_Creation_Rule__c criteria.
 * This is the engine called by Case_Creation_Eligibility_Flow.
 */
@IsTest
private class IRM_CaseCreationRuleTest {

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
        insert new List<SVStatus__c>{
            new SVStatus__c(Name = 'New Deal',   Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Renewal',    Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Add-On',     Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Expansion',  Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId())
        };
        Account acc = new Account(
            Name = 'IRM CCR Test Co',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;

        // SA Assignment rule: Qualification, Amount >= 500k
        Case_Creation_Rule__c saRule = new Case_Creation_Rule__c(
            Stage__c = 'Qualification', Case_Type__c = 'SA Assignment',
            Record_Type_Dev_Name__c = 'Deal_Support',
            Queue_Developer_Name__c = 'Solution_Specialist_Queue',
            Logic_Expression__c = '1', Is_Active__c = true, Priority__c = 10
        );
        insert saRule;
        insert new Case_Creation_Condition__c(
            Rule__c = saRule.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '500000'
        );
        insert new Case_Creation_Doc_Requirement__c(
            Rule__c = saRule.Id, Document_Type__c = 'Solution Assessment',
            Document_Category__c = 'Scoping and Technical Documents',
            Is_Required_To_Start__c = true, Is_Required_For_Case__c = true
        );

        // Pricing rule: Qualification, unconditional (no conditions)
        Case_Creation_Rule__c pricingRule = new Case_Creation_Rule__c(
            Stage__c = 'Qualification', Case_Type__c = 'Pricing',
            Record_Type_Dev_Name__c = 'Deal_Support',
            Queue_Developer_Name__c = 'DOC_Pricing_Queue',
            Logic_Expression__c = null, Is_Active__c = true, Priority__c = 20
        );
        insert pricingRule;
        insert new Case_Creation_Doc_Requirement__c(
            Rule__c = pricingRule.Id, Document_Type__c = 'Pricing Sheet',
            Document_Category__c = 'Pricing and Financial Documents',
            Is_Required_To_Start__c = true, Is_Required_For_Case__c = true
        );
    }

    private static CaseCreationRuleEvaluatorAction.Request makeRequest(Id oppId) {
        CaseCreationRuleEvaluatorAction.Request r = new CaseCreationRuleEvaluatorAction.Request();
        r.opportunityId = oppId;
        return r;
    }

    // ── Phase 1 AC1: Matched rule returns correct Case Type and Queue ─────────

    @IsTest
    static void test_matchedRuleHasCorrectOutputFields() {
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        Opportunity opp = new Opportunity(
            Name = 'SA Rule Test', AccountId = accId,
            Type = 'New Deal', StageName = 'Qualification', CloseDate = Date.today().addDays(30), Pricebook2Id = Test.getStandardPricebookId(), Amount = 600000,
            Bypass_Validation__c = true
        );
        insert opp;

        System.debug('TEST: Evaluating rules for Opp Id=' + opp.Id + ', Stage=Qualification, Amount=600000. Expect SA Assignment rule to match.');

        Test.startTest();
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ makeRequest(opp.Id) });
        Test.stopTest();

        System.debug('RESULT: hasMatches=' + results[0].hasMatches
            + ' | matchedRuleCount=' + results[0].matchedRuleCount
            + ' | matchedRulesJson=' + results[0].matchedRulesJson);

        System.assertEquals(true, results[0].hasMatches,
            'Phase 1: hasMatches should be true for 600k Qualification opp. Got: ' + results[0].hasMatches);

        List<Object> matched = (List<Object>) JSON.deserializeUntyped(results[0].matchedRulesJson);
        System.debug('MATCHED RULES parsed count=' + matched.size());

        // Find the SA Assignment rule in results
        Map<String, Object> saRule;
        for (Object m : matched) {
            Map<String, Object> mr = (Map<String, Object>) m;
            if (mr.get('caseType') == 'SA Assignment') { saRule = mr; break; }
        }
        System.debug('SA Assignment rule found in results: ' + (saRule != null) + ' | detail=' + saRule);

        System.assertNotEquals(null, saRule,
            'Phase 1: SA Assignment rule should be in matched results. matchedRulesJson=' + results[0].matchedRulesJson);
        System.assertEquals('Deal_Support', (String) saRule.get('recordTypeDeveloperName'),
            'Phase 1: recordTypeDeveloperName should be Deal_Support. Got: ' + saRule.get('recordTypeDeveloperName'));
        System.assertEquals('Solution_Specialist_Queue', (String) saRule.get('queueDeveloperName'),
            'Phase 1: queueDeveloperName should be Solution_Specialist_Queue. Got: ' + saRule.get('queueDeveloperName'));
    }

    // ── Phase 1 AC2: Required doc types returned ─────────────────────────────

    @IsTest
    static void test_requiredDocTypesReturnedInResult() {
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        Opportunity opp = new Opportunity(
            Name = 'Doc Type Test', AccountId = accId,
            Type = 'New Deal', StageName = 'Qualification', CloseDate = Date.today().addDays(30), Pricebook2Id = Test.getStandardPricebookId(), Amount = 600000,
            Bypass_Validation__c = true
        );
        insert opp;

        System.debug('TEST: Evaluating doc requirements for SA Assignment rule. Expect Solution Assessment in requiredDocTypes.');

        Test.startTest();
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ makeRequest(opp.Id) });
        Test.stopTest();

        List<Object> matched = (List<Object>) JSON.deserializeUntyped(results[0].matchedRulesJson);
        Map<String, Object> saRule;
        for (Object m : matched) {
            Map<String, Object> mr = (Map<String, Object>) m;
            if (mr.get('caseType') == 'SA Assignment') { saRule = mr; break; }
        }

        System.debug('RESULT: requiredDocTypes=' + (saRule != null ? saRule.get('requiredDocTypes') : 'RULE NOT FOUND'));

        System.assertNotEquals(null, saRule, 'SA Assignment rule should be present. matchedRulesJson=' + results[0].matchedRulesJson);
        System.assert(((String) saRule.get('requiredDocTypes')).contains('Solution Assessment'),
            'Phase 1: requiredDocTypes should contain "Solution Assessment". Got: ' + saRule.get('requiredDocTypes'));
    }

    // ── Phase 1 AC3: No match when amount below threshold ────────────────────

    @IsTest
    static void test_noMatchWhenAmountBelowThreshold() {
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        Opportunity opp = new Opportunity(
            Name = 'Low Amount Test', AccountId = accId,
            Type = 'New Deal', StageName = 'Qualification', CloseDate = Date.today().addDays(30), Pricebook2Id = Test.getStandardPricebookId(), Amount = 50000,
            Bypass_Validation__c = true
        );
        insert opp;

        System.debug('TEST: Evaluating rules for Opp Amount=50000. SA Assignment requires 500k. Unconditional Pricing rule should still match.');

        Test.startTest();
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ makeRequest(opp.Id) });
        Test.stopTest();

        System.debug('RESULT: hasMatches=' + results[0].hasMatches
            + ' | matchedRuleCount=' + results[0].matchedRuleCount
            + ' | matchedRulesJson=' + results[0].matchedRulesJson);

        // SA Assignment should NOT match; unconditional Pricing rule SHOULD match
        List<Object> matched = (List<Object>) JSON.deserializeUntyped(results[0].matchedRulesJson);
        Boolean saFound = false;
        Boolean pricingFound = false;
        for (Object m : matched) {
            Map<String, Object> mr = (Map<String, Object>) m;
            if (mr.get('caseType') == 'SA Assignment') saFound = true;
            if (mr.get('caseType') == 'Pricing') pricingFound = true;
        }
        System.debug('SA Assignment in results: ' + saFound + ' | Pricing in results: ' + pricingFound);

        System.assertEquals(false, saFound,
            'Phase 1: SA Assignment rule should NOT match when Amount=50000 (threshold is 500000). matchedRulesJson=' + results[0].matchedRulesJson);
        System.assertEquals(true, pricingFound,
            'Phase 1: Unconditional Pricing rule should always match regardless of amount. matchedRulesJson=' + results[0].matchedRulesJson);
    }

    // ── Phase 1 AC4: No match when wrong stage ───────────────────────────────

    @IsTest
    static void test_noMatchWhenWrongStage() {
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        Opportunity opp = new Opportunity(
            Name = 'Wrong Stage Test', AccountId = accId,
            Type = 'New Deal', StageName = 'Solutioning', CloseDate = Date.today().addDays(30), Pricebook2Id = Test.getStandardPricebookId(), Amount = 600000,
            Bypass_Validation__c = true
        );
        insert opp;

        System.debug('TEST: Evaluating rules for Stage=Solutioning. All seeded rules are for Qualification. Expect no matches.');

        Test.startTest();
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ makeRequest(opp.Id) });
        Test.stopTest();

        System.debug('RESULT: hasMatches=' + results[0].hasMatches
            + ' | matchedRuleCount=' + results[0].matchedRuleCount);

        System.assertEquals(false, results[0].hasMatches,
            'Phase 1: No rules exist for Solutioning stage — hasMatches should be false. matchedRulesJson=' + results[0].matchedRulesJson);
    }

    // ── Phase 1 AC5: Inactive rule is skipped ────────────────────────────────

    @IsTest
    static void test_inactiveRuleIgnored() {
        // Deactivate all rules
        List<Case_Creation_Rule__c> rules = [SELECT Id FROM Case_Creation_Rule__c];
        for (Case_Creation_Rule__c r : rules) r.Is_Active__c = false;
        update rules;

        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        Opportunity opp = new Opportunity(
            Name = 'Inactive Rule Test', AccountId = accId,
            Type = 'New Deal', StageName = 'Qualification', CloseDate = Date.today().addDays(30), Pricebook2Id = Test.getStandardPricebookId(), Amount = 600000,
            Bypass_Validation__c = true
        );
        insert opp;

        System.debug('TEST: All rules deactivated. Expect no matches.');

        Test.startTest();
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ makeRequest(opp.Id) });
        Test.stopTest();

        System.debug('RESULT: hasMatches=' + results[0].hasMatches);

        System.assertEquals(false, results[0].hasMatches,
            'Phase 1: Inactive rules should be ignored. Expected hasMatches=false. Got: ' + results[0].hasMatches);
    }

    // ── Phase 1 AC6: Null Opportunity ID returns empty result ────────────────

    @IsTest
    static void test_nullOppIdReturnsEmptyResult() {
        System.debug('TEST: Passing null opportunityId. Expect no exception and hasMatches=false.');

        Test.startTest();
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ makeRequest(null) });
        Test.stopTest();

        System.debug('RESULT: hasMatches=' + results[0].hasMatches);

        System.assertEquals(false, results[0].hasMatches,
            'Phase 1: Null opportunityId should return hasMatches=false without throwing. Got: ' + results[0].hasMatches);
    }

    // ── Phase 1 AC7: Bulk — 200 opportunities processed ─────────────────────

    @IsTest
    static void test_bulk200Opportunities() {
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            opps.add(new Opportunity(
                Name = 'Bulk Opp ' + i, AccountId = accId,
                Type = 'New Deal', StageName = 'Qualification', CloseDate = Date.today().addDays(30), Pricebook2Id = Test.getStandardPricebookId(), Amount = 600000,
            Bypass_Validation__c = true
            ));
        }
        List<CaseCreationRuleEvaluatorAction.Request> requests = new List<CaseCreationRuleEvaluatorAction.Request>();

        // startTest resets SOQL counter — insert + evaluate share a fresh 100-query budget.
        // 200-opp bulk insert fires OpportunityTrigger which can exhaust the outer test limit.
        System.debug('TEST: Inserting 200 opps and invoking evaluator inside startTest to avoid SOQL limit 101. Expect no governor limit errors.');

        Test.startTest();
        insert opps;
        // Re-build requests after insert so Ids are populated
        requests = new List<CaseCreationRuleEvaluatorAction.Request>();
        for (Opportunity o : opps) requests.add(makeRequest(o.Id));
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(requests);
        Test.stopTest();

        System.debug('RESULT: result count=' + results.size()
            + ' | first hasMatches=' + results[0].hasMatches);

        System.assertEquals(200, results.size(),
            'Bulk: Expected 200 results, one per request. Got: ' + results.size());
        for (Integer i = 0; i < results.size(); i++) {
            System.assertEquals(true, results[i].hasMatches,
                'Bulk: Result[' + i + '] hasMatches should be true. Got: ' + results[i].hasMatches);
        }
    }
}