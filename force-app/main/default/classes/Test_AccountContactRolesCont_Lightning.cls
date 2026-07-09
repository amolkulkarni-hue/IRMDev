@isTest
private class Test_AccountContactRolesCont_Lightning {
    static testMethod void ContactRole(){        
        List<Account> acct = TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, True);
        System.debug('Inside Test-Account Id='+acct[0].id+'ContactId='+cnt.id);
        Test.startTest();
        PageReference myVfPage = Page.AccountContactRole;
        System.currentPageReference().getParameters().put('cid',cnt.Id);
        Test.setCurrentPage(myVfPage);
        
        AccountContactRole cr = new AccountContactRole();
        cr.AccountId = acct[0].id;
        cr.ContactId = cnt.id;
        cr.Role = 'Records Manager';
        cr.IsPrimary = True;         
  		ApexPAges.StandardController sc = new ApexPages.StandardController(cr);
  		AccountContactRolesCont_Lightning testController = new AccountContactRolesCont_Lightning(sc);
        testController.save();
        testController.savenew();
        testController.cancel();
     
        Test.stopTest();
 }
}