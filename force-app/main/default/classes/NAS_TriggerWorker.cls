/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Trigger Worker class. Executes the run method of the trigger handler parameter which is a 
* NAS_TriggerHandler.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public with sharing class NAS_TriggerWorker {
	/**
	 * @name execute
     * @description Executes the trigger handler run method.
    **/
    public static void execute(String triggerHandlerClassName)
    {
    	Type triggerHandlerType = Type.forname(triggerHandlerClassName);
    	if(triggerHandlerType != null)
    	{
    		NAS_TriggerHandler triggerHandler = (NAS_TriggerHandler) triggerHandlerType.newInstance();
    		triggerHandler.run();
    	}
    }
}