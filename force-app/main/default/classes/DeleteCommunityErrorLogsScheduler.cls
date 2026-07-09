global class DeleteCommunityErrorLogsScheduler implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        
        // Run the batch with default batch size of 200
        Database.executeBatch(new DeleteCommunityErrorLogsBatch(), 200);
        
    }
}