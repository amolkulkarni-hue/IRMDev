/*****************************************************************************************************
* Class: QTB_UsageSuspenseBatchables
* Author: Virtusa
* Purpose: This class is used to delete the UsageSuspenseRecords 
* Requirement: Deletion of UsageSuspenseRecords when the QTB_Mediation_Status__c is processed.
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*             11/17/2023
*******************************************************************************************************/
global class QTB_UsageSuspenseBatchables implements Database.Batchable<SObject>{
    
    global Database.QueryLocator start(Database.BatchableContext context) {
        
        return Database.getQueryLocator(
            'SELECT Id from QTB_Usage_Suspense__c WHERE QTB_Mediation_Status__c=\'Processed\'');
        
    }
    global void execute(Database.BatchableContext context ,List<QTB_Usage_Suspense__c> UsageSuspense)
        
    {    
         
        try{
                      
         //Deleting the UsageSuspenseRecordsID's              
            if(UsageSuspense.size()>0)
            {
                Database.deleteResult[] usageSuspenseList = Database.delete(UsageSuspense,false);   
            }
                        
        }
        catch(exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_UsageSuspenseBatchables');
        }
        
        
    }
    
    global void finish(Database.BatchableContext BC)
    {
        
    }
    
}