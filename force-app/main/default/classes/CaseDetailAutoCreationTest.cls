@IsTest
private class CaseDetailAutoCreationTest {

    @TestSetup
    static void setup() {
        // Required by OpportunityHelper.createOpportunityShare — see CaseCreationEndToEndTest
        // for the full explanation of why every Opportunity-inserting test needs this.
        insert new Country_Settings__c(Name = 'United States', Object_Name__c = 'Opportunity', SetupOwnerId = UserInfo.getOrganizationId());
        // See CaseCreationEndToEndTest for why this second seed row is also required.
        insert new OpportunityProductSelection__c(Name = 'CloudSolutionsProduct', Product_Class_Name__c = 'Cloud Solutions', Product_Line_Name__c = 'Cloud Solutions');

        Account acc = new Account(Name = 'CaseDetailAutoCreate Test Account');
        insert acc;
        insert new Contact(LastName = 'CaseDetailAutoCreate', AccountId = acc.Id);
        Opportunity opp = new Opportunity(
            Name = 'CaseDetailAutoCreate Test Opp', AccountId = acc.Id, StageName = 'Qualification',
            CloseDate = Date.today().addDays(30), Amount = 100000
        );
        insert opp;
    }

    private static Id dealSupportRTId() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Deal_Support' LIMIT 1].Id;
    }

    private static Case insertDealSupportCase(String caseType) {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Case c = new Case(
            RecordTypeId = dealSupportRTId(),
            Type = caseType,
            ContactId = con.Id,
            Opportunity__c = opp.Id,
            Status = 'New'
        );
        insert c;
        return c;
    }

    @IsTest
    static void testDealSupportCaseGetsExactlyOneCaseDetailChild() {
        Test.startTest();
        Case c = insertDealSupportCase('Remarketing');
        Test.stopTest();

        List<Case_Detail__c> children = [SELECT Id, Case__c FROM Case_Detail__c WHERE Case__c = :c.Id];
        System.assertEquals(1, children.size(),
            'Case_Detail_Auto_Create_Flow should create exactly one Case_Detail__c child for a Deal_Support Case.');
    }

    @IsTest
    static void testUnrelatedRecordTypeGetsNoCaseDetailChild() {
        // Case_Detail_Auto_Create_Flow's entry filter is scoped to RecordType_Name__c IN
        // ('B2B/Implementation', 'Deal Support') — a deliberate deviation from the original
        // "no entry filter" design, and a reasonable one (avoids an orphan Case_Detail__c for
        // every unrelated legacy Case Record Type). Confirms that scoping actually holds.
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Id genericRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Case_Record_Type' LIMIT 1].Id;

        Test.startTest();
        Case c = new Case(RecordTypeId = genericRTId, ContactId = con.Id, Status = 'New');
        insert c;
        Test.stopTest();

        List<Case_Detail__c> children = [SELECT Id FROM Case_Detail__c WHERE Case__c = :c.Id];
        System.assertEquals(0, children.size(),
            'A Case on an unrelated Record Type should not get a Case_Detail__c child.');
    }

    @IsTest
    static void testOpportunityOwnerNotifiedViaChatterOnCaseDetailCreation() {
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity LIMIT 1];

        Test.startTest();
        insertDealSupportCase('Remarketing');
        Test.stopTest();

        List<FeedItem> posts = [SELECT Id, ParentId FROM FeedItem WHERE ParentId = :opp.OwnerId];
        System.assert(!posts.isEmpty(),
            'The Opportunity Owner should receive a Chatter post when a Case_Detail__c child is created for their Opportunity (Case_Detail_Auto_Create_Flow > Notify_Opportunity_Owner).');
    }

    @IsTest
    static void testMigratedFieldsShouldNoLongerExistOnCase() {
        // GAP: Forecast_Billing_Months__c, Sales_Billing_Estimate__c, and Delay_Category__c
        // were migrated to Case_Detail__c (and exist there), but the original Case-hosted
        // fields were never deleted as the migration design required. This assertion
        // documents that gap and will fail until the old Case fields are removed.
        Map<String, Schema.SObjectField> caseFields = Schema.SObjectType.Case.fields.getMap();
        List<String> stillPresentOnCase = new List<String>();
        for (String f : new List<String>{ 'Forecast_Billing_Months__c', 'Sales_Billing_Estimate__c', 'Delay_Category__c' }) {
            if (caseFields.containsKey(f.toLowerCase())) stillPresentOnCase.add(f);
        }
        System.assertEquals(new List<String>(), stillPresentOnCase,
            'These fields were migrated to Case_Detail__c and should have been deleted from Case, but are still present there: ' + stillPresentOnCase);
    }
}
