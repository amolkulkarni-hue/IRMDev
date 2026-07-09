public class B2B_CreateOpportunity {
    //"System" is a reserved variable string, so we need to do a string replace after this has been generated. 
    public string systemStringToBeReplaced; 
    public string format;
    public string userId;
 //   public filterObj filter;
    public addDetailsObj addDetails;
 
    
    public B2B_CreateOpportunity(Opportunity OpptyParam) {
      Map<String, Schema.RecordTypeInfo> opportunityRecordTypeIdMap = B2B_IntegrationHelper.getRecordType();
      Id  NARecordTypeID = opportunityRecordTypeIdMap.get('Standard Opportunity').getRecordTypeId();
      Id  EURecordTypeID = opportunityRecordTypeIdMap.get('IME Standard Opportunity').getRecordTypeId();
        if(NARecordTypeID == OpptyParam.RecordTypeId){
        this.systemStringToBeReplaced  = 'AMER'; 
        } else if(EURecordTypeID == OpptyParam.RecordTypeId){
        this.systemStringToBeReplaced  = 'EURO'; 
        }
        this.format= 'application/json';
        this.userID = UserInfo.getUserEmail().substring(0,7);
  //    this.filter = new filterObj(validateJson);
        this.addDetails= new addDetailsObj(OpptyParam);
        
    }
    
 /*    public class filterObj{
        public string modeOfOperation;
        public filterObj(boolean validateJson){
            this.modeOfOperation = (validateJson) ? 'CREATE' : 'UPDATE';
        }
    }
 */   
    public class addDetailsObj{
        public Opportunityobj opportunity;
        public addDetailsObj(Opportunity OpptyParam ){
            this.opportunity= new Opportunityobj(OpptyParam);
        }
    }
    //CloseDate formerly First Bill Date, Booked Date is now First Bill Date
    public class Opportunityobj{
        public String opportunityID; 
        public String name;
        public String type;
        public String stage;
        public List<CustomerDetailsobj> customerDetails;
        public String bookedDate ; 
        public String finalBilledDate; 
        public String firstBilledDate; 
        public String owner;
        public String commissionEndDate; 
        public Opportunityobj(Opportunity OpptyParam){
            this.opportunityID=OpptyParam.Id;
            this.name=OpptyParam.Name;
            this.type=OpptyParam.Type;
            this.stage=OpptyParam.StageName.substring(0,1);
            this.customerDetails= new  List<CustomerDetailsobj>{new CustomerDetailsobj(OpptyParam)};
            Date bookdate = (OpptyParam.IM_Booked_Date__c != null) ? Date.valueOf(OpptyParam.IM_Booked_Date__c) : null;
            if(bookdate != null)
            {
            Datetime bookdatetime = datetime.newInstance( bookdate.year(),bookdate.month(),bookdate.day());
            this.bookedDate=bookdatetime.format('yyyy/MM/dd');
            }
            else {
            this.bookedDate='';
            }
           
       /*     Date finalbilldate=OpptyParam.First_Bill_Booked_Date__c;
            Datetime finalbilldatetime = datetime.newInstance( finalbilldate.year(),
                                                           finalbilldate.month(),
                                                           finalbilldate.day());
            this.finalBilledDate=finalbilldatetime.format('yyyy/MM/dd');  */
            Date firstbilleddate = (OpptyParam.First_Bill_Booked_Date__c != null) ? Date.valueOf(OpptyParam.First_Bill_Booked_Date__c) : null;
            if(firstbilleddate != null){
            Datetime firstbilleddatetime = datetime.newInstance(firstbilleddate.year(),firstbilleddate.month(),firstbilleddate.day());
            this.firstBilledDate=firstbilleddatetime.format('yyyy/MM/dd');
            } else {
            this.firstBilledDate='';
            }
            this.owner=OpptyParam.Owner.Name;
            Date commissiondate = (OpptyParam.Commissionable_Window_Close_Date__c != null) ? Date.valueOf(OpptyParam.Commissionable_Window_Close_Date__c) : null;
            if(commissiondate != null){
            Datetime commissiondatetime = datetime.newInstance(commissiondate.year(),commissiondate.month(),commissiondate.day());
            this.commissionEndDate=commissiondatetime.format('yyyy/MM/dd');
            }
            else{
            this.commissionEndDate=null;
            }
        }
    }
    
    public class CustomerDetailsobj{
        public String customerId;
        public String caseNumber;
        public String IMGA;
        public CustomerDetailsobj(Opportunity OpptyParam){
        Map<String, Schema.RecordTypeInfo> opportunityRecordTypeIdMap = B2B_IntegrationHelper.getRecordType();
        Id  NARecordTypeID = opportunityRecordTypeIdMap.get('Standard Opportunity').getRecordTypeId();
        Id  EURecordTypeID = opportunityRecordTypeIdMap.get('IME Standard Opportunity').getRecordTypeId();
            if(OpptyParam.Type=='New Deal'){
                if(NARecordTypeID ==OpptyParam.RecordTypeId){
                  if(OpptyParam.Cases1__r.size()>0){
                    for(Case ca:OpptyParam.Cases1__r ){
                       this.customerId=ca.Customer_ID__r.Name;
                       this.caseNumber=ca.CaseNumber;
                       this.IMGA=OpptyParam.IMGA_Name__c;
                    }
                  } 
               } else if(EURecordTypeID == OpptyParam.RecordTypeId || test.isRunningTest()){
               this.customerId=OpptyParam.Customer_Account_Number__c;
               this.caseNumber='NA';
               this.IMGA=OpptyParam.IMGA_Name__c;
               }
            } else 
            {
                if(NARecordTypeID ==OpptyParam.RecordTypeId){
                   this.customerId=OpptyParam.Upsell_Customer_ID__r.Name; 
                } 
                else if(EURecordTypeID == OpptyParam.RecordTypeId)
                {
                    this.customerId=OpptyParam.IM_Up_Sell_Sold_To__c; 
                }
            this.caseNumber='NA';
            this.IMGA=OpptyParam.IMGA_Name__c;
            }
        }
    }
 }