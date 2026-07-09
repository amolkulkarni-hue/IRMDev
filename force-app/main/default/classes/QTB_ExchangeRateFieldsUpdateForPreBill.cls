/*****************************************************************************************************
* Class:   QTB_ExchangeRateFieldsUpdateForPreBill
* TestClass: QTB_ExcRateFieldUpdateForPreBill_Test
* Author: Virtusa
* Purpose: This is a Batch class to update fields of usage and usage summary based on foreign exchange rate during prebill
* Requirement: Gitlab #28211
* Change History: 
* Developer     	Date(dd/mm/yy)       Description
* -------------------------------------------------------------------------------------------
* Virtusa       	17/12/2024			update fields on usage and usage summary based on exchange rate
* Virtusa(Parth)	10/06/2025			#31399 Prerated unit price times the quantity should be equal to Prerated amount
*******************************************************************************************************/
public class QTB_ExchangeRateFieldsUpdateForPreBill implements Database.Batchable<SObject>,Database.Stateful {
    // Variable to get Class Name
    public static final string className = QTB_ExchangeRateFieldsUpdateForPreBill.class.getName();
    // Boolean to control exception
    public static boolean throwExplicitException = false;
    // String variable to store usageSummary Query
    public String query;
    // String variable to store PtreBill Status
    public static final String STATUS_QUEUED_FOR_INVOICE = 'Queued For Invoice';
    // String variable to store Invoice Run Status
    public static final String PENDING = QTB_Constants.INVOICE_STATUS_PENDING_BILLING;
    // variable to store target date passed from flow
    Public Date targetDates;
    // variable to store invoice batch name
    set<String>invSchBatch = new Set<String>();
    // list to store flow inputs
    Public List<QTB_PreBillBatchFlowController.FlowInputs>request1;
    public boolean runPreBill = True;
    // #30939 List of string to store Billcodes list to be excluded from forex calculation
    public Static List<string> excludedBillcodes = System.label.QTB_BillCodes_Exception_List.split(';');
    
    /*********************************************************************************************************
Method Name: runPreBillExchangeRateBatch
Parameters: List<QTB_PreBillBatchFlowController.FlowInputs>
Return Type: void
Requirement: Gitlab #28211
Description: this method will execute the QTB_ExchangeRateFieldsUpdateForPreBill batch class
**********************************************************************************************************/
    public static void runPreBillExchangeRateBatch(List<QTB_PreBillBatchFlowController.FlowInputs>request){
        if(!request.isEmpty() && request[0].targetDate != null && request[0].invoiceBatches != null){
            // assigning to set of string as invoice batch is multi select picklist field on invoice scheduler
            set<String>invoiceBatch = new set<String>(request[0].invoiceBatches.split(';'));
            Integer batchSize = Integer.ValueOf(System.Label.QTB_ExchangeRatePrebillBatch_Size);
            QTB_ExchangeRateFieldsUpdateForPreBill bat = new QTB_ExchangeRateFieldsUpdateForPreBill(invoiceBatch,request[0].targetDate,request);
            Database.executeBatch(bat,batchSize);
            
        }
    }
    
