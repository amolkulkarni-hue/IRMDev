@isTest(seeAllData=true)

private class Test_CustomerVerifiersWorksheet{

    
    static testMethod void myUnitTest() {
    Profile prof = [select Id from profile where Name='IM_Custom Sys Admin' limit 1];
    List<User> user = new List<User>();
    User U1 = new User(alias = 'sanra', email='xyz@testorg.com',
        emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US', profileId=prof.id, localesidkey='en_US', 
        Country = 'USA', timezonesidkey='America/New_York', username='sstrzs@testorg.com', CurrencyIsoCode='USD', 
        Role_Type__c='COO EVP Director');
    insert U1;
    
    User U2 = new User(alias = 'sanra', email='xyz@testorg.com',
        emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US', profileId=prof.id, localesidkey='en_US', 
        Country = 'USA', timezonesidkey='America/New_York', username='strzs@testorg.com', CurrencyIsoCode='USD', 
        Role_Type__c='Director-Hybrid'); 
   insert U2;
   
   User U3 = new User(alias = 'sanra', email='xyz@testorg.com',
        emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US', profileId=prof.id, localesidkey='en_US', 
        Country = 'USA', timezonesidkey='America/New_York', username='ssrzs@testorg.com', CurrencyIsoCode='USD', 
        Role_Type__c='VP of Ops'); 
    insert U3;
    
    User U4 = new User(alias = 'sanra', email='xyz@testorg.com',
        emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US', profileId=prof.id, localesidkey='en_US', 
        Country = 'USA', timezonesidkey='America/New_York', username='ssrzs1@testorg.com', CurrencyIsoCode='USD', 
        Role_Type__c=''); 
    insert U4;
      //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
      Account acct = TestingUtils.createAccounts(1,true)[0];
     List<Opportunity> optylist = new list<Opportunity>();
       Opportunity opp = TestingUtils.createOpportunity(null, acct.Id, false);
        opp.Customer_Verifier_1__c = true;
        opp.Customer_Verifier_2__c = true;
        opp.Customer_Verifier_3__c = true;
        opp.Lead_Source_Most_Recent__c='Other';
        opp.CloseDate =system.today()+40;
        opp.IM_Booked_Date__c = system.today()+50;
        insert opp;
        optylist.add(opp);
        
  Apexpages.StandardSetController stdController = new Apexpages.StandardSetController(optylist);
  custVerifierWorksheetclass cont= new custVerifierWorksheetclass(stdController);
  cont.currentuser = U1;
  cont.optylist1 = optylist;
   
   Test.startTest();
        System.runAs(U1){
         insert new CustomerVerifiers__c(Name='test',UserRoleID__c='COO EVP Director');
         cont.selectedList='searchCust';
         cont.PagiIndex='Next';
         cont.edit();
         cont.save();
         cont.cancel();
         cont.getSearchCustDisablePrevious();
         cont.getSearchCustDisableNext();
         cont.shiftPaginationIndex();
        cont.CustomerPagination(0,1);
         Test.stopTest();
        }
    }

    static testMethod void myUnitTest1() {
        Profile prof = [select Id from profile where Name='IM_Custom Sys Admin' limit 1];
        List<User> user = new List<User>();
        User U1 = new User(alias = 'sanra', email='xyz@testorg.com',
            emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US', profileId=prof.id, localesidkey='en_US', 
            Country = 'USA', timezonesidkey='America/New_York', username='sstrzs@testorg.com', CurrencyIsoCode='USD', 
            Role_Type__c='COO EVP');
        insert U1;
        
        User U2 = new User(alias = 'sanra', email='xyz@testorg.com',
            emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US', profileId=prof.id, localesidkey='en_US', 
            Country = 'USA', timezonesidkey='America/New_York', username='strzs@testorg.com', CurrencyIsoCode='USD', 
            Role_Type__c='Director-Hybrid'); 
       insert U2;
       
       User U3 = new User(alias = 'sanra', email='xyz@testorg.com',
            emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US', profileId=prof.id, localesidkey='en_US', 
            Country = 'USA', timezonesidkey='America/New_York', username='ssrzs@testorg.com', CurrencyIsoCode='USD', 
            Role_Type__c='VP of Ops'); 
        insert U3;
        
        User U4 = new User(alias = 'sanra', email='xyz@testorg.com',
            emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US', profileId=prof.id, localesidkey='en_US', 
            Country = 'USA', timezonesidkey='America/New_York', username='ssrzs1@testorg.com', CurrencyIsoCode='USD', 
            Role_Type__c=''); 
        insert U4;
          //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
          Account acct = TestingUtils.createAccounts(1,true)[0];
         List<Opportunity> optylist = new list<Opportunity>();
           Opportunity opp = TestingUtils.createOpportunity(null, acct.Id, false);
            opp.Customer_Verifier_1__c = true;
            opp.Customer_Verifier_2__c = true;
            opp.Customer_Verifier_3__c = true;
            opp.Lead_Source_Most_Recent__c='Other';
            opp.CloseDate =system.today()+40;
            opp.IM_Booked_Date__c = system.today()+50;
            insert opp;
            optylist.add(opp);
            
      Apexpages.StandardSetController stdController = new Apexpages.StandardSetController(optylist);
      custVerifierWorksheetclass cont= new custVerifierWorksheetclass(stdController);
       
       Test.startTest();
            System.runAs(U1){
             insert new CustomerVerifiers__c(Name='test',UserRoleID__c='COO EVP');
             cont.selectedList='searchCust';
             cont.PagiIndex='Previous';
             cont.edit();
             cont.save();
             cont.cancel();
             cont.getSearchCustDisablePrevious();
             cont.getSearchCustDisableNext();
             cont.shiftPaginationIndex();
            cont.CustomerPagination(0,1);
             Test.stopTest();
            }
        }
}