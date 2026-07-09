/***************************************************************************************************
* Trigger for SBQQ__QuoteDocument__c Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 9/22/2020
* @Modified      : 9/22/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger QTB_QuoteDocumentTrigger on SBQQ__QuoteDocument__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
        TriggerDispatcher.Run(new QTB_QuoteDocumentTriggerHandler ()); 
}