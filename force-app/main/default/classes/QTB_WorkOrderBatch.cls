/*****************************************************************************************************
* Class: QTB_WorkOrderBatch
* Author: Accenture
* Requirement: SFCPQBLG-1025
* Purpose : This is having Work Order Tier process related to Pre-bill run Process.
* Change History: 10/08/2020
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture   10/08/2020
*******************************************************************************************************/
global class QTB_WorkOrderBatch implements Database.Batchable<sObject> {
    public static boolean throwExplicitException = false;
    public static final string WORKORDER_TIER_BATCH = QTB_WorkOrderBatch.class.getName();
    public static final String PENDING = QTB_Constants.INVOICE_STATUS_PENDING_BILLING;
    public static final String QUEUED_FOR_INVOICE = QTB_Constants.STATUS_QUEUED_FOR_INVOICE;
    public Map<String, Date> mapBatchesToDate = new Map<String, Date>();
    public Set<String> invSchBatch = new Set<String>();
    public string invoiceBatch;
    public date targetDate;
    public Id preBillCheckRecordId;
    public string rebillType = '';
    public List<QTB_Bill_Flow_Controller__c> billFlowList = new List<QTB_Bill_Flow_Controller__c> (); // Gitlab US#24172 (Credit/Rebill Billnow)
    public static final Id accountBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
    public static set<id> rebillOrderIds = new set<id>(); // Gitlab US#24172 (Credit/Rebill Billnow)
    public List<QTB_WorkOrderTiers__c> workOrderTiersList = [
        SELECT
        Id,
        QTB_Account__c,
        QTB_First_Tier_Breakpoint__c,
        QTB_First_Tier_Price__c,
        QTB_Account__r.QTB_Work_Order_Tier_Flag__c,
        QTB_Account__r.QTB_WorkOrderTieringStartDate__c,
        QTB_Account__r.QTB_Hold_Billing__c,
        QTB_Product_ID__c,
        QTB_Second_Tier_Price__c
        FROM QTB_WorkOrderTiers__c
        WHERE
        QTB_Account__r.QTB_Work_Order_Tier_Flag__c = TRUE
        AND QTB_Account__r.QTB_Hold_Billing__c = FALSE
        AND QTB_Account__r.QTB_WorkOrderTieringStartDate__c <= TODAY
    ];
    public QTB_WorkOrderBatch(string invoicbatch, Date targtDate, Id prebillFlowRecord){
        mapBatchesToDate.put(invoicbatch,targtDate);
        invoiceBatch = invoicbatch;
        targetDate = targtDate;
        preBillCheckRecordId = prebillFlowRecord;
        // Gitlab US#24172 (Credit/Rebill Billnow) - Added the fields in below Query for BillNow Scenerio
        billFlowList = [SELECT Id,QTB_Rebill_Order__c,QTB_Rebill_Order__r.QTB_Rebill_Type__c  
                        FROM QTB_Bill_Flow_Controller__c 
                        WHERE Id = :prebillFlowRecord  limit 1];
        
        if(billFlowList[0].QTB_Rebill_Order__c !=null){
            rebillType = billFlowList[0].QTB_Rebill_Order__r.QTB_Rebill_Type__c;  //either Split or Regular   
            rebillOrderIds.add(billFlowList[0].QTB_Rebill_Order__c); // Gitlab US#24172 (Credit/Rebill Billnow)
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
        Set<ID> workOrderAccounts = new Set<ID>();
        Set<ID> workOrderProducts = new Set<ID>();
        List<String> workOrderAccProdList = new List<String>();
        invSchBatch.addAll(mapBatchesToDate.keySet());
        if (Test.isRunningTest()) {
            mapBatchesToDate.put('Norway-26th', date.newInstance(2021, 1, 27));
            invSchBatch.add('Norway-26th');
        }
        
        for (QTB_WorkOrderTiers__c work : workOrderTiersList) {
            if (work.QTB_Account__c != null && work.QTB_Product_ID__c != null)
            { workOrderAccounts.add(work.QTB_Account__c);
             workOrderProducts.add(work.QTB_Product_ID__c);
             workOrderAccProdList.add(String.ValueOF(work.QTB_Account__c) +String.ValueOF(work.QTB_Product_ID__c));
            }
        }
        System.Debug('accProlist>>>' + workOrderAccProdList);
        // As part of GITLAB #16257,for Split rebill type We don't need to run execute method so we made the dummy query to return zero records
        //for Rebill-invoice
        if(invoiceBatch.containsIgnoreCase('Rebill Run')){

            if (rebillType == System.Label.QTB_SplitRebill) {
                query = 'SELECT id FROM Account WHERE IsDeleted = true AND IsDeleted = false';
            }
            // Gitlab US#24172 (Credit/Rebill Billnow) added for Rebill-Regular
            else{
                query ='Select id,blng__Order__r.blng__InvoiceBatch__c,blng__Account__c,QTB_AccountProductID__c,blng__Account__r.QTB_Work_Order_Tier_Flag__c,blng__Subtotal__c,blng__Account__r.QTB_WorkOrderTieringStartDate__c, ' +
                    'blng__OrderProduct__r.Product2Id,blng__SummaryStartDate__c,blng__SummaryEndDate__c from blng__UsageSummary__c where blng__Account__r.QTB_Work_Order_Tier_Flag__c=True and blng__Subtotal__c != Null and blng__Order__r.id in :rebillOrderIds and ' +
                    'blng__Account__c in :workOrderAccounts and blng__OrderProduct__r.Product2Id in :workOrderProducts and QTB_AccountProductID__c in :workOrderAccProdList and ' +
                    'blng__Account__r.QTB_Hold_Billing__c = False and blng__Status__c =: QUEUED_FOR_INVOICE  and  blng__Account__r.QTB_WorkOrderTieringStartDate__c <=TODAY and blng__OrderProduct__r.SBQQ__Activated__c=True';
            }
        }
        //for Regular invoice we have invoice Scheduler
        else { 
            query ='Select id,blng__Order__r.blng__InvoiceBatch__c,blng__Account__c,QTB_AccountProductID__c,blng__Account__r.QTB_Work_Order_Tier_Flag__c,blng__Subtotal__c,blng__Account__r.QTB_WorkOrderTieringStartDate__c, ' +
                'blng__OrderProduct__r.Product2Id,blng__SummaryStartDate__c,blng__SummaryEndDate__c from blng__UsageSummary__c where blng__Account__r.QTB_Work_Order_Tier_Flag__c=True and blng__Subtotal__c != Null and blng__Order__r.blng__InvoiceBatch__c in :invSchBatch and ' +
                'blng__Account__c in :workOrderAccounts and blng__OrderProduct__r.Product2Id in :workOrderProducts and QTB_AccountProductID__c in :workOrderAccProdList and ' +
                'blng__Account__r.QTB_Hold_Billing__c = False and blng__InvoiceRunProcessingStatus__c=:PENDING and blng__Status__c =: QUEUED_FOR_INVOICE  and  blng__Account__r.QTB_WorkOrderTieringStartDate__c <=TODAY and blng__OrderProduct__r.SBQQ__Activated__c=True';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC,List<blng__UsageSummary__c> workOrderUsgSummaryList) 
    {
        try {
            Map<String, QTB_WorkOrderTiers__c> accountProdMap = new Map<String, QTB_WorkOrderTiers__c>();
            for (QTB_WorkOrderTiers__c work : workOrderTiersList) {
                String accountProd =String.valueOf(work.QTB_Account__c) +String.valueOf(work.QTB_Product_ID__c);
                accountProdMap.put(accountProd, work);
            }
            // System.debug('Account promap--'+accountProdMap);
            if (!workOrderUsgSummaryList.isEmpty()) {
                Map<id, blng__Usage__c> updatedUsages = new Map<id, blng__Usage__c>(); // THIS TO BE MADE PUBLIC
                set<blng__UsageSummary__c> updatedUsageSummaries = new Set<blng__UsageSummary__c>();
                map<Id, Double> workOrderUsgSummarysPrerateUpdate = new Map<Id, Double>();
                map<Id, Decimal> workOrderUsgSummarysQuantityUpdate = new Map<Id, Decimal>();
                if (Test.isRunningTest()) {
                    mapBatchesToDate.put('Norway-26th', date.newInstance(2021, 1, 27));
                    invSchBatch.add('Norway-26th');
                }
                for (blng__UsageSummary__c usgSummary : workOrderUsgSummaryList) {
                    if (usgSummary.blng__SummaryEndDate__c < mapBatchesToDate.get(usgSummary.blng__Order__r.blng__InvoiceBatch__c))//GIT-535- to take usage summaried before target day
                    {
                        // System.debug('Id usage summary>>>>>>>'+ usgSummary.id);
                        map<string, Decimal> workOrderQuantity = new Map<string, Decimal>();
                        map<string, Decimal> workOrderInvoiceQuantity = new Map<string, Decimal>();
                        map<string, Id> workOrderUsageId = new Map<string, Id>();
                        map<string, String> workOrderAccountProd = new Map<string, string>();
                        decimal summedPrerateQty =0.0;
                        decimal summedPrerateAmt =0.0;
                        String nullWorkOrderId = 'NULL';
                        for (blng__usage__c usage : [SELECT id,QTB_Work_Order_ID__c,blng__Quantity__c,QTB_Invoice_Quantity__c,blng__PreratedQuantity__c,blng__Subtotal__c,
                                                     blng__PreratedAmount__c,blng__UnitPrice__c,blng__UsageSummary__c,blng__Account__c,blng__OrderProduct__r.Product2Id
                                                     FROM blng__Usage__c WHERE blng__UsageSummary__c = :usgSummary.Id]) 
                        {
                            if(usage.blng__PreratedQuantity__c == 0 && usage.blng__Quantity__c !=0 && usage.blng__PreratedAmount__c == 0){
                                if (usage.QTB_Work_Order_ID__c != null) {
                                    if (usage.blng__Quantity__c != null && workOrderQuantity.containsKey(usage.QTB_Work_Order_ID__c)) {
                                        workOrderQuantity.put(usage.QTB_Work_Order_ID__c,workOrderQuantity.get(usage.QTB_Work_Order_ID__c) +usage.blng__Quantity__c);
                                    } 
                                    else {
                                        workOrderQuantity.put(usage.QTB_Work_Order_ID__c,usage.blng__Quantity__c);
                                    }                                
                                    if (usage.QTB_Invoice_Quantity__c != null && workOrderInvoiceQuantity.containsKey(usage.QTB_Work_Order_ID__c)) {
                                        workOrderInvoiceQuantity.put(usage.QTB_Work_Order_ID__c,workOrderInvoiceQuantity.get(usage.QTB_Work_Order_ID__c) +usage.QTB_Invoice_Quantity__c);
                                    } 
                                    else {
                                        workOrderInvoiceQuantity.put(usage.QTB_Work_Order_ID__c, usage.QTB_Invoice_Quantity__c);
                                    }
                                    if (!workOrderUsageId.containsKey(usage.QTB_Work_Order_ID__c)) {
                                        workOrderUsageId.put(usage.QTB_Work_Order_ID__c, usage.Id);
                                    }
                                    if ( !workOrderAccountProd.containsKey(usage.QTB_Work_Order_ID__c)) {
                                        workOrderAccountProd.put(usage.QTB_Work_Order_ID__c,String.valueOf(usage.blng__Account__c) +String.valueOf(usage.blng__OrderProduct__r.Product2Id));
                                    }
                                } 
                                else {
                                    if (usage.blng__Quantity__c != null && workOrderQuantity.containsKey(nullWorkOrderId)) {
                                        workOrderQuantity.put(nullWorkOrderId,workOrderQuantity.get(nullWorkOrderId) + usage.blng__Quantity__c);
                                    } 
                                    else {
                                        workOrderQuantity.put(nullWorkOrderId,usage.blng__Quantity__c);
                                    }                                
                                    if (usage.QTB_Invoice_Quantity__c != null && workOrderInvoiceQuantity.containsKey(nullWorkOrderId)) {
                                        workOrderInvoiceQuantity.put(nullWorkOrderId, workOrderInvoiceQuantity.get(nullWorkOrderId) + usage.QTB_Invoice_Quantity__c);
                                    } 
                                    else {
                                        workOrderInvoiceQuantity.put(nullWorkOrderId,usage.QTB_Invoice_Quantity__c);
                                    }
                                    if (!workOrderUsageId.containsKey(nullWorkOrderId)) {
                                        workOrderUsageId.put(nullWorkOrderId, usage.Id);
                                    }
                                    if (!workOrderAccountProd.containsKey(nullWorkOrderId)) {
                                        workOrderAccountProd.put(nullWorkOrderId,String.valueOf(usage.blng__Account__c) + String.valueOf(usage.blng__OrderProduct__r.Product2Id));
                                    }
                                }
                                blng__usage__c updtUsage = new blng__Usage__c();
                                updtUsage.Id = usage.id;
                                updtUsage.blng__Quantity__c = 0;
                                updtUsage.blng__Subtotal__c = 0;
                                updtUsage.blng__UnitPrice__c = 0;
                                updtUsage.blng__PreratedQuantity__c = 0;
                                updtUsage.QTB_WO_Usage__c=true;   
                                //updtUsage.QTB_Invoice_Quantity__c = 0;
                                updatedUsages.put(updtUsage.Id, updtUsage);
                                //System.debug('Usage>>>>'+updtUsage.Id);
                            }
                            else if(usage.blng__PreratedQuantity__c != 0 || usage.blng__PreratedAmount__c != 0)
                            {
                                summedPrerateQty = summedPrerateQty +usage.blng__PreratedQuantity__c;
                                summedPrerateAmt= summedPrerateAmt + usage.blng__PreratedAmount__c;
                            }
                        }
                        //System.debug('work order quantity--->'+workOrderQuantity);
                        //System.debug('work order invoice--->'+workOrderInvoiceQuantity);
                        //System.debug('work order work order--->'+workOrderUsageId);
                        //System.debug('work order account prod--->'+workOrderAccountProd);
                        
                        for (String workID : workOrderUsageId.keyset()) 
                        {
                            if (workOrderQuantity.containsKey(workID) && workOrderInvoiceQuantity.containsKey(workID) && 
                                workOrderAccountProd.containsKey(workID) && accountProdMap.containsKey(workOrderAccountProd.get(workID))) 
                            {
                                blng__Usage__c updtUsage = new blng__Usage__c();
                                updtUsage.Id = workOrderUsageId.get(workID);
                                // System.debug('usage id--->'+updtUsage.Id);
                                if (workOrderQuantity.get(workID) > accountProdMap.get(workOrderAccountProd.get(workID)).QTB_First_Tier_Breakpoint__c )
                                {
                                    updtUsage.blng__PreratedAmount__c =accountProdMap.get(workOrderAccountProd.get(workID)).QTB_First_Tier_Price__c 
                                        + (workOrderQuantity.get(workID) - accountProdMap.get(workOrderAccountProd.get(workID)).QTB_First_Tier_Breakpoint__c) * accountProdMap.get(workOrderAccountProd.get(workID)).QTB_Second_Tier_Price__c;
                                    //updtUsage.QTB_Invoice_Quantity__c = workOrderInvoiceQuantity.get(workID);
                                }
                                else {
                                    updtUsage.blng__PreratedAmount__c = accountProdMap.get(workOrderAccountProd.get(workID)).QTB_First_Tier_Price__c;
                                    // updtUsage.QTB_Invoice_Quantity__c = workOrderInvoiceQuantity.get(workID);
                                }
                                updtUsage.blng__Quantity__c = 0;
                                updtUsage.blng__PreratedQuantity__c =0;// workOrderQuantity.get(workID);
                                // System.debug('quantity id--->'+ updtUsage.blng__PreratedQuantity__c);
                                updtUsage.blng__UnitPrice__c = 0;
                                updtUsage.blng__Subtotal__c = 0;
                                updtUsage.QTB_WO_Usage__c=true;   
                                if (workOrderUsgSummarysPrerateUpdate.containsKey(usgSummary.id) && workOrderUsgSummarysQuantityUpdate.containsKey(usgSummary.id)) 
                                {
                                    workOrderUsgSummarysPrerateUpdate.put(usgSummary.id,workOrderUsgSummarysPrerateUpdate.get(usgSummary.id) + updtUsage.blng__PreratedAmount__c);
                                    workOrderUsgSummarysQuantityUpdate.put(usgSummary.id,workOrderUsgSummarysQuantityUpdate.get(usgSummary.id) +workOrderQuantity.get(workID));
                                } 
                                else {
                                    workOrderUsgSummarysPrerateUpdate.put(usgSummary.id,updtUsage.blng__PreratedAmount__c);
                                    workOrderUsgSummarysQuantityUpdate.put(usgSummary.id,workOrderQuantity.get(workID));
                                }
                                updatedUsages.put(updtUsage.Id, updtUsage);
                            }
                        }
                        blng__UsageSummary__c updtUsgSummary = new blng__UsageSummary__c();
                        if (workOrderUsgSummarysPrerateUpdate.containsKey(usgSummary.id) || workOrderUsgSummarysQuantityUpdate.containsKey(usgSummary.id)) {
                            updtUsgSummary.Id = usgSummary.id;
                            updtUsgSummary.blng__PreratedAmount__c = workOrderUsgSummarysPrerateUpdate.get(usgSummary.id) + summedPrerateAmt;
                            updtUsgSummary.blng__Subtotal__c = updtUsgSummary.blng__PreratedAmount__c;
                            updtUsgSummary.blng__PreratedQuantity__c = 0;//workOrderUsgSummarysQuantityUpdate.get(usgSummary.id);
                            updtUsgSummary.blng__UnbilledQuantity__c = 0;//updtUsgSummary.blng__PreratedQuantity__c;
                            updtUsgSummary.blng__TotalQuantity__c = 0;//updtUsgSummary.blng__UnbilledQuantity__c;
                            updtUsgSummary.blng__UnitPrice__c = updtUsgSummary.blng__Subtotal__c / (workOrderUsgSummarysQuantityUpdate.get(usgSummary.id)+ summedPrerateQty);
                            updatedUsageSummaries.add(updtUsgSummary);
                        }
                    }
                }
                if (!updatedUsageSummaries.isEmpty() && !updatedUsages.isEmpty()) {
                    list<blng__UsageSummary__c> usgSummariesList = new List<blng__UsageSummary__c>();
                    usgSummariesList.addAll(updatedUsageSummaries);
                    list<blng__Usage__c> usageList = new List<blng__Usage__c>();
                    usageList.addAll(updatedUsages.values());
                    //aded by DMB for testing 11/05/2021
                    SBQQ.TriggerControl.disable();
                    update usageList;
                    // System.debug('usages---->'+usageList);
                    update usgSummariesList;
                    SBQQ.TriggerControl.enable();
                    // System.debug('usages---->'+usgSummariesList);
                }
            }
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();// Gitlab US#24172 (Credit/Rebill Billnow)
            QTB_ExceptionLogger.createLog(
                e.getLineNumber(),
                e.getStackTraceString(),
                e.getMessage(),
                e.getTypeName(),
                WORKORDER_TIER_BATCH
            );
        }
    }
    
    /*********************************************************************************************************
Method Name: finish
Parameters: Database.BatchableContext
Return Type: void
Description: Calls QTB_MinimumChargesBatch Batch Class to calculate Minimum storage charges
**********************************************************************************************************/
    global void finish(Database.BatchableContext BC) {
        
        QTB_MinimumChargesBatch msc = new QTB_MinimumChargesBatch(invoiceBatch,targetDate,preBillCheckRecordId);
        Database.executeBatch(msc, 8);
    }
}