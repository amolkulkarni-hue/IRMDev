/* 
Created Date: July 22,2010
Auhtor: Nathan Shinn
Description : Used to test the DRCi Web Service stubs and wrapper.

Modified By : Vinutha Iyengar
Description : Used to cover DRCi web service with Mock callouts 
*/

@isTest
private class TestDRCiDocumentLink {
    
    public static Account testAccount;
    public static Opportunity testOpportunity;
    public static Contract testContract;
    
    public static void setup(){
        
        
        Profile p = [Select id from profile where name = 'IME_Contracts'];
        
        IM_Country__c cntry = CountryNameTranslator.getOrCreateTestCountry
            ( (new IM_Country__c(name = 'United Kingdom',
                                 Region__c = 'Europe')));
        
        Country_Settings__c setting = new Country_Settings__c();
            setting.Name = 'United States';
            setting.object_name__c = 'Account';
        insert setting;
        IM_Country__c testCountry = new IM_Country__c(Name='United States');
        insert testCountry;        
          IM_Alternative_Country_Name__c country = new IM_Alternative_Country_Name__c(IM_Country__c = testCountry.Id, Alternative_Name__c='United States');
        insert country;	
        
        RecordType EUOppType = [select id from RecordType
                                where name = 'IME standard opportunity'
                                and sObjectType = 'Opportunity'];
        
        
        
        //Create the DRCi configuration that doesn't exist -- assuming Cuba.
        DRCiWebServiceConfig__c dc 
            = new DRCiWebServiceConfig__c
            (username__c = 'test'
             , Password__c = 'test'
             , Instance__c = 'test'
             , Folder__c = 'test'
             , Endpoint__c = 'test'
             , Alias__c  = 'test'
             , pooled_session_Cookie__c = 'test'
             , pooled_session_Id__c = 'test'
             , Locked_For_Pooled_Session_Update__c = false);
        
        insert dc;
        DRCiWebServiceCountry__c cc 
            = new DRCiWebServiceCountry__c
            ( DRCiWebServiceConfig__c = dc.id
             ,Country__c = cntry.id);
        insert cc;
        
        //Create the Test Account
        testAccount = new Account(name='Test -x',BillingCountry='United States');
        insert testAccount;
        
        //Create the opportunity
        //CloseDate formerly First Bill Date, Booked Date is now First Bill Date.
        testOpportunity = new Opportunity(name = 'Test Opp'
                                          ,AccountId = testAccount.id
                                          ,Source_System__c = 'SKP'
                                          ,Billing_Country__c = cntry.id 
                                          ,Lead_Source_Most_Recent__c = 'x'
                                          ,CloseDate = date.today()
                                      ,StageName = '1 - Qualification'
                                          , RecordTypeId = EUOppType.Id
                                          ,IM_Servicing_Region__c ='London'
                                          ,IM_Commit_to_Forecast__c = true
                                          ,IM_Stage_5_Entered_Date__c  = System.today()
                                          ,IME_Reason_Won__c = 'Price'
                                          ,IM_Booked_Date__c = System.today());
        
        insert testOpportunity;
        
        //create the contract
        testContract = new Contract(IM_DRCi_Contract_Number__c = '10'
                                    ,AccountId = testAccount.id
                                    ,Opportunity__c = testOpportunity.id
                                    ,Billing_Country__c =cntry.id,IME_Other__c = True );
        insert testContract;
        
        
    }
    
    static testMethod void runLoginSuccessTest() {        
        setup();
        Test.startTest();
        DRCiDocumentLink.runSearchTest=true;  
        DRCiDocumentLink.runTest=false;
        Test.setMock(WebServiceMock.class, new LoginServiceSuccessMock());       
        DRCiDOcumentLink.DRCiDocResponse res  = DRCiDOcumentLink.getContracts(testContract.Id);
        
        Test.stopTest();        
    }
    
    static testMethod void runLoginSuccessTest1() {        
        setup();
        Test.startTest();
        DRCiDocumentLink.runSearchTest=false;    
        DRCiDocumentLink.runTest=true;
        DRCiPooledSessionManager.getInstance().releaseBusyTransaction();
        Test.setMock(WebServiceMock.class, new SearchServiceSuccessMock());       
        DRCiDOcumentLink.DRCiDocResponse res  = DRCiDOcumentLink.getContracts(testContract.Id);
        
        Test.stopTest();        
    }
    
