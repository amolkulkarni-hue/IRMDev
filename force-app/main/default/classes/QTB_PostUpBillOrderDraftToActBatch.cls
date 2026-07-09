/*****************************************************************************************************
 * Class:   QTB_PostUpBillOrderDraftToActBatch
 * Author: Virtusa
 * Purpose: This is a Batch class to Activate billing order/OrderItems.
 *  Where status is Draft (For sg Billing only Countries).
 * Requirement: 
 * Change History: 
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *             011/27/2021
 *******************************************************************************************************/
global class QTB_PostUpBillOrderDraftToActBatch implements Database.Batchable<SObject>,Database.Stateful
{
  global static final string className = QTB_PostUpBillOrderDraftToActBatch.class.getName();
  global static boolean throwExplicitException = false;
  global String query; 
  global Set<Id> RecordTypeIdSet = new Set<Id>();  
  global Set<Id> orderIdSet = new Set<Id>();
  global Set<Id> orderIdSetAsParam = new Set<Id>();
  global Set<String> CountrySet = new Set<String>();
  global List<Order> currntOrder = new List<Order>();
 
  global QTB_PostUpBillOrderDraftToActBatch(Set<Id> OrderToProcessID) {
    currntOrder = [Select id,bling_Legal_Entity__c,QTB_Legal_Entity_Country__c from order Where id IN:OrderToProcessID LIMIT 1];
    orderIdSetAsParam.addAll(OrderToProcessID);
    RecordTypeIdSet.add(Schema.SObjectType.Order.getRecordTypeInfosByName().get('Billing Order').getRecordTypeId());
    //QTB_Billing_Countries__c Billcust = QTB_Billing_Countries__c.getInstance(currntOrder);
    CountrySet.add(currntOrder[0].QTB_Legal_Entity_Country__c);
         
    query=
            ' Select Id,Status,QTB_Legal_Entity_Country__c ' +
            ' FROM Order where' +
            ' Order.Status=\''+QTB_Constants.DRAFT_STATUS+'\' AND ' + 
            ' Order.QTB_Legal_Entity_Country__c IN :CountrySet AND' +
            ' Order.id IN : orderIdSetAsParam AND' +
            ' Order.RecordTypeID IN :RecordTypeIdSet'; 
     system.debug('In execute method of batch>>>>>>>>>>1111111111111'+ query);
  }    
  /*********************************************************************************************************
  
    Method Name: start
    Parameters: Database.BatchableContext
    Return Type: Iterable
    Requirement: 
    Description: Fetch required records
    **********************************************************************************************************/
  global Database.QueryLocator start(Database.BatchableContext BC) {
       return Database.getQueryLocator(query);
  }

  /*********************************************************************************************************
    Method Name: execute
    Parameters: Database.BatchableContext,List<Order>
    Return Type: void
    Requirement: 
    Description: Activate billing order where status is Draft.(SG)
    **********************************************************************************************************/
  global void execute(Database.BatchableContext BC, List<Order> scope) {
    system.debug('In execute method of batch>>>>>>>>>>1111111111111');
    String errorIds = '';
    try {
      if (throwExplicitException) {
          system.debug('NullPointer');
        throw new NullPointerException();
      }
       List<Order> OrdersToUpdate = new List<Order>();
       for(Order ord: scope)
         {
             ord.Status='Activated'; 
             OrdersToUpdate.add(ord);
             orderIdSet.add(ord.id);
         }
      if (!OrdersToUpdate.isEmpty())
         {
        Update OrdersToUpdate;
         }
       system.debug('Orders updated total' + OrdersToUpdate);
      
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
  global void finish(Database.BatchableContext BC) {
      system.debug('in finish==========');
       String errorIds = '';
      try {
      if (throwExplicitException) {
          system.debug('NullPointer');
        throw new NullPointerException();
      } 
      if (!orderIdSet.isEmpty())
         {
         system.debug('Orders updated IDs' + orderIdSet);    
         system.debug('Orders updated total#########' + orderIdSet.size());     
         }   
      }
   catch (exception e) {
      errorIds = e.getMessage() + errorIds;
      if (errorIds.length() > 100000)
        errorIds = errorIds.substring(0, 100000);
      system.debug('In catch method of batch Finish>>>>>>>>>>');
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
}