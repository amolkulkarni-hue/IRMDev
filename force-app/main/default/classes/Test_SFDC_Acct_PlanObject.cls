/*
Author      : David Pier
Created Date: August 2012
Description : Test class for AccountPlanOwner Trigger
*/
//Modified
 /*Developer Name: Madhu Paladugu
  Company       : TheCloudFountain Inc.
  Date          : 12/4/12
  case number   : 00924109   */

@isTest(seeAllData=false)
public class Test_SFDC_Acct_PlanObject{
     
    static testMethod void myUnitTest() {
    List<Trigger_Activation_Settings__c> customsettings = Trigger_Activation_Settings__c.getall().values();
    List<Trigger_Activation_Settings__c> trgsettings = new List<Trigger_Activation_Settings__c>();
    
        Trigger_Activation_Settings__c tA = new Trigger_Activation_Settings__c();
        tA.name = 'AccountPlanOwner';
        tA.Object__c = 'SFDC_Acct_Plan__c';
        tA.Trigger__c = 'AccountPlanOwner';
        tA.Value__c = 'True';
        trgsettings.add(tA);
        
        tA = new Trigger_Activation_Settings__c();
        tA.name = 'GlobalAccountPlan';
        tA.Object__c = 'SFDC_Acct_Plan__c';
        tA.Trigger__c = 'GlobalAccountPlan';
        tA.Value__c = 'True';
        trgsettings.add(tA);
        
        insert trgsettings;
        
        List<AccountPlan_TemplateID__c> actPlanTemplateLst = new List<AccountPlan_TemplateID__c>();
        AccountPlan_TemplateID__c atc = new AccountPlan_TemplateID__c();
        atc.Name ='English';
        atc.TemplateId__c ='a1l34000004qs7k';
        actPlanTemplateLst.add(atc);
        
        atc = new AccountPlan_TemplateID__c();
        atc.Name ='French';
        atc.TemplateId__c ='a1l34000004qs7p';
        actPlanTemplateLst.add(atc);
        
        atc = new AccountPlan_TemplateID__c();
        atc.Name ='German';
        atc.TemplateId__c ='a1l34000004qs7u';
        actPlanTemplateLst.add(atc);
        
        atc = new AccountPlan_TemplateID__c();
        atc.Name ='Spanish';
        atc.TemplateId__c ='a1l34000004qs7z';
        actPlanTemplateLst.add(atc);        
        
        insert actPlanTemplateLst;
        
/*
      for(Trigger_Activation_Settings__c cs : customsettings){
        if(cs.Object__c == 'SFDC_Acct_Plan__c') {
          cs.Value__c='True';
          updatesettings.add(cs);
        }
      }
      update updatesettings;
*/
        //Create a test Account Plan
        Account testAccount = new Account(Name = 'Test Account',IM_Hierarchy_Level__c='Country Parent');
        insert testAccount;
        SFDC_Acct_Plan__c ap = new SFDC_Acct_Plan__c(
            Name = 'Test Account Plan',Account__c=testAccount.id,INTL_Country_Parent__c = testAccount.id,INTL_Country_Parent_ID__c = testAccount.id
        );
        insert ap;
        //Assert that Owner_Lookup__c = OwnerId
        System.assertEquals(ap.OwnerId, ap.Owner_Lookup__c);

        //Create a test user
        list<Profile> p1 = [SELECT Id FROM Profile WHERE Name like 'System Administrator'];
        
        User u1 = new User();
            u1.FirstName = 'fName';
            u1.LastName = 'lName';
            u1.Email = 'Test1234567@mail.com';
            u1.Username = 'Test1234567@mail.com';
            u1.Alias ='Test123';
            u1.CommunityNickname = 't123';
            u1.TimeZoneSidKey ='America/New_York';
            u1.LocaleSidKey = 'en_US';
            u1.EmailEncodingKey = 'UTF-8';
            u1.ProfileId = p1[0].id;
            u1.LanguageLocaleKey = 'en_US';
            u1.Country = 'United Kingdom';
        insert u1;
        
        //Update OwnerId
        ap.OwnerId = u1.Id;
        update ap;
        ap = [select Id,OwnerId,Owner_Lookup__c from SFDC_Acct_Plan__c where Id = :ap.Id limit 1];
        system.debug('------ap:'+ap);
        //Assert that Owner_Lookup__c = OwnerId
        System.assertEquals(ap.OwnerId, ap.Owner_Lookup__c);
    }

    static testMethod void myUnitTestBulk() {
        List<SFDC_Acct_Plan__c> plans = new List<SFDC_Acct_Plan__c>();
        Profile p = [SELECT Id FROM Profile WHERE name='System Administrator'];

        User u2 = new User();
            u2.FirstName = 'fName';
            u2.LastName = 'lName';
            u2.Email = 'Test12345678@mail.com';
            u2.Username = 'Test12345678@mail.com';
            u2.Alias ='Test1234';
            u2.CommunityNickname = 't1234';
            u2.TimeZoneSidKey ='America/New_York';
            u2.LocaleSidKey = 'en_US';
            u2.EmailEncodingKey = 'UTF-8';
            u2.ProfileId = p.id;
            u2.LanguageLocaleKey = 'en_US';
            u2.Country = 'United Kingdom';
        insert u2;
        Account testAccount = new Account(Name = 'Test Account',IM_Hierarchy_Level__c='Country Parent');
        insert testAccount;
        
        for (Integer i=0;i<10;i++) {

            SFDC_Acct_Plan__c ap = new SFDC_Acct_Plan__c(
                Name = 'Test Account Plan',
                Account__c=testAccount.id,
                INTL_Country_Parent__c = testAccount.id,
                INTL_Country_Parent_ID__c = testAccount.id,
                OwnerId = u2.Id
            );
            plans.add(ap);
        }

        insert plans;
    }
}