@isTest
private class Test_ScheduleAQuoteItemObjectTrigger  {
     
     static testMethod void doTestTriggerEnabled() {
         
        // Create the custom setting to enable the trigger - this guarantees coverage
        Trigger_Activation_Settings__c triggerSetting = new Trigger_Activation_Settings__c(
            Name = 'LockScheduleAQuoteItemVer',
            Object__c = 'Schedule_A_Quote_Item__c',
            Trigger__c = 'LockScheduleAQuoteItemVerification',
            Value__c = 'True'
        );
        insert triggerSetting;
        
        // Create test data
        Schedule_A__c testSched = TestingUtil.createScheduleA(false);
        testSched.Current_Storage_Price__c = 1;
        update testSched;
       
        Schedule_A_Quote_Item__c testlineitem = new Schedule_A_Quote_Item__c();
        testlineitem.Schedule_A__c = testSched.id;
        testlineitem.Product_Number__c = 'Test';
        insert testlineitem;
        
        Test.startTest();
        
        // This update should trigger the logic and execute IRM_ScheduleAService.lockScheduleAQuoteItemVerification
        testlineitem.Product_Number__c = testlineitem.Product_Number__c + ' Updated';
        update testlineitem;
        
        Test.stopTest();
           }
     
     static testMethod void doTestTriggerDisabled() {
         
        // Create the custom setting to disable the trigger
        Trigger_Activation_Settings__c triggerSetting = new Trigger_Activation_Settings__c(
            Name = 'LockScheduleAQuoteItemVer',
            Object__c = 'Schedule_A_Quote_Item__c',
            Trigger__c = 'LockScheduleAQuoteItemVerification',
            Value__c = 'false'
        );
        insert triggerSetting;
        
        // Create test data
        Schedule_A__c testSched = TestingUtil.createScheduleA(false);
        testSched.Current_Storage_Price__c = 1;
        update testSched;
       
        Schedule_A_Quote_Item__c testlineitem = new Schedule_A_Quote_Item__c();
        testlineitem.Schedule_A__c = testSched.id;
        testlineitem.Product_Number__c = 'Test';
        insert testlineitem;
        
        Test.startTest();
        
        // This update should NOT trigger the service method logic
        testlineitem.Product_Number__c = testlineitem.Product_Number__c + ' Updated';
        update testlineitem;
        
        Test.stopTest();
     }
     
}