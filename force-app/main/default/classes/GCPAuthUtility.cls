public class GCPAuthUtility {
    
    public static String getCloudRunIdToken() {
        // 1. 
        String serviceAccountEmail = 'irm-salesforce-sa@irm-ce-crm-quote-nonprod-g.iam.gserviceaccount.com';
        String cloudRunUrl = 'https://quote-generator-263279237420.us-central1.run.app';
        String certName = 'gcp_jwt_key'; // 
        
        // 2. 
        Auth.JWT jwt = new Auth.JWT();
        jwt.setIss(serviceAccountEmail);
        jwt.setSub(serviceAccountEmail);
        jwt.setAud('https://oauth2.googleapis.com/token');
        jwt.setValidityLength(120);
        
        // 
        Map<String, Object> additionalClaims = new Map<String, Object>();
        additionalClaims.put('target_audience', cloudRunUrl);
        jwt.setAdditionalClaims(additionalClaims);
        
        // 3.  JWT
        Auth.JWS jws = new Auth.JWS(jwt, certName);
        String assertion = jws.getCompactSerialization();
        
        // 4. 
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://oauth2.googleapis.com/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' + assertion);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) jsonResponse.get('id_token'); // 
        } else {
            throw new CalloutException('Error GCP Auth (' + res.getStatusCode() + '): ' + res.getBody());
        }
    }
}