/**
 * 	Class:				LanguageSetup
 * 
 * 	Author:			    Yashwant Verma (NeuraFlash LLC)
 * 
 * 	Purpose:			Used for multi-lingual setup.
 * 
 * 	Requirements:		IMSLB-68
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public with sharing class LanguageSetup {
    public static String LanguageSetup(String dialedPhoneNumber) {
        List<Language_Setup__c> languageSetupList = new List<Language_Setup__c>();
        List<Call_Experience__c> relatedCallExperienceList = new List<Call_Experience__c>();
        Map<String, Object> response = new Map<String, Object>();
        CallExperience relatedExperience = new CallExperience();
        List<CallExperience> relatedExperienceList = new List<CallExperience>();

        languageSetupList = [SELECT Id, Primary_Phone_Number__c, Alternate_Phone_Number__c, Initial_Greeting_Prompt__c, (SELECT Id, Language__c, DTMF_Option__c, Language_Selection_Prompt__c, Used_in_Multi_Lingual_Setup__c from Call_Experiences__r ORDER BY DTMF_Option__c ASC) from Language_Setup__c WHERE Primary_Phone_Number__c =: dialedPhoneNumber];
        if (languageSetupList != null && !languageSetupList.isEmpty()){
            system.debug('languageSetupList'+languageSetupList);
            response.put('InitialGreetingPrompt', languageSetupList[0].Initial_Greeting_Prompt__c);
            relatedCallExperienceList = languageSetupList[0].Call_Experiences__r;
        }
        else{
            languageSetupList = [SELECT Id, Primary_Phone_Number__c, Alternate_Phone_Number__c, Initial_Greeting_Prompt__c, (SELECT Id, Language__c, DTMF_Option__c, Language_Selection_Prompt__c, Used_in_Multi_Lingual_Setup__c from Call_Experiences__r ORDER BY DTMF_Option__c ASC) from Language_Setup__c WHERE Alternate_Phone_Number__c =: dialedPhoneNumber];
            if(languageSetupList != null && !languageSetupList.isEmpty()){
                system.debug('languageSetupList'+languageSetupList);
                response.put('InitialGreetingPrompt', languageSetupList[0].Initial_Greeting_Prompt__c);
                relatedCallExperienceList = languageSetupList[0].Call_Experiences__r;
            }
            else{
                response.put('RecordCount', '0');
            }
        }
        response.put('RecordCount', relatedCallExperienceList.size());

        for(Call_Experience__c eachCallExperience : relatedCallExperienceList){
            relatedExperience = SCVGoIVRManager.getCallExperienceForPhoneNumber(eachCallExperience.Id);
            relatedExperienceList.add(relatedExperience);
        }
        response.put('DefaultLanguage', relatedCallExperienceList[0].Language__c);
        response.put('CallExperiences', JSON.serialize(relatedExperienceList));
        return JSON.serialize(response);
    }
    
}