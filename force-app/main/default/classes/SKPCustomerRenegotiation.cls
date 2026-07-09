public with sharing class SKPCustomerRenegotiation {
    
    public enum availableAddressType {BILLING, CORRESPONDENCE, SHIPPING}
    //"System" is a reserved variable string, so we may need to do a string replace here. 
    public string systemStringToBeReplaced = 'AMER'; 
    
    public string userId;
    public string customerId;
    public filterObj filter;
    
    public updateDetailsObj updateDetails;
    
    
    public SKPCustomerRenegotiation(Case caseParam, Quote quoteParam, boolean validateJson, string username, SkpIntegrationHelper.CustomerIndicator indicatorParam,String customerIdStr){
        Customer_Profile__c profile = caseParam.Customer_Profile__r;
    
        Contact contact = caseParam.contact;
        this.customerId = customerIdStr;
        filter = new filterObj(validateJson);
        updateDetails = new updateDetailsObj(profile, quoteParam, contact, indicatorParam);
        this.userId = UserInfo.getUserEmail().substring(0,7);
    }
    
    public class filterObj{
        string modeOfOperation;
        public filterObj(boolean validateJson){
            this.modeOfOperation = (validateJson) ? 'VALIDATE' : 'UPDATE';
        }
    }
    
    public class updateDetailsObj{
        
        public customerDetailObj customerDetails;
        public updateDetailsObj(Customer_Profile__c profileParam, Quote quoteParam, Contact contactParam, SkpIntegrationHelper.CustomerIndicator indicatorParam){
            customerDetails = new customerDetailObj(profileParam, quoteParam, contactParam, indicatorParam);
        }
    }
    public class customerDetailObj {
        public serviceTypesObj serviceTypes;

        
        public customerDetailObj(Customer_Profile__c profileParam, Quote quoteParam, Contact contactParam, SkpIntegrationHelper.CustomerIndicator indicatorParam){
            this.serviceTypes = new serviceTypesObj(profileParam, indicatorParam);
        }
    }
   
    //addDetails.customerDetail.serviceTypes
    public class serviceTypesObj{
        public recordsManagementObj recordsManagement;
        public shreddingObj shredding;
        
        public serviceTypesObj(Customer_Profile__c profileParam, SkpIntegrationHelper.CustomerIndicator indicatorParam){
            recordsManagement = new recordsManagementObj(profileParam, indicatorParam);
            
            boolean shreddingFlag = false;
            if(indicatorParam != null){ 
                shreddingFlag = indicatorParam.shred;
            }
			if(shreddingFlag)
            	this.shredding = new shreddingObj(shreddingFlag,'');
        }
    }
    
    // addDetails.customerDetail.serviceTypes.recordsManagement
    public class recordsManagementObj{
        public boolean activateHardCopy;
        public boolean faxtrieval;
        public boolean vault;
        public boolean efsService;
        public openShelfObj openShelf;
        public imagingObj imaging;
        
        public recordsManagementObj(Customer_Profile__c profileParam, SkpIntegrationHelper.CustomerIndicator indicatorParam){
            boolean imaging = false;
            boolean openShelf = false;
            this.activateHardCopy = false;
            this.efsService = false;
            this.vault = false;
            this.faxtrieval = false;
            
            if(indicatorParam != null){
                this.activateHardCopy = indicatorParam.hardcopy;
                imaging = indicatorParam.iod;
                openShelf =  indicatorParam.openshelf;
                boolean efsService = indicatorParam.efs;
                boolean vault = indicatorParam.vault;
                this.faxtrieval =  indicatorParam.faxtrieval;
            }
            
            this.openShelf = new openShelfObj(openShelf);
            this.imaging = new imagingObj(imaging);
        }
    }
    
    // addDetails.customerDetail.serviceTypes.recordsManagement.openShelf
    public class openShelfObj{
        public boolean activated;
        
        public openShelfObj(boolean activated){
            this.activated = activated; 

        }
    }
    // addDetails.customerDetail.serviceTypes.recordsManagement.imaging
    public class imagingObj{
        public boolean activated;
        public imagingObj(boolean activatedParam){ 
            this.activated = activatedParam;
        }
    }
    
    //addDetails.customerDetail.serviceTypes.shredding
    public class shreddingObj{
        public boolean activateShredding;
        public string shreddingType;
        public shreddingObj(boolean shredParam,string shreddingType){
            this.activateShredding = shredParam;
            this.shreddingType = 'SCHEDULED';
        }
    }
    
    //addDetails.customerDetail.customerSettings
    public class customerSettingsObj{
        public string businessType;
        public string dunAndBrad;
        
        public customerSettingsObj(Customer_Profile__c profileParam){
            this.businessType = (profileParam.HealthcareAccountStoringPatientRecords__c != null && profileParam.HealthcareAccountStoringPatientRecords__c =='Yes') ? '800' : 'XXX' ;
        }
    }
    
}