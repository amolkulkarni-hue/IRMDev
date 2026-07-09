/*****************************************************************************************************
* Class: QTB_AccountContactRelationHandler
* Author: Accenture
* Purpose: This is a handler class for all business logic related to AccountContactRelation object
* Requirement:
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*           6/14/2020
*******************************************************************************************************/
public with sharing class QTB_AccountContactRelationHandler implements ITriggerHandler{
    
    public static final String DELIMITERS = '[;,]';
    
    public static boolean throwExplicitException = false;
    
    /*****************************************************************************************************************
    * Author:      Accenture
    * Date:        6/14/2020
    * Parameters:  None
    * Return:      void
    * Description: Method is used to disable trigger execution from custom setting- Metadata_Activation_Settings__c
    *****************************************************************************************************************/
    public Boolean IsDisabled(){ 
        Boolean isTriggerDisabled = false;
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if(custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
                                 || (String.isNotBlank(custSetting.SObject_API_Name__c) 
                                     && custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.SOBJECT_ACCOUNTCONTACTRELATION)
                                     && custSetting.Disable_Trigger__c) ))
        { isTriggerDisabled=true; }
        return isTriggerDisabled;
    }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        6/14/2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before insert event on the AccountContactRelation object.
    ********************************************************************************************************************/
    public void BeforeInsert(List<SObject> newItems){
        QTB_AccountContactRelationHelper.process(newItems,null,Trigger.operationtype);
    }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        6/14/2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before update event on the AccountContactRelation object.
    ********************************************************************************************************************/ 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        // Map<Id,AccountContactRelation> newItemsMap = (Map<Id,AccountContactRelation>)newItems;
        // QTB_AccountContactRelationHelper.primaryContactUpdation((List<AccountContactRelation>)newItemsMap.values(),
        // (Map<Id,AccountContactRelation>)oldItems);
        QTB_AccountContactRelationHelper.process(newItems.values(),(Map<Id,AccountContactRelation>)oldItems,Trigger.operationtype);
       
    }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        6/14/2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before delete event on the AccountContactRelation object.
    ********************************************************************************************************************/
    public void BeforeDelete(Map<Id, SObject> oldItems){
        if (oldItems != null && !oldItems.isEmpty()) {
            QTB_AccountContactRelationHelper.validateRecordsBeforeDelete(oldItems.values());
        }
    }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        6/14/2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after insert event on the AccountContactRelation object.
    ********************************************************************************************************************/
    public void AfterInsert(List<SObject> newItems) {
        // QTB_AccountContactRelationHelper.billingOSPlatformEvent((List<AccountContactRelation>) newItems);
        // QTB_AccountContactRelationHelper.billingOraclePlatformEvent((List<AccountContactRelation>) newItems, null);
        QTB_AccountContactRelationHelper.process(newItems,null,Trigger.operationtype);
    }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        6/14/2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after update event on the AccountContactRelation object.
    ********************************************************************************************************************/
    public void AfterUpdate(Map<Id, Sobject> newItems, Map<Id, Sobject> oldItems) {
        //no action
    }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        6/14/2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after delete event on the AccountContactRelation object.
    ********************************************************************************************************************/
    public void AfterDelete(Map<Id, SObject> oldItems){
        //no action
    }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        6/14/2020
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after undelete event on the AccountContactRelation object.
    ********************************************************************************************************************/
    public void AfterUndelete(Map<Id, SObject> oldItems){
        //no action
    }      
}