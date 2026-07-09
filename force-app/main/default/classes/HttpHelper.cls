/**
 * 	Class:				HttpHelper
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class handles the creation and update for all Http requests.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public without sharing class HttpHelper {
    public static Map<String,Object> getQueryMap(HttpRequest req){
        system.debug('Starting getQueryMap');
        Map<String,Object> result;
        if(req == null || req.getEndpoint() == null){
            return result;
        }
        
        String queryString = req.getEndpoint().subStringAfter('?');
        List<Object> listForArrayValue = new List<Object>();

        result = new Map<String,Object>();
        System.debug('queryString @13: ' + queryString);
        for(String k : queryString.split('&')){
            System.debug('k @15: ' + k);
            String[] p = k.split('=');
            System.debug('p @17: ' + p);
            if(!result.containsKey(p[0])){
                result.put(p[0],p[1]);
            }
            else{
                if(listForArrayValue.isEmpty()){
                    listForArrayValue.add(result.get(p[0]));
                }
                listForArrayValue.add(p[1]);
                result.put(p[0],listForArrayValue);
            }
        }
        
        return result;
    }
    
    public static String getQueryString(Map<String,Object> input){
        List<String> temp;
        String result = '';
        
        if(input != null && !input.isEmpty()){
            temp = new List<String>();
            for(String q : input.keySet()){
                if(input.get(q) != null){
                    Object ob = input.get(q);
                    
                    if(ob instanceOf List<String>){
                        for(String x : (List<String>) ob){
                            temp.add(q + '=' + x);
                        }
                    }
                    else{
                        temp.add(q + '=' + String.valueOf(input.get(q)));
                    }
                }
            }
            
            if(!temp.isEmpty()){
                result = String.join(temp, '&');
            }
        }
        
        return result;
    }
    
    public static void updateQueryString(HttpRequest req, String queryString){
        if(req != null && String.isNotBlank(queryString)){
            req.setEndpoint(req.getEndpoint().replace(req.getEndpoint().substringAfter('?'), queryString)); 
        }
    }
    
    public static HttpResponse getResponse(HttpRequest req){
        if(req == null){
            return null;
        }
        return new Http().send(req);
    }
    
    public static HttpRequest getConnectRequest(String endpoint, String method, Map<String,String> headers, Map<String,Object> queryParams, String namedCred){
        if(String.isBlank(endpoint) || String.isBlank(method)){
            return null;
        }
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        
        String ep = 'callout:' + namedCred + endpoint;
        if(String.isNotBlank(ep)){
            ep += '?' + getQueryString(queryParams);
        }
        req.setEndpoint(ep);
        
        if(headers != null && !headers.isEmpty()){
            for(String s : headers.keySet()){
                if(String.isNotBlank(headers.get(s))){
                    req.setHeader(s, headers.get(s));
                }
            }
        }
        return req;
    }

    public static void printRequest(HttpRequest res){
        system.debug('Request details are below:');
        system.debug('Endpoint: ' + res.getEndpoint());
        system.debug('Method: ' + res.getMethod());
        system.debug('Body: ' + res.getBody());
    }

    public static void printResponse(HttpResponse res){
        system.debug('Response details are below:');
        system.debug('Status Code: ' + res.getStatusCode());
        system.debug('Status: ' + res.getStatus());
        system.debug('Message: ' + res.getBody());
    }
}