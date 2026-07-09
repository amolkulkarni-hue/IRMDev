/**
 * 	Class:				SCVGoContactCenterHelper
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class will provide the status for the contact center based upon the input business hour 
* 						OR custom implementation of checking the contact center status.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public class SCVGoContactCenterHelper {

    public static ContactCenterStatus checkContactCenterStatus(RestRequest checkStateRequest){
        String customLogicForContactCenterStatusCheck = checkStateRequest.params.get('endpoint');
        String inputBusinessHour = checkStateRequest.params.get('businessHour');
        System.debug('customLogicForContactCenterStatusCheck : ' + checkStateRequest.params);

        if(String.isNotBlank(customLogicForContactCenterStatusCheck) && !'undefined'.equals(customLogicForContactCenterStatusCheck)){
            List<ApexTypeImplementor> relatedImplementors = [SELECT Id, ClassName 
                                                                FROM ApexTypeImplementor 
                                                                WHERE InterfaceName = 'SCVGoContactCenterStateDescriber'
                                                                AND InterfaceNamespacePrefix = 'nfscvxlr8' 
                                                                AND ClassName =: customLogicForContactCenterStatusCheck];
            if(relatedImplementors == null || relatedImplementors.isEmpty()){
                throw new SCVGoException('Either the provided class does not exist OR it does not implement SCVGoContactCenterStateDescriber interface. Provided Class: ' + customLogicForContactCenterStatusCheck);
            }
        }
        else{
            customLogicForContactCenterStatusCheck = 'SCVGoContactCenterStatusCheck';
        }
        SCVGoContactCenterStateDescriber statusChecker = (SCVGoContactCenterStateDescriber) Type.forName(customLogicForContactCenterStatusCheck).newInstance();
        return statusChecker.getContactCenterStatus(inputBusinessHour);
    }
    
    public static Boolean checkIfCallbackIsAllowed(RestRequest checkCallbackStateRequest){
        String inputBusinessHour = checkCallbackStateRequest.params.get('businessHour');
        String callbackThreshold = checkCallbackStateRequest.params.get('callbackThreshold');
        return new SCVGoContactCenterStatusCheck().checkIfCallbackIsAllowed(inputBusinessHour, callbackThreshold);
    }
}