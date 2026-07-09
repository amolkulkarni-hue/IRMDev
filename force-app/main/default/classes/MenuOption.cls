/**
 * 	Class:				MenuOption
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class handles the creation and conversion for Menu Option object instances.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public class MenuOption {
    @AuraEnabled
    public String menuOptionId;
    @AuraEnabled
    public String callExperienceId;
    @AuraEnabled
    public String callExperienceName;
    @AuraEnabled
    public String contactFlowToInvoke;
    @AuraEnabled
    public String parentMenuOptionId;
    @AuraEnabled
    public String parentMenuOptionName;
    @AuraEnabled
    public String selfServiceMessage;
    @AuraEnabled
    public String subMenuPrompt;
    @AuraEnabled
    public String menuOptionType;
    @AuraEnabled
    public String menuName;
    @AuraEnabled
    public String menuUserChoice;

    //Attributes related to Transfer
    public String transferDestination {get; private set;}
    @AuraEnabled
    public String transferId {get; private set;}
    @AuraEnabled
    public String transferLabel {get; private set;}
    public String transferMessage {get; private set;}
    public String transferName {get; private set;}
    public String transferType {get; private set;}
    public Boolean transferOfferCallback {get; private set;}
    public String transferCallbackPrompt {get; private set;}
    public String transferCallbackMenuPrompt {get; private set;}
    public String transferDifferentCallbackNumberPrompt {get; private set;}
    public String transferInvalidNumberPrompt {get; private set;}
    public String transferCallbackConfirmationPrompt {get; private set;}
    public String transferCallbackEndPrompt {get; private set;}
    public Integer transferCallbackThreshold {get; private set;}

    
    public MenuOption(Menu_Option__c inputOption){
        this.setAttributes(inputOption);
    }
    
    public Menu_Option__c getMenuOptionObjectInstance(){
        Menu_Option__c outputOption = new Menu_Option__c();
        outputOption.Id = this.menuOptionId;
        outputOption.Call_Experience__c = this.callExperienceId;
        outputOption.Contact_Flow_ARN__c = this.contactFlowToInvoke;
        outputOption.Parent_Menu__c = this.parentMenuOptionId;
        outputOption.Name = this.menuName;
        outputOption.Self_service_Message__c = this.selfServiceMessage;
        outputOption.Type__c = this.menuOptionType;
        outputOption.User_Choice__c = this.menuUserChoice;
        outputOption.Sub_menu_Prompt__c = this.subMenuPrompt;
        outputOption.Transfer_To__c = this.transferId;
        return outputOption;
    }

    public MenuOption(String callExperienceId, String parentMenuId, String userSelection){
        List<Menu_Option__c> relatedCallExperiences = [SELECT Id, Name, Call_Experience__c, Call_Experience__r.Name, Parent_Menu__c, Parent_Menu__r.Name, Contact_Flow_ARN__c, Self_service_Message__c, Sub_menu_Prompt__c, Type__c, User_Choice__c, Transfer_To__c, Transfer_To__r.Transfer_Destination__c, Transfer_To__r.Transfer_Label__c, Transfer_To__r.Transfer_Message__c, Transfer_To__r.Name, Transfer_To__r.Type__c, Transfer_To__r.Offer_Callback__c, Transfer_To__r.Callback_Prompt__c, Transfer_To__r.Callback_Menu_Prompt__c, Transfer_To__r.Different_Callback_Number_Prompt__c, Transfer_To__r.Invalid_Number_Prompt__c, Transfer_To__r.Callback_Confirmation_Prompt__c, Transfer_To__r.Callback_End_Prompt__c, Transfer_To__r.Callback_Threshold_In_Minutes__c FROM Menu_Option__c WHERE Call_Experience__c =: callExperienceId AND Parent_Menu__c =: parentMenuId AND User_Choice__c =: userSelection];
        if(relatedCallExperiences != null && !relatedCallExperiences.isEmpty()){
            this.setAttributes(relatedCallExperiences[0]);
        }
    }
    
	@TestVisible
    private void setAttributes(Menu_Option__c inputMenuOption){
        this.menuOptionId = inputMenuOption.Id;
        this.callExperienceId = inputMenuOption.Call_Experience__c;
        this.callExperienceName = inputMenuOption.Call_Experience__r.Name;
        this.contactFlowToInvoke = inputMenuOption.Contact_Flow_ARN__c;
        this.parentMenuOptionId = inputMenuOption.Parent_Menu__c;
        this.parentMenuOptionName = inputMenuOption.Parent_Menu__r.Name;
        this.menuName = inputMenuOption.Name;
        this.selfServiceMessage = inputMenuOption.Self_service_Message__c;
        this.menuOptionType = inputMenuOption.Type__c;
        this.menuUserChoice = inputMenuOption.User_Choice__c;
        this.subMenuPrompt = inputMenuOption.Sub_menu_Prompt__c;

        this.transferDestination = inputMenuOption.Transfer_To__r.Transfer_Destination__c;
        this.transferId = inputMenuOption.Transfer_To__c;
        this.transferLabel = inputMenuOption.Transfer_To__r.Transfer_Label__c;
        this.transferMessage = inputMenuOption.Transfer_To__r.Transfer_Message__c;
        this.transferName = inputMenuOption.Transfer_To__r.Name;
        this.transferType = inputMenuOption.Transfer_To__r.Type__c;
        this.transferOfferCallback = inputMenuOption.Transfer_To__r.Offer_Callback__c;
        this.transferCallbackPrompt = inputMenuOption.Transfer_To__r.Callback_Prompt__c;
        this.transferCallbackMenuPrompt = inputMenuOption.Transfer_To__r.Callback_Menu_Prompt__c;
        this.transferDifferentCallbackNumberPrompt = inputMenuOption.Transfer_To__r.Different_Callback_Number_Prompt__c;
        this.transferInvalidNumberPrompt = inputMenuOption.Transfer_To__r.Invalid_Number_Prompt__c;
        this.transferCallbackConfirmationPrompt = inputMenuOption.Transfer_To__r.Callback_Confirmation_Prompt__c;
        this.transferCallbackEndPrompt = inputMenuOption.Transfer_To__r.Callback_End_Prompt__c;
        this.transferCallbackThreshold = (Integer) inputMenuOption.Transfer_To__r.Callback_Threshold_In_Minutes__c;
    }
}