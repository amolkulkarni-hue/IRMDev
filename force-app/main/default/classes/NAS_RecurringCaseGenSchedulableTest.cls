/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Test Class for Schedulable class NAS_RecurringCaseGeneratorSchedulable
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class NAS_RecurringCaseGenSchedulableTest {
    /**
     * @name testRecurringCaseGeneratorSchedulable
     * @description Test Class to validate that the scheduled class is scheduled properly 
     * based on the CRON Expression.
     * class.
    **/
	@isTest
    public static void testRecurringCaseGeneratorSchedulable() {
        Test.startTest();
        	String jobId = NAS_RecurringCaseGeneratorSchedulable.run();
        
        	List<CronTrigger> listCronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM 
                                             	 CronTrigger WHERE CronJobDetail.Name = : 'Test ' + 
                               				 	 NAS_Constants.RECURRING_CASE_SCHEDULED_JOB_NAME];
        	//Verify that the Apex job is successfully scheduled.
        	System.assertEquals(1, listCronTrigger.size(), 'Incorrect number of CronTrigger in the queue.');
        	//Verify that the cron expression is correct
        	System.assertEquals(NAS_Constants.RECURRING_CASE_CRON_EXPRESSION, listCronTrigger[0].CronExpression, 
                            'Incorrect CronExpression of the job.');
        	//Verify that the scheduled job has not run yet.
        	System.assertEquals(0, listCronTrigger[0].TimesTriggered, 'Incorrect TimesTriggered value for the job.');
        	//Verify that the Scheduled Apex Queued successfully
        	List<AsyncApexJob> listAsyncApexJobScheduledApex = [SELECT Id FROM AsyncApexJob WHERE Status = 'Queued' AND 
                                               ApexClass.Name = 'NAS_RecurringCaseGeneratorSchedulable' AND 
                                               JobType = 'ScheduledApex'];
        	System.assertEquals(1, listAsyncApexJobScheduledApex.size(), 
                            'Incorrect number of Queued AsyncApexJobs of type ScheduledApex.');
        	//Verify that the batch apex is not queued yet.
        	List<AsyncApexJob> listAsyncApexJobBatchApexBeforeExecution = [SELECT Id, Status FROM AsyncApexJob WHERE
                                               Status = 'Queued' AND ApexClass.Name = 
                                               'NAS_RecurringCaseGeneratorBatchable' AND JobType = 'BatchApex'];
        	System.assertEquals(0, listAsyncApexJobBatchApexBeforeExecution.size(), 
                            'Incorrect number of Queued AsyncApexJobs of type BatchApex.');
        Test.stopTest();
        //Verify that the batch apex has queued successfully
        List<AsyncApexJob> listAsyncApexJobBatchApexAfterExecution = [SELECT Id, Status FROM AsyncApexJob WHERE
                                               Status = 'Queued' AND ApexClass.Name = 
                                               'NAS_RecurringCaseGeneratorBatchable' AND JobType = 'BatchApex'];
        System.assertEquals(1, listAsyncApexJobBatchApexAfterExecution.size(), 
                            'Incorrect number of Queued AsyncApexJobs of type BatchApex.');
    }
    /**
     * @name testRecurringCaseGeneratorSchedulableChangeCRON
     * @description Test Class to validate the reschedule functionality of 
     * NAS_RecurringCaseGeneratorSchedulable based on the update CRON Expression.
     * class.
    **/
    @isTest
    public static void testRecurringCaseGeneratorSchedulableChangeCRON() {
        Test.startTest();
        	String jobId = NAS_RecurringCaseGeneratorSchedulable.run();
        	// Change the CRON Expression
        	NAS_DataFactory.applicationConfiguration.put('RECURRING_CASE_CRON_EXPRESSION', '37 13 12 * * ?');
        Test.stopTest();
        
        List<CronTrigger> listCronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM 
                                             CronTrigger WHERE CronJobDetail.Name = : 'Test ' + 
                               				 NAS_Constants.RECURRING_CASE_SCHEDULED_JOB_NAME];
		//Verify the the Apex job is successfully scheduled.
        System.assertEquals(1, listCronTrigger.size(), 'Incorrect number of CronTrigger in the queue.');
		//Verify that the cron expression has changed
		System.assertEquals(NAS_Constants.RECURRING_CASE_CRON_EXPRESSION, listCronTrigger[0].CronExpression, 
                            'Incorrect CronExpression of the job.');
        //Verify that the Scheduled Apex Queued successfully
        List<AsyncApexJob> listAsyncApexJobScheduledApex = [SELECT Id FROM AsyncApexJob WHERE Status = 'Queued' AND 
                                               ApexClass.Name = 'NAS_RecurringCaseGeneratorSchedulable' AND 
                                               JobType = 'ScheduledApex'];
        System.assertEquals(1, listAsyncApexJobScheduledApex.size(), 
                            'Incorrect number of Queued AsyncApexJobs of type ScheduledApex.');
        //Verify that the batch apex is not queued yet.
        List<AsyncApexJob> listAsyncApexJobBatchApexAfterExecution = [SELECT Id, Status FROM AsyncApexJob WHERE
                                               Status = 'Queued' AND ApexClass.Name = 
                                               'NAS_RecurringCaseGeneratorBatchable' AND JobType = 'BatchApex'];
        System.assertEquals(0, listAsyncApexJobBatchApexAfterExecution.size(), 
                            'Incorrect number of Queued AsyncApexJobs of type BatchApex.');
    }
}