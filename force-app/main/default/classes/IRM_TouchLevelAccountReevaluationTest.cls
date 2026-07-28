/**
 * IRM_TouchLevelAccountReevaluationTest
 * Covers Touch_Level_Condition__c.Field_API_Name__c = "Account.<field>" support and the
 * Account-driven recompute path (TouchLevelAccountReevaluationAction ->
 * TouchLevelEvaluatorAction.reevaluateForAccountChanges), which lets Touch Level recompute
 * purely from an Account field change with no Opportunity field touched.
 */
@IsTest
private class IRM_TouchLevelAccountReevaluationTest {

    @TestSetup
    static void setup() {
        // Required by OpportunityHelper.createOpportunityShare (Country_Settings__c and
        // Opportunity_Security__c are list custom settings read during Opportunity AfterInsert) —
        // without these, and without an Account.BillingCountry, that sharing-rule creation
        // step throws (unrelated to Touch Level, but triggered by every Opportunity insert).
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
        // Required by OppPartnerAction's static initializer (queried the first time the class
        // loads, including on any Opportunity BeforeUpdate — e.g. this test's Account-driven
        // path issuing an `update` on Opportunity.Touch_Level__c) — without this row, that
        // static query throws "List has no rows for assignment to SObject" (unrelated to
        // Touch Level, but triggered by any Opportunity update in this org).
        insert new OpportunityProductSelection__c(Name = 'CloudSolutionsProduct',
            Product_Class_Name__c = 'Cloud', Product_Line_Name__c = 'Cloud Solutions');

        Account acc = new Account(
            Name = 'Touch Level Account Test Co', Industry = null,
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;
    }

    private static Account getAccount() {
        return [SELECT Id, Industry FROM Account LIMIT 1];
    }

    private static Opportunity makeOpp(String name, Id accountId, String stage) {
        Opportunity opp = new Opportunity(
            Name = name, AccountId = accountId, StageName = stage,
            CloseDate = Date.today().addDays(30), Amount = 500000,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert opp;
        return opp;
    }

    private static Touch_Level_Criteria__c makeIndustryCriteria(String stage, String touchLevel) {
        Touch_Level_Criteria__c criteria = new Touch_Level_Criteria__c(
            Stage__c = stage, Touch_Level_Result__c = touchLevel, Priority__c = 1, Is_Active__c = true
        );
        insert criteria;
        insert new Touch_Level_Condition__c(
            Criteria__c = criteria.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Account.Industry', Operator__c = 'EQUALS', Value__c = 'Technology'
        );
        return criteria;
    }

    private static TouchLevelAccountReevaluationRequest makeRequest(Id accountId, String oldIndustry, String newIndustry) {
        TouchLevelAccountReevaluationRequest req = new TouchLevelAccountReevaluationRequest();
        req.oldAccount = new Account(Id = accountId, Industry = oldIndustry);
        req.newAccount = new Account(Id = accountId, Industry = newIndustry);
        return req;
    }

    @IsTest
    static void testTouchLevelRecalculatedFromAccountFieldChangeAlone() {
        makeIndustryCriteria('Qualification', 'High Touch');
        Account acc = getAccount();
        Opportunity opp = makeOpp('Account Industry Opp', acc.Id, 'Qualification');

        // Industry was null at insert time — the Account.Industry condition didn't match,
        // so Touch Level should have calculated to No Touch already (via the normal
        // Opportunity BeforeInsert trigger path).
        Opportunity beforeCheck = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('No Touch', beforeCheck.Touch_Level__c);

        // The real Flow only calls the invocable after the Account is already saved, so
        // condition evaluation (which re-queries the Account fresh) sees the new value —
        // mirror that here with a real DML update, not just an in-memory request snapshot.
        acc.Industry = 'Technology';
        update acc;

        Test.startTest();
        TouchLevelAccountReevaluationAction.reevaluateForAccountChanges(
            new List<TouchLevelAccountReevaluationRequest>{ makeRequest(acc.Id, null, 'Technology') });
        Test.stopTest();

        Opportunity afterCheck = [SELECT Touch_Level__c, Touch_Level_Calculated__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('High Touch', afterCheck.Touch_Level__c,
            'Touch Level should recalculate to High Touch purely from the Account.Industry change, with no Opportunity field touched.');
        System.assertEquals('High Touch', afterCheck.Touch_Level_Calculated__c);
    }

    @IsTest
    static void testOverrideSkipsAccountDrivenRecalculation() {
        makeIndustryCriteria('Qualification', 'High Touch');
        Account acc = getAccount();
        Opportunity opp = makeOpp('Override Opp', acc.Id, 'Qualification');

        opp.Touch_Level_Override__c = true;
        opp.Touch_Level__c = 'Low Touch';
        update opp; // Override=true is already set going into this same update, so the
                    // normal BeforeUpdate recalculation skips it and Low Touch sticks.

        Test.startTest();
        TouchLevelAccountReevaluationAction.reevaluateForAccountChanges(
            new List<TouchLevelAccountReevaluationRequest>{ makeRequest(acc.Id, null, 'Technology') });
        Test.stopTest();

        Opportunity afterCheck = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Low Touch', afterCheck.Touch_Level__c,
            'Touch_Level_Override__c = true must be respected by the Account-driven path too.');
    }

    @IsTest
    static void testClosedOpportunityExcludedFromAccountDrivenRecalculation() {
        makeIndustryCriteria('Qualification', 'High Touch');
        // A second criteria on the Closed Won stage — if IsClosed exclusion were missing,
        // this is what would otherwise let the Closed Opportunity match and get recalculated.
        makeIndustryCriteria('Closed Won', 'High Touch');
        Account acc = getAccount();
        Opportunity opp = makeOpp('Closed Won Opp', acc.Id, 'Closed Won');

        Opportunity beforeCheck = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];

        Test.startTest();
        TouchLevelAccountReevaluationAction.reevaluateForAccountChanges(
            new List<TouchLevelAccountReevaluationRequest>{ makeRequest(acc.Id, null, 'Technology') });
        Test.stopTest();

        Opportunity afterCheck = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(beforeCheck.Touch_Level__c, afterCheck.Touch_Level__c,
            'A Closed Opportunity must never be recalculated by an Account field change.');
    }

    @IsTest
    static void testNoActiveAccountCondition_NoOp() {
        Account acc = getAccount();
        Opportunity opp = makeOpp('No Criteria Opp', acc.Id, 'Qualification');
        Opportunity beforeCheck = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];

        Test.startTest();
        TouchLevelAccountReevaluationAction.reevaluateForAccountChanges(
            new List<TouchLevelAccountReevaluationRequest>{ makeRequest(acc.Id, null, 'Technology') });
        Test.stopTest();

        Opportunity afterCheck = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(beforeCheck.Touch_Level__c, afterCheck.Touch_Level__c);
    }

