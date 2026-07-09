/**
* Class: DeleteGlobalServiceCase
*
* Test Class: TestDeleteGlobalServiceCase
*
* Author: TCS
*
* Purpose: This is a Batch class to Delete any Global Service Case record types that are older than 270 days and have a status of Cancelled, 
*          including all related lists and items. This deletion will be automated on a weekly basis.
*
* Requirement: GitLab #29060 
*
* Change History:
*
* Developer                     Date 	             		Description
* -------------------------------------------------------------------------------------------
* Arka Hatui(TCS)				12/Feb/2025                 Initial code
*/

public class DeleteGlobalServiceCase implements Database.Batchable<sObject>, Database.Stateful, Schedulable{

public Case_Deletion_Config__c configGSC;
    
public boolean errorTest = false;  
    
public Integer batchSize;   
Public integer errCount = 0;
public integer successCount = 0;
public integer recordsProcessed = 0; 
public integer cdCount = 0;    
public integer exceptionCount = 0;
public integer recordstobeProcessed = 0;

//Creating Templates for csv file    
//public String Sucstr = 'Id, Subject, Link \n';          
public String ErrStr = 'Id, Case No., Subject, Error \n';
public String cdstr = 'ContentDocumentId, ContentVersionId, Error, Link \n';    
public String exceptionstr = 'No., Type, Exception Error \n';    
    
