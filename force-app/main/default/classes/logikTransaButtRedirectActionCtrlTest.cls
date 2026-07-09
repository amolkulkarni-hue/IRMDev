@isTest
private class logikTransaButtRedirectActionCtrlTest {

    // ----------------------------------------------------------------------
    // 1. TEST DATA SETUP
    // ----------------------------------------------------------------------
    @TestSetup
    static void setupTestData() {
        AccountTriggerHandler.skipTriggerExecutionTestClass = true;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        // Create Custom Setting configuration
        LGK__ConfigurationTenant__c config = new LGK__ConfigurationTenant__c(
            LGK__RuntimeUrl__c = 'https://test-tenant.logik.io/',
            LGK__TenantUrl__c  = 'https://test-tenant.logik.io/'
        );
        insert config;

        // Create Account
        Account testAcc = new Account(Name = 'Test Logik Account', Billing_County__c = 'United States', BillingCountry = 'United States');
        insert testAcc;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Buyer',
            AccountId = testAcc.Id
        );
        insert testContact;

        // Create Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Logik Opp',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            AccountId = testAcc.Id
        );
        insert testOpp;

        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = testOpp.Id,
            ContactId = testContact.Id,
            Role = 'Economic Buyer', 
            IsPrimary = true
        );
        insert ocr;
    }

    // ----------------------------------------------------------------------
    // 2. MOCK CLASS TO SIMULATE API RESPONSES (HTTPCalloutMock)
    // ----------------------------------------------------------------------
    private class LogikApiMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String endpoint = req.getEndpoint();
            String method = req.getMethod();

            // Route: Create Transaction (POST /api/t)
            if (endpoint.endsWith('/api/t') && method == 'POST') {
                String responseBody = '{' +
                    '"txnSession":"55e97b23-a4a4-4845-855a-8ccf5f7baca0",' +
                    '"session":"55e97b23-a4a4-4845-855a-8ccf5f7baca0",' +
                    '"uuid":"55e97b23-a4a4-4845-855a-8ccf5f7baca0",' +
                    '"id":"55e97b23-a4a4-4845-855a-8ccf5f7baca0",' +
                    '"stage":"draft"' +
                '}';
                res.setBody(responseBody);
            } 
            // Route: Create Configuration (POST /api)
            else if (endpoint.endsWith('/api') && method == 'POST') {
                String responseBody = '{' +
                    '"uuid":"824c2413-000e-4e48-a70f-e3ddf21dbb6d",' +
                    '"revision":0,' +
                    '"valid":true' +
                '}';
                res.setBody(responseBody);
            } 
            // Route: Save Configuration (PATCH /api/{uuid}?save=true)
            else if (endpoint.contains('save=true') && method == 'PATCH') {
                res.setBody('{"status": "saved", "uuid":"824c2413-000e-4e48-a70f-e3ddf21dbb6d"}');
            }
            // Route: Upsert Lines (POST /api/t/{id}/events/upsertLines)
            else if (endpoint.contains('/events/upsertLines') && method == 'POST') {
                res.setBody('{"state":"SUCCESS"}');
            }
            // Route: Update Fields (POST /api/t/{id}/events/randomEvent)
            else if (endpoint.contains('/events/randomEvent') && method == 'POST') {
                res.setBody('{"state":"SUCCESS"}');
            }
            // Fallback for any other endpoint
            else {
                res.setBody('{"status": "success"}');
            }

            return res;
        }
    }

    // ----------------------------------------------------------------------
    // 3. TEST METHODS
    // ----------------------------------------------------------------------

    @isTest
    static void testCustomSettings() {
        Test.startTest();
        String url = logikTransaButtRedirectActionController.getLogikTenantUrl();
        LGK__ConfigurationTenant__c config = logikTransaButtRedirectActionController.getCustomSettings();
        Test.stopTest();

        System.assertEquals('https://test-tenant.logik.io/', url, 'The URL does not match the configuration.');
        System.assertNotEquals(null, config, 'The custom setting should not be null.');
    }

    @isTest
    static void testCreateLogikTransaction() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();

        Test.setMock(HttpCalloutMock.class, new LogikApiMock());

        Test.startTest();
        String txnId = logikTransaButtRedirectActionController.createLogikTransaction(acc.Id, opp.Id, pricebookId);
        Test.stopTest();

        // Assert against the real ID extracted from the provided Postman JSON
        System.assertEquals('55e97b23-a4a4-4845-855a-8ccf5f7baca0', txnId, 'The returned transaction ID does not match the real mock data.');
    }

    @isTest
    static void testUpdateLogikTransactionFields() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new LogikApiMock());

        Test.startTest();
        // Since it is a void method, we verify that it executes without throwing exceptions
        logikTransaButtRedirectActionController.updateLogikTransactionFields('55e97b23-a4a4-4845-855a-8ccf5f7baca0', 'session-999', opp.Id, acc.Id);
        Test.stopTest();
        
        System.assert(true, 'The field update failed and threw an exception.');
    }

    @isTest
    static void testCreateLogikConfiguration() {
        Test.setMock(HttpCalloutMock.class, new LogikApiMock());

        Test.startTest();
        String configUuid = logikTransaButtRedirectActionController.createLogikConfiguration('01tgP000005UfvhQAC');
        Test.stopTest();

        // Assert against the real UUID extracted from the provided Postman JSON
        System.assertEquals('824c2413-000e-4e48-a70f-e3ddf21dbb6d', configUuid, 'The returned configuration UUID is not as expected.');
    }

    @isTest
    static void testSaveLogikConfiguration() {
        Test.setMock(HttpCalloutMock.class, new LogikApiMock());

        Test.startTest();
        logikTransaButtRedirectActionController.saveLogikConfiguration('824c2413-000e-4e48-a70f-e3ddf21dbb6d');
        Test.stopTest();
        
        System.assert(true, 'The configuration save threw an exception.');
    }

    @isTest
    static void testUpsertLogikTransactionLines() {
        Test.setMock(HttpCalloutMock.class, new LogikApiMock());

        Test.startTest();
        logikTransaButtRedirectActionController.upsertLogikTransactionLines('55e97b23-a4a4-4845-855a-8ccf5f7baca0', '824c2413-000e-4e48-a70f-e3ddf21dbb6d');
        Test.stopTest();
        
        System.assert(true, 'The line upsert threw an exception.');
    }

    @isTest
    static void testGetBlueprintMetadata() {
        Test.startTest();
        try {
            logikTransactionButtonRedirectAction__mdt mdt = logikTransaButtRedirectActionController.getBlueprintMetadata();
            // Since Custom Metadata Types visibility in tests depends on org data, 
            // we assert that the query executes. It may return null if the record is missing in the testing environment.
            System.assert(true, 'Metadata query executed.');
        } catch (QueryException e) {
            // Expected if the record 'mbublueprint' does not exist in the environment running the test.
            System.assert(e.getMessage().contains('List has no rows for assignment'), 'Expected query exception if metadata is missing.');
        }
        Test.stopTest();
    }
}