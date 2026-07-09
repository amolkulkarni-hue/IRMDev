// Author: Pratap
// Date	: 16th March 2017
// This is developed to test contractTotalAnnualAmount class
@istest
public class Test_contractTotalAnnualAmount {
    
    static ID rtAddendum = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Addendum').getRecordTypeId();    
    static ID rtAddendumExt =  Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Addendum Extension').getRecordTypeId();    
    static ID rtChildContract = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Child Contract').getRecordTypeId();
    
    static ID rtIMEParent =  Schema.SObjectType.Contract.getRecordTypeInfosByName().get('IME Parent Contract').getRecordTypeId();
    // static ID EUOppType = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME standard opportunity').getRecordTypeId();
    
    
    @TestSetup
    static void datasetup()
    {	
        test.startTest();
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        Account a = GenerateTestData.createAccount();
        IM_Country__c IMCountry = GenerateTestData.createIMCountry();
        insert IMCountry;
        
        IM_Customer_Account__c cus = new IM_Customer_Account__c();
        cus.Name = 'Parent Customer';
        cus.IM_Account__c = a.id;        
        insert cus;
        
        List<Contract> contracts = new List<Contract>();
        Contract parentContract = CreateContract(rtIMEParent,IMCountry,a,false);  
        Contract ChildContract = CreateContract(rtChildContract,IMCountry,a,false); 
        Contract AddendumContract = CreateContract(rtAddendum,IMCountry,a,false); 
        Contract AddendumExtContract = CreateContract(rtAddendumExt,IMCountry,a,false);
        
        contracts.add(parentContract);
        contracts.add(ChildContract);
        contracts.add(AddendumContract);
        contracts.add(AddendumExtContract);
        insert contracts;
        
        List<Contract_Customer_Account__c> lstConCustAccts = new List<Contract_Customer_Account__c>();
        
        Contract_Customer_Account__c cca= ContractHelperClass.CreateContractCustomer(contracts[0].id,cus.ID);
        lstConCustAccts.add(cca);
        
        Contract_Customer_Account__c cca1 = ContractHelperClass.CreateContractCustomer(contracts[1].id,cus.ID);
        lstConCustAccts.add(cca1);
        
        insert lstConCustAccts;
        
        test.stopTest();
        
    }
    
