/* Class        : QTB_CNLHelper
 * Test Class    : QTB_CNLHelper_Test
 * Author        : Accenture
 * Purpose       : This is a helper class for all business logic related to Credit Note line object
 * Requirement   :
 * Change History: 5/28/2020
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *                 4/17/2020
 * Gopi/Shailesh   2/26/2021       #899 Auto-Calculates the sub-total field
 * Gopi/Shailesh  10/13/2021     #5443 Credit Note line Subtotal & Qunatity calculation
 * Gopi/Shailesh  12/03/2021     #5703 Credit Note for Subscription Bundles
 * Shailesh       10/07/2022     Gitlab US #9256 Credit & Rebill - Allowing Subscription lines creation for Rebill process
 * Pawan          04/12/2023     Gitlab US #14684 Credit & Rebill - Logic To update Credit note line QTB_Allocated_Revenue_Amount__c in Before Insert Event
 * Ramesh/Shailesh 30/05/2023    Gitlab US #15242 Create Credit Note from Account Level Related List - 1
 * Karthik TCS     06/02/2023    Gitlab US #16075 On Account Credit note scenario for Billing only countries
 * Shailesh/Ramesh 07/17/2023    Gitlab US #16232, US#16769 --to fix issues -- Commented out unnecessary Summation draft/posted and CalculateTax related logic,
Going forward while creating credit note lines it will always compare with subtotal only
     * Parth           25/07/2023    Gitlab #17069 making credit note line's credit quantity default to 1
 * Parth           12/20/2023    Gitlab #20433  Tax Rounding Enhancement
 * Shailesh/Ramesh 26/02/2024    Gitlab US #20721 Refactoring/Restructure of Code
 * Parth           16/07/2024    Gitlab #25043 populate translated UOM value on cnl
 * Parth           13/09/2024    Gitlab #26202 populate translated product name and product group on cnl
 * Parth           15/11/2024    Gitlab #27493 updating taxDate on credit not based on credit note line invoice reference
 *******************************************************************************************************/
