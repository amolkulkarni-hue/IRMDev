@isTest
private class ContractBtnsTest {
    static testMethod void contractActive(){        
        List<Account> acct = TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, True);
        Contract cont = new Contract(); 
        cont.AccountId = acct[0].Id; 
        cont.Contract_Type__c = 'IM Standard';         
        cont.ContractTerm = 12; 
        cont.Status = 'Draft';
        insert cont;
        
        Contract con = new Contract(); 
        con.AccountId = acct[0].Id; 
        con.Contract_Type__c = 'IM Standard';         
        con.ContractTerm = 12; 
        con.Status = 'Draft';
        insert con;
        
        cont.Status = 'Activated';
        cont.RecordTypeId = '01280000000UJX3';
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
        con.Main_Contract__c = cont.id;
        update cont;
        update con;
        
        list<Contract> cc = new list<Contract>();
        cc.add(con);
                
        Test.startTest(); 
        System.currentPageReference().getParameters().put('contractid',cont.Id);
        ContractTerminateBtn_Lightning testController = new ContractTerminateBtn_Lightning(); 
        testcontroller.ChildContracts = cc;
        testController.GoToContract(); 
        testController.UpdateContract();
        
        cont.RecordTypeId = '01280000000UJX2';
        update cont; 
        System.currentPageReference().getParameters().put('contractid',cont.Id);
        ContractTerminateBtn_Lightning testController3 = new ContractTerminateBtn_Lightning(); 
        testController.GoToContract(); 
        testController.UpdateContract();
        
        Test.stopTest();
    }
    static testMethod void contractActive1(){        
        List<Account> acct = TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, True);
        Contract cont = new Contract(); 
        cont.AccountId = acct[0].Id; 
        cont.Contract_Type__c = 'IM Standard';         
        cont.ContractTerm = 12; 
        cont.Status = 'Draft';
        insert cont;
        
        cont.Status = 'Activated';
        cont.RecordTypeId = '01234000000Bmlb';
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
        update cont;
        
        Contract con = new Contract(); 
        con.AccountId = acct[0].Id; 
        con.Contract_Type__c = 'IM Standard';         
        con.ContractTerm = 12; 
        con.Status = 'Draft';
        con.Main_Contract__c = cont.id;
        insert con;
        
        Test.startTest(); 
        System.currentPageReference().getParameters().put('contractid',cont.Id);
        ContractTerminateBtn_Lightning testController = new ContractTerminateBtn_Lightning(); 
        testController.GoToContract(); 
        testController.UpdateContract();
    }
      static testMethod void contractActive3(){        
        List<Account> acct = TestingUtils.createAccounts(1,True);
        Contact cnt = TestingUtils.createContact(acct[0].id, True);
        Contract cont = new Contract(); 
        cont.AccountId = acct[0].Id; 
        cont.Contract_Type__c = 'IM Standard';         
        cont.ContractTerm = 12; 
        cont.Status = 'Draft';
        insert cont;
        
        cont.Status = 'Activated'; 
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
        update cont;
        
        Contract con = new Contract(); 
        con.AccountId = acct[0].Id; 
        con.Contract_Type__c = 'IM Standard';         
        con.ContractTerm = 12; 
        con.Status = 'Draft';
        con.Main_Contract__c = cont.id;
        insert con;
        
        Test.startTest(); 
        System.currentPageReference().getParameters().put('contractid',cont.Id);
        ContractTerminateBtn_Lightning testController = new ContractTerminateBtn_Lightning(); 
        testController.GoToContract(); 
        testController.UpdateContract();
    }
}