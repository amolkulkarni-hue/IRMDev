/*****************************************************************************************************
 * Class: QTB_NewBillingDatacleanBatch
 * Author: Virtusa
 * Purpose: This is a Batch class to clean non used Usage Summary (cloned from QTB_BillingDatacleanBatch)
 * Requirement: GIT# 19121
 * Change History: NA
 * Developer         Date           Description
 * -------------------------------------------------------------------------------------------
 * 17/10/2023     This is a Batch class to clean non used Usage Summary by passing Country and record limit parameters
 *******************************************************************************************************/
Public class QTB_NewBillingDatacleanBatch implements Database.Batchable<SObject>
{
  Public static final string className = QTB_NewBillingDatacleanBatch.class.getName();
  Public static boolean throwExplicitException = false;
  Public String query; 
  Public String LegalEntityCountry;
  Public integer RecSize;
  Public Date SummaryEndDate;
  //Public Set<Id> usIdSet = new Set<Id>();
  Public QTB_NewBillingDatacleanBatch(String accCountry,Date EndDate,Integer recds) {
      LegalEntityCountry = accCountry;
      SummaryEndDate = EndDate;
      RecSize = recds;
      query= 'select id  ' +
            ' from blng__UsageSummary__c where ' +
            ' blng__Status__c=\''+QTB_Constants.STATUS_NEW+'\' AND ' +
            ' blng__SummaryEndDate__c <=: SummaryEndDate AND' +
            ' QTB_Legal_Entity_Country__c=:LegalEntityCountry AND'+
            ' blng__TotalQuantity__c = NULL LIMIT :RecSize';
          
             // ' Order.RecordTypeId=\''+QTB_Constants.DRAFT_STATUS+'\' AND ' + 
             //  ' blng__Status__c=:USstatus  AND ' +
             
     system.debug('In execute method of batch>>>>>>>>>>1111111111111'+ query);
  }    
   
  /*********************************************************************************************************
  
    Method Name: start
    Parameters: Database.BatchableContext
    Description: Fetch required records
    **********************************************************************************************************/
  Public Database.QueryLocator start(Database.BatchableContext BC) {
       return Database.getQueryLocator(query);
  }

  /*********************************************************************************************************
    Method Name: execute
    Parameters: Database.BatchableContext,List<blng__UsageSummary__c>
    Return Type: void
    Requirement: 
    Description: To delete US.
    **********************************************************************************************************/
  Public void execute(Database.BatchableContext BC, List<blng__UsageSummary__c> scope) {
    system.debug('In execute method of batch>>>>>>>>>>1111111111111');
    String errorIds = '';
    try {
      if (throwExplicitException) {
          system.debug('NullPointer');
        throw new NullPointerException();
      }
     
            List<blng__UsageSummary__c> Upordlst= new List<blng__UsageSummary__c>();
            for (blng__UsageSummary__c usg:scope)
            {
                
                Upordlst.add(usg);
                //usIdSet.add(usg.id);
            }
        
        if (!Upordlst.isEmpty())
        {
       Delete Upordlst;
        }
           
            system.debug('---------------'+ Upordlst.size());
                  
      
      } catch (exception e) {
      errorIds = e.getMessage() + errorIds;
      if (errorIds.length() > 100000)
        errorIds = errorIds.substring(0, 100000);
      system.debug('In catch method of batch 66>>>>>>>>>>');
      system.debug('Error inf::' + errorIds);
      QTB_ExceptionLogger.createLog(
        e.getLineNumber(),
        e.getStackTraceString(),
        errorIds,
        e.getTypeName(),
        className
      );
    }
  }
  /*********************************************************************************************************
    Method Name: finish
    Parameters: Database.BatchableContext
    Return Type: void
    Requirement: 
    Description: No action to be taken
    **********************************************************************************************************/
  Public void finish(Database.BatchableContext BC) {
      //system.debug('Usage Summary Deleted total:' + usIdSet.size());
      
}
}