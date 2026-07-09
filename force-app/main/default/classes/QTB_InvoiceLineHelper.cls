/*****************************************************************************************************
* Class: QTB_InvoiceLineHelper
* Author: Accenture
* Purpose: This is a helper class for all business logic related to Invoice Line object
* Change History: 5/28/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Virtusa       12/27/2023     Tax Rounding for creation of Tax Detail records based on Tax Type Flat Rate AND Product Based
* Sarwar Baig   04/10/2025     Gitlab #29100 Changed the return types of All void methods(called from after update/after insert), 
                                                    optimized the code and performed one DML/Object
*******************************************************************************************************/
public with sharing class QTB_InvoiceLineHelper {
    
    public static final String INVOICELINE_HELPER = 'QTB_InvoiceLineHelper';
    
    /***********************************************************************************************************
* Method : trigController
* Parameters: List<blng__InvoiceLine__c>, Map<ID,blng__InvoiceLine__c>,System.TriggerOperation
* Return Type : void
* Description: Generic method to handle all operations on the InvoiceLine Records
* Developer     Date           Description
--------------------------------------------------------------------------------------
* Sarwar Baig   04/10/2025     Optimization of InvoiceLine Class(29100)
***************************************************************************************************************/
    public static void trigController(List<blng__InvoiceLine__c> newList,Map<ID,blng__InvoiceLine__c> oldMap,System.TriggerOperation operationType){
        if((newList.isEmpty() && oldMap.IsEmpty()) || operationType== null){ return;} // 29100 early exit

        Set<ID> usageIdSet = new Set<ID>();
        List<ID> invoiceIdList = new List<ID>(); //Gitlab 20432 List of Invoice Line ID for Tax Rounding
        Set<String> addressComparisonSet = new Set<String>(); //Gitlab 20432 Set to store address comparison String
        Map<ID,String> invoicePaymentTermMap = new Map <ID,String>();        
        Set<ID> invoiceIdForLegacyUpdateSet = new Set<ID>();  // #20657 store Invoice ID for Legacy update
        Set<ID> invcIdHoldBillingCheckSet = new Set<ID>();// #22554 store Invoice ID for Hold Bill Check
        List<blng__InvoiceLine__c> invLineForUOMTransList = new List<blng__InvoiceLine__c>(); // #24775 update UOM value invoice line List
        Map<ID,blng__Invoice__c> finalUpdateInvoiceMap = new Map<ID,blng__Invoice__c>(); //Gitlab 29100 Map of Invoice for Update
        Map<ID,blng__InvoiceLine__c> finalUpdateInvoiceLineMap = new Map<ID,blng__InvoiceLine__c>();//Gitlab 29100 Map of Invoice Line for Update
        Map<ID,blng__UsageSummary__c> finalMapUsageSummary = new Map<ID,blng__UsageSummary__c>();  //Gitlab 29100 Map of blng__UsageSummary__cfor Update
        Map<ID,blng__Usage__c> finalMapUsageDelete = new Map<ID,blng__Usage__c>(); //Gitlab 29100 Map of blng__Usage__c for delete
        Map<ID,blng__Usage__c> finalMapUsage = new Map<ID,blng__Usage__c>(); //Gitlab 29100 Map of blng__Usage__c for Update
        Map<ID,Account> finalMapAccount = new Map<ID,Account> (); //Gitlab 29100 Map of Account for Update
        Set<id> invoiceIdSet = new Set<id>();//Gitlab 34178 for Hong Kong Invoices showing New instead of Legacy in invoice type
        
        for (blng__InvoiceLine__c invLine : newList){
            switch on operationType{
                when AFTER_INSERT{

                    if((invLine.QTB_Payment_Term__c !=null && invLine.QTB_Payment_Term__c !='15' && invLine.QTB_Payment_Term__c !='30' && invLine.QTB_Payment_Term__c !='45' // 29100 added != null and used equalsIgnoreCase
                    && invLine.QTB_Payment_Term__c !='60' && invLine.QTB_Payment_Term__c !='90') && invLine.blng__InvoiceLineStatus__c.equalsIgnoreCase(QTB_Constants.INVOICELINE_STATUS_DRAFT)
                    && (invoicePaymentTermMap!=null && !invoicePaymentTermMap.containsKey(invLine.blng__Invoice__c))){ //#29100 merged the if statement, added null check
                    
                        invoicePaymentTermMap.put(invLine.blng__Invoice__c, invLine?.QTB_Payment_Term__c);
                    } 
                        
                    //Gitlab #20432 List of Invoice Line ID AND Set of Address Comparison String to fetch TaxRate Records when InvoiceLine status is Warning
                    // Updated the condition as below as tax override is not populating at rebill invoice level on credit rebill
                    // Gitlab US#25143 (Credit/Rebill Billnow)  Added condition equal to Completed for Rebill
                    if((invLine.blng__TaxStatus__c!=null && (invLine.blng__TaxStatus__c=='Warning' ||invLine.blng__TaxStatus__c == 'Completed')) || Test.isRunningTest()){
                    
                        // Create Set of Address comparison for fetching Tax Rate record based on address Comparison field on Tax Ratecompare address with Tax Rate addressComparisonSet field
                        String invoiceLineComparison = invLine?.blng__TaxCountry__c +'-' + invLine?.blng__TaxState__c +'-' + invLine?.blng__TaxCity__c +'-'
                                                         + invLine?.blng__TaxZipCode__c +'-' + invLine?.QTB_Tax_Code__c +'-' + invLine?.blng__LegalEntity__c;
                        invoiceLineComparison = invoiceLineComparison.replaceAll('null',''); 
                        if(invoiceIdList!=null && addressComparisonSet!=null && invoiceLineComparison!= null){ // added null check as part of 29100, removed (invLine.blng__Invoice__c!=null && )
                            addressComparisonSet.add(invoiceLineComparison);
                            invoiceIdList.add(invLine.blng__Invoice__c);
                        }
                    }
                    //Gitlab 34178 for Hong Kong Invoices showing New instead of Legacy in invoice type 
                    if(invLine.QTB_Is_Legacy__c== 'Legacy Invoice' && invLine.blng__TaxCountry__c!=null && Label.QTB_NoTaxableCountries.contains(invLine.blng__TaxCountry__c.replace(' ', '').toLowerCase())){
                        invoiceIdSet.add(invLine.blng__Invoice__c);
                    }
                }
                when AFTER_UPDATE{

                    if(usageIdSet!=null && invLine.blng__InvoiceLineStatus__c!=null && invLine?.blng__InvoiceLineStatus__c.equalsIgnoreCase(QTB_Constants.INVOICELINE_STATUS_CANCELLED)){ //29100 added equalsIgnoreCase
                        usageIdSet.add(invLine.blng__UsageSummary__c);
                    }
                    //Gitlab #20432 List of Invoice Line ID AND Set of Address Comparison String to fetch TaxRate Records when InvoiceLine status is Completed
                    //Gitlab #21798 on updating tax rule tax overide amount should get calculated //Gitlab #29100 added containsIgnoreCase //$29100 added containsKey
                    if(invoiceIdList!=null && addressComparisonSet!=null && (invLine.blng__TaxStatus__c!=null && invLine.blng__TaxRule__c!=null && invLine?.blng__TaxStatus__c.equalsIgnoreCase(QTB_Constants.INVOICELINE_TAX_STATUS_COMPLETED) &&(oldMap.containsKey(invLine.ID)) 
                    &&(oldMap.get(invLine.ID).blng__TaxStatus__c != invLine.blng__TaxStatus__c || oldMap.get(invLine.ID)?.blng__TaxRule__c != invLine?.blng__TaxRule__c ))  
                    ||(Label.QTB_NA_Countries!=null && Label.QTB_NA_Countries.containsIgnoreCase(invLine.blng__TaxCountry__c))){ //Populate TaxOverride for North America for Tax Override always
                        //irresepective of Tax Status - since Resend to Tax can be done irresepective of tax status - Story 21202
                    
                        //Create Set of Address comparison for fetching Tax Rate record based on address Comparison field on Tax Ratecompare address with Tax Rate addressComparisonSet field
                        String invoiceLineComparison = invLine?.blng__TaxCountry__c +'-' + invLine?.blng__TaxState__c +'-' +  invLine?.blng__TaxCity__c +'-' +
                                                        invLine?.blng__TaxZipCode__c +'-' + invLine?.QTB_Tax_Code__c +'-' + invLine?.blng__LegalEntity__c;
                        invoiceLineComparison = invoiceLineComparison.replaceAll('null',''); 
                        addressComparisonSet.add(invoiceLineComparison);
                        invoiceIdList.add(invLine?.blng__Invoice__c);// added null check as part of 29100
                    }
                    // #20657 store Invoice ID for Legacy update  
                    if((invLine.QTB_Is_Legacy__c== 'Legacy Invoice' && oldMap.get(invLine.ID).blng__TaxStatus__c != invLine.blng__TaxStatus__c 
                    &&invLine.blng__TaxStatus__c.equalsIgnoreCase(QTB_Constants.INVOICELINE_TAX_STATUS_COMPLETED)) ||Test.isrunningTest()){
                        invoiceIdForLegacyUpdateSet.add(invLine.blng__Invoice__c);
                    }
                    // #22554 store Invoice ID for Hold Bill Check // added null check as part of #29100 and optimized the If condition
                    // Checking the Tax Status to getting changed FROM its previous value
                    if(invcIdHoldBillingCheckSet!=null && invLine.blng__TaxStatus__c!=null && oldMap.get(invLine.ID).blng__TaxStatus__c != invLine.blng__TaxStatus__c 
                    &&invLine.blng__TaxStatus__c.equalsIgnoreCase(QTB_Constants.INVOICELINE_TAX_STATUS_COMPLETED) && invLine.QTB_Order_Category__c=='Hold Billing'){
                            
                        invcIdHoldBillingCheckSet.add(invLine.blng__Invoice__c);
                    }
                }
                when BEFORE_INSERT{
                    // #24775 update UOM translated value
                    if(invLineForUOMTransList!=null &&invLine!= null && invLine.QTB_AccountLanguage__c != null){ // 29100 added invLine!= null && invLineForUOMTransList!=null
                        invLineForUOMTransList.add(invLine);
                    }
                    //28275 - update product type based on price schedule category formula field
                    if(invLine.QTB_PriceScheduleCategoryType__c != null){
                        invLine.QTB_ProductType__c = invLine.QTB_PriceScheduleCategoryType__c;
                    }
                }
                when BEFORE_UPDATE{
                    //28275 - update product type based on price schedule category formula field
                    if(invLine.QTB_PriceScheduleCategoryType__c != oldMap.get(invLine.ID)?.QTB_PriceScheduleCategoryType__c){ // Gitlab #29100 added null check
                        invLine.QTB_ProductType__c = invLine.QTB_PriceScheduleCategoryType__c;
                    }
                }
            }
        }
        switch on operationType{
            when BEFORE_INSERT{
                // #24775 update UOM translated value
                if(invLineForUOMTransList!=null && !invLineForUOMTransList.isEmpty()){
                    QTB_InvoiceLineHelperUtils.setUOMcodeTranslation(invLineForUOMTransList,null); 
                    // 29100 its working on beforeInsert INVLINE AND afterUpdate for Account AND we need not take care of Acc helper
                }
            }
            when BEFORE_UPDATE{
                //25283 
                if(System.Label.IsInvoiceLineFieldsReadOnlyForPosted.equalsIgnoreCase('True')){ //Added back as some team will work on it
                   // makeFieldsReadOnlyForPosted(newList, oldMap);
                }
                if(System.Label.IsInvoiceLineFieldsNonEditableForPosted.equalsIgnoreCase('True')){
                   makeFieldsNonEditableForPosted(newList,oldMap);
                } 
                if(Test.isRunningTest()){
                  makeFieldsReadOnlyForPosted(newList, oldMap);  
                  makeFieldsNonEditableForPosted(newList, oldMap); 
                }
            } 
            when AFTER_INSERT{
                if(invoicePaymentTermMap!=null && !invoicePaymentTermMap.isEmpty()){ // modified as part of Gitlab #29100, changed thge return type
                
                    List<blng__Invoice__c> invDueDateList = updateInvoiceDueDate(invoicePaymentTermMap);
                    if(finalUpdateInvoiceMap!=null && invDueDateList!=null && !invDueDateList.isEmpty()){
                        for(blng__Invoice__c inv: invDueDateList){
                            finalUpdateInvoiceMap.put(inv.ID, inv);
                        }  
                    }// end of modification as part of 29100
                }
                //Gitlab #20432 fetch Invoice Line when Invoice Status is Draft or Initiated
                if(invoiceIdList!=null && addressComparisonSet!=null && !invoiceIdList.isEmpty() && !addressComparisonSet.isEmpty()){

                    //#33697 Added order != null check condition as tax override amount is calculated through batch class 'QTB_TaxOverrideAmountCalculationBatch' if invoice is created through invoice scheduler
             		Map<ID,blng__InvoiceLine__c> lstInvcLineMap = new Map<ID,blng__InvoiceLine__c>([SELECT ID,QTB_Tiered_Flag__c,blng__TaxAmount__c,QTB_Tax_Override_Amount__c,blng__Invoice__r.ID,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Invoice__r.blng__Subtotal__c,
                                                                                                    blng__LegalEntity__r.ID,blng__Invoice__r.blng__InvoiceStatus__c,
                                                                                                    blng__Invoice__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,blng__LegalEntity__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                                                                                    QTB_Tax_Code__c,blng__TaxTreatment__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c,blng__Invoice__r.blng__TaxAmount__c ,blng__Invoice__r.QTB_Invoice_Type__c,blng__LegalEntity__r.QTB_Tax_Applicability__c,
                                                                                                    blng__Invoice__r.blng__TotalAmount__c,blng__Invoice__r.QTB_Tax_Override_Amount__c,blng__Invoice__r.blng__NumberOfInvoiceLines__c,blng__UsageSummary__r.QTB_Contracted_Currency_Rate__c
                                                                                                    FROM blng__InvoiceLine__c 
                                                                                                    WHERE blng__Invoice__c IN :invoiceIdList and blng__Invoice__r.blng__Order__c !=null]); 
                    // to check and remove blng__UsageSummary__r.QTB_Contracted_Currency_Rate__c, blng__Invoice__r.blng__NumberOfInvoiceLines__c , blng__Invoice__r.blng__TotalAmount__c
                    
                    //QTB_InvoiceLineHelperUtils.updateInvcAndInvocLineWithTaxOverride(lstInvcLineMap,addressComparisonSet);
                    //#29100 changed the retirn type and performed proper null checks
                    List<SObject> recordsToUpdateList = QTB_InvoiceLineHelperUtils.updateInvcAndInvocLineWithTaxOverride(lstInvcLineMap,addressComparisonSet); 
                    if(recordsToUpdateList!=null && !recordsToUpdateList.isEmpty()){
                        // Segregate the records from the List<SObject>
                        for(SObject record : recordsToUpdateList){
                            if(finalUpdateInvoiceMap!=null && record instanceof blng__Invoice__c && !finalUpdateInvoiceMap.containsKey(record.ID)) {
                                finalUpdateInvoiceMap.put(record.ID,(blng__Invoice__c) record);// Cast to Invoice
                            }    
                            else if(finalUpdateInvoiceMap!=null && record instanceof blng__Invoice__c && finalUpdateInvoiceMap.containsKey(record.ID)){ //#29101 to avoid nullpointer errors
                                finalUpdateInvoiceMap.get(record.ID).put('QTB_Tax_Override_Amount__c', record.get('QTB_Tax_Override_Amount__c'));
                                finalUpdateInvoiceMap.get(record.ID).put('QTB_Total_Tax_Rate__c', record.get('QTB_Total_Tax_Rate__c'));
                                finalUpdateInvoiceMap.get(record.ID).put('QTB_hasTieredLines__c', record.get('QTB_hasTieredLines__c'));
                            }
                            else if(finalUpdateInvoiceLineMap!=null && record instanceof blng__InvoiceLine__c) {
                                finalUpdateInvoiceLineMap.put(record.ID,(blng__InvoiceLine__c) record); // Cast to Invoice Line
                            }
                        } 
                        recordsToUpdateList.clear(); // 29100 ends
                    }    
                }
                //Gitlab 34178 for Hong Kong Invoices showing New instead of Legacy in invoice type 
                if(invoiceIdSet!=null && !invoiceIdSet.isEmpty()){
                    List<blng__Invoice__c>  legacyInvoiceLst = QTB_InvoiceLineHelperUtils.updateLegacyInvoice(invoiceIdSet);
                    if(finalUpdateInvoiceMap!=null && legacyInvoiceLst!=null && !legacyInvoiceLst.isEmpty()){ //#29100 changed the return type method and Stroing the values in an InvoiceMap
                        for(blng__Invoice__c inv: legacyInvoiceLst){
                            if(finalUpdateInvoiceMap!=null && !finalUpdateInvoiceMap.containsKey(inv.ID)){
                                finalUpdateInvoiceMap.put(inv.ID,inv);
                            }else if(finalUpdateInvoiceMap!=null){ //#29100 to avoid nullpointer errors
                                finalUpdateInvoiceMap.get(inv.ID).put('QTB_Invoice_Type__c',inv.QTB_Invoice_Type__c);
                                finalUpdateInvoiceMap.get(inv.ID).put('QTB_Transferred_To_Oracle__c',inv.QTB_Transferred_To_Oracle__c);
                                finalUpdateInvoiceMap.get(inv.ID).put('QTB_Transferred_to_Invoice_Compliance__c',inv.QTB_Transferred_to_Invoice_Compliance__c);
                            }
                        }
                    }
                }
            }
            when AFTER_UPDATE{
                if(usageIdSet!=null && !usageIdSet.isEmpty()){ //#29100 Added null check on Set 
                    Map<String,List<SObject>> resultMap = cancelMinCharges(usageIdSet);//29100 On three diff. objects DML operations are happening
                    // Add records to their respective maps for update operations
                    if(resultMap!= null&& finalMapUsage!=null && resultMap.containsKey('updateUsage')){ //#29100 Added null check on Map 
                        List<blng__Usage__c> updateUsageList = resultMap.get('updateUsage');
                        if(updateUsageList!=null && updateUsageList.isEmpty()){
                            for (blng__Usage__c us : updateUsageList){
                                    finalMapUsage.put(us.ID, us);  // Add Usage records to finalMapUsage
                            }
                            updateUsageList.clear(); // clearing the Memory
                        }
                    }
                    if(resultMap!= null&& finalMapUsageSummary!=null && resultMap.containsKey('updateUsageSummary')){ //#29100 Added null check on Map 
                        List<blng__UsageSummary__c> updateUsageSummaryList = resultMap.get('updateUsageSummary');
                        if(updateUsageSummaryList!=null && updateUsageSummaryList.isEmpty()){
                            for (blng__UsageSummary__c usgs : updateUsageSummaryList){
                                finalMapUsageSummary.put(usgs.ID, usgs);  // Add UsageSummary records to finalMapUsageSummary
                            }
                            updateUsageSummaryList.clear();// clearing the Memory
                        }
                    }    
                    if(resultMap!= null && finalMapUsageDelete!=null && resultMap.containsKey('deleteUsage')){ //#29100 Added null check on Map 
                        List<blng__Usage__c> deleteUsageList = resultMap.get('deleteUsage');
                        if(deleteUsageList!=null && deleteUsageList.isEMpty()){
                            for (blng__Usage__c us : deleteUsageList){
                                finalMapUsageDelete.put(us.ID, us);  // Add Usage records to finalMapUsageDelete
                            }
                            deleteUsageList.clear();// clearing the Memory
                        }
                    }
                }   // 29100 ends
                //Gitlab #20432 fetch Invoice Line when Invoice Status is Draft
                if(invoiceIdList!=null && addressComparisonSet!=null && !invoiceIdList.isEmpty() && !addressComparisonSet.isEmpty()){
                
                    //#34196 added QTB_resendToVertex__c condition so that if resend to vertex button is clicked on invoice that is created through invoice scheduler, than tax override amount is updated on that invoice
                    //#33697 Added order != null check condition as tax override amount is calculated through batch class 'QTB_TaxOverrideAmountCalculationBatch' if invoice is created through invoice scheduler
                    Map<ID,blng__InvoiceLine__c> lstInvcLineMap = new Map<ID,blng__InvoiceLine__c>([SELECT ID,QTB_Tiered_Flag__c,blng__TaxAmount__c,QTB_Tax_Override_Amount__c,blng__Invoice__r.ID,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Invoice__r.blng__Subtotal__c,blng__LegalEntity__r.ID,blng__Invoice__r.blng__InvoiceStatus__c,
                                                              blng__Invoice__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,blng__LegalEntity__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                                              QTB_Tax_Code__c,blng__TaxTreatment__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c,blng__Invoice__r.blng__TaxAmount__c ,blng__Invoice__r.QTB_Invoice_Type__c,blng__LegalEntity__r.QTB_Tax_Applicability__c,
                                                              blng__Invoice__r.blng__TotalAmount__c,blng__Invoice__r.QTB_Tax_Override_Amount__c,blng__UsageSummary__r.QTB_Contracted_Currency_Rate__c
                                                              FROM blng__InvoiceLine__c 
                                                              WHERE blng__Invoice__c IN:invoiceIdList AND blng__Invoice__r.blng__InvoiceStatus__c =: QTB_Constants.INVOICE_STATUS_DRAFT 
                                                              and (blng__Invoice__r.blng__Order__c !=null OR blng__Invoice__r.QTB_resendToVertex__c = true)]) ; 
                    // blng__UsageSummary__r.QTB_Contracted_Currency_Rate__c, blng__Invoice__r.blng__NumberOfInvoiceLines__c , blng__Invoice__r.blng__TotalAmount__c
                    if (QTB_RecursiveHandlerCheck.updateInvcAndInvocLineWithTaxOverrideAmntAfterInsert!=null && QTB_RecursiveHandlerCheck.updateInvcAndInvocLineWithTaxOverrideAmntAfterInsert?.containsKey('afterinsert')) {
                        QTB_RecursiveHandlerCheck.updateInvcAndInvocLineWithTaxOverrideAmntAfterInsert.get('afterinsert').clear();
                    }//Gitlab US#29100 added containsKey in place of isEMpty
                    else{
                        //#29100 changed return type
                        List<SObject> recordsToUpdateList = QTB_InvoiceLineHelperUtils.updateInvcAndInvocLineWithTaxOverride(lstInvcLineMap,addressComparisonSet); 
                        if(recordsToUpdateList!=null &&!recordsToUpdateList.isEmpty()){
                            // Segregate the records from the List<SObject>
                            for(SObject record : recordsToUpdateList){
                                if(finalUpdateInvoiceMap!=null && record instanceof blng__Invoice__c && !finalUpdateInvoiceMap.containsKey(record.ID)) {
                                    finalUpdateInvoiceMap.put(record.ID,(blng__Invoice__c) record);// Cast to Invoice
                                }    
                                else if(finalUpdateInvoiceMap!=null && record instanceof blng__Invoice__c && finalUpdateInvoiceMap.containsKey(record.ID)){ //#29101 to avoid nullpointer errors
                                    finalUpdateInvoiceMap.get(record.ID).put('QTB_Tax_Override_Amount__c', record.get('QTB_Tax_Override_Amount__c'));
                                    finalUpdateInvoiceMap.get(record.ID).put('QTB_Total_Tax_Rate__c', record.get('QTB_Total_Tax_Rate__c'));
                                    finalUpdateInvoiceMap.get(record.ID).put('QTB_hasTieredLines__c', record.get('QTB_hasTieredLines__c'));
                                    finalUpdateInvoiceMap.get(record.ID).put('QTB_resendToVertex__c', record.get('QTB_resendToVertex__c'));
                                }
                                else if(finalUpdateInvoiceLineMap!=null && record instanceof blng__InvoiceLine__c) {
                                    finalUpdateInvoiceLineMap.put(record.ID,(blng__InvoiceLine__c) record); // Cast to Invoice Line
                                }
                                else if(finalUpdateInvoiceLineMap!=null && record instanceof blng__InvoiceLine__c && finalUpdateInvoiceLineMap.containsKey(record.ID)){ //#29101 to avoid nullpointer errors
                                    finalUpdateInvoiceLineMap.get(record.ID).put('QTB_Tax_Override_Amount__c', record.get('QTB_Tax_Override_Amount__c'));
                                    finalUpdateInvoiceLineMap.get(record.ID).put('QTB_Total_Tax_Rate__c', record.get('QTB_Total_Tax_Rate__c'));
                                }
                            } 
                            recordsToUpdateList.clear();// #29100 code ends after clearing the Map
                        }
                   }  
                } 
                // #20657 store Invoice ID for Legacy update
                if(invoiceIdForLegacyUpdateSet!=null && !invoiceIdForLegacyUpdateSet.isEmpty()){
                    List<blng__Invoice__c>  legacyInvoiceList = QTB_InvoiceLineHelperUtils.updateLegacyInvoice(invoiceIdForLegacyUpdateSet);
                    if(finalUpdateInvoiceMap!=null && legacyInvoiceList!=null && !legacyInvoiceList.isEmpty()){ //#29100 changed the return type method and Stroing the values in an InvoiceMap
                        for(blng__Invoice__c inv: legacyInvoiceList){
                            if(finalUpdateInvoiceMap!=null && !finalUpdateInvoiceMap.containsKey(inv.ID)){
                                finalUpdateInvoiceMap.put(inv.ID,inv);
                            }else if(finalUpdateInvoiceMap!=null){ //#29100 to avoid nullpointer errors
                                finalUpdateInvoiceMap.get(inv.ID).put('QTB_Invoice_Type__c',inv.QTB_Invoice_Type__c);
                                finalUpdateInvoiceMap.get(inv.ID).put('QTB_Transferred_To_Oracle__c',inv.QTB_Transferred_To_Oracle__c);
                                finalUpdateInvoiceMap.get(inv.ID).put('QTB_Transferred_to_Invoice_Compliance__c',inv.QTB_Transferred_to_Invoice_Compliance__c);
                            }
                        }
                    }
                }
                // #22554 store Invoice ID for Hold Bill Check
                if(invcIdHoldBillingCheckSet!=null && !invcIdHoldBillingCheckSet.isEmpty()){//#29100 added invcIdHoldBillingCheckSet!=null
                    List<blng__InvoiceLine__c> listInvcLine = [SELECT ID,blng__InvoiceLineStatus__c,blng__UsageSummary__c,blng__UsageSummary__r.ID,blng__UsageSummary__r.blng__InvoiceRunProcessingStatus__c,
                                                            blng__UsageSummary__r.blng__InvoiceRun__c,blng__UsageSummary__r.blng__InvoiceRunStartDate__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                            blng__Invoice__c, blng__Invoice__r.QTB_Invoice_Type__c, blng__Invoice__r.ID, blng__Invoice__r.blng__InvoiceRunCreatedBy__c, blng__Invoice__r.blng__Account__r.ID, blng__Invoice__r.blng__InvoiceStatus__c, blng__Invoice__r.blng__Account__c, blng__Invoice__r.blng__Account__r.QTB_Hold_Status__c,blng__Invoice__r.blng__Account__r.QTB_Hold_Billing__c
                                                            FROM blng__InvoiceLine__c 
                                                            WHERE blng__Invoice__c IN:invcIdHoldBillingCheckSet AND blng__Invoice__r.QTB_Invoice_Type__c!='ReBill' AND blng__Invoice__r.QTB_Invoice_Type__c!='Legacy Invoice' 
                                                            AND blng__Invoice__r.blng__InvoiceStatus__c =: QTB_Constants.INVOICE_STATUS_DRAFT  ];            
                    // QTB_Hold_Billing__c , blng__InvoiceLineStatus__c , blng__UsageSummary__c , blng__UsageSummary__r.blng__InvoiceRunStartDate__c
                    
                    if(listInvcLine!=null && !listInvcLine.isEmpty()){ //#29100 added null check and changed the retrun type
                        List<SObject> recordSObjectList = QTB_InvoiceLineHelperUtils.cancelInvoicesWithHoldBilling(listInvcLine);  
                        // #29100 we took return of two Lists and allowed one to update as theyre briefly disabiling SBQQ trigger
                        // Segregate the records from the List<SObject>
                        if(recordSObjectList!= null && !recordSObjectList.IsEmpty()){
                            for(SObject record : recordSObjectList){
                                if(finalMapAccount!=null && record instanceof Account) {
                                    finalMapAccount.put(record.ID,(Account) record);// Cast to Account
                                }else if(finalMapUsageSummary!=null && record instanceof blng__UsageSummary__c && !finalMapUsageSummary.containsKey(record.ID)) {
                                    finalMapUsageSummary.put(record.ID,(blng__UsageSummary__c) record);// Cast to blng__UsageSummary__c
                                }else if(finalMapUsageSummary!=null && record instanceof blng__UsageSummary__c && finalMapUsageSummary.containsKey(record.ID)){ 
                                    finalMapUsageSummary.get(record.ID).put('blng__InvoiceRun__c', record.get('blng__InvoiceRun__c'));
                                    finalMapUsageSummary.get(record.ID).put('blng__InvoiceRunProcessingStatus__c',record.get('blng__InvoiceRunProcessingStatus__c'));
                                    finalMapUsageSummary.get(record.ID).put('blng__InvoiceRunStartDate__c',record.get('blng__InvoiceRunStartDate__c'));
                                }
                            } 
                            recordSObjectList.clear();// #29100 code ends after clearing the Map
                        }
                    }
                }
            }
        }
        // finalMapAccount moved outside the loop as part of 29100 optimization
        if(finalMapAccount!=null && !finalMapAccount.isEmpty()){
            update finalMapAccount.values();
        }
        // finalUpdateInvoiceMap moved outside the loop as part of 29100 optimization, 
        if(finalUpdateInvoiceMap != null && !finalUpdateInvoiceMap.isEmpty()){
            update finalUpdateInvoiceMap.values();
        }
        // finalUpdateInvoiceLineMap moved outside the loop as part of 29100 optimization 
        if(finalUpdateInvoiceLineMap != null && !finalUpdateInvoiceLineMap.isEmpty()){
            update finalUpdateInvoiceLineMap.values();
        }
        // finalMapUsageSummary moved outside the loop as part of 29100 optimization
        if(finalMapUsageSummary != null && !finalMapUsageSummary.isEmpty()){
            update finalMapUsageSummary.values();
        }
        // finalMapUsage moved outside the loop as part of 29100 optimization 
        if(finalMapUsage != null && !finalMapUsage.isEmpty()){
            update finalMapUsage.values();
        }
        // finalMapUsageDelete moved outside the loop as part of 29100 optimization
        if(finalMapUsageDelete != null && !finalMapUsageDelete.isEmpty()){
            delete finalMapUsageDelete.values();
        }
        finalUpdateInvoiceLineMap.clear();
        finalUpdateInvoiceMap.clear();
        invoicePaymentTermMap.clear();
        invoiceIdList.clear();
        addressComparisonSet.clear();
        usageIdSet.clear();
        invoiceIdForLegacyUpdateSet.clear();
        invcIdHoldBillingCheckSet.clear();
        invLineForUOMTransList.clear();
        finalMapUsageSummary.clear();
        finalMapUsage.clear();
        finalMapUsageDelete.clear();
        finalMapAccount.clear();
        invoiceIdSet.clear();
    }
    
/***********************************************************************************************************
* Method : updateInvoiceDueDate
* Parameters: Map<ID,String>
* Return Type : List<blng__Invoice> FROM void as part of 29100
* Requirement : SFCPQBLG-915
* Description : This is having the Functionality to update Due date of Invoice
* Developer     Date           Description
--------------------------------------------------------------------------------------
* Sarwar Baig   04/10/2025     Optimization of InvoiceLine Class(Gitlab User Story #29100)
**************************************************************************************************************/
    public static List<blng__Invoice__c> updateInvoiceDueDate(Map<ID,String> invoicePaymentTermMap){
        try{
            if(QTB_InvoiceLineTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(invoicePaymentTermMap ==null || invoicePaymentTermMap.isEmpty()) {return null;} //#Gitlab 29100 return null and early exit if invoicePaymentTermMap is null
            
            List<blng__Invoice__c> updatedInvoiceDueDateList = new List<blng__Invoice__c>();
            for(blng__Invoice__c invoice : [SELECT ID,blng__InvoiceDate__c,blng__DueDate__c,blng__InvoiceStatus__c 
                                            FROM blng__Invoice__c
                                            WHERE ID IN :invoicePaymentTermMap.keySet() ]){ 
            // blng__DueDate__c can be removed from SOQL fetched list
                if(updatedInvoiceDueDateList!=null && invoice.blng__InvoiceDate__c!=null && invoicePaymentTermMap!=null && invoicePaymentTermMap.get(invoice.ID)!=null){
                    invoice.blng__DueDate__c = invoice.blng__InvoiceDate__c + Integer.ValueOf(invoicePaymentTermMap.get(invoice.ID));
                    updatedInvoiceDueDateList.add(invoice);
                }
            }
            if(updatedInvoiceDueDateList!=null && !updatedInvoiceDueDateList.isEmpty()){
                invoicePaymentTermMap.clear(); //free-up the memory
                return updatedInvoiceDueDateList; // Modified as part of #29100 optimization
            }else{
                return null;// Modified as part of  29100 optimization
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),
                                                    e.getMessage(),e.getTypeName(),INVOICELINE_HELPER);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method : cancelMinCharges
* Parameters: Set<ID>
* Return Type : void to Map<String,List<SObject>>  as part of 29100
* Requirement : SFCPQBLG-88
* Description: This is having the Functionality related to Bill backout process.
* Developer     Date           Description
--------------------------------------------------------------------------------------
* Sarwar Baig   04/10/2025     Optimization of InvoiceLine Class(29100)
**************************************************************************************************************/
    public static Map<String,List<SObject>> cancelMinCharges(Set<ID> usgsId){
        try{
            if(QTB_InvoiceLineTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(usgsId== null || usgsId.isEmpty()){return null;} //Gitlab #29100 return null if usgsId and exit early

            List<blng__UsageSummary__c> usumList = new List<blng__UsageSummary__c>();
            List<blng__Usage__c> usgList = new List<blng__Usage__c>();
            Map<String,List<SObject>> resultMap = new Map<String,List<SObject>>(); //Gitlab #29100 declared Map<String,List<SObject>> to store various diff Sobjects with diff DML operations to be performed
            //Map for storing Usage records
            Map<ID,blng__Usage__c> usagesMap = new Map<ID,blng__Usage__c>([SELECT ID,QTB_System_Generated__c,QTB_System_Cancelled__c,blng__Quantity__c,blng__PreratedQuantity__c, blng__Subtotal__c,blng__PreratedAmount__c,blng__UsageSummary__c,blng__UsageSummary__r.blng__PreratedQuantity__c,
                                                                        blng__UsageSummary__r.blng__Subtotal__c,blng__UsageSummary__r.blng__PreratedAmount__c,blng__UsageSummary__r.blng__TotalQuantity__c,blng__UsageSummary__r.blng__UnbilledQuantity__c                                                        
                                                                        FROM blng__Usage__c 
                                                                        WHERE QTB_System_Generated__c= true AND blng__UsageSummary__c IN: usgsId  ]); 
            if(usagesMap==null || usagesMap.isEmpty()){return null;} //Gitlab #29100 return null if usgsId and exit early
            // remove QTB_System_Generated__c, blng__Quantity__c and ask QTB_System_Cancelled__c
            
            //Loop for iterating the Usage records AND updating field on Usage Summary Records
            for(blng__Usage__c us : usagesMap.values()){ 
            // 29100 optimized by adding null checks and ternary operators
                if(us.blng__UsageSummary__c != null && us.blng__UsageSummary__r != null){ //#Gitlab29100 (us.blng__UsageSummary__r) checks if the related record (sObject) itself is not null.
                    blng__UsageSummary__c usgsum = new blng__UsageSummary__c();
                    usgsum.ID = us.blng__UsageSummary__c;
                    
                    usgsum.blng__Subtotal__c = ((us.blng__UsageSummary__r?.blng__Subtotal__c != null) ? (us.blng__UsageSummary__r.blng__Subtotal__c) :( 0)) 
                                            - ((us.blng__PreratedAmount__c != null) ? (us.blng__PreratedAmount__c):( 0));
                    usgsum.blng__PreratedAmount__c = ((us.blng__UsageSummary__r?.blng__PreratedAmount__c != null) ?(us.blng__UsageSummary__r.blng__PreratedAmount__c ): (0)) 
                                                    - ((us.blng__PreratedAmount__c != null) ? (us.blng__PreratedAmount__c ): (0));
                    usgsum.blng__PreratedQuantity__c = ((us.blng__UsageSummary__r?.blng__PreratedQuantity__c != null) ? (us.blng__UsageSummary__r.blng__PreratedQuantity__c) : (0)) 
                                                    - ((us.blng__PreratedQuantity__c != null) ? (us.blng__PreratedQuantity__c): (0));
                    usgsum.blng__TotalQuantity__c = ((us.blng__UsageSummary__r?.blng__TotalQuantity__c != null )? (us.blng__UsageSummary__r.blng__TotalQuantity__c) : (0)) 
                                                - ((us.blng__PreratedQuantity__c != null )? (us.blng__PreratedQuantity__c) : (0));
                    usgsum.blng__UnbilledQuantity__c = ((us.blng__UsageSummary__r?.blng__UnbilledQuantity__c != null) ? (us.blng__UsageSummary__r.blng__UnbilledQuantity__c) : (0)) 
                                                    - ((us.blng__PreratedQuantity__c != null )? (us.blng__PreratedQuantity__c ): (0));
                    us.QTB_System_Cancelled__c = true;
                    usgList.add(us);
                    usumList.add(usgsum);
                }
            }
            if(usgList!=null && !usgList.isEmpty()){
                resultMap.put('updateUsage', usgList); //#29100 changed from Database.update(usgList,false); 
                usgList.clear(); // ##29100 clear list and Maps only when it has data and after assigning to finalMap
            }
            if(usumList!=null && !usumList.isEmpty()){
                resultMap.put('updateUsageSummary', usumList); //#29100 changed from Database.update(usumList,false);
                 usumList.clear(); // ##29100 clear list and Maps only when it has data and after assigning to finalMap
             }
            if(usagesMap!=null && !usagesMap.values().isEmpty()){ //Deleting Minimum Storage Charges Usage record.
                resultMap.put('deleteUsage', usagesMap.values()); //#29100 changed from Delete usagesMap.values(); 
                usagesMap.clear();// ##29100 clear list and Maps only when it has data and after assigning to finalMap
            }
            if(resultMap!=null && !resultMap.isEmpty()){ //# 29100 changed return type
                usagesMap.clear(); // ##29100 clear list and Maps
                return resultMap;
            } else{
                return null;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),
                                e.getMessage(),e.getTypeName(),INVOICELINE_HELPER);
            throw e;
        }
    }

/*************************************************************************************************************************
* Method    : makeFieldsNonEditableForPosted
* Parameters : List<blng__InvoiceLine__c>, Map<ID, blng__InvoiceLine__c>
* Description: This is used to prevent the modification of the record after invoice posted AND QTB_Ready_for_Integration__c Set as true or false.
* Story Number: 25283 
* Developer     Date           Description
--------------------------------------------------------------------------------------
* Sarwar Baig   04/10/2025     Optimization of InvoiceLine Class(29100)
**************************************************************************************************************/
    
    public static void makeFieldsNonEditableForPosted(List<blng__InvoiceLine__c> newItems, Map<ID, blng__InvoiceLine__c> oldMap){  
        try{
            if(QTB_InvoiceLineTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(newItems== null || oldMap== null || newItems.isEmpty() || oldMap.isEmpty()){ return;} // 29100 early exit if its null 

            List<String> excludedProfilesList; // 29100 did not assign until null check is done and placed it inside try block
            Set<ID> invoiceIdSet = new Set<ID>();
            Map<ID,blng__Invoice__c> invoiceMap;

            for(blng__InvoiceLine__c invLineObj : newItems){
                if(invLineObj.blng__InvoiceLineStatus__c!=null && invLineObj.blng__InvoiceLineStatus__c.equalsIgnoreCase(QTB_Constants.INVOICELINE_STATUS_POSTED) && oldMap.get(invLineObj.ID)?.blng__InvoiceLineStatus__c.equalsIgnoreCase(QTB_Constants.INVOICELINE_STATUS_POSTED)){
                    invoiceIdSet.add(invLineObj.blng__Invoice__c); //#29100 each invLine will have an Invoice so we need not check null
                }
            }
            if(invoiceIdSet== null || invoiceIdSet.isEmpty()){ return; } // 29100 early exit if its null and to avoid deep nested if
            invoiceMap = new Map<ID,blng__Invoice__c>([SELECT ID, blng__InvoiceStatus__c, QTB_Ready_for_Integration__c 
                                                        FROM blng__Invoice__c 
                                                        WHERE ID IN : invoiceIdSet ]);
            // can remove , QTB_Ready_for_Integration__c  29100

            if(String.isNotBlank(Label.QTB_LockdownExcludedProfiles) && Label.QTB_LockdownExcludedProfiles != null){ // 29100 added null check and pushed assignment within bracket
                excludedProfilesList = Label.QTB_LockdownExcludedProfiles.split(','); 
            }

            if(invoiceMap == null || invoiceMap.isEmpty() || userinfo.getuserId()==null ||excludedProfilesList==null|| excludedProfilesList.isEmpty()){return;} // 29100 early exit if its null and to avoid deep nested if

            List<User> lgUser = [SELECT ID,Name,profile.Name 
                                FROM User 
                                WHERE profile.Name NOT IN: excludedProfilesList AND ID =: userinfo.getuserId() ];
            
            if(lgUser ==null || lgUser.isEmpty() ){return;} // 29100 early exit if its null and to avoid deep nested if

            for(blng__InvoiceLine__c invLine: newItems){

                // merged conditions as part of 29100 to resolve sonarqube relaed issues and removed (lgUser != null &&) condition from IF
                if(invoiceMap.get(invLine.blng__Invoice__c) != null && invLine?.blng__InvoiceLineStatus__c.equalsIgnoreCase(QTB_Constants.INVOICELINE_STATUS_POSTED)
                    &&(invLine?.QTB_End_Date_MRC__c != oldMap.get(invLine.ID)?.QTB_End_Date_MRC__c || invLine?.QTB_Start_Date_MRC__c != oldMap.get(invLine.ID)?.QTB_Start_Date_MRC__c)){
                
                    invLine.addError(System.Label.QTB_makeInvoiceLineFieldsNonEditableForPosted);//#29100 Used Custom Labels to throw error
                }
            } 
            invoiceMap.clear(); //free-up the memory 
            invoiceIdSet.clear(); //free-up the memory
            excludedProfilesList.clear();
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),
                                        e.getMessage(),e.getTypeName(),INVOICELINE_HELPER);
            throw e;
        }
    }
    
    /***********************************************************************************************************
    * Method    : makeFieldsReadOnlyForPosted
    * Parameters : List<blng__InvoiceLine__c>, Map<ID, blng__InvoiceLine__c>
    * Description: This is used to prevent the modification of the record after record status is Posted AND transfered to invoice presentment on invoice is not null.
    * Story Number: 25283 
    * Developer     Date           Description
    --------------------------------------------------------------------------------------
    * Sarwar Baig   04/10/2025     Optimization of InvoiceLine Class(29100)
    **************************************************************************************************************/
    public static void makeFieldsReadOnlyForPosted(List<blng__InvoiceLine__c> newItems, Map<ID, blng__InvoiceLine__c> oldMap){
        try{
            if(QTB_InvoiceLineTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(newItems == null|| oldMap == null|| newItems.isEmpty() || oldMap.isEmpty()){ return;} //Gitlab #29100 return early if null

            Set<ID> invoiceIdSet = new Set<ID>();
            Map<ID,blng__Invoice__c> invoiceMap ;

            for(blng__InvoiceLine__c invLineObj : newItems){  //Gitlab #29100 added equalsIgnoreCase in place of ===
                if(invLineObj.blng__InvoiceLineStatus__c!=null && invoiceIdSet!=null && oldMap.get(invLineObj.ID).blng__InvoiceLineStatus__c!=null && invLineObj.blng__InvoiceLineStatus__c.equalsIgnoreCase(QTB_Constants.INVOICELINE_STATUS_POSTED) 
                && oldMap.get(invLineObj.ID).blng__InvoiceLineStatus__c.equalsIgnoreCase(QTB_Constants.INVOICELINE_STATUS_POSTED)){
                    invoiceIdSet.add(invLineObj.blng__Invoice__c);
                }    
            }
            if(invoiceIdSet == null || invoiceIdSet.isEmpty()){ return;} //Gitlab #29100 return early if invoiceIdSet is empty
            
            invoiceMap = new Map<ID,blng__Invoice__c>([SELECT ID, blng__InvoiceStatus__c, QTB_transfered_to_invoice_presentment__c 
                                                        FROM blng__Invoice__c
                                                        WHERE ID IN : invoiceIdSet ]); 
            
            if(invoiceMap == null || invoiceMap.isEmpty()){ return;} //Gitlab #29100 return early if invoiceMap is empty
            
            for(blng__InvoiceLine__c invLine: newItems){
                if(invoiceMap.get(invLine.blng__Invoice__c)!= null && invoiceMap.get(invLine.blng__Invoice__c).QTB_transfered_to_invoice_presentment__c != null && invLine?.blng__InvoiceLineStatus__c.equalsIgnoreCase(QTB_Constants.INVOICELINE_STATUS_POSTED)
                &&(invLine?.QTB_End_Date_MRC__c != oldMap.get(invLine.ID)?.QTB_End_Date_MRC__c || invLine?.QTB_Start_Date_MRC__c != oldMap.get(invLine.ID)?.QTB_Start_Date_MRC__c)){
                    // 29100 merged if  
                    invLine.addError(System.Label.QTB_InvoiceLineFieldsReadOnlyForPosted); // 29100 merged if and used Custom Labels to throw error
                }
            } 
            invoiceMap.clear(); 
            invoiceIdSet.clear(); //free-up the memory
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),
                                        e.getMessage(),e.getTypeName(),INVOICELINE_HELPER);
            throw e;
        }
    } 
}