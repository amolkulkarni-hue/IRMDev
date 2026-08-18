/* Search and deletion of orphaned records

// Cron expression for Daily at 12:00 AM Midnight
String cronExp = '0 0 0 * * ?'; 

// Cron expression for Daily at 12:00 PM Midday (Noon)
String cronExp = '0 0 12 * * ?';

System.schedule(
    'Daily Cleanup of Orphaned Configuration Line Items', 
    cronExp, 
    new CleanupConfigLineItemsBatch()
);
*/
global class CleanupConfigLineItemsBatch implements Database.Batchable<sObject>, System.Schedulable {

    // 1. Schedulable Interface: Allows the class to be scheduled daily
    global void execute(System.SchedulableContext sc) {
        // Execute the batch with a default scope size of 200 records
        Database.executeBatch(new CleanupConfigLineItemsBatch(), 200);
    }

    // 2. Batchable Interface: Collects all Configuration Line Items
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Fetch all Configuration Line Items to evaluate
        return Database.getQueryLocator(
            'SELECT Id, LGK__ConfigurationId__c FROM LGK__ConfigurationLineItem__c'
        );
    }

    // 3. Batchable Interface: Processes records in chunks of 200
    global void execute(Database.BatchableContext bc, List<LGK__ConfigurationLineItem__c> scope) {
        Set<String> configIdsInScope = new Set<String>();
        
        // Step 1: Gather all unique Configuration IDs within this specific batch chunk
        for (LGK__ConfigurationLineItem__c cli : scope) {
            if (String.isNotBlank(cli.LGK__ConfigurationId__c)) {
                configIdsInScope.add(cli.LGK__ConfigurationId__c);
            }
        }
        
        Set<String> activeTransactionConfigIds = new Set<String>();
        
        // Step 2: Query Transaction Lines matching the current scope's IDs
        // Grouping prevents hitting the 50,000 row query limit if an ID is reused frequently
        if (!configIdsInScope.isEmpty()) {
            for (AggregateResult ar : [
                SELECT LGK__ConfigurationId__c 
                FROM LGK__TransactionLine__c 
                WHERE LGK__ConfigurationId__c IN :configIdsInScope 
                GROUP BY LGK__ConfigurationId__c
            ]) {
                String txnConfigId = (String)ar.get('LGK__ConfigurationId__c');
                activeTransactionConfigIds.add(txnConfigId);
            }
        }
        
        List<LGK__ConfigurationLineItem__c> recordsToDelete = new List<LGK__ConfigurationLineItem__c>();
        
        // Step 3: Identify orphans (IDs not found in activeTransactionConfigIds or are Null/Blank)
        for (LGK__ConfigurationLineItem__c cli : scope) {
            if (String.isBlank(cli.LGK__ConfigurationId__c) || !activeTransactionConfigIds.contains(cli.LGK__ConfigurationId__c)) {
                recordsToDelete.add(cli);
            }
        }
        
        // Step 4: Perform the deletion safely
        if (!recordsToDelete.isEmpty()) {
            // allOrNone = false ensures that if one record fails (e.g. due to a lock or custom validation), 
            // the remaining valid orphan records in the batch are still successfully deleted.
            Database.delete(recordsToDelete, false);
        }
    }

    // 4. Batchable Interface: Runs once the entire batch job finishes
    global void finish(Database.BatchableContext bc) {
        // Optional: Implement post-processing logic here (like sending an execution summary email)
    }
}