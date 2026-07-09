public class CaseTriggerHandler implements ITriggerHandler {
    
  public static Boolean isRecordInserted = false;
    
    public void BeforeInsert(List<Case> newItems) {
        
    }

    public void AfterInsert(List<Case> newItems) {
        
    }     
	public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {        
        
    }
     
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {         
    }
     
    public void BeforeDelete(Map<Id, SObject> oldItems) {         
    }
     
    public void AfterDelete(Map<Id, SObject> oldItems) {
         
    }
     
    public void AfterUndelete(Map<Id, SObject> oldItems) {
         
    }    
    public Boolean IsDisabled(){ 
       return false; 
    }
   }