@isTest
private class TestNetCubeGrowthComponentsController {
	
	private static Integer currentYear = Integer.valueOf(Label.Current_Cube_Year); 
	private static Integer currentMonth = Integer.valueOf(Label.Current_End_Cube_Period); 
	private static Date currentStorageDate = Date.newInstance(currentYear, currentMonth, 1);
	private static Datetime currentStorageDatetime = Datetime.newInstance(currentYear, currentMonth, 1);
	
	
	final static String DASHBOARD_ID_ONE = 'dashboard_id_one';
	final static String DASHBOARD_ID_TWO = 'dashboard_two';
	final static String DASHBOARD_ID_THREE = 'dashboard_three';
	
	final static List<String> BILLING_TERRITORY_NAMES = new List<String>{'test_territory_one', 'test_territory_two', 'test_territory_three'};
	final static List<String> INVALID_BILLING_TERRITORY_NAMES = new List<String>{'test_invalid_territory_one'};
	
	final static List<String> DASHBOARD_ID_ONE_TERRITORIES = new List<String>{BILLING_TERRITORY_NAMES[0], BILLING_TERRITORY_NAMES[1], BILLING_TERRITORY_NAMES[2]};
	final static List<String> DASHBOARD_ID_TWO_TERRITORIES = new List<String>{BILLING_TERRITORY_NAMES[0]};
	final static List<String> DASHBOARD_ID_THREE_TERRITORIES = new List<String>{BILLING_TERRITORY_NAMES[0], BILLING_TERRITORY_NAMES[1]};
	
	static {
		
		
		
		List<Territory_Dashboard_Component_Assignment__c> csList = new List<Territory_Dashboard_Component_Assignment__c>();
		csList.add(new Territory_Dashboard_Component_Assignment__c(Name='test1', DashboardId__c = DASHBOARD_ID_ONE, Territory_Region__c = DashboardTerritoryLookup.TERRITORY, TerritoryNames__c=String.join(DASHBOARD_ID_ONE_TERRITORIES, ',')));
		csList.add(new Territory_Dashboard_Component_Assignment__c(Name='test2', DashboardId__c = DASHBOARD_ID_TWO, Territory_Region__c = DashboardTerritoryLookup.TERRITORY, TerritoryNames__c=String.join(DASHBOARD_ID_TWO_TERRITORIES, ',')));
		csList.add(new Territory_Dashboard_Component_Assignment__c(Name='test3', DashboardId__c = DASHBOARD_ID_THREE, Territory_Region__c = DashboardTerritoryLookup.TERRITORY, TerritoryNames__c=String.join(DASHBOARD_ID_THREE_TERRITORIES, ',')));
		insert csList;
		
		List<Billing_Territory__c> billingTerritories = new List<Billing_Territory__c>();
		for (String billingTerritoryName : BILLING_TERRITORY_NAMES){
			billingTerritories.add(TestingUtils.createBillingTerritory(billingTerritoryName, 'TEST_REGION', false));
		}
		UnitTest.addData(billingTerritories).tag('Valid Billing Territories').tag('Billing Territories');

		List<Billing_Territory__c> invalidBillingTerritories = new List<Billing_Territory__c>();
		for (String billingTerritoryName : INVALID_BILLING_TERRITORY_NAMES){
			invalidBillingTerritories.add(TestingUtils.createBillingTerritory(billingTerritoryName, 'TEST_REGION', false));
		}
		UnitTest.addData(invalidBillingTerritories).tag('Invalid Billing Territories').tag('Billing Territories');
		UnitTest.get('Billing Territories').insertAll();
	}
	
	
	
	static testMethod void testGetCurrentBillingPeriodSnapshots(){
		
		List<Territory_Snapshot__c> territorySnapshots = TestingUtils.createTerritorySnapshots(200, null, false);
		
		UnitTest.addData(territorySnapshots).tag('Territory Snapshots').divide(4)
			.part('Snapshots In Current And Valid Territory') 
			.part('Snapshots Not In Current And Valid Territory')
			.part('Snapshots In Current And Invalid Territory')
			.part('Snapshots Not Current And Invalid Territory');
		
		UnitTest.get('Snapshots In Current And Valid Territory')
			.property('Storage_Date__c').assign(currentStorageDate)
			.property('Territory__c').assignFrom('Valid Billing Territories'); 
		UnitTest.get('Snapshots Not In Current And Valid Territory')
			.property('Storage_Date__c').assignFrom(
				new List<Date>{currentStorageDate.addMonths(2), currentStorageDate.addYears(-1)})
			.property('Territory__c').assignFrom('Valid Billing Territories');
		UnitTest.get('Snapshots In Current And Invalid Territory')
			.property('Storage_Date__c').assign(currentStorageDate)
			.property('Territory__c').assignFrom('Invalid Billing Territories');
		UnitTest.get('Snapshots Not Current And Invalid Territory')
			.property('Storage_Date__c').assign(currentStorageDate.addMonths(-1))
			.property('Territory__c').assignFrom('Invalid Billing Territories');
		
		UnitTest.get('Territory Snapshots').insertAll();
		
		NetCubeGrowthComponentsController controller = new NetCubeGrowthComponentsController(DASHBOARD_ID_ONE);
		
		Test.startTest();
			List<Territory_Snapshot__c> actualTerritorySnapshots = controller.getCurrentBillingPeriodSnapshots();
		Test.stopTest();
		
		UnitTest.analyze('Snapshots In Current And Valid Territory').assertEquivalence(actualTerritorySnapshots, 'We expect to get back the territory snapshots within the current billing period and within valid territories ');
		for(Territory_Snapshot__c snapshot : actualTerritorySnapshots) {
			System.assertEquals(UnitTest.analyze('Snapshots In Current And Valid Territory').selectById(snapshot.Id).getPropertyValue('Territory__c'), snapshot.Territory__c);
		}
	}

