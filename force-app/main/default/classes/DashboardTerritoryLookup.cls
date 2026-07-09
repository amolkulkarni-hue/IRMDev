public class DashboardTerritoryLookup {
	
	public final static String REGION = 'Region';
	public final static String TERRITORY = 'Territory';
	@TestVisible static String INVALID_CUSTOM_SETTING_TERRITORY_NAME = 'There is an invalid territory or region name being used in the custom setting Territory Dashboard Component Assignment.';
	@TestVisible static String INVALID_DASHBOARD_ERROR = 'An invalid dashboard id used on Net Cube Growth Component dashboard.';
	
	public Set<String> territoryNames {get; set;}
	public Set<String> regionNames {get; set;}
	private Set<String> validDashboards {get; set;}
	
	public String dashboardId { 
		get; 
		set {
			dashboardId = value;
			refreshDashboardFromCS();
		} 
	} 
	
	public DashboardTerritoryLookup() {
		refreshDashboardFromCS();
	}
	public DashboardTerritoryLookup(String dashId) {
		dashboardId = dashId;
	}
	
	public void refreshDashboardFromCS()
	{
		validDashboards = new Set<String>();
		territoryNames = new Set<String>();
		regionNames = new Set<String>();
		for (Territory_Dashboard_Component_Assignment__c cs : Territory_Dashboard_Component_Assignment__c.getAll().values() ){
			validDashboards.add(cs.DashboardId__c);
			if (cs.DashboardId__c == dashboardId){
				for (String terrtitory : cs.TerritoryNames__c.split(',')){
					if (!String.isBlank(terrtitory)){
						if (cs.Territory_Region__c == REGION){
							regionNames.add(terrtitory.trim());
						}
						else if (cs.Territory_Region__c == TERRITORY){
							territoryNames.add(terrtitory.trim());
						}
					}
				}
			}
		}
	}
	
	public Boolean isValidDashboardId() {
		return validDashboards.contains(dashboardId);
	}
	
	public List<Billing_Territory__c> getBillingTerritoryIds(){
		List<Billing_Territory__c> allTerritories = new List<Billing_Territory__c>();
		allTerritories.addAll(getTerritories());
		allTerritories.addAll(getRegions());
		return allTerritories;
		
	}
	
	@testVisible private List<Billing_Territory__c> getRegions(){
		
		List<Billing_Territory__c> billingTerritories = [Select Id, Name, Region__c From Billing_Territory__c Where Region__c in :regionNames];
		if (billingTerritories.size() != regionNames.size()){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, INVALID_CUSTOM_SETTING_TERRITORY_NAME));
		}
		return billingTerritories;
	}
	
	
	@testVisible private List<Billing_Territory__c> getTerritories() {
		
		List<Billing_Territory__c> billingTerritories = [Select Id, Name, Region__c From Billing_Territory__c Where Name in :territoryNames];
		if (billingTerritories.size() != territoryNames.size()){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, INVALID_CUSTOM_SETTING_TERRITORY_NAME));
		}
		return billingTerritories;
	}

}