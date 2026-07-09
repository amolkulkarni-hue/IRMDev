Trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update, after delete, after undelete) 
{   
    
   
    System.debug('Opportunity Trigger Executing'); 
    TriggerDispatcher.Run(new OpportunityTriggerHandler()); 
    
   
}