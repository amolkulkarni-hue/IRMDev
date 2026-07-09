/**
 * 	Class:				SCVGoRestResource
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class handles the different Http requests sent from AWS Lambda function, like 
 * 						checking contact center status, fetching details about IVR experience, menu options etc.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@RestResource(urlMapping='/scvgo')
global class SCVGoRestResource {
    
    public static RestResponse invocationResult{
        get;
        private set;
    }
    
    static{
        invocationResult = new RestResponse();
    }

    @HttpGet
    global static String handleGetRequests() {
        RestRequest req = RestContext.request;
        String invokedMethod = RestContext.request.params.get('method');
        System.debug('invokedMethod: ' + invokedMethod);
        try{
            if('checkContactCenterStatus'.equals(invokedMethod)){
                ContactCenterStatus status = SCVGoContactCenterHelper.checkContactCenterStatus(req);
                invocationResult.responseBody = Blob.valueOf(JSON.serialize(status));
            }
            else if('getCallExperience'.equals(invokedMethod)){
                String callExperienceIdFromRequest = req.params.get('callExperienceId').trim();
                CallExperience relatedExperience = SCVGoIVRManager.getCallExperienceForPhoneNumber(callExperienceIdFromRequest);
                invocationResult.responseBody = Blob.valueOf(JSON.serialize(relatedExperience));
            }
            else if('getCallbackState'.equals(invokedMethod)){
                Boolean isCallbackAllowed = SCVGoContactCenterHelper.checkIfCallbackIsAllowed(req);
                invocationResult.responseBody = Blob.valueOf(JSON.serialize(isCallbackAllowed));
            }
            else if('getMenuExperience'.equals(invokedMethod)){
                String callExperienceId = req.params.get('callExperienceId');
                String parentMenuId = req.params.get('parentMenuId');
                if('null'.equals(parentMenuId)){
                    parentMenuId = null;
                }
                String userSelection = req.params.get('userSelection');
                MenuOption relatedExperience = SCVGoIVRManager.getMenuExperience(callExperienceId, parentMenuId, userSelection);
                invocationResult.responseBody = Blob.valueOf(JSON.serialize(relatedExperience));
            }
            else if('getLanguageSetup'.equals(invokedMethod)){
                String dialedPhoneNumberFromRequest = '+' + req.params.get('dialedPhoneNumber').trim();
                invocationResult.responseBody = Blob.valueOf(LanguageSetup.LanguageSetup(dialedPhoneNumberFromRequest));
            }
            invocationResult.statusCode = 200;
        }
        catch(Exception ex){
            SCVGoLogger.log(ex);
            invocationResult.statusCode = 500;
            invocationResult.responseBody = Blob.valueOf(ex.getMessage());
        }
        return JSON.serialize(invocationResult);
    }
}