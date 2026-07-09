@isTest
public class Test_SKPRateUploadQPINotificationBatch {
  
    @isTest static void testExecute() {

        Scdl_SKPRateUploadQPINotificationBatch schedulable = new Scdl_SKPRateUploadQPINotificationBatch();

        Test.startTest();

        String jobId = System.schedule('Test SKP Rate Upload QPI Notification Batch', 
                                      System.now().addMinutes(1).format('s m H d M \'?\' yyyy'), 
                                      schedulable);
        
        // Verify that a job ID was returned
        System.assertNotEquals(null, jobId);

        schedulable.execute(null);

        Test.stopTest();
    }
}