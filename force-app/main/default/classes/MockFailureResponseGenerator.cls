/**
 *   Class:        MockFailureResponseGenerator
 * 
 *   Author:        Amit Gayal (NeuraFlash LLC)
 * 
 *   Purpose:      This class creates invalid mock response for API calls.
 * 
 *   Requirements:    IMSLB-30
 * 
 *   Change History:    
 * 
 *   Developer          Date        Description
 * ----------------------------------------------------------------------------------------
 */

@IsTest
global with sharing class MockFailureResponseGenerator implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"test": {"id":2, "name":"Test"}}');
        response.setStatusCode(404);
        return response;
    }
}