/* Commenting the entire code as part of Gitlab #24448 */
global class EndingBalanceBatch{
    public EndingBalanceBatch(){
        
    }
}
/*
global class EndingBalanceBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	public static final String ENDING_BALANCE_BATCH_NAME = 'EndingBalanceBatch';
	public static final Integer BATCH_SCOPE_SIZE = 5000;

	public ErrorHandling.ErrorLog errorHandling;
	@TestVisible private EndingBalanceBatchModel EndingBalanceBatchModelInstance;
	
	global EndingBalanceBatch(){
		errorHandling = new ErrorHandling.ErrorLog( );
		EndingBalanceBatchModelInstance = new EndingBalanceBatchModel();
	}

	global EndingBalanceBatch(Integer year, Integer month){
		errorHandling = new ErrorHandling.ErrorLog( );
		EndingBalanceBatchModelInstance = new EndingBalanceBatchModel(year, month);
	}
	
	global Database.QueryLocator start(Database.batchableContext info){
        return Database.getQueryLocator(EndingBalanceBatchModelInstance.buildDatabaseQuery()); 
    }

	global void execute(Database.BatchableContext BC, List<sObject> scope){
		EndingBalanceBatchModelInstance.processAggregatedResults(scope, errorHandling);
    }
	
	global void finish(Database.BatchableContext batch){
    	EndingBalanceBatchModelInstance.sendErrorNotifications(batch, errorHandling); 
	}

}*/