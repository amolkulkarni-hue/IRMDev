/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group test
 * @description The test class for ArchiveEmailService
 */

@isTest
private class ArchiveEmailServiceTest {
    static final String CLOSED_STATUS = 'Closed';
    static final String OPEN_STATUS = 'Open';
    static final String SUBJECT = 'Subject';
    static final String BODY = 'Body';
    static final Id CASE_RECORDTYPE = Schema.SobjectType.Case.getRecordTypeInfosByDeveloperName().get('NCSP_New_Customer_Setup').getRecordTypeId();
    static final Integer RECORD_COUNT = 10;
    static final Date TODAY = Date.today();
    @testSetup
    static void setup() {
        List<Case> cases = new SObjectBuilder(Case.SObjectType)
            .put(Case.Status, CLOSED_STATUS)
            .put(Case.RecordTypeId, CASE_RECORDTYPE)
            .put(Case.Project_Completion_Date__c, TODAY)
            .put(Case.Transition_Date__c, TODAY)
            
            // Commenting for 8977 on 17th June 2022
            //.put(Case.Service_Order_Required__c, 'Yes')
            .put(Case.Emails_Archived__c, true)
            .count(RECORD_COUNT).create().getRecords();

        List<EmailMessage> emails = new SobjectBuilder(EmailMessage.SobjectType)
        .put(EmailMessage.ParentId, cases)
        .put(EmailMessage.Subject, SUBJECT)
        .put(EmailMessage.TextBody, BODY)
        .count(RECORD_COUNT).create().getRecords();

        new SobjectBuilder(Attachment.SobjectType)
        .put(Attachment.ParentId, emails)
        .put(Attachment.Name, SUBJECT)
        .put(Attachment.Body, Blob.valueOf('TEST'))
        .count(RECORD_COUNT).create();
        
        ContentVersion contentVersion = new ContentVersion(
            Title          = 'a picture',
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true);
        insert contentVersion;
        
       // List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
         id documents = [select contentdocumentid from contentversion where id =: contentVersion.id].contentdocumentid;
        
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = emails[0].id;
        cdl.ContentDocumentId = documents;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }
    @isTest
    static void buildQueryLocator_QueryCasesToBeArchive() {
        ArchiveEmailDataServiceMock dataServiceMock = new ArchiveEmailDataServiceMock();
        ArchiveEmailService service = new ArchiveEmailService(dataServiceMock);
        Integer queryRun;
        Test.startTest();
            Database.QueryLocator iterator = service.buildQueryLocator();
            queryRun = Limits.getQueries();
        Test.stopTest();
 
        System.assertEquals(2, queryRun, 'The query locator should execute on start of the batch');
    }

    @isTest
    static void archiveEmails_GenerateBigObjectAndDeleteEmail() {
        List<EmailMessage> toArchive = [SELECT BccAddress, CcAddress, FromAddress, FromName, ParentId, Status, Subject, TextBody, ToAddress, MessageDate FROM EmailMessage];
        Set<String> originalEmailIds = Pluck.strings(EmailMessage.Id, toArchive);

        ArchiveEmailDataServiceMock dataServiceMock = new ArchiveEmailDataServiceMock();
        ArchiveEmailService service = new ArchiveEmailService(dataServiceMock);
        service.emailLogger = new LoggerMock();
        Test.startTest();
            service.archiveEmails(toArchive);
        Test.stopTest();
        List<EmailMessage> emailMessages = [SELECT Id FROM EmailMessage];
        Set<Id> caseIds = Pluck.ids([SELECT Id FROM Case]);

        System.assert(emailMEssages.isEmpty(), 'When emails are archived, the email should be deleted');
        System.assert(!dataServiceMock.upserted.isEmpty(), 'Archived emails should be created');

        System.assertEquals(RECORD_COUNT, [SELECT Id FROM Attachment WHERE ParentId IN: caseIds].size(),
            'All attachments should be reparent to cases');
        for(Archive_Email__b archiveEmail : dataServiceMock.upserted) {
            System.assert(originalEmailIds.contains(archiveEmail.Email__c),
                'The archived email should still contain the original information about the email');
            System.assert(caseIds.contains(archiveEmail.Case__c),
                'The archived email should still contain the original information about the parent case');
            System.assertEquals(SUBJECT, archiveEmail.Subject__c,
                'The archived email should still contain the original information: ' + SUBJECT);
            System.assertEquals(BODY, archiveEmail.TextBody__c,
                'The archived email should still contain the original information: ' + BODY);
        }
    }

    @isTest
    static void clearArchiveEmailOnCaseDelete_RemoveArchiveEmailsWhenCaseIsDelete() {
        Case openCase = (Case) new SObjectBuilder(Case.SObjectType)
            .put(Case.Status, OPEN_STATUS)
            .put(Case.RecordTypeId, CASE_RECORDTYPE)
            .put(Case.Project_Completion_Date__c, TODAY)
            .put(Case.Transition_Date__c, TODAY)
            
            // Commenting for 8977 on 17th June 2022
            //.put(Case.Service_Order_Required__c, 'Yes')
            .create().getRecord();

        List<Case> cases =[SELECT Status, Emails_Archived__c FROM Case];
        Set<Id> caseIds = Pluck.ids(cases);

        ArchiveEmailDataServiceMock dataServiceMock = new ArchiveEmailDataServiceMock();
        ArchiveEmailService service = new ArchiveEmailService(dataServiceMock);
        Test.startTest();
            service.clearArchiveEmailOnCaseDelete(cases);
        Test.stopTest();

        System.assertEquals(RECORD_COUNT, ArchiveEmailDataServiceMock.casesToClearArchive.size(), 
            'Only cases with closed status should have their archived emails removed');

        System.assert(!ArchiveEmailDataServiceMock.casesToClearArchive.contains(openCase.Id),
            'Cases with open status should not activate the archived email removal process');
    }

}