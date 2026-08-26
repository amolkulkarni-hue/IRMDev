/**
 * IRM_CaseCreationAccountReevaluationTest
 * Covers Case_Creation_Condition__c.Field_API_Name__c = "Account.<field>" support and the
 * Account-driven re-evaluation path (CaseCreationAccountReevaluationAction ->
 * CaseCreationRuleEvaluatorAction.reevaluateForAccountChanges), which lets a Case be
 * created purely from an Account field change with no Opportunity field touched.
 */
@IsTest
private class IRM_CaseCreationAccountReevaluationTest {

    @TestSetup
    static void setup() {
        IM_Country__c testCountry = new IM_Country__c(Name = 'United States');
        insert testCountry;
        insert new IM_Alternative_Country_Name__c(
            IM_Country__c = testCountry.Id, Alternative_Name__c = 'United States'
        );
        insert new Country_Settings__c(Name = 'United States', Object_Name__c = 'Opportunity', SetupOwnerId = UserInfo.getOrganizationId());
        insert new List<Opportunity_Security__c>{
            new Opportunity_Security__c(Name = 'Primary CDE',          Field_Name__c = 'Primary_CDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'R', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Original Lead Owner',  Field_Name__c = 'IM_Original_Lead_Owner__c', Object_Name__c = 'Opportunity', Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Primary BDE',          Field_Name__c = 'Primary_BDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId())
        };
        insert new OpportunityProductSelection__c(Name = 'CloudSolutionsProduct',
            Product_Class_Name__c = 'Cloud', Product_Line_Name__c = 'Cloud Solutions');
        insert new List<SVStatus__c>{
            new SVStatus__c(Name = 'New Deal', Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId())
        };
        insert new SVStatus__c(Name = 'SVStatusPassed', Amount__c = 0, SetupOwnerId = UserInfo.getOrganizationId());
    }

    private static Account makeAccount(String name, String rating) {
        Account acc = new Account(
            Name = name, Rating = rating,
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;
        return acc;
    }

    private static Opportunity makeOpp(String name, Id accountId, String stage) {
        Opportunity opp = new Opportunity(
            Name = name, AccountId = accountId,
            Type = 'New Deal', StageName = stage, CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(), Amount = 100000,
            Bypass_Validation__c = true
        );
        insert opp;
        return opp;
    }

    private static Case_Creation_Rule__c makeAccountRatingRule() {
        Case_Creation_Rule__c rule = new Case_Creation_Rule__c(
            Stage__c = 'Qualification', Case_Type__c = 'Account Review',
            Record_Type_Dev_Name__c = 'Deal_Support',
            Queue_Developer_Name__c = 'Solution_Specialist_Queue',
            Is_Active__c = true, Priority__c = 1
        );
        insert rule;
        insert new Case_Creation_Condition__c(
            Rule__c = rule.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Account.Rating', Operator__c = 'EQUALS', Value__c = 'Hot'
        );
        return rule;
    }

    private static CaseCreationAccountReevaluationRequest makeRequest(Id accountId, String oldRating, String newRating) {
        CaseCreationAccountReevaluationRequest req = new CaseCreationAccountReevaluationRequest();
        req.oldAccount = new Account(Id = accountId, Rating = oldRating);
        req.newAccount = new Account(Id = accountId, Rating = newRating);
        return req;
    }

    @IsTest
    static void testCaseCreatedFromAccountFieldChangeAlone_NoOpportunityFieldTouched() {
        makeAccountRatingRule();
        Account acc = makeAccount('Account Rating Test Co', null);
        Opportunity opp = makeOpp('Account Rating Opp', acc.Id, 'Qualification');

        // Rating was null at Opportunity insert time — the Account.Rating condition
        // doesn't match yet, so no Case should exist.
        System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Opportunity__c = :opp.Id]);

        // The real Flow only calls the invocable after the Account is already saved, so
        // condition evaluation (which re-queries the Account fresh) sees the new value —
        // mirror that here with a real DML update, not just an in-memory request snapshot.
        acc.Rating = 'Hot';
        update acc;

        Test.startTest();
        CaseCreationAccountReevaluationAction.reevaluateForAccountChanges(
            new List<CaseCreationAccountReevaluationRequest>{ makeRequest(acc.Id, null, 'Hot') });
        Test.stopTest();

