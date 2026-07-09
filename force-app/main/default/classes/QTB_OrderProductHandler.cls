/*****************************************************************************************************
 * Class: QTB_OrderProductHandler
 * Author: Accenture
 * Purpose: This is a handler class for all business logic related to OrderProduct object
 * Requirement:
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *              27/5/2020
 *******************************************************************************************************/
public with sharing class QTB_OrderProductHandler implements ITriggerHandler {
  public static final String DELIMITERS = '[;,]';
  public static final String className = 'QTB_OrderProductHandler';
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
      custSetting != null &&
      ((String.isBlank(custSetting.SObject_API_Name__c) &&
      custSetting.Disable_Trigger__c) ||
      (String.isNotBlank(custSetting.SObject_API_Name__c) &&
      custSetting.SObject_API_Name__c.split(DELIMITERS)
        .contains(QTB_Constants.SOBJECT_ORDERPRODUCT) &&
      custSetting.Disable_Trigger__c))
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
   * Description: This method is used to handle business logic for before insert event on the OrderProduct object.
   ********************************************************************************************************************/
  public void BeforeInsert(List<SObject> newItems) {
    QTB_OrderProductHelper.trigController(
      newItems,
      null,
      Trigger.OperationType
    );
  }

  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        27-05-2020
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for before update event on the OrderProduct object.
   ********************************************************************************************************************/
  public void BeforeUpdate(
    Map<Id, SObject> newItems,
    Map<Id, SObject> oldItems
  ) {
    QTB_OrderProductHelper.trigController(
      newItems.values(),
      (Map<Id, OrderItem>) oldItems,
      Trigger.operationtype
    );
  }

  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        27-05-2020
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for before delete event on the OrderProduct object.
   ********************************************************************************************************************/
  public void BeforeDelete(Map<Id, SObject> oldItems) {
    //no Action
  }

  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        27-05-2020
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for after insert event on the OrderProduct object.
   ********************************************************************************************************************/
  public void AfterInsert(List<SObject> newItems) {
     QTB_OrderProductHelper.trigController(newItems,null,Trigger.OperationType);
  }

  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        27-05-2020
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for after update event on the OrderProduct object.
   ********************************************************************************************************************/
  public void AfterUpdate(
    Map<Id, SObject> newItems,
    Map<Id, SObject> oldItems
  ) {
       QTB_OrderProductHelper.trigController( newItems.values(),(Map<Id, OrderItem>) oldItems,Trigger.OperationType);
  }

  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        27-05-2020
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for after delete event on the OrderProduct object.
   ********************************************************************************************************************/
  public void AfterDelete(Map<Id, SObject> oldItems) {
    //no Action
  }

  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        27-05-2020
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for after undelete event on the OrderProduct object.
   ********************************************************************************************************************/
  public void AfterUndelete(Map<Id, SObject> oldItems) {
    //no Action
  }
}