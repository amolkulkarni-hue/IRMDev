/*****************************************************************************************************
* Class: QTB_AttachmentsEditDeleteController
* Author: IRM/Virtusa
* Purpose: This is a helper class for logic to restrict the user to delete or insert/edit the attachment
* Requirement: 
* Test Class: QTB_AttachmentsEditDeleteController_Test
* Change History: 11/29/2022 11/29/2024
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Suprabha     11/29/2022      Gitlab US #11539 unable to delete or change attachments
* Priyatham    11/29/2024	   Gitlab US #26907 blocking automatedUsers
*******************************************************************************************************/
public with sharing class QTB_AttachmentsEditDeleteController {
    private static final String CLASSNAME = QTB_AttachmentsEditDeleteController.class.getName();
    
    /***********************************************************************************************************
* Method :      processInsert
* Parameters:   List<ContentVersion>
* Return Type : void
* Description:  Generic method to handle insert and update operations on notes and attachments 
**************************************************************************************************************/
    public static void processInsert(List<ContentVersion> conVer) {
        Set<Id> caseIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        Boolean blnAutomatedUser = getLoginUserType(); 
        // Blocking AutomatedProcess
        if(!blnAutomatedUser){
            Profile profileObj = getLoginUserProfile();
            Set<String> excludedProfileSet = getExcludedUserProfiles();
            
            for(ContentVersion cv : conVer){
                if(cv.FirstPublishLocationId != null && String.valueOf(cv.FirstPublishLocationId).startsWith('500')){
                    caseIdSet.add(cv.FirstPublishLocationId);
                }
                if(cv.FirstPublishLocationId != null && String.valueOf(cv.FirstPublishLocationId).startsWith('006')){
                    oppIdSet.add(cv.FirstPublishLocationId);
                }
            }
            
            //Check profile on content Document and add the error when profile is restricted
            Map<Id, Case> caseMap = new Map<Id, Case>();
            Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>();
            if(!caseIdSet.isEmpty()){
                caseMap = getCaseByIdMap(caseIdSet);
            }
            if(!oppIdSet.isEmpty()){
                oppsMap = getOpportunityByIdMap(oppIdSet);
            }
            
            if(!caseMap.isEmpty() || !oppsMap.isEmpty()){
                for(ContentVersion cv : conVer){
                    String caseOrOppId = cv.FirstPublishLocationId;
                    if(caseOrOppId.startsWith('500') && (caseMap.get(cv.FirstPublishLocationId).NCSP_Opportunity__r.StageName == '6 - Setup' || caseMap.get(cv.FirstPublishLocationId).NCSP_Opportunity__r.StageName == '7 - Closed') && excludedProfileSet.contains(profileObj.Name)){
                        cv.addError('Cannot upload or delete a file');
                    }
                    if(caseOrOppId.startsWith('006') && (oppsMap.get(cv.FirstPublishLocationId).StageName == '6 - Setup' || oppsMap.get(cv.FirstPublishLocationId).StageName == '7 - Closed') && excludedProfileSet.contains(profileObj.Name)){
                        cv.addError('Cannot upload or delete a file');
                    }
                } 
            }
        }
    }
    
    /***********************************************************************************************************
* Method :      processDelete
* Parameters:   List<ContentDocument>
* Return Type : void
* Description:  Generic method to handle delete operations on notes and attachments based on profile
**************************************************************************************************************/    
    public static void processDelete(List<ContentDocument> conDoc) {
        Set<Id> conIdSet = new Set<Id>();
        Set<Id> caseIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        List<ContentVersion> conVerList = new List<ContentVersion>();
        Boolean blnAutomatedUser = getLoginUserType();
        // Blocking AutomatedProcess
        if(!blnAutomatedUser){
            
            Profile profileObj = getLoginUserProfile();
            Set<string> excludedProfileSet = getExcludedUserProfiles();
            
            for(ContentDocument cd : conDoc){
                conIdSet.add(cd.Id);
            }
            
            if(!conIdSet.isEmpty()){
                conVerList = [select Id, ContentDocumentId, FirstPublishLocationId FROM ContentVersion WHERE ContentDocumentId IN : conIdSet];
            }
            
            Map<Id, ID> cvMap = new Map<Id, ID>();
            for(ContentVersion cv : conVerList){
                if(cv.FirstPublishLocationId != null && String.valueOf(cv.FirstPublishLocationId).startsWith('500')){
                    caseIdSet.add(cv.FirstPublishLocationId);
                }
                if(cv.FirstPublishLocationId != null && String.valueOf(cv.FirstPublishLocationId).startsWith('006')){
                    oppIdSet.add(cv.FirstPublishLocationId);
                }
                cvMap.put(cv.ContentDocumentId, cv.FirstPublishLocationId);
            }
            
            //Check profile on content Document and add the error when profile is restricted
            Map<Id, Case> caseMap = new Map<Id, Case>();
            Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>();
            if(!caseIdSet.isEmpty()){
                caseMap = getCaseByIdMap(caseIdSet);
            }
            if(!oppIdSet.isEmpty()){
                oppsMap = getOpportunityByIdMap(oppIdSet);
            }
            
            if(!caseIdSet.isEmpty() || !oppIdSet.isEmpty()){
                for(ContentDocument cd : conDoc){
                    String caseOrOppId = cvMap.get(cd.id);
                    if(caseOrOppId.startsWith('500') && (caseMap.get(caseOrOppId).NCSP_Opportunity__r.StageName == '6 - Setup' || caseMap.get(caseOrOppId).NCSP_Opportunity__r.StageName == '7 - Closed') && excludedProfileSet.contains(profileObj.Name)){
                        cd.addError('Cannot upload or delete a file');
                    }
                    
                    if(caseOrOppId.startsWith('006') && (oppsMap.get(caseOrOppId).StageName == '6 - Setup' || oppsMap.get(caseOrOppId).StageName == '7 - Closed') && excludedProfileSet.contains(profileObj.Name)){
                        cd.addError('Cannot upload or delete a file');
                    }
                } 
            }
        }
    }
    
    /***********************************************************************************************************
* Method :      processDeleteAttachment
* Parameters:   List<Attachment>
* Return Type : void
* Description:  Generic method to handle delete operations on notes and attachments based on profile
**************************************************************************************************************/     
    public static void processDeleteAttachment(List<Attachment> attachmentList) {
        System.debug('>>>processDeleteAttachment');
        Set<Id> caseIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        
        Profile profileObj = getLoginUserProfile();
        Set<string> excludedProfileSet = getExcludedUserProfiles();
        
        System.debug('>>>excludedProfileSet'+excludedProfileSet);
        
        Map<Id, ID> attMap = new Map<Id, ID>();
        for(Attachment attachObj : attachmentList){
            if(attachObj.ParentId != null && String.valueOf(attachObj.ParentId).startsWith('500')){
                caseIdSet.add(attachObj.ParentId);
            }
            if(attachObj.ParentId != null && String.valueOf(attachObj.ParentId).startsWith('006')){
                oppIdSet.add(attachObj.ParentId);
            }
            attMap.put(attachObj.Id, attachObj.ParentId);
        }
        
        System.debug('>>>caseIdSet'+caseIdSet);
        System.debug('>>>oppIdSet'+oppIdSet);
        System.debug('>>>attMap'+attMap);
        Map<Id, Case> caseMap = new Map<Id, Case>();
        Map<Id, Opportunity> oppsMap = new Map<Id, Opportunity>();
        if(!caseIdSet.isEmpty()){
            caseMap = getCaseByIdMap(caseIdSet);
        }
        if(!oppIdSet.isEmpty()){
            oppsMap = getOpportunityByIdMap(oppIdSet);
        }
        
        System.debug('>>>caseMap'+caseMap);
        System.debug('>>>oppsMap'+oppsMap);
        
        
        if(!caseIdSet.isEmpty() || !oppIdSet.isEmpty()){
            for(Attachment attachObj : attachmentList){
                String caseOrOppId = attMap.get(attachObj.Id);
                System.debug('>>>caseOrOppId'+caseOrOppId);
                
                if(caseOrOppId.startsWith('500') && (caseMap.get(caseOrOppId).NCSP_Opportunity__r.StageName == '6 - Setup' || caseMap.get(caseOrOppId).NCSP_Opportunity__r.StageName == '7 - Closed') && excludedProfileSet.contains(profileObj.Name)){
                    attachObj.addError('Cannot upload or delete a file');
                    System.debug('>>>caseOrOppId--->1'+caseOrOppId);
                }
                
                if(caseOrOppId.startsWith('006') && (oppsMap.get(caseOrOppId).StageName == '6 - Setup' || oppsMap.get(caseOrOppId).StageName == '7 - Closed') && excludedProfileSet.contains(profileObj.Name)){
                    attachObj.addError('Cannot upload or delete a file');
                    System.debug('>>>caseOrOppId--->2'+caseOrOppId);
                }
            } 
        }
    } 
    
    //Helper - To get Loggedin User Profile record
    private static Profile getLoginUserProfile(){        
        return [select id, Name from profile where id = :userinfo.getProfileId()];
    }
    
    //Helper - To get excluded Profile records from AttachmentAccessProfile__mdt
    private static Set<string> getExcludedUserProfiles(){
        Set<string> profileSet = new Set<string>();
        for(AttachmentAccessProfile__mdt objDoc : AttachmentAccessProfile__mdt.getall().values()){
            if(objDoc.isExcluded__c){
                profileSet.add(objDoc.Label);
            }
        }
        return profileSet;
    } 
    
    //Helper - To get Opportunity records
    private static Map<Id,Opportunity> getOpportunityByIdMap(Set<Id> oppIdSet){
        return new Map<Id, Opportunity>([Select id, StageName from Opportunity where Id IN : oppIdSet]);
    }
    
    //Helper - To get Case records
    private static Map<Id,Case> getCaseByIdMap(Set<Id> caseIdSet){
        return new Map<Id, Case>([Select Id, NCSP_Opportunity__c, NCSP_Opportunity__r.StageName FROM Case WHERE Id IN : caseIdSet]);
    }
    
    //Helper - To get Loggedin User Type to check whether user is automatedprocess
    private static boolean getLoginUserType()
    {
        if (UserInfo.getUserType() == 'automatedprocess'){
            return true;
        }
        else 
            return false;
    }
}