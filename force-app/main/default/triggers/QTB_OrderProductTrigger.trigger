/***************************************************************************************************
* Trigger for Order Product Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 4/13/2020
* @Modified      : 4/29/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger QTB_OrderProductTrigger on OrderItem(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    	TriggerDispatcher.Run(new QTB_OrderProductHandler()); 
}