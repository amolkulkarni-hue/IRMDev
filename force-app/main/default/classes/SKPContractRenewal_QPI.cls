public class SKPContractRenewal_QPI  {
    
    //"System" is a reserved variable string, so we need to do a string replace after this has been generated. 
    public string systemStringToBeReplaced = 'AMER';     
    public string companyID;
    public string userId;
    public filterObj filter;
    public UpdateDetailsObj updateDetails;   
    Public static boolean minimumStorage = false;
    Public static boolean minimumOrder = false;
    
    
    public SKPContractRenewal_QPI(Quote quoteParam,string erid,Set<String> custIdSet,String customerNameParam){
        this.userID = UserInfo.getUserEmail().substring(0,7);
        this.filter = new filterObj();
        minimumStorage = false;
        minimumOrder = false;
        this.updateDetails = new UpdateDetailsObj(quoteParam,erid,custIdSet,customerNameParam);
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
        
        public UpdateDetailsObj(Quote quoteParam,string erid,Set<String> custIdSet,String customerNameParam){
            this.contractDetails = new contractDetailsObj(quoteParam,erid,custIdSet,customerNameParam); 
        }
    }
    
    //SKPContract.addDetails.contractDetails
    public class contractDetailsObj{
        public Boolean QPI;
        public string contractType;
        public exceptionRateDetailObj exceptionRateDetail;
       // public string standardRate;
        public List<ownersObj> owners;
        public List<minimumObj> minimum;        
        public contractSettingsObj contractSettings;        
        
        public contractDetailsObj(Quote quoteParam,string erid,Set<String> custIdSet,String customerNameParam){
            this.QPI = true;
            this.contractType = 'AR';
           // this.standardRate = String.valueOf(Date.today().year());
            this.owners = new List<OwnersObj>();                
           // Date maxEffectiveDate = quoteParam.Effective_Date__c; 
            Date maxEffectiveDate = quoteParam.q2w_Effective_Date__c; 
            
            Datetime contractEffectiveDate = datetime.newInstance( maxEffectiveDate.year(),
                                                           maxEffectiveDate.month(),
                                                           maxEffectiveDate.day());
            Datetime effectiveDate = datetime.newInstance( maxEffectiveDate.year(),
                                                           maxEffectiveDate.month(),
                                                           1);
            
            
            string effectiveDateString = effectiveDate.format('yyyy/MM/dd');
            string nextQuarterDateString = effectiveDate.addMonths(3).format('yyyy/MM/dd');
            string nextYearDateString = SkpIntegrationHelper.getNextYearDateString(maxEffectiveDate);

            this.contractSettings = new contractSettingsObj(nextYearDateString,effectiveDateString);    
            this.minimum = new List<minimumobj>();
            Set<String> billCodes = Pluck.strings('Product_Name__c', quoteParam.QuoteLineItems);
            Set<String> initBillCodes = new Set<String>();
            for (String billCode : billCodes){
                string standardBillCode = SkpIntegrationHelper.cleanBillCode(billcode);   
                SKP_Minimum_Mapping__c mapping = SKP_Minimum_Mapping__c.getInstance(standardBillCode);
                if(mapping!= null){
                    if(mapping.minimum_Type__c=='Storage' && minimumStorage == false)
                    {                        
                    	minimum.add(new minimumobj(mapping));
                        minimumStorage=true;
                    }
                    else if(mapping.minimum_Type__c=='Order' && minimumOrder == false)
                    {                                              
                    	minimum.add(new minimumobj(mapping));
                        minimumOrder=true;
                    }
                }
               
                
                if(SkpIntegrationHelper.isInitBillCode(billCode)){
                    initBillCodes.add(standardBillCode);
                }
            }
                    
            for(String custId:custIdSet){
               owners.add(new OwnersObj(custId)) ;
            }
            this.exceptionRateDetail = new exceptionRateDetailObj(quoteParam.QuoteLineItems, customerNameParam, effectiveDateString, nextQuarterDateString, initBillCodes,erid);                        
        }
    }
    
    //SKPContract.addDetails.contractDetails.exceptionRateDetail
    public class exceptionRateDetailObj{
        public string exceptionRateId;
        public string exceptionRateDesc;
        public List<exceptionRateObj> exceptionRates;
        
        public exceptionRateDetailObj(List<QuoteLineItem> lineItemListParam, string customerNameParam, string effectiveDateParam, string nextQuarterDateParam, Set<String> initBillCodesParam,string erid){
            string customerName = (customerNameParam != null) ? customerNameParam : '' ;
            this.exceptionRateDesc = '';//customerName.length() > 25 ? customerName.substring(0, 24) : customerName ;
            this.exceptionRateId = erid;
            this.exceptionRates = new List<exceptionRateObj>();
            
            
            for(QuoteLineItem qli : lineItemListParam){
                SKP_Excluded_Billcodes__c excludedBillCode = SKP_Excluded_Billcodes__c.getInstance(qli.Product_Name__c);
                if(excludedBillCode == null) {
                    exceptionRates.add(new exceptionRateObj(qli, effectiveDateParam, nextQuarterDateParam, initBillCodesParam));
                }
            }
        }
    }
    public class exceptionRateObj {
        public string districtId;
        public string billCode;
        public string effectiveDate;
        
        public scaleListObj scaleList;
        
        public exceptionRateObj(){}
        
        public exceptionRateObj(QuoteLineItem qliParam, String effectiveDateParam, string nextQuarterDateParam, Set<String> initBillCodesParam){
            this.districtId = 'ALL';
            
            this.billCode = SkpIntegrationHelper.cleanBillCode(qliParam.Product_Name__c);
            
            /*if(initBillCodesParam.contains(qliParam.Product_Name__c) && (!SkpIntegrationHelper.isInitBillCode(qliParam.Product_Name__c))){
                this.effectiveDate = nextQuarterDateParam;
            } else */
            {
                this.effectiveDate = effectiveDateParam;
            } 
            
            
            this.scaleList = new scaleListObj(qliParam);
        }
        
    }
    
    public class scaleListObj {
        public boolean scaleInd;
        public Decimal exceptRate;
        public string UOM='EA';
        
        public scaleListObj(QuoteLineItem qliParam){
            this.scaleInd = false;
            //this.exceptRate = qliParam.UnitPrice;
            //setting proposed price instead of UNIT Price for QPI Quotes - Mentioned in requirements
            this.exceptRate = qliParam.Proposed_Price__c;
            if(qliParam.Unit_of_Measure__c != null) {
                SKP_Bill_Code_UOM__c uomSetting = SKP_Bill_Code_UOM__c.getInstance(qliParam.Unit_of_Measure__c);
                if(uomSetting != null){
                    this.UOM = uomSetting.SKP_UOM__c;
                }
            }
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
    
    //SKPContract.addDetails.contractDetails.contractSettings
    public class contractSettingsObj{
       public string serviceReviewDate;
       public string storageReviewDate;
       public string lastServiceIncrease;
       public string lastStorageIncrease;

        public contractSettingsObj(string nextYearDateString, string effectiveDateString){
            this.storageReviewDate = nextYearDateString;
            this.serviceReviewDate = nextYearDateString;
            this.lastServiceIncrease = effectiveDateString;
            this.lastStorageIncrease = effectiveDateString;
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

}