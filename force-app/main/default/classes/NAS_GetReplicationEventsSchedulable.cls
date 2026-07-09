/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Implementation of Schedulable interface to be scheduled based on the scheduled frequency. During 
* execution this will invoke NAS_GetReplicationEvents that pulls replication events from SKP and 
* generates Case.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
global class NAS_GetReplicationEventsSchedulable implements Schedulable {
	/**
     * @name run
     * @description Service method to schedule the class based on the configured Cron Expression.
    **/
    public static String run()
    {
		return System.schedule((Test.isRunningTest() ? 'Test ' : '') + 
                               NAS_Constants.GET_EVENTS_SCHEDULED_JOB_NAME, 
                               '0 ' 
                               + Math.mod(System.now().minute() 
                                          + NAS_Constants.GET_EVENTS_FREQUENCY_IN_MINUTES, 60) 
                               + ' * * * ?', 
                               new NAS_GetReplicationEventsSchedulable());
    }
    /**
     * @name execute
     * @description Implementation of execute method of Schedulable Interface. Checks if there 
     * is any change in Cron Expression. If there is any change, aborts currently scheduled job and
     * reschedules a new scheduled job with the updated Cron Expression. If there is no change Invokes the 
     * executeRecurringCaseGeneratorBatch service method in NAS_RecurringCaseGeneratorBatchable to 
     * start generation of recurring cases.
    **/
    global void execute(SchedulableContext SC) 
    {
        try
        {
            if(NAS_Utilities.isExecuteGetReplicationEventsBatch())
            	NAS_GetReplicationEventsBatchable.executeGetReplicationEventsBatch();
        }
        catch(Exception e) {}
        finally
        {
            System.abortJob(sc.getTriggerId());
        	NAS_GetReplicationEventsSchedulable.run();
        }
    }
}