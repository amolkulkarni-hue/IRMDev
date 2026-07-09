/**
 * 	Class:				SCVGoTestFactoryTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for SCVGoTestFactory apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@IsTest
public with sharing class SCVGoTestFactoryTest {
    @IsTest
    static void testGetTestNamedCredentialPicklistOptionForAWSService(){
        Assert.areEqual(1, SCVGoTestFactory.getTestNamedCredentialPicklistOptionForAWSService('TEST').size());
    }

    @IsTest
    static void testGetTestContactCenterInstance(){
        Assert.areEqual(1, SCVGoTestFactory.getTestContactCenterInstance().InstanceSummaryList.size());
    }

    @IsTest
    static void testGetTestHttpRequest(){
        Assert.areEqual('GET', SCVGoTestFactory.getTestHttpRequest().getMethod());
    }

    @IsTest
    static void testGetTestHttpResponse(){
        Assert.areEqual(404,SCVGoTestFactory.getTestHttpResponse().getStatusCode());
    }

    @IsTest
    static void testGetTestContactCenterUsers(){
        SCVGoTestFactory factory = new SCVGoTestFactory();
        Assert.areEqual(1, factory.getTestContactCenterUsers().size());
    }
}