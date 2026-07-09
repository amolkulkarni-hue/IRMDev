global class DeleteCommunityErrorLogsBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query ALL records older than 1 month
        return Database.getQueryLocator([
            SELECT Id
            FROM Community_Error_Log__c
            WHERE CreatedDate < :System.today().addMonths(-1)
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Community_Error_Log__c> scope) {
        try {
            delete scope;
            System.debug('Deleted ' + scope.size() + ' logs in this batch.');
        } catch (DmlException dmlEx) {
            System.debug('DML Exception while deleting logs: ' + dmlEx.getMessage());
        } catch (Exception ex) {
            System.debug('Unexpected Exception: ' + ex.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('Batch finished deleting error logs.');
    }
}