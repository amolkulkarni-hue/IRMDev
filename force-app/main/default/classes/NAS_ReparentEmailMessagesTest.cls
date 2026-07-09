/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Test class for Reparent Email Messages functionality. This class verifies if the email messages
* are correctly copied under the new parent case.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
public with sharing class NAS_ReparentEmailMessagesTest {
    /**
     * @name setupTestData
     * @description Sets up Test data needed for all test cases in this Test Class.
    **/
	@testSetup
    public static void setupTestData()
    {
        NAS_PostToChatterAction.bypassChatterPost = true;
        NAS_TestDataFactory.setupTestData(1);
        List<Case> caseList = NAS_TestDataFactory.createCase(1, NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE, 
                                       true, NAS_Constants.PICKLIST_STATUS_CASE_NEW);
        List<EmailMessage> emailMessageList = NAS_TestDataFactory.insertEmailMessages(2, caseList[0]);	
    }
	/**
     * @name testReparentEmailMessages
     * @description Tests Reparenting of Email Messages in the parent case once the child case is updated with parent id.
    **/
    @isTest
    public static void testReparentEmailMessages()
    {
        NAS_PostToChatterAction.bypassChatterPost = true;
        List<Case> newCaseList = NAS_TestDataFactory.createCase(1, NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE, 
                                       true, NAS_Constants.PICKLIST_STATUS_CASE_NEW);
		Case existingCase = [SELECT Id FROM Case WHERE Id NOT IN :newCaseList];
        existingCase.ParentId = newCaseList[0].Id;
		existingCase.NAS_Reparent_Email_Messages__c = true;
		UPDATE existingCase;
		Test.startTest();
        NAS_ReparentEmailMessages.reparentEmailMessages(new List<Id> {existingCase.Id});
		Test.stopTest();
		List<EmailMessage> newEmailMessageList = [SELECT Id, (SELECT Id, ContentDocumentId, LinkedEntityId, ShareType, 
												  Visibility FROM ContentDocumentLinks) FROM EmailMessage WHERE ParentId IN :newCaseList];
		List<EmailMessage> existingEmailMessageList = [SELECT Id, (SELECT Id, ContentDocumentId, LinkedEntityId, ShareType, 
												  Visibility FROM ContentDocumentLinks) FROM EmailMessage WHERE ParentId IN :newCaseList];
		System.assertEquals(existingEmailMessageList.size(), newEmailMessageList.size(), 'Incorrect number of Email Messages created under the parent case');
		for(EmailMessage em : newEmailMessageList)
			System.assertNotEquals(0, em.ContentDocumentLinks.size(), 'Incorrect number of Content Document Links');
    }
    
    @isTest
    static void testAfterInsert() {
        NAS_TriggerHandler handler = new NAS_TriggerHandler();
        
        Test.startTest();
        handler.afterInsert();
        Test.stopTest();

    }
}