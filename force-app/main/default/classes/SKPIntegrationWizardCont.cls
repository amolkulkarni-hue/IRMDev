public with sharing class SKPIntegrationWizardCont {
    
    public Case skpCase {get; set;}
    public boolean validatedInSKP {get;set;}
    public List<ScheduleAWrapper> wrappers {get;set;}
    public Quote selectedScheduleA {get;set;}
    public SKP_Contract_Type_Mapping__c contractMapping;
    public SkpIntegrationHelper.CustomerIndicator customerIndicator;
    public string customerID;
    public string customerName;
    public string districtId;
    public boolean debugMode = false;
    public string contractType = '';
    public string recordTypeName = '';
    public string paymentTerm {get;set;}
    public string shredType {get; private set;}
    
    public boolean calloutException = false;
    public boolean recurringCalloutException = false;    
    public boolean isPrevalidate{get;private set;}
    
    
    public SKPCustomer customerForValidation;
    public SKPContract contractForValidation;
    
    public string customerJsonString {get;set;}
    public string contractJsonString {get;set;}
    
    public List<SKP_Sync_Error__c> syncErrors {get;set;}
    public List<SKP_Sync_Error__c> syncWarnings {get;set;}
    
    public static final string NO_SCHEDULE_A_FOUND = 'No Schedule A objects were found on the opportunity';
    public static final string NO_CASE_FOUND = 'No case found';
    public static final string NO_CONTRACT_MAPPING_FOUND = 'No contract mapping found.';
    public static final string NO_CUSTOMER_ACCOUNT_FOR_PREVALIDATION = 'No Customer Accounts found for pre validation';
    public static final string SELECT_A_SCHEDULE_A = 'Please select a Schedule A';
    public static final string SKP_NA = 'SKP NA';
    public static final string SRC_CUST_ID_MISSING = 'You must have source customer Id and Exception Rate Id to sync Affiliate Contract';
    public static final string CUST_Profile_MISSING = 'You must have Customer Profile to sync Affiliate Contract';
    
    
    public boolean noScheduleAMessageForOptionA {get;set;}
    string caseID;
    
    public List<Case_Customer_Account__c> caseCustomerAccts {get;set;}
    public List <IM_Customer_Account__c> customerAccounts {get;set;}
    public set<Id> custid {get;set;}
    public SKP_Contract_Type_Mapping__c singleContractMapping{get;set;}
    Map<IM_Customer_Account__c,SKPPreValidationResponse> skpCustData = new Map<IM_Customer_Account__c,SKPPreValidationResponse>();
    Map<IM_Customer_Account__c,SKPPreValidationContractResponse> skpContractData = new Map<IM_Customer_Account__c,SKPPreValidationContractResponse>();    
    Map<String, SKPRecurringChargesDetails__c> recurringChargesDetailsMap; 
    
    public enum Button {NONE, VALIDATE, VALIDATECONTRACT, CREATECONTRACT, CREATECUSTOMER,MultiYearSync} 
    public Button currentButton;
    public string finalSecurityToken;
    
    public String buttonToDisplay {get { return currentButton.name();}  private set;}
    
    public static Boolean runningInASandbox {
        get{
            if ( runningInASandbox == null) {
                runningInASandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
            }
            return runningInASandbox;
        } set;
    }
    
    public  SKP_Integration_Details__c skpDetails{
        get{
            if(skpDetails == null){
                string sandboxType = runningInASandbox ? 'Sandbox' : 'Production' ;
                skpDetails = SKP_Integration_Details__c.getInstance(sandboxType);
            }
            return skpDetails;
        }
        set;
    }
    
    public static Set<String> scheduleAFields{
        get{
            if(scheduleAFields == null){
                scheduleAFields = new Set<String>{'name', 'id','service_line__c', 'effective_date__c','RM_Contract_Length__c','SS_Contract_Length__c'};
                    for( Schema.FieldSetMember member : SobjectType.Quote.FieldSets.SKP_Display_Fields.getFields() ) {
                        scheduleAFields.add(member.getFieldPath().toLowerCase());
                    }
            }
            return scheduleAFields;
        } set;
    }
    
    
    public SKPIntegrationWizardCont(){
        validatedInSKP = false;
        wrappers = new List<ScheduleAWrapper>();
        Map<String, string> parameters = ApexPages.currentPage().getParameters();
        caseID = parameters.get('id');
        debugMode = (parameters.get('debug') == '1');
        syncErrors = new List<SKP_Sync_Error__c>();
        syncWarnings = new List<SKP_Sync_Error__c>();
        customerID = '';
        customerName = '';
        paymentTerm = '30';
        caseCustomerAccts = new List<Case_Customer_Account__c>();
        customerAccounts = new List <IM_Customer_Account__c> ();
        skpCase = queryCase(caseId);
        caseCustomerAccts = SKPIntegrationHelper.fetchCaseCustomerAccts(skpCase);
        custid= new set<Id>(); 
        recurringChargesDetailsMap =  SKPIntegrationHelper.recurringChargesDetails;          
        
        if(caseCustomerAccts !=null && caseCustomerAccts.size()>0){
            for(Case_Customer_Account__c cc: caseCustomerAccts){
                custid.add(cc.Customer_Account__r.Id);
            }
        }
        
        this.customerAccounts  =[Select Id,Name,SKP_Customer_Name__c,SKP_Contract_Link_Code__c,SKP_Admin_Fee__c,SKP_Fuel_Surcharge__c,SKP_Hardcopy_Indicator__c,SKP_Shred_Indicator__c,SKP_Billing_Cycle__c,SKP_Container_Billing_Indicator__c,SKP_Exception_Rate_ID__c,Renewal_ERID__c  From IM_Customer_Account__c Where Id =: custid];
        if(custid.size() == 1 && customerAccounts[0].Renewal_ERID__c == false){
            customerAccounts[0].Renewal_ERID__c = true;
        }
        
        
        if(skpCase != null) {
            contractType = skpCase.Contract_Type__c;
            recordTypeName = skpCase.RecordType.Name;            
            
            if(skpCase.NCSP_Service_line__c == 'One Time Shred')   
                shredType = 'One Time';
            else if (skpCase.NCSP_Service_line__c == 'Shred')   
                shredType = 'recurring';
            else
                shredType = ''; 
            
            if(skpCase.SKP_Contract_Sync_Date__c != null){
                currentButton = Button.NONE;
            } else if(skpCase.SKP_Customer_Sync_Date__c != null){
                if(skpCase.Sync_succeeded_till__c != null)
                {        
                    currentButton = Button.MultiYearSync;
                }
                else
                {
                    currentButton = Button.VALIDATECONTRACT;
                }
            } else {
                currentButton = Button.VALIDATE;
            }
            
            if(recordTypeName == 'NCSP Renewal'){isPrevalidate = true;}            
            system.debug('(string)skpCase.NCSP_Opportunity__c=='+(string)skpCase.NCSP_Opportunity__c); 
            system.debug('new List<String>(scheduleAFields)=='+new List<String>(scheduleAFields)); 
            List<Quote> scheduleAs =  SKPIntegrationHelper.getScheduleAs((string)skpCase.NCSP_Opportunity__c, new List<String>(scheduleAFields) );
            
            if(SkpIntegrationHelper.getMappings(skpCase.contract_type__c) != null 
               && SkpIntegrationHelper.getMappings(skpCase.contract_type__c).size() != 0)
                singleContractMapping = SkpIntegrationHelper.getMappings(skpCase.contract_type__c)[0]; 
            
            this.customerID = (skpCase.Customer_ID__c != null) ? skpCase.Customer_ID__r.name : '';
            this.customerName = (skpCase.Customer_ID__c != null) ? skpCase.Customer_ID__r.IM_Customer_Account_Name__c : '';
            this.districtID = (skpCase.Customer_ID__c != null) ? skpCase.Customer_ID__r.IM_District_Branch_Id__c : '';
            
            if (String.isBlank(customerName) && String.isBlank(customerID)){
                customerName = skpCase.Customer_Profile__r.Customer_Name__c;
                customerId = 'SFEXP';
            }
            
            if(contractType != 'Affiliate Option 1' && scheduleAs.isEmpty()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, NO_SCHEDULE_A_FOUND));
                currentButton = Button.NONE; 
            } else if(contractType == 'Affiliate Option 1' && scheduleAs.isEmpty()){           
                noScheduleAMessageForOptionA = true ; 
            }else if (scheduleAs.size() == 1){
                selectedScheduleA =scheduleAs[0];
                ScheduleAWrapper wrapper = new ScheduleAWrapper(selectedScheduleA);
                wrapper.ischecked = true;
                System.debug('QLIs==='+selectedScheduleA.quoteLineItems);
                customerIndicator = new SkpIntegrationHelper.customerIndicator(selectedScheduleA.quoteLineItems, skpCase.contract_type__c);
                
                wrappers.add(wrapper);
            } else {
                for( Quote schedA: scheduleAs ) {
                    wrappers.add(new ScheduleAWrapper(schedA));
                }
            }
        }
    }
    
    public void updateSingleCust(List<IM_Customer_Account__c> custToUpate){
        custToUpate[0].Renewal_ERID__c = true;
        update custToUpate;
    }
    
    public PageReference save(){
        List<IM_Customer_Account__c> custaccts= new List<IM_Customer_Account__c>();
        if(customerAccounts != null && customerAccounts.size()>0){
            for(IM_Customer_Account__c imca: customerAccounts){
                if(imca.Renewal_ERID__c == true)
                    custaccts.add(imca);
            }
        }
        
        if(custaccts != null && (custaccts.size()== 1 || custaccts.size()== 0)){
            update customerAccounts;
        }else if(custaccts != null && custaccts.size()>1){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Fatal,'Please select only One Renewal ERID at the time'));
        }
        return null;
    }
    
    public pageReference cancel(){
        return null;
    }
    
    public pageReference validateSKPCustomerAndContract(){
        finalSecurityToken = SKPIntegrationHelper.checkOAuthSecurityToken(skpDetails.OAuth_EndPoint__c,skpDetails.Client_Id__c,skpDetails.Client_Secret__c);
        system.debug('#####validateSKPCustomerAndContract'+finalSecurityToken);
        if(finalSecurityToken != null){
        PageReference reference;
        skpCase = queryCase(caseId);
        caseCustomerAccts = SKPIntegrationHelper.fetchCaseCustomerAccts(skpCase);
        if(caseCustomerAccts !=null && caseCustomerAccts.size()>0){
            for(Case_Customer_Account__c cc: caseCustomerAccts){
                custid.add(cc.Customer_Account__r.Id);
            }
            this.customerAccounts  =[Select Id,Name,SKP_Customer_Name__c,SKP_Contract_Link_Code__c,SKP_Admin_Fee__c,SKP_Fuel_Surcharge__c,SKP_Hardcopy_Indicator__c,SKP_Shred_Indicator__c,SKP_Billing_Cycle__c,SKP_Container_Billing_Indicator__c,SKP_Exception_Rate_ID__c,Renewal_ERID__c  From IM_Customer_Account__c Where Id =: custid];            
        }
        
        
        
        
        
        List<IM_Customer_Account__c> custaccts= new List<IM_Customer_Account__c>();
        if(customerAccounts != null && customerAccounts.size()>0){
            for(IM_Customer_Account__c imca: customerAccounts){
                if(imca.Renewal_ERID__c == true)
                    custaccts.add(imca);
            }
            if(custaccts != null && custaccts.size() == 0){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Fatal,'Please select atleast One Renewal ERID.'));
                return null;
            }             
        }        
        
        if(contractType == 'Affiliate Option 1'){
            reference = customerCallout_Affiliate(true);  
            if(!calloutException){
                reference = contractCallout_Affiliate(true);
            }
            insertNewSyncErrors(true);  
        }else if(contractType == 'Affiliate Option 2'){
            reference = customerCallout_Affiliate(true);  
            if(!calloutException){
                reference = contractCallout_Affiliate(true);
            }
            insertNewSyncErrors(true);  
        }else if(recordTypeName == 'NCSP Renewal'){
            //Renewal and Renegotiation
            system.debug('customerCallout_RenewalNRenego==');
            reference = customerCallout_RenewalNRenego(true);
            
            if(!calloutException){
                reference = contractCallout_RenewalNRenego(true,1);
            }
            
            insertNewSyncErrors(true);
        }else{
            reference = customerCallout(true);
            
            if(!calloutException){
                reference = contractCallout(true);
            }
            
            insertNewSyncErrors(true);
        }
        
        return reference;
    }else{
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'Security Token is NOT Valid !!!'));
        return null;
    }
    }
    
    public PageReference createSKPCustomer(){
        PageReference reference;
        system.debug('+++++skpDetails'+skpDetails.OAuth_EndPoint__c+'===11'+skpDetails.Client_Id__c+'----11'+skpDetails.Client_Secret__c);
        finalSecurityToken = SKPIntegrationHelper.checkOAuthSecurityToken(skpDetails.OAuth_EndPoint__c,skpDetails.Client_Id__c,skpDetails.Client_Secret__c);
        system.debug('++++createSKPCustomer/Secu'+finalSecurityToken);
        if(finalSecurityToken != null){
            
            if(contractType == 'Affiliate Option 1' || contractType == 'Affiliate Option 2'){
                system.debug('Check00');
                reference = customerCallout_Affiliate(false);
            }else if(recordTypeName == 'NCSP Renewal'){
                system.debug('Check11');
                reference = customerCallout_RenewalNRenego(false);
            }else{
                system.debug('Check22');
                reference = customerCallout(false);
                system.debug('@@@@@');
            }
            insertNewSyncErrors(false);
            return reference;
        }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'Security Token is NOT Valid !!!'));
                return null;
        }
    }
    
    public PageReference customerCallout(boolean validate){
        
        Http http = new Http();
        HTTPResponse customerResponse;
        SKPResponse skpCustomerResp;
        OAuthResponse tokenDetails;
        
        if(!hasSelectedScheduleA()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, SELECT_A_SCHEDULE_A));
            return null;
        }
        
        customerJsonString = JSON.serialize(new SKPCustomer(skpCase, selectedScheduleA, validate, skpDetails.Username__c, customerIndicator));
        customerJsonString = customerJsonString.replaceAll('systemStringToBeReplaced', 'system');
        
        //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
        Blob headerValue = Blob.valueOf(skpDetails.Username__c);
        //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        String authorizationHeader = EncodingUtil.base64Encode(headerValue);
        
        //HttpRequest customerRequest = SKPIntegrationHelper.buildRequest(skpDetails.Customer_Endpoint__c, authorizationHeader, customerJsonString);
        System.debug('====11'+customerJsonString);
        HttpRequest customerRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Customer_Endpoint__c,finalSecurityToken, authorizationHeader, customerJsonString);
        system.debug('%%%%%1'+customerRequest);
        try{
            if(debugMode) {ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, customerJsonString));}
            
            customerResponse = http.send(customerRequest);
            calloutException = false;
            
            string customerResponseBody = customerResponse.getBody();
            System.debug('customerResponseBody==='+customerResponseBody);
            System.debug(LoggingLevel.Info,'customerResponseBody==='+customerResponseBody);
            skpCustomerResp  = (SKPResponse)JSON.deserialize(customerResponseBody, SKPResponse.class);
            system.debug('%%%%%1-2'+skpCustomerResp);
            if((!validate) && skpCustomerResp.success && skpCustomerResp.result != null ){
                
                Market__c[] owningBranch = [select id, name from Market__c where Owning_District_Id__c = :skpCustomerResp.result.districtid limit 1];
                
                IM_Customer_Account__c newCustomer = new IM_Customer_Account__c(name = skpCustomerResp.result.customerId, 
                                                                                IM_Account__c = skpCase.accountId, 
                                                                                Source_System__c = SKP_NA,
                                                                                IM_District_Branch_Id__c = skpCustomerResp.result.districtid,
                                                                                IM_Customer_Account_Name__c = skpCustomerResp.result.customerName);
                
                if(owningBranch.size() > 0)
                    newCustomer.Owning_District_Id__c = owningBranch[0].id;
                
                SkpIntegrationHelper.insertObjects(new List<Sobject>{newCustomer});
                
                this.customerID = newCustomer.name;
                this.customerName = newCustomer.IM_Customer_Account_Name__c;
                this.districtId = newCustomer.IM_District_Branch_Id__c;
                
                skpCase.Customer_ID__c = newCustomer.id;
                skpCase.SKP_Customer_Sync_Date__c = Datetime.now();
                
                SkpIntegrationHelper.upsertObjects(new List<Sobject>{skpCase});
                skpCase = queryCase(caseId);
            }
        } catch (CalloutException e){
            ApexPAges.addMessages(e);
            calloutException = true;
            return null;
        } 
        
        handleSKPResponse(skpCustomerResp, validate);
        
        if( syncErrors != null && (!syncErrors.isEmpty())){
            currentButton = Button.NONE;
            
        } else if( !validate ) {
            currentButton = Button.CREATECONTRACT ;
        }
        
        return null;
    }
    
    
    public PageReference createSKPContract(){
        finalSecurityToken = SKPIntegrationHelper.checkOAuthSecurityToken(skpDetails.OAuth_EndPoint__c,skpDetails.Client_Id__c,skpDetails.Client_Secret__c);
        system.debug('#####createSKPContract/Secu'+finalSecurityToken);
        if(finalSecurityToken != null){
            PageReference reference ;
            
            system.debug('selectedScheduleA==='+selectedScheduleA); 
            integer maxYears = (selectedScheduleA.RM_Contract_Length__c>selectedScheduleA.SS_Contract_Length__c ? selectedScheduleA.RM_Contract_Length__c : selectedScheduleA.SS_Contract_Length__c).intValue();
            
            system.debug('maxYears=='+maxYears);
            
            if(contractType == 'Affiliate Option 1' ||contractType == 'Affiliate Option 2')
            {
                system.debug('====1');
                reference = contractCallout_Affiliate(false);  
            }
            else if(recordTypeName == 'NCSP Renewal')
            {     
                system.debug('====2');
                reference = contractCallout_RenewalNRenego(false,maxYears); 
            }
            else
            {
                system.debug('Record Type:'+ recordTypeName+'contract Type:'+contractType+'====3');
                reference = contractCallout(false); 
            }
            
            if(syncErrors.isEmpty() && recordTypeName != 'NCSP Renewal' && maxYears==1)
            {     
                skpCase.SKP_Contract_Sync_Date__c = Datetime.now();
            } 
            system.debug('=====5'+skpCase);
            SkpIntegrationHelper.upsertObjects(new List<Sobject>{skpCase});
            insertNewSyncErrors(false); 
            return reference;
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'Security Token is NOT Valid !!!'));
                return null;
            }
    }
    
    public PageReference multiYearContractUpdate(){
        finalSecurityToken = SKPIntegrationHelper.checkOAuthSecurityToken(skpDetails.OAuth_EndPoint__c,skpDetails.Client_Id__c,skpDetails.Client_Secret__c);
        system.debug('#####'+finalSecurityToken);
        if(finalSecurityToken != null){
            PageReference reference ;
            Integer initYear;
            
            if(!hasSelectedScheduleA()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, SELECT_A_SCHEDULE_A));
                return null;
            }
            
            system.debug('selectedScheduleA==='+selectedScheduleA); 
            
            integer maxYears = (selectedScheduleA.RM_Contract_Length__c>selectedScheduleA.SS_Contract_Length__c ? selectedScheduleA.RM_Contract_Length__c : selectedScheduleA.SS_Contract_Length__c).intValue();
            
            if(skpCase.Sync_succeeded_till__c!= null)
                initYear= (skpCase.Sync_succeeded_till__c).intValue();
            else
                initYear = 1;
            
            initYear++; 
            
            system.debug('maxYears=='+maxYears);
            
            for(Integer year=initYear;year<=maxYears;year++)   
            { 
                if(contractType == 'Affiliate Option 2')
                {   
                    reference = multiContractCallout_Affiliate(year);
                }
                else            
                { 
                    reference = contractMultiCallout(year);  
                }
            }
            
            if(syncErrors != null && syncErrors.isEmpty() && recordTypeName != 'NCSP Renewal')
            {            
                skpCase.SKP_Contract_Sync_Date__c = Datetime.now();  
                SkpIntegrationHelper.upsertObjects(new List<Sobject>{skpCase});
            } 
            insertNewSyncErrors(false);            
            
            return reference;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'Security Token is NOT Valid !!!'));
            return null;
        }
    }
    
    public PageReference contractCallout(boolean validate){
        
        Http http = new Http();
        HTTPResponse contractResponse;
        SKPResponse skpContractResp;
        SKPUpdateContractResponse skpUpdateContractResp;
        HttpRequest contractRequest;
        
        system.debug('In contractCallout');
        
        if(!hasSelectedScheduleA()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, SELECT_A_SCHEDULE_A));
            return null;
        }
        
        if (! hasContractMapping() ){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, NO_CONTRACT_MAPPING_FOUND));
            return null;
        }
        
        //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
        //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        Blob headerValue = Blob.valueOf(skpDetails.Username__c);
        String authorizationHeader = EncodingUtil.base64Encode(headerValue);
        boolean isSuccess = false;
        System.debug(LoggingLevel.Info,'Territory Id=='+skpCase.Customer_Profile__r.Sales_Rep_ID__c);
        
        integer maxYears = (selectedScheduleA.RM_Contract_Length__c>selectedScheduleA.SS_Contract_Length__c ? selectedScheduleA.RM_Contract_Length__c : selectedScheduleA.SS_Contract_Length__c).intValue();
        
        try
        {
            contractJsonString = JSON.serialize(new SKPContract(skpCase, selectedScheduleA, contractMapping, customerindicator, validate, customerId, customerName,1));
            contractJsonString = contractJsonString.replaceAll('systemStringToBeReplaced', 'system');
            //contractRequest = SKPIntegrationHelper.buildRequest(skpDetails.Contract_Endpoint__c, authorizationHeader, contractJsonString);
            contractRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Contract_Endpoint__c,finalSecurityToken, authorizationHeader, contractJsonString);
            system.debug('&&&&&&&'+contractRequest);
            system.debug('SKPContract response contractJsonString for year 1 ==='+contractJsonString);
            if(debugMode) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, contractJsonString));      
            
            contractResponse = http.send(contractRequest);    
            system.debug('contractResponse=='+contractResponse);
            calloutException = false;
            system.debug('&&&&&&&11'+contractResponse );
            skpContractResp  = (SKPResponse)JSON.deserialize(contractResponse.getBody(), SKPResponse.class);
            system.debug('&&&&&&&222'+skpContractResp  );
            if(debugMode) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, 'SKP Response'+skpContractResp));        
            if(!validate && skpContractResp.success){
                isSuccess = true;
                system.debug('---->1');
                /*  
                * For New Deals - Below code is to find recurring charges
                * Once Contract Validation is successfully completed then Salesforce will fetch
                * the recurring charges for Recurring Products by calling SKP services
                */
                System.debug(LoggingLevel.Info,'customerindicator.recurringChargesExists + New Deal ==='+customerindicator.recurringChargesExists);
                if(Test.isRunningTest()){
                    customerindicator.recurringChargesExists = true;
                }                
                system.debug('---->2'+customerindicator);
                if(customerindicator != null && customerindicator.recurringChargesExists){
                    system.debug('---->3');
                    Set<String> recList;
                    List<QuoteLineItem> newQlis = new List<QuoteLineItem>(); 
                    Set<String> recurringCustIds = new Set<String>(); 
                    if(skpCase.RecordType.Name == 'NCSP: SKP New Customer Setup' && skpCase.Customer_ID__c != null){
                        recurringCustIds.add(skpCase.Customer_ID__r.Name);
                    }
                    
                    System.debug(LoggingLevel.Info,'New Deal recurringCustIds=='+recurringCustIds);
                    Map<String,QuoteLineItem> SFDCLineItems = new Map<String,QuoteLineItem>();
                    
                    for(QuoteLineItem qli1:selectedScheduleA.quoteLineItems){
                        if(recurringChargesDetailsMap.get(qli1.Product_Name__c) != null 
                           && (recurringChargesDetailsMap.get(qli1.Product_Name__c).ProductName__c.equals(qli1.Product_Name__c)
                               || recurringChargesDetailsMap.get(qli1.Product_Name__c).BillCode__c.equals(qli1.Product_Name__c))){
                                   System.debug(LoggingLevel.Info,'Qli1 coming here is ==='+qli1);   
                                   SFDCLineItems.put(recurringChargesDetailsMap.get(qli1.Product_Name__c).BillCode__c,qli1); 
                               }     
                    }
                    
                    if(SFDCLineItems != null && SFDCLineItems.size() > 0){
                        for(String str : SFDCLineItems.keySet()){
                            newQlis.add(SFDCLineItems.get(str));
                        }
                    }
                    
                    if(newQlis != null && newQlis.size() > 0){
                        processRecurringCharges(recurringCustIds,newQlis,null,false);
                    }
                    
                } 
                System.debug(LoggingLevel.Info,'recurringCalloutException=='+recurringCalloutException);
                
            } 
            handleSKPResponse(skpContractResp, validate);
            
        } 
        catch (CalloutException e)
        {
            system.debug('current year==1');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, 'Contract synced till year 1'));
            ApexPages.addMessages(e);
            calloutException = true;
            return null;
        }   
        system.debug('----->5'+validate+'---->6'+syncErrors+'---->7'+syncErrors.isEmpty());
        if((validate) &&  syncErrors != null && syncErrors.isEmpty()){
            currentButton = (skpCase.SKP_Customer_Sync_Date__c != null) ? Button.CREATECONTRACT : Button.CREATECUSTOMER ;
        } 
        else if ((maxYears>1) && (isSuccess) && (!validate))
        {
            system.debug('check-maxYear55'+maxYears);
            skpCase.Sync_succeeded_till__c=1;
            currentButton = Button.MultiYearSync;
        }
        else {
            currentButton = Button.NONE;
        }               
        return null;
    }
    
    
    public PageReference contractMultiCallout(Integer year){
        
        Http http = new Http();
        HTTPResponse contractResponse;
        SKPResponse skpContractResp;
        SKPUpdateContractResponse skpUpdateContractResp;
        HttpRequest contractRequest;
        
        system.debug('In Multi year contractCallout');
        
        if(!hasSelectedScheduleA()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, SELECT_A_SCHEDULE_A));
            return null;
        }
        
        if (! hasContractMapping() ){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, NO_CONTRACT_MAPPING_FOUND));
            return null;
        }
        
        //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
        //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        Blob headerValue = Blob.valueOf(skpDetails.Username__c);
        String authorizationHeader = EncodingUtil.base64Encode(headerValue);
        boolean isSuccess = true;
        System.debug(LoggingLevel.Info,'Territory Id=='+skpCase.Customer_Profile__r.Sales_Rep_ID__c);
        
        integer maxYears = (selectedScheduleA.RM_Contract_Length__c>selectedScheduleA.SS_Contract_Length__c ? selectedScheduleA.RM_Contract_Length__c : selectedScheduleA.SS_Contract_Length__c).intValue();

        try
        {            
            contractJsonString = JSON.serialize(new SKPContractUpdate(skpCase, selectedScheduleA, contractMapping, customerindicator, false, customerId, customerName,customerId,year));                
            contractJsonString = contractJsonString.replaceAll('systemStringToBeReplaced', 'system');
            //contractRequest = SKPIntegrationHelper.buildRequest(skpDetails.Update_Contract_Info__c, authorizationHeader, contractJsonString);           
            contractRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Update_Contract_Info__c,finalSecurityToken, authorizationHeader, contractJsonString);
            
            
            system.debug('SKPContract response contractJsonString for year '+year+'==='+contractJsonString);
            if(debugMode) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, contractJsonString));      
            
            contractResponse = http.send(contractRequest);    
            system.debug('contractResponse=='+contractResponse);
            calloutException = false;
            
            skpUpdateContractResp  = (SKPUpdateContractResponse)JSON.deserialize(contractResponse.getBody(), SKPUpdateContractResponse.class);                
            if(debugMode) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, 'SKP Response'+skpUpdateContractResp));      
            
            handleSKPUpdateContractResponse(skpUpdateContractResp,false);
        } 
        catch (CalloutException e)
        {
            system.debug('current year=='+year);
            skpCase.Sync_succeeded_till__c=year;
            update skpCase;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, 'Contract synced till year '+year));
            ApexPages.addMessages(e);
            calloutException = true;
            return null;
        }   
        
        currentButton = Button.NONE;
        
        return null;
    }
    
    public PageReference customerCallout_Affiliate(boolean validate){
        Http http = new Http();
        HTTPResponse customerResponse;
        SKPResponse skpCustomerResp;
        system.debug('-----1');
        if(contractType != 'Affiliate Option 1' && !hasSelectedScheduleA()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, SELECT_A_SCHEDULE_A));
            return null;
        }
        
        if((contractType == 'Affiliate Option 1' && (skpCase.Source_Customer_Id__c == null || skpCase.Source_Customer_Id__c == ''))
           || (contractType == 'Affiliate/Option2') && (skpCase.Source_Customer_Id__c == null || skpCase.Source_Customer_Id__c == '') )
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, SRC_CUST_ID_MISSING)); 
            return null;
        } 
        if(skpCase.Customer_Profile__r == null) 
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, CUST_Profile_MISSING )); 
            return null;
        } 
        
        customerJsonString = JSON.serialize(new SKPCustomerAffiliate(skpCase.Source_Customer_Id__c,skpCase, selectedScheduleA, validate, skpDetails.Username__c, customerIndicator));
        customerJsonString = customerJsonString.replaceAll('systemStringToBeReplaced', 'system');
        
        //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
        //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        Blob headerValue = Blob.valueOf(skpDetails.Username__c);
        String authorizationHeader = EncodingUtil.base64Encode(headerValue);
        //HttpRequest customerRequest = SKPIntegrationHelper.buildRequest(skpDetails.Customer_Endpoint__c, authorizationHeader, customerJsonString);
        HttpRequest customerRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Customer_Endpoint__c,finalSecurityToken, authorizationHeader, customerJsonString);
        system.debug('customerJsonString==='+customerJsonString);
        system.debug('-----1-1'+customerRequest);
        try{
            if(debugMode) {ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, customerJsonString));}
            
            customerResponse = http.send(customerRequest);
            calloutException = false;
            
            string customerResponseBody = customerResponse.getBody();
            system.debug('-----1-2'+customerResponseBody);
            System.debug('customerResponseBody for Affiliate==='+customerResponseBody);
            skpCustomerResp  = (SKPResponse)JSON.deserialize(customerResponseBody, SKPResponse.class);
            system.debug('-----1-3'+customerResponseBody);
            if((!validate) && skpCustomerResp.success && skpCustomerResp.result != null ){
                
                Market__c[] owningBranch = [select id, name from Market__c where Owning_District_Id__c = :skpCustomerResp.result.districtid limit 1];
                
                IM_Customer_Account__c newCustomer = new IM_Customer_Account__c(name = skpCustomerResp.result.customerId, 
                                                                                IM_Account__c = skpCase.accountId, 
                                                                                Source_System__c = SKP_NA,
                                                                                IM_District_Branch_Id__c = skpCustomerResp.result.districtid,
                                                                                IM_Customer_Account_Name__c = skpCustomerResp.result.customerName);
                
                if(owningBranch.size() > 0)
                    newCustomer.Owning_District_Id__c = owningBranch[0].id;
                
                SkpIntegrationHelper.insertObjects(new List<Sobject>{newCustomer});
                
                this.customerID = newCustomer.name;
                this.customerName = newCustomer.IM_Customer_Account_Name__c;
                this.districtId = newCustomer.IM_District_Branch_Id__c;
                
                skpCase.Customer_ID__c = newCustomer.id;
                skpCase.SKP_Customer_Sync_Date__c = Datetime.now();
                
                SkpIntegrationHelper.upsertObjects(new List<Sobject>{skpCase});
                
                skpCase = queryCase(caseId);
            }
        } catch (CalloutException e){
            ApexPAges.addMessages(e);
            calloutException = true;
            return null;
        } 
        
        handleSKPResponse(skpCustomerResp, validate);
        
        if( syncErrors != null && (!syncErrors.isEmpty())){
            currentButton = Button.NONE;            
        } else if(validate && skpCase.SKP_Customer_Sync_Date__c == null){
            currentButton = Button.CREATECUSTOMER ; 
        } else if( !validate ) {
            currentButton = Button.CREATECONTRACT ;
        }
        
        return null;
    }
    public PageReference createSKPCustomer_Affiliate(){
        PageReference reference = customerCallout_Affiliate(false);
        insertNewSyncErrors(false);
        return reference;
    }
    
    public PageReference contractCallout_Affiliate(boolean validate){
        
        Http http = new Http();
        HTTPResponse contractResponse;
        SKPResponse skpContractResp;
        HttpRequest contractRequest;
        SKPUpdateContractResponse skpUpdateContractResp;
        
        system.debug('In contractCallout_Affiliate');
        
        if(contractType != 'Affiliate Option 1' && !hasSelectedScheduleA()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, SELECT_A_SCHEDULE_A));
            return null;
        }
        
        if (!hasContractMapping() ){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, NO_CONTRACT_MAPPING_FOUND));
            return null;
        }
        
        //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
        //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        Blob headerValue = Blob.valueOf(skpDetails.Username__c);
        String authorizationHeader = EncodingUtil.base64Encode(headerValue);
        boolean isSuccess = false; integer maxYears;
        
        system.debug('selectedScheduleA==='+selectedScheduleA); 
        
        if(selectedScheduleA != null)
          maxYears = (selectedScheduleA.RM_Contract_Length__c>selectedScheduleA.SS_Contract_Length__c ? selectedScheduleA.RM_Contract_Length__c : selectedScheduleA.SS_Contract_Length__c).intValue();
        else
          maxYears = 1;
                 
        try{
            if(contractType == 'Affiliate Option 1')
                contractJsonString = JSON.serialize(new SKPContractAffiliateOption1(skpCase, selectedScheduleA, contractMapping, customerindicator, validate, customerId, customerName));
            else
                contractJsonString = JSON.serialize(new SKPContractAffiliateOption2(skpCase, selectedScheduleA, contractMapping, customerindicator, validate, customerId, customerName,1));
            
            contractJsonString = contractJsonString.replaceAll('systemStringToBeReplaced', 'system'); 
            if(debugMode) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, contractJsonString));
            //contractRequest = SKPIntegrationHelper.buildRequest(skpDetails.Contract_Endpoint__c, authorizationHeader, contractJsonString);
            contractRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Contract_Endpoint__c,finalSecurityToken, authorizationHeader, contractJsonString);
            system.debug('=====11'+contractRequest);
            contractResponse = http.send(contractRequest);    
            calloutException = false;
            String contractResponseBody= contractResponse.getBody();
            system.debug('=====11-1'+contractRequest);
            if(!validate)isSuccess=true;
            
            skpContractResp  = (SKPResponse)JSON.deserialize(contractResponseBody, SKPResponse.class);
            system.debug('=====11-2'+skpContractResp);
            handleSKPResponse(skpContractResp, validate);
            
        } catch (CalloutException e){
            ApexPAges.addMessages(e);
            calloutException = true;
            return null;
        }
        
        if((validate) &&  syncErrors != null && syncErrors.isEmpty()){
            currentButton = (skpCase.SKP_Customer_Sync_Date__c != null) ? Button.CREATECONTRACT : Button.CREATECUSTOMER ;
        } 
        else if ((maxYears>1) && (isSuccess) && (!validate))
        {
            skpCase.Sync_succeeded_till__c=1;
            currentButton = Button.MultiYearSync;
        }
        else {
            currentButton = Button.NONE;
        }
        
        return null;
    }
    
    public PageReference multiContractCallout_Affiliate(Integer year){
        
        Http http = new Http();
        HTTPResponse contractResponse;
        SKPResponse skpContractResp;
        HttpRequest contractRequest;
        SKPUpdateContractResponse skpUpdateContractResp;
        
        system.debug('In multi contractCallout_Affiliate');
        
        if(contractType != 'Affiliate Option 1' && !hasSelectedScheduleA()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, SELECT_A_SCHEDULE_A));
            return null;
        }
        
        if (!hasContractMapping() ){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, NO_CONTRACT_MAPPING_FOUND));
            return null;
        }
        
        //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
        //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        Blob headerValue = Blob.valueOf(skpDetails.Username__c);
        String authorizationHeader = EncodingUtil.base64Encode(headerValue);
 
        integer maxYears = (selectedScheduleA.RM_Contract_Length__c>selectedScheduleA.SS_Contract_Length__c ? selectedScheduleA.RM_Contract_Length__c : selectedScheduleA.SS_Contract_Length__c).intValue();
                
        try
        {
            contractJsonString = JSON.serialize(new SKPContractUpdate (skpCase, selectedScheduleA, contractMapping, customerindicator, false, customerId, customerName,customerId,year));                
            contractJsonString = contractJsonString.replaceAll('systemStringToBeReplaced', 'system');
            
            system.debug('contractJsonString  for affiliate 1 ==='+contractJsonString);
            if(debugMode) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, contractJsonString));   
            
            //contractRequest = SKPIntegrationHelper.buildRequest(skpDetails.Update_Contract_Info__c, authorizationHeader, contractJsonString);           
            contractRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Update_Contract_Info__c,finalSecurityToken, authorizationHeader, contractJsonString);
            
            contractResponse = http.send(contractRequest);    
            calloutException = false;
            String contractResponseBody= contractResponse.getBody();
            
            skpUpdateContractResp  = (SKPUpdateContractResponse)JSON.deserialize(contractResponse.getBody(), SKPUpdateContractResponse.class);                
            if(debugMode) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, 'SKP Response'+skpUpdateContractResp));      
            
            handleSKPUpdateContractResponse(skpUpdateContractResp,false);
            
        } 
        catch (CalloutException e){
            system.debug('current year=='+year);
            skpCase.Sync_succeeded_till__c=year;
            update skpCase;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.info, 'Contract synced till year '+year));
            ApexPages.addMessages(e);
            calloutException = true;
            return null;
        }
        currentButton = Button.NONE;
        return null;
    }
    
    public boolean hasSelectedScheduleA(){
        for(ScheduleAWrapper wrapper : wrappers){
            if(wrapper.isChecked){
                selectedScheduleA = wrapper.scheduleA;
                system.debug('selectedScheduleA in hasSelectedScheduleA=='+selectedScheduleA );
                customerIndicator = new SkpIntegrationHelper.customerIndicator(selectedScheduleA.quoteLineItems, skpCase.contract_type__c);
                return true;
            }
        }
        
        selectedScheduleA = null;
        return false;
    }
    
    
    public boolean hasContractMapping (){
        List<SKP_Contract_Type_Mapping__c> contractMappings = SkpIntegrationHelper.getMappings(skpCase.contract_type__c);
        system.debug('contractMappings ==='+contractMappings );
        contractMapping = (contractMappings != null && contractMappings.size() == 1) ? contractMappings[0] : null ;
        system.debug('contractMappings and contract_type__c==='+contractMapping+'==='+skpCase.contract_type__c);
        if(contractMappings!= null && contractMappings.size() > 0)  
            singleContractMapping =  contractMappings[0]; 
        return (contractMapping != null);
    }
    
    public void handleSKPResponse(SKPResponse response, Boolean validate){
        
        string syncType = (validate) ? 'Validate' : 'Sync' ;
        
        List<SKPResponse.CodeAndMessage> errors = new List<SKPResponse.CodeAndMessage>();
        List<SKPResponse.CodeAndMessage> warnings = new List<SKPResponse.CodeAndMessage>();
        system.debug('error==='+response);
        if(response.errors != null){
            errors.addAll(response.errors);
        }
        if(response.warnings != null){
            warnings.addAll(response.warnings);
        }
        
        boolean hasErrors = !(errors.isEmpty());
        boolean hasWarnings = !(warnings.isEmpty());
        
        List<SKP_Sync_Error__c> newSyncResults = new List<SKP_Sync_Error__c>();
        
        for(SKPResponse.CodeAndMessage error : errors){
            SKP_Sync_Error__c skpError = new SKP_Sync_Error__c(Error_Code__c = error.code, Error_Description__c = error.message, Severity__c='Error' ,Case__c = skpCase.id, Sync_Validate__c = syncType);
            syncErrors.add(skpError);
            newSyncResults.add(skpError);
        }
        
        for(SKPResponse.CodeAndMessage warn : warnings){
            SKP_Sync_Error__c SKPWarning = new SKP_Sync_Error__c(Error_Code__c = warn.code, Error_Description__c = warn.message, Severity__c='Warning' ,Case__c = skpCase.id, Sync_Validate__c = syncType);
            syncWarnings.add(SKPWarning);
            newSyncResults.add(skpWarning);
        }
    }
    
    public void handleSKPUpdateContractResponse(SKPUpdateContractResponse response, Boolean validate)
    {
        if(response.updateContractResult.contractDetails != null 
           && response.updateContractResult.contractDetails.size() > 0 
           || response.updateContractResult.GeneralWarnings != null){
               integer size = response.updateContractResult.contractDetails.size();
               for(Integer i=0;i<size;i++){
                   List<SKP_Sync_Error__c> newSyncResults = new List<SKP_Sync_Error__c>();                        
                   if(response.updateContractResult.contractDetails[i].errors != null 
                      && !response.updateContractResult.contractDetails[i].errors.isEmpty() )  {
                          for(integer k=0;k<response.updateContractResult.contractDetails[i].errors.size();k++){                               
                              SKP_Sync_Error__c skpError = new SKP_Sync_Error__c(Error_Code__c = response.updateContractResult.contractDetails[i].errors[k].code, Error_Description__c = 'CustomerId:'+response.updateContractResult.contractDetails[i].customerId+'  '+response.updateContractResult.contractDetails[i].errors[k].message, Severity__c='Error' ,Case__c = skpCase.id, Sync_Validate__c = (validate) ? 'Validate' : 'Sync');
                              if(syncErrors.size()<999)
                              {                               
                                  syncErrors.add(skpError);
                                  newSyncResults.add(skpError);
                              }
                          }      
                      }                            
                   if(response.updateContractResult.contractDetails[i].warnings != null 
                      && !response.updateContractResult.contractDetails[i].warnings.isEmpty() )  {
                          for(integer j=0;j<response.updateContractResult.contractDetails[i].warnings.size();j++){   
                              String descStr = response.updateContractResult.contractDetails[i].warnings[j].message.length() > 230 ? response.updateContractResult.contractDetails[i].warnings[j].message.subString(0,229):response.updateContractResult.contractDetails[i].warnings[j].message;                                
                              SKP_Sync_Error__c SKPWarning = new SKP_Sync_Error__c(Error_Code__c = response.updateContractResult.contractDetails[i].warnings[j].code, Error_Description__c = 'CustomerId:'+response.updateContractResult.contractDetails[i].customerId+'  '+descStr, Severity__c='Warning' ,Case__c = skpCase.id, Sync_Validate__c = (validate) ? 'Validate' : 'Sync');
                              if(syncWarnings.size()<999)
                              {
                                  syncWarnings.add(SKPWarning);
                                  newSyncResults.add(skpWarning);  
                              }
                          }                                
                      }  
                   
                   if(response.updateContractResult.generalWarnings != null
                      && !response.updateContractResult.generalWarnings.isEmpty())  {
                          for(integer l=0;l<response.updateContractResult.generalWarnings.size();l++){                                
                              String descStr = response.updateContractResult.generalWarnings[l].message.length() > 255 ? response.updateContractResult.generalWarnings[l].message.subString(0,254):response.updateContractResult.generalWarnings[l].message;
                              SKP_Sync_Error__c SKPWarning = new SKP_Sync_Error__c(Error_Code__c = response.updateContractResult.generalWarnings[l].code, Error_Description__c = descStr, Severity__c='General Warning' ,Case__c = skpCase.id, Sync_Validate__c = (validate) ? 'Validate' : 'Sync');
                              if(syncWarnings.size()<999)
                              {
                                  syncWarnings.add(SKPWarning);
                                  newSyncResults.add(skpWarning); 
                              } 
                          }
                      }                        
               }
           }
        
    }
    
    public PageReference back(){
        return new PageReference('/' + skpCase.id);
    }
    
    public class ScheduleAWrapper{
        public Quote scheduleA {get;set;}
        public boolean isChecked {get;set;}
        
        public ScheduleAWrapper(Quote scheduleAParam){
            this.scheduleA = scheduleAParam;
            this.isChecked = false;
        }
    }
    
    public Case queryCase (id caseIdParam){
        List<Case> cases = SkpIntegrationHelper.getCases(caseIDParam);
        
        if(!cases.isEmpty()){
            return cases[0];
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, NO_CASE_FOUND));
            currentButton = Button.NONE;
            return null;
        }
    } 
    
    public void insertNewSyncErrors(boolean validate){
        List<SKP_Sync_Error__c> newSyncErrors = new List<SKP_Sync_Error__c>();
        string syncType = (validate) ? 'Validate' : 'Sync' ;
        
        boolean hasErrors = false;
        boolean hasWarnings = false;
        
        for( SKP_Sync_Error__c error : syncErrors){
            if(error.id == null){
                newSyncErrors.add(error);
                hasErrors = true;
            }
        }
        for( SKP_Sync_Error__c warning : syncWarnings){
            if(warning.id == null){
                newSyncErrors.add(warning);
                hasWarnings = true;
            }
        }
        
        SkpIntegrationHelper.insertObjects(newSyncErrors);
        
        String pageMessage = syncType + (hasErrors ? ' failed' : ' succeeded') + (hasErrors || !hasWarnings ? '.' : ' with warnings.'  );
        ApexPages.severity severity = hasErrors ? ApexPages.severity.Error : 
        (hasWarnings ? ApexPages.severity.Warning :  
         ApexPages.severity.Confirm);
             ApexPages.addMessage(new ApexPages.Message(severity, pageMessage));
        
        /*    if((syncErrors != null && syncErrors.size() > 999 ) 
|| syncWarnings != null && syncWarnings.size() > 999){
syncErrors.clear();
syncWarnings.clear();
} */
        
    }
    
    public PageReference validateSKPContract(){
        finalSecurityToken = SKPIntegrationHelper.checkOAuthSecurityToken(skpDetails.OAuth_EndPoint__c,skpDetails.Client_Id__c,skpDetails.Client_Secret__c);
        system.debug('#####'+finalSecurityToken);
        if(finalSecurityToken != null){
            PageReference ref ;
            if(contractType == 'Affiliate Option 1' || contractType == 'Affiliate Option 2'){       
                ref =  contractCallout_Affiliate(true);
            }else if(recordTypeName == 'NCSP Renewal'){       
                ref =  contractCallout_RenewalNRenego(true,1);
            }else{
                ref = contractCallout(true);
            }   
            insertNewSyncErrors(true);
            return ref;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'Security Token is NOT Valid !!!'));
            return null;
        }
    }
    
    
    public PageReference customerCallout_RenewalNRenego(boolean validate){
        string customerid;
        
        if(skpCase.Setup_Type__c =='Schedule A only'){
            return null;
        } 
        Http http = new Http();
        HTTPResponse customerResponse;
        SKPResponse skpCustomerResp;
        
        if(!hasSelectedScheduleA()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, SELECT_A_SCHEDULE_A));
            return null;
        }
        
        Set<String> custIdSet0 = new Set<String>();        
        for(Case_customer_account__c c: caseCustomerAccts){
            customerid = c.Customer_Account__r.Name;    
            customerJsonString = JSON.serialize(new SKPCustomerRenegotiation(skpCase, selectedScheduleA, validate, skpDetails.Username__c, customerIndicator,customerid));
            customerJsonString = customerJsonString.replaceAll('systemStringToBeReplaced', 'system');
            /*below changes is to not send some indicators if they are false */
            customerJsonString = customerJsonString.replaceAll('"faxtrieval":false,','');
            customerJsonString = customerJsonString.replaceAll(',"faxtrieval":false','');            
            customerJsonString = customerJsonString.replaceAll('"vault":false,','');
            customerJsonString = customerJsonString.replaceAll(',"vault":false','');             
            customerJsonString = customerJsonString.replaceAll('"efsService":false,','');
            customerJsonString = customerJsonString.replaceAll(',"efsService":false','');
            customerJsonString = customerJsonString.replaceAll('"activateHardCopy":false,','');
            customerJsonString = customerJsonString.replaceAll(',"activateHardCopy":false','');
            customerJsonString = customerJsonString.replaceAll('"shredding":null,','');
            
            //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
            //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            Blob headerValue = Blob.valueOf(skpDetails.Username__c);
            String authorizationHeader = EncodingUtil.base64Encode(headerValue);
            
            //HttpRequest customerRequest = SKPIntegrationHelper.buildRequest(skpDetails.Update_Customer_Info__c, authorizationHeader, customerJsonString);
            HttpRequest customerRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Update_Customer_Info__c,finalSecurityToken, authorizationHeader, customerJsonString);
            System.debug(LoggingLevel.INFO,'customerJsonString customerCallout_RenewalNRenego == '+customerJsonString);            
            System.debug('customerJsonString customerCallout_RenewalNRenego == '+customerJsonString);
            
            try{
                if(debugMode) {ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, customerJsonString));}
                
                customerResponse = http.send(customerRequest);
                calloutException = false;
                
                string customerResponseBody = customerResponse.getBody();
                system.debug('customerResponseBody customerCallout_RenewalNRenego=='+customerResponseBody);            
                
                skpCustomerResp  = (SKPResponse)JSON.deserialize(customerResponseBody, SKPResponse.class);
                
            } catch (CalloutException e){
                ApexPAges.addMessages(e);
                calloutException = true;
                return null;
            } 
            
            handleSKPResponse(skpCustomerResp, validate);
            
            if( syncErrors != null && (!syncErrors.isEmpty())){
                currentButton = Button.NONE;
                isPrevalidate = false;
                
            } else if( !validate ) {
                currentButton = Button.CREATECONTRACT ;
                isPrevalidate = false;
            }
        }        
        
        if((!validate) && !calloutException ){
            skpCase.SKP_Customer_Sync_Date__c = Datetime.now();
            SkpIntegrationHelper.upsertObjects(new List<Sobject>{skpCase});
        }         
        return null;
    } 
    
    public PageReference contractCallout_RenewalNRenego(boolean validate,Integer maxYears){
        
        Http http = new Http();
        HTTPResponse contractResponse;
        SKPUpdateContractResponse skpContractResp;
        HttpRequest contractRequest;
        HttpRequest recurringChargesRequest;
        Set<String> eridSet = new Set<String>();
        boolean isSuccess = true;
        
        system.debug('In contractCallout_RenewalNRenego');
        
        for(Case_customer_account__c c: caseCustomerAccts){
            if(c.Customer_Account__r.SKP_Exception_Rate_ID__c != null 
               && !''.equals(c.Customer_Account__r.SKP_Exception_Rate_ID__c))
                eridSet.add(c.Customer_Account__r.SKP_Exception_Rate_ID__c);
        }
        
        system.debug('eridSet=='+eridSet);  
        
        if(!hasSelectedScheduleA()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, SELECT_A_SCHEDULE_A));
            return null;
        }
        
        if (! hasContractMapping() ){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, NO_CONTRACT_MAPPING_FOUND));
            return null;
        }
        
        if(Test.isRunningTest() && maxYears>3)
        {
             SKPMultiYearSyncBatch multiYearSync = new SKPMultiYearSyncBatch(maxYears, eridSet, skpCase, selectedScheduleA, customerId, customerName);
            Id batchProcessId = Database.executeBatch(multiYearSync,1);
        }
         
        if(((eridSet.size()*maxYears)>10) && !validate)
        {
            system.debug('===');
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO,'You will be notified by email after the contract is synced.'));                                     
            SKPMultiYearSyncBatch multiYearSync = new SKPMultiYearSyncBatch(maxYears, eridSet, skpCase, selectedScheduleA, customerId, customerName);
            Id batchProcessId = Database.executeBatch(multiYearSync,1);
        }
        else
        {          
            
            //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
            //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            Blob headerValue = Blob.valueOf(skpDetails.Username__c);
            String authorizationHeader = EncodingUtil.base64Encode(headerValue);
            Integer initYear;
            
            if(skpCase.Sync_succeeded_till__c!= null)
                initYear= (skpCase.Sync_succeeded_till__c).intValue();
            else
                initYear = 1;
            
            for(Integer year=initYear;year<=maxYears;year++)   
            {
                for(String erid:eridSet){
                    try{    
                        Set<String> custIdSet = new Set<String>();
                        
                        for(Case_customer_account__c c: caseCustomerAccts){
                            if(c.Customer_Account__r.SKP_Exception_Rate_ID__c == erid)
                                custIdSet.add(c.Customer_Account__r.Name);
                        }            
                        
                        if(skpCase.Setup_Type__c =='Schedule A only') 
                        { 
                            contractJsonString = JSON.serialize(new SKPContractRenewal(skpCase, selectedScheduleA, contractMapping, customerindicator, validate, customerId, customerName, erid, custIdSet, year));                         
                        }
                        else
                        {
                            contractJsonString = JSON.serialize(new SKPContractRenegotiation(skpCase, selectedScheduleA, contractMapping, customerindicator, validate, customerId, customerName, erid, custIdSet, year));                         
                        }
                        contractJsonString = contractJsonString.replaceAll('systemStringToBeReplaced', 'system');
                        contractJsonString = contractJsonString.replaceAll('"effectiveDate":"ToBeRemoved",','');
                        contractJsonString = contractJsonString.replaceAll(',"effectiveDate":"ToBeRemoved"','');             
                        
                        if(debugMode) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, 'Request for Year '+year+':'+contractJsonString));
                        System.debug('contractJsonString =='+contractJsonString);
                        
                        //contractRequest = SKPIntegrationHelper.buildRequest(skpDetails.Update_Contract_Info__c, authorizationHeader, contractJsonString);
                        contractRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Update_Contract_Info__c,finalSecurityToken, authorizationHeader, contractJsonString);
                        contractResponse = http.send(contractRequest); 
                        String contractResponseBody = contractResponse.getBody() ;
                        
                        if(debugMode) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm,'Response for Year '+year+':'+ contractResponseBody));            
                        System.debug('contractResponseBody===='+contractResponseBody);
                        calloutException = false;                        
                        
                        
                        
                        skpContractResp  = (SKPUpdateContractResponse)JSON.deserialize(contractResponseBody, SKPUpdateContractResponse.class);
                        handleSKPUpdateContractResponse(skpContractResp,validate);
                        
                    } catch (CalloutException e){
                        isSuccess = false;
                        skpCase.Sync_succeeded_till__c=initYear;
                        ApexPAges.addMessages(e);
                        calloutException = true;
                        return null;
                    }
                }
                
            }
            
            
        }
        
        
        
        /*Need to comment - Below code is to find recurring charges
Once Contract Validation is successfully completed then Salesforce will fetch
the recurring charges for Recurring Products by calling SKP services*/
        if(!validate && syncErrors != null && syncErrors.isEmpty() 
           && (customerindicator != null && customerindicator.recurringChargesExists)
          ){
              Set<String> recList;
              List<QuoteLineItem> existingQlis = new List<QuoteLineItem>();
              List<QuoteLineItem> newQlis = new List<QuoteLineItem>(); 
              Set<String> skpOnlyWrapper = new Set<String>();
              Set<String> recurringCustIds = new Set<String>(); 
              
              
              if (caseCustomerAccts != null && caseCustomerAccts.size() > 0){
                  recList = new Set<String>();
                  for(Case_Customer_Account__c ca:caseCustomerAccts)
                  {   
                      recurringCustIds.add(ca.Customer_Account__r.Name);
                      processGetRecurringCharges(ca,'',recList);
                  }
              }
              //Find the new vs existing bill codes here
              /*    if(recList != null && recList.size() > 0){
Map<String,QuoteLineItem> SFDCLineItems = new Map<String,QuoteLineItem>();
for(QuoteLineItem qli1:selectedScheduleA.quoteLineItems){
if(recurringChargesDetailsMap.get(qli1.Product_Name__c) != null 
&& recurringChargesDetailsMap.get(qli1.Product_Name__c).ProductName__c.equals(qli1.Product_Name__c)){
SFDCLineItems.put(recurringChargesDetailsMap.get(qli1.Product_Name__c).BillCode__c,qli1); 
}     
}

for(String scw:recList){
if(SFDCLineItems.containskey(scw)) {
existingQlis.add(SFDCLineItems.get(scw));
SFDCLineItems.remove(scw);
} else{
skpOnlyWrapper.add(scw);
SFDCLineItems.remove(scw);
}  
}
if(SFDCLineItems != null && SFDCLineItems.size() > 0){
for(String str : SFDCLineItems.keySet()){
newQlis.add(SFDCLineItems.get(str));
}
}
}

if(newQlis != null && newQlis.size() > 0){
//build CreateRecurrningCharges
processRecurringCharges(recurringCustIds,newQlis,null,false);
}
if(existingQlis != null && existingQlis.size() > 0 || skpOnlyWrapper != null && skpOnlyWrapper.size() > 0){
//build UpdateRecurringCharges Request here -- Existing QLIs
processRecurringCharges(recurringCustIds,existingQlis,skpOnlyWrapper,true);
}*/
          } 
        
        
        if(!validate && syncErrors != null && syncErrors.isEmpty() && isSuccess){
            /* Setting the Customer Sync date same as contract sync date for Renewals on contract sync success 
*        as there is no customer sync for renewals */ 
            if(skpCase.Setup_Type__c =='Schedule A only'){
                skpCase.SKP_Customer_Sync_Date__c = Datetime.now();
            }
            skpCase.SKP_Contract_Sync_Date__c = Datetime.now();
            skpCase.SKP_Synced_ScheduleA__c= selectedScheduleA.Id;
            SkpIntegrationHelper.upsertObjects(new List<Sobject>{skpCase});
            
            if(custid.size() == 1){        
                updateSingleCust(customerAccounts);        
            }                            
        }              
        
        /* if(syncErrors != null && syncErrors.isEmpty())
{            
SkpIntegrationHelper.upsertObjects(new List<Sobject>{skpCase});
insertNewSyncErrors(false);
} */
        
        if( (validate) &&  syncErrors != null && syncErrors.isEmpty()){
            currentButton = (skpCase.SKP_Customer_Sync_Date__c != null 
                             || skpCase.Setup_Type__c =='Schedule A only') ? Button.CREATECONTRACT : Button.CREATECUSTOMER ;
            isPrevalidate = false;
        } else {
            currentButton = Button.NONE;
            isPrevalidate = false;
        }
        
        return null;
    } 
    
    public pageReference preValidateSKPCustomerAndContract(){
        finalSecurityToken = SKPIntegrationHelper.checkOAuthSecurityToken(skpDetails.OAuth_EndPoint__c,skpDetails.Client_Id__c,skpDetails.Client_Secret__c);
        system.debug('#####'+finalSecurityToken);
        if(finalSecurityToken != null){
            PageReference reference;
            List<IM_Customer_Account__c> imcToUpdate = new List<IM_Customer_Account__c>();
            
            if (caseCustomerAccts != null && caseCustomerAccts.size() == 0){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, NO_CUSTOMER_ACCOUNT_FOR_PREVALIDATION));
                return null;
            } 
            
            if (caseCustomerAccts != null && caseCustomerAccts.size() > 0){
                for(Case_Customer_Account__c ca:caseCustomerAccts)
                {   
                    IM_Customer_Account__c custIdToUpdate = [Select Id From IM_Customer_Account__c Where Id =: ca.Customer_Account__r.Id] ;
                    reference = processPreValidationCustomer(ca,custIdToUpdate);
                    reference = processPreValidationContract(ca,custIdToUpdate);
                }
            }    
            
            if(skpContractData != null && skpContractData.size() > 0){
                for(IM_Customer_Account__c imc: skpContractData.keySet()){
                    SKPPreValidationContractResponse tempresp = new SKPPreValidationContractResponse() ;
                    tempresp.contract = skpContractData.get(imc).contract;  
                    
                    if(tempresp.contract != null){ 
                        if(skpCustData != null && skpCustData.size() > 0 
                           && skpCustData.get(imc) != null && skpCustData.get(imc).customer != null){
                               SKPPreValidationResponse tempresp1 = new SKPPreValidationResponse() ;
                               tempresp1.customer = skpCustData.get(imc).customer;                         
                               imc.SKP_Hardcopy_Indicator__c = (tempresp1.customer.serviceIndicators.hardCopyEnabled) ? 'Y':'N';
                               imc.SKP_Shred_Indicator__c = (tempresp1.customer.serviceIndicators.shreddingServiceEnabled) ? 'Y':'N';
                           }                     
                        
                        imc.SKP_Customer_Name__c = tempresp.contract.customerName;  
                        imc.SKP_Admin_Fee__c = (tempresp.contract.contractDetails[0].rmAdminFeeEnabled) ? 'Y' : 'N';
                        imc.SKP_Contract_Link_Code__c = tempresp.contract.contractDetails[0].contractLink ;
                        imc.SKP_Billing_Cycle__c = tempresp.contract.contractDetails[0].billingCycle;
                        imc.SKP_Fuel_Surcharge__c = (tempresp.contract.contractDetails[0].fuelSurchargeEnabled)? 'Y':'N';    
                        imc.SKP_Container_Billing_Indicator__c = (tempresp.contract.contractDetails[0].containerBillingEnabled)? 'Y':'N';
                        imc.SKP_Exception_Rate_ID__c = tempresp.contract.contractDetails[0].exceptionRateId;
                        //imc.SKP_Last_Service_Date__c =  tempresp.contract.contractDetails[0].lastServiceIncrease;
                        //imc.SKP_Last_Storage_Date__c =  tempresp.contract.contractDetails[0].lastStorageIncrease; 
                        imcToUpdate.add(imc);   
                        isPrevalidate = false;   
                    }     
                }
            } else if(skpContractData == null && skpCustData != null && skpCustData.size() > 0){
                for(IM_Customer_Account__c imc: skpCustData.keySet()){
                    if(skpCustData.get(imc) != null && skpCustData.get(imc).customer != null){
                        SKPPreValidationResponse tempresp1 = new SKPPreValidationResponse() ;
                        tempresp1.customer = skpCustData.get(imc).customer;                         
                        imc.SKP_Hardcopy_Indicator__c = (tempresp1.customer.serviceIndicators.hardCopyEnabled) ? 'Y':'N';
                        imc.SKP_Shred_Indicator__c = (tempresp1.customer.serviceIndicators.shreddingServiceEnabled) ? 'Y':'N';
                        imcToUpdate.add(imc);  
                    } 
                } 
            }                
            
            if(imcToUpdate != null && imcToUpdate.size() > 0){
                update imcToUpdate;     
                this.customerAccounts  =[Select Id,Name,SKP_Customer_Name__c,SKP_Contract_Link_Code__c,SKP_Admin_Fee__c,SKP_Fuel_Surcharge__c,SKP_Hardcopy_Indicator__c,SKP_Shred_Indicator__c,SKP_Billing_Cycle__c,SKP_Container_Billing_Indicator__c,SKP_Exception_Rate_ID__c,Renewal_ERID__c  From IM_Customer_Account__c Where Id =: custid];
            }            
            
            return reference;
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'Security Token is NOT Valid !!!'));
            return null;
        }
    }
    
    public PageReference processPreValidationCustomer(Case_Customer_Account__c custAcct,IM_Customer_Account__c custIdToUpdate){
        
        Http http = new Http();
        HTTPResponse customerResponse;
        SKPPreValidationResponse skpCustomerResp;
        
        customerJsonString = JSON.serialize(new SKPPreValidation(skpCase, selectedScheduleA,skpDetails.Username__c, customerIndicator,custAcct.Customer_Account__r.Name));
        customerJsonString = customerJsonString.replaceAll('systemStringToBeReplaced', 'system');
        
        //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
        //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);    
        Blob headerValue = Blob.valueOf(skpDetails.Username__c);
        String authorizationHeader = EncodingUtil.base64Encode(headerValue);
        
        //HttpRequest customerRequest = SKPIntegrationHelper.buildRequest(skpDetails.Get_Customer_Profile__c, authorizationHeader, customerJsonString);
        HttpRequest customerRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Get_Customer_Profile__c,finalSecurityToken, authorizationHeader, customerJsonString);
        
        try{
            if(debugMode) {ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, customerJsonString));}
            
            customerResponse = http.send(customerRequest);
            
            calloutException = false;
            string customerResponseBody = customerResponse.getBody();
            if(debugMode) {ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, customerResponseBody));}
            
            skpCustomerResp  = (SKPPreValidationResponse)JSON.deserialize(customerResponseBody, SKPPreValidationResponse.class);
            
            if(skpCustomerResp != null && skpCustomerResp.customer != null ){
                skpCustData.put(custIdToUpdate,skpCustomerResp);
            }
        } catch (CalloutException e){
            ApexPAges.addMessages(e);
            calloutException = true;
            return null;
        } 
        
        handleSKPCustResponse_PreVal(skpCustomerResp);
        return null;
    }
    
    public PageReference processPreValidationContract(Case_Customer_Account__c custAcct,IM_Customer_Account__c custIdToUpdate){
        Http http = new Http();
        HTTPResponse contractResponse;
        SKPPreValidationContractResponse skpContractResp;
        String contractJsonString;
        
        contractJsonString = JSON.serialize(new SKPPreValidationContract(skpCase,custAcct.Customer_Account__r.Name));
        contractJsonString = contractJsonString.replaceAll('systemStringToBeReplaced', 'system');
        
        //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
        //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        Blob headerValue = Blob.valueOf(skpDetails.Username__c);
        String authorizationHeader = EncodingUtil.base64Encode(headerValue);
        
        //HttpRequest contractRequest = SKPIntegrationHelper.buildRequest(skpDetails.Get_Contract_Info__c, authorizationHeader, contractJsonString);
        HttpRequest contractRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Get_Contract_Info__c,finalSecurityToken, authorizationHeader, contractJsonString);
        
        try{
            if(debugMode) {ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, contractJsonString));}
            
            contractResponse = http.send(contractRequest);
            calloutException = false;
            
            string contractResponseBody = contractResponse.getBody();
            skpContractResp  = (SKPPreValidationContractResponse)JSON.deserialize(contractResponseBody, SKPPreValidationContractResponse.class);
            
            if(skpContractResp != null && skpContractResp.contract != null 
               && skpContractResp.contract.contractDetails != null ){
                   skpContractData.put(custIdToUpdate,skpContractResp);                   
               }
            
        } catch (CalloutException e){
            ApexPAges.addMessages(e);
            calloutException = true;
            return null;
        } 
        
        handleSKPContractResponse_PreVal(skpContractResp);
        return null;
    } 
    
    public void handleSKPCustResponse_PreVal(SKPPreValidationResponse response){
        
        string syncType = 'Pre Validate Customer' ;
        
        List<SKPPreValidationResponse.CodeAndMessage> errors = new List<SKPPreValidationResponse.CodeAndMessage>();
        List<SKPPreValidationResponse.CodeAndMessage> warnings = new List<SKPPreValidationResponse.CodeAndMessage>();
        if(response.errors != null){
            errors.addAll(response.errors);
        }
        if(response.warnings != null){
            warnings.addAll(response.warnings);
        }
        
        boolean hasErrors = !(errors.isEmpty());
        boolean hasWarnings = !(warnings.isEmpty());
        
        List<SKP_Sync_Error__c> newSyncResults = new List<SKP_Sync_Error__c>();
        
        for(SKPPreValidationResponse.CodeAndMessage error : errors){
            SKP_Sync_Error__c skpError = new SKP_Sync_Error__c(Error_Code__c = error.code, Error_Description__c = error.message, Severity__c='Error' ,Case__c = skpCase.id, Sync_Validate__c = syncType);
            syncErrors.add(skpError);
            newSyncResults.add(skpError);
        }
        
        for(SKPPreValidationResponse.CodeAndMessage warn : warnings){
            SKP_Sync_Error__c SKPWarning = new SKP_Sync_Error__c(Error_Code__c = warn.code, Error_Description__c = warn.message, Severity__c='Warning' ,Case__c = skpCase.id, Sync_Validate__c = syncType);
            syncWarnings.add(SKPWarning);
            newSyncResults.add(skpWarning);
        }
    }
    
    public void handleSKPContractResponse_PreVal(SKPPreValidationContractResponse response){
        
        string syncType = 'Pre Validate Contract' ;
        
        List<SKPPreValidationContractResponse.CodeAndMessage> errors = new List<SKPPreValidationContractResponse.CodeAndMessage>();
        List<SKPPreValidationContractResponse.CodeAndMessage> warnings = new List<SKPPreValidationContractResponse.CodeAndMessage>();
        if(response.errors != null){
            errors.addAll(response.errors);
        }
        if(response.warnings != null){
            warnings.addAll(response.warnings);
        }
        
        boolean hasErrors = !(errors.isEmpty());
        boolean hasWarnings = !(warnings.isEmpty());
        
        List<SKP_Sync_Error__c> newSyncResults = new List<SKP_Sync_Error__c>();
        
        for(SKPPreValidationContractResponse.CodeAndMessage error : errors){
            SKP_Sync_Error__c skpError = new SKP_Sync_Error__c(Error_Code__c = error.code, Error_Description__c = error.message, Severity__c='Error' ,Case__c = skpCase.id, Sync_Validate__c = syncType);
            syncErrors.add(skpError);
            newSyncResults.add(skpError);
        }
        
        for(SKPPreValidationContractResponse.CodeAndMessage warn : warnings){
            SKP_Sync_Error__c SKPWarning = new SKP_Sync_Error__c(Error_Code__c = warn.code, Error_Description__c = warn.message, Severity__c='Warning' ,Case__c = skpCase.id, Sync_Validate__c = syncType);
            syncWarnings.add(SKPWarning);
            newSyncResults.add(skpWarning);
        }
    }
    
    public void processGetRecurringCharges(Case_Customer_Account__c custAcct,String newDealCustId,Set<String> recList){
        
        Http http = new Http();
        HTTPResponse getRecurrChargesResponse;
        SKPGetRecurringChargesResponse getReccuringResp;
        String recurringJsonString;
        String recurringResponseBody;  
        if(newDealCustId != null && !newDealCustId.equals(''))
            recurringJsonString = JSON.serialize(new SKPGetRecurringChargesRequest(skpCase, selectedScheduleA,skpDetails.Username__c, customerIndicator,newDealCustId));
        else
            recurringJsonString = JSON.serialize(new SKPGetRecurringChargesRequest(skpCase, selectedScheduleA,skpDetails.Username__c, customerIndicator,custAcct.Customer_Account__r.Name));
        recurringJsonString = recurringJsonString.replaceAll('systemStringToBeReplaced', 'system');
        
        //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
        //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);    
        Blob headerValue = Blob.valueOf(skpDetails.Username__c);
        String authorizationHeader = EncodingUtil.base64Encode(headerValue);
        //HttpRequest customerRequest = SKPIntegrationHelper.buildRequest(skpDetails.Get_Recurring_Charges__c, authorizationHeader, recurringJsonString);
        HttpRequest customerRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Get_Recurring_Charges__c,finalSecurityToken, authorizationHeader, recurringJsonString);
        
        try{
            if(debugMode) {ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, recurringJsonString));}
            
            getRecurrChargesResponse = http.send(customerRequest);
            
            calloutException = false;
            recurringResponseBody = getRecurrChargesResponse.getBody();
            if(debugMode) {ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, recurringResponseBody));}
            
            getReccuringResp  = (SKPGetRecurringChargesResponse)JSON.deserialize(recurringResponseBody, SKPGetRecurringChargesResponse.class);
            if(getReccuringResp.recurringCharges != null
               && !getReccuringResp.recurringCharges.isEmpty())  {
                   for(integer l=0;l<getReccuringResp.recurringCharges.size();l++){                                
                       recList.add(getReccuringResp.recurringCharges[l].billCode);
                   }
               } 
            System.debug('Recurring charges List=='+recList);
            
            Set<String> recurringCustIds = new Set<String>();
            recurringCustIds.add(custAcct.Customer_Account__r.Name);
            List<QuoteLineItem> existingQlis = new List<QuoteLineItem>();
            List<QuoteLineItem> newQlis = new List<QuoteLineItem>(); 
            Set<String> skpOnlyWrapper = new Set<String>();
            if(recList != null && recList.size() > 0 || (getReccuringResp != null && getReccuringResp.count == 0)){
                Map<String,QuoteLineItem> SFDCLineItems = new Map<String,QuoteLineItem>();
                for(QuoteLineItem qli1:selectedScheduleA.quoteLineItems){
                    if(recurringChargesDetailsMap.get(qli1.Product_Name__c) != null 
                       && (recurringChargesDetailsMap.get(qli1.Product_Name__c).ProductName__c.equals(qli1.Product_Name__c)
                           || recurringChargesDetailsMap.get(qli1.Product_Name__c).BillCode__c.equals(qli1.Product_Name__c))){
                               SFDCLineItems.put(recurringChargesDetailsMap.get(qli1.Product_Name__c).BillCode__c,qli1); 
                           }     
                }
                
                for(String scw:recList){
                    if(SFDCLineItems.containskey(scw)) {
                        existingQlis.add(SFDCLineItems.get(scw));
                        SFDCLineItems.remove(scw);
                    } else{
                        skpOnlyWrapper.add(scw);
                        SFDCLineItems.remove(scw);
                    }  
                }
                if(SFDCLineItems != null && SFDCLineItems.size() > 0){
                    for(String str : SFDCLineItems.keySet()){
                        newQlis.add(SFDCLineItems.get(str));
                    }
                    SFDCLineItems.clear();
                }
            }
            
            if(newQlis != null && newQlis.size() > 0){
                //build CreateRecurrningCharges
                processRecurringCharges(recurringCustIds,newQlis,null,false);
            }
            if(existingQlis != null && existingQlis.size() > 0 || skpOnlyWrapper != null && skpOnlyWrapper.size() > 0){
                //build UpdateRecurringCharges Request here -- Existing QLIs
                System.debug(LoggingLevel.Info,'existingQlis coming here==='+existingQlis);
                System.debug(LoggingLevel.Info,'skpOnlyWrapper coming here==='+skpOnlyWrapper); 
                /*skpOnlyWrapper.clear() is added becuase now business dont want 
skponly billcode to be sent to SKP*/                  
                if(skpOnlyWrapper != null)
                    skpOnlyWrapper.clear(); 
                System.debug(LoggingLevel.Info,'skpOnlyWrapper coming here after clearing==='+skpOnlyWrapper);                   
                processRecurringCharges(recurringCustIds,existingQlis,skpOnlyWrapper,true);
                if(existingQlis != null)
                    existingQlis.clear();
            }
            
        } catch (CalloutException e){
            ApexPAges.addMessages(e);
            calloutException = true;
            recurringCalloutException = true;
        } 
        
        handleSKPContractResponse_RecurringCharges(recurringResponseBody);
    }
    
    public PageReference processRecurringCharges(Set<String> custIdSet,List<QuoteLineItem> qlis,Set<String> skpOnlyWrapper, boolean updateRecurring){
        
        Http http = new Http();
        HTTPResponse recurringResponse;
        SKPResponse skpRecurringResp;
        String recurringJSONString;
        HttpRequest recurringRequest;
        String recurringResponseBody;
        //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
        //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        Blob headerValue = Blob.valueOf(skpDetails.Username__c);
        String authorizationHeader = EncodingUtil.base64Encode(headerValue);
        
        
        if(updateRecurring){
            if(skpOnlyWrapper != null && skpOnlyWrapper.size() > 0 || qlis != null && qlis.size() > 0){   
                recurringJSONString = JSON.serialize(new SKPUpdateRecurringCharges(skpCase,selectedScheduleA,recurringChargesDetailsMap,custIdSet,qlis,skpOnlyWrapper)); 
            }
            
            recurringJSONString = recurringJSONString.replaceAll('systemStringToBeReplaced', 'system'); 
            recurringJSONString = recurringJSONString.replaceAll('"startDate":"TOBEREMOVED",', '');   
            recurringJSONString = recurringJSONString.replaceAll('"startDate":"TOBEREMOVED"', '');   
            recurringJSONString = recurringJSONString.replaceAll('"endDate":"TOBEREMOVED",', '');   
            recurringJSONString = recurringJSONString.replaceAll('"enddate":"TOBEREMOVED"', '');             
            recurringJSONString = recurringJSONString.replaceAll('"startDate":"RECCTOBEREMOVED",', '');   
            recurringJSONString = recurringJSONString.replaceAll('"startDate":"RECCTOBEREMOVED"', '');             
            recurringJSONString = recurringJSONString.replaceAll('"billingCycle":"RECCTOBEREMOVED",', '');   
            recurringJSONString = recurringJSONString.replaceAll('"billingCycle":"RECCTOBEREMOVED"', '');             
            recurringJSONString = recurringJSONString.replaceAll('"quantity":"RECCTOBEREMOVED",', '');   
            recurringJSONString = recurringJSONString.replaceAll('"quantity":"RECCTOBEREMOVED"', '');             
            recurringJSONString = recurringJSONString.replaceAll('"rate":"RECCTOBEREMOVED",', '');   
            recurringJSONString = recurringJSONString.replaceAll('"rate":"RECCTOBEREMOVED"', '');             
            recurringJSONString = recurringJSONString.replaceAll('"uom":"RECCTOBEREMOVED",', '');   
            recurringJSONString = recurringJSONString.replaceAll('"uom":"RECCTOBEREMOVED"', '');             
            recurringJSONString = recurringJSONString.replaceAll('"districtId":"RECCTOBEREMOVED",', '');   
            recurringJSONString = recurringJSONString.replaceAll('"districtId":"RECCTOBEREMOVED"', '');             
            
            
            //recurringRequest = SKPIntegrationHelper.buildRequest(skpDetails.Update_Recurring_Charges__c, authorizationHeader, recurringJSONString);
            recurringRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Update_Recurring_Charges__c,finalSecurityToken, authorizationHeader, recurringJSONString);
        }else{
            System.debug('custIdSet==='+custIdSet);   
            recurringJSONString = JSON.serialize(new SKPCreateRecurringCharges(skpCase,selectedScheduleA,recurringChargesDetailsMap,custIdSet,qlis));            
            recurringJSONString = recurringJSONString.replaceAll('systemStringToBeReplaced', 'system');            
            //recurringRequest = SKPIntegrationHelper.buildRequest(skpDetails.Create_Recurring_Charges__c, authorizationHeader, recurringJSONString);
            recurringRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Create_Recurring_Charges__c,finalSecurityToken, authorizationHeader, recurringJSONString);
        }
        
        try{
            if(debugMode) {ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, 'Update/Create message ='+recurringJSONString));}
            
            recurringResponse = http.send(recurringRequest);
            
            calloutException = false;
            recurringResponseBody = recurringResponse.getBody();
            System.debug(LoggingLevel.Info,'Recurring Response=='+recurringResponseBody);
            if(debugMode) {ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Confirm, recurringResponseBody));}
            
        } catch (CalloutException e){
            ApexPAges.addMessages(e);
            recurringCalloutException = true;
            return null;
        } 
        if(recurringResponseBody != null && recurringResponseBody.length() > 0)
            handleSKPContractResponse_RecurringCharges(recurringResponseBody);
        return null;
    } 
    
    public void handleSKPContractResponse_RecurringCharges(String responseData){
        String syncType;
        if(responseData.contains('updateRecurringChargeResult'))
            syncType = 'UpdateRecurringCharges';
        else if(responseData.contains('createRecurringChargeResult'))
            syncType = 'CreateRecurringCharges';
        else         
            syncType = 'GetRecurringCharges';
        
        List<SKP_Sync_Error__c> newSyncResults = new List<SKP_Sync_Error__c>();
        
        JSONParser parser = JSON.createParser(responseData);
        String errorCode;
        String errorMessage;
        String warningCode;
        String warningMessage;        
        boolean isError=true;
        String severity='Error';
        while (parser.nextToken()!= null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                String fieldName = parser.getText();
                parser.nextToken();
                if(fieldName == 'errors' || fieldName == 'warnings') {
                    if(fieldName == 'warnings'){isError=false;}
                    if(fieldName == 'errors'){isError=true;}
                    parser.nextToken();
                    while (parser.nextToken()!= null)
                    { 
                        if ((parser.getCurrentToken() == JSONToken.FIELD_NAME)){
                            String currentField = parser.getText();                            
                            if (currentField == 'warnings')isError=false;
                            if (currentField == 'errors')isError=true;                            
                            parser.nextToken();
                            
                            if(currentField == 'code') {  
                                errorCode = parser.getText();
                            } 
                            if(currentField == 'message') {
                                errorMessage = parser.getText();
                            } 
                            
                            if(errorCode!=null && errorMessage!=null)
                            {
                                if(isError)
                                {                               
                                    severity = 'Error'; 
                                    SKP_Sync_Error__c skpError = new SKP_Sync_Error__c(Error_Code__c = errorCode, Error_Description__c = errorMessage, Severity__c=severity ,Case__c = skpCase.id, Sync_Validate__c = syncType);
                                    syncErrors.add(skpError);
                                    newSyncResults.add(skpError);
                                    recurringCalloutException = true;
                                }
                                else
                                {
                                    severity = 'Warning'; 
                                    SKP_Sync_Error__c skpWarning = new SKP_Sync_Error__c(Error_Code__c = errorCode, Error_Description__c = errorMessage, Severity__c=severity ,Case__c = skpCase.id, Sync_Validate__c = syncType);
                                    syncWarnings.add(skpWarning);
                                    newSyncResults.add(skpWarning);  
                                }     
                                errorCode=null;
                                errorMessage=null;          
                            }
                        }
                    }                    
                }
            }
        }        
        
    }      
}