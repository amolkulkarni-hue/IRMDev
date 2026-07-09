/**
* @File Name : CommunityPageRedirect.cls
* Test Class : CommunityPageRedirectTest
* Modification Log: (Date (MM/DD/YYYY) - Name - Change Summary - Reference(#story,#incident))
                        09/06/2024 - Roopesh Lakshmanan - initial development - Gitlab #26168

**/
@isTest
public class CommunityPageRedirectTest {
	@isTest
    public static void testGetFeedItemCaseID() {
        // Get the record type ID for 'Global Service Case'
        RecordType globalServiceCaseRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND Name = 'Global Service Case' LIMIT 1];
        
        // Create a case with the mandatory fields: RecordTypeId and Origin
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            RecordTypeId = globalServiceCaseRecordType.Id
            //Origin = 'ANZ_Chat'
        );
        insert testCase;
        
        // Create a FeedItem associated with the Case
        FeedItem testFeedItem = new FeedItem(
            ParentId = testCase.Id,
            Body = 'Test Feed Item',
            Type = 'TextPost'
        );
        insert testFeedItem;
        
        // Test the method
        Test.startTest();
        String caseId = CommunityPageRedirect.getFeedItemCaseID(testFeedItem.Id);
        Test.stopTest();
        
        // Assert that the returned ParentId (Case ID) matches the expected Case ID
        System.assertEquals(testCase.Id, caseId, 'The case ID returned does not match the expected value.');
    }
}