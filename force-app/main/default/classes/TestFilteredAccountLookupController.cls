@isTest
private class TestFilteredAccountLookupController {

    static Opportunity opp;
    static List<IM_Customer_Account__c> testIMCustomerAccounts = new List<IM_Customer_Account__c>();
    static List<Account> testAccounts;
    static final String IM_ACCOUNT_NAME = 'IM_DELOITTE';
    static final Integer NUM_ACCOUNTS = 4;
    static final Integer NUM_IM_CUST_ACCOUNTS = 4;
    static final String CUST_NAME_FULL = 'TestCustName';
    static Integer counter = 0;
    
    static void setup() {
        
        Boolean connectAccounts = true;
        
        setup( connectAccounts );
    }
    
    static void setup( Boolean connectAccounts ) {
        
        TestingUtils.setupCountryCustomSettings(true);
       // setupOpportunitySecuritySettings();
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        testAccounts = TestingUtils.createAccounts(NUM_ACCOUNTS, false);
        
        if( connectAccounts )
        {
            for (Account acc : testAccounts){
                acc.IM_IMGA_Indexed__c = IM_ACCOUNT_NAME;
            }
        }
        
        insert testAccounts; 
        
        
        
        
        opp = TestingUtils.createOpportunity('Test Opp', testAccounts[0].Id, true);
        
        for (Account acc : testAccounts){
            testIMCustomerAccounts.addAll(TestingUtils.createIMCustomerAccounts(NUM_IM_CUST_ACCOUNTS, acc.Id, false));
        }
        
        for( IM_Customer_Account__c testIMCust : testIMCustomerAccounts)
        {
            testIMCust.Name = CUST_NAME_FULL + counter;
            testIMCust.IM_Status__c = FilteredAccountLookupController.IM_ACCOUNT_STATUS;
            testIMCust.NA_PY_YTD_Consulting__c = 10.0;
            testIMCust.NA_CY_YTD_Consulting__c = 10.0;
            
            counter++;
        }
        
        insert testIMCustomerAccounts;
        
        testIMCustomerAccounts = [SELECT Id, Name, 
                                  IM_Account__c, NA_PY_YTD_TOTAL__c, 
                                  NA_CY_YTD_TOTAL__c, IM_Status__c 
                                  FROM IM_Customer_Account__c
                                  WHERE Id in : testIMCustomerAccounts];
                                  
    }
    