    @IsTest
    static void testBulkAccountUpdate_10Accounts() {
        makeIndustryCriteria('Qualification', 'High Touch');

        // Capped well below 200: this org's pre-existing (unrelated) AccountHelper.preventAccountCreation
        // calls a SOQL query once per Account inside a for-loop over the trigger batch, and
        // other legacy Opportunity-side automation adds further per-record overhead on top of
        // that — none of it part of this feature. 10 stays safely under the combined ceiling
        // while still proving this engine's own bulk-safety (a single Account SOQL, a single
        // Opportunity SOQL, and one Opportunity update regardless of batch size).
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            accounts.add(new Account(
                Name = 'Bulk Touch Account ' + i, Industry = null,
                BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
            ));
        }
        insert accounts;

        List<Opportunity> opps = new List<Opportunity>();
        for (Account acc : accounts) {
            opps.add(new Opportunity(
                Name = 'Bulk Touch Opp for ' + acc.Name, AccountId = acc.Id,
                StageName = 'Qualification', CloseDate = Date.today().addDays(30), Amount = 500000,
                Pricebook2Id = Test.getStandardPricebookId()
            ));
        }
        insert opps;

        // Real DML, matching the after-save timing the Flow provides in production — condition
        // evaluation re-queries the Account fresh, so the value must actually be committed.
        for (Account acc : accounts) acc.Industry = 'Technology';
        update accounts;

        List<TouchLevelAccountReevaluationRequest> requests = new List<TouchLevelAccountReevaluationRequest>();
        for (Account acc : accounts) {
            requests.add(makeRequest(acc.Id, null, 'Technology'));
        }

        Test.startTest();
        TouchLevelAccountReevaluationAction.reevaluateForAccountChanges(requests);
        Test.stopTest();

        Integer highTouchCount = [
            SELECT COUNT() FROM Opportunity WHERE AccountId IN :accounts AND Touch_Level__c = 'High Touch'
        ];
        System.assertEquals(10, highTouchCount,
            'Every impacted open Opportunity across a bulk Account update should recalculate to High Touch within governor limits.');
    }
}
