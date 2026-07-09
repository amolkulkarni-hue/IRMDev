/*****************************************************************************************************
* Class: QTB_PurchaseOrderAccountTriggerHandler
* Author: Virtusa
* Purpose: This is a handler class for all business logic related to Usage object
* Requirement: EPIC - #2698
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*             16th June2025
*******************************************************************************************************/

public with sharing class QTB_PurchaseOrderAccountTriggerHandler implements ITriggerHandler {

    public static final String DELIMITERS = '[;,]';
    private static final String CLASSNAME = QTB_PurchaseOrderAccountTriggerHandler.class.getName();
    public static Boolean throwExplicitException = false;  
    public static Boolean skipTriggerExecutionTestClass = false;

    /*****************************************************************************************************************
    * Author:      Virtusa
    * Date:        16th June 2025
    * Parameters:  None
    * Return:      void
    * Description: Method is used to disable trigger execution from custom setting- Metadata_Activation_Settings__c
    *****************************************************************************************************************/
    public Boolean isDisabled(){ 
        Boolean isTriggerDisabled=false;
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if(custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
                                 || (String.isNotBlank(custSetting.SObject_API_Name__c) 
                                     && custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.SOBJECT_PURCHASEORDER_ACCOUNT)
                                     && custSetting.Disable_Trigger__c) )){     
        	isTriggerDisabled=true;
        }
        return isTriggerDisabled;
    }
    
    /*******************************************************************************************************************
    * Author:      Virtusa
    * Date:        16th June 2025
    * Parameters:  List<SObject>
    * Return:      void
    * Description: This method is used to handle business logic for before insert event on the QTB_PurchaseOrderAccount__c object.
    ********************************************************************************************************************/
    public void beforeInsert(List<SObject> newItems){
        
        if(!QTB_PurchaseOrderAccountTriggerHandler.skipTriggerExecutionTestClass){
            List<QTB_PurchaseOrderAccount__c> newPurchaseOrderAccounts= (List<QTB_PurchaseOrderAccount__c>) newItems;
            QTB_PurchaseOrderAccountHelper.process(newPurchaseOrderAccounts,null,Trigger.OperationType);
        }
    }
 
    /*******************************************************************************************************************
    * Author:      Virtusa
    * Date:        16th June 2025
    * Parameters:  Map<ID,SObject>, Map<ID,SObject>
    * Return:      void
    * Description: This method is used to handle business logic for before update event on the QTB_PurchaseOrderAccount__c object.
    ********************************************************************************************************************/ 
    public void beforeUpdate(Map<ID,SObject> newItems, Map<ID,SObject> oldItems){
        
        /*if(!QTB_PurchaseOrderAccountTriggerHandler.skipTriggerExecutionTestClass){
            Map<ID,QTB_PurchaseOrderAccount__c> newPurchaseOrderAccounts = (Map<ID,QTB_PurchaseOrderAccount__c>)newItems;
            QTB_PurchaseOrderAccountHelper.process(newPurchaseOrderAccounts.values(),(Map<ID,QTB_PurchaseOrderAccount__c>)oldItems,Trigger.OperationType);   
        }*/
    }
 
     /*******************************************************************************************************************
    * Author:      Virtusa
    * Date:        16th June2025
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for before delete event on the invoice object.
    ********************************************************************************************************************/
    public void beforeDelete(Map<ID, SObject> oldItems){
        //Add logic
    }
  
    /*******************************************************************************************************************
    * Author:      Virtusa
    * Date:        16th June 2025
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after insert event on the QTB_PurchaseOrderAccount__c object.
    ********************************************************************************************************************/
    public void afterInsert(List<SObject> newItems){
        
        if(!QTB_PurchaseOrderAccountTriggerHandler.skipTriggerExecutionTestClass){
            List<QTB_PurchaseOrderAccount__c> newPurchaseOrderAccounts= (List<QTB_PurchaseOrderAccount__c>) newItems;
            Map<ID,QTB_PurchaseOrderAccount__c> newInvoicesMap=new Map<ID,QTB_PurchaseOrderAccount__c>();
            QTB_PurchaseOrderAccountHelper.process(newPurchaseOrderAccounts,null,Trigger.OperationType);
        }
    }
 
     /*******************************************************************************************************************
    * Author:      Virtusa
    * Date:        16th June 2025
    * Parameters:  None
    * Return:      void
    * Description: This method is used to handle business logic for after update event on the QTB_PurchaseOrderAccount__c object.
    ********************************************************************************************************************/
    public void afterUpdate(Map<ID, SObject> newItems, Map<ID, SObject> oldItems) {
        //enable to add logic

        /*if(!QTB_PurchaseOrderAccountTriggerHandler.skipTriggerExecutionTestClass){
            Map<ID,QTB_PurchaseOrderAccount__c> newPurchaseOrderAccounts = (Map<ID,QTB_PurchaseOrderAccount__c>)newItems;
            Map<ID,QTB_PurchaseOrderAccount__c> oldInvoices = (Map<ID,QTB_PurchaseOrderAccount__c>)oldItems;
            List<QTB_PurchaseOrderAccount__c> newInvoiceslist=new List<QTB_PurchaseOrderAccount__c>();
        
           //QTB_PurchaseOrderAccountHelper.updateNotesOnAccountFromUsage(newPurchaseOrderAccounts.values());
        
            QTB_PurchaseOrderAccountHelper.process(newPurchaseOrderAccounts.values(),(Map<ID,QTB_PurchaseOrderAccount__c>)oldItems,Trigger.OperationType); 
        }*/
    }
 
     /*******************************************************************************************************************
    * Author:      Virtusa
    * Date:        16th June 2025
    * Parameters:  Map<ID,SObject> 
    * Return:      void
    * Description: This method is used to handle business logic for after delete event on the QTB_PurchaseOrderAccount__c object.
    ********************************************************************************************************************/
    public void afterDelete(Map<ID,SObject> oldItems){
         if(!QTB_PurchaseOrderAccountTriggerHandler.skipTriggerExecutionTestClass){
        Map<ID, QTB_PurchaseOrderAccount__c> oldPOAmap = (Map<ID, QTB_PurchaseOrderAccount__c>)oldItems;
        QTB_PurchaseOrderAccountHelper.process(null, oldPOAmap, System.TriggerOperation.AFTER_DELETE);
    }
    }
 
     /*******************************************************************************************************************
    * Author:      Virtusa
    * Date:        16th June 2025
    * Parameters:  Map<ID,SObject>
    * Return:      void
    * Description: This method is used to handle business logic for after undelete event on the QTB_PurchaseOrderAccount__c object.
    ********************************************************************************************************************/
    public void afterUndelete(Map<ID,SObject> oldItems){  
    }   

}