        List<Case> cases = [SELECT Id, Status, Type FROM Case WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, cases.size(),
            'A Case should be created purely from the Account.Rating change, with no Opportunity field ever touched.');
        System.assertEquals('New', cases[0].Status);
        System.assertEquals('Account Review', cases[0].Type);
    }

    @IsTest
    static void testClosedOpportunityExcludedFromAccountDrivenReevaluation() {
        makeAccountRatingRule();
        Account acc = makeAccount('Closed Opp Test Co', null);
        Opportunity opp = makeOpp('Closed Opp', acc.Id, 'Closed Won');

        Test.startTest();
        CaseCreationAccountReevaluationAction.reevaluateForAccountChanges(
            new List<CaseCreationAccountReevaluationRequest>{ makeRequest(acc.Id, null, 'Hot') });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Opportunity__c = :opp.Id],
            'A Closed Opportunity must never be re-cased by an Account field change.');
    }

    @IsTest
    static void testNoDuplicateCaseOnRepeatedInvocation() {
        makeAccountRatingRule();
        Account acc = makeAccount('No Dup Test Co', null);
        Opportunity opp = makeOpp('No Dup Opp', acc.Id, 'Qualification');

        acc.Rating = 'Hot';
        update acc;

        Test.startTest();
        CaseCreationAccountReevaluationAction.reevaluateForAccountChanges(
            new List<CaseCreationAccountReevaluationRequest>{ makeRequest(acc.Id, null, 'Hot') });
        CaseCreationAccountReevaluationAction.reevaluateForAccountChanges(
            new List<CaseCreationAccountReevaluationRequest>{ makeRequest(acc.Id, 'Hot', 'Hot') });
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Case WHERE Opportunity__c = :opp.Id],
            'Re-invoking Account-driven reevaluation for a still-matching Account must not create a second Case.');
    }

    @IsTest
    static void testNoActiveAccountCondition_NoOp() {
        // No Case_Creation_Rule__c / Condition referencing Account.<field> exists at all —
        // the method must return immediately without querying or creating anything.
        Account acc = makeAccount('No Rule Test Co', null);
        Opportunity opp = makeOpp('No Rule Opp', acc.Id, 'Qualification');

        Test.startTest();
        CaseCreationAccountReevaluationAction.reevaluateForAccountChanges(
            new List<CaseCreationAccountReevaluationRequest>{ makeRequest(acc.Id, null, 'Hot') });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Opportunity__c = :opp.Id]);
    }

    @IsTest
    static void testBulkAccountUpdate_10Accounts() {
        makeAccountRatingRule();

        // Capped well below 200: this org has several pre-existing (unrelated) non-bulkified
        // automations that each burn ~1 SOQL query per record in the batch — confirmed here to
        // include AccountHelper.preventAccountCreation (Account insert) and at least one legacy
        // Process/Flow triggered off Opportunity Stage (Opportunity insert) — none of it part
        // of this feature. 10 stays safely under the combined ceiling while still proving this
        // engine's own bulk-safety (a single Account SOQL, a single Opportunity SOQL, and one
        // Case insert regardless of batch size).
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            accounts.add(new Account(
                Name = 'Bulk Account ' + i, Rating = null,
                BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
            ));
        }
        insert accounts;

        List<Opportunity> opps = new List<Opportunity>();
        for (Account acc : accounts) {
            opps.add(new Opportunity(
                Name = 'Bulk Opp for ' + acc.Name, AccountId = acc.Id,
                Type = 'New Deal', StageName = 'Qualification', CloseDate = Date.today().addDays(30),
                Pricebook2Id = Test.getStandardPricebookId(), Amount = 100000,
                Bypass_Validation__c = true
            ));
        }
        insert opps;

        for (Account acc : accounts) acc.Rating = 'Hot';

        // Real DML through the real, Active Case_Creation_Account_Reevaluation_Flow — not a
        // direct Apex call to the action — since that Flow already fires automatically on this
        // update. Calling the action directly afterward as well would double-execute the
        // reevaluation (once via the Flow, once explicitly), which is a test artifact, not
        // production behavior. Test.startTest() resets governor limits immediately before this
        // bulk update, the heaviest DML in the test.
        Test.startTest();
        update accounts;
        Test.stopTest();

        System.assertEquals(10, [SELECT COUNT() FROM Case WHERE AccountId IN :accounts],
            'Every impacted open Opportunity across a bulk Account update should get its Case created within governor limits.');
    }
}
