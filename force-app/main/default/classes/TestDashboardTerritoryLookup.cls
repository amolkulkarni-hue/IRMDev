@isTest
public class TestDashboardTerritoryLookup {

	
	final static String INVALID_DASHBOARD_ID = 'invalid_dashboard_id';
	
	final static String VALID_DASHBOARD_ID_ONE = 'dashboard_id_one';
	final static String VALID_DASHBOARD_ID_TWO = 'dashboard_id_two';
	final static String VALID_DASHBOARD_ID_THREE = 'dashboard_id_three';
	final static String VALID_DASHBOARD_ID_FOUR = 'dashboard_id_four';
	
	final static List<String> VALID_BILLING_TERRITORY_NAMES = new List<String>{'test_territory_one', 'test_territory_two', 'test_territory_three'};
	final static List<String> VALID_BILLING_REGION_NAMES = new List<String>{'test_region_one', 'test_region_two'};
	
	static List<String> VALID_BILLING_TERRITORY_NAMES_PLUS_INVALID = VALID_BILLING_TERRITORY_NAMES.clone(); 
	static List<String> VALID_BILLING_REGION_NAMES_PLUS_INVALID = VALID_BILLING_REGION_NAMES.clone(); 
	
	static {
		
		VALID_BILLING_TERRITORY_NAMES_PLUS_INVALID.add('invalid_territory_here');
		VALID_BILLING_REGION_NAMES_PLUS_INVALID.add('invalid_region_here');
		
		List<Billing_Territory__c> billingTerritoriesByName = new List<Billing_Territory__c>();
		for (String billingTerritoryName : VALID_BILLING_TERRITORY_NAMES){
			billingTerritoriesByName.add(TestingUtils.createBillingTerritory(billingTerritoryName, 'TEST_REGION', false));
		}
		List<Billing_Territory__c> billingTerritoriesByRegion = new List<Billing_Territory__c>();
		for (String billingRegionName : VALID_BILLING_REGION_NAMES){
			billingTerritoriesByRegion.add(TestingUtils.createBillingTerritory('test_billing_territory_name', billingRegionName, false));
		}
		UnitTest.addData(billingTerritoriesByName).tag('Valid Billing Territories By Name').tag('Valid Billing Territories');
		UnitTest.addData(billingTerritoriesByRegion).tag('Valid Billing Territories By Region').tag('Valid Billing Territories');
		UnitTest.get('Valid Billing Territories').insertAll();
		
		
		// Set Up Custom Settings
		List<Territory_Dashboard_Component_Assignment__c> csList = new List<Territory_Dashboard_Component_Assignment__c>();
		csList.add(new Territory_Dashboard_Component_Assignment__c(
			Name='test1', 
			DashboardId__c = VALID_DASHBOARD_ID_ONE,
			Territory_Region__c=DashboardTerritoryLookup.TERRITORY,
			TerritoryNames__c = String.join(VALID_BILLING_TERRITORY_NAMES, ',')));
		csList.add(new Territory_Dashboard_Component_Assignment__c(
			Name='test2', 
			DashboardId__c = VALID_DASHBOARD_ID_TWO,
			Territory_Region__c=DashboardTerritoryLookup.REGION,
			TerritoryNames__c = String.join(VALID_BILLING_REGION_NAMES, ',')));
		csList.add(new Territory_Dashboard_Component_Assignment__c(
			Name='test3', 
			DashboardId__c = VALID_DASHBOARD_ID_THREE,
			Territory_Region__c=DashboardTerritoryLookup.REGION,
			TerritoryNames__c = String.join(VALID_BILLING_REGION_NAMES_PLUS_INVALID, ',')));
		csList.add(new Territory_Dashboard_Component_Assignment__c(
			Name='test4', 
			DashboardId__c = VALID_DASHBOARD_ID_FOUR,
			Territory_Region__c=DashboardTerritoryLookup.TERRITORY,
			TerritoryNames__c = String.join(VALID_BILLING_TERRITORY_NAMES_PLUS_INVALID, ',')));
		insert csList;
	}
	
	
	public testMethod static void testNoDashboardIdSet(){
		
		
		
		Test.startTest();
			DashboardTerritoryLookup dtl = new DashboardTerritoryLookup();
		Test.stopTest();
		
		System.assertEquals(false, dtl.isValidDashboardId(), 'We expect the dashboard territory lookup to be in an invalid state if no id is set');
		
	}
	
	
	public testMethod static void testInvalidDashboardIdSet(){
		
		
		DashboardTerritoryLookup dtl = new DashboardTerritoryLookup();
		
		Test.startTest();
			dtl.dashboardId = INVALID_DASHBOARD_ID;
			dtl.refreshDashboardFromCS();
		Test.stopTest();
		
		System.assertEquals(false, dtl.isValidDashboardId(), 'We expect the dashboard territory lookup to be in an invalid state if set with a dashboard id not in the custom settings');
		
	}
	
