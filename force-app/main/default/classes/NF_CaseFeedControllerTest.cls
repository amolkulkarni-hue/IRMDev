@isTest
public class NF_CaseFeedControllerTest {
    @isTest
    public static void testQueryCases() {
        Contact con = new Contact(FirstName='TestCon', LastName='1001');
        Case testCase = new Case(ContactId = con.Id);
        testCase.Type = 'Void Case';
        // Set up the test case record

        Test.startTest();
        List<Case> result = NF_CaseFeedController.queryCases(testCase.Id);
        Test.stopTest();

        // Assert the results
        System.assertEquals(0, result.size());
        // Add additional assertions as needed
    }

    @isTest
    public static void testGetCaseFeedUserTypes() {
        Contact con = new Contact(FirstName='TestCon', LastName='1001');
        Case testCase = new Case(ContactId = con.Id);
        testCase.Type = 'Void Case';
        // Set up the test case record
        List<CaseFeed> testCaseFeeds = new List<CaseFeed>();
        // Set up the test case feeds associated with the test case

        Test.startTest();
        Map<String, Boolean> result = NF_CaseFeedController.getCaseFeedUserTypes(testCase.Id);
        Test.stopTest();

        // Assert the results
        // Add assertions based on the expected behavior
    }

    @isTest
    public static void testGetCaseChatter() {
        Contact con = new Contact(FirstName='TestCon', LastName='1001');
        Case testCase = new Case(ContactId = con.Id);
        testCase.Type = 'Void Case';
        // Set up the test case record
        List<CaseFeed> testCaseFeeds = new List<CaseFeed>();
        // Set up the test case feeds associated with the test case

        Test.startTest();
        Map<String, CaseFeed> result = NF_CaseFeedController.getCaseChatter(testCase.Id);
        Test.stopTest();

        // Assert the results
        // Add assertions based on the expected behavior
    }

    @isTest
    public static void testSubmitCaseFeed() {
        // Account acc = new Account(Name = 'test');
        // insert acc;
        // Contact con = new Contact(FirstName='TestCon', LastName='1001');
        // Case testCase = new Case(AccountId = acc.Id, ContactId = con.Id);
        // testCase.Type = 'Void Case';
        // testCase.Status = 'New';
        // insert testCase;
        // Set up the test case record


        Id VALIDATE_RECORD_TYPE = RecordTypeCache.get(Case.SObjectType, 'NCSP_DMS').Id;
        List<case> listOfCases = new SObjectBuilder(Case.SObjectType)
            .put(Case.Status, 'Open')
            .put(Case.Project_Completion_Date__c, system.today() )
            .put(Case.Transition_Date__c, system.today() )
            .put(Case.RecordTypeId, VALIDATE_RECORD_TYPE)
            .count(1).create().getRecords();



        String jsonPayload = '{"records":[{"Body":"Test Body","ParentId":"' + listOfCases[0].Id + '","IsRichText":false,"TextPost":"TextPost"}]}';

        Test.startTest();
        Boolean result = NF_CaseFeedController.submitCaseFeed(jsonPayload);
        Test.stopTest();

        // Assert the results
        System.assertEquals(true, result);
        // Add additional assertions as needed
    }
}