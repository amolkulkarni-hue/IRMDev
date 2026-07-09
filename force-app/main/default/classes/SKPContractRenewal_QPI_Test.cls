@isTest
public class SKPContractRenewal_QPI_Test {
	public static string customerID = '12345';
    public static string districtID = 'D1234';
    public static string companyID = 'c1234';
    
    public static Account testAccount;
    public static Contact testContact;
    public static Opportunity testOpp;
    public static Case testCase;
    public static User testUser;
    public static Quote testScheduleA;
    public Quote testScheduleB;
    public static IM_Customer_Account__c imAccount;
    public static Customer_Profile__c testProfile;    
    public static IM_Customer_Account__c testCustomerAccount;
    public static Case_Customer_Account__c testCaseCustomerAccount;
    public static RecordType NCSPRenewalRecordType;
    public SkpIntegrationHelper.CustomerIndicator customerIndicator;
    
    public static string systemStringToBeReplaced = 'AMER';     
   	Public static boolean minimumStorage = false;
    Public static boolean minimumOrder = false;
    
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
        testScheduleA.RecordTypeId='01280000000UJ1AAAW';
        insert testScheduleA;
        
        Product2 productforShred = TestingUtils.createProduct('1500', true);
        
        PriceBookEntry shredPBE = TestingUtils.createPriceBookEntry(productforShred.id, standardPB, true);
        
        QuoteLineItem qliForShred = TestingUtils.createQuoteLineItem(shredPBE.id, testScheduleA.id, true);
        
        testProfile = TestingUtils.createCustomerProfile(testOpp.id, new Map<string, Object>(), true);
        SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                            name='Sandbox', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
        SKP_Integration_Details__c details2 = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                             name='Production', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
        insert new List<SKP_Integration_Details__c>{details, details2};
    }
    public static testMethod  void validateSKPCustomerAndContract_setup(){    
        testAccount = [select id from Account limit 1];
        testCase = [select id,Source_Customer_Id__c,Customer_ID__c,Customer_Profile__c from case limit 1 ];
       
        testProfile = [select id from Customer_Profile__c limit 1];
        testScheduleA = [select id,Schedule_A__c,q2w_Effective_Date__c from Quote limit 1 ];
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
    public static testMethod void multicontractCalloutAffiliate(){
        validateSKPCustomerAndContract_setup();
        testCase.contract_type__c = 'Affiliate Option 2';
        update testCase;
        SKP_Minimum_Mapping__c mapp = new SKP_Minimum_Mapping__c(name ='2476',Minimum_Level__c='CUSTOMER', 
                                             Minimum_Order_Type__c='SHREDDING OFF SITE', Minimum_Type__c='Order');
        insert mapp;
        Test.startTest();      
        SKPContractRenewal_QPI.scaleListObj chckscaleRenewal = new       SKPContractRenewal_QPI.scaleListObj
            (new QuoteLineItem(QuoteId = testScheduleA.id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1));
      	SKPContractRenewal_QPI.minimumObj minobj = new SKPContractRenewal_QPI.minimumObj(mapp);
        SKPContractRenewal_QPI.ownersObj ownrsObj = new SKPContractRenewal_QPI.ownersObj(testCustomerAccount.Id);
        SKPContractRenewal_QPI.contractSettingsObj contsetsObj = new SKPContractRenewal_QPI.contractSettingsObj('','');
        SKPContractRenewal_QPI.exceptionRateObj ExpRatObj = new SKPContractRenewal_QPI.exceptionRateObj();
        SKPContractRenewal_QPI.filterObj filtObj = new SKPContractRenewal_QPI.filterObj();
        Set<String> custIdSet=new Set<String>();
        custIdSet.add(testCustomerAccount.Id);
        testScheduleA = [select id,Schedule_A__c,q2w_Effective_Date__c,RecordTypeId from Quote limit 1 ];
        system.debug(testScheduleA);
        SKPContractRenewal_QPI skpcontren = new SKPContractRenewal_QPI(testScheduleA,'6577',custIdSet,'test123');
        Set<String> initBillCodesParam=new Set<String>();
        List<QuoteLineItem> lineItemListParam =[select id,Product_Name__c,Proposed_Price__c,Unit_of_Measure__c from QuoteLineItem];
        SKPContractRenewal_QPI.exceptionRateDetailObj excRatedetObj = new       SKPContractRenewal_QPI.exceptionRateDetailObj
            (lineItemListParam,'test123',null,null,initBillCodesParam,'6577');
        Test.stopTest();
    }
}