@isTest(SeeAllData=true)
private class Test_ScheduleAObjectTrigger {
     
     static testMethod void doTest() {
        List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
        List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
        for(Trigger_Activation_Settings__c cs : customsettings){
          if(cs.Object__c == 'Schedule_A__c') {
            cs.Value__c='True';
            updatesettings.add(cs);
          }
        }
        update updatesettings;
         
        Schedule_A__c testSched;
        
        testSched = TestingUtil.createScheduleA(false);

        testSched.Current_Storage_Price__c=1;
 
        update testSched;
     }
}