/***************************************************************************************************
* Trigger for Invoice Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 
* @Modified      : 7/1/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger QTB_InvoiceTrigger on blng__Invoice__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.Run(new QTB_InvoiceTriggerHandler()); 
}