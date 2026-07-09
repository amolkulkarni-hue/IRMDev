/***************************************************************************************************
* Trigger for OpportunityTeamMember Object
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture 
* @ModifiedBy    : Accenture
* @Created       : 3/17/2020
* @Modified      : 4/29/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
*******************************************************************************************************/
trigger QTB_OpportunityTeamTrigger on OpportunityTeamMember (before insert,before update,before delete,after insert,after update,after delete,after undelete) {
      	TriggerDispatcher.Run(new QTB_OpportunityTeamHandler()); 
}