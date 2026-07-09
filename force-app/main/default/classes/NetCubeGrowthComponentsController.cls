public class NetCubeGrowthComponentsController {
	
	public DashboardTerritoryLookup dtl;
	
	final static Integer ONE_MILLION = 1000000;
	final static Integer ONE_THOUSAND = 1000;
	@TestVisible static String YTD_PERIOD_LABEL = 'YTD';
	@TestVisible static String NO_TERRITORY_SNAPSHOTS_FOUND = 'No territory snapshots were found for the specified territories.';
	@TestVisible static String DEFAULT_CURRENT_PERIOD_LABEL {
		get{
			 if (DEFAULT_CURRENT_PERIOD_LABEL == null){
			 	if (Label.Current_Cube_Year.isNumeric() && Label.Current_End_Cube_Period.isNumeric()){
			 		Datetime d = Datetime.newInstance(Integer.valueOf(Label.Current_Cube_Year), Integer.valueOf(Label.Current_End_Cube_Period), 1);
			 		DEFAULT_CURRENT_PERIOD_LABEL = d.format('MMMMM yyyy');
			 	}
			 	else {
			 		DEFAULT_CURRENT_PERIOD_LABEL = 'Current Billing Period';
			 	}
			 }
			 return DEFAULT_CURRENT_PERIOD_LABEL;
		}
		set;
	}
	
	public NetCubeGrowthComponentsController() {
		dtl = new DashboardTerritoryLookup();
	}
	
	public NetCubeGrowthComponentsController(String dashboardIdToUse){
		dtl = new DashboardTerritoryLookup(dashboardIdToUse);
	}
	
	public String dashboardId {
		get {
			return dtl.dashboardId;
		}
		set {
			dtl.dashboardId = value;
		}
	}
	public Boolean isValidDashboardId {
		get {
			return dtl.isValidDashboardId();
		}
	}
	
	
	@TestVisible private class NetCubeGrowthComponentWrapper {
		
		public String periodLabel { get; set; }
		public String style { get; set; }
		public Decimal inboundTotalVolume { get; set; }
		public String inboundTotalVolumeStr { 
			get {
				Boolean largerThanMillion = inboundTotalVolume.abs() > ONE_MILLION;
				Integer divisor = largerThanMillion ? ONE_MILLION : ONE_THOUSAND; 
				Decimal inboundTotalVolumeRouded = inboundTotalVolume.divide(divisor, 2);
				return inboundTotalVolumeRouded.format() + (largerThanMillion ? ' M' : ' K');
			} 
			set; 
		}
		public Decimal pwTotalVolume { get; set; }
		public String pwTotalVolumeStr { 
			get {
				Boolean largerThanMillion = pwTotalVolume.abs() > ONE_MILLION;
				Integer divisor = largerThanMillion ? ONE_MILLION : ONE_THOUSAND; 
				Decimal pwTotalVolumeRouded = pwTotalVolume.divide(divisor, 2);
				return pwTotalVolumeRouded.format() + (largerThanMillion ? ' M' : ' K');
			}
			set; 
		}
		public Decimal destructionTotalVolume { get; set; }
		public String destructionTotalVolumeStr { 
			get {
				Boolean largerThanMillion = destructionTotalVolume.abs() > ONE_MILLION;
				Integer divisor = largerThanMillion ? ONE_MILLION : ONE_THOUSAND; 
				Decimal destructionTotalVolumeRouded = destructionTotalVolume.divide(divisor, 2);
				return destructionTotalVolumeRouded.format() + (largerThanMillion ? ' M' : ' K');
			} 
			set; 
		}
		public Decimal netNewCubeTotalVolume { get; set; }
		public String netNewCubeTotalVolumeStr { 
			get {
				Boolean largerThanMillion = netNewCubeTotalVolume.abs() > ONE_MILLION;
				Integer divisor = largerThanMillion ? ONE_MILLION : ONE_THOUSAND; 
				Decimal netNewCubeTotalVolumeRouded = netNewCubeTotalVolume.divide(divisor, 2);
				return netNewCubeTotalVolumeRouded.format() + (largerThanMillion ? ' M' : ' K');
			}
			set; 
		}
		
		public NetCubeGrowthComponentWrapper(String periodLabelValue){
			periodLabel = periodLabelValue;
			inboundTotalVolume = 0;
			pwTotalVolume = 0;
			destructionTotalVolume = 0;
			netNewCubeTotalVolume = 0;
			style = '';
		}
	}
	
	
	
	public List<NetCubeGrowthComponentWrapper> wrapperRecords {
		
		get{
			if (wrapperRecords == null){
				generateWrapperRecords();
			}
			return wrapperRecords;
		}
		set;
		
	}
	
	public void generateWrapperRecords(){
		List<Territory_Snapshot__c> validSnapshots = getCurrentBillingPeriodSnapshots();
		
		wrapperRecords = new List<NetCubeGrowthComponentWrapper>();
		wrapperRecords.add(createCurrentMonthWrapperRecord(validSnapshots));
		wrapperRecords.add(createYTDWrapperRecord(validSnapshots));
		
	}
	
	/*
	Pre: A list of territory snapshots with the following fields requested: 
			Storage_Date__c, Total_Inbound__c, Total_PW__c, Total_Net_New_Cube__c, Total_Destruction__c
			- Assumption: All Territory Snapshots have the same storage date:  
				Current Month, Current Year, and 1st of the month
	Post: A wrapper record with all of the non-YTD fields aggregated: 
			Total_Inbound__c, Total_PW__c, Total_Net_New_Cube__c, Total_Destruction__c
	*/
	public NetCubeGrowthComponentWrapper createCurrentMonthWrapperRecord(List<Territory_Snapshot__c> snapshots){
		
		NetCubeGrowthComponentWrapper wrapper = new NetCubeGrowthComponentWrapper(DEFAULT_CURRENT_PERIOD_LABEL);
		for (Territory_Snapshot__c snapshot : snapshots){
			if (snapshot.Total_Inbound__c != null)
				wrapper.inboundTotalVolume += snapshot.Total_Inbound__c;
			if (snapshot.Total_PW__c != null)
				wrapper.pwTotalVolume += snapshot.Total_PW__c;
			if (snapshot.Total_Destruction__c != null)
				wrapper.destructionTotalVolume += snapshot.Total_Destruction__c;
			if (snapshot.Total_Net_New_Cube__c != null)
				wrapper.netNewCubeTotalVolume += snapshot.Total_Net_New_Cube__c;
		}
		return wrapper;
	}
	
	/*
	Pre: A list of territory snapshots with the following fields requested:
			CY_YTD_Inbound_Cube__c, CY_YTD_PW__c, CY_YTD_Destruction__c, CY_YTD_Net_Cube_w_o_Aqui__c
	Post: A wrapper record with all of the YTD fields aggregated: 
			CY_YTD_Inbound_Cube__c, CY_YTD_PW__c, CY_YTD_Destruction__c, CY_YTD_Net_Cube_w_o_Aqui__c
	*/
	public NetCubeGrowthComponentWrapper createYTDWrapperRecord(List<Territory_Snapshot__c> snapshots){
		NetCubeGrowthComponentWrapper wrapper = new NetCubeGrowthComponentWrapper(YTD_PERIOD_LABEL);
		for (Territory_Snapshot__c snapshot : snapshots){
			if (snapshot.CY_YTD_Inbound_Cube__c != null)
				wrapper.inboundTotalVolume += snapshot.CY_YTD_Inbound_Cube__c;
			if (snapshot.CY_YTD_PW__c != null)
				wrapper.pwTotalVolume += snapshot.CY_YTD_PW__c;
			if (snapshot.CY_YTD_Destruction__c != null)
				wrapper.destructionTotalVolume += snapshot.CY_YTD_Destruction__c;
			if (snapshot.CY_YTD_Net_Cube_w_o_Aqui__c != null)
				wrapper.netNewCubeTotalVolume += snapshot.CY_YTD_Net_Cube_w_o_Aqui__c;
		}
		wrapper.style = 'background-color:#eee;';
		return wrapper;
	}
	

	
	public List<Territory_Snapshot__c> getCurrentBillingPeriodSnapshots(){
		
		List<Territory_Snapshot__c> snapshots = [Select Id, Territory__c, Total_Inbound__c, 
															Total_PW__c, Total_Net_New_Cube__c, 
															Total_Destruction__c, CY_YTD_Inbound_Cube__c, 
															CY_YTD_PW__c, CY_YTD_Destruction__c, 
															CY_YTD_Net_Cube_w_o_Aqui__c,
															Storage_Date__c
													From Territory_Snapshot__c 
													Where Current_Cube_Period__c = 'YES'
														AND Territory__c in :dtl.getBillingTerritoryIds()];
		if (snapshots.isEmpty()){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, NO_TERRITORY_SNAPSHOTS_FOUND));
		}
		return snapshots;
	}
	
	
	
}