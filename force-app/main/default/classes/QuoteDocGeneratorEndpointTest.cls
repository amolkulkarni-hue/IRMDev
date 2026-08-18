@isTest
private class QuoteDocGeneratorEndpointTest {

    // ----------------------------------------------------------------------
    // 1. HTTP CALLOUT MOCK
    // Simulates the responses from GCP Cloud Run (200 OK and 500 Error)
    // ----------------------------------------------------------------------
    private class CloudRunMock implements HttpCalloutMock {
        private Integer statusCodeToReturn;

        public CloudRunMock(Integer statusCode) {
            this.statusCodeToReturn = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCodeToReturn);

            if (this.statusCodeToReturn == 200) {
                // Simulate the successful GCP response
                String jsonBody = '{' +
                    '"status": "success",' +
                    '"files": [' +
                        '{ "fileName": "Oppty Product LWC test 1 - US - Standard.pdf", "base64": "VGVzdA==" }' + 
                    ']' +
                '}';
                res.setBody(jsonBody);
            } else {
                // Simulate an error response
                res.setBody('{"error": "Internal Server Error"}');
            }
            
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

        // Query the Profile
        Profile im_sales_Profile = [SELECT Id FROM Profile WHERE Name = 'IM_Sales' LIMIT 1];
        
        // Create the Test User
        User IM_Sales_User = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Alias = 'tadmin',
            Email = 'testadmin_' + DateTime.now().getTime() + '@example.com',
            Username = 'testadmin_' + DateTime.now().getTime() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            ProfileId = im_sales_Profile.Id,
            Country = 'United States'
        );

        insert IM_Sales_User;


        List<PermissionSetGroup> psgList = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Sales_Operations_Business_Partner_PSG' LIMIT 1];
        
        if (!psgList.isEmpty()) {
            PermissionSetAssignment psgAssignment = new PermissionSetAssignment(
                AssigneeId = IM_Sales_User.Id,
                PermissionSetGroupId = psgList[0].Id 
            );
            insert psgAssignment;
            
 
            Test.calculatePermissionSetGroup(psgList[0].Id); 
        }

        //Query the Permission Set
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Logik_Custom_CPQ_PS' LIMIT 1];
        
        //Assign the Permission Set to the newly created User
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = IM_Sales_User.Id,
            PermissionSetId = ps.Id
        );
        insert psa;


        System.runAs(IM_Sales_User) {
            // Create test Account
            Account acc = new Account(
                Name = 'ABC Account',
                BillingCity = 'Test City',
                BillingStreet = '123 Test St',
                BillingState = 'TS',
                BillingPostalCode = '12345',
                BillingCountry = 'United States'
            );
            insert acc;

            // Create test transaction record
            Opportunity txn = new Opportunity(
                Name = 'Oppty Product LWC test 1',
                StageName = '1 - Qualification',
                CloseDate = Date.today(),
                AccountId = acc.Id
            );
            insert txn;
        }
    }

    // ----------------------------------------------------------------------
    // 3. HELPER METHOD TO GENERATE PAYLOAD
    // ----------------------------------------------------------------------
    private static String generateLogikPayload(String transactionId, String accountId) {
        Map<String, Object> logikPayload = new Map<String, Object>{
            'transactionId' => transactionId,
            'accountId' => accountId,
            'oppId' => '006gP00000A23s5QAB',
            'effectiveDate' => '',
            'accountName' => 'ABC Account',
            'opportunityName' => 'Oppty Product LWC test 1',
            'iMGA' => 'IM_WOODSIDE_ENERGY',
            'total' => '0',
            'totalDiscountAmount' => '0',
            'netTotal' => '0',
            'extendedListTotal' => '0',
            'subTotal' => '0',
            'quoteName' => 'Quote#1786056746224',
            'lines' => new List<Object>{
                new Map<String, Object>{
                    'productName' => 'MBU Blueprint',
                    'productCode' => 'MBUBlueprint',
                    'quantity' => '1',
                    'price' => '0',
                    'extPrice' => '0',
                    'uom' => '',
                    'productGroup' => ''
                },
                new Map<String, Object>{
                    'productName' => 'Storage, Carton',
                    'productCode' => '01100-0514',
                    'quantity' => '100',
                    'price' => '1.66',
                    'extPrice' => '0',
                    'uom' => '',
                    'productGroup' => 'StorageCarton'
                },
                new Map<String, Object>{
                    'productName' => 'SS - One Time Shred',
                    'productCode' => 'CS1SHRED',
                    'quantity' => '2.4',
                    'price' => '1',
                    'extPrice' => '0',
                    'uom' => '',
                    'productGroup' => 'Shred'
                }
            }
        };

        return JSON.serialize(logikPayload);
    }

    // ----------------------------------------------------------------------
    // 4. TEST METHODS
    // ----------------------------------------------------------------------

    @isTest
    static void testGenerateDoc_NewDocument_200() {
        User IM_Sales_User = [SELECT Id FROM User WHERE Alias = 'tadmin' LIMIT 1];

        System.runAs(IM_Sales_User) {
            // Retrieve generated data
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Opportunity txn = [SELECT Id FROM Opportunity LIMIT 1];

            // Configure the REST context
            RestRequest req = new RestRequest();
            req.requestURI = '/services/apexrest/generateQuoteDoc/';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(generateLogikPayload(txn.Id, acc.Id));
            RestContext.request = req;

            // Set the Mock to return a 200 OK
            Test.setMock(HttpCalloutMock.class, new CloudRunMock(200));

            Test.startTest();
            Map<String, String> response = QuoteDocGeneratorEndpoint.generateDoc();
            Test.stopTest();

            // Assertions
            System.assertNotEquals(null, response, 'The response should not be null.');
            System.assert(response.containsKey('publicLink'), 'The response must contain the publicLink.');

            // Verify that the ContentVersion was created
            List<ContentVersion> cvList = [SELECT Id, Title, FirstPublishLocationId FROM ContentVersion WHERE Title = 'Oppty Product LWC test 1 - US - Standard.pdf'];
            System.assertEquals(1, cvList.size(), 'Exactly 1 new file should have been inserted.');
            System.assertEquals(txn.Id, cvList[0].FirstPublishLocationId, 'The file must be linked to the transaction.');
        }
    }


    @isTest
    static void testGenerateDoc_ErrorResponse() {
        User IM_Sales_User = [SELECT Id FROM User WHERE Alias = 'tadmin' LIMIT 1];

        System.runAs(IM_Sales_User) {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Opportunity txn = [SELECT Id FROM Opportunity LIMIT 1];

            // Configure the REST context
            RestRequest req = new RestRequest();
            req.requestURI = '/services/apexrest/generateQuoteDoc/';
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueOf(generateLogikPayload(txn.Id, acc.Id));
            RestContext.request = req;

            // Set the Mock to return a 500 Error
            Test.setMock(HttpCalloutMock.class, new CloudRunMock(500));

            Test.startTest();
            Map<String, String> response = QuoteDocGeneratorEndpoint.generateDoc();
            Test.stopTest();

            // Assertions
            System.assertNotEquals(null, response, 'The response should not be null.');
            System.assert(response.containsKey('error'), 'The response must contain an error message.');
            System.assertEquals('Cloud Run failed with status code 500', response.get('error'), 'The error message must match the expected output.');
        }
    }
}