public class SKPPreValidationResponse {
	public Customer customer;
    public Boolean success;
    public String statusCode;
    public string statusDescription;
    public List<CodeAndMessage> errors;
    public List<CodeAndMessage> warnings;
	
	public SKPPreValidationResponse(){
		customer = new Customer();
        errors = new List<CodeAndMessage>();
        warnings = new List<CodeAndMessage>();
        statusCode = '';
        statusDescription ='';
	}
	
	public class Customer{
		public CustomerProfile customerProfile;
		public ServiceIndicators serviceIndicators;
        public BillingIndicatorsAndReports billingIndicatorsAndReports;
        public CustomerIndicators customerIndicators;
        public ServiceInquiry serviceInquiry;
		
		public Customer(){
			customerProfile = new CustomerProfile();
			serviceIndicators = new ServiceIndicators();
            //billingIndicatorsAndReports = new BillingIndicatorsAndReports();
		}
	} 
	
	public class CustomerProfile{
		public String customerId;
        public string districtId;
        public string districtName;
        public string addressCode;
        public string customerName;
        public string address1;
        public string address2;
        public string address3;
        public string floor;
        public string city;
        public string state;
		public string zip;
        public string country;
        public string contact;
        public string phone;
        public string fax;
        public string email;
        public string transactionDateTime;
        public string transactionUserId;
	}
	
    public class BillingIndicatorsAndReports{
        
		public string deptBillingCode;
        public string remitLevel;
        public string remittanceCustomer;
        public boolean deptReqForOrder;        

    }
    
    public class CustomerIndicators{ 
    	public string chargebackIndicator;
        public boolean divisionEnabled;
        public boolean validateDept;
        public integer recordCodeParameter;
        public integer transmittalUseIndicator;
        public string individualListIndicator;
    }
	public class ServiceIndicators{
		public boolean hardCopyEnabled;
		public boolean shreddingServiceEnabled;
        public string shreddingServiceType;
        public string destructionMethod;
        public boolean vaultEnabled;
        public boolean faxRetrievalEnabled;
        public boolean openShelf;
        public boolean iodEnabled;
        public boolean imConnectEnabled;
        public boolean imcUsersOnly;
        public boolean efsServicesEnabled;
        public boolean rcCustomData;
        public string printType;
        public boolean pullForward;
        public boolean xodEnabled;
        public boolean smartPurgeEnabled;
        public integer validationType;
        public boolean webServiceEnabled;
        public boolean accutracCustomer;
        public boolean fileReconciliation;
        
	}
    
    public class ServiceInquiry{
        public string serviceLevelProfileId;
        public string businessDayId;   
        public string serviceParameters;
    }
    
   public class CodeAndMessage {
        public String code;
        public String message;
    }

}