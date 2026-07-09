/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Factory class to implement various custom data types.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
global class NAS_DataTypeFactory {
	/**
     * @name NAS_IMCFormData
     * @description Implements the IMC Form data structure. Used for strict validation of incoming
     * IMC Requests.
    **/
    global class NAS_IMCFormData {
        global String custID;
        global String contactName;
        global String contactPhone;
        global String contactEmail;
        global String preferredContact;
        global String issueType;
        global String category;
        global String lob;
        global Integer orderNo;
        global String invoiceNo;
        global String requestID;
        global Boolean isNewRequest;
        global String divisionId;
        global String departmentId;
        global String description;
        global String language;
    }
    /**
     * @name NAS_IMCFormResponse
     * @description Implements the IMC Form Response structure. Response to IMC is returned using this type.
    **/
    global class NAS_IMCFormResponse {
        global Integer httpStatus;
        global String responseStatus;
        global String message;
        global String caseId;
    }
    /**
     * @name CECommEventIterable
     * @description Iterable implementation of the CE Communicator Event structure.
    **/
    global class CECommEventIterable implements Iterable<NAS_DataTypeFactory.CECommEvent>
    {
        private List<NAS_DataTypeFactory.CECommEvent> events {get; set;} 
        private NAS_DataTypeFactory.CECommSKPCustomer skpCustomer {get;set;}
        public CECommEventIterable(List<NAS_DataTypeFactory.CECommEvent> events, NAS_DataTypeFactory.CECommSKPCustomer skpCustomer) {
            this.events = events;
            this.skpCustomer = skpCustomer;
        }
        global Iterator<NAS_DataTypeFactory.CECommEvent> Iterator(){
			return new NAS_DataTypeFactory.CECommEventIterator(events, skpCustomer);
		}

    }
    /**
     * @name CECommEventIterator
     * @description Iterator implementation of the CE Communicator Event structure.
    **/
    global class CECommEventIterator implements Iterator<NAS_DataTypeFactory.CECommEvent>
    {
        private List<NAS_DataTypeFactory.CECommEvent> events {get; set;} 
        private Integer index = 0; 
        public CECommEventIterator(List<NAS_DataTypeFactory.CECommEvent> events, NAS_DataTypeFactory.CECommSKPCustomer skpCustomer) {
            this.events = events;
            for(NAS_DataTypeFactory.CECommEvent evt : this.events)
                evt.skpCustomer = skpCustomer; 
        }
        global boolean hasNext()
        { 
            if(index >= events.size()) {
                return false; 
            } 
            else 
            {
                return true; 
            }
        }
        global NAS_DataTypeFactory.CECommEvent next(){
            if(index == events.size()){return null;} 
            return events[index++]; 
        }
    }
    /**
     * @name CECommEvent
     * @description Implementation of the CE Communicator Event structure.
    **/
    global class CECommEvent {
        public String eventId {get;set;}
        public String eventType {get;set;}
        public String eventName {get;set;}
        public String eventStatus {get;set;}
        public String groupId {get;set;}
        public String groupType {get;set;}
        public String failCount {get;set;}
        public String environmentCode {get;set;}
        public String eventSource {get;set;}
        public String createDateTime {get;set;}
        public String createUserId {get;set;}
        public String transactionDateTime {get;set;}
        public String transactionUserId {get;set;}
        
        public Map<String, String> eventFieldData {get;set;}
        public NAS_DataTypeFactory.CECommSKPCustomer skpCustomer {get;set;}
    }
    /**
     * @name CECommSKPCustomerIdSet
     * @description Implementation of the SKP Customer structure. Includes a set of Customer Account, Division, Department and Contact.
    **/
    public class CECommSKPCustomerIdSet
    {
        public Set<String> customerSKPIdSet = new Set<String>();
        public Set<String> divisionSKPIdSet = new Set<String>();
        public Set<String> departmentSKPIdSet = new Set<String>();
        public Set<String> contactEmailSet = new Set<String>();
    }
    /**
     * @name SKPCustomerList
     * @description Implementation of the SKP Customer structure. Includes a List of Customer Account, Division, Department and Contact.
    **/
    public class SKPCustomerList
    {
        public List<IM_Customer_Account__c> customerAccountList = new List<IM_Customer_Account__c>();
        public List<Division__c> customerDivisionList = new List<Division__c>();
        public List<Department__c> customerDepartmentList = new List<Department__c>();
        /*Gitlab:13068-start
        public List<NAS_Authorized__c> authorizedList = new List<NAS_Authorized__c>();
        Gitlab:13068-Stop*/
    }
    /**
     * @name CECommSKPCustomer
     * @description Implementation of the SKP Customer structure.
    **/
    public class CECommSKPCustomer
    {
        public NAS_DataTypeFactory.SKPCustomerList skpCustomerList {get;set;}
        public Map<String, IM_Customer_Account__c> mapSKPIDToCustomerAccount {get;set;}
        public Map<Id, Map<String, Division__c>> mapCustIdSKPDivIdToDivision {get;set;}
        public Map<Id, Map<Id, Map<String, Department__c>>> mapCustIdDivIdSKPDeptIdToDepartment {get;set;}
        public Map<Id, Map<String, Map<String, Map<String, Contact>>>> mapCustIdDivIdDeptIdEmailToContact {get;set;}
    }
    /**
     * @name SKPAPIResponse
     * @description Wrapper of response status values. Contains success, error, warning and information deatils.
    **/
    public class SKPAPIResponse {
        @AuraEnabled public Boolean isError = false;
        @AuraEnabled public String errorMessage = '';
        @AuraEnabled public Boolean isWarning = false;
        @AuraEnabled public String warningMessage = '';
        @AuraEnabled public Boolean isInfo = false;
        @AuraEnabled public String infoMessage = '';
        @AuraEnabled public Boolean isSuccess = false;
    }
}