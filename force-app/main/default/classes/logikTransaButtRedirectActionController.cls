public with sharing class logikTransaButtRedirectActionController {

    @AuraEnabled(cacheable=true)
    public static String getLogikTenantUrl() {
        LGK__ConfigurationTenant__c config = LGK__ConfigurationTenant__c.getInstance();
        return config?.LGK__RuntimeUrl__c;
    }

    @AuraEnabled(cacheable=true)
    public static LGK__ConfigurationTenant__c getCustomSettings() {
        return LGK__ConfigurationTenant__c.getInstance();
    }

    // ----------------------------------------------------------------------
    // LWC EXPOSED METHODS (NO CREDENTIALS IN PARAMETERS)
    // ----------------------------------------------------------------------

    // Create Transaction (POST)
    @AuraEnabled
    public static String createLogikTransaction(Id accountId, Id opportunityId, Id pricebookId, Id sfTransactionId) {
        String endpoint = getLogikTenantUrl();
        String runtimeToken = System.Label.logikRuntimeToken;
        
        if (String.isBlank(endpoint) || String.isBlank(runtimeToken)) {
            throw new AuraHandledException('Missing Logik configuration (URL or Token).');
        }
        endpoint = endpoint.endsWith('/') ? endpoint.substring(0, endpoint.length() - 1) : endpoint;

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + '/api/t');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Origin', endpoint);
        req.setHeader('Authorization', 'Bearer ' + runtimeToken);
        req.setTimeout(120000);
        
        String payload = '{"stateful": false, "fields": [' +
            '{"variableName": "txn.account.id", "value": "' + accountId + '"}, ' +
            '{"variableName": "txn.opportunity.id", "value": "' + opportunityId + '"}, ' +
            '{"variableName": "txn.pricebook.id", "value": "' + pricebookId + '"}, '+
            '{"variableName": "txn.custom.sfRecordID", "value": "' + sfTransactionId + '"}' +
        ']}';
        
        req.setBody(payload);
        
        HttpResponse res = http.send(req);
        String bodyText = res.getBody();
        Integer chunkSize = 2000;

        for (Integer i = 0; i < bodyText.length(); i += chunkSize) {
            Integer endIndex = Math.min(i + chunkSize, bodyText.length());
            System.debug('[LTA] createLogikTransaction Response Response Body: ' + (i/chunkSize + 1) + ': ' + bodyText.substring(i, endIndex));
        }

        if (res.getStatusCode() >= 400) {
            throw new CalloutException('Failed to create Logik Transaction. Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
        }

        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (String) responseData.get('id');
    }

    // Update Fields (POST)
    @AuraEnabled
    public static void updateLogikTransactionFields(String logikTransactionId, String sessionId, Id opportunityId, Id accountId) {
        String endpoint = getLogikTenantUrl();
        String runtimeToken = System.Label.logikRuntimeToken;
        
        if (String.isBlank(endpoint) || String.isBlank(runtimeToken)) {
            throw new AuraHandledException('Missing Logik configuration (URL or Token).');
        }
        endpoint = endpoint.endsWith('/') ? endpoint.substring(0, endpoint.length() - 1) : endpoint;

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + '/api/t/' + logikTransactionId + '/events/randomEvent');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Origin', endpoint);
        req.setHeader('Authorization', 'Bearer ' + runtimeToken);
        req.setTimeout(120000);
        
        String payload = '{"context": {"session": "'+sessionId+'", "stateful": true}, "fields": [{"variableName": "txn.opportunity.id", "value": "'+opportunityId+'", "datatype": "text"}, {"variableName": "txn.account.id", "value": "'+accountId+'", "datatype": "text"}]}';
        req.setBody(payload);
        
        HttpResponse res = http.send(req);
        String bodyText = res.getBody();
        Integer chunkSize = 2000;

        for (Integer i = 0; i < bodyText.length(); i += chunkSize) {
            Integer endIndex = Math.min(i + chunkSize, bodyText.length());
            System.debug('[LTA] updateLogikTransactionFields Response Body: ' + (i/chunkSize + 1) + ': ' + bodyText.substring(i, endIndex));
        }
        if (res.getStatusCode() >= 400) {
            throw new CalloutException('Failed to update Logik Transaction Fields. Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
        }
    }

    // Create Configuration (POST)
    @AuraEnabled
    public static String createLogikConfiguration(String configurableProductId) {
        String endpoint = getLogikTenantUrl();
        String runtimeToken = System.Label.logikRuntimeToken;
        
        if (String.isBlank(endpoint) || String.isBlank(runtimeToken)) {
            throw new AuraHandledException('Missing Logik configuration (URL or Token).');
        }
        endpoint = endpoint.endsWith('/') ? endpoint.substring(0, endpoint.length() - 1) : endpoint;

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + '/api');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Origin', endpoint);
        req.setHeader('Authorization', 'Bearer ' + runtimeToken);
        req.setTimeout(120000);
        
        String payload = '{"sessionContext": {"stateful": true}, "partnerData": {"product": {"configuredProductId": "'+configurableProductId+'"}}, "fields": []}';
        req.setBody(payload);
        
        HttpResponse res = http.send(req);
        String bodyText = res.getBody();
        Integer chunkSize = 2000;

        for (Integer i = 0; i < bodyText.length(); i += chunkSize) {
            Integer endIndex = Math.min(i + chunkSize, bodyText.length());
            System.debug('[LTA] createLogikConfiguration Response Body: ' + (i/chunkSize + 1) + ': ' + bodyText.substring(i, endIndex));
        }

        if (res.getStatusCode() >= 400) {
            throw new CalloutException('Failed to create Logik Configuration. Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
        }

        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (String) responseData.get('uuid'); 
    }

    // Save Configuration (PATCH)
    @AuraEnabled
    public static void saveLogikConfiguration(String configUuid) {
        String endpoint = getLogikTenantUrl();
        String runtimeToken = System.Label.logikRuntimeToken;
        
        if (String.isBlank(endpoint) || String.isBlank(runtimeToken)) {
            throw new AuraHandledException('Missing Logik configuration (URL or Token).');
        }
        endpoint = endpoint.endsWith('/') ? endpoint.substring(0, endpoint.length() - 1) : endpoint;

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String fullURL = endpoint + '/api/' + configUuid + '?save=true';
        System.debug('fullURL: '+ fullURL);
        req.setEndpoint(fullURL);
        req.setMethod('PATCH');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Origin', endpoint);
        req.setHeader('Authorization', 'Bearer ' + runtimeToken);
        req.setTimeout(120000);
        req.setBody('{}');
        
        HttpResponse res = http.send(req);
        String bodyText = res.getBody();
        Integer chunkSize = 2000;

        for (Integer i = 0; i < bodyText.length(); i += chunkSize) {
            Integer endIndex = Math.min(i + chunkSize, bodyText.length());
            System.debug('[LTA] saveLogikConfiguration Response Body: ' + (i/chunkSize + 1) + ': ' + bodyText.substring(i, endIndex));
        }

        if (res.getStatusCode() >= 400) {
            throw new CalloutException('Failed to save Logik Configuration. Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
        }
    }

    // Upsert Lines to Transaction (POST)
    @AuraEnabled
    public static void upsertLogikTransactionLines(String logikTransactionId, String configUuid) {
        String endpoint = getLogikTenantUrl();
        String runtimeToken = System.Label.logikRuntimeToken;

        if (String.isBlank(endpoint) || String.isBlank(runtimeToken)) {
            throw new AuraHandledException('Missing Logik configuration (URL or Token).');
        }
        endpoint = endpoint.endsWith('/') ? endpoint.substring(0, endpoint.length() - 1) : endpoint;

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint + '/api/t/' + logikTransactionId + '/events/upsertLines');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Origin', endpoint);
        req.setHeader('Authorization', 'Bearer ' + runtimeToken);
        req.setTimeout(120000);
        
        String payload = '{"context": {"stateful": false}, "items": [{"configurationId": "'+configUuid+'"}]}';
        //String payload = '{"context": {"stateful": false}, "items": [{"configurationId": "'+configUuid+'", "quantity": 1}]}';
        req.setBody(payload);
        
        HttpResponse res = http.send(req);
        String bodyText = res.getBody();
        Integer chunkSize = 2000;

        for (Integer i = 0; i < bodyText.length(); i += chunkSize) {
            Integer endIndex = Math.min(i + chunkSize, bodyText.length());
            System.debug('[LTA] upsertLogikTransactionLines Response Body: ' + (i/chunkSize + 1) + ': ' + bodyText.substring(i, endIndex));
        }

        if (res.getStatusCode() >= 400) {
            throw new CalloutException('Failed to upsert lines to Logik Transaction. Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
        }
    }

    @AuraEnabled(cacheable=true)
    public static logikTransactionButtonRedirectAction__mdt getBlueprintMetadata() {
        return [
            SELECT blueprint__c, pricebook__c 
            FROM logikTransactionButtonRedirectAction__mdt 
            WHERE DeveloperName = 'mbublueprint' 
            LIMIT 1
        ];
    }
}