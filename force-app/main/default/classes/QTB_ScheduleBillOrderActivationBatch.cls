/*****************************************************************************************************
 * Class: QTB_ScheduleBillOrderActivationBatch
 * Author: Accenture
 * Purpose: This is a Schedular class invoking a batch class Billing Order for Termination/Activation
 * Requirement: Git#9 and Git#15
 * Developer     Date           Description

 *******************************************************************************************************/
global class QTB_ScheduleBillOrderActivationBatch implements Schedulable {
    Integer batchSize;
    /***********************************************************************************************************
     * Method :  Constructor
     **************************************************************************************************************/
    global QTB_ScheduleBillOrderActivationBatch() {
      batchSize = Integer.valueOf(System.Label.QTB_contract_batch_size);
    }
    /***********************************************************************************************************
     * Method : execute
     * Parameters: Database.SchedulableContext
     * ReturnType: void
     **************************************************************************************************************/
    global void execute(SchedulableContext sc) {
      QTB_BillOrderActivationBatch b=new QTB_BillOrderActivationBatch();
      Database.executeBatch(b, 1);
    }
  }