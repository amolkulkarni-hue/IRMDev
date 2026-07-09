/***************************************************************************************************
* Trigger for Invoice Scheduler Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Virtusa 
* @ModifiedBy    : Virtusa
* @Created       : 
* @Modified      : 19/09/2025
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger QTB_TaxDetailTrigger on QTB_Tax_Detail__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.Run(new QTB_TaxDetailTriggerHandler()); 
}