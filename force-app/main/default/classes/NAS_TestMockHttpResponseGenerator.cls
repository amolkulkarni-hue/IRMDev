/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Implementation of HttpCalloutMock interface to respond to Unit test http requests.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class NAS_TestMockHttpResponseGenerator implements HttpCalloutMock {
    /**
     * @name respond
     * @description Returns a HTTPResponse based on the request type.
    **/
  public HTTPResponse respond(HTTPRequest req) {
        String response = null;
        Integer statusCode = 200;  
        System.debug('Test Http respoonse>>>>.'+req.getEndpoint());
        System.debug(req.getEndpoint());
        if(req.getEndpoint() == NAS_Constants.URL_SKP_API_GET_REPLICATION_EVENTS)
            response = NAS_TestConstants.SKP_API_GET_REPLICATION_EVENTS_RESPONSE_SUCCESS;
        if(req.getEndpoint() == NAS_Constants.URL_SKP_API_UPDATE_REPLICATION_EVENTS)
            response = NAS_TestConstants.SKP_API_UPDATE_REPLICATION_EVENTS_RESPONSE_SUCCESS;
        if(req.getEndpoint() == NAS_Constants.URL_SKP_API_UPDATE_COMMUNICATOR)
            response = NAS_TestConstants.SKP_API_UPDATE_COMMUNICATOR_RESPONSE_SUCCESS;
        else if(req.getEndpoint() == NAS_Constants.URL_WSG_AUTHORIZATION)
            response = NAS_TestConstants.WSG_AUTHORIZATION_RESPONSE_SUCCESS;
        else if(req.getEndpoint() == NAS_Constants.URL_SKP_API_PIN_VERIFICATION)
        {
            Map<String, Object> requestBodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
            if(String.valueOf(((Map<String, Object>) requestBodyMap.get('filter')).get('IRMApplication')) == 'SKP') {
                if(String.valueOf(((Map<String, Object>) requestBodyMap).get('password')) == 
                NAS_Utilities.encryptAES128WithSKPKey(NAS_TestConstants.CORRECT_IMC_SKP_PIN)) {
                    response = NAS_TestConstants.PIN_VERIFICATION_SKP_API_RESPONSE_SUCCESS;
                    statusCode = 200;
                }
                else
                {
                    response = NAS_TestConstants.PIN_VERIFICATION_SKP_API_RESPONSE_FAILURE;
                    statusCode = 400;
                }
            }
            else if(String.valueOf(((Map<String, Object>) requestBodyMap.get('filter')).get('IRMApplication')) == 'IMC') {
                if(String.valueOf(((Map<String, Object>) requestBodyMap).get('PIN')) == 
                NAS_TestConstants.CORRECT_IMC_SKP_PIN) {
                    response = NAS_TestConstants.PIN_VERIFICATION_SKP_API_RESPONSE_SUCCESS;
                    statusCode = 200;
                }
                else
                {
                    response = NAS_TestConstants.PIN_VERIFICATION_IMC_API_RESPONSE_FAILURE;
                    statusCode = 400;
                }
            }
        }
        else if(req.getEndpoint() == NAS_Constants.URL_SKP_API_GET_SERVICE_MARKET) {
            Map<String, Object> requestBodyMap = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());
            if(Integer.valueOf(requestBodyMap.get('orderNumber')) == 
               NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_ORDER_NUMBER) {
                response = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_RESPONSE_SUCCESS_ON;
                statusCode = 200;
            }
            else if(String.valueOf(requestBodyMap.get('zipCode')) == 
               NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_ZIP_CODE && 
               String.valueOf(requestBodyMap.get('country')) == 
               NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_COUNTRY_CODE) {
                response = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_RESPONSE_SUCCESS_ZIP;
                statusCode = 200;
            }
            else if(Integer.valueOf( requestBodyMap.get('orderNumber')) ==  null &&
                    requestBodyMap.get('zipCode') == null && 
                    requestBodyMap.get('country') == null) {
                response = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_RESPONSE_NO_PARAM;
                statusCode = 400;
            }
            else if(String.valueOf(requestBodyMap.get('orderNumber')) == 
               NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_ON_SMALL) {
                response = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_RESPONSE_ON_SMALL;
                statusCode = 400;
            }
            else if(String.valueOf(requestBodyMap.get('zipCode')) == 
               NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_ZIP_CODE && 
               requestBodyMap.get('country') == null) {
                response = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_RESPONSE_ZIP_NO_COUNTRY;
                statusCode = 400;
            }
            else if(String.valueOf(requestBodyMap.get('zipCode')) == 
               NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_ZIP_LARGE && 
               requestBodyMap.get('country') != null) {
                response = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_RESPONSE_ZIP_LARGE;
                statusCode = 400;
            }
            else if(requestBodyMap.get('zipCode') ==  null && 
               String.valueOf(requestBodyMap.get('country')) == 
               NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_COUNTRY_CODE) {
                response = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_RESPONSE_MISSING_ZIP;
                statusCode = 400;
            }
            else if(String.valueOf(requestBodyMap.get('zipCode')) ==
               NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_ZIP_MARKET_NOT_FOUND) {
                response = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_RESPONSE_MARKET_NOT_FOUND;
                statusCode = 400;
            }
            else if(String.valueOf(requestBodyMap.get('zipCode')) ==
               NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_ZIP_NO_TRANSPORTATION_ZONE) {
                response = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_RESPONSE_NO_TRANSPORTATION_ZONE;
                statusCode = 200;
            }
            else if(String.valueOf(requestBodyMap.get('zipCode')) ==
               NAS_TestConstants.GET_SERVICE_MARKET_INCORRECT_ZIP_CODE) {
                response = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_RESPONSE_ZIP_NOT_FOUND;
                statusCode = 404;
            }
            else if(String.valueOf(requestBodyMap.get('country')) ==
               NAS_TestConstants.GET_SERVICE_MARKET_INCORRECT_COUNTRY_CODE) {
                response = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_RESPONSE_COUNTRY_NOT_FOUND;
                statusCode = 400;
            }
            else if(String.valueOf(requestBodyMap.get('country')) ==
               NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_COUNTRY_UNSUPPORTED) {
                response = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_RESPONSE_COUNTRY_UNSUPPORTED;
                statusCode = 406;
            }
            else if(Integer.valueOf(requestBodyMap.get('orderNumber')) ==
               NAS_TestConstants.GET_SERVICE_MARKET_INEXISTENT_ORDER_NUMBER) {
                response = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_RESPONSE_ON_NOT_FOUND;
                statusCode = 404;
            }
        }
        else if (req.getEndpoint() == NAS_Constants.URL_SKP_API_INFOWIN_CUST_INSTR)
        {
            Map<String, Object> requestBodyMap1 = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());    
            String response1 = NAS_TestConstants.GET_CUSTOMER_INSTRUCTION_SKP_API_RESPONSE_SUCCESS_ON;
            Map<String, Object> requestBodyMap2 = (Map<String, Object>) JSON.deserializeUntyped(response1);
            if(requestBodyMap2.get('customerins') =='ins'){
                response = NAS_TestConstants.GET_CUSTOMER_INSTRUCTION_SKP_API_RESPONSE_SUCCESS_ON;
                statusCode = 200;
            }else if(requestBodyMap2.get('customerins') !='ins'){ 
                response = NAS_TestConstants.GET_CUSTOMER_INSTRUCTION_API_FAILURE_RESPONSE;
                statusCode = 404;   
            }   
        }
        else if(req.getEndpoint() == NAS_Constants.URL_SKP_API_INFOWIN_CUST_NOTES)
        {
           Map<String, Object> requestBodyMap2 = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());      
            String response1 = NAS_TestConstants.GET_NOTES_API_SUCCESS_RESPONSE;
            System.debug('TEST Response>>>>'+response1);
            Map<String, Object> requestBodyMap3 = (Map<String, Object>) JSON.deserializeUntyped(response1);
            System.debug('Test Value>>>>'+requestBodyMap3);
            if(requestBodyMap3.get('deerType')=='DER'){
                response = NAS_TestConstants.GET_DEER_NOTES_API_SUCCESS_RESPONSE;
                statusCode = 200;
            } 
            else if(requestBodyMap3.get('type')=='QA'){
                response = NAS_TestConstants.GET_CUSTOMER_INSTRUCTION_API_FAILURE_RESPONSE;
                statusCode = 404;
            } else if(requestBodyMap3.get('type')=='BIL'){
                response = NAS_TestConstants.GET_BILL_NOTES_API_SUCCESS_RESPONSE;
                statusCode = 404;
            }
        }
        else if(req.getEndpoint() == NAS_Constants.URL_SKP_API_INFOWIN_SRVC_PRFL){
            Map<String, Object> requestBodyMap2 = (Map<String, Object>) JSON.deserializeUntyped(req.getBody());      
            String response1 = NAS_TestConstants.GET_SERVICE_PROFILE_API_RESPONSE;
            System.debug('TEST Response>>>>'+response1);
            Map<String, Object> requestBodyMap3 = (Map<String, Object>) JSON.deserializeUntyped(response1);
            if(requestBodyMap3.get('override')==false){
                response = NAS_TestConstants.GET_SERVICE_PROFILE_API_RESPONSE1;
                statusCode = 200;
            }else if(requestBodyMap3.get('override')==true){
                statusCode = 200;
                response = NAS_TestConstants.GET_SERVICE_PROFILE_API_RESPONSE;
            } else if(requestBodyMap3.get('override')!=true){
                statusCode = 400;
                response = NAS_TestConstants.GET_CUSTOMER_INSTRUCTION_API_FAILURE_RESPONSE;
            }
        }
        System.debug('Test Response>>>>>'+response);
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody(response);
        res.setStatusCode(statusCode); 
        return res;
    }
}