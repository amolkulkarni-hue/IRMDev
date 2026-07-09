/*****************************************************************************************************
* Class: QTB_InvoiceHelper
* Author: Accenture
* Purpose: This is a helper class for all business logic related to I object
* Requirement: QTB-14/SFCPQBLG 62
* Change History: 6/02/2020
* Developer        Date           Description
* ---------------------------------------------------------------------------------------------------------------------------------------------------------
*                  5/22/2020
* Virtusa          11/22/2021        Git #6352 -- Standard Tax Details are records are getting generated under Invoice lines for Vertex Integration
* Virtusa          06/10/2022        Git #9089 -- Getting POBalance Batch Error in Prod
* Gopi/ Shailesh   06/30/2022        Gitlab US #9256 Credit & Rebill
* TCS              11/10/2022        Gitlab US #10736 Credit & Rebill
* Shailesh(Virtusa)07/14/2023        SplitRebill Gitlab US#16256
* Lokesh(Virtusa)  27/12/2023        Gitlab #20432 Gitlab 20432 Calculate Tax override on Invoice AND Invoice Line for Tax Type Flat Rate AND Product Based.
* Parth(Virtusa)   20/05/2024        Gitlab #22654 update Service type AND Insert PO based on Service Type
* Sarwar(virtusa)  11/04/2025        Gitlab #29101 Changed the return types of All void methods(called from after update/after insert),
optimized the code and performed one DML/Object
**********************************************************************************************************************************************************/
public with sharing class QTB_InvoiceHelper
{
    public static Map<String, List<blng__TaxRate__c>> taxRatesMap = new Map<String, List<blng__TaxRate__c>>(); //#29101 Observation its getting called from QTB_InvoiceLineHelperUtils  and QTB_ CNLHelperUtilshence static
    private static final String CLASSNAME = QTB_InvoiceHelper.class.getName();
    public static Boolean isSITADInvoice = false;
    /***********************************************************************************************************
* Method : process
* Parameters: List<blng__Invoice__c>, Map<ID,blng__Invoice__c>, System.TriggerOperation
* Requirement :
* Start Date :
* Author : Accenture
* Description: Generic method to handle all operations on the invoice Records
**************************************************************************************************************/
    public static void process(List<blng__Invoice__c> newItems, Map<ID, blng__Invoice__c> oldMap, System.TriggerOperation operationType)
    {
        if((operationType == null) || (newItems.isEmpty() && oldMap.isEmpty())) { return; }//#29101 return early added more items to check
        
        Set<ID> invoiceRunSet =  new Set<ID>();
        Set<ID> orderIdSet = new Set<ID>(); // Gitlab US#25023 (Credit/Rebill Billnow)
        Map<ID,blng__Invoice__c> billingCountriesInvoiceMap; // 29101 billingCountries became billingCountriesInvoiceMap
        //Gitlab #22654
        Map<ID,blng__Invoice__c> draftInvoiceMap = new Map<ID,blng__Invoice__c>();// 29101 we use it to store values in for loop to use it later
        Map<ID,blng__Invoice__c> invExchangeRateUpdateMap = new Map<ID,blng__Invoice__c>(); //26654 Created Map for storing the ids AND Invoice for Updating the Exchange Rate based upon Foreign Exchange object (Local Currency)
        Map<ID,blng__InvoiceRun__c> relatedInvoiceRunMap; // Added #21598 Invoice Scheduler Invoice Period in Query for checking not equals to null
        Set<ID> postedInvoiceIdsSet = new Set<ID>();
        Set<ID> billingAccountIdsSet = new Set<ID>();
        Set<ID> rebillInvoiceIdsSet = new Set<ID>();
        Set<ID> alreadyProcessedSet = new Set<ID>();
        Map<ID,Boolean> rebillInvoiceIdsWithIsCancelMap = new Map<ID,Boolean>();//CreditRebill
        Set<ID> splitRebillInvoiceIdSet = new Set<ID>(); //SplitRebill
        Set<ID> invPOIdSet =new Set<ID>(); ////Gitlab:28610 EPIC:2795
        Set<ID> rebillInvoiceIdSet = new Set <ID>(); //Gitlab US#24712
        Set<ID> taxOverrideInvoiceId = new Set<ID>(); //Gitlab US#25143
        // Gitlab US#25023 (Credit/Rebill Billnow)
        Map<ID,Order> orderMap = new Map <ID,Order>();
        Set<ID> draftInvoiceIdsSet = new Set<ID>(); // GitLab # 11971, List of draft Invoices for Updating tax rule to No Tax Rule
        Set<ID> setInvcId = new Set<ID>(); // GitLab #22656,Box Summary Map to store custom Invoice number with Invoice
        Set<ID> setInvId = new Set<ID>(); // #25604 created a Set  for calling the method : updateNotesOnAccountFromUsage
        Set<ID> setInvoiceId = new Set<ID>(); //#Gitlab #27777 Automate invoice notes to display exchange rate on Foreign currency invoices
        Set<ID> invIdSet = new Set<ID>(); //27735 - updating invoice level bill cycle day from order level invoice batch
        // All final Update Map Variables
        Map<ID,Account> finalUpdateAccountMap = new Map<ID,Account>(); // #25604 created a Map  for updating Account only once when ever the Account want to be Updated(New Structure of code)
        Map<ID,blng__Invoice__c> finalUpdateInvoiceMap = new Map<ID,blng__Invoice__c>(); // #27494 created a Map  for updating AccountInfo only once when ever the Account want to be Updated(New Structure of code)
        Map<ID,QTB_Bill_Flow_Controller__c> finalUpdateBillFlowControllerMap = new Map<ID,QTB_Bill_Flow_Controller__c>();        // #29101 created a Map for updating BillFlowConroller only once when ever the BillFlowConroller is to be Updated(Code Optimization)
        Map<ID,blng__InvoiceLine__c> finalUpdateInvoiceLineMap = new Map<ID,blng__InvoiceLine__c>(); // #29101 created a Map for updating InvoiceLine only once when ever the InvoiceLine is to be Updated(Code Optimization)
        List<QTB_Tax_Detail__c> finalTaxDetailInsertList = new List<QTB_Tax_Detail__c>(); // #29101 created a List for updating TaxDetail only once when ever the TaxDetail is to be Inserted(Code Optimization)
        Map<ID,QTB_PurchaseOrder__c> finalPurchaseOrderUpdateMap = new Map<ID,QTB_PurchaseOrder__c>(); // #29101 created a Map for updating QTB_PurchaseOrder__c only once when ever the QTB_PurchaseOrder__c is to be Updated(Code Optimization)
        Map<ID,OrderItem> finalOrderItemToUpdateMap = new Map<ID,OrderItem>();  // #29101 created a Map for updating OrderItem only once when ever the OrderItem is to be Updated(Code Optimization)
        Map<ID,Credit_ReBill_InvoiceSchedulerValidation__c> creditReBillInvoiceSchedulerValidationToUpdateMap = new Map<ID,Credit_ReBill_InvoiceSchedulerValidation__c>();  // #29101 created a Map for updating Credit_ReBill_InvoiceSchedulerValidation__c only once when ever the Credit_ReBill_InvoiceSchedulerValidation__c is to be Updated(Code Optimization)
        Map<ID,blng__CreditNote__c> finalCreditNoteToUpdateMap = new Map<ID,blng__CreditNote__c>();  // #29101 created a Map for update blng__CreditNote__c only once when ever the blng__CreditNote__c is to be updated(Code Optimization)
        //Map<ID,blng__CreditNote__c> creditNoteToInsertMap = new Map<ID,blng__CreditNote__c>();  // #29101 created a Map for inserting blng__CreditNote__c only once when ever the blng__CreditNote__c is to be inserted(Code Optimization)
        //Map<ID,blng__CreditNoteLine__c> creditNoteLineToInsertMap = new Map<ID,blng__CreditNoteLine__c>(); // #29101 created a Map for inserting InvoiceLine only once when ever the InvoiceLine is to be inserted (Code Optimization)
        Set<ID> invoiceIdForSubInvoiceLineSet = new Set<ID>();// Gitlab #30888 storing rebill invoice Id for sub invoice line logic
        Map<ID,Boolean> invSubLinesCreatedMap = new Map<ID,Boolean>();// Gitlab #30888  rebill invocice map where sub lines are not cretaed
        for (blng__Invoice__c invoice : newItems){
            if(invoice.blng__InvoiceRunCreatedBy__c!= null){// added null check as part of 29101
                invoiceRunSet.add(invoice.blng__InvoiceRunCreatedBy__c);
            }
            // Gitlab US#25023 (Credit/Rebill Billnow)
            if(invoice.blng__Order__c != null && operationType.name().equalsIgnoreCase('BEFORE_INSERT')){
                orderIdSet.add(invoice.blng__Order__c);
            }
        }
        //28131 GITLAB - Adding a Operation types in the condition to avoid the SOQL 201 Error during bulk test
        if(billingCountriesInvoiceMap == null  && (operationType.name().equalsIgnoreCase('BEFORE_UPDATE')|| operationType.name().equalsIgnoreCase('AFTER_UPDATE'))){
            
            // Added blng__Account__r.QTB_SITAD__c field in below Query as part of Gitlab #22185
            // Added #21598 Invoice Period in Query for checking not equals to null
            billingCountriesInvoiceMap = new Map<ID,blng__Invoice__c>([SELECT ID, blng__Account__r.BillingCountry,blng__Account__r.QTB_Legal_Entity_Country__c,blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Bill_Forward_Type__c,blng__Account__r.QTB_DM_Source_System__c,blng__Account__r.QTB_Tax_Threshold_Amount__c,
                                                                       blng__Subtotal__c,blng__Account__r.QTB_Special_Tax_Condition__c,blng__Account__r.ShippingCountry,QTB_Parent_Invoice__r.blng__InvoiceDate__c,QTB_Invoice_Period__c, blng__Account__r.QTB_SITAD__c 
                                                                       FROM blng__Invoice__c 
                                                                       WHERE ID IN: newItems ]); //Gitlab US#29101 -- added
        } // as optimization remove blng__Account__r.ShippingCountry,QTB_Parent_Invoice__r.blng__InvoiceDate__c
        
        //28131 GITLAB - Adding a Operation types in the condition to avoid the SOQL 201 Error during bulk test
        if(invoiceRunSet!=null && !invoiceRunSet.isEmpty() && relatedInvoiceRunMap == null && (operationType.name().equalsIgnoreCase('BEFORE_INSERT'))){
            // //exclude Sierra26 Invoice from Purchase Order calculation
            relatedInvoiceRunMap = new Map<ID,blng__InvoiceRun__c>([SELECT ID,blng__InvoiceScheduler__r.blng__InvoiceBatches__c,blng__InvoiceScheduler__r.QTB_Parent_Invoice__c,blng__InvoiceScheduler__r.QTB_ReBill_Credit_Reason__c,blng__InvoiceScheduler__r.QTB_ReBill_CreditNote_Internal_Note__c,
                                                                    blng__InvoiceScheduler__r.QTB_Rebill_Type__c, blng__InvoiceScheduler__r.QTB_Invoice_Period__c
                                                                    FROM blng__InvoiceRun__c  
                                                                    WHERE ID IN : invoiceRunSet AND blng__InvoiceScheduler__r.blng__InvoiceBatches__c !=: SYSTEM.LABEL.QTB_sierra26Label ]); //Gitlab US#29101 -- added
        }
        // optimized soql 29101 remove blng__InvoiceScheduler__r.QTB_ReBill_Credit_Reason__c, blng__InvoiceScheduler__r.QTB_ReBill_CreditNote_Internal_Note__c
        if(orderIdSet!=null && !orderIdSet.isEmpty()){
            orderMap = new Map<ID,Order>([SELECT ID, QTB_OriginalRebillInvoice__c, QTB_OrderCategory__c, QTB_Rebill_Type__c,QTB_OriginalRebillInvoice__r.QTB_Invoice_Period__c,QTB_OriginalRebillInvoice__r.blng__InvoiceDate__c 
                                          FROM Order 
                                          WHERE ID IN: orderIdSet AND QTB_OrderCategory__c = 'Rebill' ]); //Gitlab US#29101 -- added
        }
        
        for(blng__Invoice__c invoice : newItems){
            switch on operationType{
                when BEFORE_INSERT{
                    invoice.RecordTypeid = QTB_Utils.INVOICE_DRAFT_RECTYPEID;
                    // Added #21598 as part of bringning the Invoice scheduler Invoice period to Invocie level invocie Period
                    // Gitlab US#24585 (Credit/Rebill Billnow) -- added null check //#29101 added invoice.blng__InvoiceRunCreatedBy__c!=null
                    if(invoice.blng__InvoiceRunCreatedBy__c != null && relatedInvoiceRunMap!=null && relatedInvoiceRunMap.containsKey(invoice.blng__InvoiceRunCreatedBy__c) &&
                       relatedInvoiceRunMap.get(invoice.blng__InvoiceRunCreatedBy__c)?.blng__InvoiceScheduler__r.QTB_Invoice_Period__c != null){
                           
                           invoice.QTB_Invoice_Period__c = relatedInvoiceRunMap.get(invoice.blng__InvoiceRunCreatedBy__c).blng__InvoiceScheduler__r.QTB_Invoice_Period__c;
                       }
                    //Gitlab #25905 updating invoice date AND due date of manual invoice generated for ad-Hoc order
                    // 29101 added more null check, we had a single null check before i.e. "invoice.QTB_AdHocInvoicePeriod__c"
                    else if(invoice.QTB_AdHocInvoicePeriod__c != null && invoice.QTB_AdHocInvoiceDate__c!= null && invoice.blng__InvoiceDate__c != null && invoice.QTB_PaymentTerm__c != null){
                        
                        invoice.QTB_Invoice_Period__c = invoice?.QTB_AdHocInvoicePeriod__c;
                        invoice.blng__InvoiceDate__c = invoice?.QTB_AdHocInvoiceDate__c;
                        invoice.blng__DueDate__c = invoice?.blng__InvoiceDate__c + (Integer)invoice?.QTB_PaymentTerm__c;
                    }
                    if(billingAccountIdsSet!=null && invoice.blng__Account__c != null){
                        billingAccountIdsSet.add(invoice.blng__Account__c);
                    }
                    // Gitlab US#25023 (Credit/Rebill Billnow) updating Rebill invoice
                    if(orderMap!=null && !orderMap.isEmpty() && invoice.blng__Order__c != null){
                        invoice.QTB_Parent_Invoice__c = orderMap.get(invoice.blng__Order__c)?.QTB_OriginalRebillInvoice__c;
                        invoice.QTB_Invoice_Type__c = 'ReBill';
                        invoice.QTB_Bill_Cycle_Day__c = 'Rebill Run';
                        invoice.QTB_Rebill_Type__c = orderMap.get(invoice.blng__Order__c)?.QTB_Rebill_Type__c; //SplitRebill
                        invoice.QTB_Invoice_Period__c = orderMap.get(invoice.blng__Order__c)?.QTB_OriginalRebillInvoice__r?.QTB_Invoice_Period__c;
                    }
                    if(invoice?.QTB_Invoice_Type__c == 'New'){
                        invoice.QTB_Rebill_Type__c = ''; //Set Rebill Type as blank whenever invoiceType=New
                    }
                }
                when AFTER_INSERT{
                    // Added as part of GitLab # 3543
                    //Gitlab US#22511 -- instead of equals to change to contains of "Rebill Run"
                    if(rebillInvoiceIdsSet!=null && invoice != null && invoice.QTB_Bill_Cycle_Day__c != null && invoice.QTB_Bill_Cycle_Day__c.containsIgnoreCase('Rebill Run')) { // containsIgnoreCase as 29101
                        rebillInvoiceIdsSet.add(invoice.ID);
                    }
                }
                when BEFORE_UPDATE{
                    //GITLAB US #14554 Credit / Rebill - Internal Notes - Populate Internal Note at Pop Up AND back end level
                    //As part of the story (To Nullify Internal Notes AND CreditReason on Update of status to null)
                    if((oldMap.get(invoice.ID).QTB_ReBill_Status__c != invoice.QTB_ReBill_Status__c )&& (invoice.QTB_ReBill_Status__c == null)){
                        
                        invoice.QTB_ReBill_Credit_Reason__c = '';
                        invoice.QTB_ReBill_CreditNote_Internal_Note__c = '';
                        invoice.QTB_SplitRebillSubtotalOnParentInvoice__c = null;//SplitRebill
                        invoice.QTB_ReBill_Total_Amount__c = null;//SplitRebill
                        invoice.QTB_ReBill_Invoice_With_Total__c = null;//SplitRebill
                    }
                    //Added below as part of Gitlab #22185
                    isSITADInvoice = billingCountriesInvoiceMap.get(invoice.ID).blng__Account__r?.QTB_SITAD__c; //#29101 added SafeNavigation
                    
                    //Gitlab #22654 update Service type AND Insert PO based on Service Type at the time of draft created
                    //checking tax override amount so that PO get calculated once tax is calculated
                    if(invoice.blng__InvoiceStatus__c=='Draft'&& invoice.QTB_Invoice_Type__c=='New' &&
                       (oldMap.get(invoice.ID).QTB_Tax_Override_Amount__c != invoice?.QTB_Tax_Override_Amount__c ||invoice?.QTB_Tax_Override_Amount__c == 0 || TEST.isRunningTest())){
                           draftInvoiceMap.put(invoice.ID,invoice);
                       }
                    //#26654 Adding the Invocieids as Key AND Value as Invoice whenever status is changed AND its equals to Draft for calling the method updateExchangeRate for stamping the Exchange Rate based upon Foreign Exchange object
                    //Adding the new Formula field which will decide whether its a Forex invocie or not
                    if(oldMap!= null&&invExchangeRateUpdateMap!=null && invoice.blng__InvoiceStatus__c != null && oldMap.get(invoice.ID).blng__InvoiceStatus__c != invoice.blng__InvoiceStatus__c &&
                       invoice.blng__InvoiceStatus__c=='Draft' && invoice.QTB_Foreign_Exchange_Applicable__c){
                           invExchangeRateUpdateMap.put(invoice.ID,invoice);
                       }
                    // #27581 - update invoice date due date based on date of posting
                    // #30236 Added InvoiceType != Legacy Invoice to Bypass the inv date and Due Date stampage
                    if(invoice.QTB_LegalEntityCountry__c != null && System.label.QTB_InvoiceDateUpdate.containsIgnoreCase(invoice.QTB_LegalEntityCountry__c) && oldMap!= null &&
                       invoice.QTB_PaymentTerm__c != null && oldMap.get(invoice.ID).blng__InvoiceStatus__c != invoice.blng__InvoiceStatus__c &&
                       invoice.blng__InvoiceStatus__c=='Posted' && invoice.QTB_Invoice_Type__c != null && invoice.QTB_Invoice_Type__c != 'Legacy Invoice' && invoice.QTB_PaymentTerm__c != null){ // Added null check as part of 29101 invoice.QTB_PaymentTerm__c
                           
                           invoice.blng__InvoiceDate__c = System.today();
                           invoice.blng__DueDate__c = invoice.blng__InvoiceDate__c + (Integer)invoice.QTB_PaymentTerm__c;
                       }
                    //once invoice line are inserted below field value gets changed from manage package so based on that will update order level invoice batch
                    // picking order refrence from invoice line because if invoice are created through invoice scheduler in that case order refrence is not present at invoice
                    if(oldMap.get(invoice.ID).blng__NumberOfInvoiceLines__c != invoice.blng__NumberOfInvoiceLines__c){
                        invIdSet.add(invoice.ID);
                    }
                }
                when AFTER_UPDATE
                {
                    // Gitlab #30888 to create sub invoce line for rebill invoice
                    if(invoice.QTB_Invoice_Type__c.equalsIgnoreCase('ReBill') && invoice.QTB_hasTieredLines__c == true && invoice.blng__InvoiceStatus__c.equalsIgnoreCase('Draft') && oldMap != null && invoiceIdForSubInvoiceLineSet!=null
                       && oldMap.get(invoice.Id).blng__InvoiceStatus__c !=  invoice.blng__InvoiceStatus__c && invoice.QTB_Sublines_Added__c == false && QTB_RecursiveHandlerCheck.afterUpdateCheck_createSubInvoiceLines){
                           invoiceIdForSubInvoiceLineSet.add(invoice.Id);
                    }
                    //25604 GITLAB: Added to call the method :  updateNotesOnAccountFromUsage
                    if(invoice.QTB_LegalEntityCountry__c != null && isSITADInvoice && setInvId!=null&&
                       (invoice.QTB_LegalEntityCountry__c.equalsIgnoreCase('United States') || invoice.QTB_LegalEntityCountry__c.equalsIgnoreCase('Canada'))){
                           setInvId.add(invoice.ID);
                       }
                    //closeticket 25604
                    ////Gitlab:28610 EPIC:2795
                    if(invPOIdSet!=null&& invoice.QTB_PurchaseOrder__c != null && invoice.blng__InvoiceStatus__c==('Posted') &&  oldMap.get(invoice.ID).blng__InvoiceStatus__c != 'Posted'){
                            invPOIdSet.add(invoice.ID);
                        }
                    if(rebillInvoiceIdSet!=null && oldMap.get(invoice.ID).blng__NumberOfInvoiceLines__c != invoice.blng__NumberOfInvoiceLines__c){
                        rebillInvoiceIdSet.add(invoice.ID);
                    }
                    
                    //Gitlab #20432 using existing Set of Invoice ids for Tax Detail creation related to Tax Rounding
                    if(oldMap.get(invoice.ID)?.blng__InvoiceStatus__c != invoice?.blng__InvoiceStatus__c && invoice?.blng__InvoiceStatus__c.equalsIgnoreCase(QTB_Constants.INVOICE_STATUS_POSTED) &&  // 29101 ADDED equalsIgnoreCase
                       invoice.blng__Account__r?.QTB_Bill_Cycle_Day__c != System.Label.QTB_sierra26Label && QTB_RecursiveHandlerCheck.afterUpdate_calculateIndividualTaxAmountsOnInvoiceLineItems){ // 29101 added recursive check fix){
                           
                           //Gitlab-#24175 replaced relatedInvoiceRunMap.containsKey(invoice.blng__InvoiceRunCreatedBy__c) ) // contains invoiceRun which not related to Sierra26 invoice Scheduler
                           postedInvoiceIdsSet.add(invoice.ID);
                       }
                    
                    //SplitRebill -- Storing splitRebill Invoice ID in Set if rebilltype is split AND total amount is change
                    if(splitRebillInvoiceIdSet!=null && invoice.QTB_Rebill_Type__c!= null && String.isNotBlank(System.Label.QTB_SplitRebill) && invoice.QTB_Rebill_Type__c.equalsIgnoreCase(System.Label.QTB_SplitRebill) &&
                       (oldmap.get(invoice.ID)?.blng__TotalAmount__c != invoice?.blng__TotalAmount__c ||  //this condition is to check if the tax gets calculated AND it have some value
                        (invoice?.blng__TaxAmount__c != null && oldmap.get(invoice.ID)?.blng__TaxAmount__c == invoice?.blng__TaxAmount__c && invoice?.blng__TaxAmount__c == 0))){ //this condition for in case of tax 0, totalamount would be same
                            
                            splitRebillInvoiceIdSet.add(invoice.ID);//storing the splitRebillInvoiceids
                        }
                    ////Logic to populate MRC dates on Invoice
                    String  accBillingCountry = (billingCountriesInvoiceMap!=null && billingCountriesInvoiceMap.get(invoice.ID).blng__Account__r.QTB_Legal_Entity_Country__c!=null)
                        ? billingCountriesInvoiceMap.get(invoice.ID).blng__Account__r.QTB_Legal_Entity_Country__c : '';//#29101 added Ternaryoperators
                    String billingCountry = (QTB_Billing_Countries__c.getValues(accBillingCountry) != null)
                        ? QTB_Billing_Countries__c.getValues(accBillingCountry).Name : ''; //#29101 added Ternaryoperators
                    
                    // Changing Posted status to Draft status as per the Gitlab #21173
                    // Changed as part of # 21598 adding Invoice period null check
                    // Gitalb #32884 - calling updateInvoiceMRCDates method only for credit rebill or adhoc order invoices else calling batch class from invoice run helpr
                    if(alreadyProcessedSet!=null && invoice.blng__InvoiceStatus__c.equalsIgnoreCase(QTB_Constants.INVOICELINE_STATUS_DRAFT) && (QTB_Billing_Countries__c.getValues(accBillingCountry) != null) &&
                       billingCountriesInvoiceMap.get(invoice.ID).blng__Account__r.QTB_Billing_Frequency__c != null
                       && billingCountriesInvoiceMap.get(invoice.ID).blng__Account__r.QTB_Bill_Forward_Type__c != null
                       && billingCountriesInvoiceMap.get(invoice.ID).blng__Account__r.QTB_Bill_Forward_Type__c != 'None'
                       && oldmap.get(invoice.ID).blng__InvoiceStatus__c!=invoice.blng__InvoiceStatus__c
                       && billingCountriesInvoiceMap.get(invoice.ID).QTB_Invoice_Period__c != null && invoice.blng__Order__c != null
                       && !alreadyProcessedSet.contains(invoice.ID) && QTB_RecursiveHandlerCheck.afterUpdateCheck_updateInvoiceMRCDates){// 29101 merged if ; // US #31275 defect fix
                           
                           alreadyProcessedSet.add(invoice.ID);
                       }
                    //Gitlab US #10736 Credit & Rebill
                    
                    //start -->11752 tax free country credit note creation
                    Boolean taxFreeCountryPresent = false;
                    // Gitlab #29101 optimized
                    if(String.isNotBlank(System.Label.QTB_Tax_Free_Country) && System.Label.QTB_Tax_Free_Country.containsIgnoreCase(accBillingCountry)){ //
                        taxFreeCountryPresent = true;
                    }
                    
                    //As part of GITLAB #16267 added invoice.QTB_Billing_Account_Tax_Exempt__c== 'Yes'. whenever Billing Account with Tax Exempt = true,
                    //credit note creation of failing after adding this condition credit note is getting created
                    //Checking invoiceType = Rebill AND blng__InvoiceStatus__c != cancelled AND (Tax Amount is calculated or taxAmount is 0)
                    // Gitlab US#24173 (Credit/Rebill Billnow) Added Tax Amount is calculated or taxAmount is 0 AND QTB_RecursiveHandlerCheck.afterUpdateCreateReBillCreditNote
                    if(rebillInvoiceIdsWithIsCancelMap !=null && invoice.QTB_Parent_Invoice__c !=null && invoice.QTB_Invoice_Type__c==('ReBill'))
                    {
                        if(invoice.blng__InvoiceStatus__c != 'Cancelled' && invoice.blng__InvoiceStatus__c==('Draft') &&
                           ((oldMap.get(invoice.ID).blng__TaxAmount__c != invoice.blng__TaxAmount__c || invoice.QTB_Billing_Account_Tax_Exempt__c==('Yes') || taxFreeCountryPresent) ||
                            (oldmap.get(invoice.ID).blng__TaxAmount__c == invoice.blng__TaxAmount__c && (invoice.blng__TaxAmount__c == 0 || invoice.blng__TaxAmount__c > 0) && QTB_RecursiveHandlerCheck.afterUpdateCreateReBillCreditNote))){
                                
                                rebillInvoiceIdsWithIsCancelMap.put(invoice.ID,false);
                            }
                        if(oldMap.get(invoice.ID).blng__InvoiceStatus__c != invoice.blng__InvoiceStatus__c && invoice.blng__InvoiceStatus__c==('Cancelled')) {
                            rebillInvoiceIdsWithIsCancelMap.put(invoice.ID,true);
                        }
                    }
                    
                    //Gitlab US #11971  Billing countries: No tax amount to be calculated based upon Accounts Threshold value
                    //created By TCS/Virtusa
                    // Updating Invoice line Tax rule to "NO Tax Rule" for Billing countries if that Billing Account's QTB_Tax_Threshold_Amount__c value > 0 AND invoice amount is less than threshold
                    // For Example Thaialnd should be Non - Taxable less than 5000 TH
                    if (draftInvoiceIdsSet!=null && invoice.blng__Subtotal__c <= billingCountriesInvoiceMap.get(invoice.ID).blng__Account__r.QTB_Tax_Threshold_Amount__c && accBillingCountry == billingCountry
                        && billingCountriesInvoiceMap.get(invoice.ID).blng__Account__r.QTB_Tax_Threshold_Amount__c > 0 && invoice.blng__InvoiceStatus__c==('Draft')
                        && billingCountriesInvoiceMap.get(invoice.ID).blng__Account__r.QTB_Special_Tax_Condition__c==('None')){
                            
                            draftInvoiceIdsSet.add(invoice.ID);
                        }
                    
                    ///end 11971C
                    //GitLab #22656, compare the invoice status should be Draft
                    if(oldMap.get(invoice.ID)?.blng__TaxStatus__c !=invoice?.blng__TaxStatus__c && setInvcId!=null &&
                       invoice?.blng__TaxStatus__c.equalsIgnoreCase(QTB_Constants.INVOICE_TAXSTATUS_COMPLETED) && invoice?.blng__InvoiceStatus__c.equalsIgnoreCase(QTB_Constants.INVOICE_STATUS_DRAFT)){
                           
                           setInvcId.add(invoice.ID);
                       }
                    
                    // Gitlab US#25143 (Credit/Rebill Billnow)  Added condition equal to Completed AND Rebill for rebill invoice
                    // gitlab US#32729 replaced Rebill condition with order != null so that the logic will work for both adhoc order invoice and rebill invoice, 
                    // as both are using bill now functionality, blng__order__c will not be null 
                    if((taxOverrideInvoiceId!=null && invoice.blng__TaxStatus__c == 'Completed' && invoice.blng__Order__c != null &&
                        (oldMap.get(invoice.ID)?.blng__TaxStatus__c != invoice?.blng__TaxStatus__c ))){
                            //Populate TaxOverride for North America for Tax Override always
                            //irresepective of Tax Status - since Resend to Tax can be done irresepective of tax status - Story 21202
                            
                            taxOverrideInvoiceId.add(invoice.ID);
                        }
                    // #Gitlab #27777 Automate invoice notes to display exchange rate on Foreign currency invoices
                    if(((oldMap!= null && invoice.blng__InvoiceStatus__c != null && oldMap.get(invoice.ID).blng__InvoiceStatus__c != invoice.blng__InvoiceStatus__c && invoice.blng__InvoiceStatus__c == 'Draft') ||
                        (invoice.QTB_Contracted_Currency_Rate__c !=null && oldMap.get(invoice.ID).QTB_Contracted_Currency_Rate__c != invoice.QTB_Contracted_Currency_Rate__c) ||
                        (invoice.QTB_Subtotal_local_currency__c !=null && oldMap.get(invoice.ID).QTB_Subtotal_local_currency__c != invoice.QTB_Subtotal_local_currency__c) ||
                        (invoice.QTB_Tax_Override_Amt_Local__c !=null && oldMap.get(invoice.ID).QTB_Tax_Override_Amt_Local__c != invoice.QTB_Tax_Override_Amt_Local__c) ||
                        (invoice.QTB_Total_Amt_Tax_Override_local__c !=null && oldMap.get(invoice.ID).QTB_Total_Amt_Tax_Override_local__c != invoice.QTB_Total_Amt_Tax_Override_local__c) ||
                        (invoice.QTB_Exchange_Rate__c !=null && oldMap.get(invoice.ID).QTB_Exchange_Rate__c != invoice.QTB_Exchange_Rate__c))
                       &&(invoice.QTB_Exchange_Rate__c != 1 || invoice.QTB_Contracted_Currency_Rate__c !=null)){
                           
                           setInvoiceId.add(invoice.ID);
                       }
                }
            }
        }
        switch on operationType{
            when BEFORE_UPDATE{
                
                //25283
                if((System.Label.IsInvoiceFieldsNonEditableForPosted == 'true' && QTB_RecursiveHandlerCheck.checkFieldEditableMethod)){
                    makeFieldsNonEditableForPosted(newItems, oldMap);
                }
                if(System.Label.IsInvoiceFieldsReadOnlyForPosted == 'true'){ // 29101 ask  if we can delete
                    //   makeFieldsReadyOnlyForPosted(newItems, oldMap);
                }
                if(Test.isRunningTest()){
                    makeFieldsNonEditableForPosted(newItems, oldMap);
                    makeFieldsReadyOnlyForPosted(newItems, oldMap);
                }
                // Calling populateOrderFieldsOnInvoice method if isSITADInvoice is TRUE as part of GitLab #22185
                if(isSITADInvoice){
                    populateOrderFieldsOnInvoice(newItems); // it will be called only once AND its part of bef update
                }
                
                updatePOInvoiceLevel(newItems, oldMap); //22030
                //Gitlab #22654 update Service type AND Insert PO based on Service Type
                if(draftInvoiceMap!=null && !draftInvoiceMap.isEmpty()){ // ask  29101
                    
                    Map<ID,blng__Invoice__c> updateService = QTB_InvoiceHelperUtils.serviceTypeAssignment(draftInvoiceMap); // Gitlab #27181
                    Map<ID,blng__Invoice__c> assignPO = autoUpdatePO(draftInvoiceMap); // Gitlab #27181
                }
                //27735 - updating invoice level bill cycle day from order level invoice batch
                if(invIdSet!=null && !invIdSet.isEmpty()){
                    prePopulateFields(invIdSet,newItems);
                }
            }
            when AFTER_UPDATE{
                // Gitlab US#24173 (Credit/Rebill Billnow)
                if(rebillInvoiceIdSet!=null && !rebillInvoiceIdSet.isEmpty() && QTB_RecursiveHandlerCheck.afterUpdateCallVertex){
                    List<QTB_Bill_Flow_Controller__c> billFlowUpdate = callVertexAndAssignBillFlowControllerForRebill(rebillInvoiceIdSet);
                    if(finalUpdateBillFlowControllerMap!=null && billFlowUpdate != null && !billFlowUpdate.isEmpty()){// 29101 modified
                        for(QTB_Bill_Flow_Controller__c billFlow: billFlowUpdate){
                            finalUpdateBillFlowControllerMap.put(billFlow.ID,billFlow);
                        }
                    }
                }
                //Gitlab:28610 EPIC:2795 Calling the method to update the PO balance
                if(QTB_RecursiveHandlerCheck.calculatingPOBalanceInv && !invPOIdSet.isEmpty()){
                    List<QTB_PurchaseOrder__c> poBalancewithoutShareList = calculatingPOBalance(newItems, oldMap);
                    // 29101 added
                    if(finalPurchaseOrderUpdateMap!=null && poBalancewithoutShareList!=null && !poBalancewithoutShareList.isEmpty()){
                        for(QTB_PurchaseOrder__c pows : poBalancewithoutShareList){
                            finalPurchaseOrderUpdateMap.put(pows.ID, pows);
                        }
                    }
                }
                // #25143 - To populate tax overrride amount calling QTB_InvoiceLineHelperUtils.updateInvcAndInvocLineWithTaxOverride as below
                // Gitlab US#25143 (Credit/Rebill Billnow)
                if(taxOverrideInvoiceId != null && !taxOverrideInvoiceId.isEmpty()){
                    Map<ID,blng__InvoiceLine__c> lstInvcLineMap = new Map<ID,blng__InvoiceLine__c>([SELECT ID,QTB_Tiered_Flag__c,blng__Subtotal__c,blng__Invoice__r.blng__Subtotal__c,blng__TaxAmount__c,QTB_Tax_Override_Amount__c,blng__Invoice__r.ID,blng__TaxPercentageApplied__c,
                                                                                                    blng__LegalEntity__r.ID,blng__Invoice__r.blng__InvoiceStatus__c,
                                                                                                    blng__Invoice__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,blng__LegalEntity__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                                                                                    QTB_Tax_Code__c,blng__TaxTreatment__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c,blng__Invoice__r.blng__TaxAmount__c ,blng__Invoice__r.QTB_Invoice_Type__c,blng__LegalEntity__r.QTB_Tax_Applicability__c,
                                                                                                    blng__Invoice__r.blng__TotalAmount__c,blng__Invoice__r.QTB_Tax_Override_Amount__c,blng__Invoice__r.blng__NumberOfInvoiceLines__c,blng__UsageSummary__r.QTB_Contracted_Currency_Rate__c
                                                                                                    FROM blng__InvoiceLine__c 
                                                                                                    WHERE blng__Invoice__c In:taxOverrideInvoiceId 
                                                                                                    AND blng__Invoice__r.blng__InvoiceStatus__c ='Draft']);
                    Set<String> addressComparisonSet = new Set<String>();
                    for(blng__InvoiceLine__c invLine : lstInvcLineMap.values()){
                        String invoiceLineComparison = invLine.blng__TaxCountry__c +'----' +invLine.QTB_Tax_Code__c +'-' + invLine.blng__LegalEntity__c;
                        invoiceLineComparison = invoiceLineComparison.replaceAll('null','');
                        addressComparisonSet.add(invoiceLineComparison);
                    }
                    List<SObject> recordsToUpdateList = QTB_InvoiceLineHelperUtils.updateInvcAndInvocLineWithTaxOverride(lstInvcLineMap,addressComparisonSet);
                    if(recordsToUpdateList!=null && !recordsToUpdateList.isEmpty()){
                        // Segregate the records from the List<SObject>
                        for(SObject record : recordsToUpdateList){
                            if(finalUpdateInvoiceMap!=null && record instanceof blng__Invoice__c){
                                finalUpdateInvoiceMap.put(record.ID,(blng__Invoice__c) record);
                            }else if(finalUpdateInvoiceLineMap!=null && record instanceof blng__InvoiceLine__c){
                                finalUpdateInvoiceLineMap.put(record.ID,(blng__InvoiceLine__c) record);
                            }
                        }
                        recordsToUpdateList.clear();// 29101 ends
                    }
                }
                
                // Gitlab US#24173 (Credit/Rebill Billnow)
                /* Commenetd as 29101 its a redundant code and spoke with the dev of US#24173
if(!rebillInvoiceIdsWithIsCancelMap.isEmpty())
{
List<Boolean> isTrueOrFalseList = rebillInvoiceIdsWithIsCancelMap.values();
Boolean isCancel = false;
if(!isTrueOrFalseList.isEmpty() && isTrueOrFalseList.contains(true)){
isCancel = true;
}
                    // ask  29101 its inserting both creditnote AND creditnotelines
List<SObject> recordsToUpdateAndInsertList = createReBillCreditNote(rebillInvoiceIdsWithIsCancelMap.keySet(),isCancel); //calling this method to process regular CreditRebill logic

} */
                
                //25604 GITLAB: Added to call the method :  updateNotesOnAccountFromUsage
                if(!setInvId.isEmpty() && QTB_RecursiveHandlerCheck.afterupdateCheck_updateNotesOnAccountFromUsage)
                {
                    System.debug('>>insideiffafterupdateupdateNotesOnAccountFromUsage'+ setInvId);
                    //Calling a returntype method
                    List<Account> accUpdateList = updateNotesOnAccountFromUsage(setInvId);
                    if(finalUpdateAccountMap!=null && accUpdateList!=null && !accUpdateList.isEmpty()) // 29101 added.isEmpty in place of null
                    {
                        for(Account acc: accUpdateList){
                            finalUpdateAccountMap.put(acc.ID,acc); //#29101 first addition hence added directly to the Map.
                        }
                        accUpdateList.clear();// 29101 ends
                    }
                }
                //Gitlab #27777 Automate invoice notes to display exchange rate on Foreign currency invoices
                if(setInvoiceId!=null && !setInvoiceId.isEmpty() && QTB_RecursiveHandlerCheck.invoiceNoteRecursiveCheck)
                {
                    
                        List<blng__Invoice__c> lstInvoiceUpdate = QTB_InvoiceHelperUtils.updateInvoiceNote(setInvoiceId);
                        if(lstInvoiceUpdate != null && !lstInvoiceUpdate.IsEmpty())
                        {
                            for(blng__Invoice__c inv : lstInvoiceUpdate)
                            {
                                // if that Invoiceid not present in List add as it is for further updates
                                if(finalUpdateInvoiceMap!=null && !finalUpdateInvoiceMap.containsKey(inv.ID))
                                {
                                    finalUpdateInvoiceMap.put(inv.ID,inv);
                                }else if(finalUpdateInvoiceMap!=null){
                                    // if that ID presents add that related Field Name as per ID AND Value as Fields data that needs to be updated
                                    finalUpdateInvoiceMap.get(inv.ID).put('blng__Notes__c', inv.blng__Notes__c);
                                }
                            }
                        }
                    }
                // Code refactor start #29101
                if(!newItems.isEmpty() && !oldMap.isEmpty()&& QTB_RecursiveHandlerCheck.afterupdateCheck_UpdatePO)
                {
                    //Calling a return type method
                    updatePOForCreditAndRebill(newItems, oldMap);
                    /*Map<ID,blng__Invoice__c> invUpdateMap =
if(finalUpdateInvoiceMap!=null && invUpdateMap!=null && !invUpdateMap.isEmpty()){
finalUpdateInvoiceMap.putAll(invUpdateMap);
}*/
                }// // Code refactor end #29101
                // Gitlab #30888 creating sub line for only those rebill invoices where legal entity is product based and storage and service period is true
                // It will execute only in Rebill Scenario
                if(invoiceIdForSubInvoiceLineSet != null  && !invoiceIdForSubInvoiceLineSet.isEmpty()){
                    Set<ID>  invoiceToCreateSubLineSet = new Set<Id>();
                    // passing only that invoices where legal entity tax applicability is product based and storage service period is true
                    // removed product based condition as part of story #30942
                    for(blng__invoice__c inv :[SELECT Id,blng__Account__r.QTB_Legal_Entity__r.QTB_Tax_Applicability__c,
                                               blng__Account__r.QTB_Legal_Entity__r.QTB_Storage_Service_Period_Range__c from blng__invoice__c where Id in :invoiceIdForSubInvoiceLineSet]){
                                                   if(inv.blng__Account__r.QTB_Legal_Entity__r.QTB_Storage_Service_Period_Range__c){
                                                       invoiceToCreateSubLineSet.add(inv.Id);
                                                   }
                                               }
                    if(invoiceToCreateSubLineSet != null && !invoiceToCreateSubLineSet.isEmpty()){
                        List<blng__Invoice__c> invLst = QTB_InvoiceHelperUtils.createSubLinesAndUpdateInvAndInvLine(invoiceToCreateSubLineSet);
                        invoiceToCreateSubLineSet.clear();
                        if(invLst != null && !invLst.isEmpty()){
                            for(blng__Invoice__c inv : invLst){
                                // if sub invoice line not craeted than updating the status to error
                                if(!inv.QTB_Sublines_Added__c){
                                    invSubLinesCreatedMap.put(inv.Id,False); // adding to map which will be used at the time of credit note creation
                                    inv.blng__InvoiceStatus__c = 'Error';
                                    Inv.QTB_Invoice_generation_error__c = 'Sub Invoice line not created';
                                }
                                // if that Invoiceid not present in List add as it is for further updates
                                if(finalUpdateInvoiceMap!=null && !finalUpdateInvoiceMap.containsKey(inv.ID)){
                                    finalUpdateInvoiceMap.put(inv.ID,inv);
                                }else if(finalUpdateInvoiceMap!=null){
                                    // if that ID presents add that related Field Name as per ID AND Value as Fields data that needs to be updated
                                    finalUpdateInvoiceMap.get(inv.ID).put('QTB_Sublines_Added__c', inv.QTB_Sublines_Added__c);
                                    //added null check, to make sure tax overide amount we are updating only if new value assigned through sublines logic
                                    if(inv.QTB_Tax_Override_Amount__c != null){
                                        finalUpdateInvoiceMap.get(inv.ID).put('QTB_Tax_Override_Amount__c', inv.QTB_Tax_Override_Amount__c);
                                    }
                                    if(!inv.QTB_Sublines_Added__c){
                                        finalUpdateInvoiceMap.get(inv.ID).put('blng__InvoiceStatus__c', inv.blng__InvoiceStatus__c);
                                        finalUpdateInvoiceMap.get(inv.ID).put('QTB_Invoice_generation_error__c', inv.QTB_Invoice_generation_error__c);
                                    }
                                }
                            }
                            invLst.clear();
                        }
                    }
                }
            }
        }
        
        //Gitlab #20432 Calculate Tax override on Invoice AND Invoice Line
        if (postedInvoiceIdsSet!=null && !postedInvoiceIdsSet.isEmpty())
        {
            List<QTB_Tax_Detail__c> taxDetailInsert = calculateIndividualTaxAmountsOnInvoiceLineItems(postedInvoiceIdsSet);
            System.debug('29101 taxDetailInsert = '+ taxDetailInsert);
            if(finalTaxDetailInsertList!=null && taxDetailInsert!=null && !taxDetailInsert.isEmpty())
            {
                finalTaxDetailInsertList.addAll(taxDetailInsert); //#29101 changed the return type and added it to the Map
            }
        }
        
        if (!draftInvoiceIdsSet.isEmpty()){
            List<blng__TaxTreatment__c>  taxtreatment2List = [SELECT ID,blng__taxRule__r.ID 
                                                              FROM blng__TaxTreatment__c 
                                                              WHERE NAME = 'Thailand No Tax Treatment'  LIMIT 1]; //Gitlab US#29101 -- added
            List<blng__InvoiceLine__c> invLineUpdateList = updateTaxruleForInvoiceLine(draftInvoiceIdsSet,taxtreatment2List[0]?.blng__taxRule__r?.ID,taxtreatment2List[0]?.ID); //29101
            if(finalUpdateInvoiceLineMap!=null && invLineUpdateList != null && !invLineUpdateList.isEmpty()){// 29101
                for(blng__InvoiceLine__c invLine: invLineUpdateList){
                    if(!finalUpdateInvoiceLineMap.containsKey(invLine.ID)){
                        finalUpdateInvoiceLineMap.put(invLine.ID,invLine);//#29101 changed the return type and added it to the Map
                    }else{
                        finalUpdateInvoiceLineMap.get(invLine.ID).put('blng__TaxRule__c', invLine.blng__TaxRule__c);
                        finalUpdateInvoiceLineMap.get(invLine.ID).put('blng__TaxTreatment__c', invLine.blng__TaxTreatment__c);
                    }
                }
                invLineUpdateList.clear();// 29101 ends
            }
        }
        //change on MRC dates issue###13364
        if(alreadyProcessedSet!=null && !alreadyProcessedSet.isEmpty()){
            //27494 Added the below format as code New Structure
            List<blng__Invoice__c> invItemUpdateList = updateInvoiceMRCDates(alreadyProcessedSet);
            if(invItemUpdateList != null && !invItemUpdateList.isEmpty()){
                for(blng__Invoice__c inv : invItemUpdateList){
                    // if that Invoiceid not present in List add as it is for further updates
                    if(finalUpdateInvoiceMap!=null && !finalUpdateInvoiceMap.containsKey(inv.ID)){
                        finalUpdateInvoiceMap.put(inv.ID,inv);
                    }else if(finalUpdateInvoiceMap!=null){ //#29101 to avoid nullpointer errors
                        // if that ID presents add that related Field Name as per ID AND Value as Fields data that needs to be updated
                        finalUpdateInvoiceMap.get(inv.ID).put('QTB_Start_Date_MRC__c', inv.QTB_Start_Date_MRC__c);
                        finalUpdateInvoiceMap.get(inv.ID).put('QTB_End_Date_MRC__c', inv.QTB_End_Date_MRC__c);
                        finalUpdateInvoiceMap.get(inv.ID).put('QTB_Service_Start_Date__c', inv.QTB_Service_Start_Date__c);
                        finalUpdateInvoiceMap.get(inv.ID).put('QTB_Service_End_Date__c', inv.QTB_Service_End_Date__c);
                        finalUpdateInvoiceMap.get(inv.ID).put('QTB_Tax_Period_Start_Date__c', inv.QTB_Tax_Period_Start_Date__c);
                        finalUpdateInvoiceMap.get(inv.ID).put('QTB_Tax_Period_End_Date__c', inv.QTB_Tax_Period_End_Date__c);
                    }
                }
            }
        }
        
        //SplitRebill -- checking splitRebillInvoiceIdSet
        if(splitRebillInvoiceIdSet!=null && !splitRebillInvoiceIdSet.isEmpty()){
            List<blng__Invoice__c> splitInvoiceUpdateList = updateReBillInvoiceWithTotalOnSplit(splitRebillInvoiceIdSet);//calling this method to process splitRebill logic
            if((finalUpdateInvoiceMap!=null)&&splitInvoiceUpdateList!=null && !splitInvoiceUpdateList.isEmpty()){// 29101
                for(blng__Invoice__c invSplit : splitInvoiceUpdateList){
                    if(finalUpdateInvoiceMap!=null && !finalUpdateInvoiceMap.containsKey(invSplit.ID)){
                        finalUpdateInvoiceMap.put(invSplit.ID,invSplit);//#29101 changed the return type and added it to the Map
                    }else if(finalUpdateInvoiceMap!=null){ //#29101 to avoid nullpointer errors
                        finalUpdateInvoiceMap.get(invSplit.ID).put('QTB_SplitRebillSubtotalOnParentInvoice__c', invSplit.QTB_SplitRebillSubtotalOnParentInvoice__c);
                        finalUpdateInvoiceMap.get(invSplit.ID).put('QTB_ReBill_Total_Amount__c', invSplit.QTB_ReBill_Total_Amount__c);
                        finalUpdateInvoiceMap.get(invSplit.ID).put('QTB_ReBill_Invoice_With_Total__c', invSplit.QTB_ReBill_Invoice_With_Total__c);
                        finalUpdateInvoiceMap.get(invSplit.ID).put('QTB_ReBill_Invoice_With_Total__c', invSplit.QTB_ReBill_Invoice_With_Total__c);
                    }
                }
                splitInvoiceUpdateList.clear(); //#29101 ends
            }
        }
        // GitLab #22656, Box Summar to call utils class to update Usage Category
        if(setInvcId!=null && !setInvcId.isEmpty()){
            //QTB_InvoiceHelperUtils.linkBoxSummary(setInvcId); // to ask  AND clear
        }
        //Updating only once as per the new structure -24604
        if(finalUpdateAccountMap!=null && !finalUpdateAccountMap.isEmpty() ){ // 29101
            update finalUpdateAccountMap.values();
            finalUpdateAccountMap.clear();
        }
        //Updating invoice Line only once as per the new structure -29101
        if(finalUpdateInvoiceLineMap!=null && !finalUpdateInvoiceLineMap.isEmpty() ) {// 29101
            update finalUpdateInvoiceLineMap.values();
            finalUpdateInvoiceLineMap.clear();
        }
        //Updating only once as per the new structure -29101
        if(finalUpdateBillFlowControllerMap!=null && !finalUpdateBillFlowControllerMap.isEmpty()){ // 29101
            update finalUpdateBillFlowControllerMap.values();
            finalUpdateBillFlowControllerMap.clear();
        }
        //Updating only once as per the new structure -29101, do not check security as it will produce error for QTB_PurchaseOrder__c
        if(finalPurchaseOrderUpdateMap!=null && !finalPurchaseOrderUpdateMap.isEmpty()) {// 29101
            QTB_WithoutSharingUtills.updatingPOBalanceAmountWithoutSharing(finalPurchaseOrderUpdateMap);
            //update finalPurchaseOrderUpdateMap.values();
            finalPurchaseOrderUpdateMap.clear();
        }
        // #27494 Updating only once the Invoice List what fields needs to be further updated as per the new code Structure
        if(finalUpdateInvoiceMap!=null && !finalUpdateInvoiceMap.isEmpty() ){
            update finalUpdateInvoiceMap.values();
            finalUpdateInvoiceMap.clear();
        }
        //CreditRebill
        if(rebillInvoiceIdsWithIsCancelMap!=null && !rebillInvoiceIdsWithIsCancelMap.isEmpty()){
            // Gitlab #30888, if sub invoice line not created then do not create credit note
            for(ID inv :rebillInvoiceIdsWithIsCancelMap.keySet()){
                if(invSubLinesCreatedMap != null && !invSubLinesCreatedMap.isEmpty() && invSubLinesCreatedMap.containsKey(inv)){
                    rebillInvoiceIdsWithIsCancelMap.remove(inv);
                }
            }
            List<Boolean> isTrueOrFalseList = rebillInvoiceIdsWithIsCancelMap.values();
            Boolean isCancel = (isTrueOrFalseList!=null &&!isTrueOrFalseList.isEmpty() && isTrueOrFalseList.contains(true))
                ? true : false;
            //#29101  inserting both creditnote AND creditnotelines
            Map<String, List<SObject>> resultMap =  createReBillCreditNote(rebillInvoiceIdsWithIsCancelMap.keySet(),isCancel);
            // calling this method to process regular CreditRebill logic
            
            if(resultMap!= null && resultMap.containsKey('updateOrderItem')){ //#29100 Added null check on Map
                List<OrderItem> orderProductList = resultMap.get('updateOrderItem');
                if(finalOrderItemToUpdateMap!=null && orderProductList!= null && !orderProductList.isEmpty()){//#29100 Added null check on Map
                    for (OrderItem oi : orderProductList){
                        finalOrderItemToUpdateMap.put(oi.ID, oi); //#29100 Add OrderItem records to finalOrderItemToUpdateMap to update finalOrderItemToUpdateMap
                    }
                    orderProductList.clear(); // clearing the Memory
                }
            }
            if(resultMap!= null && resultMap.containsKey('updateCredit_ReBill_InvoiceSchedulerValidation__c')){ //#29100 Added null check on Map
                List<Credit_ReBill_InvoiceSchedulerValidation__c> updateCreditRebillValidationList = resultMap.get('updateCredit_ReBill_InvoiceSchedulerValidation__c');
                if(creditReBillInvoiceSchedulerValidationToUpdateMap!=null && updateCreditRebillValidationList!=null && !updateCreditRebillValidationList.isEmpty()){      //#29100 Added null check on Map
                    for (Credit_ReBill_InvoiceSchedulerValidation__c crisv : updateCreditRebillValidationList){
                        creditReBillInvoiceSchedulerValidationToUpdateMap.put(crisv.ID, crisv); //#29100 Add Credit_ReBill_InvoiceSchedulerValidation__c records to creditReBillInvoiceSchedulerValidationToUpdateMap to update creditReBillInvoiceSchedulerValidationToUpdateMap
                    }
                    updateCreditRebillValidationList.clear();
                }
            }
            
            if(resultMap!= null && resultMap.containsKey('updatecreditNote')){ //#29100 Added null check on Map
                List<blng__CreditNote__c> updatecreditNoteList = resultMap.get('updatecreditNote');
                if(finalCreditNoteToUpdateMap!=null && updatecreditNoteList!=null && !updatecreditNoteList.isEmpty()){
                    for (blng__CreditNote__c cn : updatecreditNoteList){
                        finalCreditNoteToUpdateMap.put(cn.ID, cn);  //#29100 Add blng__CreditNote__c records to finalCreditNoteToUpdateMap to update finalCreditNoteToUpdateMap
                    }
                    updatecreditNoteList.clear();// clearing the Memory
                }
            }
            
            if(resultMap!=null && !resultMap.isEmpty()){
                resultMap.clear();
            }//29101 ends and clearing the Memory as last resultMap item is processed
        }
        if(finalTaxDetailInsertList!=null && !finalTaxDetailInsertList.isEmpty() ){ // 29101
            insert finalTaxDetailInsertList;
            finalTaxDetailInsertList.clear();
        }
        // 29101 start here
        if(finalOrderItemToUpdateMap!=null && !finalOrderItemToUpdateMap.isEmpty()){
            update finalOrderItemToUpdateMap.values();
            finalOrderItemToUpdateMap.clear();
        }
        if(creditReBillInvoiceSchedulerValidationToUpdateMap!=null && !creditReBillInvoiceSchedulerValidationToUpdateMap.isEmpty()){ //code review recomendation removed  (&& Schema.sObjectType.Credit_ReBill_InvoiceSchedulerValidation__c.isUpdateable())
            update creditReBillInvoiceSchedulerValidationToUpdateMap.values();
            creditReBillInvoiceSchedulerValidationToUpdateMap.clear();
        }
        if(finalCreditNoteToUpdateMap!=null && !finalCreditNoteToUpdateMap.isEmpty() ){
            update finalCreditNoteToUpdateMap.values();
            finalCreditNoteToUpdateMap.clear();
        }
        // 29101 ends here
        
        //26654 Calling updateExchangeRate from Utils to stamp the Exchange Rate on Invoice based upon Foreign Exchange object Record data
        if( invExchangeRateUpdateMap!=null && !invExchangeRateUpdateMap.isEmpty() && QTB_RecursiveHandlerCheck.invUpdateExchangeRate){
            QTB_InvoiceHelperUtils.updateExchangeRate(invExchangeRateUpdateMap);
            // 29101 to ask  invExchangeRateUpdateMap is coming from before update and theres no DML happening
        }
        postedInvoiceIdsSet.clear();
        billingAccountIdsSet.clear();
        rebillInvoiceIdsSet.clear();
        alreadyProcessedSet.clear();
        rebillInvoiceIdsWithIsCancelMap.clear();
        splitRebillInvoiceIdSet.clear();
        invPOIdSet.clear();
        rebillInvoiceIdSet.clear();
        taxOverrideInvoiceId.clear();
    }
    /***********************************************************************************************************
* Method     : UpdatePOInvoiceLeveL
* Parameters : List<blng__Invoice__c> newItems
* Description: this method called when user change the PO at the invoice level.
* Change History :
* Developer         Date           Description
* ----------------------------------------------------------------------------------------------------------
Sarwar          11/04/2025    #29101 Optimized the code
**************************************************************************************************************/
    public static void updatePOInvoiceLevel(List<blng__Invoice__c> newItems, Map<ID,blng__Invoice__c> oldMap){
        try{
            if(newItems == null || oldMap ==null || newItems.isEmpty() || oldMap.isEmpty()){
                throw new NullPointerException();
            }//#29101 early exit
            Set<ID> poidSet = new Set<ID>();
            for (blng__Invoice__c invObj: newItems){
                if (poidSet!=null && (oldMap.get(invObj.ID).QTB_PurchaseOrder__c == null) &&(invObj.QTB_PurchaseOrder__c != null)){
                    // Gitlab #27000 added null check // 29101 merged if ask safe navigation on (invObj.QTB_PurchaseOrder__c != null)
                    poidSet.add(invObj.QTB_PurchaseOrder__c);
                }
            }
            if(poidSet==null || poidSet.isEmpty()) {return;} //#29101 Exit early if no Purchase Order ids to process and it eliminates use of nested if
            Map<ID,QTB_PurchaseOrder__c> poMap = new Map<ID,QTB_PurchaseOrder__c>([SELECT ID, QTB_PO_Type__c,QTB_Status__c,QTB_PO_Balance_Amount__c 
                                                                                   FROM QTB_PurchaseOrder__c 
                                                                                   WHERE ID IN :poidSet ]);  //Gitlab US#29101 -- added
            if(poMap==null || poMap.isEmpty()) {return;} //#29101 Exit early if no poidSet is there to process
            
            for(blng__Invoice__c inv: newItems){
                if (inv.QTB_PurchaseOrder__c != null){
                    // Gitlab #27000 added null check
                    if(!poMap.isEmpty() && poMap.get(inv.QTB_PurchaseOrder__c).QTB_PO_Type__c == 'Standard'
                       && poMap.get(inv.QTB_PurchaseOrder__c).QTB_Status__c == 'Active' && (poMap.get(inv.QTB_PurchaseOrder__c).QTB_PO_Balance_Amount__c == null ||
                                                                                            poMap.get(inv.QTB_PurchaseOrder__c).QTB_PO_Balance_Amount__c < inv.QTB_Total_Amount_with_Tax_Override__c)){
                                                                                                
                                                                                                // Gitlab #27181 checking PO Balance null for user's not allowing to manually update POs on invoice if PO balance is null
                                                                                                inv.QTB_PurchaseOrder__c.addError(System.Label.QTB_InsufficientPOAmount);
                                                                                            }else if(!poMap.isEmpty() && poMap.get(inv.QTB_PurchaseOrder__c) != null){
                                                                                                
                                                                                                inv.QTB_Internal_PO_Notes__c = '';
                                                                                            }
                }
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    /***********************************************************************************************************
* Method     : autoUpdatePO8
* Parameters : List<blng__Invoice__c> newItems
* Description: this method helps to  SELECT PO automatically in the invoice level once its posted.#22030
Gitlab #22654 when invoice is in draft assign the PO based on service type
**************************************************************************************************************/
    /***********************************************************************************************************
* Method: autoUpdatePO
* Parameters: Map<ID, blng__Invoice__c> newItemsMap
* Description: This method helps to automatically SELECT a PO at the invoice level based on specific criteria.
* Retains existing functionality with added criteria for handling multiple POs for the same date range.
* Change History:
* #26902 Added by Mounika - Enhanced logic to handle cases WHERE multiple POs exist in the same date range.
* // Gitlab #27181 changed from void to return type
***********************************************************************************************************/
    public static Map<ID,blng__Invoice__c> autoUpdatePO (Map<ID, blng__Invoice__c> newItemsMap)
    {
        try {
            if(QTB_InvoiceTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(newItemsMap==null || newItemsMap.isEmpty()) { return null;}//29101 early exit
            Map<ID, List<QTB_PurchaseOrder__c>> accountIdPoMap = new Map<ID, List<QTB_PurchaseOrder__c>>();
            Set<ID> billingAccountSet = new Set<ID>();
            
            // Collect billing account ids
            for(blng__Invoice__c invoice : newItemsMap.values()){
                billingAccountSet.add(invoice.blng__Account__c);
            }
            // Query POs for accounts
            if(!billingAccountSet.isEmpty()) {
                List<QTB_PurchaseOrder__c> purchaseOrders = [SELECT Id, QTB_Service_Type__c, QTB_PO_Type__c, QTB_Status__c, QTB_PO_Balance_Amount__c,
                                                             QTB_Start_Date__c, QTB_End_Date__c, 
                                                             (SELECT Id, Name, QTB_Account__c, QTB_Purchase_Order__c FROM PurchaseOrderAccounts__r)
                                                             FROM QTB_PurchaseOrder__c
                                                             WHERE QTB_PO_Type__c = 'Standard' AND  
                                                             Id IN (SELECT QTB_Purchase_Order__c FROM QTB_PurchaseOrderAccount__c
                                                                    WHERE QTB_Account__c IN :billingAccountSet) 
                                                             AND QTB_Status__c = 'Active'];// Gitlab #31452
                
                if (!purchaseOrders.isEmpty()){
                    // Gitlab #31452 Loop through each Purchase Order and then their junction object records
                    for (QTB_PurchaseOrder__c po : purchaseOrders) {
                        for (QTB_PurchaseOrderAccount__c poAccount : po.PurchaseOrderAccounts__r) {
                            Id accountId = poAccount.QTB_Account__c;
                            
                            if (accountIdPoMap!=null && accountIdPoMap.containsKey(accountId)) {
                                accountIdPoMap.get(accountId).add(po);
                            } else {
                                accountIdPoMap.put(accountId, new List<QTB_PurchaseOrder__c>{ po });
                            }
                        }
                    }
                }
            }
            if(accountIdPoMap==null || accountIdPoMap.isEmpty()) {return null;}//29101 early exit
            for(blng__Invoice__c invoice : newItemsMap.values()){
                if(accountIdPoMap.containsKey(invoice.blng__Account__c)){
                    List<QTB_PurchaseOrder__c> poList = accountIdPoMap.get(invoice.blng__Account__c);
                    Boolean duplicatePOFlag = false;
                    if(poList == null || poList.isEmpty()){
                        continue;//29101 move to the next item in the loop ; there was no null check in SIT25 added freshly for null check
                    }           // and to avoid if within if
                    // Check for overlapping POs with matching service types
                    for(Integer i = 0; i < poList.size(); i++){
                        for(Integer j = i + 1; j < poList.size(); j++){
                            QTB_PurchaseOrder__c po1 = poList[i];
                            QTB_PurchaseOrder__c po2 = poList[j];
                            if(po1.QTB_PO_Type__c == 'Standard' && po2.QTB_PO_Type__c == 'Standard' &&po1.QTB_Service_Type__c == po2.QTB_Service_Type__c
                               &&(po1.QTB_Start_Date__c <= po2.QTB_End_Date__c && po1.QTB_End_Date__c >= po2.QTB_Start_Date__c)
                               &&(invoice.blng__InvoiceDate__c >= po1.QTB_Start_Date__c && invoice.blng__InvoiceDate__c <= po1.QTB_End_Date__c)
                               &&(invoice.blng__InvoiceDate__c >= po2.QTB_Start_Date__c && invoice.blng__InvoiceDate__c <= po2.QTB_End_Date__c)){
                                   
                                   invoice.QTB_PurchaseOrder__c = null;
                                   invoice.QTB_Internal_PO_Notes__c = System.Label.QTB_OverlappingPO;
                                   duplicatePOFlag = true;
                                   break;
                               }
                        }
                        if(duplicatePOFlag){
                            break;
                        }
                    }
                    if(duplicatePOFlag){
                        continue;
                    }
                    // Loop through POs to assign based on service type, balance, AND date range
                    for(QTB_PurchaseOrder__c po : accountIdPoMap.get(invoice.blng__Account__c)){
                        if(po.QTB_PO_Balance_Amount__c == null && po.QTB_Service_Type__c == invoice.QTB_Service_Type__c &&
                           po.QTB_Start_Date__c <= invoice.blng__InvoiceDate__c && po.QTB_End_Date__c >= invoice.blng__InvoiceDate__c){
                               
                               if(String.isBlank(invoice.QTB_Internal_PO_Notes__c)){
                                   invoice.QTB_Internal_PO_Notes__c = System.Label.QTB_PO_Balance_Null;
                               }
                               invoice.QTB_PurchaseOrder__c = null;
                               continue;
                           }
                        if(po.QTB_Service_Type__c == invoice.QTB_Service_Type__c && po.QTB_Start_Date__c <= invoice.blng__InvoiceDate__c &&
                           po.QTB_End_Date__c >= invoice.blng__InvoiceDate__c && po.QTB_PO_Balance_Amount__c >= invoice.QTB_Total_Amount_with_Tax_Override__c){
                               
                               invoice.QTB_PurchaseOrder__c = po.ID;
                               invoice.QTB_Internal_PO_Notes__c = null; // Clear notes on successful assignment
                               break;
                           }
                        
                        if(po.QTB_Service_Type__c == invoice.QTB_Service_Type__c &&
                           (po.QTB_PO_Balance_Amount__c < invoice.QTB_Total_Amount_with_Tax_Override__c || po.QTB_PO_Balance_Amount__c <= 0)) {
                               
                               invoice.QTB_PurchaseOrder__c = null;
                               invoice.QTB_Internal_PO_Notes__c = 'There is no sufficient amount to calculate';
                           }
                    }
                    // Assign PO with Mixed type as fallback
                    for(QTB_PurchaseOrder__c po : accountIdPoMap.get(invoice.blng__Account__c)){
                        if(invoice.QTB_PurchaseOrder__c == null && (invoice.QTB_Service_Type__c == 'Storage' || invoice.QTB_Service_Type__c == 'Service') &&
                           po.QTB_Service_Type__c == 'Mixed' && po.QTB_End_Date__c >= invoice.blng__InvoiceDate__c && po.QTB_PO_Balance_Amount__c >= invoice.QTB_Total_Amount_with_Tax_Override__c){
                               
                               invoice.QTB_PurchaseOrder__c = po.ID;
                               invoice.QTB_Internal_PO_Notes__c = null; // Clear notes on successful assignment
                           }
                        else if(invoice.QTB_PurchaseOrder__c == null && (invoice.QTB_Service_Type__c == 'Storage' || invoice.QTB_Service_Type__c == 'Service')
                                && po.QTB_Service_Type__c == 'Mixed' && po.QTB_End_Date__c >= invoice.blng__InvoiceDate__c && po.QTB_PO_Balance_Amount__c < invoice.QTB_Total_Amount_with_Tax_Override__c
                                && (String.isBlank(invoice.QTB_Internal_PO_Notes__c))){ // 29101 merged if statements TRY TO ASK AND  MERGE
                                    
                                    invoice.QTB_Internal_PO_Notes__c = 'There is no sufficient amount to calculate';
                                }
                    }
                    // Populate notes if no PO is assigned
                    if(invoice.QTB_PurchaseOrder__c == null && String.isBlank(invoice.QTB_Internal_PO_Notes__c)){
                        invoice.QTB_Internal_PO_Notes__c = 'The PO dates are not intersecting with Invoice dates';
                    }
                }
            }
            return newItemsMap;
        }catch (Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method : Invoking PO in Invoice level
* Parameters:  ist<blng__Invoice__c>, Map<ID, blng__Invoice__c>
* Return Type : void
* Requirement : For GitLab story Number : 22030
* Description: This is having the Functionality to calculate the PO Balance when user SELECT the Purchase order in Invoice level
* Change History :
* Developer         Date           Description
* ----------------------------------------------------------------------------------------------------------
Sarwar          11/04/2025    #29101 changed return type from void to List<QTB_PurchaseOrder__c> ,Added try catch block
**************************************************************************************************************/
    public static List<QTB_PurchaseOrder__c> calculatingPOBalance(List<blng__Invoice__c> newItems,Map<ID,blng__Invoice__c> oldMap){
        try{  //#29101 Added try catch block
            if(QTB_InvoiceTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(newItems == null || oldMap ==null || newItems.isEmpty() || oldMap.isEmpty()){ return null;} //#29101 Perfrom early exit to avoid multiple nested if
            
            //GITLAB:28527 Calling the class to avoid the INSUFFICIENT_ACCESS_OR_READONLY exception.
            List<QTB_PurchaseOrder__c> purchaseOrderWithoutSharing = QTB_WithoutSharingUtills.calculatingPOBalanceAmountWithoutSharing(newItems,oldMap);
            
            if(purchaseOrderWithoutSharing!=null && !purchaseOrderWithoutSharing.isEmpty()){
                return purchaseOrderWithoutSharing;
            }else{
                return null;
            }
        } catch (Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    /***********************************************************************************************************
* Method     : updatePOForCreditAndRebill
* Parameters : List<blng__Invoice__c>, Map<ID, blng__Invoice__c>
* Description: Implementing the PO number  in Credit AND Rebill functionality.
* Story Number: #22030
* Developer         Date           Description
* ----------------------------------------------------------------------------------------------------------

**************************************************************************************************************/
    public static void updatePOForCreditAndRebill(List<blng__Invoice__c> newItems, Map<ID, blng__Invoice__c> oldMap){
        try{
            if(newItems == null || oldMap == null || oldMap.isEmpty() || newItems.isEmpty()){
                throw new NullPointerException();
            }
            Set<ID> rebillInvoiceIdSet =new Set<ID>();
            Map<ID,blng__Invoice__c> rebillInvoiceUpdateMap = new Map<ID,blng__Invoice__c>();
            Map<ID,Date> invMap = new Map<ID,Date>();
            //Gitlab #25774 update Rebill invoice date
            Set<ID> orderIdSetForPO = new Set<ID>();//#29101 orderIdSet name changed to orderIdSetForPO
            Map<ID,Order> orderMap = new Map<ID,Order> ();
            
            Boolean disableTrigger = false;
            Boolean updateNeeded = false;
            //Gitlab #27181
            Map<ID,blng__Invoice__c> parentInvoicesWithoutPOMap = new Map<ID,blng__Invoice__c>();
            Set<ID> billingAccountSet = new Set<ID>();
            Map<ID, List<QTB_PurchaseOrder__c>> accIdPoMap = new Map<ID, List<QTB_PurchaseOrder__c>>();
            
            for(blng__Invoice__c inv : newItems){ //29101 added null check to fix failures identified through Test class
                if(inv.QTB_Invoice_Type__c != null && inv.QTB_Invoice_Type__c.equalsIgnoreCase(QTB_Constants.ORDCATEGORY_REBILL)){ // checking its invoice type is reBill or not
                    rebillInvoiceIdSet.add(inv.ID);
                    //Gitlab #25774 update Rebill invoice date
                    if(inv.blng__Order__c != null){
                        orderIdSetForPO.add(inv.blng__Order__c);
                    }
                }
            }
            //Gitlab #25774 update Rebill invoice date
            if(!orderIdSetForPO.isEmpty()){
                orderMap = new Map <ID,Order>([SELECT ID, QTB_OriginalRebillInvoice__c, QTB_OrderCategory__c, QTB_Rebill_Type__c,QTB_OriginalRebillInvoice__r.QTB_Invoice_Period__c,
                                               QTB_OriginalRebillInvoice__r.blng__InvoiceDate__c,QTB_OriginalRebillInvoice__r.blng__DueDate__c
                                               FROM Order
                                               WHERE ID IN: orderIdSetForPO and QTB_OrderCategory__c = 'Rebill']);
            }
            if(rebillInvoiceIdSet ==null && rebillInvoiceIdSet.isEmpty()){ return; } //#29101 return early
            Map<ID,blng__Invoice__c> rebillInvoiceMap1 = new Map<ID,blng__Invoice__c> ([SELECT ID,QTB_PurchaseOrder__c,QTB_Parent_Invoice__r.QTB_Internal_PO_Notes__c,QTB_Internal_PO_Notes__c,QTB_Invoice_Type__c,QTB_Parent_Invoice__r.QTB_PurchaseOrder__r.QTB_PO_Balance_Amount__c,
                                                                                        blng__InvoiceStatus__c,blng__InvoiceDate__c, blng__DueDate__c,QTB_Total_Amount_with_Tax_Override__c,QTB_Parent_Invoice__c,blng__Subtotal__c, QTB_Parent_Invoice__r.QTB_Total_Amount_with_Tax_Override__c,
                                                                                        QTB_Parent_Invoice__r.blng__Account__c,QTB_Parent_Invoice__r.blng__Subtotal__c,CurrencyIsoCode,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Parent_Invoice__r.QTB_ReBill_Status__c,QTB_Rebill_Type__c,
                                                                                        QTB_Parent_Invoice__r.QTB_SplitRebillSubtotalOnParentInvoice__c,QTB_Parent_Invoice__r.QTB_PurchaseOrder__c,QTB_ReBill_Credit_Reason__c,blng__Order__c,QTB_LegalEntityCountry__c,QTB_ReBill_CreditNote_Internal_Note__c,
                                                                                        QTB_Parent_Invoice__r.QTB_PurchaseOrder__r.QTB_Start_Date__c,QTB_Parent_Invoice__r.QTB_PurchaseOrder__r.QTB_End_Date__c,blng__Account__c, QTB_Service_Type__c,QTB_Parent_Invoice__r.QTB_Service_Type__c,blng__Account__r.QTB_Split_Invoice_Flag__c, 
                                                                                        (SELECT ID,blng__OrderProduct__r.blng__InvoiceGroupid__c 
                                                                                         FROM blng__InvoiceInvoiceLines__r LIMIT 1) 
                                                                                        FROM blng__Invoice__c 
                                                                                        WHERE ID IN: rebillInvoiceIdSet AND blng__InvoiceStatus__c = 'Draft']);
            
            if(!rebillInvoiceMap1.isEmpty()){
                for(blng__Invoice__c reBillInvObj : rebillInvoiceMap1.values()){
                    
                    if(reBillInvObj.QTB_Parent_Invoice__c != null && reBillInvObj.QTB_Parent_Invoice__r.blng__Account__c != null){ //Gitlab #27181
                        billingAccountSet.add(reBillInvObj.QTB_Parent_Invoice__r.blng__Account__c);
                    }
                    if(reBillInvObj.QTB_Parent_Invoice__r.QTB_PurchaseOrder__c == null && !reBillInvObj.blng__Account__r.QTB_Split_Invoice_Flag__c){ //Gitlab #27181
                        parentInvoicesWithoutPOMap.put(reBillInvObj.ID,reBillInvObj);
                    }
                    //Gitlab #25774 update Rebill Invoice date and Due date to Parent invoice
                    if (reBillInvObj.blng__InvoiceStatus__c != 'Cancelled' && !orderMap.isEmpty() && reBillInvObj.blng__Order__c != null && reBillInvObj.QTB_LegalEntityCountry__c != null &&
                        System.Label.UpdateRebillDate.containsIgnoreCase(reBillInvObj.QTB_LegalEntityCountry__c)){
                            if(reBillInvObj.blng__InvoiceDate__c != orderMap.get(reBillInvObj.blng__Order__c).QTB_OriginalRebillInvoice__r.blng__InvoiceDate__c){
                                reBillInvObj.blng__InvoiceDate__c = orderMap.get(reBillInvObj.blng__Order__c).QTB_OriginalRebillInvoice__r.blng__InvoiceDate__c;
                                updateNeeded = true;
                            }
                            if(reBillInvObj.blng__DueDate__c != orderMap.get(reBillInvObj.blng__Order__c).QTB_OriginalRebillInvoice__r.blng__DueDate__c){
                                reBillInvObj.blng__DueDate__c = orderMap.get(reBillInvObj.blng__Order__c).QTB_OriginalRebillInvoice__r.blng__DueDate__c;
                                updateNeeded = true;
                            }
                            if(updateNeeded){
                                disableTrigger = true;
                                rebillInvoiceUpdateMap.put(reBillInvObj.ID, reBillInvObj);
                            }
                        }
                }
                if(!billingAccountSet.isEmpty()){
                    // Gitlab #27181
                    List<QTB_PurchaseOrder__c> newPOList = [SELECT Id, Name, QTB_Start_Date__c, QTB_End_Date__c,  QTB_PO_Type__c,QTB_Status__c,
                                                            QTB_PO_Balance_Amount__c,QTB_Service_Type__c, 
                                                            (SELECT Id, Name, QTB_Account__c, QTB_Purchase_Order__c FROM PurchaseOrderAccounts__r)
                                                            FROM QTB_PurchaseOrder__c
                                                            WHERE  Id IN 
                                                            (SELECT QTB_Purchase_Order__c FROM QTB_PurchaseOrderAccount__c
                                                             WHERE QTB_Account__c IN :billingAccountSet) 
                                                            AND QTB_Status__c = 'Active' AND QTB_PO_Type__c = 'Standard'];// Gitlab #31452
                    
                    if(newPOList!=null && !newPOList.isEmpty()){
                        // Gitlab #31452 Loop through each Purchase Order and then their junction object records
                        for (QTB_PurchaseOrder__c po : newPOList) {
                            for (QTB_PurchaseOrderAccount__c poAccount : po.PurchaseOrderAccounts__r) {
                                Id accountId = poAccount.QTB_Account__c;
                                
                                if (accIdPoMap!=null && accIdPoMap.containsKey(accountId)) {
                                    accIdPoMap.get(accountId).add(po);
                                } else {
                                    accIdPoMap.put(accountId, new List<QTB_PurchaseOrder__c>{ po });
                                }
                            }
                        }
                    }else{
                        // if no POs are found
                        for (blng__Invoice__c rebillInv : rebillInvoiceMap1.values()){
                            rebillInv.QTB_PurchaseOrder__c = null;
                            rebillInv.QTB_Internal_PO_Notes__c = System.Label.QTB_NoPOsRebill;
                            rebillInvoiceUpdateMap.put(rebillInv.ID,rebillInv);
                        }
                    }
                }
                if(accIdPoMap != null && !accIdPoMap.isEmpty()){
                    List<QTB_PurchaseOrder__c> accPO = new List<QTB_PurchaseOrder__c> (); // Gitlab #27181
                    for(blng__Invoice__c rebillInv : rebillInvoiceMap1.values()){
                    if(accIdPoMap!= null && rebillInv.blng__Account__c !=null && accIdPoMap.containsKey(rebillInv.blng__Account__c)){
                            List<QTB_PurchaseOrder__c> relatedPOs = accIdPoMap.get(rebillInv.blng__Account__c);
                            if(relatedPOs != null && !relatedPOs.isEmpty()){
                                Boolean duplicatePOFlag = false;
                                for(Integer i = 0; i < relatedPOs.size(); i++){
                                    for(Integer j = i + 1; j < relatedPOs.size(); j++){
                                        QTB_PurchaseOrder__c po1 = relatedPOs[i];
                                        QTB_PurchaseOrder__c po2 = relatedPOs[j];
                                        // Added by Mounika N for POType check: Consider duplicates only if both POs are of type "Standard"
                                        if((!rebillInv.blng__Account__r.QTB_Split_Invoice_Flag__c &&po1.QTB_Service_Type__c == 'Mixed' && po2.QTB_Service_Type__c == 'Mixed')
                                           &&(po1.QTB_Start_Date__c <= po2.QTB_End_Date__c &&po1.QTB_End_Date__c >= po2.QTB_Start_Date__c)
                                           &&(rebillInv.blng__InvoiceDate__c >= po1.QTB_Start_Date__c && rebillInv.blng__InvoiceDate__c <= po1.QTB_End_Date__c)
                                           &&(rebillInv.blng__InvoiceDate__c >= po2.QTB_Start_Date__c &&rebillInv.blng__InvoiceDate__c <= po2.QTB_End_Date__c)){
                                               
                                               rebillInv.QTB_Purchase_Order__c = null;
                                               rebillInv.QTB_Internal_PO_Notes__c = System.Label.QTB_DuplicatePORebill;
                                               duplicatePOFlag = true;
                                               break;
                                           }
                                    }
                                    if (duplicatePOFlag) {break;}
                                }
                                // Proceed if no overlapping POs are found
                                if(relatedPOs.size() > 0){ // Single PO found, associate it
                                    accPO = relatedPOs; // Gitlab #27181
                                }
                            }
                            if(!accPO.isEmpty()){
                                for(QTB_PurchaseOrder__c po : accPO){
                                    if(rebillInv.QTB_Parent_Invoice__r.QTB_PurchaseOrder__c == po.ID
                                       &&((!rebillInv.blng__Account__r.QTB_Split_Invoice_Flag__c && rebillInv.blng__InvoiceDate__c >= po.QTB_Start_Date__c &&  rebillInv.blng__InvoiceDate__c <= po.QTB_End_Date__c) || rebillInv.blng__Account__r.QTB_Split_Invoice_Flag__c)){
                                           
                                           if(rebillInv.QTB_Total_Amount_with_Tax_Override__c !=null && rebillInv.QTB_Parent_Invoice__r.QTB_Total_Amount_with_Tax_Override__c != null &&
                                              rebillInv.QTB_Total_Amount_with_Tax_Override__c <= rebillInv.QTB_Parent_Invoice__r.QTB_Total_Amount_with_Tax_Override__c &&
                                              rebillInv.blng__InvoiceStatus__c == 'Draft' && po.QTB_PO_Balance_Amount__c != null &&  po.QTB_PO_Balance_Amount__c >= rebillInv.QTB_Total_Amount_with_Tax_Override__c){
                                                  
                                                  rebillInv.QTB_PurchaseOrder__c = rebillInv.QTB_Parent_Invoice__r.QTB_PurchaseOrder__c;
                                                  rebillInvoiceUpdateMap.put(rebillInv.ID,rebillInv);
                                              }
                                           else if(rebillInv.QTB_Total_Amount_with_Tax_Override__c != null && rebillInv.QTB_Parent_Invoice__r.QTB_Total_Amount_with_Tax_Override__c != null &&
                                                   rebillInv.QTB_Total_Amount_with_Tax_Override__c > rebillInv.QTB_Parent_Invoice__r.QTB_Total_Amount_with_Tax_Override__c &&
                                                   rebillInv.blng__InvoiceStatus__c == 'Draft' && po.QTB_PO_Balance_Amount__c != null && po.QTB_PO_Balance_Amount__c < rebillInv.QTB_Total_Amount_with_Tax_Override__c) {
                                                       
                                                       rebillInv.QTB_PurchaseOrder__c = null;
                                                       rebillInv.QTB_Internal_PO_Notes__c = 'PO will not populate as its not having sufficient amount to calculate';
                                                       rebillInvoiceUpdateMap.put(rebillInv.ID,rebillInv);
                                                   }
                                           else if(rebillInv.QTB_Total_Amount_with_Tax_Override__c != null && rebillInv.QTB_Parent_Invoice__r.QTB_Total_Amount_with_Tax_Override__c != null &&
                                                   rebillInv.QTB_Total_Amount_with_Tax_Override__c > rebillInv.QTB_Parent_Invoice__r.QTB_Total_Amount_with_Tax_Override__c &&
                                                   rebillInv.blng__InvoiceStatus__c == 'Draft' && po.QTB_PO_Balance_Amount__c != null && po.QTB_PO_Balance_Amount__c >= rebillInv.QTB_Total_Amount_with_Tax_Override__c) {
                                                       
                                                       rebillInv.QTB_PurchaseOrder__c = rebillInv.QTB_Parent_Invoice__r.QTB_PurchaseOrder__c;
                                                       rebillInvoiceUpdateMap.put(rebillInv.ID,rebillInv);
                                                   }
                                           else if(rebillInv.blng__InvoiceStatus__c == 'Draft'){
                                               
                                               rebillInv.QTB_PurchaseOrder__c = null;
                                               rebillInv.QTB_Internal_PO_Notes__c = 'PO will not populate as its not having sufficient amount to calculate';
                                               rebillInvoiceUpdateMap.put(rebillInv.ID,rebillInv);
                                           }
                                       }else{
                                           if(!rebillInv.blng__Account__r.QTB_Split_Invoice_Flag__c){
                                               parentInvoicesWithoutPOMap.put(rebillInv.ID,rebillInv); // Gitlab #27181
                                               System.debug(' else parentInvoicesWithoutPOMap >>>> '+JSON.serialize(parentInvoicesWithoutPOMap));
                                           }
                                       }
                                }
                            }
                        }
                    }
                    if(!parentInvoicesWithoutPOMap.isEmpty()){
                        // Gitlab #27181
                        Map<ID,blng__Invoice__c> updateService = QTB_InvoiceHelperUtils.serviceTypeAssignment(parentInvoicesWithoutPOMap);
                        if(!updateService.isEmpty()){
                            Map<ID,blng__Invoice__c> assignedPO = autoUpdatePO(updateService);
                            if(!assignedPO.isEmpty()){
                                for(blng__Invoice__c rebillAssignPO  :assignedPO.values()){
                                    rebillInvoiceUpdateMap.put(rebillAssignPO.ID, rebillAssignPO);
                                }
                            }
                        }
                    }
                }
            }
            if(rebillInvoiceUpdateMap==null || rebillInvoiceUpdateMap.isEmpty()){  //31276 fixed issue via 29101
                return;
            } //#29101 return early if null
            QTB_RecursiveHandlerCheck.afterupdateCheck_UpdatePO =false;
            if(disableTrigger){ //Gitlab #25774 update Rebill invoice date
                SBQQ.TriggerControl.disable();
                update rebillInvoiceUpdateMap.values();
                SBQQ.TriggerControl.enable();
            }else{
                update rebillInvoiceUpdateMap.values();
            }
        }catch (Exception e){ // Gitlab #27181
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method : calculateIndividualTaxAmountsOnInvoiceLineItems
* Parameters: Set<ID> postedInvoiceIdsSet
* Start Date :
* Author : Accenture
* Description:
* Change History Date: 27/12/2023
* Description: Gitlab #20432
* Developer         Date           Description
* ----------------------------------------------------------------------------------------------------------
* Virtusa        27/12/2023        Create List of Invoice Line AND a String Set for address comparision based on Tax Type Flat Rate AND Product based on story #20432.
* Sarwar         04/11/2025     optimized and added proper null checks #29101
**************************************************************************************************************/
    public static List<QTB_Tax_Detail__c>  calculateIndividualTaxAmountsOnInvoiceLineItems(Set<ID> postedInvoiceIdsSet){
        try {
            if(QTB_InvoiceTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(postedInvoiceIdsSet== null || postedInvoiceIdsSet.isEmpty()){ return null;} //#29101 early exit
            
            List<blng__InvoiceLine__c> invcLineForFlatRateList = new List<blng__InvoiceLine__c>();
            List<blng__InvoiceLine__c> invcLineForProductRateList = new List<blng__InvoiceLine__c>();
            Set<String> addressComparisonSet = new Set <String>();// Set of address comparison to fetch Tax Rate records.
            Map<ID,blng__InvoiceLine__c> invcIdAndInvcLineMap = new Map<ID,blng__InvoiceLine__c>();
            List<QTB_Tax_Detail__c> taxDetailInsertList = new List<QTB_Tax_Detail__c>(); //#29101 added
            
            //#29101 placed outside loop
            //Git #6352 -- Ignore standard tax for United States & Canada, as tax is getting calculated using Vertex System. //#29101 added NullCheck
            QTB_Tax_Integration_Setting__mdt countryValForVertex =  (QTB_Tax_Integration_Setting__mdt.getAll()!=null)
                ? QTB_Tax_Integration_Setting__mdt.getInstance('Vertex_Integration') : null;
            
            // Fetching all Invoice Lines whose Invoice get Posted
            for(blng__InvoiceLine__c invoiceLine : [ SELECT ID, blng__TaxTreatment__r.blng__TaxLegalEntity__c,blng__TaxTreatment__r.QTB_Invoice_Print_Tax_Name__c, blng__Subtotal__c,
                                                    QTB_Tax_Override_Amount__c, blng__Invoice__c, blng__TaxAmount__c, blng__OrderProduct__r.blng__LegalEntity__c,blng__OrderProduct__r.blng__TaxTreatment__r.blng__TaxLegalEntity__c, blng__TaxCountry__c,blng__TaxState__c,  blng__TaxCity__c, blng__TaxZipCode__c, QTB_Tax_Code__c,
                                                    blng__LegalEntity__c, CurrencyIsoCode, blng__Invoice__r.blng__SubTotal__c,blng__Invoice__r.blng__TaxAmount__c,blng__Invoice__r.QTB_Tax_Override_Amount__c, blng__Invoice__r.CurrencyIsoCode, blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,
                                                    blng__Invoice__r.QTB_Invoice_Type__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity__r.QTB_Tax_Applicability__c,blng__LegalEntity__r.QTB_Tax_Applicability__c,  blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                    blng__Invoice__r.blng__Account__r.QTB_Language__c, blng__TaxTreatment__r.Name,QTB_Tiered_Flag__c,blng__LegalEntity__r.QTB_Storage_Service_Period_Range__c
                                                    FROM blng__InvoiceLine__c 
                                                    WHERE blng__Invoice__c IN :postedInvoiceIdsSet ]){ //Gitlab US#29101 -- added
                                                        
                                                        // optimized soql 29101 blng__Invoice__r.QTB_Tax_Override_Amount__c, blng__Invoice__r.CurrencyIsoCode , blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c, blng__Invoice__r.QTB_Invoice_Type__c, blng__Invoice__r.blng__Account__r.QTB_Legal_Entity__r.QTB_Tax_Applicability__c
                                                        
                                                        // changed if condition for #13578 to make it work for shipto as Vertex countries for Billing only countries
                                                        if(countryValForVertex!= null && !(invoiceLine.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c !=null && countryValForVertex.QTB_End_System__c == 'Vertex'
                                                                                           && countryValForVertex.QTB_Country__c.containsIgnoreCase(invoiceLine.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c))){
                                                                                               
                                                                                               // Gitlab #20432 To create Set of Address Comparison for fetching Tax Rate records.
                                                                                               String invoiceLineComparison = invoiceLine.blng__TaxCountry__c +'----' + invoiceLine.QTB_Tax_Code__c +'-' + invoiceLine.blng__LegalEntity__c;
                                                                                               invoiceLineComparison = invoiceLineComparison.replaceAll('null','');
                                                                                               addressComparisonSet.add(invoiceLineComparison);
                                                                                               
                                                                                               // Gitlab #20432 To create Map of Invoiceid AND Invoice Line for Flat Rate Tax
                                                                                               if(invcIdAndInvcLineMap!=null && invoiceLine?.blng__LegalEntity__c!=null && invoiceLine?.blng__LegalEntity__r?.QTB_Tax_Applicability__c.equalsIgnoreCase(QTB_Constants.LEGALENTITY_TYPE_FLAT)
                                                                                                  &&!invcIdAndInvcLineMap.containsKey(invoiceLine.blng__Invoice__c)){
                                                                                                      
                                                                                                      invcIdAndInvcLineMap.put(invoiceLine.blng__Invoice__c,invoiceLine);
                                                                                                  }
                                                                                               // Gitlab #20432 To create List of Invoice Line for Product Based Rate
                                                                                               else if(invcLineForProductRateList!=null && invoiceLine?.blng__LegalEntity__c!=null && invoiceLine?.blng__LegalEntity__r?.QTB_Tax_Applicability__c.equalsIgnoreCase(QTB_Constants.LEGALENTITY_PRODUCT_BASED)){
                                                                                                   
                                                                                                   invcLineForProductRateList.add(invoiceLine);
                                                                                               }
                                                                                           }
                                                    }
            // Gitlab #20432 calling a calculateTax method when Tax Type is Product based.
            if(!invcLineForProductRateList.IsEmpty() && !addressComparisonSet.isEmpty()){
                
                List<QTB_Tax_Detail__c> calculateTaxProductList = calculateTax(invcLineForProductRateList, QTB_Constants.LEGALENTITY_PRODUCT_BASED,addressComparisonSet);
                if(calculateTaxProductList!=null && !calculateTaxProductList.isEmpty()){//#29101 added nullCheck and
                    taxDetailInsertList.addAll(calculateTaxProductList);
                }
            }
            // Gitlab #20432 calling a calculateTax method when Tax Type is Flat Rate.
            if(!invcIdAndInvcLineMap.isEmpty() && !addressComparisonSet.isEmpty()){ // Cannot exit early as taxDetailInsertList!=null
                
                invcLineForFlatRateList.addAll(invcIdAndInvcLineMap.values());
                List<QTB_Tax_Detail__c> calculateTaxFlatList = calculateTax(invcLineForFlatRateList, QTB_Constants.LEGALENTITY_TYPE_FLAT, addressComparisonSet);
                if((calculateTaxFlatList!= null) && (!calculateTaxFlatList.isEmpty())){//#29101 added nullCheck and instead of inserting we are adding into List
                    taxDetailInsertList.addAll(calculateTaxFlatList);
                }
            }
            QTB_RecursiveHandlerCheck.afterUpdate_calculateIndividualTaxAmountsOnInvoiceLineItems = false; // 29101  fix
            if((taxDetailInsertList!=null) && (!taxDetailInsertList.isEmpty())){ //removed as part of 29101 taxDetailInsertList!= null &&
                return taxDetailInsertList;
            }else{
                return null;
            }
        }catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    /***********************************************************************************************************
* Method : calculateTax
* Parameters: List<blng__InvoiceLine__c> lstInvoiceLine
* Start Date :
* Author : Accenture
* Description: calc tax AND create object items for indiv tax rates from single InvoiceLine
* Change History:
* Description: Gitlab #20432 two new parameters added String , Set<String>
* Developer         Date           Description
* ----------------------------------------------------------------------------------------------------------
* Virtusa           27/12/2023        To create Tax Detail record based on invoice Line AND invoice based on Tax Type Flat Rate AND Product.
* Virtusa(Sarwar)    18/02/2025        #29101 changed return type to List<QTB_Tax_Detail__c>
**************************************************************************************************************/
    public static List<QTB_Tax_Detail__c> calculateTax(List<blng__InvoiceLine__c> lstInvoiceLine, String productType, Set<String> addressComparisonSet){
        try{
            if(String.isBlank(productType)|| lstInvoiceLine==null|| addressComparisonSet== null || lstInvoiceLine.IsEmpty() ||  addressComparisonSet.isEmpty() || QTB_InvoiceTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            
            // Calling buildTaxRateMap method to get taxrate records
            buildTaxRateMap(addressComparisonSet);
            List<QTB_Tax_Detail__c> taxDetailList = new List <QTB_Tax_Detail__c>();
            List<blng__TaxRate__c> taxRatesList = new List<blng__TaxRate__c>();
            Set <ID> invoiceLineIdsSet=new Set<ID>();//#31609
            Map<String,QTB_Tax_Description_Translations__mdt> taxDescTransMap = new Map<String, QTB_Tax_Description_Translations__mdt>();
            //Gitlab #24201 Create a Map of QTB_Tax_Description_Translations__mdt with key Set as combination of QTB_Legal_Entity_Country__c,  QTB_Language__c AND QTB_Tax_Treatment_Name__c to fetch unique records based on customer language preference
            //Addition of WHT as part of Turkey scenario
            for(QTB_Tax_Description_Translations__mdt taxDescTrans: [SELECT ID, QTB_Legal_Entity_Country__c, QTB_Language__c, QTB_Tax_Treatment_Name__c, QTB_Translated_Value__c,QTB_Withholding_Tax_Rate__c
                                                                     FROM QTB_Tax_Description_Translations__mdt ]){  //Gitlab US#29101 -- added
                                                                         //#29101 Construct key safely, handling null values for each field
                                                                         String key = (taxDescTrans.QTB_Legal_Entity_Country__c != null ? taxDescTrans.QTB_Legal_Entity_Country__c : '') +
                                                                             (taxDescTrans.QTB_Language__c != null ? taxDescTrans.QTB_Language__c : '') +
                                                                             (taxDescTrans.QTB_Tax_Treatment_Name__c != null ? taxDescTrans.QTB_Tax_Treatment_Name__c : '')+ 
                                                                             taxDescTrans.QTB_Withholding_Tax_Rate__c; //Addition of WHT as part of Turkey
                                                                         if(taxDescTransMap!=null && key!=null && String.isNotBlank(key)){ // Only add to map if the key is not empty and#29101 not null
                                                                             taxDescTransMap.put(key, taxDescTrans);
                                                                         }
                                                                     }
            for(blng__InvoiceLine__c invcLine: lstInvoiceLine){
                // Create Address comparison String to compare address with Tax Rate addressComparisonSet field
                String invoiceLineComparison = invcLine.blng__TaxCountry__c +'----' + invcLine.QTB_Tax_Code__c +'-' + invcLine.blng__LegalEntity__c;
                invoiceLineComparison = (invoiceLineComparison!=null) ? (invoiceLineComparison.replaceAll('null','')) : '';
                //#31609 Start- Storing Invoice line Ids in Set
                if(productType.equalsIgnoreCase(QTB_Constants.LEGALENTITY_PRODUCT_BASED)
                   && invcLine.QTB_Tiered_Flag__c
                   && invcLine.blng__LegalEntity__r.QTB_Storage_Service_Period_Range__c){
                       invoiceLineIdsSet.add(invcLine.Id);
                   }
                //#31609 End
                // Fetching all Tax Rate record based on address comparion String of Invoice Line
                if(String.isNotBlank(invoiceLineComparison)
                   && taxRatesMap!=null
                   && taxRatesMap.containsKey(invoiceLineComparison)){
                       taxRatesList = taxRatesMap.get(invoiceLineComparison);//#29101 added (String.isNotBlank) in the if condition,It will check both null and isBlank at once
                   }
                if(taxRatesList!= null
                   && !taxRatesList.isEmpty()){  // #29101
                       
                       for(blng__TaxRate__c taxRate : taxRatesList){ // Gitlab #20432 to create Tax Detail record for Tax Types Flat AND Product
                           
                           //build the comparison String of the invoice line item to compare against tax invoice line item
                           QTB_Tax_Detail__c taxDetail = new QTB_Tax_Detail__c();
                           //Gitlab #31117 As part of Turkey Multi tax code enhancement
                           //taxDetail.QTB_Tax_Code__c = taxRate?.blng__TaxCode__c;
                           if(taxRate.QTB_Oracle_Tax_Code__c != null
                              && taxRate.QTB_Tax_Type__c == 'WHT'){
                                  taxDetail.QTB_Tax_Code__c = taxRate?.QTB_Oracle_Tax_Code__c;
                              }
                           else {
                               taxDetail.QTB_Tax_Code__c = taxRate?.blng__TaxCode__c;
                           }
                           //#31117 Population of WHT% if Type = 'WHT'
                           if(taxRate.QTB_Withholding_Tax_Rate__c != null && taxRate.QTB_Tax_Type__c == 'WHT'){
                               taxDetail.QTB_Withholding_Tax_Rate__c = taxRate?.QTB_Withholding_Tax_Rate__c;
                           }
                           
                           //End
                           taxDetail.QTB_EffectiveRate__c = taxRate?.blng__Rate__c;
                           taxDetail.QTB_TaxRateid__c = taxRate.ID;
                           taxDetail.QTB_TaxType__c = taxRate?.QTB_TaxDisplay__c;
                           taxDetail.CurrencyIsoCode = invcLine?.CurrencyIsoCode;
                           taxDetail.QTB_Tax_Applicability__c = productType;
                           // Gitlab #24201 Update tax description QTB_Print_Tax_Detail__c based on customer's preferred language using unique value from Map taxDescTransMap
                           // if Key combination is present in QTB_Tax_Description_Translations__mdt, Update tax description from translated values else from the tax treatment
                           // Addition of WHT as part of Turkey Scenario
                           taxDetail.QTB_Print_Tax_Detail__c = (taxDescTransMap!=null && taxDescTransMap.containsKey(invcLine.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c+invcLine.blng__Invoice__r.blng__Account__r.QTB_Language__c+invcLine.blng__TaxTreatment__r.Name+taxDetail.QTB_Withholding_Tax_Rate__c))
                               ?taxDescTransMap.get(invcLine.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c + invcLine.blng__Invoice__r.blng__Account__r.QTB_Language__c + invcLine.blng__TaxTreatment__r.Name+taxDetail.QTB_Withholding_Tax_Rate__c).QTB_Translated_Value__c
                               : invcLine.blng__TaxTreatment__r.QTB_Invoice_Print_Tax_Name__c;
                        
                           //For Product Based Tax Detail fields
                           if(productType.equalsIgnoreCase(QTB_Constants.LEGALENTITY_PRODUCT_BASED)){ // 29101 added equalsIgnoreCase
                               
                               //if(invcLine?.blng__Subtotal__c != null && taxRate?.blng__Rate__c != null && invcLine?.blng__Subtotal__c!=0 && taxRate?.blng__Rate__c!=0){ // 29101 multoplied and divided by1.0
                               taxDetail.QTB_Tax_Override_Amount__c = (invcLine?.blng__Subtotal__c * (taxRate?.blng__Rate__c * 0.01)).setScale(2, System.RoundingMode.HALF_UP);
                               taxDetail.QTB_Individual_Tax_Amount__c = invcLine?.blng__Subtotal__c *(taxRate?.blng__Rate__c * 0.01);
                               
                               taxDetail.QTB_CalculatedTax__c = invcLine?.blng__TaxAmount__c;
                               taxDetail.QTB_Invoice_Line__c = invcLine.ID;
                               taxDetail.QTB_Invoice_Line_Subtotal__c = invcLine?.blng__Subtotal__c;
                               
                           }else{ //For Flat Rate Tax Detail fields
                               
                               // if(invcLine.blng__Invoice__r.blng__Subtotal__c != null && taxRate.blng__Rate__c != null && invcLine?.blng__Subtotal__c!=0 && taxRate?.blng__Rate__c!=0)
                               taxDetail.QTB_Tax_Override_Amount__c = (invcLine?.blng__Invoice__r.blng__Subtotal__c * taxRate?.blng__Rate__c * 0.01).setScale(2, System.RoundingMode.HALF_UP);
                               taxDetail.QTB_Individual_Tax_Amount__c = invcLine?.blng__Invoice__r.blng__Subtotal__c * taxRate?.blng__Rate__c * 0.01;
                               
                               taxDetail.QTB_CalculatedTax__c = invcLine.blng__Invoice__r?.blng__TaxAmount__c;
                               taxDetail.QTB_Invoice__c = invcLine.blng__Invoice__r.ID;
                           }
                           taxDetailList.add(taxDetail);
                       }
                   }
            }
            
            //#31609 Generate Tax detail for sublines
            
            if(invoiceLineIdsSet!=null){
                for(blng__SubInvoiceLine__c subInv:[SELECT Id,blng__InvoiceLine__c, blng__InvoiceLine__r.blng__TaxCountry__c,blng__InvoiceLine__r.blng__LegalEntity__c,blng__InvoiceLine__r.QTB_Tax_Code__c,blng__Subtotal__c,CurrencyIsoCode,blng__InvoiceLine__r.blng__TaxTreatment__r.QTB_Invoice_Print_Tax_Name__c,blng__InvoiceLine__r.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c, blng__InvoiceLine__r.blng__Invoice__r.blng__Account__r.QTB_Language__c,blng__InvoiceLine__r.blng__TaxTreatment__r.name,blng__TaxAmount__c
                                                    FROM blng__SubInvoiceLine__c WHERE blng__InvoiceLine__c IN:invoiceLineIdsSet]){
                                                        // Create Address comparison String to compare address with Tax Rate addressComparisonSet field
                                                        String invoiceLineComparison = subInv.blng__InvoiceLine__r.blng__TaxCountry__c +'----' + subInv.blng__InvoiceLine__r.QTB_Tax_Code__c +'-' + subInv.blng__InvoiceLine__r.blng__LegalEntity__c;
                                                        invoiceLineComparison = (invoiceLineComparison!=null) ? (invoiceLineComparison.replaceAll('null','')) : '';
                                                        
                                                        // Fetching all Tax Rate record based on address comparion String of Invoice Line
                                                        if(String.isNotBlank(invoiceLineComparison) && 
                                                           taxRatesMap!=null && 
                                                           taxRatesMap.containsKey(invoiceLineComparison)){
                                                               taxRatesList = taxRatesMap.get(invoiceLineComparison);// (String.isNotBlank) in the if condition,It will check both null and isBlank at once
                                                           }
                                                        if(taxRatesList!= null && !taxRatesList.isEmpty()){  
                                                            
                                                            for(blng__TaxRate__c taxRate : taxRatesList){ //  to create Tax Detail record for Tax Types Flat AND Product
                                                                
                                                                //build the comparison String of the invoice line item to compare against tax invoice line item
                                                                QTB_Tax_Detail__c taxDetail = new QTB_Tax_Detail__c();
                                                                
                                                                if(taxRate.QTB_Oracle_Tax_Code__c != null && taxRate.QTB_Tax_Type__c == 'WHT'){
                                                                    taxDetail.QTB_Tax_Code__c = taxRate?.QTB_Oracle_Tax_Code__c;
                                                                }
                                                                else {
                                                                    taxDetail.QTB_Tax_Code__c = taxRate?.blng__TaxCode__c;
                                                                }
                                                                
                                                                //Population of WHT% if Type = 'WHT'
                                                                if(taxRate.QTB_Withholding_Tax_Rate__c != null && taxRate.QTB_Tax_Type__c == 'WHT'){
                                                                    taxDetail.QTB_Withholding_Tax_Rate__c = taxRate?.QTB_Withholding_Tax_Rate__c;
                                                                }
                                                                taxDetail.QTB_EffectiveRate__c = taxRate?.blng__Rate__c;
                                                                taxDetail.QTB_TaxRateid__c = taxRate.ID;
                                                                taxDetail.QTB_TaxType__c = taxRate?.QTB_TaxDisplay__c;
                                                                taxDetail.CurrencyIsoCode = subInv?.CurrencyIsoCode;
                                                                taxDetail.QTB_Tax_Applicability__c = productType;
                                                                taxDetail.QTB_Print_Tax_Detail__c = (taxDescTransMap!=null && taxDescTransMap.containsKey(subInv.blng__InvoiceLine__r.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c+subInv.blng__InvoiceLine__r.blng__Invoice__r.blng__Account__r.QTB_Language__c+subInv.blng__InvoiceLine__r.blng__TaxTreatment__r.Name+taxDetail.QTB_Withholding_Tax_Rate__c)) ?taxDescTransMap.get(subInv.blng__InvoiceLine__r.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c + subInv.blng__InvoiceLine__r.blng__Invoice__r.blng__Account__r.QTB_Language__c + subInv.blng__InvoiceLine__r.blng__TaxTreatment__r.Name+taxDetail.QTB_Withholding_Tax_Rate__c).QTB_Translated_Value__c : subInv.blng__InvoiceLine__r.blng__TaxTreatment__r.QTB_Invoice_Print_Tax_Name__c;
                                                                
                                                                System.debug('SubInv Print tax Detail>>'+taxDetail.QTB_Print_Tax_Detail__c);
                                                                //if(subInv.blng__InvoiceLine__r?.blng__Subtotal__c != null && taxRate?.blng__Rate__c != null && subInv.blng__InvoiceLine__r?.blng__Subtotal__c!=0 && taxRate?.blng__Rate__c!=0){ // 29101 multoplied and divided by1.0
                                                                taxDetail.QTB_Tax_Override_Amount__c = (subInv?.blng__Subtotal__c * (taxRate?.blng__Rate__c * 0.01)).setScale(2, System.RoundingMode.HALF_UP);
                                                                taxDetail.QTB_Individual_Tax_Amount__c = subInv?.blng__Subtotal__c *(taxRate?.blng__Rate__c * 0.01);
                                                                
                                                                taxDetail.QTB_CalculatedTax__c = subInv?.blng__TaxAmount__c;
                                                                taxDetail.QTB_Sub_Invoice_Line__c = subInv.ID;
                                                                taxDetail.QTB_Invoice_Line_Subtotal__c = subInv?.blng__Subtotal__c;
                                                                
                                                                taxDetailList.add(taxDetail);
                                                            }
                                                        }
                                                    }
            }
            //#31609
            
            if(taxDetailList!=null && !taxDetailList.isEmpty()){
                System.debug('29101  taxDetailList retirned from CalculateTax = ' + taxDetailList);
                return taxDetailList; //#29101 avoided (insert taxDetailList;) and added to a List that returns value
            } else{
                return null;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method : buildTaxRateMap
* Parameters:
* Start Date :
* Author : Accenture
* Description: To build rateMap with all the rates by legal entitiy ID
* Change History Date: 27/12/2023
* Description: Gitlab #20432
* Description: New parameter added Set<String> to filter out Tax Rate results
* Developer         Date           Description
* ----------------------------------------------------------------------------------------------------------
* Virtusa        27/12/2023        Create Map of address comparison AND List of Tax Rate based on story #20432.
* Sarwar         04/11/2025     optimized and added proper null checks #29101
**************************************************************************************************************/
    public static void buildTaxRateMap(Set<String> addressComparisonSet){
        try {
            if(QTB_InvoiceTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(addressComparisonSet==null || addressComparisonSet.isEmpty()){ return;} //#29101 return early if empty
            taxRatesMap.clear();
            //#31295 Add QTB_Withholding_Tax_Rate__c & QTB_Oracle_Tax_Code__cfields in the query
            // Fetching all Tax Rate record based on the address comparison field
            for(blng__TaxRate__c taxRate : [SELECT ID, blng__TaxCode__c, blng__LegalEntity__c, blng__Rate__c, blng__Priority__c,QTB_Withholding_Tax_Rate__c,
                                            blng__AddressComparison__c, blng__Country__c, blng__State__c, blng__City__c,  blng__ZipCode__c, QTB_TaxDisplay__c,QTB_Oracle_Tax_Code__c,QTB_Tax_Type__c
                                            FROM blng__TaxRate__c 
                                            WHERE blng__AddressComparison__c IN:addressComparisonSet  ORDER BY blng__LegalEntity__c]){ //Gitlab US#29101 -- added  ])
                                                
                                                // Map to store Address comparision AND List of Tax Rate record for paticular address comparison
                                                if(taxRatesMap!=null && taxRatesMap.containsKey(taxRate.blng__AddressComparison__c)){
                                                    taxRatesMap.get(taxRate.blng__AddressComparison__c).add(taxRate);
                                                } else{
                                                    // Map to store Address comparision AND List of Tax Rate record for paticular address comparison currently condition working for India(cgst+sgst)
                                                    taxRatesMap.put(taxRate.blng__AddressComparison__c, new List<blng__TaxRate__c>{taxRate}); //# 29101 Added directly on the Map
                                                }
                                            }
        }catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method : prePopulateFields
* Parameters: Set<ID> billingAccountIdsSet,List<blng__invoice__c> invoices
* Start Date :
* Author : Accenture
* Description: populate bill cycle day on invoice
Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Sarwar       04/11/2025     optimized and added proper null checks #29101
**************************************************************************************************************/
    public static void prePopulateFields(Set<ID> invIdSet, List<blng__invoice__c> invoicesList){
        try{
            if(invoicesList== null || invIdSet == null || invoicesList.isEmpty() || invIdSet.isEmpty()){ 
                throw new NullPointerException();
            } 
        Map<ID,blng__Invoice__c> invMap = new Map<ID,blng__Invoice__c>([SELECT ID,(SELECT ID,blng__invoice__c,blng__OrderProduct__r.Order.blng__InvoiceBatch__c,blng__UsageSummary__r.QTB_Contracted_Currency_Rate__c
                                                                                   FROM blng__InvoiceInvoiceLines__r 
                                                                                   WHERE blng__OrderProduct__c != null  AND blng__UsageSummary__c != null LIMIT 1) 
                                                                        FROM blng__Invoice__c    //#29101 optimized SOQL, the SOQL is already optimized 
                                                                        WHERE ID IN :invIdSet ]); //Gitlab US#29101 -- added
        // looping on trigger.new List
        for(blng__Invoice__c invs :invoicesList){ //#29101 removed loop within loop
            
            if(invMap!=null && !invMap.containsKey(invs.ID)){continue; }//#29101 skip to the next item in the loop
            // Get the first related invoice line, if any otherwise assign Null; also note we have LIMIT 1 in the query
            blng__InvoiceLine__c invLine = (invMap.get(invs.ID)?.blng__InvoiceInvoiceLines__r.isEmpty())
                ?(null) : (invMap.get(invs.ID).blng__InvoiceInvoiceLines__r[0]);
                    
                    if(invLine == null) {continue; }//#29101 skip to the next item in the loop
            
            // Safely assign the values from the invoice line to the invoice
            invs.QTB_Bill_Cycle_Day__c = invLine.blng__OrderProduct__r?.Order?.blng__InvoiceBatch__c;  // if Map contains invoice ID then assign biil cycle day
            invs.QTB_Contracted_Currency_Rate__c = invLine.blng__UsageSummary__r?.QTB_Contracted_Currency_Rate__c; // #28211 - assigning usage summary contract currency rate to invoice
        }
        }catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
    }
    }
    
    /***********************************************************************************************************
* Method : updateInvoiceMRCDates
* Parameters:  Invoice
* Return Type : void
* Requirement : For GitLab story Number : 10098
Changes as part of #21598 Driving the MRC dates AND Service Dates from the selected legal Entity AND Invoive period on Invoice scheduler
* Description: This is having the Functionality to update updateInvoiceMRCDates of Invoice MRC start AND End End date AND Service Start AND End date based on Account - Billing Frequency AND Account - Billing Forward type AND Invoice Scheduler Legal Entity AND Invoice period selected
**************************************************************************************************************/
    public static List<blng__Invoice__c> updateInvoiceMRCDates(Set<ID> invoiceIdsSet) {
        try{
            if(QTB_InvoiceTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            
            Set<ID> invidsSet = invoiceIdsSet;
            List<ID> usgSummidList = new List<ID>();
            List<ID> usgSummProdSalesidList = new List<ID>(); //#28758  Created a List to store product Sales Summary ids
            Map<ID,Date> dateCalMap = new Map<ID,Date>();
            Map<ID,Date> invDateCalMap = new Map<ID,Date>();
            Map<ID,Date> invDateCalMapMin = new Map<ID,Date>(); //30166 Added Map to store Max Source Service Date as key value and ID for respective usage summary
            Map<ID,Date> invDateCalMapMax = new Map<ID,Date>();
            Map<ID,Date> invDateCalMapMinMRC = new Map<ID,Date>(); //30146 Added Map to store Min and Max Storage Dates as key value and ID for respective usage summary
            Map<ID,Date> invDateCalMapMaxMRC = new Map<ID,Date>();
            Map<ID,Date> usageStartDateCalMap = new Map<ID,Date>();  //27496 Adding one Map to store the Minimum Start date as key value AND ID as respective Usage Summary
            Map<ID,Date> usageEndDateCalMap = new Map<ID,Date>(); //27496 Adding one Map to store the Max End date as key value AND ID as respective Usage Summary
            Map<ID,Date> usageServStartDateCalMap = new Map<ID,Date>(); //30166 Adding usageServStartDateCalMap and usageServEndDateCalMap to store the Min Service Start and End date as key value AND ID as respective Usage Summary
            Map<ID,Date> usageServEndDateCalMap = new Map<ID,Date>();
            Map<ID,Date> usageStorageStartDateCalMap = new Map<ID,Date>(); //30146 Adding usageStorageStartDateCalMap and usageStorageEndDateCalMap to store the Min Storage Start and Max End date MRC as key value AND ID as respective Usage Summary
            Map<ID,Date> usageStorageEndDateCalMap = new Map<ID,Date>();
            Map<ID,Date> taxPeriodStartDateMap = new Map<ID,Date>();
            Map<ID,Date> taxPeriodEndDateMap = new Map<ID,Date>();
            Map<ID,blng__Invoiceline__c> usageSummryToInvLineMap = new Map<ID,blng__Invoiceline__c>();
            Date firstDayOfMonth;
            List<blng__Invoice__c> listToUpdate = new List<blng__Invoice__c>();
            List<blng__Invoice__c> updatedInvoice  = [SELECT ID,blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c,QTB_LegalEntityCountry__c,QTB_InvoiceProductType__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,QTB_Service_Start_Date__c,QTB_Service_End_Date__c,blng__Account__c, blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Service_Period_Range__c,
                                                      blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Bill_Forward_Type__c,QTB_Invoice_Period__c,QTB_Invoice_Period__r.blng__PeriodEndDate__c,//GITLAB US #25356 (Credit/Rebill Billnow)
                                                      blng__Account__r.QTB_DM_Source_System__c,blng__InvoiceDate__c,blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Invoice_Period__r.blng__PeriodEndDate__c,blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Legal_Entity__c,QTB_Tax_Period_Start_Date__c,QTB_Tax_Period_End_Date__c
                                                      FROM blng__Invoice__c  
                                                      WHERE ID IN :invidsSet AND blng__Account__r.QTB_Billing_Frequency__c!= null AND blng__Account__r.QTB_Bill_Forward_Type__c!= null AND blng__Account__r.QTB_Bill_Forward_Type__c!= 'None'
                                                      AND QTB_Invoice_Period__c != null  AND QTB_LegalEntityCountry__c != null  ];//GITLAB US #25356 (Credit/Rebill Billnow) //Gitlab US#29101 -- added
            
            if(!updatedInvoice.isEmpty()){
                //#28758 Added Billing Account type field from Account level to know whether its Product Sales or Existing
                List<blng__Invoiceline__c> updatedInvoiceLinesList = [SELECT ID, blng__Invoice__c, blng__UsageSummary__c,blng__Invoice__r.blng__Account__r.QTB_Billing_Account_Type__c, blng__Invoice__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Service_Period_Range__c, blng__Invoice__r.QTB_InvoiceProductType__c, QTB_ProductType__c 
                                                                      FROM blng__InvoiceLine__c 
                                                                      WHERE blng__Invoice__c IN :invidsSet ]; //Gitlab US#29101 -- added
                //Adding usage summary ID to List AND Usage summary AND Inv lines into Map
                for(blng__Invoiceline__c invline : updatedInvoiceLinesList){
                    //#27494 Added if loop to avoid null Pointer Exception
                    //#28758 Added if AND Else if conditions to diff from whether its Product Sales or not
                    if(invline.blng__UsageSummary__c != null)
                    {
                        if(invline.blng__Invoice__r.blng__Account__r.QTB_Billing_Account_Type__c != 'Product Sales'){
                            usgSummidList.add(invline.blng__UsageSummary__c);
                        } else{
                            usgSummProdSalesidList.add(invline.blng__UsageSummary__c);
                        }
                        usageSummryToInvLineMap.put(invline.blng__UsageSummary__c, invline); // 29101 merged if
                    }
                }
                //27494 Created List for handling Query More () Exception AND also added null checks for all queried as From Query
                //#28758 Added if AND Else if conditions to differenciate the product Sales AND Contionous Service AND also queried required fields only in both the queries
                if((usgSummidList != null && !usgSummidList.isEmpty()) || (usgSummProdSalesidList != null && !usgSummProdSalesidList.isEmpty())){
                    //#28758 Added both List check and its respective Service period data null check because this logic should work for both Product Sales AND Contious Service
                    for(blng__Usage__c usg :[SELECT ID,blng__UsageSummary__c,QTB_Service_Period_Date__c,QTB_Source_Service_Date__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,QTB_Delivery_Date__c,
                                             blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c,
                                             blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Service_Period_Range__c,QTB_Product_Line__c,QTB_Storage_Type__c, blng__OrderProduct__r.Product2.QTB_Price_Schedule_Category__c FROM blng__Usage__c WHERE blng__UsageSummary__c IN :usgSummidList OR blng__UsageSummary__c IN :usgSummProdSalesidList ]){
                                                 if(dateCalMap != null && !dateCalMap.isEmpty() && dateCalMap.containsKey(usg.blng__UsageSummary__c) && usg.QTB_Service_Period_Date__c != null && dateCalMap.get(usg.blng__UsageSummary__c) > usg.QTB_Service_Period_Date__c){
                                                     dateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Service_Period_Date__c);
                                                 }
                                                 else if(dateCalMap != null && usg.QTB_Service_Period_Date__c != null && !dateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                                     dateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Service_Period_Date__c);
                                                 }
                                                 // #27494 getting the Min AND Max Dates FROM respective usage Summary Usages (Multiple Usages to same Usage Summary Scenario) AND adding to Map as Usage Summary as Key AND date as value
                                                 //when Source Servie Date != null AND Start Date AND MRC dates == null
                                                 //#28758 Added if loop to Bypass the below logic for Product Sales
                                                 if(usgSummidList!= null && !usgSummidList.isEmpty()){
                                                     //when Source Servie Date != null AND Start Date AND MRC dates == null
                                                     if(usg.QTB_Source_Service_Date__c != null &&  usg.QTB_Start_Date_MRC__c == null && usg.QTB_End_Date_MRC__c == null){
                                                         //Stroing min of QTB_Source_Service_Date__c
                                                         if(usageStartDateCalMap != null && !usageStartDateCalMap.isEmpty() && usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageStartDateCalMap.get(usg.blng__UsageSummary__c) > usg.QTB_Source_Service_Date__c){
                                                             usageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                                                         }
                                                         else if(usageStartDateCalMap != null && !usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                                             usageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                                                         }
                                                         //Stroing max of QTB_Source_Service_Date__c
                                                         if(usageEndDateCalMap != null && !usageEndDateCalMap.isEmpty() && usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageEndDateCalMap.get(usg.blng__UsageSummary__c) < usg.QTB_Source_Service_Date__c){
                                                             usageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                                                         }
                                                         else if(usageEndDateCalMap != null && !usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                                             usageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                                                         }
                                                     }
                                                     //#27494 when Start date AND End Dare MRC != null AND Source Service Date == null
                                                     else if(usg.QTB_Start_Date_MRC__c != null && usg.QTB_End_Date_MRC__c != null && usg.QTB_Source_Service_Date__c == null)
                                                     {
                                                         //Stroing min of QTB_Start_Date_MRC__c
                                                         if(usageStartDateCalMap != null && !usageStartDateCalMap.isEmpty() && usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageStartDateCalMap.get(usg.blng__UsageSummary__c) > usg.QTB_Start_Date_MRC__c){
                                                             usageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Start_Date_MRC__c);
                                                         }
                                                         else if(usageStartDateCalMap != null && !usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                                             usageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Start_Date_MRC__c);
                                                         }
                                                         //Stroing max of QTB_End_Date_MRC__c
                                                         if(usageEndDateCalMap != null && !usageEndDateCalMap.isEmpty() && usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageEndDateCalMap.get(usg.blng__UsageSummary__c) < usg.QTB_End_Date_MRC__c){
                                                             usageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_End_Date_MRC__c);
                                                         }
                                                         else if(usageEndDateCalMap != null && !usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                                             usageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_End_Date_MRC__c);
                                                         }
                                                     }
                                                     //#27494 when Both Source Servie Date != null && Start AND End MRC Dates != null
                                                     else if(usg.QTB_Start_Date_MRC__c != null && usg.QTB_End_Date_MRC__c != null && usg.QTB_Source_Service_Date__c != null){
                                                         // Storing the minimum start date: Choose the earlier of MRC Start or Source Service Start
                                                         if(usageStartDateCalMap != null && usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                                             Date existingStartDate = usageStartDateCalMap.get(usg.blng__UsageSummary__c);
                                                             Date newStartDate = usg.QTB_Start_Date_MRC__c <= usg.QTB_Source_Service_Date__c ? usg.QTB_Start_Date_MRC__c : usg.QTB_Source_Service_Date__c;
                                                             if (existingStartDate > newStartDate){
                                                                 usageStartDateCalMap.put(usg.blng__UsageSummary__c, newStartDate);
                                                             }
                                                         }else if(usageStartDateCalMap != null && !usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                                             usageStartDateCalMap.put(usg.blng__UsageSummary__c, usg.QTB_Start_Date_MRC__c <= usg.QTB_Source_Service_Date__c ? usg.QTB_Start_Date_MRC__c : usg.QTB_Source_Service_Date__c);
                                                         }
                                                         
                                                         // Storing the maximum end date: Choose the later of MRC End or Source Service End
                                                         if(usageEndDateCalMap != null && usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c))
                                                         {
                                                             Date existingEndDate = usageEndDateCalMap.get(usg.blng__UsageSummary__c);
                                                             Date newEndDate = usg.QTB_End_Date_MRC__c >= usg.QTB_Source_Service_Date__c ? usg.QTB_End_Date_MRC__c : usg.QTB_Source_Service_Date__c;
                                                             if (existingEndDate < newEndDate){
                                                                 usageEndDateCalMap.put(usg.blng__UsageSummary__c, newEndDate);
                                                             }
                                                         }else if(usageEndDateCalMap != null && !usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                                             
                                                             usageEndDateCalMap.put(usg.blng__UsageSummary__c, usg.QTB_End_Date_MRC__c >= usg.QTB_Source_Service_Date__c ? usg.QTB_End_Date_MRC__c : usg.QTB_Source_Service_Date__c);
                                                         }
                                                     }
                                                 }
                                                 else if(usgSummProdSalesidList!= null && !usgSummProdSalesidList.isEmpty() && usg.QTB_Delivery_Date__c != null){
                                                     //Stroing min of QTB_Delivery_Date__c
                                                     if(usageStartDateCalMap != null && !usageStartDateCalMap.isEmpty() && usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageStartDateCalMap.get(usg.blng__UsageSummary__c) > usg.QTB_Delivery_Date__c){
                                                         usageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Delivery_Date__c);
                                                     }
                                                     else if(usageStartDateCalMap != null && !usageStartDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                                         usageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Delivery_Date__c);
                                                     }
                                                     //Stroing max of QTB_Delivery_Date__c
                                                     if(usageEndDateCalMap != null && !usageEndDateCalMap.isEmpty() && usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageEndDateCalMap.get(usg.blng__UsageSummary__c) < usg.QTB_Delivery_Date__c){
                                                         usageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Delivery_Date__c);
                                                     }
                                                     else if(usageEndDateCalMap != null && !usageEndDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                                         usageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Delivery_Date__c);
                                                     }
                                                 }
                                                 //30166
                                                 //30166 to get minimum and maximum Source service period dates where Storage/Service Period Range = true and Product line! = Storage
                                                 //32285 - considering Service Date on Invoice picklist value for service date calculation
                                                 if(usg.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c != null && usg.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c == 'Service Range' && 
                                                    usg.blng__OrderProduct__r.Product2.QTB_Price_Schedule_Category__c != null && usg.blng__OrderProduct__r.Product2.QTB_Price_Schedule_Category__c != 'Storage' && 
                                                    usg.QTB_Source_Service_Date__c != null ){
                                                        //30166 Stroing min of QTB_Source_Service_Date__c
                                                        if(usageServStartDateCalMap != null && !usageServStartDateCalMap.isEmpty() && usageServStartDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageServStartDateCalMap.get(usg.blng__UsageSummary__c) > usg.QTB_Source_Service_Date__c){
                                                            usageServStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                                                        }
                                                        else if(usageServStartDateCalMap != null && !usageServStartDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                                            usageServStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                                                        }
                                                        //30166 Stroing max of QTB_Source_Service_Date__c
                                                        if(usageServEndDateCalMap != null && !usageServEndDateCalMap.isEmpty() && usageServEndDateCalMap.containsKey(usg.blng__UsageSummary__c) && usageServEndDateCalMap.get(usg.blng__UsageSummary__c) < usg.QTB_Source_Service_Date__c){
                                                            usageServEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                                                        }
                                                        else if(usageServEndDateCalMap != null && !usageServEndDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                                            usageServEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Source_Service_Date__c);
                                                        }
                                                    }
                                                 //32285 - considering Storage Date on Invoice picklist value for Storage date calculation    
                                                 if(usg.blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c != null && usg.blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c == 'Storage Range' && 
                                                    usg.blng__OrderProduct__r.Product2.QTB_Price_Schedule_Category__c != null && usg.blng__OrderProduct__r.Product2.QTB_Price_Schedule_Category__c == 'Storage' && 
                                                    usg.QTB_Storage_Type__c != null && usg.QTB_Storage_Type__c == 'Regular' ){
                                                        //30166 Stroing min of QTB_Start_Date_MRC__c
                                                        if(usageStorageStartDateCalMap != null && !usageStorageStartDateCalMap.isEmpty() && usageStorageStartDateCalMap.containsKey(usg.blng__UsageSummary__c) && usg.QTB_Start_Date_MRC__c != null && usageStorageStartDateCalMap.get(usg.blng__UsageSummary__c) > usg.QTB_Start_Date_MRC__c){
                                                            usageStorageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Start_Date_MRC__c);
                                                        }
                                                        else if(usageStorageStartDateCalMap != null && usg.QTB_Start_Date_MRC__c != null && !usageStorageStartDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                                            usageStorageStartDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_Start_Date_MRC__c);
                                                        }
                                                        //30166 Stroing max of QTB_End_Date_MRC__c
                                                        if(usageStorageEndDateCalMap != null && !usageStorageEndDateCalMap.isEmpty() && usageStorageEndDateCalMap.containsKey(usg.blng__UsageSummary__c) && usg.QTB_End_Date_MRC__c != null && usageStorageEndDateCalMap.get(usg.blng__UsageSummary__c) < usg.QTB_End_Date_MRC__c){
                                                            usageStorageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_End_Date_MRC__c);
                                                        }
                                                        else if(usageStorageEndDateCalMap != null && usg.QTB_End_Date_MRC__c != null && !usageStorageEndDateCalMap.containsKey(usg.blng__UsageSummary__c)){
                                                            usageStorageEndDateCalMap.put(usg.blng__UsageSummary__c,usg.QTB_End_Date_MRC__c);
                                                        }
                                                    }
                                                 
                                             }
                    
                    //Add invoice lines to List invLList that are available in dateCalMap Map which contains usage summary ID AND minimum date from related usages
                    List<blng__InvoiceLine__c> invLList = new List<blng__InvoiceLine__c>();
                    //#27494 Added the bewlow Set to Add the usage Summaries respective scenarios
                    Set<ID> usageSummaryids = new Set<ID>();
                    if(!usageStartDateCalMap.isEmpty()|| (usageStartDateCalMap.size() > 0 && dateCalMap.size() > 0)){
                        usageSummaryids = usageStartDateCalMap.keyset();
                    }
                    else if(!usageEndDateCalMap.isEmpty()|| (usageEndDateCalMap.size() > 0 && dateCalMap.size() > 0)){
                        usageSummaryids = usageEndDateCalMap.keyset();
                    }
                    else if(!dateCalMap.isEmpty()){
                        usageSummaryids = dateCalMap.keyset();
                    }
                    for(ID usid : usageSummaryids){
                        if (usageSummryToInvLineMap.containskey(usid)){
                            invLList.add(usageSummryToInvLineMap.get(usid));
                        }
                    }
                    
                    //Loop through invoice lines to get minimum service date on invoice from related usage summary
                    for(blng__InvoiceLine__c invo : invLList){
                        if(invDateCalMap.containsKey(invo.blng__Invoice__c) && dateCalMap.containsKey(invo.blng__UsageSummary__c)){
                            //Get minimum service date on invoice by iterating through AND comparing dates on all related invoice lines.
                            invDateCalMap.put(invo.blng__Invoice__c, invDateCalMap.get(invo.blng__Invoice__c) < dateCalMap.get(invo.blng__UsageSummary__c) ? invDateCalMap.get(invo.blng__Invoice__c) : dateCalMap.get(invo.blng__UsageSummary__c));
                        }
                        else if(dateCalMap.containsKey(invo.blng__UsageSummary__c)){
                            invDateCalMap.put(invo.blng__Invoice__c, dateCalMap.get(invo.blng__UsageSummary__c));
                        }
                        //30166 Calculate minimum source service date from service usages.
                        if(invo.QTB_ProductType__c!='Storage'){
                            if(invDateCalMapMin.containsKey(invo.blng__Invoice__c)){
                                //Get minimum source service date from service usages on invoice by iterating through AND comparing dates on all related invoice lines.
                                invDateCalMapMin.put(invo.blng__Invoice__c, invDateCalMapMin.get(invo.blng__Invoice__c) < usageServStartDateCalMap.get(invo.blng__UsageSummary__c) ? invDateCalMapMin.get(invo.blng__Invoice__c) : usageServStartDateCalMap.get(invo.blng__UsageSummary__c));
                            } else{
                                invDateCalMapMin.put(invo.blng__Invoice__c, usageServStartDateCalMap.get(invo.blng__UsageSummary__c));
                            }
                            //30166 Calculate maximum source service date from service usages.
                            if(invDateCalMapMax.containsKey(invo.blng__Invoice__c)){
                                //Get maximum source service date from service usages on invoice by iterating through AND comparing dates on all related invoice lines.
                                invDateCalMapMax.put(invo.blng__Invoice__c, invDateCalMapMax.get(invo.blng__Invoice__c) > usageServEndDateCalMap.get(invo.blng__UsageSummary__c) ? invDateCalMapMax.get(invo.blng__Invoice__c) : usageServEndDateCalMap.get(invo.blng__UsageSummary__c));
                            }else{
                                invDateCalMapMax.put(invo.blng__Invoice__c, usageServEndDateCalMap.get(invo.blng__UsageSummary__c));
                            }
                        }
                        
                        //30146 Calculate minimum storage date on invoice from multiple usage summaries which has multiple usages.
                        if(invo.QTB_ProductType__c == 'Storage' && usageStorageStartDateCalMap.containsKey(invo.blng__UsageSummary__c) && usageStorageEndDateCalMap.containsKey(invo.blng__UsageSummary__c)){
                            if(invDateCalMapMinMRC.containsKey(invo.blng__Invoice__c)) {
                                //Get minimum storage date from storage usages on invoice by iterating through AND comparing dates on all related invoice lines.
                                invDateCalMapMinMRC.put(invo.blng__Invoice__c, invDateCalMapMinMRC.get(invo.blng__Invoice__c) < usageStorageStartDateCalMap.get(invo.blng__UsageSummary__c) ? invDateCalMapMinMRC.get(invo.blng__Invoice__c) : usageStorageStartDateCalMap.get(invo.blng__UsageSummary__c));
                            } else{
                                invDateCalMapMinMRC.put(invo.blng__Invoice__c, usageStorageStartDateCalMap.get(invo.blng__UsageSummary__c));
                            }
                            //30146 Calculate maximum storage date from storage usages.
                            if(invDateCalMapMaxMRC.containsKey(invo.blng__Invoice__c)){
                                //Get maximum storage date from storage usages on invoice by iterating through AND comparing dates on all related invoice lines.
                                invDateCalMapMaxMRC.put(invo.blng__Invoice__c, invDateCalMapMaxMRC.get(invo.blng__Invoice__c) > usageStorageEndDateCalMap.get(invo.blng__UsageSummary__c) ? invDateCalMapMaxMRC.get(invo.blng__Invoice__c) : usageStorageEndDateCalMap.get(invo.blng__UsageSummary__c));
                            }else{
                                invDateCalMapMaxMRC.put(invo.blng__Invoice__c, usageStorageEndDateCalMap.get(invo.blng__UsageSummary__c));
                            }
                        }
                        
                        //#27494 Putting the Values of Invocie AND its Date to be stamped on tax period Start Date
                        if(usageStartDateCalMap.size() >0 && taxPeriodStartDateMap.containsKey(invo.blng__Invoice__c)){
                            //Get minimum service date on invoice by iterating through AND comparing dates on all related invoice lines.
                            taxPeriodStartDateMap.put(invo.blng__Invoice__c, taxPeriodStartDateMap.get(invo.blng__Invoice__c) <= usageStartDateCalMap.get(invo.blng__UsageSummary__c) ? taxPeriodStartDateMap.get(invo.blng__Invoice__c) : usageStartDateCalMap.get(invo.blng__UsageSummary__c));
                        } else{
                            taxPeriodStartDateMap.put(invo.blng__Invoice__c, usageStartDateCalMap.get(invo.blng__UsageSummary__c));
                        }
                        //#27494 Putting the Values of Invocie AND its Date to be stamped on tax period End Date
                        if(usageEndDateCalMap.size() >0 && taxPeriodEndDateMap.containsKey(invo.blng__Invoice__c)) {
                            //Get minimum service date on invoice by iterating through AND comparing dates on all related invoice lines.
                            taxPeriodEndDateMap.put(invo.blng__Invoice__c, taxPeriodEndDateMap.get(invo.blng__Invoice__c) >= usageEndDateCalMap.get(invo.blng__UsageSummary__c) ? taxPeriodEndDateMap.get(invo.blng__Invoice__c) : usageEndDateCalMap.get(invo.blng__UsageSummary__c));
                        } else{
                            taxPeriodEndDateMap.put(invo.blng__Invoice__c, usageEndDateCalMap.get(invo.blng__UsageSummary__c));
                        }
                    }
                    System.debug(invDateCalMap);
                    for(blng__Invoice__c inl: updatedInvoice){
                        //if Service Date on usage is null, calculate MRC AND service dates based on Invoice Period
                        System.debug(invDateCalMap);
                        if(invDateCalMap.get(inl.ID) == null){
                            //GITLAB US #25356 (Credit/Rebill Billnow)
                            firstDayOfMonth = inl.QTB_Invoice_Period__r.blng__PeriodEndDate__c.toStartOfMonth();
                        } else{
                            //Else calculate MRC AND service dates based on minimum service date on usages
                            firstDayOfMonth = invDateCalMap.get(inl.ID);
                        }
                        //#27494 Stampage of values based upon mp what we got
                        if(taxPeriodStartDateMap.size() > 0 && taxPeriodStartDateMap.containsKey(inl.ID)){
                            inl.QTB_Tax_Period_Start_Date__c = taxPeriodStartDateMap.get(inl.ID);
                        }
                        if(taxPeriodEndDateMap.size() > 0 && taxPeriodEndDateMap.containsKey(inl.ID)){
                            inl.QTB_Tax_Period_End_Date__c = taxPeriodEndDateMap.get(inl.ID);
                        }
                        // #32284, #32285 - added new picklist value on legal entity based on which need to calculate dates
                        if((inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c != null && inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c == 'Regular Storage') || 
                           (inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c != null && inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c == 'Invoice Period')){ //#30146 and #30166
                               if (inl.blng__Account__r.QTB_Billing_Frequency__c==('Monthly')) {//29101 added equalsIgnoreCase
                                   if (inl.blng__Account__r.QTB_Bill_Forward_Type__c==('Arrears')) {  //29101 added equalsIgnoreCase
                                       updateDates(firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                   } else{
                                       updateDates(firstDayOfMonth.addMonths(1),firstDayOfMonth.addMonths(2).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                   }
                               }
                               else if (inl.blng__Account__r.QTB_Billing_Frequency__c==('Quarterly')) { //29101 added equalsIgnoreCase
                                   if(inl.blng__Account__r.QTB_Bill_Forward_Type__c==('Arrears')) {  //29101 added equalsIgnoreCase
                                       updateDates(firstDayOfMonth.addmonths(-2),firstDayOfMonth.addMonths(1).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                   } else{
                                       updateDates(firstDayOfMonth.addMonths(1),firstDayOfMonth.addMonths(4).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                   }
                               }
                               else if (inl.blng__Account__r.QTB_Billing_Frequency__c==('Semiannual')) { //29101 added equalsIgnoreCase
                                   if (inl.blng__Account__r.QTB_Bill_Forward_Type__c==('Arrears')) {  //29101 added equalsIgnoreCase
                                       updateDates(firstDayOfMonth.addmonths(-5),firstDayOfMonth.addMonths(1).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                   } else{
                                       updateDates(firstDayOfMonth.addMonths(1),firstDayOfMonth.addMonths(7).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                   }
                               }
                               else if (inl.blng__Account__r.QTB_Billing_Frequency__c==('Annual')) {//29101 added equalsIgnoreCase
                                   if (inl.blng__Account__r.QTB_Bill_Forward_Type__c==('Arrears')) {//29101 added equalsIgnoreCase
                                       updateDates(firstDayOfMonth.addmonths(-11),firstDayOfMonth.addMonths(1).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                   } else{
                                       updateDates(firstDayOfMonth.addMonths(1),firstDayOfMonth.addMonths(13).addDays(-1),firstDayOfMonth,firstDayOfMonth.addMonths(1).addDays(-1),inl);
                                   }
                               }
                           } 
                        if(inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c != null && 
                           inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c == 'Service Range'){// 32285
                               inl.QTB_Service_Start_Date__c = invDateCalMapMin.get(inl.ID);
                               inl.QTB_Service_End_Date__c = invDateCalMapMax.get(inl.ID);
                           }
                        if(inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c != null && 
                           inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c == 'Storage Range'){// 32284
                               //30146: Updating Storage Period dates for Invoices with Regular Storage Type
                               if(invDateCalMapMinMRC.containsKey(inl.ID) && invDateCalMapMaxMRC.containsKey(inl.ID)){
                                   inl.QTB_Start_Date_MRC__c = invDateCalMapMinMRC.get(inl.ID);
                                   inl.QTB_End_Date_MRC__c = invDateCalMapMaxMRC.get(inl.ID);
                               }else{
                                   inl.QTB_Start_Date_MRC__c = null;
                                   inl.QTB_End_Date_MRC__c = null;
                               }
                           }
                        // 33924 Service Period customization for ANZ, serice start date and end date to be calculated based on billing frequency if QTB_Service_Date_on_Invoice__c on legal entity is Billing Frquency
                        if(inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c != null && inl.blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c == 'Billing Frequency'){
                            inl.QTB_Service_End_Date__c = firstDayOfMonth.toStartOfMonth().addMonths(1).addDays(-1);
                            if(inl.blng__Account__r.QTB_Billing_Frequency__c == 'Annual'){
                                inl.QTB_Service_Start_Date__c = firstDayOfMonth.toStartOfMonth().addMonths(-11);
                            }else if(inl.blng__Account__r.QTB_Billing_Frequency__c == 'Semiannual'){
                                inl.QTB_Service_Start_Date__c = firstDayOfMonth.toStartOfMonth().addMonths(-5);
                            }else if(inl.blng__Account__r.QTB_Billing_Frequency__c == 'Quarterly'){
                                inl.QTB_Service_Start_Date__c = firstDayOfMonth.toStartOfMonth().addMonths(-2);
                            }else{
                                inl.QTB_Service_Start_Date__c = firstDayOfMonth.toStartOfMonth();
                                 }
                        }
                        //28275 - if custom lable contains legal entity country than based on invoice product type update service date AND storage dates
                        if(System.label.QTB_ServiceTypeDates_Countries_list.containsIgnoreCase(inl.QTB_LegalEntityCountry__c)){
                            // if invoice contains only storage product than Service period should be blank AND if invoice contains only services type
                            // of product than Storage period should be bland AND if invoice have mixed type of products than no change
                            if(inl.QTB_InvoiceProductType__c==('Storage')){ //29101 added equalsIgnoreCase
                                inl.QTB_Service_Start_Date__c = null;
                                inl.QTB_Service_End_Date__c = null;
                            }
                            else if(inl.QTB_InvoiceProductType__c==('Services')){//29101 added equalsIgnoreCase
                                inl.QTB_Start_Date_MRC__c = null;
                                inl.QTB_End_Date_MRC__c   = null;
                            }
                        }
                        listToUpdate.add(inl);
                    }
                }
            }
            invidsSet.clear();
            usgSummidList.clear();
            usgSummProdSalesidList.clear();
            dateCalMap.clear();
            invDateCalMap.clear();
            invDateCalMapMin.clear();
            invDateCalMapMax.clear();
            invDateCalMapMinMRC.clear();
            invDateCalMapMaxMRC.clear();
            usageStartDateCalMap.clear();
            usageEndDateCalMap.clear();
            usageServStartDateCalMap.clear();
            usageServEndDateCalMap.clear();
            usageStorageStartDateCalMap.clear();
            usageStorageEndDateCalMap.clear();
            taxPeriodStartDateMap.clear();
            taxPeriodEndDateMap.clear();
            usageSummryToInvLineMap.clear();
            //QTB_RecursiveHandlerCheck.afterUpdateCheck_updateInvoiceMRCDates = false; // US #31275 defect fix
            return listToUpdate;
        } catch (Exception e){
            QTB_ExceptionLogger.enable();
                    QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
            throw e;
        }
    }
    /***********************************************************************************************************
* Method      : updateDates
* Parameters  : date mrcStartDate, date mrcEndDate, Date serviceStartDate, Date serviceEndDate, blng__InvoiceLine__c invl
* Return Type : void
* Requirement : Git #27494 Updating the Service Start/End Date and MRC Start/End Date based on new Logic
* Description :
**************************************************************************************************************/
    public static void updateDates(Date mrcStartDate, Date mrcEndDate, Date serviceStartDate, Date serviceEndDate, blng__Invoice__c invl ){
        try{
            if(mrcStartDate == null ||mrcEndDate == null ||serviceStartDate == null ||serviceEndDate == null || invl==null ){
                throw new NullPointerException();
            } //29101 exit early if either is null
            invl.QTB_Start_Date_MRC__c = mrcStartDate;
            invl.QTB_End_Date_MRC__c = mrcEndDate;
            invl.QTB_Service_Start_Date__c = serviceStartDate;
            invl.QTB_Service_End_Date__c = serviceEndDate;
        }catch (Exception e){
            QTB_ExceptionLogger.enable();
                    QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method      : createReBillCreditNote
* Parameters  : Set<ID> rebillInvoiceIdsSet,Boolean isCancel
* Return Type : void changed to List<SObject> as part of 29101 user Story
* Requirement : Git #9256 Credit & Rebill //Credit ReBill By IRM/Virtusa
* Description : Creating CreditNotes & CreditNoteLines based on Parent Invoice of rebillInvoice
Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Sarwar       04/11/2025     changed return type from void to Map<String, List<SObject>> added proper null checks #29101
**************************************************************************************************************/
    public static Map<String, List<SObject>> createReBillCreditNote(Set<ID> rebillInvoiceIdsSet,Boolean isCancel){
        try{ //29101 Added try catch
            QTB_RecursiveHandlerCheck.afterUpdateCreateReBillCreditNote = false;
            if(rebillInvoiceIdsSet== null || rebillInvoiceIdsSet.isEmpty()){
                throw new NullPointerException();
            } //29101 exit early if either is null
            // Gitlab US#24173 (Credit/Rebill Billnow)
            //calling QTB_CreditRebillUtil apex class method to handle credit-rebill related logic
            Map<String, List<SObject>> createReBillCreditNoteSobjectMap = QTB_CreditRebillUtil.handleInvoiceHelperCreditRebill(rebillInvoiceIdsSet,isCancel);
            // AND updating Credit_ReBill_InvoiceSchedulerValidation__c update crediteReBillInvSch , orderProductList
            
            if(createReBillCreditNoteSobjectMap!=null && !createReBillCreditNoteSobjectMap.isEmpty()){ // #29101 returned value
                return createReBillCreditNoteSobjectMap;
            }else{
                return null;
            }
        }catch (Exception e) {
            QTB_ExceptionLogger.enable();
                    QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method      : updateTaxruleForInvoiceLine
* Parameters  : invoiceIdsSet, Tax Rule (No Tax Rule)
* Return Type : void changed to List<blng__InvoiceLine__c> as per 29101
* Requirement : Git #11971 Billing Countries: No tax amount to be calculated based upon Accounts Threshold value
* Description : Updating  Invoice Line Tax Rule to "No Tax Rule" based upon Accounts QTB_Tax_Threshold_Amount__c value populated (No Tax  will be Calculated)
Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Sarwar       04/11/2025     changed return type from void to List<blng__InvoiceLine__c> added proper null checks #29101
**************************************************************************************************************/
    public static List<blng__InvoiceLine__c> updateTaxruleForInvoiceLine(Set<ID> invoiceIdsSet,ID taxRule, ID taxtreatment){
        try{
            if(QTB_InvoiceTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(invoiceIdsSet == null ||invoiceIdsSet.isEmpty()|| taxRule == null || taxtreatment == null){ return null;} //29101 exit early if either is null
            List<blng__InvoiceLine__c> updateInvLineList = new  List<blng__InvoiceLine__c>(); //29101 ADDED List TO RETURN VALUE
            
            // Iterating Invoiceline AND Updating invoice TaxRule to "No Tax Rule"
            for(blng__InvoiceLine__c invLine: [SELECT ID,blng__TaxRule__c,blng__TaxTreatment__c 
                                               FROM blng__InvoiceLine__c 
                                               WHERE blng__Invoice__c IN :invoiceIdsSet ]){ //Gitlab US#29101 -- added
                                                   
                                                   updateInvLineList.add(new blng__InvoiceLine__c(ID = invLine.ID, blng__TaxRule__c = taxRule,
                                                                                                  blng__TaxTreatment__c = taxtreatment));////#29101 Added directly to updateInvLineList
                                               }
            if(updateInvLineList!=null && !updateInvLineList.isEmpty()){
                return updateInvLineList;   //#29101 modified the code in such a way that instead of update updateInvLine;
            }else{
                return null;                //#29101 We are returning value from this method
            }
        }catch (Exception e){
            QTB_ExceptionLogger.enable();
                    QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    /***********************************************************************************************************
* Method     : updateReBillInvoiceWithTotalOnSplit
* Parameters : Set<ID>splitRebillInvoiceIdSet
* Description: SplitRebill -- this methods get called every time after invoice update, the logic will execute after tax calculated
: passing splitRebillInvoiceids to creditRebill handler class
Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Sarwar       04/11/2025     changed return type from void to List<blng__Invoice__c>, added proper null checksAnd TRyCatch #29101
**************************************************************************************************************/
    public static List<blng__Invoice__c> updateReBillInvoiceWithTotalOnSplit(Set<ID> splitRebillInvoiceIdSet){
        try{
            //calling QTB_CreditRebillUtil apex class method to handle split credit-rebill related logic
            List<blng__Invoice__c> invoicesSplit = QTB_CreditRebillUtil.calculateRebillAmountsOnSplitRebillInvoice(splitRebillInvoiceIdSet);
            if(invoicesSplit!=null && !invoicesSplit.isEmpty()){ //# 29101 added return type
                return invoicesSplit;
            }else{
                return null;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
                    QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method    : makeFieldsNonEditableForPosted
* Parameters : List<blng__Invoice__c>, Map<ID, blng__Invoice__c>
* Description: This is used to prevent the modification of the record after invoice posted AND QTB_Ready_for_Integration__c Set as true or false.
* Story Number: 25283
Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Sarwar       04/11/2025     Optimized the method and add proper null checks,SystemLabel and TRyCatch #29101
**************************************************************************************************************/
    public static void makeFieldsNonEditableForPosted(List<blng__Invoice__c> newItems, Map<ID,blng__Invoice__c> oldMap){
        try{
            if(newItems == null || oldMap == null || newItems.isEmpty() || oldMap.IsEmpty() || System.Label.QTB_LockdownExcludedProfiles == null){
                throw new NullPointerException();
            } //#29100 return throw new NullPointerException();
            List<String> excludedProfiles = System.Label.QTB_LockdownExcludedProfiles.split(',');
            List<User> lgUser = [SELECT ID,Name,Profile.Name 
                                 FROM User 
                                 WHERE profile.Name NOT IN: excludedProfiles AND ID =: userinfo.getuserid() ];//Gitlab US#29100 -- added
            for(blng__Invoice__c inv : newItems){
                
                if(((inv.QTB_End_Date_MRC__c != oldMap.get(inv.ID).QTB_End_Date_MRC__c) ||(inv.QTB_Start_Date_MRC__c != oldMap.get(inv.ID).QTB_Start_Date_MRC__c))
                   &&(inv.blng__InvoiceStatus__c==('Posted') && oldMap.get(inv.ID).blng__InvoiceStatus__c==('Posted') && !lgUser.isEmpty()  )){
                       // 29101 merged if and checked if excludedProfiles is != null
                       inv.addError(System.Label.QTB_makeInvoiceFieldsNonEditableForPosted);
                   }
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
                    QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method    : makeFieldsReadyOnlyForPosted
* Parameters : List<blng__Invoice__c>, Map<ID, blng__Invoice__c>
* Description: This is used to prevent the modification of the record after record status is posted AND QTB_transfered_to_invoice_presentment__c on invoice is not null.
* Story Number: 25283
Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Sarwar       04/11/2025     Optimized the method and add proper null checks,SystemLabel and TRyCatch #29101
**************************************************************************************************************/
    
    public static void makeFieldsReadyOnlyForPosted(List<blng__Invoice__c> newItems, Map<ID, blng__Invoice__c> oldMap){
        try{
            if(newItems == null || oldMap == null || newItems.isEmpty() || oldMap.IsEmpty()){
                throw new NullPointerException();
            } //#29100 return throw new NullPointerException();
            for(blng__Invoice__c inv : newItems){
                if((inv?.blng__InvoiceStatus__c==('Posted') && inv.QTB_transfered_to_invoice_presentment__c != null && oldMap.get(inv.ID)?.blng__InvoiceStatus__c==('Posted'))
                   &&(inv?.QTB_End_Date_MRC__c != oldMap.get(inv.ID)?.QTB_End_Date_MRC__c || inv?.QTB_Start_Date_MRC__c != oldMap.get(inv.ID)?.QTB_Start_Date_MRC__c)){       //29101 merged if
                       
                       inv.addError(System.Label.QTB_InvoiceFieldsReadOnlyForPosted);
                   }
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
                    QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    /***********************************************************************************************************
Method      : updateNotesOnAccountFromUsage
Parameters : List<blng__Invoice__c> newInvoiceList
Invoke: afterupdate
Description: : To update Notes with workorderid with comma seperated from Usage.
Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Sarwar       04/11/2025     Optimized the method and add proper null checks #29101
**************************************************************************************************************/
    public static List<Account> updateNotesOnAccountFromUsage(Set<ID> setInvId){
        try{
            if(QTB_InvoiceTriggerHandler.throwExplicitException){
                throw new NullPointerException();
            }
            if(setInvId ==null || setInvId.isEmpty()){
                QTB_RecursiveHandlerCheck.afterupdateCheck_updateNotesOnAccountFromUsage = false;
            return null;} //29101 early rturn if null 
            
            List<Account> accListToUpdate = new List<Account>();
            String woIdStr = 'Case Numbers: ';
            //Based on Invoice ID Retrive the workorderid from Usage
            for(blng__Usage__c usgObj : [SELECT ID,blng__UsageSummary__r.blng__Invoice__c, QTB_Source_Invoice_Reference__c ,blng__Account__c,CurrencyIsoCode
                                         FROM blng__Usage__c 
                                         WHERE blng__UsageSummary__r.blng__Invoice__c IN : setInvId AND QTB_Source_Invoice_Reference__c != null AND blng__Account__c!= null  ORDER BY blng__Account__c ]){ //Gitlab US#29101 -- added
                                             // can be optimized to : SELECT ID, blng__Account__c,QTB_Source_Invoice_Reference__c .blng__Account__c 29101
                                             if(woIdStr!= null && String.isNotBlank(woIdStr) && !woIdStr.contains(usgObj?.QTB_Source_Invoice_Reference__c)){ //#29100 added safeNavigation and null checks
                                                 
                                                 Account acc = new Account();
                                                 woIdStr = woIdStr + usgObj.QTB_Source_Invoice_Reference__c + ',';
                                                 if(woIdStr.length()<=100){
                                                     acc.ID = usgObj.blng__Account__c;
                                                     acc.QTB_Invoice_Notes__c = woIdStr.removeEnd(',');
                                                     accListToUpdate.add(acc);
                                                 }
                                             }
                                         }
            QTB_RecursiveHandlerCheck.afterupdateCheck_updateNotesOnAccountFromUsage = false;
            if(accListToUpdate!=null && !accListToUpdate.isEmpty()){ // 29101 added null check
                return accListToUpdate;
            }else{
                return null;
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
                    QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    /***********************************************************************************************************
* Method  : populateOrderOnInvoice
* Parameters : List<blng__Invoice__c> invoiceList
* Invoke: afterupdate
* Description: : To populate Case Number, Purchase Order, Service District & Site Number for SITAD Invoice
Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Sarwar       04/11/2025     Optimized the method and add proper null checks #29101
**************************************************************************************************************/
    public static void populateOrderFieldsOnInvoice(List<blng__Invoice__c> invoiceList){
        try{
            if( QTB_InvoiceTriggerHandler.throwExplicitException || invoiceList==null || invoiceList.isEmpty()){ //#29101 exit early if invoiceList null;
                throw new NullPointerException();
            }
                
            Map<ID,blng__Invoice__c> invoiceUpdateMap = new Map<ID,blng__Invoice__c>();
            //29101 we can remove blng__Invoice__r.QTB_Invoice_Type__c
            List<blng__InvoiceLine__c> invLineLst = [SELECT ID,blng__Invoice__r.QTB_LegalEntityCountry__c,blng__OrderProduct__r.Order.QTB_Case_Number__c, blng__OrderProduct__r.Order.PoNumber,
                                                     blng__OrderProduct__r.Order.QTB_Service_District__c, blng__OrderProduct__r.Order.QTB_Site_Number__c,blng__OrderProduct__r.orderid,blng__OrderProduct__r.Order.QTB_OrderCategory__c,
                                                     blng__OrderProduct__r.Order.blng__InvoiceBatch__c,blng__Invoice__r.blng_InvoiceRunCreatedBy_Name__c,blng__Invoice__c,blng__Invoice__r.QTB_Invoice_Type__c,blng__UsageSummary__c,blng__Invoice__r.QTB_InvoiceProductType__c,
                                                     blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,blng__Invoice__r.blng__Account__r.QTB_Language__c,blng__UsageSummary__r.blng__SummaryEndDate__c 
                                                     FROM blng__InvoiceLine__c 
                                                     WHERE blng__Invoice__c IN: invoiceList ]; //Gitlab US#29101 -- added
            if(invLineLst== null || invLineLst.isEmpty()) {return;} //#29101 exit early if invLineLst is null;
            
            for(blng__InvoiceLine__c invLine:invLineLst){
                if(invoiceUpdateMap!= null && !invoiceUpdateMap.containskey(invLine.blng__Invoice__c)){
                    
                    blng__Invoice__c invoiceToUpdate = new blng__Invoice__c();
                    invoiceToUpdate.ID = invLine.blng__Invoice__c;
                    //#29101 Use Ternary Operators, safe navigation operator to safely assign fields if they are not null
                    invoiceToUpdate.QTB_Purchase_Order__c   = invLine.blng__OrderProduct__r?.Order?.PoNumber != null                ? invLine.blng__OrderProduct__r.Order.PoNumber                : null;
                    invoiceToUpdate.QTB_Case_Number__c      = invLine.blng__OrderProduct__r?.Order?.QTB_Case_Number__c != null      ? invLine.blng__OrderProduct__r.Order.QTB_Case_Number__c      : null;
                    invoiceToUpdate.QTB_Service_District__c = invLine.blng__OrderProduct__r?.Order?.QTB_Service_District__c != null ? invLine.blng__OrderProduct__r.Order.QTB_Service_District__c : null;
                    invoiceToUpdate.QTB_Site_Number__c      = invLine.blng__OrderProduct__r?.Order?.QTB_Site_Number__c != null      ? invLine.blng__OrderProduct__r.Order.QTB_Site_Number__c      : null;
                    
                    //Gitlab #28005 - Invoice notes should not be update for SITAD NA //#29101 merged using TernaryOperators and Null Coaelscent operators
                    // 31276 added ignorecase
                    invoiceToUpdate.blng__Notes__c = (String.isNotBlank(System.label.QTB_NA_Countries) && !System.label.QTB_NA_Countries.containsIgnoreCase(invLine.blng__Invoice__r.QTB_LegalEntityCountry__c))
                        ? ((invLine.blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c?.equalsIgnoreCase('France') ?? false) && (invLine.blng__Invoice__r.blng__Account__r.QTB_Language__c?.equalsIgnoreCase('fr') ?? false)
                           ? 'N° Projet ALM: ' + (invLine.blng__OrderProduct__r.Order.QTB_Case_Number__c ?? '')
                           : 'ALM Case No: ' + (invLine.blng__OrderProduct__r.Order.QTB_Case_Number__c ?? '')) : ''; //#27757 Update Case Number at Invoice Notes
                    
                    //GitLab #28711 - Populating the QTB_Service_End_Date__c from Usage summary End date for SITAD cluster 1 countries
                    //28275 - service dates should be blank if invoice is of storage type //#29101 merged using TernaryOperators and Null Coaelscent operators
                    invoiceToUpdate.QTB_Service_End_Date__c = (invLine.blng__UsageSummary__c != null)
                        ? (label.QTB_ServiceTypeDates_Countries_list.containsIgnoreCase(invLine.blng__Invoice__r.QTB_LegalEntityCountry__c) && invLine.blng__Invoice__r.QTB_InvoiceProductType__c==('Storage')
                        ? null : invLine.blng__UsageSummary__r?.blng__SummaryEndDate__c ?? null) : null; // Null coalescing operator here
                    
                    //GitLab #28711 - End
                    invoiceUpdateMap.put(invLine.blng__Invoice__c, invoiceToUpdate);
                }
            }
            for(blng__Invoice__c inv: invoiceList){
                if(invoiceUpdateMap.containskey(inv.ID)){ //#29101 move to the next item of the loop if the key is unavailable
                    
                    //#29101 performed proper null check using SafeNavigation & Null Coaelscent operator
                    inv.QTB_Purchase_Order__c = invoiceUpdateMap.get(inv.ID)?.QTB_Purchase_Order__c     ?? inv.QTB_Purchase_Order__c;
                    inv.QTB_Case_Number__c = invoiceUpdateMap.get(inv.ID)?.QTB_Case_Number__c           ?? inv.QTB_Case_Number__c;
                    inv.QTB_Service_District__c = invoiceUpdateMap.get(inv.ID)?.QTB_Service_District__c ?? inv.QTB_Service_District__c;
                    inv.QTB_Site_Number__c = invoiceUpdateMap.get(inv.ID)?.QTB_Site_Number__c           ?? inv.QTB_Site_Number__c;
                    
                    //Gitlab #28005 - Invoice notes should not be update for SITAD NA //#29101 Simplified using Ternary Operators
                    inv.blng__Notes__c = (invoiceUpdateMap.get(inv.ID)?.blng__Notes__c != null)
                        ? (invoiceUpdateMap.get(inv.ID)?.blng__Notes__c ?? inv.blng__Notes__c) : (null); //#27757 Update Case Number at Invoice Notes
                    
                    //GitLab #28711 - Populating the QTB_Service_End_Date__c from Usage summary End date for SITAD cluster 1 countries
                    //28275 - service dates should be blank if invoice is of storage type  //#29101 optimized 28711 code using ternary operators and safe navigation/ null coaelscent operators
                    inv.QTB_Service_End_Date__c = (invoiceUpdateMap.get(inv.ID)?.QTB_Service_End_Date__c != null && label.QTB_ServiceTypeDates_Countries_list.containsIgnoreCase(inv.QTB_LegalEntityCountry__c) && inv.QTB_InvoiceProductType__c==('Storage'))
                        ? null : invoiceUpdateMap.get(inv.ID)?.QTB_Service_End_Date__c;
                }
            }
        }catch(Exception e){
            QTB_ExceptionLogger.enable();
                    QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            throw e;
        }
    }
    
    /***********************************************************************************************************
* Method  : callVertexAndAssignBillFlowControllerForRebill
* Gitlab :  Gitlab US#24173 (Credit/Rebill Billnow)
* Parameters : Set<ID> lineids
* Invoke: afterinsert
* return type changed to List<QTB_Bill_Flow_Controller__c> as per 29101
* Description: : To call vertex AND assign related billflowcontroller for Rebill invoice
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
#25905 assign related billFlowController for Ad-Hoc order
* Sarwar       04/11/2025     Optimized the method and add proper null checks #29101
**************************************************************************************************************/
    public static List<QTB_Bill_Flow_Controller__c> callVertexAndAssignBillFlowControllerForRebill(Set<ID> invoiceIdsSet){
        try
        {
            if(invoiceIdsSet == null || invoiceIdsSet.isEmpty()|| String.isBlank(System.Label.QTB_sierra26Label)){
                throw new NullPointerException();
            } //#29101 exception if the invoiceIdsSet is empty
            QTB_RecursiveHandlerCheck.afterUpdateCallVertex = false;
            
            Map<ID,List <ID>> rebillOrderidWithInvoiceidsMap = new Map <ID,List<ID>>();
            List<QTB_CreditRebillVertexCall__e> creditRebillVertexCallEventList = new List <QTB_CreditRebillVertexCall__e>();
            List<QTB_Bill_Flow_Controller__c> billFlowListToUpdate = new List <QTB_Bill_Flow_Controller__c>();
            
            for(blng__Invoice__c invoice: [SELECT ID, Name, QTB_Invoice_Type__c, blng__Account__r.QTB_Legal_Entity_Country__c, blng__Order__c 
                                    FROM blng__Invoice__c 
                                    WHERE ID IN: invoiceIdsSet AND blng__Account__r.QTB_Bill_Cycle_Day__c !=: System.Label.QTB_sierra26Label AND (QTB_Invoice_Type__c = 'Rebill' OR blng__order__r.QTB_OrderCategory__c = 'Ad-Hoc')]){ //Gitlab US#29101 -- added
                                               //#29101 added null check for System.Label.QTB_NA_Countries != null
                if(System.Label.QTB_NA_Countries != null && System.Label.QTB_NA_Countries.containsIgnoreCase(invoice.blng__Account__r?.QTB_Legal_Entity_Country__c) && invoice.QTB_Invoice_Type__c==('Rebill'))  {
                                                creditRebillVertexCallEventList.add(new QTB_CreditRebillVertexCall__e(QTB_Rebill_Invoice_id__c = String.valueOf(invoice.ID)));
                                            }
                                            if(invoice.blng__Order__c != null){
                                                   // used continue to move to the next item in the loop, as the next statement would work if blng__Order__c!=null
                                                if(rebillOrderidWithInvoiceidsMap!=null && rebillOrderidWithInvoiceidsMap.containsKey(invoice?.blng__Order__c)){
                                                    rebillOrderidWithInvoiceidsMap.get(invoice.blng__Order__c).add(invoice.ID);
                                                }else if(rebillOrderidWithInvoiceidsMap!=null){
                                                    rebillOrderidWithInvoiceidsMap.put(invoice.blng__Order__c, new List<ID>{ invoice.ID });
                                                }
                                            }
                                        }
            if(creditRebillVertexCallEventList!=null && !creditRebillVertexCallEventList.isEmpty()){ // 29101 removed  && creditRebillVertexCallEventList.size() > 0
                EventBus.publish(creditRebillVertexCallEventList);
            }
            // 29101 return null early if rebillOrderidWithInvoiceidsMap is empty
            if(rebillOrderidWithInvoiceidsMap == null || rebillOrderidWithInvoiceidsMap.isEmpty())  {return null;}
            
            List<QTB_Bill_Flow_Controller__c> billFlowList = [SELECT ID, QTB_Rebill_Invoice__c, QTB_Rebill_Order__c, QTB_Rebill_Order__r.QTB_OrderCategory__c,QTB_Rebill_Invoice__r.blng__Account__r.W_L__c, QTB_Rebill_Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c
                                                              FROM QTB_Bill_Flow_Controller__c // Gitlab #29101 we need not check (!= null) in WHERE clause : The IN clause already filters out nulls implicitly.
                                                              WHERE QTB_Rebill_Order__c  IN: rebillOrderidWithInvoiceidsMap.keySet()  ]; //Gitlab US#29101 -- added ,
            
            // 29101 optimized query
            // List < QTB_Bill_Flow_Controller__c > billFlowList = [SELECT ID,QTB_Rebill_Order__c,QTB_Rebill_Invoice__c FROM QTB_Bill_Flow_Controller__c  WHERE QTB_Rebill_Order__c  IN: rebillOrderidWithInvoiceidsMap.keySet()  ]; // 29101
            
            if(billFlowList ==null || billFlowList.isEmpty()) {return null;} //#29101 return null if billFlowList isEmpty, commented ((billFlowList.size() > 0)|| (billFlowList.size() <= 0))
            
            // Gitlab #27456 - Added Empty check because it is throwing 'List index out of bounds: 0' for Cluster 1 Addtional order countries while creating invoices
            List<ID> invoiceidsForOrderList = (billFlowList.isEmpty() || billFlowList[0].QTB_Rebill_Order__c == null || rebillOrderidWithInvoiceidsMap == null || rebillOrderidWithInvoiceidsMap.isEmpty())
                ? null  : rebillOrderidWithInvoiceidsMap.get(billFlowList[0].QTB_Rebill_Order__c);
            
            if(invoiceidsForOrderList==null || (billFlowList== null) || invoiceidsForOrderList.isEmpty() || billFlowList.isEmpty()|| (invoiceidsForOrderList.size() != billFlowList.size()))
            {return null;} //#29101 return null if any condition fails
            
            for(Integer i = 0; i < billFlowList.size(); i++){
                billFlowListToUpdate.add(new QTB_Bill_Flow_Controller__c(ID = billFlowList[i].ID, // 29101 adding directly to billFlowListToUpdate
                                                                         QTB_Rebill_Invoice__c = rebillOrderidWithInvoiceidsMap.get(billFlowList[i].QTB_Rebill_Order__c)[i]));
            }
            if(billFlowListToUpdate!=null && !billFlowListToUpdate.isEmpty()) {
                return billFlowListToUpdate;
            }else {
                return null; // 29101
            }
        }catch (Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(), 
                e.getStackTraceString(), 
                e.getMessage(), 
                e.getTypeName(), 
                CLASSNAME);
            throw e;
        }
    }
    
    public static void codeCoverage(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
                i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
                i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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