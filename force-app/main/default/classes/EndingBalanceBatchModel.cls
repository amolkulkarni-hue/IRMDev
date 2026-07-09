/* Commenting the entire code as part of Gitlab #24448 */
public class EndingBalanceBatchModel {
    public EndingBalanceBatchModel(){
        
    }
/* 
	private Date currentStorageDate;
	private Integer currentMonth;
	private Integer currentYear;
	
	@TestVisible private static String hashEndingBalanceKey(Id customerAccountId, Id billingMarketId, String deptId, String divId){
		return customerAccountId + '#' + billingMarketId + '#' + deptId + '#' + divId;
	}
	
	@TestVisible private Set<String> rtWhitelist {
		get{
			if (rtWhitelist == null){
				rtWhiteList = new Set<String>();
				for (InboundStorageRecordTypesReportWhitelist__c rt : InboundStorageRecordTypesReportWhitelist__c.getAll().values()){
					rtWhiteList.add(rt.DeveloperName__c);
				}
			}
			return rtWhiteList;
		}
		set;
	}
	private Set<String> rtWhitelistQuery {
		get{
			if (rtWhitelistQuery == null){
				rtWhitelistQuery = new Set<String>();
				for (String rtDeveloperName : rtWhiteList){
					rtWhitelistQuery.add('\''+rtDeveloperName+'\'');
				}
			}
			return rtWhitelistQuery;
		}
		set;
	}
	
	private String PadZeros(Integer Num, Integer Len) {
	  String s = String.valueOf(Num);
	  while (s.length() < Len) s = '0' + s;
	  return s;
	}

	public String buildDatabaseQuery(){ 
		
		String dbQuery = 'SELECT Id, Storage_Date__c, Customer_Account__c, Cube_District__c, Dept_ID_del__c, Div_ID_del__c, RecordType.DeveloperName ' + getInboundStorageFieldsForQuery 
      					+ ' FROM Inbound_Storage__c WHERE Cube_District__c != null AND Customer_Account__c != null AND Storage_Date__c <= '+PadZeros(currentYear, 2)+'-'+PadZeros(currentMonth, 2)+'-01 ' 
      					+ ' AND RecordType.DeveloperName in ( ' + String.join(new List<String>(rtWhitelistQuery), ',') +' ) ORDER BY Storage_Date__c DESC';		
		return dbQuery;
	}
	
	public EndingBalanceBatchModel(){
		this(Integer.valueOf(Label.Current_Commission_Year), Integer.valueOf(Label.BoB_M2_End_Period));
	}
	
	public EndingBalanceBatchModel(Integer year, Integer month){
		currentMonth = month;
		currentYear = year;
		currentStorageDate = Date.newInstance(currentYear, currentMonth, 1);
	}
	
	public Set<String> getInboundStorageFieldsFromCS(){
		
		Set<String> inboundFields = new Set<String>();
		for (Current_Ending_Balance_Mapping__c endingBalanceMapping : Current_Ending_Balance_Mapping__c.getAll().values()){
			String mapFieldFromLatestInboundStorage = (String)endingBalanceMapping.get('Map_From_Field__c');
			inboundFields.add(mapFieldFromLatestInboundStorage);
		}
		return inboundFields;
	}
	
	public String getInboundStorageFieldsForQuery {
		get {
			if (getInboundStorageFieldsForQuery == null){
				String queryFields = ', ';
				queryFields += String.join(new List<String>(getInboundStorageFieldsFromCS()), ', ');
				getInboundStorageFieldsForQuery = queryFields; 
			}
			return getInboundStorageFieldsForQuery;
		}
		set;
	}
	
	public void processAggregatedResults(List<Inbound_Storage__c> allInboundStorage, ErrorHandling.ErrorLog errorHandling){
		
		Map<String, Current_Ending_Balance__c> customerAccountBillingMarketToEndingBalance = new Map<String, Current_Ending_Balance__c>();	
		
		Set<Id> scopedCustomerAccountIds =  new Set<Id>();  
		Set<Id> scopedBillingMarketIds =  new Set<Id>();  	 
		Set<String> scopedDeptIds =  new Set<String>();  	 
		Set<String> scopedDivIds = new Set<String>(); 	
		 
		for (Inbound_Storage__c inbound : allInboundStorage){
			if (inbound.Customer_Account__c != null) 
				scopedCustomerAccountIds.add(inbound.Customer_Account__c);
			if (inbound.Customer_Account__c != null) 
				scopedBillingMarketIds.add(inbound.Cube_District__c);
			if (inbound.Customer_Account__c != null) 
				scopedDeptIds.add(inbound.Dept_ID_del__c);
			if (inbound.Customer_Account__c != null) 
				scopedDivIds.add(inbound.Div_ID_del__c);
		}
		
		Set<String> previouslyProcessedCurrentEndingBalances = new Set<String>();
		List<Current_Ending_Balance__c> listCurrentEndingBalancesDB = [Select Customer_Account__c, Billing_Market__c, Department__c, Division__c  From Current_Ending_Balance__c 
																		Where Storage_Date__c = :currentStorageDate AND Billing_Market__c in :scopedBillingMarketIds 
																			AND Customer_Account__c in :scopedCustomerAccountIds
																			AND Department__c in :scopedDeptIds
																			AND Division__c in :scopedDivIds ];
																			
		for (Current_Ending_Balance__c endingBalance : listCurrentEndingBalancesDB){
			previouslyProcessedCurrentEndingBalances.add(hashEndingBalanceKey(endingBalance.Customer_Account__c, endingBalance.Billing_Market__c, endingBalance.Department__c, endingBalance.Division__c));
		
		}
		
		System.debug('InboundStorages for this block: ' + allInboundStorage.size());
		for (Inbound_Storage__c inbound : allInboundStorage){
			
			String hashCustomerAccountBillingMarketKey = hashEndingBalanceKey(inbound.Customer_Account__c, inbound.Cube_District__c, inbound.Dept_ID_del__c, inbound.Div_ID_del__c);
			
			// first encountered pair, that inbound is the latest when query orderby storage date 
			if (!customerAccountBillingMarketToEndingBalance.containsKey(hashCustomerAccountBillingMarketKey) && !previouslyProcessedCurrentEndingBalances.contains(hashCustomerAccountBillingMarketKey) ){ 
	
				customerAccountBillingMarketToEndingBalance.put(hashCustomerAccountBillingMarketKey, 
						new Current_Ending_Balance__c(Customer_Account__c = inbound.Customer_Account__c, Billing_Market__c = inbound.Cube_District__c, Storage_Date__c = currentStorageDate, 
																	Department__c = inbound.Dept_ID_del__c, Division__c = inbound.Div_ID_del__c));
				customerAccountBillingMarketToEndingBalance.get(hashCustomerAccountBillingMarketKey).put('Last_Month_with_Cube__c', inbound.Storage_Date__c );
				for (Current_Ending_Balance_Mapping__c endingBalanceMapping : Current_Ending_Balance_Mapping__c.getAll().values()){
					String mapFieldFromLatestInboundStorage = (String)endingBalanceMapping.get('Map_From_Field__c');
					String mapToEndingBalanceField = (String)endingBalanceMapping.get('Map_To_Field__c');
					
					customerAccountBillingMarketToEndingBalance.get(hashCustomerAccountBillingMarketKey).put(mapToEndingBalanceField, inbound.get(mapFieldFromLatestInboundStorage));
				}
				
			}			
		}

		SafeDML endingBalancesToInsert = new SafeInsert();
		endingBalancesToInsert.queue( customerAccountBillingMarketToEndingBalance.values() , errorHandling );
		endingBalancesToInsert.doDML();
		
	}

	public void sendErrorNotifications(Database.BatchableContext BC, ErrorHandling.ErrorLog errorHandling){
		
		if(errorHandling.areThereErrors()){
			AsyncApexJob job = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, CreatedBy.Firstname
                            from AsyncApexJob where Id = :BC.getJobId()];   
			errorHandling.emailLog(new List<String>{'jay.jackson@bluewolf.com', 'joo.kang@bluewolf.com', job.CreatedBy.Email}, 'Errors from Ending Balance Batch');
		}
	} */
}