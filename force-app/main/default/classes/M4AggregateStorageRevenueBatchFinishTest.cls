/* Commenting the entire code as part of Gitlab #24448 */
@isTest
private class M4AggregateStorageRevenueBatchFinishTest {
/*
    static testMethod void M4AggregateStorageRevenueBatch_FinishTest() {
        Account acc =  TestingUtils.createAccounts(1, true)[0];
        Parent_Billing_Market__c pbm = TestingUtils.createParentBillingMarketRecords(1, true)[0];
        M4_Revenue_Coverage__c revCoverage = IMGAUtilities.createTestM4(acc.id, pbm.id, 'Canada', 'DBR');
        insert revCoverage;
        
        
        List<Aggregate_Storage_Revenue__c> aggStorageCoverages = new List<Aggregate_Storage_Revenue__c>();
        Date janDate = Date.newInstance(Date.today().year(), 1, 1);
        
        for(Integer i = 0; i < 100; i++) {
            Aggregate_Storage_Revenue__c rev = new Aggregate_Storage_Revenue__c(M4_Revenue_Coverage__c = revCoverage.id, Invoice_Date__c = janDate);
            rev.Aggregation_In_Progress__c = true;
            aggStorageCoverages.add(rev);
        }
        
        insert aggStorageCoverages;
        
        Test.startTest();
            
            M4AggregateStorageRevenueBatch_Finish job = new M4AggregateStorageRevenueBatch_Finish(null);

            Database.executeBatch(job, 100);
        Test.stopTest();
        
        List<Aggregate_Storage_Revenue__c> queriedRevenues = [Select Aggregation_in_Progress__c, id from Aggregate_Storage_Revenue__c];
        System.AssertEquals(100, queriedRevenues.size(), 'An incorrect number of coverages returned');
        for( Aggregate_Storage_Revenue__c revenue : queriedRevenues){
            System.Assert(!revenue.Aggregation_In_Progress__c, 'The Aggregate in Progress flag should have been flipped on this ASR record.');
        }
        
    }*/
}