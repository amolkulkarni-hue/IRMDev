@isTest
private class SKPIntegrationWizardContTest {
    public static string customerID = '12345';
    public static string districtID = 'D1234';
    public static string companyID = 'c1234';
    
    public static Account testAccount;
    public static Contact testContact;
    public static Opportunity testOpp;
    public static Case testCase;
    public static User testUser;
    public static Quote testScheduleA;
    public static IM_Customer_Account__c imAccount;
    public static Customer_Profile__c testProfile;    
    public static IM_Customer_Account__c testCustomerAccount;
    public static Case_Customer_Account__c testCaseCustomerAccount;
    public static RecordType NCSPRenewalRecordType;
    public SkpIntegrationHelper.CustomerIndicator customerIndicator;
    
    @testSetup
    public static void setup(){
       OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;  
        IM_Country__c cntry = TestingUtil.createIMCountry();
        testAccount = TestingUtils.createAccounts(1, true)[0];
        
        testContact = TestingUtils.createContact(testAccount.Id, false);
        testContact.FirstName = 'TestContact';
        insert testContact;
        
        RecordType EUOppType = [select id from RecordType
                                where name = 'Standard Opportunity'
                                and sObjectType = 'Opportunity'];
        
        Product2 product =
            new Product2(
                Secondary_Product_Allowed__c=true,
                Name='test',
                CurrencyIsoCode='GBP',
                IsActive=true);
        insert product;
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
        
        testOpp = TestingUtils.createOpportunity('test_Opp', testAccount.Id, false);
        testOpp.Source_System__c = 'test SKP Europe';
        testOpp.Billing_Country__c = cntry.id;
        testOpp.Lead_Source_Most_Recent__c = 'x';
        testOpp.StageName = '1 - Qualification';
        testOpp.IM_Servicing_Region__c ='London';
        testOpp.IME_Reason_Won__c = 'Price';
        testOpp.CloseDate = System.today();
        testOpp.CurrencyIsoCode = 'USD';
        testOpp.Lead_Source_Most_Recent__c = 'x';
        testOpp.IM_Booked_Date__c = System.today();
        testOpp.IM_Commit_to_Forecast__c = true;
        testOpp.IM_Stage_5_Entered_Date__c  = System.today();
        testOpp.RecordTypeId = EUOppType.Id;
        testOpp.pricebook2ID= standardPB;
        testOpp.type = 'Price Change';
        
        
        insert testOpp;
        system.debug('source customer for oppt==');
        // system.debug('opp.Source_Customer_Id__c=='+testOpp.Source_Customer_Id__c);
        testUser = TestingUtil.createUser();
        testCase = TestingUtils.createCase(testOpp, testContact, true);
        //system.debug('testCase.Source_Customer_Id__c=='+testCase.Source_Customer_Id__c);
        testCase.contract_type__c = 'IM2000';
        
        
        
         Quote testScheduleA = TestingUtils.createQuotes(testOpp.id, 1, false)[0];
        testScheduleA.Pricebook2Id = test.getStandardPriceBookId();
        insert testScheduleA;
        
        Product2 productforShred = TestingUtils.createProduct('1500', true);
        
         PriceBookEntry shredPBE = TestingUtils.createPriceBookEntry(productforShred.id, standardPB, true);
        
         QuoteLineItem qliForShred = TestingUtils.createQuoteLineItem(shredPBE.id, testScheduleA.id, true);
        
        /*
         Quote scheduleA = SkpIntegrationHelper.getScheduleAs( (string) testOpp.id, new List<String>(SkpIntegrationWizardCont.scheduleAFields))[0];
			QuoteLineItem qliForShred = testScheduleA */
        testProfile = TestingUtils.createCustomerProfile(testOpp.id, new Map<string, Object>(), true);
        SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                            name='Sandbox', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
        SKP_Integration_Details__c details2 = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                             name='Production', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
        insert new List<SKP_Integration_Details__c>{details, details2};
            }
    
  /*  public static void setup2(){
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;  
        IM_Country__c cntry = TestingUtil.createIMCountry();
        testAccount = TestingUtils.createAccounts(1, true)[0];
        
        testContact = TestingUtils.createContact(testAccount.Id, true);
        
        RecordType EUOppType = [select id from RecordType
                                where name = 'Standard Opportunity'
                                and sObjectType = 'Opportunity'];
        
        Product2 product =
            new Product2(
                Secondary_Product_Allowed__c=true,
                Name='test2',
                CurrencyIsoCode='GBP',
                IsActive=true);
        insert product;
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
        
        testOpp = TestingUtils.createOpportunity('test_Opp', testAccount.Id, false);
        testOpp.Source_System__c = 'test SKP Europe';
        testOpp.Billing_Country__c = cntry.id;
        testOpp.Lead_Source_Most_Recent__c = 'x';
        testOpp.StageName = '1 - Qualification';
        testOpp.IM_Servicing_Region__c ='London';
        testOpp.IME_Reason_Won__c = 'Price';
        testOpp.CloseDate = System.today();
        testOpp.CurrencyIsoCode = 'USD';
        testOpp.Lead_Source_Most_Recent__c = 'x';
        testOpp.IM_Booked_Date__c = System.today();
        testOpp.IM_Commit_to_Forecast__c = true;
        testOpp.IM_Stage_5_Entered_Date__c  = System.today();
        testOpp.RecordTypeId = EUOppType.Id;
        testOpp.pricebook2ID= standardPB;
        testOpp.type = 'Price Change';
        
        
        insert testOpp;
        system.debug('source customer for oppt==');
        // system.debug('opp.Source_Customer_Id__c=='+testOpp.Source_Customer_Id__c);
        testUser = TestingUtil.createUser();
        testCase = TestingUtils.createCase(testOpp, testContact, true);
        //system.debug('testCase.Source_Customer_Id__c=='+testCase.Source_Customer_Id__c);
        testCase.contract_type__c = 'Affiliate Option 1';
        testCase.NCSP_Service_line__c = 'One Time Shred';
        testCase.Sync_succeeded_till__c = 1;
        
        testScheduleA = TestingUtils.createQuotes(testOpp.id, 1, false)[0];
        
        
        testProfile = TestingUtils.createCustomerProfile(testOpp.id, new Map<string, Object>(), true);
        SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                            name='Sandbox', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
        SKP_Integration_Details__c details2 = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                             name='Production', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
        insert new List<SKP_Integration_Details__c>{details, details2};
            }
    */
    static testMethod void SKPIntegrationWizardCont_Test() {
        
      //  setup();
      	testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
      	testScheduleA = [select id,Schedule_A__c from Quote limit 1 ];
        testScheduleA.Status = 'Accepted';
        update testScheduleA;
        testCase.SKP_Customer_Sync_Date__c = Date.today();
        update testCase;
        testOpp = [select id from opportunity limit 1];
        
        ApexPages.currentPage().getParameters().put('Id', testCase.id);
        
        List<Quote> scheduleAs = [Select Name, id, Effective_Date__c from Quote where Opportunityid =: testOpp.Id];
        
        Test.startTest();
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        Test.stopTest();
        
        List<Case> cases = SkpIntegrationHelper.getCases(testCase.Id);
        
        System.assertEquals(cases[0].id, skpCont.skpCase.id, 'We would expect the case fields queried appropriately and returned.');
        
        System.assert(!skpCont.wrappers.isEmpty(), 'We would expect the scheduleAs to be non-empty.');
        System.assert(skpCont.wrappers.size() == 1, 'We would expect the size of scheduleA wrappers to be 1');
        System.assertEquals(scheduleAs[0].id, skpCont.selectedScheduleA.id, 'We would expect the wrapper to have the correct scheduleA object');
        System.AssertEquals(SKPIntegrationWizardCont.Button.VALIDATEContract, skpCont.currentButton, 'An incorrect button set');
    }
    
    static testMethod void SKPIntegrationWizardCont_Test_MultipleScheduleAs() {
        //setup();
        //update testCase;
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
        testOpp = [select id from opportunity limit 1];
        testScheduleA = [select id,Schedule_A__c from Quote limit 1 ];
        List<Quote> testScheduleAs = TestingUtils.createQuotes(testOpp.id, 2, false);
        for(Quote q : testScheduleAs){
            q.Status = 'Accepted';
        }
        insert testScheduleAs;
        
        
        ApexPages.currentPage().getParameters().put('id', testCase.id);
        
        List<Quote> scheduleAs = [Select Name, id from Quote where Opportunityid =: testOpp.Id];
        List<Quote> listAllScheduleAs = new List<quote>();
        
        Test.startTest();
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        Test.stopTest();
        system.debug('skpCont.wrappers.size() '+skpCont.wrappers.size());
        System.assert(!skpCont.wrappers.isEmpty(), 'We would expect the scheduleAs to be non-empty.');
        System.assert(skpCont.wrappers.size() == 3, 'We would expect the size of scheduleA wrappers to be 3');
        
        for(integer i = 0; i < 3; i++) {
            SKPIntegrationWizardCont.ScheduleAWrapper scheduleAObj = skpCont.wrappers.get(i);
            listAllScheduleAs.add(scheduleAObj.scheduleA);
        }
        
        System.assertEquals(Pluck.ids(scheduleAs), Pluck.ids(listAllScheduleAs), 'We would expect the wrapper to have correct scheduleA objects');
        System.AssertEquals(SKPIntegrationWizardCont.Button.VALIDATE, skpCont.currentButton, 'An incorrect button set');
        
        
    }
    
