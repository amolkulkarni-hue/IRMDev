public class CustAccountSITADErrorResponse{
    public List<cls_Errors> Errors;
    public List<cls_Warnings> Warnings;
    
    public CustAccountSITADErrorResponse(){
        this.Errors = new List<cls_Errors>();
        this.Warnings = new List<cls_Warnings>();
    }
    public class cls_Errors {
        public string Code;
        public string Message;
        public cls_ModelState ModelState;
        public string SMSAccountID;
        public cls_Errors(){
             this.ModelState = new cls_ModelState();
        }
    }
    public class cls_Warnings {
        public string Code;
        public string Message;
        public cls_ModelState ModelState;
        public string SMSAccountID;
        public cls_Warnings(){
             this.ModelState = new cls_ModelState();
        }
    }
    public class cls_ModelState{
        public cls_ModelState(){
        }
    }
}