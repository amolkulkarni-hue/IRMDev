/***************************************************************************************************
* Trigger for AccountContactRelation Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 6/14/2020
* @Modified      : 6/14/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
****************************************************************************************************/
trigger QTB_AccountContactRelationTrigger on AccountContactRelation(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.Run(new QTB_AccountContactRelationHandler()); 
}