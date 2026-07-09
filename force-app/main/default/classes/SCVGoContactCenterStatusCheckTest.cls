/**
 * 	Class:				SCVGoContactCenterHelperTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for SCVGoContactCenterStatusCheck apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@IsTest
public with sharing class SCVGoContactCenterStatusCheckTest {
    @IsTest
    static void testGetContactCenterStatus(){
        Holiday holiday = new Holiday(Name='TEST');
        holiday.ActivityDate = System.today();
        insert holiday;
        SCVGoContactCenterStatusCheck classObj = new SCVGoContactCenterStatusCheck();
        Assert.areEqual(false,classObj.getContactCenterStatus('TEST').isOpen);
    }
    @IsTest
    static void testGetContactCenterStatus2(){
        Holiday holiday = new Holiday(Name='TEST');
        holiday.ActivityDate = System.today();
        insert holiday;
        SCVGoContactCenterStatusCheck classObj = new SCVGoContactCenterStatusCheck();
        Assert.areEqual(false,classObj.getContactCenterStatus(null).isOpen);
    }
}