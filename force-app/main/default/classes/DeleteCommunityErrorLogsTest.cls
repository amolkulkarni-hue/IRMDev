@isTest
private class DeleteCommunityErrorLogsTest {  
    
    @isTest
    static void testBatchDeletesOldLogs() {
        // Create old logs (should be deleted)
        List<Community_Error_Log__c> oldLogs = new List<Community_Error_Log__c>();
        for (Integer i = 0; i < 200; i++) {
            oldLogs.add(new Community_Error_Log__c(Component_Name__c = 'OldLog ' + i));
        }
        insert oldLogs;

        // Backdate them to 2 months ago using Test.setCreatedDate
        for (Community_Error_Log__c log : oldLogs) {
            Test.setCreatedDate(log.Id, DateTime.now().addMonths(-2));
        }
        
        

        // Create recent logs (should NOT be deleted)
        List<Community_Error_Log__c> recentLogs = new List<Community_Error_Log__c>();
        for (Integer i = 0; i < 5; i++) {
            recentLogs.add(new Community_Error_Log__c(Component_Name__c = 'RecentLog ' + i));
        }
        insert recentLogs;

        // Run the batch inside test context        
        Test.startTest();
        Database.executeBatch(new DeleteCommunityErrorLogsBatch(), 200);
        Test.stopTest();      

        // Verify only recent logs remain
        System.assertEquals(
            5, 
            [SELECT COUNT() FROM Community_Error_Log__c], 
            'Only the recent logs should remain.'
        );
    }
    
    
    @isTest
    static void testScheduledBatchRuns() {
        // Insert 1 old log
        Community_Error_Log__c log = new Community_Error_Log__c(Component_Name__c = 'OldLog');
        insert log;
        Test.setCreatedDate(log.Id, DateTime.now().addMonths(-2));
       
		List<Community_Error_Log__c> tt= [SELECT id,createddate from Community_Error_Log__c where id=: log.id];        
        System.debug('@@Community_Error_Log__c-='+tt);
        
        // Schedule the job
        
        Test.startTest();
        String cronExp = '0 0 0 1 * ?'; // 1st of every month       
                               				 
        System.schedule('DeleteLogsJobTest', cronExp, new DeleteCommunityErrorLogsScheduler());
        Test.stopTest();
        List<CronTrigger> listCronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM 
                                             CronTrigger WHERE CronJobDetail.Name = 'DeleteLogsJobTest'];
        System.debug('@@listCronTrigger size'+listCronTrigger.size());
        
        //Verify the the Apex job is successfully scheduled.
        System.assertEquals(1, listCronTrigger.size());
        
        // Verify logs deleted
        /*System.assertEquals(
            0, 
            [SELECT COUNT() FROM Community_Error_Log__c], 
            'Old logs should be deleted after scheduled job runs.'
        );*/
    }
}