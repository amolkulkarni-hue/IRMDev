/*****************************************************************************************************
* Class: QTB_InvoiceRunTriggerHandler
* Author: IRM
* Purpose: This is a handler class for all business logic related to Purchase Order object
* Requirement:
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Gopinandan   07/12/2021      #857 Vertex Tax Integration
*******************************************************************************************************/
public with sharing class QTB_InvoiceRunTriggerHandler implements ITriggerHandler {
    public static final String DELIMITERS = '[;,]';
    public static boolean throwExplicitException = false;
    /*****************************************************************************************************************
    * Author:      IRM
    * Date:        07/12/2021
    * Parameters:  None
    * Return:      boolean
    * Description: Method is used to disable trigger execution from custom setting- Metadata_Activation_Settings__c
    *****************************************************************************************************************/
    public Boolean IsDisabled(){ 
        Boolean isTriggerDisabled = false;
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if(custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
                                 || (String.isNotBlank(custSetting.SObject_API_Name__c) 
                                     && custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.SOBJECT_PURCHASEORDER)
                                     && custSetting.Disable_Trigger__c) )){ isTriggerDisabled = true; }
        return isTriggerDisabled;
    }
    /*******************************************************************************************************************
    * Author:      IRM
    * Date:       07/12/2021
    * Parameters:  List<Sobject>
    * Return:      void
    * Description: This method is used to handle business logic for before insert event on the Order object.
    ********************************************************************************************************************/
    public void BeforeInsert(List<SObject> newItems){
        
    } 
    
    /*******************************************************************************************************************
    * Author:      IRM
    * Date:       07/12/2021
    * Parameters: Map<Id, SObject> newItems, Map<Id, SObject> oldItems
    * Return:      oid
    * Description: This method is used to handle business logic for before update event on the Order object.
    ********************************************************************************************************************/ 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
    
    }
    
    /*******************************************************************************************************************
    * Author:      IRM
    * Date:       07/12/2021
    * Parameters:  Map<Id, SObject> oldItems
    * Return:      void
    * Description: This method is used to handle business logic for before delete event on the Order object.
    ********************************************************************************************************************/ 
    public void BeforeDelete(Map<Id, SObject> oldItems){
    }
    
    /*******************************************************************************************************************
    * Author:      IRM
    * Date:       07/12/2021
    * Parameters:  List<SObject> newItems
    * Return:      void
    * Description: This method is used to handle business logic for after insert event on the Order object.
    ********************************************************************************************************************/ 
    public void AfterInsert(List<SObject> newItems) {
       
    }
    /*******************************************************************************************************************
    * Author:      IRM
    * Date:        12-07-2020
    * Parameters:  Map<Id, SObject> newItems, Map<Id, SObject> oldItems
    * Return:      void
    * Description: This method is used to handle business logic for after update event on the Order object.
    ********************************************************************************************************************/
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map<ID,blng__InvoiceRun__c> newInvRun = (Map<ID,blng__InvoiceRun__c>)newItems;
        QTB_InvoiceRunHelper.trigController(newInvRun.values(),(Map<ID,blng__InvoiceRun__c>)oldItems,Trigger.OperationType);
    }
    /*******************************************************************************************************************
    * Author:      IRM
    * Date:        12-07-2020
    * Parameters:  Map<Id, SObject> oldItems
    * Return:      void
    * Description: This method is used to handle business logic for after delete event on the Order object.
    ********************************************************************************************************************/
    public void AfterDelete(Map<Id, SObject> oldItems){
        
    }
    
    /*******************************************************************************************************************
    * Author:      IRM
    * Date:        12-07-2020
    * Parameters:  Map<Id, SObject> oldItems
    * Return:      void
    * Description: This method is used to handle business logic for after undelete event on the Order object.
    ********************************************************************************************************************/
    public void AfterUndelete(Map<Id, SObject> newItems){
        
    } 
}