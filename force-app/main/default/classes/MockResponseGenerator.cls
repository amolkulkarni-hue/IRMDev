/**
 *   Class:        MockResponseGenerator
 * 
 *   Author:        Amit Gayal (NeuraFlash LLC)
 * 
 *   Purpose:      This class generates valid mock response for API calls.
 * 
 *   Requirements:    IMSLB-30
 * 
 *   Change History:    
 * 
 *   Developer          Date        Description
 * ----------------------------------------------------------------------------------------
 */
 
@isTest
global class MockResponseGenerator implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"test": {"id":2, "name":"Test"}}');
        response.setStatusCode(200);
        response.setStatus('200 OK');
        return response; 
    }
}