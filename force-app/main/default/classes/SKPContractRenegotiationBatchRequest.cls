public class SKPContractRenegotiationBatchRequest {
    
        //"System" is a reserved variable string, so we need to do a string replace after this has been generated. 
    public string systemStringToBeReplaced = 'AMER';     
    public string companyID;
    public string userId;
    public filterObj filter;
    public UpdateDetailsObj updateDetails;    
    
    public SKPContractRenegotiationBatchRequest(Case caseParam,string erid,Set<String> custIdSet,SKP_Contract_Type_Mapping__c mappingParam,SkpIntegrationHelper.CustomerIndicator indicatorParam){
        this.userID = UserInfo.getUserEmail().substring(0,7);
        this.filter = new filterObj();
        this.updateDetails = new UpdateDetailsObj(caseParam,erid,custIdSet,mappingParam, indicatorParam);
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
        
        public UpdateDetailsObj(Case caseParam,string erid,Set<String> custIdSet,SKP_Contract_Type_Mapping__c mappingParam,SkpIntegrationHelper.CustomerIndicator indicatorParam){
            this.contractDetails = new contractDetailsObj(caseParam,erid,custIdSet,mappingParam, indicatorParam); 
        }
    }
    
    //SKPContract.addDetails.contractDetails
    public class contractDetailsObj{
        public string contractType;
        public exceptionRateDetailObj exceptionRateDetail;
        public string standardRate;
        public List<ownersObj> owners;
        public adminFeeObj adminFee;
        
        public contractDetailsObj(Case caseParam,string erid,Set<String> custIdSet,SKP_Contract_Type_Mapping__c mappingParam,SkpIntegrationHelper.CustomerIndicator indicatorParam){
     
            this.contractType = 'AR';
            this.standardRate = String.valueOf(Date.today().year());
            this.exceptionRateDetail = new exceptionRateDetailObj(erid);
            this.owners = new List<OwnersObj>();  
            this.adminFee = new adminFeeObj(mappingParam, indicatorParam);
                
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
    
    //SKPContract.addDetails.contractDetails.adminFee
    public class adminFeeObj{
        public boolean enableFuelSurcharge;
        public boolean enableRMAdminFee;
        public string reasonCode;
        
        
        public adminFeeObj(SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam){
            this.enableFuelSurcharge   = (mappingParam.Fuel_Surcharge_Indicator__c  == 'Yes');
            this.enableRMAdminFee = indicatorParam.rmAdminFee;
            this.reasonCode = indicatorParam.reasonCode;
        }
    }

}