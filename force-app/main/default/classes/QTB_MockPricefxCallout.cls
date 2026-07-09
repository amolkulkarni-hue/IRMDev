/*****************************************************************************************************
* Class: QTB_MockPricefxCallout
* Author: Accenture
* Purpose: This is mock response for pricefx for new customer
* Change History: 6/15/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   
*******************************************************************************************************/

global with sharing class QTB_MockPricefxCallout implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest request){
        	HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
        	res.setBody('[{"resultName": "ReturnList","resultLabel": "Return List","result": {"billCodeRates": [{"billCode": "201","targetPrice": 0.3}]}}]');
        	res.setStatusCode(200);
            res.setStatus('OK');
            return res;
    }

}