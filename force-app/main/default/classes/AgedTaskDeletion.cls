/** 
 *Author: Rajashekar Kampally/Praneel
 *Date: 08/16/2021
 *Comments: Batch Class for deletion of task which deletes 4+ Years open task.
 * Gitlab # 4027
 */
global class AgedTaskDeletion implements 
    Database.Batchable<sObject>, Database.Stateful {
        global integer recordsProcessed=0;
      // global static Date AgeingDate = Date.today().addDays(-1460);
        Map<Id, String> errorMap;
        Map<Id, SObject> IdToSObjectMap;
        Map<Id, String> successMap;
        String baseURL;
        SendTaskDeleteEmail__c getEmails;
        //constructor
        public AgedTaskDeletion(){
        errorMap = new Map<Id, String>();
        successMap = new Map<Id, String>();
        IdToSObjectMap = new Map<Id, SObject>();
        baseURL = URL.getSalesforceBaseUrl().toExternalForm();
            system.debug('get base url:'+baseURL);
        getEmails = SendTaskDeleteEmail__c.getValues('Emaillist');
            system.debug('list of emails'+getEmails);
    }
        
   // global Date CurrentDate=system.today();
       // global Date AgeingDate=CurrentDate-1460;
   global Database.QueryLocator start(Database.BatchableContext bc) {
       
       Date AgeingDate = Date.today().addDays(-Integer.valueOf(getEmails.AgeingDays__c));
       system.debug('Date before 4 years:'+AgeingDate);
        return Database.getQueryLocator(
            'SELECT Id, Subject FROM Task where  status=\'Not Started\' and Due_Date__c=null and createdDate<=:AgeingDate and IsRecurrence=false'
        );
       
    }
        
    global void execute(Database.BatchableContext bc, List<Task> taskList){
        system.debug('the size of task records:'+taskList.Size());
        Integer index = 0;
		Database.DeleteResult[] srList = Database.delete(taskList, false);
        Database.emptyRecycleBin(taskList);
        system.debug('Size of delete Results:'+srList.Size());
        for (Database.DeleteResult sr : srList) {
            if (sr.isSuccess()) {
                String sucMsg = baseURL + '/' + sr.Id;
                successMap.put(sr.getId(), sucMsg);
        // Operation was successful, so get the ID of the record that was processed
        System.debug('Successfully Deleted Task. Task ID: ' + sr.getId());
    }
    else {
        Database.Error error = sr.getErrors().get(0);
        String failedDML = error.getMessage();
        errorMap.put(sr.getId(), failedDML);
        // Operation failed, so get all errors                
        system.debug('the following is the size of error:'+errorMap.keySet().Size());
            System.debug('The following error has occurred.');                    
            System.debug(error.getStatusCode() + ': ' + error.getMessage());
            System.debug('Task fields that affected this error: ' + error.getFields());
        }
            IdToSObjectMap.put(taskList[index].Id, taskList[index]);
            index++;
    }    
    }
    global void finish(Database.BatchableContext bc){
        if(!IdToSObjectMap.isEmpty()) {
            //Send an email to the User after your batch completes
            AsyncApexJob a = [SELECT id, ApexClassId,
                              JobItemsProcessed, TotalJobItems,
                              NumberOfErrors, CreatedBy.Email
                              FROM AsyncApexJob
                              WHERE id = :BC.getJobId()];
            String body = Label.AgedTaskBody;
            body=body.replace('IdToSObjectMap.size()',String.valueOf(IdToSObjectMap.size()));
            String subject = Label.AgedTaskSubject;
            // Define the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            // Define email file attachment list
            Messaging.EmailFileAttachment[] emailAttList = new List<Messaging.EmailFileAttachment>();
            if(!errorMap.isEmpty()){
                // Creating the CSV file for error
                String finalstr = 'Id, Subject, Error \n';
               
                String attName = 'TaskErrors' + system.now().format('YYYYMMDDhhmm') + '.csv';
                for(Id id  : errorMap.keySet()){
                    string err = errorMap.get(id);
                    Task Tsk = (Task)IdToSObjectMap.get(id);
                    string recordString = '"'+id+'","'+Tsk.Subject+'","'+err+'"\n';
                    finalstr = finalstr +recordString;
                }
                               
                // Create the email attachment    
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(attName);
                efa.setBody(Blob.valueOf(finalstr));
                emailAttList.add(efa);
            }
            if(! successMap.isEmpty()) {
                // Creating the CSV file for successful updates
                String finalstr = 'Id, Subject, Link \n';
                String attName = 'TaskSuccess' + system.now().format('YYYYMMDDhhmm') + '.csv';
                for(Id id  : successMap.keySet()){
                    string suc = successMap.get(id);
                    Task tsk = (Task) IdToSObjectMap.get(id);
                    string recordString = '"'+id+'","'+tsk.Subject+'","'+suc+'"\n';
                    finalstr = finalstr +recordString;
                }
               
                // Create the email attachment    
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(attName);
                efa.setBody(Blob.valueOf(finalstr));
                emailAttList.add(efa);
                 
            }
            String[] toDddr = new String[]{};
            
            toDddr = getEmails.Emails__c.split(',');
            system.debug('toDddr :::'+toDddr);
                
            // Sets the paramaters of the email
            email.setSubject( subject );
            ///*getEmails.Emails__c*/
            email.setToAddresses( toDddr );
            email.setPlainTextBody( body );
            email.setFileAttachments(emailAttList);
           
            // Sends the email
            Messaging.SendEmailResult [] r =
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
     // can add here any email notification code  
    }    
}