    static testMethod void runLoginErrorTest() {        
        setup();
        Test.startTest();
        DRCiDocumentLink.runSearchTest=true;    
        DRCiDocumentLink.runTest=false;
        Test.setMock(WebServiceMock.class, new LoginServiceErrorMock());        
        DRCiDOcumentLink.DRCiDocResponse res  = DRCiDOcumentLink.getContracts(testContract.Id);        
        Test.stopTest();        
    }
    
    static testMethod void runSearchSuccessTest() {        
        setup();
        Test.startTest();
        DRCiDocumentLink.runTest=true;
        DRCiDocumentLink.runSearchTest=false;   
        Test.setMock(WebServiceMock.class, new SearchServiceSuccessMock());        
        DRCiDOcumentLink.DRCiDocResponse res  = DRCiDOcumentLink.getContracts(testContract.Id);        
        Test.stopTest();        
    }
    
    static testMethod void runSearchSuccessTest1() {        
        setup();
        Test.startTest();
        DRCiDocumentLink.runTest=false;
        DRCiDocumentLink.runSearchTest=true;   
        Test.setMock(WebServiceMock.class, new LoginServiceErrorMock());        
        DRCiDOcumentLink.DRCiDocResponse res  = DRCiDOcumentLink.getContracts(testContract.Id);        
        Test.stopTest();        
    }
    
    static testMethod void TestcleanupPooledConnection() {        
        setup();
        Test.startTest();
        DRCiDocumentLink.runTest=false;
        DRCiDocumentLink.runSearchTest=false;   
        Test.setMock(WebServiceMock.class, new LogOutServiceMock());        
        DRCiDOcumentLink.cleanupPooledConnection('Session_id','www/test/logoutTest');        
        Test.stopTest();        
    }
    
    public class LoginServiceSuccessMock implements WebServiceMock {
        public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType) {
                WsDRCiLoginService.LoginResponse_element respElement = 
                    new WsDRCiLoginService.LoginResponse_element();
                respElement.ErrorMsg = '';
                respElement.ErrorCode = 0;
                respElement.SessionToken= 'Mock Token';
                response.put('response_x', respElement); 
            }
    }
    
    public class LoginServiceErrorMock implements WebServiceMock {
        public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType) {
                WsDRCiLoginService.LoginResponse_element respElement = 
                    new WsDRCiLoginService.LoginResponse_element();
                respElement.ErrorMsg = 'Mock Error';
                respElement.ErrorCode = 0;
                respElement.SessionToken= '';
                response.put('response_x', respElement); 
            }
    }
    
     public class SearchServiceSuccessMock implements WebServiceMock {
        public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType) {
                
                WsDRCiSearchService.HitType docDetails = new WsDRCiSearchService.HitType();
                docDetails.DocId = 'test 123';
                docDetails.DocName = 'Test Contract Doc'; 
                docDetails.DownloadURL = 'www.test.testdownload';
                
                List<WsDRCiSearchService.HitType> HitItems = new List<WsDRCiSearchService.HitType>();
                HitItems.add(docDetails);
                
                WsDRCiSearchService.HitsType HitDets = new WsDRCiSearchService.HitsType();
                HitDets.Hit = HitItems;
                
                WsDRCiSearchService.SearchResponse_element respElement = new WsDRCiSearchService.SearchResponse_element();
                respElement.ErrorMsg = '';
                respElement.ErrorCode = 4;
                respElement.Folder= 'Mock Contracts';
                respElement.HitCount = 2;
                respElement.Hits = HitDets;
                response.put('response_x', respElement); 
            }
    }   
    
     public class LogOutServiceMock implements WebServiceMock {
        public void doInvoke(
            Object stub,
            Object request,
            Map<String, Object> response,
            String endpoint,
            String soapAction,
            String requestName,
            String responseNS,
            String responseName,
            String responseType) {
                WsDRCiSearchService.SearchResponse_element respElement = new WsDRCiSearchService.SearchResponse_element();
                respElement.ErrorMsg = '';
                respElement.ErrorCode = 0;
                response.put('response_x', respElement); 
            }
    }   
    
}