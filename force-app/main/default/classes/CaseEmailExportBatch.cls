public class CaseEmailExportBatch implements Database.Batchable<SObject>, Database.Stateful {
    private List<String> csvLines = new List<String>();
    
    public String query;
    public Date startDate;
    public Date endDate;

    public CaseEmailExportBatch() {
        // Adjust date range if needed
        startDate = Date.newInstance(System.today().year() - 1, 1, 1); // Jan 1 previous year
        endDate = Date.newInstance(System.today().year(), 12, 31);    // Dec 31 current year
        system.debug('startDate '+startDate);
        system.debug('endDate '+endDate);
     
        this.query = 'SELECT Id, CreatedDate, IsClosed FROM Case WHERE Origin = \'NAS_EMAIL_English_Auto_Response_AskCS\'';
        this.query += ' AND DAY_ONLY(convertTimezone(CreatedDate)) >= :startDate AND DAY_ONLY(convertTimezone(CreatedDate)) <= :endDate';
       
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(this.query);
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        List<Case> cases = (List<Case>)scope;
        Set<Id> caseIds = new Set<Id>();

        for (Case c : cases) {
            caseIds.add(c.Id);
           // csvLines.add('"Case","' + c.Subject + '","","","' + c.Owner.Name + '","' + c.Contact.Name + '","' + c.CreatedDate + '"');
        }

        // EmailMessage
        List<EmailMessage> emails = [SELECT parent.casenumber,parent.isClosed, FromAddress, ToAddress, CreatedDate  FROM EmailMessage WHERE ParentId IN :caseIds AND (NOT FromAddress LIKE '%@ironmountain.com%')];
        for (EmailMessage em : emails) {
            csvLines.add('"EmailMessage","' + em.parent.casenumber + '","'+em.parent.isClosed+'","' + em.FromAddress + '","' + em.ToAddress + '","","","' + em.CreatedDate + '"');
        }

        // Archive_Email__b
     //   List<Archive_Email__b> archived = [SELECT Case__r.casenumber,Case__r.isClosed ,FromAddress__c, ToAddress__c, Case__r.CreatedDate, Case__c FROM Archive_Email__b WHERE Case__c IN :caseIds];
        
        for (Archive_Email__b ae : [SELECT Case__r.casenumber,Case__r.isClosed ,FromAddress__c, ToAddress__c, Case__r.CreatedDate, Case__c FROM Archive_Email__b WHERE Case__c IN :caseIds]) {
            if(!ae.FromAddress__c.contains('ironmountain.com')){
            	csvLines.add('"Archive_Email","' + ae.Case__r.casenumber + '","' + ae.Case__r.isClosed+ '","' + ae.FromAddress__c + '","' + ae.ToAddress__c + '","","","' + ae.Case__r.CreatedDate + '"');
            }
        }
    }

    public void finish(Database.BatchableContext context) {
    csvLines.add(0, 'Type,Case Number,From Address,To Address,Owner Name,Contact Name,Created Date');
    String csvContent = String.join(csvLines, '\n');

    // Create ContentVersion (file)
    ContentVersion cv = new ContentVersion();
    cv.Title = 'Case_Email_Export';
    cv.PathOnClient = 'CaseEmailExport.csv';
    cv.VersionData = Blob.valueOf(csvContent);
    insert cv;

    // Get ContentDocumentId and latest ContentVersionId
    ContentVersion insertedCV = [
        SELECT Id, ContentDocumentId 
        FROM ContentVersion 
        WHERE Id = :cv.Id
    ];

    // Optional: Share publicly via ContentDistribution
    ContentDistribution cd = new ContentDistribution();
    cd.Name = 'Case Email Export Direct Download';
    cd.ContentVersionId = insertedCV.Id;
    cd.PreferencesAllowViewInBrowser = false;
    cd.PreferencesAllowOriginalDownload = true;
    cd.PreferencesNotifyOnVisit = false;
    cd.PreferencesPasswordRequired = false;
    insert cd;

    // Direct download URL (forces file download)
   
    String downloadUrl = URL.getOrgDomainURL().toExternalForm() +
   '/' +'sfc/servlet.shepherd/version/download/' + insertedCV.Id;

    // Email the user with the direct download link
    User currentUser = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

    if (currentUser.Email != null) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { currentUser.Email });
        mail.setSubject('Your Case Email Export is Ready');
        mail.setHtmlBody('Hello,<br/><br/>' +
                         'Your export of case and email data is complete.<br/><br/>' +
                         'Click below to download your CSV file:<br/><br/>' +
                         '<a href="' + downloadUrl + '" target="_blank">Download Case_Email_Export.csv</a><br/><br/>' +
                         'Thank you.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    System.debug('Export completed. Download link sent to user: ' + downloadUrl);
}

}