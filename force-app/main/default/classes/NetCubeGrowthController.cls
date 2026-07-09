public class NetCubeGrowthController {
	
	public DashboardTerritoryLookup dtl;
	
	final static Integer ONE_MILLION = 1000000;
	final static Integer ONE_THOUSAND = 1000;
	@TestVisible final static String FORMULA_YES = 'YES';
	@TestVisible static String YTD_PERIOD_LABEL = 'YTD';
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
	
	public NetCubeGrowthController() {
		dtl = new DashboardTerritoryLookup();
	}
	public NetCubeGrowthController(String dashId) {
		dtl = new DashboardTerritoryLookup(dashId);
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
	
	
	@TestVisible private class NetCubeGrowthWrapper {
		
		public String periodLabel { get; set; }
		public Decimal beginningBalance { get; set; }
		public String beginningBalanceStr { 
			get {
				Boolean largerThanMillion = beginningBalance.abs() > ONE_MILLION;
				Integer divisor = largerThanMillion ? ONE_MILLION : ONE_THOUSAND; 
				Decimal beginningBalanceRouded = beginningBalance.divide(divisor, 2);
				return beginningBalanceRouded.format() + (largerThanMillion ? ' M' : ' K');
			}
			set; 
		}
		public Decimal netNewVolume { get; set; }
		public String netNewVolumeStr{ 
			get {
				Boolean largerThanMillion = netNewVolume.abs() > ONE_MILLION;
				Integer divisor = largerThanMillion ? ONE_MILLION : ONE_THOUSAND; 
				Decimal netNewVolumeRouded = netNewVolume.divide(divisor, 2);
				return netNewVolumeRouded.format() + (largerThanMillion ? ' M' : ' K');
			}
			set; 
		}
		public Decimal currentBalance { get; set; }
		public String currentBalanceStr { 
			get {
				Boolean largerThanMillion = currentBalance.abs() > ONE_MILLION;
				Integer divisor = largerThanMillion ? ONE_MILLION : ONE_THOUSAND; 
				Decimal currentBalanceRouded = currentBalance.divide(divisor, 2);
				return currentBalanceRouded.format() + (largerThanMillion ? ' M' : ' K');
			}
			set; 
		}
		public String style { get; set; }
		
		public NetCubeGrowthWrapper(String periodLabelValue){
			periodLabel = periodLabelValue;
			beginningBalance = 0;
			netNewVolume = 0;
			currentBalance = 0;
			style = '';
		}
	}
	
	public List<NetCubeGrowthWrapper> wrapperRecords {
		get{
			if (wrapperRecords == null){
				generateWrapperRecords();
			}
			return wrapperRecords;
		}
		set;
	}
	
	public void generateWrapperRecords(){
		
		List<Territory_Snapshot__c> previousMonthSnapshots = getPreviousMonthCubePeriodTerritorySnapshots();
		List<Territory_Snapshot__c> currentMonthSnapshots = getCurrentCubePeriodTerritorySnapshots();
		
		wrapperRecords = new List<NetCubeGrowthWrapper>();
		wrapperRecords.add(createCurrentMonthWrapperRecord(currentMonthSnapshots, previousMonthSnapshots));
		wrapperRecords.add(createYTDWrapperRecord(currentMonthSnapshots));
		
	}
	
	/*
	Pre: A list of current Territory_Snapshot__c with the following fields: 
		Id, Territory__c, Current_Cube_Period__c, Previous_Cube_Period__c,
		Total_Net_New_Cube__c, CM_End_Cube__c, PY_Total_Cube__c,
		Total_Inbound__c, Total_Destruction__c, Total_PW__c
	Post: A wrapper record 
	*/
	@TestVisible private NetCubeGrowthWrapper createCurrentMonthWrapperRecord(List<Territory_Snapshot__c> currentCubeSnapshots, List<Territory_Snapshot__c> previousMonthCubeSnapshots ){
		
		NetCubeGrowthWrapper wrapper = new NetCubeGrowthWrapper(DEFAULT_CURRENT_PERIOD_LABEL);
		for (Territory_Snapshot__c snapshot : previousMonthCubeSnapshots){
			wrapper.beginningBalance += snapshot.CM_End_Cube__c != null ? snapshot.CM_End_Cube__c : 0;
		}
		for (Territory_Snapshot__c snapshot : currentCubeSnapshots){
			wrapper.currentBalance += snapshot.CM_End_Cube__c != null ? snapshot.CM_End_Cube__c : 0;
		}
		wrapper.netNewVolume = wrapper.currentBalance - wrapper.beginningBalance;
		return wrapper;
	}
	
	/*
	Pre: A list of current Territory_Snapshot__c with the following fields:
		Id, Territory__c, Current_Cube_Period__c, Previous_Cube_Period__c,
		Total_Net_New_Cube__c, CM_End_Cube__c, PY_Total_Cube__c,
		Total_Inbound__c, Total_Destruction__c, Total_PW__c
	Post: A wrapper record 
	*/
	@TestVisible private NetCubeGrowthWrapper createYTDWrapperRecord(List<Territory_Snapshot__c> snapshots){
		
		NetCubeGrowthWrapper wrapper = new NetCubeGrowthWrapper(YTD_PERIOD_LABEL);
		for (Territory_Snapshot__c snapshot : snapshots){
			wrapper.beginningBalance += snapshot.PY_Total_Cube__c != null ? snapshot.PY_Total_Cube__c : 0;
			wrapper.currentBalance += snapshot.CM_End_Cube__c != null ? snapshot.CM_End_Cube__c : 0;
		}
		wrapper.netNewVolume = wrapper.currentBalance - wrapper.beginningBalance;
		wrapper.style = 'background-color:#eee;';
		return wrapper;
	}
	
	public List<Territory_Snapshot__c> getCurrentCubePeriodTerritorySnapshots(){
		List<Territory_Snapshot__c> snapshots = [
			Select Id, Territory__c, Current_Cube_Period__c, Previous_Cube_Period__c,
				Total_Net_New_Cube__c, CM_End_Cube__c, PY_Total_Cube__c,
				Total_Inbound__c, Total_Destruction__c, Total_PW__c
			From Territory_Snapshot__c 
			Where Current_Cube_Period__c = :FORMULA_YES
				AND Territory__c in :dtl.getBillingTerritoryIds()
			];
		return snapshots;
	}
	
	public List<Territory_Snapshot__c> getPreviousMonthCubePeriodTerritorySnapshots(){
		List<Territory_Snapshot__c> snapshots = [
			Select Id, Territory__c, Current_Cube_Period__c, Previous_Cube_Period__c,
				Total_Net_New_Cube__c, CM_End_Cube__c, PY_Total_Cube__c,
				Total_Inbound__c, Total_Destruction__c, Total_PW__c
			From Territory_Snapshot__c 
			Where Previous_Cube_Period__c = :FORMULA_YES
				AND Territory__c in :dtl.getBillingTerritoryIds()
			];
		return snapshots;
	}
	

}