global class Schedule_PopulateGreaterDateFieldBatch implements Schedulable{
    global void execute(SchedulableContext sc){
        IM_PopulateGreaterDateFieldBatch pdb = new IM_PopulateGreaterDateFieldBatch();
        id batched = database.executeBatch(pdb, 200);
    }
}