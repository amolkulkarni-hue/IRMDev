/*****************************************************************************************************
* Class: QTB_CRDN_Ready_for_Int_Scheduler
* Author: Yogesh/ kullayappa 
* Purpose: This is a Batch class containing logic for the CreditNote lines which are in draft even after Invoices are posted
* Requirement: To iterate on the draft CreditNote lines
* Change History: 12/07/2024
* Developer                         Date                    Description
* ------------------------------------------------------------------------------------------- 
Yogesh/ kullayappa      22/05/2024     Creation of new Scheduler class that calls the batch QTB_CRDN_Ready_for_integration_Batch for posting the Draft CreditNote lines
*******************************************************************************************************/
global class QTB_CRDN_Ready_for_Int_Scheduler implements Schedulable{
    global Set<Id> cRDNIds  = new Set<Id> ();
    global  List<QTB_CustomInvoiceNumber__c> customSettToUpdate=new List<QTB_CustomInvoiceNumber__c>();
    global QTB_CRDN_Ready_for_Int_Scheduler(Set<Id> processedCRDNIds,List<QTB_CustomInvoiceNumber__c> invCustomSettToUpdate){
        system.debug('processedCRDNIds  '+processedCRDNIds.size());
        if(!processedCRDNIds.isEmpty()){
            cRDNIds.addAll(processedCRDNIds);
        }
        if(!invCustomSettToUpdate.isEmpty()){
           customSettToUpdate.addAll(invCustomSettToUpdate); 
        }
    }
    global void execute(SchedulableContext sc) {
        system.debug('PASS Schedule class'+cRDNIds);
        Integer batchSize=Integer.ValueOf(System.Label.QTB_Ready_for_Int_Batch_size);
        QTB_CRDN_Ready_for_integration_Batch b=new QTB_CRDN_Ready_for_integration_Batch(cRDNIds,customSettToUpdate);
        Database.executeBatch(b,batchSize);
    }
}