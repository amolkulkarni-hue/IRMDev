/***************************************************************************************************
* Trigger for SBQQ__QuoteLine__c Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 5/18/2020
* @Modified      : 5/28/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger QTB_QuoteLineTrigger on SBQQ__QuoteLine__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
        TriggerDispatcher.Run(new QTB_QuoteLineHandler ()); 
}