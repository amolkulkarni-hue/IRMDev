/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group service
 * @description the default implmentation of IArchiveEmailDataService
 */

public class ArchiveEmailDataServiceDefault implements IArchiveEmailDataService{
    public List<Database.SaveResult> upsertBigObject(List<Archive_Email__b> toUpsert) {
        return Database.insertImmediate(toUpsert);
    }
    
    public List<Database.SaveResult> upsertContentDocLink(List<ContentDocumentLink> lstCDocLink) {
        return Database.insert(lstCDocLink, false);
    }

    public void deleteBigObject(Set<Id> cases) {
        ArchiveEmailDataServiceDefault.handleDeleteBigObject(cases);
    }

    @future
    public static void handleDeleteBigObject(Set<Id> cases) {
        List<Database.DeleteResult> results = Database.deleteImmediate([SELECT Case__c, Email__c FROM Archive_Email__b WHERE Case__c IN: cases]);
        ILogger emailLogger = new LoggerFactoryDefault().createLogger(
                    LoggerStrategy.EMAIL,
                    LogLevel.ERROR,
                    'ArchiveEmailService',
                    'Delete Archived Case Emails');
        for(Database.DeleteResult result : results) {
            if(!result.isSuccess()) {
                emailLogger.log(result.getErrors()[0].getMessage(), ArchiveEmailService.class);
            }
        }
        emailLogger.emit();
    }
}