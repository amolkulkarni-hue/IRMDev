global class NF_RetrieveUriEventDataSchedulable implements Schedulable {
    
    global void execute(SchedulableContext context) {
        // Query the latest EventLogFile records for the URI event type, created within the last 24 hours
        List<EventLogFile> logFiles = [
            SELECT Id
            FROM EventLogFile
            WHERE EventType = 'URI'
            AND Interval = 'Hourly'
            AND CreatedDate = LAST_N_DAYS:1
            ORDER BY LogDate DESC
        ];

        // Check if there are any log files
        if (!logFiles.isEmpty()) {
            // Extract the Ids of the retrieved EventLogFiles
            List<Id> logFileIds = new List<Id>();
            for (EventLogFile logFile : logFiles) {
                logFileIds.add(logFile.Id);
            }
            
            // Enqueue the first instance of the Queueable job to start processing
            //ARMAN: if(!Test.isRunningTest()) {
                System.enqueueJob(new NF_RetrieveUriEventDataQueueable(logFileIds));
            //ARMAN}
        
        } else {
            System.debug('No EventLogFiles found within the last 24 hours.');
        }
    }
}