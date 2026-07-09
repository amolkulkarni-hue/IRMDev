/*****************************************************************************************************
* Class: QTB_MockPricefxCalloutRenewal
* Author: Accenture
* Purpose: This is mock response for pricefx renewal
* Change History: 6/15/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   
*******************************************************************************************************/

global class QTB_MockPricefxCalloutRenewal implements HttpCalloutMock{
    global HTTPResponse respond(HTTPRequest request){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"resultName": "ReturnList","resultLabel": "Return List","result": {"currentRateInfo": [{"billCode": "201","targetPrice": 0.3,"floorPrice": 0.49,"expertPrice": 0.60}],"businessUnit": "RM"}}]');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
    }

}