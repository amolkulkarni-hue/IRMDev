/*****************************************************************************************************
* Class         : QTB_GenerateApixExtractQueueable
* Test Class    : QTB_GenerateApixExtractQueueableTest
* Author        : Virtusa
* Purpose       : This class containing logic for generating txt file for invoice
* Developer         Date          Description
* ------------------------------------------------------------------------------------------- 
*  Shailesh        18/06/2024      Gitlab US#24329 - Generating the Apix extract Text file for Invoice
*******************************************************************************************************/
public class QTB_GenerateApixExtractQueueable implements Queueable, Database.AllowsCallouts {
    public string invoiceOrCreditNoteId;
    public string invoiceOrCreditNoteNumber;
    public string invoiceOrCreditNoteName;
    public string invoiceOrCreditNoteStatus;
    public string accountLanguage;
    public boolean isInvoiceOrCreditNoteTextFile = false;
    public QTB_GenerateApixExtractQueueable(List<sObject> invoiceOrCreditNoteList,boolean isInvoiceText )
    {
        if(invoiceOrCreditNoteList != null && !invoiceOrCreditNoteList.isEmpty()){
            if(invoiceOrCreditNoteList[0].getSObjectType().getDescribe().getName() == 'blng__Invoice__c'){
                blng__Invoice__c invoice = (blng__Invoice__c) invoiceOrCreditNoteList[0];    
                invoiceOrCreditNoteId = invoice.Id;
                invoiceOrCreditNoteNumber = invoice.QTB_Custom_Invoice_Number__c;
                invoiceOrCreditNoteName = invoice.Name;
                invoiceOrCreditNoteStatus = invoice.blng__InvoiceStatus__c;
                accountLanguage = invoice.blng__Account__r.QTB_Language__c;
            }
            else if(invoiceOrCreditNoteList[0].getSObjectType().getDescribe().getName() == 'blng__CreditNote__c'){
                blng__CreditNote__c creditNote = (blng__CreditNote__c)invoiceOrCreditNoteList[0];    
                invoiceOrCreditNoteId = creditNote.Id;
                invoiceOrCreditNoteNumber = creditNote.QTB_Custom_Invoice_Number__c;
                invoiceOrCreditNoteName = creditNote.Name;
                invoiceOrCreditNoteStatus = creditNote.blng__Status__c;
                accountLanguage = creditNote.blng__Account__r.QTB_Language__c;
            }
        }
        isInvoiceOrCreditNoteTextFile = isInvoiceText;
    }
    
