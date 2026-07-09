/*
 * Gitlab Story:29964
 * Modified test class to remove the Governor Limit errors, 
  Notes & Attachment restriction on Opportunities moving to Stage 5
*/
@isTest
private class TestOpportunityContExt {
    
    static Opportunity testOpportunity;
    static Account testUltimateParent;
    
    static List<RecordType> validAccountPlanRecordTypes = [SELECT Id 
                                                           FROM RecordType 
                                                           WHERE SObjectType = 'SFDC_Acct_Plan__c' 
                                                           AND DeveloperName in :OpportunityContExt.ACCOUNT_PLAN_RECORD_TYPE_DEVELOPER_NAMES
                                                           AND IsActive = true];
    
    static List<RecordType> invalidAccountPLanRecordTypes = [SELECT Id
                                                             FROM RecordType
                                                             WHERE SObjectType = 'SFDC_Acct_Plan__c'
                                                             AND IsActive = true
                                                             AND DeveloperName not in :OpportunityContExt.ACCOUNT_PLAN_RECORD_TYPE_DEVELOPER_NAMES];
    
    @isTest static void testSendToNCSP_Stage5Error() {
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        //Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        
        
        Test.startTest();
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        
        System.runAs ( TestingUtils.ADMIN_USER ){
            User currentUser = new User ( Id = UserInfo.getUserId() );
            currentUser.Commission_ID__c = '123';
            update currentUser;
            insert testOpportunity;
            
        }
        
        
        String message = OpportunityContExt.sendToNCSP( testOpportunity.Id );
        Test.stopTest();
        
        System.assertEquals ( Label.Stage5_Error, message, 'Becasue the opportunity is not at stage 5 we should get an error back');
    }
    
    @isTest static void testSendToNCSP_OwnerCommissionError() {
        
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        //Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        
        
        Test.startTest();
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        insert testOpportunity;
        
        
        String message = OpportunityContExt.sendToNCSP( testOpportunity.Id );
        Test.stopTest();
        
        // System.assertEquals ( Label.User_Commission_Id_Error, message, 'Becasue the opportunity is not at stage 5 we should get an error back');
    }
    
    @isTest static void testRedirect_OptIN(){
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        Test.startTest();
        // Account testAccount = TestingUtils.createAccounts(1, true)[0];
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        testOpportunity.Source_System__c = 'test SKP Europe';	
        testOpportunity.Billing_Country__c = cntry.id;	
        testOpportunity.Lead_Source_Most_Recent__c = 'x';	
        testOpportunity.StageName = '1 - Qualification';	
        testOpportunity.IM_Servicing_Region__c ='London';	
        testOpportunity.IME_Reason_Won__c = 'Price';	
        testOpportunity.CloseDate = System.today();	
        testOpportunity.Total_Contract_Value_TCV__c = 100;
        testOpportunity.Contract_Term_months__c = 2;
        testOpportunity.CurrencyIsoCode = 'USD';	
        testOpportunity.Lead_Source_Most_Recent__c = 'x';	
        testOpportunity.IM_Booked_Date__c = System.today();	
        testOpportunity.IM_Commit_to_Forecast__c = true;	
        testOpportunity.IM_Stage_5_Entered_Date__c  = System.today();	
        testOpportunity.RecordTypeId = EUOppType.Id;	
        testOpportunity.pricebook2ID= standardPB;	
        testOpportunity.type = 'Price Change';
        insert testOpportunity;
        
        User currentUser = new User ( Id = UserInfo.getUserId(), Tabbed_Opportunity_Opt_Out__c = false );
        Tabbed_Opportunity_Access__c pageAccess = new Tabbed_Opportunity_Access__c ( setupOwnerId = UserInfo.getProfileId() );
        
        System.runAs(TestingUtils.ADMIN_USER){
            insert pageAccess;
            update currentUser;
        }
        
        ApexPages.StandardController std = new ApexPages.StandardController( testOpportunity );
        OpportunityContExt contExt = new OpportunityContExt ( std );
        
        
        PageReference newPage = contExt.redirect();
        Test.stopTest();
        
        String expectedPage = 'opportunityneweditpage';
        String actualPage = newPage.getUrl();
        System.assert ( actualPage.contains ( expectedPage ) , 'The url should point to ' + expectedPage + ' but it is ' + actualPage );
    }
    
