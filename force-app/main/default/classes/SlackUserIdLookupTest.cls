@isTest
private class SlackUserIdLookupTest {
    @isTest
    static void testGetSlackUserIDs() {

        // Create test Salesforce IDs
        List<String> salesforceIDs = new List<String>();
        
        salesforceIDs.add('0052X00000Xxxxx');
        
        // Mock the Slack.UserMappingService class
        Test.startTest();

        // Call the method to be tested
        List<String> slackUserIDs = SlackUserIdLookup.getSlackUserIDs(salesforceIDs);

        Test.stopTest();

        // Perform assertions
        System.assert(slackUserIDs != null, 'Returned list of Slack User IDs should not be null');
    }
}