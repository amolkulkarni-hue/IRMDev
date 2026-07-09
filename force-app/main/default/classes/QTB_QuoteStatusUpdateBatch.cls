/*****************************************************************************************************
* Class: QTB_QuoteStatusUpdateBatch 
* Author: Accenture
* Purpose: This is a batch class to set Quote status to Expired when Pricing expiration Date <= today's date
* Requirement: CPQ-43
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*             30/4/2020
*******************************************************************************************************/
global class QTB_QuoteStatusUpdateBatch implements Database.Batchable<sObject>{

   public static boolean throwExplicitException = false;
   Date currentDate = Date.today();
     /*********************************************************************************************************
    Method Name: start
    Parameters: Database.BatchableContext
    Return Type: Database.QueryLocator
    Requirement: SFCPQBLG-40
    Description: Query required records
    **********************************************************************************************************/
   global Database.QueryLocator start(Database.BatchableContext BC){
      String approvedStatus = QTB_constants.APPROVED_STATUS ;  
      String Query;
      Query ='SELECT Id, RecordTypeId,SBQQ__Status__c, QTB_Pricing_Expiration_Date__c '  
              +'FROM SBQQ__Quote__c '+ 
              'where QTB_Pricing_Expiration_Date__c<=:currentDate and SBQQ__Status__c =: approvedStatus ';
       return Database.getQueryLocator(Query);
    }
      /*********************************************************************************************************
    Method Name: execute
    Parameters: Database.BatchableContext,List<SBQQ__Quote__c>
    Return Type: void
    Requirement: SFCPQBLG-40
    Description: Sets the quote status to expired
    **********************************************************************************************************/
    global void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> listOfQuotes)
    {
       try
        {
            if(listOfQuotes!= null && !listOfQuotes.isEmpty()){
                for(SBQQ__Quote__c quotes: listOfQuotes){
                     quotes.SBQQ__Status__c= QTB_constants.QUOTE_EXPIRED_STATUS ;
                     }
                }  
                   update listOfQuotes;
                     if(throwExplicitException){
                throw new NullPointerException();
            }
             }
        catch(Exception e){
                QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(),
                                              QTB_QuoteStatusUpdateBatch.class.getname());
            }                   
    }
      /*********************************************************************************************************
    Method Name: finish
    Parameters: Database.BatchableContext
    Return Type: void
    Requirement: SFCPQBLG-40
    Description: No action to be taken
    **********************************************************************************************************/
     global void finish(Database.BatchableContext BC){
            
       
        }
}