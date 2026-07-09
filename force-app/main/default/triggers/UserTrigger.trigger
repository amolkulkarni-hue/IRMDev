/***************************************************************************************************
* Trigger for Usage Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 
* @Modified      : 4/29/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger UserTrigger on User(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    	TriggerDispatcher.Run(new QTB_UserTriggerHandler());
}