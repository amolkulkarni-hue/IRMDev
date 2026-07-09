/**
 * 	Class:				CallExperience
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class handles the creation and conversion for Call Experience object instances.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public with sharing class CallExperience {
    
    public String callExperienceId {get; private set;}
    public Boolean isActive {get; private set;}
    public String greetingPrompt {get; private set;}
    public String retryPrompt1 {get; private set;}
    public String retryPrompt2 {get; private set;}
    public String dtmfOption {get; private set;}
    public String language {get; private set;}
    public String languageSelectionPrompt {get; private set;}
    public Boolean usedInMultiLingual {get; private set;}
    public String fallbackPrompt {get; private set;}
    public String emergencyPrompt {get; private set;}
    public String holidayPrompt {get; private set;}
    public String menuPrompt {get; private set;}
    public String menuPromptARN {get; private set;}
    public String offHoursPrompt {get; private set;}
    public Boolean isEmergency {get; private set;}
    public String errorHandlingPrompt {get; private set;}
    public String agentUnavailabilityPrompt {get; private set;}
    public String workingHoursId {get; private set;}
    public String workingHoursName {get; private set;}
    public String voicemailPrompt {get; private set;}
    public String voicemailAcknowledgementPrompt {get; private set;}
    public String captureIntentPrompt {get; private set;}
    public Boolean captureIntent {get; private set;}
    public String afterHoursAction {get; private set;}
    public String externalTransferNumber {get; private set;}
    public String contactFlowARN {get; private set;}
    public String recordingPrompt {get; private set;}
    public Boolean enableRecordingOption {get; private set;}
    
    //Attributes related to Immediate Transfer
    public String immediateTransferDestination {get; private set;}
    public String immediateTransferId {get; private set;}
    public String immediateTransferLabel {get; private set;}
    public String immediateTransferMessage {get; private set;}
    public String immediateTransferName {get; private set;}
    public String immediateTransferType {get; private set;}

    //Attributes related to Business Hour status
    public Boolean isOpen;
    public Boolean isHoliday;
    public String holidayName;
    public Boolean isOffHours;

    public CallExperience(){
        this.callExperienceId = null;
        this.isActive = false;
        this.greetingPrompt = '';
        this.menuPrompt = '';
        this.dtmfOption = '';
        this.language = '';
        this.languageSelectionPrompt = '';
        this.usedInMultiLingual = false;
        this.offHoursPrompt = '';
        this.agentUnavailabilityPrompt = '';
        this.retryPrompt1 = '';
        this.isEmergency = false;
        this.retryPrompt2 = '';
        this.emergencyPrompt = '';
        this.holidayPrompt = '';
        this.errorHandlingPrompt = '';
        this.workingHoursId = null;
        this.fallbackPrompt = '';
        this.immediateTransferId = null;
        this.voicemailPrompt = '';
        this.voicemailAcknowledgementPrompt = '';
        this.captureIntentPrompt = '';
        this.captureIntent = false;
        this.afterHoursAction = '';
        this.externalTransferNumber = '';
        this.contactFlowARN = '';
        this.recordingPrompt = '';
        this.enableRecordingOption = false;
    }

    public CallExperience(Call_Experience__c inputOption){
        this.setAttributes(inputOption);
    }
	
    public CallExperience(String passedCallExperienceId){
        List<Call_Experience__c> relatedCallExperiences = [SELECT Id, Working_Hours__c,Greeting_Prompt__c, Working_Hours__r.Name, Agent_Unavailability_Prompt_optional__c, Error_Handling_Prompt__c, Is_Active__c, Immediate_Transfer_To__c, DTMF_Option__c, Fallback_Prompt__c, Is_Emergency__c, Language_Selection_Prompt__c, Language__c, Used_in_Multi_Lingual_Setup__c,  Menu_Prompt_ARN__c, Menu_Prompt__c, Off_hours_Prompt__c, Retry_Prompt_1__c, Retry_Prompt_2__c, Holiday_Prompt__c, Emergency_Prompt__c,  Immediate_Transfer_To__r.Transfer_Destination__c, Immediate_Transfer_To__r.Transfer_Label__c, Immediate_Transfer_To__r.Transfer_Message__c, Immediate_Transfer_To__r.Name, Immediate_Transfer_To__r.Type__c, Voicemail_Prompt__c, Voicemail_Acknowledgement_Prompt__c, Intent_Capture_Prompt__c, Capture_Intent__c, After_Hours_Action__c, External_Transfer_Number__c, Contact_Flow_ARN__c, Recording_Opt_in__c, Recording_Opt_in_Message__c
                                                           FROM Call_Experience__c 
                                                           WHERE Id =: passedCallExperienceId];
                                                           system.debug('relatedCallExperiences' +relatedCallExperiences);
                                                           system.debug('passedCallExperienceId'+passedCallExperienceId);
        if(relatedCallExperiences != null && !relatedCallExperiences.isEmpty()){
            this.setAttributes(relatedCallExperiences[0]);
        }
    }

    private void setAttributes(Call_Experience__c inputCallExperience){
        this.callExperienceId = inputCallExperience.Id;
        this.isActive = inputCallExperience.Is_Active__c;
        this.greetingPrompt = inputCallExperience.Greeting_Prompt__c;
        this.menuPrompt = inputCallExperience.Menu_Prompt__c;
        this.menuPromptARN = inputCallExperience.Menu_Prompt_ARN__c;
        this.offHoursPrompt = inputCallExperience.Off_hours_Prompt__c;
        this.retryPrompt1 = inputCallExperience.Retry_Prompt_1__c;
        this.retryPrompt2 = inputCallExperience.Retry_Prompt_2__c;
        this.dtmfOption = inputCallExperience.DTMF_Option__c;
        this.language = inputCallExperience.Language__c;
        this.agentUnavailabilityPrompt = inputCallExperience.Agent_Unavailability_Prompt_optional__c;
        this.languageSelectionPrompt = inputCallExperience.Language_Selection_Prompt__c;
        this.usedInMultiLingual = inputCallExperience.Used_in_Multi_Lingual_Setup__c;
        this.emergencyPrompt = inputCallExperience.Emergency_Prompt__c;
        this.fallbackPrompt = inputCallExperience.Fallback_Prompt__c;
        this.holidayPrompt = inputCallExperience.Holiday_Prompt__c;
        this.isEmergency = inputCallExperience.Is_Emergency__c;
        this.errorHandlingPrompt = inputCallExperience.Error_Handling_Prompt__c;
        this.workingHoursId = inputCallExperience.Working_Hours__c;
        this.workingHoursName = inputCallExperience.Working_Hours__r.Name;
        this.voicemailPrompt = inputCallExperience.Voicemail_Prompt__c;
        this.voicemailAcknowledgementPrompt = inputCallExperience.Voicemail_Acknowledgement_Prompt__c;
        this.captureIntentPrompt = inputCallExperience.Intent_Capture_Prompt__c;
        this.captureIntent = inputCallExperience.Capture_Intent__c;
        this.afterHoursAction = inputCallExperience.After_Hours_Action__c;
        this.externalTransferNumber = inputCallExperience.External_Transfer_Number__c;
        this.contactFlowARN = inputCallExperience.Contact_Flow_ARN__c;
        this.recordingPrompt = inputCallExperience.Recording_Opt_in_Message__c;
        this.enableRecordingOption = inputCallExperience.Recording_Opt_in__c;

        this.immediateTransferDestination = inputCallExperience.Immediate_Transfer_To__r.Transfer_Destination__c;
        this.immediateTransferId = inputCallExperience.Immediate_Transfer_To__c;
        this.immediateTransferLabel = inputCallExperience.Immediate_Transfer_To__r.Transfer_Label__c;
        this.immediateTransferMessage = inputCallExperience.Immediate_Transfer_To__r.Transfer_Message__c;
        this.immediateTransferName = inputCallExperience.Immediate_Transfer_To__r.Name;
        this.immediateTransferType = inputCallExperience.Immediate_Transfer_To__r.Type__c;

        this.setBusinessHourStatus();
    }

    private void setBusinessHourStatus(){
        ContactCenterStatus currentStatus = new SCVGoContactCenterStatusCheck().getContactCenterStatus(this.workingHoursName);
        if(currentStatus != null){
            this.isOpen = currentStatus.isOpen;
            this.isHoliday = currentStatus.isHoliday;
            this.holidayName = currentStatus.holidayName;
            this.isOffHours = currentStatus.isOffHours;
        }
    }
}