    static testMethod void queryCaseTest_Negative() {
        //setup();     
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
        testOpp = [select id from opportunity limit 1]; 
        testContact = [select id from contact limit 1];
        testScheduleA = [select id,Schedule_A__c from Quote limit 1 ];
        
        ApexPages.currentPage().getParameters().put('Id', testCase.id);
        
        Case testCase2 = TestingUtils.createCase(testOpp, testContact, false);
        testCase2.SKP_Contract_Sync_Date__c = Date.today();
        testCase2.contract_type__c = 'IMTest';
        insert testCase2;
        
        //TestingUtils.dummyInsert(new List<Case>{testCase});
        
        Test.startTest();
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        Case resultCase = skpCont.queryCase(testContact.id);
        system.debug('resultCase '+resultCase);
        Test.stopTest();
        
        System.AssertEquals(1, ApexPages.getMessages().size(), 'We would expect a page message on the page.');
        // System.AssertEquals(null, resultCase, 'We would expect an empty case returned');
        
        ApexPages.currentPage().getParameters().put('id', testCase2.id);
        SKPIntegrationWizardCont skpCont2 = new SKPIntegrationWizardCont();
        System.AssertEquals(SKPIntegrationWizardCont.Button.NONE, skpCont2.currentButton, 'An incorrect button set for a completed case.');
        
        
        
        
    }
    
    
    static testMethod void queryCaseTest() {
        //setup();      
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
        ApexPages.currentPage().getParameters().put('Id', testCase.id);
        
        Test.startTest();
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        Case resultCase = skpCont.queryCase(null);
        Test.stopTest();
        
    }
    
    
    /*
static testMethod void handleSKPResponseTest_twoInputs(){
setup();

testCase.NCSP_Opportunity__c = testOpp.id;
insert testCase;


SKPResponse.CodeAndMessage errorMessage = new SKPResponse.CodeAndMessage();
errorMessage.Code ='500';
errorMessage.message ='Error occurred';

SKPResponse.CodeAndMessage warningMessage = new SKPResponse.CodeAndMessage();
warningMessage.Code ='400';
warningMessage.message = 'Warning, there is a warning.';

SKPResponse responseWithErrors = new SKPResponse();
responseWithErrors.errors = new List<SKPResponse.CodeAndMessage>{errorMessage};
responseWithErrors.warnings = new List<SKPResponse.CodeAndMessage>();
responseWithErrors.success = false;

SKPResponse responseWithWarnings = new SKPResponse();
responseWithWarnings.errors = new List<SKPResponse.CodeAndMessage>();
responseWithWarnings.warnings = new List<SKPResponse.CodeAndMessage>{warningMessage};
responseWithWarnings.success = true;

SKPResponse responseWithSuccess = new SKPResponse();
responseWithSuccess.errors = new List<SKPResponse.CodeAndMessage>();
responseWithSuccess.warnings = new List<SKPResponse.CodeAndMessage>();
responseWithSuccess.success = true;


SKP_Sync_Error__c expectedError = new SKP_Sync_Error__c(Error_Code__c = errorMessage.code, Error_Description__c = errorMessage.message, Severity__c='Error', Case__c = testCase.id, id= null);
SKP_Sync_Error__c expectedWarning = new SKP_Sync_Error__c(Error_Code__c = warningMessage.code, Error_Description__c = warningMessage.message, Severity__c='Warning', Case__c = testCase.id, id = null);
Set<SKP_Sync_Error__c> expectedSyncErrors = new Set<SKP_Sync_Error__c>{expectedError, expectedWarning};


ApexPages.currentPage().getParameters().put('id', testCase.id);
SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();

Test.StartTest();
skpCont.handleSKPResponse(responseWithErrors, responseWithSuccess, true);
System.AssertEquals(SKPIntegrationWizardCont.Step.VALIDATEERRORS, skpCont.currentStep);

skpCont.handleSKPResponse(responseWithWarnings, responseWithSuccess, false);
System.AssertEquals(SKPIntegrationWizardCont.Step.SYNCWARNINGS, skpCont.currentStep);

skpCont.handleSKPResponse(responseWithSuccess, responseWithSuccess, false);
System.AssertEquals(SKPIntegrationWizardCont.Step.SYNCSUCCESS, skpCont.currentStep);

Test.stopTest();

List<SKP_Sync_Error__c> actualErrors = [Select error_code__c, error_description__c, severity__c, case__c from SKP_Sync_Error__c];
System.AssertEquals(2, actualErrors.size(), 'An incorrect number of errors returned');

actualErrors[0].id = actualErrors[1].id = null; // We don't have access to the actual Ids, but want to assert that the rest of the values are correct.  
System.AssertEquals(expectedSyncErrors, new set<SKP_Sync_Error__c>(actualErrors), 'Incorrect  errors returned');

}
*/
    
    static testMethod void handleSKPResponseTest(){
        //setup();
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
        testOpp = [select id from opportunity limit 1]; 
        testCase.NCSP_Opportunity__c = testOpp.id;
        update testCase;
        
        
        SKPResponse.CodeAndMessage errorMessage = new SKPResponse.CodeAndMessage();
        errorMessage.Code ='500';
        errorMessage.message ='Error occurred';
        
        SKPResponse.CodeAndMessage warningMessage = new SKPResponse.CodeAndMessage();
        warningMessage.Code ='400';
        warningMessage.message = 'Warning, there is a warning.';
        
        SKPResponse responseWithErrors = new SKPResponse();
        responseWithErrors.errors = new List<SKPResponse.CodeAndMessage>{errorMessage};
            responseWithErrors.warnings = new List<SKPResponse.CodeAndMessage>();
        responseWithErrors.success = false;
        
        SKPResponse responseWithWarnings = new SKPResponse();
        responseWithWarnings.errors = new List<SKPResponse.CodeAndMessage>();
        responseWithWarnings.warnings = new List<SKPResponse.CodeAndMessage>{warningMessage};
            responseWithWarnings.success = true;
        
        SKPResponse responseWithSuccess = new SKPResponse();
        responseWithSuccess.errors = new List<SKPResponse.CodeAndMessage>();
        responseWithSuccess.warnings = new List<SKPResponse.CodeAndMessage>();
        responseWithSuccess.success = true;
        
        
        SKP_Sync_Error__c expectedError = new SKP_Sync_Error__c(Error_Code__c = errorMessage.code, Error_Description__c = errorMessage.message, Severity__c='Error', Case__c = testCase.id, id= null);
        SKP_Sync_Error__c expectedWarning = new SKP_Sync_Error__c(Error_Code__c = warningMessage.code, Error_Description__c = warningMessage.message, Severity__c='Warning', Case__c = testCase.id, id = null);
        Set<SKP_Sync_Error__c> expectedSyncErrors = new Set<SKP_Sync_Error__c>{expectedError, expectedWarning};
            
            
            ApexPages.currentPage().getParameters().put('id', testCase.id);
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        
        Test.StartTest();
        skpCont.handleSKPResponse(responseWithErrors, true);
        System.AssertEquals(1, skpCont.syncErrors.size());
        System.AssertEquals(0, skpCont.syncWarnings.size());
        
        skpCont.handleSKPResponse(responseWithWarnings, false);
        System.AssertEquals(1, skpCont.syncErrors.size());
        System.AssertEquals(1, skpCont.syncWarnings.size());
        
        skpCont.handleSKPResponse(responseWithSuccess, false);
        
        Test.stopTest();
        
        
        List<SKP_Sync_Error__c> errors = [Select error_code__c, error_description__c, severity__c, case__c from SKP_Sync_Error__c];
        System.AssertEquals(0, errors.size(), 'An incorrect number of errors returned');
        
        List<SKP_Sync_Error__c> syncErrors = new List<SKP_Sync_Error__c>(skpCont.syncErrors);
        syncErrors.addAll(skpCont.syncWarnings);
        insert syncErrors;
        
        List<SKP_Sync_Error__c> actualErrors = [Select error_code__c, error_description__c, severity__c, case__c from SKP_Sync_Error__c];
        System.AssertEquals(2, actualErrors.size(), 'An incorrect number of errors returned');
        
        actualErrors[0].id = actualErrors[1].id = null; // We don't have access to the actual Ids, but want to assert that the rest of the values are correct.  
        System.AssertEquals(expectedSyncErrors, new set<SKP_Sync_Error__c>(actualErrors), 'Incorrect  errors returned');
        
    }
    
