/*****************************************************************************************************
* Class: QTB_Ready_for_Int_Invoice_Scheduler
* Author: Lokesh Tewari / Pragathi B V
* Purpose: This is a Batch class containing logic for the invoice lines which are in draft even after Invoices are posted
* Requirement: To iterate on the draft invoice lines
* Change History: 22/05/2024
* Developer                         Date                    Description
* ------------------------------------------------------------------------------------------- 
Lokesh Tewari / Pragathi B V      22/05/2024     Creation of new Scheduler class that calls the batch QTB_Ready_for_Integration_Batch for posting the Draft invoice lines
*******************************************************************************************************/
global class QTB_Ready_for_Int_Invoice_Scheduler implements Schedulable{
     //global List<blng__InvoiceLine__c> lstUpdatedInvcLine  = new List<blng__InvoiceLine__c> ();
    global Set<Id> InvcIds  = new Set<Id> ();
    global QTB_Ready_for_Int_Invoice_Scheduler(Set<Id> processedInvoiceIds){
        system.debug('processedInvoiceIds  '+processedInvoiceIds.size());
        if(!processedInvoiceIds.isEmpty()){
            invcIds.addAll(processedInvoiceIds);
        }
    }
    global void execute(SchedulableContext sc) {
        system.debug('PASS Schedule class'+invcIds);
        Integer batchSize=Integer.ValueOf(System.Label.QTB_Ready_for_Int_Batch_size);
        QTB_Ready_for_Integration_Batch b=new QTB_Ready_for_Integration_Batch(invcIds);
        Database.executeBatch(b,batchSize);
    }
}