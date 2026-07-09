public class SKPPreValidationContractResponse {
    
    public Contract contract;
    public Boolean success;
    public String statusCode;
    public string statusDescription;
    public List<CodeAndMessage> errors;
    public List<CodeAndMessage> warnings;

	
	public SKPPreValidationContractResponse(){
		contract = new Contract();
        errors = new List<CodeAndMessage>();
        warnings = new List<CodeAndMessage>();
        statusCode = '';
        statusDescription ='';
	}
	
	public class Contract{
		public string customerId;
        public string customerName;
        public integer count;
        public integer offset;
        public integer maxResultsLimit;
        public integer totalMatches;
        public string owningDistrictId;
		public List<ContractDetails> contractDetails;
		
		public Contract(){
			contractDetails = new List<ContractDetails>();
		}
	} 
    
	public class ContractDetails{
        public string divisionId;
        public string departmentId;
        public string contractType;
        public string contractLink;
        public string version;
        public string businessType;
        public string effectiveDate;
        public string contractEndDate;
        public string districtRateSchedule;
        public string serviceReviewDate;
        public string storageReviewDate;
        public string lastServiceIncrease;
        public string lastStorageIncrease;
        public string exceptionRateId;
        public String billingCycle;
        public string bundledPricingEnabled;
		public boolean rmAdminFeeEnabled;
		public boolean fuelSurchargeEnabled;
        public boolean containerBillingEnabled;
	}
    
    public class CodeAndMessage {
        public String code;
        public String message;
    }

}