	static testMethod void testGetZeroCurrentBillingPeriodSnapshots() {
		
		List<Territory_Snapshot__c> territorySnapshots = TestingUtils.createTerritorySnapshots(200, null, false);

		UnitTest.addData(territorySnapshots).tag('Territory Snapshots That Do Not Meet Criteria').divide(3)
			.part('Snapshots Not In Current And Valid Territory')
			.part('Snapshots In Current And Invalid Territory')
			.part('Snapshots Not Current And Invalid Territory');

		UnitTest.get('Snapshots Not In Current And Valid Territory')
			.property('Storage_Date__c').assignFrom(
				new List<Date>{currentStorageDate.addMonths(2), currentStorageDate.addYears(-1)})
			.property('Territory__c').assignFrom('Valid Billing Territories');
		UnitTest.get('Snapshots In Current And Invalid Territory')
			.property('Storage_Date__c').assign(currentStorageDate)
			.property('Territory__c').assignFrom('Invalid Billing Territories');
		UnitTest.get('Snapshots Not Current And Invalid Territory')
			.property('Storage_Date__c').assign(currentStorageDate.addMonths(-1))
			.property('Territory__c').assignFrom('Invalid Billing Territories');

		NetCubeGrowthComponentsController controller = new NetCubeGrowthComponentsController(DASHBOARD_ID_ONE);

		Test.startTest();
			List<Territory_Snapshot__c> actualTerritorySnapshots = controller.getCurrentBillingPeriodSnapshots();
		Test.stopTest();

		System.assert(actualTerritorySnapshots.isEmpty(), 'Empty list should be returned if no snaphsots are found');
		System.assert(TestingUtils.pageMessageContains(NetCubeGrowthComponentsController.NO_TERRITORY_SNAPSHOTS_FOUND), 'Along with returning an empty list, there should be a warning message about having no territory snapshots in criteria');
	}
	
	static testMethod void testGetWrapperRecords() {
		
		final Decimal SINGLE_INBOUND = 100;
		final Decimal SINGLE_PW = 200;
		final Decimal SINGLE_DEST = 300;
		final Date TEST_STORAGE_DATE = Date.newInstance(2014, 1, 2);
		
		List<Territory_Snapshot__c> territorySnapshots = TestingUtils.createTerritorySnapshots(200, null, false);
		
		UnitTest.addData(territorySnapshots).tag('Snapshots')
			.property('Territory__c').assignFrom('Valid Billing Territories')
			.property('Total_Inbound__c').assign(SINGLE_INBOUND)
			.property('Total_PW__c').assign(SINGLE_PW)
			.property('Total_Destruction__c').assign(SINGLE_DEST)
			.property('Storage_Date__c').assign(TEST_STORAGE_DATE);
		UnitTest.get('Snapshots').insertAll();
			
		NetCubeGrowthComponentsController controller = new NetCubeGrowthComponentsController(DASHBOARD_ID_ONE);

		Test.startTest();
			List<NetCubeGrowthComponentsController.NetCubeGrowthComponentWrapper> actualWrappers = controller.wrapperRecords;
		Test.stopTest();

		System.assertEquals(2, actualWrappers.size(), 'We expect to get back two wraper records');
	}
	
