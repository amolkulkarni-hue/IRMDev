/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Apex service method to build parameters for various API requests.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public class NAS_RequestParamBuilder {
    /**
     * @name getServiceMarket
   * @description Constructs the parameters for getServiceMarket API
    **/
  public static Map<String, Object> getServiceMarket(Case cs)
    {
        String errorMessage = null;
      Integer orderNumber = null;
        if(cs.NAS_Order_Number__c != null)
        {
            try {
                orderNumber = Integer.valueOf(cs.NAS_Order_Number__c);
            } catch (Exception e) {
                errorMessage = NAS_Constants.NAS_ORDER_NUMBER_VALIDATION_MESSAGE;
            }
        }
      String zipCode = cs.Zip__c;
      String country = cs.NAS_SKP_Country__c;
        
        Map<String, Object> requestJSON = NAS_RequestParamBuilder.formatSKPRequestBody(null);
        if(orderNumber != null && errorMessage == null)
          requestJSON.put('orderNumber', orderNumber);
        else if(zipCode != null && country != null && errorMessage == null)
        {
          requestJSON.put('zipCode', zipCode);
          requestJSON.put('country', country);
        }
        if(errorMessage != null){
            requestJSON.put('errorMessage', errorMessage);
        }
        return requestJSON;
    }
  /**
     * @name updateCommunicatorParam
   * @description Constructs the parameters for updateCommunicator API
    **/
  public static Map<String, Object> getUpdateCommunicatorParam(Case cs)
    {
      String eventId = cs.NAS_External_ID__c.replaceFirst(NAS_Constants.CECOMM, '');
      String communicatorId = cs.NAS_Communicator_Id__c;
      Integer communicatorIdInt = 0;
        try{
            communicatorIdInt = Integer.valueOf(communicatorId);
        }
        catch(Exception e){}

        Map<String, String> updateCommunicatorDetails = new Map<String, String>();
        updateCommunicatorDetails.put('status', 'CLOSED');
        updateCommunicatorDetails.put('resolution', NAS_TransformationFactory.replaceNull(cs.NAS_Root_Cause_Reason__c, cs.Status));
        
        Map<String, Integer> filter = new Map<String, Integer>();
        filter.put('communicatorId', communicatorIdInt);
        
        Map<String, Object> requestJSON = NAS_RequestParamBuilder.formatSKPRequestBody(null);
        requestJSON.put('updateCommunicatorDetails', updateCommunicatorDetails);
        requestJSON.put('filter', filter);
        requestJSON.put('userId', NAS_DataFactory.getUserUniqueIdentifier(cs));
        
        return requestJSON;
    }
  /**
     * @name updateReplicationEventsParam
   * @description Constructs the parameters for updateReplicationEventsParam API
    **/
  public static Map<String, Object> getUpdateReplicationEventsParam(Case cs)
    {
      String eventId = cs.NAS_External_ID__c.replaceFirst(NAS_Constants.CECOMM, '');
        Integer eventIdInt = 0;
        try{
            eventIdInt = Integer.valueOf(eventID);
        }
        catch(Exception e){}
      
        Map<String, String> updateDetails = new Map<String, String>();
        updateDetails.put('eventStatus', 'DONE');
        updateDetails.put('transactionId', cs.Id);
        updateDetails.put('userId', NAS_DataFactory.getUserUniqueIdentifier(cs));
        
        Map<String, Object> requestJSON = NAS_RequestParamBuilder.formatSKPRequestBody(null);
        requestJSON.put('eventId', eventIdInt);
        requestJSON.put('updateDetails', updateDetails);
        
        return requestJSON;
    }
    /**
     * @name updateReplicationEventsParam
   * @description Constructs the parameters for getReplicationEventsParam API
    **/
  public static Map<String, Object> getReplicationEventsParam()
    {
        List<String> eventNames = new List<String>();
        eventNames.add(NAS_Constants.CECOMM);
        
        Map<String, Object> filter = new Map<String, Object>();
        filter.put('eventType', 'AW');
        filter.put('eventNames', eventNames);
        filter.put('count', NAS_Constants.REQUEST_COUNT_GET_REPLICATION_EVT_CECOMM);
        filter.put('includeTotalMatches', false);
        filter.put('eventStatus', 'NEW');
        
        Map<String, Object> requestJSON = NAS_RequestParamBuilder.formatSKPRequestBody(filter);
        requestJSON.put('method', 'getReplicationEvents');
        return requestJSON;
    }
    /**
     * @name getPasswordVerificationParam
   * @description Constructs the parameters for getPasswordVerificationParam API
    **/
 /* public static Map<String, Object> getPasswordVerificationParam(Id caseId, String passwordInput)
    {
        Map<String, Object> requestJSON = null;
        String passwordEncrypted = NAS_Utilities.encryptAES128WithSKPKey(passwordInput);
        Case c = [SELECT Id, Contact.Name, ContactId, Contact.NAS_SKP_Contact_Status__c, Contact.NAS_SKP_Contact_ID__c, 
                  Contact.NAS_IMC_Contact_Status__c, Contact.NAS_IMC_Contact_ID__c, Division_ID__c, 
                  Division_ID__r.Name, Department_ID__c, Department_ID__r.Name,
                  Customer_ID__c, Customer_ID__r.Name FROM Case WHERE Id = :caseId];
        Map<String, Object> filter = null;
        String authUserId = null;
        String password = null;
        String pin = null;
        if(c.Contact.NAS_SKP_Contact_Status__c == NAS_Constants.SKP_STATUS_CONTACT_ACTIVE)
        {
            filter = new Map<String, Object>();
            List<NAS_Authorized__c> authorizedList = [SELECT Id, NAS_User_Id__c FROM NAS_Authorized__c
                  WHERE NAS_Customer_Account__c = :c.Customer_ID__c AND NAS_Contact__c = :c.ContactId
                  AND NAS_Division__c = :c.Division_ID__c AND NAS_Department__c = :c.Department_ID__c];
            if(!authorizedList.isEmpty()) {
                filter.put('customerId', c.Customer_ID__r.Name);
                filter.put('divisionId', NAS_RequestParamBuilder.getTransformedDivisionDepartment(
                               c.Division_ID__r.Name));
                filter.put('departmentId', NAS_RequestParamBuilder.getTransformedDivisionDepartment(
                               c.Department_ID__r.Name));
                filter.put('IRMApplication', 'SKP');

                authUserId = authorizedList[0].NAS_User_Id__c;
                password = passwordEncrypted;
            }
        }
        else if(c.Contact.NAS_IMC_Contact_Status__c == NAS_Constants.IMC_STATUS_CONTACT_ACTIVE)
        {
            filter = new Map<String, Object>();
            filter.put('IRMApplication', 'IMC');

            authUserId = c.Contact.NAS_IMC_Contact_ID__c;
            pin = passwordInput;
        }
        else {
            requestJSON = new Map<String, Object>();
            requestJSON.put('isError', true);
            requestJSON.put('errorMessage', c.Contact.Name + ' ' + NAS_Constants.NAS_Contact_Inactive_Error_Message);
        }
        
        if(filter != null)
        {
            requestJSON = NAS_RequestParamBuilder.formatSKPRequestBody(filter);
            if(authUserId != null)
                requestJSON.put('authUserId', authUserId);
            if(password != null)
                requestJSON.put('password', password);
            if(pin != null)
                requestJSON.put('PIN', pin);
        }
        return requestJSON;
    }
*/
    /**
     * @name formatSKPRequestBody
   * @description Formats the SKP Request body to add the format and system parameters and optionally the filter parameter.
    **/
    public static Map<String, Object> formatSKPRequestBody(Map<String, Object> filter)
    {
        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('format', 'application/json');
        requestBody.put('system', 'AMER');
        if(filter != null)
          requestBody.put('filter', filter);
        return requestBody;
    }
    /**
     * @name getTransformedDivisionDepartment
   * @description Transforms the division/department for master division/department
    **/
    public static String getTransformedDivisionDepartment(String code)
    {
        if(code == null || code == NAS_Constants.MASTER_DIVISION_DEPARTMENT_CODE)
            return NAS_Constants.MASTER_DIVISION_DEPARTMENT;
        else
            return code;
    }
}