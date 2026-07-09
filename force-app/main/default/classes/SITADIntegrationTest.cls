/*
 * Removed the fields (CDM_Global_Ultimate_ID__c,CDM_Global_Ultimate_Name__c) dependency as part of #16051
 */
@isTest
private class SITADIntegrationTest {
public static User u;
public static Case cas;
public static IM_Customer_Account__c custAcc;
public static SITAD_Integration_Details__c SDetail;   
public static Trigger_Activation_Settings__c TriggerSetting;    
public static Boolean runningInASandbox;
    
    public static void setup()
    {
    	OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        IM_Country__c cntry = TestingUtil.createIMCountry();
        Profile p = [SELECT Id FROM Profile WHERE Name='IM_Custom Sys Admin']; 
                u = [select Id from user where ProfileId=:p.id AND isactive =: true limit 1];
        
        SITADIntegration sInt = new SITADIntegration();
        Boolean isSanBox = SITADIntegration.runningInASandbox;
        SITAD_Integration_Details__c siIntCustom = SITADIntegration.sitadDetails;
     
        //insert Account
        Account acc = TestingUtils.createAccounts(1, false)[0];
        
          //acc.CDM_Global_Ultimate_ID__c = '12345';
          //acc.CDM_Global_Ultimate_Name__c  = 'Test';
          insert acc;
        
        //insert Customer Account
        custAcc = TestingUtils.createCustomerAccount(acc.id, true);
        custAcc.name='test CA';
        update custAcc;
        
        //insert Contact
        Contact con = TestingUtils.createContact(acc.id, false);
        con.firstName = 'testFName';
          con.Phone ='9066376272';
          con.Email ='test@ion.com';
          insert con;
        
        //insert Opportunity
        Opportunity Opp = TestingUtils.createOpportunity('TestOpp', acc.Id, true);
        
        //get case record type
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.case; 
        Map<String,Schema.RecordTypeInfo> OppRecordTypeInfo = cfrSchema.getRecordTypeInfosByName(); 
        Id rtId = OppRecordTypeInfo.get('NCSP: DP New Customer Setup').getRecordTypeId();
        
        //insert case
        cas = TestingUtils.createCase(Opp, con , false);
            cas.NCSP_Service_line__c = 'DB&R';
            cas.Case_Contact_Name__c ='Test';
            cas.RecordTypeId = rtId;
            cas.AccountId = acc.id;
            cas.Customer_ID__c = custAcc.id;
            cas.Status = 'New';
            cas.Origin = 'Internal';
            cas.NCSP_Cust_Name__c = 'Test';
            cas.Sales_Person_Name_Account_Manager__c = u.id;//user;
            cas.Date_Contract_Signed__c = system.today();
            cas.Date_Paperwork_Received__c = system.today();
            cas.Setup_Type__c = 'Standard';
            cas.ContactId = con.id;
            cas.Address__c = 'Test';
            cas.State__c = 'Odisha';
            cas.Zip__c = '756001';
            cas.City__c ='Test';
            cas.Country__c = 'USA';
            cas.Service_Order_Date__c = system.today();
            cas.Service_Completion_Date__c = system.today();
            cas.Billing_Contact_Email__c = 'test@ion.com';
            //cas.SITAD_Disposition_Type__c = 'Offsite Media Destruction – Bulk;Offsite Media Destruction – Itemized Hard Drives;  Onsite Degaussing';           
            insert cas;
        
        //Checking for Environment or SandBox
        runningInASandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
                    
        //insert custom setting
        SDetail = new SITAD_Integration_Details__c();
        	string sandboxType = runningInASandbox ? 'Sandbox' : 'Production' ;
            SDetail.name = sandboxType;
            SDetail.Authorization_Head__c = 'Basic NjA2MDM4YjktNjkxMy00MDE1LWIyYTMtZWRjMWQwNWI5Y2U5OnFoOHhscHBNenNlZy9XbWJmc0toc0E9PQ==  ';
            SDetail.caseObj_Endoint__c = 'https://sitad.ironmountain.com/api/case';
            SDetail.Client_Id__c = '606038b9-6913-4015-b2a3-edc1d05b9ce9';
            SDetail.Client_Secret__c = 'qh8xlppMzseg/WmbfsKhsA==';
            SDetail.CustomerAcc_Endpoint__c = 'https://sitad.ironmountain.com/api/customeraccount';
            SDetail.Grant_Type__c = 'client_credentials';
            SDetail.Scope__c = 'Ironmountain_sfdc';
            SDetail.Token_endpoint__c = 'https://sitad.ironmountain.com/identity/connect/token';
            insert SDetail;
        
        TriggerSetting = new Trigger_Activation_Settings__c();
            TriggerSetting.Object__c = 'Case';
            TriggerSetting.Trigger__c='caseSITADIntegration';
            TriggerSetting.name='caseSITADIntegration';
            TriggerSetting.Value__c='TRUE';
            insert TriggerSetting;
    }
    
