public with sharing class DocuSignStatusScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        System.debug('Scheduled job started: Syncing DocuSign envelopes');
        DocuSignStatusSync.syncDocuSignStatuses();
        System.debug('Scheduled job finished successfully');
    }
}