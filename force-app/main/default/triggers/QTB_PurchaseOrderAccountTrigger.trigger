/***************************************************************************************************
* Trigger for Invoice Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Virtusa 
* @ModifiedBy    : Virtusa
* @Created       : 16th June2025
* @Modified      : 
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger QTB_PurchaseOrderAccountTrigger on QTB_PurchaseOrderAccount__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.Run(new QTB_PurchaseOrderAccountTriggerHandler()); 
}