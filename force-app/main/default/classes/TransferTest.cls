/**
 * 	Class:				TransferTest
 * 
 * 	Author:				Amit Gayal (NeuraFlash LLC)
 * 
 * 	Purpose:			It's the test class for Transfer apex class.
 * 
 * 	Requirements:		IMSLB-30
 * 
 * 	Change History:		
 * 
 * 	Developer					Date				Description
 * ----------------------------------------------------------------------------------------
 */

@isTest
private class TransferTest {

    @isTest
    static void getTransferSObjectInstanceTest(){
        Test.startTest();
        new Transfer();
        new Transfer(new Transfer__c());
        Transfer__c instance = new Transfer().getTransferSObjectInstance();
        Test.stopTest();
        Assert.areEqual('LiveChatTranscript',instance.Channel__c);
    }
}