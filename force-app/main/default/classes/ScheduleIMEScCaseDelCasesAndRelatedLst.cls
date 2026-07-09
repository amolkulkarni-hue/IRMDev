global class ScheduleIMEScCaseDelCasesAndRelatedLst implements Schedulable {
global void execute(SchedulableContext sc) {
        //Database.executeBatch takes in the class, and then the size of batches.
        ID BatchId = Database.executeBatch(new DeleteImeScCasesAndRelatedLst(), 200);
    }
}