/**
 * 	Class:				MenuOptionManager
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class handles creation and update for MenuOption records.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public class MenuOptionManager {

    final String menuOptionObject = 'Menu_Option__c';
    final String menuOptionViewEditScreenFieldSet = 'View_Edit_Screen';
    Map<String,String> fieldApiToWrapperMap;

    @AuraEnabled
    public MenuOption currentMenuOption;

    @AuraEnabled
    public List<SCVGoWrapper.PicklistOption> callTransferOptions {get; private set;}

    @AuraEnabled
    public List<SCVGoWrapper.PicklistOption> amazonConnectNamedCredentials {get; private set;}

    @AuraEnabled
    public List<SCVGoWrapper.PicklistOption> amazonConnectFlows {get; private set;}

    @AuraEnabled
    public List<SCVGoWrapper.PicklistOption> menuOptionTypes {get; private set;}

    MenuOptionManager(String menuOptionId){
        this.callTransferOptions = new List<SCVGoWrapper.PicklistOption>();
        List<Transfer__c> callTransfers = [SELECT Id, Name, Type__c, Transfer_Label__c, Offer_Callback__c  FROM Transfer__c LIMIT 50000];
        if(callTransfers != null && !callTransfers.isEmpty()){
            for(Transfer__c eachEntry : callTransfers){
                SCVGoWrapper.PicklistOption theOption = new SCVGoWrapper.PicklistOption(eachEntry.Name, eachEntry.Id, eachEntry.Type__c);
                this.callTransferOptions.add(theOption);
            }
        }

        SCVGoConfigurator connectionConfig = SCVGoConfigurator.getInitialConfiguration();
        this.amazonConnectNamedCredentials = connectionConfig.awsConnectNamedCredentials;

        this.menuOptionTypes = new List<SCVGoWrapper.PicklistOption>();
        Schema.DescribeFieldResult typeDescription = Schema.Menu_Option__c.sobjecttype.getDescribe().fields.getMap().get('Type__c').getDescribe();
        if(typeDescription != null && !typeDescription.getPicklistValues().isEmpty()){
            for(Schema.PicklistEntry eachEntry : typeDescription.getPicklistValues()){
                if(eachEntry.isActive()){
                    SCVGoWrapper.PicklistOption eachTypeOption = new SCVGoWrapper.PicklistOption();
                    eachTypeOption.label = eachEntry.getLabel();
                    eachTypeOption.value = eachEntry.getValue();
                    this.menuOptionTypes.add(eachTypeOption);
                }
            }
        }

        String baseQuery = this.getMenuOptionBaseQueryFromFieldSetMembers();
        baseQuery += ' WHERE Id =: menuOptionId';
        System.debug(baseQuery + menuOptionId);
        List<Menu_Option__c> relatedMenuOptions = (List<Menu_Option__c>) Database.query(baseQuery);
        system.debug('relatedMenuOptions'+relatedMenuOptions);
        if(relatedMenuOptions != null && !relatedMenuOptions.isEmpty()){
            this.currentMenuOption = new MenuOption(relatedMenuOptions[0]);
        }
    }

    @AuraEnabled
    public static UserInterfaceActionResult getMenuOptionDetails(String menuOptionId){
        UserInterfaceActionResult menuOptionResult = new UserInterfaceActionResult(true, '');
        try {
            menuOptionResult.hasSucceeded();
            menuOptionResult.setPayload(new MenuOptionManager(menuOptionId));
        } catch (Exception e) {
            
            menuOptionResult.hasFailed();
            menuOptionResult.setMessage(e.getMessage());
        }
        return menuOptionResult;
    }

    @AuraEnabled
    public static UserInterfaceActionResult getRelatedAmazonConnectInstances(String namedCredentialName){
        UserInterfaceActionResult menuOptionResult = new UserInterfaceActionResult(true, '');
        try {
            List<SCVGoWrapper.PicklistOption> relatedConnectInstances = new List<SCVGoWrapper.PicklistOption>();
            List<SCVGoWrapper.InstanceSummary> receivedInstances = SCVGoConfigurator.getAmazonConnectInstances(namedCredentialName);
            if(receivedInstances != null && !receivedInstances.isEmpty()){
                for(SCVGoWrapper.InstanceSummary eachInstance : receivedInstances){
                    SCVGoWrapper.PicklistOption thePicklistOption = new SCVGoWrapper.PicklistOption(eachInstance.InstanceAlias, eachInstance.id, eachInstance.arn);
                    relatedConnectInstances.add(thePicklistOption);
                }
            }
            menuOptionResult.hasSucceeded();
            menuOptionResult.setPayload(relatedConnectInstances);
        } catch (Exception e) {
            SCVGoLogger.log(e);
            ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'MenuOptionManager');
            menuOptionResult.hasFailed();
            menuOptionResult.setMessage(e.getMessage());
        }
        return menuOptionResult;
    }

    @AuraEnabled
    public static UserInterfaceActionResult getRelatedAmazonConnectFlows(String awsConnectionInfo, String instanceId){
        UserInterfaceActionResult menuOptionResult = new UserInterfaceActionResult(true, '');
        try {
            List<SCVGoWrapper.PicklistOption> relatedConnectFlows = new List<SCVGoWrapper.PicklistOption>();
            List<SCVGoWrapper.ContactFlowSummary> resultantFlows = getAmazonConnectInstancesFlows(awsConnectionInfo, instanceId);
            if(resultantFlows != null && !resultantFlows.isEmpty()){
                for(SCVGoWrapper.ContactFlowSummary eachFlow : resultantFlows){
                    SCVGoWrapper.PicklistOption thePicklistOption = new SCVGoWrapper.PicklistOption(eachFlow.Name, eachFlow.Arn, eachFlow.ContactFlowType);
                    relatedConnectFlows.add(thePicklistOption);
                }
            }

            menuOptionResult.hasSucceeded();
            menuOptionResult.setPayload(relatedConnectFlows);
        } catch (Exception e) {
            SCVGoLogger.log(e);
            ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'MenuOptionManager');
            menuOptionResult.hasFailed();
            menuOptionResult.setMessage(e.getMessage());
        }
        return menuOptionResult;
    }
    
    private List<Schema.FieldSetMember> getMenuOptionViewEditScreenFieldSetMembers(){
        return SCVGoUtility.readFieldSet(this.menuOptionObject, this.menuOptionViewEditScreenFieldSet);
    }

    private String getMenuOptionBaseQueryFromFieldSetMembers(){
        String menuOptionQuery = 'SELECT {0} FROM {1}';
        List<Schema.FieldSetMember> menuOptionFields = this.getMenuOptionViewEditScreenFieldSetMembers();
        List<String> menuOptionFieldAPINames = new List<String>();

        if(menuOptionFields != null && !menuOptionFields.isEmpty()){
            for(Schema.FieldSetMember eachFieldSetMember : menuOptionFields){
                menuOptionFieldAPINames.add(eachFieldSetMember.getFieldPath());
            }
        }

        List<String> dynamicQueryParameters = new List<String>();
        dynamicQueryParameters.add(String.join(menuOptionFieldAPINames, ', '));
        dynamicQueryParameters.add(this.menuOptionObject);
        return String.format(menuOptionQuery, dynamicQueryParameters);
    }

    private static List<SCVGoWrapper.ContactFlowSummary> getAmazonConnectInstancesFlows(String awsConnectionInfo, String instanceId){
        List<SCVGoWrapper.ContactFlowSummary> allRelatedFlows = new List<SCVGoWrapper.ContactFlowSummary>();
        SCVGoConnectHelper helperInstance = new SCVGoConnectHelper();
        helperInstance.namedCredential = awsConnectionInfo;
        HttpRequest getListContactFlowsRequest = helperInstance.getListContactFlowsRequest(instanceId);
        
        if(getListContactFlowsRequest != null) {
            List<HttpResponse> flowsResponseList = helperInstance.processListRequest(getListContactFlowsRequest);
            for(HttpResponse response : flowsResponseList) {
                if(response.getStatusCode() == 200) {
                    SCVGoWrapper.ListContactFlows data = (SCVGoWrapper.ListContactFlows) JSON.deserialize(response.getBody(), SCVGoWrapper.ListContactFlows.class);                        
                    if(data != null && data.ContactFlowSummaryList != null && !data.ContactFlowSummaryList.isEmpty()) {
                        allRelatedFlows.addAll(data.ContactFlowSummaryList);
                    }
                }
                else{
                    SCVGoLogger.LogCalloutException(getListContactFlowsRequest, response);
                }
            }
        }
        return allRelatedFlows;
    }

    @AuraEnabled
    public static UserInterfaceActionResult saveMenuTypeInformation(Map<String,String> menuTypeInfoFromUI){
        system.debug('menuTypeInfoFromUI' + menuTypeInfoFromUI);
        UserInterfaceActionResult menuTypeSaveResult = new UserInterfaceActionResult(true, 'Data updated successfully.');
        try {
            if(menuTypeInfoFromUI == null || menuTypeInfoFromUI.isEmpty()){
                throw new SCVGoException('Input from user interface is invalid: ' + menuTypeInfoFromUI);
            }
            else if(!menuTypeInfoFromUI.containsKey('id') || menuTypeInfoFromUI.get('id') == null){
                throw new SCVGoException('Invalid Record Id: ' + menuTypeInfoFromUI.get('id'));
            }
            else{
                Menu_Option__c optionToUpdate = new Menu_Option__c();
                optionToUpdate.Id = menuTypeInfoFromUI.get('id');
                optionToUpdate.Type__c = menuTypeInfoFromUI.get('type');
                optionToUpdate.Self_service_Message__c = '';
                optionToUpdate.Contact_Flow_ARN__c = '';
                optionToUpdate.Transfer_To__c = null;
                optionToUpdate.Sub_menu_Prompt__c = '';

                if('Self-Service Message'.equals(optionToUpdate.Type__c)){
                    optionToUpdate.Self_service_Message__c = menuTypeInfoFromUI.get('value');
                }
                else if('Amazon Contact Flow'.equals(optionToUpdate.Type__c)){
                    optionToUpdate.Contact_Flow_ARN__c = menuTypeInfoFromUI.get('value');
                }
                else if('Call Transfer'.equals(optionToUpdate.Type__c)){
                    optionToUpdate.Transfer_To__c = menuTypeInfoFromUI.get('value');
                }
                else if('Sub-menu'.equals(optionToUpdate.Type__c)){
                    optionToUpdate.Sub_menu_Prompt__c = menuTypeInfoFromUI.get('value');
                }
                update optionToUpdate;
            }

            menuTypeSaveResult.hasSucceeded();
        } catch (Exception e) {
            menuTypeSaveResult.hasFailed();
            menuTypeSaveResult.setMessage(e.getMessage());
            SCVGoLogger.log(e);
            ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'MenuOptionManager');
        }
        return menuTypeSaveResult;
    }
}