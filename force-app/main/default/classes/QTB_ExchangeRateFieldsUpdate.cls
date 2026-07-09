/*****************************************************************************************************
* Class:   QTB_ExchangeRateFieldsUpdate
* Test Class: QTB_ExchangeRateFieldsUpdate_Test
* Author: Virtusa
* Purpose: This is a Batch class to update fields of invoice, invoice line, usage and usage summary based on foreign exchange rate during post bill
* Requirement: 
* Change History: 
* Developer     Date(dd/mm/yy)       Description
* -------------------------------------------------------------------------------------------
* Virtusa       17/12/2024			update fields of invoice, invoice line, usage and usage summary based on exchange rate
*******************************************************************************************************/
public class QTB_ExchangeRateFieldsUpdate implements Database.Batchable<SObject> {
    // Variable to get Class Name
    public static final string className = QTB_ExchangeRateFieldsUpdate.class.getName();
    // Boolean to control exception
    public static boolean throwExplicitException = false;
    // String variable to store Invoice Query
    public String query;
    //Set to store Invoice scheduler Ids
    public Set<Id> invSchedulerIdSet = new Set<Id>();
    // string to store legal entity country
    public static string invCountry ='';
    //Set to store AdHoc order Id or rebill order Id
    public set<Id> rebillAdHocInvoiceIds = new Set<Id>();
    public static final String DraftStatus = QTB_Constants.INVOICE_STATUS_DRAFT;
    //Map to store bill flow controller Id and invoice batch
    public Map<Id,string> postBillRecordWithInvoiceBatch = new Map<Id,string>();
    
    /*********************************************************************************************************
Method Name: runPostBillExchangeRateBatch
Parameters: List<QTB_PostBillFlowController.flowInputs>request
Return Type: void
Requirement: Gitlab #28211
Description: this method will execute the QTB_ExchangeRateFieldsUpdate batch class
**********************************************************************************************************/
    public static void runPostBillExchangeRateBatch(List<QTB_PostBillFlowController.flowInputs>request){
        Integer batchSize = Integer.ValueOf(System.Label.QTB_ExchangeRatePostbillBatch_Size);
        QTB_ExchangeRateFieldsUpdate bat = new QTB_ExchangeRateFieldsUpdate(request);
        database.executeBatch(bat,batchSize);
    }
    /*********************************************************************************************************
Method Name: QTB_ExchangeRateFieldsUpdate
Parameters: List<QTB_PostBillFlowController.flowInputs>request
Return Type: void
Requirement: Gitlab #28211
Description: constructor of batch class
**********************************************************************************************************/
    // Constructor to to get Invoice run ids
    public QTB_ExchangeRateFieldsUpdate(List<QTB_PostBillFlowController.flowInputs>request){
        for(QTB_PostBillFlowController.FlowInputs flow:request)
        {
            //Storing billFlowRecordId and invoiceBatch in map.
            postBillRecordWithInvoiceBatch.put(flow.postbillBatchRunRecordId, flow.invoiceBatches);
            System.debug('postbillBatchRunRecordId-->'+flow.postbillBatchRunRecordId);
        }
        for(QTB_Bill_Flow_Controller__c bill : [Select Id, Name,Invoice_Scheduler__c, QTB_Rebill_Invoice__c From QTB_Bill_Flow_Controller__c
                                                where Id IN: postBillRecordWithInvoiceBatch.keySet()])
        {
            if(bill.Invoice_Scheduler__c != null){
                invSchedulerIdSet.add(bill.Invoice_Scheduler__c);
            }
            else if(bill.QTB_Rebill_Invoice__c != null){
                rebillAdHocInvoiceIds.add(bill.QTB_Rebill_Invoice__c);
            }
        }
        if(invSchedulerIdSet != null){
            // Invoice Query based on invoice scheduler
            query = 'SELECT Id,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Legal_Entity_Country__c,blng__Account__r.QTB_Contract_Currency__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c, CurrencyIsoCode from blng__Invoice__c '+ 
                'where blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c IN :invSchedulerIdSet and blng__InvoiceStatus__c  =:DraftStatus and blng__Account__r.QTB_Contract_Entity__r.QTB_Contract_Currency_Applicable__c = true and blng__Account__r.QTB_isContractRateApplicable__c = true and blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c != null';
        }
        else If(rebillAdHocInvoiceIds != null){
            // Invoice Query for rebill or adHoc
            query = 'SELECT Id,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Legal_Entity_Country__c,blng__Account__r.QTB_Contract_Currency__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c, CurrencyIsoCode '+
                'from blng__Invoice__c where Id IN :rebillAdHocInvoiceIds and blng__InvoiceStatus__c  =:DraftStatus and blng__Account__r.QTB_Contract_Entity__r.QTB_Contract_Currency_Applicable__c = true and blng__Account__r.QTB_isContractRateApplicable__c = true and blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c != null';
        }
        system.debug('QTB_ExchangeRateFieldsUpdate constructor --->'+ query);
    }
    
