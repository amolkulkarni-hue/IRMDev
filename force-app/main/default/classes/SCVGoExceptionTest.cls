/**
 * 	Class:				SCVGoExceptionTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for SCVGoException apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */

@IsTest
public with sharing class SCVGoExceptionTest {
    @IsTest
    static void testCall(){
        SCVGoException s = new SCVGoException();
        System.assertEquals(s.getTypeName(), 'SCVGoException');
    }
}