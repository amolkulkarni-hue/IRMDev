public class DeleteImeScCasesAndRelatedLst implements Database.Batchable<sObject>, Database.Stateful {
public set<Id> caseIds=new set<Id>();
public list<Case> caselst;
public Date AgeingDate;
public string[] RecordTypeNames;
public string[] emailslst;
//public string RecordTypeNames;
public string status;
public string IMESC_ClosureReason;
public IMESC_Case_Deletion_Config__c config;
//Map<string, Case_Deletion_Config__c> config;
Public integer recordsProcessed=0;
String baseURL;
Map<Id, String> errorMap;
Map<Id, SObject> IdToSObjectMap;
Map<Id, String> successMap;
    public DeleteImeScCasesAndRelatedLst(){
        errorMap = new Map<Id, String>();
        successMap = new Map<Id, String>();
        IdToSObjectMap = new Map<Id, SObject>();
        baseURL = URL.getSalesforceBaseUrl().toExternalForm();
            system.debug('get base url:'+baseURL);
        //config = Case_Deletion_Config__c.getAll();
        config=new IMESC_Case_Deletion_Config__c();
        config=IMESC_Case_Deletion_Config__c.getValues('IME SC Case');
        AgeingDate=Date.today().addDays(-Integer.valueOf(config.Ageing_Days__c));
        //if we use multiple record types seperated by custom setting value should be in the IME SC Case,NAS General Support Case format)
        RecordTypeNames=config.Record_types__c.split(',');
        //emailslst=config.Send_Email_To__c.split(',');
        //RecordTypeNames=config.Record_types__c;
        system.debug('Record Type Names are:'+RecordTypeNames);
        status=config.Status__c;
        IMESC_ClosureReason=config.Closure_Reason__c;
        caselst=new list<Case>();
        
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug('++++aging+++++:'+AgeingDate);
        system.debug('++++++Recordtype Name+++:'+RecordTypeNames);
        system.debug('++++Status++++'+status);
        system.debug('++++++Closure Reason++++++'+IMESC_ClosureReason);
       string query='select Id,Subject,RecordTypeId,RecordType.Name,createdDate,IME_SC_Closure_Reason__c from Case where createdDate<=:AgeingDate and status=:status and RecordType.Name IN:RecordTypeNames and IME_SC_Closure_Reason__c=:IMESC_ClosureReason';
        //string query='select Id, RecordTypeId,RecordType.Name,createdDate from Case where createdDate<=:AgeingDate and status=:status and RecordType.Name=\'IME SC Case\'' ;
        //string query='select Id, RecordTypeId,RecordType.Name,createdDate from Case where createdDate<=:AgeingDate and status=:status and RecordType.Name IN (\'IME SC Case\',\'NAS General Support Case\')' ;

        return Database.getQueryLocator(query); 
    }
    public void execute(Database.BatchableContext bc, List<Case> CaseLst){
        Integer index = 0;
        for(Case c : CaseLst){
            system.debug('+++record type name in execute method+++'+c.RecordType.Name);
            caseIds.add(c.Id);
        }
        if(caseIds.size()>0 && !caseIds.isEmpty()){
            system.debug('the size of the records are:'+caseIds.size());
            try{    
        DELETE [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN : caseIds];
        DELETE [SELECT Id, ParentId, LatestPublishedVersionId, PublishStatus, ArchivedById, CreatedById, ContentAssetId FROM ContentDocument where id IN :caseIds];
        DELETE [SELECT Id, ParentId, Name FROM Attachment where ParentId IN: caseIds];
        DELETE [SELECT Id, WhoId, WhatId, Subject FROM Task where WhatId IN: caseIds];
        DELETE [SELECT Id FROM EmailMessage WHERE RelatedToId IN :caseIds];
        DELETE [Select id from Case_Field_History__c WHERE Case_Lookup__c IN:caseIds];
        //Commented as part of #12563       
     /* DELETE [Select Id from SFDC_Bug__c WHERE Case__c IN:caseIds];
        DELETE [Select Id from Sales_Tool_Project_Case__c WHERE Parent__c IN:caseIds]; */
        DELETE [SELECT Id FROM CX_Survey_Details__c WHERE Case__c IN:caseIds];
        DELETE [SELECT Id FROM Case_Action__c WHERE Case__c IN:caseIds];
        caselst= [SELECT Id,subject FROM Case where id IN: caseIds];
                system.debug('the size in execute method before delete:'+caselst.size());
        Database.DeleteResult[] srList = Database.delete(caselst, false);
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
            IdToSObjectMap.put(caselst[index].Id, caselst[index]);
            index++;
    }    
            } catch(exception e){
                system.debug('exception occurs in the catch method:'+e.getMessage());
               /* Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
               String[] toAddresses=new String[]{};
	           toAddresses=config.Send_Email_To__c.split(',');
               mail.setToAddresses(toAddresses);
               mail.setSenderDisplayName('Error in Batch Apex DeleteImeScCasesAndRelatedLst');
               mail.setSubject('Error from Org : ' + UserInfo.getOrganizationName());
               mail.setPlainTextBody(e.getMessage());
               Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); */
            } 
            
        }
    }
    public void finish(Database.BatchableContext bc){
         if(!IdToSObjectMap.isEmpty()) {
            //Send an email to the User after your batch completes
            AsyncApexJob a = [SELECT id, ApexClassId,
                              JobItemsProcessed, TotalJobItems,
                              NumberOfErrors, CreatedBy.Email
                              FROM AsyncApexJob
                              WHERE id = :BC.getJobId()];
            String body = Label.AgedCaseDeleteBody;
            body=body.replace('IdToSObjectMap.size()',String.valueOf(IdToSObjectMap.size()));
            String subject = Label.AgedCaseSubject;
            // Define the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            // Define email file attachment list
            Messaging.EmailFileAttachment[] emailAttList = new List<Messaging.EmailFileAttachment>();
            if(!errorMap.isEmpty()){
                // Creating the CSV file for error
                String finalstr = 'Id, Subject, Error \n';
               
                String attName = 'CaseErrors' + system.now().format('YYYYMMDDhhmm') + '.csv';
                for(Id id  : errorMap.keySet()){
                    string err = errorMap.get(id);
                    Case csk = (Case)IdToSObjectMap.get(id);
                    string recordString = '"'+id+'","'+csk.Subject+'","'+err+'"\n';
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
                String attName = 'Case Success' + system.now().format('YYYYMMDDhhmm') + '.csv';
                for(Id id  : successMap.keySet()){
                    string suc = successMap.get(id);
                    Case csk = (Case) IdToSObjectMap.get(id);
                    string recordString = '"'+id+'","'+csk.subject+'","'+suc+'"\n';
                    finalstr = finalstr +recordString;
                }
               
                // Create the email attachment    
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(attName);
                efa.setBody(Blob.valueOf(finalstr));
                emailAttList.add(efa);
                 
            }
            String[] toDddr = new String[]{};
            toDddr=config.Send_Email_To__c.split(',');
            system.debug('toDddr :::'+toDddr);   
            // Sets the paramaters of the email
            email.setSubject( subject );
            email.setToAddresses( toDddr );
            email.setPlainTextBody( body );
            email.setFileAttachments(emailAttList);
            // Sends the email
            Messaging.SendEmailResult [] r =
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
    }
}