public with sharing class SKPIntegrationHelper {
    public static final string INIT = 'INIT';
    public static final string ACCEPTED = 'Accepted';
    public static final string PRODUCTION = 'Production';
    
    public static final string HARDCOPY_NAME = 'Hardcopy';

    public static final string OPENSHELF_NAME = 'Open Shelf';
    public static final string FAXTRIEVAL_NAME  = 'Faxtrieval';
    public static final string EFS_NAME = 'EFS';
    public static final string VAULT_NAME = 'Vault';
    public static final string SHRED_NAME = 'Shred';
    public static final string XOD_NAME = 'XOD';
    public static final string IOD_NAME = 'IOD';
    
    public static final string SHRED_ONLY = 'SHRED ONLY';
    public static final string BUNDLED_PROGRAM = 'BUNDLED PROGRAM ACCOUNT';
    public static final string REPLACEMENT_VALUE = 'REPLACEMENT VALUE';
    public static final string APPLY_TO_MASTER = 'Apply to Master Div&Dept';
    public static final string MINIMUM_STORAGE_ACCOUNT = 'MINIMUM STORAGE ACCOUNT';
    public static final string DMS_SERVICE_ONLY = 'DMS SERVICE ONLY';
    
    public static Set<String> rmAdminContractVersions = new Set<String>{'IM5000LLC13', 'IM5000'};
    public static Set<Integer> shredAndSalesCode = new Set<Integer>{890,2476};
    
    public static Map<String, SKP_Customer_Indicator_Ranges__c> indicatorRanges {
        get{
           if(indicatorRanges == null){
               indicatorRanges = SKP_Customer_Indicator_Ranges__c.getAll();
           }
           return indicatorRanges;
           
        } set;
    }
    
    public static Map<String, SKPRecurringChargesDetails__c> recurringChargesDetails {
        get{
           if(recurringChargesDetails == null){
               recurringChargesDetails = SKPRecurringChargesDetails__c.getAll();
           }
           return recurringChargesDetails;
           
        } set;
    }    
    
    public static void insertObjects(List<Sobject> objectsToUpsert){
        try{
            insert objectsToUpsert;
        } catch (dmlexception e){
            ApexPages.addMessages(e);
        }
    }
    
    public static void upsertObjects(List<Sobject> objectsToUpsert){
        try{
            update objectsToUpsert;
        } catch (dmlexception e){
            ApexPages.addMessages(e);
        }
    }

    public static List<Case> getCases(String idParam){
        return [select id,
                   Contract_Type__c,
                   NCSP_Service_line__c,
                   Contract_Effective_Date__c,
                   NCSP_Opportunity__c,
                   Country__c,
                   NCSP_Opportunity__r.TotalOpportunityQuantity,
                   AccountId,
                   SKP_Customer_Sync_Date__c,
                   SKP_Contract_Sync_Date__c,
                   Source_Customer_Id__c,
                   Exception_Rate_Id__c,
                   Sync_succeeded_till__c,
                   Customer_ID__r.name,
                   Customer_ID__r.IM_District_Branch_Id__c,
                   Customer_ID__c,
                   Customer_ID__r.IM_Customer_Account_Name__c,
                
                   Contact.name,
                
                   Customer_Profile__r.Same_as_Service_Address__c,
                   Customer_Profile__r.Same_as_Service_Address_cor__c,
                   Customer_Profile__r.Same_as_Billing_Address__c,
                   Customer_Profile__r.Customer_Name__c,
                   Customer_Profile__r.Correspondence_Address__c,
                   Customer_Profile__r.Correspondence_City__c,
                   Customer_Profile__r.Correspondence_State_Province__c,
                   Customer_Profile__r.Correspondence_Zip_Postal_Code__c,
                   Customer_Profile__r.Correspondence_Country__c,
                   Customer_Profile__r.Correspondence_Contact__c,
                   Customer_Profile__r.Correspondence_Contact__r.name,
                   Customer_Profile__r.Correspondence_Contact__r.phone,
                   Customer_Profile__r.Correspondence_Contact__r.email,
                   
                   Customer_Profile__r.Address__c,
                   Customer_Profile__r.Address_Line_2__c,
                   Customer_Profile__r.City__c,
                   Customer_Profile__r.state_province__c,
                   Customer_Profile__r.Zip_Postal_Code__c,
                   Customer_Profile__r.country__c,
                   Customer_Profile__r.Primary_Service_Contact__r.name,
                   Customer_Profile__r.Primary_Service_Contact__r.phone,
                   Customer_Profile__r.Primary_Service_Contact__r.email,
                   
                   Customer_Profile__r.Billing_Address__c,
                   Customer_Profile__r.Billing_City__c,
                   Customer_Profile__r.Billing_Zip_Postal_Code__c,
                   Customer_Profile__r.Billing_State_Province__c,
                   Customer_Profile__r.Billing_Country__c,
                   Customer_Profile__r.Billing_Contact__c,
                   Customer_Profile__r.Billing_Contact__r.name,
                   Customer_Profile__r.Billing_Contact__r.phone,
                   Customer_Profile__r.Billing_Contact__r.email,
                   
                   Customer_Profile__r.Department_Billing_Code__c,
                   Customer_Profile__r.Department_Restricted__c,
                   Customer_Profile__r.Remittance_Level__c,
                   Customer_Profile__r.Invoice_Delivery_Method__c,
                   Customer_Profile__r.Record_Code_Parameter__c,
                   Customer_Profile__r.HealthcareAccountStoringPatientRecords__c,
                   Customer_Profile__r.Sales_Rep_ID__c,
                   Customer_Profile__r.Individually_List_Files__c,
                   Customer_Profile__r.Sales_Rep_Percent_from_Opportunity__c,
                   Customer_Profile__r.Split_Rep_Percent_from_Opportunity__c,
                   Customer_Profile__r.Selling_District__r.Owning_District_Id__c,
                   contact.phone, contact.email, contact.firstname, contact.lastname,
                   NCSP_Service_Line_SKP_Mapping__c,
                   RecordType.Name,
                   Setup_Type__c,
                   Shred_Service_Method__c
                from Case where ID =:idParam limit 1];
    }
   
    public static List<SKP_Contract_Type_Mapping__c> getMappings (string version){
        return [Select id, District_Rate_Schedule__c, Effective_Date__c, RM_Admin_Fee__c,
                           Excess_Value_of_Deposit__c, Fuel_Surcharge_Indicator__c, Increase_Cap_Quoted__c,
                           Indemnification_Customer__c, Indemnification_Iron_Mountain__c, Initial_Term__c,
                           Insurance_Special__c, Late_Fee_Percent__c, Late_Fee_Indicator__c,
                           LOL_UOM__c, Net_Payment__c, Next_Increase_Date_Storage_and_Service__c,
                           Non_Standard_Version__c, Rate_Increase_Notice__c, Renewal_term__c,UOM__c
                       FROM SKP_Contract_Type_Mapping__c where Contract_Version__c =: version limit 1];
    }
    
    public static HttpRequest buildRequest(String endpoint, string authorizationHeader, string jsonString){
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        
        if(endpoint.contains('get') || endpoint.contains('Get')){
            request.setMethod('GET');
        }else{    
            request.setMethod('POST');
        }   
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', authorizationHeader);
        request.setBody(jsonString);
        request.setTimeout(100*1000);
        return request;
    }
    
    
    public static List<Quote> getScheduleAs(String opportunityId, List<String> fieldsToQuery){
        string soqlString = 'Select ' +  String.join(fieldsToQuery, ',') +
                            ', (Select Bill_Code_Classification__c, Unit_of_Measure__c, UnitPrice,Quantity, Product_Number__c, Product_Name__c,Product_Code__c,Base_Quantity__c,Base_Amount__c,Unit_Quantity__c,Unit_Rate__c,Category_Abbreviation__c,Proposed_Price_Year_1__c,Proposed_Price_Year_2__c,Proposed_Price_Year_3__c,Proposed_Price_Year_4__c,Proposed_Price_Year_5__c,Proposed_Price_Year_6__c,Proposed_Price_Year_7__c,Proposed_Price_Year_8__c,Proposed_Price_Year_9__c,Proposed_Price_Year_10__c From QuoteLineItems)' +
                            ' from Quote where OpportunityId =\'' +  String.escapeSingleQuotes(opportunityId) + '\'';
        return Database.query(soqlString);
    }
    
    public static boolean isInitBillCode(string billCode){
        return (billCode != null && billCode.contains(INIT));
    }
    
    public static string cleanBillCode(String billcode){
        string billCodeToReturn = billCode;
        if(billCodeToReturn != null){
            if(isInitBillCode(billCodeToReturn)){
                billCodeToReturn = billCodeToReturn.replace(INIT, '');
            }
        }
        return billCodeToReturn;
    }
    
    public static Integer getNumericBillCode(string billcode){
        string strippedBillCode = (billcode!= null) ? billcode.replaceAll('[^0-9]', '') : '';
        return (strippedBillCode.isnumeric()) ? Integer.valueOf(strippedBillCode) : 0 ;
        
    }
    
    public static boolean billCodeInRange(Integer billcode, Integer max, Integer min){
        return (billCode != null && billCode >= min && billCode <= max);
    }
    
    public static Date maxDate(date date1, date date2){
        if (date1 == null && date2 != null) {
            return date2;
        } else if (date1 != null && date2 == null){
            return date1;
        } else if (date1 == null && date2 == null){
            return Date.today();
        } else {
            return (date1 > date2) ? date1 : date2  ; 
        }
    }
    
    
    
    
    public class CustomerIndicator{
        
        public boolean hardCopy = false;
        public boolean openShelf = false;
        public boolean faxtrieval = false;
        public boolean efs = false;
        public boolean vault = false;
        public boolean shred = false;
        public boolean xod = false;
        public boolean iod = false;
        public boolean rmAdminFee = false;
        public string reasonCode = SHRED_ONLY ;
        public boolean bundledIndicator = false;
        public string recurringBillCode = '';
        public string recurringRate = '';
        public boolean recurringChargesExists = false;  
        public boolean shredAndServiceBoth = false;
        
        public CustomerIndicator(List<QuoteLineItem> qlis, String contractVersion){
            
            Set<Integer> productCodes = new set<Integer>(); 
            boolean valProductCodeExists = false;
            
            boolean series5000BillCode = false;
            boolean series1800BillCode = false;   
            boolean series2000BillCode = false;
            
            for(QuoteLineItem qli : qlis){
                Integer numericBillCode = getNumericBillCode(qli.Product_Name__c);
                for (SKP_Customer_Indicator_Ranges__c ranges : indicatorRanges.values()){
                    Integer maxCode = Integer.valueOf(ranges.Bill_Code_Maximum__c);
                    Integer minCode = Integer.valueOf(ranges.Bill_Code_Minimum__c);
                    
                    hardCopy = hardCopy || (ranges.Customer_Indicator__c == HARDCOPY_NAME && billCodeInRange(numericBillCode, maxCode, minCode));
                    openShelf = openShelf || (ranges.Customer_Indicator__c == OPENSHELF_NAME && billCodeInRange(numericBillCode, maxCode, minCode));
                    faxtrieval = faxtrieval || (ranges.Customer_Indicator__c == FAXTRIEVAL_NAME && billCodeInRange(numericBillCode, maxCode, minCode));
                    efs = efs || (ranges.Customer_Indicator__c == EFS_NAME && billCodeInRange(numericBillCode, maxCode, minCode));
                    vault = vault || (ranges.Customer_Indicator__c == VAULT_NAME && billCodeInRange(numericBillCode, maxCode, minCode));
                    shred = shred || (ranges.Customer_Indicator__c == SHRED_NAME && billCodeInRange(numericBillCode, maxCode, minCode));
                    xod = xod || (ranges.Customer_Indicator__c == XOD_NAME && billCodeInRange(numericBillCode, maxCode, minCode));
                    iod = iod || (ranges.Customer_Indicator__c == IOD_NAME && billCodeInRange(numericBillCode, maxCode, minCode));
                }
                
                series5000BillCode = series5000BillCode || billCodeInRange(numericBillCode, 5999, 5000);
                series1800BillCode = series1800BillCode || billCodeInRange(numericBillCode, 1899, 1800);
                series2000BillCode = series2000BillCode || billCodeInRange(numericBillCode, 2999, 2000);
                string productNameLowerCase = qli.Product_Name__c != null ? qli.Product_Name__c.toLowerCase() : '';
                valProductCodeExists = valProductCodeExists || productNameLowerCase.contains('3472') || productNameLowerCase.contains('3473')
                                                            || productNameLowerCase.contains('3474') || productNameLowerCase.contains('3478')
                                                            || productNameLowerCase.contains('val') || productNameLowerCase.contains('easy');
                recurringChargesExists = recurringChargesExists || recurringChargesDetails.containsKey(qli.Product_Name__c);
                productCodes.add(numericBillCode);
                
               /*if(recurringChargesExists){
                for(SKPRecurringChargesDetails__c sc : recurringChargesDetails.values()){
                    if(sc.Name.equals(qli.Product_Name__c)){
                        recurringBillCode = sc.BillCode__c;
                        recurringRate = sc.Rate__c;
                        }     
                      } 
                 } */
                
            }
            
            //if( rmAdminContractVersions.contains(contractVersion) ) {
                findReasonCode(valProductCodeExists, productCodes, series1800BillCode, series5000BillCode);
            //}
            
            if(productCodes != null && productCodes.contains(890) && series2000BillCode){
                shredAndServiceBoth = true;//productCodes.containsAll(shredAndSalesCode);
            }
            
        }
        public void findReasonCode (boolean valProductCodeExists, Set<Integer> productCodes, boolean series1800BillCode, boolean series5000BillCode){
            if(valProductCodeExists){
                this.reasonCode = BUNDLED_PROGRAM ;
                this.bundledIndicator = true;
            } 
            //else if (((productCodes.contains(890) || series1800BillCode) && !productCodes.contains(3475))|| (series5000BillCode && !productCodes.contains(5799))) 
            if ((productCodes.contains(318) || productCodes.contains(319)) && (!productCodes.contains(3475)) && (!productCodes.contains(5799)))
            {
                this.reasonCode = '';
                this.rmAdminFee = true;
            } 
            else if (productCodes.contains(890) && productCodes.contains(3475)) 
            {
                this.reasonCode = MINIMUM_STORAGE_ACCOUNT ;
            } 
            else if (productCodes.contains(58)){
                this.reasonCode = DMS_SERVICE_ONLY ;
            }
        }

    }

    public static String cleanCountryCode (String country){
        String countryToReturn = country;
        if(country != null && country.toLowerCase().contains('canada') ){
            countryToReturn = 'CAN';
        }
        return countryToReturn;
    }
    
    public static string getNextYearDateString(Date startDate){
        Integer month = (startDate.day() >= 15 ) ? startDate.month() + 1 : startDate.month();
        Datetime nextDate = datetime.newInstance( startDate.year() + 1, month, 1);
        return nextDate.format('yyyy/MM/dd');
    }
    
        public static List<Case_Customer_Account__c> fetchCaseCustomerAccts(Case c){
        List<Case_Customer_Account__c> caseCustAccList = [select Id, Name,Customer_Account__r.Name,Customer_Account__r.SKP_Customer_Name__c,Customer_Account__r.SKP_Contract_Link_Code__c,Customer_Account__r.SKP_Admin_Fee__c,Customer_Account__r.SKP_Fuel_Surcharge__c,Customer_Account__r.SKP_Hardcopy_Indicator__c,Customer_Account__r.SKP_Shred_Indicator__c,Customer_Account__r.SKP_Billing_Cycle__c,Customer_Account__r.SKP_Container_Billing_Indicator__c,Customer_Account__r.SKP_Exception_Rate_ID__c,Customer_Account__r.Renewal_ERID__c from Case_Customer_Account__c where Case__c = :c.Id];
        return caseCustAccList;
    }
    public static string checkOAuthSecurityToken(string endPoint, string clientId, string clientSecret){
        Http http = new Http();
        HTTPResponse tokenResponse;
        OAuthResponse tokenDetails;
        //build Request
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint); 
        request.setMethod('POST');
        request.setHeader('client_key', ClientId);
        request.setHeader('client_secret', ClientSecret);
        //call SKP System
        try{
            tokenResponse = http.send(request);
            String tokenResponseBody = tokenResponse.getBody();
            tokenDetails= (OAuthResponse)JSON.deserialize(tokenResponseBody, OAuthResponse.class);
            string finalSecurityToken;
            finalSecurityToken = tokenDetails.access_token;
            return finalSecurityToken;
        }catch (CalloutException e){
            ApexPAges.addMessages(e);
            return null;
        }
     }
     public static HttpRequest OAuthbuildRequest(String endpoint, String accesstoken, string authorizationHeader, string jsonString){
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        
        if(endpoint.contains('get') || endpoint.contains('Get')){
            request.setMethod('GET');
        }else{    
            request.setMethod('POST');
        }   
        request.setHeader('access_token', 'Bearer ' + accesstoken);
        request.setHeader('Content-Type', 'application/json');
       // request.setHeader('Authorization', authorizationHeader);
        request.setHeader('userid', authorizationHeader);
        request.setBody(jsonString);
        request.setTimeout(100*1000);
        return request;
    }
    
    public class testQty{
        public Decimal var1;
        public Decimal var2;
        public Decimal var3;
        public Decimal var4;
        public Decimal var5;
        public Decimal var6;
        public Decimal var7;
        public Decimal var8;
        
        public testQty(){
            this.var1 = 1;
            this.var2 = 1;
            this.var3 = 1;
            this.var4 = 1;
            this.var5 = 1;
            this.var6 = 1;
            this.var7 = 1;
            this.var8 = 1;
        }
    }
}