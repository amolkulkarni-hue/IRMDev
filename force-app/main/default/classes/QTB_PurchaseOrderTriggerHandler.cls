/*****************************************************************************************************
* Class: QTB_PurchaseOrderTriggerHandler
* Author: Accenture
* Purpose: This is a handler class for all business logic related to Purchase Order object
* Requirement:
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              10/06/2020
*******************************************************************************************************/
public with sharing class QTB_PurchaseOrderTriggerHandler implements ITriggerHandler {
    public static final String DELIMITERS = '[;,]';
    public static boolean throwExplicitException = false;
    /*****************************************************************************************************************
    * Author:      Accenture
    * Date:        10-06-2020
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
    * Author:      Accenture
    * Date:       10-06-2020
    * Parameters:  List<Sobject>
    * Return:      void
    * Description: This method is used to handle business logic for before insert event on the Order object.
    ********************************************************************************************************************/
    public void BeforeInsert(List<SObject> newItems){
        QTB_PurchaseOrderHelper.trigController((List<QTB_PurchaseOrder__c>)newItems,null,Trigger.OperationType);
    } 
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        10-06-2020
    * Parameters: Map<Id, SObject> newItems, Map<Id, SObject> oldItems
    * Return:      oid
    * Description: This method is used to handle business logic for before update event on the Order object.
    ********************************************************************************************************************/ 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
         QTB_PurchaseOrderHelper.trigController((List<QTB_PurchaseOrder__c>)newItems.values(),(Map<id,QTB_PurchaseOrder__c>)oldItems,Trigger.OperationType);
        }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:       10-06-2020
    * Parameters:  Map<Id, SObject> oldItems
    * Return:      void
    * Description: This method is used to handle business logic for before delete event on the Order object.
    ********************************************************************************************************************/ 
    public void BeforeDelete(Map<Id, SObject> oldItems){
    }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        10-06-2020
    * Parameters:  List<SObject> newItems
    * Return:      void
    * Description: This method is used to handle business logic for after insert event on the Order object.
    ********************************************************************************************************************/ 
    public void AfterInsert(List<SObject> newItems) {
        Map<ID,QTB_PurchaseOrder__c> poIdMap = new Map<ID,QTB_PurchaseOrder__c>();
        QTB_PurchaseOrderHelper.reCalculatePOBalance((List<QTB_PurchaseOrder__c>)newItems, poIdMap, true);
        }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        10-06-2020
    * Parameters:  Map<Id, SObject> newItems, Map<Id, SObject> oldItems
    * Return:      void
    * Description: This method is used to handle business logic for after update event on the Order object.
    ********************************************************************************************************************/
       public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map<ID,QTB_PurchaseOrder__c> newPos = (Map<ID,QTB_PurchaseOrder__c>)newItems;
        Map<ID,QTB_PurchaseOrder__c> poIdMap = new Map<ID,QTB_PurchaseOrder__c>();
        List<SObject> newItemst = new List<SObject>();
        QTB_PurchaseOrderHelper.trigController(newPos.values(),(Map<ID,QTB_PurchaseOrder__c>)oldItems,Trigger.OperationType);
        //for(SObject objNew : newItems.values()){
            newItemst.addAll(newItems.values());
       // }
      //  QTB_PurchaseOrderHelper.calculatePOsOnAccount((List<QTB_PurchaseOrder__c>)newItemst, poIdMap);
    }
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        10-06-2020
    * Parameters:  Map<Id, SObject> oldItems
    * Return:      void
    * Description: This method is used to handle business logic for after delete event on the Order object.
    ********************************************************************************************************************/
      public void AfterDelete(Map<Id, SObject> oldItems){
        }
    
    
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        10-06-2020
    * Parameters:  Map<Id, SObject> oldItems
    * Return:      void
    * Description: This method is used to handle business logic for after undelete event on the Order object.
    ********************************************************************************************************************/
    public void AfterUndelete(Map<Id, SObject> newItems){
        /*System.debug('newItems:::'+newItems);
        Map<ID,QTB_PurchaseOrder__c> newPos = (Map<ID,QTB_PurchaseOrder__c>)newItems;
        System.debug('newPos:::'+newPos);
        List<Sobject> oldItemst = new List<SObject>();
        Map<ID,QTB_PurchaseOrder__c> poIdMap = new Map<ID,QTB_PurchaseOrder__c>();
        for(QTB_PurchaseOrder__c objOld : newPos.values()){
            oldItemst.add(objOld);
        }
        QTB_PurchaseOrderHelper.calculatePOsOnAccount((List<QTB_PurchaseOrder__c>)oldItemst, poIdMap);*/
    } 
    
}