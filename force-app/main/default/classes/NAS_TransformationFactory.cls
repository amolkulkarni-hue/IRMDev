/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Apex factory class to implement various transformation functionalities.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public class NAS_TransformationFactory {
    /**
* @name updateSKPAPIReponse
* @description Transforms the SKP API response error, warning and info messages and status to 
* a NAS_DataTypeFactory.SKPAPIResponse.
**/
    public static void updateSKPAPIReponse(Map<String, Object> response, NAS_DataTypeFactory.SKPAPIResponse returnValue)
    {
        List<Object> errors = (List<Object>) response.get('errors');
        if(errors != null && !errors.isEmpty()) {
            Map<String, Object> error = (Map<String, Object>) errors[0];
            returnValue.isError = true;
            returnValue.errorMessage = NAS_Constants.SKP_ERROR + String.valueOf(error.get('message'));
        }
        else if(response.get('success') != true){
            returnValue.isError = true;
            returnValue.errorMessage = NAS_Constants.NAS_UNKNOWN_ERROR;
        }
        List<Object> warnings = (List<Object>) response.get('warnings');
        if(warnings != null && !warnings.isEmpty()) {
            Map<String, Object> warning = (Map<String, Object>) warnings[0];
            returnValue.isWarning = true;
            returnValue.warningMessage = String.valueOf(warning.get('message'));
        }
        List<Object> info = (List<Object>) response.get('info');
        if(info != null && !info.isEmpty()) {
            Map<String, Object> infoElement = (Map<String, Object>) info[0];
            returnValue.isInfo = true;
            returnValue.infoMessage = String.valueOf(infoElement.get('message'));
        }
    }
    /**
* @name getNewLineTerminatedText
* @description Overloaded method, returns a new line terminated text line with key: value format for Boolean value.
**/
    public static String getNewLineTerminatedText(String key, Boolean value)
    {
        return NAS_TransformationFactory.getNewLineTerminatedText(key, String.valueOf(value));
    }
    /**
* @name getNewLineTerminatedText
* @description Overloaded method, returns a new line terminated text line with key: value format for Integer value.
**/
    public static String getNewLineTerminatedText(String key, Integer value)
    {
        return NAS_TransformationFactory.getNewLineTerminatedText(key, String.valueOf(value));
    }
    /**
* @name getNewLineTerminatedText
* @description Overloaded method, returns a new line terminated text line with key: value format for String value.
**/
    public static String getNewLineTerminatedText(String key, String value)
    {
        return key + ': ' + value + '\n';
    }
    /**
* @name ifNull
* @description returns a replacement text if the key is null. returns '' otherwise.
**/
    public static String ifNull(String key, String textIfNull)
    {
        return (key == null? textIfNull : '');
    }
    /**
* @name replaceNull
* @description returns a replacement text if the key is null. returns the text as is otherwise.
**/
    public static String replaceNull(String key, String replacement)
    {
        return (key == null || key == ''? replacement : key);
    }
    /**
* @name formatReplicationEvents
* @description Parses the SKP JSON response replicationEventsMap, constructs and returns a list of NAS_DataTypeFactory.CECommEvent.
* Updates the parameter skpIdSet with SKP customer, division and department ids and contact email while parsing the eventHeaderList.
**/
    public static List<NAS_DataTypeFactory.CECommEvent> formatReplicationEvents(Map<String, Object> replicationEventsMap,
                                                                                NAS_DataTypeFactory.CECommSKPCustomerIdSet skpIdSet)
    {
        List<Object> eventHeaderList = (List<Object>) replicationEventsMap.get('eventHeaderList');
        
        List<NAS_DataTypeFactory.CECommEvent> eventList = new List<NAS_DataTypeFactory.CECommEvent>();
        for(Object eventHeaderObj: eventHeaderList)
        {
            NAS_DataTypeFactory.CECommEvent evt = new NAS_DataTypeFactory.CECommEvent();
            eventList.add(evt);
            Map<String, Object> eventHeader = (Map<String, Object>) eventHeaderObj;
            evt.eventId = String.valueOf(eventHeader.get('eventId'));
            evt.eventType = String.valueOf(eventHeader.get('eventType'));
            evt.eventName = String.valueOf(eventHeader.get('eventName'));
            evt.eventStatus = String.valueOf(eventHeader.get('eventStatus'));
            evt.groupId = String.valueOf(eventHeader.get('groupId'));
            evt.groupType = String.valueOf(eventHeader.get('groupType'));
            evt.failCount = String.valueOf(eventHeader.get('failCount'));
            evt.environmentCode = String.valueOf(eventHeader.get('environmentCode'));
            evt.eventSource = String.valueOf(eventHeader.get('eventSource'));
            evt.createDateTime = String.valueOf(eventHeader.get('createDateTime'));
            evt.createUserId = String.valueOf(eventHeader.get('createUserId'));
            evt.transactionDateTime = String.valueOf(eventHeader.get('transactionDateTime'));
            evt.transactionUserId = String.valueOf(eventHeader.get('transactionUserId'));
            List<Object> eventDataList = (List<Object>) eventHeader.get('eventDataList');
            evt.eventFieldData = new Map<String, String>();
            for(Object eventDataObj : eventDataList)
            {
                Map<String, Object> eventData = (Map<String, Object>) eventDataObj;
                String eventIdOfEventData = String.valueOf(eventData.get('eventId'));
                String eventDataField = String.valueOf(eventData.get('eventDataName'));
                String eventDataValue = String.valueOf(eventData.get('eventDataValue'));
                if((eventDataField == 'DIVISION_ID' || eventDataField == 'DEPARTMENT_ID') 
                   && (eventDataValue == '' || eventDataValue == null))
                    eventDataValue = 'Master';
                evt.eventFieldData.put(eventDataField, eventDataValue);
            }
            skpIdSet.customerSKPIdSet.add(evt.eventFieldData.get('CUSTOMER_ID'));
            skpIdSet.divisionSKPIdSet.add(evt.eventFieldData.get('DIVISION_ID'));
            skpIdSet.departmentSKPIdSet.add(evt.eventFieldData.get('DEPARTMENT_ID'));
            skpIdSet.contactEmailSet.add(evt.eventFieldData.get('CONTACT_EMAIL'));
        }
        return eventList;
    }
    /**
* @name formatSKPRequestParameters
* @description Formats Request Parameters to be sent to SKP. Current method removes barred 
* characters from the request with replacement characters as defined in the application configuration.
* @param {String} parameters - Request parameter that will be formatted.
**/
    public static String formatSKPRequestParameters(Map<String, Object> parameters)
    {
        return JSON.serialize(NAS_Utilities.replaceBarredCharacters(parameters));
    }
    /**
* @name formatSKPResponse
* @description Formats the Response of the returned value of SKP API Call as applicable to the requestType.
**/
    public static Map<String, Object> formatHttpResponse(HttpResponse res, String requestType)
    {
        Map<String, Object> returnValue = null;
        if(requestType == NAS_Constants.RQTYPE_SKP_API_GET_REPLICATION_EVENTS)
            returnValue = NAS_TransformationFactory.formatSKPResponseGetReplicationEvents(res);
        else if(requestType == NAS_Constants.RQTYPE_SKP_API_UPDATE_REPLICATION_EVENTS)
            returnValue = NAS_TransformationFactory.formatSKPResponseUpdateReplicationEvents(res);
        else if(requestType == NAS_Constants.RQTYPE_SKP_API_UPDATE_COMMUNICATOR)
            returnValue = NAS_TransformationFactory.formatSKPResponseUpdateCommunicator(res);
        else if(requestType == NAS_Constants.RQTYPE_SKP_API_PIN_VERIFICATION)
            returnValue = NAS_TransformationFactory.formatSKPResponsePinVerification(res);
        else if(requestType == NAS_Constants.RQTYPE_SKP_API_GET_SERVICE_MARKET)
            returnValue = NAS_TransformationFactory.formatSKPResponseGetServiceMarket(res);
        else if(requestType == NAS_Constants.RQTYPE_SKP_API_INFOWIN_CUST_NOTES)
            returnValue = NAS_TransformationFactory.formatSKPResponseGetNotes(res);
        else if(requestType == NAS_Constants.RQTYPE_SKP_API_INFOWIN_CUST_INSTR || 
                 requestType == NAS_Constants.RQTYPE_SKP_API_INFOWIN_SRVC_PRFL)
            returnValue = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return returnValue;
    }
    
    /**
* @name formatSKPResponseGetServiceMarket
* @description Formats the Response of the returned value of SKP API Call for Get Service Market.
**/
    private static Map<String, Object> formatSKPResponseGetServiceMarket(HttpResponse res)
    {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> errors = new List<Map<String, String>>();
        List<Map<String, String>> warnings = new List<Map<String, String>>();
        if(res.getStatusCode() == 200 || res.getStatusCode() == 400 || res.getStatusCode() == 404 || res.getStatusCode() == 406)
        {
            returnValue = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        }
        else
        {
            NAS_TransformationFactory.addGenericException(errors, '500', NAS_Constants.UNAVAILABLE_REMOTE_SYSTEM);
            returnValue.put('errors', errors);
            returnValue.put('warnings', warnings);
        }
        returnValue.put('statusCode', res.getStatusCode());
        return returnValue;
    }
       
    /**
* @name formatSKPResponseGetNotes
* @description Formats the Response of the returned value of SKP API Call for Get Customer Notes.
**/
    private static Map<String, Object> formatSKPResponseGetNotes(HttpResponse res)
    {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> errors = new List<Map<String, String>>();
        List<Map<String, String>> warnings = new List<Map<String, String>>();
        if(res.getStatusCode() == 200 || res.getStatusCode() == 400 || res.getStatusCode() == 404 || res.getStatusCode() == 406)
        {
            returnValue = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        }
        else
        {
            NAS_TransformationFactory.addGenericException(errors, '500', NAS_Constants.UNAVAILABLE_REMOTE_SYSTEM);
            returnValue.put('errors', errors);
            returnValue.put('warnings', warnings);
        }
        returnValue.put('statusCode', res.getStatusCode());
        return returnValue;
    }
    
    /**
* @name formatSKPResponseUpdateCommunicator
* @description Formats the Response of the returned value of SKP API Call for updateCommunicator.
**/
    private static Map<String, Object> formatSKPResponseUpdateCommunicator(HttpResponse res)
    {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> errors = new List<Map<String, String>>();
        List<Map<String, String>> warnings = new List<Map<String, String>>();
        if(res.getStatusCode() == 200 || res.getStatusCode() == 400 || res.getStatusCode() == 404 || res.getStatusCode() == 401)
        {
            returnValue = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        }
        else
        {
            NAS_TransformationFactory.addGenericException(errors, '500', NAS_Constants.UNAVAILABLE_REMOTE_SYSTEM);
        }
        returnValue.put('statusCode', res.getStatusCode());
        returnValue.put('errors', errors);
        returnValue.put('warnings', warnings);
        return returnValue;
    }
    /**
* @name formatSKPResponseUpdateReplicationEvents
* @description Formats the Response of the returned value of SKP API Call for update replication events.
**/
    private static Map<String, Object> formatSKPResponseUpdateReplicationEvents(HttpResponse res)
    {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> errors = new List<Map<String, String>>();
        List<Map<String, String>> warnings = new List<Map<String, String>>();
        if(res.getStatusCode() == 200 || res.getStatusCode() == 400 || res.getStatusCode() == 404)
        {
            returnValue = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        }
        else
        {
            NAS_TransformationFactory.addGenericException(errors, '500', NAS_Constants.UNAVAILABLE_REMOTE_SYSTEM);
        }
        returnValue.put('statusCode', res.getStatusCode());
        returnValue.put('errors', errors);
        returnValue.put('warnings', warnings);
        return returnValue;
    }
    /**
* @name formatSKPResponseGetReplicationEvents
* @description Formats the Response of the returned value of SKP API Call for get replication events.
**/
    private static Map<String, Object> formatSKPResponseGetReplicationEvents(HttpResponse res)
    {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> errors = new List<Map<String, String>>();
        List<Map<String, String>> warnings = new List<Map<String, String>>();
        if(res.getStatusCode() == 200)
        {
            returnValue.put('replicationEvents', 
                            ((Map<String, Object>)JSON.deserializeUntyped(res.getBody())).get('replicationEvents'));
        }
        else
        {
            NAS_TransformationFactory.addGenericException(errors, '500', NAS_Constants.UNAVAILABLE_REMOTE_SYSTEM);
        }
        returnValue.put('statusCode', res.getStatusCode());
        returnValue.put('errors', errors);
        returnValue.put('warnings', warnings);
        return returnValue;
    }
    /**
* @name formatSKPResponsePinVerification
* @description Formats the Response of the returned value of SKP API Call for verify customer pin.
**/
    private static Map<String, Object> formatSKPResponsePinVerification(HttpResponse res)
    {
        Map<String, Object> returnValue = new Map<String, Object>();
        List<Map<String, String>> errors = new List<Map<String, String>>();
        List<Map<String, String>> warnings = new List<Map<String, String>>();
        if(res.getStatusCode() == 200 || res.getStatusCode() == 400 || res.getStatusCode() == 403 || res.getStatusCode() == 401)
        {
            returnValue = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        }
        else
        {
            NAS_TransformationFactory.addGenericException(errors, '500', NAS_Constants.UNAVAILABLE_REMOTE_SYSTEM);
            returnValue.put('errors', errors);
            returnValue.put('warnings', warnings);
        }
        returnValue.put('statusCode', res.getStatusCode());
        return returnValue;
    }
    /**
* @name addGenericException
* @description Adds a generic exception if the request is unsuccessful and there is not error code available. Utilized in verify pin.
**/
    private static void addGenericException(List<Map<String, String>> container, String genericCode, String genericMessage)
    {
        Map<String, String> containerUnit = new Map<String, String>();
        containerUnit.put('code', genericCode);
        containerUnit.put('message', genericMessage);
        container.add(containerUnit);
    }
}