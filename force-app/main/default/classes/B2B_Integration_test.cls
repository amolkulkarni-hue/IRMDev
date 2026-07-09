/*Developer Name: Vijay Andrews
  Company       : Iron Mountain Services.
  Desrciption   : This is the test utility for B2B_Integration,B2B_UpdateOpportunity,B2B_CreateOpportunity
                   B2B_Response and B2B_IntegrationHelper Classes.
  Date          : 12/11/2015 */
@isTest
public class B2B_Integration_test {
    public static Account testAccount;
    //public static list <Account> testAccount1;
    //public static Contact testContact;
    //public static Opportunity testOpp;
    //public static Case testCase;
    public static User testUser;
    public static OpportunityLineItem  testOpportunityLineItem;
    public static IM_Customer_Account__c imAccount;  
    public static IM_Customer_Account__c testCustomerAccount;
    public static Product2 createProduct;
    public static Pricebook2  createPricebook;
    public static PriceBookEntry   createPriceBookEntry;
    public static Id NCSP_SKP_NEW_CUSTOMER_SETUP
    {
        get
        {
            if( NCSP_SKP_NEW_CUSTOMER_SETUP == null )
                NCSP_SKP_NEW_CUSTOMER_SETUP =Schema.SObjectType.Case.getRecordTypeInfosByName().get('NCSP: SKP New Customer Setup').getRecordTypeId();
            return NCSP_SKP_NEW_CUSTOMER_SETUP;
        }
        private set;
    }
    public static Id IME_Standard_Opportunity
    {
        get
        {
            if( IME_Standard_Opportunity == null )
                IME_Standard_Opportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IME Standard Opportunity').getRecordTypeId();
            return IME_Standard_Opportunity;
        }
        private set;
    }
    public static Id Standard_Opportunity
    {
        get
        {
            if( Standard_Opportunity == null )
                Standard_Opportunity = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();
            return Standard_Opportunity;
        }
        private set;
    }
    public static Id NA_Customer_Account
    {
        get
        {
            if( NA_Customer_Account == null )
                NA_Customer_Account = Schema.SObjectType.IM_Customer_Account__c.getRecordTypeInfosByName().get('NA Customer Account').getRecordTypeId();
            return NA_Customer_Account;
        }
        private set;
    }
    public static Id IME_Customer_Account
    {
        get
        {
            if( IME_Customer_Account == null )
                IME_Customer_Account =  Schema.SObjectType.IM_Customer_Account__c.getRecordTypeInfosByName().get('IME Customer Account').getRecordTypeId();
            return IME_Customer_Account;
        }
        private set;
    }
    @testSetup static void setup1(){
        list <Account> testAccount1 = TestingUtils.createAccounts(1, true);
        Contact testContact = TestingUtils.createContact(testAccount1[0].Id, true);
        IM_Customer_Account__C testCustomerAccount= TestingUtils.createCustomerAccount(testAccount1[0].Id,true);

        
        List<Country_Settings__c> countrySetting = new List<Country_Settings__c>();
        Country_Settings__c cS = new Country_Settings__c();
        cS.Name = 'Canada';
        cS.Object_Name__c = 'Account';
        countrySetting.add(cS);
        
        Country_Settings__c cS1 = new Country_Settings__c();
        cS1.Name = 'United States';
        cS1.Object_Name__c = 'Account';
        countrySetting.add(cS1);
        
    
        insert countrySetting;
        
    List<SVStatus__c> SVS = new List<SVStatus__c>();
    SVStatus__c sv = new SVStatus__c();
    sv.Name = 'SVStatusPassed';
    sv.Amount__c = 24000;
    sv.OpptType__c = 'New Deal,Up-Sell/Lift';
    sv.Stage__c = '6 - Setup';
        
    SVS.add(sv);
    insert SVS;
    
        List<OpportunityProductSelection__c> opprodsel = new List<OpportunityProductSelection__c >();
        OpportunityProductSelection__c ops = new OpportunityProductSelection__c();
        ops.Name = 'CloudSolutionsProduct';
        ops.Product_Class_Name__c = 'Data Backup and Recovery';
        ops.Product_Class_Name__c = 'Cloud Solutions';
        opprodsel.add(ops);
        
        insert opprodsel;
        Opportunity testOpp = new Opportunity( Name='testoppty',IM_Booked_Date__c=Date.today(),StageName = '1 - Qualification'  ,AccountId =testAccount1[0].Id,Group_Purchasing_Organization_GPO__c='HealthTrust',IME_Vended_Unvended__c='Unknown');
         testOpp.CloseDate=Date.today();
        insert testOpp;
    
    
    Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);
        insert customPB;
    Id standardPB = Test.getStandardPricebookId();
        List<Product2> testProducts = new List<Product2>();
        for(Integer i=0; i < 5; i++)
        {
          Product2 testProduct = TestingUtils.createProduct('Test Product'+i, false);
          testProducts.add(testProduct);
        }
        insert testProducts;
        PricebookEntry stdPbe = new PricebookEntry();
        PricebookEntry testPbe = new PricebookEntry();
        for(Integer i=0; i < 5; i++)
        {
          stdPbe =  TestingUtils.createPriceBookEntry(testProducts[i].Id,standardPB, false);
      stdPbe.useStandardPrice = false;
      stdPbe.UnitPrice = 200;
      stdPbe.IsActive = true;
      insert stdPbe;
               
          testPbe = TestingUtils.createPriceBookEntry(testProducts[i].Id,customPB.id, false);
            testPbe.useStandardPrice = false;
            testPbe.currencyisocode ='USD';
      testPbe.UnitPrice = 100;
      testPbe.IsActive = true;
      insert testPbe;

        }
    
