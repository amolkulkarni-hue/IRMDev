/*****************************************************************************************************
* Class: QTB_BillingOrderProcessBatch 
* Author: Accenture
* Purpose: This is a Batch class for Billing Contract generation
* Requirement: SFCPQBLG-398, SFCPQBLG-295, SFCPQBLG-968
* Change History: 26/08/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              Need to Delete
*******************************************************************************************************/
global class QTB_BillingOrderProcessBatch implements Database.Batchable<SObject>{
    public String query;
    public Database.Error errors;
    public static final string CONTRACT_BATCH ='QTB_BillingOrderProcessBatch';
    public static final QTB_Manage_Contract_Scheduler__c manageCustSettings=QTB_Manage_Contract_Scheduler__c.getInstance(QTB_Constants.GET_FIRST_RECORD);
    /***********************************************************************************************************
* Method : Parameterised Constructor
* Requirement : SFCPQBLG-295
* Author : Accenture
* Description: Used to initaite query string.
**************************************************************************************************************/
    global QTB_BillingOrderProcessBatch(){
        query='select  Id, Status,QTB_Failed_Contracting_Attempts__c,QTB_Hold_Contracting__c,SBQQ__Contracted__c,QTB_Active_Order_Product_Count__c,QTB_No_of_Order_Products__c from Order where Status=\''+QTB_Constants.ACTIVATED_STATUS+'\' AND SBQQ__Contracted__c =False AND QTB_Hold_Contracting__c = False';
    }
    /***********************************************************************************************************
* Method : start
* Parameters: Database.BatchableContext 
* ReturnType: Database.QueryLocator
* Requirement : SFCPQBLG-295
* Author : Accenture
* Description: Used to collect all Actiated Orders in context.
**************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(query);
    }
    /***********************************************************************************************************
* Method : execute
* Parameters: Database.BatchableContext List<SBQQ__Quote__c>
* ReturnType: void
* Requirement : SFCPQBLG-295
* Start Date : 6/5/2020
* Author : Accenture
* Description: Used to process Order to generate  contracts .
**************************************************************************************************************/
    global void execute(Database.BatchableContext bc,List<Order> orderList){
        List<Id> failedOrderIdList=new List<Id>();    
        List<Order> updateOrderList=new List<Order>();
        List<Order> failedOrderList=new List<Order>();
        for(Order temp:orderList){
            if(temp.QTB_Active_Order_Product_Count__c==temp.QTB_No_of_Order_Products__c){
                temp.SBQQ__Contracted__c=True;
                updateOrderList.add(temp);
            }              
        }
        
        if(updateOrderList.size()>0){
            
            Database.SaveResult[] ordUpdateSR = Database.update(updateOrderList,false);
            for(Integer i=0; i < ordUpdateSR.size(); i++) {
                if(!ordUpdateSR.get(i).isSuccess()) {
                    //SFCPQBLG-968 Retry 3 times if there is a failure in batch and then send email
                    updateOrderList[i].QTB_Failed_Contracting_Attempts__c = updateOrderList[i].QTB_Failed_Contracting_Attempts__c + 1;
                    if(updateOrderList[i].QTB_Failed_Contracting_Attempts__c == 3){
                        updateOrderList[i].QTB_Hold_Contracting__c = true;
                        errors =  ordUpdateSR[i].getErrors().get(0);
                        system.debug('Error message-->'+errors.getMessage());
                        failedOrderIdList.add(updateOrderList[i].Id);
                    }
                    updateOrderList[i].SBQQ__Contracted__c = false;
                    failedOrderList.add(updateOrderList[i]);
                }
            }
            if(failedOrderList.size()>0){
              update failedOrderList;
            }
        }
        if(!failedOrderIdList.isEmpty()){
            //QTB_RenewalBillingBatchHelper.sendErrorLogMail(failedOrderIdList,QTB_Constants.CONTRACT_STRING);
           if(errors.getMessage() != NULL){
                QTB_ExceptionLogger.createLog(0,'',errors.getMessage(),'',CONTRACT_BATCH); 
          }
        }
    }
    /***********************************************************************************************************
* Method : finish
* Parameters: Database.BatchableContext
* ReturnType: void
* Requirement : SFCPQBLG-295
* Start Date : 6/5/2020
* Author : Accenture
* Description: Used to invoke scheduled apex after hold time
**************************************************************************************************************/
    global void finish(Database.BatchableContext bc){
        if(manageCustSettings.QTB_Contract_Schedueler_On__c)
            scheduleForNextRun();
    }
    
    public void scheduleForNextRun(){
        System.schedule('QTB_ContractBatch'+System.now(),QTB_RenewalBillingBatchHelper.setHoldTime(Integer.ValueOf(manageCustSettings.QTB_Scheduler_Hold_Time_In_Min__c)),new QTB_ScheduleBillingOrderProcess());
    }
}