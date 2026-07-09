/**
 * 	Class:				SCVGoConfigurator
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class will help in automatic deployment of pre-defined Contact flows, AWS Lambda functions.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public with sharing class SCVGoConfigurator {
    
    private List<NamedCredential> allNamedCredentials;

    @AuraEnabled
    public List<SCVGoWrapper.PicklistOption> awsConnectNamedCredentials{get; private set;}
    @AuraEnabled
    public List<SCVGoWrapper.PicklistOption> relatedContactCenters{get; private set;}
    @AuraEnabled
    public List<SCVGoWrapper.PicklistOption> awsCloudformationNamedCredentials{get; private set;}
    /* @AuraEnabled
    public SCVGoDeployments allDeployments{get; private set;} */

    SCVGoConfigurator(){
        this.setAllNamedCredentialsForAWSServices();
        this.awsConnectNamedCredentials = new List<SCVGoWrapper.PicklistOption>();
        this.relatedContactCenters = new List<SCVGoWrapper.PicklistOption>();
    }

    @AuraEnabled
    public static SCVGoConfigurator getInitialConfiguration(){
        SCVGoConfigurator initialConfig = new SCVGoConfigurator();
        initialConfig.awsConnectNamedCredentials = initialConfig.getListOfNamedCredentialsForAWSConnect();
        initialConfig.awsCloudformationNamedCredentials = initialConfig.getListOfNamedCredentialsForAWSCloudformation();
        // initialConfig.allDeployments = initialConfig.fetchAllDeployments();
        return initialConfig;
    }

    @AuraEnabled
    public static List<SCVGoWrapper.PicklistOption> getListOfAvailableContactCenters(String namedCredentialDeveloperName) {
        List<SCVGoWrapper.PicklistOption> contactCenterListForUserInterface = new List<SCVGoWrapper.PicklistOption>();
        Map<String,String> allSFContactCenters = getContactCentersCreatedFromSalesforce();
        String currentOrg15DigitId = String.valueOf(Id.valueOf(UserInfo.getOrganizationId()).to15());
        
        try{
            SCVGoConnectHelper helperInstance = new SCVGoConnectHelper();
            helperInstance.namedCredential = namedCredentialDeveloperName;
            HttpRequest getInstancesRequest = helperInstance.getListInstancesRequest();
            
            if(getInstancesRequest != null) {
                List<HttpResponse> instancesResponseList = helperInstance.processListRequest(getInstancesRequest);
                if(instancesResponseList != null && !instancesResponseList.isEmpty()) {
                    contactCenterListForUserInterface.add(getDefaultPlaceholderPicklistOption());
                    SCVGoWrapper.PicklistOption centerOptionWrapper;
                    for(HttpResponse response : instancesResponseList) {
                        if(response.getStatusCode() == 200) {
                            SCVGoWrapper.ListInstances data = (SCVGoWrapper.ListInstances) JSON.deserialize(response.getBody(), SCVGoWrapper.ListInstances.class); 
                            if(data != null && data.InstanceSummaryList != null && !data.InstanceSummaryList.isEmpty()) {
                                for(SCVGoWrapper.InstanceSummary summaryRecord : data.InstanceSummaryList) {
                                    String contactCenterLoginType = summaryRecord.IdentityManagementType;
                                    //Add only if the Contact Center is created from Salesforce
                                    if('SAML'.equals(contactCenterLoginType)){
                                        String updatedContactCenterAlias;
                                        if(summaryRecord.InstanceAlias.containsIgnoreCase(currentOrg15DigitId)){
                                            updatedContactCenterAlias = summaryRecord.InstanceAlias.replace(currentOrg15DigitId.toLowerCase(), '');
                                        }
                                        Boolean createdFromSF = allSFContactCenters.containsKey(updatedContactCenterAlias);
                                        if(createdFromSF){
                                            centerOptionWrapper = new SCVGoWrapper.PicklistOption(allSFContactCenters.get(updatedContactCenterAlias), summaryRecord.arn, summaryRecord.id);
                                            contactCenterListForUserInterface.add(centerOptionWrapper);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        catch(Exception retrieveCallCenterException) {
            SCVGoLogger.log(retrieveCallCenterException);
            ExceptionLogger.createLog(retrieveCallCenterException.getLineNumber(), retrieveCallCenterException.getStackTraceString(), retrieveCallCenterException.getMessage(), retrieveCallCenterException.getTypeName(), 'SCVGoConfigurator');
            throw new AuraHandledException(retrieveCallCenterException.getMessage());
        }
        return contactCenterListForUserInterface;
    }

    public static List<SCVGoWrapper.InstanceSummary> getAmazonConnectInstances(String awsConnectionInfo){
        List<SCVGoWrapper.InstanceSummary> allRelatedInstances = new List<SCVGoWrapper.InstanceSummary>();
        SCVGoConnectHelper helperInstance = new SCVGoConnectHelper();
        helperInstance.namedCredential = awsConnectionInfo;
        HttpRequest getInstancesRequest = helperInstance.getListInstancesRequest();
        
        if(getInstancesRequest != null) {
            List<HttpResponse> instancesResponseList = helperInstance.processListRequest(getInstancesRequest);
                        System.debug('instancesResponseList @85: ' + instancesResponseList);

            for(HttpResponse response : instancesResponseList) {
                if(response.getStatusCode() == 200) {
                    SCVGoWrapper.ListInstances data = (SCVGoWrapper.ListInstances) JSON.deserialize(response.getBody(), SCVGoWrapper.ListInstances.class);                        
                    if(data != null && data.InstanceSummaryList != null && !data.InstanceSummaryList.isEmpty()) {
                        allRelatedInstances.addAll(data.InstanceSummaryList);
                    }
                }
                else{
                    SCVGoLogger.LogCalloutException(getInstancesRequest, response);
                }
            }
        }
        return allRelatedInstances;
    }
    
    /* private SCVGoDeployments fetchAllDeployments(){
        return SCVGoDeployments.fetchAndListAllDeployments();
    } */

    private void setAllNamedCredentialsForAWSServices(){
        if(this.allNamedCredentials == null || this.allNamedCredentials.isEmpty()){
            this.allNamedCredentials = [SELECT Id, DeveloperName, MasterLabel, Endpoint FROM NamedCredential LIMIT 50000];
        }
    }

    private List<SCVGoWrapper.PicklistOption> getListOfNamedCredentialsForAWSConnect(){
        return getListOfNamedCredentialsByAWSService('connect');
    }

    private List<SCVGoWrapper.PicklistOption> getListOfNamedCredentialsForAWSCloudformation(){
        return getListOfNamedCredentialsByAWSService('cloudformation');
    }

    private List<SCVGoWrapper.PicklistOption> getListOfNamedCredentialsByAWSService(String awsServiceCode){
        if(Test.isRunningTest()){
            return SCVGoTestFactory.getTestNamedCredentialPicklistOptionForAWSService(awsServiceCode);
        }
        this.setAllNamedCredentialsForAWSServices();
        List<SCVGoWrapper.PicklistOption> namedCredentialOptions;

        if(this.allNamedCredentials != null && !this.allNamedCredentials.isEmpty()){
            namedCredentialOptions = new List<SCVGoWrapper.PicklistOption>();
            namedCredentialOptions.add(getDefaultPlaceholderPicklistOption());

            for(NamedCredential eachEntry : this.allNamedCredentials){
                String endPoint = eachEntry.Endpoint;
                Boolean isAWSServiceEndpoint = String.isNotBlank(endPoint) && endPoint.startsWith('https://' + awsServiceCode);
                
                if(isAWSServiceEndpoint){
                    SCVGoWrapper.PicklistOption namedCredOption = new SCVGoWrapper.PicklistOption(eachEntry.MasterLabel, eachEntry.DeveloperName, eachEntry.Endpoint);
                    namedCredentialOptions.add(namedCredOption);
                }
            }
            return namedCredentialOptions;
        }
        return new List<SCVGoWrapper.PicklistOption>();
    }

    private static Map<String,String> getContactCentersCreatedFromSalesforce(){
        Map<String,String> allSFContactCenters = new Map<String,String>();
        List<CallCenter> allContactCenters = [SELECT Name, InternalName FROM CallCenter LIMIT 50000];
        
        if(allContactCenters != null && !allContactCenters.isEmpty()){
            for(CallCenter eachEntry : allContactCenters){
                allSFContactCenters.put(eachEntry.InternalName.toLowerCase(), eachEntry.InternalName);
            }
        }
        System.debug('allSFContactCenters: ' + allSFContactCenters);
        return allSFContactCenters;
    }

    private static SCVGoWrapper.PicklistOption getDefaultPlaceholderPicklistOption(){
        return getPlaceholderPicklistOptionWithCustomText('-- Choose an option --');
    }

    private static SCVGoWrapper.PicklistOption getPlaceholderPicklistOptionWithCustomText(String placeholderText){
        return new SCVGoWrapper.PicklistOption(placeholderText, '');
    }

    public class DeploymentParams{
        public String clientName {get;set;}
        public String contactCenterInstance {get;set;}
        public String contactCenterRegion {get;set;}
        public String deploymentConnection {get;set;}
        public String deploymentRegion {get;set;}
        public Boolean deployHelperLambda {get;set;}
        public Boolean deployContactFlows {get;set;}
        public String callCenterApiName {get;set;}
        public String orgDomainName {get; private set;}

        public void setOrgDomainName(){
            this.orgDomainName = System.Url.getOrgDomainUrl().toExternalForm();
        }
    }
}