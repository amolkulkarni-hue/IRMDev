/* Placeholder Test Class While Integration is fixed -LR */
@isTest
public class nf_datatableCtrTest { 

    // static User usr;
    @TestSetup
    static void makeData(){
        Id VALIDATE_RECORD_TYPE = RecordTypeCache.get(Case.SObjectType, 'NCSP_DMS').Id;        
        List<Account> acct = TestingUtils.createAccounts(1,True);
        contact cnt = TestingUtils.createContact(acct[0].id, true);      
        IM_Customer_Account__c crac = new IM_Customer_Account__c();
        crac.RecordTypeId ='01280000000UHF0AAO';
        crac.IM_Account__c =acct[0].id;
        crac.Source_System__c = 'SKP NA';
        INSERT crac;

        id pr = [SELECT id from profile where name= 'Customer Community Plus Login Customer' limit 1].id;
        User portalUser = new User(
            FirstName      = 'Portal',
            LastName       = 'User',
            Email          = 'portaluser@testirmexp.com',
            Username       = 'portaluser' + DateTime.now().getTime() + '@test.com',
            Alias          = 'ptlusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey   = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId      = pr,
            ContactId      = cnt.Id,
            country = 'India'
        );
        insert portalUser;
        List<User> usr = [SELECT id,Contactid from USER where Email ='portaluser@testirmexp.com'];        
        List<case> listOfCases = new SObjectBuilder(Case.SObjectType)
                .put(Case.Status, 'Open')
                .put(Case.Project_Completion_Date__c, system.today() )
                .put(Case.Transition_Date__c, system.now() )
                .put(Case.RecordTypeId, VALIDATE_RECORD_TYPE)
                .put(Case.ContactId, cnt.Id)
                .count(1).create().getRecords();

    }
    /* Placeholder Test Method While Integration is fixed -LR */

    @isTest
    static void testGetSourceSystems_Success() {
        Test.startTest();
        Set<String> sourceSystems = nf_datatableCtr.getSourceSystems();
        Test.stopTest();
        
        System.assert(!sourceSystems.isEmpty(), 'The set should not be empty.');
        System.assertEquals(6, sourceSystems.size(), 'Should return two source systems.');       
    }

    @IsTest
    static void retrieveOrders() {       
       	List<User> usr = [SELECT id,Contactid from USER where Email ='portaluser@testirmexp.com'];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new nf_datatableCtrTest.CalloutMock());
        String str = nf_datatableCtr.retrieveOrders(usr[0].id);
        Assert.isNotNull (str, 'Calloutshould return data');
        Test.stopTest();
    }
    
    /* Placeholder Test Method While Integration is fixed -LR */
    @IsTest
    static void retrieveInvoices() {
        List<User> usr = [SELECT id,Contactid from USER where Email ='portaluser@testirmexp.com'];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new nf_datatableCtrTest.CalloutMock());
        String str = nf_datatableCtr.retrieveInvoices(usr[0].id); //'TestUserId'
        Assert.isNotNull (str, 'Calloutshould return data');
        Test.stopTest();
    }
    
     @isTest
    static void testRetrieveOrdersErrorPath() {
        List<User> usr = [SELECT id,Contactid from USER where Email ='portaluser@testirmexp.com'];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new nf_datatableCtrTest.CalloutMockError());
        
        String result = nf_datatableCtr.retrieveOrders(usr[0].id);
        Test.stopTest();
        System.assertEquals('ERROR', result, 'Should return ERROR for 500 error');
    }

    @isTest
    static void testRetrieveInvoicesErrorPath() {
        List<User> usr = [SELECT id,Contactid from USER where Email ='portaluser@testirmexp.com'];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new nf_datatableCtrTest.CalloutMockError());        
        String result = nf_datatableCtr.retrieveInvoices(usr[0].id);
        Test.stopTest();
        System.assertEquals('ERROR', result, 'Should return ERROR for 500 error');
    }
    
    /* Placeholder Test Method While Integration is fixed -LR */
    @IsTest
    static void convertSetToString() {
        Test.startTest();
        Set<String> testSet = new Set<String>();
        testSet.add('testSet');
        testSet.add('testSet2');
        testSet.add('testSet3');
        
        String testString = nf_datatableCtr.convertSetToString(testSet);
        Assert.areEqual(testString,'testSet,testSet2,testSet3');
        Test.stopTest();
    }
    public class CalloutMock implements HttpCalloutMock{
      public HttpResponse respond(HTTPRequest req){
        HttpResponse res = new HttpResponse();
        res.setStatus('OK');
        res.setStatusCode(200);
        res.setBody('GREAT SCOTT');
        return res;
      }
    }
    
    // Custom mock returning error
    public class CalloutMockError implements HttpCalloutMock {
        public HttpResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Server Error');
            return res;
        }
    }

    @isTest
    static void testGetMetadataAsMap() {        
        // Call the method to test
        Test.startTest();
        Map<String, String> metadataMap = nf_datatableCtr.getMetadataAsMap();
        Test.stopTest();
    }
    
     @isTest
    static void testGetSourceSystems() {        
        // Call the method to test
        Test.startTest();
         Set<String> sourceSystemValues = nf_datatableCtr.getSourceSystems();
        Test.stopTest();
    }
    
     @isTest
    static void testaddZeroPrefixedToStrings() {        
        // Call the method to test
        Test.startTest();
         String prefixVal = nf_datatableCtr.addZeroPrefixedToStrings('1234');
        Test.stopTest();
    }
    @IsTest
    static void testCacheSetAndGet() {
        String sessionKey = 'testSessionKey';
        String testData = 'cachedOrderData';
    
        Test.startTest();
    
        // Set data into cache
        nf_datatableCtr.setCachedOrderOrInvoice(sessionKey, testData);
    
        // Immediately get data from cache
        String cachedData = nf_datatableCtr.getCachedOrderOrInvoice(sessionKey);
    
        Test.stopTest();
    
        System.assertEquals(testData, cachedData, 'Cached data should be retrieved correctly');
    }
    @IsTest
    static void testRetrieveOrders_CacheBranch() {
        // Prepare fake cache key for orders
        List<User> usr = [SELECT id,Contactid from USER where Email ='portaluser@testirmexp.com'];  
        String fakeKey = 'ORD' + usr[0].id;
        nf_datatableCtr.setCachedOrderOrInvoice(fakeKey, fakeKey);
        
        Test.startTest();
        String result = nf_datatableCtr.retrieveOrders(usr[0].id);
        Test.stopTest();
    }

    @IsTest
    static void testRetrieveInvoices_CacheBranch() {
        List<User> usr = [SELECT id,Contactid from USER where Email ='portaluser@testirmexp.com'];        
        String fakeKey = 'INV' + usr[0].id;
        nf_datatableCtr.setCachedOrderOrInvoice(fakeKey, fakeKey);        
        Test.startTest();
        String result = nf_datatableCtr.retrieveInvoices(usr[0].id);
        Test.stopTest(); 
    }
    @IsTest
    static void getRelatedCustomerIdstest() {
       	List<User> usr = [SELECT id,Contactid from USER where Email ='portaluser@testirmexp.com'];        
        system.debug('@@urId, Conactid'+usr[0].ContactId);               
        Test.startTest();
        Set<String> setOfRelatedCustomerId = nf_datatableCtr.getRelatedCustomerIds(usr[0].id);
        Test.stopTest();
    }
}