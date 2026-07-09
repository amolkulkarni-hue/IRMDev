/**
* Class: DistributedCaseEmailControllerTest
*
* Author: TCS
*
* Purpose: This is a test class for DistributedCaseEmailController
*
* Requirement: GitLab : #31411 
*
* Change History:
*
* Developer                     Date 	             		Description
* -------------------------------------------------------------------------------------------
* Praneel                       21/Jul/2025               test class for DistributedCaseEmailController
*/
@isTest
public class DistributedCaseEmailControllerTest {
    
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
        
         Archive_Email__b archivedEmail = new Archive_Email__b(
            Case__c = cases[0].Id,
            Email__c = RANDOM_EMAIL,
            FromAddress__c = '29329@irm.com'
           
        );
        Case_Email_Count__c cec = new Case_Email_Count__c(Year__c = Date.today().year(),Month__c = Date.today().month(), count__c = 10,YearMonth__c='Jan '+Date.today().year());
        insert cec;
     //   database.insertImmediate(archivedEmail);
    }
    
    @isTest
    static void testCaseEmailMsgWithoutArchival(){
        
        
        
        test.startTest();
        	DistributedCaseEmailController dce = new DistributedCaseEmailController();
        	DistributedCaseEmailController.fetchDistributedCaseData(System.now(),10);
        test.stopTest();
    }
}