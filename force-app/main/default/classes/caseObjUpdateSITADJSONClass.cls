public class caseObjUpdateSITADJSONClass{
    public cls_account account;
    public caseObjUpdateSITADJSONClass(Case Cas){
        this.account = new cls_account(Cas);
    }
    public class cls_account{
        public string customerAccountID;
        public string customerAccountName;
        //public string salesType;
        public string caseNumber;
        //public string serviceOrderDate;
        public string serviceScheduleDate;
        public string serviceCompletionDate;
        public string districtId;
        public string marketName;
        public string salesRep;
        public cls_serviceAddress serviceAddress;
        public cls_serviceContact serviceContact;
        //public List<dispositionObj> dispositionType;
        public cls_account(Case Cas){
            //this.customerAccountID = Cas.Customer_ID__c;
            this.customerAccountId = Cas.Customer_ID__r.name;
            this.customerAccountName = Cas.Customer_Name__c;
            this.caseNumber = Cas.CaseNumber;
            this.serviceScheduleDate = string.ValueOf(Cas.Service_Schedule_Date__c);
            this.serviceCompletionDate = string.ValueOf(Cas.Service_Completion_Date__c);
            this.districtId = Cas.IM_Market__c;
            this.marketName = Cas.Market_Name__c;
            this.salesRep = Cas.Owner.name;//'Ed Fabian';
            this.serviceAddress = new cls_serviceAddress(Cas);
            this.serviceContact = new cls_serviceContact(Cas);
        }
    }
    public class cls_serviceAddress{
        public cls_address address;
        public cls_serviceAddress(Case Ca){
            this.address = new cls_address(Ca);
        }
    }
    public class cls_address{
        public string street;
        public string city;
        public string state;
        public string postalCode;
        public string country;
        public cls_address(Case Cas){
            this.street = cas.Address__c;
            this.city = cas.City__c;
            this.state = cas.State__c;
            this.postalCode = cas.Zip__c;
            this.country = cas.Country__c;
        }
    }
    public class cls_serviceContact{
        public string name;
        public string phoneNumber;
        public string emailAddress;
        public cls_serviceContact(Case caCon){
            this.name = caCon.Owner.Name;
            this.phoneNumber = caCon.Owner.Phone;
            this.emailAddress = caCon.Owner.Email;
        }
    }
}