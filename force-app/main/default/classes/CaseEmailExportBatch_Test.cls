@isTest
private class CaseEmailExportBatch_Test {
    @isTest
    static void testBatchExport() {
        // Create test user
        User u = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId()];

        // Create a test contact
        Contact c = new Contact(LastName='Test Contact');
        insert c;

        // Create test case
        Case testCase = new Case(Status='New',  ContactId = c.Id,Origin = 'NAS_EMAIL_English_Auto_Response_AskCS');
        insert testCase;

        // Set the CreatedDate for consistent filtering
        Test.setCreatedDate(testCase.Id, DateTime.now().addDays(-1));

        // Create EmailMessage related to the case
        EmailMessage em = new EmailMessage(
            ParentId = testCase.Id,
            FromAddress = 'test@example.com',
            ToAddress = 'user@example.com',
            Subject = 'Test Email'
        );
        insert em;

        // Create Archive_Email__b (Big Object simulation using Custom Object for test)
        Archive_Email__b archiveEmail = new Archive_Email__b(
            Case__c = testCase.Id,
            FromAddress__c = 'archived@example.com',
            ToAddress__c = 'archivedto@example.com',
            subject__c = 'Archived Email'
        );
      //  insert archiveEmail;

        Test.startTest();

       CaseEmailExportBatchLauncher.startExportBatch();

        Test.stopTest();

        // Assert a file was created
        List<ContentVersion> cvs = [SELECT Id, Title, PathOnClient FROM ContentVersion WHERE Title = 'Case_Email_Export'];
        System.assertEquals(1, cvs.size(), 'Expected one CSV ContentVersion');

       
    }
}