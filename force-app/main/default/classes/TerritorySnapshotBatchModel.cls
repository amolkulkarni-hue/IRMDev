/* Commenting the entire code as part of Gitlab #24448 */
public class TerritorySnapshotBatchModel {
    public TerritorySnapshotBatchModel(){
        
    }
/*	
	private static BluewolfDevUtils bwdevutils = new BluewolfDevUtils();
	private static String fieldRollupPrefix = 'r_';
	
	private Integer currentMonth;
	private Integer currentYear;
	private Integer previousYear;
	
	public Map<String, Territory_Snapshot__c> hashTerritoryYearMonth;
	public Map<String, RecordType> InboundStorageRecordTypeDevNameToRecordType;
	public Map<Id, RecordType> InboundStorageRecordTypeIdToRecordType;
	public Map<String, List<TerritorySnapshotRollupSettings__c>> InboundStorageRecordTypeDevNameToSettings;
	public Map<String, String> InboundStorageRecordTypeDevNameAndFieldToDestination;
	public Map<String, Set<String>> InboundStorageFieldsToRollupByRecordType;
	
	public List<Territory_Snapshot__c> TerritorySnapshotsToInsert;
	public Map<String, Decimal> ytdTerritorySnapshotsByRecordType;
	public Map<String, Decimal> parsedAggregateFieldValueTotalMap;
	public Set<String> InboundStorageFieldsToRollup;
	public Set<String> InboundStorageFieldsToRollupYTD;
	public Map<String, Map<String, String>> InboundYTDRecordTypeDestinationFields;
	
	
	public TerritorySnapshotBatchModel(Integer currentYearToParse, Integer currentMonthToParse){
		currentMonth = currentMonthToParse;
		currentYear = currentYearToParse;
		previousYear = currentYear - 1;
		
		hashTerritoryYearMonth = new Map<String, Territory_Snapshot__c>();
		ytdTerritorySnapshotsByRecordType = new Map<String, Decimal>();
		parsedAggregateFieldValueTotalMap = new Map<String, Decimal>();
		InboundStorageRecordTypeDevNameToSettings = new Map<String, List<TerritorySnapshotRollupSettings__c>>();
		InboundStorageRecordTypeDevNameAndFieldToDestination = new Map<String, String>();
		InboundStorageRecordTypeDevNameToRecordType = new Map<String, RecordType>();
		InboundStorageFieldsToRollup = new Set<String>();
		InboundStorageFieldsToRollupYTD = new Set<String>();
		InboundStorageFieldsToRollupByRecordType = new Map<String, Set<String>>();
		
		for (TerritorySnapshotRollupSettings__c setting : TerritorySnapshotRollupSettings__c.getAll().values()){
			if (!InboundStorageRecordTypeDevNameToSettings.containsKey(setting.Inbound_Storage_Record_Type__c)){
				InboundStorageRecordTypeDevNameToSettings.put(setting.Inbound_Storage_Record_Type__c, new List<TerritorySnapshotRollupSettings__c>());
			}
			if (!InboundStorageFieldsToRollupByRecordType.containsKey(setting.Inbound_Storage_Record_Type__c)){
				InboundStorageFieldsToRollupByRecordType.put(setting.Inbound_Storage_Record_Type__c, new Set<String>());
			}
			InboundStorageFieldsToRollupByRecordType.get(setting.Inbound_Storage_Record_Type__c).add(setting.Inbound_Storage_Rollup_Field__c);
			InboundStorageRecordTypeDevNameToSettings.get(setting.Inbound_Storage_Record_Type__c).add(setting);
			InboundStorageRecordTypeDevNameAndFieldToDestination.put(hashFields(setting.Inbound_Storage_Record_Type__c, setting.Inbound_Storage_Rollup_Field__c), setting.Territory_Snapshot_Destination_Field__c);
			InboundStorageFieldsToRollup.add(setting.Inbound_Storage_Rollup_Field__c);
			if (setting.Rollup_YTD__c){
				InboundStorageFieldsToRollupYTD.add(setting.Inbound_Storage_Rollup_Field__c);
			}
		}
		InboundStorageRecordTypeIdToRecordType = new Map<Id, RecordType>([Select Id, DeveloperName From RecordType Where DeveloperName in :InboundStorageRecordTypeDevNameToSettings.keySet()]);
		for (RecordType recordType : InboundStorageRecordTypeIdToRecordType.values()){
			InboundStorageRecordTypeDevNameToRecordType.put(recordType.DeveloperName, recordType);
		}
		
		InboundYTDRecordTypeDestinationFields = new Map<String, Map<String, String>>();
		for (TerritorySnapshotRecordTypeDestination__c setting : TerritorySnapshotRecordTypeDestination__c.getAll().values()){
			if (!InboundYTDRecordTypeDestinationFields.containsKey(setting.Inbound_Storage_Record_Type__c)){
				InboundYTDRecordTypeDestinationFields.put(setting.Inbound_Storage_Record_Type__c, new Map<String, String>());
			}
			InboundYTDRecordTypeDestinationFields.get(setting.Inbound_Storage_Record_Type__c).put('PY', setting.Territory_Snapshot_PY_Destination_Field__c);
			InboundYTDRecordTypeDestinationFields.get(setting.Inbound_Storage_Record_Type__c).put('CY', setting.Territory_Snapshot_CY_Destination_Field__c);
		}
		
	}
	
	
	public String buildDatabaseQuery(){ 
		String dbQuery = 'SELECT Id FROM Inbound_Storage__c '
						+ ' WHERE Cube_District__r.Parent_Billing_Market__r.Territory__c != null '
						+ ' AND RecordTypeId != null AND CALENDAR_YEAR(Storage_Date__c) >= '+previousYear
						+ ' AND CALENDAR_MONTH(Storage_Date__c) <= ' + currentMonth;
  		return dbQuery;
	}
	
	private String feildSetToSOQLFields(Set<String> fieldSetToRullup){
		String RolledUpFields = '';
		for (String field : new List<String>(fieldSetToRullup)){
			RolledUpFields += ', SUM('+field+') '+fieldRollupPrefix+field + ' ';
		}
		return RolledUpFields;
	}
	
	private static String hashValues(Id territory, Integer year, Integer month, String recordType, String field){
		return territory+'#'+year+'#'+month+'#'+recordType+'#'+field;
	}
	
	private static String hashFields(String recordType, String field){
		return recordType+'#'+field;
	}
	
	
	private class InboundStorageDatabaseQueryBuilder {
		
		private List<Inbound_Storage__c> allInboundStorage;
		private Set<String> defaultFields;
		private Set<String> defaultAggregateFields;
		private Set<String> fieldsToGroupBy;
		private Set<String> otherAggregateFields;
		
		public Map<String, String> queryFieldMap;
		
		public InboundStorageDatabaseQueryBuilder(List<Inbound_Storage__c> allInboundStorageInput, 
												  Set<String> otherAggregateFieldInput){
			allInboundStorage = allInboundStorageInput;
			defaultFields = new Set<String>{'RecordTypeId', 
											'Cube_District__r.Parent_Billing_Market__r.Territory__c'};
			defaultAggregateFields = new Set<String>{'CALENDAR_YEAR(Storage_Date__c)', 
													 'CALENDAR_MONTH(Storage_Date__c)'};
			queryFieldMap = new Map<String, String>();
			fieldsToGroupBy = new Set<String>();
			fieldsToGroupBy.addAll(defaultFields);
			fieldsToGroupBy.addAll(defaultAggregateFields);
			otherAggregateFields = otherAggregateFieldInput;
		}
		
		public String dbQuery {
			get {
				if (dbQuery == null){
					Boolean leadingComma = false;
					String exprPrefix = 'expr';
					dbQuery = 'SELECT ';
					
					for (String field : defaultFields){
						// fields with the same name ? 
						String fieldParsed = field.substringAfterLast('.');
						if (String.isBlank(fieldParsed)) fieldParsed = field;
						dbQuery += ( leadingComma ? ', ' + field : field) + ' ';
						queryFieldMap.put(fieldParsed, fieldParsed);
						if (!leadingComma) leadingComma = true;
					}
					Integer exprIndex = 0;
					for (String field : defaultAggregateFields){
						dbQuery += ( leadingComma ? ', ' + field : field) + ' ';
						queryFieldMap.put(field, exprPrefix+exprIndex);
						if (!leadingComma) leadingComma = true;
						exprIndex++;
					}
					for (String field : otherAggregateFields){
						dbQuery += ( leadingComma ? ', ' : '') + ' SUM(' + field + ') ';
						queryFieldMap.put(field, exprPrefix+exprIndex);
						if (!leadingComma) leadingComma = true;
						exprIndex++;
					}
					
					
					dbQuery += ' FROM Inbound_Storage__c WHERE Id in :allInboundStorage ';
					dbQuery += ' GROUP BY ';
					
					
					leadingComma = false;
					for (String field : fieldsToGroupBy){
						dbQuery += ( leadingComma ? ', ' + field : field) + ' ';
						if (!leadingComma) leadingComma = true;
					}
				}
				return dbQuery;
			}
			set; 
		}
		
		public String getExprIndex(String field){
			return queryFieldMap.get(field);
		}
		
		public List<AggregateResult> aggregatedResults {
			get {
				if (aggregatedResults == null && dbQuery != null){
					aggregatedResults = Database.query(dbQuery);
				}
				return aggregatedResults;
			}
			set;
		}
		
		
	}
	
	
	public void processAggregatedResults(List<Inbound_Storage__c> allInboundStorage){
		
  		InboundStorageDatabaseQueryBuilder qBuilder = new InboundStorageDatabaseQueryBuilder(allInboundStorage, InboundStorageFieldsToRollup);

		for (AggregateResult ar : qBuilder.aggregatedResults){
			System.debug('AR: ' + ar);
			Integer parsedAggregateYear = (Integer)ar.get(qBuilder.getExprIndex('CALENDAR_YEAR(Storage_Date__c)'));
			Integer parsedAggregateMonth = (Integer)ar.get(qBuilder.getExprIndex('CALENDAR_MONTH(Storage_Date__c)'));
			Id parsedAggregateTerritory = (Id)ar.get(qBuilder.getExprIndex('Territory__c'));
			Id parsedAggregateRecordTypeId = (Id)ar.get(qBuilder.getExprIndex('RecordTypeId'));
			
			if (InboundStorageRecordTypeIdToRecordType.containsKey(parsedAggregateRecordTypeId)){
				String parsedAggregateRecordTypeName = InboundStorageRecordTypeIdToRecordType.get(parsedAggregateRecordTypeId).DeveloperName;
				String hashTerritoryYearMonthKey = hashValues(parsedAggregateTerritory, parsedAggregateYear, parsedAggregateMonth, null, null);
				String hashTerritoryYearMonthKeyRecordType = hashValues(parsedAggregateTerritory, parsedAggregateYear, parsedAggregateMonth, parsedAggregateRecordTypeName, null);
				
				Territory_Snapshot__c currentTerritorySnapshot;
				
				if (!hashTerritoryYearMonth.containsKey(hashTerritoryYearMonthKey)){
					currentTerritorySnapshot = new Territory_Snapshot__c();
					currentTerritorySnapshot.Territory__c = parsedAggregateTerritory;
					currentTerritorySnapshot.Storage_Date__c = Date.newInstance(parsedAggregateYear, parsedAggregateMonth, 1); //yr,month,day
					hashTerritoryYearMonth.put(hashTerritoryYearMonthKey, currentTerritorySnapshot); 
				}
				
				currentTerritorySnapshot = hashTerritoryYearMonth.get(hashTerritoryYearMonthKey);
				
				for (String field : InboundStorageFieldsToRollupByRecordType.get(parsedAggregateRecordTypeName)){
					String hashTerritoryYearMonthKeyRecordTypeField = hashValues(parsedAggregateTerritory, parsedAggregateYear, parsedAggregateMonth, parsedAggregateRecordTypeName, field);
				
					Object parsedAggregateFieldValue = ar.get(qBuilder.getExprIndex(field));
					if (parsedAggregateFieldValue == null) parsedAggregateFieldValue = 0;
					if (!ytdTerritorySnapshotsByRecordType.containsKey(hashTerritoryYearMonthKeyRecordTypeField)){
						ytdTerritorySnapshotsByRecordType.put(hashTerritoryYearMonthKeyRecordTypeField, 0);
					}
					if (!parsedAggregateFieldValueTotalMap.containsKey(hashTerritoryYearMonthKeyRecordTypeField)){
						parsedAggregateFieldValueTotalMap.put(hashTerritoryYearMonthKeyRecordTypeField, 0);	
					}
					Decimal parsedAggregateFieldValueTotal = (Decimal)parsedAggregateFieldValue + (Decimal)parsedAggregateFieldValueTotalMap.get(hashTerritoryYearMonthKeyRecordTypeField);
					parsedAggregateFieldValueTotalMap.put(hashTerritoryYearMonthKeyRecordTypeField, parsedAggregateFieldValueTotal);
					String hashRecordTypeField = hashFields(parsedAggregateRecordTypeName, field);
					String TerritorySnapshotDestinationField = InboundStorageRecordTypeDevNameAndFieldToDestination.get(hashRecordTypeField);
					if (TerritorySnapshotDestinationField != null){
						currentTerritorySnapshot.put(TerritorySnapshotDestinationField, parsedAggregateFieldValueTotal);
					}
					if (InboundStorageFieldsToRollupYTD.contains(field)){
						ytdTerritorySnapshotsByRecordType.put(hashTerritoryYearMonthKeyRecordType, parsedAggregateFieldValueTotal);
					}
				}
			}
		}
	}
	
	
	
	public List<Territory_Snapshot__c> processTerritorySnapshots(){
		
		List<Territory_Snapshot__c> orderedTerritorySnapshots = bwdevutils.standardSortBy(hashTerritoryYearMonth.values(), 'Storage_Date__c', 'ASC');
		Map<String, Decimal> runningTotalByTerritoryAndRecordType = new Map<String, Decimal>();
		Map<String, Decimal> runningTotalByTerritoryAndRecordTypePrevious = new Map<String, Decimal>();
		Map<String, Territory_Snapshot__c> hashTerritoryCurrentYearMonth = new Map<String, Territory_Snapshot__c>();
		
		for (Territory_Snapshot__c currentSnapshot : orderedTerritorySnapshots){
			String snapshotTerritoryYearMonth = hashValues(currentSnapshot.Territory__c, currentSnapshot.Storage_Date__c.year(), currentSnapshot.Storage_Date__c.month(), null, null);
			
			for (Id aggregateRecordTypeId : InboundStorageRecordTypeIdToRecordType.keySet()){ 
				String snapshotTerritoryPreviousYearMonth = hashValues(currentSnapshot.Territory__c, currentSnapshot.Storage_Date__c.year()-1, currentSnapshot.Storage_Date__c.month(), null, null);
				String snapshotRecordTypeName = InboundStorageRecordTypeIdToRecordType.get(aggregateRecordTypeId).DeveloperName;
				
				String snapshotTerritoryRecordType = hashValues(currentSnapshot.Territory__c, currentSnapshot.Storage_Date__c.year(), null, snapshotRecordTypeName, null);
				String snapshotTerritoryRecordTypeYearMonth = hashValues(currentSnapshot.Territory__c, currentSnapshot.Storage_Date__c.year(), currentSnapshot.Storage_Date__c.month(), snapshotRecordTypeName, null);
				String snapshotTerritoryRecordTypePreviousYearMonth = hashValues(currentSnapshot.Territory__c, (currentSnapshot.Storage_Date__c.year()-1), currentSnapshot.Storage_Date__c.month(), snapshotRecordTypeName, null);
				
				if (!runningTotalByTerritoryAndRecordType.containsKey(snapshotTerritoryRecordType)){
					runningTotalByTerritoryAndRecordType.put(snapshotTerritoryRecordType, 0);
				}
				
				if (ytdTerritorySnapshotsByRecordType.containsKey(snapshotTerritoryRecordTypeYearMonth) ){
					
					String PYField = InboundYTDRecordTypeDestinationFields.get(snapshotRecordTypeName).get('PY');
					String CYField = InboundYTDRecordTypeDestinationFields.get(snapshotRecordTypeName).get('CY');
					
					runningTotalByTerritoryAndRecordType.put(snapshotTerritoryRecordType, runningTotalByTerritoryAndRecordType.get(snapshotTerritoryRecordType) + ytdTerritorySnapshotsByRecordType.get(snapshotTerritoryRecordTypeYearMonth));
					if (currentSnapshot.Storage_Date__c.year() == previousYear){
						runningTotalByTerritoryAndRecordTypePrevious.put(snapshotTerritoryRecordTypeYearMonth, runningTotalByTerritoryAndRecordType.get(snapshotTerritoryRecordType));
					}

					currentSnapshot.put(CYField,  runningTotalByTerritoryAndRecordType.get(snapshotTerritoryRecordType));
					if (currentSnapshot.Storage_Date__c.year() == currentYear){
						currentSnapshot.put(PYField,  runningTotalByTerritoryAndRecordTypePrevious.get(snapshotTerritoryRecordTypePreviousYearMonth));
					}

				}
				if (currentSnapshot.Storage_Date__c.year() == currentYear && currentSnapshot.Storage_Date__c.month() == currentMonth){
					hashTerritoryCurrentYearMonth.put(snapshotTerritoryYearMonth, currentSnapshot);
				}
			}
		}
		return hashTerritoryCurrentYearMonth.values();
	} 
	
	public static List<Territory_Snapshot__c> insertTerritorySnapshots(List<Territory_Snapshot__c> territorySnapshots, Database.BatchableContext BC){
		
		SafeDML snapshotsToInsert = new SafeInsert();
		ErrorHandling.ErrorLog errorHandling = new ErrorHandling.ErrorLog( );
		snapshotsToInsert.queue( territorySnapshots, errorHandling );
		snapshotsToInsert.doDML();
		
		AsyncApexJob job = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Firstname
                            from AsyncApexJob where Id = :BC.getJobId()];
		
		errorHandling.emailLog(new List<String>{job.CreatedBy.Email}, 'Updating Territory Snapshots on '+TerritorySnapshotBatch.TERRITORY_SNAPSHOT_BATCH_NAME + ' : ' + job.Status);
		
		return territorySnapshots;
	}
*/
}