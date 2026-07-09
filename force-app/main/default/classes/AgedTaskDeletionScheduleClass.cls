global class AgedTaskDeletionScheduleClass implements Schedulable {
   global void execute(SchedulableContext sc) {
      AgedTaskDeletion atd = new AgedTaskDeletion(); 
      database.executebatch(atd);
   }
}