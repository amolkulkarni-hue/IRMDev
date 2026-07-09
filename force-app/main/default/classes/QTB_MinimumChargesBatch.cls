/*******************************************************************************************************************************************************
* Class: QTB_MinimumChargesBatch
* Author: Accenture
* Requirement: QTB-8b (SFCPQBLG-88)
* Purpose : This is Minimum Storage Charges related to Pre-bill run Process.
* Change History: 06/17/2020
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture   05/06/2020
* Accenture     05/11/2021      GitLab # 1733, prepending the order number to the matching id of minimum
*                               charges usage
*******************************************************************************************************/
 //Ramesh/Abdul 26/07/2024  Gitlab US 24172 (Credit/Rebill Billnow)
global class QTB_MinimumChargesBatch implements Database.Batchable<sObject> {
    //variables
    public string invoiceBatch;
    public date targetDate;
    public Id preBillcheckRecordId;
    public static boolean throwExplicitException = false;
    public static final string MINIMUM_CHARGES_BATCH = QTB_MinimumChargesBatch.class.getName();
    public static final String PENDING = QTB_Constants.INVOICE_STATUS_PENDING_BILLING;
    public static final String QUEUED_FOR_INVOICE = QTB_Constants.STATUS_QUEUED_FOR_INVOICE;
    public Map<String, Date> mapBatchesToDate = new Map<String, Date>();
    public Set<String> invSchBatch = new Set<String>();
    public static final Id accountBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;

    public string rebillType = '';
    public Set<Id> accountIds = new Set<Id>();
    public Set<Id> rebillOrderIds = new Set<Id>(); // Gitlab US#24172 (Credit/Rebill Billnow)
    public List<QTB_Bill_Flow_Controller__c> billFlowList; // Gitlab US#24172 (Credit/Rebill Billnow)
    
    //constructor
    public QTB_MinimumChargesBatch(string Schedularbatch, Date targtDate, Id prebillFlowRecord){
        mapBatchesToDate.put(Schedularbatch,targtDate);
        invoiceBatch = Schedularbatch;
        targetDate = targtDate;
        preBillcheckRecordId = prebillFlowRecord;
        // Gitlab US#24172 (Credit/Rebill Billnow)
        if(Schedularbatch.containsIgnoreCase('Rebill Run')){            
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
Requirement: SFCPQBLG-88
Description: Query required records
**********************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC) {
        invSchBatch.addAll(mapBatchesToDate.keySet());
        System.debug(invSchBatch);
        
        if (Test.isRunningTest()) {
            mapBatchesToDate.put('Norway-26th', date.newInstance(2021, 1, 27));
            invSchBatch.add('Norway-26th');
        }
        String query;
        //Gitlab US#22511 -- instead of equals to change to contains of "Rebill Run"
        //For Rebill
        if(invoiceBatch.containsIgnoreCase('Rebill Run'))
        { 
            //As part of GITLAB #16257 added if check for split rebill type , for Split rebill We don't need to run execute method so we made the dummy query to return zero records.
            if (rebillType == System.Label.QTB_SplitRebill) {   
                query = 'SELECT id FROM Account WHERE IsDeleted = true AND IsDeleted = false';
            }
            else { 
                query = 'SELECT id,QTB_Records_Management__c,QTB_Minimum_Charges_Start_Date__c,QTB_Minimum_Storage_Charges__c,QTB_Hold_Billing__c,ParentId,QTB_Apply_Minimum_Storage_Charges__c,QTB_Bill_Cycle_Day__c,QTB_Customer_Number__c, CurrencyIsoCode ' +
                    ' FROM Account where Id IN:accountIds AND RecordTypeId=: accountBillRecordTypeId and ParentId != null and QTB_Hold_Billing__c = False and QTB_Apply_Minimum_Storage_Charges__c=True ' +
                    ' and QTB_Records_Management__c=True and QTB_Minimum_Charges_Start_Date__c<=TODAY';  
            }
        }
        //For Regualr invoice we have invoice schedular
        else{
            query =
                'SELECT id,QTB_Records_Management__c,QTB_Minimum_Charges_Start_Date__c,QTB_Minimum_Storage_Charges__c,QTB_Hold_Billing__c,ParentId,QTB_Apply_Minimum_Storage_Charges__c,QTB_Bill_Cycle_Day__c,QTB_Customer_Number__c,CurrencyIsoCode ' +
                ' FROM Account where RecordTypeId=: accountBillRecordTypeId and ParentId != null and QTB_Hold_Billing__c = False and QTB_Apply_Minimum_Storage_Charges__c=True and QTB_Bill_Cycle_Day__c IN :invSchBatch ' +
                ' and QTB_Records_Management__c=True and QTB_Minimum_Charges_Start_Date__c<=TODAY'; 
        }
        return Database.getQueryLocator(query);
    }
    /*********************************************************************************************************
Method Name: execute
Parameters: Database.BatchableContext,List<blng__UsageSummary__c>
Return Type: void
Requirement: SFCPQBLG-88
Description: Calculates Minimum Charges for a Billing Account
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
                Map<ID, Account> relatedAccs = new Map<ID, Account>();
                set<id> accountIDs = new Set<id>();
                map<id, double> total = new Map<id, double>();
                List<blng__Usage__c> usg = new List<blng__Usage__c>();
                
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
                    ' blng__Order__r.blng__InvoiceBatch__c,blng__Account__c,blng__Account__r.QTB_Minimum_Storage_Charges__c, '+
                    ' blng__Subtotal__c,blng__SummaryStartDate__c,blng__SummaryEndDate__c,blng__UnitPrice__c,blng__MatchingAttribute__c '+ 
                    ' FROM blng__UsageSummary__c WHERE '+
                    ' blng__OrderProduct__r.Product2.QTB_Storage_Product__c = TRUE '+
                    ' AND blng__Subtotal__c != NULL '+
                    ' AND blng__Subtotal__c > 0 '+
                    ' AND blng__OrderProduct__r.SBQQ__Activated__c = TRUE '+
                    ' AND blng__Status__c = :QUEUED_FOR_INVOICE ';
                // Gitlab US#24172 (Credit/Rebill Billnow)
                if(invoiceBatch.containsIgnoreCase('Rebill Run')){
                    usgSummary+= ' AND blng__Order__c IN: rebillOrderIds ';



                }else{
                    Set<id> ids = relatedAccs.keySet();
                    usgSummary+= ' AND blng__InvoiceRunProcessingStatus__c = :PENDING AND blng__Account__c IN :ids';

                }
                
                List<blng__UsageSummary__c> usgSumList = Database.query(usgSummary);
                
                List<blng__UsageSummary__c> usegeSumlistForMiniCharge = new  List<blng__UsageSummary__c>();
                Set<Id> orderIds = new Set<Id>();
                if(usgSumList != null && !usgSumList.isEmpty()){
                    for(blng__UsageSummary__c usgsumm : usgSumList){
                        if(usgsumm.blng__Order__c != null){
                            orderIds.add(usgsumm.blng__Order__c); 
                        }
                    }
                    if(orderIds != null && !orderIds.isEmpty()){
                        usegeSumlistForMiniCharge = [SELECT id,blng__MatchingAttribute__c 
                                                     From blng__UsageSummary__c 
                                                     WHERE blng__Order__c IN :orderIds AND
                                                     blng__OrderProduct__r.QTB_Product_Name__c = 'Minimum Storage Charges']; 
                    }
                }
                system.debug('Minimum Charges usgSumList '+usgSumList);
                if(!usgSumList.isEmpty() && usgSumList.size() > 0){
                    for (blng__UsageSummary__c eachAccountUS :usgSumList) {
                        /* GitLab # 1733 Stand */
                        billedOrderNumberByAccountId.put(
                            eachAccountUS.blng__Account__c,
                            eachAccountUS.blng__OrderProduct__r.QTB_PrefixMatchingID__c <> null ?
                            eachAccountUS.blng__OrderProduct__r.QTB_PrefixMatchingID__c : ''
                        );
                        if(usegeSumlistForMiniCharge !=null && !usegeSumlistForMiniCharge.isEmpty()){
                            accountIdWithUsgSumMatchingAttributeMap.put(eachAccountUS.blng__Account__c,usegeSumlistForMiniCharge[0].blng__MatchingAttribute__c);
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
                            // System.debug('inside slecetd storage usgsummary');
                            total.put(
                                eachAccountUS.blng__Account__c,
                                eachAccountUS.blng__Subtotal__c
                            );
                        }
                    }
                }
                //System.debug('Account map--->'+total);
                //Loop to Compare total Map with the Minimum Storage Charge on Billing Account
                //and Create Usage for Minimum Charges Product accordingly
                if (total != null) {
                    for (Id acc : total.keySet()) {
                        if (
                            relatedAccs != null &&
                            relatedAccs.containsKey(acc) &&
                            total.get(acc) > 0 &&
                            total.get(acc) <
                            relatedAccs.get(acc).QTB_Minimum_Storage_Charges__c
                        ) {
                            date insertDate;
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
                                LABEL.QTB_Minimum_Storage;
                            usage.blng__MatchingAttribute__c = accountIdWithUsgSumMatchingAttributeMap.get(acc);
                            usage.blng__StartDateTime__c = endDateTime;
                            usage.blng__EndDateTime__c = endDateTime;
                            usage.blng__PreratedAmount__c =
                                relatedAccs.get(acc).QTB_Minimum_Storage_Charges__c -
                                total.get(acc);
                            usage.QTB_System_Generated__c = true;
                            usage.QTB_Invoice_Quantity__c = 1;
                            usage.CurrencyIsoCode = relatedAccs.get(acc).CurrencyIsoCode;
                            usg.add(usage);
                            //System.debug('Usage---->'+usage);
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
                            'Storage Minimum Usage Insert Failed',
                            errorMessage,
                            '',
                            MINIMUM_CHARGES_BATCH
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
                MINIMUM_CHARGES_BATCH
            );
        }
    }
    /*********************************************************************************************************
Method Name: finish
Parameters: Database.BatchableContext
Return Type: Void
Requirement: SFCPQBLG-88
Description: Calls QTB_FuelSurchargesBatch Batch Class to Calculate Fuel Surcharges for Usages
**********************************************************************************************************/
    global void finish(Database.BatchableContext BC) {
        
        //QTB_InvoiceMinimumBatch qtb = new QTB_InvoiceMinimumBatch(invoiceBatch,targetDate,preBillcheckRecordId);
        //Database.executeBatch(qtb, 5);
        //Added new Batch class for Calculating Fuel Surcharges US#2719
        QTB_FuelSurchargesBatch qtb = new QTB_FuelSurchargesBatch(invoiceBatch,targetDate,preBillcheckRecordId);
        Database.executeBatch(qtb, 5);
    }
}