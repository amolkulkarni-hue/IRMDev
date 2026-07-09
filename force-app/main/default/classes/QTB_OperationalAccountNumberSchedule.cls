/**********************************************************************************************************************************************
 * Class: QTB_OperationalAccountNumberSchedule
 * Author: Virtusa
 * Purpose: This is a Scheduler class for QTB_OperationalAccountNumberBatch
 * Requirement: GITLAB #28887 Dev: Batch class creation for new object (QTB_Operational_Account_Number__c) records and deletion of records
 * Change History:
 * Developer                 Date
 * ----------------------------------------------------------------------------------------------------------------------------------------------
 * Thrinethra                12/02/2025
 *************************************************************************************************************************************************/
global class QTB_OperationalAccountNumberSchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        QTB_OperationalAccountNumberBatch batchJob = new QTB_OperationalAccountNumberBatch();
        
        Database.executeBatch(batchJob, 2000);
    }
}