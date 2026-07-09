/**
 * @author Andrew Yu, Nathan Vass
 * @date August/2018
 * @group Logger Factory
 * @description This class contains the logic of Email error logging strategy
 * Requirement: 
 * Change History: Git#21329 , changed the logic to send an email with CSV as attachment instead of all errors in email body
 */
public with sharing class EmailLogger extends LoggerBase implements ILogger{
    @testVisible final String ADMIN_PROFILE = 'System Administrator';
   // @testVisible final Integer EMAIL_CHARACTERS_LIMIT = 30000;
     @testVisible final Integer CSV_RECORD_LIMIT = 1000;
    @testVisible final String JOB_NAME_PLACEHOLDER = '{!jobName}';
    @testVisible final String JOB_DESCRIPTION_PLACEHOLDER = '{!jobDescription}';
    @testVisible String emailBodyIntro;
    @testVisible String emailBody = '';
    @testVisible String emailSubject;
    @testVisible LogLevel emailLogLevel;
    //@testVisible Integer emailBodyLength;
    @testVisible Integer csvRecordCount = 0;

    @testVisible private List<User> emailRecipients {
        get {
            if(emailRecipients == null) {
                Set<String> usernames = Pluck.strings('Username__c', [SELECT Username__c FROM Error_Email_Handled_By_User__mdt]);
                emailRecipients = [SELECT Email FROM User WHERE Username IN: usernames];
            }
            return emailRecipients;
        }set;
    }

    public EmailLogger(LogLevel minLogLevel,String jobname,String jobDescription) {
        this.emailLogLevel = minLogLevel;
        this.emailSubject = Label.Logger_Email_Subject
            .replace(JOB_NAME_PLACEHOLDER, jobname);
        this.emailBodyIntro = String.join(new List<String>{'Job Description : ', jobDescription + '<br/>'}, '');
        this.csvRecordCount = 0;
    }

    public override void emit() {
        if (String.isBlank(this.emailBody) || emailRecipients == null || emailRecipients.isEmpty()) {
            return;
        }
        /* Git#21329, Begin */
        String finalstr = 'Id, Error \n';
        String attName = 'UserErrors' + system.now().format('YYYYMMDDhhmm') + '.csv';
        
        finalstr += emailBody;
        
        Messaging.EmailFileAttachment[] emailAttList = new List<Messaging.EmailFileAttachment>();
        
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(attName);
            efa.setBody(Blob.valueOf(finalstr));
            emailAttList.add(efa);
        /* Git#21329, End */
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>(Pluck.strings(User.Id, this.emailRecipients)));
        email.setSubject(this.emailSubject);
        email.setHtmlBody(String.join(new List<String>{this.emailBodyIntro}, ''));
        email.setFileAttachments(emailAttList); // Git#21329
        email.setSaveAsActivity(false);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        this.emailBody = '';
        this.csvRecordCount = 0;
    }

    public override void log(String exceptionMessage,Type originatingClass) {
        log(exceptionMEssage, originatingClass, null);
    }

    public override void log(String exceptionMessage,Type originatingClass,Sobject record) {
        String recordInfo = '';
        if(record != null) {
            if(record.id != null){
                recordInfo = URL.getSalesforceBaseUrl().toExternalForm() + '/' + record.Id;
            }
            else {
                if(record instanceof Attachment){
                    Attachment att = (Attachment) record;  
                    recordInfo = URL.getSalesforceBaseUrl().toExternalForm() + '/' + att.ParentId;
                }
            }
        }
  /* Commented as part of  Git#21329 */
     /*   String currentErrorMessage = String.join(
            new List<String>{
                'Orginating Class :' + originatingClass.getName(),
                'Exception Message :' + exceptionMessage.abbreviate(EMAIL_CHARACTERS_LIMIT),
                recordInfo
            }, '<br/>'
        );*/
        if(csvRecordCount == 0){
          emailBodyIntro = 'Orginating Class :' + originatingClass.getName() + emailBodyIntro;
        }
        String currentErrorMessage = recordInfo + ','+ exceptionMessage + '\n';

        autoEmit(currentErrorMessage);
    }
    

    @testVisible private void autoEmit(String currentErrorMessage) {
        Integer currentEmailMessageCharacterCount = currentErrorMessage.length();
        if(this.csvRecordCount  > CSV_RECORD_LIMIT && (currentErrorMessage!=null)) { // changed as part of Git#21329
            emit();
            this.emailBody = currentErrorMessage;
            this.csvRecordCount = 0;
        } else {
            this.emailBody += currentErrorMessage;
            this.csvRecordCount++;
        }
    }
}