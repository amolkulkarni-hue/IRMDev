public with sharing class SKPCustomerAffiliate {

    public enum availableAddressType {BILLING, CORRESPONDENCE, SHIPPING}
    //"System" is a reserved variable string, so we may need to do a string replace here. 
    public string systemStringToBeReplaced = 'AMER'; 
    
    public string userId;
    public filterObj filter;
    public sourceObj source;
    
    public addDetailsObj addDetails;
    
    
    public SKPCustomerAffiliate(String srcCustomerId,Case caseParam, Quote quoteParam, boolean validateJson, string username, SkpIntegrationHelper.CustomerIndicator indicatorParam){
        Customer_Profile__c profile = caseParam.Customer_Profile__r;
    
        Contact contact = caseParam.contact;
        System.debug('Inside SKPCustomer_Affiliate constructor with validate=='+validateJson);
        filter = new filterObj(validateJson);
        source = new sourceObj(srcCustomerId);
        addDetails = new addDetailsObj(profile, quoteParam, contact, indicatorParam);
        this.userId = UserInfo.getUserEmail().substring(0,7);
    }
    
    public class filterObj{
        string modeOfOperation;
        public filterObj(boolean validateJson){
            this.modeOfOperation = (validateJson) ? 'VALIDATE' : 'CREATE';
        }
    }
    
    public class sourceObj{
        string customerId;
        public sourceObj(string customerId){
            this.customerId = customerId;
        }
    }
    
    public class addDetailsObj{
        
        public customerDetailObj newCustomerDetail;
        public addDetailsObj(Customer_Profile__c profileParam, Quote quoteParam, Contact contactParam, SkpIntegrationHelper.CustomerIndicator indicatorParam){
            newCustomerDetail = new customerDetailObj(profileParam, quoteParam, contactParam, indicatorParam);
        }
    }
    public class customerDetailObj {
        public List<addressObj> address;
        public string customerName;
        public billingObj billing;
        public authorizedUserObj authorizedUser;
        
        public customerDetailObj(Customer_Profile__c profileParam, Quote quoteParam, Contact contactParam, SkpIntegrationHelper.CustomerIndicator indicatorParam){
            this.customerName = profileParam.Customer_Name__c;
            this.address = new List<addressObj>();
            this.address.add(new addressObj(availableAddressType.SHIPPING, profileParam, contactParam));
            this.address.add(new addressObj(availableAddressType.BILLING, profileParam, contactParam));
            this.address.add(new addressObj(availableAddressType.CORRESPONDENCE, profileParam, contactParam));
            this.billing = new billingObj(profileParam);
            this.authorizedUser = new authorizedUserObj(); 
        }
    }
   
    
    
    //addDetails.customerDetail.address
    public class addressObj{
        public string addressType;
        public string addressCode;
        public string customerName;
        public string address1;
        public string address2;
        public string address3;
        public string floor;
        public string city;
        public string state;
        public string country;
        public string zip;
        public string contactName;
        public string phoneNumber;
        public integer extensionNo;
        public integer faxNumber;
        public string email;
        
        public addressObj(availableAddressType addressTypeParam, Customer_Profile__c profileParam, Contact contactParam){
            if(addressTypeParam == availableAddressType.CORRESPONDENCE && (!profileParam.Same_as_Service_Address_cor__c) && (!profileParam.Same_as_Billing_Address__c)){
                this.addressType = 'CORRESPONDENCE';
                this.address1 = profileParam.Correspondence_Address__c;
                this.address2 = profileParam.Address_Line_2__c;
                this.city = profileParam.Correspondence_City__c;
                this.state = profileParam.Correspondence_State_Province__c;
                this.zip = profileParam.Correspondence_Zip_Postal_Code__c;
                this.country = SkpIntegrationHelper.cleanCountryCode(profileParam.Correspondence_Country__c);
                this.contactName = (profileParam.Correspondence_Contact__c != null) ? profileParam.Correspondence_Contact__r.name : '';
                this.phoneNumber = (profileParam.Correspondence_Contact__c != null && profileParam.Correspondence_Contact__r.phone != null) ? String.valueOf(profileParam.Correspondence_Contact__r.phone).replaceAll('\\D+', '') : '';
                this.email = (profileParam.Correspondence_Contact__c != null) ? profileParam.Correspondence_Contact__r.email: '';
                
            }
            else if((addressTypeParam == availableAddressType.BILLING && (!profileParam.Same_as_Service_Address__c))
                     || (addressTypeParam == availableAddressType.CORRESPONDENCE && profileParam.Same_as_Billing_Address__c)
            ){
                this.addressType = addressTypeParam.name();
                this.address1 = profileParam.Billing_Address__c;
                this.city = profileParam.Billing_City__c;
                this.state = profileParam.Billing_State_Province__c;
                this.zip = profileParam.Billing_Zip_Postal_Code__c;
                this.country = SkpIntegrationHelper.cleanCountryCode(profileParam.Billing_Country__c);
                this.contactName = (profileParam.Billing_Contact__c != null) ? profileParam.Billing_Contact__r.name : '';
                this.phoneNumber = (profileParam.Billing_Contact__c != null && profileParam.Billing_Contact__r.phone != null) ? String.valueOf(profileParam.Billing_Contact__r.phone).replaceAll('\\D+', '') : '';
                this.email = (profileParam.Billing_Contact__r != null) ? profileParam.Billing_Contact__r.email: '';
            }
            else {
                this.addressType = addressTypeParam.name();
                this.address1 = profileParam.Address__c;
                this.address2 = profileParam.Address_Line_2__c;
                this.city = profileParam.City__c;
                this.state = profileParam.state_province__c;
                this.zip = profileParam.Zip_Postal_Code__c;
                this.country = SkpIntegrationHelper.cleanCountryCode(profileParam.country__c);
                
                
                this.contactName = (profileParam.Primary_Service_Contact__c != null) ? profileParam.Primary_Service_Contact__r.name : '';
                this.phoneNumber = (profileParam.Primary_Service_Contact__c != null && profileParam.Primary_Service_Contact__r.phone != null ) ? String.valueOf(profileParam.Primary_Service_Contact__r.phone).replaceAll('\\D+', '') : '';
                this.email = (profileParam.Primary_Service_Contact__c != null) ? profileParam.Primary_Service_Contact__r.email: '';
            }
            this.customerName = profileParam.customer_name__c;
        }
        
    }
    
    //addDetails.customerDetail.billing
    public class billingObj{
        public List<deliveryTypeObj> deliveryTypes;
        public integer remittanceLevel=0;        
        public billingObj(Customer_Profile__c profileParam){
            String email = '';
            String deliveryTypeId= 'PRT';

            if(profileParam.Invoice_Delivery_Method__c != null){
                if(profileParam.Remittance_Level__c != null)
                {   
                    String remitLevel = profileParam.Remittance_Level__c.substring(0, 1);
                	this.remittanceLevel = (remitLevel.isNumeric()) ? Integer.valueOf(remitLevel) : 0 ;
                }
                deliveryTypeId = profileParam.Invoice_Delivery_Method__c.toLowerCase().contains('email') ? 'EML' : 'PRT' ;
            }
          
          
          if(profileParam.Primary_Service_Contact__r != null || profileParam.Billing_Contact__r != null){
              email = (profileParam.Same_as_Service_Address__c && profileParam.Primary_Service_Contact__r != null && profileParam.Primary_Service_Contact__r.email != null) 
                      ? profileParam.Primary_Service_Contact__r.email
                      : profileParam.Billing_Contact__r.email ;
          }
          
          this.deliveryTypes = new List<deliveryTypeObj>{new deliveryTypeObj(deliveryTypeID, email)};
        }
    }
    
    //addDetails.customerDetail.billing.deliveryTypeObj
    public class deliveryTypeObj{
       string deliveryTypeId;
       List<string> email;
       public deliveryTypeObj(string deliveryTypeIdParam, string emailParam ){
           this.deliveryTypeId = deliveryTypeIdParam;
           this.email = new List<String>{emailParam};
       }
    }
    
    //addDetails.customerDetail.authorizedUser
    public class authorizedUserObj{
        public string authorizedUser;
        public string authorizedName;
        public string title;
        public string password;
        public string phoneNumber;
        
        public authorizedUserObj(){
            this.authorizedUser = '*****';
            this.authorizedName ='***STRICT AUTHORIZATION***';
        }
    }
    
}