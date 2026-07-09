@isTest
public class SKPCalloutsTest {

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
    
    
    /************* Setup method for all **********/
    
     public static void setup(){
        testAccount = TestingUtils.createAccounts(1, true)[0];
        testContact = TestingUtils.createContact(testAccount.Id, false);
        testContact.FirstName = 'testClassContact';
        insert testContact;
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();
        oppprodsel.Name = 'CloudSolutionsProduct';
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              
        insert oppprodsel;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
         
        testOpp = TestingUtils.createOpportunity('test_Opp', testAccount.Id, true);
        testUser = TestingUtil.createUser();
        testCase = TestingUtils.createCase(testOpp, testContact, true);
        testCase.contract_type__c = 'IM2000';
        
        testScheduleA = TestingUtils.createQuotes(testOpp.id, 1, false)[0];
        
        
        testProfile = TestingUtils.createCustomerProfile(testOpp.id, new Map<string, Object>(), true);
        SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies', 
                                             name='Sandbox', Customer_Endpoint__c='www.test.com/test', Contract_Endpoint__c='www.test.com/test', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
        SKP_Integration_Details__c details2 = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies', 
                                             name='Production', Customer_Endpoint__c='www.test.com/test', Contract_Endpoint__c='www.test.com/test', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
        insert new List<SKP_Integration_Details__c>{details, details2};
            
        SKP_Excluded_Billcodes__c billcodes = new SKP_Excluded_Billcodes__c(name='318');
         insert billcodes;    
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
    
    /************* method for SKPContract **********/
    
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
    
    public class MockGetCustContract implements HttpCalloutMock {
        Map<String, HttpCalloutMock> requests;
    
        public MockGetCustContract(Map<String, HttpCalloutMock> requests) {
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
    
 static testmethod void contractCalloutTest(){
        
        setup();
         
        SKP_Contract_Type_Mapping__c expectedMapping = TestingUtils.createSkpMappingObject('USA', 'test version', false);
        SKP_Contract_Type_Mapping__c otherMapping = TestingUtils.createSkpMappingObject('USA', 'Other version', false);
        insert new List<SKP_Contract_Type_Mapping__c>{expectedMapping, otherMapping};
            
        testScheduleA.Status = 'Accepted';
        insert testScheduleA; 
        imAccount = TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
        
        testCase.NCSP_Opportunity__c = testOpp.id;
        testCase.SKP_Customer_Sync_Date__c = Date.today();
        testCase.Customer_ID__c = imAccount.id;
        testCase.contract_type__c = 'test version';
        testCase.Customer_Profile__c = testProfile.id;
        
        update testCase;
            
        Test.startTest();         
        ApexPages.currentPage().getParameters().put('id', testCase.id);
        
        Product2 testProd = new Product2(Name = '2011', IsActive= true );
        insert testProd;
        
        List<Quote> scheduleAs = [Select Name, id, Effective_Date__c from Quote where Opportunityid =: testOpp.Id];
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
                
        Quote scheduleA = SkpIntegrationHelper.getScheduleAs( (string) testOpp.id, new List<String>(SkpIntegrationWizardCont.scheduleAFields))[0];
        system.debug('scheduleA=='+scheduleA);
        QuoteLineItem qli1 = new QuoteLineItem(QuoteId = scheduleA.id, Product2Id=testProd.id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1);
        
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
         qlis.add(qli1);  
        
        Set<String> billCodes = new Set<String>();
        billCodes.add('2011');
        Set<String> initBillCodes = new Set<String>();
            
            for (String billCode : billCodes){
                string standardBillCode = SkpIntegrationHelper.cleanBillCode(billcode);
               
                  if(SkpIntegrationHelper.isInitBillCode(billCode)){
                    initBillCodes.add(standardBillCode);
                }
            }
        
        string effectiveDateString = system.now().format('yyyy/MM/dd');
        string nextQuarterDateString = system.now().addMonths(3).format('yyyy/MM/dd','GMT-04:00');
        
        SKPContract.scaleListObj chckscale = new SKPContract.scaleListObj(qli1,1);
        SKPContract.exceptionRateDetailObj exeDetObj = new SKPContract.exceptionRateDetailObj(qlis, '12345', 'SFEXP', effectiveDateString, nextQuarterDateString, initBillCodes,1,2,1);
        SKPContract.exceptionRateObj exeObj = new SKPContract.exceptionRateObj(qli1, effectiveDateString, nextQuarterDateString, initBillCodes,1,1);
        
        skpCont.customerIndicator = new SkpIntegrationHelper.customerIndicator(scheduleA.quoteLineItems, 'test version');
        
        //For Security Token
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        HttpCalloutMock contCall = new MockSkpContractCallout();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('www.test.iron.com',contCall);
        
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
     
            skpCont.validateSKPContract();
            skpCont.createSKPContract();
        Test.stopTest();        
        
    }
   
    /************* Method for SKPContractAffiliateOption1 ****/
    
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
    
    public static testMethod void validateSKPCustomerAndContract_setup(){
        setup();    
        testCustomerAccount=TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
        testCase.Source_Customer_Id__c=testCustomerAccount.Id;
        testCase.Customer_ID__c = testCustomerAccount.id;
        testCase.Customer_Profile__c = testProfile.id;
        update testCase;        
        ApexPages.currentPage().getParameters().put('id', testCase.id);
        
        SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies', 
                                             name='Sandbox', Customer_Endpoint__c='www.test.com/test', Contract_Endpoint__c='www.test.com/test',Update_Customer_Info__c='www.test.com/custUpdate', Update_Contract_Info__c='www.test.com/contractUpdate',Get_Recurring_Charges__c='www.test.com/getRecurring', Update_Recurring_Charges__c='www.test.com/UpdateRecurring',Create_Recurring_Charges__c='www.test.com/CreateRecurring', OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        SKP_Integration_Details__c details2 = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies', 
                                             name='Production', Customer_Endpoint__c='www.test.com/test', Contract_Endpoint__c='www.test.com/test',Update_Customer_Info__c='www.test.com/custUpdate', Update_Contract_Info__c='www.test.com/contractUpdate',Get_Recurring_Charges__c='www.test.com/getRecurring', Update_Recurring_Charges__c='www.test.com/UpdateRecurring',Create_Recurring_Charges__c='www.test.com/CreateRecurring', OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        insert new List<SKP_Integration_Details__c>{details, details2};
        testScheduleA.Status = 'Accepted';  
        
        List<Schedule_A__c> sch = TestingUtils.createPAModels(1, true);
       sch[0].RM_Contract_Length__c = 10;
        sch[0].SS_Contract_Length__c  = 1;
        //sch[0].New_Storage_Volume__c = 450;
        update sch[0];

        
       /* Schedule_A__c sch = TestingUtils.createPAModels(1, false)[0];
        sch.RM_Contract_Length__c = 10;
        sch.SS_Contract_Length__c  = 1;
        insert sch; */
                
        testScheduleA.Schedule_A__c = sch[0].id;
        insert testScheduleA;
        
        List<Quote> scheduleAs = [Select Name, id, Effective_Date__c from Quote where Opportunityid =: testOpp.Id];    
       // SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
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
        endpoint2TestResp.put('www.test.iron.com',mockValcall);
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        
         
        testCase.contract_type__c = 'Affiliate Option 1';
        update testCase;   
            
        Test.startTest();   
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont(); 
         
        SKPContractAffiliateOption1.customerNotificationObj custObj = new SKPContractAffiliateOption1.customerNotificationObj(testCase);
                 
            skpCont.validateSKPCustomerAndContract();     
            skpCont.createSKPCustomer();
            skpCont.createSKPContract();
            skpCont.validateSKPContract();
        Test.stopTest();
        
    }   
    
    
    /*************** Affiliate option 2********/
    
     public static testMethod void validateSKPCustomerAndContract_test_option2()
     {
        validateSKPCustomerAndContract_setup();
        //
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        HttpCalloutMock valCallOut = new MockValidateCallout();
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('www.test.iron.com',valCallOut);
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        testCase.contract_type__c = 'Affiliate Option 2';
        update testCase;    
         
        Test.startTest();  
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont(); 
               
        Quote scheduleA = SkpIntegrationHelper.getScheduleAs( (string) testOpp.id, new List<String>(SkpIntegrationWizardCont.scheduleAFields))[0];
        system.debug('scheduleA=='+scheduleA);
        QuoteLineItem qli1 = new QuoteLineItem(QuoteId = scheduleA.id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1);
        
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        qlis.add(qli1);  
        
        Set<String> billCodes = new Set<String>();
        billCodes.add('2011');
        Set<String> initBillCodes = new Set<String>();
            
            for (String billCode : billCodes){
                string standardBillCode = SkpIntegrationHelper.cleanBillCode(billcode);
               
                  if(SkpIntegrationHelper.isInitBillCode(billCode)){
                    initBillCodes.add(standardBillCode);
                }
            }
        
        string effectiveDateString = system.now().format('yyyy/MM/dd');
        string nextQuarterDateString = system.now().addMonths(3).format('yyyy/MM/dd','GMT-04:00');
         
        SKPContractAffiliateOption2.scaleListObj chckscale = new SKPContractAffiliateOption2.scaleListObj(qli1,1);
        SKPContractAffiliateOption2.exceptionRateDetailObj exeDetObj = new SKPContractAffiliateOption2.exceptionRateDetailObj(qlis, '12345', 'SFEXP', effectiveDateString, nextQuarterDateString, initBillCodes,1,2,1);
        SKPContractAffiliateOption2.exceptionRateObj exeObj = new SKPContractAffiliateOption2.exceptionRateObj(qli1, effectiveDateString, nextQuarterDateString, initBillCodes,1,1);
        SKPContractAffiliateOption2.customerNotificationObj custObj = new SKPContractAffiliateOption2.customerNotificationObj(testCase);

                    
            skpCont.validateSKPCustomerAndContract();     
            skpCont.createSKPCustomer();
            skpCont.createSKPContract();
            skpCont.validateSKPContract();
        Test.stopTest();
    }
    
    /******************** SKPContractUpdate ************/
     public class MockUpdateContractUpdate implements HttpCalloutMock{
        
        public HTTPResponse respond (httpRequest req){
            
            
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
    
  public static testMethod void multicontractCalloutAffiliate(){
        validateSKPCustomerAndContract_setup();
        testCase.contract_type__c = 'Affiliate Option 2';
        update testCase;
         Test.startTest();    
        ApexPages.currentPage().getParameters().put('id', testCase.id);
        
        SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont();
        
        HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
        HttpCalloutMock mockContractUp = new MockUpdateContractUpdate();
        
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
        endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        endpoint2TestResp.put('www.test.iron.com',mockContractUp);
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        
        SKP_Minimum_Mapping__c mapp = new SKP_Minimum_Mapping__c(name ='2476',Minimum_Level__c='CUSTOMER', 
                                             Minimum_Order_Type__c='SHREDDING OFF SITE', Minimum_Type__c='Order');
        
        Quote scheduleA = SkpIntegrationHelper.getScheduleAs( (string) testOpp.id, new List<String>(SkpIntegrationWizardCont.scheduleAFields))[0];
        system.debug('scheduleA=='+scheduleA);
       
        QuoteLineItem qli1 = new QuoteLineItem(QuoteId = scheduleA.id, UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,
		Unit_Quantity__c=10,Unit_Rate__c=1);
        
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        qlis.add(qli1);  
        
        String contractVersion = 'v1';  
        
        SkpIntegrationHelper.CustomerIndicator indicator = new SkpIntegrationHelper.CustomerIndicator(qlis, contractVersion);
    indicator.bundledIndicator = true;
       
       SKP_Contract_Type_Mapping__c mapping = [SELECT Id,Effective_Date__c,Non_Standard_Version__c,Next_Increase_Date_Storage_and_Service__c,Late_Fee_Percent__c,Initial_Term__c,Indemnification_Iron_Mountain__c,Indemnification_Customer__c,Rate_Increase_Notice__c,Net_Payment__c,LOL_UOM__c,Late_Fee_Indicator__c,Insurance_Special__c,Renewal_term__c,Admin_Fee_Reason_Code__c,Contract_Version__c,Country__c,District_Rate_Schedule__c
                                                ,Excess_Value_of_Deposit__c,Increase_Cap_Quoted__c,Name,RM_Admin_Fee__c,UOM__c,Fuel_Surcharge_Indicator__c FROM SKP_Contract_Type_Mapping__c LIMIT 1];
        indicator.bundledIndicator = true;
       Set<String> billCodes = new Set<String>();
        billCodes.add('2011');
        Set<String> initBillCodes = new Set<String>();
            
            for (String billCode : billCodes){
                string standardBillCode = SkpIntegrationHelper.cleanBillCode(billcode);
               
                  if(SkpIntegrationHelper.isInitBillCode(billCode)){
                    initBillCodes.add(standardBillCode);
                }
            }
        
        string effectiveDateString = system.now().format('yyyy/MM/dd');
        string nextQuarterDateString = system.now().addMonths(3).format('yyyy/MM/dd','GMT-04:00');
         
        SKPContractUpdate.scaleListObj chckscale = new SKPContractUpdate.scaleListObj(qli1,1);
           SKPContractUpdate.exceptionRateDetailObj exeDetObj = new SKPContractUpdate.exceptionRateDetailObj(qlis, '12345', 'SFEXP', effectiveDateString, nextQuarterDateString, initBillCodes,1,2,1);
             SKPContractUpdate.exceptionRateObj exeObj = new SKPContractUpdate.exceptionRateObj(qli1, effectiveDateString, nextQuarterDateString, initBillCodes,1,1);
         SKPContractUpdate.minimumObj minobj = new SKPContractUpdate.minimumObj(mapp);
        
        //SKPContractUpdate.customerNotificationObj custObj = new SKPContractUpdate.customerNotificationObj(testCase);
       //skpCont.createSKPContract();
            skpCont.wrappers[0].ischecked = true;
            skpCont.multiYearContractUpdate();
         
       SKPContractUpdate contractUpdate = new SKPContractUpdate(testCase, scheduleA, mapping, indicator, true, '12345', 'Test Customer', '12345', 1);
        System.debug('Minimum List Size: ' + contractUpdate.updateDetails.contractDetails.minimum.size());

        Test.stopTest();
       System.assert(contractUpdate.updateDetails.contractDetails.businesstype == 'BUNDLED PROGRAMS', 'Business type should be set to BUNDLED PROGRAMS'); 
    }
    
    public static testMethod void multicontractCallout(){
    validateSKPCustomerAndContract_setup();
    testCase.contract_type__c = 'IM-38';
    update testCase;
     /*IM_Customer_Account__c testCustomerAccount1=TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
         testCustomerAccount1.SKP_Exception_Rate_ID__c='test_data';
         update testCustomerAccount1;   
         testCaseCustomerAccount=TestingUtils.createCaseCustomerAccount(testCase.Id,testCustomerAccount1.Id,true); */      

  Test.startTest(); 
   SKP_Minimum_Mapping__c mapp = new SKP_Minimum_Mapping__c(name ='2476',Minimum_Level__c='CUSTOMER', 
                                             Minimum_Order_Type__c='SHREDDING OFF SITE', Minimum_Type__c='Order');
    //insert minimumMapping;
    System.debug('Minimum Mapping Created: ' + mapp.Name);
    Product2 testProd = new Product2(Name = '3472', IsActive= true,IM_Unit_of_Measure__c = 'Each',IM_Product_Class__c='Data Backup and Recovery',Schedule_A_Category__c='Custom Storage and Services');
        insert testProd;
        
         testProd = [select id,Name,IsActive,IM_Unit_of_Measure__c,IM_Product_Class__c,Schedule_A_Category__c,Category_Abreviation__c from Product2];

  Quote scheduleA = SkpIntegrationHelper.getScheduleAs( (string) testOpp.id, new List<String>(SkpIntegrationWizardCont.scheduleAFields))[0];
    
 Id pricebookId = Test.getStandardPricebookId();
         
         PricebookEntry pbe = new PricebookEntry(Product2Id = testProd.Id, pricebook2Id = pricebookId, unitprice=100, isActive=true);
         insert pbe;
                 QuoteLineItem qli1 = new QuoteLineItem(QuoteId = scheduleA.id, Product2Id=testProd.id,
                                               UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,
                                                Unit_Quantity__c=10,Unit_Rate__c=1,PricebookEntryId = pbe.Id);
     
        Quote scheduleA_requeried = [SELECT Id, (SELECT Id, Product_Name__c FROM QuoteLineItems) 
                              FROM Quote WHERE Id = :scheduleA.Id];
       System.debug(scheduleA_requeried.QuoteLineItems);

 List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        qlis.add(qli1); 
     
       Set<String> billCodes = new Set<String>();
        billCodes.add('2011');
        Set<String> initBillCodes = new Set<String>();
            
            for (String billCode : billCodes){
                string standardBillCode = SkpIntegrationHelper.cleanBillCode(billcode);
               
                  if(SkpIntegrationHelper.isInitBillCode(billCode)){
                    initBillCodes.add(standardBillCode);
                }
            }
         string effectiveDateString = system.now().format('yyyy/MM/dd');
        string nextQuarterDateString = system.now().addMonths(3).format('yyyy/MM/dd','GMT-04:00');
        testOpp.Sales_Rep_Percent__c = 5;
        update testOpp;
               
        SKPContractUpdate.scaleListObj chckscale = new SKPContractUpdate.scaleListObj(qli1,1);
        SKPContractUpdate.exceptionRateDetailObj exeDetObj = new SKPContractUpdate.exceptionRateDetailObj(qlis, '12345', 'SFEXP', effectiveDateString, nextQuarterDateString, initBillCodes,1,2,1);
       SKPContractUpdate.exceptionRateObj exeObj = new SKPContractUpdate.exceptionRateObj(qli1, effectiveDateString, nextQuarterDateString, initBillCodes,1,1);
       SKPContractUpdate.minimumObj minobj = new SKPContractUpdate.minimumObj(mapp); 
      
        SKPContractUpdate.salesCommissionObj salObj = new SKPContractUpdate.salesCommissionObj(testProfile,true,'SALES');
             //For Security Token
         HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
         
         //HttpCalloutMock fakeCustProfile = new MockValidateCallout();
         HttpCalloutMock fakeContractResp = new MockUpdateContract();
         
         Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
         
         endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        // endpoint2TestResp.put('www.test.com/custUpdate',fakeCustProfile);
         endpoint2TestResp.put('www.test.com/contractUpdate',fakeContractResp);
         
         HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
         Test.setMock(HttpCalloutMock.class, multiCalloutMock);
         
         SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont(); 
          
          skpCont.contractMultiCallout(5);
    Test.stopTest();
   
}
  /*********** Renegotiation ***********/
    
     public class MockUpdateContract implements HttpCalloutMock{
        
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
    
    public static testMethod void validateSKPCustomerAndContract_test_NCSP_renego()
     {
         validateSKPCustomerAndContract_setup1();   
          
         testCase.contract_type__c = 'IM-38';
         NCSPRenewalRecordType = [Select Id From RecordType where Name = 'NCSP Renewal' AND SobjectType = 'Case'];
         testCase.RecordTypeId=NCSPRenewalRecordType.Id;
        // testCase.RecordTypeId='01280000000UP5s';
         update testCase;   
         
         IM_Customer_Account__c testCustomerAccount1=TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
         testCustomerAccount1.SKP_Exception_Rate_ID__c='test_data';
         update testCustomerAccount1;   
         testCaseCustomerAccount=TestingUtils.createCaseCustomerAccount(testCase.Id,testCustomerAccount1.Id,true);       

        
        SKP_Minimum_Mapping__c mapp = new SKP_Minimum_Mapping__c(name ='3472',Minimum_Level__c='CUSTOMER', 
                                             Minimum_Order_Type__c='SHREDDING OFF SITE', Minimum_Type__c='Order');
        /*--13427 Start --*/
        Product2 testProd = new Product2(Name = '3472', IsActive= true,IM_Unit_of_Measure__c = 'Each',IM_Product_Class__c='Records Management',Schedule_A_Category__c='Custom Storage and Services');
        insert testProd;
        
         testProd = [select id,Name,IsActive,IM_Unit_of_Measure__c,IM_Product_Class__c,Schedule_A_Category__c,Category_Abreviation__c from Product2];
         
         system.debug('testProd....'+testProd.Category_Abreviation__c);
        Quote scheduleA = SkpIntegrationHelper.getScheduleAs( (string) testOpp.id, new List<String>(SkpIntegrationWizardCont.scheduleAFields))[0];
        
        system.debug('scheduleA=='+scheduleA);
         
         Id pricebookId = Test.getStandardPricebookId();
         
         PricebookEntry pbe = new PricebookEntry(Product2Id = testProd.Id, pricebook2Id = pricebookId, unitprice=100, isActive=true);
         insert pbe;
         
        QuoteLineItem qli1 = new QuoteLineItem(QuoteId = scheduleA.id, Product2Id=testProd.id,
                                               UnitPrice=2,Quantity=2,Base_Quantity__c=10,Base_Amount__c=10,Unit_Quantity__c=10,Unit_Rate__c=1,PricebookEntryId = pbe.Id);
     	system.debug('Category Abbreviation... '+qli1.Category_Abbreviation__c);
        // insert qli1;
         /*13427 -- End */
         //	insert qli1;
         
      //  QuoteLineItem qli2 = [select QuoteId,Product2Id,UnitPrice,Quantity,Base_Quantity__c,Base_Amount__c,Unit_Quantity__c,Unit_Rate__c,Category_Abbreviation__c from QuoteLineItem limit 1 ];
         
        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        qlis.add(qli1);  
        
        Set<String> billCodes = new Set<String>();
        billCodes.add('2011');
        Set<String> initBillCodes = new Set<String>();
            
            for (String billCode : billCodes){
                string standardBillCode = SkpIntegrationHelper.cleanBillCode(billcode);
               
                  if(SkpIntegrationHelper.isInitBillCode(billCode)){
                    initBillCodes.add(standardBillCode);
                }
            }
        
        string effectiveDateString = system.now().format('yyyy/MM/dd');
        string nextQuarterDateString = system.now().addMonths(3).format('yyyy/MM/dd','GMT-04:00');
         
        testOpp.Sales_Rep_Percent__c = 5;
        update testOpp;
         system.debug('testOpp=='+testOpp.Sales_Rep_Percent__c);
         system.debug('testProfile=='+testProfile.Sales_Rep_Percent_from_Opportunity__c);
             
        SKPContractRenegotiation.scaleListObj chckscale = new SKPContractRenegotiation.scaleListObj(qli1,1);
         /*13427 -- Start --> Changed the proposedYear parameter value from 1 to 10 */
        SKPContractRenegotiation.exceptionRateDetailObj exeDetObj = new SKPContractRenegotiation.exceptionRateDetailObj(qlis, '12345', 'SFEXP', effectiveDateString, nextQuarterDateString, initBillCodes,'test',10,2,1);
        
         /*13427 -- End --> Changed the proposedYear parameter value from 1 to 10 */
         SKPContractRenegotiation.exceptionRateObj exeObj = new SKPContractRenegotiation.exceptionRateObj(qli1, effectiveDateString, nextQuarterDateString, initBillCodes,1,1);
        SKPContractRenegotiation.minimumObj minobj = new SKPContractRenegotiation.minimumObj(mapp); 
        SKPContractRenegotiation.salesCommissionObj salObj = new SKPContractRenegotiation.salesCommissionObj(testProfile,true);
        SKPContractRenegotiation.testQty testQty = new SKPContractRenegotiation.testQty();         
          //For Security Token
         HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
         
         //HttpCalloutMock fakeCustProfile = new MockValidateCallout();
         HttpCalloutMock fakeContractResp = new MockUpdateContract();
         
         Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
         
         endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
        // endpoint2TestResp.put('www.test.com/custUpdate',fakeCustProfile);
         endpoint2TestResp.put('www.test.com/contractUpdate',fakeContractResp);
         
         HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
         Test.setMock(HttpCalloutMock.class, multiCalloutMock);
         
         SKPIntegrationWizardCont skpCont = new SKPIntegrationWizardCont(); 
                       
        Test.startTest();             
            skpCont.contractCallout_RenewalNRenego(true,5);
        Test.stopTest();
    }
    
    /************* Customer callout *******/
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
    static testmethod void customerCalloutTest(){
        
        setup();
        
        testScheduleA.Status = 'Accepted';
        insert testScheduleA; 
        testCase.NCSP_Opportunity__c = testOpp.id;
        testCase.SKP_Customer_Sync_Date__c = Date.today();
        testCase.contract_type__c = 'test version';
        testCase.Customer_Profile__c = testProfile.id;
        testCase.AccountId = testAccount.id;
        
        update testCase;
        
        
        SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies', 
                                             name='Sandbox', Customer_Endpoint__c='www.test.com/test', Contract_Endpoint__c='www.test.com/test', OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        SKP_Integration_Details__c details2 = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies', 
                                             name='Production', Customer_Endpoint__c='www.test.com/test', Contract_Endpoint__c='www.test.com/test', OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
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
        endpoint2TestResp.put('www.test.com/test',custCallOut);
        
        HttpCalloutMock multiCalloutMock = new MockGetCustContract(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
                
            skpCont.createSKPCustomer();
        Test.stopTest();
        
        Case returnedCase = [Select id, SKP_Customer_Sync_Date__c from Case where ID =: testCase.id];
        List<IM_Customer_Account__c> customerAccounts = [Select id, IM_Account__c from IM_Customer_Account__c where IM_Account__c=: testCase.accountID ];
        
    }
    
    /************* SKP Helper Class *******/
    static testMethod void helperTest() {
        
       integer a = SKPIntegrationHelper.getNumericBillCode('121');
        boolean b = SKPIntegrationHelper.billCodeInRange(1121, 5, 2);
        SKPIntegrationHelper.testQty testQty = new SKPIntegrationHelper.testQty();         

        HttpRequest req= SKPIntegrationHelper.buildRequest('https://api-preprod.ironmountainconnect.com/login', 'fakeSecurityToken', 'jsonString');
    }
    
    public static void setup1(){
        
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true; 
        testAccount = TestingUtils.createAccounts(1, true)[0];
        testContact = TestingUtils.createContact(testAccount.Id, false);
        testContact.FirstName = 'testClassContact';
        insert testContact;
        
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();
        oppprodsel.Name = 'CloudSolutionsProduct';
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              
        insert oppprodsel;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
        
        
        testOpp = TestingUtils.createOpportunity('test_Opp', testAccount.Id, true);
        testUser = TestingUtil.createUser();
        testCase = TestingUtils.createCase(testOpp, testContact, true);
        testCase.contract_type__c = 'IM2000';
        
        testScheduleA = TestingUtils.createQuotes(testOpp.id, 1, false)[0];
        
        
        testProfile = TestingUtils.createCustomerProfile(testOpp.id, new Map<string, Object>(), true);
        SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies', 
                                             name='Sandbox', Customer_Endpoint__c='www.test.com/test', Contract_Endpoint__c='www.test.com/test', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
        SKP_Integration_Details__c details2 = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies', 
                                             name='Production', Customer_Endpoint__c='www.test.com/test', Contract_Endpoint__c='www.test.com/test', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
        insert new List<SKP_Integration_Details__c>{details, details2};
            
       /* SKP_Excluded_Billcodes__c billcodes = new SKP_Excluded_Billcodes__c(name='318');
         insert billcodes;    
	*/
     }
    
    public static void validateSKPCustomerAndContract_setup1(){
        setup1();    
        testCustomerAccount=TestingUtils.createIMCustomerAccounts(1, testAccount.id, true)[0];
        testCase.Source_Customer_Id__c=testCustomerAccount.Id;
        testCase.Customer_ID__c = testCustomerAccount.id;
        testCase.Customer_Profile__c = testProfile.id;
        update testCase;        
        ApexPages.currentPage().getParameters().put('id', testCase.id);
        
        SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies', 
                                             name='Sandbox', Customer_Endpoint__c='www.test.com/test', Contract_Endpoint__c='www.test.com/test',Update_Customer_Info__c='www.test.com/custUpdate', Update_Contract_Info__c='www.test.com/contractUpdate',Get_Recurring_Charges__c='www.test.com/getRecurring', Update_Recurring_Charges__c='www.test.com/UpdateRecurring',Create_Recurring_Charges__c='www.test.com/CreateRecurring', OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        SKP_Integration_Details__c details2 = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies', 
                                             name='Production', Customer_Endpoint__c='www.test.com/test', Contract_Endpoint__c='www.test.com/test',Update_Customer_Info__c='www.test.com/custUpdate', Update_Contract_Info__c='www.test.com/contractUpdate',Get_Recurring_Charges__c='www.test.com/getRecurring', Update_Recurring_Charges__c='www.test.com/UpdateRecurring',Create_Recurring_Charges__c='www.test.com/CreateRecurring', OAuth_EndPoint__c='https://api-preprod.ironmountainconnect.com/login', Client_Id__c='test1212', Client_Secret__c='test2323');
        insert new List<SKP_Integration_Details__c>{details, details2};
        testScheduleA.Status = 'Accepted';  
        
        
        List<Schedule_A__c> sch = TestingUtils.createPAModels(1, true);
       sch[0].RM_Contract_Length__c = 10;
        sch[0].SS_Contract_Length__c  = 1;
        //sch[0].New_Storage_Volume__c = 450;
        update sch[0];
       /* Schedule_A__c sch = TestingUtils.createPAModels(1, false)[0];
        sch.RM_Contract_Length__c = 10;
        sch.SS_Contract_Length__c  = 1;
        insert sch; */
                
        testScheduleA.Schedule_A__c = sch[0].id;
        insert testScheduleA;
        
        List<Quote> scheduleAs = [Select Name, id, Effective_Date__c from Quote where Opportunityid =: testOpp.Id];    
        
        system.debug('testScheduleA======='+testScheduleA);
         system.debug('scheduleAs ======='+scheduleAs);
        
        SKP_Contract_Type_Mapping__c mapping1 = TestingUtils.createSkpMappingObject('USA', 'Affiliate Option 1', false);
        SKP_Contract_Type_Mapping__c mapping2 = TestingUtils.createSkpMappingObject('USA', 'Affiliate Option 2', false);
        SKP_Contract_Type_Mapping__c mapping3 = TestingUtils.createSkpMappingObject('USA', 'IM-38', false);
        insert new List<SKP_Contract_Type_Mapping__c>{mapping1, mapping2, mapping3};
    }
    
}