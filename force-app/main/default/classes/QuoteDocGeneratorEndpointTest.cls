@isTest
private class QuoteDocGeneratorEndpointTest {

    // ----------------------------------------------------------------------
    // 1. HTTP CALLOUT MOCK
    // Simulates the responses from Google Apps Script (200 and 302)
    // ----------------------------------------------------------------------
    private class GoogleAppScriptMock implements HttpCalloutMock {
        private Integer statusCodeToReturn;

        public GoogleAppScriptMock(Integer statusCode) {
            this.statusCodeToReturn = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();

            // Simulate the redirect scenario (302)
            if (this.statusCodeToReturn == 302 && req.getMethod() == 'POST') {
                res.setStatusCode(302);
                res.setHeader('Location', 'https://mock-redirect-url.google.com');
                return res;
            }

            // Simulate the final success scenario (200 OK)
            res.setStatusCode(200);
            String jsonBody = '{' +
                '"status": "success",' +
                '"files": [' +
                    '{ "fileName": "Test Document.pdf", "base64": "VGVzdA==" }' + 
                ']' +
            '}';
            res.setBody(jsonBody);
            return res;
        }
    }

    // ----------------------------------------------------------------------
    // 2. TEST DATA SETUP
    // ----------------------------------------------------------------------
    @TestSetup
    static void makeData() {

        // --- BYPASS THE ACCOUNT TRIGGER ---
        // This prevents AccountHelper OpportunityHelper and the Country Validation from firing during the test
        AccountTriggerHandler.skipTriggerExecutionTestClass = true;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        // Create test Account
        Account acc = new Account(
            Name = 'Test Account',
            BillingCity = 'Test City',
            BillingStreet = '123 Test St',
            BillingState = 'TS',
            BillingPostalCode = '12345',
            BillingCountry = 'United States');
        insert acc;

        // Create test transaction record
        Opportunity txn = new Opportunity(
            Name = 'Test Transaction',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert txn;
    }

    // ----------------------------------------------------------------------
    // 3. TEST METHODS
    // ----------------------------------------------------------------------

    @isTest
    static void testGenerateDoc_NewDocument_200() {
        // Retrieve generated data
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity txn = [SELECT Id FROM Opportunity LIMIT 1];

        // Prepare the mocked payload from Logik.io
        String jsonPayload = '{"transactionId": "' + txn.Id + '", "accountId": "' + acc.Id + '"}';

        // Configure the REST context
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/generateQuoteDoc/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;

        // Set the Mock to return a direct 200 OK
        Test.setMock(HttpCalloutMock.class, new GoogleAppScriptMock(200));

        Test.startTest();
        // Invoke the endpoint - Correctly expecting a Map
        Map<String, String> response = QuoteDocGeneratorEndpoint.generateDoc();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, response, 'The response should not be null.');
        System.assert(response.containsKey('publicLink'), 'The response must contain the publicLink.');

        // Verify that the ContentVersion was created
        List<ContentVersion> cvList = [SELECT Id, Title, FirstPublishLocationId FROM ContentVersion WHERE Title = 'Test Document.pdf'];
        System.assertEquals(1, cvList.size(), 'Exactly 1 new file should have been inserted.');
        System.assertEquals(txn.Id, cvList[0].FirstPublishLocationId, 'The file must be linked to the transaction.');
    }

    @isTest
    static void testGenerateDoc_WithRedirect_302() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity txn = [SELECT Id FROM Opportunity LIMIT 1];

        String jsonPayload = '{"transactionId": "' + txn.Id + '", "accountId": "' + acc.Id + '"}';

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/generateQuoteDoc/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;

        // Set the Mock to return a 302 and force the second GET call
        Test.setMock(HttpCalloutMock.class, new GoogleAppScriptMock(302));

        Test.startTest();
        // Correctly expecting a Map
        Map<String, String> response = QuoteDocGeneratorEndpoint.generateDoc();
        Test.stopTest();

        // Validate successful execution despite the redirect
        System.assertNotEquals(null, response, 'The response should not be null after the redirect.');
        List<ContentVersion> cvList = [SELECT Id FROM ContentVersion WHERE Title = 'Test Document.pdf'];
        System.assertEquals(1, cvList.size(), 'The document should have been created after the 302 redirect.');
    }
}