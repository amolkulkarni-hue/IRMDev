public with sharing class B2B_IntegrationHelper {

static Map<String,Schema.RecordTypeInfo> recordTypeNameMap = null;
    
public static void updateObjects(List<Sobject> objectsToUpsert){
        try{
          //  B2B_Integration.firstRun=false;
            update objectsToUpsert;
            
           } catch (dmlexception e){
            system.debug('++dml exception++'+ e.getMessage());
        }
    }
   //CloseDate formerly First Bill Date, Booked Date is now First Bill Date. 
public static List<Opportunity> getOpportunities(String idParam){
        return [ Select Id,Owner.Name,Status__c,IM_Booked_Date__c,Name,Type,StageName,Commissionable_Window_Close_Date__c,
                 IMGA_Name__c,First_Bill_Booked_Date__c,Upsell_Customer_ID__r.Name,Customer_Account_Number__c ,IM_Up_Sell_Sold_To__c,RecordTypeId,SKP_Opportunity_Sync_Date__c,
                (Select Id,Customer_ID__r.Name,CaseNumber from Cases1__r where RecordType.Name IN ('NCSP: SKP New Customer Setup','NCSP: DMS'))
                from Opportunity where Id  =:idParam limit 1];
    }
 /*   
public static void chatterfeed(Opportunity Opportunitydetails,B2B_Response response){
     //   B2B_Integration.firstRun=false;
        List<FeedItem> feedlist =new  List<FeedItem>();
        FeedItem recordpost = new FeedItem();
        FeedItem userpost = new FeedItem();
        if(response == null){
             
               String message='There is a problem with The SKP Endpoints. Please Reprocess the Opportunity Record.'+
                                '\n\n To view Opportunity record click here:' +' '+EncodingUtil.urlDecode(URL.getSalesforceBaseUrl().toExternalForm() + '/' + Opportunitydetails.Id, 'UTF-8'); 
                recordpost.ParentId= Opportunitydetails.Id;
                recordpost.Body=message;
                recordpost.Title=Opportunitydetails.Name;
             // recordpost.CreatedById =UserInfo.getUserId();
                userpost.ParentId= Opportunitydetails.OwnerId;
                userpost.Body=message;
                userpost.Title=Opportunitydetails.Name;
             // userpost.CreatedById =UserInfo.getUserId();
                feedlist.add(recordpost);
                feedlist.add(userpost);
           }
        else if(!response.success){
              
                String message='The Opportunity:'+' ' +Opportunitydetails.Name+' '+'has not been successfully Created/Updated to SKP System. Please Check the Errors from "SKP Manage Opportunity Errors" Related list on Opportunity'+
                                '\n\n To view Opportunity record click here:' +' '+EncodingUtil.urlDecode(URL.getSalesforceBaseUrl().toExternalForm() + '/' + Opportunitydetails.Id, 'UTF-8'); 
                recordpost.ParentId= Opportunitydetails.Id;
                recordpost.Body=message;
                recordpost.Title=Opportunitydetails.Name;
            //  recordpost.CreatedById =UserInfo.getUserId();
                userpost.ParentId= Opportunitydetails.OwnerId;
                userpost.Body=message;
                userpost.Title=Opportunitydetails.Name;
             // userpost.CreatedById =UserInfo.getUserId();
                feedlist.add(recordpost);
                feedlist.add(userpost);
           }
           if(feedlist.size()>0  &&  feedlist != null){
               insert feedlist;
           }
    }
*/
 public static Map<String,Schema.RecordTypeInfo> getRecordType()
     {
        Schema.DescribeSObjectResult opportunityObject = Schema.SObjectType.Opportunity;
        Map<Id, Schema.RecordTypeInfo> opportunityRecordTypeIdMap = opportunityObject.getRecordTypeInfosById();
        
        if(recordTypeNameMap == null)
        {
            recordTypeNameMap = opportunityObject.getRecordTypeInfosByName();
        }
        return recordTypeNameMap;
     } 
 
/*public static HttpRequest buildRequest(String endpoint, string authorizationHeader, string jsonString){
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization', authorizationHeader);
        request.setBody(jsonString);
        request.setTimeout(100*1000);
        return request;
    }*/
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
        request.setMethod('POST');
        request.setHeader('access_token', 'Bearer ' + accesstoken);
        request.setHeader('Content-Type', 'application/json');
       // request.setHeader('Authorization', authorizationHeader);
        request.setHeader('userid', authorizationHeader);
        request.setBody(jsonString);
        request.setTimeout(100*1000);
        return request;
     }
}