/****************************** 
   Developer Name    : Apurva Dutta
   
   Date              : 1/22/14
   
   Company Name      : Iron Mountain Service India Pvt. Ltd.
   
   Purpose           : This class is used as test class for checking that only one customer accounts can be linked with one contract.
   
   Dependent Class   :  Apex Class  : ContractCusAccDuplicate
   
   Case Number       : 01590130
                                  
 ********************************/

@isTest

public class Test_ContractCusAccDuplicate{
    static testmethod void contrctCusAccDup(){
    
       test.startTest();
       
           Account acct = new Account(Name = 'Test Account New');
           insert acct;
            
           IM_Country__c contry = new IM_Country__c();
           contry.Name = 'United States';
           insert contry;
           
           Recordtype rectypCont = [Select ID,Name from recordtype where SObjectType = 'Contract' and Name = 'IME Parent Contract'];
           
           Contract contrct = new Contract();
           contrct.Name = 'test contract new';
           contrct.AccountId = acct.id;
           contrct.Billing_Country__c = contry.id;
           contrct.Status = 'Draft';
           contrct.StartDate = Date.today();
           contrct.IME_Contract_Term_Type__c = 'Fixed term';
           contrct.ContractTerm = 12;
           contrct.IM_Renewal_Term__c = 24;
           contrct.IME_Expiration_Notice_days__c = 60;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           insert contrct;
           
           Recordtype rectypCusAccnt = [Select ID,Name from recordtype where SObjectType = 'IM_Customer_Account__c' and Name = 'IME Customer Account'];
           
           IM_Customer_Account__c custAccnt = new IM_Customer_Account__c();
           custAccnt.Name = 'BlahBlahBlah';
           custAccnt.IM_Account__c = acct.id;
           custAccnt.Billing_Country__c = contry.id;
           insert custAccnt;
           
           Contract_Customer_Account__c contrctcustaccnt = new Contract_Customer_Account__c();
           //contrctcustaccnt.Name = 'BlahBlahBlah';
           contrctcustaccnt.IME_Contract_Id__c = contrct.id;
           contrctcustaccnt.IME_Customer_Accounts_Id__c = custAccnt.id;
           insert contrctcustaccnt;
           
           try
           {
               Contract_Customer_Account__c contrctcustaccntnew = new Contract_Customer_Account__c();
               //contrctcustaccntnew.Name = 'BlahBlahBlah';
               contrctcustaccntnew.IME_Contract_Id__c = contrct.id;
               contrctcustaccntnew.IME_Customer_Accounts_Id__c = custAccnt.id;
               insert contrctcustaccntnew;
           }
           catch(Exception e)
           {
                 Boolean expectedExceptionThrownnew =  e.getMessage().contains('Record Already Existed')?true : false;
                 System.AssertEquals(expectedExceptionThrownnew, false);
           }

           try
           {
                // contrctcustaccnt.Name = 'BlahBlahBlahnew'; 
                 update  contrctcustaccnt;
           }
           
           catch(Exception e)
           {
                 Boolean expectedExceptionThrown =  e.getMessage().contains('Record Already Existed')?true : false;
                 System.AssertEquals(expectedExceptionThrown, false);
           }
           
           test.stopTest();  
    }
    
