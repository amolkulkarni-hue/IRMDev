/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Test Class for Queueable update communicator service class.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public with sharing class NAS_UpdateCommunicatorQueueableTest {
	/**
     * @name setupTestData
     * @description Sets up Test data needed for all test cases in this Test Class.
    **/
	@testSetup
    public static void setupTestData()
    {
        NAS_TestDataFactory.setupTestData(1);
    	//NAS_TestDataFactory.createCase(1, NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE, 
                                       //true, NAS_Constants.PICKLIST_STATUS_CASE_NEW);
        
        //------------------
        List<Case> caseList1 = new List<Case>();
        Account a = new Account(Name = 'Test Account');
        INSERT a;
        Contact con = new Contact(LastName = 'Test', firstName = 'Contact',
                                Email = 'test@gmail.com',
                                        Phone = '1234567890',
                                        AccountId = a.Id,
                                 Survey_Opt_Out__c = true);
        INSERT con;
        List<IM_Customer_Account__c> customerAccountList = [SELECT Id, IM_Account__c FROM IM_Customer_Account__c
                                                            //WHERE Name LIKE 'CustomerAccount%'
                                                            ORDER BY IM_Account__c, Id];
        IM_Customer_Account__c ca = new IM_Customer_Account__c(
            Name = 'Test CustomerAccount',
            RecordTypeId = NAS_DataFactory.getRecordTypeId('IM_Customer_Account__c', 
                                                           NAS_Constants.NA_CUSTOMER_ACCOUNT_RECORDTYPE),
            IM_Account__c = a.Id,
            Source_System__c = NAS_Constants.SOURCE_SYSTEM_CODE_SKP_NA);

 		Case cs = new Case();        
        cs.Customer_Id__c = ca.Id;
        cs.AccountId = a.Id;
        cs.ContactId = con.Id;
        cs.RecordTypeId = NAS_DataFactory.getRecordTypeId('Case', NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE);
        cs.Status = NAS_Constants.NEWCASESTATUS;
        cs.Origin = 'Communicator';
        cs.Priority = NAS_Constants.DEFAULT_CASE_PRIOROTY;
        cs.Subject = 'Test Case Record';
        cs.Description = 'Test Case Record';
        caseList1.add(cs);
        INSERT caseList1;        
        //		
        for(Case c : caseList1)
       	{
       		c.Type = 'Account Maintenance';
    		c.NAS_Root_Cause_Reason__c = 'Account Maintenance (CallBacks/Hold Code/Record Code/Special Instr.)';
    		c.NAS_External_Id__c = 'CECOMM5006C00000486GMQAY';
    		c.NAS_CECOMM_Event_Status__c = NAS_Constants.CECOMM_NOTIFIED;
       	}
       	update caseList1;
		for(Case c : caseList1)
       	{
       		c.Status = NAS_Constants.CASE_STATUS_CLOSED;
       	}
       	update caseList1;
    }
    /**
     * @name testNAS_UpdateCommunicatorQueueable
     * @description tests the update communicator functionality on closure of a case that was 
     * originated from a communicator event.
    **/
    @isTest
    public static void testNAS_UpdateCommunicatorQueueable() {
    	Test.setMock(HttpCalloutMock.class, new NAS_TestMockHttpResponseGenerator());
		List<Case> caseList = [SELECT Id FROM Case];
        Test.startTest();
		//NAS_UpdateCommunicatorQueueable.enqueueJob();
        NAS_UpdateCommunicatorQueueable.updateCommunicator();
        Test.stopTest();
        List<Case> caseResultList = [SELECT Id, NAS_CECOMM_Event_Status__c FROM Case];
        for(Case c : caseResultList)
       	{
       		System.assertEquals(NAS_Constants.CECOMM_CLOSED, c.NAS_CECOMM_Event_Status__c, 
                            'Incorrect CE Communicator Event Status.');
       	}
    }
}