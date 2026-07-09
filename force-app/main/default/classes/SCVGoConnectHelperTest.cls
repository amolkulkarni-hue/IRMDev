/**
 * 	Class:				SCVGoConnectHelperTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for SCVGoConnectHelper apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@IsTest
public with sharing class SCVGoConnectHelperTest {
    @IsTest
    static void testGetConnectRequest(){
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        scvGoConnectHelper.getConnectRequest('ListRoutingProfileQueues');
        scvGoConnectHelper.getConnectRequest('ListRoutingProfiles');
        scvGoConnectHelper.getConnectRequest('ListQueues');
        scvGoConnectHelper.getConnectRequest('ListUsers');
        scvGoConnectHelper.getConnectRequest('ListContactFlows');
        scvGoConnectHelper.getConnectRequest('DescribeUser');
        scvGoConnectHelper.getConnectRequest('DescribeQueue');
        scvGoConnectHelper.getConnectRequest('ListSecurityProfiles');
        Assert.areEqual(scvGoConnectHelper.getConnectRequest('ListQueues').getMethod(), 'GET');
    }

    @IsTest
    static void testSetMaxResults(){
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        scvGoConnectHelper.setMaxResults('test', 1);
        Assert.isTrue(scvGoConnectHelper != null);
    }

    @IsTest
    static void testGetListSecurityProfilesRequest(){
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        Assert.areEqual('GET',scvGoConnectHelper.getListSecurityProfilesRequest('test', 1).getMethod());
    }

    @IsTest
    static void testGetListQueuesRequest(){
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        Assert.areEqual('GET', scvGoConnectHelper.getListQueuesRequest('test', 'test', 1, 'test').getMethod());
    }

    @IsTest
    static void testGetListUsersRequest(){
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        Assert.areEqual('GET', scvGoConnectHelper.getListUsersRequest('test', 1, 'test').getMethod());
    }

    @IsTest
    static void testGetListUsersRequest1(){
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        Assert.areEqual('GET', scvGoConnectHelper.getListUsersRequest('test').getMethod());
    }

    @IsTest
    static void testGetListUsersRequest2(){
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        Assert.areEqual('GET', scvGoConnectHelper.getListUsersRequest('test', 2).getMethod());
    }

    @IsTest
    static void testGetListContactFlowsRequest(){
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        List<String> strings = new List<String>();
        strings.add('test');
        Assert.areEqual('GET',scvGoConnectHelper.getListContactFlowsRequest('test', strings, 1, 'test').getMethod());
    }

    @IsTest
    static void testGetListContactFlowsRequest1(){
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        List<String> strings = new List<String>();
        strings.add('test');
        Assert.areEqual('GET',scvGoConnectHelper.getListContactFlowsRequest('test').getMethod());
    }

    @IsTest
    static void testGetListContactFlowsRequest2(){
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        List<String> strings = new List<String>();
        strings.add('test');
        Assert.areEqual('GET', scvGoConnectHelper.getListContactFlowsRequest('test', strings).getMethod());
    }

    @IsTest
    static void testGetDescribeUserRequest(){
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        Assert.areEqual('GET',scvGoConnectHelper.GetDescribeUserRequest('test', 'test').getMethod());
    }

    @IsTest
    static void testGetDescribeQueueRequest(){
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        Assert.areEqual('GET', scvGoConnectHelper.GetDescribeQueueRequest('test', 'test').getMethod());

    }

    @IsTest
    static void testProcessListRequest(){
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());

        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        Assert.isTrue(scvGoConnectHelper.ProcessListRequest(scvGoConnectHelper.getConnectRequest('ListRoutingProfileQueues')) != null);
    }

    @IsTest
    static void testReplaceNextToken(){
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        HttpRequest request = scvGoConnectHelper.getListInstancesRequest();
        String oldEndPoint = request.getEndpoint();
        scvGoConnectHelper.ReplaceNextToken(request,'test');
        String newEndPoint = request.getEndpoint();
        Assert.isTrue(newEndPoint != oldEndPoint);
    }

    @IsTest
    static void testGetListQueuesRequest1(){
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        Assert.areEqual('GET',scvGoConnectHelper.getListQueuesRequest('test').getMethod());
    }

    @IsTest
    static void testGetListQueuesRequest2(){
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        Assert.areEqual('GET', scvGoConnectHelper.getListQueuesRequest('test', 'test').getMethod());
    }

    @IsTest
    static void testGetListQueuesRequest3(){
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
        SCVGoConnectHelper scvGoConnectHelper = new SCVGoConnectHelper();
        Assert.areEqual('GET', scvGoConnectHelper.getListQueuesRequest('test', 'test', 3).getMethod());
    }
}