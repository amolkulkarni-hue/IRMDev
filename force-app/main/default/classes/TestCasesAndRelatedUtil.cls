public class TestCasesAndRelatedUtil {
public static void insertEM( list<Case> lstcases ) {
    integer i=0;
    list<EmailMessage> newEmailMsgs=new list<EmailMessage>();
    for(case c : lstcases){
       
       
        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.Incoming = True;
        email.ToAddress= 'test@xyz.org';
        email.Subject = 'Test email'+(++i);
        email.HtmlBody = 'Test email body'+(++i);
        email.ParentId = c.id;
        email.RelatedToId = c.Id;
        newEmailMsgs.add(email);
    }
     insert newEmailMsgs;          
    }
    public static void insertAttAndContent(list<Case> lstcases) {
    integer i=0;
    list<Attachment> atslst=new list<Attachment>();
    list<ContentVersion> cvs=new list<ContentVersion>();
    list<ContentDocumentLink> cds=new list<ContentDocumentLink>();
    integer count=0;
    for(Case c: lstcases){
        ContentVersion cv = new ContentVersion();
            cv.Title = 'Some document'+(++i);
            cv.PathOnClient = 'some document.txt';
            cv.VersionData = Blob.valueOf('Unit Test content version...');
         cvs.add(cv);
        
    }
    insert cvs;
    for(ContentVersion cv: cvs){
    
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        system.debug('conDocId++++++++++++:'+conDocId);
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = conDocId;
        cdl.LinkedEntityId = lstcases.get(count).id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'V';
        cds.add(cdl);
        Attachment att = new Attachment();
        att.ParentId   = lstcases.get(count).id;
        Blob bodyBlob  = Blob.valueOf('Unit Test Attachment Body');
        att.body       = bodyBlob;
        att.Name       = 'attachHarry'+(++i);
        atslst.add(att);
        ++count;
    }
    
    insert cds;
    insert atslst;
}
    public static void insertRelatedRecords(list<Case> lstcases){
        list<Case_Field_History__c> cfhlst=new list<Case_Field_History__c>();
     // Commented as part of 12563
     /* list<SFDC_Bug__c> sblst=new list<SFDC_Bug__c>();
        list<Sales_Tool_Project_Case__c> stpclst=new list<Sales_Tool_Project_Case__c>(); */
        list<CX_Survey_Details__c> csdlst=new list<CX_Survey_Details__c>();
        list<Case_Action__c> calst=new list<Case_Action__c>();
        for(case c: lstcases){
          Case_Field_History__c cfh = new Case_Field_History__c();
            cfh.Case_Lookup__c=c.id;
            cfhlst.add(cfh);
         // Commented as part of 12563
         /* SFDC_Bug__c sb=new SFDC_Bug__c();
            sb.Case__c=c.id;
            sb.Problem__c='Tester class';
            sblst.add(sb); 
            Sales_Tool_Project_Case__c stpc=new Sales_Tool_Project_Case__c();
            stpc.Parent__c=c.id;
            stpclst.add(stpc); */
            CX_Survey_Details__c csd=new CX_Survey_Details__c();
            csd.Case__c=c.id;
            csdlst.add(csd);
            Case_Action__c ca=new Case_Action__c();
            ca.Case__c=c.id;
            calst.add(ca);
            
        }
        insert cfhlst;
     // Commented as part of 12563
     /* insert sblst;
        insert stpclst; */
        insert csdlst;
        insert calst;
           
    }
    public static void insertTask(list<Case> lstcases){
        integer i=0;
    list<Task> tsklst=new list<Task>();
        for(Case c : lstcases){
        Task t         = new Task();
        t.subject      = 'Creating Attachments'+(++i);
        t.Description  = 'The Good, The Bad & The Ugly'+(++i);
        t.Priority     = 'High';
        t.WhatId = c.id;
        tsklst.add(t);
        }
        insert tsklst;
    }
}