/**********************************************************************************************************************************************
 * Class: QTB_OperationalAccountNumberBatch
 * Test Class : QTB_OperationalAccountNumberBatch_Test
 * Author: Virtusa
 * Purpose: Test class for QTB_OperationalAccountNumberBatch
 * Requirement: GITLAB #28887 Dev: Batch class creation for new object (QTB_Operational_Account_Number__c) records and deletion of records
 * Change History:
 * Developer                 Date
 * ----------------------------------------------------------------------------------------------------------------------------------------------
 * Thrinethra                12/02/2025
 *************************************************************************************************************************************************/

@isTest
private class QTB_OperationalAccountNumberBatch_Test {
    
    @isTest
    static void testInitialRecordsPopulation() {
        
        //Confirming no records exist at the start
        Integer initialCount = [SELECT COUNT() FROM QTB_Operational_Account_Number__c];
        System.assertEquals(0, initialCount, 'There should not be any records before the test');
        
        Test.startTest();
        QTB_OperationalAccountNumberBatch batchJob = new QTB_OperationalAccountNumberBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();
        
        //Retrieving the count of records from custom label
        Integer recordsCountAsPerCustomLabel = Integer.valueOf(System.Label.Count_of_Records_for_Operational_Account);
        //Querying the record count after the batch job finishes
        Integer finalCount = [SELECT COUNT() FROM QTB_Operational_Account_Number__c];
        
        System.assertEquals(recordsCountAsPerCustomLabel, finalCount, 'After initial population, the record count should be equal to Count_of_Records_for_Operational_Account value');
    }
    
    @isTest
    static void testUtilisedRecordsDeletionAndPopulation() {
        
        //Creating 3 records with QTB_Number_Utilised__c = true
        List<QTB_Operational_Account_Number__c> utilisedRecords = new List<QTB_Operational_Account_Number__c>();
        for (Integer i = 0; i<3; i++) {
            QTB_Operational_Account_Number__c utilisedRecord = new QTB_Operational_Account_Number__c();
            utilisedRecord.QTB_Unique_Number__c = 'A' + String.valueOf(10000 +i);
            utilisedRecord.QTB_Number_Utilised__c = true;
            utilisedRecords.add(utilisedRecord);
        }
        
        //Creating 2 records with QTB_Number_Utilised__c = false
        List<QTB_Operational_Account_Number__c> nonUtilisedRecords = new List<QTB_Operational_Account_Number__c>();
        for (Integer i = 0; i<2; i++) {
            QTB_Operational_Account_Number__c nonUtilisedRecord = new QTB_Operational_Account_Number__c();
            nonUtilisedRecord.QTB_Unique_Number__c = 'A' + String.valueOf(20000 +i);
            nonUtilisedRecord.QTB_Number_Utilised__c = false;
            nonUtilisedRecords.add(nonUtilisedRecord);
        }
        
        insert utilisedRecords;
        insert nonUtilisedRecords;
        
        //Total records now = 5, batch will delete 3 utilised records
        
        Test.startTest();
        QTB_OperationalAccountNumberBatch batchJob = new QTB_OperationalAccountNumberBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();
        
        //Retrieving the count of records from custom label
        Integer recordsCountAsPerCustomLabel = Integer.valueOf(System.Label.Count_of_Records_for_Operational_Account);
        //Querying the record count after the batch job finishes
        Integer finalCount = [SELECT COUNT() FROM QTB_Operational_Account_Number__c];
        
        System.assertEquals(recordsCountAsPerCustomLabel, finalCount, 'After processing, the final record count should be equal to Count_of_Records_for_Operational_Account value');
        
        Integer utilisedCount = [SELECT COUNT() FROM QTB_Operational_Account_Number__c WHERE QTB_Number_Utilised__c = true];
        System.assertEquals(0, utilisedCount, 'All utilised records should have been deleted');
    }
    
    @isTest
    static void testGeneratedRecordsSeqRollOver() {
        QTB_OperationalAccountNumberBatch batchInst = new QTB_OperationalAccountNumberBatch();
        
        String lastSeq = 'D99999';
        List<QTB_Operational_Account_Number__c> recs = batchInst.generateRecords(lastSeq, 1);
        System.assertEquals(1, recs.size(), 'One record should be created');
        System.assertEquals('E00001', recs[0].QTB_Unique_Number__c, 'Rollover sequence from D99999 should produce E00001');
    }
    
    @isTest
    static void testJumpToDSeries() {
        QTB_OperationalAccountNumberBatch batchInst = new QTB_OperationalAccountNumberBatch();
        
        String lastSeq = 'A99999';
        List<QTB_Operational_Account_Number__c> recs = batchInst.generateRecords(lastSeq, 1);
        System.assertEquals(1, recs.size(), 'One record should be created');
        System.assertEquals('D00001', recs[0].QTB_Unique_Number__c, 'Sequence Jumps from A series should produce D00001');
    }
    
    @isTest(seealldata=false)
    static void testScheduleJob() {
        Test.startTest();
        String cronExp = '0 0 13 * * ?';
        String jobId = System.schedule('Test QTB_OperationalAccountNumberBatch', cronExp, new QTB_OperationalAccountNumberSchedule());
        Test.stopTest();
        
        System.assertNotEquals(jobId, null);
    }
}