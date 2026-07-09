/**
 * 	Class:				SCVGoConfiguratorTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for SCVGoConfigurator apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@IsTest
public with sharing class SCVGoConfiguratorTest {

    @IsTest
    static void testGetListOfAvailableContactCenters(){
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
        assert.areEqual(SCVGoConfigurator.getListOfAvailableContactCenters('TEST').size(), 1);
    }

    @IsTest
    static void testGetMenuOptionDetails(){
        assert.areEqual(MenuOptionManager.getMenuOptionDetails('test').actionStatus, true);
    }

    @IsTest
    static void testGetRelatedAmazonConnectInstances(){
        assert.areEqual(MenuOptionManager.getRelatedAmazonConnectInstances('test').actionStatus, true);
    }

    @IsTest
    static void testGetRelatedAmazonConnectFlows(){
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
        assert.areEqual(MenuOptionManager.getRelatedAmazonConnectFlows('test', 'test').actionStatus, true);

    }

    @IsTest
    static void testSaveMenuTypeInformation(){
        Call_Experience__c callExperience = new Call_Experience__c();
        insert callExperience;
        Menu_Option__c option = new Menu_Option__c();
        option.Call_Experience__c = callExperience.Id;
        insert option;
        option = [SELECT Id FROM Menu_Option__c];
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
        Map<String, String> infoMap = new Map<String, String>();
        infoMap.put('id', option.Id);
        assert.areEqual(MenuOptionManager.saveMenuTypeInformation(infoMap).actionStatus, true);
    }

    @IsTest
    static void testDeploymentParams(){
        SCVGoConfigurator.DeploymentParams params = new SCVGoConfigurator.DeploymentParams();
        params.clientName = 'test';
        params.contactCenterInstance = 'test';
        params.contactCenterRegion = 'test';
        params.deploymentConnection = 'test';
        params.deploymentRegion = 'test';
        params.deployHelperLambda = true;
        params.deployContactFlows = true;
        params.callCenterApiName = 'test';
        assert.areEqual(params.clientName, 'test');
    }

    @IsTest
    static void testSetOrgDomainName(){
        SCVGoConfigurator.DeploymentParams params = new SCVGoConfigurator.DeploymentParams();
        params.setOrgDomainName();
        assert.areEqual(params.orgDomainName, System.Url.getOrgDomainUrl().toExternalForm());
    }

    @IsTest
    static void testGetAmazonConnectInstances(){
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
        assert.areEqual(SCVGoConfigurator.getAmazonConnectInstances('test').size(), 0);
    }

    @IsTest
    static void testGetAmazonConnectInstancesFailedCallout(){
        Test.setMock(HttpCalloutMock.class, new MockFailureResponseGenerator());
        assert.areEqual(SCVGoConfigurator.getAmazonConnectInstances('test').size(), 0);
    }

    @IsTest
    static void testGetListOfAvailableContactCentersFailedCallout(){
        Test.setMock(HttpCalloutMock.class, new MockFailureResponseGenerator());
        assert.areEqual(SCVGoConfigurator.getListOfAvailableContactCenters('TEST').size(), 1);
    }

    @IsTest
    static void testGetListOfAvailableContactCentersFailedCallout2(){
        Test.setMock(HttpCalloutMock.class, new MockResponseGeneratorSCVGo());

        try{
            SCVGoConfigurator.getListOfAvailableContactCenters('TEST');
        }
        catch(Exception e){
            assert.areEqual(e.getTypeName(), 'System.AuraHandledException');
        }
    }

}