/***************************************************************************************************
* Trigger for Credit Note Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 5/4/2020
* @Modified      : 5/28/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger QTB_CreditNoteTrigger on blng__CreditNote__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    private static final QTB_CreditNoteTriggerHandler handler = new QTB_CreditNoteTriggerHandler();
    TriggerDispatcher.Run(handler); 
   
}