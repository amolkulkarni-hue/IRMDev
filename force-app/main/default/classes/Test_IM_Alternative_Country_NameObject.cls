/*Developer Name: Madhu Paladugu
  Company       : TheCloudFountain Inc.
  Desrciption   : Test utility for IM_Alternative_Country_NameObject trigger.
  Date          : 12/3/12
  case number   : 00924109   */
@isTest(seeallData=true)
private class Test_IM_Alternative_Country_NameObject {

    static testMethod void runTest() {
      
      triggerFlowControl.setControlEnabled(false);//allow triggers to run without limit
      List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
      List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
      for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c == 'IM_Alternative_Country_Name__c') {
          cs.Value__c='True';
          updatesettings.add(cs);
        }
      }
      update updatesettings;
      
        IM_Country__c c = new IM_Country__c(name='This is a test');
        insert c;
        
        IM_Alternative_Country_Name__c acs = new IM_Alternative_Country_Name__c(Alternative_Name__c = 'Test Country',
                                                                               IM_Country__c = c.id);
        insert acs;
        
        IM_Alternative_Country_Name__c ac = [Select Id, Alternative_Name__c from IM_Alternative_Country_Name__c where IM_Country__c = :c.Id limit 1];
        
        boolean genError = false;
        //test renaming the root country
        try{
          ac.Alternative_Name__c = 'x';
          update ac;
        }
        catch(Exception e)
        {
          genError = true;
        }
        
         System.assertEquals(genError, false);
        
        genError = false;
        //test deleting the root country
        try{
          delete ac;
        }
        catch(Exception e)
        {
          genError = true;
        }
        
        System.assertEquals(genError, false);
        
    }
}