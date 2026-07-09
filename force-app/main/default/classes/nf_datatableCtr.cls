/**
* @name: nf_datatableCtr
* Luis Rocha - Neuraflash LLC
* including their account and account relations. It queries the IM_Customer_Account__c object 
* to retrieve customer information related to a list of account Ids and the user's contact Id.

Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
* 
2/14/2025 - Roopesh Lakshmanan - commented the lines to stop prefixing 0s to custID - GitLab #29141
2/24/2025 - Roopesh Lakshmanan - updated mulesoft params as customerID-Source system for invoice and orders request.
            inscope source system is maintained in Community_Site_Configuration__mdt.
===================================================
*/
public class nf_datatableCtr { 
    /**
    * @name: getRelatedCustomerIds
    * Luis Rocha - Neuraflash LLC
    * @param userId: The user for whom related customer information should be retrieved.
    * @return: String - Comma-separated list of related customer IDs.
    */
    public static Set<String> getSourceSystems(){
       // Retrieve the single record
     Community_Site_Configuration__mdt sourceSystemRecord = [
        SELECT Config_Values__c 
        FROM Community_Site_Configuration__mdt 
        WHERE Label = 'Source Systems' 
        AND Functionality_Type__c = 'Orders_Invoice'
        LIMIT 1
    ]; 

        // Extract Source_Systems__c and split it into a Set<String>
        Set<String> sourceSystemValues = new Set<String>();
        if (sourceSystemRecord != null && String.isNotBlank(sourceSystemRecord.Config_Values__c)) {
            sourceSystemValues.addAll(sourceSystemRecord.Config_Values__c.split(','));
        }
        return sourceSystemValues;
        
    }
    
    public static Set<String> getRelatedCustomerIdsByCases(String contactId){
        Set<String> inScopesourceSystems = getSourceSystems();
        Set<String> setOfCustomerIds = new Set<String>();
        System.debug([SELECT LastModifiedDate, Customer_ID__r.Name,Customer_ID__r.Source_System__c FROM Case WHERE ContactId =: contactId AND (Customer_ID__c != '') AND Customer_ID__r.Source_System__c IN:inScopesourceSystems  ORDER BY LastModifiedDate DESC]);
        for( Case cs : [SELECT LastModifiedDate, Customer_ID__r.Name,Customer_ID__r.Source_System__c FROM Case WHERE ContactId =: contactId AND (Customer_ID__c != '') AND Customer_ID__r.Source_System__c IN:inScopesourceSystems  ORDER BY LastModifiedDate DESC] ){
            if(setOfCustomerIds.size() <= 10){ 
                setOfCustomerIds.add(cs.Customer_ID__r.Name+'-'+cs.Customer_ID__r.Source_System__c);
            }
        }
        return setOfCustomerIds;
    } 

    public static String addZeroPrefixedToStrings(String checkString) {
        if (checkString.length() < 6 && checkString.length() > 3) {
            checkString = checkString.leftPad( 6, '0');
        }
        return checkString;
    }
     
    /** 
    * @name: getRelatedCustomerIds
    * Luis Rocha - Neuraflash LLC
    * @param userId: The user for whom related customer information should be retrieved.
    * @return: String - Comma-separated list of related customer IDs.
    */
    public static Set<String> getRelatedCustomerIds(String userId){
        try {
            Integer MAXNUMBEROFCUSTOMERID = integer.valueof(System.Label.nf_datatableCtr_MAXNUMBEROFCUSTOMERID);
            Set<String> setOfCustomerIds = new Set<String>();
            User usr = [SELECT ContactId FROM User WHERE Id =: userId][0];
            Set<String> setOfRelatedCustomerId = getRelatedCustomerIdsByCases(usr.ContactId);
            Integer updatedLimit = MAXNUMBEROFCUSTOMERID - setOfCustomerIds.size();
            if(setOfRelatedCustomerId.size() < MAXNUMBEROFCUSTOMERID){
                Set<Id> accountIds = new Set<Id>();
                for(AccountContactRelation accContactRel : [SELECT AccountId FROM AccountContactRelation WHERE ContactId =: usr.ContactId] ){
                    accountIds.add(accContactRel.AccountId);
                }
                if(accountIds.size() > 0){
                     Set<String> inScopesourceSystems = getSourceSystems();
                    for(IM_Customer_Account__c ima : [SELECT Name, IM_Account__c,Source_System__c FROM IM_Customer_Account__c WHERE IM_Account__c IN: accountIds AND Source_System__c IN:inScopesourceSystems LIMIT :updatedLimit] ){setOfRelatedCustomerId.add(ima.Name+'-'+ima.Source_System__c); }
                }
            }
            return setOfRelatedCustomerId;
        } catch (Exception e){ 
            return new Set<String>{'ERROR'};
        }
    }

