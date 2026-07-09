/*****************************************************************************************************
 * Class:  
 * Author: Accenture
 * Purpose: This is a handler class for all business logic related to Order object
 * Requirement:
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *              27/5/2020
 *******************************************************************************************************/
public with sharing class QTB_OrderTriggerHandler implements ITriggerHandler {
  public static final String DELIMITERS = '[;,]';
  public static boolean throwExplicitException = false;
  /*****************************************************************************************************************
   * Author:      Accenture
   * Date:        27-05-2020
   * Parameters:  None
   * Return:      void
   * Description: Method is used to disable trigger execution from custom setting- Metadata_Activation_Settings__c
   *****************************************************************************************************************/
  public Boolean IsDisabled() {
    Boolean isTriggerDisabled = false;
    Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
    if (
      (custSetting != null &&
      ((String.isBlank(custSetting.SObject_API_Name__c) &&
      custSetting.Disable_Trigger__c) ||
      (String.isNotBlank(custSetting.SObject_API_Name__c) &&
      custSetting.SObject_API_Name__c.split(DELIMITERS)
        .contains(QTB_Constants.SOBJECT_ORDER) &&
      custSetting.Disable_Trigger__c)))
    ) {
      isTriggerDisabled = true;
    }
    return isTriggerDisabled;
  }

  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        27-05-2020
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for before insert event on the Order object.
   ********************************************************************************************************************/
  public void BeforeInsert(List<SObject> newItems) {
    // QTB_OrderHelper.setOrderTypeValue(newItems);
    QTB_OrderHelper.trigController(newItems, null, Trigger.OperationType);
  }

  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        27-05-2020
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for before update event on the Order object.
   ********************************************************************************************************************/
  public void BeforeUpdate(
    Map<Id, SObject> newItems,
    Map<Id, SObject> oldItems
  ) {
    QTB_OrderHelper.trigController(
      newItems.values(),
      (Map<Id, Order>) oldItems,
      Trigger.OperationType
    );
  }

  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        27-05-2020
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for before delete event on the Order object.
   ********************************************************************************************************************/
  public void BeforeDelete(Map<Id, SObject> oldItems) {
    //no action
  }

  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        27-05-2020
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for after insert event on the Order object.
   ********************************************************************************************************************/
    public void AfterInsert(List<SObject> newItems) {
        /*******************************************************************************************************************
* Author:      Virtusa
* Developer:   Suresh Uppala
* Date:        18-05-2021
* Story Number: #471
* Description: when order is created and sending the orderId to this QTB_S26_SendAccinfo from this we are sending the information to fire base
********************************************************************************************************************/

       List<Order> listOrd = (List<Order>) newItems;
        set<Id> quoteIdSet = new set<Id>();
        Map<id,id> QuoteOrdermap = new Map<id,id>();
        // Iterate all orders
        for(Order sObjOrd : listOrd){
            QuoteOrdermap.put(sObjOrd.SBQQ__Quote__c,sObjOrd.id);
        }
        system.debug('QuoteOrdermap>>>>'+QuoteOrdermap);
        //Get all the QuoteLines with respect to Quotes/Orders & check the Sierra 26 PPL
        List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id,SBQQ__Quote__c,SBQQ__Product__r.Name,SBQQ__Product__r.Family 
                                                  FROM SBQQ__QuoteLine__c where SBQQ__Product__r.Family=: Label.QTB_S26_Family AND 
                                                  SBQQ__Quote__c IN: QuoteOrdermap.keySet() ];
        
        
        if(quoteLineList.size()>0){
            //Iterate  all QuoteLine and get the Quotes
            for(SBQQ__QuoteLine__c ql : quoteLineList){
                quoteIdSet.add(ql.SBQQ__Quote__c);
            }
            system.debug('quoteIdSet>>>>>>'+quoteIdSet);
            //Iterate  all Quote Ids and get the Respective Orders
            for(Id quoteId : quoteIdSet){
                QTB_S26_SendAccinfo.Sierra26_SendAccData(QuoteOrdermap.get(quoteId));
            }
        }
    }
    
  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        27-05-2020
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for after update event on the Order object.
   ********************************************************************************************************************/
  public void AfterUpdate(
    Map<Id, SObject> newItems,
    Map<Id, SObject> oldItems
  ) {
    QTB_OrderHelper.trigController(
      newItems.values(),
      (Map<Id, Order>) oldItems,
      Trigger.operationType
    );
  }

  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        27-05-2020
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for after delete event on the Order object.
   ********************************************************************************************************************/
  public void AfterDelete(Map<Id, SObject> oldItems) {
    //no action
  }

  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        27-05-2020
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for after undelete event on the Order object.
   ********************************************************************************************************************/
  public void AfterUndelete(Map<Id, SObject> oldItems) {
  }
}