    static testMethod void testAddendumTotalAnnualAmount (){
        List<Contract> contracts = [select id,IM_DRCi_Contract_Number__c,AccountId,RecordTypeId,IME_Price_Increase_Type_Storage__c,IME_Special_Terms_Other_Storage__c,IME_Fixed_Pricing_Period_months_Storage__c,IME_End_of_Fixed_Pricing_Period_Storage__c,Status,IME_Copy_to_all__c,IME_Index_Storage__c,IME_Capped_Percentage_Storage__c,IME_Original_Contract_Start_Date__c,StartDate,Contract_Signed_Date__c,ContractTerm,Billing_Country__c, IME_Other__c,CurrencyIsoCode,IME_Annual_Value_Opportunities__c,IME_MFP_Clause__c,IM_Renewal_Term__c,IME_Contract_Term_Type__c from Contract];      
        List<Contract> AddendumContracts = new List<Contract>();
        Contract parentContract;
        for(Contract cnt : contracts){
            if(cnt.RecordTypeId == rtIMEParent){
                parentContract = cnt;
            }else if(cnt.RecordTypeId == rtAddendum){
                AddendumContracts.add(cnt);
            }
        }
        // contracts[0].IME_Annual_Value_Opportunities__c = 10;
        contracts[0].Status = 'Activated'; 
        contracts[0].IME_Financial_Controller_Comments__c = 'Testing parent reocrd';
        contracts[0].SpecialTerms = 'Testing special terms';
        contracts[1].Status = 'Activated';
        contracts[1].Main_Contract__c = contracts[0].id;
        
        update contracts;
        
        
        AddendumContracts[0].status  = 'Activated';
        AddendumContracts[0].Main_Contract__c = contracts[0].id;
        AddendumContracts[0].Contract_Signed_Date__c = System.today()+3; 
        AddendumContracts[0].IME_MFP_Clause__c = 'Yes';
        AddendumContracts[0].IME_Non_Standard_Clause__c  = 'Yes';
        AddendumContracts[0].IME_Expiration_Notice_days__c = 45;
        AddendumContracts[0].IME_Expiration_Notice_days__c = 20;
        AddendumContracts[0].IM_Liability__c = 40;
        AddendumContracts[0].IM_Max_Liability__c =50;
        AddendumContracts[0].SpecialTerms = 'Test line ';
        AddendumContracts[0].IME_MFP_Clause__c = 'Yes';
        AddendumContracts[0].IME_Non_Standard_Clause__c = 'Yes';
        AddendumContracts[0].IME_Financial_Controller_Comments__c ='Financial comments';
        AddendumContracts[0].IME_Price_Increase_Type_Storage__c = 'Other';
        AddendumContracts[0].IME_Index_Storage__c = 'test services';
        AddendumContracts[0].IME_Capped_Percentage_Storage__c = 100;
        AddendumContracts[0].IME_End_of_Fixed_Pricing_Period_Storage__c = system.today().addMonths(1);
        AddendumContracts[0].IME_Special_Terms_Other_Storage__c = 'Special terms';
        AddendumContracts[0].IME_Price_Increase_Type_Services__c = 'Other';
        AddendumContracts[0].IME_Index_Services__c= 'Test services';
        AddendumContracts[0].IME_Capped_Percentage_Services__c = 50;
        AddendumContracts[0].IME_Special_Terms_Other_Services__c='special terms services';
        
        AddendumContracts[0].IME_End_of_Fixed_Pricing_Period_Services__c =system.today().addMonths(1);
        AddendumContracts[0].IME_Price_Increase_Type_Transport__c ='Other';
        AddendumContracts[0].IME_Index_Transport__c = 'Transport';
        AddendumContracts[0].IME_Capped_Percentage_Transport__c = 60;
        AddendumContracts[0].IME_Special_Terms_Other_Transp__c = 'Special terms other test234';
        AddendumContracts[0].IME_End_of_Fixed_Pricing_Period_Transp__c = system.today().addMonths(1);
        AddendumContracts[0].IME_Price_Increase_Type_Product_Sales__c = 'Other';
        AddendumContracts[0].IME_Index_Product_Sales__c = 'Product sales';
        AddendumContracts[0].IME_Capped_Percentage_Product_Sales__c = 60;
        AddendumContracts[0].IME_End_of_Fixed_Pricing_Period_Prod_S__c = system.today().addMonths(2);
        AddendumContracts[0].IME_Special_Terms_Other_Prod_S__c ='Special terms other test';
        AddendumContracts[0].StartDate = System.today().addmonths(1);
        AddendumContracts[0].IME_Contract_Term_Type__c ='Evergreen';
        AddendumContracts[0].ContractTerm = 12;
        AddendumContracts[0].IM_Renewal_Term__c = 12;
        AddendumContracts[0].IME_Liability_Currency__c = 'GBP';
        AddendumContracts[0].IME_Annual_Value_Opportunities__c = 0;
        AddendumContracts[0].Status = 'Activated'; 
        update AddendumContracts;
        
        // AddendumContracts[0].IME_Annual_Value_Opportunities__c=100;
        // update AddendumContracts;
        Test.startTest();
        
        List<contract> parent = new List<contract>();
        parent.add(parentContract);
        contractTotalAnnualAmount cnt = new contractTotalAnnualAmount();
        cnt.UpdateTotalAnnualValue(parent);
        Test.stopTest();
    }
    
