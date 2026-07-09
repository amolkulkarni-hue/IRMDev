@isTest
private class Test_ContractCancelBtn_Lightning {
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
        cont.Main_Contract__c=con.Id;
        cont.IME_Fixed_Pricing_Period_months_Services__c=12;
        cont.RecordTypeId='01280000000UJX3';
        cont.Status = 'Draft';
        cont.IME_Fixed_Pricing_Period_months_Services__c = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Services__c  = date.today();
        cont.IME_Fixed_Pricing_Period_months_Storage__c	 = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Storage__c  = date.today();
        cont.IME_Fixed_Pricing_Period_months_Prod_S__c = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Prod_S__c = date.today();
        cont.IME_Fixed_Pricing_Period_months_Transp__c = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Transp__c = date.today();
        cont.IME_Price_Increase_Type_Product_Sales__c = 'Index';
        cont.IME_Price_Increase_Type_Services__c = 'Index'; 
        cont.IME_Price_Increase_Type_Transport__c = 'Index';
        cont.IME_Price_Increase_Type_Storage__c = 'Index';
        insert cont;
        cont.Status = 'Draft';
        update cont;
        
        PageReference myVfPage = Page.ContractCancelBtn_Lightning;
        Test.setCurrentPage(myVfPage);
        ApexPages.currentPage().getParameters().put('contractid',cont.Id);
        Test.startTest();  
        ContractCancelBtn_Lightning testController = new ContractCancelBtn_Lightning(); 
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
        cont.IME_Fixed_Pricing_Period_months_Services__c = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Services__c  = date.today();
        cont.IME_Fixed_Pricing_Period_months_Storage__c	 = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Storage__c  = date.today();
        cont.IME_Fixed_Pricing_Period_months_Prod_S__c = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Prod_S__c = date.today();
        cont.IME_Fixed_Pricing_Period_months_Transp__c = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Transp__c = date.today();
        cont.IME_Price_Increase_Type_Product_Sales__c = 'Index';
        cont.IME_Price_Increase_Type_Services__c = 'Index'; 
        cont.IME_Price_Increase_Type_Transport__c = 'Index';
        cont.IME_Price_Increase_Type_Storage__c = 'Index';
        cont.RecordTypeId='01234000000Bmlc'; 
        insert cont;
        cont.Status = 'Draft'; 
        cont.Account_Registration_Number__c = 'test';
        update cont;
        
        PageReference myVfPage = Page.ContractCancelBtn_Lightning;
        Test.setCurrentPage(myVfPage);
        ApexPages.currentPage().getParameters().put('contractid',cont.Id);
        Test.startTest();  
        ContractCancelBtn_Lightning testController = new ContractCancelBtn_Lightning(); 
        testController.GoToContract(); 
        testController.UpdateContract();
        Test.stopTest();
    }
     static testMethod void contractActive2(){        
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
        update cont;
        
        PageReference myVfPage = Page.ContractCancelBtn_Lightning;
        Test.setCurrentPage(myVfPage);
        ApexPages.currentPage().getParameters().put('contractid',cont.Id);
        Test.startTest();  
        ContractCancelBtn_Lightning testController = new ContractCancelBtn_Lightning(); 
        testController.GoToContract(); 
        testController.UpdateContract();
        Test.stopTest();
    }
     static testMethod void contractActive3(){        
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
         cont.IME_Fixed_Pricing_Period_months_Services__c = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Services__c  = date.today();
        cont.IME_Fixed_Pricing_Period_months_Storage__c	 = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Storage__c  = date.today();
        cont.IME_Fixed_Pricing_Period_months_Prod_S__c = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Prod_S__c = date.today();
        cont.IME_Fixed_Pricing_Period_months_Transp__c = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Transp__c = date.today();
        cont.IME_Price_Increase_Type_Product_Sales__c = 'Index';
        cont.IME_Price_Increase_Type_Services__c = 'Index'; 
        cont.IME_Price_Increase_Type_Transport__c = 'Index';
        cont.IME_Price_Increase_Type_Storage__c = 'Index';
        cont.RecordTypeId='01280000000UJX2'; 
        cont.Main_Contract__c=con.Id;
        insert cont; 
        
        PageReference myVfPage = Page.ContractCancelBtn_Lightning;
        Test.setCurrentPage(myVfPage);
        ApexPages.currentPage().getParameters().put('contractid',cont.Id);
        Test.startTest();  
        ContractCancelBtn_Lightning testController = new ContractCancelBtn_Lightning(); 
        testController.GoToContract(); 
        testController.UpdateContract();
        Test.stopTest();
    }
     static testMethod void contractActive4(){        
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
         cont.IME_Fixed_Pricing_Period_months_Services__c = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Services__c  = date.today();
        cont.IME_Fixed_Pricing_Period_months_Storage__c	 = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Storage__c  = date.today();
        cont.IME_Fixed_Pricing_Period_months_Prod_S__c = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Prod_S__c = date.today();
        cont.IME_Fixed_Pricing_Period_months_Transp__c = 4;
        cont.IME_End_of_Fixed_Pricing_Period_Transp__c = date.today();
        cont.IME_Price_Increase_Type_Product_Sales__c = 'Index';
        cont.IME_Price_Increase_Type_Services__c = 'Index'; 
        cont.IME_Price_Increase_Type_Transport__c = 'Index';
        cont.IME_Price_Increase_Type_Storage__c = 'Index';
        cont.RecordTypeId='01280000000UJX2'; 
        cont.Main_Contract__c=con.Id;
        insert cont; 
         cont.Status = 'Terminated';
         update cont;
        
        PageReference myVfPage = Page.ContractCancelBtn_Lightning;
        Test.setCurrentPage(myVfPage);
        ApexPages.currentPage().getParameters().put('contractid',cont.Id);
        Test.startTest();  
        ContractCancelBtn_Lightning testController = new ContractCancelBtn_Lightning(); 
        testController.GoToContract(); 
        testController.UpdateContract();
        Test.stopTest();
    }
}