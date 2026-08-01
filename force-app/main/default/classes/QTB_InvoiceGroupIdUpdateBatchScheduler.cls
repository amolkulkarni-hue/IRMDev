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
    // TEMPORARILY DISABLED (2026-07-31): QTB_InvoiceGroupIdUpdateBatch no longer has a no-arg
    // constructor (org-wide Apex compile failure otherwise, unrelated to this scheduler's own
    // logic). No CronTrigger currently references this class in this sandbox. Needs a real fix
    // from the QTB/CPQ billing code owner to confirm what a parameterless scheduled run should
    // do (e.g. which Account Ids to target) before re-enabling.
    global void execute(SchedulableContext sc){
        System.debug(LoggingLevel.WARN, 'QTB_InvoiceGroupIdUpdateBatchScheduler is temporarily disabled pending a fix to QTB_InvoiceGroupIdUpdateBatch\'s missing no-arg constructor.');
    }
}