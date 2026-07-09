/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Apex Test class to test the Get Service Market functionality implemented in Apex Class,
* NAS_GetServiceMarketNTransportationZone.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public with sharing class NAS_GetSrvcMarketNTsptZoneTest {
    /**
     * @name setupTestData
     * @description Sets up Test data needed for all test cases in this Test Class.
    **/
	@testSetup
    public static void setupTestData()
    {

        NAS_TestDataFactory.setupTestData(1);
    	NAS_TestDataFactory.createCase(1, NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE, 
                                       true, NAS_Constants.PICKLIST_STATUS_CASE_NEW);
    }
    /**
    * @name getServiceAndMarketTransportationZoneTestSuccessON
    * @description Test Success response with order number input.
    **/
    @isTest
    public static void getServiceAndMarketTransportationZoneTestSuccessON() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
    	List<Case> caseList = [SELECT Id FROM Case];
        for(Case c : caseList)
       	{
       		c.NAS_Order_Number__c = String.valueOf(NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_ORDER_NUMBER);
       	}
       	update caseList;
        Test.startTest();
        NAS_GetServiceMarketNTransportationZone.getServiceAndMarketTransportationZone(caseList[0].Id);
        Test.stopTest();
        Case c = [SELECT Id, NAS_Service_Market_Id__c, NAS_Service_Market__c, NAS_Transportation_Zone__c FROM Case WHERE Id = :caseList[0].Id];
        System.assertNotEquals(null, c.NAS_Service_Market_Id__c, 'Incorrect Service Market Id');
        System.assertNotEquals(null, c.NAS_Service_Market__c, 'Incorrect Servie Market');
        System.assertNotEquals(null, c.NAS_Transportation_Zone__c, 'Incorrect Transportation Zone');
    }
    /**
    * @name getServiceAndMarketTransportationZoneTestSuccessZip
    * @description Test Success response with zip code & country input.
    **/
    @isTest
    public static void getServiceAndMarketTransportationZoneTestSuccessZip() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
    	List<Case> caseList = [SELECT Id FROM Case];
        for(Case c : caseList)
       	{
       		c.Zip__c = NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_ZIP_CODE;
            c.NAS_SKP_Country__c = NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_COUNTRY_CODE;
       	}
       	update caseList;
        Test.startTest();
        NAS_GetServiceMarketNTransportationZone.getServiceAndMarketTransportationZone(caseList[0].Id);
        Test.stopTest();
        Case c = [SELECT Id, NAS_Service_Market_Id__c, NAS_Service_Market__c, NAS_Transportation_Zone__c FROM Case WHERE Id = :caseList[0].Id];
        System.assertNotEquals(null, c.NAS_Service_Market_Id__c, 'Incorrect Service Market Id');
        System.assertNotEquals(null, c.NAS_Service_Market__c, 'Incorrect Servie Market');
        System.assertNotEquals(null, c.NAS_Transportation_Zone__c, 'Incorrect Transportation Zone');
    }
    /**
    * @name getServiceAndMarketTransportationZoneTestFailureNoParam
    * @description Test Failure response with no input.
    **/
    @isTest
    public static void getServiceAndMarketTransportationZoneTestFailureNoParam() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
    	List<Case> caseList = [SELECT Id FROM Case];
        Test.startTest();
        NAS_GetServiceMarketNTransportationZone.getServiceAndMarketTransportationZone(caseList[0].Id);
        Test.stopTest();
        Case c = [SELECT Id, NAS_Service_Market_Id__c, NAS_Service_Market__c, NAS_Transportation_Zone__c FROM Case WHERE Id = :caseList[0].Id];
        System.assertEquals(null, c.NAS_Service_Market_Id__c, 'Incorrect Service Market Id');
        System.assertEquals(null, c.NAS_Service_Market__c, 'Incorrect Servie Market');
        System.assertEquals(null, c.NAS_Transportation_Zone__c, 'Incorrect Transportation Zone');
    }
    /**
    * @name getServiceAndMarketTransportationZoneTestFailureONIncorrectSize
    * @description Test Failure response with order number of incorrect length.
    **/
    @isTest
    public static void getServiceAndMarketTransportationZoneTestFailureONIncorrectSize() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
    	List<Case> caseList = [SELECT Id FROM Case];
        for(Case c : caseList)
       	{
       		c.NAS_Order_Number__c = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_ON_SMALL;
       	}
       	update caseList;
        Test.startTest();
        NAS_GetServiceMarketNTransportationZone.getServiceAndMarketTransportationZone(caseList[0].Id);
        Test.stopTest();
        Case c = [SELECT Id, NAS_Service_Market_Id__c, NAS_Service_Market__c, NAS_Transportation_Zone__c FROM Case WHERE Id = :caseList[0].Id];
        System.assertEquals(null, c.NAS_Service_Market_Id__c, 'Incorrect Service Market Id');
        System.assertEquals(null, c.NAS_Service_Market__c, 'Incorrect Servie Market');
        System.assertEquals(null, c.NAS_Transportation_Zone__c, 'Incorrect Transportation Zone');
    }
    /**
    * @name getServiceAndMarketTransportationZoneTestFailureZipNoCountry
    * @description Test Failure response with zip code and no country as input.
    **/
    @isTest
    public static void getServiceAndMarketTransportationZoneTestFailureZipNoCountry() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
    	List<Case> caseList = [SELECT Id FROM Case];
        for(Case c : caseList)
       	{
       		c.Zip__c = NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_ZIP_CODE;
            c.NAS_SKP_Country__c = null;
       	}
       	update caseList;
        Test.startTest();
        NAS_GetServiceMarketNTransportationZone.getServiceAndMarketTransportationZone(caseList[0].Id);
        Test.stopTest();
        Case c = [SELECT Id, NAS_Service_Market_Id__c, NAS_Service_Market__c, NAS_Transportation_Zone__c FROM Case WHERE Id = :caseList[0].Id];
        System.assertEquals(null, c.NAS_Service_Market_Id__c, 'Incorrect Service Market Id');
        System.assertEquals(null, c.NAS_Service_Market__c, 'Incorrect Servie Market');
        System.assertEquals(null, c.NAS_Transportation_Zone__c, 'Incorrect Transportation Zone');
    }
    /**
    * @name getServiceAndMarketTransportationZoneTestFailureZipLarge
    * @description Test Failure response with zip code of incorrect length as input.
    **/
    @isTest
    public static void getServiceAndMarketTransportationZoneTestFailureZipLarge() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
    	List<Case> caseList = [SELECT Id FROM Case];
        for(Case c : caseList)
       	{
       		c.Zip__c = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_ZIP_LARGE;
       	}
       	update caseList;
        Test.startTest();
        NAS_GetServiceMarketNTransportationZone.getServiceAndMarketTransportationZone(caseList[0].Id);
        Test.stopTest();
        Case c = [SELECT Id, NAS_Service_Market_Id__c, NAS_Service_Market__c, NAS_Transportation_Zone__c FROM Case WHERE Id = :caseList[0].Id];
        System.assertEquals(null, c.NAS_Service_Market_Id__c, 'Incorrect Service Market Id');
        System.assertEquals(null, c.NAS_Service_Market__c, 'Incorrect Servie Market');
        System.assertEquals(null, c.NAS_Transportation_Zone__c, 'Incorrect Transportation Zone');
    }
    /**
    * @name getServiceAndMarketTransportationZoneTestFailureNoZip
    * @description Test Failure response with only country as input.
    **/
    @isTest
    public static void getServiceAndMarketTransportationZoneTestFailureNoZip() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
    	List<Case> caseList = [SELECT Id FROM Case];
        for(Case c : caseList)
       	{
       		c.NAS_SKP_Country__c = NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_COUNTRY_CODE;
       	}
       	update caseList;
        Test.startTest();
        NAS_GetServiceMarketNTransportationZone.getServiceAndMarketTransportationZone(caseList[0].Id);
        Test.stopTest();
        Case c = [SELECT Id, NAS_Service_Market_Id__c, NAS_Service_Market__c, NAS_Transportation_Zone__c FROM Case WHERE Id = :caseList[0].Id];
        System.assertEquals(null, c.NAS_Service_Market_Id__c, 'Incorrect Service Market Id');
        System.assertEquals(null, c.NAS_Service_Market__c, 'Incorrect Servie Market');
        System.assertEquals(null, c.NAS_Transportation_Zone__c, 'Incorrect Transportation Zone');
    }
    /**
    * @name getServiceAndMarketTransportationZoneTestFailureNoMarket
    * @description Test Failure response with zip code where no associated market exists.
    **/
    @isTest
    public static void getServiceAndMarketTransportationZoneTestFailureNoMarket() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
    	List<Case> caseList = [SELECT Id FROM Case];
        for(Case c : caseList)
       	{
       		c.Zip__c = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_ZIP_MARKET_NOT_FOUND;
            c.NAS_SKP_Country__c = NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_COUNTRY_CODE;
       	}
       	update caseList;
        Test.startTest();
        NAS_GetServiceMarketNTransportationZone.getServiceAndMarketTransportationZone(caseList[0].Id);
        Test.stopTest();
        Case c = [SELECT Id, NAS_Service_Market_Id__c, NAS_Service_Market__c, NAS_Transportation_Zone__c FROM Case WHERE Id = :caseList[0].Id];
        System.assertEquals(null, c.NAS_Service_Market_Id__c, 'Incorrect Service Market Id');
        System.assertEquals(null, c.NAS_Service_Market__c, 'Incorrect Servie Market');
        System.assertEquals(null, c.NAS_Transportation_Zone__c, 'Incorrect Transportation Zone');
    }
    /**
    * @name getServiceAndMarketTransportationZoneTestPartialSuccessNoMarket
    * @description Test Partial Success response with zip code where no associated zone exists.
    **/
    @isTest
    public static void getServiceAndMarketTransportationZoneTestPartialSuccessNoZone() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
    	List<Case> caseList = [SELECT Id FROM Case];
        for(Case c : caseList)
       	{
       		c.Zip__c = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_ZIP_NO_TRANSPORTATION_ZONE;
            c.NAS_SKP_Country__c = NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_COUNTRY_CODE;
       	}
       	update caseList;
        Test.startTest();
        NAS_GetServiceMarketNTransportationZone.getServiceAndMarketTransportationZone(caseList[0].Id);
        Test.stopTest();
        Case c = [SELECT Id, NAS_Service_Market_Id__c, NAS_Service_Market__c, NAS_Transportation_Zone__c FROM Case WHERE Id = :caseList[0].Id];
        System.assertNotEquals(null, c.NAS_Service_Market_Id__c, 'Incorrect Service Market Id');
        System.assertNotEquals(null, c.NAS_Service_Market__c, 'Incorrect Servie Market');
        System.assertEquals(null, c.NAS_Transportation_Zone__c, 'Incorrect Transportation Zone');
    }
    /**
    * @name getServiceAndMarketTransportationZoneTestFailureIncorrectZip
    * @description Test Failure response with incorrect zip code.
    **/
    @isTest
    public static void getServiceAndMarketTransportationZoneTestFailureIncorrectZip() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
    	List<Case> caseList = [SELECT Id FROM Case];
        for(Case c : caseList)
       	{
       		c.Zip__c = NAS_TestConstants.GET_SERVICE_MARKET_INCORRECT_ZIP_CODE;
            c.NAS_SKP_Country__c = NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_COUNTRY_CODE;
       	}
       	update caseList;
        Test.startTest();
        NAS_GetServiceMarketNTransportationZone.getServiceAndMarketTransportationZone(caseList[0].Id);
        Test.stopTest();
        Case c = [SELECT Id, NAS_Service_Market_Id__c, NAS_Service_Market__c, NAS_Transportation_Zone__c FROM Case WHERE Id = :caseList[0].Id];
        System.assertEquals(null, c.NAS_Service_Market_Id__c, 'Incorrect Service Market Id');
        System.assertEquals(null, c.NAS_Service_Market__c, 'Incorrect Servie Market');
        System.assertEquals(null, c.NAS_Transportation_Zone__c, 'Incorrect Transportation Zone');
    }
    /**
    * @name getServiceAndMarketTransportationZoneTestFailureIncorrectCountry
    * @description Test Failure response with incorrect country.
    **/
    @isTest
    public static void getServiceAndMarketTransportationZoneTestFailureIncorrectCountry() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
    	List<Case> caseList = [SELECT Id FROM Case];
        for(Case c : caseList)
       	{
       		c.Zip__c = NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_ZIP_CODE;
            c.NAS_SKP_Country__c = NAS_TestConstants.GET_SERVICE_MARKET_INCORRECT_COUNTRY_CODE;
       	}
       	update caseList;
        Test.startTest();
        NAS_GetServiceMarketNTransportationZone.getServiceAndMarketTransportationZone(caseList[0].Id);
        Test.stopTest();
        Case c = [SELECT Id, NAS_Service_Market_Id__c, NAS_Service_Market__c, NAS_Transportation_Zone__c FROM Case WHERE Id = :caseList[0].Id];
        System.assertEquals(null, c.NAS_Service_Market_Id__c, 'Incorrect Service Market Id');
        System.assertEquals(null, c.NAS_Service_Market__c, 'Incorrect Servie Market');
        System.assertEquals(null, c.NAS_Transportation_Zone__c, 'Incorrect Transportation Zone');
    }
    /**
    * @name getServiceAndMarketTransportationZoneTestFailureUnsupportedCountry
    * @description Test Failure response with unsupported country.
    **/
    @isTest
    public static void getServiceAndMarketTransportationZoneTestFailureUnsupportedCountry() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
    	List<Case> caseList = [SELECT Id FROM Case];
        for(Case c : caseList)
       	{
       		c.Zip__c = NAS_TestConstants.GET_SERVICE_MARKET_CORRECT_ZIP_CODE;
            c.NAS_SKP_Country__c = NAS_TestConstants.GET_SERVICE_MARKET_SKP_API_COUNTRY_UNSUPPORTED;
       	}
       	update caseList;
        Test.startTest();
        NAS_GetServiceMarketNTransportationZone.getServiceAndMarketTransportationZone(caseList[0].Id);
        Test.stopTest();
        Case c = [SELECT Id, NAS_Service_Market_Id__c, NAS_Service_Market__c, NAS_Transportation_Zone__c FROM Case WHERE Id = :caseList[0].Id];
        System.assertEquals(null, c.NAS_Service_Market_Id__c, 'Incorrect Service Market Id');
        System.assertEquals(null, c.NAS_Service_Market__c, 'Incorrect Servie Market');
        System.assertEquals(null, c.NAS_Transportation_Zone__c, 'Incorrect Transportation Zone');
    }
    /**
    * @name getServiceAndMarketTransportationZoneTestFailureInexistentON
    * @description Test Failure response with inexistent order number.
    **/
    @isTest
    public static void getServiceAndMarketTransportationZoneTestFailureInexistentON() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
    	List<Case> caseList = [SELECT Id FROM Case];
        for(Case c : caseList)
       	{
       		c.NAS_Order_Number__c = String.valueOf(NAS_TestConstants.GET_SERVICE_MARKET_INEXISTENT_ORDER_NUMBER);
       	}
       	update caseList;
        Test.startTest();
        NAS_GetServiceMarketNTransportationZone.getServiceAndMarketTransportationZone(caseList[0].Id);
        Test.stopTest();
        Case c = [SELECT Id, NAS_Service_Market_Id__c, NAS_Service_Market__c, NAS_Transportation_Zone__c FROM Case WHERE Id = :caseList[0].Id];
        System.assertEquals(null, c.NAS_Service_Market_Id__c, 'Incorrect Service Market Id');
        System.assertEquals(null, c.NAS_Service_Market__c, 'Incorrect Servie Market');
        System.assertEquals(null, c.NAS_Transportation_Zone__c, 'Incorrect Transportation Zone');
    }
}