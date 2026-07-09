/* Commenting the entire code as part of Gitlab #24448 */
global without sharing class M1_Physical_CDE_Batch{
    public M1_Physical_CDE_Batch(){
        
    }
}
/*
global without sharing class M1_Physical_CDE_Batch implements Database.Batchable<SOBject>, Database.Stateful  {

    // external classes
    private InboundStorageToBoBCoverage_Log    logger;
    private InboundStorageToBoBCoverage_Helper helper;    
    private final static String   moduleName       = 'M1_Physical_CDE_Batch';
    private final static String   IMGA_PREFIX      = 'IM_';  
    private final static Integer  MAX_PERIODS      = 12;      // months
    private final static Integer  START_PERIOD     = 1;
    private final static Integer  END_PERIOD       = 12;
    private final static Integer  DML_ROW_LIMIT    = Limits.getLimitDMLRows() - 30;  // leave room for log insertions
    private final        String   SCHAR            = ';';
    private final        String   PRIMARY          = '';
    private final        String   NO_CID           = '';
    private final        DateTime DUMMY_TIME       = DateTime.newInstance(1970, 1, 1);
    
    // runtime config parameters
    private M1_CDE_Settings__c settings; 
    private Long                          flushAfterExecutes;  // periodic flushing of log entries
    private string customSettingName;
    private integer heapSizeMax;
    
    // effective timeframe, defaulting to entire year
    private final String  effectiveYearText;
    private final Integer effectiveYear; 
    private final String  priorYearText;
    private final Integer priorYear;
    private       Integer startPeriod = 1;
    private       Integer endPeriod   = 12;  
    private       List<Aggregate_Volume__c> volumes;
	private 	  Map<String, InboundStorageToBoBCoverage_Log.EmailErrorMapping> emailErrorMap;
	
    global M1_Physical_CDE_Batch (String useThisCustomSetting, String jobId) {
     
		emailErrorMap = new Map<String, InboundStorageToBoBCoverage_Log.EmailErrorMapping>();
		
        customSettingName = useThisCustomSetting;
        settings = M1_CDE_Settings__c.getInstance(customSettingName);
        
        logger = new InboundStorageToBoBCoverage_Log(customSettingName);
        System.debug('Logger ' + logger);
        helper = new InboundStorageToBoBCoverage_Helper(customSettingName);
        logger.setJobId(jobId);      
        logger.setLogImmediate(true, false, false, true, false); 
        logger.newEntry(moduleName, 'Info', 'settings', String.valueOf(settings) + ', ' + 
            DML_ROW_LIMIT, -1);                 
        helper.postToChatterGroup(settings.chatter_group_name__c, System.label.M1_Batch_Job_Start_Message);
        
        
        effectiveYearText = settings.Focus_Year__c;
        effectiveYear     = Integer.valueOf(effectiveYearText);
        priorYear         = effectiveYear - 1;
        priorYearText     = String.valueOf(priorYear);     
        startPeriod       = Integer.valueOf(settings.Focus_Start_Period__c);
        endPeriod         = Integer.valueOf(settings.Focus_End_Period__c); 
      
        
        // validate the start/end period values       
        if (this.endPeriod >= this.startPeriod) {
            logger.newEntry(moduleName, 'Info', 'effective period', String.valueOf(this.effectiveYear) + 
                ': ' + String.valueOf(this.startPeriod) + ' -> ' + String.valueOf(this.endPeriod) + ', ' +
                String.valueOf(this.priorYear) + ': 1 -> 12', -1); 
        }
        else {  
            logger.newEntry(moduleName, 'Error', 'end period earlier than start', 'years: ' + 
                String.valueOf(this.startPeriod) + ', ' + String.valueOf(this.endPeriod), -1);  
        } 
        
    }

	global Database.QueryLocator start(Database.BatchableContext batch) {
		
		heapSizeMax = Limits.getHeapSize();
        logger.newEntry(moduleName, 'Info', 'started, heap size: ', String.valueOf(heapSizeMax), -1); 
		String fullQuery = '   SELECT ' + settings.Query_Associate_Select__c   +                                      +  
                           '     FROM Inbound_Storage__c ';

        // append the multi-part additions (if any) to the WHERE clause 
        if (String.isNotEmpty(settings.Query_Associate_Where__c)) { 
            fullQuery += ' WHERE ' + settings.Query_Associate_Where__c + ' AND (';
        } else {
            fullQuery += ' WHERE (';
        }
         
        fullQuery += '(Storage_year__c = \'' + effectiveYearText + '\' AND Storage_Month__c >=' + startPeriod + 'AND Storage_Month__c <=' + endPeriod
                  +  ') OR  Storage_year__c =\'' + priorYearText + '\' ) ' ;  
       
        
                    
        // append the ORDER BY clause (if any)
        // This can negatively impact performance!                  
        if (String.isNotEmpty(settings.Query_Associate_Order_By__c))
            fullQuery += ' ORDER BY ' + settings.Query_Associate_Order_By__c;
        
        logger.newEntry(moduleName, 'Info', 'query', fullQuery, -1);
       	System.debug(fullQuery);
        return Database.getQueryLocator(fullQuery); 
	}
	
	global void execute(Database.BatchableContext batch, List<Inbound_Storage__c> storageRecords){
		
		Map<String, Map<Id, Map<String, Aggregate_Volume__c>>> coverageMap = new Map<String, Map<Id, Map<String, Aggregate_Volume__c>>>();
		
		Set<String> coverageQueryGeneralHashSet = helper.buildGeneralHashForInboundStorageRecords (storageRecords);
		
		Map<Id, List<String>> storageToHashes = new Map<Id, List<String>>();
		Set<String> allStorageHashes = new Set<String>();
		
		Map<String, Aggregate_Volume__c> existingRelevantVolumes = new Map<String, Aggregate_Volume__c>();
		
		//To perform updates, we will query for the volume records using a formula hash
		for( Inbound_Storage__c storage : storageRecords)
		{
			List<String> hashesForStorage = helper.buildHashForInboundStorageRecord ( storage );
			
			String marketSpecificHash = hashesForStorage.size() == 2 ? hashesForStorage[1] : null;
			
			allStorageHashes.addAll( hashesForStorage );
			
			storageToHashes.put( storage.Id, hashesForStorage );
		}
		
		
		List<BoB_Coverage_Eligible__c> allCoverages =  helper.findAllCoveragesForCYSettingsRange( effectiveYearText, coverageQueryGeneralHashSet );
		
        helper.buildCoverageMap(allCoverages, coverageMap);
		
		Map<String, List<Aggregate_Volume__c>> inboundHashToExistingVolumeMap = new Map<String, List<Aggregate_Volume__c>>();
		
		for( Aggregate_Volume__c volumeFound : [ SELECT Id, Total_Volume__c, Inbound_Storage_Matching_Hash__c, BoB_Coverage_Eligible__c FROM Aggregate_Volume__c WHERE BOB_Coverage_Eligible__C in : allCoverages ])
		{
			if( !inboundHashToExistingVolumeMap.containsKey( volumeFound.Inbound_Storage_Matching_Hash__c ) )
				inboundHashToExistingVolumeMap.put( volumeFound.Inbound_Storage_Matching_Hash__c, new List<Aggregate_Volume__c>{ volumeFound } );
			else
				{
					List<Aggregate_Volume__c> existingList = inboundHashToExistingVolumeMap.get( volumeFound.Inbound_Storage_Matching_Hash__c );
					existingList.add( volumeFound );
					inboundHashToExistingVolumeMap.put( volumeFound.Inbound_Storage_Matching_Hash__c, existingList );
				}
		}
				
		//Lets use the covergare map only for creating volumes
		//This way we can clear it at the end of the execute block
		
		Map<String, Aggregate_Volume__c> uniqueVolumesToUpsert = new Map<String, Aggregate_Volume__c>();
		
		

		
		for(Inbound_Storage__c storage :  storageRecords) {
	    	helper.buildVolumeRecordsAndPopulateCoverageMap( coverageMap, storage, uniqueVolumesToUpsert, inboundHashToExistingVolumeMap, storageToHashes.get( storage.Id ));
		}
		
		List<Aggregate_Volume__c> volumesToUpsert = uniqueVolumesToUpsert.values();
		
		logger.buildErrorMappingFromResults( emailErrorMap, Database.upsert( volumesToUpsert, false ), volumesToUpsert );
		
		System.debug( 'Heap Size --> ' + Limits.getHeapSize() );
		
	}
	
	global void finish(Database.BatchableContext batch){
		
		logger.reportDatabaseFailuresToDatabase ( emailErrorMap, 'Upsert', moduleName);
		helper.postToChatterGroup(settings.chatter_group_name__c, System.label.M1_Batch_Job_Completion_Message);
		
	}
	
}*/