/*****************************************************************************************************
* Class: QTB_InvoiceGroupIdUpdateBatchScheduler
* Author: Accenture
* Purpose: This is a scheduler class for QTB_InvoiceGroupIdUpdateBatch
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   20/5/2020
*******************************************************************************************************/
global class QTB_InvoiceGroupIdUpdateBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc){
        QTB_InvoiceGroupIdUpdateBatch job = new QTB_InvoiceGroupIdUpdateBatch(); 
        Database.executeBatch(job);
    }
}