/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   Test_BillingsToBoBCoverage_LauncherCont (Class)
**
** PURPOSE
**   Tests the BillingsToBoBCoverage_LauncherCont controller class.
**
** NOTES
**   Executing batch class by passing 'Developement'instance to controller class.
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 2013/03/25; Srinivasa Rao Mandalapu/Ranstad; Iron Mountain SFDC Billings Data Project (Project a0b00000000FTkA); Initial release
**
************************************************************************/

/* Commenting the entire code as part of Gitlab #25402 */

@isTest
private class Test_BillingsToBoBCoverage_LauncherCont {    
/*    
  //   public static final String testSettingsName = 'Test Settings';
     public static final Id Billing_RecordType_ID =
            [ select id from recordtype
               where sobjecttype = 'Billings__c' and developername = 'Country_Parent' ].Id;
    static testMethod void myUnitTest() {
          BillingsToBoBCoverageJoins__c settings = new BillingsToBoBCoverageJoins__c();
         String testSettingsName = 'Test Settings'; 
        //  String testSettingsName = 'Test Settings';
        // override its defaults as needed
        settings.Abort_Previous_Jobs__c      = TRUE;           // ensure starting clean
        settings.Associate_Enabled__c        = TRUE;
                  // run Clean and Chain       
        settings.Description__c              = 'Unit Test';
        settings.Focus_End_Period__c         = 1;
        settings.Focus_Year__c               = '2013';
        settings.Name                        = testSettingsName;
        settings.Query_Associate_Limit__c    = 'LIMIT 10';   // can only test one block anyway
        settings.Scope_Size__c               = 10; 
        settings.Test_Mode__c                = TRUE;
        settings.RecordTypeId__c            = ' AND RecordTypeId IN (\''+ Billing_RecordType_ID +'\')';// executes more code    
        settings.Query_Associate_Order_By__c = 'Id Desc';
        settings.Query_Associate_Select__c = 'Id,Country_Parent_ID_Text__c';
        settings.Query_Associate_Where__c = ' Id <> Null';
        insert settings;
        

        // TO DO: implement unit test
        BillingsToBoBCoverage_LauncherCont bbccontlr = new BillingsToBoBCoverage_LauncherCont();
        
        bbccontlr.setSettingsName(testSettingsName);
        //bbccontlr.setSettingsName('Test Dummy');
         // create a test execution instance
        Test.startTest();
        try{
        bbccontlr.runSyncjob();
        bbccontlr.customSettingToUse1 = testSettingsName;
        //bbccontlr.runSyncjob1();
        bbccontlr.runBatch();
        bbccontlr.customSettingToUse1 = testSettingsName;
        bbccontlr.runBatch1();
        bbccontlr.customSettingToUse2=settings.Name;
        bbccontlr.runM4AggregateStorageBatchJob1();
        }
        catch(Exception ex){
            system.debug('++++++do nothing++++');
        }
        //System.abortJob('707V0000003cBfw');
        // stopTest() won't return until batch job is complete
        Test.stopTest(); 
        
    }
    
    static testMethod void  runM4AggregateStorageBatchJobTest() {
        
        BillingsToBoBCoverage_LauncherCont launcher = new BillingsToBoBCoverage_LauncherCont();
        launcher.customSettingToUse = Test_InboundStorageToBoBCoverageHelper.CUSTOM_SETTING_NAME;
        
        Test.startTest();
            launcher.runM4AggregateStorageBatchJob();
        Test.stopTest();
        
        System.AssertNotEquals(Null, launcher.processID, 'The process ID for this batch job should have been set');
        
    } 
    
   static testMethod void  runM4AggregateStorageBatchJobPYTest() {
        
        BillingsToBoBCoverage_LauncherCont launcher = new BillingsToBoBCoverage_LauncherCont();
        launcher.customSettingToUse = Test_InboundStorageToBoBCoverageHelper.CUSTOM_SETTING_NAME;
        
        Test.startTest();
            launcher.runM4AggregateStorageBatchJobPY();
        Test.stopTest();
        
        System.AssertNotEquals(Null, launcher.processID, 'The process ID for this batch job should have been set');
    }  
    /*
    1/17/2014 - Preparing for deployment
    static testMethod void  runInboundStorageBatchJobTest() {
        Test_InboundStorageToBoBCoverageHelper.setup();
        
        BillingsToBoBCoverage_LauncherCont launcher = new BillingsToBoBCoverage_LauncherCont();
        launcher.customSettingToUse = Test_InboundStorageToBoBCoverageHelper.CUSTOM_SETTING_NAME;
        
        Test.startTest();
            launcher.runInboundStorageBatchJob();
        Test.stopTest();
        
        System.AssertNotEquals(Null, launcher.processID, 'The process ID for this batch job should have been set');
        
    } 
    */
}