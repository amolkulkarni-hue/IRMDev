/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Test Class for Get Replication events functionality.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class NAS_GetReplicationEventsSchedulableTest {
	/**
     * @name testGetReplicationEventsSchedulableWithMD
     * @description Tests the get replication events functionality.
    **/
	@isTest
    public static void testGetReplicationEventsSchedulableWithMD() {
        NAS_TestDataFactory.setupTestData(1);
        Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
        Test.startTest();
        String jobId = NAS_GetReplicationEventsSchedulable.run();
        
        List<CronTrigger> listCronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM 
                                             CronTrigger WHERE CronJobDetail.Name = : 'Test ' + 
                                             NAS_Constants.GET_EVENTS_SCHEDULED_JOB_NAME];
        //Verify that the Apex job is successfully scheduled.
        System.assertEquals(1, listCronTrigger.size(), 'Incorrect number of CronTrigger in the queue.');
        //Verify that the cron expression is correct
        String cronExpRegExp = '0 [0-9]+ \\* \\* \\* \\?';
        System.assert(Pattern.matches(cronExpRegExp, listCronTrigger[0].CronExpression), 
                      'Incorrect CronExpression of the job.');
        //Verify that the scheduled job has not run yet.
        System.assertEquals(0, listCronTrigger[0].TimesTriggered, 'Incorrect TimesTriggered value for the job.');
        //Verify that the Scheduled Apex Queued successfully
        List<AsyncApexJob> listAsyncApexJobScheduledApex = [SELECT Id FROM AsyncApexJob WHERE Status = 'Queued' AND 
                                                            ApexClass.Name = 'NAS_GetReplicationEventsSchedulable' AND 
                                                            JobType = 'ScheduledApex'];
        System.assertEquals(1, listAsyncApexJobScheduledApex.size(), 
                            'Incorrect number of Queued AsyncApexJobs of type ScheduledApex.');
        Test.stopTest();
    }
    /**
     * @name testGetReplicationEventsSchedulableWithoutMD
     * @description Tests the get replication events functionality without any master data in the 
     * systems. Verifies the missing data scenarios.
    **/
    @isTest
    public static void testGetReplicationEventsSchedulableWithoutMD() {
        Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
        Test.startTest();
        String jobId = NAS_GetReplicationEventsSchedulable.run();
        
        List<CronTrigger> listCronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM 
                                             CronTrigger WHERE CronJobDetail.Name = : 'Test ' + 
                                             NAS_Constants.GET_EVENTS_SCHEDULED_JOB_NAME];
        //Verify that the Apex job is successfully scheduled.
        System.assertEquals(1, listCronTrigger.size(), 'Incorrect number of CronTrigger in the queue.');
        //Verify that the cron expression is correct
        String cronExpRegExp = '0 [0-9]+ \\* \\* \\* \\?';
        System.assert(Pattern.matches(cronExpRegExp, listCronTrigger[0].CronExpression), 
                      'Incorrect CronExpression of the job.');
        //Verify that the scheduled job has not run yet.
        System.assertEquals(0, listCronTrigger[0].TimesTriggered, 'Incorrect TimesTriggered value for the job.');
        //Verify that the Scheduled Apex Queued successfully
        List<AsyncApexJob> listAsyncApexJobScheduledApex = [SELECT Id FROM AsyncApexJob WHERE Status = 'Queued' AND 
                                                            ApexClass.Name = 'NAS_GetReplicationEventsSchedulable' AND 
                                                            JobType = 'ScheduledApex'];
        System.assertEquals(1, listAsyncApexJobScheduledApex.size(), 
                            'Incorrect number of Queued AsyncApexJobs of type ScheduledApex.');
        Test.stopTest();
    }
}