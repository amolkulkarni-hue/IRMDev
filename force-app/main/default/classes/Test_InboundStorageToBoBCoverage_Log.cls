/* Commenting the entire code as part of Gitlab #24446 */
@isTest
private class Test_InboundStorageToBoBCoverage_Log {
    /*
    static String CUSTOM_SETTINGS_NAME;
    
    public static void setup(){
        CUSTOM_SETTINGS_NAME = Test_InboundStorageToBoBCoverageHelper.CUSTOM_SETTING_NAME;
        Test_InboundStorageToBoBCoverageHelper.setup();
    }


    static testMethod void InboundStorageToBoBCoverage_LogTest() {
        setup();
        
        Test.startTest();
            InboundStorageToBoBCoverage_Log log = new InboundStorageToBoBCoverage_Log(CUSTOM_SETTINGS_NAME);
        Test.stopTest();
        ID settingID = [Select ID from M1_CDE_Settings__c where ID =: log.M1_settings.id limit 1].id;
        System.AssertEquals(Test_InboundStorageToBoBCoverageHelper.testCustomSettings.id, settingID, 'An incorrect custom setting has been set into the logger');
        
    }
     
    public static testMethod void reportDatabaseFailuresToDatabaseTest () {                     
      
      InboundStorageToBoBCoverage_Log log = new InboundStorageToBoBCoverage_Log(null);
      
      Map<String, InboundStorageToBoBCoverage_Log.EmailErrorMapping> emailErrorMap = new Map<String, InboundStorageToBoBCoverage_Log.EmailErrorMapping>();
      
      List<Account> accounts = TestingUtils.createAccounts(2, false);
      TestingUtils.dummyInsert( accounts );
      
      InboundStorageToBoBCoverage_Log.EmailErrorMapping testMapping1 = new InboundStorageToBoBCoverage_Log.EmailErrorMapping( accounts[0].id );
      testMapping1.errorCounter = 25;
      
      InboundStorageToBoBCoverage_Log.EmailErrorMapping testMapping2 = new InboundStorageToBoBCoverage_Log.EmailErrorMapping( accounts[1].id );
      testMapping2.errorCounter = 10;
      
      emailErrorMap.put( StatusCode.INVALID_ID_FIELD.name(), testMapping1 );
      emailErrorMap.put( StatusCode.INVALID_CROSS_REFERENCE_KEY.name(), testMapping2 );
      
      Test.startTest();
          log.reportDatabaseFailuresToDatabase(emailErrorMap , 'Upsert', 'M1_Physical_CDE_Batch');
      Test.stopTest();
      
      List<BoB_Coverage_Join_Log__c> logEntries = [Select ID, details__c, Message__c, Significance__c from BoB_Coverage_Join_Log__c];
      
      System.AssertEquals(1, logEntries.size(), 'An incorrect number of log entries is being created');
      System.AssertEquals('Error',  logEntries[0].significance__c, 'The significance should be error');
      System.Assert(logEntries[0].Message__c.contains( 'Upsert Failed' ), 'The correct operation should be captured');
      System.Assert(logEntries[0].details__c.contains(StatusCode.INVALID_ID_FIELD.name()), 'The detail message should contain an invalid ID field message.');
      System.Assert(logEntries[0].details__c.contains(StatusCode.INVALID_CROSS_REFERENCE_KEY.name()), 'The detail message should contain an invalid cross reference ID field error.');
      System.Assert(logEntries[0].details__c.contains('A total of 35 errors occurred : '), 'The detail message should contain the correct number of total errors.');
      System.Assert(logEntries[0].details__c.contains(accounts[0].id), 'The detail message should contain the correct account Id.');
      System.Assert(logEntries[0].details__c.contains(accounts[1].id), 'The detail message should contain the correct account Id.');
      
    }
    
    public static testMethod void buildErrorMappingFromResultsTest()
    {
      setup();
      InboundStorageToBoBCoverage_Log log = new InboundStorageToBoBCoverage_Log(CUSTOM_SETTINGS_NAME);
      final Integer NUM_RECORDS = 10;
    
      Account account = TestingUtils.createAccounts(1, false)[0];
      account.IM_Hierarchy_Level__c = 'IM Group (IMGA)';
      insert account;
        
      
      List<BoB_Coverage_eligible__c> bobEligibles = TestingUtils.createBoBCoverageEligibles(new List<Account>{ account, account, account}, false );//(account.id, 'Coverage Name' , 'Data Backup and Recovery', 'Canada', false);
      
      for( BoB_Coverage_Eligible__c eligible : bobEligibles){
          eligible.Country_Coverage__c = 'Canada';
      }
      
      insert bobEligibles;
      
      List<BoB_Coverage_Eligible__c> testEligibles = [ Select Id, Account__c from BoB_Coverage_Eligible__c ];
      
      List<Aggregate_Volume__c> volumesWithNoParentIDs = TestingUtils.createAggregateVolumes(null, NUM_RECORDS, false);
      List<Aggregate_Volume__c> volumesWithNoEligible = TestingUtils.createAggregateVolumes(bobEligibles[1].id, NUM_RECORDS, false);
      List<Aggregate_Volume__c> volumes = new List<Aggregate_Volume__c>();
      volumes.addAll(volumesWithNoParentIDs);
      volumes.addAll(volumesWithNoEligible);
      
      insert volumesWithNoEligible;
      
      delete bobEligibles[1];
      
      List<Database.UpsertResult> results =  Database.Upsert(volumesWithNoParentIDs, false);
      
      List<Database.UpsertResult> results2 =  Database.Upsert(volumesWithNoEligible, false);
      Map<String, InboundStorageToBoBCoverage_Log.EmailErrorMapping> errorMap = new Map<String, InboundStorageToBoBCoverage_Log.EmailErrorMapping>();
      
      Test.startTest();
          log.buildErrorMappingFromResults(errorMap, results, volumesWithNoParentIDs);
          log.buildErrorMappingFromResults(errorMap, results2, volumesWithNoEligible);
      Test.stopTest();
      
      System.assert( !errorMap.isEmpty(), 'Our Error Map should contain some entries');
      System.AssertEquals(2, errorMap.keyset().size(), 'There should be two different kinds of error messages');
      System.AssertEquals(NUM_RECORDS, errorMap.get(StatusCode.REQUIRED_FIELD_MISSING.name()).errorCounter, 'There should be ten required field errors');
      System.AssertEquals(NUM_RECORDS, errorMap.get(StatusCode.ENTITY_IS_DELETED.name()).errorCounter, 'There should be ten entity is deleted errors');
    }
    */
    
}