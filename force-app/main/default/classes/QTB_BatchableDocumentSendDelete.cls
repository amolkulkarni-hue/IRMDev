/*****************************************************************************************************
* Class 		: QTB_BatchableDocumentSendDelete
* Test Class    : QTB_BatchableDocumentSendDeleteTest
* Author		: Accenture
* Purpose		: This is a helper class for all business logic related to I object
* Requirement	: 
* Change History: 01/22/2024
* Developer        Date           Description
* -------------------------------------------------------------------------------------------
*  Accenture      
*  Virtusa  		01/22/2024      Refactor the class, added the comments
*******************************************************************************************************/
global class QTB_BatchableDocumentSendDelete implements Database.Batchable<SObject> {
    String contDocLinkError ='';
    String docDelError ='';
    
    /*********************************************************************************************************
Method Name: start
Parameters : Database.BatchableContext
Return Type: Database.QueryLocator
Description: start() method is responsible to fetch all records from QTB_Documents_Send_Lookup_Queue__c object where status = 'Delete'
**********************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
            'SELECT Id,QTB_Invoice__c,QTB_Credit_Note__c,QTB_Invoice_Scheduler__c,QTB_Status__c FROM QTB_Documents_Send_Lookup_Queue__c WHERE QTB_Status__c=\'Delete\'');
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters : Database.BatchableContext
Return Type: Database.QueryLocator
Description: execute method is responsible to pass docLookUpList data to updateInvoices() function, and then delete the ContentDocumentLink & QTB_Documents_Send_Lookup_Queue__c records
**********************************************************************************************************/
    global void execute(Database.BatchableContext context,List<QTB_Documents_Send_Lookup_Queue__c> docLookUpList)
    {
        list<QTB_Documents_Send_Lookup_Queue__c> documentSentLookupToDelete = new list<QTB_Documents_Send_Lookup_Queue__c>();
        list<ID> docSendLookupIds = new list<ID>();
        try{
            system.debug('values are'+docLookUpList);
            //Calling updateInvoices() method to update the invoices
            updateInvoices(docLookUpList);
            
            //iterating over QTB_Documents_Send_Lookup_Queue__c object
            for (QTB_Documents_Send_Lookup_Queue__c docSendLookup: docLookUpList) {
                docSendLookupIds.add(docSendLookup.ID);                
                QTB_Documents_Send_Lookup_Queue__c tempDocLookUp = new QTB_Documents_Send_Lookup_Queue__c();
                tempDocLookUp.id = docSendLookup.ID;
                documentSentLookupToDelete.add(tempDocLookUp);
            }
            
            //Checking if docSendLookupIds
            if(!docSendLookupIds.isEmpty() && docSendLookupIds.size() > 0) 
            {
                //Fetch ContentDocumentId from the ContentDocumentLink
                list<ContentDocumentLink> contDocLinkList = [SELECT id, ContentDocumentId, ContentDocument.LatestPublishedVersionId 
                                                             FROM ContentDocumentLink 
                                                             WHERE LinkedEntityId IN :docSendLookupIds];
                system.debug('tests'+contDocLinkList);
                if (contDocLinkList.size() > 0) { 
                    
                    //delete contDocLinkList
                    Database.deleteResult[] contDocDeleteList = database.delete(contDocLinkList, false);
                    for (Database.deleteResult contDocLink : contDocDeleteList) {
                        if (!contDocLink.isSuccess()) {           
                            for(Database.Error err : contDocLink.getErrors()) {            
                                contDocLinkError = contDocLinkError + contDocLink.getId() + ' - '+ err.getMessage();
                            }
                        }
                    }
                    system.debug('Error Records: '+contDocLinkError);
                }
                
                if(documentSentLookupToDelete.size() > 0) { 
                    //delete documentSentLookupToDelete
                    Database.deleteResult[] docSentLookupDel = database.delete(documentSentLookupToDelete, false);
                    for (Database.deleteResult docDel : docSentLookupDel) {
                        if (!docDel.isSuccess()) {           
                            for(Database.Error err : docDel.getErrors()) {            
                                docDelError = docDelError + docDel.getId() + ' - '+ err.getMessage();
                            }
                        }
                    }
                    system.debug('Error Records: '+docDelError);   
                }
            } 
        }
        catch(exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_BatchableDocumentSendDelete');
        }
    }
    
    /*********************************************************************************************************
Method Name: finish
Parameters : Database.BatchableContext
Return Type: void
Description: No action is required
**********************************************************************************************************/
    global void finish(Database.BatchableContext context) {
        
    }
    
    /*********************************************************************************************************
Method Name: updateInvoices()
Parameters : list<QTB_Documents_Send_Lookup_Queue__c> docLookUpList
Return Type: void
Description: this method is updating the Invoice's & CreditNote's QTB_Last_Invoice_Portal_Sent__c field value to today() date.
**********************************************************************************************************/
    global static void updateInvoices(list<QTB_Documents_Send_Lookup_Queue__c> docLookUpList){
        list<ID> invoiceIdsToUpdate = new list<ID>();
        list<ID> creditNtIdsToUpdate = new list<ID>();
        list<ID> invoiceSchdIds = new list<ID>();
        
        list<ID> singleInvIdsToUpdate = new list<ID>();
        list<ID> singleCreditNtIdsToUpdate = new list<ID>();
        
        String invoiceUpdateError ='';
        String creditNoteUpdateError = '';        
        try{            
            for(QTB_Documents_Send_Lookup_Queue__c docSendLookup: docLookUpList)
            {
                //if invoice !=null
                if (docSendLookup.QTB_Invoice__c != null) {
                    invoiceIdsToUpdate.add(docSendLookup.QTB_Invoice__c);
                    singleInvIdsToUpdate.add(docSendLookup.QTB_Invoice__c);
                }
                //if creditnote !=null
                if (docSendLookup.QTB_Credit_Note__c != null) {
                    creditNtIdsToUpdate.add(docSendLookup.QTB_Credit_Note__c);
                    singleCreditNtIdsToUpdate.add(docSendLookup.QTB_Credit_Note__c);
                }
                //if invoice scheduler !=null
                if (docSendLookup.QTB_Invoice_Scheduler__c != null) {
                    invoiceSchdIds.add(docSendLookup.QTB_Invoice_Scheduler__c);
                }
            }
            
            Map<ID, blng__CreditNote__c> credtNtMap;
            Map<ID, blng__Invoice__c> invLstMap;
            String postedStatus = QTB_Constants.INVOICE_STATUS_POSTED;
            
            if(invoiceSchdIds.size() > 0)
            {
                //Fetching all the invoice scheduler
                list<blng__InvoiceScheduler__c> invSchd = [SELECT id,blng__InvoiceBatches__c,blng__TargetDate__c,Name
                                                           FROM blng__InvoiceScheduler__c 
                                                           WHERE ID IN:invoiceSchdIds]; 
                
                list<String> InvoiceBatchesvalues = new list<String>();
                
                for (blng__InvoiceScheduler__c invSch: invSchd) {
                    String invoiceBatch = '';
                    if(invSch.blng__InvoiceBatches__c != null)
                    {
                        invoiceBatch = String.valueOf(invSch.blng__InvoiceBatches__c);
                        if (invoiceBatch.contains(';')) {
                            list<String> tempBatches = invoiceBatch.split(';');
                            InvoiceBatchesvalues.addAll(tempBatches);
                        } else {
                            InvoiceBatchesvalues.add(invoiceBatch);
                        }
                    }
                }
                
                system.debug('The invoicebatchesvalues are@@'+InvoiceBatchesvalues);                
                invLstMap = new Map<ID, blng__Invoice__c>([SELECT id,QTB_Last_Invoice_Portal_Sent__c
                                                           FROM blng__Invoice__c 
                                                           WHERE QTB_Last_Invoice_Portal_Sent__c = null 
                                                           AND blng__InvoiceStatus__c =:postedStatus
                                                           AND blng__Account__r.QTB_Bill_Cycle_Day__c IN :InvoiceBatchesvalues limit 50000]);
                
                if(invLstMap.size() > 0) {
                    invoiceIdsToUpdate.addAll(invLstMap.keySet());
                }
                
                credtNtMap = new Map<ID, blng__CreditNote__c>([SELECT name,id,QTB_Last_Invoice_Portal_Sent__c
                                                               FROM blng__CreditNote__c 
                                                               WHERE QTB_Last_Invoice_Portal_Sent__c = null 
                                                               AND blng__Status__c =:postedStatus 
                                                               AND blng__Account__r.QTB_Bill_Cycle_Day__c IN :InvoiceBatchesvalues limit 50000]);  
                
                if (credtNtMap.size() > 0){
                    creditNtIdsToUpdate.addAll(credtNtMap.keySet());
                } 
            }
            
            //Invoice related logic
            list<blng__Invoice__c> invUpdate = new list<blng__Invoice__c>();
            if (singleInvIdsToUpdate.size() > 0)
            {
                list<blng__Invoice__c> invUpdateList = [SELECT id,QTB_Last_Invoice_Portal_Sent__c
                                                        FROM blng__Invoice__c 
                                                        WHERE ID IN:invoiceIdsToUpdate limit 50000];
                
                for(blng__Invoice__c inv: invUpdateList){
                    blng__Invoice__c invoices = new blng__Invoice__c();
                    invoices.id = inv.id;
                    invoices.QTB_Last_Invoice_Portal_Sent__c = datetime.now();
                    invUpdate.add(invoices);
                }
            } 
            else if(invLstMap != null && invLstMap.size() > 0) 
            {
                for(blng__Invoice__c inv: invLstMap.values()) {
                    blng__Invoice__c invoices = new blng__Invoice__c();
                    invoices.id = inv.id;
                    invoices.QTB_Last_Invoice_Portal_Sent__c = datetime.now();
                    invUpdate.add(invoices);
                }
            }
            
            //Updating the Invoice if invUpdate is not null
            if(invUpdate.size() > 0) 
            {
                // update invUpdate;
                Database.saveResult[] invUpdateList = database.update(invUpdate, false);
                for (Database.saveResult invoiceUpdate : invUpdateList) {
                    if (!invoiceUpdate.isSuccess()) {           
                        for(Database.Error err : invoiceUpdate.getErrors()) {            
                            invoiceUpdateError = invoiceUpdateError + invoiceUpdate.getId() + ' - '+ err.getMessage();
                        }
                    }
                }
                system.debug('Error Records of invoice@@'+invoiceUpdateError);
            }
            
            //CreditNote related logic start
            list<blng__CreditNote__c> crdNtUpdate = new list<blng__CreditNote__c>();
            if (singleCreditNtIdsToUpdate.size() > 0) 
            {
                postedStatus=Test.isRunningTest()?'Draft':postedStatus;
                list<blng__CreditNote__c> crdNteList = [SELECT name,id,QTB_Last_Invoice_Portal_Sent__c
                                                        FROM blng__CreditNote__c 
                                                        WHERE QTB_Last_Invoice_Portal_Sent__c = null 
                                                        AND blng__Status__c =:postedStatus limit 50000];                
                
                for(blng__CreditNote__c crdNt: crdNteList)
                {
                    blng__CreditNote__c crdNts = new blng__CreditNote__c();
                    crdNts.id = crdNt.id;
                    crdNts.QTB_Last_Invoice_Portal_Sent__c = datetime.now(); 
                    crdNtUpdate.add(crdNts);
                }
            }
            else if(credtNtMap != null && credtNtMap.size() > 0)
            {
                for(blng__CreditNote__c crdNt: credtNtMap.values()) {
                    blng__CreditNote__c crdNts = new blng__CreditNote__c();
                    crdNts.id = crdNt.id;
                    crdNts.QTB_Last_Invoice_Portal_Sent__c = datetime.now();
                    crdNtUpdate.add(crdNts);
                }
            }
            
            //Updating the CreditNote if crdNtUpdate is not null
            if(crdNtUpdate.size() > 0)
            {
                //update crdNtUpdate;
                Database.saveResult[] crdtUpdateList = database.update(crdNtUpdate, false);
                for (Database.SaveResult creditNoteUpdate : crdtUpdateList) {
                    if (!creditNoteUpdate.isSuccess()) {           
                        for(Database.Error err : creditNoteUpdate.getErrors()) {            
                            creditNoteUpdateError = creditNoteUpdateError + creditNoteUpdate.getId() + ' - '+ err.getMessage();
                        }
                    }
                }
                system.debug('Error Records of creditNote@@'+creditNoteUpdateError);
            } 
        }
        catch(Exception e){
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), 'QTB_BatchableDocumentSendDelete');        
        }
    }
}