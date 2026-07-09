public class SKPResponse {
    public Boolean success;
    public String statusCode;
    public string statusDescription;
    public SuccessResult result;
    public List<CodeAndMessage> errors;
    public List<CodeAndMessage> warnings;
    
    public SKPResponse(){
        errors = new List<CodeAndMessage>();
        warnings = new List<CodeAndMessage>();
        statusCode = '';
        statusDescription ='';
    }
    
    public class CodeAndMessage {
        public String code;
        public String message;
    }

    public class SuccessResult {
        public String customerId;
        public String contractType;
        public String exceptionRateId;
        public string message;
        public string customerName;
        public string districtId;
    }
}