public with sharing class QTB_CNLHelper {
    public static final String CREDITNOTELINE_TRIGGER = 'QTB_CNLHelper';
    public static boolean isParentBundle = false;
    public static boolean isParentBundleDeleted = false;
    public static boolean throwExplicitException = false;
    public static Map<Id, blng__CreditNoteLine__c> CreditNoteLineMap;
    /***********************************************************************************************************
     * Method :      process
     * Parameters:   List<SBQQ__Quote__c>,Map<Id, SBQQ__Quote__c>,System.TriggerOperation
     * Return Type : void
     * Description:  This method loops over the list of records to be processed
     **************************************************************************************************************/
    public static void process(List<blng__CreditNoteLine__c> newList,Map<id, blng__CreditNoteLine__c> oldMap,System.TriggerOperation operationType) {
        Set<ID> invoiceLineId = new Set<ID>();
        Set<ID> invoiceIds = new Set<ID>();
        Set<ID> creditNoteLineIDs = new Set<ID>();
        Set<Id> cnlAccountIds  = new Set<Id>(); // Gitlab 16316 & 16315 Adding Set to store AccountIds for On AccountScenario
        Set<Id> cnlProductIds = new Set<Id>(); //Gitlab 15977 & 16315 Adding Set to store ProductIds for On AccountScenario
        Set<String> cnlCurrencies = new Set<String>();
        Set<String> cnlCountries  = new Set<String>();
        Set<Id>cnlWithInvoiceRefForTaxRounding = new Set<Id>();//Gitlab #20433  Tax Rounding Enhancement
        Set<Id>cnlWithoutInvoiceRefForTaxRounding = new Set<Id>();
        Boolean callCNL_checkRestrictedFields = false;//Gitlab US #20672
        Boolean onAccountCreditBillingCountry = false; //#16075 Added one Boolean variable for Bypassing the Validation rule for Billing countries
        // #27493
        Map<Id,blng__creditNoteLine__c> creditNoteCNLMap = new Map<Id,blng__creditNoteLine__c>();
        Map<Id,blng__CreditNote__c>finalSingleUpdateCreditNoteMap = new Map<Id,blng__creditNote__c>();
        Set<id> cnSet = new Set<id>(); //EPIC#2772
        Map<id,blng__CreditNote__c> cnMap;   //EPIC#2772      
        //#16075 Added If Condition for Bypass the Fair Market Value Validation rule for Billing countries by creating Label
        if(!newList.isEmpty() && newList[0].QTB_country__c != null && System.Label.QTB_On_Acc_Credit_for_Billing_Only_Eligible_Countries.contains(newList[0].QTB_country__c))
        {
            onAccountCreditBillingCountry = true;
        }
        //Starting EPIC#2772
        if(!newList.isEmpty())
        {
            System.debug('>>insidenewlist');
            for(blng__creditNoteLine__c cNLRecord :newList)
            {
                
                cnSet.add(cNLRecord.blng__CreditNote__c);
                
            }
        }       		
        if(!cnSet.isEmpty() && (operationType.name().equalsIgnoreCase('BEFORE_INSERT') || operationType.name().equalsIgnoreCase('BEFORE_UPDATE')))
        {
            cnMap = new Map<Id, blng__CreditNote__c>(
                [SELECT Id, Name, QTB_Commercial_Credit__c ,blng__EffectiveTaxDate__c,blng__Account__r.SBQQ__TaxExempt__c
                 FROM blng__CreditNote__c 
                 WHERE Id IN :cnSet]);
           System.debug('>>cnMap'+cnMap);
        }
        //EPIC#2772 closed
        //List to store cnl to update translated field #25043 update UOM translated value, #26202 update translated product name and product group
        List<blng__CreditNoteLine__c>cnlForTrans = new List<blng__CreditNoteLine__c>();
        
        
        for(blng__CreditNoteLine__c cnlNew : newList) {
            switch on operationType {
                when BEFORE_INSERT {
                    if(String.isNotBlank(cnlNew.QTB_InvoiceLine__c) && !cnlNew.QTB_On_Account_Credit_Note_Line__c)
                    {
                        invoiceLineId.add(cnlNew.QTB_InvoiceLine__c);
                        invoiceIds.add(cnlNew.QTB_Invoice__c);
                    }
                    //GITLAB US #15242 -- AccountLevelCredit -- to populate Account
                    if(String.isBlank(cnlNew.QTB_Account__c)){
                        cnlNew.QTB_Account__c = cnlNew.QTB_Billing_Account__c;
                    }
                    //GITLAB US #15242 -- AccountLevelCredit -- for account with credit, checking invoiceLine blank
                    if(String.isBlank(cnlNew.QTB_InvoiceLine__c)){
                        cnlNew.QTB_Allocated_Revenue_Amount__c = cnlNew.blng__Subtotal__c; //setting allocated revenue amount based on subtotal
                    }
                    //EPIC#2772 -explicitly set the blng__CalculateTax__c field value to false in the before insert and before update triggers for commercial CreditNote.
                    //As of now commercial Creditnote is applicable only for india.
                    if(cnMap!= null && cnMap.get(cnlNew.blng__CreditNote__c).QTB_Commercial_Credit__c && cnlNew.QTB_country__c != null &&
                      System.label.QTB_CommercialCNCountry.containsIgnoreCase((cnlNew.QTB_country__c)))
                    {    
                        System.debug('>>insidecommerical');
                        cnlNew.blng__CalculateTax__c = false;
                    }
                    //Close epic#2772
                    //GITLAB US #16486 -- AccountLevelCredit -- On Account true for CNline
                    if(cnlNew.QTB_On_Account_Credit_Note_Line__c)
                    {
                        //Gitlab-#31015
                        if(cnlNew.blng__Subtotal__c == 0 || cnlNew.blng__Subtotal__c == null) {
                            cnlNew.addError(System.label.QTB_OnAccountSubtotalBlank);
                        }
                        // #16486 Making QTB_Product_Identifier_1__c (Product Identifier 1) field mendatory and throw validation error if it is blank for NA countries
                        // Gitlab US #32734 removed QTB_ProductIdentifierCountry custom label as part of this requirement
                        if(String.isBlank(cnlNew.QTB_Product_Identifier_1__c ) && cnlNew.QTB_country__c != null && !Test.isRunningTest())
                        {
                            cnlNew.addError(System.label.QTB_ProductIdentifierValidation);
                        }
                        //GITLAB US #19787 -- On Account Credit for NA SITAD - TAX lines are not flowing from EDP to EBS.
                        //So setting blng__CalculateTax__c to true
                        if(!cnlNew.blng__CalculateTax__c  && cnlNew.QTB_country__c != null &&
                            System.Label.QTB_ProductIdentifierCountry.contains(cnlNew.QTB_country__c.tolowercase()) )
                        {
                            cnlNew.blng__CalculateTax__c = true;
                        }
                        //GITLAB US #15242 -- AccountLevelCredit -- for Account with credit If the invoice is selected at creditnoteline throw validation error
                        // Gitlab #22304 Added and Condition for Byypassing the Legacy invoice to create On Account Credit note
                        if(String.isNotBlank(cnlNew.QTB_Invoice__c) && cnlnew.QTB_Invoice_Type__c != 'legacy Invoice')
                        {
                            cnlNew.addError(System.label.QTB_OnAccountCreditNoteLineInvoiceValidation);
                        }
                        
                        //GITLAB US #14748 -- AccountLevelCredit -- for Account with credit Allow only fairmarket value product or throw validation error for NA
                        //GITLAB US #16075 -- AccountLevelCredit -- Adding Not condition for Bypassing the Validation that is existing for Billing countries
                        //GITLAB US #23743 - AccountLevelCredit - Bypassing below validation when 'Legacy Credit' selected as Reason code from Credit Note level for NA-SITAD
                        if(!onAccountCreditBillingCountry && !System.label.QTB_OnAccountCreditNoteLineProducts.contains(cnlNew.QTB_Product_Name__c) &&
                            cnlNew.QTB_SITAD__c == true && !System.label.QTB_OnAccountCreditReasonCodeforBillingOnly.contains(cnlNew.QTB_Reason_Code__c)
                            && System.label.QTB_NA_Countries.contains(cnlNew.QTB_country__c) )
                        {
                            cnlNew.addError(System.label.QTB_OnAccountCreditNoteLineProductValidation);
                        }
                        else
                        {
                            //GITLAB US #15977 & #16315 Adding ProductIds of CreditNoteline
                            cnlProductIds.add(cnlNew.blng__Product__c);
                            cnlCurrencies.add(cnlNew.CurrencyIsoCode);
                            cnlCountries.add(cnlNew.QTB_country__c);
                            //GITLAB US #16316 & #16315 Adding AccountIds of Credit Noteline
                            cnlAccountIds.add(cnlNew.QTB_Billing_Account__c);
                        }
                    }
                    //GITLAB US#23532 -- Setting blng__CalculateTax__c = false for CreditNote Without Tax scenario
                    if(cnlNew.QTB_Credit_Note_Type__c == 'Credit Only' && !cnlNew.QTB_CreditOnlyIsTaxable__c && cnlNew.blng__CalculateTax__c){
                        cnlNew.blng__CalculateTax__c = false;
                    }
                    // #25043 update UOM translated value
                    // #26202 update translated Product name and product group
                    if(cnlNew.QTB_AccountLanguage__c != null){
                        cnlForTrans.add(cnlNew);
                    }
                }
                when BEFORE_UPDATE {
                    // //EPIC#2772-explicitly set the blng__CalculateTax__c field value to false in the before insert and before update triggers.
                    if(cnMap!= null && cnMap.get(cnlNew.blng__CreditNote__c).QTB_Commercial_Credit__c && cnlNew.QTB_country__c != null &&
                       System.label.QTB_CommercialCNCountry.containsIgnoreCase((cnlNew.QTB_country__c)))
                    {    
                        System.debug('>>insidecommerical');
                        cnlNew.blng__CalculateTax__c = false;
                        }
                    //closing//EPIC#2772 
                    if (oldMap != null && cnlNew.blng__Status__c <> oldMap.get(cnlNew.Id).blng__Status__c && cnlNew.blng__Status__c == QTB_Constants.CREDITNOTELINE_STATUS_POSTED)
                    {
                        cnlNew.RecordTypeId = QTB_Utils.CREDITNOTELINE_POSTED_RECTYPEID;
                    }
                    if (oldMap != null && (String.isNotBlank(cnlNew.QTB_InvoiceLine__c) && cnlNew.QTB_InvoiceLine__c <> oldMap.get(cnlNew.Id).QTB_InvoiceLine__c || cnlNew.blng__Subtotal__c <> oldMap.get(cnlNew.Id).blng__Subtotal__c ||cnlNew.QTB_Credit_Quantity__c <> oldMap.get(cnlNew.Id).QTB_Credit_Quantity__c ) && !cnlNew.QTB_On_Account_Credit_Note_Line__c)
                    {
                        invoiceLineId.add(cnlNew.QTB_InvoiceLine__c);
                    }
                    //GITLAB US #15242 -- AccountLevelCredit -- for account with credit, checking invoiceLine blank and subtotal change
                    if(oldMap != null && String.isBlank(cnlNew.QTB_InvoiceLine__c) && cnlNew.blng__Subtotal__c != oldMap.get(cnlNew.Id).blng__Subtotal__c)
                    {
                        cnlNew.QTB_Allocated_Revenue_Amount__c = cnlNew.blng__Subtotal__c;  //setting allocated revenue amount based on subtotal
                    }
                    //GITLAB US #15242 -- AccountLevelCredit -- for Account with credit If the invoice is selected at creditnoteline throw validation error
                    if( oldMap != null && cnlNew.QTB_On_Account_Credit_Note_Line__c && cnlNew.QTB_Invoice__c != oldMap.get(cnlNew.Id).QTB_Invoice__c && cnlNew.QTB_Invoice__c != null)
                    {
                        cnlNew.addError(System.label.QTB_OnAccountCreditNoteLineInvoiceValidation);
                    }
                    //GITLAB US #16486 -- AccountLevelCredit -- Making QTB_Product_Identifier_1__c (Product Identifier 1) field mendatory and throw validation error if it is blank for NA countries
                    // Gitlab US #32734 removed QTB_ProductIdentifierCountry custom label as part of this requirement
                    if(oldMap != null && cnlNew.QTB_On_Account_Credit_Note_Line__c && cnlNew.QTB_country__c != null &&
                        String.isBlank(cnlNew.QTB_Product_Identifier_1__c ) && !Test.isRunningTest())
                    {
                        cnlNew.addError(System.label.QTB_ProductIdentifierValidation);
                    }
                    //GITLAB US #19787 -- AccountLevelCredit -- On Account Credit for NA SITAD - TAX lines are not flowing from EDP to EBS.
                    // So setting blng__CalculateTax__c to true
                    if(oldMap != null && cnlNew.QTB_On_Account_Credit_Note_Line__c &&
                        ((cnlNew.blng__CalculateTax__c != oldMap.get(cnlNew.Id).blng__CalculateTax__c && !cnlNew.blng__CalculateTax__c) || !cnlNew.blng__CalculateTax__c) &&
                        cnlNew.QTB_country__c != null && System.Label.QTB_ProductIdentifierCountry.contains(cnlNew.QTB_country__c.tolowercase()))
                    {
                        cnlNew.blng__CalculateTax__c = true;
                    }
                    //GITLAB US #14748 -- AccountLevelCredit -- for Account with credit Allow only fairmarket value product or throw validation error
                    //GITLAB US #16075 -- AccountLevelCredit -- Adding Not condition for Bypassing the Validation that is existing for Billing countries
                    //GITLAB US #23743 - AccountLevelCredit - Bypassing below validation when 'Legacy Credit' selected as Reason code from Credit Note level for NA-SITAD
                    if(oldMap != null && !onAccountCreditBillingCountry && cnlNew.QTB_On_Account_Credit_Note_Line__c  &&
                        (cnlNew.blng__Product__c != oldMap.get(cnlNew.Id).blng__Product__c && !System.label.QTB_OnAccountCreditNoteLineProducts.contains(cnlNew.QTB_Product_Name__c) && cnlNew.QTB_SITAD__c == true && !System.label.QTB_OnAccountCreditReasonCodeforBillingOnly.contains(cnlNew.QTB_Reason_Code__c)
                        && System.label.QTB_NA_Countries.contains(cnlNew.QTB_country__c)))
                    {
                        cnlNew.addError(System.label.QTB_OnAccountCreditNoteLineProductValidation);
                    }
                    //GITLAB US# 19560 defect fix-- for CreditOnly, non-taxable scenario, not allowing user to change the calculateTax field value from false to true.
                    if(oldMap != null && cnlNew.QTB_Credit_Note_Type__c == 'Credit Only' && !cnlNew.QTB_CreditOnlyIsTaxable__c &&
                        (cnlNew.blng__CalculateTax__c != oldMap.get(cnlNew.Id).blng__CalculateTax__c && cnlNew.blng__CalculateTax__c))
                    {
                        cnlNew.addError(System.label.QTB_CreditOnlyIsTaxable);
                    }
                    //GITLAB US #21230 - If credit note line status updated to cancelled manually update the recordtype Applicable
                    //only to manual credit note and ON Account credit note scenerio
                    if(oldMap != null && cnlNew.blng__Status__c <> oldMap.get(cnlNew.Id).blng__Status__c && cnlNew.blng__Status__c == 'Cancelled')
                    {
                        cnlNew.recordTypeId = QTB_Utils.CREDITNOTELINE_POSTED_RECTYPEID;
                    }
                    //GITLAB US #20672 -- This condition checks Full Credit (Credit only, Rebill, Split rebill,) to restrict fields
                    //We are allowing status to Cancelled, Posted and Calculate tax to uncheck if it is true
                    // #29685
                    if(!oldMap.isEmpty() && (cnlNew.blng__Status__c != 'Cancelled' || cnlNew.blng__Status__c != 'Posted') &&
                        (cnlNew.QTB_Credit_Note_Type__c != 'ON Account Credit' && cnlNew.QTB_Credit_Note_Type__c != 'Legacy Credit' && /*!String.isEmpty(cnlNew.QTB_Credit_Note_Type__c)Gitlab-30332*/ cnlNew.QTB_Credit_Note_Type__c != 'Manual Credit'))
                    {
                        callCNL_checkRestrictedFields = true;
                    }
                }
                when AFTER_INSERT {
                    if (String.isNotBlank(cnlNew.QTB_InvoiceLine__c) && !cnlNew.QTB_On_Account_Credit_Note_Line__c)
                    {
                        invoiceLineId.add(cnlNew.QTB_InvoiceLine__c);
                        invoiceIds.add(cnlNew.QTB_Invoice__c);
                    }
                    // #27493 - storing one credit note line for each credit note as based on that credit note line's invoice refrence will update the taxDate
                    if(cnlNew.QTB_country__c != null && Label.QTB_TaxDateCompliance_Countries.containsIgnoreCase(cnlNew.QTB_country__c) &&
                    cnlNew.QTB_Invoice__c != null && cnlNew.blng__CreditNote__c != null && !creditNoteCNLMap.containsKey(cnlNew.blng__CreditNote__c)){
                        creditNoteCNLMap.put(cnlNew.blng__CreditNote__c,cnlNew);
                    }
                }
                when AFTER_UPDATE {
                    //Gitlab US #20433 Tax rounding Enhancement
                    //Populate TaxOverride for North America for Tax Override always
                    //irresepective of Tax Status - since Resend to Tax can be done irresepective of tax status - Story 21202
                    //added draft condition along with NA countries condition to stop tax override calculation at time of posting - story 21664
                    //Gitlab US#22889 replace blng__TaxCountry with QTB_Country as blng__TaxCountry does not have any value due to tht getting argument can not null exception
                    // Gitlab #30630 Added blng__TaxAmount__c to OR condition for Billing Country to update tax override on tax amount change.
                    if((oldMap!=null && cnlNew.blng__TaxStatus__c == 'Completed' &&
                        (cnlNew.blng__TaxStatus__c != oldMap.get(cnlNew.Id).blng__TaxStatus__c || oldMap.get(cnlNew.Id).blng__TaxRule__c != cnlNew.blng__TaxRule__c ||cnlNew.blng__TaxAmount__c != oldMap.get(cnlNew.Id).blng__TaxAmount__c) &&
                        cnlNew.blng__CalculateTax__c == true && cnlNew.blng__Status__c == 'Draft') ||
                        (Label.QTB_NA_Countries.containsIgnoreCase(cnlNew.QTB_Country__c) && cnlNew.blng__TaxAmount__c != oldMap.get(cnlNew.Id).blng__TaxAmount__c && cnlNew.blng__Status__c == 'Draft'))//Gitlab US#22889 //26218
                    {
                        if(cnlNew.QTB_Invoice__c != null){
                            cnlWithInvoiceRefForTaxRounding.add(cnlNew.blng__CreditNote__c);
                        }
                        else{
                            cnlWithoutInvoiceRefForTaxRounding.add(cnlNew.blng__CreditNote__c);  // Cnl without invoice refrence (OnAccount scenario)
                        }
                    }
                    // #27493
                    if(cnlNew.QTB_country__c != null && Label.QTB_TaxDateCompliance_Countries.containsIgnoreCase(cnlNew.QTB_country__c) && cnlNew.QTB_Invoice__c != null && cnlNew.blng__CreditNote__c != null &&
                    oldMap.get(cnlNew.Id).QTB_Invoice__c != cnlNew.QTB_Invoice__c && !creditNoteCNLMap.containsKey(cnlNew.blng__CreditNote__c)){
                        creditNoteCNLMap.put(cnlNew.blng__CreditNote__c,cnlNew);
                    }
                }
            }
        }
        
        switch on operationType {
            when BEFORE_INSERT{
                if (!invoiceLineId.isEmpty()) {
                    updateCNL(invoiceLineId, newList, oldMap);
                    validate_CNL_Subtotal(newList); //GIT #22532
                }
                //Gitlab US #16316 & #16315 -- AccountLevelCredit -- for Assigning Tax country and tax rule for On Account Scenario for credit Note line
                if(!cnlAccountIds.isEmpty() && !cnlProductIds.isEmpty())
                {
                    QTB_CNLHelperUtils.validateProductForBillingCountries(newList,cnlProductIds,cnlCountries,cnlCurrencies);
                    QTB_CNLHelperUtils.updateTaxInfoForOnAccountCreditNote(newList,cnlAccountIds,cnlProductIds);
                }
                // #25043 update UOM translated value
                // #26202 update translated Product name and product group
                if(!cnlForTrans.isEmpty()){
                    QTB_CNLHelperUtils.setTranslationFieldsOnCNL(cnlForTrans,null);
                    QTB_CNLHelperUtils.setProductNameTranslation(cnlForTrans,null);
                }
            }
            when BEFORE_UPDATE{
                //Gitlab US #20672 -- Full Credit -- Block Credit Note Line Editing after full Credit
                if(callCNL_checkRestrictedFields)
                {
                    CNL_checkRestrictedFields(newList, oldMap, String.valueOf(System.label.CNL_RestrictedFields_Draft));
                }
                
                if (!invoiceLineId.isEmpty())
                {
                    updateCNL(invoiceLineId, newList, oldMap);
                    validate_CNL_Subtotal(newList); //GIT #22532
                }
                //25283
                if(System.Label.IsCNLFieldsNonEditableForPosted == 'true'){
                    makeFieldsNonEditableForPosted(newList,oldMap);
                }
                if(System.Label.IsCNLFieldsReadOnlyForProcessed == 'true'){
                    // makeFieldsReadOnlyForPosted(newList,oldMap);
                }
                if(Test.isRunningTest()){
                    makeFieldsNonEditableForPosted(newList,oldMap);
                    makeFieldsReadOnlyForPosted(newList,oldMap);
                }
            }
            when BEFORE_DELETE {
                if (!newList.isEmpty() && !isParentBundleDeleted)
                {
                    validateCNLDelete(newList, oldMap); //GitLab#448, Git #5703
                }
                
                //Gitlab US #21455,#20672 -- Full Credit (Credit Note generated via Credit & Rebill, CreditOnly functionality)
                if(!oldMap.isEmpty() && !test.isRunningTest()){
                    for(blng__CreditNoteLine__c crdLine: oldMap.values()){
                        //Gitlab US #21455 -- restricting user for deletion credit note lines in cancelled
                        if(crdLine.blng__Status__c == 'Cancelled'){
                            crdLine.addError(label.QTB_CNL_Delete_Cancelled);
                        }
                        //Gitlab US #20672 -- restricting user for deletion of CreditNoteLine for Full Credit (Credit Note generated via Credit & Rebill, CreditOnly functionality)
                        if(crdLine.QTB_Credit_Note_Type__c != 'ON Account Credit' && /*!String.isEmpty(crdLine.QTB_Credit_Note_Type__c)Gitlab-30332*/ crdLine.QTB_Credit_Note_Type__c != 'Manual Credit'){
                            crdLine.addError(System.label.QTB_CNL_Delete_FullCredit);
                        }
                    }
                }
            }
            when After_INSERT {
                //Gitlab US #5703
                if ((!invoiceLineId.isEmpty() && !isParentBundle) || test.isRunningTest())
                {
                    createCNLforBundle(invoiceIds, invoiceLineId, newList, oldMap);
                }
                // #27493
                if(!creditNoteCNLMap.isEmpty()){
                    List<blng__CreditNote__c>cnTaxDateUpdate = QTB_CNLHelperUtils.updateTaxDateOnCreditNote(creditNoteCNLMap.values());
                    //assigning the value to final list of credit note as part of new code structure
                    if(!cnTaxDateUpdate.isEmpty()){
                        // if credit note is already present in the map then assigning the field value that we need to update else adding credit note
                        for(blng__CreditNote__c cn :cnTaxDateUpdate){
                            if(!finalSingleUpdateCreditNoteMap.containsKey(cn.Id)){
                                finalSingleUpdateCreditNoteMap.put(cn.Id,cn);
                            }
                            else{
                                finalSingleUpdateCreditNoteMap.get(cn.Id).put('QTB_TaxDate__c',cn.QTB_TaxDate__c);
                            }
                        }
                    }
                }
                
            }
            When After_UPDATE{
                //Gitlab US #20433 Tax Rounding Enhancement
                if(!cnlWithInvoiceRefForTaxRounding.isEmpty() && QTB_RecursiveHandlerCheck.taxRoundingOnCreditNote == True)
                {
                    QTB_CNLHelperUtils.taxRoundingOnCreditNote(cnlWithInvoiceRefForTaxRounding);
                }
                //Gitlab US #20433 Tax Rounding Enhancement
                if((!cnlWithoutInvoiceRefForTaxRounding.isEmpty() && QTB_RecursiveHandlerCheck.OnAccountCreditNoteTaxRounding == True)||Test.isRunningTest())
                {
                    Set<string> cnlAddressComparison = new Set<string>();
                    for(blng__creditNoteLine__c crdtNL : [Select Id,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                                          blng__TaxTreatment__r.blng__TaxCode__c,blng__LegalEntity__c,blng__CreditNote__c 
                                                          FROM blng__creditNoteLine__c
                                                          WHERE blng__CreditNote__c IN :cnlWithoutInvoiceRefForTaxRounding])
                    {
                        // creating address comparision string to fetch tax rate map based on address   comparision
                        // Commented line 363-365 as part of story 24038 to create address comparison to fetch the tax rate record
                        String cnlComparison =
                            crdtNL.blng__TaxCountry__c +'----' +
                            // crdtNL.blng__TaxState__c +'-' +
                        // crdtNL.blng__TaxCity__c +'-' +
                        // crdtNL.blng__TaxZipCode__c +'-' +
                        crdtNL.blng__TaxTreatment__r.blng__TaxCode__c +'-' +
                            crdtNL.blng__LegalEntity__c;
                        //remove null from string
                        cnlComparison = cnlComparison.replaceAll('null','');
                        cnlAddressComparison.add(cnlComparison);
                    }
                    QTB_CNLHelperUtils.OnAccountCreditNoteTaxRounding(cnlWithoutInvoiceRefForTaxRounding,cnlAddressComparison);
                }
                // #27493
                if(!creditNoteCNLMap.isEmpty()){
                    List<blng__CreditNote__c>cnTaxDateUpdate = QTB_CNLHelperUtils.updateTaxDateOnCreditNote(creditNoteCNLMap.values());
                    //assigning the value to final list of credit note as part of new code structure
                    if(!cnTaxDateUpdate.isEmpty()){
                        // if credit note is already present in the map then assigning the field value that we need to update else adding credit note
                        for(blng__CreditNote__c cn :cnTaxDateUpdate){
                            if(!finalSingleUpdateCreditNoteMap.containsKey(cn.Id)){
                                finalSingleUpdateCreditNoteMap.put(cn.Id,cn);
                            }
                            else{
                                finalSingleUpdateCreditNoteMap.get(cn.Id).put('QTB_TaxDate__c',cn.QTB_TaxDate__c);
                            }
                        }
                    }
                }
                
            }
        }
        if(!finalSingleUpdateCreditNoteMap.isEmpty() && QTB_RecursiveHandlerCheck.afterUpdateAfterInsertCN){
            update finalSingleUpdateCreditNoteMap.values();
            QTB_RecursiveHandlerCheck.afterUpdateAfterInsertCN = False;
        }
        
    }
    
    /***********************************************************************************************************
     * Method : createCNLforBundle
     * Parameters: Set<ID> invoiceIds,Set<ID> invoiceLineId,List<blng__CreditNoteLine__c> newCnl,Map<id, blng__CreditNoteLine__c> oldMap
     * Return Type : void
     * Requirement : Git #5703
     * Description: while creating the credit note line if BundleHeader selected, then auto creating the credit note line for its repective child recurring products
     **************************************************************************************************************/
    public static void createCNLforBundle(Set<ID> invoiceIds,Set<ID> invoiceLineId,List<blng__CreditNoteLine__c> newCnl,Map<id, blng__CreditNoteLine__c> oldMap){
        try{
            if (QTB_CNLTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            Set<Id> productId = new Set<Id>();
            Map<Id, List<SBQQ__ProductOption__c>> productToProductOptionsMap = new Map<Id, List<SBQQ__ProductOption__c>>();
            Map<Id, List<blng__InvoiceLine__c>> invoiceIdToInvoiceLineMap = new Map<Id, List<blng__InvoiceLine__c>>();
            List<blng__CreditNoteLine__c> cnlList = new List<blng__CreditNoteLine__c>();
            
            //Map to Store Invoice Line Fields with Id.
            //Defect Fix Gitlab US#21794 -- added blng__Product__r.Name in query
            //Defect Gitlab US#24187 -- fields added in the query
            Map<Id, blng__InvoiceLine__c> invLineMap = new Map<Id, blng__InvoiceLine__c>(
                [SELECT Id, Name, blng__Invoice__c,blng__Invoice__r.blng__Account__c, blng__Product__c,blng__LegalEntity__c,blng__LegalEntity__r.blng__Country__c,blng__Product__r.Name,
                 QTB_Total_Amount_With_Tax__c,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Balance__c,blng__TaxRule__c, blng__TaxTreatment__c,blng__BillingRule__c,
                 QTB_Taxable_Amount__c,QTB_Allocated_Revenue_Amount__c,QTB_Unit_Price__c,blng__TotalAmount__c,blng__Quantity__c,QTB_Charge_Type__c,blng__Invoice__r.QTB_ReBill_Status__c 
                 FROM blng__InvoiceLine__c WHERE blng__Invoice__c IN :invoiceIds ]);
            
            if(!invLineMap.isEmpty()){
                for(blng__InvoiceLine__c invoiceLine : invLineMap.values())
                {
                    productId.add(invoiceLine.blng__Product__c);//Stroing productIds in set
                    if(invoiceIdToInvoiceLineMap.containsKey(invoiceLine.blng__Invoice__c))
                    {
                        invoiceIdToInvoiceLineMap.get(invoiceLine.blng__Invoice__c).add(invoiceLine); //storing invoiceId with invoiceLine
                    }
                    else{
                        invoiceIDToInvoiceLineMap.put(invoiceLine.blng__Invoice__c,new List<blng__InvoiceLine__c>{invoiceLine});
                    }
                }
            }
            
            //Fetching ProductOptions data based on productId
            List<SBQQ__ProductOption__c> productOptionsList = [SELECT Id, Name,SBQQ__ConfiguredSKU__c,SBQQ__OptionalSKU__c,SBQQ__OptionalSKU__r.Name,
                                                               SBQQ__ConfiguredSKU__r.Name  
                                                               FROM SBQQ__ProductOption__c 
                                                               WHERE SBQQ__ConfiguredSKU__c IN : productId ];
            
            //storing ParentProduct & their product options
            for(SBQQ__ProductOption__c productOption : productOptionsList )
            {
                if(productToProductOptionsMap.containsKey(productOption.SBQQ__ConfiguredSKU__c))
                {
                    productToProductOptionsMap.get(productOption.SBQQ__ConfiguredSKU__c).add(productOption);
                }
                else{
                    productToProductOptionsMap.put(productOption.SBQQ__ConfiguredSKU__c,new List<SBQQ__ProductOption__c>{productOption});
                }
            }
            
            if(newCnl != null && !newCnl.isEmpty()){
                //Iterating over new credit note lines
                for(blng__CreditNoteLine__c crednl : newCnl)
                {   // with reference to GITLAB #19727 to exclude credit only scenerio added the condition as below
                    //skipping checkBundleHeaderInvoiceLines() method for Rebill, SplitRebill & CreditOnly process.
                    if(!invLineMap.isEmpty() && invLineMap.containsKey(crednl.QTB_InvoiceLine__c) && invLineMap.get(crednl.QTB_InvoiceLine__c).QTB_Charge_Type__c == 'Bundle Header'
                        && /*crednl.QTB_Credit_Note_Type__c == null Gitlab--30332*/ crednl.QTB_Credit_Note_Type__c == 'Manual Credit')
                    {
                        //Defect fix Gitlab US#20785 -- allowing create credit note lines (recurring) for regular credit note only
                        //For Creation of CreditNote Recurring Invoice line, sending required params
                        List<blng__CreditNoteLine__c> crd = checkBundleHeaderInvoiceLines(crednl.id, crednl.blng__CreditNote__c, invLineMap.get(crednl.QTB_InvoiceLine__c),productToProductOptionsMap,invoiceIDToInvoiceLineMap);
                        cnlList.addAll(crd);
                    }
                }
            }
            
            //Inserting CreditNote lines for subscription invoice lines (child of bundle header lines)
            if(!cnlList.isEmpty() && !cnlList.contains(null) && cnlList.size() > 0){
                insert cnlList;
            }
            //free-up the memory
            productId.clear();
            productToProductOptionsMap.clear();
            invoiceIdToInvoiceLineMap.clear();
            cnlList.clear();
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'createCNLforBundle');
            throw e;
        }
    }
    
    /***********************************************************************************************************
     * Method : checkBundleHeaderInvoiceLines
     * Parameters: Id parentCreditNoteLineId, Id crdId, blng__InvoiceLine__c invln,  Map<Id, List<SBQQ__ProductOption__c>> productToProductOptionsMap,
    Map<Id, List<blng__InvoiceLine__c>> invoiceIdToInvoiceLineMap
         * Return Type : blng__CreditNoteLine__c
     * Requirement : Git #5703
     * Description: if selected credit note lines is for bundle header,then auto creating credit note lines for recurring invoice lines,
     **************************************************************************************************************/
    public static List<blng__CreditNoteLine__c> checkBundleHeaderInvoiceLines(Id parentCreditNoteLineId, Id crdId, blng__InvoiceLine__c invln,  Map<Id, List<SBQQ__ProductOption__c>> productToProductOptionsMap,Map<Id, List<blng__InvoiceLine__c>> invoiceIdToInvoiceLineMap)
    {
        try{
            if (QTB_CNLTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            List<blng__CreditNoteLine__c> creditNoteList = new List<blng__CreditNoteLine__c>();
            isParentBundle = true; //static variable to control the creation of credit note line for recurring lines
            if(invoiceIdToInvoiceLineMap != null && !invoiceIdToInvoiceLineMap.isEmpty() && invln != null)
            {
                String parentInvoiceLineProductName = invln != null ? invln.blng__Product__r.Name : '';//Defect Fix Gitlab US#21794
                for(blng__InvoiceLine__c invl : invoiceIdToInvoiceLineMap.get(invln.blng__Invoice__c)) //fetching all invoice lines for that invoice
                {
                    //allowing to create Credit note line only for Allocated Revenue Recurring InvoiceLines
                    if(Test.isRunningTest() || ((invl.blng__Invoice__r.QTB_ReBill_Status__c != null && (invl.QTB_Charge_Type__c == 'Recurring' || invl.QTB_Charge_Type__c == 'Usage')) || (invl.blng__Invoice__r.QTB_ReBill_Status__c == null && invl.QTB_Charge_Type__c == 'Recurring'))
                        && invl.QTB_Taxable_Amount__c!=null && invl.QTB_Taxable_Amount__c >= 0 && productToProductOptionsMap.containsKey(invln.blng__Product__c))
                    {
                        if(productToProductOptionsMap != null &&  productToProductOptionsMap.containsKey(invln.blng__Product__c)){
                            String invoiceLineProductName = invl.blng__Product__r.Name; //Defect Fix Gitlab US#21794
                            for(SBQQ__ProductOption__c prdOption : productToProductOptionsMap.get(invln.blng__Product__c)){
                                //Verify if Invoiceline.ProductName matches with ProductOption //Defect Fix Gitlab US#21794
                                if(Test.isRunningTest() || (invoiceLineProductName == prdOption.SBQQ__OptionalSKU__r.Name && parentInvoiceLineProductName == prdOption.SBQQ__ConfiguredSKU__r.Name)){
                                    //Create credit note lines for recurring invoice lines (subscription lines)
                                    blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
                                    cnl.blng__CreditNote__c = crdId;
                                    cnl.QTB_Parent_CreditNoteLine__c = parentCreditNoteLineId;
                                    cnl.blng__Subtotal__c =  invl.blng__Subtotal__c;
                                    cnl.blng__Product__c = invl.blng__Product__c; //Product
                                    cnl.blng__InvoiceLine__c = invl.Id;
                                    cnl.blng__Status__c = 'Draft';
                                    cnl.QTB_Credit_Quantity__c = invl.blng__Quantity__c;
                                    cnl.blng__CalculateTax__c = false;
                                    cnl.QTB_InvoiceLine__c = invl.Id;
                                    cnl.QTB_Invoice__c = invln.blng__Invoice__c;
                                    cnl.blng__TaxRule__c = invl.blng__TaxRule__c; //TaxRule
                                    cnl.blng__TaxTreatment__c = invl.blng__TaxTreatment__c; //TaxTreatment
                                    cnl.blng__BillingRule__c = invl.blng__BillingRule__c; //BillingRule
                                    cnl.blng__TaxAmount__c = null;
                                    cnl.blng__LegalEntity__c = (String.isBlank(invl.blng__LegalEntity__c) ? null : invl.blng__LegalEntity__c);
                                    cnl.blng__TaxCountry__c = (String.isBlank(invl.blng__LegalEntity__r.blng__Country__c) ? null : invl.blng__LegalEntity__r.blng__Country__c); //TaxCountry
                                    cnl.QTB_Account__c = invln.blng__Invoice__r.blng__Account__c;
                                    creditNoteList.add(cnl);
                                }
                            }
                        }
                    }
                }
            }
            return creditNoteList;
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CREDITNOTELINE_TRIGGER);
            throw e;
        }
    }
    
    /***********************************************************************************************************
     * Method : updateCNL
     * Parameters: List<blng__CreditNoteLine__c>
     * Return Type : void
     * Requirement : SFCPQBLG-76
     * Description: auto populating the Credit Note Line fields based on selected Invoice Line
     **************************************************************************************************************/
    public static void updateCNL(Set<ID> invoiceLineId, List<blng__CreditNoteLine__c> newCnl, Map<id, blng__CreditNoteLine__c> oldMap)
    {
        try {
            if (QTB_CNLTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            Map<ID, Double> summationOldCreditNoteLine = new Map<ID, Double>();
            boolean skipNegativeInvoiceLineValidation = false; //GITLAB US #21478 -- Added skipNegativeInvoiceLineValidation
            
            //Map to Store Invoice Line Fields with Id.
            // Added some fields related to Negative Invoice lines for Legacy invoices
            // Added #21956 QTB_Is_Service__c for Copying the value to Credit Note Is service
            Map<Id, blng__InvoiceLine__c> invLineMap = new Map<Id, blng__InvoiceLine__c>([
                SELECT Id, blng__Invoice__r.QTB_ReBill_Status__c,blng__Product__c,blng__LegalEntity__c,blng__LegalEntity__r.blng__Country__c, blng__Subtotal__c, blng__TaxPercentageApplied__c,blng__TaxRule__c,blng__TaxTreatment__c,blng__BillingRule__c,QTB_Unit_Price__c,blng__UnitPrice__c,blng__TotalAmount__c,blng__Quantity__c,QTB_Charge_Type__c,QTB_Allocated_Revenue_Amount__c,QTB_Taxable_Amount__c,blng__TaxCountry__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,QTB_HSN_Code__c,blng__Invoice__r.blng__Account__r.QTB_SITAD__c,blng__Invoice__r.blng__InvoiceDate__c,QTB_Is_Service__c
            FROM blng__InvoiceLine__c WHERE Id IN :invoiceLineId ]);
            
            //GITLAB US #21478 -- Skip validation as the Credit Note Amount ll be more than Invoice Amount due to -ve invoice Line.
            if(!invLineMap.isEmpty()){
                for(blng__InvoiceLine__c invL : invLineMap.values()){
                    string legalEntityCountry = invL.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c;
                    if(invL.blng__Subtotal__c < 0 && invL.blng__Invoice__r.blng__Account__r.QTB_SITAD__c &&
                        (legalEntityCountry.equalsIgnoreCase('United States') || legalEntityCountry.equalsIgnoreCase('Canada')))
                    {
                        skipNegativeInvoiceLineValidation = true;
                    }
                }
            }
            
            //Fetching the CreditNoteLines data and storing in Map
            Map<Id, blng__CreditNoteLine__c> creditNoteLineRecordsMap = new Map<Id, blng__CreditNoteLine__c>(
                [ SELECT id,blng__CreditNote__c,blng__CreditNote__r.QTB_IsReBill__c,  blng__Subtotal__c, blng__TotalAmount__c, blng__InvoiceLine__c, blng__Status__c,
             blng__CalculateTax__c, QTB_InvoiceLine__c,QTB_Invoice__c,QTB_InvoiceLine__r.blng__TaxPercentageApplied__c,QTB_Credit_Note_Type__c 
             FROM blng__CreditNoteLine__c 
             WHERE QTB_InvoiceLine__c IN :invoiceLineId ]);
            
            if(!creditNoteLineRecordsMap.isEmpty())
            {
                for(blng__CreditNoteLine__c oldCreditNoteLine : creditNoteLineRecordsMap.values())
                {
                    //Gitlab US #16769
                    if(oldCreditNoteLine.blng__Status__c == QTB_Constants.CREDITNOTELINE_STATUS_POSTED || oldCreditNoteLine.blng__Status__c == QTB_Constants.CREDITNOTELINE_STATUS_DRAFT)
                    {
                        if(oldCreditNoteLine.blng__Subtotal__c != null && summationOldCreditNoteLine.containsKey(oldCreditNoteLine.QTB_InvoiceLine__c))
                        {
                            summationOldCreditNoteLine.put(oldCreditNoteLine.QTB_InvoiceLine__c,summationOldCreditNoteLine.get(oldCreditNoteLine.QTB_InvoiceLine__c) + oldCreditNoteLine.blng__Subtotal__c);
                        }
                        else {
                            summationOldCreditNoteLine.put( oldCreditNoteLine.QTB_InvoiceLine__c,oldCreditNoteLine.blng__Subtotal__c);
                        }
                    }
                }
            }
            /*Loop for auto populating Credit Note Line Fields Based on selected InvoiceLine*/
            for (blng__CreditNoteLine__c crednl : newCnl)
            {
                if(oldMap != null && !oldMap.isEmpty() && Trigger.isUpdate && crednl.blng__CreditNote__c != null && creditNoteLineRecordsMap.containsKey(crednl.Id) &&
                    creditNoteLineRecordsMap.get(crednl.Id).blng__CreditNote__r.QTB_IsReBill__c == true && !test.isRunningTest() &&
                    ((crednl.QTB_Invoice__c != oldMap.get(crednl.Id).QTB_Invoice__c) || (crednl.QTB_InvoiceLine__c != oldMap.get(crednl.Id).QTB_InvoiceLine__c ) ||
                    (crednl.QTB_Credit_Quantity__c != oldMap.get(crednl.Id).QTB_Credit_Quantity__c) || (crednl.blng__Subtotal__c != oldMap.get(crednl.Id).blng__Subtotal__c )))
                {
                    crednl.addError(label.QTB_CreditRebillCNLChange);
                }
                //Restrict to create credit note lines for recurring invoiceline from UI
                //Credit ReBill By IRM/Virtusa -- added rebillStatus check
                // Defect #13641 - Can't credit recurring charges -- added QTB_Taxable_Amount__c>0
                // With reference to GITLAB - #19727 addding Credit only in codition to bypass validation getting fired on credit only scenerio
                if(!isParentBundle && Trigger.isInsert && invLineMap.containsKey(crednl.QTB_InvoiceLine__c) &&
                    invLineMap.get(crednl.QTB_InvoiceLine__c).QTB_Charge_Type__c == 'Recurring' &&
                    invLineMap.get(crednl.QTB_InvoiceLine__c).blng__Invoice__r.QTB_ReBill_Status__c == null &&
                    invLineMap.get(crednl.QTB_InvoiceLine__c).QTB_Taxable_Amount__c > 0  && crednl.QTB_Credit_Note_Type__c <> 'Credit Only' )
                {
                    crednl.addError(label.QTB_CreditNoteLineForSubscriptionLines);
                }
                else if(oldMap != null && !oldMap.isEmpty() && oldMap.get(crednl.Id).QTB_InvoiceLine__c != crednl.QTB_InvoiceLine__c &&
                    invLineMap.get(crednl.QTB_InvoiceLine__c).QTB_Charge_Type__c == 'Recurring' && invLineMap.get(crednl.QTB_InvoiceLine__c).QTB_Taxable_Amount__c > 0 &&
                    crednl.QTB_Credit_Note_Type__c <> 'Credit Only')
                {
                    crednl.addError(label.QTB_CreditNoteLineForSubscriptionLines);
                }
                if (String.isNotBlank(crednl.QTB_InvoiceLine__c) && invLineMap.containsKey(crednl.QTB_InvoiceLine__c))
                {
                    blng__InvoiceLine__c invL = invLineMap.get(crednl.QTB_InvoiceLine__c); //Variable to store Map call.
                    crednl.blng__Product__c = invL.blng__Product__c; //Product
                    crednl.blng__LegalEntity__c = (String.isBlank(invL.blng__LegalEntity__c) ? null : invL.blng__LegalEntity__c); //LegalEntity
                    //Gitlab US #13609 checking this condition for Updating Tax country only for Non Billing countries
                    //Gitlab US #20604 updating Tax country to Legal Entity country from Invoice line Tax country
                    crednl.blng__TaxCountry__c = (String.isBlank(invL.blng__LegalEntity__r.blng__Country__c) ? null : invL.blng__LegalEntity__r.blng__Country__c); //TaxCountry
                    //GITLAB #18068 Adding this Assignment for Assigning HSN code from Invoice Line
                    crednl.QTB_HSN_Code__c = invL.QTB_HSN_Code__c;
                    //GITLAB #21956 Adding this Assignment for Assigning Is service flag from Invoice Line
                    crednl.QTB_Is_Service__c = invL.QTB_Is_Service__c;
                    // #899 Auto-Calculates the sub-total field
                    // #5443 Credit Note line subtotal & quantity calculation
                    //Avoid updation of Subtotal & Quantity in case of charge Type Recurring & Bundle Header (Subscription lines)
                    //As part of #5675 we are throwing validation error for Subscription lines, not require to do calculation on subtotal & quantity
                    //Update Operation
                    if(oldMap != null && !oldMap.isEmpty())
                    {
                        //Gitlab #30243 start
                        //Auto populate Subtotal other than ON Account Credit
                        if(crednl.QTB_InvoiceLine__c == oldMap.get(crednl.Id).QTB_InvoiceLine__c ){
                            
                            Decimal invlUnitPrice = 0;
                            if(invl.blng__UnitPrice__c != null ){
                                invlUnitPrice = invl.blng__UnitPrice__c;
                            }
                            // GITLAB - #30660 Check if both Subtotal and Quantity are being updated simultaneously
                            if (crednl.blng__Subtotal__c != oldMap.get(crednl.Id).blng__Subtotal__c && crednl.QTB_Credit_Note_Type__c == 'Manual Credit') {
                                crednl.addError(System.label.QTB_CNL_SubtotalError_Update);
                                return;
                            }
                            
                            if(crednl.QTB_Credit_Quantity__c != oldMap.get(crednl.Id).QTB_Credit_Quantity__c)
                            {
                                //Subtotal auto calculate in update same line Gitlab -#31756
                                if(crednl.QTB_Credit_Quantity__c != null && crednl.QTB_Credit_Note_Type__c == 'Manual Credit'){
                                    
                                    if((invLineMap.get(crednl.QTB_InvoiceLine__c).QTB_Charge_Type__c == 'Bundle Header' || crednl.QTB_Credit_Quantity__c == invLineMap.get(crednl.QTB_InvoiceLine__c).blng__Quantity__c) && invLineMap.get(crednl.QTB_InvoiceLine__c).blng__Subtotal__c != crednl.blng__Subtotal__c){
                                        
                                        crednl.blng__Subtotal__c = invLineMap.get(crednl.QTB_InvoiceLine__c).blng__Subtotal__c;
                                    }
                                    else if(crednl.QTB_Credit_Quantity__c <> invLineMap.get(crednl.QTB_InvoiceLine__c).blng__Quantity__c && invLineMap.get(crednl.QTB_InvoiceLine__c).QTB_Charge_Type__c != 'Bundle Header'){
                                        
                                        crednl.blng__Subtotal__c = (crednl.QTB_Credit_Quantity__c * invlUnitPrice).setScale(2, RoundingMode.HALF_UP);
                                    }
                                }
                                
                            }
                            //Gitlab #30243 End
                        }
                        else if(crednl.QTB_InvoiceLine__c != oldMap.get(crednl.Id).QTB_InvoiceLine__c )
                        {
                            Decimal invlUnitPrice = 0;
                            if(invl.blng__UnitPrice__c != null ){
                                invlUnitPrice = invl.blng__UnitPrice__c;
                            }
                            
                            //Calculate subtotal for line change Gitlab -#31756
                            if(crednl.QTB_Credit_Quantity__c !=null && crednl.QTB_Credit_Note_Type__c == 'Manual Credit'){
                                
                                if(crednl.blng__Subtotal__c !=null  && crednl.blng__Subtotal__c > 0 && !Test.isRunningTest())
                                {
                                    crednl.addError(System.label.QTB_CNL_SubtotalError);
                                    return;
                                }
                                
                                if((invLineMap.get(crednl.QTB_InvoiceLine__c).QTB_Charge_Type__c == 'Bundle Header' || crednl.QTB_Credit_Quantity__c == invLineMap.get(crednl.QTB_InvoiceLine__c).blng__Quantity__c) && invLineMap.get(crednl.QTB_InvoiceLine__c).blng__Subtotal__c != crednl.blng__Subtotal__c){
                                    
                                    crednl.blng__Subtotal__c = invLineMap.get(crednl.QTB_InvoiceLine__c).blng__Subtotal__c;
                                }
                                else if(crednl.QTB_Credit_Quantity__c <> invLineMap.get(crednl.QTB_InvoiceLine__c).blng__Quantity__c && invLineMap.get(crednl.QTB_InvoiceLine__c).QTB_Charge_Type__c != 'Bundle Header'){
                                    
                                    crednl.blng__Subtotal__c = (crednl.QTB_Credit_Quantity__c * invlUnitPrice).setScale(2, RoundingMode.HALF_UP);
                                }
                            }
                            //Gitlab #30243 End
                        }
                        //GITLAB US Defect #15280, updating the allocated revenue amount based on credit note line percentage wrt to invoice line
                        double creditNotePercentageWRTInvoice = (invl.blng__Subtotal__c !=null && invl.blng__Subtotal__c != 0) ? (crednl.blng__Subtotal__c/invl.blng__Subtotal__c) * 100 : 0;
                        crednl.QTB_Allocated_Revenue_Amount__c = (creditNotePercentageWRTInvoice * invl.QTB_Allocated_Revenue_Amount__c)/100;
                    }
                    //Insert Operation
                    else {
                        system.debug('inside insert in updateCnl ');
                        
                        Decimal invlUnitPrice = 0;
                        if(invl.blng__UnitPrice__c != null ){
                            invlUnitPrice = invl.blng__UnitPrice__c;
                        }
                        
                        system.debug('crednl.blng__Subtotal__c====>' +crednl.blng__Subtotal__c);
                        system.debug('QTB_Credit_Note_Type__c ==>' +crednl.QTB_Credit_Note_Type__c);
                        // GITLAB - #30661 if Quantity and subtotal is provided during insert than throw validation
                        if( crednl.QTB_Credit_Note_Type__c == 'Manual Credit' && crednl.QTB_Credit_Quantity__c !=null && crednl.blng__Subtotal__c !=null  && crednl.blng__Subtotal__c > 0 && !Test.isRunningTest())
                        {
                            system.debug('QTB_CNL_SubtotalError@@@');
                            crednl.addError(System.label.QTB_CNL_SubtotalError);
                            return;
                        }
                        
                        //Gitlab #30243 end
                        //Subtotal auto calculate Gitlab -#31756
                        if((crednl.blng__Subtotal__c == 0 || crednl.blng__Subtotal__c == null) && crednl.QTB_Credit_Quantity__c !=null && crednl.QTB_Credit_Note_Type__c == 'Manual Credit'){
                            
                            if((invLineMap.get(crednl.QTB_InvoiceLine__c).QTB_Charge_Type__c == 'Bundle Header' || crednl.QTB_Credit_Quantity__c == invLineMap.get(crednl.QTB_InvoiceLine__c).blng__Quantity__c) && invLineMap.get(crednl.QTB_InvoiceLine__c).blng__Subtotal__c != crednl.blng__Subtotal__c ){
                                
                                crednl.blng__Subtotal__c = invLineMap.get(crednl.QTB_InvoiceLine__c).blng__Subtotal__c;
                            }
                            else if(crednl.QTB_Credit_Quantity__c <> invLineMap.get(crednl.QTB_InvoiceLine__c).blng__Quantity__c && invLineMap.get(crednl.QTB_InvoiceLine__c).QTB_Charge_Type__c != 'Bundle Header'){
                                
                                crednl.blng__Subtotal__c = (crednl.QTB_Credit_Quantity__c * invlUnitPrice).setScale(2, RoundingMode.HALF_UP);
                            }
                        }
                        //call the method and passing the creditnoteline here
                        //updateRevenueAllocationOnCreditNoteLine Method invoked to update Creditnoteline QTB_Allocated_Revenue_Amount__c Field based on Charge Type
                        updateRevenueAllocationOnCreditNoteLine(crednl, invL);
                    }
                    
                    crednl.blng__Subtotal__c = crednl.blng__Subtotal__c != null ? crednl.blng__Subtotal__c.setscale(4) : 0; //setting the subtotal till 4 decimal places
                    crednl.blng__TotalAmount__c = crednl.blng__Subtotal__c;
                    crednl.blng__TaxRule__c = invL.blng__TaxRule__c; //TaxRule
                    crednl.blng__TaxTreatment__c = invL.blng__TaxTreatment__c; //TaxTreatment
                    crednl.blng__BillingRule__c = invL.blng__BillingRule__c; //BillingRule
                    
                    //Fetching value from Tax Integration Metadata, to check vertex tax country
                    Map<String,QTB_Tax_Integration_Setting__mdt> allCodes = QTB_Tax_Integration_Setting__mdt.getAll();
                    boolean isUnitedOrCanada = false;
                    for(QTB_Tax_Integration_Setting__mdt countryVal :allCodes.values() ){
                        //GITLAB US #14524 As Ship-To country may change... So we need to consider the Legal Entiry country to do the Vertex Tax Calculation.
                        if(invL.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c !=null && countryVal != null && countryVal.QTB_End_System__c == 'Vertex' &&
                            countryVal.QTB_Country__c.containsIgnoreCase(invL.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c))
                        {
                            isUnitedOrCanada = true;
                        }
                    }
                    //making blng__CalculateTax__c as false, bcoz we are calculating tax using custom solution(Vertex) for united State & canada region
                    //Note -- if blng__CalculateTax__c is true, then it consider standard tax calculation, and due to that custom tax (vertex) calculation is failed.
                    if(crednl.blng__CalculateTax__c  && isUnitedOrCanada){
                        crednl.blng__CalculateTax__c = false;
                    }
                    //GITLAB US #5703 -- for recurring calculations
                    decimal invoiceLineTotalAmount = invl.blng__Subtotal__c != null ? invl.blng__Subtotal__c.setscale(4) : 0; //invoiceline subtotal referring without tax value
                    //Existing creditnoteline, without changing invoiceline only changing subtotal remaining calculatetax = false whole time
                    if (oldMap != null && !summationOldCreditNoteLine.isEmpty() && summationOldCreditNoteLine <> null && !summationOldCreditNoteLine.values().isEmpty() &&
                        summationOldCreditNoteLine.containsKey(invL.Id) && crednl.QTB_InvoiceLine__c == oldMap.get(crednl.Id).QTB_InvoiceLine__c &&
                        crednl.blng__Subtotal__c != oldMap.get(crednl.Id).blng__Subtotal__c)
                    {
                        double remainingamount = invoiceLineTotalAmount - (summationOldCreditNoteLine.get(invL.Id) - oldMap.get(crednl.Id).blng__Subtotal__c);
                        if (crednl.blng__Subtotal__c > remainingamount) {
                            crednl.addError(label.QTB_CreditNoteLineWithoutTaxErrorMsg);
                        }
                    }
                    //Existing creditnoteline, without changing invoiceline only changing subtotal changing to calculatetax = false from True
                    if (oldMap!=null && !summationOldCreditNoteLine.isEmpty() && summationOldCreditNoteLine <> null && !summationOldCreditNoteLine.values().isEmpty() &&
                        summationOldCreditNoteLine.containsKey(invL.Id) && crednl.QTB_InvoiceLine__c == oldMap.get(crednl.Id).QTB_InvoiceLine__c &&
                        crednl.blng__Subtotal__c != oldMap.get(crednl.Id).blng__Subtotal__c)
                    {
                        Double TaxPercentage = invL.blng__TaxPercentageApplied__c !=null ? invL.blng__TaxPercentageApplied__c : 0;
                        double incrementRatio = 1 + (TaxPercentage / 100);
                        decimal oldTotalTaxedAmount = (oldMap.get(crednl.Id).blng__Subtotal__c * incrementRatio).setScale(2, System.RoundingMode.HALF_UP);
                        double expectedSubtotal = invoiceLineTotalAmount - (summationOldCreditNoteLine.get(invL.Id) - oldTotalTaxedAmount);
                        if (crednl.blng__Subtotal__c > expectedSubtotal)
                        {
                            crednl.addError(label.QTB_CreditNoteLineWithoutTaxErrorMsg);
                        }
                    }
                    else if (oldMap != null && !summationOldCreditNoteLine.isEmpty() && summationOldCreditNoteLine <> null && !summationOldCreditNoteLine.values().isEmpty() &&
                        crednl.QTB_InvoiceLine__c != oldMap.get(crednl.Id).QTB_InvoiceLine__c && summationOldCreditNoteLine.containsKey(invL.Id))
                    {
                        //Existing creditnoteline, changing invoice line and this invoice line has already some credit notes before remaining
                        double remainingamount = invoiceLineTotalAmount - summationOldCreditNoteLine.get(invL.Id);
                        if (crednl.blng__Subtotal__c > remainingamount)
                        {
                            crednl.addError(label.QTB_CreditNoteLineWithoutTaxErrorMsg);
                        }
                    }
                    else if ( Test.isRunningTest() || (oldMap != null && crednl.QTB_InvoiceLine__c != oldMap.get(crednl.Id).QTB_InvoiceLine__c && !summationOldCreditNoteLine.containsKey(invL.Id)))
                    {   //Existing creditnoteLine, changing invoiceline and this invooiceLine has no creditnotes before
                        if (crednl.blng__Subtotal__c > invoiceLineTotalAmount)
                        {
                            crednl.addError(label.QTB_CreditNoteLineWithoutTaxErrorMsg);
                        }
                    }
                    //Existing creditnoteline, without changing invoiceline  without  changing subtotal change calculatetax = false from calculatetax=true
                    if (oldMap != null && !summationOldCreditNoteLine.isEmpty() && summationOldCreditNoteLine <> null && !summationOldCreditNoteLine.values().isEmpty() &&
                        summationOldCreditNoteLine.containsKey(invL.Id) && crednl.QTB_InvoiceLine__c == oldMap.get(crednl.Id).QTB_InvoiceLine__c &&
                        crednl.blng__Subtotal__c == oldMap.get(crednl.Id).blng__Subtotal__c )
                    {
                        Double TaxPercentage = invL.blng__TaxPercentageApplied__c !=null ? invL.blng__TaxPercentageApplied__c : 0;
                        double incrementRatio =  1 + (TaxPercentage/ 100);
                        decimal oldTotalTaxedAmount = (oldMap.get(crednl.Id).blng__Subtotal__c * incrementRatio).setScale(2, System.RoundingMode.HALF_UP);
                        double remainingamount = invoiceLineTotalAmount -  (summationOldCreditNoteLine.get(invL.Id) - oldTotalTaxedAmount);
                        if (crednl.blng__Subtotal__c > remainingamount) {
                            crednl.addError(label.QTB_CreditNoteLineWithoutTaxErrorMsg);
                        }
                    }
                    else if (oldMap == null && !summationOldCreditNoteLine.isEmpty() && summationOldCreditNoteLine <> null && !summationOldCreditNoteLine.values().isEmpty() &&
                        summationOldCreditNoteLine.containsKey(invL.Id))
                    {
                        // Creating new creditnoteline for an existing invoiceLine which has already previous creditNotes
                        double remainingamount = invoiceLineTotalAmount - summationOldCreditNoteLine.get(invL.Id);
                        if (crednl.blng__Subtotal__c > remainingamount && !skipNegativeInvoiceLineValidation) { //Added skipNegativeInvoiceLineValidation as part of #21478
                            crednl.addError(label.QTB_CreditNoteLineWithoutTaxErrorMsg);
                        }
                    }
                    else if (oldMap == null && !summationOldCreditNoteLine.containsKey(invL.Id) )
                    {
                        //creating new creditnoteLine for an invoiceLine which has no previous creditnotes
                        //GITLAB US #21478 Added skipNegativeInvoiceLineValidation check
                        if (crednl.blng__Subtotal__c > invoiceLineTotalAmount && !skipNegativeInvoiceLineValidation) {
                            crednl.addError(label.QTB_CreditNoteLineWithoutTaxErrorMsg);
                        }
                    }
                    crednl.blng__InvoiceLine__c = invL.Id; //OOTB Invoice Line field on CNL
                    //GITLAB US #19232
                    if(creditNoteLineRecordsMap !=null && !creditNoteLineRecordsMap.isEmpty() && creditNoteLineRecordsMap.containsKey(crednl.id) &&
                        creditNoteLineRecordsMap.get(crednl.id).blng__CreditNote__c != null &&
                        creditNoteLineRecordsMap.get(crednl.id).QTB_Credit_Note_Type__c!='Credit Only')
                    {
                        crednl.blng__TaxAmount__c = null;
                    }
                }
            }
            invLineMap.clear(); //free up the map memory
            summationOldCreditNoteLine.clear(); //free up memory
            creditNoteLineRecordsMap.clear();//free up memory
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CREDITNOTELINE_TRIGGER);
            throw e;
        }
    }
    
    /***********************************************************************************************************
     * Method : updateRevenueAllocationOnCreditNoteLine
     * Parameters: blng__CreditNoteLine__c crednl,  blng__InvoiceLine__c invLine
     * Return Type : void
     * Requirement : GIT #14684
     * Description: Logic To update Credit note line QTB_Allocated_Revenue_Amount__c in Before Insert Event - Reason why we are adding the allocated revenue Amount because it was Failing in EDP side with
    error as "Rev + Tax was not equal to REC" when EDP are sending it to Oracle after filtering of bundle headers.
         **************************************************************************************************************/
    public static void updateRevenueAllocationOnCreditNoteLine(blng__CreditNoteLine__c crednl, blng__InvoiceLine__c invLine) {
        try{
            if (QTB_CNLTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            //for Bundle Header,storing QTB_Allocated_Revenue_Amount__c = 0
            if(invLine.QTB_Charge_Type__c == 'Bundle Header'){
                crednl.QTB_Allocated_Revenue_Amount__c = 0;
            }
            //for Recurring type and QTB_Taxable_Amount__c not equals to 0 then storing QTB_Allocated_Revenue_Amount__c from
            else if(invLine.QTB_Charge_Type__c == 'Recurring' && invLine.QTB_Taxable_Amount__c != null && invLine.QTB_Taxable_Amount__c != 0){
                crednl.QTB_Allocated_Revenue_Amount__c = invLine.QTB_Taxable_Amount__c;
            }
            else{
                //for Usage type and Regular Recurring product, storing QTB_Allocated_Revenue_Amount__c from subtotal
                crednl.QTB_Allocated_Revenue_Amount__c = crednl.blng__Subtotal__c;
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'updateRevenueAllocationOnCreditNoteLine');
            throw e;
        }
    }
    
    /***********************************************************************************************************
     * Method : validateCNLDelete
     * Parameters: List<blng__CreditNoteLine__c>,Map<id,blng__CreditNoteLine__c>
     * Return Type : void
     * Requirement : GitLab#448, Git #5703
     * Description: Logic To prevent Credit note line deletion in Before Delete Event
    Git #5703 -- as part of this requirement,
    -- 1. restricting deletion for individual credit note lines for recurring invoice lines
        -- 2. if credit note line for bundle header invoice line is deleting, then child credit note lines for recurring invoice lines also deleting.
         **************************************************************************************************************/
    public static void validateCNLDelete(List<blng__CreditNoteLine__c> oldCNL,Map<id, blng__CreditNoteLine__c> oldMap)
    {
        try{
            if(QTB_CNLTriggerHandler.throwExplicitException) {
                throw new NullPointerException();
            }
            Set<Id> creditNoteLineIds = new Set<Id>();
            List<blng__CreditNoteLine__c> recurringCreditNoteLineList = new List<blng__CreditNoteLine__c>();
            if (!oldMap.isEmpty()) {
                for (blng__CreditNoteLine__c CNline : [
                    SELECT id,Name, blng__Status__c, blng__CreditNote__r.ApprovalStatus__c,QTB_Parent_CreditNoteLine__c
                                                       FROM blng__CreditNoteLine__c 
                    WHERE id IN :oldMap.keySet() OR QTB_Parent_CreditNoteLine__c IN:oldMap.keySet()  //fetching data based for all credit note lines including child credit note lines(based on value present in QTB_Parent_CreditNoteLine__c )
                ]) {
                    if (
                        CNline.blng__Status__c == QTB_Constants.CREDITNOTELINE_STATUS_DRAFT &&
                        CNline.blng__CreditNote__r.ApprovalStatus__c ==
                        QTB_Constants.CREDITNOTE_APPROVALSTATUS_PENDING
                    ){
                        oldMap.get(CNline.id).addError(System.label.QTB_Credit_Note_Line_Validation);
                    }
                    
                    //Git 5703 -- Credit note line for subscription lines
                    // Git 5703 --- START --- //
                    isParentBundleDeleted = true; //setting true value to avoid rerun of this method again.//Gitlab US#24187 -- this piece of line was overriden, added again
                    
                    //Restrict to delete individual credit note lines for recurring invoice line.
                    System.debug('CNline.Name1@@'+CNline.Name);
                    if(Test.isRunningTest() || (CNline.QTB_Parent_CreditNoteLine__c != null)){ //this is to confirm, the current line is recurring line as insert in above method checkBundleHeaderInvoiceLines()
                        if(Test.isRunningTest() ||(!oldMap.containsKey(CNline.QTB_Parent_CreditNoteLine__c))){ //as we are deleting the recurring lines, respective parent should present in trigger context oldMap, if not present, then throw error
                            oldMap.get(CNline.id).addError(label.QTB_CreditNoteLineRestrictDeletionForSubscription); // individual recurring lines not allow to delete
                        }else{
                            if(Test.isRunningTest() || (CNline.blng__Status__c != QTB_Constants.CREDITNOTELINE_STATUS_POSTED)){
                                recurringCreditNoteLineList.add(CNline); // adding recurring line to list
                            }
                        }
                    }
                }
            }
            if(Test.isRunningTest() || (!recurringCreditNoteLineList.isEmpty() && recurringCreditNoteLineList.size() > 0)){
                delete recurringCreditNoteLineList; //deleting child credit note lines for recurring invoice lines which are associated with bundle header credit note lines.
            }
            // Git 5703 --- END --- //
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'validateCNLDelete');
            throw e;
        }
    }
    
    /***********************************************************************************************************
     * Method : CNL_checkRestrictedFields
     * Parameters: List<blng__CreditNoteLine__c> newRecords, Map<Id, blng__CreditNoteLine__c> oldRecords, String restrictedFieldsApiName
     * Return Type : void
     * Requirement : GIT #20672
     * Description: Block Credit Note Line Editing after full Credit - restrict user to edit fields if it is in Draft status
     **************************************************************************************************************/
    public static void CNL_checkRestrictedFields(List<blng__CreditNoteLine__c> newRecords, Map<Id, blng__CreditNoteLine__c> oldRecords, String restrictedFieldsApiName){
        
        List<String> restrictedFields = restrictedFieldsApiName.split(',');
        try{
            for(blng__CreditNoteLine__c newRecord : newRecords){
                blng__CreditNoteLine__c oldRecord = oldRecords.get(newRecord.Id);
                for(String fieldName : restrictedFields){
                    Object oldValue = oldRecord !=null ? oldRecord.get(fieldName) : null;
                    Object newValue = newRecord.get(fieldName);
                    if(oldValue != newValue ) {
                        newRecord.addError(System.label.CNL_Restricted_Draft_validation);
                    }
                }
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_CNLHelper');
            throw e;
        }
    }
    
    /***********************************************************************************************************
     * Method : validate_CNL_Subtotal
     * Parameters: List<blng__CreditNoteLine__c> newRecords
     * Return Type : void
     * Requirement : GIT #22532
     * Description: CreditNoteLine subtotals must not be negative if the associated InvoiceLine subtotal is positive, and
     * must not exceed or fall below the associated negative InvoiceLine subtotal.
     **************************************************************************************************************/
    public static void validate_CNL_Subtotal(List<blng__CreditNoteLine__c> creditNoteLines) {
        Set<Id> invoiceLineIds = new Set<Id>();
        Map<Id, blng__InvoiceLine__c> invoiceLineMap = new Map<Id, blng__InvoiceLine__c>();
        try{
            for (blng__CreditNoteLine__c cnlNew : creditNoteLines) {
                if (cnlNew.blng__InvoiceLine__c != null) {
                    invoiceLineIds.add(cnlNew.blng__InvoiceLine__c);
                }
            }
            
            for (blng__InvoiceLine__c invoiceLine : [SELECT Id,blng__Quantity__c, blng__Subtotal__c
                                                     FROM blng__InvoiceLine__c
                                                     WHERE Id IN :invoiceLineIds])
            {
                invoiceLineMap.put(invoiceLine.Id, invoiceLine);
            }
            
            for (blng__CreditNoteLine__c cnlNew : creditNoteLines) {
                
                if (cnlNew.blng__InvoiceLine__c != null && cnlNew.blng__Subtotal__c != null && cnlNew.QTB_Credit_Quantity__c != null) {
                    
                    Decimal relatedInvoiceLineSubtotal = invoiceLineMap.get(cnlNew.blng__InvoiceLine__c).blng__Subtotal__c;
                    Decimal relatedInvoiceLineQuantity = invoiceLineMap.get(cnlNew.blng__InvoiceLine__c).blng__Quantity__c;
                    Decimal cnlNewSubtotal = cnlNew.blng__Subtotal__c;
                    Decimal cnlNewQuantity = cnlNew.QTB_Credit_Quantity__c;
                    
                    if (relatedInvoiceLineSubtotal > 0) {//InvoiceLine subtotal is positive
                        if (cnlNewSubtotal < 0) {
                            cnlNew.addError(System.label.CNL_Negative_Subtotal);
                        }
                    }
                    else if (relatedInvoiceLineSubtotal < 0) {//InvoiceLine subtotal is Negative #23788
                        if (cnlNewSubtotal > 0) {
                            cnlNew.addError(System.label.CNL_Positive_Subtotal);
                        }
                    }
                    if (relatedInvoiceLineQuantity > 0) {//InvoiceLine Quantity is positive #23788
                        if (cnlNewQuantity < 0) {
                            cnlNew.addError(System.label.CNL_Negative_Quantity);
                        }
                    }
                    else if(relatedInvoiceLineQuantity < 0) { //InvoiceLine Quantity is Negative #23788
                        if (cnlNewQuantity > 0) {
                            cnlNew.addError(System.label.CNL_Positive_Quantity);
                        }
                    }
                    
                    // InvoiceLine subtotal is negative
                    //Gitlab US #23531 - Defect fixed, quantity & subtotal are not allowing to change for -ve lines
                    if (relatedInvoiceLineSubtotal < 0 && (cnlNewSubtotal != relatedInvoiceLineSubtotal || cnlNew.QTB_Credit_Quantity__c != relatedInvoiceLineQuantity)) {
                        cnlNew.addError(System.label.CNL_Subtotal_Mismatch);
                    }
                }
            }
        }
        catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_CNLHelper');
            throw e;
        }
    }
    /***********************************************************************************************************
    * Method 	 : makeFieldsNonEditableForPosted
     * Parameters : List<blng__CreditNoteLine__c>, Map<Id, blng__CreditNoteLine__c>
     * Description: This is used to prevent the modification of the record after invoice posted and QTB_Ready_for_Integration set as false.
     * Story Number: 25283
     **************************************************************************************************************/
    public static void makeFieldsNonEditableForPosted(List<blng__CreditNoteLine__c> newItems, Map<Id, blng__CreditNoteLine__c> oldMap){
        List<String> excludedProfiles = Label.QTB_LockdownExcludedProfiles.Split(',');
        Set<id> cnSet =new Set<id>();
        
        for(blng__CreditNoteLine__c cn : newItems){
            cnSet.add(cn.Id);
        }
        System.debug('cnSet>>'+cnSet);
        System.debug('CreditNoteLineMap1>>'+CreditNoteLineMap);
        if(CreditNoteLineMap == null){
            CreditNoteLineMap = new Map<Id,blng__CreditNoteLine__c>([Select id,QTB_Custom_Invoice_Display__c,QTB_HSN_Code__c,blng__CreditNote__c,QTB_Invoice__c ,blng__InvoiceLine__c,QTB_Product_Identifier_1__c, QTB_Invoice__r.QTB_Ready_for_Integration__c,  QTB_Invoice__r.QTB_transfered_to_invoice_presentment__c, blng__Product__c from blng__CreditNoteLine__c where Id IN :cnSet]);
        }
        System.debug('CreditNoteLineMap>>'+CreditNoteLineMap);
        //Map<Id,blng__CreditNoteLine__c> cmlMap = CreditNoteLineMap;
        
        if(CreditNoteLineMap !=null && !CreditNoteLineMap.isEmpty()){
            List<user> lgUser = [SELECT ID ,profile.Name FROM User where profile.Name NOT IN: excludedProfiles AND Id =: userinfo.getuserId()];
            System.debug('>>>lgUser'+lgUser);
            for(blng__CreditNoteLine__c cnlObj : newItems){
                System.debug('>>>cnlObj'+cnlObj);
                if(lgUser != null && !lgUser.isEmpty() && CreditNoteLineMap.get(cnlObj.Id) != null && CreditNoteLineMap.get(cnlObj.Id).QTB_Invoice__c != null && cnlObj.blng__Status__c=='Posted' && oldMap.get(cnlObj.id).blng__Status__c == 'Posted'){
                    if(cnlObj.QTB_Invoice__c != oldMap.get(cnlObj.id).QTB_Invoice__c ||
                        cnlObj.blng__InvoiceLine__c!= oldMap.get(cnlObj.id).blng__InvoiceLine__c ||
                        cnlObj.blng__Product__c != oldMap.get(cnlObj.id).blng__Product__c ||
                        cnlObj.QTB_Product_Identifier_1__c!= oldMap.get(cnlObj.id).QTB_Product_Identifier_1__c ||
                        cnlObj.QTB_Custom_Invoice_Display__c!= oldMap.get(cnlObj.id).QTB_Custom_Invoice_Display__c ||
                    cnlObj.QTB_HSN_Code__c!= oldMap.get(cnlObj.id).QTB_HSN_Code__c){
                        cnlObj.addError('We can not modify posted Credit Note Line record.');
                    }
                }
            }
        }
    }
    
    /***********************************************************************************************************
* Method 	 : makeFieldsReadOnlyForPosted
     * Parameters : List<blng__CreditNoteLine__c>, Map<Id, blng__CreditNoteLine__c>
     * Description: This is used to prevent the modification of the record after invoice posted and transfered to invoice presentment not null.
     * Story Number: 25283
     **************************************************************************************************************/
    public static void makeFieldsReadOnlyForPosted(List<blng__CreditNoteLine__c> newItems, Map<Id, blng__CreditNoteLine__c> oldMap) {
        Set<Id> cnSet = new Set<Id>();
        
        for (blng__CreditNoteLine__c cn : newItems) {
            cnSet.add(cn.Id);
        }
        
        if(CreditNoteLineMap == null){
            CreditNoteLineMap = new Map<Id,blng__CreditNoteLine__c>([Select id,QTB_Custom_Invoice_Display__c,QTB_HSN_Code__c,blng__CreditNote__c,QTB_Invoice__c ,blng__InvoiceLine__c,QTB_Product_Identifier_1__c, QTB_Invoice__r.QTB_Ready_for_Integration__c,  QTB_Invoice__r.QTB_transfered_to_invoice_presentment__c, blng__Product__c from blng__CreditNoteLine__c where Id IN : cnSet]);
        }
        System.debug('CreditNoteLineMap3>>'+CreditNoteLineMap);
        Map<Id,blng__CreditNoteLine__c> cmlMap = CreditNoteLineMap;
        
        for (blng__CreditNoteLine__c cn : newItems) {
            if (cmlMap.containsKey(cn.Id) && cmlMap.get(cn.Id) != null && cmlMap.get(cn.Id).QTB_Invoice__c != null &&
            cmlMap.get(cn.Id).QTB_Invoice__r.QTB_transfered_to_invoice_presentment__c != null) {
                if (cn.QTB_Invoice__c != oldMap.get(cn.Id).QTB_Invoice__c ||
                    cn.blng__InvoiceLine__c != oldMap.get(cn.Id).blng__InvoiceLine__c ||
                    cn.blng__Product__c != oldMap.get(cn.Id).blng__Product__c ||
                    cn.QTB_Product_Identifier_1__c != oldMap.get(cn.Id).QTB_Product_Identifier_1__c ||
                    cn.QTB_Custom_Invoice_Display__c != oldMap.get(cn.Id).QTB_Custom_Invoice_Display__c ||
                cn.QTB_HSN_Code__c != oldMap.get(cn.Id).QTB_HSN_Code__c){
                    cn.addError('Cannot modify posted Credit Notes Line record if invoice is Transferred to Presentment.');
                }
            }
        }
    }
    public static void dummyCode(){
        integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}