    static testMethod void testAddendumExtTotAmount (){
        
        List<Contract> contracts = [select id,IM_DRCi_Contract_Number__c,AccountId,RecordTypeId,IME_Price_Increase_Type_Storage__c,IME_Special_Terms_Other_Storage__c,IME_Fixed_Pricing_Period_months_Storage__c,IME_End_of_Fixed_Pricing_Period_Storage__c,Status,IME_Copy_to_all__c,IME_Index_Storage__c,IME_Capped_Percentage_Storage__c,IME_Original_Contract_Start_Date__c,StartDate,Contract_Signed_Date__c,ContractTerm,Billing_Country__c, IME_Other__c,CurrencyIsoCode,IME_Annual_Value_Opportunities__c,IME_MFP_Clause__c,IM_Renewal_Term__c,IME_Contract_Term_Type__c from Contract];      
        List<Contract> updateContracts = new List<Contract>();
        List<Contract> AddendumContracts = new List<Contract>();
        Contract parentContract = new Contract();
        Contract ChildContract = new Contract();
        Contract AddendumExtContract = new Contract();
        List<Contract> lstNewcontracts = new  List<Contract>();
        for(Contract cnt : contracts){
            if(cnt.RecordTypeId == rtIMEParent){
                parentContract = cnt;
            }else if(cnt.RecordTypeId == rtChildContract){
                ChildContract = cnt;
                system.debug('Child Contract entered');
            }else if(cnt.RecordTypeId == rtAddendumExt){
                AddendumExtContract = cnt;
                 system.debug('Add Contract entered');
            }
        }
        
        /*  Contract_Customer_Account__c cca= ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
insert cca;
*/
        parentContract.Status = 'Activated';
        parentContract.IME_Copy_to_all__c = false;
        
        updateContracts.add(parentContract);
        
        system.debug('ChildContract.....id...'+ChildContract.Id);
        system.debug('AddendumExtContract.....id...'+AddendumExtContract.Id);
        
        
        System.debug('parentContract ID:'+parentContract.id);
        
     
        ChildContract.Main_Contract__c = parentContract.id;
        AddendumExtContract.Main_Contract__c = parentContract.id;
        // contracts.add(parentContract);
        lstNewcontracts.add(ChildContract);
        lstNewcontracts.add(AddendumExtContract);
       
        update lstNewcontracts;
        
        // contracts[0].IME_Annual_Value_Opportunities__c = 10;
        ChildContract.Status = 'Activated'; 
        ChildContract.IME_Financial_Controller_Comments__c = 'Testing parent reocrd';
        ChildContract.SpecialTerms = 'Testing special terms';
        ChildContract.IME_Expiration_Notice_days__c = null;
        ChildContract.IME_Copy_to_all__c = false;
        /*
Contract_Customer_Account__c cca1 = ContractHelperClass.CreateContractCustomer(contracts[0].id,cus.ID);
insert cca1;
*/
        updateContracts.add(ChildContract);
        //  insert AddendumContracts;
        system.debug('Record Type:'+ contracts[1].RecordTypeId);
        //  contracts[2].Main_Contract__c = contracts[0].id;
        AddendumExtContract.Contract_Signed_Date__c = System.today()+3; 
        AddendumExtContract.IME_MFP_Clause__c = 'Yes';
        AddendumExtContract.IME_Non_Standard_Clause__c  = 'Yes';
        AddendumExtContract.IME_Expiration_Notice_days__c = 45;
        AddendumExtContract.IME_Expiration_Notice_days__c = 20;
        AddendumExtContract.IM_Liability__c = 40;
        AddendumExtContract.IM_Max_Liability__c =50;
        AddendumExtContract.SpecialTerms = 'Test line ';
        AddendumExtContract.IME_MFP_Clause__c = 'Yes';
        AddendumExtContract.IME_Non_Standard_Clause__c = 'Yes';
        AddendumExtContract.IME_Financial_Controller_Comments__c ='Financial comments';
        AddendumExtContract.IME_Price_Increase_Type_Storage__c = 'Other';
        AddendumExtContract.IME_Index_Storage__c = 'test services';
        AddendumExtContract.IME_Capped_Percentage_Storage__c = 100;
        AddendumExtContract.IME_End_of_Fixed_Pricing_Period_Storage__c = system.today().addMonths(1);
        AddendumExtContract.IME_Special_Terms_Other_Storage__c = 'Special terms 123';
        AddendumExtContract.IME_Price_Increase_Type_Services__c = 'Other';
        AddendumExtContract.IME_Index_Services__c= 'Test services';
        AddendumExtContract.IME_Capped_Percentage_Services__c = 50;
        AddendumExtContract.IME_Special_Terms_Other_Services__c='special terms services 123';
        
        AddendumExtContract.IME_End_of_Fixed_Pricing_Period_Services__c =system.today().addMonths(1);
        AddendumExtContract.IME_Price_Increase_Type_Transport__c ='Other';
        AddendumExtContract.IME_Index_Transport__c = 'Transport';
        AddendumExtContract.IME_Capped_Percentage_Transport__c = 60;
        AddendumExtContract.IME_Special_Terms_Other_Transp__c = 'Special terms other test234';
        AddendumExtContract.IME_End_of_Fixed_Pricing_Period_Transp__c = system.today().addMonths(1);
        AddendumExtContract.IME_Price_Increase_Type_Product_Sales__c = 'Other';
        AddendumExtContract.IME_Index_Product_Sales__c = 'Product sales';
        AddendumExtContract.IME_Capped_Percentage_Product_Sales__c = 60;
        AddendumExtContract.IME_End_of_Fixed_Pricing_Period_Prod_S__c = system.today().addMonths(2);
        AddendumExtContract.IME_Special_Terms_Other_Prod_S__c ='Special terms other test';
        AddendumExtContract.StartDate = System.today().addmonths(1);
        AddendumExtContract.IME_Contract_Term_Type__c ='Evergreen';
        AddendumExtContract.ContractTerm = 12;
        AddendumExtContract.IM_Renewal_Term__c = 12;
        AddendumExtContract.IME_Liability_Currency__c = 'GBP';
        AddendumExtContract.IME_Annual_Value_Opportunities__c = 10;
        AddendumExtContract.Status = 'Activated'; 
        AddendumExtContract.IME_Copy_to_all__c = false;
        updateContracts.add(AddendumExtContract); 
        
        update updateContracts;
        Test.startTest();
       
        List<contract> parent = new List<contract>();
        parent.add(parentContract);
        contractTotalAnnualAmount cnt = new contractTotalAnnualAmount();
        contractTotalAnnualAmount.runOnce();
        cnt.UpdateTotalAnnualValue(parent);
        
        Test.stopTest();

    }
    
