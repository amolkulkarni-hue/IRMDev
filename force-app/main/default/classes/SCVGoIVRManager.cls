/**
 * 	Class:				SCVGoEventHandler
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class handled the IVR experience, like how a call is driven and what options are to be presented.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public class SCVGoIVRManager {

    public static CallExperience getCallExperienceForPhoneNumber(String passedCallExperienceId){
        return new CallExperience(passedCallExperienceId);
    }

    public static MenuOption getMenuExperience(String callExperienceId, String parentMenuId, String userSelection){
        return new MenuOption(callExperienceId, parentMenuId, userSelection);
    }
}