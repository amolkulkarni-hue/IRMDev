Trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update, after delete, after undelete) 
{   
    System.debug('Opportunity Trigger Executing'); 
    TriggerDispatcher.Run(new OpportunityTriggerHandler()); 
    
    //Opportunity Stage Governance and Booking Verification Control enforces the field lock across all save paths by comparing
    // Old/new values for every field listed in Locked_Opportunity_Field__mdt.
    // Wired directly here rather than through OpportunityTriggerHandler/ TriggerDispatcher per your request — see note below on consolidating later.
    if (Trigger.isBefore && Trigger.isUpdate) {
        NF_OpportunityFieldLockService.enforceFieldLocks(Trigger.new, Trigger.oldMap);
    }
}