    static testMethod void backTest() {                
        //setup();
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
        ApexPages.currentPage().getParameters().put('Id', testCase.id);
        
        Test.startTest();
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        skpCont.skpCase = testCase;
        PageReference backPref = skpCont.back();
        Test.stopTest();
        
        System.assert(backPref.getUrl().contains(testCase.id), 'An incorrect page reference returned');
    }
    
    static testMethod void hasScheduleATest(){
        
        //setup();
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
        testCase.contract_type__c = 'IMTest';
        update testCase;
        ApexPages.currentPage().getParameters().put('Id', testCase.id);
        
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        Quote unexpectedScheduleA  = new Quote();
        Quote expectedScheduleA  = new Quote();
        TestingUtils.dummyInsert(new List<Quote>{unexpectedScheduleA, expectedScheduleA});
        
        
        // Case newCase = new Case(contract_type__c ='IMTest');
        
        SkpIntegrationWizardCont.ScheduleAWrapper wrapper1 = new SkpIntegrationWizardCont.ScheduleAWrapper(unexpectedScheduleA);
        SkpIntegrationWizardCont.ScheduleAWrapper wrapper2 = new SkpIntegrationWizardCont.ScheduleAWrapper(expectedScheduleA);
        wrapper2.isChecked = true;
        
        skpCont.skpCase = testCase;
        skpCont.wrappers = new List<SkpIntegrationWizardCont.ScheduleAWrapper>{wrapper1, wrapper2};
            Test.startTest();
        boolean scheduleACheck = skpCont.hasSelectedScheduleA();
        Test.stopTest();
        
        System.Assert(scheduleACheck, 'There should be a schedule A in the controller.');
        System.AssertEquals(expectedScheduleA, skpCont.selectedScheduleA, 'An incorrect schedule a has been selected.');
        
    }
    
    static testMethod void hasContractMappingTest(){
        //setup();
        
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
        testCase.contract_type__c = 'test version';
        update testCase;
        
        ApexPages.currentPage().getParameters().put('Id', testCase.id);
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        
        SKP_Contract_Type_Mapping__c expectedMapping = TestingUtils.createSkpMappingObject('USA', 'test version', false);
        SKP_Contract_Type_Mapping__c otherMapping = TestingUtils.createSkpMappingObject('USA', 'Other version', false);
        insert new List<SKP_Contract_Type_Mapping__c>{expectedMapping, otherMapping};
            
            Test.startTest();
        boolean scheduleACheck = skpCont.hasContractMapping();
        Test.stopTest();
        
        System.AssertEquals(expectedMapping.id, skpCont.contractMapping.id, 'An incorrect mapping has been selected.');
        
    }
    
    static testmethod void insertNewSyncErrorsTest(){
        //setup();
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
    
        System.currentPageReference().getParameters().put('id', testCase.id);
        SkpIntegrationWizardCont cont = new SkpIntegrationWizardCont();
        
        Set<String> expectedBillCodes = new Set<String>{'COM9876', 'COM1234'};
            
            SKP_Sync_Error__c syncErrorWithID = TestingUtils.createSKPSyncError(testCase.id, 'BZ1234', 'An error has occurred', 'Error', 'Validate', false);
        SKP_Sync_Error__c syncErrorWithoutID = TestingUtils.createSKPSyncError(testCase.id, 'COM1234', 'An error has occurred', 'Error', 'Validate', false);
        
        SKP_Sync_Error__c syncWarningWithID = TestingUtils.createSKPSyncError(testCase.id, 'BZ9876', 'An error has occurred', 'Warning', 'Validate', false);
        SKP_Sync_Error__c syncWarningWithoutID = TestingUtils.createSKPSyncError(testCase.id, 'COM9876', 'An error has occurred', 'Warning', 'Validate', false);
        
        TestingUtils.dummyInsert(new List<SKP_Sync_Error__c>{syncErrorWithID, syncWarningWithID});
        
        cont.syncErrors = new List<SKP_Sync_Error__c>{syncErrorWithID, syncErrorWithoutID};
            cont.syncWarnings = new List<SKP_Sync_Error__c>{syncWarningWithID, syncWarningWithoutID};
                
                Test.startTest();
        cont.insertNewSyncErrors(false);
        Test.stopTest();
        
        List<SKP_Sync_Error__c> returnedSyncErrors = [Select Error_Code__c, Id from SKP_Sync_Error__c ];
        System.AssertEquals(2, returnedSyncErrors.size(), 'An incorrect number of sync errors returned.' );
        System.AssertEquals(expectedBillCodes, Pluck.strings('Error_Code__c', returnedSyncErrors), 'An unexpected billcode set on the insert sync errors');
        
    }
    
    static testmethod void customerCalloutTest(){
        
        //setup();
        testAccount = [select id from Account limit 1];
        testProfile = [select id from Customer_Profile__c limit 1];
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
        testOpp = [select id from opportunity limit 1]; 
       	testScheduleA = [select id,Schedule_A__c from Quote limit 1 ];
        
        testScheduleA.Status = 'Accepted';
        update testScheduleA;
        testCase.NCSP_Opportunity__c = testOpp.id;
        testCase.SKP_Customer_Sync_Date__c = Date.today();
        testCase.contract_type__c = 'test version';
        testCase.Customer_Profile__c = testProfile.id;
        testCase.AccountId = testAccount.id;
        
        update testCase;
        
        
        SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                            name='Sandbox', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test', OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        SKP_Integration_Details__c details2 = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                             name='Production', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test', OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        insert new List<SKP_Integration_Details__c>{details, details2};
            SKP_Contract_Type_Mapping__c expectedMapping = testingUtils.createSkpMappingObject('USA', 'test version', true);
        Test.startTest();
        ApexPages.currentPage().getParameters().put('Id', testCase.id);
        
        List<Quote> scheduleAs = [Select Name, id, Effective_Date__c from Quote where Opportunityid =: testOpp.Id];
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        //For Security Token
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        HttpCalloutMock custCallOut = new MockSkpCustomerCallout();
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('http://www.test.com/test',custCallOut);
        
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        //Test.setMock(HttpCalloutMock.class, new MockSkpCustomerCallout());
        
        
        skpCont.createSKPCustomer();
        Test.stopTest();
        
        Case returnedCase = [Select id, SKP_Customer_Sync_Date__c from Case where ID =: testCase.id];
        List<IM_Customer_Account__c> customerAccounts = [Select id, IM_Account__c from IM_Customer_Account__c where IM_Account__c=: testCase.accountID ];
        system.debug('customerAccounts=='+customerAccounts);
        system.debug('customerAccounts.size()=='+customerAccounts.size());
        //System.AssertEquals(1, customerAccounts.size(), 'An incorrect number of customer accounts returned');
        //System.AssertEquals(testCase.accountID, customerAccounts[0].IM_Account__c, 'An incorrect account id has been set.');
        
        //System.AssertEquals(customerID, skpCont.customerID, 'An incorrect customer id set');
        //System.AssertEquals(districtID, skpCont.districtID, 'An incorrect district id set');
        
        //System.AssertNotEquals(null, returnedCase.SKP_Customer_Sync_Date__c, 'A date must be set');
        //System.AssertEquals(SkpIntegrationWizardCont.Button.CREATECONTRACT, skpCont.currentButton);
        
        
        
    }
    
    static testmethod void contractCalloutTest(){
        
        //setup();
        testAccount = [select id from Account limit 1];
        testProfile = [select id from Customer_Profile__c limit 1];
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
        testOpp = [select id from opportunity limit 1]; 
       	testScheduleA = [select id,Schedule_A__c from Quote limit 1 ];
 
        testScheduleA.Status = 'Accepted';
        update testScheduleA;
        imAccount = TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
        
        testCase.NCSP_Opportunity__c = testOpp.id;
        testCase.SKP_Customer_Sync_Date__c = Date.today();
        testCase.Customer_ID__c = imAccount.id;
        testCase.contract_type__c = 'test version';
        testCase.Customer_Profile__c = testProfile.id;
        
        update testCase;
        
        SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                            name='Sandbox', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
        SKP_Integration_Details__c details2 = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                             name='Production', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
        insert new List<SKP_Integration_Details__c>{details, details2};
            SKP_Contract_Type_Mapping__c expectedMapping = testingUtils.createSkpMappingObject('USA', 'test version', true);
        
        ApexPages.currentPage().getParameters().put('id', testCase.id);
        
        List<Quote> scheduleAs = [Select Name, id, Effective_Date__c from Quote where Opportunityid =: testOpp.Id];
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        
        
        Quote scheduleA = SkpIntegrationHelper.getScheduleAs( (string) testOpp.id, new List<String>(SkpIntegrationWizardCont.scheduleAFields))[0];
        skpCont.customerIndicator = new SkpIntegrationHelper.customerIndicator(scheduleA.quoteLineItems, 'test version');
        
        //For Security Token
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        HttpCalloutMock contCall = new MockSkpContractCallout();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('http://www.test.com/test',contCall);
        
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        Test.startTest();
        skpCont.validateSKPContract();
        skpCont.createSKPContract();
        Test.stopTest();
        
        Case returnedCase = [Select id, SKP_Contract_Sync_Date__c from Case where ID =: testCase.id];
        
        //System.AssertNotEquals(null, returnedCase.SKP_CONTRACT_Sync_Date__c, 'A date must be set');
        //System.AssertEquals(SkpIntegrationWizardCont.Button.NONE, skpCont.currentButton);
        
    }
    