   static testMethod void testInsertCustomerAccountSuccess() {       
        setup();
        system.debug('cas=='+cas);
        system.debug('SDetail=='+SDetail);
        system.debug('User=='+u);        
      
        {
                HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
                HttpCalloutMock fakeCustAcc = new MockSITADCreateCUstomerCallout();
                HttpCalloutMock fakeCaseRec = new MockSITADCreateCaseCallout();
            
            
                Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
            
                endpoint2TestResp.put('https://sitad.ironmountain.com/identity/connect/token',fakeSecurityToken);
                endpoint2TestResp.put('https://sitad.ironmountain.com/api/customeraccount',fakeCustAcc);
                endpoint2TestResp.put('https://sitad.ironmountain.com/api/case',fakeCaseRec);
                
                HttpCalloutMock multiCalloutMock = new MockGetCustAccount(endpoint2TestResp);
                Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            
            Test.startTest(); 
                SITADIntegration.callSMSSync(cas.id);               
            Test.stopTest(); 
        }
    }
    
    static testMethod void testInsertCustomerAccountError() {       
        setup();
        system.debug('cas=='+cas);
        system.debug('SDetail=='+SDetail);
        system.debug('User=='+u);        
      
        {
                HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
                HttpCalloutMock fakeCustAcc = new MockSITADCreateCUstomerCallout();
                HttpCalloutMock fakeCaseRec = new MockSITADCreateCaseCallout();
            
            
                Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
            
                endpoint2TestResp.put('https://sitad.ironmountain.com/identity/connect/token',fakeSecurityToken);
                endpoint2TestResp.put('https://sitad.ironmountain.com/api/customeraccount',fakeCustAcc);
                endpoint2TestResp.put('https://sitad.ironmountain.com/api/case',fakeCaseRec);
                
                HttpCalloutMock multiCalloutMock = new MockGetCustAccount(endpoint2TestResp);
                Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            
            Test.startTest(); 
            	SITADIntegration.calloutException = true;
                SITADIntegration.callSMSSync(cas.id);               
            Test.stopTest(); 
        }
    }
    
    static testMethod void testInsertCaseOnly() {       
        setup();
        
       // custAcc.SITAD_Flag__c = true;
        //update custAcc;
        
        cas.QTB_SITAD_Integration_Flag__c = true;
        update cas;
        
        system.debug('cas=='+cas);
        system.debug('SDetail=='+SDetail);
        system.debug('User=='+u);        
      
        {
                HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
                HttpCalloutMock fakeCustAcc = new MockSITADCreateCUstomerCallout();
                HttpCalloutMock fakeCaseRec = new MockSITADCreateCaseCallout();
            
            
                Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
            
                endpoint2TestResp.put('https://sitad.ironmountain.com/identity/connect/token',fakeSecurityToken);
                endpoint2TestResp.put('https://sitad.ironmountain.com/api/customeraccount',fakeCustAcc);
                endpoint2TestResp.put('https://sitad.ironmountain.com/api/case',fakeCaseRec);
                
                HttpCalloutMock multiCalloutMock = new MockGetCustAccount(endpoint2TestResp);
                Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            
            Test.startTest(); 
                SITADIntegration.callSMSSync(cas.id);               
            Test.stopTest(); 
        }
    }
    
