public with sharing class B2B_Integration {
    public static boolean firstRun = true; 
    public static Opportunity skpopportunity;
    public static string createopportunityJsonString;
    public static string updateopportunityJsonString;
    
    public static Boolean runningInSandbox{
        get{
            runningInSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
            return runningInSandbox;
        } set;
    }
    
    public static B2BIntegration__c B2BDetails{
        get{
            string sandboxType = runningInSandbox ? 'Sandbox' : 'Production';
            B2BDetails= B2BIntegration__c.getInstance(sandboxType);
            return B2BDetails;
        } set;
    }  
    public static string finalSecurityToken;
    @future (callout=true)
    public static void create_opportunity(Id OpptyId, boolean validate){
        finalSecurityToken = B2B_IntegrationHelper.checkOAuthSecurityToken(B2BDetails.OAuth_EndPoint__c,B2BDetails.Client_Id__c,B2BDetails.Client_Secret__c);
        system.debug('#####'+finalSecurityToken);
        if(finalSecurityToken != null){
            firstRun = false; 
            skpopportunity = queryopportunity(OpptyId);
            B2B_Response B2BCreateResponse;
            Http http = new Http();
            HTTPResponse opportunityResponse;
            
            createopportunityJsonString=JSON.serialize(new B2B_CreateOpportunity(skpopportunity)); 
            createopportunityJsonString=createopportunityJsonString.replaceAll('systemStringToBeReplaced', 'system'); 
            //Blob headerValue = Blob.valueOf(B2BDetails.Username__c + ':' + B2BDetails.Password__c);
            //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            Blob headerValue = Blob.valueOf(B2BDetails.Username__c);
            String authorizationHeader = EncodingUtil.base64Encode(headerValue);
            //HttpRequest createRequest = B2B_IntegrationHelper.buildRequest(B2BDetails.Create_Opportunity__c, authorizationHeader, createopportunityJsonString);
            HttpRequest createRequest = B2B_IntegrationHelper.OAuthbuildRequest(B2BDetails.Create_Opportunity__c,finalSecurityToken, authorizationHeader, createopportunityJsonString);
            System.debug(createopportunityJsonString);
             try{
                   opportunityResponse = http.send(createRequest);          
                   String opportunityResponseBody = opportunityResponse.getBody();
                   B2BCreateResponse= (B2B_Response)JSON.deserialize(opportunityResponseBody, B2B_Response.class);
                   System.debug('B2B response: '+ B2BCreateResponse);
                 
                   if(B2BCreateResponse.success){
                   skpopportunity.SKP_Opportunity_Sync_Date__c=Datetime.now();
                   B2B_IntegrationHelper.updateObjects(new List<Sobject>{skpopportunity});
                   skpopportunity = queryopportunity(OpptyId);
                   } else {
             /* Commented this chatter Notifications- RJ*/
                 //  B2B_IntegrationHelper.chatterfeed(skpopportunity,B2BCreateResponse);
                }
            }
            catch (calloutException e) {
             System.debug('Callout error: '+ e);
           /* Commented this chatter Notifications- RJ*/
          //   B2B_IntegrationHelper.chatterfeed(skpopportunity,B2BCreateResponse);
            }
            handleB2BResponse(B2BCreateResponse,validate);
        }else{
        
            system.debug('Security Token is NOT Valid !!!');
        }
    }
    
       @future (callout=true)
        public static void update_opportunity(Id OpptyId,boolean validate){
        finalSecurityToken = B2B_IntegrationHelper.checkOAuthSecurityToken(B2BDetails.OAuth_EndPoint__c,B2BDetails.Client_Id__c,B2BDetails.Client_Secret__c);
        system.debug('#####'+finalSecurityToken);
        if(finalSecurityToken != null){
            firstRun = false; 
            skpopportunity = queryopportunity(OpptyId);
            B2B_Response B2BUpdateResponse;
            Http http = new Http();
            HTTPResponse opportunityResponse;
            
            updateopportunityJsonString=JSON.serialize(new B2B_UpdateOpportunity(skpopportunity)); 
            updateopportunityJsonString=updateopportunityJsonString.replaceAll('systemStringToBeReplaced', 'system'); 
            //Blob headerValue = Blob.valueOf(B2BDetails.Username__c + ':' + B2BDetails.Password__c);
            //String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            Blob headerValue = Blob.valueOf(B2BDetails.Username__c);
            String authorizationHeader = EncodingUtil.base64Encode(headerValue);
            //HttpRequest updateRequest = B2B_IntegrationHelper.buildRequest(B2BDetails.Update_Opportunity__c, authorizationHeader, updateopportunityJsonString);
            HttpRequest updateRequest = B2B_IntegrationHelper.OAuthbuildRequest(B2BDetails.Update_Opportunity__c, finalSecurityToken,authorizationHeader, updateopportunityJsonString);
            System.debug(updateopportunityJsonString);
             try{
                   opportunityResponse = http.send(updateRequest);          
                   String opportunityResponseBody = opportunityResponse.getBody();
                   B2BUpdateResponse= (B2B_Response)JSON.deserialize(opportunityResponseBody, B2B_Response.class);
                   System.debug('B2B response: '+ B2BUpdateResponse);
                   
                   if(!B2BUpdateResponse.success){
                 /* Commented this chatter Notifications- RJ*/
                 //  B2B_IntegrationHelper.chatterfeed(skpopportunity,B2BUpdateResponse); 
                   }  
              }
             catch (calloutException e) {
             System.debug('Callout error: '+ e);
           /* Commented this chatter Notifications- RJ*/
          //   B2B_IntegrationHelper.chatterfeed(skpopportunity,B2BUpdateResponse);
            }
            handleB2BResponse(B2BUpdateResponse,validate);
        }else{
            System.debug('Security Token is NOT Valid !!!');
        }
   }
   
    public static Opportunity queryopportunity (Id opptyId){
        List<Opportunity> opportunities = B2B_IntegrationHelper.getOpportunities(opptyId);
        
        if(!opportunities.isEmpty()){
            return opportunities[0];
        } else {
            return null;
        }
    }
    
    public static void handleB2BResponse(B2B_Response response, Boolean validate){
        List<SKP_Manage_Opportunity_Errors__c> newSyncResults = new List<SKP_Manage_Opportunity_Errors__c>();
        string syncType = (validate) ? 'Create' : 'Update' ; 
        List<B2B_Response.CodeAndMessage> errors = new List<B2B_Response.CodeAndMessage>();
        List<B2B_Response.CodeAndMessage> warnings = new List<B2B_Response.CodeAndMessage>();
        if(response != null){
        if(response.errors != null){
            errors.addAll(response.errors);
        }
        if(response.warnings != null){
            warnings.addAll(response.warnings);
        }
        for(B2B_Response.CodeAndMessage error : errors){
            SKP_Manage_Opportunity_Errors__c skpError = new SKP_Manage_Opportunity_Errors__c(Error_Code__c = error.code, Error_Description__c = error.message, Severity__c='Error' ,Opportunity__c = skpopportunity.Id, Step_Name__c = syncType);
            newSyncResults.add(skpError);
        }
        
        for(B2B_Response.CodeAndMessage warn : warnings){
            SKP_Manage_Opportunity_Errors__c SKPWarning = new SKP_Manage_Opportunity_Errors__c(Error_Code__c = warn.code, Error_Description__c = warn.message, Severity__c='Warning' ,Opportunity__c = skpopportunity.Id, Step_Name__c = syncType);
            newSyncResults.add(skpWarning);
        }
     }   
        if(newSyncResults.size()>0 && newSyncResults != null)
            insert newSyncResults;
      }
    
}