    /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Return Type: Database.QueryLocator
Description: Query Draft invoice records in context
**********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('In start method');
        return Database.getQueryLocator(query);
    }
    
    
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext,List<blng__Invoice__c>
Return Type: void
Requirement: 
Description: this method will update the fields of inv, invLine, usage and usageSummary based on currenct date of foreign exchange reocrd 
**********************************************************************************************************/
    public void execute(Database.BatchableContext BC, List<blng__invoice__c> scope){
        String errorIds = '';
        try {
            System.debug('In execute method of QTB_ExchangeRateFieldsUpdate batch  try block');
            if (throwExplicitException) {
                System.debug('NullPointer');
                throw new NullPointerException();
            }
            // Set to store Account contract Currencies
            Set<String> contractCurrencies = new Set<String>();
            // Set to store Invoice Currencies
            Set<String> invoiceCurrencies = new Set<String>();
            // Set to store legal Entity Rate Types
            Set<String> legalEntityRateTypes = new Set<String>();
            // List to store Invoice records to be update
            List<blng__Invoice__c>invoiceToUpdate = new List<blng__Invoice__c>();
            
            for(blng__invoice__c inv :scope){
                invCountry = inv.blng__Account__r.QTB_Legal_Entity_Country__c;
                invoiceToUpdate.add(inv);
                contractCurrencies.add(inv.blng__Account__r.QTB_Contract_Currency__c);
                invoiceCurrencies.add(inv.CurrencyIsoCode);
                legalEntityRateTypes.add(inv.blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c);
            }
            if(!invoiceToUpdate.isEmpty()){
                List<blng__InvoiceLine__c>invoiceLineToupdate = [Select Id,blng__TotalAmount__c,blng__Quantity__c,blng__Invoice__c,blng__UnitPrice__c,blng__Subtotal__c,blng__TaxAmount__c,QTB_Taxable_Amount__c,
                                                                 QTB_Tax_Override_Amount__c,blng__UsageSummary__c,blng__UsageSummary__r.blng__AppliedUnitPrice__c,blng__UsageSummary__r.blng__TotalQuantity__c,
                                                                 blng__UsageSummary__r.blng__PreratedAmount__c,blng__UsageSummary__r.QTB_TaxAmount__c,blng__UsageSummary__r.blng__Subtotal__c,blng__UsageSummary__r.QTB_Contracted_Currency_Rate__c,
                                                                 blng__UsageSummary__r.blng__UnitPrice__c from blng__InvoiceLine__c where blng__Invoice__c in :invoiceToUpdate];
                
                //to store invoice Id and rate that is used to update field last time
                Map<Id,decimal>InvIdAndOldExchangeRate = new Map<Id,decimal>();
                if(!invoiceLineToupdate.isEmpty()){
                    for(blng__InvoiceLine__c invLn :invoiceLineToupdate){
                        if(!InvIdAndOldExchangeRate.containsKey(invLn.blng__Invoice__c) && invLn.blng__UsageSummary__r.QTB_Contracted_Currency_Rate__c != null){
                            InvIdAndOldExchangeRate.put(invLn.blng__Invoice__c,invLn.blng__UsageSummary__r.QTB_Contracted_Currency_Rate__c);
                        }
                    }
                }
                
                //Fetching foreign exchange records
                if(!contractCurrencies.isEmpty() && !invoiceCurrencies.isEmpty() && !legalEntityRateTypes.isEmpty()){
                    // Variable to store current date
                    date currentdate = system.today(); 
                    // List to store Foreign Exchange
                    List<QTB_Foreign_Exchange__c> feList = [select id,QTB_Rate__c,QTB_Currency_From__c,QTB_Currency_To__c,QTB_Start_Date__c,QTB_End_Date__c,QTB_Tax_Rate_Type__c
                                                            from QTB_Foreign_Exchange__c where QTB_Currency_From__c IN :contractCurrencies and QTB_Currency_To__c IN :invoiceCurrencies 
                                                            and QTB_Tax_Rate_Type__c IN :legalEntityRateTypes and QTB_Start_Date__c <= :currentdate and QTB_End_Date__c >= :currentdate];
                    // Clearing list
                    contractCurrencies.clear();
                    invoiceCurrencies.clear();
                    legalEntityRateTypes.clear();
                    
                    // List to update Usage Summary
                    List<blng__UsageSummary__c>usToUpdate = new List<blng__UsageSummary__c>();
                    // List to update Usage records
                    List<blng__Usage__c> usageToUpdate = new List<blng__Usage__c>();
                    // Map to store Invoice Id and Rate
                    Map<Id,decimal>InvoiceExchangeRateMap = new Map<Id,decimal>();
                    // Map to store Usage summary Id and Rate
                    Map<Id,decimal> usgSmryAndExcngRate = new Map<Id,decimal>();
                    if(!feList.isEmpty()){
                        for(blng__invoice__c inv :invoiceToUpdate){
                            for(QTB_Foreign_Exchange__c fe :feList){
                                // Check for Account Contract Currency equals to Foreign Exchange ISO Currency and Rate Type and account Contract entity equals to Foreign Exchange Rate Type
                                if(inv.blng__Account__r.QTB_Contract_Currency__c ==fe.QTB_Currency_From__c && inv.currencyIsoCode == fe.QTB_Currency_To__c && 
                                   inv.blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c == fe.QTB_Tax_Rate_Type__c && inv.QTB_Tax_Override_Amount__c != null && 
                                   InvIdAndOldExchangeRate.containsKey(inv.Id) && InvIdAndOldExchangeRate.get(inv.Id) != fe.QTB_Rate__c && InvIdAndOldExchangeRate.get(inv.Id) != 0) //updating only if exchange rate is changed
                                {
                                    InvoiceExchangeRateMap.put(inv.Id,fe.QTB_Rate__c);
                                    inv.QTB_Tax_Override_Amount__c = (inv.QTB_Tax_Override_Amount__c/InvIdAndOldExchangeRate.get(inv.Id)) *fe.QTB_Rate__c;
                                    inv.QTB_Contracted_Currency_Rate__c = fe.QTB_Rate__c;
                                    break;
                                }
                            }
                        }
                        
                        for(blng__InvoiceLine__c invL :invoiceLineToupdate){
                            // check if map contains Invoice Ids to update only that invoice lines and usage summary where exchange rate is changed
                            if(InvoiceExchangeRateMap.containsKey(invL.blng__Invoice__c) && InvIdAndOldExchangeRate.containsKey(invL.blng__Invoice__c) && InvIdAndOldExchangeRate.get(invL.blng__Invoice__c) != 0 ){
                                // Calculate below fields based on new Exchange Rate value
                                invL.blng__Subtotal__c = invL.blng__Subtotal__c != null ? (invL.blng__Subtotal__c/InvIdAndOldExchangeRate.get(invL.blng__Invoice__c))*InvoiceExchangeRateMap.get(invL.blng__Invoice__c) : null;
                                invL.blng__TaxAmount__c = invL.blng__TaxAmount__c != null ? (invL.blng__TaxAmount__c/InvIdAndOldExchangeRate.get(invL.blng__Invoice__c))*InvoiceExchangeRateMap.get(invL.blng__Invoice__c) : null;
                                if(invL.blng__Subtotal__c != null  || invL.blng__TaxAmount__c != null){
                                    if(invL.blng__Subtotal__c != null  && invL.blng__TaxAmount__c != null){
                                        invL.blng__TotalAmount__c = invL.blng__Subtotal__c + invL.blng__TaxAmount__c;
                                    }
                                    if(invL.blng__Subtotal__c == null){
                                        invL.blng__TotalAmount__c = invL.blng__TaxAmount__c;
                                    }
                                    if(invL.blng__TaxAmount__c == null){
                                        invL.blng__TotalAmount__c = invL.blng__Subtotal__c;
                                    }
                                }
                                // for flat rate, at invoice line level tax override amount is null
                                if(invL.QTB_Tax_Override_Amount__c != null){
                                    invL.QTB_Tax_Override_Amount__c = (invL.QTB_Tax_Override_Amount__c/InvIdAndOldExchangeRate.get(invL.blng__Invoice__c))*InvoiceExchangeRateMap.get(invL.blng__Invoice__c);
                                }
                                //invL.QTB_Taxable_Amount__c = invL.QTB_Taxable_Amount__c*InvoiceExchangeRateMap.get(invL.blng__Invoice__c);
                                invL.blng__UnitPrice__c = invL.blng__Quantity__c != null && invL.blng__Quantity__c != 0 ? invL.blng__Subtotal__c/invL.blng__Quantity__c : invL.blng__UnitPrice__c;
                                
                                // Variable to store Pre Rated amount of usage summary
                                decimal preRatedAmount = invL.blng__UsageSummary__r.blng__PreratedAmount__c != null ? (invL.blng__UsageSummary__r.blng__PreratedAmount__c/InvIdAndOldExchangeRate.get(invL.blng__Invoice__c))*InvoiceExchangeRateMap.get(invL.blng__Invoice__c) : null;
                                blng__UsageSummary__c us = 
                                    new blng__UsageSummary__c(
                                        Id = InvL.blng__UsageSummary__c,
                                        blng__PreratedAmount__c = preRatedAmount != null ? preRatedAmount : null,
                                        //QTB_TaxAmount__c = invL.blng__UsageSummary__r.QTB_TaxAmount__c*InvoiceExchangeRateMap.get(invL.blng__Invoice__c),
                                        blng__Subtotal__c = invL.blng__UsageSummary__r.blng__Subtotal__c != null ? (invL.blng__UsageSummary__r.blng__Subtotal__c/InvIdAndOldExchangeRate.get(invL.blng__Invoice__c))*InvoiceExchangeRateMap.get(invL.blng__Invoice__c) : null,
                                        blng__UnitPrice__c = preRatedAmount != null && invL.blng__UsageSummary__r.blng__TotalQuantity__c != null && invL.blng__UsageSummary__r.blng__TotalQuantity__c != 0 ? preRatedAmount/invL.blng__UsageSummary__r.blng__TotalQuantity__c : null,
                                        blng__AppliedUnitPrice__c = preRatedAmount != null && invL.blng__UsageSummary__r.blng__TotalQuantity__c != null && invL.blng__UsageSummary__r.blng__TotalQuantity__c != 0 ? preRatedAmount/invL.blng__UsageSummary__r.blng__TotalQuantity__c : null,
                                        QTB_Contracted_Currency_Rate__c = InvoiceExchangeRateMap.get(invL.blng__Invoice__c)
                                    );
                                // Map to store usage summary Id and Rate value
                                usgSmryAndExcngRate.put(InvL.blng__UsageSummary__c,InvoiceExchangeRateMap.get(invL.blng__Invoice__c));
                                // List to store updated Usage Summary
                                usToUpdate.add(us);
                                
                            }
                        }
                        InvoiceExchangeRateMap.clear();
                        if(!usToUpdate.IsEmpty()){
                            // fetching usage records based on usage summary id
                            for(blng__Usage__c usg : [select id, QTB_Contracted_Currency_Amount__c, blng__UsageSummary__c,blng__PreratedQuantity__c,blng__PreratedAmount__c,QTB_Prerated_Unit_Price__c,blng__Quantity__c,
                                                      blng__Subtotal__c,QTB_TaxAmount__c,blng__UnitPrice__c from blng__Usage__c where 
                                                      blng__UsageSummary__c in :usToUpdate and QTB_Contracted_Currency_Amount__c != null])
                            {
                                // Condition to cehck if map contains usage summary id
                                if(usgSmryAndExcngRate.containsKey(usg.blng__UsageSummary__c)){
                                    blng__Usage__c usage = new blng__Usage__c();
                                    usage.id = usg.id;
                                    // Variable to store new Pre Rated Amount
                                    decimal exchangeRateprice = usg.QTB_Contracted_Currency_Amount__c*usgSmryAndExcngRate.get(usg.blng__UsageSummary__c);                            
                                    usage.blng__PreratedAmount__c = exchangeRateprice;
                                    usage.QTB_Prerated_Unit_Price__c = usg.blng__PreratedQuantity__c != null && usg.blng__PreratedQuantity__c != 0 ? exchangeRateprice / usg.blng__PreratedQuantity__c : usg.QTB_Prerated_Unit_Price__c;
                                    // List to store Usage to update
                                    usageToUpdate.add(usage);
                                }
                                
                            }
                        }
                    }
                    // To Update Invoice, Invoice Line, Usage Summary and Usage based on new Rate
                    if(!invoiceToUpdate.isEmpty() && !invoiceLineToupdate.isEmpty() && !usToUpdate.isEmpty() && !usageToUpdate.isEmpty()){                
                        sbqq.TriggerControl.disable();
                        update usageToUpdate;
                        update usToUpdate;
                        update invoiceLineToupdate;
                        update invoiceToUpdate;
                        sbqq.TriggerControl.enable();
                    }
                    // Clearing memory
                    usageToUpdate.clear();
                    usToUpdate.clear();
                    invoiceLineToupdate.clear();
                    invoiceToUpdate.clear();
                    feList.clear();
                    usgSmryAndExcngRate.clear();
                }
                InvIdAndOldExchangeRate.clear();
            }
        }
        catch(exception e){
            System.debug('In execute  catch block of QTB_ExchangeRateFieldsUpdate --->'+ e.getLineNumber());
            QTB_ExceptionLogger.enable();
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
            System.debug('In catch method of batch QTB_ExchangeRateFieldsUpdate');
            System.debug('Error inf::' + errorIds);
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                errorIds,
                e.getTypeName(),
                className
            );
        }
    }
    public void finish(Database.BatchableContext BC) {
        system.debug('in finish method of exchange rate post bill');
        // after updating fields calling post bill logic for posting of invoice
        Set<Id>finalInvoiceOrRunids = QTB_PostBillFlowController.getInvoiceIds(postBillRecordWithInvoiceBatch.keySet());
        QTB_PostBillFlowController.postInvoice(invCountry,postBillRecordWithInvoiceBatch,finalInvoiceOrRunids);
    }
}