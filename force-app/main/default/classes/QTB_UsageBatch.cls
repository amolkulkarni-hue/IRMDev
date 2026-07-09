/*****************************************************************************************************
* Class: QTB_UsageBatch
* Author: Accenture
* Purpose: This is a Batch class 
* Requirement: 
* Change History: 6/17
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*             6/16/2020
*******************************************************************************************************/
global class QTB_UsageBatch implements Database.Batchable<sObject>,Database.AllowsCallouts {
    
    private static final String CLASSNAME = QTB_UsageBatch.class.getName();
    public static Final String ERROR1 = QTB_Constants.USAGE_STATUS_WARNING_UNRATED;
    public static Final String ERROR2 =QTB_Constants.USAGE_STATUS_ERROR;
    public static List<QTB_Field_Mapping__mdt> metadatas= new List<QTB_Field_Mapping__mdt>();
	public static boolean throwExplicitException = false;    
    
    /*********************************************************************************************************
    Method Name: start
    Parameters: Database.BatchableContext
    Return Type: Database.QueryLocator
    Requirement: 
    Description: 
    **********************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext BC){ 
        String finalQuery='';
        metadatas = QTB_Utils.GetFieldMapMetadata('blng__Usage__c', 'QTB_Usage_Suspense__c','Usage');
        if(!metadatas.isEmpty()){
            finalQuery= QTB_Utils.ReturnSourceRecordQuery(metadatas) + ' where (blng__Status__c =:ERROR1 OR blng__Status__c=:ERROR2)';
        }
        return Database.getQueryLocator(finalQuery);
    }
    
    /*********************************************************************************************************
    Method Name: execute
    Parameters: Database.BatchableContext,List<blng__Invoice__c>
    Return Type: void
    Requirement: 
    Description: 
    **********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<blng__Usage__c> scope){
        try{
            String errorMessage='';
            if(throwExplicitException){
                throw new NullPointerException();
            }
            if(!scope.isEmpty()){
                Database.DeleteResult[] usageDeleteSR = Database.Delete(scope,false);
                for(Integer i=0; i < usageDeleteSR.size(); i++) {
                    if (!usageDeleteSR[i].isSuccess()) {
                        errorMessage += ';;Usage with Id-'+scope[i].Id+' Error is::'+usageDeleteSR[i].getErrors()[0].getMessage();
                    }
                }
                system.debug('errorMessage-->'+errorMessage);
                if(errormessage != ''){
                    if(errormessage.length()>100000){errormessage = errormessage.substring(0,100000);}
                    QTB_ExceptionLogger.createLog(1,'Errored Usage Deletion Failed',errormessage,'',CLASSNAME);         
                }
            }
        }
        catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
        }
    }
    
    /*********************************************************************************************************
    Method Name: finish
    Parameters: Database.BatchableContext
    Return Type: void
    Requirement: 
    Description: No Action required
    **********************************************************************************************************/
    global void finish(Database.BatchableContext BC){
        //no action
    }
    
}