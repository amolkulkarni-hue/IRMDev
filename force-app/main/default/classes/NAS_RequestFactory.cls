/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Apex factory method to implement out bound https requests.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public without sharing class NAS_RequestFactory {
	/**
     * @name requestAuthorizationToken
     * @description Implementation of outbound request to WSG Gateway for authorization token.
    **/
    public static String requestAuthorizationToken()
    {
        String NAS_WSG_AUTHORIZATION_TOKEN = 'UNAVAILABLE';
        Map<String, Object> authorizationResponse = null;
        String endPoint = NAS_RequestFactory.getEndpoint(NAS_Constants.RQTYPE_WSG_AUTHORIZATION);
        system.debug('Auth endPoint=='+endPoint);
        system.debug('client_key=='+NAS_Constants.WSG_CLIENT_KEY);
        Map<String, String> requestHeader = new Map<String, String>();
        requestHeader.put('client_key', NAS_Constants.WSG_CLIENT_KEY);
        requestHeader.put('client_secret', NAS_Constants.WSG_CLIENT_SECRET);
        requestHeader.put('username', NAS_Constants.WSG_USERNAME);
        requestHeader.put('password', NAS_Constants.WSG_PASSWORD);
        requestHeader.put('IRM_APP_ID', NAS_Constants.WSG_IRM_APP_ID);
        HttpResponse res = NAS_RequestFactory.postHttpRequest(endPoint, requestHeader, 
                                               null);
        if(res != null)
        	authorizationResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        if(authorizationResponse != null) {
            NAS_WSG_AUTHORIZATION_TOKEN = (String)authorizationResponse.get('JWT');
        }
        else {
            NAS_ErrorLogger.log(NAS_RequestFactory.class.getName(), 
                                JSON.serialize(res), JSON.serialize(requestHeader));
        }
        return NAS_WSG_AUTHORIZATION_TOKEN;
    }
    public static String getAuthorizationToken(Boolean reset)
    {
        return (String) NAS_Utilities.getOrgCache(NAS_Constants.KEY_ORG_CACHE_WSG_AUTHORIZATION_TOKEN, reset);
    }
    /**
     * @name postSKPHttpRequest
     * @description Implementation of outbound request to SKP API. Based on the request type, it resolves the
     * endpoint, sends a post request using the supplied parameters.
    **/
    public static Map<String, Object> postSKPHttpRequest(String requestType, Map<String, Object> parameters)
    {
        return postSKPHttpRequest(requestType, parameters, false);
    }
    /**
     * @name postSKPHttpRequest
     * @description Implementation of outbound request to SKP API. Based on the request type, it resolves the
     * endpoint, sends a post request using the supplied parameters. Overloaded method, accepts additional 
     * parameter to reset WSG authorization token. Called if token expired in a previous call. 
    **/
    private static Map<String, Object> postSKPHttpRequest(String requestType, Map<String, Object> parameters, 
                                                          Boolean resetAuthToken)
    {
        Map<String, Object> returnValue = null;
        String endPoint = NAS_RequestFactory.getEndpoint(requestType); 
        if(endPoint != null) {
            Map<String, String> requestHeader = new Map<String, String>();
            requestHeader.put('Content-Type', 'application/json');
            requestHeader.put('JWT', NAS_RequestFactory.getAuthorizationToken(resetAuthToken));
            requestHeader.put('Userid', NAS_Constants.WSG_USERNAME_B64);
            HttpResponse res = NAS_RequestFactory.postHttpRequest(endPoint, requestHeader, 
                                               NAS_TransformationFactory.formatSKPRequestParameters(parameters));
            if(res != null && res.getStatusCode() != 200 && !resetAuthToken) {
                String responseBody = res.getBody();
                try {
                    Map<String, Object> responseJSON = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                    if(responseJSON.get('errors') != null) {
                        List<Object> errors = (List<Object>) responseJSON.get('errors');
                        if(!errors.isEmpty()) {
                            Map<String, Object> error = (Map<String, Object>) errors[0];
                            if(error.get('code') != null && (String.valueOf(error.get('code')) == 'WSG990' || 
                                String.valueOf(error.get('code')) == 'WSG401' || 
                                String.valueOf(error.get('code')) == 'WSG500' || 
                                String.valueOf(error.get('code')) == 'WSG06')) {
                                return postSKPHttpRequest(requestType, parameters, true);
                            }
                        }
                    }
                } catch (Exception e) {
                    
                }
            }
            if(res != null)
            	returnvalue = NAS_TransformationFactory.formatHttpResponse(res, requestType);
            	system.debug('result body =='+res.getBody());
        }
        return returnvalue;
    }
    /**
     * @name postHttpRequest
     * @description Implementation of outbound Http Request to the supplied endpoint with, provided requestHeader and requestBody
    **/
    private static HttpResponse postHttpRequest(String endPoint, 
                                                Map<String, String> requestHeader, 
                                                String requestBody)
    {
    	if(Limits.getLimitCallouts() - Limits.getCallouts() < 1)
			return null;
        HttpResponse res = null;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        if(requestHeader != null)
        	for(String key: requestHeader.keySet())
        	{
        		req.setHeader(key, requestHeader.get(key));
        	}

        req.setMethod('POST');
        if(requestBody != null)
        	req.setBody(requestBody);
        Http http = new Http();
        try
        {
            system.debug('requestHeader=='+JSON.serialize(requestHeader));
            system.debug('requestBody=='+ req.getBody());
            res = http.send(req);
        }
        catch(CalloutException ce)
        {
            NAS_ErrorLogger.log(NAS_RequestFactory.class.getName(), 
                                JSON.serialize(res), 
                                'Endpoint: ' + endPoint +
                                ' Request Header: ' + JSON.serialize(requestHeader) + 
                                ' Request Body: ' + JSON.serialize(req) +
                                ' Stacktrace: ' + ce.getStackTraceString());
            res = null;
        }
        return res;
    }
    /**
     * @name getEndpoint
     * @description Translates the requestType to an Endpoint URL.
    **/
    private static String getEndpoint(String requestType)
    {
        String returnValue = null;
        if(requestType == NAS_Constants.RQTYPE_SKP_API_GET_REPLICATION_EVENTS)
            returnValue = NAS_Constants.URL_SKP_API_GET_REPLICATION_EVENTS;
        else if(requestType == NAS_Constants.RQTYPE_SKP_API_UPDATE_REPLICATION_EVENTS)
            returnValue = NAS_Constants.URL_SKP_API_UPDATE_REPLICATION_EVENTS;
        else if(requestType == NAS_Constants.RQTYPE_SKP_API_UPDATE_COMMUNICATOR)
            returnValue = NAS_Constants.URL_SKP_API_UPDATE_COMMUNICATOR;
        else if(requestType == NAS_Constants.RQTYPE_SKP_API_PIN_VERIFICATION)
            returnValue = NAS_Constants.URL_SKP_API_PIN_VERIFICATION;
        else if(requestType == NAS_Constants.RQTYPE_WSG_AUTHORIZATION)
            returnValue = NAS_Constants.URL_WSG_AUTHORIZATION;
        else if(requestType == NAS_Constants.RQTYPE_SKP_API_GET_SERVICE_MARKET)
            returnValue = NAS_Constants.URL_SKP_API_GET_SERVICE_MARKET;
        else if(requestType == NAS_Constants.RQTYPE_SKP_API_INFOWIN_CUST_INSTR)
            returnValue = NAS_Constants.URL_SKP_API_INFOWIN_CUST_INSTR;
        else if(requestType == NAS_Constants.RQTYPE_SKP_API_INFOWIN_SRVC_PRFL)
            returnValue = NAS_Constants.URL_SKP_API_INFOWIN_SRVC_PRFL;
        else if(requestType == NAS_Constants.RQTYPE_SKP_API_INFOWIN_CUST_NOTES)
            returnValue = NAS_Constants.URL_SKP_API_INFOWIN_CUST_NOTES;
        return returnValue;
    }
}