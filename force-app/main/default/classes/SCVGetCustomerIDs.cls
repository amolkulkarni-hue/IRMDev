/**
 * 	Class:				SCVGetCustomerIDs
 * 
 * 	Author:				Yashwant Verma (Neuraflash LLC)
 * 
 * 	Purpose:			This class is used for retrieving the Customer Ids for the Self Service IVR
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@RestResource(urlMapping='/getCustomerIDs')
global with sharing class SCVGetCustomerIDs {
    public static RestResponse invocationResult{
        get;
        private set;
    }
    
    static{
        invocationResult = new RestResponse();
    }

    
    @HttpGet
    global static String getCustomerIDs(){
        Map<String, Object> response = new Map<String, Object>();
        try{
            invocationResult.responseBody= Blob.valueOf('{"result":"empty"}');
            String phNumber = RestContext.request.params.get('phoneNumber');
            String phoneNumberSearchString = phNumber.right(10) + ' OR ' + phNumber.remove('+') + ' OR ' + phNumber;
            List<Id> accountIdList = new List<Id>(); 
            List<IM_Customer_Account__c> customerIdList = new List<IM_Customer_Account__c>();
            List<String> listOfCustomerIds = new List<String>();
            system.debug('phoneNumberSearchString = '+phoneNumberSearchString);
            
            String query = 'FIND \''+ phoneNumberSearchString + '\' IN PHONE FIELDS RETURNING Contact (AccountId)';
            Search.SearchResults searchResults = Search.find(query);

            for (Search.SearchResult eachContact : searchResults.get('Contact')){     
                accountIdList.add(((Contact) eachContact.getSObject()).AccountId);
            }
            system.debug('accountIdList = '+accountIdList);

            if(accountIdList !=null && !accountIdList.isEmpty()){
                customerIdList = [SELECT Id, Name FROM IM_Customer_Account__c WHERE IM_Account__c IN: accountIdList];
            }
            if (customerIdList != null && !customerIdList.isEmpty()){
                for(IM_Customer_Account__c eachCustomerAccount : customerIdList){
                    system.debug(eachCustomerAccount.Name);
                    listOfCustomerIds.add(eachCustomerAccount.Name);
                }
                system.debug('listOfCustomerIds>>>> '+ listOfCustomerIds);
                response.put('result', JSON.serialize(listOfCustomerIds));
                system.debug('response>>'+ response);
                invocationResult.responseBody= Blob.valueOf(JSON.Serialize(response));
            }
               
        }catch(exception ex){
            system.debug('Exception Encountered in getCustomerIDs of SCVGetCustomerIDs class >>' + ex.getMessage() + ' ' + ex.getLineNumber());
            invocationResult.statusCode = 500;
            invocationResult.responseBody = Blob.valueOf(ex.getMessage());
        }
        invocationResult.statusCode = 200;
        return JSON.Serialize(invocationResult);
    }
}