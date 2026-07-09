/***************************************************************************************************
* Trigger for Order Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 3/16/2020
* @Modified      : 3/19/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger QTB_OrderTrigger on Order(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
        TriggerDispatcher.Run(new QTB_OrderTriggerHandler()); 
}