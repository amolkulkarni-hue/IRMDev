Public class SITADHelper{
    public static string checkOAuthSecurityToken(string TokenEndPoint, string clientId, string clientSecret,string AuthorizationHeader){
        Http http = new Http();
        HTTPResponse tokenResponse;
        OAuthTokenResponse tokenDetails;
        //build Request
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');        
        request.setEndpoint(TokenEndPoint); 
        String content = 'client_key='+EncodingUtil.urlEncode(ClientId, 'UTF-8')+'&client_secret='+EncodingUtil.urlEncode(ClientSecret, 'UTF-8')+'&grant_type='+EncodingUtil.urlEncode('client_credentials', 'UTF-8')+'&scope='+EncodingUtil.urlEncode('ironmountain_sfdc', 'UTF-8');
        request.setBody(content);
        request.setHeader('Authorization', AuthorizationHeader);
        //call SITAD System
        try{
            tokenResponse = http.send(request);
            System.debug('tokenResponse '+tokenResponse);
            String tokenResponseBody = tokenResponse.getBody();
            tokenDetails= (OAuthTokenResponse)JSON.deserialize(tokenResponseBody, OAuthTokenResponse.class);
            string finalSecurityToken;
            finalSecurityToken = tokenDetails.access_token;
            return finalSecurityToken;
        }catch (CalloutException e){
            return null;
         }
    }
     public static HttpRequest OAuthbuildRequest(String endpoint,string callMethod, String BasicAuthorization, string JsonString){
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod(callMethod);   
        request.setHeader('Content-Type','application/json');
        request.setHeader('Authorization', BasicAuthorization);
        request.setBody(JsonString);
        return request;
    }
}