public with sharing class SKPContractRenewal {
    
        //"System" is a reserved variable string, so we need to do a string replace after this has been generated. 
    public string systemStringToBeReplaced = 'AMER'; 
    public string companyID;
    public string userId;
    public filterObj filter;
    
    public UpdateDetailsObj updateDetails;
    
    //public string customerId;
    
    
    public SKPContractRenewal(Case caseParam, Quote quoteParam, SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, boolean validateJson, string customerIDParam, string customerNameParam,string erid,Set<String> custIdSet, Integer proposedYear){
        Opportunity opp = caseParam.NCSP_Opportunity__r;
        
        this.userID = UserInfo.getUserEmail().substring(0,7);
        this.filter = new filterObj(validateJson);
        
        this.updateDetails = new UpdateDetailsObj(caseParam, quoteParam, opp, mappingParam, indicatorParam, customerIDParam, customerNameParam,erid,custIdSet, proposedYear);
    }
    
    //SKPContract.filterObj
    public class filterObj{
        public string modeOfOperation;
        public filterObj(boolean validateJson){
            this.modeOfOperation = (validateJson) ? 'VALIDATE' : 'UPDATE';
        }
    }
    
    //SKPContract.addDetails
    public class UpdateDetailsObj{
        public contractDetailsObj contractDetails;
        
        public UpdateDetailsObj(Case caseParam, Quote quoteParam, Opportunity opportunityParam, SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, String customerIDParam, String customerNameParam,string erid,Set<String> custIdSet,Integer proposedYear){
            this.contractDetails = new contractDetailsObj(caseParam, quoteParam, opportunityParam, mappingParam, indicatorParam, customerIDParam, customerNameParam,erid,custIdSet, proposedYear); 
        }
    }
    
    //SKPContract.addDetails.contractDetails
    public class contractDetailsObj{
        public string contractType;
        public string standardRate;        
        public string businesstype; // This is NOT camelCased, it is all lowercase. Do not change this.          
        public contractSettingsObj contractSettings;
        public exceptionRateDetailObj exceptionRateDetail;
        public List<minimumObj> minimum;
        public List<ownersObj> owners;
        //public adminFeeObj adminFee;
        public contractDetailsObj(Case caseParam, Quote quoteParam, Opportunity OpportunityParam, SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, String customerIDParam, String customerNameParam,string erid,Set<String> custIdSet,Integer proposedYear){
     
            integer rmLength = (quoteParam.RM_Contract_Length__c).intValue();
            integer ssLength = (quoteParam.SS_Contract_Length__c).intValue();
            integer maxYears = rmLength>ssLength ? rmLength : ssLength;
            
            this.contractType = 'AR';
            Date nullcheckedEffectiveDate = (caseParam.Contract_Effective_Date__c != null) ? Date.valueOf(caseParam.Contract_Effective_Date__c) : null;
            Date maxEffectiveDate = SkpIntegrationHelper.maxDate( nullcheckedEffectiveDate, quoteParam.Effective_Date__c); 
            
            Datetime contractEffectiveDate = datetime.newInstance( maxEffectiveDate.year(),
                                                           maxEffectiveDate.month(),
                                                           maxEffectiveDate.day());
            Datetime effectiveDate = datetime.newInstance( maxEffectiveDate.year(),
                                                           maxEffectiveDate.month(),
                                                           1);
            
            
            string effectiveDateString = effectiveDate.format('yyyy/MM/dd');
            //string nextQuarterDateString = effectiveDate.addMonths(3).format('yyyy/MM/dd');
            string nextQuarterDateString = effectiveDate.addMonths(3).format('yyyy/MM/dd','GMT-04:00');            
            //this.contractEffectiveDate = contractEffectiveDate.format('yyyy/MM/dd') ;
            
            string nextYearDateString = SkpIntegrationHelper.getNextYearDateString(maxEffectiveDate);
           	
            Date reviewDate = maxEffectiveDate.addYears(maxYears-1);
			  
            string reviewDateString = SkpIntegrationHelper.getNextYearDateString(reviewDate);
            
            this.contractSettings = new contractSettingsObj(mappingParam, caseParam, indicatorParam, reviewDateString);
            
            this.standardRate = String.valueOf(Date.today().year());
            /*if(indicatorParam.recurringChargesExists){
                this.adminFee = new adminFeeObj(mappingParam, indicatorParam);
            } */   
            boolean openShelf = indicatorParam.openShelf;
            string serviceLine = caseParam.NCSP_Service_Line_SKP_Mapping__c;
            if(indicatorParam != null && indicatorParam.bundledIndicator){
                this.businesstype = 'BUNDLED PROGRAMS';
            }
            else{
                this.businesstype = (serviceLine != null && serviceLine.length() > 20) ?  serviceLine.substring(0, 20) : serviceLine;
            }
            
            
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
            
            this.exceptionRateDetail = new exceptionRateDetailObj(quoteParam.QuoteLineItems, customerIDParam, customerNameParam, effectiveDateString, nextQuarterDateString, initBillCodes,erid, proposedYear, quoteParam.RM_Contract_Length__c, quoteParam.SS_Contract_Length__c);
            
            this.owners = new List<OwnersObj>();                
                
            for(String custId:custIdSet){
               owners.add(new OwnersObj(custId)) ;
            }
        }
    }

    //SKPContract.addDetails.contractDetails.adminFee
    public class adminFeeObj{
        public boolean enableRMAdminFee;
        public string reasonCode;
        
        
        public adminFeeObj(SKP_Contract_Type_Mapping__c mappingParam, SkpIntegrationHelper.CustomerIndicator indicatorParam){
            this.enableRMAdminFee = indicatorParam.rmAdminFee;
            this.reasonCode = indicatorParam.reasonCode;
        }
    }
    
    //SKPContract.addDetails.contractDetails.exceptionRateDetail
    public class exceptionRateDetailObj{
        public string exceptionRateId;
        //public string exceptionRateDesc;
        public List<exceptionRateObj> exceptionRates;
        
        public exceptionRateDetailObj(List<QuoteLineItem> lineItemListParam, string customerIDParam, string customerNameParam, string effectiveDateParam, string nextQuarterDateParam, Set<String> initBillCodesParam,string erid,Integer proposedYear,decimal rmLength, decimal ssLength){
            string customerName = (customerNameParam != null) ? customerNameParam : '' ;
           // this.exceptionRateDesc = customerName.length() > 25 ? customerName.substring(0, 24) : customerName ;
            this.exceptionRateId = erid;
            this.exceptionRates = new List<exceptionRateObj>();
            Decimal proposedYearPrice;           
            //proposedYear=proposedYear-1;         
            Integer proposedYearCurrent=proposedYear-1;   
            for(QuoteLineItem qli : lineItemListParam){
                SKP_Excluded_Billcodes__c excludedBillCode = SKP_Excluded_Billcodes__c.getInstance(qli.Product_Name__c);
                if(excludedBillCode == null) {
                    
                    string serviceCateg=qli.Category_Abbreviation__c;
                    
                    if(proposedYear==1)proposedYearPrice = qli.Proposed_Price_Year_1__c;
                    else if(proposedYear==2)proposedYearPrice = qli.Proposed_Price_Year_2__c;
                    else if(proposedYear==3)proposedYearPrice = qli.Proposed_Price_Year_3__c;
                    else if(proposedYear==4)proposedYearPrice = qli.Proposed_Price_Year_4__c;
                    else if(proposedYear==5)proposedYearPrice = qli.Proposed_Price_Year_5__c;
                    else if(proposedYear==6)proposedYearPrice = qli.Proposed_Price_Year_6__c;
                    else if(proposedYear==7)proposedYearPrice = qli.Proposed_Price_Year_7__c;
                    else if(proposedYear==8)proposedYearPrice = qli.Proposed_Price_Year_8__c;
                    else if(proposedYear==9)proposedYearPrice = qli.Proposed_Price_Year_9__c;
                    else if(proposedYear==10)proposedYearPrice = qli.Proposed_Price_Year_10__c;
                    
                    system.debug('serviceCateg=='+serviceCateg);
                    
                    if(serviceCateg.startsWith('RM') && proposedYear <=rmLength)
                    {
                        system.debug('in RM');
                        exceptionRates.add(new exceptionRateObj(qli, effectiveDateParam, nextQuarterDateParam, initBillCodesParam,proposedYearPrice,proposedYearCurrent));                                          
                    }
                    else if(serviceCateg=='Shred' && proposedYear <=ssLength)
                    {
                        system.debug('in Shred');
                        exceptionRates.add(new exceptionRateObj(qli, effectiveDateParam, nextQuarterDateParam, initBillCodesParam,proposedYearPrice,proposedYearCurrent));                                                              
                    }
                    
                    /*if(proposedYearCurrent==0)
                    {
                        exceptionRates.add(new exceptionRateObj(qli, effectiveDateParam, nextQuarterDateParam, initBillCodesParam,null,null));
                    }
                    else
                    {
                        exceptionRates.add(new exceptionRateObj(qli, effectiveDateParam, nextQuarterDateParam, initBillCodesParam,proposedYearPrice,proposedYearCurrent));                                                                                     
                    }   */
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
            
            if(effectiveDate != null && proposedYear != null && proposedYear != 0){
              this.effectiveDate = String.valueOf(Date.valueOf(effectiveDate.replaceAll('/','-')).addYears(proposedYear)).replaceAll('-','/');  
              //this.districtId = '*';                
            }            
            
            if(SkpIntegrationHelper.recurringChargesDetails.containsKey(qliParam.Product_Name__c)){
                  this.billCode = SkpIntegrationHelper.recurringChargesDetails.get(qliParam.Product_Name__c).BillCode__c;
            } else
                this.billCode = SkpIntegrationHelper.cleanBillCode(qliParam.Product_Name__c);
           
            
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
            if(qliParam.Product_Name__c != null 
               && (qliParam.Product_Name__c.toLowerCase().contains('3472') 
                   || qliParam.Product_Name__c.toLowerCase().contains('3473')
                   || qliParam.Product_Name__c.toLowerCase().contains('3474') 
                   || qliParam.Product_Name__c.toLowerCase().contains('3478')
                   || qliParam.Product_Name__c.toLowerCase().contains('val') 
                   || qliParam.Product_Name__c.toLowerCase().contains('easy')) ){
                       this.exceptRate = 99.99;
                   }else {
                       this.exceptRate = proposedYearPrice != null? proposedYearPrice :qliParam.UnitPrice;
                   }
            if(qliParam.Base_Quantity__c != null || qliParam.Base_Quantity__c != null)
                this.scaleInd = true;
            else
                this.scaleInd = false;
            if(qliParam.Base_Quantity__c != null)
              this.baseQty = qliParam.Base_Quantity__c;  
            
            if(qliParam.Base_Amount__c != null)    
              this.baseAmnt = qliParam.Base_Amount__c;
            
            if(qliParam.Unit_of_Measure__c != null) {
                SKP_Bill_Code_UOM__c uomSetting = SKP_Bill_Code_UOM__c.getInstance(qliParam.Unit_of_Measure__c);
                if(uomSetting != null){
                    this.UOM = uomSetting.SKP_UOM__c;
                }else if(qliParam.Product_Name__c != null 
                         && (qliParam.Product_Name__c.toLowerCase().contains('val') 
                             || qliParam.Product_Name__c.toLowerCase().contains('easy')
                             || qliParam.Product_Name__c.toLowerCase().contains('3472') 
                             || qliParam.Product_Name__c.toLowerCase().contains('3473')) ){
                    this.UOM = 'EA';
                }
            }
            if(qliParam.Unit_Quantity__c != null && qliParam.Unit_Rate__c != null){
                this.scaleQty = new List<scaleQty>();
                this.scaleQty.add(new scaleQty(qliParam.Unit_Quantity__c,qliParam.Unit_Rate__c,UOM));            
             }            
        }
    }
    
    
    //SKPContract.addDetails.contractDetails.contractSettings
    public class contractSettingsObj{
       public string serviceReviewDate;
       public string storageReviewDate;
       public boolean bundlePricingInd; 

        public contractSettingsObj(SKP_Contract_Type_Mapping__c mappingParam, Case caseParam, SkpIntegrationHelper.CustomerIndicator indicatorParam, string reviewDateString){
            this.storageReviewDate = reviewDateString;
            this.serviceReviewDate = reviewDateString;
            if(indicatorParam != null && indicatorParam.bundledIndicator){
                this.bundlePricingInd = indicatorParam.bundledIndicator;    
            }            
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
    
    public class scaleQty{
        public Decimal unitQty;
        public Decimal unitRate;
        public String baseUOM;
        
        public scaleQty(Decimal qty,Decimal rate,string baseUOM){
            this.unitQty = qty;
            this.unitRate = rate;
            this.baseUOM = baseUOM;
        }
        
    }    
}