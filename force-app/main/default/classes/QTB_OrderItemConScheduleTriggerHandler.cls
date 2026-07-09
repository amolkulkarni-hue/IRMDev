/*****************************************************************************************************
 * Class: QTB_OrderItemConScheduleTriggerHandler 
 * Author: Virtusa
 * Purpose: This is a handler class for all business logic related to SBQQ__OrderItemConsumptionSchedule__c object
 * Requirement:
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *              08/25/2024
 *******************************************************************************************************/

public with sharing class QTB_OrderItemConScheduleTriggerHandler implements ITriggerHandler {
    public static final String DELIMITERS = '[;,]';
    public static boolean throwExplicitException = false;
   /*****************************************************************************************************************
   * Author:      Virtusa
   * Date:        08/25/2024
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
        .contains('SBQQ__OrderItemConsumptionSchedule__c') &&
      custSetting.Disable_Trigger__c)))
    ) {
      isTriggerDisabled = true;
    }
    return isTriggerDisabled;
  }   
    
    
    /*******************************************************************************************************************
* Author:  Virtusa
* Date:    08/25/2024
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for before insert event on the SBQQ__OrderItemConsumptionSchedule__c object.
********************************************************************************************************************/
  public void BeforeInsert(List<SObject> newItems) {
    QTB_OrderItemConsumptionScheduleHelper.trigController(newItems,null,Trigger.OperationType);    
  }
  
  /*******************************************************************************************************************
   * Author:      Virtusa
   * Date:        08/25/2024
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for before update event on the SBQQ__OrderItemConsumptionSchedule__c object.
   ********************************************************************************************************************/
  public void BeforeUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) { 
    
  }

   /*******************************************************************************************************************
   * Author:      Virtusa
   * Date:        08/25/2024
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for before delete event on the SBQQ__OrderItemConsumptionSchedule__c object.
   ********************************************************************************************************************/
  public void BeforeDelete(Map<Id, SObject> oldItems) {
    //no action
  }
    
  /*******************************************************************************************************************
   * Author:      Virtusa
   * Date:        08/25/2024
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for after insert event on the SBQQ__OrderItemConsumptionSchedule__c object.
   ********************************************************************************************************************/
    public void AfterInsert(List<SObject> newItems) {
    }
    
      /*******************************************************************************************************************
   * Author:      Virtusa
   * Date:        08/25/2024
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for after update event on the SBQQ__OrderItemConsumptionSchedule__c object.
   ********************************************************************************************************************/
  public void AfterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems) {
  
  }
    
   /*******************************************************************************************************************
   * Author:      Virtusa
   * Date:        08/25/2024
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for after delete event on the SBQQ__OrderItemConsumptionSchedule__c object.
   ********************************************************************************************************************/
  public void AfterDelete(Map<Id, SObject> oldItems) {
    //no action
  }

  /*******************************************************************************************************************
   * Author:      Virtusa
   * Date:        08/25/2024
   * Parameters:  None
   * Return:      void
   * Description: This method is used to handle business logic for after undelete event on the SBQQ__OrderItemConsumptionSchedule__c object.
   ********************************************************************************************************************/
  public void AfterUndelete(Map<Id, SObject> oldItems) {
  }
    
}