/*************************************************************************************************8
* Trigger for blng__InvoiceRun__c Object. Calls handler class for logic
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : IRM 
* @ModifiedBy    : IRM
* @Created       : 07/12/2021
* @Modified      : 07/12/2021
* ──────────────────────────────────────────────────────────────────────────────────────────────────
******************************************************************************************************/
trigger QTB_InvoiceRunTrigger on  blng__InvoiceRun__c(before insert, before update,before delete,after insert,after update,after delete,after undelete) {
        TriggerDispatcher.Run(new QTB_InvoiceRunTriggerHandler()); 
}