/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Implementation of Batchable interface to be invoked based on the scheduled frequency. During 
* execution this will Generate one or more Case record based on the Recurrence Frequency.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
global class NAS_RecurringCaseGeneratorBatchable implements Database.Batchable<sObject>, Database.Stateful {
    /**
* @name executeRecurringCaseGeneratorBatch
* @description Service method to start the batch execution. It instanciates an instance of 
* this Batchable class and invokes executeBatch.
**/    
    Set<Id> parentAllds = new Set<Id>();
    Set<id> failedUpdateIds = new Set<id>();
    public static Id executeRecurringCaseGeneratorBatch()
    {
        Id batchProcessId;
        batchProcessId = Database.executeBatch(new NAS_RecurringCaseGeneratorBatchable(), 
                                               NAS_Constants.RECURRING_CASE_BATCH_SIZE);
        return batchProcessId;
    }
    /**
* @name start
* @description Implementation of Batchable start method. Returns the QueryLocator of the 
* Recurring Case Records.
**/
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        return NAS_Utilities.getRecurringCaseQueryLocator();
    }
    /**
* @name execute
* @description Impementation of Batchable execute method. Clones the recurring Case Records
* to create new NAS_GENERAL_SUPPORT_CASE records and updates the 
* NAS_Next_Case_Creation_Date__c field of the recurring case record.
* Updated the method to get the failure NAS recurring cases : GitLab #31329 

**/
    global void execute(Database.BatchableContext bc, List<sObject> recurringCases)
    {
        system.debug('@Cases size:'+recurringCases.size());        
        NAS_DataFactory datafactory = new NAS_DataFactory();
        RecurringCaseResultWrapper result = datafactory.createRecurringCases(recurringCases);
        // Add to your global collections or process immediately
    	parentAllds.addAll(result.failedInsertParentIds);
    	failedUpdateIds.addAll(result.failedUpdateCaseIds);
    }
    /**
* @name finish
* @description Send email and custom notifications to the owner of NAS Recurring Cases if there is a failure in inserting GS Cases.
* GitLab #31329 
**/ 
    global void finish(Database.BatchableContext BC) {
        //Sending Notifications to manually created child cases for failed Child case inserts.
        NAS_DataFactory.sendNotifications(parentAllds);
        //Send Notifications to set next case creation date manually as the update failed on Parent NAS Recurring Support Case.
        NAS_DataFactory.sendUpdateFailureNotifications(failedUpdateIds);
    }       
    
}