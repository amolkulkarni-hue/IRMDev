/**
* @author         Accenture
* @modifiedBy     Accenture
* @created        5/13/2020
* @modified       5/13/2020
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* Description: Scheduler class for QTB_QuoteStatusUpdateBatch
* Story No: CPQ-34 (SPRINT-3)
* Requirement : Set Quote status to Expired when Pricing expiration Date <= today's date 
* 
* ___________________________________________________________________________________________________
*/
global class QTB_QuoteStatusUpdateScheduler implements Schedulable 
{
    global void execute(SchedulableContext sc) 
    {
        QTB_QuoteStatusUpdateBatch job = new QTB_QuoteStatusUpdateBatch(); 
        database.executebatch(job);
    }
}