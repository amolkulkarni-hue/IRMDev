/**
 * 	Class:				SCVGoContactCenterStateDescriber
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This interface should be implemented if you want to customize the logic of checking the contact center status.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
global interface SCVGoContactCenterStateDescriber {
    ContactCenterStatus getContactCenterStatus(String businessHourName);
}