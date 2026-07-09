/* Commenting the entire code as part of Gitlab #24446 */
@isTest
public class Test_InboundStorageToBoBCoverageHelper {
    /*
    @TestVisible static final String CUSTOM_SETTING_NAME = 'Sandbox';
    @TestVisible static M1_CDE_Settings__c testCustomSettings;
    @TestVisible static final string PARENT_BILLING_MARKET = 'Kansas City';
    
    @TestVisible static void setup(){
        
        //Create some custom settings
        testCustomSettings = new M1_CDE_Settings__c();
        testCustomSettings.Focus_Start_Period__c = 1;
        testCustomSettings.Focus_End_Period__c = 7;
        testCustomSettings.Focus_Year__c = '2013';
        testCustomSettings.Name = CUSTOM_SETTING_NAME;
        testCustomSettings.Query_Associate_Order_By__c = 'Id Desc';
        testCustomSettings.Query_Associate_Select__c = 'Id';
        testCustomSettings.Query_Associate_Where__c = ' Id <> Null';
        
        System.runAs( TestingUtils.ADMIN_USER )
        {
            insert testCustomSettings;
        }
    }
    
    @TestVisible static void setEligibleValues(BoB_Coverage_Eligible__c eligibleRecord, Integer startMonth, Integer endMonth, Integer year, Id parentBillingId)
    {
        eligibleRecord.Parent_Billing_Market__c = parentBillingId;
        eligibleRecord.Effective_Start_Period__c = String.valueOf( startMonth );
        eligibleRecord.Effective_End_Period__c = String.valueOf( endMonth );
        eligibleRecord.Effective_Year__c = String.valueOf( year );
    }
    
    static testMethod void testGetJobStatusWithNoJobsRunning() 
    {
        setup();
        Test.startTest();
            //Instantiate the helper
            InboundStorageToBoBCoverage_Helper testHelper = new InboundStorageToBoBCoverage_Helper ( CUSTOM_SETTING_NAME );
        Test.StopTest();
        
        System.assertEquals( null, testHelper.jobStatus(), 'No batch Jobs should be found ' );
    }

    static testMethod void testGetJobStatusWithOneJobRunning() 
    {
        final String TEST_JOB_ID = 'M1_Joins_' + DateTime.now().format('MM/dd_HH:mm:ss');
        setup();
        
        Test.startTest();
            //Instantiate the helper
            InboundStorageToBoBCoverage_Helper testHelper = new InboundStorageToBoBCoverage_Helper ( CUSTOM_SETTING_NAME );
            
            //Run the M1 batch
            M1_Physical_CDE_Batch testJob = new M1_Physical_CDE_Batch( CUSTOM_SETTING_NAME, TEST_JOB_ID);
            Database.executeBatch( testJob );
            
            System.assertNotEquals(null, testHelper.jobStatus(), 'One batch should be detected');
            System.assertEquals('M1_Physical_CDE_Batch', testHelper.jobStatus().ApexClass.Name, 'One batch with the correct class name should be detected');
            System.assertEquals('Queued', testHelper.jobStatus().Status, 'One batch with the queued status should be detected');
            
        Test.StopTest();
        
        //After completion, the completed batch should be detected
        System.assertNotEquals(null, testHelper.jobStatus(), 'One batch should be detected');
        System.assertEquals('M1_Physical_CDE_Batch', testHelper.jobStatus().ApexClass.Name, 'One batch with the correct class name should be detected');
        System.assertEquals('Completed', testHelper.jobStatus().Status, 'One batch with the completed status should be detected');
    }

    static testMethod void testFindCYRangeBOBCoveragesEligibles() 
    {
        final Integer COVERAGE_SIZE = 200;
        Set<String> currentYearFormulaHashes = new Set<String>();
        Set<String> priorYearFormulaHashes = new Set<String>();
        final String IMGA = 'IM_AECOM';
        
        setup();
        
        Account aecomAccount = TestingUtils.createAccounts(1, false)[0];
        aecomAccount.IM_IMGA_Indexed__c = IMGA;
        aecomAccount.IM_Hierarchy_Level__c = 'IM Group (IMGA)';
        insert aecomAccount;
        
        Parent_Billing_Market__c testPB = TestingUtils.createParentBillingMarketRecords(1, false)[0];
        testPB.name = PARENT_BILLING_MARKET;
        insert testPB;
                
        List<BoB_Coverage_Eligible__c> inValidBobCoverageEligiblesAecom = new List<BoB_Coverage_Eligible__c>();
        List<BoB_Coverage_Eligible__c> validBobCoverageAecomEligibles =  new List<BoB_Coverage_Eligible__c>();
        List<BoB_Coverage_Eligible__c> totalBobCoverageAecomEligibles = new List<BoB_Coverage_Eligible__c>();// 
        for(integer i = 0 ; i < COVERAGE_SIZE ; i++) {
            Bob_Coverage_Eligible__c eligible = TestingUtils.createBoBCoverageEligibles(new List<Account>{ aecomAccount}, false)[0];
            eligible.country_Coverage__c = 'Canada'; 
            totalBobCoverageAecomEligibles.add(eligible);
        }
        
        
        for( integer i = 0; i < totalBobCoverageAecomEligibles.size(); i++) {
            
            Integer month = Math.mod(i, 12) + 1;
            Integer yearsToSubtract = Math.mod(i, 3);
            
            Integer year = Integer.valueOf(testCustomSettings.Focus_Year__c) - yearsToSubtract;
            
            setEligibleValues(totalBobCoverageAecomEligibles[i], month, month + 1, year, testPB.id);
            
            if( yearsToSubtract == 0 ) 
                validBobCoverageAecomEligibles.add( totalBobCoverageAecomEligibles[i] );    
            else
                inValidBobCoverageEligiblesAecom.add( totalBobCoverageAecomEligibles[i] );
        }
        
        insert totalBobCoverageAecomEligibles;
        
        String effectiveYearText = testCustomSettings.Focus_Year__c;
        Integer effectiveYear     = Integer.valueOf(effectiveYearText);
        Integer priorYear         = effectiveYear - 1;
        String priorYearText     = String.valueOf(priorYear);
        Integer startPeriod = Integer.valueOf( testCustomSettings.Focus_Start_Period__c );
        Integer endPeriod = Integer.valueOf( testCustomSettings.Focus_End_Period__c );
        
        currentYearFormulaHashes.add( IMGA + testPB.Id + effectiveYearText);
        priorYearFormulaHashes.add( IMGA + testPB.Id + priorYearText);
        
        List<BoB_Coverage_Eligible__c> actualEligibles;
        List<BoB_Coverage_Eligible__c> actualEligiblesBasedOnPYHashes;
        
        Test.startTest();
            //Instantiate the helper
            InboundStorageToBoBCoverage_Helper testHelper = new InboundStorageToBoBCoverage_Helper ( CUSTOM_SETTING_NAME );
            actualEligibles = testHelper.findAllCoveragesForCYSettingsRange(effectiveYearText, currentYearFormulaHashes);
            actualEligiblesBasedOnPYHashes = testHelper.findAllCoveragesForCYSettingsRange(effectiveYearText, priorYearFormulaHashes);
            
        Test.StopTest();
        
         assertCorrectnessOfEligibles( validBobCoverageAecomEligibles, actualEligibles );
         assertCorrectnessOfEligibles( validBobCoverageAecomEligibles, actualEligiblesBasedOnPYHashes );
    }
    
    static void assertCorrectnessOfEligibles( List<BoB_Coverage_Eligible__c> validBobCoverageEligibleAecom, List<BoB_Coverage_Eligible__c> actualEligibles )
    {
        Map<Id, BoB_Coverage_Eligible__c> validMap = new Map<Id, BoB_Coverage_Eligible__c> ( validBobCoverageEligibleAecom );
        Map<Id, BoB_Coverage_Eligible__c> actualMap = new Map<Id, BoB_Coverage_Eligible__c> ( actualEligibles );
        
        System.assertEquals( validMap.size(), actualMap.size(), 'The correct number of coverage eligables should be returned');
        System.assert( validMap.keySet().containsAll( actualMap.keySet() ), 'The eligible records should be connected to the correct coverage records' );
    }
    
    static testMethod void testBuildBOBCoveragesEligiblesHashes() 
    {
        final Integer COVERAGE_SIZE = 1;
        final String NORTH_AMERICA_LCASE = 'north america';
        final String CANADA_LCASE = 'canada';
        String IMGA1 = 'IM_AECOM';
        String IMGA2 = 'IM_AECOM_2';
        
        setup();
        
        Integer startPeriod = Integer.valueOf(testCustomSettings.Focus_Start_Period__c);
        Integer endPeriod = Integer.valueOf(testCustomSettings.Focus_End_Period__c);
        
        Account aecomAccount = TestingUtils.createAccounts(1, false)[0];
        aecomAccount.IM_IMGA_Indexed__c = IMGA1;
        aecomAccount.IM_Hierarchy_Level__c = 'IM Group (IMGA)';
        insert aecomAccount;

        Account aecomAccount2 = TestingUtils.createAccounts(1, false)[0];
        aecomAccount2.IM_IMGA_Indexed__c = IMGA2;
        aecomAccount2.IM_Hierarchy_Level__c = 'IM Group (IMGA)';
        insert aecomAccount2;
        
        Parent_Billing_Market__c testPB = TestingUtils.createParentBillingMarketRecords(1, false)[0];
        testPB.name = PARENT_BILLING_MARKET;
        insert testPB;
        
            
        BoB_Coverage_Eligible__c bobEligibleAecomWithMarketEarliestStartMiddleEnd =  TestingUtils.createBoBCoverageEligibles(new List<Account>{ aecomAccount}, false)[0];
        BoB_Coverage_Eligible__c bobEligibleAecomWithMarketMiddleStartLatestEnd = TestingUtils.createBoBCoverageEligibles(new List<Account>{ aecomAccount}, false)[0];
        BoB_Coverage_Eligible__c bobEligibleAecomWithoutMarketEarliestStartAndLatestEnd = TestingUtils.createBoBCoverageEligibles(new List<Account>{ aecomAccount2}, false)[0];
        bobEligibleAecomWithMarketEarliestStartMiddleEnd.country_Coverage__c = 'Canada';
        bobEligibleAecomWithoutMarketEarliestStartAndLatestEnd.country_Coverage__c = 'Canada';
        bobEligibleAecomWithMarketMiddleStartLatestEnd.country_Coverage__c = 'Canada';
        
        Integer year = Integer.valueOf(testCustomSettings.Focus_Year__c);
        Integer priorYear = year - 1;
        Integer middle = Integer.valueOf(testCustomSettings.Focus_Start_Period__c + Math.round( ( (endPeriod - startPeriod) / 2) ));
        
        setEligibleValues(bobEligibleAecomWithMarketEarliestStartMiddleEnd, startPeriod, middle, year, testPB.id);
        setEligibleValues(bobEligibleAecomWithMarketMiddleStartLatestEnd, middle, endPeriod, year, testPB.id);
        setEligibleValues(bobEligibleAecomWithoutMarketEarliestStartAndLatestEnd, startPeriod, endPeriod, year, null);
        
        insert new List<BoB_Coverage_Eligible__c>{bobEligibleAecomWithMarketEarliestStartMiddleEnd,
                                         bobEligibleAecomWithMarketMiddleStartLatestEnd,
                                         bobEligibleAecomWithoutMarketEarliestStartAndLatestEnd};
                                         
        
        Set<String> expectedHashesforStartToMiddleWMarket = new Set<String>();
        Set<String> expectedHashesforMiddleToLatestWMarket = new Set<String>();
        Set<String> expectedHashesforStartToEndWithoutMarket = new Set<String>();
        
        //Populate the expected hash values for the prior year
        for( Integer i = 1; i < 13; i++)
        {
            expectedHashesforStartToMiddleWMarket.add( IMGA1 + testPB.Id + i + priorYear );
            expectedHashesforMiddleToLatestWMarket.add( IMGA1 + testPB.Id + i + priorYear );
            expectedHashesforStartToEndWithoutMarket.add( IMGA2 + CANADA_LCASE  +  i + priorYear );
        }

        //Populate the expected hash values for the current year
        for( Integer i =  startPeriod; i <=  endPeriod; i++)
        {
            if( i <= middle )
                expectedHashesforStartToMiddleWMarket.add( IMGA1 + testPB.Id + i + year );
            
            if( i >= middle )
                expectedHashesforMiddleToLatestWMarket.add( IMGA1 + testPB.Id + i + year );
                
            expectedHashesforStartToEndWithoutMarket.add( IMGA2 + CANADA_LCASE + i + year );
        }
        
        Map<Id, BoB_Coverage_Eligible__c> actualEligiblesMap = new Map<Id, BoB_Coverage_Eligible__c> ( [SELECT Id, Account__r.IM_IMGA_Indexed__c,
                                                                                      Parent_Billing_Market__c,
                                                                                      Effective_Year__c,
                                                                                      Effective_Start_Period__c,
                                                                                      Effective_End_Period__c,
                                                                                      Effective_Start_Period_Value__c,
                                                                                      Effective_End_Period_Value__c,
                                                                                      Country_Coverage__c
                                                                                      FROM BoB_Coverage_Eligible__c ]);
        
        Set<String>actualsForStartToMiddle;
        Set<String>actualsForMiddleToEnd;
        Set<String>actualsForStartToEnd; 
                
        Test.startTest();
            //Instantiate the helper
            InboundStorageToBoBCoverage_Helper testHelper = new InboundStorageToBoBCoverage_Helper ( CUSTOM_SETTING_NAME );
            
            actualsForStartToMiddle = testHelper.buildHashForCoverageRecord( actualEligiblesMap.get( bobEligibleAecomWithMarketEarliestStartMiddleEnd.Id ));
                                                                                                    
            actualsForMiddleToEnd = testHelper.buildHashForCoverageRecord( actualEligiblesMap.get( bobEligibleAecomWithMarketMiddleStartLatestEnd.Id ));
                                                                                                   
            actualsForStartToEnd = testHelper.buildHashForCoverageRecord( actualEligiblesMap.get( bobEligibleAecomWithoutMarketEarliestStartAndLatestEnd.Id ));
            
        Test.StopTest();
        
        System.assertEquals(expectedHashesforStartToMiddleWMarket.size(), actualsForStartToMiddle.size(), 'The correct number of hashes should be received' );
        System.assert(expectedHashesforStartToMiddleWMarket.containsAll( actualsForStartToMiddle ), 'The correct hashes should be received' );
        
        System.assertEquals(expectedHashesforMiddleToLatestWMarket.size(), actualsForMiddleToEnd.size(), 'The correct number of hashes should be received' );
        System.assert(expectedHashesforMiddleToLatestWMarket.containsAll( actualsForMiddleToEnd ), 'The correct hashes should be received' );
        
        System.assertEquals(expectedHashesforStartToEndWithoutMarket.size(), actualsForStartToEnd.size(), 'The correct number of hashes should be received' );
        System.assert(expectedHashesforStartToEndWithoutMarket.containsAll( actualsForStartToEnd ), 'The correct hashes should be received' );
        
        
    }

    static testMethod void testBuildInboundStorageHashes() 
    {
        final Integer STORAGE_SIZE = 1;
        final String NORTH_AMERICA_LCASE = 'north america';
        final String CANADA_LCASE = 'canada';
        String IMGA1 = 'IM_AECOM';
        String IMGA2 = 'IM_AECOM_2';
        
        setup();
            
            Profile prof = [Select id from Profile where Name = 'IM_Custom Sys Admin' limit 1];

        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                              ,emailencodingkey='UTF-8'
                              , lastname='Testing', languagelocalekey='en_US'
                              , localesidkey='en_US', profileid = prof.id
                              , timezonesidkey='America/Los_Angeles'
                              , username='userwithrole@testorg.com'
                              , Country = 'United Kingdom',
                              CurrencyIsoCode= 'USD'); 

        
        system.runas(u)
        {
            Integer startPeriod = Integer.valueOf(testCustomSettings.Focus_Start_Period__c);
            Integer endPeriod = Integer.valueOf(testCustomSettings.Focus_End_Period__c);
            
            Account aecomAccount = TestingUtils.createAccounts(1, false)[0];
            aecomAccount.IM_IMGA_Indexed__c = IMGA1;
            aecomAccount.IM_Hierarchy_Level__c = 'IM Group (IMGA)';
            insert aecomAccount;
    
            Account aecomAccount2 = TestingUtils.createAccounts(1, false)[0];
            aecomAccount2.IM_IMGA_Indexed__c = IMGA2;
            aecomAccount2.IM_Hierarchy_Level__c = 'IM Group (IMGA)';
            insert aecomAccount2;
            
            Parent_Billing_Market__c testPB = TestingUtils.createParentBillingMarketRecords(1, false)[0];
            testPB.name = PARENT_BILLING_MARKET;
            insert testPB;
            
            Billing_Market__c testBillingMarketWithParent = TestingUtils.createBillingMarketRecords('Test P Market', 1, false)[0];
            testBillingMarketWithParent.Parent_Billing_Market__c = testPB.Id;
            insert testBillingMarketWithParent;
            
            Billing_Market__c testBillingMarketWithoutParent = TestingUtils.createBillingMarketRecords('Test Market', 1, true)[0];
            
            IM_Customer_Account__c imAecomAccount = TestingUtils.createIMCustomerAccounts(1, aecomAccount.Id, true)[0];
            IM_Customer_Account__c imAecom2Account = TestingUtils.createIMCustomerAccounts(1, aecomAccount2.Id, true)[0];
            
            Inbound_Storage__c inboundStorageWithoutParentBillingMarket = TestingUtils.createInboundStorageRecords(imAecomAccount, testBillingMarketWithoutParent, Date.Today(), STORAGE_SIZE, false)[0];
            Inbound_Storage__c inboundStorageWithParentBillingMarket = TestingUtils.createInboundStorageRecords(imAecom2Account, testBillingMarketWithParent, Date.Today(), STORAGE_SIZE, false)[0];
            
            Integer year = Integer.valueOf(testCustomSettings.Focus_Year__c);
            
            Date testValidBeginDate = Date.newInstance(year, startPeriod, 28 );
            Date testValidEndDate = Date.newInstance(year, endPeriod, 1 );
            
            inboundStorageWithoutParentBillingMarket.Storage_Date__c = testValidBeginDate;
            inboundStorageWithParentBillingMarket.Storage_Date__c = testValidEndDate;
            
                                             
            insert new List<Inbound_Storage__c>{inboundStorageWithoutParentBillingMarket,
                                                inboundStorageWithParentBillingMarket};
            
            //Populate expected hash values
            Set<String> expectedHashesforISWithMarket = new Set<String>();
            expectedHashesforISWithMarket.add(IMGA2 + testPB.Id + endPeriod + year );
            expectedHashesforISWithMarket.add(IMGA2 + NORTH_AMERICA_LCASE +  endPeriod + year );
            expectedHashesforISWithMarket.add(IMGA2 + CANADA_LCASE +  endPeriod + year );
            
            Set<String> expectedHashesforISWithoutMarket = new Set<String>();
            expectedHashesforISWithoutMarket.add(IMGA1 + startPeriod + year );
            
                    
            Map<Id, Inbound_Storage__c> actualStorageMap = new Map<Id, Inbound_Storage__c> ( [SELECT Id, Storage_Year__c, Storage_Month__c, Country_Coverage__c,
                                                                                              Cube_District__r.Parent_Billing_Market__c,
                                                                                              IMGA_Name__c
                                                                                              FROM Inbound_Storage__c ]);
            
            List<String>actualsForISWithMarket;
            List<String>actualsForISWithoutMarket;
                    
            Test.startTest();
                //Instantiate the helper
                InboundStorageToBoBCoverage_Helper testHelper = new InboundStorageToBoBCoverage_Helper ( CUSTOM_SETTING_NAME );
                
                actualsForISWithMarket = testHelper.buildHashForInboundStorageRecord( actualStorageMap.get( inboundStorageWithParentBillingMarket.Id ));
                                                                                                        
                actualsForISWithoutMarket = testHelper.buildHashForInboundStorageRecord( actualStorageMap.get( inboundStorageWithoutParentBillingMarket.Id ));
                
            Test.StopTest();
            
            System.assertEquals(expectedHashesforISWithoutMarket.size(), actualsForISWithoutMarket.size(), 'The correct number of hashes should be received' );
            System.assert(expectedHashesforISWithoutMarket.containsAll( actualsForISWithoutMarket ), 'The correct hashes should be received');
            
            System.assertEquals(expectedHashesforISWithMarket.size(), actualsForISWithMarket.size(), 'The correct number of hashes should be received' );
            System.assert(expectedHashesforISWithMarket.containsAll( actualsForISWithMarket ),  expectedHashesforISWithMarket + 'The correct hashes should be received' + actualsForISWithMarket );
       } 
    
    }
    
    
    static testMethod void testBuildBOBCoveragesEligiblesHashMAP() 
    {
        final Integer COVERAGE_SIZE = 1;
        String IMGA1 = 'IM_AECOM';
        String IMGA2 = 'IM_AECOM_2';
        
        setup();
        
        User coverageOwner1;
        User coverageOwner2;
        
        System.runAs(TestingUtils.ADMIN_USER) {
           List<User> users = TestingUtil.createUsers(2, true);
           coverageOwner1 = users[0];
           coverageOwner2 = users[1];
        }
        
        Integer startPeriod = Integer.valueOf(testCustomSettings.Focus_Start_Period__c);
        Integer endPeriod = Integer.valueOf(testCustomSettings.Focus_End_Period__c);
        
        Account aecomAccount = TestingUtils.createAccounts(1, false)[0];
        aecomAccount.IM_IMGA_Indexed__c = IMGA1;
        aecomAccount.IM_Hierarchy_Level__c = 'IM Group (IMGA)';
        insert aecomAccount;
        
        Parent_Billing_Market__c testPB = TestingUtils.createParentBillingMarketRecords(1, false)[0];
        testPB.name = PARENT_BILLING_MARKET;
        insert testPB;
        
        List<BoB_Coverage_Eligible__c> bobEligiblesAecomWithMarketUser1 = TestingUtils.createBoBCoverageEligibles(new List<Account>{ aecomAccount, aecomAccount}, false);
        BoB_Coverage_Eligible__c bobEligiblesAecomWithMarketUser2 = TestingUtils.createBoBCoverageEligibles(new List<Account>{ aecomAccount}, false)[0]; 
        
        Integer year = Integer.valueOf(testCustomSettings.Focus_Year__c);
        Integer priorYear = year - 1;
        Integer middle = Integer.valueOf(testCustomSettings.Focus_Start_Period__c + Math.round( ( (endPeriod - startPeriod) / 2) ));
        
        setEligibleValues(bobEligiblesAecomWithMarketUser1[0], startPeriod, middle, year, testPB.id);
        setEligibleValues(bobEligiblesAecomWithMarketUser1[1], middle, endPeriod, year, testPB.id);
        setEligibleValues(bobEligiblesAecomWithMarketUser2, startPeriod, endPeriod, year, testPB.id);
        
        
        insert new List<BoB_Coverage_Eligible__c>{bobEligiblesAecomWithMarketUser1[0],
                                         bobEligiblesAecomWithMarketUser1[1],
                                         bobEligiblesAecomWithMarketUser2};
                                         
        
        Map<Id, BoB_Coverage_Eligible__c> actualEligiblesMap = new Map<Id, BoB_Coverage_Eligible__c> ( [SELECT Id, Account__r.IM_IMGA_Indexed__c,
                                                                                      Parent_Billing_Market__c,
                                                                                      Effective_Year__c,
                                                                                      Effective_Start_Period__c, 
                                                                                      Effective_End_Period__c, 
                                                                                      Effective_Start_Period_Value__c,
                                                                                      Effective_End_Period_Value__c
                                                                                      FROM BoB_Coverage_Eligible__c ]);
                                                                                   
        BoB_Coverage_Eligible__c eligibleWithMarketUser1 = actualEligiblesMap.get( bobEligiblesAecomWithMarketUser1[0].Id );
        BoB_Coverage_Eligible__c secondEligibleWithMarketUser1 = actualEligiblesMap.get( bobEligiblesAecomWithMarketUser1[1].Id );
        BoB_Coverage_Eligible__c eligibleWithMarketUser2 = actualEligiblesMap.get( bobEligiblesAecomWithMarketUser2.Id );
        
        Map<String, Map<Id, Map<String, Aggregate_Volume__c>>> expectedHashesforCoverages = new Map<String, Map<Id, Map<String, Aggregate_Volume__c>>>();
        
        //Populate the expected hash values for the prior year
        for( Integer i = 1; i < 13; i++)
        {
            Map<Id, Map<String, Aggregate_Volume__c>> coverageIdToVolume = new Map<Id, Map<String, Aggregate_Volume__c>>();
            coverageIdToVolume.put( eligibleWithMarketUser1.id, null );
            coverageIdToVolume.put( secondEligibleWithMarketUser1.id, null );
            coverageIdToVolume.put( eligibleWithMarketUser2.id, null );
            
            expectedHashesforCoverages.put( IMGA1 + testPB.Id + i + priorYear, coverageIdToVolume );
        }

        //Populate the expected hash values for the current year
        for( Integer i =  startPeriod; i <=  endPeriod; i++)
        {
            Map<Id, Map<String, Aggregate_Volume__c>> coverageIdToVolume = new Map<Id, Map<String, Aggregate_Volume__c>>();
            
            if( i <= middle )
                coverageIdToVolume.put( eligibleWithMarketUser1.id, null);
            
            if( i >= middle )
                coverageIdToVolume.put( secondEligibleWithMarketUser1.id, null);
                
            coverageIdToVolume.put( eligibleWithMarketUser2.id, null);
            expectedHashesforCoverages.put( IMGA1 + testPB.Id + i + year, coverageIdToVolume );
        }
        
        
        List<BoB_Coverage_Eligible__c> actualEligibles = new List<BoB_Coverage_Eligible__c>{eligibleWithMarketUser1, secondEligibleWithMarketUser1, eligibleWithMarketUser2};
        
        Map<String, Map<Id, Map<String, Aggregate_Volume__c>>> actualHashesforCoverages = new Map<String, Map<Id, Map<String, Aggregate_Volume__c>>>();
                        
        Test.startTest();
            //Instantiate the helper
            InboundStorageToBoBCoverage_Helper testHelper = new InboundStorageToBoBCoverage_Helper ( CUSTOM_SETTING_NAME );
            testHelper.buildCoverageMap( actualEligibles, actualHashesforCoverages );
                                                                                                    
        Test.StopTest();
        
        System.assertEquals(expectedHashesforCoverages.keySet(), actualHashesforCoverages.keySet(), 'The correct hashes should be received' );
        
        for( String actualHash : actualHashesforCoverages.keySet() )
        {
            Map<Id, Map<String, Aggregate_Volume__c>> coverageIdToVolume = actualHashesforCoverages.get( actualHash );
            
            System.assertEquals( expectedHashesforCoverages.get( actualHash ), coverageIdToVolume, 'The Coverages should be hashed correctly');
        }
    }
    
    static Map<Id, Map<String, Aggregate_Volume__c>> buildExpectedCoverageVolumeMap( Id coverageId, Decimal volume, Date storageDate, Id custAcctId, Id parentBillingMarketId)
    {
        Map<Id, Map<String, Aggregate_Volume__c>> expectedCoverageVolume = new Map<Id, Map<String, Aggregate_Volume__c>>();
        
        Aggregate_Volume__c test1 = TestingUtils.createAggregateVolumes ( coverageId, 1, false )[0]; 
        
          test1.Total_Volume__c = volume; 
          test1.Storage_Date__c = storageDate; 
          test1.Customer_Account__c = custAcctId;
          test1.Parent_Billing_Market__c = parentBillingMarketId;
          test1.Inbound_Storage_Matching_Hash__c = coverageID + storageDate.toStartOfMonth().format() + parentBillingMarketId + ':' +custAcctId;
              
        expectedCoverageVolume.put( coverageId, new Map<String, Aggregate_Volume__c> {parentBillingMarketId+':'+custAcctId => test1});
        
        return expectedCoverageVolume;
    }
    
    static testMethod void testBuildVolumeAndPopulateCoverageMap() 
    {
        final Integer STORAGE_SIZE = 1;
        final String NORTH_AMERICA_LCASE = 'north america';
        String IMGA1 = 'IM_AECOM';
        String IMGA2 = 'IM_AECOM_2';
        
         Profile prof = [Select id from Profile where Name = 'IM_Custom Sys Admin' limit 1];

        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                              ,emailencodingkey='UTF-8'
                              , lastname='Testing', languagelocalekey='en_US'
                              , localesidkey='en_US', profileid = prof.id
                              , timezonesidkey='America/Los_Angeles'
                              , username='userwithrole@testorg.com'
                              , Country = 'United Kingdom',
                              CurrencyIsoCode= 'USD'); 

        
        system.runas(u)
        {
        
            setup();
            
            Integer startPeriod = Integer.valueOf(testCustomSettings.Focus_Start_Period__c);
            Integer endPeriod = Integer.valueOf(testCustomSettings.Focus_End_Period__c);
            
            Account aecomAccount = TestingUtils.createAccounts(1, false)[0];
            aecomAccount.IM_IMGA_Indexed__c = IMGA1;
            aecomAccount.IM_Hierarchy_Level__c = 'IM Group (IMGA)';
            insert aecomAccount;
            
            Account aecomAccount2 = TestingUtils.createAccounts(1, false)[0];
            aecomAccount2.IM_IMGA_Indexed__c = IMGA2;
            aecomAccount2.IM_Hierarchy_Level__c = 'IM Group (IMGA)';
            insert aecomAccount2;
            
            Parent_Billing_Market__c testPB = TestingUtils.createParentBillingMarketRecords(1, false)[0];
            testPB.name = PARENT_BILLING_MARKET;
            insert testPB;
    
            Parent_Billing_Market__c testPB2 = TestingUtils.createParentBillingMarketRecords(1, false)[0];
            testPB2.name = PARENT_BILLING_MARKET;
            insert testPB2;
            
            Billing_Market__c testBillingMarketWithParent = TestingUtils.createBillingMarketRecords('Test P Market', 1, false)[0];
            testBillingMarketWithParent.Parent_Billing_Market__c = testPB.Id;
            insert testBillingMarketWithParent;
    
            Billing_Market__c testBillingMarketWithParent2 = TestingUtils.createBillingMarketRecords('Test P Market2', 1, false)[0];
            testBillingMarketWithParent2.Parent_Billing_Market__c = testPB2.Id;
            insert testBillingMarketWithParent2;
            
            IM_Customer_Account__c imAecomAccount = TestingUtils.createIMCustomerAccounts(1, aecomAccount.Id, true)[0];
            IM_Customer_Account__c imAecomAccount2 = TestingUtils.createIMCustomerAccounts(1, aecomAccount2.Id, true)[0];
            IM_Customer_Account__c imAecomAccount3 = TestingUtils.createIMCustomerAccounts(1, aecomAccount2.Id, true)[0];
            
            Inbound_Storage__c IS_1_Match_Coverage_1 = TestingUtils.createInboundStorageRecords(imAecomAccount, testBillingMarketWithParent, Date.Today(), STORAGE_SIZE, false)[0];
            Inbound_Storage__c IS_2_Match_Coverage_1 = TestingUtils.createInboundStorageRecords(imAecomAccount, testBillingMarketWithParent, Date.Today(), STORAGE_SIZE, false)[0];
            Inbound_Storage__c IS_Match_Coverage_2 = TestingUtils.createInboundStorageRecords(imAecomAccount2, testBillingMarketWithParent, Date.Today(), STORAGE_SIZE, false)[0];
            Inbound_Storage__c IS_1_Match_Coverage_3 = TestingUtils.createInboundStorageRecords(imAecomAccount2, testBillingMarketWithParent, Date.Today(), STORAGE_SIZE, false)[0];
            Inbound_Storage__c IS_2_Match_Coverage_3 = TestingUtils.createInboundStorageRecords(imAecomAccount2, testBillingMarketWithParent, Date.Today(), STORAGE_SIZE, false)[0];
            Inbound_Storage__c IS_3_Match_Coverage_3 = TestingUtils.createInboundStorageRecords(imAecomAccount3, testBillingMarketWithParent, Date.Today(), STORAGE_SIZE, false)[0];
            Inbound_Storage__c IS_4_Match_Coverage_3 = TestingUtils.createInboundStorageRecords(imAecomAccount3, testBillingMarketWithParent2, Date.Today(), STORAGE_SIZE, false)[0];
            
            Integer year = Integer.valueOf(testCustomSettings.Focus_Year__c);
            Date testValidBeginDate = Date.newInstance(year, startPeriod, 28 );
            Date testValidEndDate = Date.newInstance(year, endPeriod, 1 );
            
            IS_1_Match_Coverage_1.Storage_Date__c = testValidEndDate;
            IS_1_Match_Coverage_1.Box__c = 100;
            
            IS_2_Match_Coverage_1.Storage_Date__c = testValidEndDate.addMonths(-1);
            IS_2_Match_Coverage_1.Box__c = 100;
            
            IS_Match_Coverage_2.Storage_Date__c = testValidEndDate;
            IS_Match_Coverage_2.Box__c = 100;
            
            IS_1_Match_Coverage_3.Storage_Date__c = testValidBeginDate;
            IS_1_Match_Coverage_3.Box__c = 100;
    
            IS_2_Match_Coverage_3.Storage_Date__c = testValidBeginDate;
            IS_2_Match_Coverage_3.Box__c = 100;
    
            IS_3_Match_Coverage_3.Storage_Date__c = testValidBeginDate;
            IS_3_Match_Coverage_3.Box__c = 100;
    
            IS_4_Match_Coverage_3.Storage_Date__c = testValidBeginDate;
            IS_4_Match_Coverage_3.Box__c = 600;
            
                                             
            List<Inbound_Storage__c> allInboundStorageRecords = new List<Inbound_Storage__c>{IS_Match_Coverage_2,
                                                                                            IS_1_Match_Coverage_3,
                                                                                            IS_2_Match_Coverage_3,
                                                                                            IS_3_Match_Coverage_3,
                                                                                            IS_4_Match_Coverage_3,
                                                                                            IS_1_Match_Coverage_1,
                                                                                            IS_2_Match_Coverage_1};
            insert allInboundStorageRecords;                                                                                
        
        
        List<BoB_Coverage_Eligible__c> eligibles = TestingUtils.createBoBCoverageEligibles(new List<Account>{ aecomAccount, aecomAccount, aecomAccount}, false);
        for(Bob_Coverage_Eligible__c eligible : eligibles ) {
            eligible.Country_Coverage__c = 'North America';
        }
        insert eligibles;
        
        BoB_Coverage_Eligible__c coverage1 = eligibles[0];
        BoB_Coverage_Eligible__c coverage2 = eligibles[1];
        BoB_Coverage_Eligible__c coverage3 = eligibles[2];
        
        
        String hashForCoverage1 = IMGA1 + testPB.Id + endPeriod + year;
        String secondHashForCoverage1 = IMGA1 + testPB.Id + (endPeriod - 1) + year;
        String hashForCoverage2 = IMGA2 + NORTH_AMERICA_LCASE + endPeriod + year;
        String hashForCoverage3 = IMGA2 + NORTH_AMERICA_LCASE + startPeriod + year;
        
        Map<String, Map<Id, Map<String, Aggregate_Volume__c>>> expectedCoverageMap = new Map<String, Map<Id, Map<String, Aggregate_Volume__c>>>();
        Map<String, Map<Id, Map<String, Aggregate_Volume__c>>> actualCoverageMap = new Map<String, Map<Id, Map<String, Aggregate_Volume__c>>>();
        
        Map<Id, Map<String, Aggregate_Volume__c>> expectedCoverage1Volumes = buildExpectedCoverageVolumeMap( coverage1.id, 100.00, Date.newInstance( year, endPeriod, 1), imAecomAccount.Id, testPB.Id);
        Map<Id, Map<String, Aggregate_Volume__c>> expectedCoverage1Volumes_part2 = buildExpectedCoverageVolumeMap( coverage1.id, 100.00, Date.newInstance( year, (endPeriod - 1), 1), imAecomAccount.Id, testPB.Id);
        Map<Id, Map<String, Aggregate_Volume__c>> expectedCoverage2Volumes = buildExpectedCoverageVolumeMap( coverage2.id, 100.00, Date.newInstance( year, endPeriod, 1), imAecomAccount2.Id, testPB.Id);
        Map<Id, Map<String, Aggregate_Volume__c>> expectedCoverage3Volumes = buildExpectedCoverageVolumeMap( coverage3.id, 200.00, Date.newInstance( year, startPeriod, 1), imAecomAccount2.Id, testPB.Id);
        
        Map<Id, Map<String, Aggregate_Volume__c>> temp3VolumeVariesByCustomerAccount = buildExpectedCoverageVolumeMap( coverage3.id, 100.00, Date.newInstance( year, startPeriod, 1), imAecomAccount3.Id, testPB.Id);
        expectedCoverage3Volumes.get(coverage3.id).putAll( temp3VolumeVariesByCustomerAccount.get( coverage3.id ) );

        Map<Id, Map<String, Aggregate_Volume__c>> temp3VolumeVariesByParentBillingMarket = buildExpectedCoverageVolumeMap( coverage3.id, 600.00, Date.newInstance( year, startPeriod, 1), imAecomAccount3.Id, testPB2.Id);
        expectedCoverage3Volumes.get(coverage3.id).putAll( temp3VolumeVariesByParentBillingMarket.get( coverage3.id ) );

        expectedCoverageMap.put( hashForCoverage1, expectedCoverage1Volumes);
        expectedCoverageMap.put( secondHashForCoverage1, expectedCoverage1Volumes_part2);
        expectedCoverageMap.put( hashForCoverage2, expectedCoverage2Volumes);
        expectedCoverageMap.put( hashForCoverage3, expectedCoverage3Volumes);
        
        Map<Id, Map<String, Aggregate_Volume__c>> actualCoverage1Volumes = new Map<Id, Map<String, Aggregate_Volume__c>>{ coverage1.id => null };
        Map<Id, Map<String, Aggregate_Volume__c>> actualCoverage1Volumes_part2 = new Map<Id, Map<String, Aggregate_Volume__c>>{ coverage1.id => null };
        Map<Id, Map<String, Aggregate_Volume__c>> actualCoverage2Volumes = new Map<Id, Map<String, Aggregate_Volume__c>>{ coverage2.id => null };
        Map<Id, Map<String, Aggregate_Volume__c>> actualCoverage3Volumes = new Map<Id, Map<String, Aggregate_Volume__c>>{ coverage3.id => null };

        actualCoverageMap.put( hashForCoverage1, actualCoverage1Volumes);
        actualCoverageMap.put( secondHashForCoverage1, actualCoverage1Volumes_part2);
        actualCoverageMap.put( hashForCoverage2, actualCoverage2Volumes);
        actualCoverageMap.put( hashForCoverage3, actualCoverage3Volumes);
        
                
        List<Inbound_Storage__c> actualStorages = new List<Inbound_Storage__c> ( [SELECT Id, Storage_Year__c, Storage_Month__c, Total_Volume__c, Storage_Date__c, Country_Coverage__c,
                                                                                  Cube_District__r.Parent_Billing_Market__c, Customer_Account__c,
                                                                                  IMGA_Name__c
                                                                                  FROM Inbound_Storage__c ]);
        Map<String, Aggregate_Volume__c> volumeRecords = new Map<String, Aggregate_Volume__c>();
        List<String> hashesResults = new List<STring>();
        Test.startTest();
            InboundStorageToBoBCoverage_Helper testHelper = new InboundStorageToBoBCoverage_Helper ( CUSTOM_SETTING_NAME );
            Map<String, List<Aggregate_Volume__c>> existingRelevantVolumes = new Map<String, List<Aggregate_Volume__c>>();
            for( Inbound_Storage__c storage : actualStorages )
            {
                List<String> hashes = testHelper.buildHashForInboundStorageRecord( storage );
                hashesResults.addAll(hashes);
                testHelper.buildVolumeRecordsAndPopulateCoverageMap( actualCoverageMap, storage, volumeRecords, existingRelevantVolumes, hashes );
            }
            
        Test.StopTest();
        System.assertEquals( 6, volumeRecords.size(), 'The correct number of volume records should be found' );
        
        for( String actualHash : actualCoverageMap.keySet() )
        {
            Map<Id, Map<String, Aggregate_Volume__c>> coverageIdToVolume = actualCoverageMap.get( actualHash );
            
            System.assertEquals( expectedCoverageMap.get( actualHash ), coverageIdToVolume,  'The Coverages should be hashed correctly');
        }
     }
    }
    */
}