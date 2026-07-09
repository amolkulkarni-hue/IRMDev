@isTest
global class QTB_IRMToVetex_AuthorizationMockTest {
    @isTest static void testRespond() {
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new QTB_IRMToVetex_AuthorizationMock());

        // Prepare HTTP request
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://fake.endpoint.test');
        req.setMethod('GET');

        // Perform callout
        Http http = new Http();
        HttpResponse res = http.send(req);

        // Verify the response returned by the mock
        System.assertEquals(200, res.getStatusCode(), 'Status code should be 200');
        System.assertEquals('OK', res.getStatus(), 'Status message should be OK');
        
        String body = res.getBody();
        System.assert(body.contains('"JWT":'), 'Response body should contain JWT key');
        
        // Optional: Verify full expected JWT token starts as in mock
        System.assert(body.startsWith('{"JWT": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzUxMiIsImtpZCI6ImlybS1qd3QtcHJpdmF0ZS1rZXkifQ'), 'JWT token format should match');
    }
}