        /*testOpp.Type='Up-Sell/Lift';
        testOpp.Upsell_Customer_ID__c = testCustomerAccount.id;
       
        testOpp.RecordTypeId=IME_Standard_Opportunity.Id;
        testopp.IM_Servicing_Region__c='London';
        testopp.Source_System__c='SKP Europe';
        testopp.IM_Up_Sell_Detail__c='test';
        testopp.IM_Up_Sell_Quantity__c=10;
        testopp.IM_Unit_of_Measure__c='Cubic Ft';
        testopp.IM_Up_Sell_Sold_To__c='22DMN';
        testopp.IME_Reason_Won__c='Service';
    testopp.Primary_Product_Line__c = 'Data Centers';
        update testOpp;*/
        Case testCase = TestingUtils.createCase(testOpp, testContact, true);
        
        B2BIntegration__c details = new B2BIntegration__c(Username__c ='Test',Password__c='Royal', 
                                             name='Sandbox', Create_Opportunity__c='www.test.iron.com', Update_Opportunity__c='www.test.iron.com',OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        B2BIntegration__c details1 = new B2BIntegration__c(Username__c ='Test1',Password__c='Enfield', 
                                             name='Production', Create_Opportunity__c='www.test.iron.com', Update_Opportunity__c='www.test.iron.com',OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        insert new List<B2BIntegration__c>{details,details1};
    
    }
 
    //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
  /* public static void setup(){
        list<Account> testAccount = TestingUtils.createAccounts(2, true);
        system.debug('account'+testAccount[0].id);
        testContact = TestingUtils.createContact(testAccount[0].Id, true);
        testCustomerAccount= TestingUtils.createCustomerAccount(testAccount[0].Id,true);
         /*system.debug('kkkkkkkkk'+testAccount[0].Id);
        testCustomerAccount.IM_Account__c=testAccount[0].Id;
        testCustomerAccount.IM_Customer_Account_Name__c='testaccountname';
        testCustomerAccount.Source_System__c ='SKP Europe';
        testCustomerAccount.IM_Status__c='Active';
        testCustomerAccount.NA_CY_YTD_Film_Sound__c=10;
        testCustomerAccount.NA_PY_YTD_Secure_Shredding__c=10;
        testCustomerAccount.RecordTypeId=IME_Customer_Account.Id;
        update testCustomerAccount;*/
         //IM_Customer_Account__c custAcc = createCustomerAccount('101' , 'Test');
         /*
        List<Country_Settings__c> countrySetting = new List<Country_Settings__c>();
        Country_Settings__c cS = new Country_Settings__c();
        cS.Name = 'Canada';
        cS.Object_Name__c = 'Account';
        countrySetting.add(cS);
        
        Country_Settings__c cS1 = new Country_Settings__c();
        cS1.Name = 'United States';
        cS1.Object_Name__c = 'Account';
        countrySetting.add(cS1);
        
        insert countrySetting;
        
		List<SVStatus__c> SVS = new List<SVStatus__c>();
		SVStatus__c sv = new SVStatus__c();
		sv.Name = 'SVStatusPassed';
		sv.Amount__c = 24000;
		sv.OpptType__c = 'New Deal,Up-Sell/Lift';
		sv.Stage__c = '6 - Setup';
        
		SVS.add(sv);
		insert SVS;
		
         List<OpportunityProductSelection__c> opprodsel = new List<OpportunityProductSelection__c >();
        OpportunityProductSelection__c ops = new OpportunityProductSelection__c();
        ops.Name = 'CloudSolutionsProduct';
        ops.Product_Class_Name__c = 'Data Backup and Recovery';
        ops.Product_Class_Name__c = 'Cloud Solutions';
        opprodsel.add(ops);
        
        insert opprodsel;
        testOpp = new Opportunity( Name='testoppty',IM_Booked_Date__c=Date.today(),StageName = '1 - Qualification'  ,AccountId =testAccount[0].Id,Group_Purchasing_Organization_GPO__c='HealthTrust',IME_Vended_Unvended__c='Unknown');
         testOpp.CloseDate=Date.today();
        insert testOpp;
        
        
    Pricebook2 customPB = new Pricebook2(Name='North America', isActive=true);
        insert customPB;
    Id standardPB = Test.getStandardPricebookId();
        List<Product2> testProducts = new List<Product2>();
        for(Integer i=0; i < 5; i++)
        {
          Product2 testProduct = TestingUtils.createProduct('Test Product'+i, false);
          testProducts.add(testProduct);
        }
        insert testProducts;
        PricebookEntry stdPbe = new PricebookEntry();
        PricebookEntry testPbe = new PricebookEntry();
        for(Integer i=0; i < 5; i++)
        {
          stdPbe =  TestingUtils.createPriceBookEntry(testProducts[i].Id,standardPB, false);
      stdPbe.useStandardPrice = false;
      stdPbe.UnitPrice = 200;
      stdPbe.IsActive = true;
      insert stdPbe;
               
          testPbe = TestingUtils.createPriceBookEntry(testProducts[i].Id,customPB.id, false);
            testPbe.useStandardPrice = false;
            testPbe.currencyisocode ='USD';
      testPbe.UnitPrice = 100;
      testPbe.IsActive = true;
      insert testPbe;

        }
    
        testOpp.Type='Up-Sell/Lift';
        testOpp.Upsell_Customer_ID__c = testCustomerAccount.id;
       
        testOpp.RecordTypeId=IME_Standard_Opportunity.Id;
        testopp.IM_Servicing_Region__c='London';
        testopp.Source_System__c='SKP Europe';
        testopp.IM_Up_Sell_Detail__c='test';
        testopp.IM_Up_Sell_Quantity__c=10;
        testopp.IM_Unit_of_Measure__c='Cubic Ft';
        testopp.IM_Up_Sell_Sold_To__c='22DMN';
        testopp.IME_Reason_Won__c='Service';
    testopp.Primary_Product_Line__c = 'Data Centers';
        update testOpp;
        testCase = TestingUtils.createCase(testOpp, testContact, true);
    /*  createProduct=TestingUtils.createProduct('testproduct',true);
        pricebook2 standardpb = [select id from pricebook2 where isstandard = true limit 1];
        Pricebook2 standardpb = new Pricebook2(Name='pbName',isstandard= true);
        insert standardpb;
        createPricebook=TestingUtils.createPriceBook('testproduct',true);
        pricebookentry standardprice = new pricebookentry( product2id = createProduct.id, pricebook2id = standardpb.id, unitprice = 4.99,IsActive = true), customprice = new pricebookentry( product2id = createProduct.id, pricebook2id = createPricebook.id, usestandardprice = true ,unitprice = 4.99,IsActive = true);
        insert standardprice;
        insert customprice;
        testOpportunityLineItem=TestingUtils.createOLI(standardprice.Id,testOpp.Id,true);
     
        
        B2BIntegration__c details = new B2BIntegration__c(Username__c ='Test',Password__c='Royal', 
                                             name='Sandbox', Create_Opportunity__c='www.test.iron.com', Update_Opportunity__c='www.test.iron.com',OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        B2BIntegration__c details1 = new B2BIntegration__c(Username__c ='Test1',Password__c='Enfield', 
                                             name='Production', Create_Opportunity__c='www.test.iron.com', Update_Opportunity__c='www.test.iron.com',OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        insert new List<B2BIntegration__c>{details,details1};
    }*/
    
    static testmethod void opportunityTest(){
        //setup1();
        Test.setMock(HttpCalloutMock.class, new MockSkpCreateopportunityCallout());
        Opportunity testOpp=[select id,name from opportunity limit 1];
        Test.startTest();
        B2B_Integration.create_opportunity(testOpp.Id,true);
        B2B_Integration.update_opportunity(testOpp.Id,false);
        //Opportunity resultOpportunity = B2B_Integration.queryopportunity(testOpp.Id);
        Test.stopTest();
        //Opportunity returnedOpportunity = [Select id, SKP_Opportunity_Sync_Date__c from Opportunity where ID =: testOpp.Id];
        //System.AssertNotEquals(null, returnedOpportunity.SKP_Opportunity_Sync_Date__c, 'A date must be set');
    }
    static testmethod void opportunity_newdealNATest(){
        //setup1();
        //system.debug('limit queries after setup1 in newdeal '+limits.getQueries());
        Opportunity testopp=[select id,name,type,recordtypeid from opportunity limit 1];
        testOpp.type = 'New Deal';
        testOpp.RecordTypeId=Standard_Opportunity;
        //system.debug('limit queries before starttest in newdeal '+limits.getQueries());
        Test.startTest();

        update testopp;
        //system.debug('limit queries after update'+limits.getQueries());
        Case testCase=[select id,NCSP_Opportunity__c,SKP_Customer_Sync_Date__c,
                       contract_type__c,AccountId,Customer_ID__c,RecordTypeId from  Case limit 1];
        Account testAccount1=[select id from Account limit 1];
        IM_customer_Account__c testCustomerAccount =[select id from IM_Customer_Account__c limit 1];
        testCase.NCSP_Opportunity__c = testOpp.id;
        testCase.SKP_Customer_Sync_Date__c = Date.today();
        testCase.contract_type__c = 'test version';
        testCase.AccountId = testAccount1.id;
        testCase.Customer_ID__c=testCustomerAccount.id;
        testCase.RecordTypeId=NCSP_SKP_NEW_CUSTOMER_SETUP;
        update testCase;  
    
        
        //Test.setMock(HttpCalloutMock.class, new MockSkpCreateopportunityCallout());
       
         //For Security Token
        HttpCalloutMock fakeSecurityToken = new MockSecurityTokenCallout();
        HttpCalloutMock oppCall = new MockSkpCreateopportunityCallout();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('www.test.iron.com',oppCall);
        
        HttpCalloutMock multiCalloutMock = new MultiRequestMock (endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);      
        
        B2B_Integration.create_opportunity(testOpp.Id,true);
        B2B_Integration.update_opportunity(testOpp.Id,false);
        Test.stopTest();
    }
    static testmethod void opportunity_newdealEuropeTest(){
        //setup1();
    	Test.startTest();
        Opportunity testopp=[select id,name,type,recordtypeid,Primary_Product_Line__c from opportunity limit 1];

        testOpp.type = 'New Deal';
    	testOpp.RecordTypeId=IME_Standard_Opportunity;
    	testopp.Primary_Product_Line__c = 'Data Centers';
        update testopp; 
    /*testCase.NCSP_Opportunity__c = testOpp.id;
        testCase.SKP_Customer_Sync_Date__c = Date.today();
        testCase.contract_type__c = 'test version';
        testCase.AccountId = testAccount1[0].id;
        testCase.Customer_ID__c=testCustomerAccount.id;
        testCase.RecordTypeId=NCSP_SKP_NEW_CUSTOMER_SETUP.Id;
        update testCase; */  
         
         //For Security Token
        HttpCalloutMock fakeSecurityToken = new MockSecurityTokenCallout();
        HttpCalloutMock oppCall = new MockSkpCreateopportunityCallout();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('www.test.iron.com',oppCall);
        
        HttpCalloutMock multiCalloutMock = new MultiRequestMock (endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
         
       // Test.setMock(HttpCalloutMock.class, new MockSkpCreateopportunityCallout());
        //Test.startTest();
        B2B_Integration.create_opportunity(testOpp.Id,true);
        B2B_Integration.update_opportunity(testOpp.Id,false);
        Test.stopTest();
    }
    
     public class MultiRequestMock  implements HttpCalloutMock {
        Map<String, HttpCalloutMock> requests;
    
        public MultiRequestMock (Map<String, HttpCalloutMock> requests) {
            this.requests = requests;
        }
    
        public HTTPResponse respond(HTTPRequest req) {
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
    
    //Response of Security Token
    public class MockSecurityTokenCallout implements HttpCalloutMock{
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
    
    static testmethod void opportunityerrorsTest(){
        //setup1();
        Opportunity testopp=[select id,name,type,recordtypeid,Primary_Product_Line__c,SKP_Opportunity_Sync_Date__c from opportunity limit 1];

        testopp.SKP_Opportunity_Sync_Date__c=system.now();
        
        Test.startTest();

        update testOpp;
        //Test.setMock(HttpCalloutMock.class, new MockSKPFailures());
        
        //For Security Token
        HttpCalloutMock fakeSecurityToken = new MockSecurityTokenCallout();
        HttpCalloutMock oppCall = new MockSKPFailures();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login', fakeSecurityToken);
        endpoint2TestResp.put('www.test.iron.com',oppCall);
        
        HttpCalloutMock multiCalloutMock = new MultiRequestMock (endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);  
        
        B2B_Integration.create_opportunity(testOpp.Id,true);
        B2B_Integration.update_opportunity(testOpp.Id,false);
        Test.stopTest();
    }
    
    static testMethod void handleSKPResponseTest(){
        //setup1();
        Test.StartTest();

        B2B_Response.CodeAndMessage errorMessage = new B2B_Response.CodeAndMessage();
        errorMessage.Code ='401';
        errorMessage.message ='Error occurred';
        
        B2B_Response.CodeAndMessage warningMessage = new B2B_Response.CodeAndMessage();
        warningMessage.Code ='400';
        warningMessage.message = 'Warning, there is a warning.';
        
        B2B_Response responseWithErrors = new B2B_Response();
        responseWithErrors.errors = new List<B2B_Response.CodeAndMessage>{errorMessage};
        responseWithErrors.warnings = new List<B2B_Response.CodeAndMessage>{warningMessage};
        responseWithErrors.success = false;
        
        B2B_Response responseWithWarnings = new B2B_Response();
        responseWithWarnings.errors = new List<B2B_Response.CodeAndMessage>();
        responseWithWarnings.warnings = new List<B2B_Response.CodeAndMessage>{warningMessage};
        responseWithWarnings.success = true;
         Opportunity testopp=[select id from Opportunity limit 1];
        SKP_Manage_Opportunity_Errors__c expectedError = new SKP_Manage_Opportunity_Errors__c(Error_Code__c = errorMessage.code, Error_Description__c = errorMessage.message, Severity__c='Error', Opportunity__c = testOpp.id, Step_Name__c='create');
        SKP_Manage_Opportunity_Errors__c expectedWarning = new SKP_Manage_Opportunity_Errors__c(Error_Code__c = warningMessage.code, Error_Description__c = warningMessage.message, Severity__c='Warning', Opportunity__c = testOpp.id, Step_Name__c='create'); 
        Set<SKP_Manage_Opportunity_Errors__c> expectedSyncErrors = new Set<SKP_Manage_Opportunity_Errors__c>{expectedError, expectedWarning};
            
        
     /*       B2B_Integration.handleB2BResponse(responseWithErrors, true);
            
            B2B_Integration.handleB2BResponse(responseWithWarnings, false);
            
            B2B_Integration.handleB2BResponse(responseWithSuccess, false);
      */      
        Test.stopTest();
        
        
        List<SKP_Manage_Opportunity_Errors__c> errors = [Select error_code__c, error_description__c, severity__c, Opportunity__c from SKP_Manage_Opportunity_Errors__c];
        System.AssertEquals(0, errors.size(), 'An incorrect number of errors returned');
        
        
       // List<SKP_Manage_Opportunity_Errors__c> actualErrors = [Select error_code__c, error_description__c, severity__c, Opportunity__c from SKP_Manage_Opportunity_Errors__c];
    //    System.AssertEquals(0, actualErrors.size(), 'An incorrect number of errors returned');
        
     //   actualErrors[0].id = actualErrors[1].id = null; // We don't have access to the actual Ids, but want to assert that the rest of the values are correct.  
     //   System.AssertEquals(expectedSyncErrors, new set<SKP_Manage_Opportunity_Errors__c>(actualErrors), 'Incorrect  errors returned');
        
    }
    
    public class MockSkpCreateopportunityCallout implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            B2B_Response successfulSKPResponse = new B2B_Response();
            successfulSKPResponse.success = true;
            res.setBody(JSON.serialize(successfulSKPResponse));
            res.setStatusCode(201);
            return res;
        }
    }
    public class MockSKPFailures implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            B2B_Response failedSKPResponse = new B2B_Response();
            B2B_Response.CodeAndMessage skpError = new B2B_Response.CodeAndMessage();
            skpError.code = '401';
            skpError.message='error';
            B2B_Response.CodeAndMessage skpWarning = new B2B_Response.CodeAndMessage();
            skpError.code = '101';
            skpError.message='warning';
            failedSKPResponse.errors = new List<B2B_Response.CodeAndMessage>{skpError};  
            failedSKPResponse.warnings = new List<B2B_Response.CodeAndMessage>{skpWarning};  
            failedSKPResponse.success = false;
            res.setBody(JSON.serialize(failedSKPResponse));
            res.setStatusCode(200);
            return res;
        }
    }
    public class UnauthorizedEndpointResponse implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest request) {
        CalloutException e = (CalloutException)CalloutException.class.newInstance();
        e.setMessage('Unauthorized endpoint.');
        throw e;
      }
  }
  
 
  
  
}