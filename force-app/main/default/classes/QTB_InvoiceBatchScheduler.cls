global class QTB_InvoiceBatchScheduler implements Schedulable
{
    // TEMPORARILY DISABLED (2026-07-31): QTB_InvoiceBatch no longer has a no-arg constructor
    // (org-wide Apex compile failure otherwise, unrelated to this scheduler's own logic).
    // No CronTrigger currently references this class in this sandbox. Needs a real fix from
    // the QTB/CPQ billing code owner to confirm what a parameterless scheduled run should do
    // before re-enabling.
    global void execute(SchedulableContext sc)
    {
        System.debug(LoggingLevel.WARN, 'QTB_InvoiceBatchScheduler is temporarily disabled pending a fix to QTB_InvoiceBatch\'s missing no-arg constructor.');
    }
}