/**
* Class: OpportunityTriggerHandler 
*
* Author: Vinutha Iyengar
*
* Date Created: 01.06.2020
*
* Purpose: ExceptionLogger is used to catch all eception and add it to the Exception_Log__c object
* 
*/
public without sharing class ExceptionLogger {
    
    public static void createLog(Integer lineNumber,String stackTrace,String errorMessage,String exType,String classReference){
        try{
            //Ensure that we're well within the Governor Limits.
            if((Limits.getDMLRows() < Limits.getLimitDMLRows()) && 
               (Limits.getDMLStatements() < Limits.getLimitDMLStatements())){
                   Exception_Log__c exceptionLog = new Exception_Log__c(
                       Class_Reference__c  = classReference,
                       Error_Message__c  = errorMessage,
                       Exception_Type__c  = exType,
                       Line_Number__c  = lineNumber,
                       Stack_Trace__c = stackTrace
                   );
                   
                   Database.insert(exceptionLog, FALSE);
               }
            else{
                System.debug('The Governor Limits have already been exhausted and hence failed to create a Log!');
            }
        }
        catch(DMLException ex){
            System.debug('Something fatal has occurred and hence failed to create a Log! Error:' + ex.getMessage());
        }
    }
    public static void createLogForFailedBatchRecords(List<String> results,String classReference,Integer lineNumber){
        List<Exception_Log__c> exceptionList = new List<Exception_Log__c>();
        try{
            for(String sr :results){
                //Ensure that we're well within the Governor Limits.
                if((Limits.getDMLRows() < Limits.getLimitDMLRows()) && 
                   (Limits.getDMLStatements() < Limits.getLimitDMLStatements())){
                       Exception_Log__c exceptionLog = new Exception_Log__c(
                           Class_Reference__c  = classReference,
                           Error_Message__c  = sr,
                           Exception_Type__c  = 'DML',
                           Line_Number__c  = lineNumber
                           // Stack_Trace__c = err.getMessage();
                       );
                       exceptionList.add(exceptionLog);
                   }else{
                       System.debug('The Governor Limits have already been exhausted and hence failed to create a Log!');
                   }
                
                
                
            }
            if(exceptionList != null && exceptionList.size() > 0){
                insert exceptionList;
            }
        } catch(DMLException ex){
            System.debug('Something fatal has occurred and hence failed to create a Log! Error:' + ex.getMessage());
        }
    }
    
    
}