	static testMethod void testCreateCurrentMonthWrapperRecord() {
		final Decimal SINGLE_INBOUND = 100;
		final Decimal SINGLE_PW = 200;
		final Decimal SINGLE_DEST = 300;
		//final Decimal SINGLE_NEWCUBE = SINGLE_INBOUND-SINGLE_PW-SINGLE_DEST;
		final Date TEST_STORAGE_DATE = Date.newInstance(2014, 1, 2);
		Billing_Territory__c testTerritory = TestingUtils.createBillingTerritory('test_billing_territory', 'test_region', true);
		List<Territory_Snapshot__c> territorySnapshots = TestingUtils.createTerritorySnapshots(200, testTerritory.Id, false);
		UnitTest.addData(territorySnapshots).tag('Snapshots')
			.property('Total_Inbound__c').assign(SINGLE_INBOUND)
			.property('Total_PW__c').assign(SINGLE_PW)
			.property('Total_Destruction__c').assign(SINGLE_DEST)
			.property('Storage_Date__c').assign(TEST_STORAGE_DATE);

		NetCubeGrowthComponentsController controller = new NetCubeGrowthComponentsController(DASHBOARD_ID_ONE);

		Test.startTest();
			NetCubeGrowthComponentsController.NetCubeGrowthComponentWrapper actualWrapper = controller.createCurrentMonthWrapperRecord(territorySnapshots);
		Test.stopTest();

		System.assertEquals(200*SINGLE_INBOUND, actualWrapper.inboundTotalVolume, 'The Inbound Total Volume was incorrectly aggregated');
		System.assertEquals(200*SINGLE_PW, actualWrapper.pwTotalVolume, 'The PW Total Volume was incorrectly aggregated');
		System.assertEquals(200*SINGLE_DEST, actualWrapper.destructionTotalVolume, 'The Destruction Total Volume was incorrectly aggregated');
		//System.assertEquals(200*SINGLE_NEWCUBE, actualWrapper.netNewCubeTotalVolume, 'The Net New Cube Total Volume was incorrectly aggregated');
		System.assertEquals(currentStorageDatetime.format('MMMMM yyyy'), actualWrapper.periodLabel, 'The Period Label should be the formatted string of the storage date of the territories');

	}
	
	static testMethod void testGetBackDefaultProfileLabelForWrapper(){
		
		final Decimal SINGLE_INBOUND = 100;
		final Decimal SINGLE_PW = 200;
		final Decimal SINGLE_DEST = 300;
		//final Decimal SINGLE_NEWCUBE = SINGLE_INBOUND-SINGLE_PW-SINGLE_DEST;
		final Date TEST_STORAGE_DATE = Date.newInstance(2014, 1, 2);
		Billing_Territory__c testTerritory = TestingUtils.createBillingTerritory('test_billing_territory', 'test_region', true);
		List<Territory_Snapshot__c> territorySnapshots = TestingUtils.createTerritorySnapshots(200, testTerritory.Id, false);
		UnitTest.addData(territorySnapshots).tag('Snapshots')
			.property('Total_Inbound__c').assign(SINGLE_INBOUND)
			.property('Total_PW__c').assign(SINGLE_PW)
			.property('Total_Destruction__c').assign(SINGLE_DEST);

		NetCubeGrowthComponentsController controller = new NetCubeGrowthComponentsController(DASHBOARD_ID_ONE);

		Test.startTest();
			NetCubeGrowthComponentsController.NetCubeGrowthComponentWrapper actualWrapper = controller.createCurrentMonthWrapperRecord(territorySnapshots);
		Test.stopTest();

		System.assertEquals(NetCubeGrowthComponentsController.DEFAULT_CURRENT_PERIOD_LABEL, actualWrapper.periodLabel, 
			'The Period Label should be defaulted if no Storage_Date__c is found on the snapshots or no spapshots at all');
	
	
	}

	static testMethod void testCreateYTDWrapperRecord() {
		final Decimal SINGLE_INBOUND = 100;
		final Decimal SINGLE_PW = 200;
		final Decimal SINGLE_DEST = 300;
		//final Decimal SINGLE_NEWCUBE = 400;

		Billing_Territory__c testTerritory = TestingUtils.createBillingTerritory('test_billing_territory', 'test_region', true);
		List<Territory_Snapshot__c> territorySnapshots = TestingUtils.createTerritorySnapshots(200, testTerritory.Id, false);
		UnitTest.addData(territorySnapshots).tag('Snapshots')
			.property('CY_YTD_Inbound_Cube__c').assign(SINGLE_INBOUND)
			.property('CY_YTD_PW__c').assign(SINGLE_PW)
			.property('CY_YTD_Destruction__c').assign(SINGLE_DEST);

		NetCubeGrowthComponentsController controller = new NetCubeGrowthComponentsController(DASHBOARD_ID_ONE);

		Test.startTest();
			NetCubeGrowthComponentsController.NetCubeGrowthComponentWrapper actualWrapper = controller.createYTDWrapperRecord(territorySnapshots);
		Test.stopTest();

		System.assertEquals(200*SINGLE_INBOUND, actualWrapper.inboundTotalVolume, 'The Inbound Total Volume was incorrectly aggregated');
		System.assertEquals(200*SINGLE_PW, actualWrapper.pwTotalVolume, 'The PW Total Volume was incorrectly aggregated');
		System.assertEquals(200*SINGLE_DEST, actualWrapper.destructionTotalVolume, 'The Destruction Total Volume was incorrectly aggregated');
		//System.assertEquals(200*SINGLE_NEWCUBE, actualWrapper.netNewCubeTotalVolume, 'The Net New Cube Total Volume was incorrectly aggregated');
		System.assertEquals('YTD', actualWrapper.periodLabel, 'The Period Label should be the formatted string of the storage date of the territories');
	}
}