    static testMethod void testUpdateCustomerAccount() {       
        setup();
        
       // custAcc.SITAD_Flag__c = true;
       // update custAcc;

        
        system.debug('cas=='+cas);
        system.debug('SDetail=='+SDetail);
        system.debug('User=='+u);      
        system.debug('custAcc.name=='+custAcc.name);
        system.debug('Customer_ID__r name=='+cas.Customer_ID__c);
        
        cas.QTB_SITAD_Integration_Flag__c  = true;
        cas.SMS_Customer_Sync_Date__c = system.today();
        cas.SMS_Order_Sync_Date__c = system.today();
        cas.Service_Completion_Date__c = system.today();
        cas.Service_Schedule_Date__c = system.today();
        update cas;
        Case case1 = [SELECT Customer_ID__c,SMS_Customer_Sync_Date__c, SMS_Order_Sync_Date__c,QTB_SITAD_Integration_Flag__c,Customer_ID__r.name, Customer_ID__r.SITAD_Flag__c, Owner.Name, Owner.Phone, Owner.Email,SITAD_Disposition_Type__c, IM_Market__c, Owner.id, Market_Name__c, Service_Order_Date__c,Service_Schedule_Date__c, Service_Completion_Date__c, CaseNumber, Customer_Name__c, Account.Id,Account.Name, Address__c,City__c,  State__c, Zip__c, Country__c, Case_Contact_Name__c, Contact.Phone, Contact.Email FROM Case WHERE id =:cas.id];
        

        system.debug('Customer_ID__r name=='+case1.Customer_ID__r.name);
      
        Test.startTest(); 
       
                HttpCalloutMock fakeSecurityToken = new MockSITADSecurityTokenCallout();
                HttpCalloutMock fakeCustAcc = new MockSITADUpdateCUstomerCallout();
                HttpCalloutMock fakeCaseRec = new MockSITADCreateCaseCallout();
            
            
                Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String,HttpCalloutMock>();
            
                endpoint2TestResp.put('https://sitad.ironmountain.com/identity/connect/token',fakeSecurityToken);
                endpoint2TestResp.put('https://sitad.ironmountain.com/api/customeraccount/'+case1.Customer_ID__r.name,fakeCustAcc);
                endpoint2TestResp.put('https://sitad.ironmountain.com/api/case',fakeCaseRec);
                
                HttpCalloutMock multiCalloutMock = new MockGetCustAccount(endpoint2TestResp);
                Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            	
        		
       
                SITADIntegration.callTriggerToSMSSync(case1);    
        
                   
         Test.stopTest(); 
    }

    //Customer Account insert SUCCESS
    static testMethod void testCustomerAccountSuccess() {       
        setup();
        Test.startTest(); 
            Test.setMock(HttpCalloutMock.class, new MockSITADCreateCUstomerCallout());
            SITADIntegration.callCustomerSMSSync(cas,'testSecurityToken');               
        Test.stopTest(); 
    }
    
    //Customer Account insert ERROR
    static testMethod void testCustomerAccountError() {       
        setup();
        Test.startTest(); 
            Test.setMock(HttpCalloutMock.class, new MockSITADErrorCACallout());
            SITADIntegration.callCustomerSMSSync(cas,'testSecurityToken');               
        Test.stopTest(); 
    }
    
    //Case insert SUCCESS
    static testMethod void testCaseSuccess(){       
        setup();
        Test.startTest(); 
            Test.setMock(HttpCalloutMock.class, new MockSITADCreateCaseCallout());
            SITADIntegration.callCaseSMSSync(cas,'testSecurityToken');               
        Test.stopTest(); 
    }
    
    //Case insert ERROR
    static testMethod void testCaseError(){       
        setup();
        Test.startTest(); 
            Test.setMock(HttpCalloutMock.class, new MockSITADErrorCreateCaseCallout());
            SITADIntegration.callCaseSMSSync(cas,'testSecurityToken');               
        Test.stopTest(); 
    }
    
    //Customer Account update ERROR
    static testMethod void testCAUpdateError(){       
        setup();
        Test.startTest(); 
            Test.setMock(HttpCalloutMock.class, new MockSITADErrorCACallout());
            SITADIntegration.callTriggerSMSSync(cas,'testSecurityToken');               
        Test.stopTest(); 
    }
    