    public DeleteGlobalServiceCase(boolean passederrorTest){
        this.errorTest = passederrorTest;
         
        configGSC=new Case_Deletion_Config__c();
        configGSC=Case_Deletion_Config__c.getValues('Greater than 270 days');
        batchSize=Integer.valueOf(configGSC.Batch_Size__c);
 
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        string query;

        string[] RecordTypeNamesGSC=configGSC.Record_types__c.split(',');
        system.debug('Ageing Days are: '+configGSC.Ageing_Days__c);
        Date AgeingDateGSC=Date.today().addDays(-Integer.valueOf(configGSC.Ageing_Days__c));
        system.debug('AgeingDateGSC '+AgeingDateGSC);
      	string statusGSC=configGSC.Status__c;
        
        if(Test.isRunningTest()){
        	query='SELECT Id,RecordTypeId,RecordType.Name,createdDate FROM Case WHERE status=:statusGSC and RecordType.Name IN:RecordTypeNamesGSC and createdDate<=:AgeingDateGSC LIMIT 1';
        }
        else{
         	query='SELECT Id,RecordTypeId,RecordType.Name,createdDate FROM Case WHERE status=:statusGSC and RecordType.Name IN:RecordTypeNamesGSC and createdDate<=:AgeingDateGSC'; 
            //query='SELECT Id,RecordTypeId,RecordType.Name,createdDate FROM Case WHERE id = \'500Hr00001bEAEOIA4\'';
        }
        system.debug('The query got executed ');
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Case> CaseLst){
        set<Id> caseIds = new set<Id>();
        Set<Id> idsToGetContentLinkIds = new Set<Id>();
        Map<Id, SObject> IdToSObjectMap = new Map<Id, SObject>(); 
        Map<Id, String> successMap = new Map<Id, String>();
        Map<Id, String> errorMap = new Map<Id, String>();
        Map<Id, String> cdmap = new Map<Id, String>();
        List<ContentVersion> conVerList = new List<ContentVersion>();
        //Map<Id, Id> CasetoContentDocument = new Map<Id, Id>();
        
        Integer index = 0; 
        //Boolean flag = true;

        String baseURL = URL.getOrgDomainURL().toExternalForm();
        system.debug('get base url:'+baseURL);
        
        //Identifying the Cases for execution and Content Document
        for(Case c : CaseLst){
            system.debug('+++record type name in execute method+++'+c.RecordType.Name);
            	caseIds.add(c.Id);
            	idsToGetContentLinkIds.add(c.Id);
            
            //This is code for when FirstPublishLocationId = null in a content doucment. We are commenting this for now because it's affecting the performance.
            //In this section we can capture the case id related to content document which caused the error. But to increase performance we will not capture the case id.
           /* Set<Id> contDocumentIds = new set<Id>();
            Id cntid;
            
            for(ContentDocumentLink cid : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :c.Id]){
				contDocumentIds.add(cid.ContentDocumentId);
                //CasetoContentDocument.put(c.Id,cid.ContentDocumentId);
            }
           	for(ContentVersion cvid : [select Id, ContentDocumentId FROM ContentVersion WHERE FirstPublishLocationId = null AND ContentDocumentId IN :contDocumentIds]){
                cntid = cvid.ContentDocumentId;
                flag = false;
                recordstobeProcessed++;
                break;
            }
            If(flag==false){
                exceptionCount++;
                string errstring = string.format('The error occurred because the FirstPublishLocationId is null for the ContentDocument {0} on Case {1}', new string[]{cntid,c.Id});
                //preparing the csv for the exception
				string recordString3 = '"'+exceptionCount+'","'+'NullPointerException'+'","'+errstring+'"\n';
                exceptionstr += recordString3;
                //system.debug('error occured for content document '+CasetoContentDocument);
            }
            else{
                system.debug('+++record type name in execute method+++'+c.RecordType.Name);
            	caseIds.add(c.Id);
            	idsToGetContentLinkIds.add(c.Id);
            }*/

        }
        
        
        
        if(caseIds.size()>0 && !caseIds.isEmpty()){
            system.debug('the size of the records inside Execute method: '+caseIds.size());
            recordstobeProcessed += caseIds.size();
            Set<Id> contDocumentId = new set<Id>();
            Set<Id> emailMsgIds = new Set<Id>();
            Set<Id> VoiceCallId = new Set<Id>();
            Set<Id> converId = new Set<Id>();
            
            try{    
                system.debug('get the case' + caseIds);
                for(VoiceCall vc : [SELECT Id FROM VoiceCall WHERE NF_Case_Number__c IN :caseIds]){
                    VoiceCallId.add(vc.Id);
                    system.debug('get the Voice Call' + vc);
                }
                
                for(EmailMessage emailId : [SELECT Id FROM EmailMessage WHERE RelatedToId IN :caseIds]){
                    
                    idsToGetContentLinkIds.add(emailId.Id);
                }
               	for(ContentDocumentLink cid : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :idsToGetContentLinkIds]){

                    contDocumentId.add(cid.ContentDocumentId);
                }
                for(ContentVersion cvid : [select Id, ContentDocumentId FROM ContentVersion WHERE FirstPublishLocationId = null AND ContentDocumentId IN :contDocumentId]){
                    contDocumentId.remove(cvid.ContentDocumentId);
                    converId.add(cvid.ContentDocumentId);
                    
                }
                
                //Deleting Case related records
                DELETE [SELECT Id FROM ContentDocument where id IN :contDocumentId];
                DELETE [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN : caseIds];
               
                DELETE [SELECT Id FROM EngagementAttendee WHERE EngagementId IN :VoiceCallId];
                DELETE [SELECT Id FROM VoiceCall WHERE NF_Case_Number__c IN :caseIds];
                
                DELETE [SELECT Id, ParentId, Name FROM Attachment where ParentId IN: caseIds];
                DELETE [SELECT Id, WhoId, WhatId, Subject FROM Task where WhatId IN: caseIds];
        
                DELETE [SELECT Id FROM EmailMessage WHERE RelatedToId IN :caseIds];
                DELETE [Select id from Case_Field_History__c WHERE Case_Lookup__c IN:caseIds];
        
                DELETE [SELECT Id FROM SurveyInvitation where Case__c IN:caseIds];
                DELETE [SELECT Id FROM CX_Survey_Details__c WHERE Case__c IN:caseIds];
                
                DELETE [SELECT Id FROM Case_Action__c WHERE Case__c IN:caseIds];                
                Caselst = [SELECT Id, CaseNumber, Subject FROM Case where id IN: caseIds];
                        
                system.debug('Size of Case list before delete: '+Caselst.size());
                
                Database.DeleteResult[] Successlst;
        
                // Delete the cases
                if(Test.isRunningTest() && errorTest) { 
                    //This is for testing Error Case
                    Id errorId = Caselst[0].Id;
                    Database.DeleteResult dr = (Database.DeleteResult)
                        JSON.deserialize('{ "id":"'+errorId+'", "success":false,"errors":[{"message":"You cannot do this...","statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION"}]}', Database.DeleteResult.class);
                    Successlst = new List<Database.DeleteResult>();
                    Successlst.add(dr);
                }else{
                    
                    Successlst = Database.delete(Caselst, false);
                }
                for (Database.DeleteResult sr : Successlst) {
                    
                    //Capturing the Success and errors for the Case deletion 
                    if (sr.isSuccess()) {
                        
                        // Operation was successful, so get the ID of the record that was processed
                        String SuccessMsg = baseURL + '/' + sr.Id;
                        successMap.put(sr.getId(), SuccessMsg);
                        successCount++;                		
                        System.debug('Successfully Deleted Case. Case ID: ' + sr.getId());
                        system.debug('Success Count: ' + successCount);
                    }
                    else {
                        
                        // Operation failed, so get all errors 
                        Database.Error error = sr.getErrors().get(0);
                        String failedDML = error.getMessage();
                        errorMap.put(sr.getId(), failedDML);
                        errCount++;               
                        system.debug('the following is the size of error: '+errorMap.keySet().Size());                  
                        System.debug(error.getStatusCode() + ': ' + error.getMessage());
                        System.debug('Case fields that affected this error: ' + error.getFields());
                        system.debug('Error Count: ' + errCount);
                    }
                    
                    //Cases Processed, add them to the map
                    system.debug('Id of the last Case processed: ' + Caselst[index].Id);
                    IdToSObjectMap.put(Caselst[index].Id, Caselst[index]);
                    index++;
    			}
                
                //Count the total number of records processed
                recordsProcessed += IdToSObjectMap.size();
                System.debug('Total Size of Case processed is '+ recordsProcessed);
                System.debug('Total Success Count '+ successCount + 'Total Error count: '+ errCount);
                
                //Commenting out the success emails because we don't need it for now and it's affecting the performance
        		// Creating the CSV file for successful updates
        		/*if(!successMap.isEmpty()) {
          			System.debug('The map size is ' + successMap.size() + ' and ' + successCount);
                	for(Id id  : successMap.keySet()){
                    string suc = successMap.get(id);
                    Case csk = (Case) IdToSObjectMap.get(id);
                    string recordString = '"'+id+'","'+csk.subject+'","'+suc+'"\n';
                    Sucstr += recordString;
                 	}
				}*/
        
        		// Creating the CSV file for error
        		if(!errorMap.isEmpty()){
            		for(Id id  : errorMap.keySet()){
                		string err = errorMap.get(id);
                		Case csk = (Case)IdToSObjectMap.get(id);
                		string recordString1 = '"'+id+'","'+csk.CaseNumber+'","'+csk.Subject+'","'+err+'"\n';
                		ErrStr = ErrStr + recordString1;
            		}
        		}
                
                // Creating the CSV file for errored content document
                if(!converId.isEmpty()){
                    conVerList = [select Id, ContentDocumentId FROM ContentVersion WHERE FirstPublishLocationId = null AND ContentDocumentId IN :converId];
                    for(ContentVersion cv : conVerList){
                        String cdlink = baseURL + '/' + cv.ContentDocumentId;
                        string recordString3 = '"'+cv.ContentDocumentId+'","'+cv.Id+'","'+'NullPointerException: FirstPublishLocationId = null'+'","'+cdlink+'"\n';
                        cdstr += recordString3;
                        cdCount++;
                    }
                }
                
            } catch(exception e){
                                exceptionCount++;
                
                //preparing the csv for the exception
				string recordString2 = '"'+exceptionCount+'","'+e.getTypeName()+'","'+e.getMessage()+'"\n';
                exceptionstr += recordString2;
                system.debug('exception occurs in the catch method: '+e.getMessage());
            }
        }
        
        
    }
    
    public void finish(Database.BatchableContext bc){
        if(recordsProcessed > 0 || exceptionCount > 0) {
            
            //Send an email to the User after your batch completes
            AsyncApexJob a = [SELECT id, ApexClassId,
                              JobItemsProcessed, TotalJobItems,
                              NumberOfErrors, CreatedBy.Email
                              FROM AsyncApexJob
                              WHERE id = :BC.getJobId()];
            String body = Label.DeleteGlobalServiceCase_Body;
            
            //Preparing the Couters to send through the mail.
            body = body.replace('IdToSObjectMap.size()',String.valueOf(recordstobeProcessed));
            system.debug('Case volume Size in finish method: ' + recordstobeProcessed);
            
            body = body.replace('successMap.size()',String.valueOf(successCount));
            system.debug('Number of successful processed records: ' + successCount);
            
            body = body.replace('errorMap.size()',String.valueOf(errCount));
            system.debug('Number of Errored records: ' + errCount);
            
            body = body.replace('recordMap.size()',String.valueOf(recordstobeProcessed-recordsProcessed));
            system.debug('Number of Exception records: ' + (recordstobeProcessed-recordsProcessed));
            
            String subject = Label.DeleteGlobalServiceCase_Subject;
            // Define the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            // Define email file attachment list
            Messaging.EmailFileAttachment[] emailAttList = new List<Messaging.EmailFileAttachment>();
            
            // Create the email attachment for errors  
            if(errCount>0){
                String attName = 'Case Errors ' + system.now().format('YYYYMMDDhhmm') + '.csv'; 
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(attName);
                efa.setBody(Blob.valueOf(ErrStr));
                //efa.setBody(Blob.valueOf(exceptionstr));
                emailAttList.add(efa);
            }
            
            //Commenting out the success emails because we don't need it for now and it's affecting the performance
            // Create the email attachment for success 
            /*if(successCount > 0) {
                String attName = 'Case Success ' + system.now().format('YYYYMMDDhhmm') + '.csv'; 
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(attName);
                efa.setBody(Blob.valueOf(Sucstr));
                emailAttList.add(efa);   
            }*/
            
            // Create the email attachment for exception   
            if(exceptionCount>0){
                String attName = 'Case Exception ' + system.now().format('YYYYMMDDhhmm') + '.csv';
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(attName);
                efa.setBody(Blob.valueOf(exceptionstr));
                emailAttList.add(efa);
            }
            
            //Create the email attachment for undeleted Content Document
            if(cdCount>0){
                String attName = 'Errors from Content Document ' + system.now().format('YYYYMMDDhhmm') + '.csv';
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(attName);
                efa.setBody(Blob.valueOf(cdstr));
                emailAttList.add(efa);
            }
            
            String[] toDddr = new String[]{};
            toDddr=configGSC.Send_Email_To__c.split(',');
            system.debug('toDddr :::'+toDddr);   
            // Sets the paramaters of the email
            email.setSubject( subject );
            email.setToAddresses( toDddr );
            email.setPlainTextBody( body );
            email.setFileAttachments(emailAttList);
            // Sends the email
            Messaging.SendEmailResult [] r =
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            system.debug('email sent');
        }
    }
    
     public void execute(SchedulableContext sc) {
        If(Test.isRunningTest()){

      		ID jobID = Database.executeBatch(new DeleteGlobalServiceCase(errorTest), 10);
      		//System.abortJob(jobID);

        }else{
            ID BatchId = Database.executeBatch(new DeleteGlobalServiceCase(errorTest), batchSize);
        }
    }
}