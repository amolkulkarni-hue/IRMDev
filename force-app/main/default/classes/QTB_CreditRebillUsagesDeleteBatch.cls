/*****************************************************************************************************
* Class         : QTB_CreditRebillUsagesDeleteBatch
* Test Class    : QTB_CreditRebillUsagesDeleteBatch_Test
* Author        : IRM/Virtusa
* Purpose       : This class handle deletion of usages, usageSummary & OrderProduct for bulk usages
* Requirement   : Initial Story - Gitlab US #9256 Credit & Rebill
* Change History: 
* Developer            Date           Description
* -----------------------------------------------------------------------------------------------------
* Shailesh       12/12/2023        Credit & Rebill -- Defect fix #19900 -- for bulk usage deletion
*******************************************************************************************************/
public class QTB_CreditRebillUsagesDeleteBatch implements Database.Batchable<sObject> {
    
    public Set<Id> orderProductIdSet = new Set<Id>();
    public static final String QTB_CreditRebillUsagesDeleteBatch = 'QTB_CreditRebillUsagesDeleteBatch';  

    /*********************************************************************************************************
Method Name: QTB_CreditRebillUsagesDeleteBatch()
Parameters : Database.BatchableContext,List<blng__Usage__c>
Return Type: void
Description: QTB_CreditRebillUsagesDeleteBatch() constructor is used for setting orderProductIdSet
**********************************************************************************************************/    
    public QTB_CreditRebillUsagesDeleteBatch(Set<Id> ordPrdIdSet){
        if(ordPrdIdSet != null){
          orderProductIdSet.addAll(ordPrdIdSet);  
        }
    }

    /*********************************************************************************************************
Method Name: start
Parameters : Database.BatchableContext
Return Type: Database.QueryLocator
Description: start() method is responsible to fetch all usages wrt orderProductIds
**********************************************************************************************************/    
    public Database.QueryLocator start(Database.BatchableContext bc){  
        if(!orderProductIdSet.isEmpty() && orderProductIdSet != null ){
            String usgQuery = 'SELECT Id FROM blng__Usage__c WHERE blng__OrderProduct__c IN : orderProductIdSet';
            return Database.getQueryLocator(usgQuery);   
        }
        return null;    	
    }

    /*********************************************************************************************************
Method Name: execute
Parameters : Database.BatchableContext,List<blng__Usage__c>
Return Type: void
Description: execute() method is responsible for deletion of usages
**********************************************************************************************************/    
    public void execute(Database.BatchableContext bc,List<blng__Usage__c> usageList){
        try{
            if(!usageList.isEmpty() && usageList != null){
                SBQQ.TriggerControl.disable();
                delete usageList;
                SBQQ.TriggerControl.enable();
            }
        }
        Catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_CreditRebillUsagesDeleteBatch);
        }
    }
    
    /*********************************************************************************************************
Method Name: finish
Parameters : Database.BatchableContext
Return Type: void
Description: finish() method is responsible for deletion of usage summary and order products
**********************************************************************************************************/
    public void finish(Database.BatchableContext bc){
        try{
            if(!orderProductIdSet.isEmpty() && orderProductIdSet != null){
                List<blng__UsageSummary__c> usgSummaryList = [SELECT Id FROM blng__UsageSummary__c WHERE blng__OrderProduct__c IN :orderProductIdSet];
                SBQQ.TriggerControl.disable();
                //delete usage summary
                if(!usgSummaryList.isEmpty() && usgSummaryList.size() > 0){
                    delete usgSummaryList;
                }
                
                List<OrderItem> orderProductlist = [SELECT Id FROM OrderItem WHERE Id IN: orderProductIdSet];
                //delete Order Products
                if(!orderProductlist.isEmpty() && orderProductlist.size() > 0){
                    delete orderProductlist;
                }
                SBQQ.TriggerControl.enable();
            }
        }
        Catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),QTB_CreditRebillUsagesDeleteBatch);
        }
    }
}