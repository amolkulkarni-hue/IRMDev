/**
 * 	Class:				SCVGoUtilityTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for SCVGoUtility apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */

@IsTest
public with sharing class SCVGoUtilityTest {
    @IsTest
    static void testReadFieldSet(){
        ContactCenterStatus st = new ContactCenterStatus();
        st.setClose('Demo Leaves');

        RestRequest businessHourCheckRequest = new RestRequest();
        businessHourCheckRequest.requestURI = System.Url.getOrgDomainUrl() + '/services/apexrest/scvproduct';
        businessHourCheckRequest.addParameter('method','getMenuExperience');

        Test.startTest();
        RestContext.request = businessHourCheckRequest;
        SCVGoRestResource.handleGetRequests();

        new SCVGoTestFactory().createTestHolidayForDate('SCV Go Holiday', Date.today());
        SCVGoRestResource.handleGetRequests();

        businessHourCheckRequest.addParameter('endpoint','GhostClass');
        SCVGoRestResource.handleGetRequests();
        Assert.areEqual(200, SCVGoRestResource.invocationResult.statusCode);

        Test.stopTest();
    }
}