    static testmethod void testContrctDataUpdate1(){
    
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
           contrct.IME_Contract_Term_Type__c = 'Fixed term';
           contrct.ContractTerm = 12;
           contrct.IM_Renewal_Term__c = 24;
           contrct.IME_Expiration_Notice_days__c = 60;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           contrct.IME_Copy_to_all__c = True;
           contrct.IME_Price_Increase_Type_Storage__c='Other';
           contrct.IME_Special_Terms_Other_Storage__c='Other Conent';        
        	contrct.IME_Fixed_Pricing_Period_months_Storage__c=3;
           insert contrct;
           
           test.stopTest();  
    }
    static testmethod void testContrctDataUpdate2(){
    
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
           contrct.IME_Contract_Term_Type__c = 'Fixed term';
           contrct.ContractTerm = 12;
           contrct.IM_Renewal_Term__c = 24;
           contrct.IME_Expiration_Notice_days__c = 60;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           contrct.IME_Copy_to_all__c = True;           
           contrct.IME_Index_Storage__c = 'CPI';
           contrct.IME_Price_Increase_Type_Storage__c='Regular Increase';
        	contrct.IME_Fixed_Pricing_Period_months_Storage__c=3;
           insert contrct;
           
           test.stopTest();  
    }
    static testmethod void testContrctDataUpdate3(){
    
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
           contrct.IME_Contract_Term_Type__c = 'Fixed term';
           contrct.ContractTerm = 12;
           contrct.IM_Renewal_Term__c = 24;
           contrct.IME_Expiration_Notice_days__c = 60;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           contrct.IME_Copy_to_all__c = True;           
           contrct.IME_Price_Increase_Type_Storage__c='Regular Increase';
        	contrct.IME_Fixed_Pricing_Period_months_Storage__c=3;
           contrct.IME_Capped_Percentage_Storage__c = 12;
           insert contrct;
           
           test.stopTest();  
    }
    static testmethod void testContrctDataUpdate4(){
    
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
           contrct.IME_Contract_Term_Type__c = 'Fixed term';
           contrct.ContractTerm = 12;
           contrct.IM_Renewal_Term__c = 24;
           contrct.IME_Expiration_Notice_days__c = 60;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           contrct.IME_Copy_to_all__c = True;
           contrct.IME_Price_Increase_Type_Storage__c='Index Linked';
           contrct.IME_Index_Storage__c = 'CPI';
           contrct.IME_Capped_Percentage_Storage__c = 12;        
        	contrct.IME_Fixed_Pricing_Period_months_Storage__c=3;
           insert contrct;
           
           test.stopTest();  
    }
    static testmethod void testContrctDataUpdate5(){
    
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
           contrct.IME_Contract_Term_Type__c = 'Fixed term';
           contrct.ContractTerm = 12;
           contrct.IM_Renewal_Term__c = 24;
           contrct.IME_Expiration_Notice_days__c = 60;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           contrct.IME_Copy_to_all__c = True;
           contrct.IME_Price_Increase_Type_Storage__c='Index Linked';
           contrct.IME_Index_Storage__c = 'CPI';
        	contrct.IME_Fixed_Pricing_Period_months_Storage__c=3;
           insert contrct;
           
           test.stopTest();  
    }
    static testmethod void testContrctDataUpdate6(){
    
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
           contrct.IME_Contract_Term_Type__c = 'Fixed term';
           contrct.ContractTerm = 12;
           contrct.IM_Renewal_Term__c = 24;
           contrct.IME_Expiration_Notice_days__c = 60;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           contrct.IME_Copy_to_all__c = True;
           contrct.IME_Price_Increase_Type_Storage__c='Other';
           contrct.IME_Capped_Percentage_Storage__c = 12;
        	contrct.IME_Special_Terms_Other_Storage__c='Other test';
        	contrct.IME_Fixed_Pricing_Period_months_Storage__c=3;
           insert contrct;
           
           test.stopTest();  
    }
    static testmethod void testContrctDataUpdate7(){
    
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
           contrct.IME_Contract_Term_Type__c = 'Fixed term';
           contrct.ContractTerm = 12;
           contrct.IM_Renewal_Term__c = 24;
           contrct.IME_Expiration_Notice_days__c = 60;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           contrct.IME_Copy_to_all__c = True;
           contrct.IME_Index_Storage__c = 'CPI';
           contrct.IME_Capped_Percentage_Storage__c = 12;
           contrct.IME_Price_Increase_Type_Storage__c='Regular Increase';
        	contrct.IME_Fixed_Pricing_Period_months_Storage__c=3;
           insert contrct;
           
           test.stopTest();  
    }
    static testmethod void testContrctDataUpdate8(){
    
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
           contrct.IME_Contract_Term_Type__c = 'Fixed term';
           contrct.ContractTerm = 12;
           //contrct.IM_Renewal_Term__c = ;
           contrct.IME_Expiration_Notice_days__c = 60;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           contrct.IME_Copy_to_all__c = True;
           contrct.IME_Index_Storage__c = 'CPI';
           contrct.IME_Capped_Percentage_Storage__c = 12;
           contrct.IME_Price_Increase_Type_Storage__c='Regular Increase';
        	contrct.IME_Fixed_Pricing_Period_months_Storage__c=3;
           insert contrct;
           
           test.stopTest();  
    }
    static testmethod void testContrctDataUpdate9(){
    
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
           contrct.IME_Contract_Term_Type__c = 'Evergreen';
           contrct.ContractTerm = 12;
           contrct.IM_Renewal_Term__c = 1.3;
           contrct.IME_Expiration_Notice_days__c = 60;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           contrct.IME_Copy_to_all__c = True;
           contrct.IME_Index_Storage__c = 'CPI';
           contrct.IME_Capped_Percentage_Storage__c = 12;
           contrct.IME_Price_Increase_Type_Storage__c='Regular Increase';
           contrct.IME_Fixed_Pricing_Period_months_Storage__c=3;
           insert contrct;
           
           test.stopTest();  
    }
    static testmethod void testContrctDataUpdate10(){
    
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
           contrct.IME_Contract_Term_Type__c = 'Evergreen (open rolling)';
           contrct.ContractTerm = null;
           contrct.IM_Renewal_Term__c = null;
           //contrct.IME_Expiration_Notice_days__c = null ;
           contrct.Contract_Type__c = 'IM Standard';
           contrct.IM_Contract_Category__c = 'Single Product';
           contrct.IME_Contract_Version__c = 'NDA';
           contrct.IME_MFP_Clause__c = 'YES';
           contrct.IME_Non_Standard_Clause__c = 'YES';
           contrct.IME_Other__c = True;
           contrct.IME_Copy_to_all__c = True;
           contrct.IME_Index_Storage__c = 'CPI';
           contrct.IME_Capped_Percentage_Storage__c = 12;
           contrct.IME_Price_Increase_Type_Storage__c='Regular Increase';
        	contrct.IME_Fixed_Pricing_Period_months_Storage__c=3;
           insert contrct;
           
           test.stopTest();  
    }
}