@isTest()
private class Test_IME_ContractDataCheck_BatchClass{
    static testMethod void testIME_ContractDataCheck_BatchClass()
    {
        test.startTest();
       
           Account acct = new Account(Name = 'Test Account New');
           insert acct;
            
           IM_Country__c contry = new IM_Country__c();
           contry.Name = 'United States';
           insert contry;
           
           Recordtype rectypCont = [Select ID,Name from recordtype where SObjectType = 'Contract' and Name = 'IME Parent Contract'];
           
           Contract contrct = new Contract();
           contrct.Name = 'test contract new';
           contrct.RecordTypeId = rectypCont.Id;
           contrct.AccountId = acct.id;
           contrct.Billing_Country__c = contry.id;
           contrct.Status = 'Draft';
           contrct.StartDate = Date.today();
           contrct.IME_Contract_Renewal_Date__c = System.today();
           contrct.IM_Renewal_Term__c = 24;
           contrct.IME_Contract_Term_Type__c = 'Evergreen';
           contrct.ContractTerm = 12;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           contrct.IME_Copy_to_all__c = True;
           contrct.IME_Price_Increase_Type_Storage__c='Regular Increase';
           contrct.IME_Fixed_Pricing_Period_months_Storage__c=3;
           insert contrct;
           
           Contract contrct1 = new Contract();
           contrct1.Name = 'test contract new';
           contrct1.RecordTypeId = rectypCont.Id;
           contrct1.AccountId = acct.id;
           contrct1.Billing_Country__c = contry.id;
           contrct1.Status = 'Draft';
           contrct1.StartDate = Date.today();
           contrct1.IME_Contract_Renewal_Date__c = System.today();
           contrct1.IM_Renewal_Term__c = 24;
           contrct1.IME_Contract_Term_Type__c = 'Evergreen';
           contrct1.ContractTerm = 12;
           contrct1.Contract_Type__c = 'IM Standard';
           contrct1.IM_Contract_Category__c = 'Single Product';
           contrct1.IME_Contract_Version__c = 'NDA';
           contrct1.IME_MFP_Clause__c = 'YES';
           contrct1.IME_Non_Standard_Clause__c = 'YES';
           contrct1.IME_Other__c = True;
           contrct1.IME_Copy_to_all__c = True;           
           contrct1.IME_Price_Increase_Type_Storage__c='Regular Increase';
           contrct1.IME_Fixed_Pricing_Period_months_Storage__c=3;
           insert contrct1;
           
           IME_ContractDataCheck_BatchClass objBatch = new IME_ContractDataCheck_BatchClass();
           Database.executeBatch(objBatch);
           
           test.stopTest();  
    }
    
}