/***************************************************************************************************
* Trigger for Invoice Line Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 5/4/2020
* @Modified      : 5/28/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger QTB_InvoiceLineTrigger on blng__InvoiceLine__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.Run(new QTB_InvoiceLineTriggerHandler()); 
}