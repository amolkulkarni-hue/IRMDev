/*****************************************************************************************************
* Class: QTB_ScheduleUpdtStorageSeviceDatesOnInv
* Test:  QTB_SchUpdtStorageSeviceDatesOnInv_Test
* Author: Virtusa(Parth)
* Purpose:  This will schedule QTB_UpdateStorageServiceDatesOnInvBatch batch class which will run after 1 min to update Mrc dates and service dates 
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Parth         18/07/2025     # calling QTB_UpdateStorageServiceDatesOnInvBatch Batch class to run after 1 minute
*******************************************************************************************************/
public class QTB_ScheduleUpdtStorageSeviceDatesOnInv implements schedulable{
    public static boolean throwExplicitException = false;
    public Set<ID> invoiceIdSet = new Set<ID>();
    public Set<ID> invoiceSchedulerIdSet = new Set<Id>(); //#33490 - passing invoice scheduler Id to batch class to update QTB_InvoiceRunCompleted__c field
    //Constructor 
    public QTB_ScheduleUpdtStorageSeviceDatesOnInv(Set<ID> invoiceRunIDSet, Set<ID>invSchedulerIdSet) {
        // if invoice is created through inv scheduler than need to fetch its related invoice to pass to batch class
        invoiceSchedulerIdSet = invSchedulerIdSet;
        If(invoiceRunIDSet != null && !invoiceRunIDSet.isEmpty()){
            for(blng__Invoice__c invoice : [SELECT Id FROM blng__Invoice__c WHERE blng__InvoiceRunCreatedBy__c IN :invoiceRunIDSet]){
                invoiceIdSet.add(invoice.Id);
            }
        }
    }
    
    /*********************************************************************************************************
Method Name: execute
Parameters: SchedulableContext  sc
Return Type: void
Requirement: 
Description: calling QTB_UpdateStorageServiceDatesOnInvBatch Batch class to run after 1 minute
**********************************************************************************************************/
    public void execute(SchedulableContext  sc) {
        try {
            if (throwExplicitException) {
                throw new NullpointerException();
            }
            Integer batchSize = Integer.ValueOf(System.Label.QTB_UpdateStorageServiceDatesOnInvBatch_Size);
            Database.executeBatch(new QTB_UpdateStorageServiceDatesOnInvBatch(invoiceIdSet,invoiceSchedulerIdSet),batchSize);
            
        } catch (Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'QTB_ScheduleUpdtStorageSeviceDatesOnInv');
        }
    }
    /*********************************************************************************************************
Method Name: scheduleUpdateOfInvDates
Parameters: Set<ID> invoiceRunIDSet, Set<Id>invoiceId
Return Type: void
Requirement: 
Description: schedule QTB_ScheduleUpdtStorageSeviceDatesOnInv after 20 seconds
**********************************************************************************************************/
    public static void scheduleUpdateOfInvDates(Set<ID> invoiceRunIDSet,Set<ID>invSchedulerIdSet) {
        // Schedule the job to run after 20 seconds
        List<ID> invRunInvList = new List<ID>();
        If(invoiceRunIDSet != null && !invoiceRunIDSet.isEmpty()){
            invRunInvList.addAll(invoiceRunIDSet);
        }
        system.debug('invRunInvList- '+invRunInvList);
        ID invRunID = invRunInvList[0]; //Created List to store the 0th index ID as Set doesn't provides indexed values.
        invRunInvList.clear();
        Integer secondsToAdd = Integer.ValueOf(System.Label.QTB_ScheduleUpdtStorageSeviceDatesOnInv_ScheduledTime);
        Datetime scheduledTime = System.now().addSeconds(secondsToAdd);
        String cronExp = scheduledTime.format('s m H d M ? yyyy');
        // for inv scheduler scenario
        If(invoiceRunIDSet != null && !invoiceRunIDSet.isEmpty() && invSchedulerIdSet != null && !invSchedulerIdSet.isEmpty()){
            System.schedule('QTB_ScheduleUpdtStorageSeviceDatesOnInv' + invRunID, cronExp, new QTB_ScheduleUpdtStorageSeviceDatesOnInv(invoiceRunIDSet,invSchedulerIdSet));
        }
    }
}