    public static testMethod void contractCalloutWithErrors(){
        //setup();
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
        testScheduleA = [select id,Schedule_A__c from Quote limit 1 ];
        testCase.contract_type__c = 'test version';
        update testCase;
        //inserting a schedlue A
        Schedule_A__c sch = TestingUtils.createPAModels(1, false)[0];
        sch.RM_Contract_Length__c = 1;
        sch.SS_Contract_Length__c  = 1;
        sch.Reference__c='Testxml.xlsx';
        insert sch;
        
        
        testScheduleA.Status = 'Accepted';
        testScheduleA.Schedule_A__c = sch.id;
        //    insert testScheduleA;
        
        
        update new List<Quote>{testScheduleA};//, testScheduleA.clone()};
            
            ApexPages.currentPage().getParameters().put('id', testCase.id);
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        
        //For Security Token
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        HttpCalloutMock testfailure = new MockSKPFailures();
        //Test.setMock(HttpCalloutMock.class, new MockSKPFailures());
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('http://www.test.com/test',testfailure);
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        Test.startTest();
        skpCont.createSKPContract();
        skpCont.wrappers[0].ischecked = true;
        skpCont.createSKPContract();
        
        Test.stopTest();
        
        //System.AssertEquals(3, ApexPages.getMessages().size(), 'An incorrect number of page messages returned');
        //System.Assert(TestingUtils.pageMessageContains(SKPIntegrationWizardCont.SELECT_A_SCHEDULE_A));
        //System.Assert(TestingUtils.pageMessageContains(SKPIntegrationWizardCont.NO_CONTRACT_MAPPING_FOUND));
        //System.AssertEquals(SkpIntegrationWizardCont.Button.VALIDATE, skpCont.currentButton);
        
    }
    
    public static testMethod void customerCalloutErrors(){
        //setup();
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
        testScheduleA = [select id,Schedule_A__c from Quote limit 1 ];
        testProfile = [select id from Customer_Profile__c limit 1];
        testContact = [select id from contact limit 1];
        testCase.contract_type__c = 'test version';
        testCase.Customer_Profile__c = testProfile.id;
        update testCase;
        
        testScheduleA.Status = 'Accepted';
        
        ApexPages.currentPage().getParameters().put('id', testCase.id);
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        //Security Token response
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        HttpCalloutMock fakeMockF = new MockSKPFailures();
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('http://www.test.com/test',fakeMockF);
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        Test.startTest();
        skpCont.createSKPCustomer();
        
        update new List<Quote>{testScheduleA};
            SkpCont.wrappers = new List<SKPIntegrationWizardCont.ScheduleAWrapper>{new SKPIntegrationWizardCont.ScheduleAWrapper(testScheduleA)};
                skpCont.createSKPCustomer();
        Test.stopTest();
        
        //System.AssertEquals(3, ApexPages.getMessages().size(), 'An incorrect number of page messages returned');
        //System.Assert(TestingUtils.pageMessageContains(SKPIntegrationWizardCont.SELECT_A_SCHEDULE_A));
        
        //System.AssertEquals(SkpIntegrationWizardCont.Button.NONE, skpCont.currentButton);
        
    }
    
    
    
    public class MockSkpCustomerCallout implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            SKPResponse successfulSKPResponse = new SKPResponse();
            SKPResponse.successResult result =  new SKPResponse.successResult();
            result.customerID = customerID;
            result.districtID = districtID;
            successfulSKPResponse.success = true;
            successfulSKPResponse.result = result;
            res.setBody(JSON.serialize(successfulSKPResponse));
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class MockSkpContractCallout implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            SKPResponse successfulSKPResponse = new SKPResponse();
            SKPResponse.successResult result =  new SKPResponse.successResult();
            result.customerID = customerID;
            result.districtID = districtID;
            successfulSKPResponse.success = true;
            successfulSKPResponse.result = result;
            res.setBody(JSON.serialize(successfulSKPResponse));
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class MockSKPFailures implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            SKPResponse failedSKPResponse = new SKPResponse();
            
            SKPResponse.CodeAndMessage skpError = new SKPResponse.CodeAndMessage();
            skpError.code = '401';
            skpError.message='error';
            failedSKPResponse.errors = new List<SKPResponse.CodeAndMessage>{skpError};  
                failedSKPResponse.success = false;
            res.setBody(JSON.serialize(failedSKPResponse));
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class MockValidateCallout implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            SKPResponse successfulSKPResponse = new SKPResponse();
            SKPResponse.successResult result =  new SKPResponse.successResult();
            result.customerID = customerID;
            
            successfulSKPResponse.success = true;
            successfulSKPResponse.result = result;
            
