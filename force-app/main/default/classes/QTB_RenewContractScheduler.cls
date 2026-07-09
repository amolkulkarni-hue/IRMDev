/*****************************************************************************************************
* Class: QTB_RenewContractScheduler
* Author: Accenture
* Purpose: This is a scheduler class to schedule QTB_RenewContractsBatch 
* Requirement: OM-5
* Change History: 6/8/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*             3/31/2020
*******************************************************************************************************/
global class QTB_RenewContractScheduler implements Schedulable 
{
    /*******************************************************************************************************************
    * Author:      Accenture
    * Date:        3-31-2020
    * Parameters:  SchedulableContext sc
    * Return:      void
    * Description: This method is used to execute QTB_RenewContractsBatch.*/
    public static boolean throwExplicitException = false;
    global void execute(SchedulableContext sc) 
    {
        try{
            if (throwExplicitException) {
                throw new NullPointerException();
            }
        QTB_RenewContractsBatch job = new QTB_RenewContractsBatch(); 
        database.executebatch(job,1);
        }catch(Exception e){
            QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),'Renew Contract Scheduler');  
        }
    }
}