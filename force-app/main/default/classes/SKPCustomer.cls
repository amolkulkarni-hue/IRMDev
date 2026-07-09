public with sharing class SKPCustomer {

    public enum availableAddressType {BILLING, CORRESPONDENCE, SHIPPING}
    //"System" is a reserved variable string, so we may need to do a string replace here. 
    public string systemStringToBeReplaced = 'AMER'; 
    
    public string userId;
    public filterObj filter;
    
    public addDetailsObj addDetails;
    
    public SKPCustomer(Case caseParam, Quote quoteParam, boolean validateJson, string username, SkpIntegrationHelper.CustomerIndicator indicatorParam){
        Customer_Profile__c profile = caseParam.Customer_Profile__r;
        String shredType;
            if(caseParam.NCSP_Service_line__c == 'One Time Shred')
        		shredType = 'ON-CALL';
        	else if(caseParam.NCSP_Service_line__c == 'Shred') 
                shredType = 'SCHEDULED';
        	else 
                shredType = '';
        
        String defOrderType;
        if(caseParam.NCSP_Service_line__c == 'One Time Shred' || caseParam.NCSP_Service_line__c == 'Shred')
            defOrderType = 'D';
        else
            defOrderType = '1';
        
        Contact contact = caseParam.contact;
        filter = new filterObj(validateJson);
        addDetails = new addDetailsObj(profile, quoteParam, contact, indicatorParam,shredType,defOrderType);
        this.userId = UserInfo.getUserEmail().substring(0,7);
    }
    
    public class filterObj{
        string modeOfOperation;
        public filterObj(boolean validateJson){
            this.modeOfOperation = (validateJson) ? 'VALIDATE' : 'CREATE';
        }
    }
    
    public class addDetailsObj{
        
        public customerDetailObj customerDetail;
        public addDetailsObj(Customer_Profile__c profileParam, Quote quoteParam, Contact contactParam, SkpIntegrationHelper.CustomerIndicator indicatorParam,String shredType, string defOrderType){
            customerDetail = new customerDetailObj(profileParam, quoteParam, contactParam, indicatorParam,shredType,defOrderType);
        }
    }
    public class customerDetailObj {
        public List<addressObj> address;
        public string customerId;
        public string customerName;
        public creditDetailObj creditDetail;
        public serviceTypesObj serviceTypes;
        public billingObj billing;
        public customerSettingsObj customerSettings;
        public departmentDetailsObj departmentDetails;
        public authorizedUserObj authorizedUser;
        
        public customerDetailObj(Customer_Profile__c profileParam, Quote quoteParam, Contact contactParam, SkpIntegrationHelper.CustomerIndicator indicatorParam,String shredType, string defOrderType){
            this.customerName = profileParam.Customer_Name__c;
            this.address = new List<addressObj>();
            this.address.add(new addressObj(availableAddressType.SHIPPING, profileParam, contactParam));
            this.address.add(new addressObj(availableAddressType.BILLING, profileParam, contactParam));
            this.address.add(new addressObj(availableAddressType.CORRESPONDENCE, profileParam, contactParam));
            
            this.customerName = profileParam.Customer_Name__c;
            this.billing = new billingObj(profileParam);
            this.customerSettings = new customerSettingsObj(profileParam);
            this.serviceTypes = new serviceTypesObj(profileParam, indicatorParam,shredType);
            
            this.departmentDetails = new departmentDetailsObj(profileParam,defOrderType);
            this.authorizedUser = new authorizedUserObj(); 
            this.creditDetail = new creditDetailObj();
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
    
    
    
    //addDetails.customerDetail.creditDetail
    public class creditDetailObj{
        public integer creditLimit;
        public String creditReviewDate;
        
        public creditDetailObj(){
            creditLimit = 0;
            Date todayDate = Date.today();
            creditReviewDate = todayDate.year() + '/' + todayDate.month() + '/' + todayDate.day(); 
        }
    }
    
    //addDetails.customerDetail.serviceTypes
    public class serviceTypesObj{
        public recordsManagementObj recordsManagement;
        public shreddingObj shredding;
        public String shreddingType;
        
        public serviceTypesObj(Customer_Profile__c profileParam, SkpIntegrationHelper.CustomerIndicator indicatorParam,String shredType){
            recordsManagement = new recordsManagementObj(profileParam, indicatorParam);
            
            boolean shreddingFlag = false;
            if(indicatorParam != null){ 
                shreddingFlag = indicatorParam.shred;
            }
            
            //System.assert(False, indicatorParam);
           	if(shreddingFlag)
            	this.shredding = new shreddingObj(shreddingFlag,shredType);
        }
    }
    
    // addDetails.customerDetail.serviceTypes.recordsManagement
    public class recordsManagementObj{
        public boolean activateHardCopy;
        public string destructionMethod;
        public string chargeBack;
        public string transmittalUsage;        
        public openShelfObj openShelf;
        public imagingObj imaging;
        public boolean faxtrieval;
        public boolean xRay;
        
        public boolean smartPurge;
        public boolean billToRequester;
        public boolean lockedLocation;
        public boolean containerBilling;
        public boolean vault;
        public boolean efsService;
        
        public recordsManagementObj(Customer_Profile__c profileParam, SkpIntegrationHelper.CustomerIndicator indicatorParam){
            boolean imaging = false;
            boolean openShelf = false;
            this.activateHardCopy = false;
            this.efsService = false;
            this.vault = false;
            this.faxtrieval = false;
            
            if(indicatorParam != null){
                this.activateHardCopy = indicatorParam.hardcopy;
                imaging = indicatorParam.iod;
                openShelf =  indicatorParam.openshelf;
                this.efsService = indicatorParam.efs;
                this.vault = indicatorParam.vault;
                this.faxtrieval =  indicatorParam.faxtrieval;
            }
            
            this.containerBilling = false;
           
            this.destructionMethod ='SHRED';
            this.openShelf = new openShelfObj(openShelf);
            this.imaging = new imagingObj(imaging);
            this.chargeBack = '2'; 
            
        }
    }
    
    // addDetails.customerDetail.serviceTypes.recordsManagement.openShelf
    public class openShelfObj{
        public boolean activated;
        public boolean pullForward;
        public string printType;
        
        public openShelfObj(boolean activated){
            this.activated = activated; 
            this.pullForward = true;
            this.printType = 'Labels';
        }
    }
    // addDetails.customerDetail.serviceTypes.recordsManagement.imaging
    public class imagingObj{
        public boolean activated;
        public imagingObj(boolean activatedParam){ 
            this.activated = activatedParam;
        }
    }
    
    
    //addDetails.customerDetail.serviceTypes.shredding
    public class shreddingObj{
        public boolean activateShredding;
        public string shreddingType;
        public shreddingObj(boolean shredParam,String shredType){
            this.activateShredding = shredParam;
            this.shreddingType = shredType;
        }
    }
    
    
    //addDetails.customerDetail.billing
    public class billingObj{
        public Integer deptBillCode;
        public boolean deptRequired;
        public integer remittanceLevel = 0;
        public List<deliveryTypeObj> deliveryTypes;
        
        public billingObj(Customer_Profile__c profileParam){
            String email = '';
            String deliveryTypeId= 'PRT';
            
            if(profileParam.Department_Billing_Code__c != null){
                String billCode = profileParam.Department_Billing_Code__c.substring(0, 1);
                this.deptBillCode = (billCode.isNumeric()) ? Integer.valueOf(billCode) : 0 ;
            }
            
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
          
          Set<Integer> deptRequiredCodes = new Set<Integer>{2, 4, 8};
          this.deptRequired = (deptRequiredCodes.contains(this.deptBillCode));
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
    
    //addDetails.customerDetail.customerSettings
    public class customerSettingsObj{
        public string businessType;
        public string dunAndBrad;
        
        public customerSettingsObj(Customer_Profile__c profileParam){
            this.businessType = (profileParam.HealthcareAccountStoringPatientRecords__c != null && profileParam.HealthcareAccountStoringPatientRecords__c =='Yes') ? '800' : 'XXX' ;
        }
    }
    
    //addDetails.customerDetail.departmentDetails
    public class departmentDetailsObj{
       // boolean businessType;
       public string individualListCode;
       public string instructions;
       public string specialFileFormat;
       public string requestRestrictionIndicator;
       public string orderType;
       public string electronicInvoiceCode;
       public string stateTaxCode;
       public string countyTaxCode;
       public string primaryRequestType= 'BOX_ONLY';
        
        public departmentDetailsObj(Customer_Profile__c profileParam, string defOrderType){
            this.individualListCode = 'NOT INDIVIDUALLY LISTED'; 
            
            this.specialFileFormat = 'Box';
            this.requestRestrictionIndicator = 'E';
            
            this.electronicInvoiceCode = 'NONE';
            
            this.specialFileFormat = 'BOX';
            this.orderType = defOrderType;
            this.stateTaxCode ='ARIZONA';
            this.countyTaxCode= '';
            
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