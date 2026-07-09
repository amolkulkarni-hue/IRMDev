/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
*   QTB-8b,QTB-30 and SFCPQBLG-482
*   Scheduler for QTB_ProductDiscountBatch 
*
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @Author        : Accenture
* @ModifiedBy    : Accenture
* @Created       : 5/6/2020
* @Modified      : 5/30/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
*/
global class QTB_ProductDiscountScheduler implements Schedulable
{  
    /*********************************************************************************************************
    Method Name: execute
    Parameters: SchedulableContext
    Return Type: Void
	Description: Scheduler for QTB_ProductDiscountBatch Batch class
    **********************************************************************************************************/
    global void execute(SchedulableContext SC)
    {
        QTB_ProductDiscountBatch pDisc = new QTB_ProductDiscountBatch();
        Database.executeBatch(pDisc);
    }
}