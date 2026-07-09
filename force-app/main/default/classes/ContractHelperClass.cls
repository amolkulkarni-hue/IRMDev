public class ContractHelperClass {
    
    public static contract CreateContract(ID recTypeID){
         IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        
        account a = new Account(name='x');
        insert a;  
        
        Contract ContractObj = new Contract(IM_DRCi_Contract_Number__c = '12'
                                 ,AccountId = a.id
                                 ,RecordTypeId =recTypeID                                                             
                                 ,IME_Price_Increase_Type_Storage__c='Other'
                                 ,IME_Special_Terms_Other_Storage__c='Test' 
                                 ,IME_Fixed_Pricing_Period_months_Storage__c=3 
                                 ,IME_End_of_Fixed_Pricing_Period_Storage__c= System.today()
                                 ,Status = 'Draft'             
                                 ,IME_Copy_to_all__c=true 
                                 ,IME_Index_Storage__c='CPI'
                                 ,IME_Capped_Percentage_Storage__c=2 
                                 ,IME_Original_Contract_Start_Date__c=System.today()
                                 ,StartDate=System.today().addmonths(-1)
                                 ,Contract_Signed_Date__c = System.today()+2           
                                 ,ContractTerm=1
                                 ,Billing_Country__c =cntry.id,IME_Other__c = True
                                  ,CurrencyIsoCode='GBP'
                                  ,IME_Annual_Value_Opportunities__c = 10,
                                   IME_MFP_Clause__c = 'No',                                  
                                   IM_Renewal_Term__c=12,
                                   IME_Contract_Term_Type__c='Fixed term');
        
        return ContractObj;
    }
    
    public static Contract_Customer_Account__c CreateContractCustomer(ID ContractID,ID CusID){
        Contract_Customer_Account__c cca = new Contract_Customer_Account__c();
        cca.IME_Customer_Accounts_Id__c = CusID;
        cca.IME_Contract_Id__c = ContractID;  
        return cca;
    }
}