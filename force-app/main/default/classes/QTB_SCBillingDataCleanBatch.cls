/*****************************************************************************************************
 * Class: QTB_SCBillingDataCleanBatch
 * QTB_BillingDatacleanBatch
 * Author: Virtusa
 * Purpose: This is a Schedular class invoking a batch class to Delete 2 months old Unused Usage Summaries (QTB_BillingDatacleanBatch).
 * Requirement:  GIT# 8145
 * Developer     Date 11/17/2021          Description

 *******************************************************************************************************/
global class QTB_SCBillingDataCleanBatch implements Schedulable {
    public String usageSummaryBatchSize = System.Label.QTB_UsageSummaryDeletion_BatchSize;
    /***********************************************************************************************************
     * Method :  Constructor
     **************************************************************************************************************/
    global QTB_SCBillingDataCleanBatch() {
     
    }
    /***********************************************************************************************************
     * Method : execute
     * Parameters: Database.SchedulableContext
     * ReturnType: void
     **************************************************************************************************************/
    global void execute(SchedulableContext sc) {
      QTB_BillingDatacleanBatch b=new QTB_BillingDatacleanBatch();
      Database.executeBatch(b,integer.valueOf(usageSummaryBatchSize));
    }
  }