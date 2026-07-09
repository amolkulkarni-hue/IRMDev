/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Trigger Handler Franework abstract class.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public abstract class NAS_TriggerHandlerFramework {
    /**
     * @description Returns true if the current context for the Apex code is a trigger, not a 
     * Visualforce page, a Web service, or an executeanonymous() API call.
    **/
	public Boolean isExecuting	= Trigger.isExecuting;
	
	/**
     * @description Returns true if this trigger was fired due to an insert operation, from 
     * the Salesforce user interface, Apex, or the API.
    **/
	public Boolean isInsert = Trigger.isInsert;
	
	/**
     * @description Returns true if this trigger was fired due to an update operation, from the 
     * Salesforce user interface, Apex, or the API.
    **/
	public Boolean isUpdate = Trigger.isUpdate;
	
	/**
     * @description Returns true if this trigger was fired due to a delete operation, from the 
     * Salesforce user interface, Apex, or the API.
    **/
	public Boolean isDelete = Trigger.isDelete;
	
	/**
     * @description Returns true if this trigger was fired before any record was saved.
    **/
	public Boolean isBefore = Trigger.isBefore;
	
	/**
     * @description Returns true if this trigger was fired after all records were saved.
    **/
	public Boolean isAfter = Trigger.isAfter;
	
	/**
     * @description Returns true if this trigger was fired after a record is recovered from the Recycle 
     * Bin. This recovery can occur after an undelete operation from the Salesforce user interface, 
     * Apex, or the API.
    **/
	public Boolean isUndelete = Trigger.isUndelete;
	
	/**
     * @description Returns a list of the new versions of the sObject records. This sObject list is only 
     * available in insert, update, and undelete triggers, and the records can only be modified in before triggers.
    **/
	public List<sObject> newList = Trigger.new;
	
	/**
     * @description A map of IDs to the new versions of the sObject records.
	 * This map is only available in before update, after insert, after update, and after undelete triggers.
    **/
	public Map<Id, sObject> newMap = Trigger.newMap;
	
	/**
     * @description Returns a list of the old versions of the sObject records.
	 * This sObject list is only available in update and delete triggers.
    **/
	public List<sObject> oldList = Trigger.old;
	
	/**
     * @description A map of IDs to the old versions of the sObject records.
	 * This map is only available in update and delete triggers.
    **/
	public Map<Id, sObject> oldMap	= Trigger.oldMap;
	
	/**
     * @description Returns an enum of type System.TriggerOperation corresponding to the current operation.
	 * Possible values of the System.TriggerOperation enum are: BEFORE_INSERT, BEFORE_UPDATE, 
	 * BEFORE_DELETE,AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, and AFTER_UNDELETE. If you vary your 
	 * programming logic based on different trigger types, consider using the switch statement with 
	 * different permutations of unique trigger execution enum states.
    **/
	public System.TriggerOperation operationType = Trigger.operationType;
	
	/**
     * @description The total number of records in a trigger invocation, both old and new.
    **/
	public Integer size = Trigger.size;
	
	/**
	 * @name beforeInsert
     * @description Before Insert Trigger Handler.
	 * Commented as this action is currently not being used.
    **/
    //public abstract void beforeInsert();
 	/**
	 * @name beforeUpdate
     * @description Before Update Trigger Handler.
	 * Commented as this action is currently not being used.
    **/
    //public abstract void beforeUpdate();
 	/**
	 * @name beforeDelete
     * @description Before Delete Trigger Handler.
	 * Commented as this action is currently not being used.
    **/
    //public abstract void beforeDelete();
 	/**
	 * @name afterInsert
     * @description After Insert Trigger Handler.
    **/
    public abstract void afterInsert();
 	/**
	 * @name afterUpdate
     * @description After Update Trigger Handler.
	 * Commented as this action is currently not being used.
    **/
    //public abstract void afterUpdate();
 	/**
	 * @name afterDelete
     * @description After Delete Trigger Handler.
	 * Commented as this action is currently not being used.
    **/
    //public abstract void afterDelete();
 	/**
	 * @name afterUndelete
     * @description After Undelete Trigger Handler.
	 * Commented as this action is currently not being used.
    **/
    //public abstract void afterUndelete();
    /**
	 * @name run
     * @description Run method of the trigger. Currently the application 
     * does not use any handler other than the afterInsert. To be uncommented 
     * to use the framework for other events.
    **/
    public void run()
    {
    	if(this.isExecuting)
    	{
			//Commented as this action is currently not being used.
    		//if(this.isBefore)
    		//{
    		//	if(isInsert) beforeInsert();
    		//	else if(isUpdate) beforeUpdate();
    		//	else if(isDelete) beforeDelete();
    		//}
    		//else 
    		if(this.isAfter)
    		{
    			if(isInsert) afterInsert();
				//Commented as these actions are currently not being used.
    			//else if(isUpdate) afterUpdate();
    			//else if(isDelete) afterDelete();
    			//else if(isUndelete) afterUndelete();
    		}
    	}
    }
}