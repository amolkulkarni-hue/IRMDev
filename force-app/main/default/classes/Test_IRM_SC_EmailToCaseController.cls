/************************************************************************
** CLIENT
**   Iron Mountain
**
** MODULE
**   Test_IRM_SC_EmailToCaseController (Controller Class)
**
** PURPOSE
**   To cover code coverage for EmailToCaseController. 
**
** CHANGE LOG
**   [[Version; Date; Author; Project/Case; Description]]
**   v1.0; 07/18/2013; Srinivasa Rao/Randstad; Email-to-case emails not creating cases (Customer Services) (Case # 01414611); Initial release
**
************************************************************************/
@isTest(SeeAllData=true)
private class Test_IRM_SC_EmailToCaseController {

    static testMethod void Test_EmailWithAttachment() {
        // TO DO: implement unit test
        ID caseRecordType =  DataFactory.getRecordTypeId('Case','IME SC Case');
        //RecordType caseRecordType = [select id from RecordType where name='IME SC Case']; 
        //Create a New Case.
        Case cas = new Case();
        cas.Status = 'In Progress';
        cas.RecordTypeId = caseRecordType;
        cas.IME_SC_Category__c= 'Amendment of customer details';
        cas.IME_SC_Sub_Category__c = 'Add/amend customer rate';
        cas.IME_SC_Request_Type__c = 'Non Order';
        cas.IME_SC_Cut_Off_Time__c = 'Standard (8 Hours)';
        cas.Closure_Reason__c = 'Value 1';
        cas.Subject = 'Test Subject';
        cas.IME_SC_Case_Owner_Email__c = 'test@IM.com';
        cas.IME_SC_Closure_Reason__c = 'Cancelled';
        cas.IME_SC_Case_Cause__c = 'Completed';
        insert cas;
        system.debug('Print the Case' + cas);
        
        //Create a New EmailMessage.
        EmailMessage email = new EmailMessage();
        email.FromName='TestSrinuMandalapu';
        email.TextBody='TestSrinu';
        email.Subject='Test Email Subject';
        email.parentID=cas.Id;
        email.status='0';   
        email.MessageDate=System.now();
        insert email;
        system.debug('print email subject'+ email.Subject);
        
        //Create a New Attachment.
        Attachment atchmnt =new Attachment();
        atchmnt.Body=Blob.valueOf('Test Body');
        atchmnt.Name='Test Name';
        atchmnt.Description='Test Description';
        atchmnt.ParentId=email.Id;
        insert atchmnt;
        System.debug('Print attachment name' + atchmnt.Name);
        
        //EmailtoCase Custom Controller Instance and calling method.
        IRM_SC_EmailToCaseController IRM_SC_E2C = new IRM_SC_EmailToCaseController ();
        IRM_SC_E2C.EmailId=email.Id;
        IRM_SC_E2C.CaseId = cas.Id;
        IRM_SC_E2C.ShowSucessMessage=true;
        IRM_SC_E2C.doCreateEmail();
        
        //Dummey Email Id
        IRM_SC_E2C.EmailId='1234';
        IRM_SC_E2C.doCreateEmail();  
        
        IRM_SC_E2C.EmailId='';
        IRM_SC_E2C.doCreateEmail();       
    }
}