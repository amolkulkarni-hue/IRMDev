/* Commenting the entire code as part of Gitlab #24448 */
@isTest
private class Test_M1_Physical_CDE_Batch {
    /*
    static final String CUSTOM_SETTING_NAME = 'Sandbox';
    static M1_CDE_Settings__c testCustomSettings;
    static final string PARENT_BILLING_MARKET = 'Kansas City';
    static final string OTHER_BILLING_MARKET = 'Boston';
    static final String TEST_JOB_ID = 'M1_Joins_' + DateTime.now().format('MM/dd_HH:mm:ss');
    static List<Inbound_Storage__c> validInboundStorageRecords;
    static integer additionalEligibleMatches = 0;
    //These examples were taken from the requirements doc IM gave us to ensure proper understanding of
    //their intended goal with this batch job. More stringent tests are included below. 
    
    
    static final Map<String, String> example1Params = new Map<String, String>{
        'Effective_Start_Period__c' => '1',
        'Effective_End_Period__c'   => '4',
        'Effective_Year__c'         => '2013',
        'Sales_Rep_Name__c'             => 'Test Rep',
        'Customer_Account__c'       => 'IM_TEST_ACCOUNT',
        'Cube_District__c'      => 'Kansas City',
        'Start_Period__c'           => '2',
        'End_Period__c'             => '12',
        'Year__c'                   => '2013'
    };

    static final Map<String, String> example2Params = new Map<String, String>{
        'Effective_Start_Period__c' => '1',
        'Effective_End_Period__c'   => '4',
        'Effective_Year__c'         => '2013',
        'Sales_Rep_Name__c'             => 'Test Rep',
        'Customer_Account__c'       => 'IM_AECOM',
        'Cube_District__c'      => '',
        'Start_Period__c'           => '2',
        'End_Period__c'             => '3',
        'Year__c'                   => '2013'
    };

    //create custom settings in a static block
    static{
        testCustomSettings = new M1_CDE_Settings__c();
        testCustomSettings.Focus_Start_Period__c = 3;
        testCustomSettings.Focus_End_Period__c = 12;
        testCustomSettings.Focus_Year__c = '2013';
        testCustomSettings.Name = CUSTOM_SETTING_NAME;
        testCustomSettings.Query_Associate_Order_By__c = 'Id Desc';
        testCustomSettings.Query_Associate_Select__c = 'Id, Storage_Year__c, Storage_Month__c, Storage_Date__c, Country_Coverage__c, ' + 
                                                       ' Cube_District__r.Parent_Billing_Market__c, IMGA_Name__c, Total_Volume__c, Customer_Account__c ';
        testCustomSettings.Query_Associate_Where__c = ' Id <> Null';
        System.runAs( TestingUtils.ADMIN_USER )
        {
            insert testCustomSettings;
        }
    }

        
        
    static void setup(Integer coverageRecords, Integer storageRecords){
        User coverageOwner;
        System.runAs(TestingUtils.ADMIN_USER) {
           coverageOwner = TestingUtil.createUsers(1, false)[0];
        }
        
        
         Profile prof = [Select id from Profile where Name = 'IM_Custom Sys Admin' limit 1];

        User u = new User(alias = 'hasrole', email='userwithrole@roletest1.com'
                              ,emailencodingkey='UTF-8'
                              , lastname='Testing', languagelocalekey='en_US'
                              , localesidkey='en_US', profileid = prof.id
                              , timezonesidkey='America/Los_Angeles'
                              , username='userwithrole@testorg.com'
                              , Country = 'United Kingdom',
                              CurrencyIsoCode= 'USD'); 

        
        
        Parent_Billing_Market__c testPB = TestingUtils.createParentBillingMarketRecords(1, false)[0];
        testPB.name = PARENT_BILLING_MARKET;
        insert testPB;
        
        Parent_Billing_Market__c testPB2 = TestingUtils.createParentBillingMarketRecords(1, false)[0];
        testPB2.name = OTHER_BILLING_MARKET;
        insert testPB2;
        
        Billing_Market__c testBillingMarket = TestingUtils.createBillingMarketRecords('Test P Market', 1, false)[0];
        testBillingMarket.Parent_Billing_Market__c = testPB.Id;
        insert testBillingMarket;
        
        Billing_Market__c testBillingMarket2 = TestingUtils.createBillingMarketRecords('Test Market', 1, false)[0];
        testBillingMarket2.Parent_Billing_Market__c = testPB2.id;
        insert testBillingMarket2;
        
        Account aecomAccount = TestingUtils.createAccounts(1, false)[0];
        aecomAccount.IM_IMGA_Indexed__c = 'IM_AECOM';
        
        Account otherAccount = TestingUtils.createAccounts(1, false)[0];
        otherAccount.IM_IMGA_Indexed__c = 'IM_TEST_ACCOUNT';
        
        insert new list<Account>{ aecomAccount, otherAccount };
        
        IM_Customer_Account__c imAecomAccount = TestingUtils.createIMCustomerAccounts(1, aecomAccount.Id, true)[0];
        IM_Customer_Account__c imOtherAccount = TestingUtils.createIMCustomerAccounts(1, otherAccount.Id, true)[0];
        
        Integer startMonth = Integer.valueOf(testCustomSettings.Focus_Start_Period__c);
        Integer endMonth = Integer.valueOf(testCustomSettings.Focus_End_Period__c);
        Integer year = Integer.valueOf(testCustomSettings.Focus_Year__c);
  
        
        List<BoB_Coverage_Eligible__c> bobCoverageEligibleAecom = TestingUtils.createBoBCoverageEligibles(new List<Account>{ aecomAccount}, false  );
        for(BOB_Coverage_Eligible__c eligible : bobCoverageEligibleAecom) {
            Test_InboundStorageToBoBCoverageHelper.setEligibleValues(eligible, startMonth, endMonth, year, testPB.id);
            eligible.country_coverage__c = 'Canada';
        }
        
        List<BoB_Coverage_Eligible__c> bobCoverageEligibleOtherAccount = TestingUtils.createBoBCoverageEligibles(new List<Account>{ otherAccount}, false  );
        for(BOB_Coverage_Eligible__c eligible : bobCoverageEligibleOtherAccount) {
            Test_InboundStorageToBoBCoverageHelper.setEligibleValues(eligible, 1, 2, year, null);
            eligible.country_coverage__c = 'Canada';
        }
        
        List<BoB_Coverage_Eligible__c> bobCoverageEligibleForCountry= TestingUtils.createBoBCoverageEligibles( new List<Account>{aecomAccount},  false); 
        for(BOB_Coverage_Eligible__c eligible : bobCoverageEligibleForCountry) {
            Test_InboundStorageToBoBCoverageHelper.setEligibleValues(eligible, 1, 2, year, null);
            eligible.country_coverage__c = 'North America';
        }

        List<BoB_Coverage_Eligible__c> allEligibles = new List<BoB_Coverage_Eligible__c>(); 
        allEligibles.addAll(bobCoverageEligibleAecom);
        allEligibles.addAll(bobCoverageEligibleOtherAccount);
        allEligibles.addAll(bobCoverageEligibleForCountry);
        insert allEligibles;
        
        
        List<Inbound_Storage__c> inboundStoragesWithMarketAndCountryMatches = TestingUtils.createInboundStorageRecords(imAecomAccount, testBillingMarket, Date.Today(), storageRecords, false);
        List<Inbound_Storage__c> inboundStoragesWithMarketMatches = TestingUtils.createInboundStorageRecords(imAecomAccount, testBillingMarket2, Date.Today(), storageRecords, false);
        List<Inbound_Storage__c> inboundStoragesWithImTestAccount = TestingUtils.createInboundStorageRecords(imOtherAccount, testBillingMarket, Date.Today(), storageRecords, false);
        
        List<Inbound_Storage__c> allInboundStorageRecords = new List<Inbound_Storage__c>();
        validInboundStorageRecords = new List<Inbound_Storage__c>();
        allInboundStorageRecords.addAll(inboundStoragesWithMarketMatches);
        allInboundStorageRecords.addAll(inboundStoragesWithMarketAndCountryMatches);
        allInboundStorageRecords.addAll(inboundStoragesWithImTestAccount);
        
        Integer inboundCount = allInboundStorageRecords.size();
        
        Set<Inbound_Storage__c> inboundStoragesWithMarketAndCountryMatchesSet = new Set<Inbound_Storage__c>(inboundStoragesWithMarketAndCountryMatches);
        
        for (integer i = 0; i < inboundCount ; i++ ) {
            Integer mod = Math.mod(i, 12);
            Integer yearMod = Math.mod(i, 2);
            if ( (yearMod == 1 ) || ((testCustomSettings.Focus_Start_Period__c <= i) && (testCustomSettings.Focus_End_Period__c >= i)) ){
                validInboundStorageRecords.add(allInboundStorageRecords[i]);
            }
            allInboundStorageRecords[i].Storage_Date__c = date.newinstance(Integer.valueof(testCustomSettings.Focus_Year__c) - yearMod, mod + 1, i + 1);
            allInboundStorageRecords[i].Box__c = 100;
        }
        
        System.runAs(u)
        {
            insert allInboundStorageRecords;
        }
        
    }

    static testMethod void testExample1() {
        setup(1, 3);
        
        Test.startTest();
            //Run the M1 batch
            M1_Physical_CDE_Batch testJob = new M1_Physical_CDE_Batch( CUSTOM_SETTING_NAME, TEST_JOB_ID);
            Database.executeBatch( testJob );
        Test.stopTest();
        
        List<Aggregate_Volume__c> actualVolumes = [Select Id, Total_Volume__c, Inbound_Storage_Matching_Hash__c from Aggregate_Volume__c];
        
        system.assertEquals( validInboundStorageRecords.size() , actualVolumes.size() , 'The correct number of Volume records should be created');
        
    }
*/
}