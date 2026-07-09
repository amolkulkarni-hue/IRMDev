/* Commenting the entire code as part of Gitlab #24448 */
global without sharing class AccountPrioritizationBatch{
   public AccountPrioritizationBatch(){}
}
/*
global without sharing class AccountPrioritizationBatch implements Schedulable, Database.Stateful, Database.Batchable<sObject> {
	
	String query;

	global class BatchException extends Exception {}

	global Priority_Batch_Settings__c settings;
	global String targetUserRole;
	
	global void execute(SchedulableContext SC){
		Database.executeBatch(new AccountPrioritizationBatch(), Integer.valueOf(settings.Batch_Size__c));
	}

	global AccountPrioritizationBatch(){
		settings = [SELECT 
						Id, 
						Name,
						Batch_End__c,
						Batch_Size__c,
						Batch_Start__c,
						Batch_Status__c,
						Contract_Renewal_Threshhold__c,
						Created_Date__c,
						End_Date__c,
						IM_Volume_Threshhold__c,
						Non_IM_Volume_Threshhold__c,
						Sales_Rep_Type__c,
						Start_Date__c,
                        FULL_Record_Type_Name__c,
                        BRIEF_Record_Type_Name__c
					FROM Priority_Batch_Settings__c 
					ORDER BY Created_Date__c DESC 
					LIMIT 1];
		targetUserRole = settings.Sales_Rep_Type__c;
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		if(settings.Batch_Status__c=='Started' || settings.Batch_Status__c=='In Progress'){
			throw new BatchException('This batch appears to already be in progress.  If you believe this is an error, update the Priority Batch custom setting.');
		}
		query = 'SELECT Id, Name, FirstName, LastName FROM User WHERE Sales_Segment__c = :targetUserRole AND IsActive = true';

		settings.Batch_Start__c = System.now();
		settings.Batch_Status__c = 'Started';
		update settings;
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<User> scope) {
   		if(settings.Batch_Status__c=='Started'){
   			settings.Batch_Status__c = 'In Progress';
   			update settings;
   		}
   		AccountPrioritizationService svc = new AccountPrioritizationService(settings);
   		svc.prioritizeForReps(scope);
	}
	
	global void finish(Database.BatchableContext BC) {
		settings.Batch_End__c = System.now();
		settings.Batch_Status__c = 'Complete';
		update settings;
	}
	
}
*/