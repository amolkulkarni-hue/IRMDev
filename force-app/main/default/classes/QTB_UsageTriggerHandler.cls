/*****************************************************************************************************
* Class: QTB_UsageTriggerHandler
* Author: Accenture
* Purpose: This is a handler class for all business logic related to Usage object
* Requirement:
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              28/5/2020
*******************************************************************************************************/
public with sharing class QTB_UsageTriggerHandler implements ITriggerHandler{
	private static Boolean isTriggerHandlerDisabled = false;
    private static final String CLASSNAME = QTB_UsageTriggerHandler.class.getName();
    public static final String DELIMITERS = '[;,]';
	public static Boolean throwExplicitException = false;    
    /*****************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: Method is used to disable trigger execution from custom setting- Metadata_Activation_Settings__c
    *****************************************************************************************************************/
    public Boolean isDisabled(){ 
        Boolean isTriggerDisabled=false;
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if(custSetting!=null 
        && ((String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
            || (String.isNotBlank(custSetting.SObject_API_Name__c) 
                && custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.SOBJECT_BLNG_USAGE)
                && custSetting.Disable_Trigger__c))){     
        	isTriggerDisabled=true;
        }
        return isTriggerHandlerDisabled || isTriggerDisabled;
    }
    // disable usage trigger using apex
    public static void disable() {
        isTriggerHandlerDisabled = true;
    }
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before insert event on the Usage object.
    ********************************************************************************************************************/
    public void beforeInsert(List<SObject> newItems){
        QTB_UsageHelper.process((List<blng__Usage__c>)newItems,null,Trigger.OperationType);
    }
 
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before update event on the Usage object.
    ********************************************************************************************************************/ 
    public void beforeUpdate(Map<ID,SObject> newItems, Map<ID,SObject> oldItems){
       	Map<ID,blng__Usage__c> newUsageMap = (Map<ID,blng__Usage__c>)newItems;
        Map<ID,blng__Usage__c> oldUsageMap = (Map<ID,blng__Usage__c>)oldItems;
        QTB_UsageHelper.process(newUsageMap.values(),oldUsageMap,Trigger.OperationType);
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before delete event on the Usage object.
    ********************************************************************************************************************/
    public void beforeDelete(Map<ID,SObject> oldItems){
        Map<ID,blng__Usage__c> usageMap = (Map<ID,blng__Usage__c>)oldItems;
        QTB_UsageHelper.process(usageMap.values(),null,Trigger.OperationType);
    }
  
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after insert event on the Usage object.
    ********************************************************************************************************************/
    public void AfterInsert(List<SObject> newItems) {
        //#20867 Tiered Rate flag setting 
        QTB_UsageHelper.process((List<blng__Usage__c>)newItems,null,Trigger.OperationType);
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after update event on the Usage object.
    ********************************************************************************************************************/
    public void AfterUpdate(Map<ID,SObject> newItems, Map<ID,SObject> oldItems) {
        Map<ID,blng__Usage__c> newUsageMap = (Map<ID,blng__Usage__c>) newItems;
        Map<ID,blng__Usage__c> oldUsageMap = (Map<ID,blng__Usage__c>) oldItems;
        QTB_UsageHelper.process(newUsageMap.values(),oldUsageMap,Trigger.OperationType);
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after delete event on the Usage object.
    ********************************************************************************************************************/
    public void afterDelete(Map<ID, SObject> oldItems){
        Map<ID,blng__Usage__c> usageMap = (Map<ID,blng__Usage__c>) oldItems;
        QTB_UsageHelper.process(usageMap.values(),null,Trigger.OperationType);
    }
 
     /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        28-05-2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after undelete event on the Usage object.
    ********************************************************************************************************************/
    public void afterUndelete(Map<ID, SObject> newItems){
        Map<ID,blng__Usage__c> newUsageMap = (Map<ID,blng__Usage__c>) newItems;
        QTB_UsageHelper.process(newUsageMap.values(),null,Trigger.OperationType);
    }      
}