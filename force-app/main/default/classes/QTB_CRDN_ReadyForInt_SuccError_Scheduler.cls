/*****************************************************************************************************
* Class: QTB_CRDN_ReadyForInt_SuccError_Scheduler
* Author: Yogesh/ Kullayappa 
* Purpose: This is a Batch class containing logic for the Creditnote lines which are in draft even after creditnote are posted
* Requirement: To iterate on the draft Creditnote lines
* Change History: 22/05/2024
* Developer                         Date                    Description
* ------------------------------------------------------------------------------------------- 
Yogesh/ Kullayappa     22/05/2024     Creation of new Scheduler class that calls the batch QTB_Ready_for_Integration_Batch for posting the Draft Creditnote lines
*******************************************************************************************************/
global class QTB_CRDN_ReadyForInt_SuccError_Scheduler implements Schedulable{
    global Set<Id> CrdNoteIds  = new Set<Id> ();
    global QTB_CRDN_ReadyForInt_SuccError_Scheduler(Set<Id> processedCRDNIds){
       system.debug('processedCRDNIds  '+processedCRDNIds.size());
        if(!processedCRDNIds.isEmpty()){
            CrdNoteIds.addAll(processedCRDNIds);
        }
    }
    global void execute(SchedulableContext sc) {
        system.debug('PASS Schedule class'+CrdNoteIds);
        Integer batchSize=Integer.ValueOf(System.Label.QTB_Ready_for_Int_Batch_size);
        QTB_CRDN_ReadyForIntegWithSuccessError b=new QTB_CRDN_ReadyForIntegWithSuccessError(CrdNoteIds);
        Database.executeBatch(b,batchSize);
       
    }
    
}