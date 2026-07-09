/*Modified by: Simranjit Kaur
 *          User Story: #8796 Enable Rolling 7 Day Orders case record type archiving automation
 * 	        Record Type: Global Orders 
 * */
public class DeleteCasesAndRelatedLst implements Database.Batchable<sObject>, Database.Stateful {
public set<Id> caseIds=new set<Id>();
public Date AgeingDate;
public string[] RecordTypeNames;
public string status;
public Case_Deletion_Config__c config;
    
public Case_Deletion_Config__c configGlobal;
public Date AgeingDateGlobal;
public string[] RecordTypeNamesGlobal;
public string statusGlobal;
//Map<string, Case_Deletion_Config__c> config;
Public integer recordsProcessed=0;
    public DeleteCasesAndRelatedLst(){
        //config = Case_Deletion_Config__c.getAll();
        config=new Case_Deletion_Config__c();
        configGlobal=new Case_Deletion_Config__c();
        
        config=Case_Deletion_Config__c.getValues('Greater than 30days');
        AgeingDate=Date.today().addDays(-Integer.valueOf(config.Ageing_Days__c));
        RecordTypeNames=config.Record_types__c.split(',');
        system.debug('Record Type Names are:'+RecordTypeNames);
        status=config.Status__c;
        
        configGlobal=Case_Deletion_Config__c.getValues('Greater than 7days');
        RecordTypeNamesGlobal=configGlobal.Record_types__c.split(',');
        //system.debug('Record Type Names are:'+RecordTypeNamesGlobal);
        //system.debug('Ageing Days are:'+configGlobal.Ageing_Days__c);
        AgeingDateGlobal=Date.today().addDays(-Integer.valueOf(configGlobal.Ageing_Days__c));
        statusGlobal=configGlobal.Status__c;
        
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        //system.debug('++++aging+++++:'+AgeingDate);
        //system.debug('++++++Recordtype Name+++:'+RecordTypeNames);
        //system.debug('++++Status++++'+status);
        //Updated the query for record type Global Orders
        string query='select Id, RecordTypeId,RecordType.Name,createdDate from Case where (createdDate<=:AgeingDate and status=:status and RecordType.Name IN:RecordTypeNames) OR (createdDate<=:AgeingDateGlobal and status=:statusGlobal and RecordType.Name IN:RecordTypeNamesGlobal)';    
            
        //string query='select Id, RecordTypeId,RecordType.Name,createdDate from Case where createdDate<=:AgeingDate and status=:status and RecordType.Name=\'IME SC Case\'' ;
        //string query='select Id, RecordTypeId,RecordType.Name,createdDate from Case where createdDate<=:AgeingDate and status=:status and RecordType.Name IN (\'IME SC Case\',\'NAS General Support Case\')' ;
        return Database.getQueryLocator(query); 
    }
    public void execute(Database.BatchableContext bc, List<Case> CaseLst){
        Set<Id> idsToGetContentLinkIds = new Set<Id>();
        for(Case c : CaseLst){
            system.debug('+++record type name in execute method+++'+c.RecordType.Name);
            caseIds.add(c.Id);
            idsToGetContentLinkIds.add(c.Id);
        }
        if(caseIds.size()>0 && !caseIds.isEmpty()){
            system.debug('the size of the records are:'+caseIds.size());
            Set<Id> contDocumentId = new set<Id>();
            Set<Id> emailMsgIds = new Set<Id>();
            
            try{    
                for(EmailMessage emailId : [SELECT Id FROM EmailMessage WHERE RelatedToId IN :caseIds]){
                    idsToGetContentLinkIds.add(emailId.Id);
                }
               for(ContentDocumentLink cid : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN : idsToGetContentLinkIds]){
                   // system.debug('cLinkid '+cid);
                    contDocumentId.add(cid.ContentDocumentId);
                }
           		//system.debug('idsToGetContentLinkIds '+idsToGetContentLinkIds);
                //system.debug('contDocumentId'+contDocumentId);
      DELETE [SELECT Id FROM ContentDocument where id IN :contDocumentId];
       	DELETE [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId IN : caseIds];
       
        DELETE [SELECT Id, ParentId, Name FROM Attachment where ParentId IN: caseIds];
        DELETE [SELECT Id, WhoId, WhatId, Subject FROM Task where WhatId IN: caseIds];
        DELETE [SELECT Id FROM EmailMessage WHERE RelatedToId IN :caseIds];
        DELETE [Select id from Case_Field_History__c WHERE Case_Lookup__c IN:caseIds];
      
        //Commented as part of #12563
     /* DELETE [Select Id from SFDC_Bug__c WHERE Case__c IN:caseIds];
        DELETE [Select Id from Sales_Tool_Project_Case__c WHERE Parent__c IN:caseIds]; */
        DELETE [SELECT Id FROM SurveyInvitation where Case__c IN:caseIds];
        DELETE [SELECT Id FROM CX_Survey_Details__c WHERE Case__c IN:caseIds];
        DELETE [SELECT Id FROM Case_Action__c WHERE Case__c IN:caseIds];
        DELETE [SELECT Id FROM Case where id IN: caseIds];
            } catch(exception e){
                system.debug('exception occurs in the catch method:'+e.getMessage());
            }
            /*try{
        DELETE [SELECT Id FROM Case where id IN: caseIds];
            }catch(exception e){
              Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
               String[] toAddresses=new String[]{};
	           toAddresses=config.Send_Email_To__c.split(',');
               mail.setToAddresses(toAddresses);
               mail.setSenderDisplayName('Apex error message');
               mail.setSubject('Error from Org : ' + UserInfo.getOrganizationName());
               mail.setPlainTextBody(e.getMessage());
               Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
            } */
        }
    }
    public void finish(Database.BatchableContext bc){
        
    }
}