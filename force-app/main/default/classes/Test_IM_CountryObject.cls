/*Developer Name: Madhu Paladugu
  Company       : TheCloudFountain Inc.
  Desrciption   :  Test Utility for IM_CountryObject Trigger.
  Date          : 12/3/12
  case number   : 00924109   */
@isTest(seeAllData=true)
private class Test_IM_CountryObject {

    static testMethod void runTest() {
      List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
      List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
      for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c == 'IM_Country__c ') {
          cs.Value__c='True';
          updatesettings.add(cs);
        }
      }
      update updatesettings;
        IM_Country__c c = new IM_Country__c(name='This is a test',Active__c=true);
        insert c;
        
            System.assertEquals([Select Id, Alternative_Name__c from IM_Alternative_Country_Name__c where IM_Country__c = :c.Id].Alternative_Name__c
                                , 'This is a test');
                            
        
        c.name = 'This the second Test';
       try{
        update c;
        }
        catch(DmlException e){
        system.debug('+++++++++do nothing+++');
        }
                          
        /*System.assertEquals([Select Id, Alternative_Name__c from IM_Alternative_Country_Name__c where IM_Country__c = :c.Id].Alternative_Name__c
                            , 'This the second Test'); */
    }
}