public with sharing class SKPContractAffiliateOption2 {
    
        //"System" is a reserved variable string, so we need to do a string replace after this has been generated. 
    public string systemStringToBeReplaced = 'AMER'; 
    public string userId;

    public filterObj filter;
    public sourceObj source;    
    public addDetailsObj addDetails;       
    
    
    public SKPContractAffiliateOption2(Case caseParam, Quote quoteParam, SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, boolean validateJson, string customerIDParam, string customerNameParam,integer proposedYear){
        Opportunity opp = caseParam.NCSP_Opportunity__r;
        this.userID = UserInfo.getUserEmail().substring(0,7);
        this.filter = new filterObj(validateJson);
        this.source = new sourceObj(caseParam.Source_Customer_Id__c,'','');
        this.addDetails = new addDetailsObj(caseParam, quoteParam, opp, mappingParam, indicatorParam, customerIDParam, customerNameParam, proposedYear);
    }
    
    //SKPContract.filterObj
    public class filterObj{
        public string modeOfOperation;
        public filterObj(boolean validateJson){
            this.modeOfOperation = (validateJson) ? 'VALIDATE' : 'CREATE';
        }
    }
    
    public class sourceObj{
        public string customerId;
        public string divisionId;
        public string departmentId;
        
        public sourceObj(string customerId,string divisionId,string departmentId){
            this.customerId = customerId;
            this.divisionId = divisionId;
            this.departmentId = departmentId;
        }
    }    
    //SKPContract.addDetails
    public class addDetailsObj{
        public contractDetailsObj contractDetails;
        
        public addDetailsObj(Case caseParam, Quote quoteParam, Opportunity opportunityParam, SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, String customerIDParam, String customerNameParam, integer proposedYear){
            this.contractDetails = new contractDetailsObj(caseParam, quoteParam, opportunityParam, mappingParam, indicatorParam, customerIDParam, customerNameParam, proposedYear); 
        }
    }
    
    //SKPContract.addDetails.contractDetails
    public class contractDetailsObj{
        public string customerId;
        public string contractType;
        public string divisionId;
        public string departmentId;
        public string businesstype; // This is NOT camelCased, it is all lowercase. Do not change this.  
        public string  contractEffectiveDate;
        public integer initialContractTerm;
        public integer contractRenewalTerm;

        //public adminFeeObj adminFee;
        public contractSettingsObj contractSettings;
        public string billingCycle;
        public exceptionRateDetailObj exceptionRateDetail;
        //public string contractVersion;
        public string version;
        public string standardRate;
        public List<salesCommissionObj> salesCommission;
        public List<minimumObj> minimum;        
        public customerNotificationObj customerNotification;
        
        public contractDetailsObj(Case caseParam, Quote quoteParam, Opportunity OpportunityParam, SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, String customerIDParam, String customerNameParam,integer proposedYear){
     
            integer rmLength = (quoteParam.RM_Contract_Length__c).intValue();
            integer ssLength = (quoteParam.SS_Contract_Length__c).intValue();
            integer maxYears = rmLength>ssLength ? rmLength : ssLength;
            integer contractTerm = 12;
            if(caseParam.NCSP_Service_line__c == 'One Time Shred' && caseParam.Contract_Type__c == 'IM-45') contractTerm=1;

            this.customerId = caseParam.Customer_ID__r.Name;
            this.contractType = 'AR';
            divisionId = '';
            departmentId = '';
            this.version = 'AFFILIATE';//caseParam.contract_type__c;
            
            this.initialContractTerm = maxYears * contractTerm;
            
            
            
           // this.initialContractTerm = (mappingParam.Initial_Term__c != null && mappingParam.Initial_Term__c.isnumeric()) ? integer.valueOf(mappingParam.Initial_Term__c) : 12;
           // this.contractRenewalTerm = (mappingParam.Renewal_term__c != null && mappingParam.Renewal_term__c.isnumeric()) ? integer.valueOf(mappingParam.Renewal_term__c) : 12;
            
            
            string serviceLine = caseParam.NCSP_Service_Line_SKP_Mapping__c;
            this.businesstype = (serviceLine != null && serviceLine.length() > 20) ?  serviceLine.substring(0, 20) : serviceLine;
            
            Date nullcheckedEffectiveDate = (caseParam.Contract_Effective_Date__c != null) ? Date.valueOf(caseParam.Contract_Effective_Date__c) : null;
            Date maxEffectiveDate = SkpIntegrationHelper.maxDate( nullcheckedEffectiveDate, quoteParam.Effective_Date__c); 
            
            Datetime contractEffectiveDate = datetime.newInstance( maxEffectiveDate.year(),
                                                           maxEffectiveDate.month(),
                                                           maxEffectiveDate.day());
            Datetime effectiveDate = datetime.newInstance( maxEffectiveDate.year(),
                                                           maxEffectiveDate.month(),
                                                           1);
            
            Datetime effectiveDateNew = datetime.newInstance(System.now().year(),
                                                           System.now().month(),
                                                           1);
            
            string effectiveDateString = effectiveDateNew.format('yyyy/MM/dd');
            
            //string effectiveDateString = effectiveDate.format('yyyy/MM/dd');
            string nextQuarterDateString = effectiveDate.addMonths(3).format('yyyy/MM/dd');
            //this.contractEffectiveDate = contractEffectiveDate.format('yyyy/MM/dd') ;
            
            string nextYearDateString = SkpIntegrationHelper.getNextYearDateString(maxEffectiveDate);
            
            Date reviewDate = maxEffectiveDate.addYears(maxYears-1);
			  
            string reviewDateString = SkpIntegrationHelper.getNextYearDateString(reviewDate);
            
            //this.adminFee = new adminFeeObj(mappingParam, indicatorParam);
            //this.contractSettings = new contractSettingsObj(mappingParam, caseParam, indicatorParam, nextYearDateString);
            
            this.contractSettings = new contractSettingsObj(mappingParam, caseParam, indicatorParam, reviewDateString);            
            
            this.billingCycle = 'M';
            //this.version = caseParam.contract_type__c;

            this.standardRate = String.valueOf(Date.today().year());
            
            boolean openShelf = indicatorParam.openShelf;
            
            
            this.minimum = new List<minimumobj>();
            Set<String> billCodes = Pluck.strings('Product_Name__c', quoteParam.QuoteLineItems);
            Set<String> initBillCodes = new Set<String>();
            
            for (String billCode : billCodes){
                string standardBillCode = SkpIntegrationHelper.cleanBillCode(billcode);
                SKP_Minimum_Mapping__c mapping = SKP_Minimum_Mapping__c.getInstance(standardBillCode);
                if(mapping!= null){
                    minimum.add(new minimumobj(mapping));
                }
               
                
                if(SkpIntegrationHelper.isInitBillCode(billCode)){
                    initBillCodes.add(standardBillCode);
                }
            } 
            
            this.exceptionRateDetail = new exceptionRateDetailObj(quoteParam.QuoteLineItems, customerIDParam, customerNameParam, effectiveDateString, nextQuarterDateString, initBillCodes, proposedYear, quoteParam.RM_Contract_Length__c, quoteParam.SS_Contract_Length__c);
            
            if(indicatorParam.shredAndServiceBoth){
                this.salesCommission = new List<salesCommissionObj>();
                this.salesCommission.add(new salesCommissionObj(caseParam.Customer_Profile__r, openShelf,'SALES'));
                this.salesCommission.add(new salesCommissionObj(caseParam.Customer_Profile__r, openShelf,'SHREDDING'));                
             }else{
                this.salesCommission = new List<salesCommissionObj>{new salesCommissionObj(caseParam.Customer_Profile__r, openShelf,indicatorParam.shred == true ?'SHREDDING':'SALES')};
             }                
        }
    }
    //SKPContract.addDetails.contractDetails.adminFee
  /*  public class adminFeeObj{
        public boolean enableFuelSurcharge;
        public boolean enableRMAdminFee;
        public string reasonCode;
        public string deptAllocation;
        public string divisionId;
        public string departmentId;     
        public boolean enableLinkTransBilling;
        public boolean enableBillRSHStorage;
        
        public adminFeeObj(SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam){
            this.enableFuelSurcharge   = (mappingParam.Fuel_Surcharge_Indicator__c  == 'Yes');
            this.enableRMAdminFee = indicatorParam.rmAdminFee;
            this.reasonCode = indicatorParam.reasonCode;
            deptAllocation = 'APPLY TO MASTER DIVISION/DEPARTMENT';
            divisionId = '';
            departmentId = '';
            enableLinkTransBilling = true;
            enableBillRSHStorage = true;
        }
    }*/
    
    //SKPContract.addDetails.contractDetails.exceptionRateDetail
    public class exceptionRateDetailObj{
        public string exceptionRateId;
        public string exceptionRateDesc;
        public List<exceptionRateObj> exceptionRates;
        
        public exceptionRateDetailObj(List<QuoteLineItem> lineItemListParam, string customerIDParam, string customerNameParam, string effectiveDateParam, string nextQuarterDateParam, Set<String> initBillCodesParam,integer proposedYear,decimal rmLength, decimal ssLength){
            string customerName = (customerNameParam != null) ? customerNameParam : '' ;
            this.exceptionRateDesc = customerName.length() > 25 ? customerName.substring(0, 24) : customerName ;
            this.exceptionRateId = customerIdParam;
            this.exceptionRates = new List<exceptionRateObj>();
            Decimal proposedYearPrice;            
            
            for(QuoteLineItem qli : lineItemListParam){
                SKP_Excluded_Billcodes__c excludedBillCode = SKP_Excluded_Billcodes__c.getInstance(qli.Product_Name__c);
                if(excludedBillCode == null) {
                
                    string serviceCateg=qli.Category_Abbreviation__c;
                    if(serviceCateg.startsWith('RM') && proposedYear <=rmLength)
                    {
                        if(proposedYear == 1){
                           exceptionRates.add(new exceptionRateObj(qli, effectiveDateParam, nextQuarterDateParam, initBillCodesParam,null,null));
                        }                           
                    }
                    else if(serviceCateg=='Shred' && proposedYear <=ssLength)
                    {
                        if(proposedYear == 1){
                           exceptionRates.add(new exceptionRateObj(qli, effectiveDateParam, nextQuarterDateParam, initBillCodesParam,null,null));
                        }                          
                    }                    
                    
                    //exceptionRates.add(new exceptionRateObj(qli, effectiveDateParam, nextQuarterDateParam, initBillCodesParam));
                }
            }
        }
        
    }
    
    //SKPContract.addDetails.contractDetails.exceptionRateDetail.exceptionRates
    public class exceptionRateObj {
        public string districtId;
        public string billCode;
        public string effectiveDate;
        
        public scaleListObj scaleList;
        
        public exceptionRateObj(){}
        
        public exceptionRateObj(QuoteLineItem qliParam, String effectiveDateParam, string nextQuarterDateParam, Set<String> initBillCodesParam,Decimal proposedYearPrice,integer proposedYear){
            this.districtId = 'ALL';
            
            this.billCode = SkpIntegrationHelper.cleanBillCode(qliParam.Product_Name__c);
            
            if(initBillCodesParam.contains(qliParam.Product_Name__c) && (!SkpIntegrationHelper.isInitBillCode(qliParam.Product_Name__c))){
                this.effectiveDate = nextQuarterDateParam;
            } else {
                this.effectiveDate = effectiveDateParam;
            } 
            if(effectiveDate != null && proposedYear != null){
              this.effectiveDate = String.valueOf(Date.valueOf(effectiveDate.replaceAll('/','-')).addYears(proposedYear)).replaceAll('-','/');  
            }  
            
            this.scaleList = new scaleListObj(qliParam,proposedYearPrice);
        }
        
    }
    
    //SKPContract.addDetails.contractDetails.exceptionRateDetails.exceptionRates.scaleList;
    public class scaleListObj {
        public boolean scaleInd;
        public Decimal exceptRate;
        //public string UOM;
        public string UOM='EA';
        
        public scaleListObj(QuoteLineItem qliParam,Decimal proposedYearPrice){
            this.scaleInd = false;
            //this.exceptRate = qliParam.UnitPrice;
            this.exceptRate = proposedYearPrice != null? proposedYearPrice :qliParam.UnitPrice;
            if(qliParam.Unit_of_Measure__c != null) {
                SKP_Bill_Code_UOM__c uomSetting = SKP_Bill_Code_UOM__c.getInstance(qliParam.Unit_of_Measure__c);
                if(uomSetting != null){
                    this.UOM = uomSetting.SKP_UOM__c;
                }
            }
        }
    }
    
    
    //SKPContract.addDetails.contractDetails.contractSettings
    public class contractSettingsObj{
        public Integer netPaymentTerms;
        public Integer rateIncreaseNotice; 
        public Decimal rateIncreaseCap;
       // public boolean specialInsuranceInd;
       // public boolean clientIndemnifiedInd;
       // public boolean IMRMIndemnifiedInd;
        public string excessValidation; 
        public integer rateIncreaseFrequency;
        public string serviceReviewDate;
        public string storageReviewDate;
        public boolean lateFeeInd;
        public decimal lateFeePercent;
       // public string clientAuthSign;
        public decimal limitofLiability;
        public string limitofLiabilityUOM;
        //public string lastServiceIncrease;
        //public string lastStorageIncrease;
        
        public string comments;
        
        public contractSettingsObj(SKP_Contract_Type_Mapping__c mappingParam, Case caseParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, string reviewDateString){
            
            this.limitofLiability = (indicatorParam != null && indicatorParam.hardcopy) ? 1.00 : 0.00; 
            this.limitofLiabilityUOM = (mappingParam.UOM__c != null) ? mappingParam.UOM__c : 'per unit of storage';
            
            this.storageReviewDate = reviewDateString;
            this.serviceReviewDate = reviewDateString;
            
            this.netPaymentTerms =(mappingParam.Net_Payment__c != null && mappingParam.Net_Payment__c.isnumeric()) ? Integer.valueOf(mappingParam.Net_Payment__c) : 0;
            this.rateIncreaseNotice = (mappingParam.Rate_Increase_Notice__c != null && mappingParam.Rate_Increase_Notice__c.isnumeric()) ? Integer.valueOf(mappingParam.Rate_Increase_Notice__c) : 0;
            this.rateIncreaseCap = (mappingParam.Increase_Cap_Quoted__c != null && mappingParam.Increase_Cap_Quoted__c.isnumeric()) ? Decimal.valueOf(mappingParam.Increase_Cap_Quoted__c) : 0;
            //this.specialInsuranceInd = (mappingParam.Insurance_Special__c == 'Yes');
            
            //this.clientIndemnifiedInd = (mappingParam.Indemnification_Customer__c == 'Yes');
            //this.IMRMIndemnifiedInd  = (mappingParam.Indemnification_Iron_Mountain__c == 'Yes');
            this.excessValidation = mappingParam.Excess_Value_of_Deposit__c;
            this.rateIncreaseFrequency = 12;
            this.lateFeePercent =(mappingParam.Late_Fee_Percent__c != null && mappingParam.Late_Fee_Percent__c.isnumeric()) ? Decimal.valueOf(mappingParam.Late_Fee_Percent__c) : 0;
            this.lateFeeInd  = (mappingParam.Late_Fee_Indicator__c == 'Yes');
            if(caseParam != null && caseParam.contactID != null){
                String clientName = '';
                clientName += (caseParam.contact.firstName != null ) ? caseParam.contact.FirstName : '';
                clientName += (clientName != '') ? ' ' : ''; 
                clientName += (caseParam.contact.lastName != null) ? caseParam.contact.LastName : '';
                //this.clientAuthSign = clientName;  
            } 
            //this.lastServiceIncrease = '';
            //this.lastStorageIncrease = '';
            this.comments = 'AFFILIATE TO '+caseParam.Source_Customer_Id__c+' DIFFERENT RATES';
        }
    }
    
    //SKPContract.addDetails.contractDetails.salesCommission
    public class salesCommissionObj{
        public salesDetailObj salesDetail;
        public string salesType = '';
        public string startDate;
        //public string endDate='';
        public boolean openShelfEnabled;
        public boolean dataProtectionRotation = false;
        
        public salesCommissionObj(Customer_Profile__c profileParam, boolean openShelf,String salesType){
            this.salesType = salesType;
            this.salesDetail = new salesDetailObj(profileParam);
            this.openShelfEnabled = openShelf;
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
        //public string districtId;//value is not yet set need to be confirmed;
        public commissionDetailsObj(Customer_Profile__c profileParam, Decimal percentParam){
            if(profileParam != null) {
               this.territoryId = profileParam.Sales_Rep_ID__c;
            }
            
            this.percentage = percentParam;
        }
    }
    
    
    //SKPContract.addDetails.contractDetails.minimumObj
    public class minimumObj {
        public string minimumType;
        public string orderType;
        public string level;
        public string storageType;
        
        public minimumObj(SKP_Minimum_Mapping__c mapping){
            this.minimumType = mapping.minimum_Type__c;
            this.orderType = mapping.Minimum_Order_Type__c;
            this.storageType = mapping.Minimum_Storage_Type__c;
            this.level = mapping.minimum_level__c;
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