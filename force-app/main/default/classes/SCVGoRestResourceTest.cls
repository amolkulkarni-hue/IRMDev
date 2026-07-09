/**
 * 	Class:				SCVGoRestResourceTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for SCVGoRestResource apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@isTest
class SCVGoRestResourceTest {
    
    @isTest
    static void testGet(){
        ContactCenterStatus st = new ContactCenterStatus();
        st.setClose('Demo Leaves');

        RestRequest businessHourCheckRequest = new RestRequest();
        businessHourCheckRequest.requestURI = System.Url.getOrgDomainUrl() + '/services/apexrest/scvproduct';
        businessHourCheckRequest.addParameter('method','checkContactCenterStatus');

        Test.startTest();
        RestContext.request = businessHourCheckRequest;
        SCVGoRestResource.handleGetRequests();
        Assert.areEqual(200, SCVGoRestResource.invocationResult.statusCode);

        new SCVGoTestFactory().createTestHolidayForDate('SCV Go Holiday', Date.today());
        SCVGoRestResource.handleGetRequests();
        Assert.areEqual(200, SCVGoRestResource.invocationResult.statusCode);

        businessHourCheckRequest.addParameter('endpoint','GhostClass');
        SCVGoRestResource.handleGetRequests();
        Assert.areEqual(true, SCVGoRestResource.invocationResult.responseBody.toString().contains('SCVGoContactCenterStateDescriber'));

        Test.stopTest();
    }

    @isTest
    static void testGet2(){
        ContactCenterStatus st = new ContactCenterStatus();
        st.setClose('Demo Leaves');

        RestRequest businessHourCheckRequest = new RestRequest();
        businessHourCheckRequest.requestURI = System.Url.getOrgDomainUrl() + '/services/apexrest/scvproduct';
        businessHourCheckRequest.addParameter('method','getCallExperience');

        Test.startTest();
        RestContext.request = businessHourCheckRequest;
        SCVGoRestResource.handleGetRequests();

        new SCVGoTestFactory().createTestHolidayForDate('SCV Go Holiday', Date.today());
        SCVGoRestResource.handleGetRequests();

        businessHourCheckRequest.addParameter('endpoint','GhostClass');
        SCVGoRestResource.handleGetRequests();
        Assert.areEqual(false, SCVGoRestResource.invocationResult.responseBody.toString().contains('SCVGoContactCenterStateDescriber'));

        Test.stopTest();
    }

    @isTest
    static void testGet3(){
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
        Assert.areEqual(false, SCVGoRestResource.invocationResult.responseBody.toString().contains('SCVGoContactCenterStateDescriber'));

        Test.stopTest();
    }

    @isTest
    static void testGet4(){
        ContactCenterStatus st = new ContactCenterStatus();
        st.setClose('Demo Leaves');

        RestRequest callbackAllowedStatusRequest = new RestRequest();
        callbackAllowedStatusRequest.requestURI = System.Url.getOrgDomainUrl() + '/services/apexrest/scvproduct';
        callbackAllowedStatusRequest.addParameter('method','getCallbackState');
        callbackAllowedStatusRequest.addParameter('businessHour', '');
        callbackAllowedStatusRequest.addParameter('callbackThreshold', '0');

        Test.startTest();
        RestContext.request = callbackAllowedStatusRequest;
        SCVGoRestResource.handleGetRequests();
        Assert.areEqual(false, SCVGoRestResource.invocationResult.responseBody.toString().contains('SCVGoContactCenterStateDescriber'));

        Test.stopTest();
    }
}