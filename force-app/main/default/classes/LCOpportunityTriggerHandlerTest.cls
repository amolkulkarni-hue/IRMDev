@isTest
private class LCOpportunityTriggerHandlerTest {

  static testMethod void processLeadConversionsTest()
  {
    User newUser ;
    Account acc = new Account (
    Name = 'newAcc1',
    IM_Partner_Manager__c = UserInfo.getUserId()
    );  
    insert acc;
    Contact con = new Contact (
    AccountId = acc.id,
    LastName = 'portalTestUser'
    );
    insert con;
    Trigger_Activation_Settings__c acs = new Trigger_Activation_Settings__c();
    acs.Object__c = 'Opportunity';
    acs.Trigger__c = 'OpportunityTrigger';
    acs.Value__c = 'TRUE';
    acs.name = 'OpportunityTrigger';
    insert acs;

    User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
     
    System.runAs ( thisUser ) {
   //UserRole ur = [Select PortalType, PortalAccountId From UserRole where PortalType =:'PowerPartner' limit 1];
    Profile p = [select Id,name from Profile where Name = :System.Label.LCTestClassProfile limit 1];
     
     newUser = new User(
    profileId = p.id,
    username = 'testpart3345678@put.com',
    email = 'pb@ff.com',
    emailencodingkey = 'UTF-8',
    localesidkey = 'en_US',
    languagelocalekey = 'en_US',
    timezonesidkey = 'America/Los_Angeles',
    alias='nuser',
    lastname='lastname',
    contactId = con.id,
    Country='US'
    );

    }
    Account a = new Account(Name='TestAccc567', BillingCountry = 'United States',
      BillingStreet = '745 Atlantic Ave',
      BillingPostalCode = 'SE1 2TT',
      BillingCity = 'Boston',
      BillingState = 'MA',
      IM_Partner_Manager__c = UserInfo.getUserId());
    insert a;
    Contact c = new Contact(LastName='TestContact',
      AccountId=a.Id,
      Email='testemail@email.com',
      MailingStreet = '745 Atlantic Ave',
      MailingCity = 'Boston', 
      MailingCountry = 'United States', 
      MailingPostalCode = 'SE1 2TT', 
      MailingState = 'MA'
      );
    insert c;
     Lead l ;
    System.runas(newUser) {
    l = new Lead();
      l.FirstName = 'Lead';
      l.LastName = 'TestContact';
      l.Status = 'Open'; 
      l.IM_Sales_Event__c = 'Campaign;';
      l.Company = 'TestAccc567';
      l.Email = 'testemail@email.com';
      l.Street = '745 Atlantic Ave';
      l.City = 'London';
      l.State = 'London';
      l.Country = 'United Kingdom';
      l.PostalCode = 'SE1 2TT';
      l.IM_Original_Lead_Owner__c = newUser.Id;
      l.OwnerId = newUser.Id;
            //l.RecordTypeId = imRecTypeId;
      insert l;

    }
      test.startTest();
       System.runas(thisUser) {
             database.leadConvert lc = new database.leadConvert();
               lc.setLeadId(l.id);
 
               leadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
                lc.setConvertedStatus(convertStatus.MasterLabel);
 
               Database.LeadConvertResult lcr = Database.convertLead(lc);
               System.assert(lcr.isSuccess());
 
               lc.setOpportunityName('TestAccc567');

      }
      test.stopTest();
       List<Lead> leadList = [Select Id,ConvertedOpportunityId From Lead where ID = :l.Id];
       System.assert(!LeadList.isEmpty());
       List<OpportunityTeamMember> teamList = [Select Id From OpportunityTeamMember Where OpportunityId = :leadList[0].ConvertedOpportunityId];
     System.assert(!teamList.isEmpty());
  }
}