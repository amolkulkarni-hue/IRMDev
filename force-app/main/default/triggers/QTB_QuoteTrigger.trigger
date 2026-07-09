/*************************************************************************************************8
* Trigger for SBQQ_Quote Object. Calls handler class for logic
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 3/16/2020
* @Modified      : 5/29/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
******************************************************************************************************/
trigger QTB_QuoteTrigger on  SBQQ__Quote__c(before insert, before update,before delete,after insert,after update,after delete,after undelete) {
        TriggerDispatcher.Run(new QTB_QuoteHandler()); 
}