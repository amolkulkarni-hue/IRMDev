/**
* Class: DeleteRelatedObjectofAgeingCases
*
* Author: TCS
*
* Purpose: This is a Batch class to get the case records based on record types specified in custom metadata and delete
case related records
*		   It is going to call the batch class 'DeleteAgeingCases' to delete the case records
*
* Requirement: GitLab #5516  
*
* Change History:
*
* Developer                     Date 	             		Description
* -------------------------------------------------------------------------------------------
* TCS                          11/Nov/2022                  Initial code
*/

global class DeleteRelatedObjectofAgeingCases implements Database.Batchable<sObject>, Database.Stateful,Schedulable{
    //Case_Field_History__c 
    //SFDC_Bug__c
    //Sales_Tool_Project_Case__c
    //CX_Survey_Details__c
    //Case_Action__c
    
    global set<Id> caseIdsToDelete;
    public Date agingDate;
    public string[] recordTypeNames;
    public string[] status;
    public Case_Deletion_Config__c config;
    public boolean errorTest = false; 
    global set<Id> caseIdsToBeSentForDelete;
    List<Id> contntId= new List<Id>();
    Integer batchSize;
    
    global DeleteRelatedObjectofAgeingCases(){
        errorTest = false;
        batchSize = 100;
    }
    
    global DeleteRelatedObjectofAgeingCases(boolean passederrorTest){
        caseIdsToBeSentForDelete = new Set<Id>();
        this.errorTest = passederrorTest;
        config = Case_Deletion_Config__c.getValues('Greater than 3 years');
        agingDate = Date.today().adddays(-Integer.valueOf(config.Ageing_Days__c));
        recordTypeNames = config.Record_types__c.split(',');
        system.debug('Record Type Names are:'+RecordTypeNames);
        status = config.Status__c.split(',');
       	batchSize = Integer.valueOf(config.Batch_Size__c);
        system.debug('status '+status); 
        system.debug('aging date'+agingDate);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
       //String query = 'SELECT id,RecordType.Name from case where casenumber = \'01847466\' and RecordType.Name in (\'NAS General Support Case\',\'Customer Case Record Type\',\'IM Employees Support Case\',\'IM Employees Support Case Closed (Locked)\',\'Issue\',\'Issue Request\')';
     	String query='SELECT Id, RecordTypeId,RecordType.Name,createdDate from Case where createdDate<=:agingDate and status IN:status and RecordType.Name IN:recordTypeNames'; 
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        caseIdsToDelete = (new Map<Id,SObject>(scope)).keySet();
        //system.debug('caseIdsToDelete in main class'+caseIdsToDelete);
        
        
        if(caseIdsToDelete.size() > 0 && !caseIdsToDelete.isEmpty()){
            try{
                
                for(ContentDocumentLink contid:[SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN : caseIdsToDelete]){
                    contntId.add(contid.ContentDocumentId);
                }
               
                Database.DeleteResult[] conDocLinkLst = Database.delete([SELECT id,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN : caseIdsToDelete], false);
                Database.DeleteResult[] conDocLst = Database.delete([SELECT Id, ParentId, LatestPublishedVersionId, PublishStatus, ArchivedById, CreatedById, ContentAssetId FROM ContentDocument where id IN :contntId], false);
                //DELETE [SELECT id,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN : caseIdsToDelete];
                //DELETE [SELECT Id, ParentId, LatestPublishedVersionId, PublishStatus, ArchivedById, CreatedById, ContentAssetId FROM ContentDocument where id IN :contntId];
                //DELETE [SELECT Id, ParentId, Name FROM Attachment where ParentId IN: caseIdsToDelete];
                //DELETE [SELECT Id, WhoId, WhatId, Subject FROM Task where WhatId IN: caseIdsToDelete];
                //DELETE [SELECT Id FROM EmailMessage WHERE RelatedToId IN :caseIdsToDelete];
                DELETE [Select id from Case_Field_History__c WHERE Case_Lookup__c IN:caseIdsToDelete];
               // Commented as part of 12563
             /* DELETE [Select Id from SFDC_Bug__c WHERE Case__c IN:caseIdsToDelete];
                DELETE [Select Id from Sales_Tool_Project_Case__c WHERE Parent__c IN:caseIdsToDelete]; */
                DELETE [SELECT Id FROM CX_Survey_Details__c WHERE Case__c IN:caseIdsToDelete];
                DELETE [SELECT Id FROM Case_Action__c WHERE Case__c IN:caseIdsToDelete];
                caseIdsToBeSentForDelete.addAll(caseIdsToDelete);
            }catch(exception e){
                system.debug('Exception in deleting case related object records');
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        system.debug('caseIdsToBeSentForDelete in final '+this.caseIdsToBeSentForDelete.size() + ' Batch size '+batchSize);
        if(caseIdsToBeSentForDelete != null && caseIdsToBeSentForDelete.size() > 0) {
            DeleteAgeingCases delAgingCases = new DeleteAgeingCases(caseIdsToBeSentForDelete,errorTest);
            Database.executeBatch(delAgingCases,batchSize);
        }
	
    }
    
    global void execute(SchedulableContext sc) {
        DeleteRelatedObjectofAgeingCases doa = new DeleteRelatedObjectofAgeingCases(errorTest);
        database.executeBatch(doa,batchSize);
    }
}