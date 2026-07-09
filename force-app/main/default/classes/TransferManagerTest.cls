/**
 * 	Class:				TransferManagerTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for TransferManager apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */

@isTest
private class TransferManagerTest {
    
    @isTest
    static void getTransferDetailFormTest(){
        Transfer__c transferRec = new Transfer__c(Name = 'Test Transfer',
                                                  Type__c = 'Queue Transfer',
                                                  Transfer_Label__c = 'Test',
                                                  Transfer_Destination__c = 'Test',
                                                  Transfer_Message__c = 'Test Msg',
                                                  Channel__c = 'VoiceCall');
        insert transferRec;
        
        Test.startTest();
        UserInterfaceActionResult instanceReturned = TransferManager.getTransferDetailForm(transferRec.Id);
        Assert.areEqual(true, instanceReturned.actionStatus);
        Test.stopTest();
    }
    
    @isTest
    static void getTransferDetailFormTestException(){
        Test.startTest();
        UserInterfaceActionResult instanceReturned;
        try{
            instanceReturned = TransferManager.saveTransferDetails('Testing Exception');
        }
        catch(Exception ex){
            
        }
        Assert.areEqual(false, instanceReturned.actionStatus);
        Test.stopTest();
    }
    
    @isTest 
    static void testSaveTransferRecord(){
        Transfer__c transferRec = new Transfer__c(Name = 'Test Transfer',
                                                  Type__c = 'Queue Transfer',
                                                  Transfer_Label__c = 'Test',
                                                  Transfer_Destination__c = 'Test',
                                                  Transfer_Message__c = 'Test Msg',
                                                  Channel__c = 'VoiceCall');
        Transfer classInstance = new Transfer(transferRec);
        Test.startTest();
        UserInterfaceActionResult instanceReturned = TransferManager.saveTransferDetails(JSON.serialize(classInstance));
        Assert.areEqual(true, instanceReturned.actionStatus);
        Test.stopTest();
    }
    
    @isTest 
    static void testFetchChannelQueues(){
        String transferRecordString = '{"transferChannel":"MessagingSession","transferDestination":"","transferLabel":"","transferMessage":"","transferName":"","transferType":"Queue Transfer"}';
        Test.startTest();
        UserInterfaceActionResult queuesReturned = TransferManager.getChannelQueuesByChannelName(transferRecordString);
        Assert.isNotNull(queuesReturned.actionPayload);
        Test.stopTest();
    }
}