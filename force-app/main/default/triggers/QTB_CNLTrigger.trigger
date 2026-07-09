/***************************************************************************************************
* Trigger for Credit Note Line Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 3/17/2020
* @Modified      : 5/28/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger QTB_CNLTrigger on blng__CreditNoteLine__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.Run(new QTB_CNLTriggerHandler()); 
}