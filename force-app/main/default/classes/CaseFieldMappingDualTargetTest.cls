@IsTest
private class CaseFieldMappingDualTargetTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'DualTargetE2E Account');
        insert acc;
        insert new Contact(LastName = 'DualTargetE2E', AccountId = acc.Id);
    }

    private static Id dealSupportRTId() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Deal_Support' LIMIT 1].Id;
    }

    @IsTest
    static void testMappingTargetingCaseDetailActuallyWritesToTheChildRecord() {
        // GAP: Case_Field_Mapping__c.Target_Object__c = 'Case_Detail__c' exists as a valid
        // config option, but CaseFieldMappingEngine.applyMappings() never branches on it — it
        // always writes every resolved mapping onto the Case itself (casesToUpdate is the only
        // accumulator in the method). A mapping configured to target Case_Detail__c is
        // therefore silently skipped: the target field doesn't exist on Case, so the per-field
        // try/catch swallows the failure. This test documents that gap and is expected to fail
        // until the engine is extended per the approved dual-target design.
        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'DualTargetE2E Opp', AccountId = con.AccountId, StageName = 'Qualification',
            CloseDate = Date.today().addDays(30), Amount = 42000
        );
        insert opp;

        insert new Case_Field_Mapping__c(
            Source_Object__c = 'Opportunity',
            Source_Field_Path__c = 'Amount',
            Target_Object__c = 'Case_Detail__c',
            Target_Field_API_Name__c = 'Sales_Billing_Estimate__c',
            Is_Active__c = true
        );

        Case c = new Case(
            RecordTypeId = dealSupportRTId(), Type = 'Remarketing', ContactId = con.Id,
            Opportunity__c = opp.Id, Status = 'New'
        );
        insert c;

        Case_Detail__c child = [SELECT Id, Sales_Billing_Estimate__c FROM Case_Detail__c WHERE Case__c = :c.Id];
        System.assertEquals(null, child.Sales_Billing_Estimate__c, 'Sanity check: field starts blank.');

        CaseFieldMappingEngine.Request req = new CaseFieldMappingEngine.Request();
        req.caseId = c.Id;

        Test.startTest();
        CaseFieldMappingEngine.applyMappings(new List<CaseFieldMappingEngine.Request>{ req });
        Test.stopTest();

        Case_Detail__c childAfter = [SELECT Sales_Billing_Estimate__c FROM Case_Detail__c WHERE Id = :child.Id];
        System.assertEquals(42000, childAfter.Sales_Billing_Estimate__c,
            'A Case_Field_Mapping__c row with Target_Object__c = Case_Detail__c should write the mapped Opportunity value onto the Case_Detail__c child, not silently no-op.');
    }

    @IsTest
    static void testMappingTargetingCaseStillWorks() {
        // Confirms the existing, already-working Case-target behavior is untouched. Note this
        // relies on Case.Sales_Billing_Estimate__c, which per the migration design should have
        // been deleted from Case once Case_Detail__c's copy went live — it hasn't been yet
        // (see CaseDetailAutoCreationTest.testMigratedFieldsShouldNoLongerExistOnCase). Update
        // this test's target field once that cleanup lands.
        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'DualTargetE2E Opp Case-target', AccountId = con.AccountId, StageName = 'Qualification',
            CloseDate = Date.today().addDays(30), Amount = 77000
        );
        insert opp;

        insert new Case_Field_Mapping__c(
            Source_Object__c = 'Opportunity',
            Source_Field_Path__c = 'Amount',
            Target_Object__c = 'Case',
            Target_Field_API_Name__c = 'Sales_Billing_Estimate__c',
            Is_Active__c = true
        );

        Case c = new Case(
            RecordTypeId = dealSupportRTId(), Type = 'Remarketing', ContactId = con.Id,
            Opportunity__c = opp.Id, Status = 'New'
        );
        insert c;

        CaseFieldMappingEngine.Request req = new CaseFieldMappingEngine.Request();
        req.caseId = c.Id;

        Test.startTest();
        CaseFieldMappingEngine.applyMappings(new List<CaseFieldMappingEngine.Request>{ req });
        Test.stopTest();

        Case caseAfter = [SELECT Sales_Billing_Estimate__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(77000, caseAfter.Sales_Billing_Estimate__c,
            'A Case_Field_Mapping__c row with Target_Object__c = Case should continue to write onto the Case itself.');
    }
}