    public static String convertSetToString(Set<String> stringSet) {
        String result = '';
        if(stringSet != null && !stringSet.isEmpty()) {
            for(String str: stringSet) { 
                result += str + ','; 
            }
            result = result.removeEnd(',');
        }
        return result;
    }
    
    /**
    * @name: retrieveOrders
    * Luis Rocha - Neuraflash LLC
    * @param userId: The user for whom related customer information should be retrieved.
    * @return: Orders
    */
     @AuraEnabled(cacheable=false)
    public static String retrieveOrders(String userId){
        HttpRequest req = new HttpRequest();
        Set<String> customerIds = getRelatedCustomerIds(userId);
        String customerId = convertSetToString(customerIds); // customer id with source system (example : ABC-SKP NA)
        if(customerId == 'ERROR' || customerId == ''){
            return 'ERROR';
        } else {
            // check for the user seesion cahe
            String orderKey = 'ORD'+userId ;
            String cacheData = getCachedOrderOrInvoice(orderKey);
           if(cacheData != null){
                    system.debug('############### orders'+cacheData);
                    return cacheData;
           }
            String encodedCustomerId = EncodingUtil.urlEncode(customerId, 'UTF-8'); // used to avoid special char error when making http callout
            System.debug(customerId);
            req.setEndpoint('callout:NF_OrderTable?customerId='+encodedCustomerId);
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);
            req.setMethod('GET');
            Http http = new Http();
            try {
                HTTPResponse res = http.send(req);
                Integer statusCode = res.getStatusCode();
                String responseBody = res.getBody();
                if (res.getStatusCode() == 200) {
                    system.debug('############### orders'+res.getBody());
                    Util.logError('nf_datatableCtr','retrieveOrders',encodedCustomerId,'success','',userId);
                    //set the session cache for user
                    setCachedOrderOrInvoice(orderKey,responseBody);
                    return responseBody;
                } 
                String errorMessage;
                if (statusCode >= 400 && statusCode < 500) {
                    system.debug('inside 400 error');
                    errorMessage = 'External API Client Error (Status: ' + statusCode + '): ' + responseBody;
                     system.debug('finished 400 error loging');

                } else if (statusCode >= 500 && statusCode < 600) {
                     errorMessage = 'External API Client Error (Status: ' + statusCode + '): ' + responseBody;
                }else {
                    errorMessage = 'Unexpected HTTP Status Code (' + statusCode + '): ' + responseBody;
                }

                Util.logError('nf_datatableCtr','retrieveOrders',encodedCustomerId,errorMessage,'',userId);
                return 'ERROR';          
            } 
            catch(CalloutException  e){
                system.debug('inside callout exception');
                String errorMessage = 'Callout failed: ' + e.getMessage();
                 Util.logError('nf_datatableCtr','retrieveOrders',encodedCustomerId,errorMessage,e.getStackTraceString(),userId);
                // throw new AuraHandledException('Failed to connect to the external API. Please check your network or try again later.');
                return 'ERROR';
            }
            catch (Exception e) {
                system.debug('inside exception');
                 String errorMessage = 'An internal error occurred during API call: ' + e.getMessage();
                 Util.logError('nf_datatableCtr','retrieveOrders',encodedCustomerId,errorMessage,e.getStackTraceString(),userId);
                //  throw new AuraHandledException('An internal server error occurred while processing the API response: ' + e.getMessage());
                return 'ERROR';
            }            
        }
    }

    /**
    * @name: retrieveInvoices
    * Luis Rocha - Neuraflash LLC
    * @param userId: The user for whom related customer information should be retrieved.
    * @return: Orders
    */
    @AuraEnabled(cacheable=false)
    public static String retrieveInvoices(String userId){
        HttpRequest req = new HttpRequest();
        Set<String> customerIds = getRelatedCustomerIds(userId); // customer id with source system (example : ABC-SKP NA)
    //  #29141 -START - commented the lines to stop prefixing 0s to custID //
    
       /* Set<String> customerIdWithZeroPrefix = new Set<String>(); 
        If(!customerIds.isEmpty()) {
            For(String ci : customerIds) {
                ci = addZeroPrefixedToStrings(ci);
                customerIdWithZeroPrefix.add(ci);
                System.debug(ci);
            }
        }
        String customerId ;
        if (country == 'United States'){
        customerId = convertSetToString(customerIdWithZeroPrefix); // #26935 - prefixing 0's for custid < 5 digit for US
        }
        else
        {
            customerId =convertSetToString(customerIds);// #26935 - no 0 prefix for cust id for UK
        }
        */
        //  #29141 -END //
        String customerId ;
        customerId =convertSetToString(customerIds);
        if(customerId == 'ERROR' || customerId == ''){
            return 'ERROR';
        }
        String invoiceKey = 'INV'+userId ;
        String cacheData = getCachedOrderOrInvoice(invoiceKey);
        if(cacheData != null){
            system.debug('############### invoices '+cacheData);
            return cacheData;
        }

        String encodedCustomerId = EncodingUtil.urlEncode(customerId, 'UTF-8'); 
        // used to avoid special char error when making http callout
        //String encodedCountry = EncodingUtil.urlEncode(country, 'UTF-8'); // used to avoid special char error when making http callout
        req.setEndpoint('callout:NF_InvoiceTable?customerId='+encodedCustomerId);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        req.setMethod('GET');
        Http http = new Http();
    
        try {
                HTTPResponse res = http.send(req);
                Integer statusCode = res.getStatusCode();
                String responseBody = res.getBody();

                if (statusCode == 200) {
                    System.debug('############### invoice ' + responseBody);
                    Util.logError('nf_datatableCtr', 'retrieveInvoices', encodedCustomerId, 'success', '', userId);
                    setCachedOrderOrInvoice(invoiceKey,responseBody);
                    return responseBody;
                }

                // Prepare error message based on status
                String errorMessage;
                String userMessage;

                if (statusCode >= 400 && statusCode < 500) {
                    system.debug('inside 400 block');
                    errorMessage = 'External API Client Error (Status: ' + statusCode + '): ' + responseBody;
                    // userMessage = 'There was an issue with your request. Please contact support.';
                } else if (statusCode >= 500 && statusCode < 600) {
                    system.debug('inside 500 block');
                    errorMessage = 'External API Server Error (Status: ' + statusCode + '): ' + responseBody;
                    // userMessage = 'External API is currently unavailable. Please try again later.';
                } else {
                    errorMessage = 'Unexpected HTTP Status Code (' + statusCode + '): ' + responseBody;
                    // userMessage = 'Unexpected response from the service. Please try again.';
                }

                Util.logError('nf_datatableCtr', 'retrieveInvoices', encodedCustomerId, errorMessage, '', userId);
                // throw new AuraHandledException(userMessage);
                return 'ERROR';

            } catch (CalloutException ce) {
                String errorMessage = 'Callout failed: ' + ce.getMessage();
                System.debug('*** calloutException ' + errorMessage);
                Util.logError('nf_datatableCtr', 'retrieveInvoices', encodedCustomerId, errorMessage, ce.getStackTraceString(), userId);
                return 'ERROR';
                // throw new AuraHandledException('Failed to connect to the external API. Please check your network or try again later.');

            } catch (Exception e) {
                String errorMessage = 'Internal error during API call: ' + e.getMessage();
                System.debug('*** exception ' + errorMessage);
                String stackTrace = e.getStackTraceString();
                Util.logError('nf_datatableCtr', 'retrieveInvoices', encodedCustomerId, errorMessage, stackTrace, userId);
                return 'ERROR';
                // throw new AuraHandledException('An internal error occurred. Please contact support.');
            }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getMetadataAsMap() {
        // Initialize the map to store metadata records
        Map<String, String> metadataMap = new Map<String, String>();

        // Query the custom metadata type for specific fields
        List<Order_Status_Datatable_Map__mdt> metadataRecords = [
            SELECT DeveloperName, Integration_Status_Returned_Value__c, Custom_Label__c
            FROM Order_Status_Datatable_Map__mdt
        ];

        // Populate the map with DeveloperName as the key and record as the value
        for (Order_Status_Datatable_Map__mdt record : metadataRecords) {
            metadataMap.put(record.Integration_Status_Returned_Value__c, System.Label.get('',record.Custom_Label__c, UserInfo.getLanguage()) );
        }

        return metadataMap;
    }

    public static String getCachedOrderOrInvoice(String sessionKey){
         Cache.SessionPartition sessionPartition = Cache.Session.getPartition('local.CommunityCache');
         if(sessionPartition.contains(sessionKey)){
             return (String)sessionPartition.get(sessionKey);
         }
         return null;         
    }

    public static void setCachedOrderOrInvoice(String sessionKey, String data){
         Cache.SessionPartition sessionPartition = Cache.Session.getPartition('local.CommunityCache');
         sessionPartition.put(sessionKey, data,900); // set the TTL to 15 min for the data we are caching
    }

}