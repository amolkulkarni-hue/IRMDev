global class Schedule_updateOpportunityAttribution implements Schedulable{
    // TEMPORARILY DISABLED (2026-07-31): the batch class "updateOpportunityAttribution" this
    // scheduler depends on does not exist in this org/repo (Invalid type compile error,
    // unrelated to this scheduler's own logic — appears to be a long-standing gap, not a
    // recent deletion). No CronTrigger currently references this scheduler in this sandbox.
    // Needs the original batch class restored (or this scheduler retired) by whoever owns it
    // before re-enabling.
    global void execute(SchedulableContext sc){
        System.debug(LoggingLevel.WARN, 'Schedule_updateOpportunityAttribution is temporarily disabled — its batch class "updateOpportunityAttribution" does not exist in this org.');
    }

}