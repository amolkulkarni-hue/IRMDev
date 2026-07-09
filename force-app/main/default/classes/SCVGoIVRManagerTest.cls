/**
 * 	Class:				SCVGoIVRManagerTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for SCVGoIVRManager apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */

@IsTest
public with sharing class SCVGoIVRManagerTest {
    @IsTest
    static void testGetCallExperienceForPhoneNumber(){
        assert.areEqual(null, SCVGoIVRManager.getCallExperienceForPhoneNumber('test').isOpen);
    }

    @IsTest
    static void testGetMenuExperience(){
        Assert.isTrue(SCVGoIVRManager.getMenuExperience('TEST', 'TEST', 'TEST') != null);
    }
}