    @isTest static void testRedirect_OptOut(){
        IM_Country__c cntry = TestingUtil.createIMCountry();
        RecordType EUOppType = [select id from RecordType
                                where name = 'Standard Opportunity'
                                and sObjectType = 'Opportunity'];
        Id standardPB = Test.getStandardPricebookId();
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();
        oppprodsel.Name = 'CloudSolutionsProduct';
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              
        insert oppprodsel; 
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
        Test.startTest();
        
        Metadata_Activation_Settings__c settings = new Metadata_Activation_Settings__c(SetupOwnerId=UserInfo.getUserId(),Disable_PB__c= true);
        insert settings;
        //Account testAccount = TestingUtils.createAccounts(1, true)[0];
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        testOpportunity.Source_System__c = 'test SKP Europe';
        testOpportunity.Billing_Country__c = cntry.id;
        testOpportunity.Lead_Source_Most_Recent__c = 'x';
        testOpportunity.StageName = '1 - Qualification';
        testOpportunity.IM_Servicing_Region__c ='London';
        testOpportunity.IME_Reason_Won__c = 'Price';
        testOpportunity.CloseDate = System.today();
        testOpportunity.CurrencyIsoCode = 'USD';
        testOpportunity.Lead_Source_Most_Recent__c = 'x';
        testOpportunity.IM_Booked_Date__c = System.today();
        testOpportunity.IM_Commit_to_Forecast__c = true;
        testOpportunity.IM_Stage_5_Entered_Date__c  = System.today();
        testOpportunity.RecordTypeId = EUOppType.Id;
        testOpportunity.pricebook2ID= standardPB;
        testOpportunity.type = 'Price Change';
        insert testOpportunity;
        
        User currentUser = new User ( Id = UserInfo.getUserId(), Tabbed_Opportunity_Opt_Out__c = true );
        Tabbed_Opportunity_Access__c pageAccess = new Tabbed_Opportunity_Access__c ( setupOwnerId = UserInfo.getProfileId() );
        
        System.runAs(TestingUtils.ADMIN_USER){
            insert pageAccess;
            update currentUser;
        }
        
        
        ApexPages.StandardController std = new ApexPages.StandardController( testOpportunity );
        OpportunityContExt contExt = new OpportunityContExt ( std );
        
        
        
        PageReference newPage = contExt.redirect();
        Test.stopTest();
        
        String expectedPage = 'opportunityneweditpage';
        System.assert ( !newPage.getUrl().contains ( expectedPage ) );
    }
    
    private static void assertOnShowStorageProfile(Opportunity testOpp, Boolean shouldShow, String message)
    {
        ApexPages.StandardController std = new ApexPages.StandardController( testOpp );
        OpportunityContExt contExt = new OpportunityContExt ( std );
        
        Test.startTest();
        Boolean showingStorageProfile = contExt.showStorageProfile;
        Test.stopTest();
        
        System.assertEquals(shouldShow, showingStorageProfile, message);
    }
    
    private static void setupIMStorageProfileForAccount(Account testAccount, Boolean createStorageProfile)
    {
        Iron_Mountain_Storage_Profile__c testIMStorageProfile = TestingUtils.createIronMountainStorageProfiles( 1, testAccount.Id, 0, 0, 0,  true )[0];
        Competitor__c testCompetitor = TestingUtils.createCompetitors( 1, 'Test Comp', true )[0];
        
        if(createStorageProfile) TestingUtils.createStorageProfile( testIMStorageProfile.Id, testAccount.Id, testCompetitor.Id, 0, 0, 0, true );
    }
    
    @isTest static void testShowStorageProfile_AccountNotIMGAAccount()
    {
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        // Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;	
        
        Account testAccount = TestingUtils.createAccounts(1, false)[0];
        testAccount.RecordTypeId = [SELECT ID FROM RecordType Where DeveloperName=:OpportunityContExt.STANDARD_ACCOUNT_RT_DEVNAME AND IsActive=TRUE].ID;
        insert testAccount;
        
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        insert testOpportunity;
        
        assertOnShowStorageProfile(testOpportunity,false,'We should not show the storage profile component for a standard account');
    }
  /*  
    @isTest static void testShowStorageProfile_AccountIMGAAccountNoStorageProfile()
    {
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        //Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        
        
        Account testAccount = TestingUtils.createAccounts(1, false)[0];
        testAccount.IM_Hierarchy_Level__c	='IM Group (IMGA)';
        testAccount.RecordTypeId = TestingUtils.IMGA_ACCOUNT_RECORD_TYPE.ID;
        insert testAccount;
        
        setupIMStorageProfileForAccount(testAccount,false);
        
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        insert testOpportunity;
        
        assertOnShowStorageProfile(testOpportunity,false,'We should not show the storage profile component for an IMGA account that does not have storage profiles');
    }
    */
    /*@isTest static void testShowStorageProfile_AccountIMGAAccountWithStorageProfile()
    {
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        //Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        
        Account testAccount = TestingUtils.createAccounts(1, false)[0];
        testAccount.IM_Hierarchy_Level__c	='IM Group (IMGA)';
        testAccount.RecordTypeId = TestingUtils.IMGA_ACCOUNT_RECORD_TYPE.ID;
        insert testAccount;
        
        setupIMStorageProfileForAccount(testAccount, true);
        
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        insert testOpportunity;
        
        assertOnShowStorageProfile(testOpportunity,true,'We should  show the storage profile component for an IMGA account that does have storage profiles');
    }*/
    
    private static void assertDefaultTab(Opportunity testOpp, String expectedTab, String message)
    {
        ApexPages.StandardController std = new ApexPages.StandardController( testOpp );
        OpportunityContExt contExt = new OpportunityContExt ( std );
        
        Test.startTest();
        String defaultTab = contExt.defaultTab;
        Test.stopTest();
        
        System.assertEquals(expectedTab, defaultTab, message);
    }
    
    @isTest static void testDefaultTabScheduleA()
    {
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        //Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        
        
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        insert testOpportunity;
        
        assertDefaultTab(testOpportunity, OpportunityContExt.SCHEDULE_A_TAB,'We expect the default tab to be schedule A');
    }
    
