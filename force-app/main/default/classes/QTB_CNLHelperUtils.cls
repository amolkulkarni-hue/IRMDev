/*****************************************************************************************************
* Class         : QTB_CNLHelperUtils
* Test Class    : QTB_CNLHelperUtils_Test
* Functionality : QTB/Billing only implementation 
* Author        : Virtusa/TCS
* Purpose       : Utilize this class for writing methods related to Credit Note Line
* Change History: 06/16/2023
* Developer         Date           Description
* -----------------------------------------------------------------------------------------------------
* Karthik TCS     06/02/2023    Gitlab US #16075 On Account Credit note scenario for Billing only countries
* Parth           12/20/2023    Gitlab #20433 Tax Rounding Enhancement
* Parth           16/07/2024    Gitlab #25043 populate translated UOM value on cnl
* Parth           14/09/2024    Gitlab #26202 populate translated Product name and product group on cnl
* Parth           25/09/2024    Gitlab #26218 for onAccount scenario not updating CNL tax override amount for NA countries
* Parth           15/11/2024    Gitlab #27493 update taxDate on credit not based on credit note line invoice reference
*******************************************************************************************************/
public class QTB_CNLHelperUtils {
    private static final String CLASSNAME = QTB_CreditNoteHelperUtils.class.getName();
    public static Map<String, List<blng__TaxRate__c>> taxRatesMaps = new Map<String, List<blng__TaxRate__c>>();
    public static List<blng__CreditNoteLine__c>cnlListBasedOnAccount; //this will store all cnl fields values which are used to update translation fields
    /***********************************************************************************************************
* Method : validateProductForBillingCountries
* Parameters: List<blng__CreditNoteLine__c>,Set<Id> productIds
* Description : Validate the selected product's entry in corresponding pricebook (On Account scenario for Billing countries)
* Return Type : void
* Requirement : GitLab #15977
**************************************************************************************************************/
    public static void validateProductForBillingCountries(List<blng__CreditNoteLine__c> newItems,Set<Id> cnlProductIds,Set<String> cnlCountries,Set<String> cnlCurrencies){
        try{
            if(QTB_CNLTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            Set<String> countryCurrencyProductSet  = new Set<String>();
            Map<Id,String> productIdHSNCodeMap = new Map<Id,String>();
            // #21956 Created Map with ProductId and boolean to Store respective Isservice flag
            Map<Id,Boolean> productIdIserviceFlagMap = new Map<Id,Boolean>();
            //Build a set, add "country+currency+productId"
            // Added #21956 QTB_Is_Service__c for Copying the value to ON Credit Note Isservice flag
            for (Pricebookentry entry : [SELECT id,pricebook2.QTB_country__c,currencyIsoCode,Product2Id,ProductCode,Name,QTB_HSN_Code__c,QTB_Is_Service__c 
                                         FROM Pricebookentry WHERE product2Id in :cnlProductIds AND isActive=true 
                                         AND pricebook2.QTB_country__c in :cnlCountries AND CurrencyIsoCode in :cnlCurrencies])
            {
                countryCurrencyProductSet.add(entry.pricebook2.QTB_country__c+entry.CurrencyIsoCode+entry.Product2Id);                 
                //GITLAB #18068 Checking HSN code field is Empty or Not
                //#21956 Put values of productId and respective IsService flag boolean value in newly created Map
                if(entry.QTB_HSN_Code__c != Null){
                    productIdHSNCodeMap.put(entry.Product2Id,entry.QTB_HSN_Code__c);
                    productIdIserviceFlagMap.put(entry.Product2Id,entry.QTB_Is_Service__c);
                }
            }
            //Iterating over new credit note line records
            for(blng__CreditNoteLine__c cnl : newItems){
                //if there are no entries present for a product in any pricebook
                //when entry is present, but not in CreditNote's country pricebook with the same account currency
                if(!countryCurrencyProductSet.contains(cnl.QTB_country__c+cnl.CurrencyIsoCode+cnl.blng__Product__c) && !Test.isRunningTest()){
                    cnl.addError('['+cnl.QTB_Product_Name__c+']: '+system.label.QTB_OnAccountCreditNoteLineProductValidationBlngOnly);
                }
                //GITLAB #18068 Assigning the HSN code from Price Book Entry HSN code Value and checking Null check 
                if(productIdHSNCodeMap!= Null && productIdHSNCodeMap.containskey(cnl.blng__Product__c)){
                    cnl.QTB_HSN_Code__c = productIdHSNCodeMap.get(cnl.blng__Product__c);
                }
                //GITLAB #21956 Assigning Is Service flag from Price Book Entry Is service Flag Value and checking Null check
                if(productIdIserviceFlagMap!= Null && productIdIserviceFlagMap.containskey(cnl.blng__Product__c)){
                    cnl.QTB_Is_Service__c = productIdIserviceFlagMap.get(cnl.blng__Product__c);
                }
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'validateProductForBillingCountries');
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method : updateTaxInfoForOnAccountCreditNote
* Parameters: List<blng__CreditNoteLine__c>,Set<CreditNotelineAccountIds>
* Return Type : void
* Description : This method is helpful for Updating Tax rule and tax treatment for CreditNote line (On Account Ctredit scenario for Billing countries)
* Requirement : GitLab#16314, Git #16315 ,Git #16316
**************************************************************************************************************/
    public static void updateTaxInfoForOnAccountCreditNote(List<blng__CreditNoteLine__c> newItems,Set<Id>cnlAccountIds,Set<Id> cnlProductIds)
    {
        try{
            if(QTB_CNLTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            
            List<OrderItem> ordItemList = New List<OrderItem>();
            Map<Id,Account> accountLegalEntityMap = New Map<Id,Account>();
            Map<Id,OrderItem> accOrderItemMap = new Map<Id,OrderItem>();
            Map<Id,Pricebookentry> productMap=new Map<Id,Pricebookentry>();
            Boolean isSITAD = false;
            Boolean isNotSITAD = false;
            Set<Id> taxRuleIdSet = new Set<Id>();
            Map<String,Id> taxRuleLegalEntityWithTaxTreatmentMap = new Map<String,Id>();
            Map<String, blng__TaxTreatment__c> taxTreamentMap = new Map<String, blng__TaxTreatment__c>();//US#30156 changes.

            for(blng__CreditNoteLine__c cnlNew:newItems){
                if(cnlNew.QTB_SITAD__c){
                    isSITAD = true;
                }else{
                    isNotSITAD=true;
                }
            }
            //US#30156 changes.
            Set<ID> entityID = new Set<ID>();
            Set<String> accLegalEntityCountry = new Set<String>();
            Set<String> accSplTaxCondition = new Set<String>();
            Set<Id> fmvTaxableList = new Set<Id>();
            //Assuming dataload is never done together for 'SITAD' and 'billing only countries'
            if(isSITAD){
                //for SITAD querying single record
                for(Account ac :[SELECT Id,QTB_Contract_Entity__c,SBQQ__TaxExempt__c,QTB_Special_Tax_Condition__c,QTB_Legal_Entity_Country__c,QTB_Contract_Entity__r.Is_FMV_Taxable__c FROM Account WHERE Id IN : cnlAccountIds AND QTB_SITAD__c=true]){
                    if(!accountLegalEntityMap.containsKey(ac.Id)){
                        accountLegalEntityMap.put(ac.Id, ac);
                    }
                    //US#30156 changes.
                    if(ac.QTB_Contract_Entity__r.Is_FMV_Taxable__c){
                        entityID.add(ac.QTB_Contract_Entity__c);
                        accLegalEntityCountry.add(ac.QTB_Legal_Entity_Country__c);
                        accSplTaxCondition.add(ac.QTB_Special_Tax_Condition__c);
                        fmvTaxableList.add(ac.QTB_Contract_Entity__c);
                    }
                } 
                System.debug('accountLegalEntityMap@@'+accountLegalEntityMap);

                if(entityID.size()>0){
                for(blng__TaxTreatment__c  treatmentRec : [select id,QTB_Special_Tax_Condition__c,QTB_TaxCountry__c,QTB_Taxable__c, blng__TaxLegalEntity__c,blng__taxRule__c,blng__TaxLegalEntity__r.blng__Country__c,
                                                                    blng__TaxLegalEntity__r.id from blng__TaxTreatment__c where
                                                                    blng__TaxLegalEntity__c IN:entityID and blng__TaxLegalEntity__r.blng__Country__c IN:accLegalEntityCountry
                                                                    and QTB_Special_Tax_Condition__c IN:accSplTaxCondition
                                                                    ]){
                    taxTreamentMap.put(treatmentRec.blng__TaxLegalEntity__c+'_'+treatmentRec.QTB_TaxCountry__c+'_'+treatmentRec.QTB_Taxable__c+'_'+treatmentRec.QTB_Special_Tax_Condition__c,treatmentRec);
               
                                                                    }
                }
                //US#30156 changes ends here.
                
                //building a product map(key=id,value=product2) with tax rule and billing rule
                //GITLAB #20519 - As per of the US commented out Product2.Name='Fair Market Value'
                for(Pricebookentry pr :[SELECT Pricebook2.QTB_Country__c, Product2.Name, product2Id,Product2.blng__TaxRule__c,Product2.blng__BillingRule__c FROM Pricebookentry WHERE Product2Id IN :cnlProductIds /*and Product2.Name='Fair Market Value' */ and IsActive=true]){
                    if(!productMap.containskey(pr.product2Id)){
                        productMap.put(pr.product2Id,pr);
                        taxRuleIdSet.add(pr.product2.blng__TaxRule__c);
                    }
                } 
                
                //Defect fix US#16545 -- to populate TaxTreatment on CreditNoteLine, fetching the taxTreatment based on Product's TaxRules
                if(!taxRuleIdSet.isEmpty()){
                    for(blng__TaxTreatment__c taxTreatment : [SELECT Id,Name,blng__TaxRule__c,blng__TaxLegalEntity__c
                            FROM blng__TaxTreatment__c WHERE blng__TaxRule__c IN : taxRuleIdSet ])
                    {
                        taxRuleLegalEntityWithTaxTreatmentMap.put(taxTreatment.blng__TaxRule__c+'_'+taxTreatment.blng__TaxLegalEntity__c,taxTreatment.Id);                        
                    } 
                    System.debug('taxRuleLegalEntityWithTaxTreatmentMap@@'+taxRuleLegalEntityWithTaxTreatmentMap);
                }
            }
            if(isNotSITAD)
            { 
                // Querying Order Item details based upon CreditNote Line AccountIds,ProductIds
                ordItemList = [SELECT id,blng__TaxCountry__c,blng__TaxRule__c,blng__BillingRule__c,blng__LegalEntity__c,order.AccountId,blng__TaxTreatment__c FROM OrderItem 
                               WHERE order.AccountId IN : cnlAccountIds AND Product2ID IN :cnlProductIds 
                               AND order.QTB_OrderCategory__c = 'Evergreen' AND Order.Account.QTB_SITAD__c=false Order BY createddate ASC LIMIT 50000];
                if(!ordItemList.IsEmpty())
                {
                    for(OrderItem ordItem : ordItemList)
                    {
                        if(!accOrderItemMap.containskey(ordItem.order.AccountId)){
                            accOrderItemMap.put(ordItem.order.AccountId, ordItem);
                        }
                    }
                }
            }
            ordItemList.clear();
            if(!accOrderItemMap.isEmpty() || !productMap.isEmpty() || !taxTreamentMap.isEmpty()){
                //Iterating the NewList of Cnlines
                for(blng__CreditNoteLine__c cnl : newItems)
                {
                    if(cnl.QTB_SITAD__c){
                        //US#30156 changes.
                        if(fmvTaxableList.contains(accountLegalEntityMap.get(cnl.QTB_Billing_Account__c).QTB_Contract_Entity__c)){
                            String taxable = '';
                            cnl.blng__LegalEntity__c= accountLegalEntityMap.get(cnl.QTB_Billing_Account__c).QTB_Contract_Entity__c;
                            Account acct = accountLegalEntityMap.get(cnl.QTB_Billing_Account__c);
                            if(acct.SBQQ__TaxExempt__c != null && acct.SBQQ__TaxExempt__c == 'No'){
                                taxable = 'Yes';
                                cnl.blng__CalculateTax__c= true;
                                cnl.blng__EffectiveTaxDate__c= system.today();
                            }
                            else{
                                taxable = 'No';
                            }
                            blng__TaxTreatment__c taxTreatment = new blng__TaxTreatment__c();
                            taxTreatment = taxTreamentMap.get(acct.QTB_Contract_Entity__c+'_'+acct.QTB_Legal_Entity_Country__c+'_'+taxable+'_'+acct.QTB_Special_Tax_Condition__c);
                            if(taxTreatment != null){
                            cnl.blng__TaxTreatment__c = taxTreatment.id;
                            cnl.blng__TaxRule__c =   taxTreatment.blng__TaxRule__c;                                       
                            }
                            cnl.blng__TaxCountry__c = accountLegalEntityMap.get(cnl.QTB_Billing_Account__c).QTB_Legal_Entity_Country__c;
                           
                        }else{

                        if(productMap.containsKey(cnl.blng__Product__c) && accountLegalEntityMap.containsKey(cnl.QTB_Billing_Account__c))
                        {
                            System.debug('accountLegalEntityMap.get(cnl.accountLegalEntityMap).QTB_Contract_Entity__c@@'+accountLegalEntityMap.get(cnl.QTB_Billing_Account__c).QTB_Contract_Entity__c);
                            //Assigning the Tax info to Credit Note line before Insertion to data base
                            cnl.blng__LegalEntity__c= accountLegalEntityMap.get(cnl.QTB_Billing_Account__c).QTB_Contract_Entity__c;
                            cnl.blng__TaxRule__c = productMap.get(cnl.blng__Product__c).Product2.blng__TaxRule__c;                                                    
                            cnl.blng__BillingRule__c = productMap.get(cnl.blng__Product__c).Product2.blng__BillingRule__c;  
                            //Defect fix #16545
                            if(!taxRuleLegalEntityWithTaxTreatmentMap.isEmpty() && taxRuleLegalEntityWithTaxTreatmentMap.containsKey(cnl.blng__TaxRule__c +'_'+cnl.blng__LegalEntity__c))
                            {
                                cnl.blng__TaxTreatment__c = taxRuleLegalEntityWithTaxTreatmentMap.get(cnl.blng__TaxRule__c +'_'+cnl.blng__LegalEntity__c);
                            }
                            cnl.blng__TaxCountry__c = accountLegalEntityMap.get(cnl.QTB_Billing_Account__c).QTB_Legal_Entity_Country__c;
                        } 
                        }
                    }
                    else{
                        if(accOrderItemMap.containsKey(cnl.QTB_Account__c))
                        {
                            //Assigning the Tax info to Credit Note line before Insertion to data base
                            cnl.blng__TaxRule__c = accOrderItemMap.get(cnl.QTB_Account__c).blng__TaxRule__c;
                            cnl.blng__BillingRule__c = accOrderItemMap.get(cnl.QTB_Account__c).blng__BillingRule__c;
                            cnl.blng__TaxCountry__c = accOrderItemMap.get(cnl.QTB_Account__c).blng__TaxCountry__c;
                            cnl.blng__LegalEntity__c=accOrderItemMap.get(cnl.QTB_Account__c).blng__LegalEntity__c;
                            cnl.blng__TaxTreatment__c =accOrderItemMap.get(cnl.QTB_Account__c).blng__TaxTreatment__c;
                        }
                    }                    
                }
            }            
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'updateTaxInfoForOnAccountCreditNote');
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method : taxRoundingOnCreditNote
* Parameters: Set<Id> cnlWithInvoiceRefForTaxRounding
* Description : This method will update the tax overrid amount on credit note or CNL based on legal entity Tax Type
* Return Type : void
* Requirement : Gitlab #20433 Tax Rounding Enhancement
**************************************************************************************************************/
    public static void taxRoundingOnCreditNote(Set<Id> cnWithInvoiceRefForTaxRounding){
        try{
            if(QTB_CNLTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            Map<Id,blng__creditNote__c> creditNoteTaxOverrideAmountUpdateMap = new Map<Id,blng__creditNote__c>();
            list<blng__CreditNoteLine__c>cnlTaxOverRideAmtLst = new list<blng__CreditNoteLine__c>();
            for(blng__CreditNoteLine__c cnl :[Select id,QTB_Tax_Override_Amount__c,blng__CreditNote__r.blng__Subtotal__c,QTB_Invoice__r.blng__Subtotal__c,blng__TaxPercentageApplied__c,
                                              QTB_InvoiceLine__r.blng__Subtotal__c,blng__InvoiceLine__r.QTB_Tax_Override_Amount__c,QTB_Invoice__c,QTB_InvoiceLine__c,blng__Subtotal__c,QTB_InvoiceLine__r.QTB_Tax_Override_Amount__c,
                                              blng__CreditNote__c,blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,QTB_Invoice__r.QTB_Tax_Override_Amount__c from blng__CreditNoteLine__c 
                                              where blng__CreditNote__c in :cnWithInvoiceRefForTaxRounding])
            {
                blng__creditNote__c crdtNt = new blng__creditNote__c();
                //Logic to calculate tax override for Flat Rate(updation will be on CN)
                if( cnl.blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_TYPE_FLAT &&
                   !creditNoteTaxOverrideAmountUpdateMap.containsKey(cnl.blng__CreditNote__c) )
                {
                    // checking if CN subtotal = invoice subtotal or not and updating tax override amount accordingly on CN
                    // full credit scenario
                    if(cnl.blng__CreditNote__r.blng__Subtotal__c == cnl.QTB_Invoice__r.blng__Subtotal__c)
                    {
                        crdtNt.Id = cnl.blng__CreditNote__c;
                        crdtNt.QTB_Tax_Override_Amount__c = cnl.QTB_Invoice__r.QTB_Tax_Override_Amount__c;
                        crdtNt.QTB_Total_Tax_Rate__c = cnl.blng__TaxPercentageApplied__c;
                        creditNoteTaxOverrideAmountUpdateMap.put(crdtNt.Id,crdtNt);
                    }
                    //partial credit scenario
                    else if(cnl.blng__CreditNote__r.blng__Subtotal__c != cnl.QTB_Invoice__r.blng__Subtotal__c &&
                            cnl.QTB_Invoice__r.QTB_Tax_Override_Amount__c != null && cnl.blng__CreditNote__r.blng__Subtotal__c != null &&
                            cnl.QTB_Invoice__r.blng__Subtotal__c != null && cnl.QTB_Invoice__r.blng__Subtotal__c !=0)
                    {
                        crdtNt.Id = cnl.blng__CreditNote__c;
                        crdtNt.QTB_Total_Tax_Rate__c = cnl.blng__TaxPercentageApplied__c;
                        crdtNt.QTB_Tax_Override_Amount__c = (cnl.QTB_Invoice__r.QTB_Tax_Override_Amount__c *(cnl.blng__CreditNote__r.blng__Subtotal__c/cnl.QTB_Invoice__r.blng__Subtotal__c)).setScale(2, System.RoundingMode.HALF_UP);
                        creditNoteTaxOverrideAmountUpdateMap.put(crdtNt.Id,crdtNt);
                    }
                    
                }
                //Logic to calculate tax override for Product Based(updaion will be on CNL)
                else if(cnl.blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_PRODUCT_BASED)
                {
                    //full credit scenario
                    if(cnl.blng__Subtotal__c == cnl.QTB_InvoiceLine__r.blng__Subtotal__c && cnl.QTB_InvoiceLine__r.QTB_Tax_Override_Amount__c != null)
                    {
                        cnl.QTB_Tax_Override_Amount__c = cnl.QTB_InvoiceLine__r.QTB_Tax_Override_Amount__c;
                        //28097 Assigning Totao tax Rate for Product based as same as Flat Rate
                            crdtNt.QTB_Total_Tax_Rate__c = cnl.blng__TaxPercentageApplied__c;
                        // calculation to update tax override amount on CN for product based
                        if(creditNoteTaxOverrideAmountUpdateMap.containsKey(cnl.blng__CreditNote__c)){
                            decimal tempTaxOverrideAmount = creditNoteTaxOverrideAmountUpdateMap.get(cnl.blng__CreditNote__c).QTB_Tax_Override_Amount__c;
                            crdtNt.Id = cnl.blng__CreditNote__c;
                            crdtNt.QTB_Tax_Override_Amount__c = tempTaxOverrideAmount + cnl.QTB_Tax_Override_Amount__c;
                            creditNoteTaxOverrideAmountUpdateMap.put(cnl.blng__CreditNote__c,crdtNt);
                            
                        }
                        else{
                            crdtNt.Id = cnl.blng__CreditNote__c;
                            crdtNt.QTB_Tax_Override_Amount__c = cnl.QTB_Tax_Override_Amount__c;
                            creditNoteTaxOverrideAmountUpdateMap.put(cnl.blng__CreditNote__c,crdtNt);
                        }
                        cnlTaxOverRideAmtLst.add(cnl);
                    }
                    //partial credit scenario
                    else if(cnl.blng__Subtotal__c != cnl.QTB_InvoiceLine__r.blng__Subtotal__c && cnl.QTB_InvoiceLine__r.QTB_Tax_Override_Amount__c != null &&
                            cnl.blng__Subtotal__c!=null && cnl.QTB_InvoiceLine__r.blng__Subtotal__c!=null && cnl.QTB_InvoiceLine__r.blng__Subtotal__c != 0)
                    {
                        cnl.QTB_Tax_Override_Amount__c = (cnl.QTB_InvoiceLine__r.QTB_Tax_Override_Amount__c*(cnl.blng__Subtotal__c/cnl.QTB_InvoiceLine__r.blng__Subtotal__c)).setScale(2, System.RoundingMode.HALF_UP);
                        //28097 Assigning Totao tax Rate for Product based as same as Flat Rate
                            crdtNt.QTB_Total_Tax_Rate__c = cnl.blng__TaxPercentageApplied__c;
                        // calculation to update tax override amount on CN fro product based
                        if(creditNoteTaxOverrideAmountUpdateMap.containsKey(cnl.blng__CreditNote__c)){
                            decimal tempTaxOverrideAmount = creditNoteTaxOverrideAmountUpdateMap.get(cnl.blng__CreditNote__c).QTB_Tax_Override_Amount__c;
                            crdtNt.Id = cnl.blng__CreditNote__c;
                            crdtNt.QTB_Tax_Override_Amount__c = tempTaxOverrideAmount + cnl.QTB_Tax_Override_Amount__c;
                            creditNoteTaxOverrideAmountUpdateMap.put(cnl.blng__CreditNote__c,crdtNt);
                        }
                        else{
                            crdtNt.Id = cnl.blng__CreditNote__c;
                            crdtNt.QTB_Tax_Override_Amount__c = cnl.QTB_Tax_Override_Amount__c;
                            creditNoteTaxOverrideAmountUpdateMap.put(cnl.blng__CreditNote__c,crdtNt);
                        }
                        cnlTaxOverRideAmtLst.add(cnl);
                    }
                    
                }
            }
            if(!creditNoteTaxOverrideAmountUpdateMap.isEmpty()){
                update creditNoteTaxOverrideAmountUpdateMap.values();
                creditNoteTaxOverrideAmountUpdateMap.clear();
            }
            if(!cnlTaxOverRideAmtLst.isEmpty()){
                QTB_RecursiveHandlerCheck.taxRoundingOnCreditNote = False;
                update cnlTaxOverRideAmtLst;
                cnlTaxOverRideAmtLst.clear();
            }
            
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'taxRoundingOnCreditNote');
            throw e;
        }
    }
    /***********************************************************************************************************
* Method : OnAccountCreditNoteTaxRounding
* Parameters: Set<Id>cnlWithoutInvoiceRefForTaxRounding,Set<String>cnlAddressComparison
* Description : this method will update the tax override amount on CN having onAccount functionality
* Return Type : void
* Requirement : Gitlab #20433 Tax Rounding Enhancement
**************************************************************************************************************/
    public static void OnAccountCreditNoteTaxRounding(Set<Id>cnWithoutInvoiceRefForTaxRounding,Set<String>cnlAddressComparison){
        try{
            if(QTB_CNLTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            
            Map<Id,blng__CreditNote__c> taxUpdateOnCreditNoteMap = new Map<Id,blng__CreditNote__c>();
            List<blng__CreditNoteLine__c> taxUpdateOnCnl = new List<blng__CreditNoteLine__c>();
            // Below method will create the map<string,List<Tax Rate>> key as address compariosn value
            if(!cnlAddressComparison.isEmpty()){
                QTB_InvoiceHelper.buildTaxRateMap(cnlAddressComparison);
                taxRatesMaps = QTB_InvoiceHelper.taxRatesMap;
            }
            if(!cnWithoutInvoiceRefForTaxRounding.isEmpty()){
                for(blng__CreditNoteLine__c cnl :[select id,blng__TaxTreatment__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,blng__TaxTreatment__r.blng__TaxCode__c,blng__LegalEntity__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c,
                                                  blng__CalculateTax__c,blng__Subtotal__c,QTB_Tax_Override_Amount__c,blng__CreditNote__c,blng__CreditNote__r.blng__Subtotal__c,blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
                                                  blng__CreditNote__r.QTB_On_Account_Credit__c,QTB_Account__r.QTB_Legal_Entity_Country__c,
                                                  blng__TaxPercentageApplied__c,blng__TaxAmount__c from blng__CreditNoteLine__c where blng__CreditNote__c in :cnWithoutInvoiceRefForTaxRounding])
                {
                    blng__CreditNote__c crdtNote = new blng__CreditNote__c();
                    // checking if cnl is of OnAccount credit note 
                    if(cnl.blng__CreditNote__r.QTB_On_Account_Credit__c == true)
                    {
                        // for 'Flat Rate' type cheking any one cnl and picking its tax rate to calculate tax on CN
                        if(cnl.blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_TYPE_FLAT &&
                           !taxUpdateOnCreditNoteMap.containsKey(cnl.blng__CreditNote__c))
                        {
                            //fetching tax rate list based on address comparision and calculating tax for cnl
                            // Commented line 350-352 as part of story 24038 to create address comparison to fetch the tax rate record 
                            String cnlComparison =
                                cnl.blng__TaxCountry__c +'----' +
                                //cnl.blng__TaxState__c +'-' +
                                //cnl.blng__TaxCity__c +'-' +
                                //cnl.blng__TaxZipCode__c +'-' +
                                cnl.blng__TaxTreatment__r.blng__TaxCode__c +'-' +
                                cnl.blng__LegalEntity__c;
                            //remove null from string
                            cnlComparison = cnlComparison.replaceAll('null','');
                            //Fetching only that tax rate where address comparision matches CNL address comparision 
                            if(!taxRatesMaps.isEmpty() && taxRatesMaps.containsKey(cnlComparison))
                            {
                                Map<Id, Decimal> mapOfCnIdTaxOvrd = new Map<Id, Decimal>();
                                //iterating over tax rate rate as on a single cnl there can be multiple tax rate
                                for (blng__TaxRate__c taxRate : taxRatesMaps.get(cnlComparison))
                                {
                                    if(cnl.blng__CreditNote__r.blng__Subtotal__c != null && taxRate.blng__Rate__c != null){                                        
                                        decimal tax = (cnl.blng__CreditNote__r.blng__Subtotal__c *(taxRate.blng__Rate__c / 100)).setScale(2, System.RoundingMode.HALF_UP);
                                        // if there are multiple tax rates found in that case tax override amount on CN will be sum of all the tax rate 
                                        if(!mapOfCnIdTaxOvrd.containsKey(cnl.blng__CreditNote__c))
                                        {
                                            mapOfCnIdTaxOvrd.put(cnl.blng__CreditNote__c,tax);  
                                        }
                                        else
                                        {
                                            decimal taxRoundOff = mapOfCnIdTaxOvrd.get(cnl.blng__CreditNote__c);
                                            mapOfCnIdTaxOvrd.put(cnl.blng__CreditNote__c,tax+taxRoundOff);
                                        }
                                    }
                                }
                                if(mapOfCnIdTaxOvrd.containsKey(cnl.blng__CreditNote__c)){
                                    crdtNote.Id = cnl.blng__CreditNote__c;
                                    crdtNote.QTB_Tax_Override_Amount__c = mapOfCnIdTaxOvrd.get(cnl.blng__CreditNote__c);
                                    crdtNote.QTB_Total_Tax_Rate__c = cnl.blng__TaxPercentageApplied__c;
                                    taxUpdateOnCreditNoteMap.put(cnl.blng__CreditNote__c,crdtNote);
                                }
                            }
                            
                        }
                        // for Product Based type assigning tax override amount on CNL
                        else if(cnl.blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c == QTB_Constants.LEGALENTITY_PRODUCT_BASED && cnl.blng__Subtotal__c != null)
                        {
                            if (Label.QTB_NA_Countries.contains(cnl.QTB_Account__r.QTB_Legal_Entity_Country__c)){
                                //Populate TaxOverride from blng__TaxAmount__c for North America
                                cnl.QTB_Tax_Override_Amount__c = cnl.blng__TaxAmount__c;
                            } 
                            else {
                                if(cnl.blng__TaxPercentageApplied__c != null && cnl.blng__Subtotal__c != null)
                                {
                                    cnl.QTB_Tax_Override_Amount__c = (cnl.blng__TaxPercentageApplied__c *cnl.blng__Subtotal__c*0.01).setScale(2, System.RoundingMode.HALF_UP);                                    
                                }
                            }
                            if(taxUpdateOnCreditNoteMap.containsKey(cnl.blng__CreditNote__c)){
                                if(cnl.QTB_Tax_Override_Amount__c != null){
                                    decimal tempTaxOverrideAmount = taxUpdateOnCreditNoteMap.get(cnl.blng__CreditNote__c).QTB_Tax_Override_Amount__c;
                                    crdtNote.Id = cnl.blng__CreditNote__c;
                                    crdtNote.QTB_Tax_Override_Amount__c = tempTaxOverrideAmount + cnl.QTB_Tax_Override_Amount__c;
                                    //#28097 Assigning Total Tax rate value from CNL for On Account credit same like Flat Rate
                                    crdtNote.QTB_Total_Tax_Rate__c = cnl.blng__TaxPercentageApplied__c;
                                    taxUpdateOnCreditNoteMap.put(cnl.blng__CreditNote__c,crdtNote);
                                }
                            }
                            else{
                                if(cnl.QTB_Tax_Override_Amount__c != null){
                                    crdtNote.Id = cnl.blng__CreditNote__c;
                                    crdtNote.QTB_Tax_Override_Amount__c = cnl.QTB_Tax_Override_Amount__c;
                                    //#28097 Assigning Total Tax rate value from CNL for On Account credit same like Flat Rate
                                    crdtNote.QTB_Total_Tax_Rate__c = cnl.blng__TaxPercentageApplied__c;
                                    taxUpdateOnCreditNoteMap.put(cnl.blng__CreditNote__c,crdtNote);
                                }
                            }
                                taxUpdateOnCnl.add(cnl);
                            }
                    }
                    
                }
            }
            if(!taxUpdateOnCreditNoteMap.isEmpty()){
                update taxUpdateOnCreditNoteMap.values();
                taxUpdateOnCreditNoteMap.clear();
            }
            if(!taxUpdateOnCnl.isEmpty()){
                QTB_RecursiveHandlerCheck.OnAccountCreditNoteTaxRounding = False;
                update taxUpdateOnCnl;
                taxUpdateOnCnl.clear();
            }
            
            
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'OnAccountCreditNoteTaxRounding');
            throw e;
        }
    }
    /***********************************************************************************************************
* Method     : setTranslationFieldsOnCNL
* Parameters : List<blng__CreditNoteLine__c> cnlUOM, List<account>accList
* Requirement: Gitlab #25043 populate translated UOM value on cnl, #26202 update translated Product name and product group
* Author     : Virtusa
* Description: based on cnl list or account list calling different methods to update translated fields
**************************************************************************************************************/   
    public static void setTranslationFieldsOnCNL(List<blng__CreditNoteLine__c> cnlForTranslation, List<account>accList) {
        system.debug('Inside CNLHelperUtils setTranslationFieldsOnCNL method ');
        try{
            if( QTB_CNLTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(cnlForTranslation != null && !cnlForTranslation.isEmpty()){
                updateUOMOnCNL(cnlForTranslation); //Gitlab #25043 populate translated UOM value on cnl
                updateTranslatedProductGroup(cnlForTranslation,'BEFORE_INSERT'); //Gitlab #26202 populate translated price schedule category
            }
            //When After_Update is triggered from Account helper when language is changed then iterating on list of Account ids and getting the cnl 
            //(updating only that cnl where cn QTB_Transferred_to_Invoice_Compliance__c and QTB_transfered_to_invoice_presentment__c is blank and excluding cancelled CN)
            else if(!accList.isEmpty()){
                cnlListBasedOnAccount = [SELECT id,blng__Product__c,QTB_Price_Schedule_Category__c,QTB_Translated_UOM__c,QTB_AccountLanguage__c, QTB_UOM__c,
                                        QTB_Translated_Product_Group__c,QTB_Localized_Product_Name__c , blng__TaxCountry__c
                                        FROM blng__CreditNoteLine__c WHERE blng__CreditNote__r.blng__Account__c in :accList 
                                        AND blng__CreditNote__r.QTB_Transferred_to_Invoice_Compliance__c = null AND blng__CreditNote__r.QTB_transfered_to_invoice_presentment__c = null  
                                        AND blng__CreditNote__r.blng__Status__c != 'Cancelled'];
                updateUOMOnCNL(cnlListBasedOnAccount); //Gitlab #25043 populate translated UOM value on cnl
                updateTranslatedProductGroup(cnlListBasedOnAccount,'AFTER_UPDATE'); //Gitlab #26202 populate translated price schedule category
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'setUOMcodeTranslationOnCNL');
            throw e;
        }
    }
    /***********************************************************************************************************
* Method     : setProductNameTranslation
* Parameters : List<blng__CreditNoteLine__c> cnlUOM, List<account>accList
* Requirement: Gitlab #26202 populate translated UOM value on cnl, #26202 update translated Product name and product group
* Author     : Virtusa
* Description: based on cnl list or account list calling different methods to update translated fields
**************************************************************************************************************/   
    public static void setProductNameTranslation(List<blng__CreditNoteLine__c> productNameTranslation, List<account>accList) {
        system.debug('Inside CNLHelperUtils setProductNameTranslation method ');
        try{
            if( QTB_CNLTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(productNameTranslation != null && !productNameTranslation.isEmpty()){
                updateLocalisedProductName(productNameTranslation,'BEFORE_INSERT'); //Gitlab #26202 populate translated product name on cnl
            }
            //When After_Update is triggered from Account helper when language is changed then iterating on list of Account ids and getting the cnl 
            //(updating only that cnl where cn QTB_Transferred_to_Invoice_Compliance__c and QTB_transfered_to_invoice_presentment__c is blank and excluding cancelled CN)
            else if(!accList.isEmpty()){
                List<blng__CreditNoteLine__c>productNameTranslationLst = [select id,blng__Product__c,QTB_AccountLanguage__c,QTB_Localized_Product_Name__c 
                                                                       from blng__CreditNoteLine__c where blng__CreditNote__r.blng__Account__c in :accList 
                                                                       and blng__CreditNote__r.QTB_Transferred_to_Invoice_Compliance__c = null 
                                                                       and blng__CreditNote__r.QTB_transfered_to_invoice_presentment__c = null and 
                                                                       blng__CreditNote__r.blng__Status__c != 'Cancelled'];
                updateLocalisedProductName(productNameTranslationLst,'AFTER_UPDATE'); //Gitlab #26202 populate translated product name on cnl
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'setProductNameTranslation');
            throw e;
        }
    }
    /***********************************************************************************************************
* Method     : updateUOMOnCNL
* Parameters : List<blng__CreditNoteLine__c> cnlUOM
* Requirement: Gitlab #25043 populate translated UOM value on cnl
* Author     : Virtusa
* Description: setting Translated value for UOM 
**************************************************************************************************************/   
    public static void updateUOMOnCNL(List<blng__CreditNoteLine__c> cnlUOM){
        try{
        if(QTB_CNLTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            Set<string> uomValue;
            Set<string> accLangValue;
            if(!cnlUOM.isEmpty()){
                uomValue = new set<string>();
                accLangValue = new set<string>();
                for(blng__CreditNoteLine__c cnl : cnlUOM){
                    uomValue.add(cnl.QTB_UOM__c);
                    accLangValue.add(cnl.QTB_AccountLanguage__c);
                }
                //query QTB_UOM_Code_Translation__mdt records for translating UOM based on account language
                Map<String,QTB_UOM_Code_Translation__mdt> UOMtranslationMap = new Map<String,QTB_UOM_Code_Translation__mdt>();
                if(!uomValue.isEmpty() && !accLangValue.isEmpty()){
                    //Create a Map of QTB_UOM_Code_Translation__mdt, key as combination of QTB_UOM__c and QTB_Language__c
                    for(QTB_UOM_Code_Translation__mdt transUOMcode :[select id, QTB_UOM__c, QTB_Language__c, QTB_Translated_Value__c from QTB_UOM_Code_Translation__mdt where QTB_UOM__c in:uomValue and QTB_Language__c in:accLangValue ]){
                        UOMtranslationMap.put((transUOMcode.QTB_UOM__c+transUOMcode.QTB_Language__c).toLowerCase(),transUOMcode);
                    }
                    uomValue.clear();
                    accLangValue.clear();
                }
                //Iterating on list of cnl
                for(blng__CreditNoteLine__c cnl : cnlUOM){ 
                    /*if(uomTranslationMap.containsKey((cnl.QTB_UOM__c+cnl.QTB_AccountLanguage__c).toLowerCase())){
                        // updating translated value based on metadata records
                        cnl.QTB_Translated_UOM__c = uomTranslationMap.get((cnl.QTB_UOM__c+cnl.QTB_AccountLanguage__c).toLowerCase()).QTB_Translated_Value__c;
                    }else{
						// GITLAB US #27530 - Update FuelSurcharge UOM to WOrk Order for All UOM Country, //GITLAB US #30937 Checking IF the counrties name matches with UOM country list
						if(countryList!=null && !countryList.isEmpty() && countryList.contains(cnl.blng__TaxCountry__c) && cnl.QTB_Product_Name__c == 'Fuel Surcharge'){
							cnl.QTB_Translated_UOM__c = 'Work Order';
						}else{
                            System.debug('cnl.QTB_UOM__c@@' +cnl.QTB_UOM__c);
                            cnl.QTB_Translated_UOM__c = cnl.QTB_UOM__c; // if metadata record is not present then updating the same value present in UOM field
                        } 
                    }*/
                    ////GITLAB US #30937  optimized and added SystemLabel check
                    String key = (cnl.QTB_UOM__c + cnl.QTB_AccountLanguage__c).toLowerCase();
                    cnl.QTB_Translated_UOM__c = uomTranslationMap.containsKey(key)
                                                ? uomTranslationMap.get(key).QTB_Translated_Value__c
                                                : (String.isNotBlank(System.label.QTB_FuelSurWorkOrderCountries) && (cnl.blng__TaxCountry__c!=null) && System.label.QTB_FuelSurWorkOrderCountries.containsIgnoreCase(cnl.blng__TaxCountry__c) && (cnl?.QTB_Product_Name__c == 'Fuel Surcharge'))
                                                    ? 'Work Order' : cnl.QTB_UOM__c;  
                }
                uomTranslationMap.clear();
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'updateUOMOnCNL');
            throw e;
        }
    }
    /***********************************************************************************************************
* Method        : updateTranslatedProductGroup
* Parameters    : List<blng__CreditNoteLine__c>cnlLst, String operationType
* Return type   : void
* Requirement   : Gitlab US #26202 update translated product name and product group
* Description   : Setting QTB_Localized_Product_Name__c to the translated value defined at Product localisation
**************************************************************************************************************/
    public static void updateTranslatedProductGroup(List<blng__CreditNoteLine__c>cnlLst, String operationType){
        system.debug('Inside updateTranslatedProductGroup method ');
        Set<String> priceScheduleCategoryValues;
        set<string> accLan;
        try{
            if(QTB_CNLTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(!cnlLst.isEmpty()){
                priceScheduleCategoryValues = new set<String>();
                accLan = new set<string>();
                for(blng__CreditNoteLine__c cnl : cnlLst){
                    priceScheduleCategoryValues.add(cnl.QTB_Price_Schedule_Category__c);
                    accLan.add(cnl.QTB_AccountLanguage__c);
                }
                //query QTB_translatedProductGroup__mdt records for converting productgroup name based on account language
                map<String,QTB_translatedProductGroup__mdt> translationMap;
                if(!priceScheduleCategoryValues.isEmpty() && !accLan.isEmpty())
                {
                    translationMap = new map<String,QTB_translatedProductGroup__mdt>();
                    //Create a Map of QTB_translatedProductGroup__mdt, key as combination of QTB_Price_Schedule_Category__c and language
                    for(QTB_translatedProductGroup__mdt transProdGrp :[Select id,QTB_Price_Schedule_Category__c,QTB_Translated_Value__c,QTB_Language_Code__c from QTB_translatedProductGroup__mdt where
                                                                       QTB_Language_Code__c in :accLan and QTB_Price_Schedule_Category__c in :priceScheduleCategoryValues]){
                                                                           translationMap.put(transProdGrp.QTB_Price_Schedule_Category__c+transProdGrp.QTB_Language_Code__c.toLowerCase(),transProdGrp);
                                                                       }
                }
                priceScheduleCategoryValues.clear();
                accLan.clear();
                //Iterating on list of cnl received
                for(blng__CreditNoteLine__c cnl : cnlLst)
                { 
                    //if translated value is present in metadta then update the field else keep it same as of price schedule category
                    if(cnl.QTB_Price_Schedule_Category__c != null && cnl.QTB_AccountLanguage__c != null && translationMap.containsKey(cnl.QTB_Price_Schedule_Category__c+cnl.QTB_AccountLanguage__c.toLowerCase()))
                    {
                        cnl.QTB_Translated_Product_Group__c = translationMap.get(cnl.QTB_Price_Schedule_Category__c+cnl.QTB_AccountLanguage__c.toLowerCase()).QTB_Translated_Value__c;  
                    }
                    else{
                        cnl.QTB_Translated_Product_Group__c = cnl.QTB_Price_Schedule_Category__c;
                    }
                }
                translationMap.clear();
                // when account language is chanegd,method gets called from accountHelper class in after update event 
                if(OperationType == 'AFTER_UPDATE'){
                    update cnlLst;
                }
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'updateTranslatedProductGroup');
            throw e;
        }    
        
    }
    /***********************************************************************************************************
* Method        : updateLocalisedProductName
* Parameters    : List<blng__CreditNoteLine__c>cnlLst
* Return type   : void
* Requirement   : Gitlab US #26202
* Description   : updating QTB_Localized_Product_Name__c to the translated value defined at Product localisation
**************************************************************************************************************/
    public static void updateLocalisedProductName(List<blng__CreditNoteLine__c>cnlLst,String operationType){
        system.debug('Inside updateLocalisedProductName method cnlHelperUtils');
        Set<Id> product2Ids;
        set<string> accLan;
        try{
            if(QTB_CNLTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(!cnlLst.isEmpty()){
                product2Ids = new set<Id>();
                accLan = new set<string>();
                for(blng__CreditNoteLine__c cnl : cnlLst){
                    product2Ids.add(cnl.blng__Product__c);
                    accLan.add(cnl.QTB_AccountLanguage__c);
                }
                map<String,string> maplocalization;
                if(!product2Ids.isEmpty() && !accLan.isEmpty())
                {
                    maplocalization = new map<String,string>();
                    //Create a Map as key productId and value being -> Translated value of that Product Name
                    for(SBQQ__Localization__c loc:[select SBQQ__Text__c,SBQQ__Product__c,SBQQ__Language__c 
                                                   from SBQQ__Localization__c 
                                                   Where SBQQ__Product__c IN: product2Ids and SBQQ__Language__c IN: accLan and  SBQQ__APIName__c = 'Name']){
                                                       maplocalization.put(loc.SBQQ__Product__c+loc.SBQQ__Language__c.toLowerCase(),loc.SBQQ__Text__c);
                                                   }
                }
                product2Ids.clear();
                accLan.clear();
                //Iterating on list of Order item received
                for(blng__CreditNoteLine__c cnl : cnlLst)
                { 
                    //if translated value is present in metadta then update the field
                    if(cnl.blng__Product__c != null && cnl.QTB_AccountLanguage__c != null && maplocalization.containsKey(cnl.blng__Product__c+cnl.QTB_AccountLanguage__c.toLowerCase()))
                    {
                        cnl.QTB_Localized_Product_Name__c = maplocalization.get(cnl.blng__Product__c+cnl.QTB_AccountLanguage__c.toLowerCase());//Assigning the values defined at Localisation level onto cnl's QTB_Localized_Product_Name__c 
                    }
                }
                maplocalization.clear();
                // when account language is chanegd,method gets called from accountHelper class in after update event 
                if(OperationType == 'AFTER_UPDATE'){
                    update cnlLst;
                }
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'updateLocalisedProductName');
            throw e;
        }    
        
    }
    /***********************************************************************************************************
* Method        : updateTaxDateOnCreditNote
* Parameters    : List<blng__creditNoteLine__c>CrdtNtLineLst
* Return type   : List<blng__creditNote__c>
* Requirement   : Gitlab US #27493
* Description   : updating QTB_TaxDate__c on credit note based on credit note line invoice reference
**************************************************************************************************************/
    public static List<blng__creditNote__c> updateTaxDateOnCreditNote(List<blng__creditNoteLine__c>CrdtNtLineLst){
        system.debug('Inside updateTaxDateOnCreditNote method cnlHelperUtils');
        try{
            if(QTB_CNLTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            //List of Credit Notes to update
            List<blng__creditNote__c> cnTaxDateUpdate = new List<blng__creditNote__c>();
            if(!CrdtNtLineLst.isEmpty()){
                // Query the Credit Note Lines to get related Invoice Tax Date
                for(blng__CreditNoteLine__c cnl : [Select Id,blng__creditNote__c,QTB_Invoice__r.QTB_TaxDate__c from blng__CreditNoteLine__c 
                                                   Where Id IN :CrdtNtLineLst and QTB_Invoice__r.QTB_TaxDate__c != null]){
                    //adding Credit Note to update list to update tax date
                    cnTaxDateUpdate.add(new blng__creditNote__c(
                        Id = cnl.blng__creditNote__c,
                        QTB_TaxDate__c = cnl.QTB_Invoice__r.QTB_TaxDate__c
                    ));
                }
            }
            return cnTaxDateUpdate;
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'updateTaxDateOnCreditNote');
            throw e;
        }    
        
    }
    
}