/*
Auhtor       : Nagesh Ganji
Created Date : Apr 12, 2010
Description  : Wraper schedulable class for SynchronizeFieldValues. Need to schedule from web GUI at  
               specified/required time.
*/

global class SynchronizeFieldValueScheduler implements Schedulable{
	
	global Boolean nextRun;
	global Integer MAX_BATCH;
	global String oType;
	global Integer numberOfFields;
	
	global SynchronizeFieldValueScheduler() {
		nextRun = True;
		MAX_BATCH = 2000;
		oType = 'Account';
		numberOfFields = 4;
	}
	
	global void execute(SchedulableContext sc) {
		SynchronizeFieldValues b = new SynchronizeFieldValues(); 
		database.executebatch(b);
	}
}