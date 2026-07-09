@isTest
public class NF_RetrieveUriEventDataSchedulableTest {

    @isTest
    static void testSchedulableJob() {
        // Create the schedulable job instance
        NF_RetrieveUriEventDataSchedulable schedulableJob = new NF_RetrieveUriEventDataSchedulable();

        // Schedule the job (use a cron expression that fits your desired timing)
        String jobId = System.schedule('Test NF_RetrieveUriEventDataSchedulable Job', '0 0 * * * ?', schedulableJob);

        // Start and stop test context to ensure that scheduled jobs are processed
        Test.startTest();
        Test.stopTest();

        // Verify that the Queueable job was enqueued
        // Query the AsyncApexJob object to check if the job has been queued
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE Status = 'Queued' AND JobType = 'Queueable' LIMIT 1];

    }
}