/*
 * Case : 12101531 Adding District id for Customer Account Sync with SITAD 
 * 
 * Removed the fields (CDM_Global_Ultimate_ID__c,CDM_Global_Ultimate_Name__c) dependency as part of #16051
 * 
 */
public class CustAccountSITADJsonClass{
    public cls_account account;
    public CustAccountSITADJsonClass(case ca){
        this.account = new cls_account(ca);
    }
    public class cls_account{
        public string customerAccountId;
        public string customerAccountName;
        public string parentAccountId;
        public string parentAccountName;
        public string globalUltimateId;
        public string globalUltimateName;
        //Added for case :12101531
        public string districtId;
        public cls_accountAddress accountAddress;
        public cls_contact contact;
        public cls_account(case ca){
            this.customerAccountId = ca.Customer_ID__r.name;
            system.debug('customerAccountId =='+customerAccountId);
            this.customerAccountName = ca.Customer_Name__c;
            this.parentAccountId = ca.Account.Id;
            this.parentAccountName = ca.Account.Name;
            /* commented lines for #16051
            this.globalUltimateId = (ca.Account.CDM_Global_Ultimate_ID__c != null) ? ca.Account.CDM_Global_Ultimate_ID__c : '';
            this.globalUltimateName = (ca.Account.CDM_Global_Ultimate_Name__c != null) ? ca.Account.CDM_Global_Ultimate_Name__c : '';
            */
			//Added for case :12101531
            this.districtId = ca.IM_Market__c;
            this.accountAddress = new cls_accountAddress(ca);
            this.contact = new cls_contact(ca);
        }
     }
    public class cls_accountAddress{
        public cls_address address;
        public cls_accountAddress(Case caAddress){
            this.address = new cls_address(caAddress);
        }
    }
    public class cls_address{
        public string street;
        public string city;
        public string state;
        public string postalCode;
        public string country;
        public cls_address(case cas){
            this.street = cas.Address__c;
            this.city = cas.City__c;
            this.state = cas.State__c;
            this.postalCode = cas.Zip__c;
            this.country = cas.Country__c;
        }
    }
    public class cls_contact{
        public string name;
        public string phoneNumber;
        public string emailAddress;
        public cls_contact(Case caCon){
            this.name = (caCon.Case_Contact_Name__c != null) ? caCon.Case_Contact_Name__c : '';
            // Below fields are Read Only, Added only if the Contact is added to the case
            this.phoneNumber = caCon.Contact.Phone;
            this.emailAddress = caCon.Contact.Email;
        }
    }
}