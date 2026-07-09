/*****************************************************************************************************
* Class: QTB_ScheduleBillingOrderProcess 
* Author: Accenture
* Purpose: This is a Schedular class invoking a batch class for Billing Contract generation
* Requirement: SFCPQBLG-398, SFCPQBLG-295
* Change History: 19/06/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              
*******************************************************************************************************/
global  class QTB_ScheduleBillingOrderProcess implements Schedulable { 
    Integer batchSize;
    /***********************************************************************************************************
    * Method : Parameterised Constructor
    * Parameters: List<Id> , String 
    * Requirement : SFCPQBLG-295
    * Start Date : 19/06/2020
    * Author : Accenture
    * Description: Used to initaite batch size from custom label .
    **************************************************************************************************************/
    global QTB_ScheduleBillingOrderProcess(){
        batchSize=Integer.valueOf(System.Label.QTB_contract_batch_size);
    }
     /***********************************************************************************************************
    * Method : execute
    * Parameters: Database.SchedulableContext 
    * ReturnType: void
    * Requirement : SFCPQBLG-295
    * Start Date : 6/5/2020
    * Author : Accenture
    * Description: Used to invoke contracting batch
    **************************************************************************************************************/
    global void execute(SchedulableContext sc) {
         Database.executeBatch(new QTB_BillingOrderProcessBatch(),batchSize);       
    }
}