/******************************************************************************************************
* Class: QTB_ProductDiscountBatch
* Author: Accenture
* Requirement: QTB-30
* Purpose : This is having Product Billing Discount related to Pre-bill run Process.
* Change History: 06/17/2020
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture   05/22/2020
* IRM/Virtusa 11/26/2021      Git #5986 Retire Existing Work Order Tiering
* Ramesh/Abdul 26/07/2024     Gitlab US#24172 (Credit/Rebill Billnow) 
*******************************************************************************************************/
global class QTB_ProductDiscountBatch implements Database.Batchable<sObject> {
    public static boolean throwExplicitException = false;
    public static final string PRODUCT_DISCOUNT_BATCH = QTB_ProductDiscountBatch.class.getName();
    public static final String PENDING = QTB_Constants.INVOICE_STATUS_PENDING_BILLING;
    public static final String QUEUED_FOR_INVOICE = QTB_Constants.STATUS_QUEUED_FOR_INVOICE;
    public Map<String, Date> mapBatchesToDate = new Map<String, Date>();
    public Set<String> invSchBatch = new Set<String>();
    public string invoiceBatch;
    public date targetDate;
    public Id preBillCheckRecordId;
    public string rebillType = '';
    public List<QTB_Bill_Flow_Controller__c> billFlowList = new List<QTB_Bill_Flow_Controller__c> (); // Gitlab US#24172 (Credit/Rebill Billnow)
    public static set<id> rebillOrderIds = new set<id>(); // Gitlab US#24172 (Credit/Rebill Billnow)
    public List<QTB_Product_Billing_Discount__c> discount = [SELECT id, QTB_Account__c, QTB_Product__c, QTB_Discount__c
                                                             FROM QTB_Product_Billing_Discount__c
                                                             WHERE QTB_Active__c = TRUE AND QTB_Start_Date__c <= TODAY AND QTB_End_Date__c >= TODAY];
    
    public QTB_ProductDiscountBatch(string schedulerBatch, Date targtDate, Id prebillFlowRecord){
        invoiceBatch = schedulerBatch;
        targetDate = targtDate;
        mapBatchesToDate.put(schedulerBatch,targtDate);
        preBillCheckRecordId = prebillFlowRecord;
        //SplitRebill -- to get the rebillType fetching the data QTB_Bill_Flow_Controller__c
        // Gitlab US#24172 (Credit/Rebill Billnow) - Added the below Query for BillNow Scenerio
        billFlowList = [SELECT Id,QTB_Rebill_Order__c,QTB_Rebill_Order__r.QTB_Rebill_Type__c  
                        FROM QTB_Bill_Flow_Controller__c 
                        WHERE Id = :prebillFlowRecord  limit 1];
        if(billFlowList[0].QTB_Rebill_Order__c !=null){
            rebillType = billFlowList[0].QTB_Rebill_Order__r.QTB_Rebill_Type__c;  //either Split or Regular
            rebillOrderIds.add(billFlowList[0].QTB_Rebill_Order__c);// Gitlab US#24172 (Credit/Rebill Billnow)
        }
    }
    
    
    /*********************************************************************************************************
Method Name: start
Parameters: Database.BatchableContext
Return Type: Database.QueryLocator
Description: Query required records
**********************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query;
        Set<Id> discountAccountIDs = new Set<ID>();
        for (QTB_Product_Billing_Discount__c pro : discount) {
            discountAccountIDs.add(pro.QTB_Account__c);
        }
        invSchBatch.addAll(mapBatchesToDate.keySet());
        
        if (Test.isRunningTest()) {
            mapBatchesToDate.put('Norway-26th', date.newInstance(2021, 1, 27));
            invSchBatch.add('Norway-26th');
        }
        System.debug('>>mapBatchesToDate>>>'+mapBatchesToDate);
        //As part of GITLAB #16257 added if check for split rebill type , for Split rebill We don't need to run execute method so we made the dummy query to return zero records.
        //for Rebill-invoice
        if(invoiceBatch.containsIgnoreCase('Rebill Run'))
        { 
            if(rebillType == System.Label.QTB_SplitRebill){
                query = 'SELECT id FROM Account WHERE IsDeleted = true AND IsDeleted = false';
            }
            // Gitlab US#24172 (Credit/Rebill Billnow) added for Regular rebill
            else{
                query =
                    'Select id,blng__Order__r.blng__InvoiceBatch__c,blng__Account__c,blng__Subtotal__c,blng__OrderProduct__r.Product2Id,blng__SummaryStartDate__c,blng__SummaryEndDate__c, ' +
                    ' blng__MatchingId__c,blng__MatchingAttribute__c,blng__Account__r.CurrencyIsoCode from blng__UsageSummary__c where blng__Order__r.id in :rebillOrderIds and ' +
                    ' blng__Subtotal__c != Null and blng__Account__r.QTB_Hold_Billing__c = False and blng__OrderProduct__r.SBQQ__Activated__c=True and blng__Status__c =: QUEUED_FOR_INVOICE  and' +
                    ' blng__Account__c in :discountAccountIDs';
            }
        }
        //for Regular invoice we have invoice Scheduler
        else{
            query =
                'Select id,blng__Order__r.blng__InvoiceBatch__c,blng__Account__c,blng__Subtotal__c,blng__OrderProduct__r.Product2Id,blng__SummaryStartDate__c,blng__SummaryEndDate__c, ' +
                ' blng__MatchingId__c,blng__MatchingAttribute__c,blng__Account__r.CurrencyIsoCode from blng__UsageSummary__c where blng__Order__r.blng__InvoiceBatch__c in :invSchBatch and ' +
                ' blng__Subtotal__c != Null and blng__Account__r.QTB_Hold_Billing__c = False and blng__OrderProduct__r.SBQQ__Activated__c=True and blng__Status__c =: QUEUED_FOR_INVOICE  and' +
                ' blng__InvoiceRunProcessingStatus__c=:PENDING and blng__Account__c in :discountAccountIDs';
        }
        update new QTB_Bill_Flow_Controller__c(Id = preBillCheckRecordId, QTB_PreBill_Run_status__c = 'In Progress');
        return Database.getQueryLocator(query);
    }
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext, List<blng__UsageSummary__c>
Return Type: void
Description: Calculates Discount for the Products as Mentioned in QTB_Product_Billing_Discount__c Object
**********************************************************************************************************/
    global void execute(Database.BatchableContext BC,List<blng__UsageSummary__c> scope) 
    {
        try {
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            
            if (!scope.isEmpty()) {
                List<blng__Usage__c> usg = new List<blng__Usage__c>();
                Map<String, Decimal> dis = new Map<String, Decimal>();
                
                String errorMessage = '';
                for (QTB_Product_Billing_Discount__c disc : discount) {
                    String concat1 =
                        String.valueOf(disc.QTB_Account__c) +
                        String.valueOf(disc.QTB_Product__c);
                    dis.put(concat1, disc.QTB_Discount__c);
                }
                //System.debug('Discount map--->'+dis);
                //Loop to find Usage Summaries of those Products
                //for which the discount should be applied.
                // System.debug(scope);
                // System.debug(mapBatchesToDate);
                if (Test.isRunningTest()) {
                    mapBatchesToDate.put('Norway-26th', date.newInstance(2021, 1, 27));
                    invSchBatch.add('Norway-26th');
                }
                for (blng__UsageSummary__c us : scope) {
                    //System.debug(us.blng__SummaryEndDate__c);
                    //System.debug(us.blng__Order__r.blng__InvoiceBatch__c);
                    if (
                        us.blng__SummaryEndDate__c <
                        mapBatchesToDate.get(us.blng__Order__r.blng__InvoiceBatch__c) //GIT-535- to take usage summaried before target day
                    ) {
                        // System.debug('inside disc selected usg summry');
                        String concat2 =
                            String.valueOf(us.blng__Account__c) +
                            String.valueOf(us.blng__OrderProduct__r.Product2Id);
                        if (dis.containsKey(concat2)) {
                            double subtotal = -(us.blng__Subtotal__c *
                                                dis.get(concat2) /
                                                100);
                            blng__Usage__c usage = new blng__Usage__c();
                            usage.blng__MatchingId__c = us.blng__MatchingId__c;
                            usage.blng__MatchingAttribute__c = us.blng__MatchingAttribute__c; 
                            date endDate = us.blng__SummaryEndDate__c;
                            Datetime endDateTime = endDate; // Implicit cast
                            usage.blng__StartDateTime__c = endDateTime;
                            usage.blng__EndDateTime__c = endDateTime;
                            usage.blng__PreratedAmount__c = subtotal;
                            usage.QTB_System_Generated__c = true;
                            usage.QTB_Invoice_Quantity__c = 1;
                            usage.CurrencyIsoCode = us.blng__Account__r.CurrencyIsoCode;
                            usg.add(usage);
                            // System.debug('Usage--->'+usage);
                        }
                    }
                }
                // Database.insert(usg,false);
                if (usg <> null && usg.size() > 0) {
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
                        QTB_ExceptionLogger.enable(); //Gitlab US#24172
                        QTB_ExceptionLogger.createLog(
                            1,
                            'Discount Usage Insert Failed',
                            errorMessage,
                            '',
                            PRODUCT_DISCOUNT_BATCH
                        );
                    }
                }
            } 
        } catch (Exception e) {
            QTB_ExceptionLogger.enable(); //Gitlab US#24172
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                PRODUCT_DISCOUNT_BATCH
            );
        }
    }
    
    
    /*********************************************************************************************************
Method Name: finish
Parameters: Database.BatchableContext
Return Type: void
Description: Calls QTB_WorkOrderBatch Batch Class to calculate work order tier charges
**********************************************************************************************************/
    global void finish(Database.BatchableContext BC) {        
        //Git #5986 -- based on true/false value of QTB_RetireWorkOrder custom setting label, ignoring to run the QTB_WorkOrderBatch
        //execute QTB_MinimumChargesBatch to continue the process
        if(System.Label.QTB_RetireWorkOrder.equalsIgnoreCase('true')){
            QTB_MinimumChargesBatch msc = new QTB_MinimumChargesBatch(invoiceBatch,targetDate,preBillCheckRecordId);
            Database.executeBatch(msc, 8);
        }else{
            QTB_WorkOrderBatch work = new QTB_WorkOrderBatch(invoiceBatch,targetDate,preBillCheckRecordId);
            Database.executeBatch(work, 30); 
        }
    }
}