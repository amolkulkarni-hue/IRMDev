public class SKPUpdateContractResponse {
    public updateContractResult updateContractResult;
    public Boolean success;
    public String statusCode;
    public string statusDescription;
	
	public SKPUpdateContractResponse(){
		updateContractResult = new updateContractResult();
        statusCode = '';
        statusDescription ='';
	}
	
	public class updateContractResult{
		public string contractType;
		public List<ContractDetails> contractDetails;
        public List<generalWarnings> generalWarnings;
		public updateContractResult(){
			contractDetails = new List<ContractDetails>();
            generalWarnings = new List<generalWarnings>();
		}
	} 
    
	public class ContractDetails{
        public string divisionId;
        public string departmentId;
        public string customerId;
        public string success;
        public integer statusCode;
        public List<CodeAndMessage> errors;
        public List<CodeAndMessage> warnings;
        public ContractDetails(){
            errors = new List<CodeAndMessage>();
            warnings = new List<CodeAndMessage>();
        }
	}
    
    public class generalWarnings{
        public String code;
        public String message;
    }
    public class CodeAndMessage {
        public String code;
        public String message;
    }
}