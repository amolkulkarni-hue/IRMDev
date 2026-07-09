/*****************************************************************************************************
 * Class       : QTB_ScheduleOrderContractingBatch
* Test Class  : QTB_ScheduleOrderContractingBatch_Test
* Author      : Accenture, Virtusa
* Purpose     : This is a Schedular class invoking a batch class for  Contract generation and Credit  & Rebill functionality for resetting flag to creation of invoice scheduler
* Requirement : Gitlab#8 , Gitlab#10550
* Developer   : Sravya    
* Change History:10/13/2022
* Developer        Date             Description
* -------------------------------------------------------------------------------------------
* Shailesh(Virtusa) 09/18/2023      Defect Fix #18420 -- InvoiceSchedulerFlag is not resetting after 5 min.
*******************************************************************************************************/
global class QTB_ScheduleOrderContractingBatch implements Schedulable {
  Integer batchSize;
  /***********************************************************************************************************
   * Method :  Constructor 
   **************************************************************************************************************/
  global QTB_ScheduleOrderContractingBatch() {
    batchSize = Integer.valueOf(System.Label.QTB_contract_batch_size);
  }
  /***********************************************************************************************************
   * Method : execute
   * Parameters: Database.SchedulableContext
   * ReturnType: void
   **************************************************************************************************************/
  global void execute(SchedulableContext sc) {   
    Database.executeBatch(new QTB_OrderContractingBatch(), batchSize);
  }
}