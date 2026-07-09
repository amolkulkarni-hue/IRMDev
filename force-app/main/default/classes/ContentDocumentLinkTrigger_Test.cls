@isTest
public class ContentDocumentLinkTrigger_Test {
    
   @isTest
    static void createDocumentLinkTest() {
      /*  ContentVersion  content=new  ContentVersion();
        content.Title = 'Header_picture1';
        content.PathOnClient = '/' + content.Title + '.jpg';
        Blob  bodyBlob = Blob.valueof('unit test Contentversion Body');
        Content.VersionData = bodyBlob;
        content.Origin = 'H';
        insert Content;
        ContentVersion ContentVersion_2 = [ select id, title, contentdocumentid from contentversion where id =:content.id limit 1];
        Account testAccount = new Account(Name = 'test Account');
        contentDocumentLink cdlObj = new  contentDocumentLink();
        cdlObj.LinkedEntityId = testAccount.id;
        cdlObj.ContentDocumentId =ContentVersion_2.ContentDocumentId;
        cdlObj.ShareType = 'V';
        insert cdlObj;
        insert testAccount; */
    
   Account acct = new Account(Name = 'TEST_ACCT');
    insert acct;

ContentVersion contentVersion = new ContentVersion(
  Title = 'Penguins',
  PathOnClient = 'Penguins.jpg',
  VersionData = Blob.valueOf('Test Content'),
  IsMajorVersion = true
);
insert contentVersion;    
List<ContentDocument> documents = [
    SELECT Id, Title, LatestPublishedVersionId 
    FROM ContentDocument
];

//create ContentDocumentLink  record 
ContentDocumentLink cdl = new ContentDocumentLink();
cdl.LinkedEntityId = acct.id;
cdl.ContentDocumentId = documents[0].Id;
cdl.ShareType = 'V';
insert cdl;
}
}