    public static contract CreateContract(ID recTypeID,IM_Country__c cntry,Account a, Boolean isInsert){
        
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true; // bypass the Account trigger execution
        
        Contract ContractObj = new Contract();
        ContractObj.IM_DRCi_Contract_Number__c = '12';
        ContractObj.AccountId = a.id;
        ContractObj.RecordTypeId = recTypeID;
        ContractObj.IME_Price_Increase_Type_Storage__c = 'Other';
        ContractObj.IME_Special_Terms_Other_Storage__c = 'Test' ;
        ContractObj.IME_Fixed_Pricing_Period_months_Storage__c = 3 ;
        ContractObj.IME_End_of_Fixed_Pricing_Period_Storage__c = System.today();
        ContractObj.Status = 'Draft';
        ContractObj.IME_Copy_to_all__c = true ;
        ContractObj.IME_Index_Storage__c = 'CPI';
        ContractObj.IME_Capped_Percentage_Storage__c = 2 ;
        ContractObj.IME_Original_Contract_Start_Date__c = System.today();
        ContractObj.StartDate = System.today().addmonths(-1);
        ContractObj.Contract_Signed_Date__c = System.today()+2;
        ContractObj.ContractTerm=1;
        ContractObj.Billing_Country__c =cntry.id;
        ContractObj.IME_Other__c = True; 
        ContractObj.CurrencyIsoCode='GBP'; 
        ContractObj.IME_Annual_Value_Opportunities__c = 10;
        ContractObj.IME_MFP_Clause__c = 'No';  
        ContractObj.IM_Renewal_Term__c = 12;
        ContractObj.IME_Contract_Term_Type__c = 'Fixed term';
        
        if ( isInsert )
            insert ContractObj;
        return ContractObj;
    }
    
    
    
