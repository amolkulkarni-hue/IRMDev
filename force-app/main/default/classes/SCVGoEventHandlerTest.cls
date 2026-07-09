/**
 * 	Class:				SCVGoEventHandlerTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for SCVGoEventHandler apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@isTest
private class SCVGoEventHandlerTest {
    private static testMethod void testTrigger(){
        SG_Log__e newEvent = new SG_Log__e();
        Test.startTest();
        Database.SaveResult sr = EventBus.publish(newEvent);
        Test.stopTest();
		Assert.areEqual(true, sr.isSuccess());
    }
}