    static testMethod void testFilteredLookupConstructor(){
        
        setup();
        
        PageReference filteredPage = Page.FilteredAccountLookup;
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.OPPORTUNITY_ID_KEY, opp.Id);
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.QUERY_KEY, '');

        Test.setCurrentPageReference(filteredPage);
        List<IM_Customer_Account__c> accountsFound = new List<IM_Customer_Account__c>();            
        
        Test.startTest();
            FilteredAccountLookupcontroller testController = new FilteredAccountLookupcontroller();
            accountsFound = testController.accounts;
        Test.stopTest();
        Integer accSize = testController.accountsSize;
        List<IM_Customer_Account__c> accountsFound1 = new List<IM_Customer_Account__c>();
        accountsFound1.addAll(testController.blanketAccounts);
        System.assertEquals( testIMCustomerAccounts.size(),  accountsFound.size(), 'We should find the correct number of customer accounts');           
        System.assert( new Map<Id, IM_Customer_Account__c>(testIMCustomerAccounts).keySet().containsAll( new map<Id, IM_Customer_Account__c>(accountsFound).keySet()), 'We should find the correct customer accounts');         
        
    }

    static testMethod void testFilteredLookupMissingOppId(){
        
        setup();
        
        PageReference filteredPage = Page.FilteredAccountLookup;
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.QUERY_KEY, '');

        Test.setCurrentPageReference(filteredPage);
        List<IM_Customer_Account__c> accountsFound = new List<IM_Customer_Account__c>();            
        
        Test.startTest();
            FilteredAccountLookupcontroller testController = new FilteredAccountLookupcontroller();
            accountsFound = testController.accounts;
        Test.stopTest();
        
        //System.assert( TestingUtils.pageMessageContains( FilteredAccountLookupcontroller.OPP_NOT_FOUND_MESSAGE), 'We should find the correct number of customer accounts');         
        
    }
    
    static testMethod void testFilteredLookupCannotFindOpp(){
        
        setup();
        
        PageReference filteredPage = Page.FilteredAccountLookup;
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.OPPORTUNITY_ID_KEY, opp.Id);
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.QUERY_KEY, '');

        Test.setCurrentPageReference(filteredPage);
        List<IM_Customer_Account__c> accountsFound = new List<IM_Customer_Account__c>();            
        
        //Delete the oppty
        delete opp;
        
        Test.startTest();
            FilteredAccountLookupcontroller testController = new FilteredAccountLookupcontroller();
            accountsFound = testController.accounts;
        Test.stopTest();
        
        System.assert( TestingUtils.pageMessageContains( FilteredAccountLookupcontroller.OPP_NOT_FOUND_MESSAGE), 'We should find the correct number of customer accounts');         
        
    }

    static testMethod void testFilteredLookupEmptyCustAccounts(){
        
        setup();
        
        PageReference filteredPage = Page.FilteredAccountLookup;
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.OPPORTUNITY_ID_KEY, opp.Id);
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.QUERY_KEY, '');

        Test.setCurrentPageReference(filteredPage);
        List<IM_Customer_Account__c> accountsFound = new List<IM_Customer_Account__c>();            
        
        //Delete the cust accounts
        delete testIMCustomerAccounts;
        
        Test.startTest();
            FilteredAccountLookupcontroller testController = new FilteredAccountLookupcontroller();
            accountsFound = testController.accounts;
        Test.stopTest();
        
        System.assert( TestingUtils.pageMessageContains( FilteredAccountLookupcontroller.NO_RESULTS_MESSAGE), 'We should find the correct number of customer accounts');            
        
    }

    static testMethod void testFilteredLookupWithMisMatchingCriteria(){
        
        setup();
        
        final Integer ADDITIONAL_NUM_IM_CUST_ACCOUNTS = 6;
        final String IM_ACCOUNT_STATUS_INACTIVE = 'Inactive';
                
        //Create some additional IM Cust Accounts which do not meet the dollar amount criteria
        List<IM_Customer_Account__c> noCurrencyCustAccounts = TestingUtils.createIMCustomerAccounts(ADDITIONAL_NUM_IM_CUST_ACCOUNTS, testAccounts[0].Id, false);
        
        for( IM_Customer_Account__c noCurr : noCurrencyCustAccounts)
        {
            noCurr.IM_Status__c = FilteredAccountLookupController.IM_ACCOUNT_STATUS;
        }
        
        //Create some additional IM Cust Accounts which do not meet the status criteria
        List<IM_Customer_Account__c> noStatusCustAccounts = TestingUtils.createIMCustomerAccounts(ADDITIONAL_NUM_IM_CUST_ACCOUNTS, testAccounts[1].Id, false);
        
        for( IM_Customer_Account__c noStat : noStatusCustAccounts)
        {
            noStat.IM_Status__c = IM_ACCOUNT_STATUS_INACTIVE;
            noStat.NA_PY_YTD_Consulting__c = 10.0;
            noStat.NA_CY_YTD_Consulting__c = 10.0;
        }
        
        List<IM_Customer_Account__c> redHerringAccounts = new List<IM_Customer_Account__c>();
        redHerringAccounts.addAll( noCurrencyCustAccounts );
        redHerringAccounts.addAll( noStatusCustAccounts );
        
        insert redHerringAccounts;
        
        PageReference filteredPage = Page.FilteredAccountLookup;
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.OPPORTUNITY_ID_KEY, opp.Id);
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.QUERY_KEY, '');

        Test.setCurrentPageReference(filteredPage);
        List<IM_Customer_Account__c> accountsFound = new List<IM_Customer_Account__c>();            
        
        Test.startTest();
            FilteredAccountLookupcontroller testController = new FilteredAccountLookupcontroller();
            accountsFound = testController.accounts;
        Test.stopTest();
        
        //System.assertEquals( testIMCustomerAccounts.size(),  accountsFound.size(), 'We should find the correct number of customer accounts');           
        //System.assert( new Map<Id, IM_Customer_Account__c>(testIMCustomerAccounts).keySet().containsAll( new map<Id, IM_Customer_Account__c>(accountsFound).keySet()), 'We should find the correct customer accounts');         
        
    }
    
    static testMethod void testFilteredLookupWithAccountOutsideOfHierarchy(){
        
        setup();
        
        final Integer ADDITIONAL_NUM_IM_CUST_ACCOUNTS = 6;
        
        Account outSideAccount = TestingUtils.createAccounts(1, true)[0];
        
        //Create some additional IM Cust Accounts which do not meet the criteria
        TestingUtils.createIMCustomerAccounts(ADDITIONAL_NUM_IM_CUST_ACCOUNTS, outSideAccount.Id, true);
        
        PageReference filteredPage = Page.FilteredAccountLookup;
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.OPPORTUNITY_ID_KEY, opp.Id);
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.QUERY_KEY, '');

        Test.setCurrentPageReference(filteredPage);
        List<IM_Customer_Account__c> accountsFound = new List<IM_Customer_Account__c>();            
        
        Test.startTest();
            FilteredAccountLookupcontroller testController = new FilteredAccountLookupcontroller();
            accountsFound = testController.accounts;
        Test.stopTest();
        
        System.assertEquals( testIMCustomerAccounts.size(),  accountsFound.size(), 'We should find the correct number of customer accounts');           
        System.assert( new Map<Id, IM_Customer_Account__c>(testIMCustomerAccounts).keySet().containsAll( new map<Id, IM_Customer_Account__c>(accountsFound).keySet()), 'We should find the correct customer accounts');         
        
    }
    
    static testMethod void testFilteredLookupWithNoHierarchy(){
        
        setup( false );
        
        PageReference filteredPage = Page.FilteredAccountLookup;
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.OPPORTUNITY_ID_KEY, opp.Id);
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.QUERY_KEY, '');

        Test.setCurrentPageReference( filteredPage );
        
        List<IM_Customer_Account__c> accountsFound = new List<IM_Customer_Account__c>();            
        
        Test.startTest();
            FilteredAccountLookupcontroller testController = new FilteredAccountLookupcontroller();
            accountsFound = testController.accounts;
        Test.stopTest();
        
        System.assertEquals( NUM_IM_CUST_ACCOUNTS,  accountsFound.size(), 'We should find the correct number of customer accounts');            
        
        for( IM_Customer_Account__c found : accountsFound )
        {
            System.assertEquals( testAccounts[0].Id, found.IM_Account__c, 'The Customer Account Records should all be connected to the correct account' );  
        }
        
    }
    
    static testMethod void testFilteredLookupWithSearch(){
        
        setup();
        
        final String SEARCH_TERM = 'TestCust';
        final String ADDITIONAL_NAME = 'DO NOT MATCH';
        final Integer ADDITIONAL_NUM_IM_CUST_ACCOUNTS = 6;
                
        //Create some additional IM Cust Accounts which do not meet the search criteria
        List<IM_Customer_Account__c> noTextMatchCustAccounts = TestingUtils.createIMCustomerAccounts(ADDITIONAL_NUM_IM_CUST_ACCOUNTS, testAccounts[0].Id, false);
        
        for( IM_Customer_Account__c noMatch : noTextMatchCustAccounts)
        {
            noMatch.Name = ADDITIONAL_NAME;
            noMatch.IM_Status__c = FilteredAccountLookupController.IM_ACCOUNT_STATUS;
            noMatch.NA_PY_YTD_Consulting__c = 10.0;
            noMatch.NA_CY_YTD_Consulting__c = 10.0;
        }
        
        insert noTextMatchCustAccounts;
        
        PageReference filteredPage = Page.FilteredAccountLookup;
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.OPPORTUNITY_ID_KEY, opp.Id);

        Test.setCurrentPageReference(filteredPage);
        List<IM_Customer_Account__c> accountsFound = new List<IM_Customer_Account__c>();            
        
        Test.startTest();
            FilteredAccountLookupcontroller testController = new FilteredAccountLookupcontroller();
            testController.condition = SEARCH_TERM;
            testController.generateAccountsQuery();
            accountsFound = testController.accounts;
        Test.stopTest();
        
        System.assertEquals( testIMCustomerAccounts.size(),  accountsFound.size(), 'We should find the correct number of customer accounts');           
        System.assert( new Map<Id, IM_Customer_Account__c>(testIMCustomerAccounts).keySet().containsAll( new map<Id, IM_Customer_Account__c>(accountsFound).keySet()), 'We should find the correct customer accounts');         
        
    }

    static testMethod void testFilteredLookupWithWildCardSearch(){
        
        setup();
        
        final String SEARCH_TERM = 'Test*ust';
        final String ADDITIONAL_NAME = 'TestBust';
        final Integer ADDITIONAL_NUM_IM_CUST_ACCOUNTS = 6;
                
        //Create some additional IM Cust Accounts which do not meet the search criteria
        List<IM_Customer_Account__c> noTextMatchCustAccounts = TestingUtils.createIMCustomerAccounts(ADDITIONAL_NUM_IM_CUST_ACCOUNTS, testAccounts[0].Id, false);
        
        for( IM_Customer_Account__c noMatch : noTextMatchCustAccounts)
        {
            noMatch.Name = ADDITIONAL_NAME;
            noMatch.IM_Status__c = FilteredAccountLookupController.IM_ACCOUNT_STATUS;
            noMatch.NA_PY_YTD_Consulting__c = 10.0;
            noMatch.NA_CY_YTD_Consulting__c = 10.0;
        }
        
        insert noTextMatchCustAccounts;
        
        testIMCustomerAccounts.addAll( noTextMatchCustAccounts );
        
        PageReference filteredPage = Page.FilteredAccountLookup;
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.OPPORTUNITY_ID_KEY, opp.Id);
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.QUERY_KEY, SEARCH_TERM);

        Test.setCurrentPageReference(filteredPage);
        List<IM_Customer_Account__c> accountsFound = new List<IM_Customer_Account__c>();            
        
        Test.startTest();
            FilteredAccountLookupcontroller testController = new FilteredAccountLookupcontroller();
            accountsFound = testController.accounts;
        Test.stopTest();
        
        System.assertEquals( testIMCustomerAccounts.size(),  accountsFound.size(), 'We should find the correct number of customer accounts');           
        System.assert( new Map<Id, IM_Customer_Account__c>(testIMCustomerAccounts).keySet().containsAll( new map<Id, IM_Customer_Account__c>(accountsFound).keySet()), 'We should find the correct customer accounts');         
        
    }
    
    static testMethod void testFilteredLookupOrderedByNA_CY_YTD(){
        
        setup();
        
        //Create some additional IM Cust Accounts with a large NA_CY_YTD value
        List<IM_Customer_Account__c> largeMatchCustAccounts = TestingUtils.createIMCustomerAccounts(1, testAccounts[0].Id, false);
        
        for( IM_Customer_Account__c largeMatch : largeMatchCustAccounts)
        {
            largeMatch.Name = CUST_NAME_FULL + counter;
            largeMatch.IM_Status__c = FilteredAccountLookupController.IM_ACCOUNT_STATUS;
            largeMatch.NA_PY_YTD_Consulting__c = 10.0;
            largeMatch.NA_CY_YTD_Consulting__c = 150.0;
            counter++;
        }
        
        insert largeMatchCustAccounts;
        
        testIMCustomerAccounts.addAll( largeMatchCustAccounts );
        
        PageReference filteredPage = Page.FilteredAccountLookup;
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.OPPORTUNITY_ID_KEY, opp.Id);

        Test.setCurrentPageReference(filteredPage);
        List<IM_Customer_Account__c> accountsFound = new List<IM_Customer_Account__c>();            
        
        Test.startTest();
            FilteredAccountLookupcontroller testController = new FilteredAccountLookupcontroller();
            accountsFound = testController.accounts;
        Test.stopTest();
        
        System.assertEquals( testIMCustomerAccounts.size(),  accountsFound.size(), 'We should find the correct number of customer accounts');           
        System.assert( new Map<Id, IM_Customer_Account__c>(testIMCustomerAccounts).keySet().containsAll( new map<Id, IM_Customer_Account__c>(accountsFound).keySet()), 'We should find the correct customer accounts');
        System.assertEquals( largeMatchCustAccounts[0].Id, accountsFound[0].id, 'The first match should be the record with the largest NA_CY_YTD' );                    
    }
    
    static testMethod void testFilteredAccountListPagination(){
        
        setup();
        
        final Integer NUM_EXPECTED_ACCOUNTS_PER_PAGE = 1;
        final Integer NUM_EXPECTED_PAGES = 16;
        final Integer EXPECTED_PAGE_NUMBER_START = 1;
        
        FilteredAccountLookupcontroller.MAX_PAGE_SIZE = 1;
        
        PageReference filteredPage = Page.FilteredAccountLookup;
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.OPPORTUNITY_ID_KEY, opp.Id);
        
        Test.setCurrentPageReference(filteredPage);
        List<IM_Customer_Account__c> accountsFound = new List<IM_Customer_Account__c>();
        
        Test.startTest();
            FilteredAccountLookupcontroller testController = new FilteredAccountLookupcontroller();
            accountsFound = testController.accounts;
        Test.stopTest();
        
        System.assertEquals(NUM_EXPECTED_ACCOUNTS_PER_PAGE, accountsFound.size(), 'We expect there to be the correct number of results per page from the results');
        System.assertEquals(NUM_EXPECTED_PAGES, testController.totalPageNumber, 'We expect there to be the correct number of pages from the results');
        System.assertEquals(EXPECTED_PAGE_NUMBER_START, testController.pageNumber, 'We expect to be on the correct page from the results');
        
    }
    
    static testMethod void testFilteredAccountListPaginationNavigation(){
        
        setup();
        
        final Integer NUM_EXPECTED_ACCOUNTS_PER_PAGE = 1;
        final Integer NUM_EXPECTED_PAGES = 16;
        final Integer EXPECTED_PAGE_NUMBER = 3;
        
        FilteredAccountLookupcontroller.MAX_PAGE_SIZE = NUM_EXPECTED_ACCOUNTS_PER_PAGE;
        
        PageReference filteredPage = Page.FilteredAccountLookup;
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.OPPORTUNITY_ID_KEY, opp.Id);
        
        Test.setCurrentPageReference(filteredPage);
        List<IM_Customer_Account__c> accountsFound = new List<IM_Customer_Account__c>();
        
        Test.startTest();
            FilteredAccountLookupcontroller testController = new FilteredAccountLookupcontroller();
            testController.next();
            testController.previous();
            testController.next();
            testController.next();
            accountsFound = testController.accounts;
        Test.stopTest();
        
        System.assertEquals(NUM_EXPECTED_ACCOUNTS_PER_PAGE, accountsFound.size(), 'We expect there to be the correct number of results per page from the results');
        System.assertEquals(NUM_EXPECTED_PAGES, testController.totalPageNumber, 'We expect there to be the correct number of pages from the results');
        System.assertEquals(EXPECTED_PAGE_NUMBER, testController.pageNumber, 'We expect to be on the correct page from the results');
        
    }
    
    static testMethod void testFilteredAccountListPaginationNavigationGoto(){
        
        setup();
        
        final Integer NUM_EXPECTED_ACCOUNTS_PER_PAGE = 1;
        final Integer NUM_EXPECTED_PAGES = 16;
        final Integer EXPECTED_PAGE_NUMBER = 4;
        
        FilteredAccountLookupcontroller.MAX_PAGE_SIZE = 1;
        
        PageReference filteredPage = Page.FilteredAccountLookup;
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.OPPORTUNITY_ID_KEY, opp.Id);
        
        Test.setCurrentPageReference(filteredPage);
        List<IM_Customer_Account__c> accountsFound = new List<IM_Customer_Account__c>();
        
        Test.startTest();
            FilteredAccountLookupcontroller testController = new FilteredAccountLookupcontroller();
            testController.pageNumber = 4;
            testController.gotoPage();
            accountsFound = testController.accounts;
        Test.stopTest();
        
        System.assertEquals(NUM_EXPECTED_ACCOUNTS_PER_PAGE, accountsFound.size(), 'We expect there to be the correct number of results per page from the results');
        System.assertEquals(NUM_EXPECTED_PAGES, testController.totalPageNumber, 'We expect there to be the correct number of pages from the results');
        System.assertEquals(EXPECTED_PAGE_NUMBER, testController.pageNumber, 'We expect to be on the correct page from the results');
    }
    
    static testMethod void testGenerateBlanketSoqlQuery (){
        
        setup();
        integer NUM_EXPECTED_BLANKET_ACCOUNTS = 6;
        String IM_ACCOUNT_STATUS = '';
        List<String> blanketCustAccountNames = new List<String>();
        
        List<BlanketCustomerIDs__c > blanketCustomerIDS = new List<BlanketCustomerIDs__c>();
        Set<String> blanketNames = new Set<String>();
        Set<String> nonBlanketNames = new Set<String>();
        
        for(integer i = 0; i < NUM_EXPECTED_BLANKET_ACCOUNTS; i++) {
            blanketCustomerIDS.add(new BlanketCustomerIDs__c(name = testIMCustomerAccounts[i].name));
            blanketNames.add(testIMCustomerAccounts[i].name);
        }
        
        
        insert blanketCustomerIDs;
        
        for(integer i = NUM_EXPECTED_BLANKET_ACCOUNTS; i < 16 ; i++) {
            nonBlanketNames.add(testIMCustomerAccounts[i].name);
        }
        
        List<IM_Customer_Account__c> blanketCustomerAccounts = new List<IM_Customer_Account__c>();
        List<IM_Customer_Account__c> nonblanketCustomerAccounts = new List<IM_Customer_Account__c>();
        //added
        
        final Integer NUM_EXPECTED_ACCOUNTS_PER_PAGE = 1;
        final Integer NUM_EXPECTED_PAGES = 16;
        final Integer EXPECTED_PAGE_NUMBER = 3;
        
        FilteredAccountLookupcontroller.MAX_PAGE_SIZE = NUM_EXPECTED_ACCOUNTS_PER_PAGE;
        
        PageReference filteredPage = Page.FilteredAccountLookup;
        filteredPage.getParameters().put(FilteredAccountLookupcontroller.OPPORTUNITY_ID_KEY, opp.Id);
        Test.setCurrentPageReference(filteredPage);
        
        Test.startTest();
           FilteredAccountLookupcontroller testController = new FilteredAccountLookupcontroller();
           string ab = testController.IMGA_Index;
            testController.generateAccountsQuery();
            IM_ACCOUNT_STATUS = FilteredAccountLookupController.IM_ACCOUNT_STATUS;
            blanketCustAccountNames = testController.blanketCustAccountNames;
            blanketCustomerAccounts = Database.query(testController.blanketSoqlQuery);
            //nonblanketCustomerAccounts = Database.query(testController.soqlQuery);
        Test.stopTest();
        
        System.AssertEquals(NUM_EXPECTED_BLANKET_ACCOUNTS, blanketCustomerAccounts.size(), 'An incorrect number of blanket customer accounts are being return');
        //System.AssertEquals(10, nonBlanketCustomerAccounts.size(), 'An incorrect number of nonblanket customer accounts are being return');
        for(IM_Customer_Account__c account : blanketCustomerAccounts ){
            System.Assert(blanketNames.contains(account.name), 'An incorrect customer account is being returned from the blanker account soql query');  
        }
        //for(IM_Customer_Account__c account : nonblanketCustomerAccounts ){
            //System.Assert(nonblanketNames.contains(account.name), 'An incorrect customer account is being returned from the soql query');
        //}
        
        
        
        
        
    }
}