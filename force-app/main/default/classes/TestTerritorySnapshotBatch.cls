/* Commenting the entire code as part of Gitlab #24448 */
public class TestTerritorySnapshotBatch {
    public TestTerritorySnapshotBatch(){
        
    }
/*    
    private final static List<Billing_Territory__c> TerritoryList;
    private final static TerritorySnapshotBatch TerritorySnapshotBatchInstance;
    
    private final static Integer DEFAULT_INBOUND_STORAGE_BOX_VOLUME = 1;
    private static final Integer CURRENT_YEAR = 2013 ;
    private static final Integer CURRENT_MONTH = 3 ;
    private static final Integer PREVIOUS_YEAR = CURRENT_YEAR - 1;
    
    static {
        System.runAs( TestingUtils.ADMIN_USER)
        {
            List<sObject> TerritorySnapshotRollupCustomSettings = Test.loadData(TerritorySnapshotRollupSettings__c.sObjectType, 'TerritorySnapshotRollupSettingsResource');
            List<sObject> TerritorySnapshotRecordTypeDestinationCS = Test.loadData(TerritorySnapshotRecordTypeDestination__c.sObjectType, 'TerritorySnapshotRecordTypeDestinationResource');
        }
        TerritoryList = new List<Billing_Territory__c>();
        TerritorySnapshotBatchInstance = new TerritorySnapshotBatch(CURRENT_YEAR, CURRENT_MONTH);
    }
    
    private static void setup(){
        
        final Integer NUM_INBOUND_STORAGE_RECORDS_TO_CREATE = 1;
        TerritoryList.clear();
        
        final Map<String, Map<Integer, List<Integer>>> INBOUND_STORAGE_RECORD_TYPE_DATES = new Map<String, Map<Integer, List<Integer>>>{
            'PW' => new Map<Integer, List<Integer>>{
                PREVIOUS_YEAR => new List<Integer>{1, CURRENT_MONTH, 4}, 
                CURRENT_YEAR => new List<Integer>{1, 2, CURRENT_MONTH}
            }, 
            'Destruction' => new Map<Integer, List<Integer>>{
                PREVIOUS_YEAR => new List<Integer>{1}
            },
            'Inbound_Storage' => new Map<Integer, List<Integer>>{
                PREVIOUS_YEAR => new List<Integer>{1}
            }
        };
        
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        IM_Customer_Account__c testCustomerAccount = TestingUtils.createCustomerAccount(testAccount.Id, true);
        
        
        Billing_Territory__c myBillingTerritory = TestingUtils.createBillingTerritory('TERRITORY1', 'SOUTH', true);
        Parent_Billing_Market__c myParentBillingMarket = TestingUtils.createParentBillingMarket('PARENT_BILLING_MARKET1', myBillingTerritory.Id, true);
        Billing_Market__c myBillingMarket = TestingUtils.createBillingMarket('BILLING_MARKET1', 'MARKET1', myParentBillingMarket.Id, true);
        
        TerritoryList.add(myBillingTerritory);
    
        List<Inbound_Storage__c> myInboundStorageRecords = new List<Inbound_Storage__c>();
        
        for (String recordType : INBOUND_STORAGE_RECORD_TYPE_DATES.keySet()){
            for (Integer year : INBOUND_STORAGE_RECORD_TYPE_DATES.get(recordType).keySet()){
                for (Integer month : INBOUND_STORAGE_RECORD_TYPE_DATES.get(recordType).get(year)){
                    
                    Inbound_Storage__c inbound = TestingUtils.createInboundStorageRecordsWithCubeMarket(NUM_INBOUND_STORAGE_RECORDS_TO_CREATE, myBillingMarket.Id, testCustomerAccount.Id, false)[0];
                    inbound.RecordTypeId = TerritorySnapshotBatchInstance.TerritorySnapshotBatchModelInstance.InboundStorageRecordTypeDevNameToRecordType.get(recordType).Id;
                    inbound.Box__c = DEFAULT_INBOUND_STORAGE_BOX_VOLUME;
                    inbound.Storage_Date__c = Date.newInstance(year,month,1);
                    inbound.Association_to_Opportunity_Status__c = 'Unmatched';
                    myInboundStorageRecords.add(inbound);
                }
            }
        }
        
        insert myInboundStorageRecords;
    }
    
    private static void setupMulitpleTerritories(){
        
        final Integer NUM_INBOUND_STORAGE_RECORDS_TO_CREATE = 2;
        final Integer NUM_UNIQUE_STORAGE_YEAR_MONTHS = 4;
        final Integer NUM_UNIQUE_TERRITORIES = 2;
        TerritoryList.clear();
        
        final Map<String, Map<Integer, List<Integer>>> INBOUND_STORAGE_RECORD_TYPE_DATES = new Map<String, Map<Integer, List<Integer>>>{
            'PW' => new Map<Integer, List<Integer>>{
                PREVIOUS_YEAR => new List<Integer>{1, 2, CURRENT_MONTH, 4} 
                //CURRENT_YEAR => new List<Integer>{1, 2}
            }, 
            'Destruction' => new Map<Integer, List<Integer>>{
                PREVIOUS_YEAR => new List<Integer>{1, 2, CURRENT_MONTH, 4}
                //CURRENT_YEAR => new List<Integer>{1}
            },
            'Inbound_Storage' => new Map<Integer, List<Integer>>{
                PREVIOUS_YEAR => new List<Integer>{1, CURRENT_MONTH},
                CURRENT_YEAR => new List<Integer>{2, CURRENT_MONTH}
            }
        };
        
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        Account testAccount2 = TestingUtils.createAccounts(1, true)[0];
        IM_Customer_Account__c testCustomerAccount = TestingUtils.createCustomerAccount(testAccount.Id, true);
        IM_Customer_Account__c testCustomerAccount2 = TestingUtils.createCustomerAccount(testAccount2.Id, true);
        
        
        Billing_Territory__c myBillingTerritory = TestingUtils.createBillingTerritory('TERRITORY1', 'SOUTH', true);
        Billing_Territory__c myBillingTerritory2 = TestingUtils.createBillingTerritory('TERRITORY2', 'EAST', true);
        Parent_Billing_Market__c myParentBillingMarket = TestingUtils.createParentBillingMarket('PARENT_BILLING_MARKET1', myBillingTerritory.Id, true);
        Parent_Billing_Market__c myParentBillingMarket2 = TestingUtils.createParentBillingMarket('PARENT_BILLING_MARKET1', myBillingTerritory2.Id, true);
        Billing_Market__c myBillingMarket = TestingUtils.createBillingMarket('BILLING_MARKET1', 'MARKET1', myParentBillingMarket.Id, true);
        Billing_Market__c myBillingMarket2 = TestingUtils.createBillingMarket('BILLING_MARKET1', 'MARKET1', myParentBillingMarket2.Id, true);
        
        TerritoryList.addAll(new List<Billing_Territory__c>{myBillingTerritory, myBillingTerritory2});
    
        List<Inbound_Storage__c> myInboundStorageRecords = new List<Inbound_Storage__c>();
        
        for (String recordType : INBOUND_STORAGE_RECORD_TYPE_DATES.keySet()){
            for (Integer year : INBOUND_STORAGE_RECORD_TYPE_DATES.get(recordType).keySet()){
                for (Integer month : INBOUND_STORAGE_RECORD_TYPE_DATES.get(recordType).get(year)){
                    
                    Inbound_Storage__c inbound = TestingUtils.createInboundStorageRecordsWithCubeMarket(NUM_INBOUND_STORAGE_RECORDS_TO_CREATE, myBillingMarket.Id, testCustomerAccount.Id, false)[0];
                    inbound.RecordTypeId = TerritorySnapshotBatchInstance.TerritorySnapshotBatchModelInstance.InboundStorageRecordTypeDevNameToRecordType.get(recordType).Id;
                    inbound.Box__c = DEFAULT_INBOUND_STORAGE_BOX_VOLUME;
                    inbound.PY_Total_Cube__c = DEFAULT_INBOUND_STORAGE_BOX_VOLUME;
                    inbound.Storage_Date__c = Date.newInstance(year,month,1);
                    
                    Inbound_Storage__c inbound2 = TestingUtils.createInboundStorageRecordsWithCubeMarket(NUM_INBOUND_STORAGE_RECORDS_TO_CREATE, myBillingMarket2.Id, testCustomerAccount2.Id, false)[0];
                    inbound2.RecordTypeId = TerritorySnapshotBatchInstance.TerritorySnapshotBatchModelInstance.InboundStorageRecordTypeDevNameToRecordType.get(recordType).Id;
                    inbound2.Box__c = DEFAULT_INBOUND_STORAGE_BOX_VOLUME;
                    inbound2.Storage_Date__c = Date.newInstance(year,month,1);
                    inbound.Association_to_Opportunity_Status__c = 'Unmatched';
                    
                    myInboundStorageRecords.addAll(new List<Inbound_Storage__c>{inbound, inbound2});
                }
            }
        }
        
        
        insert myInboundStorageRecords;
    }
    

    private static void setupNoCurrentRecords(){
        
        final Integer NUM_INBOUND_STORAGE_RECORDS_TO_CREATE = 1;
        TerritoryList.clear();
        
        final Map<String, Map<Integer, List<Integer>>> INBOUND_STORAGE_RECORD_TYPE_DATES = new Map<String, Map<Integer, List<Integer>>>{
            'PW' => new Map<Integer, List<Integer>>{
                PREVIOUS_YEAR => new List<Integer>{1, CURRENT_MONTH, 4}, 
                CURRENT_YEAR => new List<Integer>{1, 2, 4}
            }, 
            'Destruction' => new Map<Integer, List<Integer>>{
                PREVIOUS_YEAR => new List<Integer>{1}
            },
            'Inbound_Storage' => new Map<Integer, List<Integer>>{
                PREVIOUS_YEAR => new List<Integer>{1}
            }
        };
        
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        IM_Customer_Account__c testCustomerAccount = TestingUtils.createCustomerAccount(testAccount.Id, true);
        
        
        Billing_Territory__c myBillingTerritory = TestingUtils.createBillingTerritory('TERRITORY1', 'SOUTH', true);
        Parent_Billing_Market__c myParentBillingMarket = TestingUtils.createParentBillingMarket('PARENT_BILLING_MARKET1', myBillingTerritory.Id, true);
        Billing_Market__c myBillingMarket = TestingUtils.createBillingMarket('BILLING_MARKET1', 'MARKET1', myParentBillingMarket.Id, true);
        
        TerritoryList.add(myBillingTerritory);
    
        List<Inbound_Storage__c> myInboundStorageRecords = new List<Inbound_Storage__c>();
        
        for (String recordType : INBOUND_STORAGE_RECORD_TYPE_DATES.keySet()){
            for (Integer year : INBOUND_STORAGE_RECORD_TYPE_DATES.get(recordType).keySet()){
                for (Integer month : INBOUND_STORAGE_RECORD_TYPE_DATES.get(recordType).get(year)){
                    
                    Inbound_Storage__c inbound = TestingUtils.createInboundStorageRecordsWithCubeMarket(NUM_INBOUND_STORAGE_RECORDS_TO_CREATE, myBillingMarket.Id, testCustomerAccount.Id, false)[0];
                    inbound.RecordTypeId = TerritorySnapshotBatchInstance.TerritorySnapshotBatchModelInstance.InboundStorageRecordTypeDevNameToRecordType.get(recordType).Id;
                    inbound.Box__c = DEFAULT_INBOUND_STORAGE_BOX_VOLUME;
                    inbound.Storage_Date__c = Date.newInstance(year,month,1);
                    inbound.Association_to_Opportunity_Status__c = 'Unmatched';
                    myInboundStorageRecords.add(inbound);
                }
            }
        }
        
        insert myInboundStorageRecords;
    }
    
    
    private static void assertSnapshot(Territory_Snapshot__c territorySnapshot, Map<String, Integer> expectedMap){
        String snapshotIdentifier = 'Territory: '+ territorySnapshot.Territory__c +', Year: '+territorySnapshot.Storage_Date__c.year() + ', Month: ' + territorySnapshot.Storage_Date__c.month();
        System.assertEquals(expectedMap.get('expected_Total_PW'), territorySnapshot.Total_PW__c, 'We expect to get back the correct Total PW for: ' + snapshotIdentifier);
        System.assertEquals(expectedMap.get('expected_Total_Destruction'), territorySnapshot.Total_Destruction__c, 'We expect to get back Total Destruction for: ' + snapshotIdentifier);
        System.assertEquals(expectedMap.get('expected_Total_Inbound'), territorySnapshot.Total_Inbound__c, 'We expect to get back Total Inbound for: ' + snapshotIdentifier);
        System.assertEquals(expectedMap.get('expected_PY_YTD_PW'), territorySnapshot.PY_YTD_PW__c, 'We expect to get back the correct PY YTD Total PW for: ' + snapshotIdentifier);
        System.assertEquals(expectedMap.get('expected_PY_YTD_Destruction'), territorySnapshot.PY_YTD_Destruction__c, 'We expect to get back the correct PY YTD  Total Destruction for: ' + snapshotIdentifier);
        //System.assertEquals(expectedMap.get('expected_PY_YTD_Inbound_Cube'), territorySnapshot.PY_YTD_Inbound_Cube__c, 'We expect to get back the correct PY YTD  Total Inbound_Cube for: ' + snapshotIdentifier);
        System.assertEquals(expectedMap.get('expected_CY_YTD_PW'), territorySnapshot.CY_YTD_PW__c, 'We expect to get back the correct CY YTD Total PW for: ' + snapshotIdentifier);
        System.assertEquals(expectedMap.get('expected_CY_YTD_Destruction'), territorySnapshot.CY_YTD_Destruction__c, 'We expect to get back the correct CY YTD Total Destruction for: ' + snapshotIdentifier);
        System.assertEquals(expectedMap.get('expected_CY_YTD_Inbound_Cube'), territorySnapshot.CY_YTD_Inbound_Cube__c, 'We expect to get back the correct CY YTD Total Inbound_Cube for: ' + snapshotIdentifier);
                                            
    }
    
    private static void makeAssertions(){
        
        final Integer EXPECTED_UNIQUE_TERRITORY_STORAGE_DATES = 1;
        
        List<Territory_Snapshot__c> actualTerritorySnapshots = [Select Id, Territory__c, Storage_Date__c, Total_PW__c, Total_Destruction__c, Total_Inbound__c,
                                                                        PY_YTD_PW__c, PY_YTD_Destruction__c, PY_YTD_Inbound_Cube__c, 
                                                                        CY_YTD_PW__c, CY_YTD_Destruction__c, CY_YTD_Inbound_Cube__c
                                                                FROM Territory_Snapshot__c WHERE Territory__c IN :TerritoryList];
        
        System.assertEquals(EXPECTED_UNIQUE_TERRITORY_STORAGE_DATES, actualTerritorySnapshots.size(), 'We expect to get back a territory snapshot for every unique territory and storage date');
        System.assert(actualTerritorySnapshots[0].Storage_Date__c.year() == CURRENT_YEAR && actualTerritorySnapshots[0].Storage_Date__c.month() == CURRENT_MONTH, 'We expect to get back only the snapshots for the current year and current month' );
        for (Territory_Snapshot__c territorySnapshot : actualTerritorySnapshots){
            System.assertEquals(TerritoryList[0].Id, territorySnapshot.Territory__c, 'We expect to get back the correct Territories for each Territory Snapshot');
            assertSnapshot(territorySnapshot, new Map<String, Integer>{
                'expected_Total_PW' => 1,
                'expected_Total_Destruction' => null,
                'expected_Total_Inbound' => null,
                'expected_PY_YTD_PW' => 2,
                'expected_PY_YTD_Destruction' => null,
                'expected_PY_YTD_Inbound_Cube' => null,
                'expected_CY_YTD_PW' => 3,
                'expected_CY_YTD_Destruction' => null,
                'expected_CY_YTD_Inbound_Cube' => null
            });
        }
    
    }
    
    private static void makeAssertionsMultipleTerritories(){
        
        final Integer EXPECTED_UNIQUE_TERRITORY_STORAGE_DATES = 2;
        
        List<Territory_Snapshot__c> actualTerritorySnapshots = [Select Id, Territory__c, Storage_Date__c, Total_PW__c, Total_Destruction__c, Total_Inbound__c,
                                                                        PY_YTD_PW__c, PY_YTD_Destruction__c, PY_YTD_Inbound_Cube__c, 
                                                                        CY_YTD_PW__c, CY_YTD_Destruction__c, CY_YTD_Inbound_Cube__c
                                                                FROM Territory_Snapshot__c WHERE Territory__c IN :TerritoryList];
        
        System.assertEquals(EXPECTED_UNIQUE_TERRITORY_STORAGE_DATES, actualTerritorySnapshots.size(), 'We expect to get back a territory snapshot for every unique territory and storage date');
        // assert date here instead
        for (Territory_Snapshot__c territorySnapshot : actualTerritorySnapshots){
            System.assert(Pluck.ids(TerritoryList).contains(territorySnapshot.Territory__c), 'We expect to get back the correct Territories for each Territory Snapshot');
           /* System.assert(territorySnapshot.Storage_Date__c.year() == CURRENT_YEAR && territorySnapshot.Storage_Date__c.month() == CURRENT_MONTH, 'We expect to get back only the snapshots for the current year and current month' );
            assertSnapshot(territorySnapshot, new Map<String, Integer>{
                    'expected_Total_PW' => null,
                    'expected_Total_Destruction' => null,
                    'expected_Total_Inbound' => 1,
                    'expected_PY_YTD_PW' => null,
                    'expected_PY_YTD_Destruction' => null,
                    'expected_PY_YTD_Inbound_Cube' => 2,
                    'expected_CY_YTD_PW' => null,
                    'expected_CY_YTD_Destruction' => null,
                    'expected_CY_YTD_Inbound_Cube' => 2
            });* /
        }
    
    }
    
    
    private static void makeAssertionsNoCurrentRecords(){
        
        final Integer EXPECTED_UNIQUE_TERRITORY_STORAGE_DATES = 0;
        
        List<Territory_Snapshot__c> actualTerritorySnapshots = [Select Id, Territory__c, Storage_Date__c, Total_PW__c, Total_Destruction__c, Total_Inbound__c,
                                                                        PY_YTD_PW__c, PY_YTD_Destruction__c, PY_YTD_Inbound_Cube__c, 
                                                                        CY_YTD_PW__c, CY_YTD_Destruction__c, CY_YTD_Inbound_Cube__c
                                                                FROM Territory_Snapshot__c WHERE Territory__c IN :TerritoryList];
        
        System.assertEquals(EXPECTED_UNIQUE_TERRITORY_STORAGE_DATES, actualTerritorySnapshots.size(), 'We expect to get back no territory snapshots when there are no current year and current month inbound storage records');
    }
    
    public static testMethod void testTerritorySnapshotBatchJob () {
        
        setup();
        
        Test.startTest();
            Id batchInstanceId = Database.executeBatch(TerritorySnapshotBatchInstance, TerritorySnapshotBatch.BATCH_SCOPE_SIZE);
        Test.stopTest();
        
        makeAssertions();
        
    } 
    
    public static testMethod void testTerritorySnapshotBatchJobMultipleTerritories () {
        
        setupMulitpleTerritories();
        
        Test.startTest();
            Id batchInstanceId = Database.executeBatch(TerritorySnapshotBatchInstance, TerritorySnapshotBatch.BATCH_SCOPE_SIZE);
        Test.stopTest();
        
      //  makeAssertionsMultipleTerritories();
        
    } 
    
    public static testMethod void testTerritorySnapshotBatchJobNoCurrentRecords() {
        
        setupNoCurrentRecords();
        
        Test.startTest();
            Id batchInstanceId = Database.executeBatch(TerritorySnapshotBatchInstance, TerritorySnapshotBatch.BATCH_SCOPE_SIZE);
        Test.stopTest();
        
        makeAssertionsNoCurrentRecords();
        
    } 
    */
}