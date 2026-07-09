/**
* Class: CaseEmailMessagesBigObjectCountTest
*
* Author: TCS
*
* Purpose: This is a test class for CaseEmailMessagesBigObjectCount
*
* Requirement: GitLab : #31411 
*
* Change History:
*
* Developer                     Date 	             		Description
* -------------------------------------------------------------------------------------------
* Praneel                       11/Jul/2025               test class for CaseEmailMessagesBigObjectCount
*/

@isTest
public class CaseEmailMessagesBigObjectCountTest {
	
    static final String CLOSED_STATUS = 'Closed';
    static final String OPEN_STATUS = 'Open';
    static final String SUBJECT = 'Subject';
    static final String BODY = 'Body';
    static final Id CASE_RECORDTYPE = Schema.SobjectType.Case.getRecordTypeInfosByDeveloperName().get('NCSP_New_Customer_Setup').getRecordTypeId();
    static final Integer RECORD_COUNT = 10;
    static final Date TODAY = Date.today();
    static final String RANDOM_EMAIL = '123';
    
        
     @testsetup
    static void setup1() {
        List<Case> cases = new SObjectBuilder(Case.SObjectType)
            .put(Case.Status, CLOSED_STATUS)
            .put(Case.RecordTypeId, CASE_RECORDTYPE)
            .put(Case.Project_Completion_Date__c, TODAY)
            .put(Case.Transition_Date__c, System.Now())
            .put(Case.Origin,'NAS_EMAIL_English_Auto_Response_AskCS')
            .put(Case.Emails_Archived__c, true)
            .count(RECORD_COUNT).create().getRecords();

        List<EmailMessage> emails = new SobjectBuilder(EmailMessage.SobjectType)
        .put(EmailMessage.ParentId, cases)
        .put(EmailMessage.Subject, SUBJECT)
        .put(EmailMessage.TextBody, BODY)
        .put(EmailMessage.FromAddress,'dkdow@dmdp.cld')
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
        
        Case newCase = (Case) new SobjectBuilder(Case.SobjectType)
            .put(Case.RecordTypeId, Schema.SObjectType.Case.getRecordTypeInfosByName().get('IM Employees Support Case Closed (Locked)').getRecordTypeId())
            .put(Case.Subject, 'Holder_TEST123')
            .put(Case.Status, 'Closed')
            .put(Case.Case_Sub_Category__c, 'IT Development')
        //    .put(Case.Origin,'NAS_EMAIL_English_Auto_Response_AskCS')
            .create().getRecord();
        
        List<EmailMessage> testEmail1 = new SobjectBuilder(EmailMessage.SobjectType)
        .put(EmailMessage.ParentId, newCase)
        .put(EmailMessage.Subject, SUBJECT)
        .put(EmailMessage.TextBody, BODY)
        .put(EmailMessage.FromAddress,'dkdow@dmdp.cld')
        .count(2).create().getRecords();
        
        

        
         Archive_Email__b archivedEmail = new Archive_Email__b(
            Case__c = newCase.Id,
            Email__c = RANDOM_EMAIL,
            FromAddress__c = '29329@irm.com'
           
        );
        
      //  Database.insertImmediate(archivedEmail);
            } 
    
   
    
    @isTest
    static void testCaseEmailMsgWithoutArchival(){
        
       test.starttest();
        try {
            CaseEmailMessagesBigObjectCount caseEmailBigObj = new CaseEmailMessagesBigObjectCount();
            
            
           caseEmailBigObj.emailMessageCountByMonth.put(Date.today().month()+' '+Date.today().year(),new Case_Email_Count__c());
            String chron = '0 0 23 * * ?';        
            system.schedule('Test Sched3', chron, caseEmailBigObj);
           // caseEmailBigObj.execute(null);
        } catch(exception e){
            system.debug('error occured while executing the test method '+e.getMessage());
        }
        Test.stopTest();
    }
    
     @isTest
    static void testInvalidDateRange() {
        try {
            new CaseEmailMessagesBigObjectCount(Date.today(), Date.today().addDays(-1));
            System.assert(false, 'Should have thrown exception');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Invalid date range', e.getMessage());
        }
    }
    
    
}