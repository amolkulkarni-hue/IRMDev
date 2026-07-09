/*****************************************************************************************************
* Class      : QTB_OrderContractingBatch
* Author     : Accenture
* Purpose    : This is a Batch class for Sales Contract generation
* Requirement: Git#8. Gitlab US#20219
* Change History: 26/08/2020 
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Virtusa      12/12/2023     Gitlab US #20219 
*******************************************************************************************************/
global class QTB_OrderContractingBatch implements Database.Batchable<SObject> {
    public String query; 
    public Database.Error errors;
    public static final string CONTRACT_BATCH = 'QTB_OrderContractingBatch';
    public static final QTB_Manage_Contract_Scheduler__c manageCustSettings = QTB_Manage_Contract_Scheduler__c.getInstance(QTB_Constants.GET_FIRST_RECORD);
    public static final Id salesOrderRecType = QTB_Utils.ORDER_SALES_RECTYPEID;
    public boolean throwExplicitException = false;
    
    /***********************************************************************************************************
* Method     :  Constructor
* Description: Used to initaite query string.
**************************************************************************************************************/
    global QTB_OrderContractingBatch() {
        query = 'select  Id, Status,QTB_Failed_Contracting_Attempts__c,QTB_Hold_Contracting__c,SBQQ__Contracted__c,QTB_Active_Order_Product_Count__c,QTB_No_of_Order_Products__c' +
            ' from Order where Status=\'' +QTB_Constants.ACTIVATED_STATUS +'\' AND SBQQ__Contracted__c =False' +
            ' AND RecordTypeId = :salesOrderRecType' +
            ' AND QTB_Hold_Contracting__c = False';
    }
    /***********************************************************************************************************
* Method     : start
* Parameters : Database.BatchableContext
* ReturnType : Database.QueryLocator
* Description: Used to collect all Actiated Orders in context.
**************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    /***********************************************************************************************************
* Method     : execute
* Parameters : Database.BatchableContext List<Order>
* ReturnType : void
* Author     : Accenture
* Description: Used to process Order to generate  contracts .
**************************************************************************************************************/
    global void execute(Database.BatchableContext bc, List<Order> orderList) {
        //List<Id> failedOrderIdList = new List<Id>();
        List<Order> updateOrderList = new List<Order>();
        List<Order> failedOrderList = new List<Order>();
        try{
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            for (Order temp : orderList) {
                if (temp.QTB_Active_Order_Product_Count__c == temp.QTB_No_of_Order_Products__c) {
                    temp.SBQQ__Contracted__c = true;
                    temp.QTB_Contract_Status__c = 'Contract Generated';
                    updateOrderList.add(temp);
                }
                //add this else condition to avoid recurring record processing
                else{
                    temp.QTB_Contract_Status__c = 'Contract Failed';
                    failedOrderList.add(temp);
                }
            }
            
            if(updateOrderList.size() > 0){
                Database.SaveResult[] ordUpdateSR = Database.update(updateOrderList,false);
                for (Integer i = 0; i < ordUpdateSR.size(); i++) {
                    if (!ordUpdateSR.get(i).isSuccess() || Test.isRunningTest()) {
                        //SFCPQBLG-968 Retry 3 times if there is a failure in batch and then send email
                        updateOrderList[i].QTB_Failed_Contracting_Attempts__c = updateOrderList[i].QTB_Failed_Contracting_Attempts__c + 1;
                        if (updateOrderList[i].QTB_Failed_Contracting_Attempts__c == 3) {
                            updateOrderList[i].QTB_Hold_Contracting__c = true;
                            errors = ordUpdateSR[i].getErrors().get(0);
                            system.debug('Error message-->' + errors.getMessage());   
                            //failedOrderIdList.add(updateOrderList[i].Id);
                        }
                        updateOrderList[i].SBQQ__Contracted__c = false;
                        updateOrderList[i].QTB_Contract_Status__c = 'Contract Failed';
                        failedOrderList.add(updateOrderList[i]);
                    }
                }
            }
            if (failedOrderList.size() > 0) {
                update failedOrderList;
            }
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CONTRACT_BATCH);
        }
        /*if (!failedOrderIdList.isEmpty()) {
QTB_RenewalBillingBatchHelper.sendErrorLogMail(failedOrderIdList,QTB_Constants.CONTRACT_STRING);
if (errors.getMessage() != null) {
QTB_ExceptionLogger.createLog(0,'',errors.getMessage(),'',CONTRACT_BATCH);
}
}*/
    }
    /***********************************************************************************************************
* Method : finish
* Parameters: Database.BatchableContext
* ReturnType: void
* Requirement : SFCPQBLG-295 --> Gitlab US#20219
* Start Date : 6/5/2020 -- 12/12/2023
* Author : Accenture -- Virtusa
* Description: Used to invoke scheduled apex after hold time -
: Modified the finish() method, checking if any order is activated and calling the same batch again to reprocess
**************************************************************************************************************/
    global void finish(Database.BatchableContext bc) {
        try{
            if (throwExplicitException) {
                throw new NullPointerException();
            }
            List<Order> orderList = [SELECT  Id, Status,QTB_Failed_Contracting_Attempts__c,QTB_Hold_Contracting__c,SBQQ__Contracted__c,QTB_Active_Order_Product_Count__c,QTB_No_of_Order_Products__c 
                                     FROM Order 
                                     WHERE Status =: QTB_Constants.ACTIVATED_STATUS AND RecordTypeId =: QTB_Utils.ORDER_SALES_RECTYPEID 
                                     AND SBQQ__Contracted__c = False AND QTB_Hold_Contracting__c = False AND QTB_Contract_Status__c = 'Contract Pending'];
            if(!orderList.isEmpty()){
                Integer batchSize = Integer.valueOf(System.Label.QTB_contract_batch_size);
                Database.executeBatch(new QTB_OrderContractingBatch(), batchSize);
            }
        }
        catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CONTRACT_BATCH);
        }
    }
}