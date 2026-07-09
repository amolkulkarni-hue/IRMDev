global class Schedule_NotificationAndFieldUpdateBatch implements Schedulable{
    global void execute(SchedulableContext sc){
        IM_NotificationAndFieldUpdateBatch pdb = new IM_NotificationAndFieldUpdateBatch();
        if(!Test.IsRunningTest()){
        id batched = database.executeBatch(pdb, 10);
    }
    }
}