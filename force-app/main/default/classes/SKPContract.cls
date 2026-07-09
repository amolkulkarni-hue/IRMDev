public with sharing class SKPContract {
    
    //"System" is a reserved variable string, so we need to do a string replace after this has been generated. 
    public string systemStringToBeReplaced = 'AMER'; 
    
    public string companyID;
    public string userId;
    public filterObj filter;
    
    public addDetailsObj addDetails;
    
    public string customerId;
    
    
    public SKPContract(Case caseParam, Quote quoteParam, SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, boolean validateJson, string customerIDParam, string customerNameParam,Integer proposedYear){
        Opportunity opp = caseParam.NCSP_Opportunity__r;
        
        this.userID = UserInfo.getUserEmail().substring(0,7);
        this.filter = new filterObj(validateJson);
        
        this.addDetails = new addDetailsObj(caseParam, quoteParam, opp, mappingParam, indicatorParam, customerIDParam, customerNameParam,proposedYear);
        this.customerID = customerIDParam; 
    }
    
    //SKPContract.filterObj
    public class filterObj{
        public string modeOfOperation;
        public filterObj(boolean validateJson){
            this.modeOfOperation = (validateJson) ? 'VALIDATE' : 'CREATE';
        }
    }
    
    //SKPContract.addDetails
    public class addDetailsObj{
        public contractDetailsObj contractDetails;
        
        public addDetailsObj(Case caseParam, Quote quoteParam, Opportunity opportunityParam, SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, String customerIDParam, String customerNameParam,Integer proposedYear){
            this.contractDetails = new contractDetailsObj(caseParam, quoteParam, opportunityParam, mappingParam, indicatorParam, customerIDParam, customerNameParam,proposedYear); 
        }
    }
    
    //SKPContract.addDetails.contractDetails
    public class contractDetailsObj{
        public string contractType;
        public string businesstype; // This is NOT camelCased, it is all lowercase. Do not change this.  
        public string  contractEffectiveDate;
        public integer initialContractTerm;
        public integer contractRenewalTerm;
        
        public boolean lateFeeInd;
        public decimal lateFeePercent;
        public adminFeeObj adminFee;
        public contractSettingsObj contractSettings;
        public string billingCycle;
        public exceptionRateDetailObj exceptionRateDetail;
        public string version;
        public string standardRate;
        public List<salesCommissionObj> salesCommission;
        public List<minimumObj> minimum;
        public customerNotificationObj customerNotification;
        
        public contractDetailsObj(Case caseParam, Quote quoteParam, Opportunity OpportunityParam, SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, String customerIDParam, String customerNameParam,Integer proposedYear){
     
            integer rmLength = (quoteParam.RM_Contract_Length__c).intValue();
            integer ssLength = (quoteParam.SS_Contract_Length__c).intValue();
            integer maxYears = rmLength>ssLength ? rmLength : ssLength;
            integer contractTerm = 12;            
            if(caseParam.NCSP_Service_line__c == 'One Time Shred' && caseParam.Contract_Type__c == 'IM-45') contractTerm=1;
            
            this.contractType = 'AR';
            this.initialContractTerm = maxYears * contractTerm ;
            
            //this.initialContractTerm = (mappingParam.Initial_Term__c != null && mappingParam.Initial_Term__c.isnumeric()) ? integer.valueOf(mappingParam.Initial_Term__c) : 12;
            this.contractRenewalTerm = (mappingParam.Renewal_term__c != null && mappingParam.Renewal_term__c.isnumeric()) ? integer.valueOf(mappingParam.Renewal_term__c) : 12;
            if(caseParam.NCSP_Service_line__c == 'One Time Shred' && caseParam.Contract_Type__c == 'IM-45')this.contractRenewalTerm = 0;
            
            string serviceLine = caseParam.NCSP_Service_Line_SKP_Mapping__c;
            //this.businesstype = (serviceLine != null && serviceLine.length() > 20) ?  serviceLine.substring(0, 20) : serviceLine;
            if(indicatorParam != null && indicatorParam.bundledIndicator){
                this.businesstype = 'BUNDLED PROGRAMS';
            }
            else{
                this.businesstype = (serviceLine != null && serviceLine.length() > 20) ?  serviceLine.substring(0, 20) : serviceLine;
            }

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
            string nextQuarterDateString = effectiveDate.addMonths(3).format('yyyy/MM/dd','GMT-04:00');
            this.contractEffectiveDate = contractEffectiveDate.format('yyyy/MM/dd') ;
            
            string nextYearDateString = SkpIntegrationHelper.getNextYearDateString(maxEffectiveDate);
           
            Date reviewDate = maxEffectiveDate.addYears(maxYears-1);
			  
            string reviewDateString = SkpIntegrationHelper.getNextYearDateString(reviewDate);
            
            this.adminFee = new adminFeeObj(mappingParam, indicatorParam);
            this.contractSettings = new contractSettingsObj(mappingParam, caseParam, indicatorParam, reviewDateString);
            this.customerNotification = new customerNotificationObj(caseParam);
            
            this.billingCycle = 'M';
            this.version = caseParam.contract_type__c;
            this.standardRate = String.valueOf(Date.today().year());
            
            boolean openShelf = indicatorParam.openShelf;
            
            
            this.minimum = new List<minimumobj>();
            Set<String> billCodes = Pluck.strings('Product_Name__c', quoteParam.QuoteLineItems);
            Set<String> initBillCodes = new Set<String>();
            
            for (String billCode : billCodes){
                string standardBillCode = SkpIntegrationHelper.cleanBillCode(billcode);
                SKP_Minimum_Mapping__c mapping = SKP_Minimum_Mapping__c.getInstance(standardBillCode);
                if(mapping!= null &&  !(indicatorParam.recurringChargesExists && mapping.Minimum_Type__c == 'Storage')){
                    minimum.add(new minimumobj(mapping));
                }
               
                
                if(SkpIntegrationHelper.isInitBillCode(billCode)){
                    initBillCodes.add(standardBillCode);
                }
            }
            this.exceptionRateDetail = new exceptionRateDetailObj(quoteParam.QuoteLineItems, customerIDParam, customerNameParam, effectiveDateString, nextQuarterDateString, initBillCodes,proposedYear, quoteParam.RM_Contract_Length__c, quoteParam.SS_Contract_Length__c);
            
            //this.salesCommission = new List<salesCommissionObj>{new salesCommissionObj(caseParam.Customer_Profile__r, openShelf)};
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
    
    //SKPContract.addDetails.contractDetails.exceptionRateDetail
    public class exceptionRateDetailObj{
        public string exceptionRateId;
        public string exceptionRateDesc;
        public List<exceptionRateObj> exceptionRates;
        
        public exceptionRateDetailObj(List<QuoteLineItem> lineItemListParam, string customerIDParam, string customerNameParam, string effectiveDateParam, string nextQuarterDateParam, Set<String> initBillCodesParam,Integer proposedYear,decimal rmLength, decimal ssLength){
            string customerName = (customerNameParam != null) ? customerNameParam : '' ;
            this.exceptionRateDesc = customerName.length() > 25 ? customerName.substring(0, 24) : customerName ;
            this.exceptionRateId = customerIdParam;
            this.exceptionRates = new List<exceptionRateObj>();
            Map<String, SKPRecurringChargesDetails__c> recurringChargesDetailsMap=SKPIntegrationHelper.recurringChargesDetails; 
            Decimal proposedYearPrice;
            //ssLength=0;
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

            if(SkpIntegrationHelper.recurringChargesDetails.containsKey(qliParam.Product_Name__c)){
                  this.billCode = SkpIntegrationHelper.recurringChargesDetails.get(qliParam.Product_Name__c).BillCode__c;
            } else
                 this.billCode = SkpIntegrationHelper.cleanBillCode(qliParam.Product_Name__c);
            
           // system.debug('initBillCodesParam=='+initBillCodesParam);
           // system.debug('qliParam.Product_Name__c=='+qliParam.Product_Name__c);
            
            if(initBillCodesParam.contains(qliParam.Product_Name__c) && (!SkpIntegrationHelper.isInitBillCode(qliParam.Product_Name__c))){
                this.effectiveDate = nextQuarterDateParam;
            } else {
                this.effectiveDate = effectiveDateParam;
            } 
            
            
            if(effectiveDate != null && proposedYear != null && proposedYear != 0){
              this.effectiveDate = String.valueOf(Date.valueOf(effectiveDate.replaceAll('/','-')).addYears(proposedYear)).replaceAll('-','/');  
            }
            
            
            this.scaleList = new scaleListObj(qliParam,proposedYearPrice);
        }
        
    }
    
    //SKPContract.addDetails.contractDetails.exceptionRateDetails.exceptionRates.scaleList;
    public class scaleListObj {
        public boolean scaleInd;
        public Decimal exceptRate;
        public string UOM='EA';
        public Decimal baseQty;
        public Decimal baseAmnt;
    public List<scaleQty> scaleQty;        
        public scaleListObj(QuoteLineItem qliParam,Decimal proposedYearPrice){
            if(qliParam.Base_Quantity__c != null || qliParam.Base_Quantity__c != null)
                this.scaleInd = true;
      else
              this.scaleInd = false;
            if(qliParam.Product_Name__c != null 
                         && (qliParam.Product_Name__c.toLowerCase().contains('3472') 
                                     || qliParam.Product_Name__c.toLowerCase().contains('3473')
                                 || qliParam.Product_Name__c.toLowerCase().contains('3474')
                                 || qliParam.Product_Name__c.toLowerCase().contains('3478')
                                 || qliParam.Product_Name__c.toLowerCase().contains('val') 
                                  || qliParam.Product_Name__c.toLowerCase().contains('easy'))
                      ){
                                 this.exceptRate = 99.99;
                             }else {
                                 this.exceptRate = proposedYearPrice != null? proposedYearPrice :qliParam.UnitPrice;
                          }            
            if(qliParam.Base_Quantity__c != null)
              this.baseQty = qliParam.Base_Quantity__c;  
            
            if(qliParam.Base_Amount__c != null)    
              this.baseAmnt = qliParam.Base_Amount__c;
                
            if(qliParam.Unit_of_Measure__c != null) {
                SKP_Bill_Code_UOM__c uomSetting = SKP_Bill_Code_UOM__c.getInstance(qliParam.Unit_of_Measure__c);
                if(uomSetting != null && uomSetting.SKP_UOM__c != null){
                    this.UOM = uomSetting.SKP_UOM__c;
                }
             /*   if(qliParam.Product_Name__c != null 
                         && (qliParam.Product_Name__c.toLowerCase().contains('val') 
                             || qliParam.Product_Name__c.toLowerCase().contains('easy')) ){
                    this.UOM = 'EA';
                }*/
            }
            
            if(qliParam.Unit_Quantity__c != null && qliParam.Unit_Rate__c != null){
                this.scaleQty = new List<scaleQty>();
        this.scaleQty.add(new scaleQty(qliParam.Unit_Quantity__c,qliParam.Unit_Rate__c,UOM));            
             }            
        }
    }
    
    
    //SKPContract.addDetails.contractDetails.contractSettings
    public class contractSettingsObj{
        public Integer netPaymentTerms;
        public Integer rateIncreaseNotice; 
        public Decimal rateIncreaseCap;
        public boolean specialInsuranceInd;
        public boolean clientIndemnifiedInd;
        public boolean IMRMIndemnifiedInd;
        public string excessValidation; 
        public integer rateIncreaseFrequency;
        public string serviceReviewDate;
        public string storageReviewDate;
        public boolean lateFeeInd;
        public decimal lateFeePercent;
        public string clientAuthSign;
        public decimal limitofLiability;
        public string limitofLiabilityUOM;
         public boolean bundlePricingInd;         
        public contractSettingsObj(SKP_Contract_Type_Mapping__c mappingParam, Case caseParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, string reviewDateString){
            
            this.limitofLiability = (indicatorParam != null && indicatorParam.hardcopy) ? 1.00 : 0.00; 
            this.limitofLiabilityUOM = (mappingParam.UOM__c != null) ? mappingParam.UOM__c : 'per unit of storage';
            
            this.storageReviewDate = reviewDateString;
            this.serviceReviewDate = reviewDateString;
            
            this.netPaymentTerms =(mappingParam.Net_Payment__c != null && mappingParam.Net_Payment__c.isnumeric()) ? Integer.valueOf(mappingParam.Net_Payment__c) : 0;
            this.rateIncreaseNotice = (mappingParam.Rate_Increase_Notice__c != null && mappingParam.Rate_Increase_Notice__c.isnumeric()) ? Integer.valueOf(mappingParam.Rate_Increase_Notice__c) : 0;
            this.rateIncreaseCap = (mappingParam.Increase_Cap_Quoted__c != null && mappingParam.Increase_Cap_Quoted__c.isnumeric()) ? Decimal.valueOf(mappingParam.Increase_Cap_Quoted__c) : 0;
            this.specialInsuranceInd = (mappingParam.Insurance_Special__c == 'Yes');
            if(indicatorParam != null && indicatorParam.bundledIndicator){
                this.bundlePricingInd = indicatorParam.bundledIndicator;    
            }            
            
            this.clientIndemnifiedInd = (mappingParam.Indemnification_Customer__c == 'Yes');
            this.IMRMIndemnifiedInd  = (mappingParam.Indemnification_Iron_Mountain__c == 'Yes');
            this.excessValidation = mappingParam.Excess_Value_of_Deposit__c;
            this.rateIncreaseFrequency = 12;
            this.lateFeePercent =(mappingParam.Late_Fee_Percent__c != null && mappingParam.Late_Fee_Percent__c.isnumeric()) ? Decimal.valueOf(mappingParam.Late_Fee_Percent__c) : 0;
            this.lateFeeInd  = (mappingParam.Late_Fee_Indicator__c == 'Yes');
            if(caseParam != null && caseParam.contactID != null){
                String clientName = '';
                clientName += (caseParam.contact.firstName != null ) ? caseParam.contact.FirstName : '';
                clientName += (clientName != '') ? ' ' : ''; 
                clientName += (caseParam.contact.lastName != null) ? caseParam.contact.LastName : '';
                this.clientAuthSign = clientName;  
            } 
        }
    }
    
    //SKPContract.addDetails.contractDetails.salesCommission
    public class salesCommissionObj{
        public salesDetailObj salesDetail;
        public string salesType = '';
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
    
    public class scaleQty{
        public Decimal unitQty;
        public Decimal unitRate;
        public string baseUOM;
        
        public scaleQty(Decimal qty,Decimal rate,string baseUOM){
            this.unitQty = qty;
            this.unitRate = rate;
            this.baseUOM = baseUOM;
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