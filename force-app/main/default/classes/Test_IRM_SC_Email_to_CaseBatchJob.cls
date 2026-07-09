/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   Test_Email_to_CaseBatchJob (Batch Class)
**
** PURPOSE
**   Code Coverage for 'Email_to_CaseBatchJob' Batch Class. 
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 06/05/2013; Srinivasa Rao/Randstad; Email-to-case emails not creating cases (Customer Services) (Case # 01414611); Initial release
**
************************************************************************/
@isTest(SeeAllData=true)
public class Test_IRM_SC_Email_to_CaseBatchJob {

    static testMethod void myUnitTest() {
        
        ID caseRecordType =  DataFactory.getRecordTypeId('Case','IME SC Case');
        //RecordType caseRecordType = [select id from RecordType where name='IME SC Case'];

        ID caseResolvedRecordType =  DataFactory.getRecordTypeId('Case','IME SC Case Resolved');
        //RecordType caseResolvedRecordType = [select id from RecordType where name='IME SC Case Resolved'];
                
        Case newCase = new Case();
        //System.runAs(ManagerUser){
            newCase.status = 'New';
            newcase.subject = 'Test Closed Case Mail';
            newCase.origin = 'GBR_EMAIL_ORDERS';
            newcase.Priority = 'Medium';
            newCase.recordTypeID = caseRecordType;//caseRelatedToEmail.recordTypeID;
            newcase.Description = 'Test Description';
            //newCase.ParentId = caseRelatedToEmail.ID;                            
            //newCase.country__c = caseRelatedToEmail.Country__c;
            //newCase.contactID = caseRelatedToEmail.contactID;
        
        
            insert newCase;
        //}
        case CaseCutOff  = [select id, OwnerID, IME_SC_Cut_Off_Time__c, Closure_Reason__c, subject, Status from case where Id=: newCase.Id];

        
        Test.startTest();
        CaseCutOff.recordTypeID = caseResolvedRecordType;
        CaseCutOff.status = 'Closed';
        //system.runAs(Owner1)           
        //{
            System.debug('userinfo.getusername() owner1'+userinfo.getusername());
            update CaseCutOff;
        //}
        
        emailMessage emailMsg = new emailmessage();
        emailMsg.Subject = 'Test Class';
         emailMsg.textBody='test Class Body';               
        emailMsg.ParentId = CaseCutOff.id; 
        emailMsg.status = '0';
        insert emailMsg;
        
        Set<ID> emailMsgId = new Set<ID>();
        emailMsgId.add(emailMsg.Id);
        
        IRM_SC_Email_to_CaseBatchJob Email_to_Case = new IRM_SC_Email_to_CaseBatchJob(emailMsgId);
        
        ID batchprocessid = Database.executeBatch(Email_to_Case);
        
        Test.stopTest();
    }
}