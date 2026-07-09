public class SKPPreValidationContract {
    //"System" is a reserved variable string, so we need to do a string replace after this has been generated. 
    public string systemStringToBeReplaced = 'AMER'; 
    public string customerId;
    public filterObj filter;
    
    public SKPPreValidationContract(Case caseParam,string customerId){
        this.filter = new filterObj();
        this.customerID = customerId;
    }
    
    //SKPContract.filterObj
    public class filterObj{
        public string divisionId;
        public string departmentId;
        public string contractType;
        
        public filterObj(){
           divisionId = '';
           departmentId = ''; 
           contractType = 'AR';
        }
    }
}