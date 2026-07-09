public class SKPUpdateRecurringCharges {
	public string systemStringToBeReplaced = 'AMER'; 
	public String format;
	public String companyId;
	public String userId;
	public UpdateDetailsObj updateDetails;    
    
     public SKPUpdateRecurringCharges(Case caseParam,Quote quoteParam,Map<String, SKPRecurringChargesDetails__c> recurringChargesDetailsMap,Set<String> custIdSet,List<QuoteLineItem> qlis,Set<String> skpOnlyWrapper){
        this.userID = UserInfo.getUserEmail().substring(0,7);         
        this.updateDetails = new UpdateDetailsObj(caseParam,quoteParam,recurringChargesDetailsMap,custIdSet,qlis,skpOnlyWrapper);
    }

	public class UpdateDetailsObj {
		public recurringChargeDetailsObj recurringChargeDetails;        
        public UpdateDetailsObj(Case caseParam,Quote quoteParam,Map<String, SKPRecurringChargesDetails__c> recurringChargesDetailsMap,Set<String> custIdSet,List<QuoteLineItem> qlis,Set<String> skpOnlyWrapper){
            this.recurringChargeDetails = new recurringChargeDetailsObj(caseParam,quoteParam,recurringChargesDetailsMap,custIdSet,qlis,skpOnlyWrapper); 
        }        
	}     
    
	public class recurringChargeDetailsObj {
		public List<ownersObj> owners;
		public List<RecurringChargesObj> recurringCharges;
        public recurringChargeDetailsObj(Case caseParam,Quote quoteParam,Map<String, SKPRecurringChargesDetails__c> recurringChargesDetailsMap,Set<String> custIdSet,List<QuoteLineItem> qlis,Set<String> skpOnlyWrapper){

        Date nullcheckedEffectiveDate = (caseParam.Contract_Effective_Date__c != null) ? Date.valueOf(caseParam.Contract_Effective_Date__c) : null;
        Date maxEffectiveDate = SkpIntegrationHelper.maxDate( nullcheckedEffectiveDate, quoteParam.Effective_Date__c); 
        
        Datetime contractEffectiveDate = datetime.newInstance( maxEffectiveDate.year(),
                                                              maxEffectiveDate.month(),
                                                              maxEffectiveDate.day());
        Datetime effectiveDate = datetime.newInstance( maxEffectiveDate.year(),
                                                      maxEffectiveDate.month(),
                                                      1);
        
        
        string effectiveDateString = effectiveDate.format('yyyy/MM/dd');
        string nextQuarterDateString = effectiveDate.addMonths(3).format('yyyy/MM/dd','GMT-04:00');            
        string nextYearDateString = SkpIntegrationHelper.getNextYearDateString(maxEffectiveDate);   
   		Set<String> billCodes = Pluck.strings('Product_Name__c', quoteParam.QuoteLineItems);
            Set<String> initBillCodes = new Set<String>();
            
            for (String billCode : billCodes){
                string standardBillCode = SkpIntegrationHelper.cleanBillCode(billcode);
                
                if(SkpIntegrationHelper.isInitBillCode(billCode)){
                    initBillCodes.add(standardBillCode);
                }
            }

            
            this.owners = new List<ownersObj>();  
            this.recurringCharges = new List<RecurringChargesObj>();
                
            for(String custId:custIdSet){
               owners.add(new ownersObj(custId)) ;
            }
            if((skpOnlyWrapper != null && skpOnlyWrapper.size() > 0)
               || (qlis != null && qlis.size() > 0)){  
                for(String rcdw:skpOnlyWrapper){
                   recurringCharges.add(new RecurringChargesObj(caseParam,rcdw)) ;
                }  
                
                for(QuoteLineItem qli:qlis){
                       recurringCharges.add(new RecurringChargesObj(caseParam,recurringChargesDetailsMap,qli,effectiveDateString,nextQuarterDateString,initBillCodes)) ;
                }                   
            } 
        }        
	}

 
    
	public class RecurringChargesObj {
		public String districtId;
		public String billCode;
		public String startDate;
		public String endDate='TOBEREMOVED';
		public String billingCycle;
		public String quantity;
		public String rate;
		public String uom='EA';
        public RecurringChargesObj(Case caseParam,Map<String, SKPRecurringChargesDetails__c> recurringChargesDetailsMap,QuoteLineItem qli,String effectiveDateParam, string nextQuarterDateParam,Set<String> initBillCodesParam){
            this.districtId = '';
            this.billCode = recurringChargesDetailsMap.get(qli.Product_Name__c).BillCode__c;
            this.rate = String.valueOf(qli.UnitPrice);
            this.quantity = String.valueOf(qli.quantity);
            
            if(caseParam.recordType.Name != null && caseParam.recordType.Name.equals('NCSP Renewal')){
                this.startDate = 'TOBEREMOVED';
            }else{
                 if(initBillCodesParam.contains(qli.Product_Name__c) && (!SkpIntegrationHelper.isInitBillCode(qli.Product_Name__c))){
                    this.startDate = nextQuarterDateParam;
                } else {
                    this.startDate = effectiveDateParam;
                }
            }
            
            if(qli.Unit_of_Measure__c != null) {
                SKP_Bill_Code_UOM__c uomSetting = SKP_Bill_Code_UOM__c.getInstance(qli.Unit_of_Measure__c);
                if(uomSetting != null){
                    this.uom = uomSetting.SKP_UOM__c;
                }else if(qli.Product_Name__c != null 
                         && (qli.Product_Name__c.toLowerCase().contains('val') 
                             || qli.Product_Name__c.toLowerCase().contains('easy')) ){
                    this.uom = 'EA';
                }
            }  
        }   
        
        public RecurringChargesObj(Case caseParam,String rcdw){
	            this.startDate = 'RECCTOBEREMOVED';
                this.districtId = 'RECCTOBEREMOVED';
            	this.billingCycle = 'RECCTOBEREMOVED';
                this.quantity = 'RECCTOBEREMOVED';
            	this.rate = 'RECCTOBEREMOVED';
                this.uom = 'RECCTOBEREMOVED';
            	this.billCode = rcdw;
    	        this.endDate = '';
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