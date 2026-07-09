global class SKPRateUploadQPINotificationBatch implements Database.Batchable<sObject>, Database.Stateful,Database.AllowsCallouts{
    public boolean runningInASandbox;
    SKP_Integration_Details__c skpDetails;
    public SkpIntegrationHelper.CustomerIndicator customerIndicator;
    Map<id,Quote> scheduleAs;
    public List<SKP_Sync_Quote_Error__c> syncErrors; 
    public List<SKP_Sync_Quote_Error__c> syncWarnings;
    List<Quote> quotesToUpdate ;   
    final static String STATUS_ACCEPTED = 'Accepted';
    final static String STATUS_MODIFIED = 'Modified';
    final static String STATUS_INPROGRESS = 'In-Progress';
    private List<String> statusValues = new List<String>{'Accepted', 'Modified', 'Open', 'In-Progress'};
    Public boolean isScheduledJob;    
    
    public static string finalSecurityToken;

    private String quarter;
    
    public SKPRateUploadQPINotificationBatch(String quarterString){
        runningInASandbox = [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
        this.quarter = quarterString;
        if(quarterString!= null && !quarterString.equals(''))
        {isScheduledJob=false;}
        else 
        {isScheduledJob=true;}
        string sandboxType = runningInASandbox ? 'Sandbox' : 'Production' ;
        if(Test.isRunningTest()){sandboxType ='SandboxTest';}
        skpDetails = SKP_Integration_Details__c.getInstance(sandboxType);
        system.debug('~~~~ skp details ~~~~ '+ skpDetails);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String query ='';
        if(isScheduledJob)
        {
            query = 'SELECT Id,Name,Status,q2w_Effective_Date__c, ' +
                ' (Select Bill_Code_Classification__c, Unit_of_Measure__c, UnitPrice,Proposed_Price__c,Quantity, Product_Number__c, Product_Name__c,Product_Code__c From QuoteLineItems), ' +
                ' Rate_table_Id__c FROM Quote '+
                ' Where q2w_Effective_Date__c = TODAY AND RecordType.Name IN (\'NA Renewal Quote\') ' + 
                ' AND Status IN :statusValues';
        }
        else
        {
            query = 'SELECT Id,Name,Status,q2w_Effective_Date__c, ' +
                ' (Select Bill_Code_Classification__c, Unit_of_Measure__c, UnitPrice,Proposed_Price__c,Quantity, Product_Number__c, Product_Name__c,Product_Code__c From QuoteLineItems), ' +
                ' Rate_table_Id__c FROM Quote '+
                ' Where RecordType.Name IN (\'NA Renewal Quote\') ' + 
                ' AND SKP_Contract_Sync_Date__c = null ' +
                ' AND Quarter_Status__c = \'Closed: Rates Uploaded\'' +  
                ' AND Status IN :statusValues '+
                ' AND Name LIKE \'%' + this.quarter + '\'';
               
               //query += 'AND id IN (\'0Q0c0000000XmAz\') ';            
        }
        if(Test.isRunningTest())
        {
             query = 'SELECT Id,Name,Status,q2w_Effective_Date__c, ' +
                ' (Select Bill_Code_Classification__c, Unit_of_Measure__c, UnitPrice,Proposed_Price__c,Quantity, Product_Number__c, Product_Name__c,Product_Code__c From QuoteLineItems), ' +
                ' Rate_table_Id__c FROM Quote '+
                ' Where RecordType.Name IN (\'NA Renewal Quote\') ' + 
                ' AND SKP_Contract_Sync_Date__c = null ' +
                ' AND Quarter_Status__c = \'Closed: Rates Uploaded\'' +  
                ' AND Status IN :statusValues limit 5';
        }
            
        System.debug(LoggingLevel.Info,'Query is =='+query);
   
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Quote> scope)
    {
        finalSecurityToken = B2B_IntegrationHelper.checkOAuthSecurityToken(skpDetails.OAuth_EndPoint__c,skpDetails.Client_Id__c,skpDetails.Client_Secret__c);
        system.debug('#####'+finalSecurityToken);
        if(finalSecurityToken != null){
        quotesToUpdate = new List<Quote>();
        string qidString ='';

        List<IM_Customer_Account__c> customerList=new List<IM_Customer_Account__c>();
        syncErrors = new List<SKP_Sync_Quote_Error__c>(); 
        syncWarnings = new List<SKP_Sync_Quote_Error__c>(); 
            
        for(Quote qid:scope){
            if(qidString!=''){
                qidString+=',';
            }
            qidString+='\''+qid.Id+'\'';
        }
        
        String customerQuery='Select Id,Quote__c,Name From IM_Customer_Account__c Where quote__c IN ('+qidString+')'; 
        System.debug('customerQuery=='+customerQuery);
        customerList=Database.Query(customerQuery);
        
        Map<id,List<IM_Customer_Account__c>> CustomerMap=new Map<id,List<IM_Customer_Account__c>>();
        for(IM_Customer_Account__c cus:customerList){
            List<IM_Customer_Account__c> temp=CustomerMap.get(cus.Quote__c);
            if(temp==null){
                temp=new List<IM_Customer_Account__c>();
            }
            temp.add(cus);
            CustomerMap.put(cus.Quote__c,temp);
        }

        for(Quote eachq : Scope)
        {       
            System.debug('Quote being processed.....'+eachq.Name);
            //List<IM_Customer_Account__c> quoteCustomerAccts = [Select Name From IM_Customer_Account__c Where quote__c =: eachq.id];
            List<IM_Customer_Account__c> quoteCustomerAccts = CustomerMap.get(eachq.Id);
            //syncErrors = new List<SKP_Sync_Quote_Error__c>(); 
            //syncWarnings = new List<SKP_Sync_Quote_Error__c>(); 
            
            Set<String> custIdSet = new Set<String>();
            Map<String,Set<String>> eridCustidMap = new Map<String,Set<String>>();
            if(quoteCustomerAccts != null && quoteCustomerAccts.size() > 0){
            for(IM_customer_account__c c: quoteCustomerAccts){
                    custIdSet.add(c.Name); 
                }  
            }
            if(custIdSet != null && custIdSet.size() > 0)
                processUpdateContract(eachq,eachq.Rate_table_Id__c,custIdSet);            

            if(quoteCustomerAccts != null && quoteCustomerAccts.size() > 0){
                quoteCustomerAccts.clear();
            }
            //insertNewSyncErrors();            
        }
        if(quotesToUpdate != null && quotesToUpdate.size() > 0){
            updateQuote(quotesToUpdate);
        }        
        insertNewSyncErrors();
        }
    }
    
    public void processUpdateContract(Quote echQuote,String erid,Set<String> custId){
        Http http = new Http();
        HTTPResponse contractResponse;
        SKPUpdateContractResponse skpContractResp;        
        SKP_ErrorResponse SKPErrorResp;
        HttpRequest contractRequest;
        //Blob headerValue = Blob.valueOf(skpDetails.Username__c + ':' + skpDetails.Password__c);
        //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        Blob headerValue = Blob.valueOf(skpDetails.Username__c);
        String authorizationHeader = EncodingUtil.base64Encode(headerValue);
        String contractJsonString;
        SKP_Contract_Type_Mapping__c contractMapping;
        erid = erid.substring(erid.indexOf('|')+1, erid.indexOf('('));
        List<SKP_Sync_Quote_Error__c> newSyncResults = new List<SKP_Sync_Quote_Error__c>(); 
        if(isScheduledJob)
        {
            contractJsonString = JSON.serialize(new SKPContractRenewalBatchRequest(erid,custId,true));   
        }
        else
        {
            contractJsonString = JSON.serialize(new SKPContractRenewal_QPI(echQuote,erid,custId,''));            
        }
        contractJsonString = contractJsonString.replaceAll('systemStringToBeReplaced', 'system');
        //contractRequest = SKPIntegrationHelper.buildRequest(skpDetails.Update_Contract_Info__c, authorizationHeader, contractJsonString);
        contractRequest = SKPIntegrationHelper.OAuthbuildRequest(skpDetails.Update_Contract_Info__c, finalSecurityToken, authorizationHeader, contractJsonString);
        System.debug('SFDC Request=='+contractJsonString);                
        contractResponse = http.send(contractRequest); 
        String contractResponseBody = contractResponse.getBody() ;
        //contractResponseBody = '{"success":false,"errors":[{"code":"COM011","message":"System error in Contract update service"}],"warnings":null}';
        Integer result = contractResponseBody.indexOf('updateContractResult');
        System.debug('SKP Response=='+contractResponseBody);   
        if(result>=0)
        {
            skpContractResp  = (SKPUpdateContractResponse)JSON.deserialize(contractResponseBody, SKPUpdateContractResponse.class);
            if(skpContractResp.updateContractResult.generalWarnings != null 
               && skpContractResp.updateContractResult.generalWarnings.size() > 0)
                {
                    for(integer GW=0;GW<skpContractResp.updateContractResult.generalWarnings.size();GW++)
                    {  
                        string ErrorCode=skpContractResp.updateContractResult.generalWarnings[GW].code;
                        string ErrorDescription=skpContractResp.updateContractResult.generalWarnings[GW].message;                        
                        SKP_Sync_Quote_Error__c SKPWarning = new SKP_Sync_Quote_Error__c(Error_Code__c =ErrorCode , Error_Description__c = ErrorDescription,Severity__c='Warning' ,Quote__c = echQuote.id, Sync_Validate__c = 'QPI Batch Sync');
                        syncWarnings.add(SKPWarning);
                    }
                }
            if(skpContractResp.updateContractResult.contractDetails != null 
               && skpContractResp.updateContractResult.contractDetails.size() > 0){
                   integer size = skpContractResp.updateContractResult.contractDetails.size();
                   for(Integer i=0;i<size;i++){                    
                       if(skpContractResp.updateContractResult.contractDetails[i].errors != null 
                          && !skpContractResp.updateContractResult.contractDetails[i].errors.isEmpty() )  {
                                for(integer k=0;k<skpContractResp.updateContractResult.contractDetails[i].errors.size();k++){                          
                              SKP_Sync_Quote_Error__c skpError = new SKP_Sync_Quote_Error__c(Error_Code__c = skpContractResp.updateContractResult.contractDetails[i].errors[k].code, Error_Description__c = skpContractResp.updateContractResult.contractDetails[i].errors[k].message, Severity__c='Error' ,Quote__c = echQuote.id, Sync_Validate__c = 'QPI Batch Sync');
                              syncErrors.add(skpError);
                              newSyncResults.add(skpError);
                          }                            
                        }      
                       if(skpContractResp.updateContractResult.contractDetails[i].warnings != null 
                          && !skpContractResp.updateContractResult.contractDetails[i].warnings.isEmpty() )  {
                           for(integer j=0;j<skpContractResp.updateContractResult.contractDetails[i].warnings.size();j++){                          
                              SKP_Sync_Quote_Error__c SKPWarning = new SKP_Sync_Quote_Error__c(Error_Code__c = skpContractResp.updateContractResult.contractDetails[i].warnings[j].code, Error_Description__c = skpContractResp.updateContractResult.contractDetails[i].warnings[j].message, Severity__c='Warning' ,Quote__c = echQuote.id, Sync_Validate__c = 'QPI Batch Sync');
                              syncWarnings.add(SKPWarning);
                          }     
                       }
                   }
               }    
            system.debug('TotalsyncErrors=='+syncErrors.size());
            system.debug('currentSyncErrors=='+newSyncResults.size());
            if(newSyncResults != null && newSyncResults.isEmpty()){
                echQuote.SKP_Contract_Sync_Date__c = Datetime.now();
                quotesToUpdate.add(echQuote);
            }
            
        }
        else
        {
           system.debug('Sync Failure'); 
           SKPErrorResp  = (SKP_ErrorResponse)JSON.deserialize(contractResponseBody, SKP_ErrorResponse.class);
           if(SKPErrorResp.errors != null && !SKPErrorResp.errors.isEmpty() )  
           {              
               for(integer k=0;k<SKPErrorResp.errors.size();k++)
               {                          
                   SKP_Sync_Quote_Error__c skpError = new SKP_Sync_Quote_Error__c(Error_Code__c = SKPErrorResp.errors[k].code, Error_Description__c = SKPErrorResp.errors[k].message, Severity__c='Error' ,Quote__c = echQuote.id, Sync_Validate__c = 'QPI Batch Sync');
                   syncErrors.add(skpError);
               }                            
           }
        } 
        
          
    }
    
    public static void updateQuote(List<Quote> quoteList){
        update quoteList;
    }
    public static List<Quote> getScheduleAs(String opportunityId, List<String> fieldsToQuery){
        string soqlString = 'Select ' +  String.join(fieldsToQuery, ',') +
                            ', (Select Bill_Code_Classification__c, Unit_of_Measure__c, UnitPrice, Product_Number__c, Product_Name__c From QuoteLineItems)' +
                            ' from Quote where OpportunityId =\'' +  String.escapeSingleQuotes(opportunityId) + '\'';
        return Database.query(soqlString);
    } 
    
    public void insertNewSyncErrors(){
        List<SKP_Sync_Quote_Error__c> newSyncErrors = new List<SKP_Sync_Quote_Error__c>();
        string syncType = 'Batch-Sync' ;
        
        boolean hasErrors = false;
        boolean hasWarnings = false;
        
        for( SKP_Sync_Quote_Error__c error : syncErrors){
            if(error.id == null){
                newSyncErrors.add(error);
                hasErrors = true;
            }
        }
        for( SKP_Sync_Quote_Error__c warning : syncWarnings){
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
        mail.setSubject('SKPRateUploadQPINotificationBatch' + a.Status);
        mail.setPlainTextBody
        ('The batch Apex job processed ' + a.TotalJobItems +
        ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }    
}