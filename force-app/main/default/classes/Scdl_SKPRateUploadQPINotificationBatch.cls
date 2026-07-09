global class Scdl_SKPRateUploadQPINotificationBatch implements Schedulable{
   global void execute(SchedulableContext sc){
        SKPRateUploadQPINotificationBatch qpi = new SKPRateUploadQPINotificationBatch('');
        id batched = database.executeBatch(qpi, 5);
    }
}