    static testMethod void testZeroTotAmount (){
        
        List<Contract> contracts = [select id,IM_DRCi_Contract_Number__c,AccountId,RecordTypeId,IME_Price_Increase_Type_Storage__c,IME_Special_Terms_Other_Storage__c,IME_Fixed_Pricing_Period_months_Storage__c,IME_End_of_Fixed_Pricing_Period_Storage__c,Status,IME_Copy_to_all__c,IME_Index_Storage__c,IME_Capped_Percentage_Storage__c,IME_Original_Contract_Start_Date__c,StartDate,Contract_Signed_Date__c,ContractTerm,Billing_Country__c, IME_Other__c,CurrencyIsoCode,IME_Annual_Value_Opportunities__c,IME_MFP_Clause__c,IM_Renewal_Term__c,IME_Contract_Term_Type__c from Contract];      
        List<Contract> updateContracts = new List<Contract>();
        List<Contract> AddendumContracts = new List<Contract>();
        Contract parentContract = new Contract();
        Contract ChildContract = new Contract();
        Contract AddendumExtContract = new Contract();
        List<Contract> lstNewcontracts = new  List<Contract>();
        for(Contract cnt : contracts){
            if(cnt.RecordTypeId == rtIMEParent){
                parentContract = cnt;
            }else if(cnt.RecordTypeId == rtChildContract){
                ChildContract = cnt;
                system.debug('Child Contract entered');
            }else if(cnt.RecordTypeId == rtAddendumExt){
                AddendumExtContract = cnt;
                 system.debug('Add Contract entered');
            }
        }
        
        /*  Contract_Customer_Account__c cca= ContractHelperClass.CreateContractCustomer(parentContract.id,cus.ID);
insert cca;
*/
        parentContract.Status = 'Activated';
        parentContract.IME_Copy_to_all__c = false;
        
        updateContracts.add(parentContract);
        
        system.debug('ChildContract.....id...'+ChildContract.Id);
        system.debug('AddendumExtContract.....id...'+AddendumExtContract.Id);
        
        
        System.debug('parentContract ID:'+parentContract.id);
        
     
        ChildContract.Main_Contract__c = parentContract.id;
        AddendumExtContract.Main_Contract__c = parentContract.id;
        // contracts.add(parentContract);
        lstNewcontracts.add(ChildContract);
       lstNewcontracts.add(AddendumExtContract);
       
        update lstNewcontracts;
        
        // contracts[0].IME_Annual_Value_Opportunities__c = 10;
        ChildContract.Status = 'Activated'; 
        ChildContract.IME_Financial_Controller_Comments__c = 'Testing parent reocrd';
        ChildContract.SpecialTerms = 'Testing special terms';
        ChildContract.IME_Expiration_Notice_days__c = null;
        ChildContract.IME_Copy_to_all__c = false;
        /*
Contract_Customer_Account__c cca1 = ContractHelperClass.CreateContractCustomer(contracts[0].id,cus.ID);
insert cca1;
*/
        updateContracts.add(ChildContract);
        
        //  insert AddendumContracts;
        system.debug('Record Type:'+ contracts[1].RecordTypeId);
        //  contracts[2].Main_Contract__c = contracts[0].id;
        AddendumExtContract.Contract_Signed_Date__c = System.today()+3; 
        AddendumExtContract.IME_MFP_Clause__c = 'Yes';
        AddendumExtContract.IME_Non_Standard_Clause__c  = 'Yes';
        AddendumExtContract.IME_Expiration_Notice_days__c = 45;
        AddendumExtContract.IME_Expiration_Notice_days__c = 20;
        AddendumExtContract.IM_Liability__c = 40;
        AddendumExtContract.IM_Max_Liability__c =50;
        AddendumExtContract.SpecialTerms = 'Test line ';
        AddendumExtContract.IME_MFP_Clause__c = 'Yes';
        AddendumExtContract.IME_Non_Standard_Clause__c = 'Yes';
        AddendumExtContract.IME_Financial_Controller_Comments__c ='Financial comments';
        AddendumExtContract.IME_Price_Increase_Type_Storage__c = 'Other';
        AddendumExtContract.IME_Index_Storage__c = 'test services';
        AddendumExtContract.IME_Capped_Percentage_Storage__c = 100;
        AddendumExtContract.IME_End_of_Fixed_Pricing_Period_Storage__c = system.today().addMonths(1);
        AddendumExtContract.IME_Special_Terms_Other_Storage__c = 'Special terms 123';
        AddendumExtContract.IME_Price_Increase_Type_Services__c = 'Other';
        AddendumExtContract.IME_Index_Services__c= 'Test services';
        AddendumExtContract.IME_Capped_Percentage_Services__c = 50;
        AddendumExtContract.IME_Special_Terms_Other_Services__c='special terms services 123';
        
        AddendumExtContract.IME_End_of_Fixed_Pricing_Period_Services__c =system.today().addMonths(1);
        AddendumExtContract.IME_Price_Increase_Type_Transport__c ='Other';
        AddendumExtContract.IME_Index_Transport__c = 'Transport';
        AddendumExtContract.IME_Capped_Percentage_Transport__c = 60;
        AddendumExtContract.IME_Special_Terms_Other_Transp__c = 'Special terms other test234';
        AddendumExtContract.IME_End_of_Fixed_Pricing_Period_Transp__c = system.today().addMonths(1);
        AddendumExtContract.IME_Price_Increase_Type_Product_Sales__c = 'Other';
        AddendumExtContract.IME_Index_Product_Sales__c = 'Product sales';
        AddendumExtContract.IME_Capped_Percentage_Product_Sales__c = 60;
        AddendumExtContract.IME_End_of_Fixed_Pricing_Period_Prod_S__c = system.today().addMonths(2);
        AddendumExtContract.IME_Special_Terms_Other_Prod_S__c ='Special terms other test';
        AddendumExtContract.StartDate = System.today().addmonths(1);
        AddendumExtContract.IME_Contract_Term_Type__c ='Evergreen';
        AddendumExtContract.ContractTerm = 12;
        AddendumExtContract.IM_Renewal_Term__c = 12;
        AddendumExtContract.IME_Liability_Currency__c = 'GBP';
        AddendumExtContract.IME_Annual_Value_Opportunities__c = 0;
        AddendumExtContract.Status = 'Activated'; 
        AddendumExtContract.IME_Copy_to_all__c = false;

        updateContracts.add(AddendumExtContract); 
       
        update updateContracts;
        Test.startTest();
       
        List<contract> parent = new List<contract>();
        parent.add(parentContract);
        contractTotalAnnualAmount cnt = new contractTotalAnnualAmount();
        contractTotalAnnualAmount.runOnce();
        cnt.UpdateTotalAnnualValue(parent);
        
        Test.stopTest();

    }
    
    
    
    
}