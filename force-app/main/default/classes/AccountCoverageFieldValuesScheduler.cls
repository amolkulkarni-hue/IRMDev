/*
Schedulable class for AccountCoverageFieldsSync apex class.
*/
global class AccountCoverageFieldValuesScheduler implements Schedulable{
	
    Global String Query;
	global AccountCoverageFieldValuesScheduler() {
	}
	
	global void execute(SchedulableContext sc) {
        Query =  'Select id from account where (AccountCoverageUpdated1__c =true or AccountCoverageUpdated2__c=true or Sync_fields__c=True) and  IM_Hierarchy_Level__c in (\'Sales (Site)\',\'Country Parent\')';
		AccountCoverageFieldsSync b = new AccountCoverageFieldsSync(Query); 
		database.executebatch(b,50);
	}
}