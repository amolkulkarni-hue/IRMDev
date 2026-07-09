/**
 * @author Andrew Yu, Nathan Vass
 * @date March/2019
 * @group service
 */

public with sharing class ArchiveEmailService implements IArchiveEmailService{
    final String SYSTEM_ID_TEXT = ' | System_Id_Only_:<og_Id_goes_here>';
    IArchiveEmailDataService dataService;
    public ILogger emailLogger {
        get {
            if(emailLogger == null) {
                emailLogger = new LoggerFactoryDefault().createLogger(
                    LoggerStrategy.EMAIL,
                    LogLevel.ERROR,
                    'ArchiveEmailBatchable',
                    'Archive Case email messages as big objects');
            }
            return emailLogger;
        }set;
    }

    public ArchiveEmailService(IArchiveEmailDataService dataService) {
        this.dataService = dataService;
    }
    public ArchiveEmailService() {
        this.dataService = new ArchiveEmailDataServiceDefault();
    }
    public void clearArchiveEmailOnCaseDelete(List<Case> cases) {
        Set<Id> closedCases = new Set<Id>();
        for(Case closedCase : cases) {
            if(closedCase.Status == 'Closed') {
                closedCases.add(closedCase.Id);
            }
        }
        this.dataService.deleteBigObject(closedCases);
    }

    public Database.QueryLocator buildQueryLocator() {
        List<Close_Case_Interval__mdt> caseIntervals = [SELECT Day_Interval__c,Email_Interval__c,BetweenDates__c,FromDate__c,ToDate__c,CaseStatus__c FROM Close_Case_Interval__mdt limit 1];
        
        Integer emailInterval;
        Integer dayInterval;
        Boolean isBeweenDates;
        DateTime fromDate;
        DateTime toDate;
        String ClosedDateCondition;
        string[]  caseStatus;
        Integer recordLimit = Integer.valueof(Label.Archive_Email_Query_Limit);
        system.debug('recordLimit '+recordLimit);
        for(Close_Case_Interval__mdt interval : caseIntervals) 
        {            
            dayInterval = (Integer) interval.Day_Interval__c;
            emailInterval = (Integer) interval.Email_Interval__c;
            caseStatus = interval.CaseStatus__c.split(',');
            isBeweenDates =  interval.BetweenDates__c;
            fromDate = (DateTime) interval.FromDate__c;
            toDate = (DateTime) interval.ToDate__c;
            toDate = toDate.addDays(1);
        }
        System.debug('caseStatus '+caseStatus);
        String query = 'SELECT BccAddress, CcAddress, FromAddress, FromName, ParentId, Status, Subject, TextBody, ToAddress, MessageDate FROM EmailMessage WHERE Parent.Status in :caseStatus AND  Parent.Do_Not_Archive__c = false '; 
        
        //    Integer cdays = 1;
        //    query += (' AND Parent.ClosedDate <= LAST_N_DAYS:' + cdays);
        
        System.debug('fromDate '+ fromDate);
        System.debug('toDate '+ toDate);
        Datetime currentTime = System.now();
        if(!isBeweenDates){
            query += (' AND CreatedDate < LAST_N_DAYS:' +EmailInterval);
            query += (' AND Parent.ClosedDate < LAST_N_DAYS:' + dayInterval);
            
            //  return Database.getQueryLocator([SELECT BccAddress, CcAddress, FromAddress, FromName, ParentId, Status, Subject, TextBody, ToAddress, MessageDate FROM EmailMessage WHERE Parent.Status in :caseStatus  AND parentid = '500DS00000GF38F'   ]);
        }else{
            query += (' AND CreatedDate >=:fromDate' );
            query += (' AND CreatedDate <:toDate');
           // return Database.getQueryLocator([SELECT BccAddress, CcAddress, FromAddress, FromName, ParentId, Status, Subject, TextBody, ToAddress, MessageDate FROM EmailMessage WHERE Parent.Status in :caseStatus AND Parent.Do_Not_Archive__c = false AND CreatedDate >=:fromDate AND CreatedDate <=:toDate  ORDER BY CreatedDate LIMIT :recordLimit ]);
           //return Database.getQueryLocator(query);
        }
        query += ' ORDER BY CreatedDate LIMIT :recordLimit';
        return Database.getQueryLocator(query);
    }
    public void archiveEmails(List<EmailMessage> toArchive) {
        List<Archive_Email__b> archiveEmails = new List<Archive_Email__b>();
        Map<String, String> statusMap = new Map<String, String>{
            '0' => 'New',
            '1' => 'Read',
            '2' => 'Replied',
            '3' => 'Sent',
            '4' => 'Forwarded',
            '5' => 'Draft'
        };
            Map<Id,set<id>> contDocLinkIds = new Map<Id,set<id>>();
          List<ContentDocumentLink> lstCDocLink = new List<ContentDocumentLink>();
          
          Set<Id> emailMsgIds = new Set<Id>();
          for(EmailMessage s : toArchive){
           emailMsgIds.add(s.id);
      }
          
          system.debug('emailMsgIds....'+emailMsgIds);
          Set<id> contentDocumentIds = new Set<id>();
            for(ContentDocumentLink docLink : [SELECT Id, LinkedEntityId, ContentDocumentId, IsDeleted, SystemModstamp, ShareType, Visibility FROM ContentDocumentLink where LinkedEntityId in : emailMsgIds]) {
                if(contDocLinkIds.get(docLink.LinkedEntityId) != null){
                    contentDocumentIds = contDocLinkIds.get(docLink.LinkedEntityId);
                    contentDocumentIds.add(docLink.ContentDocumentId);
                  //  contentDocumentIds = contDocLinkIds.get(docLink.LinkedEntityId) + ',' + docLink.ContentDocumentId;
                  contDocLinkIds.put(docLink.LinkedEntityId,contentDocumentIds);
                }
                else{
                    contentDocumentIds = new Set<id>();
                    contentDocumentIds.add(docLink.ContentDocumentId);
                    contDocLinkIds.put(docLink.LinkedEntityId,contentDocumentIds);
                }
            }
        system.debug('contDocLinkIds '+contDocLinkIds);
           /* for(ContentDocument conDoc : [SELECT Id, Division, Title, ParentId, FileType, FileExtension, Description FROM ContentDocument where id IN : contDocLinkIds.keySet() ]){
                docLinkAndDocMap.put(conDoc.ParentId,conDoc.Id);
            } */
    contentDocumentIds = null;
        for (EmailMessage email : toArchive) {
            contentDocumentIds = contDocLinkIds.get(email.Id);
            String mySet_Joined_List = String.join(new List<Id>(contentDocumentIds), ',');
            archiveEmails.add(
                new Archive_Email__b(
                    BccAddress__c = (String.isNotBlank(email.BccAddress)) ? email.BccAddress.abbreviate(50) : '',
                    CcAddress__c = (String.isNotBlank(email.CcAddress)) ? email.CcAddress.abbreviate(50) : '',
                    Email__c = email.Id,
                    FromAddress__c = (String.isNotBlank(email.FromAddress)) ? email.FromAddress.abbreviate(50) : '',
                    FromName__c = (String.isNotBlank(email.FromName)) ? email.FromName.abbreviate(50) : '',
                    Case__c = email.ParentId,//(String.isNotBlank(email.ParentId))? email.ParentId : email.RelatedToId,
                    Status__c = statusMap.get(email.Status),
                    Subject__c = (String.isNotBlank(email.Subject)) ? email.Subject.abbreviate(50) : '',
                    TextBody__c = (String.isNotBlank(email.TextBody)) ? email.TextBody.abbreviate(50000) : '',
                    ToAddress__c = (String.isNotBlank(email.ToAddress)) ? email.ToAddress.abbreviate(50) : '',
                    MessageDate__c = email.MessageDate,
                    ContentDocumentIDs__c = mySet_Joined_List)
            );
                  system.debug('.....mySet_Joined_List '+mySet_Joined_List );
            if(contentDocumentIds != null && contentDocumentIds.size() > 0) {
                system.debug('if entered for contentdocumentLink:::'+contentDocumentIds);
                for(Id contentDoc:contentDocumentIds){
                    ContentDocumentLink cDocLink = new ContentDocumentLink();  
                    cDocLink.ContentDocumentId = contentDoc;//Add ContentDocumentId
                    cDocLink.LinkedEntityId = email.ParentId;
                    cDocLink.ShareType = 'V';
                    cDocLink.Visibility = 'InternalUsers';
                    lstCDocLink.add(cDocLink);
                }
            }
        }
        system.debug('lstCDocLink....'+lstCDocLink);
        system.debug('before upsert '+archiveEmails);
        List<Database.SaveResult> results = dataService.upsertBigObject(archiveEmails);
        system.debug('after inserting big object results '+results);
        if (results != null) {
            this.emailLogger.handleErrorLogging(results, archiveEmails, 'Failed to insert email big objects', ArchiveEmailBatchable.class);
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    return;
                }
            }
        }
