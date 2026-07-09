/**
* Class: TriggerDispatcher
*
* Author: Vinutha Iyengar
*
* Date Created: 04.05.2020
*
* Purpose: The dispatcher is responsible for making sure all of the applicable methods on your trigger handler are called, depending on the trigger context.
* 
*/

public class TriggerDispatcher
{      
    public static void Run(ITriggerHandler handler)
    {         
        // Check to see if the trigger has been disabled. If it has, return
        if (handler.IsDisabled())
            return;
        
        // Detect the current trigger context and fire the relevant methods on the trigger handler:
        
        // Before trigger logic
        if (Trigger.IsBefore)
        {
            if (Trigger.IsInsert)
            {
                handler.BeforeInsert(trigger.new);                 
            }
            if (Trigger.IsUpdate)
            {                
                handler.BeforeUpdate(trigger.newMap, trigger.oldMap);       
            }         
            if (Trigger.IsDelete)
            {
                handler.BeforeDelete(trigger.oldMap);                
            }
        }
        
        // After trigger logic
        if (Trigger.IsAfter)
        {
            if (Trigger.IsInsert)
            {
                handler.AfterInsert(Trigger.new);                 
            }
            if (Trigger.IsUpdate)
            {
                handler.AfterUpdate(trigger.newMap, trigger.oldMap);                 
            }
            if (trigger.IsDelete) 
            {
                handler.AfterDelete(trigger.oldMap); 
            }
            
            if (trigger.isUndelete)
            {
                handler.AfterUndelete(trigger.oldMap);                
            }
        }
    }
}