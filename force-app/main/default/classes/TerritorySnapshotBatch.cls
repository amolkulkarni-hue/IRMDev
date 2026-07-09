/* Commenting the entire code as part of Gitlab #24448 */
global class TerritorySnapshotBatch{
    public TerritorySnapshotBatch(){
        
    }
}
/*global class TerritorySnapshotBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	public static final Integer BATCH_SCOPE_SIZE = 2000;
	public static final String TERRITORY_SNAPSHOT_BATCH_NAME = 'TerritorySnapshotBatch';
	
	public TerritorySnapshotBatchModel TerritorySnapshotBatchModelInstance;
	
	
	global TerritorySnapshotBatch(){
		this(Integer.valueOf(Label.Current_Cube_Year), Integer.valueOf(Label.Current_End_Cube_Period));
	}
	
    global TerritorySnapshotBatch (Integer currentYear, Integer currentMonth) {
    	TerritorySnapshotBatchModelInstance = new TerritorySnapshotBatchModel(currentYear, currentMonth);
    }

	global Database.QueryLocator start(Database.batchableContext info){
        return Database.getQueryLocator(TerritorySnapshotBatchModelInstance.buildDatabaseQuery()); 
    }
	
	global void execute(Database.BatchableContext BC, List<sObject> scope){
		TerritorySnapshotBatchModelInstance.processAggregatedResults(scope);
    }
	
	global void finish(Database.BatchableContext batch){
    	TerritorySnapshotBatchModel.insertTerritorySnapshots(TerritorySnapshotBatchModelInstance.processTerritorySnapshots(), batch); 
	}
	
}*/