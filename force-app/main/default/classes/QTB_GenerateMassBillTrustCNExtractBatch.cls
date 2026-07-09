/******************************************************************************************************************
* Class: QTB_GenerateMassBillTrustCNExtractBatch
* Test Class : QTB_GenerateMassBillTrustCNExtractBatchTest
* Purpose: This Batch class containing logic for generating Billtrust XML for mass Credit Note from invoice scheduler
* Developer         Date           Description
* ----------------------------------------------------------------------------------------------------------------
* Renuka Prasad 07/09/2024     Batch class for generating Billtrust extract for mass Credit Note
*******************************************************************************************************************/
global without sharing class QTB_GenerateMassBillTrustCNExtractBatch implements Database.Batchable<sObject>, Database.Stateful
{
    String invSchID;
    String invStatus;
    Integer exceptionCount;
    Integer processedCount;
    blng__InvoiceScheduler__c invScheduler;
  String invoiceBatchs;
  String schedulerName;
  String schedulerId;
    public List<blng__Invoice__c> invoicesToUpdate;
    public List<blng__CreditNote__c> creditNotesToUpdate;
    public list<Id> invoiceIds;
    
    
    //Call Construtor
    global QTB_GenerateMassBillTrustCNExtractBatch(String invScheduleId, String invStatusToGen, String invoiceBatch)
    {
        exceptionCount = 0;
        System.debug('invScheduleId>>>'+invScheduleId);
        System.debug('invStatusToGen>>>'+invStatusToGen);
        try {
            invSchID = invScheduleId;
            invStatus = invStatusToGen;
      invoiceBatchs = invoiceBatch;
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
        String creditNoteQueryWithCondition = '';
    
    String creditNoteQuery = 'select name,QTB_Last_Credit_Note_Sent__c,QTB_Custom_Invoice_Number__c,id, '+
       ' blng__Status__c,blng__Notes__c ,blng__Account__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Subtotal__c, '+
       ' blng__Account__r.QTB_Language__c,CurrencyIsoCode,blng__Account__r.blng__BillToContact__r.Email, '+
       ' blng__Account__r.QTB_Invoice_Delivery_Options__c,blng__Account__r.QTB_Billing_Frequency__c, '+
       ' blng__Account__r.QTB_Account_Balance__c, '+
       ' blng__CreditNoteDate__c,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c,blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.blng__City__c,blng__Account__r.QTB_Contract_Entity__r.blng__State__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.QTB_IRM_Contact_Details__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.QTB_PAN_NO__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Email__c, '+
       ' blng__TaxAmount__c,blng__TotalAmount__c,blng__Account__r.QTB_Legal_Entity__r.blng__Street1__c, '+
       ' blng__Account__r.QTB_Legal_Entity__r.blng__Street2__c,blng__Account__r.QTB_Legal_Entity__r.blng__City__c, '+
       ' blng__Account__r.QTB_Legal_Entity__r.blng__State__c, '+
       ' blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Customer_Classification__c, '+
       ' blng__Account__r.QTB_Legal_Entity__r.blng__ZipPostalCode__c,blng__Account__r.BillingStreet, '+
       ' blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode, '+
       ' blng__Account__r.BillingCountry, '+
       ' blng__Account__r.QTB_Consolidation_Flag__c,blng__Account__r.QTB_HoldInd__c,blng__Account__r.QTB_HoldRequester__c, '+
       ' blng__Account__r.QTB_IMCompany__c, '+
       ' blng__Account__r.QTB_ContractNumber__c,blng__Account__r.QTB_CageCode__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_ID__c,blng__Account__r.QTB_Contract_Entity__r.QTB_DunsNumber__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentName__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactEmail__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactPN__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContact__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnPostalCode__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnState__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnCity__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress3__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress2__c, '+
       ' blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress1__c, '+
       ' blng__Account__r.QTB_Legal_Entity_Country__c, '+
       ' (Select id,QTB_Invoice__c,blng__Product__c,QTB_Credit_Quantity__c,blng__Product__r.QTB_Price_Schedule_Category__c, '+
        ' blng__InvoiceLine__r.blng__UsageSummary__r.blng__SummaryEndDate__c,QTB_Subtotal__c, '+
        ' blng__Product__r.ProductCode,blng__TotalAmount__c,blng__TaxAmount__c,Name,blng__Subtotal__c, '+
      ' blng__CreditNote__r.blng__Account__c,QTB_Invoice__r.QTB_Custom_Invoice_Number__c, '+
      ' blng__InvoiceLine__r.blng__UnitPrice__c,blng__InvoiceLine__r.Name,blng__InvoiceLine__r.blng__Product__r.Name, '+
      ' blng__InvoiceLine__r.QTB_Charge_Type__c,blng__InvoiceLine__r.QTB_Inc_Quantity__c, '+
      ' blng__InvoiceLine__r.QTB_Charged_Quantity__c, '+
      ' blng__InvoiceLine__r.blng__Invoice__r.blng__Account__r.QTB_Language__c,blng__InvoiceLine__r.QTB_Unit_Price__c, '+
      ' blng__CreditNote__r.QTB_On_Account_Credit__c,blng__Product__r.Name,QTB_Account__r.QTB_Language__c, '+
      ' blng__CreditNote__r.blng__Account__r.QTB_SITAD__c,QTB_Unit_Price__c'+
      ' from blng__CreditNoteCreditLines__r) '+
       ' from blng__CreditNote__c WHERE QTB_Last_Credit_Note_Sent__c = null '+
       ' AND blng__Status__c =:invStatus ';
    
        list<String> invoiceBatchesvalues = new list<String>();
        if (invoiceBatchs.contains(';')) {
            list<String> tempBatches = invoiceBatchs.split(';');
            invoiceBatchesvalues.addAll(tempBatches);
        } else {
            invoiceBatchesvalues.add(invoiceBatchs);
        }
        
    String credNoteCondition = '';
    if(invoiceBatchs.contains('Rebill Run')) {
      creditNoteQuery += ' AND QTB_Rebill_Invoice__r.blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c =:invSchID';   
    } else {
      creditNoteQuery += ' AND blng__Account__r.QTB_Bill_Cycle_Day__c IN :invoiceBatchesvalues';
    }
    
    creditNoteQueryWithCondition = creditNoteQueryWithCondition + creditNoteQuery;
    return Database.getQueryLocator(creditNoteQueryWithCondition); 
  }
    
    global void execute(Database.BatchableContext bc, List<blng__CreditNote__c> creditNotes) {
        try {
      list<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo> creditNoteInfo = QTB_GenerateCreditNoteXmlExtractCTRL.getCreditNoteDetails(creditNotes);
      
      //Logic to generate Billtrust extract
      if (creditNoteInfo.size() > 0) {
        QTB_BillTrustUtil.generateBilltrustRequest(creditNoteInfo, true, schedulerName, invSchID);
      }
      //Create 'QTB_Invoice_Backing_Report_Compression__c' record for creation of ZIP File
      QTB_Invoice_Backing_Report_Compression__c InvZip = new QTB_Invoice_Backing_Report_Compression__c();
      InvZip.QTB_Invoice_Scheduler__c = invSchID;
      InvZip.QTB_Status__c = 'New';
      insert InvZip;
      
      invoiceIds = new list<Id>();
      //Logic to update the Last sent date in both Invoice and Credit Notes
      for (blng__CreditNote__c crdNt: creditNotes) {
        crdNt.QTB_Last_Credit_Note_Sent__c = datetime.now();
        
        creditNotesToUpdate.add(crdNt);
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
    
    global void finish(Database.BatchableContext bc)
    {
        
    }
}