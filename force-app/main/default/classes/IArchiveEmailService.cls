/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group Interface
 * @description Processes to be used by the Archive Email Big Object Strategy
 */

public interface IArchiveEmailService {
    /**
    * @description
    * Remove big object archive emails when cases are deleted
    * @param cases - The cases to be deleted
    **/  
    void clearArchiveEmailOnCaseDelete(List<Case> cases);

    /**
    * @description
    * Query cases which need their emails archived
    **/  
    Database.QueryLocator buildQueryLocator();

    /**
    * @description
    * Archive all email under the passed in cases
    * @param toArchive -  cases which need their emails archived
    **/  
    void archiveEmails(List<EmailMessage> toArchive);

    /**
    * @description
    * Call the emit mehod of error logger
    */
    void emitError();
}