@isTest(SeeAllData=false)

public class Test_SKPRateUploadNotificationBatch{
    
    public static Account testAccount;
    public static Contact testContact;
    public static Opportunity testOpp;
    public static Case testCase;
    public static User testUser;
    public static Quote testScheduleA;
    
    @testSetup
    public static void setup(){
        //Create Account and Contact
        testAccount = TestingUtils.createAccounts(1, true)[0];
        testContact = TestingUtils.createContact(testAccount.Id, false);
        testContact.FirstName = 'testClassContact';
        insert testContact;
        
        //Create opportunity Product Selection and country setting
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();
        oppprodsel.Name = 'CloudSolutionsProduct';
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              
        insert oppprodsel;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
        Id standardPB = Test.getStandardPricebookId();
        
        testOpp = TestingUtils.createOpportunity('test_Opp', testAccount.Id, false);
        testOpp.pricebook2ID= standardPB;
        insert testOpp;
        testUser = TestingUtil.createUser();
        testCase = TestingUtils.createCase(testOpp, testContact, false);
        
        //testCase.Sync_To_SKP__c = 'This Contract has already been Synced';
        
        //Update Case fields
        RecordType NCSP_RENEWAL = [ Select Name, Id From RecordType r where Name = 'NCSP Renewal' AND SobjectType = 'Case' ];
      	testCase.RecordTypeId = NCSP_RENEWAL.Id;
        testCase.Contract_Status__c = 'Accepted';
        testCase.NCSP_Opportunity__c = testOpp.id;
        testCase.SKP_Customer_Sync_Date__c = system.today();
        testCase.SKP_Contract_Sync_Date__c = system.today();
        testCase.Setup_Type__c ='Schedule A only';
        insert testCase;
        
        
        
        Case tCase = [Select id,casenumber,Sync_To_SKP__c from case where id =: testCase.id];
        system.debug('Case Sync_To_SKP__c '+tCase.Sync_To_SKP__c);
        
        
        Quote testQuotes = new Quote(OpportunityId = testOpp.Id, Name = 'Test Quote' + 1);
        RecordType NA_RENEWAL_QUOTE = [ Select Name, Id From RecordType r where Name = 'NA Renewal Quote' AND SobjectType = 'Quote' ];
      
        testQuotes.RecordTypeId = NA_RENEWAL_QUOTE.Id;
        testQuotes.Quarter_Status__c = 'Closed: Rates Uploaded';
        testQuotes.Status= 'Accepted';
        testQuotes.Effective_Date__c = System.today();
        testQuotes.Pricebook2Id = test.getStandardPriceBookId();
       
        insert testQuotes;
        
        List<SKP_Contract_Type_Mapping__c> mappings = new List<SKP_Contract_Type_Mapping__c>();
        SKP_Contract_Type_Mapping__c expectedMapping = testingUtils.createSkpMappingObject('USA', 'A5000', false);
        mappings.add(expectedMapping);
        mappings.add(testingUtils.createSkpMappingObject('Canada', 'A5000', false));
        mappings.add(testingUtils.createSkpMappingObject('USA', 'Other version', false));
        
        insert mappings;
        
        
        Product2 productforShred = TestingUtils.createProduct('1500', true);
        

        PriceBookEntry shredPBE = TestingUtils.createPriceBookEntry(productforShred.id, standardPB, true);
        QuoteLineItem qliForShred = TestingUtils.createQuoteLineItem(shredPBE.id, testQuotes.id, true);

    }
    
      public static testMethod void skpBatchTest(){ 
       testAccount = [select id from Account limit 1];
      Quote testQuotes = [select id from quote limit 1];
          testCase = [select id from case limit 1];
          List<IM_Customer_Account__c> testIMCustomerAccounts = new List<IM_Customer_Account__c>();
       	testIMCustomerAccounts.addAll(TestingUtils.createIMCustomerAccounts(1, testAccount.Id, false));
        
        testIMCustomerAccounts[0].quote__c = testQuotes.Id;
        testIMCustomerAccounts[0].Rate_Table_ID__c='test rate table';
        testIMCustomerAccounts[0].Renewal_ERID__c = true;
        insert testIMCustomerAccounts;
        
        Case_Customer_Account__c testCaseCustomerAccount1=TestingUtils.createCaseCustomerAccount(testCase.Id,testIMCustomerAccounts[0].Id,true);
       	
        Test.startTest();	
              
            SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies', 
                                                 name='SandboxTest', Customer_Endpoint__c='www.test.com/test', Contract_Endpoint__c='www.test.com/test', Update_Contract_Info__c='www.test.com/contract', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
            insert new List<SKP_Integration_Details__c>{details};            
              
              
             //For Security Token
            HttpCalloutMock fakeSecurityToken = new MockSecurityTokenCallout();
            HttpCalloutMock oppRenewalCall = new MockSKPContractRenewalCallout();
            HttpCalloutMock oppRenegoCall = new MockSKPContractRenegotiationCallout();
            
            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
            endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
            endpoint2TestResp.put('www.test.com/contract',oppRenewalCall);
            endpoint2TestResp.put('www.test.com/contract',oppRenegoCall);
            
            HttpCalloutMock multiCalloutMock = new MultiRequestMock (endpoint2TestResp);
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);
         
