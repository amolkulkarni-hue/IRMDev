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
    // TEMPORARILY DISABLED (2026-07-31): QTB_ProductDiscountBatch no longer has a no-arg
    // constructor (org-wide Apex compile failure otherwise, unrelated to this scheduler's own
    // logic). No CronTrigger currently references this class in this sandbox. Needs a real fix
    // from the QTB/CPQ billing code owner to confirm the intended schedulerBatch/targtDate/
    // prebillFlowRecord defaults for a parameterless scheduled run before re-enabling.
    global void execute(SchedulableContext SC)
    {
        System.debug(LoggingLevel.WARN, 'QTB_ProductDiscountScheduler is temporarily disabled pending a fix to QTB_ProductDiscountBatch\'s missing no-arg constructor.');
    }
}