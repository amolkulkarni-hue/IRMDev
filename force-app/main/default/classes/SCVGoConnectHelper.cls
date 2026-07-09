/**
 * 	Class:				SCVGoConnectHelper
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class will create and process response for any Http request related to Amazon Connect.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public with sharing class SCVGoConnectHelper{
    public String namedCredential;
    Map<String,Integer> actionMaxResultMapping = new Map<String,Integer>();
    String endpoint, method, instanceId, userId, queueId, routingProfileId, nextToken, queueType, maxResults;
    List<String> contactFlowTypes;
    Map<String,Object> queryMap = new Map<String,Object>();
    Map<String,String> headerMap = new Map<String,String>();
    
    {
        actionMaxResultMapping.put('ListInstances',10);
        actionMaxResultMapping.put('ListRoutingProfileQueues',100);
        actionMaxResultMapping.put('ListQueues',1000);
        actionMaxResultMapping.put('ListUsers',1000);
        actionMaxResultMapping.put('ListRoutingProfiles',1000);
        actionMaxResultMapping.put('ListSecurityProfiles',1000);
        actionMaxResultMapping.put('ListContactFlows',1000);
    }

    @TestVisible
    private HttpRequest getConnectRequest(String action){
        if(String.isBlank(action)){
            return null;
        }
        
        HttpRequest req;
        method = 'GET';
        
        switch on action {
            when 'ListInstances' {
                endpoint = '/instance';
                queryMap.put('maxResults', maxResults);
                queryMap.put('nextToken', nextToken);
            }
            when 'ListRoutingProfileQueues' {
                endpoint = '/routing-profiles/' + instanceId + '/' + routingProfileId + '/queues';
                queryMap.put('maxResults', maxResults);
                queryMap.put('nextToken', nextToken);
            }
            when 'ListRoutingProfiles'{
                endpoint = '/routing-profiles-summary/' + instanceId;
                queryMap.put('maxResults', maxResults);
                queryMap.put('nextToken', nextToken);
            }
            when 'ListQueues' {
                endpoint = '/queues-summary/' + instanceId;
                queryMap.put('maxResults', maxResults);
                queryMap.put('nextToken', nextToken);
                queryMap.put('queueTypes', queueType);
            }
            when 'ListUsers' {
                endpoint = '/users-summary/' + instanceId;
                queryMap.put('maxResults', maxResults);
                queryMap.put('nextToken', nextToken);
            }
            when 'ListContactFlows' {
                endpoint = '/contact-flows-summary/' + instanceId;
                queryMap.put('maxResults', maxResults);
                queryMap.put('contactFlowTypes', contactFlowTypes);
                queryMap.put('nextToken', nextToken);
            }
            when 'DescribeUser' {
                endpoint = '/users/' + instanceId + '/' + userId;
            }
            when 'DescribeQueue' {
                endpoint = '/queues/' + instanceId + '/' + queueId;
            }
            when 'ListSecurityProfiles' {
                endpoint = '/security-profiles-summary/' + instanceId;
                queryMap.put('maxResults', maxResults);
                queryMap.put('nextToken', nextToken);
            }
        }

        req = HttpHelper.getConnectRequest(endpoint, method, headerMap, queryMap, this.namedCredential);
        return req;
    }

    @TestVisible
    private void setMaxResults(String action, Integer maxResult){ 
        Integer allowedLimit = actionMaxResultMapping.get(action);
        //System.debug('Allowed limit: ' + allowedLimit);
        if(maxResult == null || (maxResult <= 0 && maxResult > allowedLimit)){
            maxResult = allowedLimit;
        }
        //System.debug('Applied limit: ' + maxResult);
        this.maxResults = String.valueOf(maxResult);
    }

    public HttpRequest getListInstancesRequest(){
        return getListInstancesRequest(null, null);
    }

    public HttpRequest getListInstancesRequest(Integer maxResult){
        return getListInstancesRequest(maxResult, null);
    }
    
    public HttpRequest getListInstancesRequest(Integer maxResult, String nextToken){
        this.nextToken = nextToken;
        setMaxResults('ListInstances', maxResult);
        return getConnectRequest('ListInstances');
    }
    
    public HttpRequest getListRoutingProfileQueuesRequest(String instanceId, String routingProfileId){
        return getListRoutingProfileQueuesRequest(instanceId, routingProfileId, null, null);
    }

    public HttpRequest getListRoutingProfileQueuesRequest(String instanceId, String routingProfileId, Integer maxResult){
        return getListRoutingProfileQueuesRequest(instanceId, routingProfileId, maxResult, null);
    }
    
    public HttpRequest getListRoutingProfileQueuesRequest(String instanceId, String routingProfileId, Integer maxResult, String nextToken){
        if(String.isBlank(instanceId) || String.isBlank(routingProfileId)){
            return null;
        }
        this.instanceId = instanceId;
        this.routingProfileId = routingProfileId;
        this.nextToken = nextToken;
        setMaxResults('ListRoutingProfileQueues',maxResult);
        return getConnectRequest('ListRoutingProfileQueues');
    }
    
    public HttpRequest getListRoutingProfilesRequest(String instanceId){
        return getListRoutingProfilesRequest(instanceId, null, null);
    }

    public HttpRequest getListRoutingProfilesRequest(String instanceId, Integer maxResult){
        return getListRoutingProfilesRequest(instanceId, maxResult, null);
    }
    
    public HttpRequest getListRoutingProfilesRequest(String instanceId, Integer maxResult, String nextToken){
        if(String.isBlank(instanceId)){
            return null;
        }
        this.instanceId = instanceId;
        this.nextToken = nextToken;
        setMaxResults('ListRoutingProfiles',maxResult);
        return getConnectRequest('ListRoutingProfiles');
    }

    public HttpRequest getListSecurityProfilesRequest(String instanceId){
        return getListSecurityProfilesRequest(instanceId, null, null);
    }

    public HttpRequest getListSecurityProfilesRequest(String instanceId, Integer maxResult){
        return getListSecurityProfilesRequest(instanceId, maxResult, null);
    }
    
    public HttpRequest getListSecurityProfilesRequest(String instanceId, Integer maxResult, String nextToken){
        if(String.isBlank(instanceId)){
            return null;
        }
        this.instanceId = instanceId;
        this.nextToken = nextToken;
        setMaxResults('ListSecurityProfiles',maxResult);
        return getConnectRequest('ListSecurityProfiles');
    }

    public HttpRequest getListQueuesRequest(String instanceId){
        return getListQueuesRequest(instanceId, null, null, null);
    }

    public HttpRequest getListQueuesRequest(String instanceId, String queueType){
        return getListQueuesRequest(instanceId, queueType, null, null);
    }

    public HttpRequest getListQueuesRequest(String instanceId, String queueType, Integer maxResult){
        return getListQueuesRequest(instanceId, queueType, maxResult, null);
    }

    public HttpRequest getListQueuesRequest(String instanceId, String queueType, Integer maxResult, String nextToken){
        if(String.isBlank(instanceId)){
            return null;
        }
        this.instanceId = instanceId;
        this.queueType = queueType;
        this.nextToken = nextToken;
        setMaxResults('ListQueues', maxResult);
        return getConnectRequest('ListQueues');
    }
    
    public HttpRequest getListUsersRequest(String instanceId){
        return getListUsersRequest(instanceId, null, null);
    }

    public HttpRequest getListUsersRequest(String instanceId, Integer maxResult){
        return getListUsersRequest(instanceId, maxResult, null);
    }
    
    public HttpRequest getListUsersRequest(String instanceId, Integer maxResult, String nextToken){
        if(String.isBlank(instanceId)){
            return null;
        }
        this.instanceId = instanceId;
        this.nextToken = nextToken;
        setMaxResults('ListUsers',maxResult);
        return getConnectRequest('ListUsers');
    }

    public HttpRequest getListContactFlowsRequest(String instanceId){
        return getListContactFlowsRequest(instanceId, null, null, null);
    }

    public HttpRequest getListContactFlowsRequest(String instanceId, List<String> contactFlowTypes){
        return getListContactFlowsRequest(instanceId, contactFlowTypes, null, null);
    }

    public HttpRequest getListContactFlowsRequest(String instanceId, List<String> contactFlowTypes, Integer maxResult){
        return getListContactFlowsRequest(instanceId, contactFlowTypes, maxResult, null);
    }

    public HttpRequest getListContactFlowsRequest(String instanceId, List<String> contactFlowTypes, Integer maxResult, String nextToken){
        if(String.isBlank(instanceId)){
            return null;
        }
        this.instanceId = instanceId;
        this.contactFlowTypes = contactFlowTypes;
        this.nextToken = nextToken;
        setMaxResults('ListContactFlows', maxResult);
        return getConnectRequest('ListContactFlows');
    }
    
    public HttpRequest getDescribeUserRequest(String instanceId, String userId){
        if(String.isBlank(instanceId) || String.isBlank(userId)){
            return null;
        }
        this.instanceId = instanceId;
        this.userId = userId;
        return getConnectRequest('DescribeUser');
    }

    public HttpRequest getDescribeQueueRequest(String instanceId, String queueId){
        if(String.isBlank(instanceId) || String.isBlank(queueId)){
            return null;
        }
        this.instanceId = instanceId;
        this.queueId = queueId;
        return getConnectRequest('DescribeQueue');
    }

    public List<HttpResponse> processListRequest(HttpRequest req){
        Boolean initialRequest = true;
        List<HttpResponse> finalResponse = new List<HttpResponse>();
        List<Object> result = new List<Object>();
        Map<String,Object> responseMap;
        try{
            do{
                //Print request
                HttpHelper.printRequest(req);

                //Make first request
                HttpResponse resp = HttpHelper.getResponse(req);

                //Print response
                HttpHelper.printResponse(resp);

                //Set initialRequest to false
                if(initialRequest){
                    initialRequest = false;
                }

                //Add current response to a list
                finalResponse.add(resp);

                //Update responseMap
                responseMap = processListResponse(req, resp);

                //Add or update next token value in the request query parameters
		        if(responseMap != null && !responseMap.isEmpty() && responseMap.containsKey('NextToken')){
                    replaceNextToken(req, String.valueOf(responseMap.get('NextToken')));
                }

            }while(initialRequest || (responseMap.containsKey('NextToken') && responseMap.get('NextToken') != null));
        }
        catch(System.CalloutException cex){
            SCVGoLogger.log(cex);
            throw cex;
        }
        catch(Exception ex){
            SCVGoLogger.log(ex);
            ExceptionLogger.createLog(ex.getLineNumber(), ex.getStackTraceString(), ex.getMessage(), ex.getTypeName(), 'SCVGoConnectHelper');
        }
        return finalResponse;
    }

    private Map<String,Object> processListResponse(HttpRequest request, HttpResponse response){
        Map<String,Object> responseMap;    
        if(response.getStatusCode() == 200){
            try{
                responseMap = (Map<String,Object>) JSON.deserializeUntyped(response.getBody());
            }
            catch(Exception ex){
                SCVGoLogger.log(ex);
            }
        }
        else{
            SCVGoLogger.LogCalloutException(request, response);
        }
        return responseMap;
    }

    @TestVisible 
    private void replaceNextToken(HttpRequest existingRequest, String token){
        Map<String,Object> queryMap = HttpHelper.getQueryMap(existingRequest);
        if(String.isNotBlank(token)){
            queryMap.put('nextToken', EncodingUtil.urlEncode(token, 'UTF-8'));
        }
        
        String newEndpoint = existingRequest.getEndpoint();
        newEndpoint = newEndpoint.replace(newEndpoint.substringAfter('?'), HttpHelper.getQueryString(queryMap));
        existingRequest.setEndpoint(newEndpoint);
        //System.debug('request.getEndpoint: ' + existingRequest.getEndpoint());
    }
}