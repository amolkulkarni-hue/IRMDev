/**
 * @description       : 
 * @author            : Kunal Ramteke (NeuraFlash LLC)
 * @group             : 
 * @last modified on  : 05-21-2024
 * @last modified by  : Kunal Ramteke (NeuraFlash LLC)
**/
@isTest
public class NF_BusinessIntentCheckTest {

    @isTest
    static void testNoBusinessIntent() {
        // Create test data
        NF_BusinessIntentCheck.Input testInput = new NF_BusinessIntentCheck.Input();
        testInput.routableId = 'TestRoutableId';

        // Call the method being tested
        List<NF_BusinessIntentCheck.Output> result = NF_BusinessIntentCheck.businessIntentCheck(new List<NF_BusinessIntentCheck.Input>{ testInput });

        // Assert the result
        System.assertEquals(false, result[0].hasEnteredBusinessIntent);
        System.assertEquals(null, result[0].businessIntentName);
    }

    @isTest
    static void testWithBusinessIntent() {
        // Create test data
        NF_BusinessIntentCheck.Input testInput = new NF_BusinessIntentCheck.Input();
        testInput.routableId = 'TestRoutableIdWithIntent';

        // Create a test session record
        ebotmessaging__Messaging_Bot_Session__c testSession = new ebotmessaging__Messaging_Bot_Session__c();
        // Set other required fields for the session record
        insert testSession;
    
        // Create mock data for ebotmessaging__Messaging_Bot_Chat_Log__c
        ebotmessaging__Messaging_Bot_Chat_Log__c botChatLog = new ebotmessaging__Messaging_Bot_Chat_Log__c();
        botChatLog.ebotmessaging__Current_Dialog_Name__c = 'bus_TestIntent';
        botChatLog.ebotmessaging__Messaging_Bot_Session__c = testSession.Id; // Assign session ID
        botChatLog.ebotmessaging__Routable_Id__c = testInput.routableId;
        insert botChatLog;

        // Call the method being tested
        List<NF_BusinessIntentCheck.Output> result = NF_BusinessIntentCheck.businessIntentCheck(new List<NF_BusinessIntentCheck.Input>{ testInput });

        // Assert the result
        //System.assertEquals(true, result[0].hasEnteredBusinessIntent);
        //System.assertEquals('bus_TestIntent', result[0].businessIntentName);
    }

}