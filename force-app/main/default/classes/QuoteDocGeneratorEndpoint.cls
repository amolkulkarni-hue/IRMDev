@RestResource(urlMapping='/generateQuoteDoc/*')
global class QuoteDocGeneratorEndpoint {

    @HttpPost
    global static Map<String, String> generateDoc() {

        RestRequest req = RestContext.request;
        String body = req.requestBody.toString();

        System.debug('QuoteDocGeneratorEndpoint :: generateDoc : body => ' + body);

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(body);
        
        String transactionId = (String) payload.get('transactionId');
        String accountId = (String) payload.get('accountId');

        // Query Account Data
        Account acc = [
            SELECT BillingCity, BillingStreet, BillingState, BillingPostalCode, BillingCountry
            FROM Account 
            WHERE Id = :accountId 
            LIMIT 1
        ];
        
        // Payload Enrichment
        payload.put('accountCity', acc.BillingCity);
        payload.put('accountAddress', acc.BillingStreet);
        payload.put('accountState', acc.BillingState);
        payload.put('accountPostalCode', acc.BillingPostalCode);
        payload.put('accountCountry', acc.BillingCountry);
        payload.put('contactName', 'Perez Test');
        payload.put('contactPhone', '33333333');
        payload.put('contactEmail', 'pereztest@test.com');

        String modifiedBody = JSON.serialize(payload);

        // Prepare Callout
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint('callout:Google_Apps_Script_DocGen');
        httpReq.setMethod('POST');
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setBody(modifiedBody);
        httpReq.setTimeout(60000); 

        Http http = new Http();
        HttpResponse res = http.send(httpReq);

        // Handle Redirect (302)
        if (res.getStatusCode() == 302) {
            String redirectedUrl = res.getHeader('Location');
            HttpRequest redirectReq = new HttpRequest();
            redirectReq.setEndpoint(redirectedUrl);
            redirectReq.setMethod('GET');
            redirectReq.setTimeout(60000);
            res = http.send(redirectReq);
        }

        // --- NEW LOGIC: PROCESS MULTIPLE FILES ---
        Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> filesList = (List<Object>) result.get('files');
        
        System.debug('QuoteDocGeneratorEndpoint :: Files returned from Google: ' + filesList.size());

        // Query existing documents on the Transaction to handle versioning/overwriting
        List<ContentDocumentLink> existingLinks = [
            SELECT ContentDocumentId, ContentDocument.Title 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :transactionId 
        ];

        // Map existing Document Titles to their ContentDocumentIds
        Map<String, Id> existingDocMap = new Map<String, Id>();
        for (ContentDocumentLink cdl : existingLinks) {
            existingDocMap.put(cdl.ContentDocument.Title, cdl.ContentDocumentId);
        }

        List<ContentVersion> cvListToInsert = new List<ContentVersion>();

        // Loop through the incoming files from Google
        for (Object fObj : filesList) {
            Map<String, Object> fileMap = (Map<String, Object>) fObj;
            String base64Pdf = (String) fileMap.get('base64');
            String fileName  = (String) fileMap.get('fileName');

            ContentVersion cv = new ContentVersion();
            cv.Title          = fileName;
            cv.PathOnClient   = fileName;
            cv.VersionData    = EncodingUtil.base64Decode(base64Pdf);

            // Check if a document with this exact name already exists
            if (existingDocMap.containsKey(fileName)) {
                // Attach to existing document (Creates V2, V3, etc.)
                cv.ContentDocumentId = existingDocMap.get(fileName);
                System.debug('QuoteDocGeneratorEndpoint :: Updating existing document: ' + fileName);
            } else {
                // Create brand new document
                cv.FirstPublishLocationId = transactionId; 
                System.debug('QuoteDocGeneratorEndpoint :: Creating new document: ' + fileName);
            }
            
            cvListToInsert.add(cv);
        }

        // Bulk insert all generated versions
        if (!cvListToInsert.isEmpty()) {
            insert cvListToInsert;
        }

        // Return success to Logik
        Map<String, String> logikResponse = new Map<String, String>();
        logikResponse.put('status', 'success');
        logikResponse.put('documentsGenerated', String.valueOf(cvListToInsert.size()));

        return logikResponse;
    }
}