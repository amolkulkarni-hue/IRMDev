/***************************************************************************************************
* Trigger for SBQQ__OrderItemConsumptionSchedule__c Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Virtusa 
* @ModifiedBy    : Virtusa
* @Created       : 08/25/2024
* @Modified      : 08/25/2024
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger QTB_OrderItemConsumptionSchedule on SBQQ__OrderItemConsumptionSchedule__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.Run(new QTB_OrderItemConScheduleTriggerHandler()); 
}