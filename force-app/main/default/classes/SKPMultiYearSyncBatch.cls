global class SKPMultiYearSyncBatch implements Database.Batchable<String>, Database.Stateful,Database.AllowsCallouts{
    
    public List<Case_Customer_Account__c> caseCustomerAccts {get;set;}
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
    public Case skpCase;
    public Quote selectedScheduleA {get;set;}
    //public List<String> erids {get;set;}
    public SKP_Contract_Type_Mapping__c contractMapping;
    public SkpIntegrationHelper.CustomerIndicator customerIndicator;
    public String customerID;
    public String customerName;
    public Integer maxYears;
    public Set<String> eridSet;
    public List<SKP_Sync_Error__c> syncErrors = new List<SKP_Sync_Error__c>(); 
    public List<SKP_Sync_Error__c> syncWarnings = new List<SKP_Sync_Error__c>();
    
    public static string finalSecurityToken;
    public SKPMultiYearSyncBatch (Integer years, Set<String> erids, Case caseDets,Quote quoteDet,string custId,string custName)
    {
        maxYears=years;
        skpCase = caseDets;
        eridSet=erids;
        selectedScheduleA = quoteDet;        
        customerID=custId;
        customerName=custName;
        
        caseCustomerAccts = SKPIntegrationHelper.fetchCaseCustomerAccts(skpCase);
        List<SKP_Contract_Type_Mapping__c> contractMappings = SkpIntegrationHelper.getMappings(skpCase.contract_type__c);
        system.debug('contractMappings ==='+contractMappings );
        contractMapping = (contractMappings != null && contractMappings.size() == 1) ? contractMappings[0] : null ;
        customerIndicator = new SkpIntegrationHelper.customerIndicator(selectedScheduleA.quoteLineItems, skpCase.contract_type__c);
        
        system.debug('maxYears='+maxYears);
        system.debug('skpCase ='+skpCase );
        system.debug('eridSet='+eridSet);
        system.debug('selectedScheduleA ='+selectedScheduleA );
        system.debug('customerID='+customerID);
        system.debug('customerName='+customerName);
        system.debug('caseCustomerAccts ='+caseCustomerAccts );
        system.debug('contractMapping ='+contractMapping );
        system.debug('customerIndicator ='+customerIndicator );
        
    }
    
    global Iterable<String> start(Database.BatchableContext BC)
    {
        List<String> erids = new List<String> {};
        
        system.debug('eridSet='+eridSet);
        for(String erid:eridSet)
        {
            system.debug('erid='+erid);
            erids.add(erid);
        }
        system.debug('erids====='+erids);
        return erids;   
    }
    
    global void execute(Database.BatchableContext BC, List<String> scope)
    {
        finalSecurityToken = B2B_IntegrationHelper.checkOAuthSecurityToken(skpDetails.OAuth_EndPoint__c,skpDetails.Client_Id__c,skpDetails.Client_Secret__c);
        system.debug('#####'+finalSecurityToken);
        if(finalSecurityToken != null){
            String erid=scope[0];
            Http http = new Http();
            HTTPResponse contractResponse;
            SKPUpdateContractResponse skpContractResp;
            HttpRequest contractRequest;
            string contractJsonString;
            //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
            //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            Blob headerValue = Blob.valueOf(skpDetails.Username__c);
            String authorizationHeader = EncodingUtil.base64Encode(headerValue);
            
            for(Integer year=1;year<=maxYears;year++)   
            {
                try{    
                    Set<String> custIdSet = new Set<String>();                
                    for(Case_customer_account__c c: caseCustomerAccts)
                    {
                        if(c.Customer_Account__r.SKP_Exception_Rate_ID__c == erid)
                        custIdSet.add(c.Customer_Account__r.Name);
                    }            
                    
                    if(skpCase.Setup_Type__c =='Schedule A only') 
                    { 
                        contractJsonString = JSON.serialize(new SKPContractRenewal(skpCase, selectedScheduleA, contractMapping, customerindicator, false, customerId, customerName, erid, custIdSet, year));                         
                    }
                    else
                    {
                        contractJsonString = JSON.serialize(new SKPContractRenegotiation(skpCase, selectedScheduleA, contractMapping, customerindicator, false, customerId, customerName, erid, custIdSet, year));                         
                    }
                    contractJsonString = contractJsonString.replaceAll('systemStringToBeReplaced', 'system');
                    contractJsonString = contractJsonString.replaceAll('"effectiveDate":"ToBeRemoved",','');
                    contractJsonString = contractJsonString.replaceAll(',"effectiveDate":"ToBeRemoved"','');             
                    
                    System.debug('contractJsonString =='+contractJsonString);
                    
                    //contractRequest = SKPIntegrationHelper.buildRequest(skpDetails.Update_Contract_Info__c, authorizationHeader, contractJsonString);
                    contractRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Update_Contract_Info__c, finalSecurityToken, authorizationHeader, contractJsonString);
                    contractResponse = http.send(contractRequest); 
                    String contractResponseBody = contractResponse.getBody() ;
                    
                    System.debug('contractResponseBody===='+contractResponseBody);
                    
                    skpContractResp  = (SKPUpdateContractResponse)JSON.deserialize(contractResponseBody, SKPUpdateContractResponse.class);
                    
                    handleSKPUpdateContractResponse(skpContractResp);
                   
                } catch (CalloutException e)
                {  
                    system.debug('Exception caught'+e);
                }
            }
        }else{
            system.debug('Security Token is NOT Valid !!!');
        }
    }
    
    public void handleSKPUpdateContractResponse(SKPUpdateContractResponse response)
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
                              String descStr = response.updateContractResult.contractDetails[i].errors[k].message.length() > 230 ? response.updateContractResult.contractDetails[i].errors[k].message.subString(0,229):response.updateContractResult.contractDetails[i].errors[k].message;                                
                              SKP_Sync_Error__c skpError = new SKP_Sync_Error__c(Error_Code__c = response.updateContractResult.contractDetails[i].errors[k].code, Error_Description__c = 'CustomerId:'+response.updateContractResult.contractDetails[i].customerId+'  '+response.updateContractResult.contractDetails[i].errors[k].message, Severity__c='Error' ,Case__c = skpCase.id, Sync_Validate__c = 'Sync');                              
                              //system.debug('skpError=='+skpError);
                              syncErrors.add(skpError);
                          }      
                      }                            
                   if(response.updateContractResult.contractDetails[i].warnings != null 
                      && !response.updateContractResult.contractDetails[i].warnings.isEmpty() )  {
                          for(integer j=0;j<response.updateContractResult.contractDetails[i].warnings.size();j++){   
                              String descStr = response.updateContractResult.contractDetails[i].warnings[j].message.length() > 230 ? response.updateContractResult.contractDetails[i].warnings[j].message.subString(0,229):response.updateContractResult.contractDetails[i].warnings[j].message;                                
                              SKP_Sync_Error__c SKPWarning = new SKP_Sync_Error__c(Error_Code__c = response.updateContractResult.contractDetails[i].warnings[j].code, Error_Description__c = 'CustomerId:'+response.updateContractResult.contractDetails[i].customerId+'  '+descStr, Severity__c='Warning' ,Case__c = skpCase.id, Sync_Validate__c = 'Sync');
                              //system.debug('SKPWarning=='+SKPWarning);
                              syncWarnings.add(SKPWarning);
                          }                                
                      }  
                   
                   if(response.updateContractResult.generalWarnings != null
                      && !response.updateContractResult.generalWarnings.isEmpty())  {
                          for(integer l=0;l<response.updateContractResult.generalWarnings.size();l++){                                
                              String descStr = response.updateContractResult.generalWarnings[l].message.length() > 255 ? response.updateContractResult.generalWarnings[l].message.subString(0,254):response.updateContractResult.generalWarnings[l].message;
                              SKP_Sync_Error__c SKPWarning = new SKP_Sync_Error__c(Error_Code__c = response.updateContractResult.generalWarnings[l].code, Error_Description__c = descStr, Severity__c='General Warning' ,Case__c = skpCase.id, Sync_Validate__c = 'Sync');
                              //system.debug('SKPWarning=='+SKPWarning);
                              syncWarnings.add(SKPWarning);
                          }
                      }                        
               }
           }        
    }
    
    global void finish(Database.BatchableContext BC)
    {
        
         if(syncErrors != null && syncErrors.isEmpty())
         {
            /* Setting the Customer Sync date same as contract sync date for Renewals on contract sync success 
             * as there is no customer sync for renewals */ 
            if(skpCase.Setup_Type__c =='Schedule A only')
            {
                skpCase.SKP_Customer_Sync_Date__c = Datetime.now();
            }
            skpCase.SKP_Contract_Sync_Date__c = Datetime.now();
            skpCase.SKP_Synced_ScheduleA__c= selectedScheduleA.Id;
            SkpIntegrationHelper.upsertObjects(new List<Sobject>{skpCase});                                         
         }  
         
         if(syncWarnings.size()>0) insert syncWarnings;
         if(syncErrors.size()>0) insert syncErrors;
         
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, CreatedBy.Email FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Multiyear Contract Sync :' + a.Status);
        mail.setPlainTextBody('Multiyear Contract sync is processed with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }    
}