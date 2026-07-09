public with sharing class SKPContractAffiliateOption1 {
    
        //"System" is a reserved variable string, so we need to do a string replace after this has been generated. 
    public string systemStringToBeReplaced = 'AMER'; 
    public string userId;
    public filterObj filter;
    public sourcedObj source;
    
    public addDetailsObj addDetails;
    
    public SKPContractAffiliateOption1(Case caseParam, Quote quoteParam, SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, boolean validateJson, string customerIDParam, string customerNameParam){
        Opportunity opp = caseParam.NCSP_Opportunity__r;
        this.userID = UserInfo.getUserEmail().substring(0,7);
        this.filter = new filterObj(validateJson);
        this.source = new sourcedObj(caseParam.Source_Customer_Id__c,'','');
        this.addDetails = new addDetailsObj(caseParam, quoteParam, opp, mappingParam, indicatorParam, customerIDParam, customerNameParam);
    }
    
    //SKPContract.filterObj
    public class filterObj{
        public string modeOfOperation;

        public filterObj(boolean validateJson){
            this.modeOfOperation = (validateJson) ? 'VALIDATE' : 'CREATE';
        }
    }
    
    public class sourcedObj{
        public string customerId;
        public string divisionId;
        public string departmentId;
        
        public sourcedObj(string customerId,string divisionId,string departmentId){
            this.customerId = customerId;
            this.divisionId = divisionId;
            this.departmentId = departmentId;
        }
    }
    //SKPContract.addDetails
    public class addDetailsObj{
        public contractDetailsObj contractDetails;
        
        public addDetailsObj(Case caseParam, Quote quoteParam, Opportunity opportunityParam, SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, String customerIDParam, String customerNameParam){
            this.contractDetails = new contractDetailsObj(caseParam, quoteParam, opportunityParam, mappingParam, indicatorParam, customerIDParam, customerNameParam ); 
        }
    }
    
    //SKPContract.addDetails.contractDetails
    public class contractDetailsObj{
        public string customerId;
        public string contractType;
        public string divisionId;
        public string departmentId;
        //public string businesstype; // This is NOT camelCased, it is all lowercase. Do not change this.  
        public contractSettingsObj contractSettings;
        
        //public string billingCycle;
        //public string contractVersion;
        public string version;
        public List<salesCommissionObj> salesCommission;
        boolean openShelf;
        //public adminFeeObj adminFee;
                
        public customerNotificationObj customerNotification;
        
        public contractDetailsObj(Case caseParam, Quote quoteParam, Opportunity OpportunityParam, SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, String customerIDParam, String customerNameParam){
     
            this.customerId = caseParam.Customer_ID__r.Name;
            this.contractType = 'AR';
            divisionId = '';
            departmentId = '';
            string serviceLine = caseParam.NCSP_Service_Line_SKP_Mapping__c;
            this.contractSettings = new contractSettingsObj(mappingParam, caseParam, indicatorParam, '');
            this.version = 'AFFILIATE';//caseParam.contract_type__c;
            if(indicatorParam != null)
                openShelf = indicatorParam.openShelf;
            //this.adminFee = new adminFeeObj(mappingParam, indicatorParam);
            Set<String> initBillCodes = new Set<String>();
            this.salesCommission = new List<salesCommissionObj>();
            this.salesCommission.add(new salesCommissionObj(caseParam.Customer_Profile__r, openShelf,'SALES'));
            this.salesCommission.add(new salesCommissionObj(caseParam.Customer_Profile__r, openShelf,'SHREDDING'));
            //this.salesCommission = new List<salesCommissionObj>{new salesCommissionObj(caseParam.Customer_Profile__r, openShelf)};
        }
    }

    //SKPContract.addDetails.contractDetails.contractSettings
    public class contractSettingsObj{
        public string comments;
        
        public contractSettingsObj(SKP_Contract_Type_Mapping__c mappingParam, Case caseParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, string nextYearDateString){
            this.comments = 'AFFILIATE TO '+caseParam.Source_Customer_Id__c;
        }
    }
    
    public class adminFeeObj{
        public boolean enableFuelSurcharge;
        public boolean enableRMAdminFee;
        public string reasonCode;
        
        public adminFeeObj(SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam){
            this.enableFuelSurcharge   = true;
            this.enableRMAdminFee = false;
            this.reasonCode = 'MINIMUM STORAGE ACCOUNT';
        }
    }    
    
    //SKPContract.addDetails.contractDetails.salesCommission
    public class salesCommissionObj{
        public salesDetailObj salesDetail;
        public string salesType;
        //public string startDate;
        //public string endDate='';
        //public boolean dataProtectionRotation = false;
        
        public salesCommissionObj(Customer_Profile__c profileParam, boolean openShelf,string salesType){
            this.salesDetail = new salesDetailObj(profileParam);
            this.salesType = salesType;
        } 
    }
    
    //SKPContract.addDetails.contractDetails.salesCommission.salesDetails
    public class salesDetailObj{
        public List<commissionDetailsObj> commissionDetails;
        public boolean splitCommission;
        public salesDetailObj(Customer_Profile__c profileParam){
            this.commissionDetails = new List<commissionDetailsObj>();
            if(profileParam != null && profileParam.Sales_Rep_Percent_from_Opportunity__c != null && profileParam.Sales_Rep_Percent_from_Opportunity__c < 100 ){
                
                this.commissionDetails.add(new commissionDetailsObj(profileParam, profileParam.Sales_Rep_Percent_from_Opportunity__c));
                this.commissionDetails.add(new commissionDetailsObj(profileParam, profileParam.Split_Rep_Percent_from_Opportunity__c));
                this.splitCommission = true;
                
            } else {
                this.commissionDetails = new List<commissionDetailsObj>{new commissionDetailsObj(profileParam, 100)};
                this.splitCommission = false;
            }
            
            
        }
    }
    //SKPContract.addDetails.contractDetails.salesCommission.salesDetails.comissionDetails
    public class commissionDetailsObj{
        public string territoryId;
        public Decimal percentage;
        public commissionDetailsObj(Customer_Profile__c profileParam, Decimal percentParam){
            if(profileParam != null) {
               this.territoryId = profileParam.Sales_Rep_ID__c;
            }
            this.percentage = percentParam;
        }
    }
    
    public class customerNotificationObj {
        public string districtId;
        public string notificationType;
        public reboxDetailObj reboxDetail;
        
        public customerNotificationObj(Case caseParam){
            this.districtId = 'J';
            this.notificationType = 'Re-Box';
            this.reboxDetail = new reboxDetailObj(caseParam);
           
        }
    }
    
    public class reboxDetailObj {
        public string reboxOption;
        public string contactType;
        
        public List<contactDetailsObj> contactDetails;
        
        public reboxDetailObj(Case caseParam){
            this.reboxOption ='ALWAYS_REBOX';
            this.contactType ='E-MAIL';
            this.contactDetails = new List<contactDetailsObj>{new contactDetailsObj(caseParam)};
        }
    }
    
    public class contactDetailsObj {
        public string contactName;
        public string contactDetailsId;
        public contactDetailsObj(Case caseParam){
            this.contactName = caseParam.Contact.name;
            this.contactDetailsId = caseParam.Contact.email;
        }
    }
}