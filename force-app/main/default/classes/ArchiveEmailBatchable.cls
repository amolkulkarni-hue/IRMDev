/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group Batchable
 * @description On batch run, find cases which have been closed for a period of time specified in a custom metadata,
 * then archive Email Messages for those cases by converting them into big objects. 
 */

public class ArchiveEmailBatchable implements Database.Batchable<sObject>,Database.Stateful {
    IArchiveEmailService service;
    
    public ArchiveEmailBatchable(IArchiveEmailService service) {
        this.service = service;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return this.service.buildQueryLocator();
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        this.service.archiveEmails(scope);
    }
    
    public void finish(Database.BatchableContext BC) {
        this.service.emitError();
    }
    
}