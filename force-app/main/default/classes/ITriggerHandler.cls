/**
 * Class: ITriggerHandler
 *
 * Author: Vinutha Iyengar
 *
 * Date Created: 04.05.2020
 *
 * Purpose: The interface dictates which methods every trigger handler must implement.
 * 
 */

public interface ITriggerHandler
{
    void BeforeInsert(List<SObject> newItems);
 
    void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems); 
 
    void BeforeDelete(Map<Id, SObject> oldItems);
 
    void AfterInsert(List<SObject> newItems);  
 
    void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems);
 
    void AfterDelete(Map<Id, SObject> oldItems);
 
    void AfterUndelete(Map<Id, SObject> oldItems);  
 
    Boolean IsDisabled();  
    
   
}