    public void execute(QueueableContext qc)
    {
        try{
            if(isInvoiceOrCreditNoteTextFile){
                generateTextFileForInvoice();
            }
            else{
                generateTextFileForCreditNote();
            }
        }
        Catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApixExtractQueueable');
        }
    }
    
    public void generateTextFileForInvoice(){
        try{
            PageReference vfPg = new PageReference('/apex/QTB_GenerateApexExtractVF');
            vfPg.getParameters().put('Id', invoiceOrCreditNoteId); // Replace with actual ID
            vfPg.getParameters().put('Lang', accountLanguage);
            vfPg.getParameters().put('isUsageWithinLimit','false'); 
            
            Blob pageData;
            if(Test.isRunningTest()) { 
                pageData = blob.valueOf('Unit.Test');
            } else {
                pageData = vfPg.getContent();
            }
            System.debug('Page content size: ' + pageData.size());
            
            // Attach Text File to the Current invoice Record
            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; // S-Document is in Salesforce.
            if (invoiceOrCreditNoteStatus == 'Posted') {
                conVer.PathOnClient = 'IRM_Invoice_' + invoiceOrCreditNoteNumber + '.txt';
                conVer.Title = 'IRM_Invoice_' + invoiceOrCreditNoteNumber + '.txt'; // Display name of the files
            } else {
                conVer.PathOnClient = 'IRM_Invoice_TEMP-' + invoiceOrCreditNoteName + '.txt';
                conVer.Title = 'IRM_Invoice_TEMP-' + invoiceOrCreditNoteName + '.txt'; // Display name of the files   
            }
            conVer.VersionData = pageData; // File content
            insert conVer;
            
            Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :conVer.Id].ContentDocumentId;
            
            // Create ContentDocumentLink
            ContentDocumentLink cDe = new ContentDocumentLink();
            cDe.ContentDocumentId = conDoc;
            cDe.LinkedEntityId =  invoiceOrCreditNoteId; // Use the InvoiceId
            cDe.ShareType = 'I'; // V - Viewer permission. C - Collaborator permission. I - Inferred permission.
            cDe.Visibility = 'AllUsers'; // AllUsers, InternalUsers, SharedUsers
            insert cDe;
            //Gitlab US#25594
            if(invoiceOrCreditNoteStatus == 'Posted'){
                blng__Invoice__c invoice = new blng__Invoice__c();
                invoice.Id = invoiceOrCreditNoteId;
                invoice.QTB_Last_Invoice_Sent__c = datetime.now();
                invoice.QTB_StoreApixInvoiceExtract__c = '';
                invoice.QTB_StoreApixUsageExtract1__c = '';
                invoice.QTB_StoreApixUsageExtract2__c = '';
                invoice.QTB_StoreApixUsageExtract3__c = '';
                invoice.QTB_StoreApixUsageExtract4__c = '';
                invoice.QTB_StoreApixUsageExtract5__c = '';
                invoice.QTB_StoreApixUsageExtract6__c = '';
                update invoice;
            }
        }
        Catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApixExtractQueueable');
        }
    }
    
    public void generateTextFileForCreditNote(){
        try{
            PageReference vfPg = new PageReference ('/apex/QTB_Generate_Creditnote_Extract');
            vfPg.getParameters().put('Id',invoiceOrCreditNoteId);
            vfPg.getParameters().put('Lang',accountLanguage);
            vfPg.getParameters().put('isUsageWithinLimit','false');//Gitlab US#24329
            
            Blob pageData;
            if(Test.isRunningTest()) { 
                pageData = blob.valueOf('Unit Test');
            } 
            else {
                pageData = vfPg.getContent();
            } 
            
            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            if(invoiceOrCreditNoteStatus == 'Posted')
            {
                conVer.PathOnClient = 'IRM_CRN_'+invoiceOrCreditNoteNumber+'.txt';      
                conVer.Title = 'IRM_CRN_'+invoiceOrCreditNoteNumber+'.txt'; // Display name of the files     
            }
            else
            {
                conVer.PathOnClient = 'IRM_CRN_'+invoiceOrCreditNoteName+'.txt';       
                conVer.Title = 'IRM_CRN_'+invoiceOrCreditNoteName+'.txt'; // Display name of the files
            }
            conVer.VersionData = pageData;//File content
            insert conVer;
            Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
            
            //Create ContentDocumentLink
            ContentDocumentLink cDe = new ContentDocumentLink();
            cDe.ContentDocumentId = conDoc;
            cDe.LinkedEntityId = invoiceOrCreditNoteId; // you can use objectId,GroupId etc
            cDe.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
            cDe.Visibility = 'InternalUsers'; //AllUsers, InternalUsers, SharedUsers
            insert cDe;
            Id  docId = cDe.Id;
            //Gitlab US#25594
            if((docId != NULL && invoiceOrCreditNoteStatus == 'Posted')|| Test.isRunningTest()){
                blng__CreditNote__c crdNote = new blng__CreditNote__c();
                crdNote.Id = invoiceOrCreditNoteId;
                crdNote.QTB_Last_Credit_Note_Sent__c = datetime.now(); 
                crdNote.QTB_StoreApixCreditNoteLineExtract__c ='';
                crdNote.QTB_StoreApixHeaderExtract__c = '';
                crdNote.QTB_StoreApixUsageExtract1__c = '';
                crdNote.QTB_StoreApixUsageExtract2__c = '';
                crdNote.QTB_StoreApixUsageExtract3__c = '';
                crdNote.QTB_StoreApixUsageExtract4__c = '';
                crdNote.QTB_StoreApixUsageExtract5__c = '';
                crdNote.QTB_StoreApixUsageExtract6__c = '';
                update crdNote;
            } 
        }
        Catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_GenerateApixExtractQueueable');
        }
    }    
}