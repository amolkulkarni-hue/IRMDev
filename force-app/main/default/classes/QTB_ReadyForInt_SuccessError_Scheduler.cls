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
global class QTB_ReadyForInt_SuccessError_Scheduler implements Schedulable{
    global Set<Id> InvcIds  = new Set<Id> ();
    global QTB_ReadyForInt_SuccessError_Scheduler(Set<Id> processedInvoiceIds){
        system.debug('processedInvoiceIds  '+processedInvoiceIds.size());
        if(!processedInvoiceIds.isEmpty()){
            invcIds.addAll(processedInvoiceIds);
        }
    }
    global void execute(SchedulableContext sc) {
        system.debug('PASS Schedule class'+invcIds);
        Integer batchSize=Integer.ValueOf(System.Label.QTB_Ready_For_SuccessError_Size);
        QTB_ReadyForIntegrationWithSuccessError b=new QTB_ReadyForIntegrationWithSuccessError(invcIds);
        Database.executeBatch(b,batchSize);
       
    }
    
}