global class Schedule_SKPRateUploadNotificationBatch implements Schedulable{
   global void execute(SchedulableContext sc){
        SKPRateUploadNotificationBatch srunb = new SKPRateUploadNotificationBatch();
        System.debug('+++++testing+++++'+srunb);
        id batched = database.executeBatch(srunb, 200);
    }

}