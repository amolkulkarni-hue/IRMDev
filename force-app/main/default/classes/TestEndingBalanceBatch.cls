/* Commenting the entire code as part of Gitlab #24448 */
@isTest
public class TestEndingBalanceBatch {
    /*
    public static Date expectedStorageDate = Date.newInstance(2013, 12, 1);
    public static List<IM_Customer_Account__c> testCustomerAccounts;
    public static List<Billing_Market__c> testBillingMarkets;
    public static List<String> testDepartments;
    public static List<String> testDivisions;
    private static Set<String> testRecordTypeWhitelist;
    private static String TEST_VALID_RECORD_TYPE;
    private static String TEST_INVALID_RECORD_TYPE;
    
    static {
        System.runAs( TestingUtils.ADMIN_USER)
        {
            List<sObject> CurrentEndingBalanceMappingCustomSettings = Test.loadData(Current_Ending_Balance_Mapping__c.sObjectType, 'CurrentEndingBalanceMappingCS');
            testRecordTypeWhitelist = new Set<String>{'PW', 'Inbound_Storage', 'Destruction'};
            List<InboundStorageRecordTypesReportWhitelist__c> rtWhitelistCS = new List<InboundStorageRecordTypesReportWhitelist__c>();
            for (String developerName : testRecordTypeWhitelist){
                InboundStorageRecordTypesReportWhitelist__c rt = new InboundStorageRecordTypesReportWhitelist__c();
                rt.Name = developerName;
                rt.DeveloperName__c = developerName; 
                rtWhitelistCS.add(rt);
            }
            insert rtWhitelistCS;
            
            TEST_VALID_RECORD_TYPE = 'Inbound_Storage';
            TEST_INVALID_RECORD_TYPE = 'Acquisition_Adjustment';
                
        }
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        
        testCustomerAccounts = new List<IM_Customer_Account__c>();
        for (Integer i = 0; i < 3 ; i++){
            testCustomerAccounts.add(TestingUtils.createCustomerAccount(testAccount.Id, false));
        }
        insert testCustomerAccounts;
        
        Billing_Territory__c myBillingTerritory = TestingUtils.createBillingTerritory('TERRITORY1', 'SOUTH', true);
        Parent_Billing_Market__c myParentBillingMarket = TestingUtils.createParentBillingMarket('PARENT_BILLING_MARKET1', myBillingTerritory.Id, true);
        
        testBillingMarkets = new List<Billing_Market__c>(); 
        for (Integer i = 0; i < 3 ; i++){
            testBillingMarkets.add(TestingUtils.createBillingMarket('BILLING_MARKET_'+i, 'MARKET_'+i, myParentBillingMarket.Id, false));
        }
        insert testBillingMarkets;
        
        testDepartments = new List<String>{'dept1', 'dept2'};
        testDivisions = new List<String>{'div1', 'div2'};
    }
    
    public static testMethod void testGetRecordTypeWhitelist(){ 
        
        Test.startTest();
            EndingBalanceBatch EndingBalanceBatchInstance = new EndingBalanceBatch(expectedStorageDate.year(), expectedStorageDate.month());
        Test.stopTest();
        
        System.assertEquals(testRecordTypeWhitelist, EndingBalanceBatchInstance.EndingBalanceBatchModelInstance.rtWhitelist, 
            'We expect the record types that are being used by the batch to be retrieved from the custom settings.');
        for (String recordType : testRecordTypeWhitelist){
            System.assert(EndingBalanceBatchInstance.EndingBalanceBatchModelInstance.buildDatabaseQuery().contains(recordType), 
            'We expect all of the record types defined in the custom settings to used in the database query');
        }
        
    }
    
    
    private static Map<String, RecordType> getInboundStorageRecordTypes {
        get{
            if (getInboundStorageRecordTypes == null){
                getInboundStorageRecordTypes = new Map<String, RecordType>();
                for (RecordType rt : [Select Id, DeveloperName From RecordType Where SobjectType = 'Inbound_Storage__c']){
                    if (!getInboundStorageRecordTypes.containsKey(rt.DeveloperName)){
                        getInboundStorageRecordTypes.put(rt.DeveloperName, rt);
                    }
                }
            }
            return getInboundStorageRecordTypes; 
        }
        set;
    }
    
    public static testMethod void testInboundStorageQueryResults(){
    
         Profile prof = [Select id from Profile where Name = 'IM_Custom Sys Admin' limit 1];

        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                              ,emailencodingkey='UTF-8'
                              , lastname='Testing', languagelocalekey='en_US'
                              , localesidkey='en_US', profileid = prof.id
                              , timezonesidkey='America/Los_Angeles'
                              , username='userwithrole@testorg.com'
                              , Country = 'United Kingdom',
                              CurrencyIsoCode= 'USD'); 
    
        List<Inbound_Storage__c> testInboundStorageRecords = new List<Inbound_Storage__c>();
        List<Inbound_Storage__c> expectedInboundStorage = new List<Inbound_Storage__c>();
        Integer i = 0;
        for (IM_Customer_Account__c custAcc : testCustomerAccounts){
            for (Billing_Market__c billingMarket : testBillingMarkets){
                for (String dept : testDepartments){
                    for (String div : testDivisions){
                        
                        for (Inbound_Storage__c inbound : TestingUtils.createInboundStorageRecordsWithCubeMarket(2, billingMarket.Id, custAcc.Id, false)){  
                            inbound.RecordTypeId = getInboundStorageRecordTypes.get(TEST_VALID_RECORD_TYPE).Id;
                            inbound.Dept_ID_del__c = dept;
                            inbound.Div_ID_del__c = div;
                            inbound.Storage_Date__c = expectedStorageDate-1;
                            inbound.PY_Total_Cube__c = i++;
                            inbound.Ending_Current_Month_Cube__c = i++;
                            testInboundStorageRecords.add(inbound);
                            expectedInboundStorage.add(inbound);
                        }
                        
                        
                        for (Inbound_Storage__c inbound : TestingUtils.createInboundStorageRecordsWithCubeMarket(2, billingMarket.Id, custAcc.Id, false)){  
                            inbound.RecordTypeId = getInboundStorageRecordTypes.get(TEST_INVALID_RECORD_TYPE).Id;
                            inbound.Dept_ID_del__c = dept;
                            inbound.Div_ID_del__c = div;
                            inbound.Storage_Date__c = expectedStorageDate;
                            inbound.PY_Total_Cube__c = i++;
                            inbound.Ending_Current_Month_Cube__c = i++;
                            testInboundStorageRecords.add(inbound);
                        }
                        
                        for (Inbound_Storage__c inbound : TestingUtils.createInboundStorageRecordsWithCubeMarket(2, billingMarket.Id, custAcc.Id, false)){  
                            inbound.RecordTypeId = getInboundStorageRecordTypes.get(TEST_VALID_RECORD_TYPE).Id;
                            inbound.Dept_ID_del__c = dept;
                            inbound.Div_ID_del__c = div;
                            inbound.Storage_Date__c = expectedStorageDate.addMonths(3);
                            inbound.PY_Total_Cube__c = i++;
                            inbound.Ending_Current_Month_Cube__c = i++;
                            testInboundStorageRecords.add(inbound);
                        }
                        
                        for (Inbound_Storage__c inbound : TestingUtils.createInboundStorageRecordsWithCubeMarket(2, billingMarket.Id, custAcc.Id, false)){  
                            inbound.RecordTypeId = getInboundStorageRecordTypes.get(TEST_INVALID_RECORD_TYPE).Id;
                            inbound.Dept_ID_del__c = dept;
                            inbound.Div_ID_del__c = div;
                            inbound.Storage_Date__c = expectedStorageDate.addMonths(3);
                            inbound.PY_Total_Cube__c = i++;
                            inbound.Ending_Current_Month_Cube__c = i++;
                            testInboundStorageRecords.add(inbound);
                        }
                                
                    }
                }
            }
        }
        
        System.runAs(u)
        {
            insert testInboundStorageRecords;
        }
        Set<Id> expectedInboundIds = new Map<Id, Inbound_Storage__c>(expectedInboundStorage).keySet();
        
        EndingBalanceBatch EndingBalanceBatchInstance = new EndingBalanceBatch(expectedStorageDate.year(), expectedStorageDate.month());
        
        Test.startTest();
            List<Inbound_Storage__c> actualInboundResult = Database.query(EndingBalanceBatchInstance.EndingBalanceBatchModelInstance.buildDatabaseQuery());
        Test.stopTest();
        
        System.assertEquals(expectedInboundStorage.size(), actualInboundResult.size(), 'We expect to get back the correct number of inbound storages from the database query');
        for (Inbound_Storage__c inbound : actualInboundResult){
            System.assert(expectedInboundIds.contains(inbound.Id), 
                'We expect all of the inbound storages that we get back to have a valid record type and a valid storage date. ');
        }
        
    }
    
    
    public static testMethod void testEndingBalanceBatchModelResults(){
        
        Profile prof = [Select id from Profile where Name = 'IM_Custom Sys Admin' limit 1];

        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                              ,emailencodingkey='UTF-8'
                              , lastname='Testing', languagelocalekey='en_US'
                              , localesidkey='en_US', profileid = prof.id
                              , timezonesidkey='America/Los_Angeles'
                              , username='userwithrole@testorg.com'
                              , Country = 'United Kingdom',
                              CurrencyIsoCode= 'USD'); 
    
        Map<String,Inbound_Storage__c> latestInboundStorageMap = new Map<String,Inbound_Storage__c>();
        List<Inbound_Storage__c> testInboundStorageRecords = new List<Inbound_Storage__c>();
        Integer i = 0;
        for (IM_Customer_Account__c custAcc : testCustomerAccounts){
            for (Billing_Market__c billingMarket : testBillingMarkets){
                for (String dept : testDepartments){
                    for (String div : testDivisions){
                        for (Inbound_Storage__c inbound : TestingUtils.createInboundStorageRecordsWithCubeMarket(9, billingMarket.Id, custAcc.Id, false)){
                            inbound.Dept_ID_del__c = dept;
                            inbound.Div_ID_del__c = div;
                            inbound.Storage_Date__c = expectedStorageDate-1;
                            inbound.PY_Total_Cube__c = i++;
                            inbound.Ending_Current_Month_Cube__c = i++;
                            
                            testInboundStorageRecords.add(inbound);
                        }
                        
                        Inbound_Storage__c latestInbound = TestingUtils.createInboundStorageRecordsWithCubeMarket(1, billingMarket.Id , custAcc.Id, false)[0];
                        latestInbound.Dept_ID_del__c = dept;
                        latestInbound.Div_ID_del__c = div;
                        latestInbound.Storage_Date__c = expectedStorageDate;
                        latestInbound.PY_Total_Cube__c = i++; 
                        latestInbound.Ending_Current_Month_Cube__c = i++;
                        latestInboundStorageMap.put(EndingBalanceBatchModel.hashEndingBalanceKey(custAcc.Id, billingMarket.Id, dept, div ), latestInbound);
                        testInboundStorageRecords.add(latestInbound);
                        
                    }
                }
            }
        }
        System.runAs(u)
        {
            insert testInboundStorageRecords;
        }
        
        EndingBalanceBatch EndingBalanceBatchInstance = new EndingBalanceBatch(expectedStorageDate.year(), expectedStorageDate.month());
        
        Test.startTest();
            Id batchInstanceId = Database.executeBatch(EndingBalanceBatchInstance, EndingBalanceBatch.BATCH_SCOPE_SIZE);
        Test.stopTest();
        
        List<Current_Ending_Balance__c> actualCurrentEndingBalances = [Select Id,Storage_Date__c,Billing_Market__c, Customer_Account__c, Department__c, Division__c, Previous_Year_End_Cube__c,Current_Ending_Balance__c 
                                                                        From Current_Ending_Balance__c  ];
        
        System.assertEquals(testCustomerAccounts.size()*testBillingMarkets.size()*testDepartments.size()*testDivisions.size(), actualCurrentEndingBalances.size(), 'We expect to get a pair for each customer account, billing market, department and division');
        
        for (Current_Ending_Balance__c endingBalance : actualCurrentEndingBalances){
            String endingBalanceKey = EndingBalanceBatchModel.hashEndingBalanceKey(endingBalance.Customer_Account__c, endingBalance.Billing_Market__c, endingBalance.Department__c, endingBalance.Division__c);
            System.assert(latestInboundStorageMap.containsKey(endingBalanceKey), 'We expect to have a latest inbound storage record for each current ending balance that is created. Not found for: ' + endingBalanceKey + ' : ' + latestInboundStorageMap.keySet());
            System.assert(new Map<Id, IM_Customer_Account__c>(testCustomerAccounts).keySet().contains(endingBalance.Customer_Account__c), 'We expect to get back a valid customer account on the current ending balance record');
            System.assert(new Map<Id, Billing_Market__c>(testBillingMarkets).keySet().contains(endingBalance.Billing_Market__c), 'We expect to get back a valid billing market on the current ending balance record');
            System.assertEquals(latestInboundStorageMap.get(endingBalanceKey).PY_Total_Cube__c, endingBalance.Previous_Year_End_Cube__c, 'We expect to get back PY Total Cube value from the latest inbound storage record for each billing market and customer account pair.');
            System.assertEquals(latestInboundStorageMap.get(endingBalanceKey).Ending_Current_Month_Cube__c, endingBalance.Current_Ending_Balance__c, 'We expect to get back CY YTD Cube value from the latest inbound storage record for each billing market and customer account pair.');
            System.assertEquals(latestInboundStorageMap.get(endingBalanceKey).Dept_ID_del__c, endingBalance.Department__c, 'We expect to get back CY YTD Cube value from the latest inbound storage record for each billing market and customer account pair.');
            System.assertEquals(latestInboundStorageMap.get(endingBalanceKey).Div_ID_del__c, endingBalance.Division__c, 'We expect to get back CY YTD Cube value from the latest inbound storage record for each billing market and customer account pair.');
            System.assertEquals(expectedStorageDate, endingBalance.Storage_Date__c, 'We expect to get back CY YTD Cube value from the latest inbound storage record for each billing market and customer account pair.');
        }
        
    
    }
    
    public static testMethod void testEndingBalanceBatchModelResultsWhenNoInboundStorage(){
        
        EndingBalanceBatch EndingBalanceBatchInstance = new EndingBalanceBatch(expectedStorageDate.year(), expectedStorageDate.month());
        
        Test.startTest();
            Id batchInstanceId = Database.executeBatch(EndingBalanceBatchInstance, EndingBalanceBatch.BATCH_SCOPE_SIZE);
        Test.stopTest();
        
        List<Current_Ending_Balance__c> actualCurrentEndingBalances = [Select Id,Storage_Date__c,Billing_Market__c, Customer_Account__c, Department__c, Division__c, Previous_Year_End_Cube__c,Current_Ending_Balance__c From Current_Ending_Balance__c];
        
        System.assertEquals(0, actualCurrentEndingBalances.size(), 'We expect to get no current ending balance records when no inbound storage records are found');
    
    }
    
    public static testMethod void testInboundStorageFieldsForQuery(){
        
        Set<String> expectedInboundStorageFields = new Set<String>{'PY_Total_Cube__c', 'Ending_Current_Month_Cube__c'};
        String expectedInboundStorageQueryFromCSResource = ', PY_Total_Cube__c, Ending_Current_Month_Cube__c';
        
        Test.startTest();
            EndingBalanceBatch EndingBalanceBatchInstance = new EndingBalanceBatch(expectedStorageDate.year(), expectedStorageDate.month());
        Test.stopTest();
        
        System.assertEquals(expectedInboundStorageFields, EndingBalanceBatchInstance.EndingBalanceBatchModelInstance.getInboundStorageFieldsFromCS(), 'We expect to get a set of inbound storage fields used in the custom setting');
        System.assertEquals(expectedInboundStorageQueryFromCSResource, EndingBalanceBatchInstance.EndingBalanceBatchModelInstance.getInboundStorageFieldsForQuery, 'We expect to get a correctly formatted query for the inbound storage fields used in the custom setting');
    
    }
  */  
    
}