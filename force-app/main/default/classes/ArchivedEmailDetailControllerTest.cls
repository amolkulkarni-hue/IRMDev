/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group Test
 * @description Test for ArchivedEmailDetailController
 */

@isTest
private class ArchivedEmailDetailControllerTest {
    static final String RANDOM_EMAIL = '123';
    static final Integer RECORD_COUNT = 12;
    @isTest static void getArchivedEmailTest() {
        ArchivedEmailDetailController controller = new ArchivedEmailDetailController();
        Test.startTest();
            Archive_Email__b archiveEmail = controller.getArchivedEmail();
        Test.stopTest();

        System.assertEquals(null, archiveEmail, 'expecting the specified archive email to be displayed');
    }
    @isTest static void getAttachmentsTest() {
        ArchivedEmailDetailController controller = new ArchivedEmailDetailController();

        Case newCase = (Case) new SobjectBuilder(Case.SobjectType)
        .put(Case.RecordTypeId, Schema.SObjectType.Case.getRecordTypeInfosByName().get('IM Employees Support Case Closed (Locked)').getRecordTypeId())
        .put(Case.Subject, 'Holder')
        .put(Case.Status, 'Closed')
        .put(Case.Case_Sub_Category__c, 'IT Development')
        .create().getRecord();

        Archive_Email__b archivedEmail = new Archive_Email__b(
            Case__c = newCase.Id,
            Email__c = RANDOM_EMAIL
        );

        new SobjectBuilder(Attachment.SobjectType)
        .put(Attachment.ParentId, newCase.Id)
        .put(Attachment.Description, controller.SPLIT_STRING + RANDOM_EMAIL)
        .put(Attachment.Name, RANDOM_EMAIL)
        .put(Attachment.Body, Blob.valueOf('TEST'))
        .count(RECORD_COUNT).create();

        controller.archivedEmail = archivedEmail;

        Test.startTest();
            List<ArchivedEmailDetailController.AttachmentWrapper> attachments = controller.getAllAttachments();
        Test.stopTest();

        System.assertEquals(RECORD_COUNT, attachments.size(), 'All attachments that have the relationship with the archived email should be returned');

    }
    @isTest static void getContentattachmentsTest() {
        ArchivedEmailDetailController controller = new ArchivedEmailDetailController();
        
        Case newCase = (Case) new SobjectBuilder(Case.SobjectType)
            .put(Case.RecordTypeId, Schema.SObjectType.Case.getRecordTypeInfosByName().get('IM Employees Support Case Closed (Locked)').getRecordTypeId())
            .put(Case.Subject, 'Holder')
            .put(Case.Status, 'Closed')
            .put(Case.Case_Sub_Category__c, 'IT Development')
            .create().getRecord();
        
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
        cdl.LinkedEntityId = newCase.Id;
        cdl.ContentDocumentId = documents;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        Archive_Email__b archivedEmail = new Archive_Email__b(
            Case__c = newCase.Id,
            Email__c = RANDOM_EMAIL,
            ContentDocumentIDs__c = documents
        );
        
        
        
        controller.archivedEmail = archivedEmail;
        
        Test.startTest();
        List<ArchivedEmailDetailController.AttachmentWrapper> attachments = controller.getAllAttachments();
        system.debug('size in test class'+attachments.size());
        Test.stopTest();
        
        System.assertEquals(1, attachments.size(), 'All attachments that have the relationship with the archived email should be returned');

    }
}