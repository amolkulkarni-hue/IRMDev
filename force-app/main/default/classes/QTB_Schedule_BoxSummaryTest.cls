/*****************************************************************************************************
* Class: QTB_Schedule_BoxSummary_Test
* Author: Lokesh Tewari
* Purpose: GitLab #26362 To link Box Summary record with EOM invoices
* Requirement: GitLab #26362 To link Box Summary record with EOM invoices 
* Change History: 14/10/2024
* Developer                         Date                    Description
* ------------------------------------------------------------------------------------------- 
Lokesh Tewari      14/10/2024     GitLab #26362 To link Box Summary record with EOM invoices
*******************************************************************************************************/
@isTest(SeeAllData=false)
private class QTB_Schedule_BoxSummaryTest {
    // Test method to verify that the schedulable class works without any exception
    @IsTest
    static void testExecuteWithoutException() {
        // Setup any necessary test data
        Test.startTest();

        // Create an instance of the Schedulable class
        QTB_Schedule_BoxSummary scheduler = new QTB_Schedule_BoxSummary();

        // Simulate the SchedulableContext and execute the class
        String jobId = System.schedule('Test_Schedulable_Job', '0 0 23 * * ?', scheduler);

        // Verify that the batch job was successfully scheduled
        Test.stopTest();
        
        // Add assertions here if necessary
        System.assertNotEquals(null, jobId, 'The scheduled job should have a valid job ID.');
    }

    // Test method to verify that the schedulable class throws an exception
    @IsTest
    static void testExecuteWithException() {
        // Setup the exception throwing flag to true
        QTB_Schedule_BoxSummary.throwExplicitException = true;

        // Start a test to ensure no governor limits are hit
        Test.startTest();
        
        // Create an instance of the Schedulable class
        QTB_Schedule_BoxSummary scheduler = new QTB_Schedule_BoxSummary();

        // Simulate the SchedulableContext and execute the class
        String jobId = System.schedule('Test_Schedulable_Job_Exception', '0 0 23 * * ?', scheduler);

        // Test.stopTest() will make sure that the scheduled job is executed
        Test.stopTest();

        // Reset the flag to false
        QTB_Schedule_BoxSummary.throwExplicitException = false;

        // We would typically check logs or handle the error scenario here,
        // but since it's caught, there's no direct exception to assert.
        // Custom exception logger should handle the logging.
    }

    // Utility method to test the batch execution in the schedulable
    @IsTest
    static void testBatchExecution() {
        // Start the test context
        Test.startTest();

        // Create an instance of the Schedulable class
        QTB_Schedule_BoxSummary scheduler = new QTB_Schedule_BoxSummary();
        
        // Schedule the job (which will run the batch process as well)
        String jobId = System.schedule('Test_Schedulable_Batch_Job', '0 0 23 * * ?', scheduler);
        
        Test.stopTest();
        
        // Check if the job has been scheduled
        System.assertNotEquals(null, jobId, 'The batch job should have been scheduled successfully.');
    }
}