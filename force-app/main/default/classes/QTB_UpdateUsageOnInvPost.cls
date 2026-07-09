/*****************************************************************************************************
* Virtusa            08/2022    Git #8540 -- Add logic to update QTB_Invoice_Line_Created_Date__c on the usage records
* Virtusa         11/01/2024    Git #20298/#21830 -- GBP: Analyse the performance of the Usage Update Batch (QTB_UpdateUsageOnInvPost)
*******************************************************************************************************/

Public class QTB_UpdateUsageOnInvPost implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful{
  Public static final string className = QTB_UpdateUsageOnInvPost.class.getName();
  Public static boolean throwExplicitException = false;
  Public String query;
  public static final String POSTED=QTB_Constants.INVOICE_STATUS_POSTED; 
  Public Set<Id> usageIdSet = new Set<Id>();
  Public Set<Id> InvoiceIdSet = new Set<Id>();
  
  Public QTB_UpdateUsageOnInvPost(set<Id> InvIdSet) {
     InvoiceIdSet.addall(InvIdSet);
      system.debug('In start method of batch for InvoiceId '+ InvoiceIdSet);
    query= 'select id,QTB_Invoice_Line_Created_Date__c ' +
            ' from blng__Usage__c where ' +
            ' blng__UsageSummary__r.blng__InvoiceLine__r.blng__InvoiceLineStatus__c =:POSTED ' +
            ' And blng__UsageSummary__r.blng__Invoice__c IN : InvoiceIdSet ';
           
     system.debug('In execute method of batch>>>>>>>>>>1111111111111'+ query);
  }    
   
  /*********************************************************************************************************
  
    Method Name: start
    Parameters: Database.BatchableContext
    Return Type: Iterable
    Requirement: 
    Description: Fetch required records
    **********************************************************************************************************/
  Public Database.QueryLocator start(Database.BatchableContext BC) {
       return Database.getQueryLocator(query);
  }

  /*********************************************************************************************************
    Method Name: execute
    Parameters: Database.BatchableContext,List<Order>
    Return Type: void
    Requirement: 
    Description: Activate billing order where status is Draft.(SG)
    **********************************************************************************************************/
  Public void execute(Database.BatchableContext BC, List<blng__Usage__c> scope) {
    system.debug('In execute method of batch>>>>>>>>>>1111111111111');
    String errorIds = '';
    try {
      if (throwExplicitException) {
          system.debug('NullPointer');
        throw new NullPointerException();
      }
     
            List<blng__Usage__c> Upordlst= new List<blng__Usage__c>();
            for (blng__Usage__c usagtoproc:scope)
            {   
                Datetime now = Datetime.now();
                //Integer offset = UserInfo.getTimezone().getOffset(now);
                //Datetime local = now.addSeconds(offset/1000);
                usagtoproc.QTB_Invoice_Line_Created_Date__c = now;
                Upordlst.add(usagtoproc);
                usageIdSet.add(usagtoproc.id);
            }
        
        if (!Upordlst.isEmpty())
        {
       update Upordlst;
        }
           
        
            system.debug('---------------'+ Upordlst.size());
                  
      
      } catch (exception e) {
      QTB_ExceptionLogger.enable();
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
      system.debug('Usage updated total:' + usageIdSet.size());
      //if (usageIdSet !=null && !usageIdSet.isEmpty()) {
       //Calling QTB_CalculatePOBalanceBatch to update the PO Balance for the processed invoices
        //Set<ID> ProcessedUsageId = new Set<ID>();
        //ProcessedUsageId.addAll(usageIdSet);
        //Database.executeBatch(new QTB_UpdateInvMRCDates(ProcessedUsageId), 50);
     // }
      
}
}