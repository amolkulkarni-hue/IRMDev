public class SKPPreValidation {
    
        public enum availableAddressType {BILLING, CORRESPONDENCE, SHIPPING}
    //"System" is a reserved variable string, so we may need to do a string replace here. 
    public string systemStringToBeReplaced = 'AMER'; 
    
    public string companyId;
    public string customerId;
    
    public SKPPreValidation(Case caseParam, Quote quoteParam, string username, SkpIntegrationHelper.CustomerIndicator indicatorParam,string custAcctId){
        Customer_Profile__c profile = caseParam.Customer_Profile__r;
        customerId = custAcctId;
    }

}