            SKPRateUploadNotificationBatch job= new SKPRateUploadNotificationBatch();
        	Database.executeBatch(job);  
        Test.stopTest();  
    } 
    
    
    public static testMethod void skpQPIBatchTest(){   
        Test.startTest(); 
            Bulk_Renewal_User_Role_Map__c UserRole = new Bulk_Renewal_User_Role_Map__c();
            UserRole.Role__c='Admin';
            UserRole.User__c=UserInfo.getUserID();
            UserRole.CurrencyIsoCode='USD';
            insert UserRole;
            
            SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies', 
                                                 name='SandboxTest', Customer_Endpoint__c='www.test.com/test', Contract_Endpoint__c='www.test.com/test', Update_Contract_Info__c='www.test.com/contract', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
            insert new List<SKP_Integration_Details__c>{details};            
              
              
             //For Security Token
            HttpCalloutMock fakeSecurityToken = new MockSecurityTokenCallout();
            HttpCalloutMock oppRenewalCall = new MockSKPContractRenewalCallout();
            HttpCalloutMock oppRenegoCall = new MockSKPContractRenegotiationCallout();
            
            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
            endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
            endpoint2TestResp.put('www.test.com/contract',oppRenewalCall);
            endpoint2TestResp.put('www.test.com/contract',oppRenegoCall);
            
            HttpCalloutMock multiCalloutMock = new MultiRequestMock (endpoint2TestResp);
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            
            SKPRateUploadQPINotificationBatch QPIjob= new SKPRateUploadQPINotificationBatch('');
            Database.executeBatch(QPIjob);         
        Test.stopTest();         
    } 
    
	public static testMethod void skpCRBatchTest(){ 
       testAccount = [select id from Account limit 1];
      Quote testQuotes = [select id from quote limit 1];
          testCase = [select id,Setup_Type__c from case limit 1];
          testCase.Setup_Type__c ='Standard';
          testCase.contract_type__c = 'A5000';
          testCase.SKP_Synced_ScheduleA__c = testQuotes.id;
        update testCase;
          List<IM_Customer_Account__c> testIMCustomerAccounts = new List<IM_Customer_Account__c>();
       	testIMCustomerAccounts.addAll(TestingUtils.createIMCustomerAccounts(1, testAccount.Id, false));
        
        testIMCustomerAccounts[0].quote__c = testQuotes.Id;
        testIMCustomerAccounts[0].Rate_Table_ID__c='test rate table';
        testIMCustomerAccounts[0].Renewal_ERID__c = true;
        insert testIMCustomerAccounts;
        
        Case_Customer_Account__c testCaseCustomerAccount1=TestingUtils.createCaseCustomerAccount(testCase.Id,testIMCustomerAccounts[0].Id,true);
       	
        Test.startTest();	
              
            SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies', 
                                                 name='SandboxTest', Customer_Endpoint__c='www.test.com/test', Contract_Endpoint__c='www.test.com/test', Update_Contract_Info__c='www.test.com/contract', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
            insert new List<SKP_Integration_Details__c>{details};            
              
              
             //For Security Token
            HttpCalloutMock fakeSecurityToken = new MockSecurityTokenCallout();
            HttpCalloutMock oppRenewalCall = new MockSKPContractRenewalCallout();
            HttpCalloutMock oppRenegoCall = new MockSKPContractRenegotiationCallout();
            
            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
            endpoint2TestResp.put('https://api-preprod.ironmountainconnect.com/login',fakeSecurityToken);
            endpoint2TestResp.put('www.test.com/contract',oppRenewalCall);
            endpoint2TestResp.put('www.test.com/contract',oppRenegoCall);
            
            HttpCalloutMock multiCalloutMock = new MultiRequestMock (endpoint2TestResp);
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);
         
            SKPRateUploadNotificationBatch job= new SKPRateUploadNotificationBatch();
        	Database.executeBatch(job);  
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
    
    public class MockSKPContractRenewalCallout implements HttpCalloutMock{
    String customerId = 'C123';
    String departmentId = 'D123';
    String divisionId = 'Div123';
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            SKPUpdateContractResponse successfulResp = new SKPUpdateContractResponse();
            SKPUpdateContractResponse.ContractDetails result = new SKPUpdateContractResponse.ContractDetails();
            result.customerID = customerId;
            result.divisionId = divisionId;
            result.departmentId = departmentId;
            successfulResp.success = true;
            //successfulResp.updateContractResult = result;
            
            SKPUpdateContractResponse.CodeAndMessage err = new SKPUpdateContractResponse.CodeAndMessage();
            err.code= '400';
            err.message= 'Error';
  
            result.errors.add(err);
            result.warnings.add(err);
            
            SKPUpdateContractResponse.generalWarnings err1 = new SKPUpdateContractResponse.generalWarnings();
            err1.code= '400';
            err1.message= 'Error';  
            
            successfulResp.updateContractResult.ContractDetails.add(result); 
            successfulResp.updateContractResult.generalWarnings.add(err1); 
            res.setBody(JSON.serialize(successfulResp));
            res.setStatusCode(200);
            return res;
        }
    }
    
   
    public class MockSKPContractRenegotiationCallout implements HttpCalloutMock{
    String customerId = 'C123';
    String departmentId = 'D123';
    String divisionId = 'Div123';
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            SKPUpdateContractResponse successfulResp = new SKPUpdateContractResponse();
            SKPUpdateContractResponse.ContractDetails result = new SKPUpdateContractResponse.ContractDetails();
            result.customerID = customerId;
            result.divisionId = divisionId;
            result.departmentId = departmentId;
            successfulResp.success = true;
            
            SKPUpdateContractResponse.CodeAndMessage err = new SKPUpdateContractResponse.CodeAndMessage();
            err.code= '400';
            err.message= 'Error';

            result.errors.add(err);
            result.warnings.add(err);
            
            successfulResp.updateContractResult.ContractDetails.add(result);
            

            res.setBody(JSON.serialize(successfulResp));
            res.setStatusCode(200);
            return res;
        }
    }

}