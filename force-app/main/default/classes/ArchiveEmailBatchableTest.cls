/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group Batchable
 * @description test class for ArchiveEmailBatchable
 * 
 * @Last Modified By : TCS
 * @Last Modified Date : 28-Jul-2022
 * @Modification Description : Story No #9442 
 * 							   NCSP field deletion : Continuation of #8977.
 * @Modification Details :  Removed the field Service_Order_Required__c from setup method case object's initialization.	
 * 							Commented method archiveEmails(List<Case> toArchive).  
 * 							Added the method to archiveEmails(List<EmailMessage> toArchive).	
 */
@isTest
private class ArchiveEmailBatchableTest {
    static ArchiveEmailBatchable batchable;
    static ArchiveEmailServiceSpy serviceMock;
    static Integer SCOPE_SIZE = 200;
    static final Integer RECORD_COUNT = Limits.getLimitQueries()+1;
    static final String CLOSED_STATUS = 'Closed';
    static final Id CASE_RECORDTYPE = Schema.SobjectType.Case.getRecordTypeInfosByDeveloperName().get('NAS_General_Support_Case').getRecordTypeId();
    static final Date TODAY = Date.today();

    @testSetup 
    /*static void setup() {
        new SObjectBuilder(Case.SObjectType)
            .put(Case.Status, CLOSED_STATUS)
            .put(Case.RecordTypeId, CASE_RECORDTYPE)
            .put(Case.Project_Completion_Date__c, TODAY)
            .put(Case.Transition_Date__c, TODAY)
            .put(Case.Emails_Archived__c, true)
            .put(Case.ContactId, test)
            .count(RECORD_COUNT).create();

    }*/
    
     static void testcreateContact() {
       // system.debug('kkkkkkkkk'+accountId);
        Contact contact = new Contact();
        //contact.AccountId = accountId;
        contact.LastName = 'Cebedo';
        contact.Phone = '415-906-3801';
        insert contact;
    }
    
    static void setup(){
        case c1=new case();
        c1.RecordTypeId=CASE_RECORDTYPE;
        c1.Status='Closed';
        c1.Project_Completion_Date__c=TODAY;
        c1.Transition_Date__c=TODAY;
        c1.Emails_Archived__c=true;
        c1.of_Service_Reschedules__c= '1';
        c1.IM_Employee_Contact__c='test';
        insert c1;
    }

    private static void setupEachTest() {
        serviceMock = new ArchiveEmailServiceSpy();
        batchable = new ArchiveEmailBatchable(serviceMock);
    }
    @isTest static void testExecute() {
        setupEachTest();
        Test.startTest();
            TestingUtils.simulateBatchRun(batchable, SCOPE_SIZE);
        Test.stopTest();

        System.assert(serviceMock.queryLocatorCall,
            'Archive Email Batchable should leverage the service class to retrieve all cases that need their emails archived');
        System.assert(serviceMock.archiveEmailsRan,
            'Archive Email Batchable should leverage the service class to archive the emails');
    }

    @isTest
    static void testFinish() {
        setupEachTest();
        Test.startTest();
            TestingUtils.simulateBatchRun(batchable, SCOPE_SIZE);
        Test.stopTest();

        System.assert(serviceMock.emitErrorRan,
            'The batchable should delagate error logging to a logger instance.');

    }

    private class ArchiveEmailServiceSpy implements IArchiveEmailService {
        Boolean archiveEmailsRan = false;
        Boolean queryLocatorCall = false;
        Boolean emitErrorRan = false;
        public void clearArchiveEmailOnCaseDelete(List<Case> cases) {
            //not used in batch
        }
     
        public Database.QueryLocator buildQueryLocator() {
            this.queryLocatorCall = true;
            return Database.getQueryLocator('SELECT Id FROM Case');
        }

        /*public void archiveEmails(List<Case> toArchive) {
            this.archiveEmailsRan = true;
        }*/
        public void archiveEmails(List<EmailMessage> toArchive) {
            this.archiveEmailsRan = true;
        }

        public void emitError() {
            this.emitErrorRan = true;
        }
    }
}