global class SKPRateUploadNotificationBatch implements Database.Batchable<sObject>, Database.Stateful,Database.AllowsCallouts{
    public boolean runningInASandbox;
    SKP_Integration_Details__c skpDetails;
    public SkpIntegrationHelper.CustomerIndicator customerIndicator;
    Map<id,Quote> scheduleAs;
    public List<SKP_Sync_Error__c> syncErrors; 
    public List<SKP_Sync_Error__c> syncWarnings;
    
    public static string finalSecurityToken;
    public SKPRateUploadNotificationBatch(){
        runningInASandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
        
        string sandboxType = runningInASandbox ? 'Sandbox' : 'Production' ;
        if(Test.isRunningTest()){sandboxType ='SandboxTest';}
        skpDetails = SKP_Integration_Details__c.getInstance(sandboxType);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        System.debug('In Start method');
        syncErrors = new List<SKP_Sync_Error__c>(); 
        syncWarnings = new List<SKP_Sync_Error__c>(); 
        String query ='';
        query = 'Select Id,CaseNumber,Setup_Type__c,NCSP_Opportunity__c,contract_type__c,RecordType_Name__c,SKP_Synced_ScheduleA__c From Case Where NCSP_Opportunity__c IN (SELECT OpportunityID FROM Quote Where Effective_Date__c = TODAY) AND Recordtype.Name = \'NCSP Renewal\' AND Contract_Status__c = \'Accepted\' AND Sync_To_SKP__c = \'This Contract has already been Synced\'';
        if(Test.isRunningTest()){           
            //query = 'Select Id,CaseNumber,Setup_Type__c,NCSP_Opportunity__c,contract_type__c,RecordType_Name__c,SKP_Synced_ScheduleA__c From Case where Recordtype.Name = \'NCSP Renewal\' AND Contract_Status__c = \'Accepted\' AND Sync_To_SKP__c = \'This Contract has already been Synced\' limit 20';
            query = query + 'limit 2';
        } 
        
        //String query = 'Select Id,Setup_Type__c,NCSP_Opportunity__c,contract_type__c,RecordType_Name__c,SKP_Synced_ScheduleA__c From Case Where NCSP_Opportunity__c IN (SELECT OpportunityID FROM Quote Where Effective_Date__c = TODAY) AND Recordtype.Name = \'NCSP Renewal\' AND Contract_Status__c = \'Accepted\' AND Setup_Type__c = \'Contract and Schedule A\'';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Case> scope)
    {
        finalSecurityToken = B2B_IntegrationHelper.checkOAuthSecurityToken(skpDetails.OAuth_EndPoint__c,skpDetails.Client_Id__c,skpDetails.Client_Secret__c);
        system.debug('#####'+finalSecurityToken);
        if(finalSecurityToken != null){
            System.debug('Scope===='+scope.size());
    
            List<Case> objcase= new List<Case>();
            List<Case_Customer_Account__c> caseCustomerAccts = [select Id,Case__c,Customer_Account__r.SKP_Exception_Rate_ID__c,Customer_Account__r.Renewal_ERID__c,Customer_Account__r.Name from Case_Customer_Account__c where Case__c IN :scope];
            
            Set<String> custIdSet = new Set<String>();
            Map<String,Set<String>> eridCustidMap = new Map<String,Set<String>>();
            List<Id> NCSPOppList = new List<Id>();
            for(Case cs:scope){
              if(cs.RecordType_Name__c == 'NCSP Renewal')  
                NCSPOppList.add(cs.NCSP_Opportunity__c);
            }
            scheduleAs = new Map<id,Quote>([Select Id,(Select Bill_Code_Classification__c, Unit_of_Measure__c, UnitPrice, Product_Number__c, Product_Name__c From QuoteLineItems) from Quote where OpportunityId IN : NCSPOppList]);
            for(Case cs : scope)
            {
                for(Case_customer_account__c c: caseCustomerAccts){
                    if(cs.Id == c.Case__c){
                        custIdSet.add(c.Customer_Account__r.Name);
                    }    
                }
                for(Case_customer_account__c c: caseCustomerAccts){
                    if(cs.Id == c.Case__c && c.Customer_Account__r.Renewal_ERID__c == true){
                        eridCustidMap.put(c.Customer_Account__r.SKP_Exception_Rate_ID__c,custIdSet);
                    }  
                }
    
                processRenewalsAndRenegotiation(cs,eridCustidMap);
            }
            
            insertNewSyncErrors();
        }else{
            system.debug('Security Token is NOT Valid !!!');
        }
    }
    
    public void processRenewalsAndRenegotiation(Case skpCase,Map<String,Set<String>> eridCustidMap){
        Http http = new Http();
        HTTPResponse contractResponse;
        SKPUpdateContractResponse skpContractResp;
        HttpRequest contractRequest;
        //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
        //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        Blob headerValue = Blob.valueOf(skpDetails.Username__c);
        String authorizationHeader = EncodingUtil.base64Encode(headerValue);
        String contractJsonString;
        SKP_Contract_Type_Mapping__c contractMapping;
    

        for(String erid:eridCustidMap.keySet()){
            System.debug('Processing for Erid=='+erid);
           // try{    
                if(skpCase.Setup_Type__c =='Schedule A only')  
                    contractJsonString = JSON.serialize(new SKPContractRenewalBatchRequest(erid,eridCustidMap.get(erid),false));
                else{
                    List<SKP_Contract_Type_Mapping__c> contractMappings = SkpIntegrationHelper.getMappings(skpCase.contract_type__c);
                    if(contractMappings != null && contractMappings.size() == 1){
                      contractMapping = contractMappings[0];  
                    } 
                    
                        customerIndicator = new SkpIntegrationHelper.customerIndicator(scheduleAs.get(skpCase.SKP_Synced_ScheduleA__c).quoteLineItems, skpCase.contract_type__c);                    
                       system.debug('~~~~~ customer Indicator ~~~~~ '+ customerIndicator);
                        contractJsonString = JSON.serialize(new SKPContractRenegotiationBatchRequest(skpCase,erid,eridCustidMap.get(erid),contractMapping,customerIndicator));
                                        
                }
                contractJsonString = contractJsonString.replaceAll('systemStringToBeReplaced', 'system');
    
                //contractRequest = SKPIntegrationHelper.buildRequest(skpDetails.Update_Contract_Info__c, authorizationHeader, contractJsonString);
                contractRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Update_Contract_Info__c, finalSecurityToken, authorizationHeader, contractJsonString);
                System.debug('Contract JSON String for Case =='+skpCase.CaseNumber+' ----'+contractJsonString);
                contractResponse = http.send(contractRequest); 
                String contractResponseBody = contractResponse.getBody() ;
                System.debug('contractResponseBody=='+contractResponseBody);
                
                skpContractResp  = (SKPUpdateContractResponse)JSON.deserializeStrict(contractResponseBody, SKPUpdateContractResponse.class);
                System.debug('skpContractResp for ERID =='+erid+'=='+skpContractResp);
              if(skpContractResp.updateContractResult.contractDetails != null 
               && skpContractResp.updateContractResult.contractDetails.size() > 0){
                   integer size = skpContractResp.updateContractResult.contractDetails.size();
                   for(Integer i=0;i<size;i++){
                     List<SKP_Sync_Error__c> newSyncResults = new List<SKP_Sync_Error__c>();                        
                     if(skpContractResp.updateContractResult.contractDetails[i].errors != null 
                        && !skpContractResp.updateContractResult.contractDetails[i].errors.isEmpty() )  {
                         SKP_Sync_Error__c skpError = new SKP_Sync_Error__c(Error_Code__c = skpContractResp.updateContractResult.contractDetails[i].errors[0].code, Error_Description__c = 'CustomerId:'+skpContractResp.updateContractResult.contractDetails[i].customerId+'  '+skpContractResp.updateContractResult.contractDetails[i].errors[0].message, Severity__c='Error' ,Case__c = skpCase.id, Sync_Validate__c = 'Batch Sync');
                         syncErrors.add(skpError);
                         newSyncResults.add(skpError);
                      }                            
                     if(skpContractResp.updateContractResult.contractDetails[i].warnings != null 
                        && !skpContractResp.updateContractResult.contractDetails[i].warnings.isEmpty() )  {
                         SKP_Sync_Error__c SKPWarning = new SKP_Sync_Error__c(Error_Code__c = skpContractResp.updateContractResult.contractDetails[i].warnings[0].code, Error_Description__c = 'CustomerId:'+skpContractResp.updateContractResult.contractDetails[i].customerId+'  '+skpContractResp.updateContractResult.contractDetails[i].warnings[0].message, Severity__c='Warning' ,Case__c = skpCase.id, Sync_Validate__c = 'Batch Sync');
                         syncWarnings.add(SKPWarning);
                         newSyncResults.add(skpWarning);  
                     }        
                   }
            }                
       }     
    }
    
    public static List<Quote> getScheduleAs(String opportunityId, List<String> fieldsToQuery){
        string soqlString = 'Select ' +  String.join(fieldsToQuery, ',') +
                            ', (Select Bill_Code_Classification__c, Unit_of_Measure__c, UnitPrice, Product_Number__c, Product_Name__c From QuoteLineItems)' +
                            ' from Quote where OpportunityId =\'' +  String.escapeSingleQuotes(opportunityId) + '\'';
        return Database.query(soqlString);
    } 
    
    public void insertNewSyncErrors(){
        List<SKP_Sync_Error__c> newSyncErrors = new List<SKP_Sync_Error__c>();
        string syncType = 'Batch-Sync' ;
        
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
    }
    
    global void finish(Database.BatchableContext BC)
    {
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
        TotalJobItems, CreatedBy.Email
        FROM AsyncApexJob WHERE Id =
        :BC.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('SKPRateUploadNotificationBatch' + a.Status);
        mail.setPlainTextBody
        ('The batch Apex job processed ' + a.TotalJobItems +
        ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }    
}