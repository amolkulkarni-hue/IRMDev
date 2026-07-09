/**
 * 	Class:				SCVLaunchFlowTest
 * 
 * 	Author:				Yashwant Verma (Neuraflash LLC)
 * 
 * 	Purpose:			This class is the Test Class for SCVLaunchFlow
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@isTest
public class SCVLaunchFlowTest {
    @isTest
    Public static void Flowtest() {
        Map<String, object> responseMap;
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.addParameter('phnumber', '1234567890');
        req.addParameter('FlowName', 'NeuraFlash_Launch_Flow ');
        req.requestURI = '/services/apexrest/nfLaunchFlow/'; 
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        test.startTest();
        responseMap = (Map<String, object>) JSON.deserializeUntyped(SCVLaunchFlow.launchFlow());
        test.stopTest();
    }
}