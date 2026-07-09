/**
 * 	Class:				SCVGoTestFactory
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			This class creates test data for test classes which are a part of SCV Go solution.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
public with sharing class SCVGoTestFactory {

    public static final String successBody = '<CreateStackResponse xmlns="http://cloudformation.amazonaws.com/doc/2010-05-15/"><CreateStackResult><StackId>arn:aws:cloudformation:us-west-2:955504846581:stack/AnAwesomeCustomer00De0000005X39GEAS1664267727415/5722beb0-3e3f-11ed-997c-06865b5b216b</StackId></CreateStackResult><ResponseMetadata><RequestId>a5c19b2c-3d90-47c2-9b33-9d25bc4f7d21</RequestId></ResponseMetadata></CreateStackResponse>';
    public static final String errorBody = '<ErrorResponse xmlns="http://cloudformation.amazonaws.com/doc/2010-05-15/"><Error><Type>Sender</Type><Code>ValidationError</Code><Message>S3 error: The specified key does not exist.For more information check http://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html</Message></Error><RequestId>a25c1076-594b-4153-b889-8897c2a54b1c</RequestId></ErrorResponse>';
    
    public static List<SCVGoWrapper.PicklistOption> getTestNamedCredentialPicklistOptionForAWSService(String serviceName){
        List<SCVGoWrapper.PicklistOption> picklistOptions = new List<SCVGoWrapper.PicklistOption>();
        SCVGoWrapper.PicklistOption theNamedCred = new SCVGoWrapper.PicklistOption();
        theNamedCred.label = 'AWS ' + serviceName + 'Named Cred';
        theNamedCred.value = 'AWS' + serviceName + 'NamedCred';
        theNamedCred.description = 'https://' + serviceName + '.us-west-2.amazonaws.com';
        picklistOptions.add(theNamedCred);
        return picklistOptions;
    }

    public static SCVGoWrapper.ListInstances getTestContactCenterInstance(){
        SCVGoWrapper.InstanceSummary instanceSummary = new SCVGoWrapper.InstanceSummary();
        instanceSummary.Delay = 0;
        instanceSummary.arn = 'arn:aws:connect:us-west-2:182937462748:instance/ecaaf4f6-816a-451c-a93b-10085e728076';
        instanceSummary.id = 'ecaaf4f6-816a-451c-a93b-10085e728076';
        instanceSummary.IdentityManagementType = 'SAML';
        instanceSummary.InstanceAlias = 'test-connect-instance' + UserInfo.getOrganizationId().toLowerCase();
        instanceSummary.InboundCallsEnabled = false;
        instanceSummary.OutboundCallsEnabled = false;
        instanceSummary.InstanceStatus = 'ACTIVE';
        instanceSummary.ServiceRole = null;

        SCVGoWrapper.ListInstances listInstanceResult = new SCVGoWrapper.ListInstances();
        listInstanceResult.InstanceSummaryList = new List<SCVGoWrapper.InstanceSummary>{instanceSummary};
        return listInstanceResult;
    }

    public static HttpRequest getTestHttpRequest(){
        HttpRequest theRequest = new HttpRequest();
        theRequest.setEndpoint('https://some.dummy.request.com');
        theRequest.setMethod('GET');
        return theRequest;
    }

    public static HttpResponse getTestHttpResponse(){
        HttpResponse theResponse = new HttpResponse();
        theResponse.setStatusCode(404);
        theResponse.setStatus('Not found');
        return theResponse;
    }

    public BusinessHours getFullDayBusinessHour(){
        BusinessHours fullDay = new BusinessHours();
        fullDay = [SELECT Id, TimeZoneSidKey, SundayStartTime, SundayEndTime, MondayStartTime, MondayEndTime, TuesdayStartTime, TuesdayEndTime, WednesdayStartTime, WednesdayEndTime, ThursdayStartTime, ThursdayEndTime, FridayStartTime, FridayEndTime, SaturdayStartTime, SaturdayEndTime FROM BusinessHours LIMIT 1];
        return fullDay;
    }
    public List<Id> getTestContactCenterUsers(){
        List<Id> result = new List<Id>();
        result.add(UserInfo.getUserId());
        return result;
    }
    public void createTestHolidayForDate(String holidayName, Date dateForHoliday){
        insert new Holiday(Name = holidayName, ActivityDate = dateForHoliday);
    }
}