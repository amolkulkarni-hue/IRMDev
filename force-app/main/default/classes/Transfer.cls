/**
 * 	Class:				Transfer
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class handles the creation and converstion of wrapper object for Transfer object instances.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public with sharing class Transfer {
    
    @AuraEnabled
    public String transferChannel {get; private set;}
    @AuraEnabled
    public String transferDestination {get; private set;}
    @AuraEnabled
    public String transferId {get; private set;}
    @AuraEnabled
    public String transferLabel {get; private set;}
    @AuraEnabled
    public String transferMessage {get; private set;}
    @AuraEnabled
    public String transferName {get; private set;}
    @AuraEnabled
    public String transferType {get; private set;}
    @AuraEnabled
    public Boolean transferOfferCallback {get; private set;}
    @AuraEnabled
    public String transferCallbackPrompt {get; private set;}
    @AuraEnabled
    public String transferCallbackMenuPrompt {get; private set;}
    @AuraEnabled
    public String transferDifferentCallbackNumberPrompt {get; private set;}
    @AuraEnabled
    public String transferInvalidNumberPrompt {get; private set;}
    @AuraEnabled
    public String transferCallbackConfirmationPrompt {get; private set;}
    @AuraEnabled
    public String transferCallbackEndPrompt {get; private set;}
    @AuraEnabled
    public Integer transferCallbackThreshold {get; private set;}
    
    public Transfer(){
        this.transferChannel = 'LiveChatTranscript';
        this.transferDestination = '';
        this.transferId = null;
        this.transferLabel = '';
        this.transferMessage = '';
        this.transferName = '';
        this.transferType = 'Queue Transfer';
        this.transferOfferCallback = false;
        this.transferCallbackPrompt = '';
        this.transferCallbackMenuPrompt = '';
        this.transferDifferentCallbackNumberPrompt = '';
        this.transferInvalidNumberPrompt = '';
        this.transferCallbackConfirmationPrompt = '';
        this.transferCallbackEndPrompt = '';
        this.transferCallbackThreshold = 0;
    }

    public Transfer(Transfer__c inputOption){
        this.transferChannel = inputOption.Channel__c;
        this.transferDestination = inputOption.Transfer_Destination__c;
        this.transferId = inputOption.Id;
        this.transferLabel = inputOption.Transfer_Label__c;
        this.transferMessage = inputOption.Transfer_Message__c;
        this.transferName = inputOption.Name;
        this.transferType = inputOption.Type__c;
        this.transferOfferCallback = inputOption.Offer_Callback__c;
        this.transferCallbackPrompt = inputOption.Callback_Prompt__c;
        this.transferCallbackMenuPrompt = inputOption.Callback_Menu_Prompt__c;
        this.transferDifferentCallbackNumberPrompt = inputOption.Different_Callback_Number_Prompt__c;
        this.transferInvalidNumberPrompt = inputOption.Invalid_Number_Prompt__c;
        this.transferCallbackConfirmationPrompt = inputOption.Callback_Confirmation_Prompt__c;
        this.transferCallbackEndPrompt = inputOption.Callback_End_Prompt__c;
        this.transferCallbackThreshold = (Integer) inputOption.Callback_Threshold_In_Minutes__c;
    }
    
    public Transfer__c getTransferSObjectInstance(){
        Transfer__c outputOption = new Transfer__c();
        outputOption.Channel__c = this.transferChannel;
        outputOption.Transfer_Destination__c = this.transferDestination;
        outputOption.Id = this.transferId;
        outputOption.Transfer_Label__c = this.transferLabel;
        outputOption.Transfer_Message__c = this.transferMessage;
        outputOption.Name = this.transferName;
        outputOption.Type__c = this.transferType;
        outputOption.Offer_Callback__c = this.transferOfferCallback;
        outputOption.Callback_Prompt__c = this.transferCallbackPrompt;
        outputOption.Callback_Menu_Prompt__c = this.transferCallbackMenuPrompt;
        outputOption.Different_Callback_Number_Prompt__c = this.transferDifferentCallbackNumberPrompt;
        outputOption.Invalid_Number_Prompt__c = this.transferInvalidNumberPrompt;
        outputOption.Callback_Confirmation_Prompt__c = this.transferCallbackConfirmationPrompt;
        outputOption.Callback_End_Prompt__c = this.transferCallbackEndPrompt;
        outputOption.Callback_Threshold_In_Minutes__c = this.transferCallbackThreshold;
        return outputOption;
    }
}