            res.setBody(JSON.serialize(successfulSKPResponse));
            res.setStatusCode(200);
            system.debug('result=='+res);
            return res;
        }
    }
    
    public class MockValidateContCallout implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            SKPResponse successfulSKPResponse = new SKPResponse();
            SKPResponse.successResult result =  new SKPResponse.successResult();
            result.customerID = customerID;
            SKPResponse.CodeAndMessage errorMessage = new SKPResponse.CodeAndMessage();
            errorMessage.Code ='500';
            errorMessage.message ='Error occurred';
            
            SKPResponse.CodeAndMessage warningMessage = new SKPResponse.CodeAndMessage();
            warningMessage.Code ='400';
            warningMessage.message = 'Warning, there is a warning.';
            
            successfulSKPResponse.success = true;
            successfulSKPResponse.result = result;
            successfulSKPResponse.errors.add(errorMessage);
            successfulSKPResponse.errors.add(warningMessage);
            
            res.setBody(JSON.serialize(successfulSKPResponse));
            res.setStatusCode(200);
            System.debug(LoggingLevel.Info,'result==='+res);
            return res;
        }
    }
    
    public class MockUpdateContract implements HttpCalloutMock{
        
        public HTTPResponse respond (httpRequest req){  
            system.debug('end point 1'+req.getEndpoint());
            SKP_Contract_Type_Mapping__c mapping1 = TestingUtils.createSkpMappingObject('USA', 'Affiliate Option 1', false);
            Quote scheduleA = SkpIntegrationHelper.getScheduleAs( (string) testOpp.id, new List<String>(SkpIntegrationWizardCont.scheduleAFields))[0];
            SkpIntegrationHelper.customerIndicator custIndicator = new SkpIntegrationHelper.customerIndicator(scheduleA.quoteLineItems, 'test version');
            Set<String> custIdSet = new Set<String>();
            custIdSet.add('test');                
            SKPContractRenegotiation contractReno = new SKPContractRenegotiation(testCase,testScheduleA,mapping1,custIndicator,true,customerID,'test','erid',custIdSet,1);            
            contractReno.companyID=companyID;  
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            SKPUpdateContractResponse contractResp = new SKPUpdateContractResponse();
            contractResp.success = true;
            SKPUpdateContractResponse.ContractDetails contract= new SKPUpdateContractResponse.ContractDetails();
            contract.customerId=customerID;
            contractResp.updateContractResult.contractDetails.add(contract);
            
            res.setBody(JSON.serialize(contractResp));
            res.setStatusCode(200);
            system.debug('result=='+res);
            return res;
        }
    }
    
    
    public class MockUpdateContractResp implements HttpCalloutMock{
        
        public HTTPResponse respond (httpRequest req){                    
            SKP_Contract_Type_Mapping__c mapping1 = TestingUtils.createSkpMappingObject('USA', 'Affiliate Option 1', false);
            Quote scheduleA = SkpIntegrationHelper.getScheduleAs( (string) testOpp.id, new List<String>(SkpIntegrationWizardCont.scheduleAFields))[0];
            SkpIntegrationHelper.customerIndicator custIndicator = new SkpIntegrationHelper.customerIndicator(scheduleA.quoteLineItems, 'test version');
            Set<String> custIdSet = new Set<String>();
            custIdSet.add('test');                
            SKPContractRenegotiation contractReno = new SKPContractRenegotiation(testCase,testScheduleA,mapping1,custIndicator,true,customerID,'test','erid',custIdSet,1);            
            contractReno.companyID=companyID;  
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            //SKPUpdateContractResponse contractResp = new SKPUpdateContractResponse();
            
            SKPUpdateContractResponse.CodeAndMessage errorMessage = new SKPUpdateContractResponse.CodeAndMessage();
            errorMessage.Code ='500';
            errorMessage.message ='Error occurred';
            
            SKPUpdateContractResponse.CodeAndMessage warningMessage = new SKPUpdateContractResponse.CodeAndMessage();
            warningMessage.Code ='400';
            warningMessage.message = 'Warning, there is a warning.';
            
            SKPUpdateContractResponse.generalWarnings generalWarningsMessage = new SKPUpdateContractResponse.generalWarnings();
            warningMessage.Code ='400';
            warningMessage.message = 'Warning, there is a general warning.';
            
            SKPUpdateContractResponse responseWithErrors = new SKPUpdateContractResponse();
            
            SKPUpdateContractResponse.ContractDetails contract= new SKPUpdateContractResponse.ContractDetails();
            contract.customerId=customerID;        
            
            contract.errors = new List<SKPUpdateContractResponse.CodeAndMessage>{errorMessage};
                contract.warnings = new List<SKPUpdateContractResponse.CodeAndMessage>{warningMessage};
                    
                    responseWithErrors.updateContractResult.contractDetails.add(contract);                
            //responseWithErrors.updateContractResult.generalWarnings.add(generalWarningsMessage);
            responseWithErrors.success = false;
            
            res.setBody(JSON.serialize(responseWithErrors));
            res.setStatusCode(200);
            system.debug('result=='+res);
            return res;
        }
    }
    public class MockUpdateContractUpdate implements HttpCalloutMock{
        
        public HTTPResponse respond (httpRequest req){
            system.debug('end point 1 ' + req.getEndpoint());
            
            SKP_Contract_Type_Mapping__c mapping1 = TestingUtils.createSkpMappingObject('USA', 'Affiliate Option 2', false);
            Quote scheduleA = SkpIntegrationHelper.getScheduleAs( (string) testOpp.id, new List<String>(SkpIntegrationWizardCont.scheduleAFields))[0];
            SkpIntegrationHelper.customerIndicator custIndicator = new SkpIntegrationHelper.customerIndicator(scheduleA.quoteLineItems, 'test version');
            Set<String> custIdSet = new Set<String>();
            custIdSet.add('test');                
            SKPContractUpdate contractReno = new SKPContractUpdate(testCase,testScheduleA,mapping1,custIndicator,true,customerID,'test','erid',1);            
            contractReno.companyID=companyID;  
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            SKPUpdateContractResponse contractResp = new SKPUpdateContractResponse();
            contractResp.success = true;
            SKPUpdateContractResponse.ContractDetails contract= new SKPUpdateContractResponse.ContractDetails();
            contract.customerId=customerID;
            contractResp.updateContractResult.contractDetails.add(contract);
            
            res.setBody(JSON.serialize(contractResp));
            res.setStatusCode(200);
            system.debug('result=='+res);
            return res;
        }
    }
    public class MockGetCustProfile implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            SKPPreValidationResponse preValidationResponse = new SKPPreValidationResponse();
            preValidationResponse.success = true;
            preValidationResponse.customer.customerProfile.customerId = customerID;
            preValidationResponse.customer.customerProfile.districtID = districtID;
            preValidationResponse.customer.serviceIndicators.hardCopyEnabled=true;
            preValidationResponse.customer.serviceIndicators.shreddingServiceEnabled = true;
            SKPPreValidationResponse.CodeAndMessage errorMessage = new SKPPreValidationResponse.CodeAndMessage();
            errorMessage.Code ='500';
            errorMessage.message ='Error occurred';
            
            SKPPreValidationResponse.CodeAndMessage warningMessage = new SKPPreValidationResponse.CodeAndMessage();
            warningMessage.Code ='400';
            warningMessage.message = 'Warning, there is a warning.';
            
            preValidationResponse.errors.add(errorMessage);
            preValidationResponse.warnings.add(warningMessage);
            
            res.setBody(JSON.serialize(preValidationResponse));
            res.setStatusCode(200);
            system.debug('result=='+res);
            return res;
        }
    }
    
    public class MockGetContractResp implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            SKPPreValidationContractResponse contractResp = new SKPPreValidationContractResponse();
            contractResp.success = true;
            contractResp.contract.customerId = customerID;
            
            SKPPreValidationContractResponse.ContractDetails test1= new SKPPreValidationContractResponse.ContractDetails();
            test1.rmAdminFeeEnabled=true;
            test1.fuelSurchargeEnabled=true;
            test1.containerBillingEnabled=true;
            
            SKPPreValidationContractResponse.CodeAndMessage errorMessage = new SKPPreValidationContractResponse.CodeAndMessage();
            errorMessage.Code ='500';
            errorMessage.message ='Error occurred';
            
            SKPPreValidationContractResponse.CodeAndMessage warningMessage = new SKPPreValidationContractResponse.CodeAndMessage();
            warningMessage.Code ='400';
            warningMessage.message = 'Warning, there is a warning.';
            
            contractResp.contract.contractDetails.add(test1);
            contractResp.errors.add(errorMessage);
            contractResp.warnings.add(warningMessage);
            
            
            res.setBody(JSON.serialize(contractResp));
            res.setStatusCode(200);
            system.debug('result=='+res);
            return res;
        }
    }
    
    public class MockGetCustContract implements HttpCalloutMock {
        Map<String, HttpCalloutMock> requests;
        
        public MockGetCustContract(Map<String, HttpCalloutMock> requests) {
            this.requests = requests;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            system.debug('end point 1 ' + req.getEndpoint());
            system.debug('end point 2 '+ requests.get(req.getEndpoint()));
            HttpCalloutMock mock = requests.get(req.getEndpoint());
            if (mock != null) {
                return mock.respond(req);
            } else {
                CalloutException e = (CalloutException)CalloutException.class.newInstance();
                e.setMessage('Unauthorized endpoint.');
                throw e;
            }
        }
        
        public void addRequestMock(String url, HttpCalloutMock mock) {
            requests.put(url, mock);
        }
    }
    
    public class UnauthorizedEndpointResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            CalloutException e = (CalloutException)CalloutException.class.newInstance();
            e.setMessage('Unauthorized endpoint.');
            throw e;
        }
    }
    
    static testMethod void TestCancel() {        
        //setup();    
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
       
        ApexPages.currentPage().getParameters().put('Id', testCase.id);
        
        Test.startTest();
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        skpCont.skpCase = testCase;
        PageReference cancelPageref = skpCont.cancel();
        Test.stopTest();
    }
    
    static testMethod void TestSave() {
        
        //setup();      
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ]; 
        testAccount = [select id from Account limit 1];
        testProfile = [select id from Customer_Profile__c limit 1];
        
        ApexPages.currentPage().getParameters().put('Id', testCase.id);
        IM_Customer_Account__c testCustomerAccount1=TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
        testCustomerAccount=TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
        //testCase.Source_Customer_Id__c=testCustomerAccount.Id;
        testCase.Customer_ID__c = testCustomerAccount.id;
        testCase.Customer_Profile__c = testProfile.id;
        update testCase;          
        testCaseCustomerAccount=TestingUtils.createCaseCustomerAccount(testCase.Id,testCustomerAccount.Id,true);
        Test.startTest();
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        skpCont.skpCase = testCase;
        PageReference cancelPageref = skpCont.save();
        Test.stopTest();
        
    }    
    
    public static testMethod  void validateSKPCustomerAndContract_setup(){
        //setup();    
        testAccount = [select id from Account limit 1];
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
       
        testProfile = [select id from Customer_Profile__c limit 1];
        testScheduleA = [select id,Schedule_A__c from Quote limit 1 ];
        testOpp = [select id from opportunity limit 1];
        testCustomerAccount=TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
        testCase.Source_Customer_Id__c=testCustomerAccount.Id;
        testCase.Customer_ID__c = testCustomerAccount.id;
        testCase.Customer_Profile__c = testProfile.id;
        update testCase;        
        ApexPages.currentPage().getParameters().put('id', testCase.id);
        
        SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                            name='Sandbox', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test',Update_Customer_Info__c='http://www.test.com/custUpdate', Update_Contract_Info__c='http://www.test.com/contractUpdate',Get_Recurring_Charges__c='http://www.test.com/getRecurring', Update_Recurring_Charges__c='http://www.test.com/UpdateRecurring',Create_Recurring_Charges__c='http://www.test.com/CreateRecurring', OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        SKP_Integration_Details__c details2 = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                             name='Production', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test',Update_Customer_Info__c='http://www.test.com/custUpdate', Update_Contract_Info__c='http://www.test.com/contractUpdate',Get_Recurring_Charges__c='http://www.test.com/getRecurring', Update_Recurring_Charges__c='http://www.test.com/UpdateRecurring',Create_Recurring_Charges__c='http://www.test.com/CreateRecurring', OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        insert new List<SKP_Integration_Details__c>{details, details2};
            testScheduleA.Status = 'Accepted';  
        
        Schedule_A__c sch = TestingUtils.createPAModels(1, false)[0];
        sch.RM_Contract_Length__c = 10;
        sch.SS_Contract_Length__c  = 1;
        sch.Reference__c='Testxml.xlsx';
        insert sch;
        
        
        
        testScheduleA.Schedule_A__c = sch.id;
        update testScheduleA;
        
        Quote scheduleA = SkpIntegrationHelper.getScheduleAs( (string) testOpp.id, new List<String>(SkpIntegrationWizardCont.scheduleAFields))[0];
        
        List<Quote> scheduleAs = [Select Name, id, Effective_Date__c from Quote where Opportunityid =: testOpp.Id];    
        
        system.debug('testScheduleA======='+testScheduleA);
        system.debug('scheduleAs ======='+scheduleAs);
        
        SKP_Contract_Type_Mapping__c mapping1 = TestingUtils.createSkpMappingObject('USA', 'Affiliate Option 1', false);
        SKP_Contract_Type_Mapping__c mapping2 = TestingUtils.createSkpMappingObject('USA', 'Affiliate Option 2', false);
        SKP_Contract_Type_Mapping__c mapping3 = TestingUtils.createSkpMappingObject('USA', 'IM-38', false);
        insert new List<SKP_Contract_Type_Mapping__c>{mapping1, mapping2, mapping3};
            }
    
    public static testMethod void validateSKPCustomerAndContract_test_option1()
    {
        validateSKPCustomerAndContract_setup();
        //Security Token
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        HttpCalloutMock mockValcall = new MockValidateCallout();
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('http://www.test.com/test',mockValcall);
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        //Test.setMock(HttpCalloutMock.class, new MockValidateCallout());  
        testCase.contract_type__c = 'Affiliate Option 1';
        update testCase;        
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        
        Test.startTest();              
        skpCont.validateSKPCustomerAndContract();    
        skpCont.createSKPCustomer();
        skpCont.createSKPContract();
        skpCont.validateSKPContract();
        Test.stopTest();
        
    }  
    
    public static testMethod void validateSKPCustomerAndContract_test_option2()
    {
        validateSKPCustomerAndContract_setup();
        //
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        HttpCalloutMock valCallOut = new MockValidateCallout();
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('http://www.test.com/test',valCallOut);
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        testCase.contract_type__c = 'Affiliate Option 2';
        update testCase;    
        //HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        //Test.setMock(HttpCalloutMock.class, fakeSecurityToken);
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        
        Test.startTest();              
        skpCont.validateSKPCustomerAndContract();                  
        Test.stopTest();
    }
    
    public static testMethod void multicontractCalloutAffiliate(){
        validateSKPCustomerAndContract_setup();
        testCase.contract_type__c = 'Affiliate Option 2';
        update testCase;
        SKP_Minimum_Mapping__c mapp = new SKP_Minimum_Mapping__c(name ='2476',Minimum_Level__c='CUSTOMER', 
                                             Minimum_Order_Type__c='SHREDDING OFF SITE', Minimum_Type__c='Order');
        insert mapp;
        Test.startTest();      
        SKPContract.scaleListObj chckscale = new SKPContract.scaleListObj
            (new QuoteLineItem(QuoteId = testScheduleA.id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1),1);
        SKPContractRenegotiation.scaleListObj chckscaleRenego = new SKPContractRenegotiation.scaleListObj
            (new QuoteLineItem(QuoteId = testScheduleA.id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1),1);
        SKPContractRenewal.scaleListObj chckscaleRenewal = new       SKPContractRenewal.scaleListObj
            (new QuoteLineItem(QuoteId = testScheduleA.id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1),1);
      SKPContractRenewal.minimumObj minobj = new SKPContractRenewal.minimumObj(mapp);
        
        ApexPages.currentPage().getParameters().put('id', testCase.id);
        
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        HttpCalloutMock mockContractUp = new MockUpdateContractUpdate();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('http://www.test.com/contractUpdate',mockContractUp);
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        //skpCont.createSKPContract();
        skpCont.wrappers[0].ischecked = true;
        skpCont.multiYearContractUpdate();
        Test.stopTest();
        
    }
    
    public static testMethod void multicontractCallout(){
        validateSKPCustomerAndContract_setup();
        testCase.contract_type__c = 'IM-38';
        update testCase;
        List<SKP_Integration_Details__c> lstSkp = [SELECT Id, Name, OAuth_EndPoint__c,Client_Id__c,Client_Secret__c FROM SKP_Integration_Details__c];
        system.debug('lstSkp '+lstSkp);
        system.debug('size in custom setting lstSkp '+lstSkp.size());
        
        
        SKPContract.scaleListObj chckscale = new SKPContract.scaleListObj
            (new QuoteLineItem(QuoteId = testScheduleA.id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1),1);
        SKPContractRenegotiation.scaleListObj chckscaleRenego = new SKPContractRenegotiation.scaleListObj
            (new QuoteLineItem(QuoteId = testScheduleA.id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1),1);
        SKPContractRenewal.scaleListObj chckscaleRenewal = new       SKPContractRenewal.scaleListObj
            (new QuoteLineItem(QuoteId = testScheduleA.id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1),1);
        
        
        
        
        ApexPages.currentPage().getParameters().put('id', testCase.id);
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        Test.setMock(HttpCalloutMock.class, new MockUpdateContractUpdate ());
        system.debug('before test limit '+ Limits.getQueries());
        Test.startTest();
        system.debug('1114 '+ Limits.getQueries());
        //skpCont.createSKPContract();
        skpCont.wrappers[0].ischecked = true;
        skpCont.multiYearContractUpdate();
        
        Test.stopTest();
        system.debug('after test limit '+ Limits.getQueries());
    }
    
    public static testMethod void multicontractCallout_MultiCallout(){
        validateSKPCustomerAndContract_setup();
        testCase.contract_type__c = 'IM-38';
        update testCase;
        
        SKPContract.scaleListObj chckscale = new SKPContract.scaleListObj
            (new QuoteLineItem(QuoteId = testScheduleA.id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1),1);
        SKPContractRenegotiation.scaleListObj chckscaleRenego = new SKPContractRenegotiation.scaleListObj
            (new QuoteLineItem(QuoteId = testScheduleA.id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1),1);
        SKPContractRenewal.scaleListObj chckscaleRenewal = new       SKPContractRenewal.scaleListObj
            (new QuoteLineItem(QuoteId = testScheduleA.id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1),1);
        
        ApexPages.currentPage().getParameters().put('id', testCase.id);
        
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        HttpCalloutMock mockContractUp = new MockUpdateContractUpdate();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('http://www.test.com/contractUpdate',mockContractUp);
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        Test.startTest();
        skpCont.wrappers[0].ischecked = true;
        skpCont.multiYearContractUpdate();
        
        Test.stopTest();
        
    }
    
    public static testMethod void validateSKPCustomerAndContract_test_NCSP_renego()
    {
        validateSKPCustomerAndContract_setup();  
        
        testCase.contract_type__c = 'IM-38';
        NCSPRenewalRecordType = [Select Id From RecordType where Name = 'NCSP Renewal' AND SobjectType = 'Case'];
        testCase.RecordTypeId=NCSPRenewalRecordType.Id;
        
        // testCase.RecordTypeId='01280000000UP5s';
        update testCase;  
        
        IM_Customer_Account__c testCustomerAccount1=TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
        testCustomerAccount1.SKP_Exception_Rate_ID__c='test_data';
        update testCustomerAccount1;  
        testCaseCustomerAccount=TestingUtils.createCaseCustomerAccount(testCase.Id,testCustomerAccount1.Id,true);      
        
        //Test.setMock(HttpCalloutMock.class, new MockUpdateContract());  
        
        //For Security Token
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        
        //HttpCalloutMock fakeCustProfile = new MockValidateCallout();
        HttpCalloutMock fakeContractResp = new MockUpdateContract();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        // endpoint2TestResp.put('www.test.com/custUpdate',fakeCustProfile);
        endpoint2TestResp.put('http://www.test.com/contractUpdate',fakeContractResp);
        
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        
        Test.startTest();            
        skpCont.contractCallout_RenewalNRenego(true,5);
        Test.stopTest();
    }
    
    public static testMethod void test_NCSP_renego_error()
    {
        validateSKPCustomerAndContract_setup();  
        
        testCase.contract_type__c = 'IM-38';
        NCSPRenewalRecordType = [Select Id From RecordType where Name = 'NCSP Renewal' AND SobjectType = 'Case'];
        testCase.RecordTypeId=NCSPRenewalRecordType.Id;
        // testCase.RecordTypeId='01280000000UP5s';
        update testCase;  
        
        IM_Customer_Account__c testCustomerAccount1=TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
        testCustomerAccount1.SKP_Exception_Rate_ID__c='test_data';
        update testCustomerAccount1;  
        testCaseCustomerAccount=TestingUtils.createCaseCustomerAccount(testCase.Id,testCustomerAccount1.Id,true);      
        
        //Test.setMock(HttpCalloutMock.class, new MockUpdateContract());  
        
        //For Security Token
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        HttpCalloutMock fakeContractResp = new MockUpdateContractResp();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('http://www.test.com/contractUpdate',fakeContractResp);
        
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        
        Test.startTest();            
        skpCont.contractCallout_RenewalNRenego(true,5);
        Test.stopTest();
    }
    
    public static testMethod void validateSKPCustomerAndContract_test_NCSP_renego1()
    {
        validateSKPCustomerAndContract_setup();  
        
        testCase.contract_type__c = 'IM-38';
        NCSPRenewalRecordType = [Select Id From RecordType where Name = 'NCSP Renewal' AND SobjectType = 'Case'];
        testCase.RecordTypeId=NCSPRenewalRecordType.Id;
        testCase.Setup_Type__c = 'Schedule A only';
        // testCase.RecordTypeId='01280000000UP5s';
        update testCase;  
        
        IM_Customer_Account__c testCustomerAccount1=TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
        testCustomerAccount1.SKP_Exception_Rate_ID__c='test_data';
        update testCustomerAccount1;  
        testCaseCustomerAccount=TestingUtils.createCaseCustomerAccount(testCase.Id,testCustomerAccount1.Id,true);      
        
        Test.setMock(HttpCalloutMock.class, new MockUpdateContract());  
        
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        
        Test.startTest();            
        skpCont.contractCallout_RenewalNRenego(true,1);
        skpCont.contractCallout_RenewalNRenego(false,1);
        Test.stopTest();
    }
    
    public static testMethod void validateSKPCustomerAndContract_test_NCSP()
    {
        validateSKPCustomerAndContract_setup();  
        
        testCase.contract_type__c = 'IM-38';
        NCSPRenewalRecordType = [Select Id From RecordType where Name = 'NCSP Renewal' AND SobjectType = 'Case'];
        testCase.RecordTypeId=NCSPRenewalRecordType.Id;
        // testCase.RecordTypeId='01280000000UP5s';
        update testCase;  
        
        IM_Customer_Account__c testCustomerAccount1=TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
        testCustomerAccount1.SKP_Exception_Rate_ID__c='test_data';
        update testCustomerAccount1;  
        testCaseCustomerAccount=TestingUtils.createCaseCustomerAccount(testCase.Id,testCustomerAccount1.Id,true);      
        
        //For Security Token
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        
        HttpCalloutMock fakeCustProfile = new MockValidateCallout();
        HttpCalloutMock fakeContractResp = new MockUpdateContract();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('http://www.test.com/custUpdate',fakeCustProfile);
        endpoint2TestResp.put('http://www.test.com/contractUpdate',fakeContractResp);
        
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        //SKPCustomerRenegotiation skpcusren = new SKPCustomerRenegotiation();
        SKPCustomerRenegotiation.shreddingObj shredObj = new SKPCustomerRenegotiation.shreddingObj(true, 'Test Type');
        
        Customer_Profile__c profileYes = new Customer_Profile__c(HealthcareAccountStoringPatientRecords__c = 'Yes', Opportunity__c=testOpp.id, Address__c = 'Test', City__c = 'NY', State_Province__c = 'NY', Zip_Postal_Code__c = '9234', Country__c = 'USA');
        insert profileYes;

      
        SKPCustomerRenegotiation.customerSettingsObj settingsObjYes = new SKPCustomerRenegotiation.customerSettingsObj(profileYes);

        Test.startTest();              
        skpCont.validateSKPCustomerAndContract();  
        skpCont.createSKPCustomer();
        skpCont.createSKPContract();
        skpCont.validateSKPContract();
        
        System.assertEquals(true, shredObj.activateShredding);
        System.assertEquals('SCHEDULED', shredObj.shreddingType); 
        System.assertEquals('800', settingsObjYes.businessType);
        Test.stopTest();
    }
    
    public static testMethod void validateSKPCustomerAndContract_test()
    {
        validateSKPCustomerAndContract_setup();
        //Security Token
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        HttpCalloutMock mockValidateCC = new MockValidateContCallout();
        HttpCalloutMock mockCustCC = new MockSkpCustomerCallout();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('http://www.test.com/test',mockValidateCC);
        endpoint2TestResp.put('http://www.test.com/test',mockCustCC);
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();  
        
        Quote scheduleA = SkpIntegrationHelper.getScheduleAs((string) testOpp.id, new List<String>(SkpIntegrationWizardCont.scheduleAFields))[0];
        Product2 prod = new Product2(Name = '3472', IM_Product_Line__c= 'Storage', ProductCode='RMVALPAC300', IM_Revenue_Type__c='Recurring',IsActive= true);
        //QuoteLineItem q1 = new QuoteLineItem(QuoteId = scheduleA.Id, Product2Id = prod.Id ,UnitPrice=2,Quantity=2);
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        //qlis.add(q1);
        skpCont.customerIndicator = new SkpIntegrationHelper.customerIndicator(qlis, 'test version');
        System.debug(LoggingLevel.Info,'skpCont.customerIndicator=='+skpCont.customerIndicator);
        System.debug('skpCont.customerIndicator=='+skpCont.customerIndicator);
        
        /*   SKPRecurringChargesDetails__c skpSetting = new SKPRecurringChargesDetails__c();
skpSetting.Name = '3472';
skpSetting.ProductName__c = '3472';
skpSetting.BillCode__c = '3472';
skpSetting.Rate__c = '99.99';
insert skpSetting;*/
        SKPContract.scaleListObj chckscale = new SKPContract.scaleListObj
            (new QuoteLineItem(QuoteId = scheduleA.Id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1),1);
        SKPContractRenegotiation.scaleListObj chckscaleRenego = new SKPContractRenegotiation.scaleListObj
            (new QuoteLineItem(QuoteId = scheduleA.Id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1),1);
        SKPContractRenewal.scaleListObj chckscaleRenewal = new       SKPContractRenewal.scaleListObj
            (new QuoteLineItem(QuoteId = scheduleA.Id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1),1);
        
        Test.startTest();              
        skpCont.validateSKPCustomerAndContract();  
        skpCont.customerIndicator.recurringChargesExists=true;      
        skpCont.validateSKPContract();    
        Test.stopTest();
    }
    
    public static testMethod void errors_NoAffiliate_NoSchedule_test()
    {
        validateSKPCustomerAndContract_setup();
        testCase.contract_type__c = 'IM-38';
        update testCase;
        delete testScheduleA;
        Test.setMock(HttpCalloutMock.class, new MockValidateCallout());  
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        
        Test.startTest();  
        skpCont.createSKPCustomer_Affiliate();
        skpCont.contractCallout_Affiliate(true);
        Test.stopTest();
        
        System.Assert(TestingUtils.pageMessageContains(SKPIntegrationWizardCont.SELECT_A_SCHEDULE_A));
    }
    
    public static testMethod void createSKPCustomer_Affiliate_NoSrcCust()
    {
        validateSKPCustomerAndContract_setup();
        testCase.contract_type__c = 'Affiliate Option 1';
        testCase.Source_Customer_Id__c = null;
        update testCase;  
        Test.setMock(HttpCalloutMock.class, new MockValidateCallout());  
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();        
        
        Test.startTest();  
        skpCont.createSKPCustomer_Affiliate();
        Test.stopTest();
        
        System.Assert(TestingUtils.pageMessageContains(SKPIntegrationWizardCont.SRC_CUST_ID_MISSING));
    }
    
    public static testmethod void preValidateSKPCustomerAndContract_test()
    {
        //setup();    
        testAccount = [select id from Account limit 1];
        testProfile = [select id from Customer_Profile__c limit 1];
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
        
       	
        
        testCustomerAccount=TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
        //testCase.Source_Customer_Id__c=testCustomerAccount.Id;
        testCase.Customer_ID__c = testCustomerAccount.id;
        testCase.Customer_Profile__c = testProfile.id;
        update testCase;          
        testCaseCustomerAccount=TestingUtils.createCaseCustomerAccount(testCase.Id,testCustomerAccount.Id,true);      
        //IM_Customer_Account__c custId = [Select Id From IM_Customer_Account__c Where Id =: testCaseCustomerAccount.Customer_Account__r.Id] ;
        
        ApexPages.currentPage().getParameters().put('id', testCase.id);
        
        SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                            name='Sandbox', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test', Get_Customer_Profile__c='http://www.test.com/custProfile', Get_Contract_Info__c='http://www.test.com/contract', OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        SKP_Integration_Details__c details2 = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                             name='Production', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test', Get_Customer_Profile__c='http://www.test.com/custProfile', Get_Contract_Info__c='http://www.test.com/contract', OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        insert new List<SKP_Integration_Details__c>{details, details2};
            //Added for security Token
            HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        
        HttpCalloutMock fakeCustProfile = new MockGetCustProfile();
        HttpCalloutMock fakeContractResp = new MockGetContractResp();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('http://www.test.com/custProfile',fakeCustProfile);
        endpoint2TestResp.put('http://www.test.com/contract',fakeContractResp);
        
        
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        Test.startTest();              
        skpCont.preValidateSKPCustomerAndContract();                
        Test.stopTest();
    }
    public static testMethod void RecurringTestMethod()
    {
        system.debug('Limits method start'+limits.getQueries());
       // validateSKPCustomerAndContract_setup();
          
        testAccount = [select id from Account limit 1];
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
       
        testProfile = [select id from Customer_Profile__c limit 1];
        testScheduleA = [select id,Schedule_A__c from Quote limit 1 ];
        testOpp = [select id from opportunity limit 1];
        testCustomerAccount=TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
        testCase.Source_Customer_Id__c=testCustomerAccount.Id;
        testCase.Customer_ID__c = testCustomerAccount.id;
        testCase.Customer_Profile__c = testProfile.id;
        update testCase;        
        ApexPages.currentPage().getParameters().put('id', testCase.id);
        SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                            name='Sandbox', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test',Update_Customer_Info__c='http://www.test.com/custUpdate', Update_Contract_Info__c='http://www.test.com/contractUpdate',Get_Recurring_Charges__c='http://www.test.com/getRecurring', Update_Recurring_Charges__c='http://www.test.com/UpdateRecurring',Create_Recurring_Charges__c='http://www.test.com/CreateRecurring', OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        SKP_Integration_Details__c details2 = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                             name='Production', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test',Update_Customer_Info__c='http://www.test.com/custUpdate', Update_Contract_Info__c='http://www.test.com/contractUpdate',Get_Recurring_Charges__c='http://www.test.com/getRecurring', Update_Recurring_Charges__c='http://www.test.com/UpdateRecurring',Create_Recurring_Charges__c='http://www.test.com/CreateRecurring', OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        insert new List<SKP_Integration_Details__c>{details, details2};
        
		
        Test.setMock(HttpCalloutMock.class, new MockValidateContCallout());
        SKPRecurringChargesDetails__c skpCiDet = new SKPRecurringChargesDetails__c();
        skpCiDet.name = '3472';
        skpCiDet.Rate__c = '99.99';
        skpCiDet.BillCode__c='3472';
        skpCiDet.ProductName__c = 'RM Value Package 100';
        insert skpCiDet;
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();  
       // OpportunityTriggerHandler.skipTriggerExecutionTestClass  = false;  
        Id stdPbId = Test.getStandardPriceBookId();
        Product2 prod = TestingUtils.createProduct('3472', false);
        
        prod.IM_Unit_of_Measure__c = 'Unit of Measure';
        insert new List<Product2>{prod};
            
        PricebookEntry stdPbe = TestingUtils.createPriceBookEntry(prod.id, stdPbId, false);
        stdPbe.useStandardPrice = false;
        stdPbe.UnitPrice = 200;
        stdPbe.IsActive = true;
        insert stdPbe;
        //insert new List<PriceBookEntry>{stdPbe};
        
            system.debug('price book entry:: '+stdPbe.id + ' price book id:: '+stdPbe.Pricebook2Id);
            
        Quote scheduleA = SkpIntegrationHelper.getScheduleAs((string) testOpp.id, new List<String>(SkpIntegrationWizardCont.scheduleAFields))[0];
        scheduleA.pricebook2id = stdPbId;
        update scheduleA;
        
        system.debug('price book entry:: Schedule '+scheduleA.pricebook2id);
        
        List<QuoteLineItem> qlisLst = new List<QuoteLineItem>();
        QuoteLineItem qli = TestingUtils.createQuoteLineItem(stdPbe.id, scheduleA.id, false);
        qli.product_Number__C = 'RM Value Package 100';
        qli.Bill_Code__c = '3472';
        
        qlisLst.add(qli);
        
        QuoteLineItem qliP = TestingUtils.createQuoteLineItem(stdPbe.id, scheduleA.id, false);
        qliP.product_Number__C = 'Archival Destruction';
        qliP.Bill_Code__c = '3472';
        
        qlisLst.add(qliP);
        
        insert new List<QuoteLineItem>{qli};
        Datetime CreatedLastYear = Datetime.now().addYears(-2);
        Test.setCreatedDate(qli.Id, CreatedLastYear); 
        List<QuoteLineItem> qlis = [SELECT Id,Bill_Code__c,UnitPrice,Quantity,Product_Name__c,Unit_of_Measure__c,Base_Quantity__c,Base_Amount__c,Unit_Quantity__c FROM QuoteLineItem where  Bill_Code__c != null LIMIT 1];
        skpCont.customerIndicator = new SkpIntegrationHelper.customerIndicator(qlis, 'test version');
        System.debug(LoggingLevel.Info,'skpCont.customerIndicator=='+skpCont.customerIndicator);
        System.debug('skpCont.customerIndicator=='+skpCont.customerIndicator);
        
        testCase.contract_type__c = 'IM-38';
        NCSPRenewalRecordType = [Select Id From RecordType where Name = 'NCSP Renewal' AND SobjectType = 'Case'];
        testCase.RecordTypeId=NCSPRenewalRecordType.Id;
        // testCase.RecordTypeId='01280000000UP5s';
        update testCase;  
        
        IM_Customer_Account__c testCustomerAccount1=TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
        testCustomerAccount1.SKP_Exception_Rate_ID__c='test_data';
        update testCustomerAccount1;  
        testCaseCustomerAccount=TestingUtils.createCaseCustomerAccount(testCase.Id,testCustomerAccount1.Id,true);      
        
        
        Set<String> recCustids = new Set<String>();
        recCustids.add(testCaseCustomerAccount.Name);
        Set<String> skpOnlyWrapper = new Set<String>();  
        system.debug('Limits before start test'+limits.getQueries());
        Test.startTest();
        skpCont.processGetRecurringCharges(testCaseCustomerAccount,'X999',new Set<String>());
        skpCont.processRecurringCharges(recCustids,qlis,skpOnlyWrapper,true);
        skpCont.processRecurringCharges(recCustids,qlis,skpOnlyWrapper,false); 
        SKPGetRecurringChargesResponse res = new SKPGetRecurringChargesResponse();
        SKPContractRenewal.scaleListObj chckscaleRenewalProd = new  SKPContractRenewal.scaleListObj(qlis[0],1);
        
        Test.stopTest();
        
    }
    //Response of Security Token
    public class MockSITADSecurityTokenCallout implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            OAuthResponse tokenR = new OAuthResponse();
            tokenR.access_token = 'testSecurityToken';
            tokenR.expires_in = 3600;
            tokenR.token_type = 'testType';
            res.setBody(JSON.serialize(tokenR));
            res.setStatusCode(200);
            system.debug('+++++res'+res);
            return res;
        }
    }
    public static testMethod void coverExtra()
    {
        //setup2();
        testAccount = [select id from Account limit 1];
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
        testProfile = [select id from Customer_Profile__c limit 1];
        
        testCase.contract_type__c = 'Affiliate Option 1';
        testCase.contract_type__c = 'IM2000';
        testCase.NCSP_Service_line__c = 'One Time Shred';
        testCase.Sync_succeeded_till__c = 1;
        update testCase;
        
        test.startTest();
        ApexPages.currentPage().getParameters().put('Id', testCase.id); 
        ApexPages.currentPage().getParameters().put('debug', '1'); 
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        boolean b = skpCont.noScheduleAMessageForOptionA;
        skpCont.contractMapping = null;
        skpCont.customerID = '';
        skpCont.customerName = '';
        skpCont.districtId = '';
        skpCont.customerForValidation = null;
        skpCont.contractForValidation = null;
        system.assertNotEquals(skpCont.buttonToDisplay,'Test ');
        
        skpCont.skpCase = testCase;
        
        List<IM_Customer_Account__c> testCustomerAccount1=TestingUtils.createIMCustomerAccounts(2, testAccount.id, true);
        testCase.Customer_ID__c = testCustomerAccount1[0].id;
        testCase.Customer_Profile__c = testProfile.id;
        update testCase;          
        testCaseCustomerAccount=TestingUtils.createCaseCustomerAccount(testCase.Id,testCustomerAccount1[0].Id,true);
        Case_Customer_Account__c testCaseCustomerAccount1=TestingUtils.createCaseCustomerAccount(testCase.Id,testCustomerAccount1[1].Id,true);
        PageReference cancelPageref = skpCont.save();
        test.stopTest();
        
    }
}