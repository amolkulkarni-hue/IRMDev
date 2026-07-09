public class SKPContractRenewalBatchRequest {
    
    //"System" is a reserved variable string, so we need to do a string replace after this has been generated. 
    public string systemStringToBeReplaced = 'AMER';     
    public string companyID;
    public string userId;
    public filterObj filter;
    public UpdateDetailsObj updateDetails;    
    
    public SKPContractRenewalBatchRequest(string erid,Set<String> custIdSet,boolean isQPI){
        this.userID = UserInfo.getUserEmail().substring(0,7);
        this.filter = new filterObj();
        this.updateDetails = new UpdateDetailsObj(erid,custIdSet,isQPI);
    }
    
    //SKPContract.filterObj
    public class filterObj{
        public string modeOfOperation;
        public filterObj(){
            this.modeOfOperation = 'UPDATE';
        }
    }
    
    //SKPContract.addDetails
    public class UpdateDetailsObj{
        public contractDetailsObj contractDetails;    
        public UpdateDetailsObj(string erid,Set<String> custIdSet, boolean isQPI){
            this.contractDetails = new contractDetailsObj(erid,custIdSet,isQPI); 
        }
    }
    
    //SKPContract.addDetails.contractDetails
    public class contractDetailsObj{
        public string contractType;
        public exceptionRateDetailObj exceptionRateDetail;
        public string standardRate;    
        public Boolean QPI;
        public List<ownersObj> owners;
        
        public contractDetailsObj(string erid,Set<String> custIdSet, boolean isQPI){
     		if(isQPI){
           	 this.QPI = true;} 
            else{
           	 this.QPI = false;} 
            this.contractType = 'AR';
            this.standardRate = String.valueOf(Date.today().year());
            this.exceptionRateDetail = new exceptionRateDetailObj(erid);
			this.owners = new List<OwnersObj>();                
                
            for(String custId:custIdSet){
               owners.add(new OwnersObj(custId)) ;
            }
        }
    }
    
    //SKPContract.addDetails.contractDetails.exceptionRateDetail
    public class exceptionRateDetailObj{
        public string exceptionRateId;
        
        public exceptionRateDetailObj(string erid){
            this.exceptionRateId = erid;
        }
    }

    public class ownersObj{
        public string customerId;
        public string divisionId;
        public string departmentId;
        
        public ownersObj(string custId){
            this.customerId = custId;
            this.divisionId = '';
            this.departmentId = '';
        }
    }

}