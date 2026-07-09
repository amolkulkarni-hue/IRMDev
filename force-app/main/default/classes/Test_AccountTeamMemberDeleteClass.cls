@isTest(seeAllData=true)
public class Test_AccountTeamMemberDeleteClass {
 static testMethod void myUnitTest() {
    Profile prof = [select Id from profile where Name='IM_Custom Sys Admin' limit 1];
    List<User> user = new List<User>();
    User U1 = new User(alias = 'sanra', email='xyz@testorg.com',
        emailencodingkey='UTF-8', lastname='Test Name', languagelocalekey='en_US', profileId=prof.id, localesidkey='en_US', 
        Country = 'USA', timezonesidkey='America/New_York', username='sstrzs@testorg.com', CurrencyIsoCode='USD', 
        Role_Type__c='Sales-BDE');
    insert U1;
  
  Account acct = TestingUtils.createAccounts(1,true)[0];
  system.debug('++acct++' + acct );   
  AccountTeamMember atm= new AccountTeamMember(UserId=U1.Id,TeamMemberRole='IMAP – Sales',AccountId=acct.Id);
  insert atm; 
  
  AccountTeamMemberDeleteClass.wrapAccountTeamMember wrap= new AccountTeamMemberDeleteClass.wrapAccountTeamMember(atm);
  
  PageReference pageRef = Page.AccountTeamMemberDelete;
  Test.setCurrentPage(pageRef);
  pageRef.getParameters().put('id', acct.id);

   
  Apexpages.StandardController stdController = new Apexpages.StandardController(acct);
  AccountTeamMemberDeleteClass cont= new AccountTeamMemberDeleteClass(stdController);
 
  Test.startTest();
     system.RunAs(U1){
        cont.delete1();
        cont.cancel();
     }
   Test.stopTest();
    }

}