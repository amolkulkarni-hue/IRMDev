/*****************************************************************************************************
 * Class: QTB_UsageSummaryTriggerHandler
 * Author: Accenture
 * Purpose: This is a handler class for all business logic related to usage summary object
 * Requirement:
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *              10/06/2020
 * Virtusa		28-10-2025     Gitlab US #19002 code optimization; we changed the case of the methodNames eg BeforeDelet becomes beforeDelete
 *******************************************************************************************************/
public with sharing class QTB_UsageSummaryTriggerHandler implements ITriggerHandler {
  public static final String DELIMITERS = '[;,]';
  public static boolean throwExplicitException = false;
  /*****************************************************************************************************************
   * Author:      Accenture
   * Date:        10-06-2020
   * Parameters:  None
   * Return:      boolean
   * Description: Method is used to disable trigger execution from custom setting- Metadata_Activation_Settings__c
   *****************************************************************************************************************/
  public Boolean isDisabled() {
    Boolean isTriggerDisabled = false;
    Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
    if ( custSetting != null 
    && ((String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c) 
      || (String.isNotBlank(custSetting.SObject_API_Name__c) && custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.SOBJECT_BLNG_USAGE_SUMMARY)
         && custSetting.Disable_Trigger__c))) {
        
          isTriggerDisabled = true;
    }
    return isTriggerDisabled;
  }
  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:       10-06-2020
   * Parameters:  List<Sobject>
   * Return:      void
   * Description: This method is used to handle business logic for before insert event on the usage summary object.
   ********************************************************************************************************************/
  public void beforeInsert(List<SObject> newItems) {
    QTB_UsageSummaryHelper.trigController((List<blng__UsageSummary__c>) newItems,null,Trigger.operationType);
  }

  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        10-06-2020
   * Parameters:  Map<Id,Sobject> newItems, Map<Id,Sobject> oldItems
   * Return:      void
   * Description: This method is used to handle business logic for before update event on the usage summary object.
   ********************************************************************************************************************/
  public void beforeUpdate(Map<Id,SObject> newItems,Map<Id,SObject> oldItems){
    QTB_UsageSummaryHelper.trigController((List<blng__UsageSummary__c>) newItems.values(),
      (Map<Id, blng__UsageSummary__c>) oldItems,Trigger.operationType);
  }
  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:       10-06-2020
   * Parameters:  Map<Id, SObject> oldItems
   * Return:      void
   * Description: This method is used to handle business logic for before delete event on the usage summary object.
   ********************************************************************************************************************/
  public void beforeDelete(Map<Id,SObject> oldItems){
    //no action
  }
  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        10-06-2020
   * Parameters:  List<SObject> newItems
   * Return:      void
   * Description: This method is used to handle business logic for after insert event on the usage summary object.
   ********************************************************************************************************************/
   public void afterInsert(List<SObject> newItems){
    //no action
  }
  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        10-06-2020
   * Parameters:  (Map<Id, SObject> newItems, Map<Id, SObject> oldItems
   * Return:      void
   * Description: This method is used to handle business logic for after update event on the usage summary object.
   ********************************************************************************************************************/
  public void afterUpdate(Map<Id, SObject> newItems,Map<Id, SObject> oldItems){
      // Added logic as per defect US#17768
    QTB_UsageSummaryHelper.trigController((List<blng__UsageSummary__c>) newItems.values(),(Map<Id, blng__UsageSummary__c>) oldItems,
                                          Trigger.operationType);
  }
  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        10-06-2020
   * Parameters:  Map<Id, SObject> oldItems
   * Return:      void
   * Description: This method is used to handle business logic for after delete event on the usage summary object.
   ********************************************************************************************************************/
  public void afterDelete(Map<Id,SObject> oldItems){
    //no action
  }
  /*******************************************************************************************************************
   * Author:      Accenture
   * Date:        10-06-2020
   * Parameters:  Map<Id, SObject> oldItems
   * Return:      void
   * Description: This method is used to handle business logic for after undelete event on the usage summary object.
   ********************************************************************************************************************/
  public void afterUndelete(Map<Id,SObject> oldItems){
    //no action
  }
}