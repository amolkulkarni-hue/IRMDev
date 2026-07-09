/**
 * 	Class:				SCVGoLoggerTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for SCVGoLogger apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */

@IsTest
public with sharing class SCVGoLoggerTest {
    @IsTest
    static void testGetCallExperienceForPhoneNumber(){
        assert.areEqual(null, SCVGoIVRManager.getCallExperienceForPhoneNumber('test').isOpen);
    }

    @IsTest
    static void testGetMenuExperience(){
        System.assert(SCVGoIVRManager.getMenuExperience('TEST', 'TEST', 'TEST') != null);
    }

    @IsTest
    static void testCreateExceptionLog(){
        SCVGoLogger.createExceptionLog('test', 'test');
        List<SCVGo_Log__c> logs = [SELECT Id FROM SCVGo_Log__c];
        assert.areEqual(0, logs.size());
    }

    @IsTest
    static void testSendMailWithMessage(){
        Test.startTest();
        SCVGoLogger.sendMailWithMessage('TEST', 'TEST', 'TEST');
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        assert.areEqual(0, invocations);
    }

    @IsTest
    static void testCreateExceptionLogWithData(){
        Test.startTest();
        SCVGoLogger.createExceptionLogWithData('TEST', 'TEST', 'TEST', 'TEST');
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        assert.areEqual(0, invocations);
    }

    @IsTest
    static void testLog(){
        Test.startTest();
        SCVGoLogger.log(new SCVGoException());
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        assert.areEqual(0, invocations);
    }

    @IsTest
    static void testLogCalloutException(){
        Test.startTest();
        SCVGoLogger.LogCalloutException(new HttpRequest(), new HttpResponse());
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
        assert.areEqual(0, invocations);
    }
}