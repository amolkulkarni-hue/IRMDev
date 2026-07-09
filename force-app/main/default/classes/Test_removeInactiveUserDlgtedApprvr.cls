/****************************** 
   Developer Name    : Venakteswarlu Avula
   
   Date              : 11/25/2013
   
   Company Name      : Iron Mountain India.
   
   Purpose           : Test Class for removeInactiveUserfromDelegatedApprover trigger.      
        
   Case Number       : 01908242
                                  
 ********************************/  

@isTest(seealldata = true)

private class Test_removeInactiveUserDlgtedApprvr {
  static testMethod void testInactiveUser(){
  
  /*List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
      List<Trigger_Activation_Settings__c> updatesettings = new List<Trigger_Activation_Settings__c>();
      for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c == 'User') {
          cs.Value__c='TRUE';
          updatesettings.add(cs);
        }
      }
      update updatesettings;
  
      // Querying for the profile
      Profile pfr = [Select id from Profile where Name = 'IME_Custom Sys Admin' limit 1];
      Profile pfrnew = [Select id from Profile where Name = 'IME_Custom Sys Admin' limit 1];
      
      
      //Creating new User      
      User usr = new User(
      FirstName = 'test',
      LastName = 'BlahBlah',
      Alias = 'testBlah',
      Email = 'invalid@ironmountain.com',
      Username = 'invalid@ironmountain.com.imi',
      CommunityNickname = 'invalid',
      ProfileId = pfr.id,
      IsActive = True,
      EmailEncodingKey = 'UTF-8',
      Country = 'India',
      TimeZoneSidKey = 'America/Los_Angeles',
      localesidkey='en_US',
      languagelocalekey='en_US');
      insert usr;
      
      //Creating new User
      User usrNew = new User(
      FirstName = 'test1',
      LastName = 'BlahBlah1',
      Alias = 'testBlh1',
      Email = 'invalid1@ironmountain.com',
      Username = 'invalid1@ironmountain.com.imi',
      CommunityNickname = 'invalid1',
      ProfileId = pfrnew.id,
      IsActive = True,
      EmailEncodingKey = 'UTF-8',
      Country = 'India',
      TimeZoneSidKey = 'America/Los_Angeles',
      DelegatedApproverId = usr.Id,
      localesidkey='en_US',
      languagelocalekey='en_US');
      
      insert usrNew;
      System.runAs(usrNew){
      usr.IsActive = False;
      update usr;
      }
      */
      
  }
}