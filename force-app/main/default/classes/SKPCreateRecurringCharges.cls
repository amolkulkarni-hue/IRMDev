public class SKPCreateRecurringCharges {
	public string systemStringToBeReplaced = 'AMER'; 
	public String format;
	public String companyId;
	public String userId;
	public AddDetails addDetails;    
    
     public SKPCreateRecurringCharges(Case caseParam, Quote quoteParam,Map<String, SKPRecurringChargesDetails__c> recurringChargesDetailsMap,Set<String> custIdSet,List<QuoteLineItem> qlis){
        this.userID = UserInfo.getUserEmail().substring(0,7);         
        this.addDetails = new AddDetails(caseParam,quoteParam,recurringChargesDetailsMap,custIdSet,qlis);
    } 
    
	public class AddDetails {
        public RecurringChargeDetails recurringChargeDetails;
        public AddDetails(Case caseParam,Quote quoteParam,Map<String, SKPRecurringChargesDetails__c> recurringChargesDetailsMap,Set<String> custIdSet,List<QuoteLineItem> qlis){
            recurringChargeDetails = new RecurringChargeDetails(caseParam,quoteParam,recurringChargesDetailsMap,custIdSet,qlis);
        }

	}    
    
    public class RecurringChargeDetails {
		public List<ownersObj> owners;
		public List<RecurringChargesObj> recurringCharges;

        public RecurringChargeDetails(Case caseParam,Quote quoteParam,Map<String, SKPRecurringChargesDetails__c> recurringChargesDetailsMap,Set<String> custIdSet,List<QuoteLineItem> qlis){
      	Date nullcheckedEffectiveDate = (caseParam.Contract_Effective_Date__c != null) ? Date.valueOf(caseParam.Contract_Effective_Date__c) : null;
        Date maxEffectiveDate = SkpIntegrationHelper.maxDate( nullcheckedEffectiveDate, quoteParam.Effective_Date__c); 
        string effectiveDateString;
        Datetime contractEffectiveDate = datetime.newInstance( maxEffectiveDate.year(),
                                                              maxEffectiveDate.month(),
                                                              maxEffectiveDate.day());
        Datetime effectiveDate = datetime.newInstance( maxEffectiveDate.year(),
                                                      maxEffectiveDate.month(),
                                                      1);
        
        if(maxEffectiveDate != null && maxEffectiveDate.day()== 1){
            effectiveDateString =   effectiveDate.addMonths(1).format('yyyy/MM/dd','GMT-04:00');
        }else{
            effectiveDateString =   effectiveDate.addMonths(2).format('yyyy/MM/dd','GMT-04:00');
        }
            
        if(caseParam.recordType.Name != null && caseParam.recordType.Name.equals('NCSP Renewal')){
            effectiveDateString = effectiveDate.format('yyyy/MM/dd','GMT-04:00');
         }    
        //string effectiveDateString = effectiveDate.format('yyyy/MM/dd');
        string nextQuarterDateString = effectiveDate.addMonths(3).format('yyyy/MM/dd','GMT-04:00');            
       // string nextYearDateString = SkpIntegrationHelper.getNextYearDateString(maxEffectiveDate);   
            
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
            System.debug('Create Recurring - CustIdList=='+custIdSet);    
            for(String custId:custIdSet){
               owners.add(new ownersObj(custId)) ;
            }
                
            for(QuoteLineItem qli:qlis){
               recurringCharges.add(new RecurringChargesObj(caseParam,recurringChargesDetailsMap,qli,effectiveDateString,nextQuarterDateString,initBillCodes)) ;
            }            
        }
	}

	public class RecurringChargesObj {

		public String districtId;
		public String billCode;
		public String startDate;
		public String endDate;
		public String billingCycle;
		public String quantity;
		public String rate;
		public String uom='EA';
        
        public RecurringChargesObj(Case caseParam,Map<String, SKPRecurringChargesDetails__c> recurringChargesDetailsMap,QuoteLineItem qli,String effectiveDateParam, string nextQuarterDateParam,Set<String> initBillCodesParam){
            /*if(caseParam.recordType.Name != null && caseParam.recordType.Name.equals('NCSP Renewal')){
                this.startDate = 'TOBEREMOVED';
            }else{*/
                //if(initBillCodesParam.contains(qli.Product_Name__c) && (!SkpIntegrationHelper.isInitBillCode(qli.Product_Name__c))){
                //    this.startDate = nextQuarterDateParam;
                //} else {
                if(effectiveDateParam != null)
                    this.startDate = effectiveDateParam.replaceAll('-','/');
                //}
           // }
            
            this.districtId = '';
            this.billCode = recurringChargesDetailsMap.get(qli.Product_Name__c).BillCode__c;            
            this.rate = String.valueOf(qli.UnitPrice);
            this.quantity = String.valueOf(qli.quantity);
            
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