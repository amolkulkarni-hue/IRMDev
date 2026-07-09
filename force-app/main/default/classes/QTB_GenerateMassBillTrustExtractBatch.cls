/******************************************************************************************************************
* Class: QTB_GenerateMassBillTrustExtractBatch
* Test Class : QTB_GenerateMassBillTrustExtBatchTest
* Purpose: This Batch class containing logic for generating Billtrust XML for mass invoice from invoice scheduler
* Developer         Date           Description
* ----------------------------------------------------------------------------------------------------------------
* Renuka Prasad  8/1/2021      Batch class for generating Billtrust extract for mass invoice
* Renuka Prasad 02/27/2024     Changes to Sync the Backing Up Report File for SITAD from Salesforce to SMS
*******************************************************************************************************************/
global without sharing class QTB_GenerateMassBillTrustExtractBatch implements Database.Batchable<sObject>, Database.Stateful
{
    String invSchID;
    String invStatus;
    Integer exceptionCount;
    Integer processedCount;
    blng__InvoiceScheduler__c invScheduler;
    public List<blng__Invoice__c> invoicesToUpdate;
    public List<blng__CreditNote__c> creditNotesToUpdate;
    public list<Id> invoiceIds;
    
    
    //Call Construtor
    global QTB_GenerateMassBillTrustExtractBatch(String invScheduleId, String invStatusToGen)
    {
        exceptionCount = 0;
        System.debug('invScheduleId>>>'+invScheduleId);
        System.debug('invStatusToGen>>>'+invStatusToGen);
        try {
            invSchID = invScheduleId;
            invStatus = invStatusToGen;
        } catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateMassExtractBatch.Constructor');
        }
    }
    
    /*********************************************************************************************************
* Method Name: start
* Parameters: Database.BatchableContext
* Return Type: Database.QueryLocator
* Requirement: 
* Description: Start method to fetch the Invoice Scheduler details
*********************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        System.debug('invSchID>>>'+invSchID);
        String Query = 'Select id,blng__InvoiceBatches__c,blng__TargetDate__c,Name from blng__InvoiceScheduler__c where ID ='+invSchID;
        System.debug('Query>>>'+Query);
        
        return Database.getQueryLocator([
            SELECT Id, blng__InvoiceBatches__c, blng__TargetDate__c, Name
            FROM blng__InvoiceScheduler__c
            WHERE ID =:invSchID
        ]); 
    }
    
    global void execute(Database.BatchableContext bc, List<blng__InvoiceScheduler__c> invoiceSchedulers) {
        system.debug('@@invoiceSchedulers'+invoiceSchedulers);
        if(!invoiceSchedulers.isEmpty())
        {
            String invoiceBatch = '';
            list<String> InvoiceBatchesvalues = new list<String>();
            String schedulerName = '';
            String schedulerId = '';
            invoiceBatch = String.valueOf(invoiceSchedulers[0].blng__InvoiceBatches__c);
            if (invoiceBatch.contains(';')) {
                list<String> tempBatches = invoiceBatch.split(';');
                InvoiceBatchesvalues.addAll(tempBatches);
            } else {
                InvoiceBatchesvalues.add(invoiceBatch);
            }
            schedulerName = String.valueOf(invoiceSchedulers[0].Name);
            schedulerId = invoiceSchedulers[0].Id;
            invoicesToUpdate = new list<blng__Invoice__c>();
            creditNotesToUpdate = new list<blng__CreditNote__c>();
            invScheduler = invoiceSchedulers[0];
            try
            {
                //Gitlab US##23530 -- Defect fix -- for Rebill Invoices also Mass extract will run
                //added if..else condition
                List<blng__Invoice__c> invLst = new List<blng__Invoice__c>();
                if(invoiceBatch.contains('Rebill Run')){
                    //Fetch all the invoice and the invoice lines details
                    invLst = [Select id,QTB_Custom_Invoice_Number__c,Name,QTB_Last_Invoice_Sent__c,blng__InvoiceStatus__c,
                              blng__Account__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Subtotal__c,blng__Account__r.QTB_Language__c,
                              CurrencyIsoCode,blng__Account__r.blng__BillToContact__r.Email,blng__Account__r.QTB_Invoice_Delivery_Options__c,
                              blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Account_Balance__c,
                              blng__InvoiceDate__c,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,
                              blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c,blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c,
                              blng__Account__r.QTB_Contract_Entity__r.blng__City__c,blng__Account__r.QTB_Contract_Entity__r.blng__State__c,
                              blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IRM_Contact_Details__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_PAN_NO__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Email__c,
                              blng__DueDate__c,blng__TaxAmount__c,blng__TotalAmount__c,blng__Account__r.QTB_Legal_Entity__r.blng__Street1__c,
                              blng__Account__r.QTB_Legal_Entity__r.blng__Street2__c,blng__Account__r.QTB_Legal_Entity__r.blng__City__c,
                              blng__Account__r.QTB_Legal_Entity__r.blng__State__c,blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Customer_Classification__c,
                              blng__Account__r.QTB_Legal_Entity__r.blng__ZipPostalCode__c,blng__Account__r.BillingStreet,
                              blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode,blng__Account__r.BillingCountry,
                              blng__Account__r.QTB_Consolidation_Flag__c,blng__Account__r.QTB_HoldInd__c,blng__Account__r.QTB_HoldRequester__c,
                              blng__Account__r.QTB_IMCompany__c,QTB_TotalAdjustmentAmount__c,QTB_LateFee__c,blng__Account__r.QTB_ContractNumber__c,
                              blng__Account__r.QTB_CageCode__c,QTB_SiteAdjustmentTotal__c,QTB_SiteNumberTotal__c,QTB_Site_Late_Fee_Amount__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_ID__c,blng__Account__r.QTB_Contract_Entity__r.QTB_DunsNumber__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentName__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactEmail__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactPN__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContact__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnPostalCode__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnState__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnCity__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress2__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress1__c,blng__Account__r.QTB_SITAD__c, //Changes to Sync the Backing Up Report File for SITAD from Salesforce to SMS
                              QTB_SiteLateFeeAmount__c,
                              QTB_PaymentsRcvd__c,QTB_AdjustmentsRcvdAmt__c,QTB_PastDueBalanceTotal__c,QTB_CurrentTotalAmount__c, blng__InvoiceRunCreatedBy__r.Name, QTB_Purchase_Order__c, QTB_Site_Number__c,blng__Account__r.QTB_Legal_Entity_Country__c,
                              //Story Git #7673 (SLALOM)
                              (Select id,blng__UsageSummary__c,blng__Invoice__c,blng__Product__c,blng__Product__r.Name,blng__Quantity__c,blng__Product__r.QTB_Price_Schedule_Category__c,blng__Product__r.ProductCode,QTB_Charge_Type__c,QTB_Inc_Quantity__c,QTB_Charged_Quantity__c,
                               blng__TotalAmount__c,blng__TaxAmount__c,Name,blng__UsageSummary__r.blng__SummaryEndDate__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,blng__Invoice__r.QTB_Custom_Invoice_Number__c,
                               blng__Invoice__r.blng__Account__r.QTB_Language__c,QTB_Unit_Price__c,blng__Invoice__r.blng__Account__r.QTB_SITAD__c //Gitlab US#22996 -- field added
                               from blng__InvoiceInvoiceLines__r)
                              from blng__Invoice__c WHERE QTB_Last_Invoice_Sent__c = null AND blng__InvoiceStatus__c =:invStatus
                              and blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c =:schedulerId
                              limit 50000];
                }
                else{
                    //Fetch all the invoice and the invoice lines details
                    invLst = [Select id,QTB_Custom_Invoice_Number__c,Name,QTB_Last_Invoice_Sent__c,blng__InvoiceStatus__c,
                              blng__Account__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Subtotal__c,blng__Account__r.QTB_Language__c,
                              CurrencyIsoCode,blng__Account__r.blng__BillToContact__r.Email,blng__Account__r.QTB_Invoice_Delivery_Options__c,
                              blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Account_Balance__c,
                              blng__InvoiceDate__c,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,
                              blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c,blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c,
                              blng__Account__r.QTB_Contract_Entity__r.blng__City__c,blng__Account__r.QTB_Contract_Entity__r.blng__State__c,
                              blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IRM_Contact_Details__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_PAN_NO__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Email__c,
                              blng__DueDate__c,blng__TaxAmount__c,blng__TotalAmount__c,blng__Account__r.QTB_Legal_Entity__r.blng__Street1__c,
                              blng__Account__r.QTB_Legal_Entity__r.blng__Street2__c,blng__Account__r.QTB_Legal_Entity__r.blng__City__c,
                              blng__Account__r.QTB_Legal_Entity__r.blng__State__c,blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Customer_Classification__c,
                              blng__Account__r.QTB_Legal_Entity__r.blng__ZipPostalCode__c,blng__Account__r.BillingStreet,
                              blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode,blng__Account__r.BillingCountry,
                              blng__Account__r.QTB_Consolidation_Flag__c,blng__Account__r.QTB_HoldInd__c,blng__Account__r.QTB_HoldRequester__c,
                              blng__Account__r.QTB_IMCompany__c,QTB_TotalAdjustmentAmount__c,QTB_LateFee__c,blng__Account__r.QTB_ContractNumber__c,
                              blng__Account__r.QTB_CageCode__c,QTB_SiteAdjustmentTotal__c,QTB_SiteNumberTotal__c,QTB_Site_Late_Fee_Amount__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_ID__c,blng__Account__r.QTB_Contract_Entity__r.QTB_DunsNumber__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentName__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactEmail__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactPN__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContact__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnPostalCode__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnState__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnCity__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress2__c,
                              blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress1__c,blng__Account__r.QTB_SITAD__c, //Changes to Sync the Backing Up Report File for SITAD from Salesforce to SMS
                              QTB_SiteLateFeeAmount__c,
                              QTB_PaymentsRcvd__c,QTB_AdjustmentsRcvdAmt__c,QTB_PastDueBalanceTotal__c,QTB_CurrentTotalAmount__c, blng__InvoiceRunCreatedBy__r.Name, QTB_Purchase_Order__c, QTB_Site_Number__c,blng__Account__r.QTB_Legal_Entity_Country__c,
                              //Story Git #7673 (SLALOM)
                              (Select id,blng__UsageSummary__c,blng__Invoice__c,blng__Product__c,blng__Product__r.Name,blng__Quantity__c,blng__Product__r.QTB_Price_Schedule_Category__c,blng__Product__r.ProductCode,QTB_Charge_Type__c,QTB_Inc_Quantity__c,QTB_Charged_Quantity__c,
                               blng__TotalAmount__c,blng__TaxAmount__c,Name,blng__UsageSummary__r.blng__SummaryEndDate__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,blng__Invoice__r.QTB_Custom_Invoice_Number__c,
                               blng__Invoice__r.blng__Account__r.QTB_Language__c,QTB_Unit_Price__c,blng__Invoice__r.blng__Account__r.QTB_SITAD__c //Gitlab US#22996 -- field added
                               from blng__InvoiceInvoiceLines__r)
                              from blng__Invoice__c WHERE QTB_Last_Invoice_Sent__c = null AND blng__InvoiceStatus__c =:invStatus
                              AND blng__Account__r.QTB_Bill_Cycle_Day__c IN :InvoiceBatchesvalues limit 50000];
                }
                list<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo> invCredInfo = new list<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo>();
                
                list<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo> invoiceInfo = QTB_GenerateBillTrustExtractCTRL.getInvoiceDetails(invLst);
                if (invLst.size() > 0) {
                    invCredInfo.addAll(invoiceInfo);
                }
                List<blng__CreditNote__c> creditNotes = new List<blng__CreditNote__c>();
                //Gitlab US##23530 -- Defect fix -- for Rebill Invoices & for its related Credit Note also Mass extract will run
                //added if..else condition
                if(invoiceBatch.contains('Rebill Run')){
                    creditNotes = [select name,QTB_Last_Credit_Note_Sent__c,QTB_Custom_Invoice_Number__c,id,
                                   blng__Status__c,blng__Notes__c ,blng__Account__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Subtotal__c,
                                   blng__Account__r.QTB_Language__c,CurrencyIsoCode,blng__Account__r.blng__BillToContact__r.Email,
                                   blng__Account__r.QTB_Invoice_Delivery_Options__c,blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Account_Balance__c,
                                   blng__CreditNoteDate__c,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,
                                   blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c,blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c,
                                   blng__Account__r.QTB_Contract_Entity__r.blng__City__c,blng__Account__r.QTB_Contract_Entity__r.blng__State__c,
                                   blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IRM_Contact_Details__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_PAN_NO__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Email__c,
                                   blng__TaxAmount__c,blng__TotalAmount__c,blng__Account__r.QTB_Legal_Entity__r.blng__Street1__c,
                                   blng__Account__r.QTB_Legal_Entity__r.blng__Street2__c,blng__Account__r.QTB_Legal_Entity__r.blng__City__c,
                                   blng__Account__r.QTB_Legal_Entity__r.blng__State__c,blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Customer_Classification__c,
                                   blng__Account__r.QTB_Legal_Entity__r.blng__ZipPostalCode__c,blng__Account__r.BillingStreet,
                                   blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode,blng__Account__r.BillingCountry,
                                   blng__Account__r.QTB_Consolidation_Flag__c,blng__Account__r.QTB_HoldInd__c,blng__Account__r.QTB_HoldRequester__c,
                                   blng__Account__r.QTB_IMCompany__c,
                                   //QTB_Late_Fee_Amount__c,QTB_SiteAdjustmentTotal__c,QTB_LateFee__c,QTB_SiteNumberTotal__c,QTB_PaymentsRcvd__c,QTB_AdjustmentsRcvdAmt__c,
                                   //QTB_PastDueBalanceTotal__c,QTB_CurrentTotalAmount__c,QTB_TotalAdjustmentAmount__c,
                                   blng__Account__r.QTB_ContractNumber__c,blng__Account__r.QTB_CageCode__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_ID__c,blng__Account__r.QTB_Contract_Entity__r.QTB_DunsNumber__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentName__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactEmail__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactPN__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContact__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnPostalCode__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnState__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnCity__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress2__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress1__c,
                                   blng__Account__r.QTB_Legal_Entity_Country__c,/*QTB_Subtotal_WithNegative__c, Gitlab-22532*/QTB_Total_Amount_with_Tax_Override__c,//Changes for Story #22175
                                   (Select id,QTB_Invoice__c,blng__Product__c,QTB_Credit_Quantity__c,blng__Product__r.QTB_Price_Schedule_Category__c,
                                    //blng__UsageSummary__c,blng__Invoice__c,blng__UsageSummary__r.blng__SummaryEndDate__c,blng__UnitPrice__c,blng__ChargeType__c,
                                    //QTB_HasConsumptionSchedule__c,
                                    blng__InvoiceLine__r.blng__UsageSummary__r.blng__SummaryEndDate__c,QTB_Subtotal__c,/*QTB_Subtotal_WithNegative__c, Gitlab-22532*/ //Changes for Story #22175
                                    blng__Product__r.ProductCode,blng__TotalAmount__c,blng__TaxAmount__c,Name,blng__Subtotal__c,
                                    blng__CreditNote__r.blng__Account__c,QTB_Invoice__r.QTB_Custom_Invoice_Number__c,
                                    blng__InvoiceLine__r.blng__UnitPrice__c,blng__InvoiceLine__r.Name,blng__InvoiceLine__r.blng__Product__r.Name,
                                    blng__InvoiceLine__r.QTB_Charge_Type__c,blng__InvoiceLine__r.QTB_Inc_Quantity__c,blng__InvoiceLine__r.QTB_Charged_Quantity__c,
                                    blng__InvoiceLine__r.blng__Invoice__r.blng__Account__r.QTB_Language__c,blng__InvoiceLine__r.QTB_Unit_Price__c,
                                    blng__CreditNote__r.QTB_On_Account_Credit__c,blng__Product__r.Name,QTB_Account__r.QTB_Language__c //Gitlab US #21579 - Product defect Fix - added fields
                                    ,blng__CreditNote__r.blng__Account__r.QTB_SITAD__c//Gitlab US#22996 
                                    from blng__CreditNoteCreditLines__r)
                                   from blng__CreditNote__c WHERE QTB_Last_Credit_Note_Sent__c = null 
                                   AND blng__Status__c =:invStatus 
                                   AND QTB_Rebill_Invoice__r.blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c =:schedulerId limit 50000];
                }
                else{
                    creditNotes = [select name,QTB_Last_Credit_Note_Sent__c,QTB_Custom_Invoice_Number__c,id,
                                   blng__Status__c,blng__Notes__c ,blng__Account__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Subtotal__c,
                                   blng__Account__r.QTB_Language__c,CurrencyIsoCode,blng__Account__r.blng__BillToContact__r.Email,
                                   blng__Account__r.QTB_Invoice_Delivery_Options__c,blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Account_Balance__c,
                                   blng__CreditNoteDate__c,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,
                                   blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c,blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c,
                                   blng__Account__r.QTB_Contract_Entity__r.blng__City__c,blng__Account__r.QTB_Contract_Entity__r.blng__State__c,
                                   blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IRM_Contact_Details__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_PAN_NO__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Email__c,
                                   blng__TaxAmount__c,blng__TotalAmount__c,blng__Account__r.QTB_Legal_Entity__r.blng__Street1__c,
                                   blng__Account__r.QTB_Legal_Entity__r.blng__Street2__c,blng__Account__r.QTB_Legal_Entity__r.blng__City__c,
                                   blng__Account__r.QTB_Legal_Entity__r.blng__State__c,blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Customer_Classification__c,
                                   blng__Account__r.QTB_Legal_Entity__r.blng__ZipPostalCode__c,blng__Account__r.BillingStreet,
                                   blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode,blng__Account__r.BillingCountry,
                                   blng__Account__r.QTB_Consolidation_Flag__c,blng__Account__r.QTB_HoldInd__c,blng__Account__r.QTB_HoldRequester__c,
                                   blng__Account__r.QTB_IMCompany__c,
                                   //QTB_Late_Fee_Amount__c,QTB_SiteAdjustmentTotal__c,QTB_LateFee__c,QTB_SiteNumberTotal__c,QTB_PaymentsRcvd__c,QTB_AdjustmentsRcvdAmt__c,
                                   //QTB_PastDueBalanceTotal__c,QTB_CurrentTotalAmount__c,QTB_TotalAdjustmentAmount__c,
                                   blng__Account__r.QTB_ContractNumber__c,blng__Account__r.QTB_CageCode__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_ID__c,blng__Account__r.QTB_Contract_Entity__r.QTB_DunsNumber__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentName__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactEmail__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactPN__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContact__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnPostalCode__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnState__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnCity__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress2__c,
                                   blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress1__c,
                                   blng__Account__r.QTB_Legal_Entity_Country__c,/*QTB_Subtotal_WithNegative__c, Gitlab-22532*/QTB_Total_Amount_with_Tax_Override__c,//Changes for Story #22175
                                   (Select id,QTB_Invoice__c,blng__Product__c,QTB_Credit_Quantity__c,blng__Product__r.QTB_Price_Schedule_Category__c,
                                    //blng__UsageSummary__c,blng__Invoice__c,blng__UsageSummary__r.blng__SummaryEndDate__c,blng__UnitPrice__c,blng__ChargeType__c,
                                    //QTB_HasConsumptionSchedule__c,
                                    blng__InvoiceLine__r.blng__UsageSummary__r.blng__SummaryEndDate__c,QTB_Subtotal__c,/*QTB_Subtotal_WithNegative__c, Gitlab-22532*/ //Changes for Story #22175
                                    blng__Product__r.ProductCode,blng__TotalAmount__c,blng__TaxAmount__c,Name,blng__Subtotal__c,
                                    blng__CreditNote__r.blng__Account__c,QTB_Invoice__r.QTB_Custom_Invoice_Number__c,
                                    blng__InvoiceLine__r.blng__UnitPrice__c,blng__InvoiceLine__r.Name,blng__InvoiceLine__r.blng__Product__r.Name,
                                    blng__InvoiceLine__r.QTB_Charge_Type__c,blng__InvoiceLine__r.QTB_Inc_Quantity__c,blng__InvoiceLine__r.QTB_Charged_Quantity__c,
                                    blng__InvoiceLine__r.blng__Invoice__r.blng__Account__r.QTB_Language__c,blng__InvoiceLine__r.QTB_Unit_Price__c,
                                    blng__CreditNote__r.QTB_On_Account_Credit__c,blng__Product__r.Name,QTB_Account__r.QTB_Language__c //Gitlab US #21579 - Product defect Fix - added fields
                                    ,blng__CreditNote__r.blng__Account__r.QTB_SITAD__c//Gitlab US#22996 
                                    from blng__CreditNoteCreditLines__r)
                                   from blng__CreditNote__c WHERE QTB_Last_Credit_Note_Sent__c = null 
                                   AND blng__Status__c =:invStatus 
                                   AND blng__Account__r.QTB_Bill_Cycle_Day__c IN :InvoiceBatchesvalues limit 50000];
                }
                
                
                list<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo> creditNoteInfo = QTB_GenerateCreditNoteXmlExtractCTRL.getCreditNoteDetails(creditNotes);
                if (creditNoteInfo.size() > 0) {
                    invCredInfo.addAll(creditNoteInfo);
                }
                
                //Logic to generate Billtrust extract
                if (invCredInfo.size() > 0) {
                    QTB_BillTrustUtil.generateBilltrustRequest(invCredInfo, true, schedulerName, schedulerId);
                }
                //Create 'QTB_Invoice_Backing_Report_Compression__c' record for creation of ZIP File
                QTB_Invoice_Backing_Report_Compression__c InvZip = new QTB_Invoice_Backing_Report_Compression__c();
                InvZip.QTB_Invoice_Scheduler__c = invSchID;
                InvZip.QTB_Status__c = 'New';
                insert InvZip;
                
                invoiceIds = new list<Id>();
                //Logic to update the Last sent date in both Invoice and Credit Notes
                if (invStatus == QTB_Constants.INVOICE_STATUS_POSTED) {
                    for (blng__Invoice__c inv: invLst) {
                        inv.QTB_Last_Invoice_Sent__c = datetime.now();
                        
                        invoicesToUpdate.add(inv);
                        invoiceIds.add(inv.id);
                        //QTB_BillTrustUtil.generateCSV(inv, InvZip.Id);
                    }
                    
                    for (blng__CreditNote__c crdNt: creditNotes) {
                        crdNt.QTB_Last_Credit_Note_Sent__c = datetime.now();
                        
                        creditNotesToUpdate.add(crdNt);
                    }
                    
                }
                
                if (invStatus != QTB_Constants.INVOICE_STATUS_POSTED) {
                    for (blng__Invoice__c inv: invLst) {
                        invoiceIds.add(inv.id);
                    }
                }
                
                if (invoicesToUpdate.size() > 0) {
                    update invoicesToUpdate;
                }
                
                if (creditNotesToUpdate.size() > 0) {
                    update creditNotesToUpdate;
                }
                
            } catch(Exception e) {
                ++exceptionCount;
                //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
                QTB_ExceptionLogger.enable();
                QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateMassExtractBatch.execute');
            }
        }
    }
    
    global void finish(Database.BatchableContext bc)
    {
        try
        {
            //Calling QTB_GenerateMassInvBckngRprtBatch for generating the backing report
            QTB_Invoice_Backing_Report_Compression__c InvZip = new QTB_Invoice_Backing_Report_Compression__c();
            InvZip.QTB_Invoice_Scheduler__c = (invSchID != null) ? ID.ValueOf(invSchID): null;
            InvZip.QTB_Status__c = 'New';
            insert InvZip;
            
            QTB_GenerateMassInvBckngRprtBatch massCsv = new QTB_GenerateMassInvBckngRprtBatch(invScheduler,InvZip,invStatus,invoiceIds);
            Database.executeBatch(massCsv, Integer.ValueOf(label.QTB_APIX_Mass_CSV_File_Batch_Size));
            
        } catch(Exception e) {
            ++exceptionCount;
            //Throw exception and create 'QTB_Exception_Log__c' record by using Platform Event
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateMassExtractBatch.finish');
        }
    }
}