system.debug('after inserting big object');
        List<Attachment> attachmentsBodySizeCheck = [SELECT BodyLength, ParentId FROM Attachment WHERE ParentId IN: Pluck.ids(toArchive) Order By ParentId];
        Set<Id> emailsWithAttachments = Pluck.ids(Attachment.ParentId, attachmentsBodySizeCheck);
        List<EmailMessage> toDeleteFirst = new List<EmailMessage>();
        for(Integer i = toArchive.size() - 1; i >= 0; i--) {
            system.debug('toArchive[i].Id) '+toArchive[i].Id);
            system.debug('content doc' + contDocLinkIds.get(toArchive[i].Id));
            if(!emailsWithAttachments.contains(toArchive[i].Id) && contDocLinkIds.get(toArchive[i].Id) == null ) {
                toDeleteFirst.add(new EmailMessage(Id = toArchive[i].Id));
                toArchive.remove(i);
            }
        }
    
        system.debug('before toDeleteFirst '+toDeleteFirst);
        List<Database.DeleteResult> deleteResults = Database.delete(toDeleteFirst, false);
        this.emailLogger.handleErrorLogging(deleteResults, toDeleteFirst, 'Failed to delete the emailMessage after archiving as big objects', ArchiveEmailBatchable.class);
       if(toArchive.isEmpty()) {
        return;
       }
        
    system.debug('after deleteResults '+deleteResults);
        //clear out as much space as possible
        statusMap = null;
        results = null;
        archiveEmails = null;
        deleteResults = null;
        toDeleteFirst = null;
        emailsWithAttachments = null;

        List<Id> toQuery = new List<Id>();
        Integer currentHeapSize = 0;
        Boolean toRollBack = false;
        Boolean existAttachmentLoop = false;
        List<Attachment> newAttachments = new List<Attachment>();
        List<Attachment> oldAttachments = new List<Attachment>();
        Integer totalHeapSize = Limits.getLimitHeapSize() - Limits.getHeapSize();
        //loop through all attachments and check the size
        while(attachmentsBodySizeCheck.size() >= 0 && !existAttachmentLoop) {
            if(Limits.getQueries() >= 195) {
                existAttachmentLoop = true;
                break;
            } 
            //if the attachment is too big to handle, throw an error and remove from the list
            if(attachmentsBodySizeCheck.size() != 0 && attachmentsBodySizeCheck[0] != null && attachmentsBodySizeCheck[0].BodyLength > totalHeapSize) {
                this.emailLogger.log('Attachment size too big. Please manually reparent or remove the attachment from the email', ArchiveEmailService.Class, attachmentsBodySizeCheck[0]);
                attachmentsBodySizeCheck.remove(0);

            //if attachment fit into the heap size, add it to the toQuery list and remove from the list
            } else if(attachmentsBodySizeCheck.size() != 0 && attachmentsBodySizeCheck[0] != null && attachmentsBodySizeCheck[0].BodyLength + currentHeapSize < totalHeapSize) {
                toQuery.add(attachmentsBodySizeCheck[0].Id);
                currentHeapSize += attachmentsBodySizeCheck[0].BodyLength;
                attachmentsBodySizeCheck.remove(0);
            //if there is no more attachments and there is still attachments to be queried, or if the heap size reaches the maximum, perform DML
            } else if((attachmentsBodySizeCheck.size() == 0) ||
                (attachmentsBodySizeCheck[0].BodyLength + currentHeapSize >= totalHeapSize)) {
                if(toQuery.size() == 0) {
                    existAttachmentLoop = true;
                    break;
                }
                for( Attachment old : [SELECT ParentId,
                                            Name,
                                            Body,
                                            Description
                                        FROM Attachment
                                        WHERE Id IN: toQuery]) {
                    Attachment newAttachment = new Attachment();               
                    newAttachment.Name = old.Name;
                    newAttachment.Body = old.Body;
                    newAttachment.Description = (String.IsBlank(old.Description))?
                        SYSTEM_ID_TEXT.replace('<og_Id_goes_here>', old.ParentId):
                        old.Description.abbreviate(450) + SYSTEM_ID_TEXT.replace('<og_Id_goes_here>', old.ParentId);
                    for(EmailMessage email : toArchive) {
                        if(email.Id == old.ParentId) {
                            newAttachment.ParentId = email.ParentId;
                            break;
                        }
                    }
                    oldAttachments.add(new Attachment(Id = old.Id));
                    newAttachments.add(newAttachment);
                }
                results = Database.insert(newAttachments, false);
                system.debug('new attachment results'+results);
                for(Attachment newlyInsert : newAttachments) {
                    newlyInsert.Body = null;
                }

                this.emailLogger.handleErrorLogging(results, newAttachments, 'Failed to insert email attachments onto the parent case', ArchiveEmailBatchable.class);
                for (Integer i = results.size()-1; i >= 0; i--) {
                    if (!results[i].isSuccess()) {
                        newAttachments.remove(i);
                        oldAttachments.remove(i);
                    }
                }
system.debug('before oldAttachments '+deleteResults);
                deleteResults = Database.delete(oldAttachments, false);
                    system.debug('after oldAttachments '+deleteResults);
                this.emailLogger.handleErrorLogging(deleteResults, oldAttachments, 'Failed to delete the email attachment after new attachment is created onto the parent case', ArchiveEmailBatchable.class);

                toQuery.clear();
                results = null;
                deleteResults = null;
                oldAttachments.clear();
                newAttachments.clear();
                currentHeapSize = 0;
                totalHeapSize = Limits.getLimitHeapSize() - Limits.getHeapSize();
            }
        }
        if(Limits.getQueries() >= 195) {
            this.emailLogger.log('Reach SOQL limit of 200', ArchiveEmailService.Class);
            existAttachmentLoop = true;
            return;
        } 
        emailsWithAttachments = Pluck.ids(Attachment.ParentId, [SELECT ParentId FROM Attachment WHERE ParentId IN: Pluck.ids(toArchive)]);
        for(Integer i = toArchive.size() - 1; i >= 0; i--) {
            if(emailsWithAttachments.contains(toArchive[i].Id)) {
                toArchive.remove(i);
            }
        }
        system.debug('before toArchive delete'+toArchive);
        deleteResults = Database.delete(toArchive, false);
        this.emailLogger.handleErrorLogging(deleteResults, toArchive, 'Failed to delete the email after being archived', ArchiveEmailBatchable.class);
        system.debug('after toArchive delete');    
        system.debug('lstCDocLink before updating '+lstCDocLink);
        if(lstCDocLink != null && lstCDocLink.size() > 0){
            ArchiveEmailDataServiceDefault archieveDefault = new ArchiveEmailDataServiceDefault();
            List<Database.SaveResult> contDocumentresults = archieveDefault.upsertContentDocLink(lstCDocLink);
            system.debug('contDocumentresults..... '+contDocumentresults);
        }
       
    }

    public void emitError() {
        this.emailLogger.emit();
    }
}