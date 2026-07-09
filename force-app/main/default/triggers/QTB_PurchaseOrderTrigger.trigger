/***************************************************************************************************
* Trigger for Purchase Order Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 6/10/2020
* @Modified      : 
* ──────────────────────────────────────────────────────────────────────────────────────────────────*/
trigger QTB_PurchaseOrderTrigger on QTB_PurchaseOrder__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    	TriggerDispatcher.Run(new QTB_PurchaseOrderTriggerHandler()); 
}