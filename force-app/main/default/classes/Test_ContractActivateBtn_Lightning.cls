@isTest
private class Test_ContractActivateBtn_Lightning {
    static testMethod void contractActive(){        
        List<Account> acct = TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, True); 
        Contract con = new Contract();
        con.Status='Draft';
        con.AccountId=acct[0].Id;
        insert con;
        Contract cont = new Contract(); 
        cont.AccountId = acct[0].Id; 
        cont.Contract_Type__c = 'IM Standard';         
        cont.ContractTerm = 12; 
        cont.Status = 'Draft';
        insert cont;
        cont.Status = 'Draft';
        cont.Account_Registration_Number__c = 'test';
        update cont;
        
        PageReference myVfPage = Page.ContractActivateBtn_Lightning;
        Test.setCurrentPage(myVfPage);
        ApexPages.currentPage().getParameters().put('contractid',cont.Id);
        Test.startTest();  
        ContractActivateBtn_Lightning testController = new ContractActivateBtn_Lightning(); 
        testController.GoToContract(); 
        testController.UpdateContract();
        Test.stopTest();
    }
    static testMethod void contractActive1(){        
        List<Account> acct = TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, True); 
        Contract con = new Contract();
        con.Status='Draft';
        con.AccountId=acct[0].Id;
        insert con;
        Contract cont = new Contract(); 
        cont.AccountId = acct[0].Id; 
        cont.Contract_Type__c = 'IM Standard';         
        cont.ContractTerm = 12; 
        cont.Status = 'Draft';
        insert cont;
        cont.Status = 'Terminated'; 
        cont.Account_Registration_Number__c = 'test';
        update cont;
        
        PageReference myVfPage = Page.ContractActivateBtn_Lightning;
        Test.setCurrentPage(myVfPage);
        ApexPages.currentPage().getParameters().put('contractid',cont.Id);
        Test.startTest();  
        ContractActivateBtn_Lightning testController = new ContractActivateBtn_Lightning(); 
        testController.GoToContract(); 
        testController.UpdateContract();
        Test.stopTest();
    }
}