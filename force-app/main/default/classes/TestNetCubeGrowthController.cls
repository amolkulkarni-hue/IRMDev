@isTest
private class TestNetCubeGrowthController {
	
	
	private static Integer currentYear = Integer.valueOf(Label.Current_Cube_Year); 
	private static Integer currentMonth = Integer.valueOf(Label.Current_End_Cube_Period); 


	private static Date currentCubePeriodStorageDate = Date.newInstance(currentYear, currentMonth, 1);
	private static Datetime currentCubePeriodStorageDatetime = Datetime.newInstance(currentYear, currentMonth, 1);
	private static Date previousMonthCubePeriodStorageDate = Date.newInstance(currentYear, currentMonth-1, 1);
	
	final static List<String> BILLING_TERRITORY_NAMES = new List<String>{'test_territory_one', 'test_territory_two', 'test_territory_three'};
	final static String DASHBOARD_ID_ONE = 'dashboard_id_one';
	final static List<String> DASHBOARD_ID_ONE_TERRITORIES = new List<String>{BILLING_TERRITORY_NAMES[0], BILLING_TERRITORY_NAMES[1], BILLING_TERRITORY_NAMES[2]};
	final static List<String> INVALID_BILLING_TERRITORY_NAMES = new List<String>{'test_invalid_territory_one'};
	
	static {
		
		List<Territory_Dashboard_Component_Assignment__c> csList = new List<Territory_Dashboard_Component_Assignment__c>();
		csList.add(new Territory_Dashboard_Component_Assignment__c(Name='test1', DashboardId__c = DASHBOARD_ID_ONE, Territory_Region__c=DashboardTerritoryLookup.TERRITORY, TerritoryNames__c=String.join(DASHBOARD_ID_ONE_TERRITORIES, ',')));
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
		
		
		List<Parent_Billing_Market__c> parentBillingMarkets = new List<Parent_Billing_Market__c>();
		for (Billing_Territory__c billingTerr : billingTerritories){
			parentBillingMarkets.add(TestingUtils.createParentBillingMarket('PARENT_BILLING_MARKET', billingTerr.Id, false));
		}
		UnitTest.addData(parentBillingMarkets).tag('Valid Parent Billing Markets');
		UnitTest.get('Valid Parent Billing Markets').insertAll();
		
		Integer i = 0;
		List<Billing_Market__c> testBillingMarkets = new List<Billing_Market__c>(); 
		for (Parent_Billing_Market__c parentBillingMarket : parentBillingMarkets){
			testBillingMarkets.add(TestingUtils.createBillingMarket('BILLING_MARKET_'+i, 'MARKET_'+i, parentBillingMarket.Id, false));
			i++;
		}
		UnitTest.addData(testBillingMarkets).tag('Valid Billing Markets').tag('Billing Markets');
		UnitTest.get('Valid Billing Markets').insertAll();
		
	}
	
	static void setupTerritorySnapshots(){
		
		List<Territory_Snapshot__c> territorySnapshots = TestingUtils.createTerritorySnapshots(200, null, false);
		
		UnitTest.addData(territorySnapshots).tag('Territory Snapshots').divide(5)
			.part('Snapshots In Current And Valid Territory') 
			.part('Snapshots In Previous And Valid Territory') 
			.part('Snapshots Not In Current And Valid Territory')
			.part('Snapshots In Current And Invalid Territory')
			.part('Snapshots Not Current And Invalid Territory');
		
		UnitTest.get('Snapshots In Current And Valid Territory')
			.property('Storage_Date__c').assign(currentCubePeriodStorageDate)
			.property('Territory__c').assignFrom('Valid Billing Territories')
			.property('CM_End_Cube__c').assign(1)
			.property('PY_Total_Cube__c').assign(1)
			.property('Total_Inbound__c').assign(1)
			.property('Total_Destruction__c').assign(1)
			.property('Total_PW__c').assign(1); 
			
		UnitTest.get('Snapshots In Previous And Valid Territory')
			.property('Storage_Date__c').assign(previousMonthCubePeriodStorageDate)
			.property('Territory__c').assignFrom('Valid Billing Territories')
			.property('CM_End_Cube__c').assign(1); 
			
		UnitTest.get('Snapshots Not In Current And Valid Territory')
			.property('Storage_Date__c').assignFrom(
				new List<Date>{currentCubePeriodStorageDate.addMonths(2), currentCubePeriodStorageDate.addYears(-1)})
			.property('Territory__c').assignFrom('Valid Billing Territories');
		UnitTest.get('Snapshots In Current And Invalid Territory')
			.property('Storage_Date__c').assign(currentCubePeriodStorageDate)
			.property('Territory__c').assignFrom('Invalid Billing Territories');
		UnitTest.get('Snapshots Not Current And Invalid Territory')
			.property('Storage_Date__c').assign(currentCubePeriodStorageDate.addMonths(-2))
			.property('Territory__c').assignFrom('Invalid Billing Territories');
		
		UnitTest.get('Territory Snapshots').insertAll();
		
	}
	
	
	static testMethod void testGetCurrentBillingPeriodSnapshots(){
		
		setupTerritorySnapshots();
	
		NetCubeGrowthController controller = new NetCubeGrowthController(DASHBOARD_ID_ONE);
		
		Test.startTest();
			List<Territory_Snapshot__c> actualTerritorySnapshots = controller.getCurrentCubePeriodTerritorySnapshots();
		Test.stopTest();
		
		UnitTest.analyze('Snapshots In Current And Valid Territory').assertEquivalence(actualTerritorySnapshots, 'We expect to get back the territory snapshots within the current billing period and within valid territories ');
		for(Territory_Snapshot__c snapshot : actualTerritorySnapshots) {
			System.assertEquals(UnitTest.analyze('Snapshots In Current And Valid Territory').selectById(snapshot.Id).getPropertyValue('Territory__c'), snapshot.Territory__c);
			System.assertEquals(NetCubeGrowthController.FORMULA_YES, snapshot.Current_Cube_Period__c);
		}
	}
	
