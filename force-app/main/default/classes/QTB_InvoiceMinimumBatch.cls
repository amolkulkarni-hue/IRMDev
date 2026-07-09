/**********************************************************************************************************************************************************
* Class: QTB_InvoiceMinimumBatch
* Author: Accenture
* Requirement: SFCPQBLG-482
* Purpose : This is having Invoice Minimum Charges related to Pre-bill run Process.
* Change History: 06/17/2020
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture   05/22/2020
* Accenture     05/11/2021      GitLab # 1733, prepending the order number to the matching id of minimum
*                               charges usage
* TCS         18/09/2023      GitLab #17007, Modifying to support Pre-Bill run for Account & Order having different Invoice batch - Multiple Invoices Build
* Ramesh/Abdul 26/07/2024  Gitlab US#24172, US#24172 (Credit/Rebill Billnow)
***********************************************************************************************************************************************************/
global class QTB_InvoiceMinimumBatch implements Database.Batchable<sObject> {
    public static boolean throwExplicitException = false;
    public static final string INVMINBATCH = QTB_InvoiceMinimumBatch.class.getName();
    public static final String PENDING = QTB_Constants.INVOICE_STATUS_PENDING_BILLING;
    public static final String QUEUED_FOR_INVOICE = QTB_Constants.STATUS_QUEUED_FOR_INVOICE;
    public Map<String, Date> mapBatchesToDate = new Map<String, Date>();
    public Set<String> invSchBatch = new Set<String>();
    public static final Id accountBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
    public string invoiceBatch;
    public date targetDate;
    public Id preBillCheckboxRecordId;
    public string invoiceSchedulerName;
    public Set<Id> accountIds = new Set<Id>();
    public string rebillType = '';
    public Set<Id> rebillOrderIds = new Set<Id>(); // Gitlab US#24172 (Credit/Rebill Billnow)
    public List<QTB_Bill_Flow_Controller__c> billFlowList; // Gitlab US#24172 (Credit/Rebill Billnow)
    
    //constructor
    public QTB_InvoiceMinimumBatch(string inBatch, Date targtDate, Id prebillFlowRecord){
        mapBatchesToDate.put(inBatch,targtDate);
        invoiceBatch = inBatch;
        targetDate = targtDate;
        preBillCheckboxRecordId = prebillFlowRecord;
        // Gitlab US#24172 (Credit/Rebill Billnow)
        if(invoiceBatch.containsIgnoreCase('Rebill Run')){            
            billFlowList = [SELECT Id,
                            QTB_Rebill_Order__r.QTB_Rebill_Type__c, QTB_Rebill_Order__c, QTB_Rebill_Order__r.QTB_OrderCategory__c,QTB_Rebill_Order__r.AccountId
                            From QTB_Bill_Flow_Controller__c WHERE Id = :prebillFlowRecord  limit 1];
            if(billFlowList[0].QTB_Rebill_Order__c != null && billFlowList[0].QTB_Rebill_Order__r.AccountId != null) {
                accountIds.add(billFlowList[0].QTB_Rebill_Order__r.AccountId);
                rebillOrderIds.add(billFlowList[0].QTB_Rebill_Order__c);
                rebillType = billFlowList[0].QTB_Rebill_Order__r.QTB_Rebill_Type__c;  //either Split or Regular
            }  
        }
    }
    
    
    /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Return Type: Database.QueryLocator
Description: Query required records
**********************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        //QTB_PreBillRunHandler pre = new QTB_PreBillRunHandler();
        invSchBatch.addAll(mapBatchesToDate.keySet());
        if (Test.isRunningTest()) {
            mapBatchesToDate.put('Norway-26th', date.newInstance(2021, 1, 27));
            invSchBatch.add('Norway-26th');
        }
        String query;
        //for Rebill invoice
        if(invoiceBatch.containsIgnoreCase('Rebill Run'))
        {
            // As part of GITLAB #16257,for Split rebill type We don't need to run execute method so we made the dummy query to return zero records
            if (rebillType == System.Label.QTB_SplitRebill) {
                query = 'SELECT id FROM Account WHERE IsDeleted = true AND IsDeleted = false';
            }
            else { 
                query = 'SELECT Id,QTB_Customer_Number__c,QTB_Invoice_Minimum_Charges__c,ParentId,CurrencyIsoCode,QTB_Apply_Invoice_Minimum_Charges__c,QTB_Hold_Billing__c,QTB_Bill_Cycle_Day__c,QTB_Invoice_Minimum_Start_Date__c '+
                    ' FROM Account WHERE Id IN :accountIds AND RecordTypeId=: accountBillRecordTypeId and ParentId != null and QTB_Hold_Billing__c= False and QTB_Apply_Invoice_Minimum_Charges__c=True ' +
                    ' and QTB_Invoice_Minimum_Start_Date__c<=Today';
            }
        }
        //for Regular invoice we have invoice Scheduler
        else{
            query = 'SELECT Id,QTB_Customer_Number__c,QTB_Invoice_Minimum_Charges__c,ParentId,CurrencyIsoCode,QTB_Apply_Invoice_Minimum_Charges__c,QTB_Hold_Billing__c,QTB_Bill_Cycle_Day__c,QTB_Invoice_Minimum_Start_Date__c '+
                ' FROM Account WHERE RecordTypeId=: accountBillRecordTypeId and ParentId != null and QTB_Hold_Billing__c= False and QTB_Apply_Invoice_Minimum_Charges__c=True and QTB_Bill_Cycle_Day__c IN :invSchBatch ' +
                ' and QTB_Invoice_Minimum_Start_Date__c<=Today';
        }
        return Database.getQueryLocator(query);
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext, List<blng__UsageSummary__c>
Return Type: Void
Requirement :SFCPQBLG-482
Description: Calculates Invoice Minimum Charges
**********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<Account> scope) {
        try {
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            if (!scope.isEmpty()) {
                if (Test.isRunningTest()) {
                    mapBatchesToDate.put('Norway-26th', date.newInstance(2021, 1, 27));
                    invSchBatch.add('Norway-26th');
                }
                map<id, Double> total = new Map<id, Double>();
                set<id> accountIDs = new Set<id>();
                List<blng__Usage__c> usg = new List<blng__Usage__c>();
                map<ID, Account> relatedAccs = new Map<ID, Account>();
                for (Account blngacc : scope) {
                    accountIDs.add(blngacc.id);
                    relatedAccs.put(blngacc.id, blngacc);
                }
                /**** GitLab # 1733 ****/
                // Store order number being billed for each account
                // at a time only one order will be billed for an account
                Map<Id, String> billedOrderNumberByAccountId = new Map<Id, String>();
                Map<Id, String> accountIdWithUsgSumMatchingAttributeMap = new Map<Id, String>();
                string usgSummary = ' SELECT id, blng__OrderProduct__r.QTB_PrefixMatchingID__c,blng__Order__r.OrderNumber,QTB_Legal_Entity_Country__c,blng__Order__c, '+
                    ' blng__Order__r.blng__InvoiceBatch__c,blng__Account__c,blng__Account__r.QTB_Minimum_Storage_Charges__c, blng__Account__r.QTB_Invoice_Minimum_Charges__c, '+
                    ' blng__Subtotal__c,blng__SummaryStartDate__c,blng__SummaryEndDate__c,blng__UnitPrice__c,blng__MatchingAttribute__c '+ 
                    ' FROM blng__UsageSummary__c WHERE '+
                    ' blng__Subtotal__c != NULL '+
                    ' AND blng__Subtotal__c > 0 '+
                    ' AND blng__OrderProduct__r.SBQQ__Activated__c = TRUE '+
                    ' AND blng__Status__c = :QUEUED_FOR_INVOICE ';
                // Gitlab US#24172 (Credit/Rebill Billnow)
                if(invoiceBatch.containsIgnoreCase('Rebill Run')){
                    usgSummary+= ' AND blng__Order__c IN:rebillOrderIds ';
                }else{
                    Set<id> ids = relatedAccs.keySet();
                    usgSummary+= ' AND blng__InvoiceRunProcessingStatus__c = :PENDING AND blng__Account__c IN :ids';
                }
                
                List<blng__UsageSummary__c> usgSumList = Database.query(usgSummary);
                List<blng__UsageSummary__c> usegeSumlistForMiniInvoice = new List<blng__UsageSummary__c>();
                 // Gitlab US#24172 (Credit/Rebill Billnow)
                Set<Id> orderIds = new Set<Id>(); 
                if(usgSumList != null && !usgSumList.isEmpty()){
                    for(blng__UsageSummary__c usgsumm : usgSumList){
                        if(usgsumm.blng__Order__c != null){
                            orderIds.add(usgsumm.blng__Order__c); 
                        }
                    }
                    if(orderIds != null && !orderIds.isEmpty()){
                        usegeSumlistForMiniInvoice = [SELECT id,blng__MatchingAttribute__c 
                                                      From blng__UsageSummary__c 
                                                      WHERE blng__OrderProduct__r.OrderId IN :rebillOrderIds AND
                                                      blng__OrderProduct__r.QTB_Product_Name__c = 'Minimum Invoice Charges'];
                    }
                }
                if(!usgSumList.isEmpty() && usgSumList.size() > 0){
                    for (blng__UsageSummary__c eachAccountUS :usgSumList ) {
                        /* GitLab # 1733 Stand */
                        billedOrderNumberByAccountId.put(
                            eachAccountUS.blng__Account__c,
                            eachAccountUS.blng__OrderProduct__r.QTB_PrefixMatchingID__c <> null ?
                            eachAccountUS.blng__OrderProduct__r.QTB_PrefixMatchingID__c : ''
                        );
                        // Gitlab US#24172 (Credit/Rebill Billnow) add if condition for Rebill scenario
                        if(usegeSumlistForMiniInvoice !=null && !usegeSumlistForMiniInvoice.isEmpty()){
                            accountIdWithUsgSumMatchingAttributeMap.put(eachAccountUS.blng__Account__c,usegeSumlistForMiniInvoice[0].blng__MatchingAttribute__c);
                        }else{
                        accountIdWithUsgSumMatchingAttributeMap.put(eachAccountUS.blng__Account__c,eachAccountUS.blng__MatchingAttribute__c);
                        }
                        /* GitLab # 1733 End */
                        if (
                            total.containsKey(eachAccountUS.blng__Account__c) &&
                            eachAccountUS.blng__SummaryEndDate__c <
                            mapBatchesToDate.get(
                                eachAccountUS.blng__Order__r.blng__InvoiceBatch__c
                            ) //GIT-535- to take usage summaries before target day
                        ) {
                            total.put(
                                eachAccountUS.blng__Account__c,
                                total.get(eachAccountUS.blng__Account__c) +
                                eachAccountUS.blng__Subtotal__c
                            );
                        } else if (
                            eachAccountUS.blng__SummaryEndDate__c <
                            mapBatchesToDate.get(
                                eachAccountUS.blng__Order__r.blng__InvoiceBatch__c
                            )
                        ) {
                            total.put(
                                eachAccountUS.blng__Account__c,
                                eachAccountUS.blng__Subtotal__c
                            );
                        }
                    } 
                }                
                if (total != null) {
                    for (Id acc : total.keySet()) {
                        if (
                            relatedAccs != null &&
                            relatedAccs.containsKey(acc) &&
                            total.get(acc) > 0 &&
                            total.get(acc) <
                            relatedAccs.get(acc).QTB_Invoice_Minimum_Charges__c
                        ) {
                            date insertDate;
                            //In case of ReBill we are not considering Original Invoice Batch
                            //Gitlab US#22511 -- instead of equals to change to contains of "Rebill Run"
                            if(invoiceBatch.containsIgnoreCase('Rebill Run')){
                                insertDate = mapBatchesToDate.get(invoiceBatch).addDays(-1);//Gitlab US#22511
                            }else{
                                insertDate = mapBatchesToDate.get(invoiceBatch).addDays(-1);
                            }
                            datetime endDateTime = insertDate;
                            blng__Usage__c usage = new blng__Usage__c();
                            usage.blng__MatchingId__c =
                                billedOrderNumberByAccountId.get(acc) + // added as part of GitLab # 1733
                                relatedAccs.get(acc).QTB_Customer_Number__c +
                                LABEL.QTB_Invoice_Minimum;
                            usage.blng__MatchingAttribute__c = accountIdWithUsgSumMatchingAttributeMap.get(acc);
                            usage.blng__StartDateTime__c = endDateTime;
                            usage.blng__EndDateTime__c = endDateTime;
                            usage.blng__PreratedAmount__c =
                                relatedAccs.get(acc).QTB_Invoice_Minimum_Charges__c -
                                total.get(acc);
                            usage.QTB_System_Generated__c = true;
                            usage.QTB_Invoice_Quantity__c = 1;
                            usage.CurrencyIsoCode = relatedAccs.get(acc).CurrencyIsoCode;
                            usg.add(usage);
                            // System.debug('Usage---->'+usage);
                        } else {
                        }
                    }
                }
                //Database.insert(usg,false);
                if (usg <> null && usg.size() > 0) {
                    String errorMessage = '';
                    Database.SaveResult[] systemUsageInsert = Database.insert(usg, false);
                    for (Integer i = 0; i < systemUsageInsert.size(); i++) {
                        if (!systemUsageInsert[i].isSuccess()) {
                            errorMessage +=
                                ';;Matching ID -' +
                                usg[i].blng__MatchingId__c +
                                '::End Date Time -' +
                                usg[i].blng__EndDateTime__c +
                                'Error is::' +
                                systemUsageInsert[i].getErrors()[0].getMessage();
                        }
                    }
                    system.debug('errorMessage-->' + errorMessage);
                    if (errorMessage != '') {
                        if (errorMessage.length() > 100000)
                            errorMessage = errorMessage.substring(0, 100000);
                        QTB_ExceptionLogger.createLog(
                            1,
                            'Invoice minimum Usage Insert Failed',
                            errorMessage,
                            '',
                            INVMINBATCH
                        );
                    }
                }
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                INVMINBATCH
            );
        }
    }
    
    /*********************************************************************************************************
Method Name: finish
Parameters: Database.BatchableContext
Return Type: Void
Requirement :SFCPQBLG-482
Description: 
**********************************************************************************************************/
    global void finish(Database.BatchableContext BC) {
        try{
            // for Regular invoice
            update new QTB_Bill_Flow_Controller__c(Id = preBillCheckboxRecordId, QTB_PreBill_Run_status__c = 'Completed');
            
            // Gitlab US#24588 (Credit/Rebill Billnow)
            // for Rebill Invoice
            List<Order> ordList  = new List<Order>();
            List<QTB_Bill_Flow_Controller__c> preBillList = [SELECT Id, QTB_Rebill_Order__c,Invoice_Scheduler__r.blng__InvoiceBatches__c,
                                                             QTB_Rebill_Order__r.QTB_OrderCategory__c
                                                             FROM QTB_Bill_Flow_Controller__c
                                                             WHERE Id = :preBillCheckboxRecordId and 
                                                             QTB_Rebill_Order__r.QTB_OrderCategory__c = 'Rebill'];
            if(!preBillList.isEmpty() && preBillList[0].QTB_Rebill_Order__c != null){
                List<Id> ordId = new List<Id>();
                ordId.add(preBillList[0].QTB_Rebill_Order__c);
                System.enqueueJob(new QTB_RunBillNowQueueable(ordId));
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),INVMINBATCH);
        }
    }
}