/**************************************************************************************************************
* Class:         QTB_SchedulePOExpirNotification
* Author:        IRM
* Purpose:       This is a Schedular class invoking a batch class QTB_sendPOExpirNotificationBatch for sending expiring email Notifications
* Requirement:   Gitlab Story#1669
* Developer      Date               Description
* -----------------------------------------------------------------------------------------------------------
* Gopinandan Biswal  08/06/2021
**************************************************************************************************************/
global class QTB_SchedulePOExpireNotification implements Schedulable {
    
    /***********************************************************************************************************
    * Method:     execute
    * Parameters: Database.SchedulableContext
    * ReturnType: void
    **************************************************************************************************************/
    global void execute(SchedulableContext sc) {
        QTB_sendPOExpireNotificationBatch POExpiringBatch = new QTB_sendPOExpireNotificationBatch();
        if(!Test.isRunningTest())
        Database.executeBatch(POExpiringBatch, integer.valueOf(system.label.QTB_PO_Expiring_Batch_Size));
    }
}