	static testMethod void testGetPreviousMonthBillingPeriodSnapshots(){
		
		setupTerritorySnapshots();
	
		NetCubeGrowthController controller = new NetCubeGrowthController(DASHBOARD_ID_ONE);
		
		Test.startTest();
			List<Territory_Snapshot__c> actualTerritorySnapshots = controller.getPreviousMonthCubePeriodTerritorySnapshots();
		Test.stopTest();
		
		UnitTest.analyze('Snapshots In Previous And Valid Territory').assertEquivalence(actualTerritorySnapshots, 'We expect to get back the territory snapshots within the current billing period and within valid territories ');
		for(Territory_Snapshot__c snapshot : actualTerritorySnapshots) {
			System.assertEquals(UnitTest.analyze('Snapshots In Previous And Valid Territory').selectById(snapshot.Id).getPropertyValue('Territory__c'), snapshot.Territory__c);
			System.assertEquals(NetCubeGrowthController.FORMULA_YES, snapshot.Previous_Cube_Period__c);
		}
	}
	
	static testMethod void testGetWrapperRecords(){
		
		setupTerritorySnapshots();
		
		NetCubeGrowthController controller = new NetCubeGrowthController(DASHBOARD_ID_ONE);
		
		Test.startTest();
			List<NetCubeGrowthController.NetCubeGrowthWrapper> actualWrappers = controller.wrapperRecords;
		Test.stopTest();
		
		System.assertEquals(2, actualWrappers.size(), 'We expect to get back the correct number of wrapper records');
		NetCubeGrowthController.NetCubeGrowthWrapper cmWrapper = actualWrappers[0];
		NetCubeGrowthController.NetCubeGrowthWrapper ytdWrapper = actualWrappers[1];
		System.assertEquals(NetCubeGrowthController.DEFAULT_CURRENT_PERIOD_LABEL, cmWrapper.periodLabel, 'We expect the Current Month wrapper to have the correct period label and be first in the list of wrapper records');
		System.assertEquals(NetCubeGrowthController.YTD_PERIOD_LABEL, ytdWrapper.periodLabel, 'We expect the Current Month wrapper to have the correct period label and be first in the list of wrapper records');
		
		Integer currentSnapshotSize = UnitTest.get('Snapshots In Current And Valid Territory').getList().size();
		Integer previousMonthSnapshotSize = UnitTest.get('Snapshots In Previous And Valid Territory').getList().size();
		
		Decimal expectedCurrentMonthEndingBalance = 1 * previousMonthSnapshotSize;
		Decimal expectedCurrentMonthBeginningBalance = expectedCurrentMonthEndingBalance - cmWrapper.netNewVolume;
		Decimal expectedYTDBeginningBalance = 1 * currentSnapshotSize;
		Decimal expectedYTDNetNewCube = 0;
		Decimal expectedYTDEndingBalance = 1 * currentSnapshotSize;
		
		System.assertEquals(expectedCurrentMonthBeginningBalance, cmWrapper.beginningBalance, 'We expect the beginning balance on the current month wrapper record to be correct.');
		System.assertEquals(expectedCurrentMonthEndingBalance, cmWrapper.currentBalance, 'We expect the current balance on the current month wrapper record to be correct.');
		System.assertEquals(expectedYTDBeginningBalance, ytdWrapper.beginningBalance, 'We expect the beginning balance on the YTD wrapper record to be correct.');
		System.assertEquals(expectedYTDNetNewCube, ytdWrapper.netNewVolume, 'We expect the net new cube on the YTD wrapper record to be correct.');
		System.assertEquals(expectedYTDEndingBalance, ytdWrapper.currentBalance, 'We expect the current balance on the YTD wrapper record to be correct.');
		
	}
	
}