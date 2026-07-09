public class B2B_Response {
    public Boolean success;
    public String statusCode;
    public List<CodeAndMessage> errors;
    public List<CodeAndMessage> warnings;
    
    public B2B_Response(){
        errors = new List<CodeAndMessage>();
        warnings = new List<CodeAndMessage>();
    }
    
    public class CodeAndMessage {
        public String code;
        public String message;
    }
}