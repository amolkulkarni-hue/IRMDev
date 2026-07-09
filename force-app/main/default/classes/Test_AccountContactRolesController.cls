@isTest
private class Test_AccountContactRolesController {
    
        static testMethod void ContactRoleShowAllYes(){        
        List<Account> acct = TestingUtils.createAccounts(1,True);
        contact cnt = TestingUtils.createContact(acct[0].id, True);
        //List<ContactRole> cr = TestingUtils.createCon            
        
          Test.startTest();
        
          PageReference myVfPage = Page.AccountContactRoleDetails;
          myVfPage.getParameters().put('showAll', 'Yes');    
          Test.setCurrentPage(myVfPage);
          ApexPAges.StandardController sc = new ApexPages.StandardController(cnt);
          AccountContactRolesController testController = new AccountContactRolesController(sc);
          List<AccountContactRole> lst = testController.acrs;
          lst = null;  
          
        
          testController.showMore();
          testController.savenew();  
          //testController.goback();
          Test.stopTest();
 }
    
       static testMethod void ContactRoleShowAllNo(){        
        List<Account> acct = TestingUtils.createAccounts(1,True);
        contact cnt = TestingUtils.createContact(acct[0].id, True);
        
          Test.startTest();
        
          PageReference myVfPage = Page.AccountContactRoleDetails;
          myVfPage.getParameters().put('showAll', 'No');    
          Test.setCurrentPage(myVfPage);
          ApexPAges.StandardController sc = new ApexPages.StandardController(cnt);
          AccountContactRolesController testController = new AccountContactRolesController(sc);
          List<AccountContactRole> lst = testController.acrs;
          lst = null;  
          
        
          testController.showMore();
          testController.savenew();  
          //testController.goback();
          Test.stopTest();
 }

}