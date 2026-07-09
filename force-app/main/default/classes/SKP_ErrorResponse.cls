public class SKP_ErrorResponse {
    public Boolean success;
    public String statusCode;
    public List<CodeAndMessage> errors;
    public List<CodeAndMessage> warnings;
    
    public SKP_ErrorResponse(){
        errors = new List<CodeAndMessage>();
        warnings = new List<CodeAndMessage>();
    }
    
    public class CodeAndMessage {
        public String code;
        public String message;
    }
}