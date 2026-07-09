@isTest
public with sharing class NAS_UpdateSKPEventQueueableTest {
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
		List<Case> caseList = [SELECT Id FROM Case];
        for(Case c : caseList)
       	{
       		c.Type = 'Account Maintenance';
    		c.NAS_Root_Cause_Reason__c = 'Account Maintenance (CallBacks/Hold Code/Record Code/Special Instr.)';
    		c.NAS_External_Id__c = 'CECOMM5006C00000486GMQAY';
    		c.NAS_CECOMM_Event_Status__c = NAS_Constants.CECOMM_CREATED;
       	}
       	update caseList;
		/*for(Case c : caseList)
       	{
       		c.Status = NAS_Constants.CASE_STATUS_CLOSED;
       	}*/
       	//update caseList; 
    }

    @isTest
    public static void testNAS_UpdateSKPEventQueueable() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
		List<Case> caseList = [SELECT Id FROM Case];
        Test.startTest();
		NAS_UpdateSKPEventQueueable.updateEvent();
        Test.stopTest();
    }
}