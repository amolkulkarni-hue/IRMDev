/*****************************************************************************************************
* Class			: QTB_IRMToVetex_AuthorizationMock
* Author		: Virtusa
* Developer     : Shailesh
* Purpose		: This is mock response for calculate tax of vertex
* Change History: 08/08/2020 
* Developer    	 Date           	Description
* ------------------------------------------------------------------------------------------- 
* Virtusa		08/08/2021       #857 -- vertex tax service call
*******************************************************************************************************/
global with sharing class QTB_IRMToVetex_AuthorizationMock implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest request){
        	HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
        	res.setBody('{"JWT": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzUxMiIsImtpZCI6ImlybS1qd3QtcHJpdmF0ZS1rZXkifQ.ew0KICAiaXNzIjoid2cxMTAxLm51cy5pcm9ubW91bnRhaW4uY29tIiwNCiAgImlhdCI6MTYyNzI3OTQyNywNCiAgImF1ZCI6IlNhbGVzRm9yY2VfUXVvdGV0b0JpbGwiLA0KICAianRpIjoiMTkyMTg1NWQtZDdhYi00MWM0LTlmMzItNWU5NjdlODY4ODQ1IiwNCiAgInN1YiI6IlNhbGVzRm9yY2VfUXVvdGV0b0JpbGwiLCAgDQogICJ0b2tlbl90eXBlIjogIkJlYXJlciIsDQogICJleHAiOjE2MjcyODMwMjcsDQogICJyb3V0aW5nX3N5c3RlbSI6InVzZXJJRFA6Q0FMREFQIiwNCiAgImV4cGlyZXNfaW4iOjM2MDAsDQogICJyZWZyZXNoX3Rva2VuIjogIjc1ZGY1ZWMxLWM1Y2ItNGYxZS1hMDY4LThmNjZlZmIzOWEyOSIsDQogICJyZWZyZXNoX2V4cCI6MzYwMA0KfQ.UD0FYy2lbkkebNHReh8rohW_HuPGfNLQ7hBXI_p64DX54dAiLqc_lHtCom3YW0AX01NRFCA0O-u5JdzahajgPb7I33e9B9R1bl9RkGLIHRkQR0WHCLT12IizMjlQDG93HdoiS7aYtpLM5uin-Otq6eJTdzawIbpIM6tU-sWNdgwpGD7FtzeW-7ZL1UmBtFK_4Rkzv8fhF-fCsw9piyCMb48h8FlEBhtJvS2_8P-SLBogUQa7LqkO4P6HUpMcenFGwTu_9XpLgNQfVOqOmY8L-egmFgWSxcETI_wT56inxLA-EDaClERV75Vq0TtD-rplJ1yTB1UNjySovBwQMaY3bw"}');
        	res.setStatusCode(200);
            res.setStatus('OK');
            return res;
    }
}