/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Test Class for Customer Info Window Controller
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public class NAS_CustomerInfoWindowControllerTest {
  /**
     * @name setupTestData
     * @description Sets up Test data needed for all test cases in this Test Class.
    **/
  @testSetup
    public static void setupTestData()
    {
        NAS_TestDataFactory.setupTestData(5);
    }
    /**
     * @name testGetTabContentCustomerInstructions
     * @description Tests NAS_CustomerInfoWindowController to get tab content for Customer Instruction tab.
    **/
    @isTest
    public static void testGetTabContentCustomerInstructions()
    {
        //TODO select external id once it is identified
        IM_Customer_Account__c ca = [SELECT Id, Name FROM IM_Customer_Account__c Limit 1];
        Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
        Test.startTest();
        String getCustomError = NAS_CustomerInfoWindowController.getNoCustomerResponse();
        String tabContent = NAS_CustomerInfoWindowController.getTabContent(ca.Name, 
                                NAS_Constants.INFOWIN_CUSTOMERINSTRUCTIONS_TABID);
        System.debug('Test Tab Content>>>>'+tabContent);
        Test.stopTest();
        System.assertNotEquals(null, tabContent, 'No Response Received.'); 
        Map<String, Object> customerInstructionMap = (Map<String, Object>)JSON.deserializeUntyped(tabContent);  
    }
     /**
     * @name testGetTabContentServiceProfile
     * @description Tests NAS_CustomerInfoWindowController to get tab content for Service Profile tab.
    **/
     @isTest
    public static void testGetTabContentServiceProfile()
    {
        //TODO select external id once it is identified
        IM_Customer_Account__c ca = [SELECT Id, Name FROM IM_Customer_Account__c Limit 1];
        Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
        Test.startTest();
        String tabContent = NAS_CustomerInfoWindowController.getTabContent(ca.Name, 
                                NAS_Constants.INFOWIN_SERVICEPROFILE_TABID);
        Test.stopTest();
        System.assertNotEquals(null, tabContent, 'No Response Received.'); 
        Map<String, Object> customerInstructionMap = (Map<String, Object>)JSON.deserializeUntyped(tabContent);  
       
    } 
    
   
    /**
     * @name testGetTabContentBilling
     * @description Tests NAS_CustomerInfoWindowController to get tab content for Billing tab.
    **/
     @isTest
    public static void testGetTabContentNotes()
    {
         //TODO select external id once it is identified
        IM_Customer_Account__c ca = [SELECT Id, Name FROM IM_Customer_Account__c Limit 1];
        Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
        Test.startTest();
        String tabContent = NAS_CustomerInfoWindowController.getTabContent(ca.Name, 
                                NAS_Constants.INFOWIN_QA_TABID);
        System.debug('Test Tab Content>>>>'+tabContent);
        Test.stopTest();
        System.assertNotEquals(null, tabContent, 'No Response Received.'); 
        Map<String, Object> qaInformationMap = (Map<String, Object>)JSON.deserializeUntyped(tabContent); 
    } 
}