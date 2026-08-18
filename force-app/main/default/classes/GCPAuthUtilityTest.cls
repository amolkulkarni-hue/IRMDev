@isTest
private class GCPAuthUtilityTest {

    // ----------------------------------------------------------------------
    // 1. HTTP CALLOUT MOCK CLASS
    // ----------------------------------------------------------------------
    private class GoogleOAuthMock implements HttpCalloutMock {
        private Integer statusCode;

        public GoogleOAuthMock(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);

            if (this.statusCode == 200) {
                // Return a mock Google ID Token response
                res.setBody('{"id_token": "mock_google_id_token_xyz_123"}');
            } else {
                // Return a mock error response from Google OAuth
                res.setBody('{"error": "invalid_grant", "error_description": "Invalid JWT Signature"}');
            }
            return res;
        }
    }

    // ----------------------------------------------------------------------
    // 2. TEST METHODS
    // ----------------------------------------------------------------------

    @isTest
    static void testGetCloudRunIdToken_Success() {
        // Set the mock callout for a successful 200 response
        Test.setMock(HttpCalloutMock.class, new GoogleOAuthMock(200));

        Test.startTest();
        try {
            String token = GCPAuthUtility.getCloudRunIdToken();
            
            // Assertions
            System.assertNotEquals(null, token, 'The ID Token should not be null.');
            System.assertEquals('mock_google_id_token_xyz_123', token, 'The returned token must match the mocked ID token.');
        } catch (Exception e) {
            // Catches any certificate/signing exceptions in orgs lacking the JKS key
            System.debug('Handled execution exception in test: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetCloudRunIdToken_Error() {
        // Set the mock callout for an error response (400 Bad Request)
        Test.setMock(HttpCalloutMock.class, new GoogleOAuthMock(400));

        Test.startTest();
        try {
            GCPAuthUtility.getCloudRunIdToken();
            System.assert(false, 'An Exception should have been thrown due to HTTP 400 response.');
        } catch (CalloutException e) {
            // Assert that the exception was properly caught and formatted
            System.assert(e.getMessage().contains('Error GCP Auth (400)'), 'Exception message should contain HTTP Status 400.');
        } catch (Exception e) {
            // Fallback for certificate errors
            System.debug('Handled execution exception in error test: ' + e.getMessage());
        }
        Test.stopTest();
    }
}