    //Case update ERROR
    static testMethod void testCaseUpdateError(){       
        setup();
        cas.SMS_Order_Sync_Date__c = system.today();
        update cas;
        Test.startTest(); 
            Test.setMock(HttpCalloutMock.class, new MockSITADErrorCreateCaseCallout());
            SITADIntegration.callCaseTriggerSMSSync(cas,'testSecurityToken');               
        Test.stopTest(); 
    }
    
    //Other Methods
    static testMethod void testSyncError(){
        setup();
        SITADIntegration.createSyncError(cas.id,'23424','Test Error');               
    }    

    //Response of Security Token
    public class MockSITADSecurityTokenCallout implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            OAuthTokenResponse tokenR = new OAuthTokenResponse();
            tokenR.access_token = 'testSecurityToken';
            tokenR.expires_in = 3600;
            tokenR.token_type = 'testType';
            res.setBody(JSON.serialize(tokenR));
            res.setStatusCode(200);
            system.debug('+++++res'+res);
            return res;
        }
    }
    
    //Response of insert customer Acount SUCCESS
    public class MockSITADCreateCUstomerCallout implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            CustAccountSITADJsonResponse successCAResponse = new CustAccountSITADJsonResponse();
            CustAccountSITADJsonResponse.cls_Account acc = new CustAccountSITADJsonResponse.cls_Account();
            acc.AccountId = '55';
            acc.CustomerAccountId ='12280999912355';
            acc.ParentAccountId = '0018000000lijamaag';
            acc.ParentAccountName= 'Ameritox';
            acc.CustomerAccountName = 'AMERITOX1155';
            acc.GlobalUltimateId ='';
            acc.GlobalUltimateName ='';
            res.setBody(JSON.serialize(successCAResponse));
            res.setStatusCode(200);
            return res;
        }
    }
    
    //Response of insert customer Acount SUCCESS
    public class MockSITADUpdateCUstomerCallout implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            string updateResp = '';
            res.setBody(updateResp);
            res.setStatusCode(200);
            return res;
        }
    }
    //Response of insert customer Acount ERROR
    public class MockSITADErrorCACallout implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            CustAccountSITADErrorResponse errorCAResponse = new CustAccountSITADErrorResponse();
            CustAccountSITADErrorResponse.cls_Errors er = new CustAccountSITADErrorResponse.cls_Errors();
            er.Code = '1234';
            er.Message = 'This is the Test ERROR';
            res.setBody(JSON.serialize(errorCAResponse));
            return res;
        }
    }
    
    //Response of insert case SUCCESS
    public class MockSITADCreateCaseCallout implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            caseObjSITADJsonResponse successCasResponse = new caseObjSITADJsonResponse();
            successCasResponse.CaseId = '64';
            successCasResponse.Account ='';
            res.setBody(JSON.serialize(successCasResponse));
            res.setStatusCode(200);
            return res;
        }
    }
    
    //Response of insert case SUCCESS
    public class MockSITADUpdateCaseCallout implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            string updateResponse ='';
            res.setBody(updateResponse);
            res.setStatusCode(200);
            return res;
        }
    }
    //Response of insert case ERROR
    public class MockSITADErrorCreateCaseCallout implements HttpCalloutMock{
        public HTTPResponse respond (httpRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            caseObjSITADErrorResponse errorCasResponse = new caseObjSITADErrorResponse();
            caseObjSITADErrorResponse.cls_Errors  casER= new caseObjSITADErrorResponse.cls_Errors();
            casER.caseNumber = '2345535';
            casER.Code = '5432';
            casER.Message = 'This is Case insert ERROR';
            res.setBody(JSON.serialize(errorCasResponse));
            return res;
        }
    }
    //Response of update customerAcc ERROR
    
    public class MockGetCustAccount implements HttpCalloutMock {
        Map<String, HttpCalloutMock> requests;    
        public MockGetCustAccount(Map<String, HttpCalloutMock> requests) {
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
}