    /*********************************************************************************************************
Method Name: QTB_ExchangeRateFieldsUpdateForPreBill
Parameters: Set<String>invsBatch, date td,List<QTB_PreBillBatchFlowController.FlowInputs>request
Return Type: void
Requirement: Gitlab #28211
Description: constructor of batch class
**********************************************************************************************************/
    public QTB_ExchangeRateFieldsUpdateForPreBill(Set<String>invsBatch, date td,List<QTB_PreBillBatchFlowController.FlowInputs>request){
        system.debug('constructor invsBatch---->'+invsBatch);
        request1 = request;
        invSchBatch.addAll(invsBatch);
        targetDates = td;
        // Usage summary query for start method
        query = 'Select id,blng__PreratedAmount__c,blng__UnitPrice__c,blng__TotalQuantity__c,blng__AppliedUnitPrice__c,blng__Account__r.QTB_Contract_Currency__c,blng__Order__r.blng__InvoiceBatch__c,blng__Account__c,blng__Subtotal__c,blng__OrderProduct__r.Product2Id,blng__SummaryStartDate__c,blng__SummaryEndDate__c, ' +
            ' blng__MatchingId__c,QTB_Contracted_Currency_Rate__c,blng__NextBillingDate__c,blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c,blng__MatchingAttribute__c,blng__Account__r.CurrencyIsoCode from blng__UsageSummary__c where blng__Order__r.blng__InvoiceBatch__c in :invSchBatch and ' +
            ' blng__Subtotal__c != Null and blng__Account__r.QTB_Hold_Billing__c = False and blng__OrderProduct__r.SBQQ__Activated__c=True and blng__Status__c =:STATUS_QUEUED_FOR_INVOICE  and' +
            ' blng__InvoiceRunProcessingStatus__c=:PENDING and blng__Account__r.QTB_Contract_Entity__r.QTB_Contract_Currency_Applicable__c = true' +
            ' and blng__Account__r.QTB_isContractRateApplicable__c = true and blng__NextBillingDate__c <= :targetDates and blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c != null';
        system.debug('QTB_ExchangeRateFieldsUpdateForPreBill constructor --->'+ query);
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
Description: 
**********************************************************************************************************/
    public void execute(Database.BatchableContext BC, List<blng__UsageSummary__c> scope){
        String errorIds = '';
        try {
            System.debug('In execute method of QTB_ExchangeRateFieldsUpdateForPreBill batch  try block');
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            
            // Set to store Account contract Currencies
            Set<String> contractCurrencies = new Set<String>();
            // Set to store Invoice Currencies
            Set<String> invoiceCurrencies = new Set<String>();
            // Set to store legal Entity Rate Types
            Set<String> legalEntityRateTypes = new Set<String>();
            // List to update Usage records
            List<blng__Usage__c> usageToUpdate = new List<blng__Usage__c>();
            // List to update Usage Summary
            List<blng__UsageSummary__c> lstUsToUpdate = new List<blng__UsageSummary__c>();
            // #30939 Map to store Usage Summary Id and Usage Summary record
            Map<id,blng__UsageSummary__c> usIdWithUsgMap = new Map<Id,blng__UsageSummary__c>();
            // #30939 Map to store Usage Summary Id and PreRated Amount of Usages
            Map<Id,decimal> usgSmryAndPreRateAmt = new Map<Id,decimal>(); 
            // #30939 Map to store Usage Summary Id and PreRated Unit Price of Usages
            //Map<Id,decimal> usgSmryAndPreRateUnitPrc = new Map<Id,decimal>(); // #31399 commented as on usage summary unit price is null, so not updating unit price after exchange rate conversion
            // #30939 Map to store Usage Summary Id and Contract Currency Rate
            Map<Id,decimal> usgSmryIdAndContractRate = new Map<Id,decimal>();
            
            for(blng__UsageSummary__c usgSmry :scope){
                contractCurrencies.add(usgSmry.blng__Account__r.QTB_Contract_Currency__c);
                invoiceCurrencies.add(usgSmry.blng__Account__r.currencyIsoCode);
                legalEntityRateTypes.add(usgSmry.blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c);
                usIdWithUsgMap.put(usgSmry.id,usgSmry);  
            }
            if(!usIdWithUsgMap.isEmpty() && !contractCurrencies.isEmpty() && !invoiceCurrencies.isEmpty() && !legalEntityRateTypes.isEmpty()){//!usToUpdate.,isEmpty()
                // as per design need to fetch foreign exchange record based on invoice date -1  
                date invoiceDate = request1[0].invoiceDate.addDays(-1); 
                system.debug('invoiceDate - '+invoiceDate);
                // List to store Foreign Exchange
                List<QTB_Foreign_Exchange__c> feList = [select id,QTB_Rate__c,QTB_Currency_From__c,QTB_Currency_To__c,QTB_Start_Date__c,QTB_End_Date__c,QTB_Tax_Rate_Type__c
                                                        from QTB_Foreign_Exchange__c where QTB_Currency_From__c IN :contractCurrencies and QTB_Currency_To__c IN :invoiceCurrencies 
                                                        and QTB_Tax_Rate_Type__c IN :legalEntityRateTypes and QTB_Start_Date__c <= :invoiceDate and QTB_End_Date__c >= :invoiceDate];
                // Clearing list
                contractCurrencies.clear();
                invoiceCurrencies.clear();
                legalEntityRateTypes.clear();
                
                if(!feList.isEmpty()){
                    // fetching usage records based on usage summary id
                    // #31399 added QTB_Actual_Rate__c as this will have original unit price valuecomming form edp, which will help to update QTB_Prerated_Unit_Price__c with exchange rate conversion
                    for(blng__Usage__c usg : [select id,QTB_Actual_Rate__c,blng__UsageSummary__c,name,blng__PreratedQuantity__c,blng__PreratedAmount__c,QTB_Prerated_Unit_Price__c,blng__Quantity__c,
                                              QTB_Product_Identifier_1__c,blng__UsageSummary__r.blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c,blng__UsageSummary__r.blng__Account__r.currencyIsoCode,blng__UsageSummary__r.blng__Account__r.QTB_Contract_Currency__c,blng__Subtotal__c,QTB_Contracted_Currency_Amount__c,QTB_TaxAmount__c,blng__UnitPrice__c from blng__Usage__c where 
                                              blng__UsageSummary__c in :usIdWithUsgMap.KeySet() and QTB_Actual_Rate__c != null])
                    {
                        for(QTB_Foreign_Exchange__c fe :feList){
                            // Variable to store exchange Rate Amount values
                            decimal exchangeRateUnitprice=0;
                            // Variable to store PreRated Amount values
                            decimal preRateAmount=0;
                            // Variable to store PreRated Unit values
                            //decimal preRateUnitprice=0;
                            // Check for Account Contract Currency equals to Foreign Exchange ISO Currency and Rate Type and account Contract entity equals to Foreign Exchange Rate Type
                            if(usg.blng__UsageSummary__r.blng__Account__r?.QTB_Contract_Currency__c ==fe.QTB_Currency_From__c && usg.blng__UsageSummary__r?.blng__Account__r?.currencyIsoCode == fe.QTB_Currency_To__c && 
                               usg.blng__UsageSummary__r.blng__Account__r?.QTB_Contract_Entity__r?.QTB_FX_Tax_Rate_Type__c == fe.QTB_Tax_Rate_Type__c && fe.QTB_Rate__c != null){
                                   // Condition to cehck if map contains usage summary id
                                   blng__Usage__c usage = new blng__Usage__c();
                                   usage.id = usg.id;
                                   // Ternary operater to assign the PreRated Amount values based on exception billcodes 
                                   exchangeRateUnitprice = (!excludedBillcodes.contains(usg.QTB_Product_Identifier_1__c))? (usg.QTB_Actual_Rate__c*fe.QTB_Rate__c).setScale(4, System.RoundingMode.HALF_UP) : (usg.QTB_Actual_Rate__c).setScale(4, System.RoundingMode.HALF_UP);
                              
                                   if(usg.blng__PreratedQuantity__c != null){
                                       preRateAmount = (exchangeRateUnitprice*usg.blng__PreratedQuantity__c).setScale(2, System.RoundingMode.HALF_UP);
                                       //preRateUnitprice = exchangeRateprice.setScale(4, System.RoundingMode.HALF_UP);
                                       usage.blng__PreratedAmount__c = preRateAmount;
                                       usage.QTB_Prerated_Unit_Price__c = exchangeRateUnitprice;
                                   }
                                   usageToUpdate.add(usage);
                                   if(usgSmryAndPreRateAmt.containsKey(usg.blng__UsageSummary__r.Id)){
                                       preRateAmount = preRateAmount + usgSmryAndPreRateAmt.get(usg.blng__UsageSummary__r.Id);
                                   }
                                   // #31399 commented as not updating unit price on usage summary
                                   /*if(usgSmryAndPreRateUnitPrc.containsKey(usg.blng__UsageSummary__r.Id)){
                                       preRateUnitprice = preRateUnitprice + usgSmryAndPreRateUnitPrc.get(usg.blng__UsageSummary__r.Id);
                                   }*/
                                   usgSmryAndPreRateAmt.put(usg.blng__UsageSummary__r.Id,preRateAmount);
                                   //usgSmryAndPreRateUnitPrc.put(usg.blng__UsageSummary__r.Id,preRateUnitprice);
                                   usgSmryIdAndContractRate.put(usg.blng__UsageSummary__r.Id,fe.QTB_Rate__c);
                               }
                        }
                    }
                    for(blng__UsageSummary__c usgSmry  :usIdWithUsgMap.Values()){
                        // Check for Account Contract Currency equals to Foreign Exchange ISO Currency and Rate Type and account Contract entity equals to Foreign Exchange Rate Type
                        if( usgSmryAndPreRateAmt.ContainsKey(usgSmry.id) /*&& usgSmryAndPreRateUnitPrc.ContainsKey(usgSmry.id)*/){
                      
                            blng__UsageSummary__c us = new blng__UsageSummary__c();
                            us.Id = usgSmry.Id;
                            us.blng__PreratedAmount__c = usgSmryAndPreRateAmt.get(usgSmry.id);
                            us.blng__Subtotal__c = usgSmryAndPreRateAmt.get(usgSmry.id);
                            // #31399 commented as not updating unit price on usage summary
                            /*if(usgSmry.blng__TotalQuantity__c !=0 && usgSmry.blng__TotalQuantity__c != null){
                            us.blng__UnitPrice__c = (usgSmryAndPreRateUnitPrc.get(usgSmry.id)/usgSmry.blng__TotalQuantity__c).setScale(4, System.RoundingMode.HALF_UP);
                            us.blng__AppliedUnitPrice__c = usgSmryAndPreRateUnitPrc.get(usgSmry.id)/usgSmry.blng__TotalQuantity__c;
                            }*/
                            us.QTB_Contracted_Currency_Rate__c = usgSmryIdAndContractRate.get(usgSmry.id);
                            lstUsToUpdate.add(us);
                        }
                    }
                }
                // To Update Invoice, Invoice Line, Usage Summary and Usage based on new Rate
                if(!lstUsToUpdate.isEmpty() && !usageToUpdate.isEmpty()){                
                    sbqq.TriggerControl.disable();
                    QTB_RecursiveHandlerCheck.checkFieldEditableMethod = false;
                    update usageToUpdate;
                    update lstUsToUpdate;
                    system.debug('UPDATE');
                    sbqq.TriggerControl.enable();
                }
                // Clearing memory
                usageToUpdate.clear();
                lstUsToUpdate.clear(); 
                usIdWithUsgMap.clear();
                usgSmryAndPreRateAmt.clear();
                //usgSmryAndPreRateUnitPrc.clear();
                usgSmryIdAndContractRate.clear();
            }
        }
        catch(exception e){
            System.debug('In execute  catch block of QTB_ExchangeRateFieldsUpdateForPreBill --->'+ e.getLineNumber());
            System.debug('In execute  catch block of QTB_ExchangeRateFieldsUpdateForPreBill --->'+ e.getMessage());
            runPreBill = false;
            QTB_ExceptionLogger.enable();
            errorIds = e.getMessage() + errorIds;
            if (errorIds.length() > 100000)
                errorIds = errorIds.substring(0, 100000);
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
        system.debug('in Finish Method of QTB_ExchangeRateFieldsUpdateForPreBill');
        system.debug('request1--->'+request1);
        system.debug('runPreBill->'+runPreBill);
        // Get batch job status
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        // If any batch chunk failed OR DML limit was exceeded
        if (!runPreBill || job.Status == 'Failed' || job.Status == 'Aborted' || job.NumberOfErrors > 0) {
            QTB_Bill_Flow_Controller__c billFlowCtrl = new QTB_Bill_Flow_Controller__c(
                Id = request1[0].prebillBatchRunRecordId, 
                QTB_PreBill_Run_Status__c = 'Error'
            );
            update billFlowCtrl;
        } else {
            QTB_PreBillBatchFlowController.executePreBill(request1);
        }
    }
}