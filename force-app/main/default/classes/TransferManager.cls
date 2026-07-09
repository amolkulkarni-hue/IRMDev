/**
 * 	Class:				TransferManager
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class handles the creation and update on records for Transfer object.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public with sharing class TransferManager {

    @AuraEnabled
    public Transfer transferRecord {get; private set;}
    @AuraEnabled
    public List<SCVGoWrapper.PicklistOption> formFieldsMetadata {get; private set;}
    @AuraEnabled
    public List<SCVGoWrapper.PicklistOption> salesforceChannelQueues {get; private set;}
    @AuraEnabled
    public List<SCVGoWrapper.PicklistOption> transferTypes {get; private set;}
    @AuraEnabled
    public List<SCVGoWrapper.PicklistOption> transferChannels {get; private set;}

    @AuraEnabled
    public static UserInterfaceActionResult getTransferDetailForm(String recordId){
        UserInterfaceActionResult getRecordForm = new UserInterfaceActionResult(true, '');
        try {
            TransferManager formAndRecordConfig = new TransferManager();

            List<Transfer__c> relatedTransfer = [SELECT Id, Name, Type__c, Transfer_Label__c, Transfer_Destination__c, Transfer_Message__c, Channel__c, Offer_Callback__c, Callback_Menu_Prompt__c, Callback_Prompt__c, Callback_Confirmation_Prompt__c, Different_Callback_Number_Prompt__c, Invalid_Number_Prompt__c, Callback_End_Prompt__c, Callback_Threshold_In_Minutes__c FROM Transfer__c WHERE Id =: recordId];
            if(relatedTransfer != null && !relatedTransfer.isEmpty()){
                formAndRecordConfig.transferRecord = new Transfer(relatedTransfer[0]);
            }
            else{
                formAndRecordConfig.transferRecord = new Transfer();
            }
            formAndRecordConfig.formFieldsMetadata = formAndRecordConfig.getTransferFieldMetadata();
            formAndRecordConfig.transferChannels = formAndRecordConfig.getChannelOptions();
            formAndRecordConfig.salesforceChannelQueues = formAndRecordConfig.getChannelQueues();
            formAndRecordConfig.transferTypes = formAndRecordConfig.getTransferTypeOptions();
            getRecordForm.setPayload(formAndRecordConfig);
            getRecordForm.hasSucceeded();
        } catch (Exception e) {
            SCVGoLogger.log(e);
            ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'TransferManager');
            getRecordForm.hasFailed();
            getRecordForm.setMessage(e.getMessage());
        }
        return getRecordForm;
    }

    private List<SCVGoWrapper.PicklistOption> getTransferFieldMetadata(){
        Map<String,String> labelToWrapperMap = this.getLabelAttributeMapping();
        List<SCVGoWrapper.PicklistOption> fieldMetadata = new List<SCVGoWrapper.PicklistOption>();
        
        Map<String,Schema.sObjectField> transferFields = Schema.Transfer__c.SobjectType.getDescribe().fields.getMap();
        if(transferFields != null && !transferFields.isEmpty()){
            for(Schema.sObjectField eachField : transferFields.values()){
                Schema.DescribeFieldResult eachFieldMetadata = eachField.getDescribe();
                SCVGoWrapper.PicklistOption eachFieldOption = new SCVGoWrapper.PicklistOption();
                eachFieldOption.label = eachFieldMetadata.getLabel();
                if(labelToWrapperMap.containsKey(eachFieldOption.label)){
                    eachFieldOption.value = labelToWrapperMap.get(eachFieldOption.label);
                    eachFieldOption.description = String.valueOf(eachFieldMetadata.getType()).toLowerCase();
                    fieldMetadata.add(eachFieldOption);
                }
            }
        }
        return fieldMetadata;
    }

    private List<SCVGoWrapper.PicklistOption> getTransferTypeOptions(){
        List<SCVGoWrapper.PicklistOption> transferPicklistOptions = new List<SCVGoWrapper.PicklistOption>();
        Schema.DescribeFieldResult typeDescription = Schema.Transfer__c.sobjecttype.getDescribe().fields.getMap().get('Type__c').getDescribe();
        if(typeDescription != null && !typeDescription.getPicklistValues().isEmpty()){
            for(Schema.PicklistEntry eachEntry : typeDescription.getPicklistValues()){
                if(eachEntry.isActive()){
                    SCVGoWrapper.PicklistOption eachTypeOption = new SCVGoWrapper.PicklistOption();
                    eachTypeOption.label = eachEntry.getLabel();
                    eachTypeOption.value = eachEntry.getValue();
                    transferPicklistOptions.add(eachTypeOption);
                }
            }
        }
        return transferPicklistOptions;
    }

    private List<SCVGoWrapper.PicklistOption> getChannelOptions(){
        List<SCVGoWrapper.PicklistOption> transferChannelOptions = new List<SCVGoWrapper.PicklistOption>();
        Schema.DescribeFieldResult channelDescription = Schema.Transfer__c.sobjecttype.getDescribe().fields.getMap().get('Channel__c').getDescribe();
        if(channelDescription != null && !channelDescription.getPicklistValues().isEmpty()){
            for(Schema.PicklistEntry eachEntry : channelDescription.getPicklistValues()){
                if(eachEntry.isActive()){
                    SCVGoWrapper.PicklistOption eachChannelOption = new SCVGoWrapper.PicklistOption();
                    eachChannelOption.label = eachEntry.getLabel();
                    eachChannelOption.value = eachEntry.getValue();
                    transferChannelOptions.add(eachChannelOption);
                }
            }
        }
        return transferChannelOptions;
    }

    private List<SCVGoWrapper.PicklistOption> getChannelQueues(){
        List<SCVGoWrapper.PicklistOption> channelQueuesOptions = new List<SCVGoWrapper.PicklistOption>();
        List<QueueSObject> allChannelQueues = [SELECT Id, Queue.Name, QueueId, SObjectType FROM QueueSObject WHERE SObjectType =: this.transferRecord.transferChannel ORDER BY Queue.Name ASC LIMIT 50000];
        if(allChannelQueues != null && !allChannelQueues.isEmpty()){
            for(QueueSObject eachEntry : allChannelQueues){
                SCVGoWrapper.PicklistOption theOption = new SCVGoWrapper.PicklistOption(eachEntry.Queue.Name, eachEntry.QueueId);
                channelQueuesOptions.add(theOption);
            }
        }
        return channelQueuesOptions;
    }

    private Map<String,String> getLabelAttributeMapping(){
        Map<String,String> fieldApiToAttributeMap = new Map<String,String>();
        fieldApiToAttributeMap.put('Transfer Name', 'transferName');
        fieldApiToAttributeMap.put('Channel', 'transferChannel');
        fieldApiToAttributeMap.put('Type', 'transferType');
        fieldApiToAttributeMap.put('Transfer Label', 'transferLabel');
        fieldApiToAttributeMap.put('Transfer Destination','transferDestination');
        fieldApiToAttributeMap.put('Transfer Message', 'transferMessage');
        fieldApiToAttributeMap.put('Offer Callback', 'transferOfferCallback');
        fieldApiToAttributeMap.put('Callback Prompt', 'transferCallbackPrompt');
        fieldApiToAttributeMap.put('Callback Menu Prompt', 'transferCallbackMenuPrompt');
        fieldApiToAttributeMap.put('Different Callback Number Prompt', 'transferDifferentCallbackNumberPrompt');
        fieldApiToAttributeMap.put('Invalid Number Prompt', 'transferInvalidNumberPrompt');
        fieldApiToAttributeMap.put('Callback Confirmation Prompt', 'transferCallbackConfirmationPrompt');
        fieldApiToAttributeMap.put('Callback End Prompt', 'transferCallbackEndPrompt');
        fieldApiToAttributeMap.put('Callback Threshold (in Minutes)', 'transferCallbackThreshold');
        return fieldApiToAttributeMap;
    }

    @AuraEnabled
    public static UserInterfaceActionResult saveTransferDetails(String transferStringValue){
        UserInterfaceActionResult saveRecord = new UserInterfaceActionResult(true, '');
        try {
            Transfer recordToSave = (Transfer) JSON.deserialize(transferStringValue, Transfer.class);
            Transfer__c sobjectRecord;
            if(recordToSave != null && recordToSave.getTransferSObjectInstance() != null){
                sobjectRecord = recordToSave.getTransferSObjectInstance();
                upsert sobjectRecord;
                saveRecord.hasSucceeded();
                saveRecord.setPayload(sobjectRecord.Id);
            }
            else{
                saveRecord.hasFailed();
                saveRecord.setMessage('Some error occurred. SObject record: ' + sobjectRecord);
            }
        } catch (Exception e) {
            SCVGoLogger.log(e);
            ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'TransferManager');
            saveRecord.hasFailed();
            saveRecord.setMessage(e.getMessage());
        }
        return saveRecord;
    }

    @AuraEnabled
    public static UserInterfaceActionResult getChannelQueuesByChannelName(String transferRecordString){
        UserInterfaceActionResult fetchChannelQueues = new UserInterfaceActionResult(true, '');
        try {
            TransferManager currentClassInstance = new TransferManager();
            currentClassInstance.transferRecord = (Transfer) JSON.deserialize(transferRecordString, Transfer.class);
            fetchChannelQueues.setPayload(currentClassInstance.getChannelQueues());
            fetchChannelQueues.hasSucceeded();
        } catch (Exception e) {
            SCVGoLogger.log(e);
            ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'TransferManager');
            fetchChannelQueues.hasFailed();
            fetchChannelQueues.setMessage(e.getMessage());
        }
        return fetchChannelQueues;
    }
}