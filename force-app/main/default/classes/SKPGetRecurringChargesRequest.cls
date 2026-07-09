public class SKPGetRecurringChargesRequest {
    public string systemStringToBeReplaced = 'AMER'; 
    public string userId;
    public string companyId;
    public string customerId;
    public filterObj filter;
    
    public SKPGetRecurringChargesRequest(Case caseParam, Quote quoteParam, string username, SkpIntegrationHelper.CustomerIndicator indicatorParam,string custAcctId){
        customerId = custAcctId;
        this.userId = UserInfo.getUserEmail().substring(0,7);
        filter = new filterObj();
    }
    
    public class filterObj{
        public string divisionId;
        public string departmentId;        
        public filterObj(){
            this.divisionId = '';
            this.departmentId = '';
        }
    }    
    	
}