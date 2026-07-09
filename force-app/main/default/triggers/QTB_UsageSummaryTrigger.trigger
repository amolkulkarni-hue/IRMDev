/***************************************************************************************************
* Trigger for Usage Summary Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 6/10/2020
* @Modified      : 
* ──────────────────────────────────────────────────────────────────────────────────────────────────
******************************************************************************************************/
trigger QTB_UsageSummaryTrigger on blng__UsageSummary__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.Run(new QTB_UsageSummaryTriggerHandler()); 
}