/* Commenting the entire code as part of Gitlab #24448 */
global with sharing class ProspectingEntryCreationBatch{
    public ProspectingEntryCreationBatch(){
        
    }
}
/*global with sharing class ProspectingEntryCreationBatch implements Schedulable, Database.Stateful, Database.Batchable<sObject> {
	
	String query;

	global class BatchException extends Exception {}

	global Prospecting_Batch__c settings;
	global Integer count;
	global Date nextMonday;
	
	global ProspectingEntryCreationBatch(){
		settings = [SELECT 
						Id, 
						Batch_Size__c,
						Last_Batch_End__c,
						Last_Batch_Start__c,
						Last_Batch_Status__c,
						Last_Run_Count__c,
						User_Filter__c
					FROM Prospecting_Batch__c 
					LIMIT 1];
		Date d = Date.today();
		Date epoch = Date.valueOf('1900-01-07');
		while(Math.mod(epoch.daysBetween(d), 7) != 1){
			d+=1;
		}
		nextMonday = d;
		count = 0;
	}

	global void execute(SchedulableContext SC){
		Database.executeBatch(new ProspectingEntryCreationBatch(), Integer.valueOf(settings.Batch_Size__c));
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		if(settings.Last_Batch_Status__c=='Started' || settings.Last_Batch_Status__c=='In Progress'){
			throw new BatchException('This batch appears to already be in progress.  If you believe this is an error, update the Prospecting Batch custom setting.');
		}
		query = 'SELECT Id, Name FROM User';
		if(settings.User_Filter__c != null){
			query += ' WHERE '+settings.User_Filter__c;
		}
		settings.Last_Batch_Start__c = System.now();
		settings.Last_Batch_Status__c = 'Started';
		update settings;
		system.debug(query);
		system.debug(settings);
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<User> scope) {
   		system.debug(scope);
   		if(settings.Last_Batch_Status__c=='Started'){
   			settings.Last_Batch_Status__c = 'In Progress';
   			update settings;
   		}
   		count += ProspectingEntryService.batchCreateWeeklyEntryRecords(nextMonday, scope);
	}
	
	global void finish(Database.BatchableContext BC) {
		settings.Last_Batch_End__c = System.now();
		settings.Last_Batch_Status__c = 'Complete';
		settings.Last_Run_Count__c = count;
		update settings;
	}

}*/