	public testMethod static void testValidDashboardIdSet(){
		
		
		DashboardTerritoryLookup dtl = new DashboardTerritoryLookup();
		dtl.dashboardId = VALID_DASHBOARD_ID_ONE;
		dtl.refreshDashboardFromCS();
		
		Test.startTest();
			List<Billing_Territory__c> actualDashboardTerritories = dtl.getBillingTerritoryIds();
		Test.stopTest();
		
		System.assertEquals(true, dtl.isValidDashboardId(), 'We expect the dashboard territory lookup to be in an valid state if set with a dashboard id in the custom settings');
		System.assertEquals(0, dtl.getRegions().size(), 'We expect to get back no territory region names to be selected when using test dashboard id one');
		System.assertEquals(VALID_BILLING_TERRITORY_NAMES.size(), dtl.getTerritories().size(), 'We expect to get back the correct territory names to be selected when using test dashboard id one');
		UnitTest.analyze('Valid Billing Territories By Name').assertEquivalence(actualDashboardTerritories, 'We expect the dashboard territory lookup to be in an valid state if set with a dashboard id in the custom settings');
		
	}
	
	
	public testMethod static void testGetTerritoriesByRegion(){
		
		
		DashboardTerritoryLookup dtl = new DashboardTerritoryLookup();
		dtl.dashboardId = VALID_DASHBOARD_ID_TWO;
		dtl.refreshDashboardFromCS();
		
		Test.startTest();
			List<Billing_Territory__c> actualDashboardTerritories = dtl.getBillingTerritoryIds();
		Test.stopTest();
		
		System.assertEquals(true, dtl.isValidDashboardId(), 'We expect the dashboard territory lookup to be in an valid state if set with a dashboard id in the custom settings');
		System.assertEquals(VALID_BILLING_REGION_NAMES.size(), dtl.getRegions().size(), 'We expect to get back the correct territory region names to be selected when using test dashboard id two');
		System.assertEquals(0, dtl.getTerritories().size(), 'We expect to get back no territory names to be selected when using test dashboard id two');
		UnitTest.analyze('Valid Billing Territories By Region').assertEquivalence(actualDashboardTerritories, 'We expect the dashboard territory lookup to be in an valid state if set with a dashboard id in the custom settings');
		
	}
	
	
	public testMethod static void testErrorOnInvalidRegionName(){
		
		
		DashboardTerritoryLookup dtl = new DashboardTerritoryLookup();
		dtl.dashboardId = VALID_DASHBOARD_ID_THREE;
		dtl.refreshDashboardFromCS();
		
		Test.startTest();
			List<Billing_Territory__c> actualDashboardTerritories = dtl.getBillingTerritoryIds();
		Test.stopTest();
		
		System.assertEquals(true, dtl.isValidDashboardId(), 'We expect the dashboard territory lookup to be in an valid state if set with a dashboard id in the custom settings');
		System.assert(TestingUtils.pageMessageContains(DashboardTerritoryLookup.INVALID_CUSTOM_SETTING_TERRITORY_NAME), 'Error message about invalid territory or region name should be displayed');
		
	}
	
	
	
	
	public testMethod static void testErrorOnInvalidTerritoryName(){
		
		
		DashboardTerritoryLookup dtl = new DashboardTerritoryLookup();
		dtl.dashboardId = VALID_DASHBOARD_ID_FOUR;
		dtl.refreshDashboardFromCS();
		
		Test.startTest();
			List<Billing_Territory__c> actualDashboardTerritories = dtl.getBillingTerritoryIds();
		Test.stopTest();
		
		System.assertEquals(true, dtl.isValidDashboardId(), 'We expect the dashboard territory lookup to be in an valid state if set with a dashboard id in the custom settings');
		System.assert(TestingUtils.pageMessageContains(DashboardTerritoryLookup.INVALID_CUSTOM_SETTING_TERRITORY_NAME), 'Error message about invalid territory or region name should be displayed');
		
	}
	
	
	
	
	
	
}