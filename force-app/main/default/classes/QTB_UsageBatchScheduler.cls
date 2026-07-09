/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
*   SFCPQBLG-701
*   Scheduler for QTB_UsageBatch 
*
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture
* @ModifiedBy    : Accenture
* @Created       : 07/14/2020
* @Modified      : 07/14/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
*/
global class QTB_UsageBatchScheduler implements Schedulable
{  
    /*********************************************************************************************************
    Method Name: execute
    Parameters: SchedulableContext
    Return Type: Void
	Description: Scheduler for QTB_UsageBatch Batch class
    **********************************************************************************************************/
    global void execute(SchedulableContext SC)
    {
        Integer batchSize=Integer.ValueOf(System.Label.QTB_Usage_Batch_Size)>2000?2000:Integer.ValueOf(System.Label.QTB_Usage_Batch_Size);
        system.debug('batch size is-->'+batchSize);
        QTB_UsageBatch usgBatch = new QTB_UsageBatch();
        Database.executeBatch(usgBatch,batchSize);
    }
}