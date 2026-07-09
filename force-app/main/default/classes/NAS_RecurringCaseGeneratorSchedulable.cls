/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Implementation of Schedulable interface to be scheduled based on the scheduled frequency. During 
* execution this will invoke NAS_RecurringCaseGeneratorBatchable implementation to batch one or 
* more batch of Recurring Case Generation request.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
global class NAS_RecurringCaseGeneratorSchedulable implements Schedulable {
    /**
     * @name run
     * @description Service method to schedule the class based on the configured Cron Expression.
    **/
    public static String run()
    {
		return System.schedule((Test.isRunningTest() ? 'Test ' : '') + 
                               NAS_Constants.RECURRING_CASE_SCHEDULED_JOB_NAME, 
                               NAS_Constants.RECURRING_CASE_CRON_EXPRESSION, 
                               new NAS_RecurringCaseGeneratorSchedulable());
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
        List<CronTrigger> listCronTrigger = [SELECT Id, CronExpression, CronJobDetail.Name FROM CronTrigger WHERE 
                                             /*CronJobDetail.Name = 
                                             :NAS_Constants.RECURRING_CASE_SCHEDULED_JOB_NAME
                                             AND */ Id = :sc.getTriggerId()];
        if(!listCronTrigger.isEmpty() && 
           listCronTrigger[0].CronExpression != NAS_Constants.RECURRING_CASE_CRON_EXPRESSION &&
           listCronTrigger[0].CronJobDetail.Name == (Test.isRunningTest() ? 'Test ' : '') + 
                               NAS_Constants.RECURRING_CASE_SCHEDULED_JOB_NAME
          )
        {
            System.abortJob(listCronTrigger[0].Id);
            NAS_RecurringCaseGeneratorSchedulable.run();
        }
        else
        	Id batchIdList = NAS_RecurringCaseGeneratorBatchable.executeRecurringCaseGeneratorBatch();
        
    }
}