global class QTB_InvoiceBatchScheduler implements Schedulable 
{
    global void execute(SchedulableContext sc) 
    {
        QTB_InvoiceBatch job = new QTB_InvoiceBatch(); 
        database.executebatch(job,70);
    }
}