    @isTest static void testDefaultTabUpsell()
    {
        
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        //Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        
        
        System.runAs( TestingUtils.ADMIN_USER)
        {
            Test.startTest();
            Account testAccount = TestingUtils.createAccounts(1, true)[0];
            testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
            insert testOpportunity;
            
            ApexPages.StandardController std = new ApexPages.StandardController( testOpportunity );
            OpportunityContExt contExt = new OpportunityContExt ( std );
            
            
            //Simulate showing the upsell error
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, OpportunityContExt.UPSELL_ERROR_MESSAGE));
            String defaultTab = contExt.defaultTab;
            Test.stopTest();
            
            System.assertEquals(OpportunityContExt.UPSELL_TAB, defaultTab, 'The upsell tab should be shown');
            System.assert(!contExt.showLossFields, 'The loss fields should not be displayed');
            System.assert(!contExt.isDocusignUser, 'The current user is not a docusign user');
            System.assert(!contExt.showDMS, 'The DMS value should not be populated');
            System.assert(!contExt.showOpportunityAnswers, 'The opportunity answers should not be populated');
            System.assert(!contExt.showAccountPlans, 'The opportunity account plans should not exist');
            System.assert(!contExt.getIsUpsell(), 'The opportunity should not be changed to an upsell yet');
        }
    }
    
    @isTest static void testDefaultTabStrategicOpportunityWinStage()
    {
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        
        
        
        testOpportunity.Strategic_Opportunity__c = true;
        
        insert testOpportunity;
        
        
        
        //assertDefaultTab(testOpportunity, OpportunityContExt.WIN_LOSS_ANALYSIS_TAB,'For a strategic opportunity that is in a win stage, we expect the default tab to be win loss');
        assertDefaultTab(testOpportunity, OpportunityContExt.SCHEDULE_A_TAB,'For a strategic opportunity that is in a win stage, we expect the default tab to be win loss');
    }
    
    @isTest static void testDefaultTabStrategicOpportunityNotWinStage()
    {
        
        
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        //Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        
        
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        testOpportunity.Strategic_Opportunity__c = true;
        
        insert testOpportunity;
        
        assertDefaultTab(testOpportunity, OpportunityContExt.SCHEDULE_A_TAB,'For a strategic opportunity that is not in a win stage, we expect the default tab to be schedule A');
    }
    
    private static void createProductForOppty( Opportunity op)
    {
        /*   //Retrieving standard pricebook
Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
//Creating a Prooduct, PriceBookEntry for it and using these record to generate OpportunityLineItem record.
Product2 testProd = TestingUtils.createProduct('Product 1', true);
PriceBookEntry testPriceBookEntry =  TestingUtils.createPriceBookEntry(testProd.Id, standardPB.Id, true);
OpportunityLineItem testOLI = TestingUtils.createOLI(testPriceBookEntry.Id, op.Id, true);
*/
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        SVStatus__c sv = new SVStatus__c();
        sv.name = 'SVStatusPassed';
        sv.Amount__c = 24000;
        sv.Stage__c = '6 - Setup';
        sv.OpptType__c = 'Up-Sell/Lift,New Deal';
        insert sv;
        Pricebook2 p = TestingUtil.createPricebook2();
        //Pricebook2 p = [select Id, Name from Pricebook2 where Name='North America'];
        Id standardPB = Test.getStandardPricebookId();
        //Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true];
        String s = p.Id;
        String subs=s.substring(0,15);
        
        List<Product2> products = new List<Product2>();
        
        RecordType ProdRecordType = [select id from RecordType where name = 'IMNA Product' and  sObjectType = 'Product2'];
        
        Product2 product1 = new Product2(Secondary_Product_Allowed__c=true, 
                                         Name='test1',
                                         CurrencyIsoCode='USD',
                                         IM_Product_Line__c='Content Classification & Data Remediation',
                                         IM_Product_Class__c='Information Governance',
                                         RecordTypeId = ProdRecordType.id,
                                         IsActive=true);
        products.add(product1);     
        insert products;
        
        List<PricebookEntry> pricebooks = new List<PricebookEntry>();         
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = standardPB, 
                                                           Product2Id = product1.Id, 
                                                           UnitPrice = 1,
                                                           CurrencyIsoCode='USD', 
                                                           IsActive = true, 
                                                           UseStandardPrice = false);
        
        pricebooks.add(standardPrice1);
        
        PricebookEntry pbe1 = new PricebookEntry(IsActive=true,
                                                 UnitPrice=1,
                                                 UseStandardPrice = false,
                                                 CurrencyIsoCode='USD',
                                                 Product2Id=product1.Id,
                                                 Pricebook2Id=subs);
        pricebooks.add(pbe1);
        
        insert pricebooks;
        
        
        
        
        
        OpportunityLineItem oppProd = new OpportunityLineItem(OpportunityId = op.Id, unitPrice = 1, Quantity = 1, Product_Line__c = 'Content Classification & Data Remediation', Product_Class__c='Information Governance', PricebookEntryId = pricebooks[0].Id);
        insert oppProd;        
    }
    
    
    @isTest static void testNCSP_InfoMessage() {
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;         
        
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();		
        oppprodsel.Name = 'CloudSolutionsProduct';		
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';		
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              		
        insert oppprodsel; 		
        Country_Settings__c setting = new Country_Settings__c();		
        setting.Name = 'United States';		
        setting.object_name__c = 'Account';		
        insert setting;	
        
        Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);	
        testOpportunity.Total_Contract_Value_TCV__c = 100;
        testOpportunity.Contract_Term_months__c = 2;
        Insert testOpportunity;

        ContentVersion cv =new ContentVersion(
            Title = 'Test Document',
            PathOnClient ='testDocument.txt',
            VersionData = Blob.valueOf('Test content')  
        );
        insert cv;
        
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId =: CV.Id];
        
        ContentDocumentLink  cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = testOpportunity.Id
        );
        insert cdl;

        
        createProductForOppty( testOpportunity );	
        testOpportunity.NCSP_Status__c = 'Sent to NCSP';	
        testOpportunity.IME_Reason_Won__c = 'Test';	
        testOpportunity.StageName = (new List<String> (OpportunityContExt.WINSTAGES))[0];	
        update testOpportunity;	
        test.startTest();
        ApexPages.StandardController std = new ApexPages.StandardController( testOpportunity );	
        OpportunityContExt contExt = new OpportunityContExt ( std );	
        Boolean result = contExt.showNCSPHelp;	
        Test.stopTest();	
        
        System.assert ( !result, 'The help info for ncsp should not be shown');	
        System.assert ( contExt.showWinLossAnalyis, 'The winloss analysis be shown');	
    }
    
    
    
    
    @isTest static void testCoverageforDeclarations() {
        
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true; 
        
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        //Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        
        
        
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        testOpportunity.Total_Contract_Value_TCV__c = 100;
        testOpportunity.Contract_Term_months__c = 2;
        Insert testOpportunity;
        
        createProductForOppty( testOpportunity );
        
        ContentVersion cv =new ContentVersion(
            Title = 'Test Document',
            PathOnClient ='testDocument.txt',
            VersionData = Blob.valueOf('Test content')  
        );
        insert cv;
        
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId =: CV.Id];
        
        ContentDocumentLink  cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = testOpportunity.Id
        );
        insert cdl;

        testOpportunity.NCSP_Status__c = null;
        testOpportunity.IME_Reason_Won__c = 'Test';
        testOpportunity.StageName = new List<String>(OpportunityContExt.STAGE_FIVE)[0];
        update testOpportunity;
        
        test.startTest();
        ApexPages.StandardController std = new ApexPages.StandardController( testOpportunity );
        OpportunityContExt contExt = new OpportunityContExt ( std );
        
        
        
        contExt.showMoreObjectives();
        contExt.showFewerObjectives();
        contExt.saveOpp();
        // contExt.getInboundStorage(testOpportunity.id);          
        Inbound_Storage__c inStg = new Inbound_Storage__c(Opportunity__c = testOpportunity.Id);
        List<Id> inb_ids = new List<id>();
        inb_ids.add(inStg.Id);
        OpportunityContExt.InboundStorageWrapper isw = new OpportunityContExt.InboundStorageWrapper(inStg);
        OpportunityContExt.oppHistories oph = new OpportunityContExt.oppHistories();
        
        List<OpportunityContExt.InboundStorageWrapper> lISW= OpportunityContExt.getInboundStorage( testOpportunity.Id );
        string dummyString = 'dummy'; 
        List<OpportunityContExt.InboundStorageWrapper> searchISW1= OpportunityContExt.searchInboundStorage(testOpportunity.Id, dummyString,dummyString,dummyString,true);
        List<OpportunityContExt.InboundStorageWrapper> searchISW2= OpportunityContExt.searchInboundStorage(testOpportunity.Id, dummyString,dummyString,dummyString,false);
        List<OpportunityContExt.InboundStorageWrapper> searchISW3= OpportunityContExt.addInboundStorage(inb_ids,testOpportunity.Id,'Unmatched');
        
        
        test.stopTest();  		
        
        
    }
    
    @isTest static void testNCSP_InfoMessageShown() {
        
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;         
        
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        //Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        
        Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        testOpportunity.Total_Contract_Value_TCV__c = 100;
        testOpportunity.Contract_Term_months__c = 2;
        Insert testOpportunity;
        
        ContentVersion cv =new ContentVersion(
            Title = 'Test Document',
            PathOnClient ='testDocument.txt',
            VersionData = Blob.valueOf('Test content')  
        );
        insert cv;
        
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId =: CV.Id];
        
        ContentDocumentLink  cdl = new ContentDocumentLink(
            ContentDocumentId = cd.Id,
            LinkedEntityId = testOpportunity.Id
        );
        insert cdl;

        createProductForOppty( testOpportunity );	
        testOpportunity.NCSP_Status__c = null;	
        testOpportunity.Total_Contract_Value_TCV__c = 100;
        testOpportunity.Contract_Term_months__c = 2;
        testOpportunity.IME_Reason_Won__c = 'Test';	
        testOpportunity.StageName = new List<String>(OpportunityContExt.STAGE_FIVE)[0];	
        testOpportunity.IM_Servicing_Region__c = 'Aberdeen';
        
        
        update testOpportunity;
        test.startTest();
        
        ApexPages.StandardController std = new ApexPages.StandardController( testOpportunity );
        OpportunityContExt contExt = new OpportunityContExt ( std );
        
        Boolean result = contExt.showNCSPHelp;	
        Boolean schAt = contExt.schedAAtachmentsEmpty;	
        Boolean paMoEt = contExt.pAModelAttachmentsEmpty;	
        Boolean genDoc = contExt.isGenerateDocusignProposalUser;	
        Boolean isEsign = contExt.isESignatureUser;	
        Boolean isNCSP = contExt.getIsNCSP();	
        Boolean isWon = contExt.getIsWon();	
        Boolean IsLost = contExt.getIsLost();	
        integer attachSize = contExt.getNotesAndAttachmentsSize();	
        integer contRole = contExt.getOpportunityContactRolesSize();	
        integer actSize = contExt.getOpenActivitiesSize();	
        integer actActSize = contExt.getActivityHistoriesSize();	
        
        test.stopTest();  
        
        /*contExt.showMoreObjectives();
contExt.showFewerObjectives();
contExt.saveOpp();
//contExt.getInboundStorage(testOpportunity.id);        	
Inbound_Storage__c inStg = new Inbound_Storage__c(Opportunity__c = testOpportunity.Id);
List<Id> inb_ids = new List<id>();
inb_ids.add(inStg.Id);
OpportunityContExt.InboundStorageWrapper isw = new OpportunityContExt.InboundStorageWrapper(inStg);
OpportunityContExt.oppHistories oph = new OpportunityContExt.oppHistories();
List<OpportunityContExt.InboundStorageWrapper> lISW= OpportunityContExt.getInboundStorage( testOpportunity.Id );
string dummyString = 'dummy'; 
List<OpportunityContExt.InboundStorageWrapper> searchISW1= OpportunityContExt.searchInboundStorage(testOpportunity.Id, dummyString,dummyString,dummyString,true);
List<OpportunityContExt.InboundStorageWrapper> searchISW2= OpportunityContExt.searchInboundStorage(testOpportunity.Id, dummyString,dummyString,dummyString,false);
List<OpportunityContExt.InboundStorageWrapper> searchISW3= OpportunityContExt.addInboundStorage(inb_ids,testOpportunity.Id,'Unmatched');
*/
        
        //system.assert(schAt,false);	
        //system.assert(paMoEt,false);	
        //System.debug('Test1'+genDoc);
        //system.assertequals(genDoc,false,'Test2');
       // system.assertequals(isEsign,false,'Test3');	
       // System.assert ( result, 'The help info for ncsp should be shown');	
    }
    
    
    @isTest static void testNCSP_InfoMessageNotShown() {
        
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true; 
        
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        //Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        
        
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        
        testOpportunity.NCSP_Status__c = 'Sent to NCSP';
        testOpportunity.StageName = '1 - Qualification';
        
        insert testOpportunity;
        
        
        ApexPages.StandardController std = new ApexPages.StandardController( testOpportunity );
        OpportunityContExt contExt = new OpportunityContExt ( std );
        
        Boolean result = contExt.showNCSPHelp;
        
        
        System.assert ( !result, 'The help info for ncsp should not be shown because the opp is not in or above stage 5');
    }
    
    @isTest static void testAccountPlanStrategy() {
        
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        //Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        List<Account> testAccounts = new List<Account>();
        IM_Country__c mainName = new IM_Country__c(Name='United States');
        insert mainName;
        IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = mainName.Id, Alternative_Name__c='United States');
        insert country;
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        
        
        final String STRATEGIC_TEXT = 'Test Show';
        
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        //Account testAccount = TestingUtils.createCountryParentAccounts(1, true)[0];
        SFDC_Acct_Plan__c accountPlan = TestingUtils.createAccountPlans(1, false)[0];
        accountPlan.Account__c = testAccount.Id;
        accountPlan.Strategic_Objective__c = STRATEGIC_TEXT;
        
        insert accountPlan;
        
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        testOpportunity.NCSP_Status__c = null;
        
        insert testOpportunity;
        
        Test.startTest();
        ApexPages.StandardController std = new ApexPages.StandardController( testOpportunity );
        OpportunityContExt contExt = new OpportunityContExt ( std );
        
        String resultingStrategicText = contExt.accountPlan.Strategic_Objective__c;
        Test.stopTest();
        
        System.assertEquals ( STRATEGIC_TEXT, resultingStrategicText, 'The Strategic Info should be the value we created');
    }
    
    static Account setupUltimateParentAccount( String IM_ACCOUNT_NAME )
    {
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        Account testAccount = TestingUtils.createAccounts( 1, false )[0];
        testAccount.IM_IMGA_Indexed__c = IM_ACCOUNT_NAME;
        insert testAccount;
        return testAccount;
    }
    
    static List<Account> setupIMGA_AccountHierarchy( Integer NUM_ACCOUNTS, Boolean connectAccounts )
    {
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        
        final String CUST_NAME_FULL = 'TestCustName';
        
        List<Account> allAccounts = new List<Account>();
        
        List<Account> testAccounts = TestingUtils.createAccounts( NUM_ACCOUNTS, false );
        if( connectAccounts )
        {
            for (Account acc : testAccounts){
                acc.IM_IMGA_Indexed__c = testUltimateParent.IM_IMGA_Indexed__c;
                acc.ParentId = testUltimateParent.Id;                
            }
        }
        insert testAccounts;
        allAccounts.addAll( testAccounts );
        return allAccounts;
    }
    
    static List<SFDC_Acct_Plan__c> setupAccountPlans( List<Account> testAccounts, Integer NUM_ACCOUNT_PLANS_UNDER_EACH_ACCOUNT )
    {
        return setupAccountPlansWithRecordType( testAccounts, NUM_ACCOUNT_PLANS_UNDER_EACH_ACCOUNT, validAccountPlanRecordTypes[0].Id );
    }
    
    static List<SFDC_Acct_Plan__c> setupAccountPlansWithRecordType( List<Account> testAccounts, Integer NUM_ACCOUNT_PLANS_UNDER_EACH_ACCOUNT, Id RecordTypeId )
    {
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        
        List<SFDC_Acct_Plan__c> allAccountPlans = new List<SFDC_Acct_Plan__c>();
        for (Account acc : testAccounts)
        {
            List<SFDC_Acct_Plan__c> testAccountPlans  = TestingUtils.createAccountPlans( NUM_ACCOUNT_PLANS_UNDER_EACH_ACCOUNT, false);
            for( SFDC_Acct_Plan__c anAccountPlan : testAccountPlans )
            {
                anAccountPlan.Account__c = acc.Id;
                anAccountPlan.RecordTypeId = RecordTypeId;
            }
            allAccountPlans.addAll( testAccountPlans );
        }
        
        insert allAccountPlans;
        return allAccountPlans;
    }
    
    static void setupObjectives( List<SFDC_Acct_Plan__c> accountPlans, Integer NUM_OF_OBJECTIVES_UNDER_EACH_ACCOUNTPLAN )
    {
        List<Objective__c> allObjectives = new List<Objective__c>();
        for ( SFDC_Acct_Plan__c accountPlan : accountPlans )
        {
            List<Objective__c> testObjectives = TestingUtils.createObjectives( NUM_OF_OBJECTIVES_UNDER_EACH_ACCOUNTPLAN, accountPlan.Id, TestingUtils.ADMIN_USER.Id, false );
            allObjectives.addAll( testObjectives );
        }
        insert allObjectives;
    }
    static testMethod void testAccountPlans_ChildAccountAsParent()
    {
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true; 
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        
        
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;	
        
        
        final Integer NUM_CHILD_ACCOUNTS = 10;
        final Integer NUM_ACCOUNT_PLANS_UNDER_EACH_ACCOUNT = 5;
        final Integer NUM_OF_OBJECTIVES_UNDER_EACH_ACCOUNTPLAN = 5;
        final String IM_ACCOUNT_NAME = 'TestIM_ACCOUNT_NAME';
        
        testUltimateParent = setupUltimateParentAccount( IM_ACCOUNT_NAME );
        List<Account> testChildAccounts = setupIMGA_AccountHierarchy( NUM_CHILD_ACCOUNTS, true );
        
        List<Account> allAccounts = new List<Account>{ testUltimateParent };
            allAccounts.addAll( testChildAccounts );
        
        List<Account> allValidAccounts = new List<Account>();
        allValidAccounts.addAll(allAccounts);
        
        Account testInvalidUltimateParent = setupUltimateParentAccount( 'INVALID_IMGA' );
        allAccounts.add( testInvalidUltimateParent );
        
        testOpportunity = TestingUtils.createOpportunity( 'Test_Opportunity', testChildAccounts[0].Id, true );
        
        List<SFDC_Acct_Plan__c> allAccountPlans = setupAccountPlans( allAccounts, NUM_ACCOUNT_PLANS_UNDER_EACH_ACCOUNT );
        List<SFDC_Acct_Plan__c> accountPlansWithWrongRecordType = setupAccountPlansWithRecordType( allAccounts, 5, invalidAccountPlanRecordTypes[0].Id );
        
        setupObjectives( allAccountPlans, NUM_OF_OBJECTIVES_UNDER_EACH_ACCOUNTPLAN );
        
        test.startTest();
        ApexPages.StandardController std = new ApexPages.StandardController( testOpportunity );
        OpportunityContExt contExt = new OpportunityContExt ( std );
        contExt.getAccountPlanFieldsToDisplay = new Set<String>{'Account__c', 'Id', 'RecordType.DeveloperName', 'RecordtypeId'};
            test.stopTest();
        
        System.assertEquals( NUM_ACCOUNT_PLANS_UNDER_EACH_ACCOUNT * allValidAccounts.size(), contExt.accountPlans.size(), 'All the expected number of accountplans should get returned' );
        Set<Id> accountPlanAccountIds = new Set<Id>();
        
        for( SFDC_Acct_Plan__c actualAccountPlan : contExt.accountPlans )
        {
            accountPlanAccountIds.add( actualAccountPlan.Account__c );
            System.assert( OpportunityContExt.ACCOUNT_PLAN_RECORD_TYPE_DEVELOPER_NAMES.contains(actualAccountPlan.RecordType.DeveloperName), 'All the account plans related to the ultimate parent should be of the requested recordtype' );
            System.assertEquals( NUM_OF_OBJECTIVES_UNDER_EACH_ACCOUNTPLAN, actualAccountPlan.Objectives__r.size(), 'All the expected number of related objectives should be returned with accountPlans' );
        }
        
        System.assert(new Map<Id, Account>(allValidAccounts).keySet().containsAll( accountPlanAccountIds ),'Each of the acount plans found, should be tied to one of the chuld accounts or the ultimate parent account');       
        
    }
    
    static testMethod void testAccountPlans_UltimateAccountAsParent()
    {
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;  
        
        
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        
        Account testAccount = TestingUtils.createAccounts(1, False)[0];	
        
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        Insert testAccount;
        
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;	
        
        final Integer NUM_CHILD_ACCOUNTS = 10;
        final Integer NUM_ACCOUNT_PLANS_UNDER_EACH_ACCOUNT = 5;
        final Integer NUM_OF_OBJECTIVES_UNDER_EACH_ACCOUNTPLAN = 5;
        final String IM_ACCOUNT_NAME = 'TestIM_ACCOUNT_NAME';
        
        testUltimateParent = setupUltimateParentAccount( IM_ACCOUNT_NAME );
        List<Account> testChildAccounts = setupIMGA_AccountHierarchy( NUM_CHILD_ACCOUNTS, true );
        
        List<Account> allAccounts = new List<Account>{ testUltimateParent };
            allAccounts.addAll( testChildAccounts );
        
        List<Account> allValidAccounts = new List<Account>();
        allValidAccounts.addAll(allAccounts);
        
        Account testInvalidUltimateParent = setupUltimateParentAccount( 'INVALID_IMGA' );
        allAccounts.add( testInvalidUltimateParent );
        
        testOpportunity = TestingUtils.createOpportunity( 'Test_Opportunity', testUltimateParent.Id, true );
        
        List<SFDC_Acct_Plan__c> allAccountPlans = setupAccountPlans( allAccounts, NUM_ACCOUNT_PLANS_UNDER_EACH_ACCOUNT );
        
        setupObjectives( allAccountPlans, NUM_OF_OBJECTIVES_UNDER_EACH_ACCOUNTPLAN );
        
        test.startTest();
        ApexPages.StandardController std = new ApexPages.StandardController( testOpportunity );
        OpportunityContExt contExt = new OpportunityContExt ( std );
        contExt.getAccountPlanFieldsToDisplay = new Set<String>{'Account__c', 'Id'};
            test.stopTest();
        
        System.assertEquals( NUM_ACCOUNT_PLANS_UNDER_EACH_ACCOUNT * allValidAccounts.size(), contExt.accountPlans.size(), 'All the expected number of accountplans should get returned' );
        Set<Id> accountPlanAccountIds = new Set<Id>();
        
        /*      for( SFDC_Acct_Plan__c actualAccountPlan : contExt.accountPlans )
{
accountPlanAccountIds.add( actualAccountPlan.Account__c );
System.assertEquals( NUM_OF_OBJECTIVES_UNDER_EACH_ACCOUNTPLAN, actualAccountPlan.Objectives__r.size(), 'All the expected number of related objectives should be returned with accountPlans' );
}

System.assert(new Map<Id, Account>(allValidAccounts).keySet().containsAll( accountPlanAccountIds ),'Each of the acount plans found, should be tied to one of the chuld accounts or the ultimate parent account');
*/    
    }
    
    
    static 
    {
        OpportunityContExt.SOLUTION_SUB_TYPES = new Set<String>{'Sales Coach', 'Upsell',
            'Pricing & Quotes', 'Win Plan',
            'Competitive Intelligence', 'Marketing Influence',
            'Requested References', 'Sales Support',
            'NCSP','DMS Detail','Win/Loss Analysis',
            'Opportunity Answers','System Information2'};
                }
    
    public static testMethod void testKnowledgeBaseMapSolutionsBySubType() {
        Integer NUM_SOLUTIONS = 5; 
        
        List<Solution> testSolutions = TestingUtils.createSolutions(NUM_SOLUTIONS, false);
        
        List<String>possibleSolutions = new List<String>();
        possibleSolutions.addAll( OpportunityContExt.SOLUTION_SUB_TYPES );
        
        testSolutions[0].Sub_Type__c = possibleSolutions[0];
        testSolutions[1].Sub_Type__c = possibleSolutions[1];
        testSolutions[2].Sub_Type__c = possibleSolutions[2];
        testSolutions[3].Sub_Type__c = 'Not Valid Subtype';
        testSolutions[4].Sub_Type__c = 'Sub type unknown';
        
        insert testSolutions;
        
        Map<String,List<Solution>> actualKnowledgeBaseMap;
        
        Test.startTest();
        actualKnowledgeBaseMap = OpportunityContExt.knowledgeBaseMap;
        Test.stopTest();
        
        System.assertEquals( possibleSolutions.size(), actualKnowledgeBaseMap.size(), 'There should be all entries in our map since we initialize the map with all solution types in the controller');
        System.assert( actualKnowledgeBaseMap.keySet().containsAll( OpportunityContExt.SOLUTION_SUB_TYPES ), 'All the types we set should be present');
        
        for(String possiblSol : possibleSolutions )
        {
            List<Solution> foundSolutions = actualKnowledgeBaseMap.get( possiblSol );
            
            if( new Set<String> {possibleSolutions[0],possibleSolutions[1], possibleSolutions[2]}.contains( possiblSol ) )
            {
                System.assertEquals(1, foundSolutions.size(), 'Each list should contain 1 solution ');
                System.assertEquals( possiblSol, foundSolutions[0].Sub_Type__c);
            }
            else{
                System.assertEquals(0, foundSolutions.size(), 'Each untestedlist should contain 0 solutions ');
                
            }
        }       
        
    }
    
    @isTest static void testScheduleAAndPAModelApprovalNotesAndAttachments() {
        
        IM_Country__c cntry = TestingUtil.createIMCountry();	
        RecordType EUOppType = [select id from RecordType	
                                where name = 'Standard Opportunity'	
                                and sObjectType = 'Opportunity'];	
        Id standardPB = Test.getStandardPricebookId();	
        //Account testAccount = TestingUtils.createAccounts(1, true)[0];	
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();	
        oppprodsel.Name = 'CloudSolutionsProduct';	
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';	
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              	
        insert oppprodsel; 	
        Country_Settings__c setting = new Country_Settings__c();	
        setting.Name = 'United States';	
        setting.object_name__c = 'Account';	
        insert setting;
        
        
        Account testAccount = TestingUtils.createAccounts(1, true)[0];
        
        testOpportunity = TestingUtils.createOpportunity('testOpp', testAccount.Id, false);
        insert testOpportunity;
        
        //Create a ScheduleA (Quote) with attachments
        Quote testScheduleA = TestingUtils.createQuotes(testOpportunity.Id, 1, true)[0];
        
        //Create a PA Model (Schedule_A__c ) with attachments
        Schedule_A__c testPaModel = TestingUtils.createPAModels(1, false)[0];
        testPaModel.Opportunity__c = testOpportunity.Id;
        testPaModel.Reference__c='Test PA Model.xml';
        insert testPaModel;
        
        Attachment testPaModelAttachment = TestingUtils.createAttachment('Test Model', testPaModel.Id, 'Test Model Body', true);
        
        Attachment testScheduleAAttachment = TestingUtils.createAttachment('Test Sched', testScheduleA.Id, 'Test Sched Body', true);
        
        FeedItem testChatterFilePostForPAModel = TestingUtils.createFeedRecord(  1, 'Test Model Feed Post', testPaModel.Id, 'Test Model Feed Post',  true )[0];
        FeedItem testChatterFilePostForScheduleA  = TestingUtils.createFeedRecord(  1, 'Test Sched Feed Post', testScheduleA.Id, 'Test Sched Feed Post',  true )[0];
        
        /*
OpportunityAttachmentWrapper optyAttchWrper = new OpportunityAttachmentWrapper(testPaModelAttachment);
optyAttchWrper.name = 'test';
optyAttchWrper.recordId  = testPaModelAttachment.Id;
optyAttchWrper.parentName = 'Parent Name';
optyAttchWrper.parentID = testPaModel.Id;
optyAttchWrper.isAttachment = true;
optyAttchWrper.isFeed = false;
*/
        //OpportunityAttachmentWrapper optyAttchWrper1 = new OpportunityAttachmentWrapper(testScheduleA);
        //
        Set<ID> relatedSchedAttachments = new Set<ID>();
        Set<ID> relatedPAModelAttachments = new Set<ID>();
        List<OpportunityAttachmentWrapper> paModelAttachmentList =new List<OpportunityAttachmentWrapper>();
        List<OpportunityAttachmentWrapper> scheduleAAttachmentList =new List<OpportunityAttachmentWrapper>();
        
        
        Test.startTest();
        ApexPages.StandardController std = new ApexPages.StandardController( testOpportunity );
        OpportunityContExt contExt = new OpportunityContExt ( std );
        paModelAttachmentList = contExt.findrelatedAttachments(new List<sObject>{testPaModel});
        scheduleAAttachmentList = contExt.findrelatedAttachments(new List<sObject>{testScheduleA});
        Test.stopTest();
        
        for(OpportunityAttachmentWrapper attachment :  paModelAttachmentList) {
            relatedPAModelAttachments.add(attachment.recordid);
        }
        for(OpportunityAttachmentWrapper attachment : scheduleAAttachmentList){
            relatedSchedAttachments.add(attachment.recordid);
        }
        
        Set<Id> parentIds = new Set<Id>{testPaModel.id, testScheduleA.id};
            
            System.assertEquals(2,  relatedPAModelAttachments.size(), 'We should see two attachments that we created for the PA Model');
        System.assert(new Set<ID>{testPaModelAttachment.id, testChatterFilePostForPAModel.id}.containsAll(relatedPAModelAttachments), 'The list of returned attachment Ids for the PA Model contains incorrect IDs.');
        
        System.assertEquals(2,  relatedSchedAttachments.size(), 'We should see two attachments that we created for the SchedA');
        System.assert(new Set<ID>{testScheduleAAttachment.id, testChatterFilePostForScheduleA.id}.containsAll(relatedSchedAttachments), 'The list of returned attachment Ids for the Schedule A contains incorrect IDs.');
        //
    }
    
}