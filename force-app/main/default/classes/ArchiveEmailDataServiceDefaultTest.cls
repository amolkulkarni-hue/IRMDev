/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group Test
 * @description test class for ArchiveEmailDataServiceDefault. 
 * Test is limited because we cannot perform any DML operations on big objects in tests.
 */

@isTest
private class ArchiveEmailDataServiceDefaultTest {
    static final Integer RECORD_COUNT = 1;
    static final Id CASE_RECORDTYPE = Schema.SobjectType.Case.getRecordTypeInfosByDeveloperName().get('NCSP_New_Customer_Setup').getRecordTypeId();
    static final Date TODAY = Date.today();

    @isTest
    static void upsertBigObject_upserts() {
        IArchiveEmailDataService service = new ArchiveEmailDataServiceDefault();
        Test.startTest();
            List<Database.SaveResult> result = service.upsertBigObject(new List<Archive_Email__b>());
        Test.stopTest();
        System.assert(result.isEmpty(), 
            'Archived emails should be attempted to be upserted');
    }

    @isTest 
    static void deleteBigObject_deletes() {
        Set<Id> caseIds = Pluck.ids(
            new SObjectBuilder(Case.SObjectType)
                .put(Case.Project_Completion_Date__c, TODAY)
                .put(Case.RecordTypeId, CASE_RECORDTYPE)
                .put(Case.Transition_Date__c, TODAY)
                // Commenting for 8977 on 17th June 2022
                //.put(Case.Service_Order_Required__c, 'Yes')
                .count(RECORD_COUNT).create().getRecords()
        );
        IArchiveEmailDataService service = new ArchiveEmailDataServiceDefault();
        Boolean errorThrown = false;
        try {
            Test.startTest();
                service.deleteBigObject(caseIds);
            Test.stopTest();
        } catch(Exception e) {
            errorThrown = true;
        }
        System.assert(!errorThrown,
            'Archived emails should be attempted to be deleted without error');
    }
}