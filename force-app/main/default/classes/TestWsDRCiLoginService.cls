@isTest
global class TestWsDRCiLoginService {
   
   static testMethod void runTest() {
           
           Test.setMock(WebServiceMock.class, new MockCalloutClass());
           Test.StartTest();
           WsDRCiLoginService svc = new WsDRCiLoginService();
           WsDRCiLoginService.LoginServiceSoap login = new WsDRCiLoginService.LoginServiceSoap();
           WsDRCiLoginService.LoginRequest_element req= new WsDRCiLoginService.LoginRequest_element ();
           WsDRCiLoginService.LoginResponse_element loginRes = new WsDRCiLoginService.LoginResponse_element();
           loginRes = login.Login('x'
                                ,'y'
                                ,'z'
                                ,'e'
                                ,'SESSION'
                                ,'b'); 
          Test.StopTest();
   }
           
    global class MockCalloutClass implements WebServiceMock {
   
     global   void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
       WsDRCiLoginService.LoginResponse_element login= 
           new WsDRCiLoginService.LoginResponse_element();
  
       response.put('response_x', login);
    }

        }
            
}