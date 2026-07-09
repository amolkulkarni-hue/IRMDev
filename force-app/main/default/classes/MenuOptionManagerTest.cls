/**
 * 	Class:				MenuOptionManagerTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for MenuOptionManager apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */
@IsTest
public with sharing class MenuOptionManagerTest {
    
    @IsTest
    static void testValidGetMenuOptionDetails(){
        Language_Setup__c langSetup = new Language_Setup__c();
        langSetup.Primary_Phone_Number__c = '+1234567890';
        langSetup.Initial_Greeting_Prompt__c = 'Test Greeting';
        insert langSetup; 
        Call_Experience__c callExperience = new Call_Experience__c();
        callExperience.Language_Setup__c = langSetup.id;
        callExperience.Language__c = 'English';
        insert callExperience;
        Menu_Option__c option = new Menu_Option__c();
        option.Call_Experience__c = callExperience.Id;
        insert option;
        Assert.areEqual(MenuOptionManager.getMenuOptionDetails(option.Id).actionStatus, true);
    }

    @IsTest
    static void testInvalidGetMenuOptionDetails(){
        Assert.areEqual(MenuOptionManager.getMenuOptionDetails('test').actionStatus, true);
    }

    @IsTest
    static void testGetRelatedAmazonConnectInstances(){
        Assert.areEqual(MenuOptionManager.getRelatedAmazonConnectInstances('test').actionStatus, true);
    }

    @IsTest
    static void testGetRelatedAmazonConnectFlows(){
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
        Assert.areEqual(MenuOptionManager.getRelatedAmazonConnectFlows('test', 'test').actionStatus, true);
    }

    @IsTest
    static void testSaveMenuTypeInformation(){
        Language_Setup__c langSetup = new Language_Setup__c();
        langSetup.Primary_Phone_Number__c = '+1234567890';
        langSetup.Initial_Greeting_Prompt__c = 'Test Greeting';
        insert langSetup; 
        Call_Experience__c callExperience = new Call_Experience__c();
        callExperience.Language_Setup__c = langSetup.id;
        callExperience.Language__c = 'English';
        insert callExperience;
        Menu_Option__c option = new Menu_Option__c();
        option.Call_Experience__c = callExperience.Id;
        insert option;
        option = [SELECT Id FROM Menu_Option__c];
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
        Map<String, String> infoMap = new Map<String, String>();
        System.debug('option.Id @32: ' + option.Id);
        infoMap.put('id', option.Id);
        Assert.areEqual(MenuOptionManager.saveMenuTypeInformation(infoMap).actionStatus, true);

    }

    @IsTest
    static void testSaveMenuTypeInformationException(){
        Test.setMock(HttpCalloutMock.class, new MockResponseGenerator());
        Map<String, String> infoMap = new Map<String, String>();
        infoMap.put('test', null);
        Assert.areEqual(MenuOptionManager.saveMenuTypeInformation(infoMap).actionStatus, false);

    }
}