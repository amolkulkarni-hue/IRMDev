/**
 * 	Class:				HttpHelperTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for HttpHelper apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */

@isTest
private class HttpHelperTest {

    @isTest 
    static void getQueryMapTest(){
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://test_query.com/?q=test');
        
        Test.startTest();
        Map<String,Object> mapReturned = HttpHelper.getQueryMap(request);
        String stringReturned = HttpHelper.getQueryString(mapReturned);
        Test.stopTest();
        
        Assert.isTrue(mapReturned != null, 'Could not map correctly');
    }
    
    @isTest
    static void updateQueryStringTest(){
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://test_query.com/?q=test');
        
        Test.startTest();
        HttpHelper.updateQueryString(request, 'updateEndPoint');
        Test.stopTest();
        
        Assert.isTrue(request.getEndpoint() != null, 'Could not update endpoint correctly');
    }
    
    @isTest
    static void getConnectRequestTest(){
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://test_query.com/?q=test');
        Map<String,Object> queryParams = HttpHelper.getQueryMap(request);
        Map<String,String> headers = new Map<String, String>{'Bearer' => 'QWERTYUIOJHBVCFDERTYUJNB'};
            
        Test.startTest();
        HttpRequest req = HttpHelper.getConnectRequest('https://test_query.com/?q=test', 'GET', headers, queryParams, 'Test');
        HttpHelper.printRequest(req);
        HttpResponse response = HttpHelper.getResponse(req);
        HttpHelper.printResponse(response);
        Test.stopTest();
        
        Assert.isTrue(req != null, 'Request not created');
        Assert.isTrue(response != null, 'Response not returned');
	}
}