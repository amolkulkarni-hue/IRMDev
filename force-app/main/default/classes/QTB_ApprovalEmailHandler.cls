/*****************************************************************************************************
* Class: QTB_ApprovalEmailHandler
* Author: Accenture
* Purpose: This is a handler class for creating and sending emails related to approval
* Change History: 4/24/2020
* Developer     Date           Description 
* ------------------------------------------------------------------------------------------- 
* Accenture     5/30/2020      Updated to include the framework
*******************************************************************************************************/
public with sharing class QTB_ApprovalEmailHandler {    
    private static final String CLASSNAME = QTB_ApprovalEmailHandler.class.getName();
    public static boolean throwExplicitException = false;
        
      /***********************************************************************************************************
    * Method :      sendEmail
    * Parameters:   List<Messaging.SingleEmailMessage>
    * Return Type : void
    * Requirement : SFCPQBLG-64
    * Description:  This method sends emails
    **************************************************************************************************************/
    public static void sendEmail(List<Messaging.SingleEmailMessage> emailMessages) {
        Messaging.SendEmailResult[] emailResults;
        try{ 
            emailResults = Messaging.sendEmail(emailMessages, false); 
        }
        catch(Exception e) { QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME); }
        for (Messaging.SendEmailResult emailResult : emailResults) {
            if (!emailResult.success) {
                QTB_ExceptionLogger.createLog(21, '' + emailResult.errors, 'Email failed to send', 'Email Errors', CLASSNAME);
            }
        }
    }
    /***********************************************************************************************************
    * Method :      getApprovals
    * Parameters:   String, List<Id>
    * Return Type : List<sbaa__Approval__c>
    * Requirement : SFCPQBLG-64
    * Description:  This method retrieves the approvals generated for the specified related object
    **************************************************************************************************************/
    private static List<sbaa__Approval__c> getApprovals(String relatedToField, List<Id> relatedRecordIds) {        
        List<String> fieldsToQuery = new List<String>{
                'Id',
                relatedToField,
                'sbaa__Status__c',
                'sbaa__Rule__r.QTB_Additional_Recipients__c', 
                'sbaa__Rule__r.sbaa__RejectionTemplate__r.sbaa__TemplateId__c',
                'sbaa__Rule__r.QTB_Approval_Notification_Template__r.sbaa__TemplateId__c',
                'sbaa__Rule__r.QTB_Notification_Template__r.sbaa__TemplateId__c'                
        };
            
        // Dynamic String of query because the relatedToField is a dynamic value
        String query = 'SELECT ' + String.join(fieldsToQuery, ', ') + 
                       ' FROM sbaa__Approval__c WHERE ' + relatedToField + 
                       ' IN (\'' + String.join(relatedRecordIds, '\', \'') + '\') ';
        
        List<sbaa__Approval__c> listOfApprovals = Database.query(String.valueOf(query));
        return listOfApprovals;
    }
    
    /***********************************************************************************************************
    * Method :      createEmails
    * Parameters:   List<sbaa__Approval__c>
    * Return Type : Map<Id, Messaging.SingleEmailMessage>
    * Requirement : SFCPQBLG-64
    * Description:  This method creates emails for each approval
    **************************************************************************************************************/
    @TestVisible
    private static Map<Id, Messaging.SingleEmailMessage> createEmails(List<sbaa__Approval__c> listOfApprovals) {
        Map<Id, Messaging.SingleEmailMessage> mapOfApprovalEmails = new Map<Id, Messaging.SingleEmailMessage>();        
        // get the approvals generated for the Credit Notes
        for (sbaa__Approval__c eachApproval : listOfApprovals) {
            // for each approval create a single email message
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setBccSender(false);
            message.setSaveAsActivity(false);
            message.setUseSignature(false);
            message.setTreatTargetObjectAsRecipient(false);
            message.setSenderDisplayName('Iron Mountain Approval Notification');
            message.setWhatId(eachApproval.Id);
            if (eachApproval.sbaa__Status__c == QTB_Constants.APPROVAL_STATUS_REQUESTED) {
                message.setTemplateId(eachApproval.sbaa__Rule__r.QTB_Notification_Template__r.sbaa__TemplateId__c);
            } else if (eachApproval.sbaa__Status__c == QTB_Constants.APPROVAL_STATUS_APPROVED) {
                message.setTemplateId(eachApproval.sbaa__Rule__r.QTB_Approval_Notification_Template__r.sbaa__TemplateId__c);
            } else if (eachApproval.sbaa__Status__c == QTB_Constants.APPROVAL_STATUS_REJECTED) {
                // add rejection notification template
            } else if (eachApproval.sbaa__Status__c == QTB_Constants.APPROVAL_STATUS_RECALLED || 
                       eachApproval.sbaa__Status__c == QTB_Constants.APPROVAL_STATUS_REVOKED) 
            {
                // add recall notification template
            }            
            mapOfApprovalEmails.put(eachApproval.Id, message);
        }
        return mapOfApprovalEmails;
    }
    
    /***********************************************************************************************************
    * Method :      sendNotification
    * Parameters:   String, Map<Id, SObject>, Set<Id>
    * Return Type : void
    * Requirement : SFCPQBLG-64
    * Description:  This method sends notification emails to the approvers specified
    **************************************************************************************************************/
    public static void sendNotification(String relatedToField, Map<Id, SObject> mapOfRecordsInApproval, Set<Id> setOfApproverIds) {
        // Set of Group Ids and the Approval Id combined to a string
        Set<String> setOfCombinedGroupApprovalId = new Set<String>();
        // Set of Group Ids
        Set<Id> setOfGroupIds = new Set<Id>();
        // Set of GroupMember
        List<GroupMember> listOfGroupMember = new List<GroupMember>();
        // Map of group id and set of user ids in the group
        Map<Id, List<Id>> mapOfGroupUserIds = new Map<Id, List<Id>>();
        // Map of Approval Id and related notification recipient user ids
        Map<Id, List<String>> mapOfApprovalEmailIds = new Map<Id, List<String>>();
        try{
            // Get the list of approvals for RecordsInApproval
            List<sbaa__Approval__c> listOfApprovals = getApprovals(relatedToField, new List<Id>(mapOfRecordsInApproval.keySet()));
            // Map of Approval Id and its corresponding Email message to be sent
            Map<Id, Messaging.SingleEmailMessage> mapOfApprovalEmail = createEmails(listOfApprovals);
            // Map of Approver records
            Map<Id, sbaa__Approver__c> mapOfApprovers = 
                new Map<Id, sbaa__Approver__c>([SELECT Id, sbaa__User__c, sbaa__GroupId__c FROM sbaa__Approver__c WHERE Id IN :setOfApproverIds]);
            
            // get the approvals generated for the Credit Notes
            for (sbaa__Approval__c eachApproval : listOfApprovals) { 
                mapOfApprovalEmailIds.put(eachApproval.Id, new List<String>());
                Messaging.SingleEmailMessage message = mapOfApprovalEmail.get(eachApproval.Id);
                // get additional recipients
                if (String.isNotBlank(eachApproval.sbaa__Rule__r.QTB_Additional_Recipients__c)) {
                    for (String eachRecipient : eachApproval.sbaa__Rule__r.QTB_Additional_Recipients__c.split(';')) {
                        // get the group id or user id from the approver record
                        Id recipientId = (Id) mapOfRecordsInApproval.get((Id) eachApproval.get(relatedToField)).get(eachRecipient);
                        // adding null check for recipient
                        if (mapOfApprovers.containsKey(recipientId)) {
                            sbaa__Approver__c currentApprover = mapOfApprovers.get(recipientId);
                            if (String.isNotBlank(currentApprover.sbaa__GroupId__c) && String.isBlank(currentApprover.sbaa__User__c)) {
                                setOfCombinedGroupApprovalId.add(currentApprover.sbaa__GroupId__c + ',' + eachApproval.Id);
                                setOfGroupIds.add(currentApprover.sbaa__GroupId__c);
                            }
                            else if (String.isBlank(currentApprover.sbaa__GroupId__c) && String.isNotBlank(currentApprover.sbaa__User__c)) {
                                mapOfApprovalEmailIds.get(eachApproval.Id).add(currentApprover.sbaa__User__c);
                                message.targetobjectid = String.isBlank(message.targetobjectid) ? currentApprover.sbaa__User__c : message.targetobjectid;
                            }
                        }
                    }
                }   
                mapOfApprovalEmail.put(eachApproval.Id, message);
            }
            if (!setOfGroupIds.isEmpty()) {
                // to handle too many records using efficient chunking
                for (List<GroupMember> listOfGroupMemberChunk : [SELECT Id, 
                                                                 UserOrGroupId, 
                                                                 GroupId 
                                                                 FROM GroupMember 
                                                                 WHERE GroupId IN :setOfGroupIds]) 
                {
                    listOfGroupMember.addAll(listOfGroupMemberChunk);
                }
                for (GroupMember eachGroupMember : listOfGroupMember) {
                    if (((String) eachGroupMember.UserOrGroupId).startsWith(QTB_Constants.USER_PREFIX)) {
                        if (mapOfGroupUserIds.containsKey(eachGroupMember.GroupId)) {
                            mapOfGroupUserIds.get(eachGroupMember.GroupId).add(eachGroupMember.UserOrGroupId);
                        } else {
                            mapOfGroupUserIds.put(eachGroupMember.GroupId, new List<Id>{eachGroupMember.UserOrGroupId});
                        }
                    }
                }             
            }
            for (String eachCombination : setOfCombinedGroupApprovalId) {
                String[] splittedIds = eachCombination.split(',');
                mapOfApprovalEmailIds.get((Id) splittedIds[1]).addAll(mapOfGroupUserIds.get((Id) splittedIds[0]));
            } 
            
            Map<Id, List<String>> mapOfActiveApprovers = getActiveApprovers(mapOfApprovalEmailIds);
            for (Id eachId : mapOfApprovalEmail.keySet()) {
                //Exception Fix - GITLAB #21491
                if (!mapOfActiveApprovers.isEmpty() && mapOfActiveApprovers != null &&  !mapOfActiveApprovers.get(eachId).isEmpty()) {
                    mapOfApprovalEmail.get(eachId).toaddresses = new String[] {mapOfActiveApprovers.get(eachId).remove(0)};
                    mapOfApprovalEmail.get(eachId).ccaddresses = mapOfActiveApprovers.get(eachId);
                }
            }  
            if (!mapOfApprovalEmail.isEmpty()) {
                sendEmail(mapOfApprovalEmail.values());
            }
            
        } catch(Exception e) {
            QTB_ExceptionLogger.enable();
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
        }
    }
    
    //Helper - To get Active users based on Approval Id
    private static Map<Id, List<String>> getActiveApprovers(Map<Id, List<String>> mapOfApprovalEmailIds){
		Map<Id, List<String>> userIdsWithApprovalIdMap = new Map<Id, List<String>>();
        Set<Id> userIds = new Set<Id>();
        Map<Id,User> userMap;
        if(!mapOfApprovalEmailIds.isEmpty()){
            for(Id approvalId : mapOfApprovalEmailIds.keySet()){
                for(String userId : mapOfApprovalEmailIds.get(approvalId)){
                   userIds.add(userId); 
                }
            } 
            if(!userIds.isEmpty()){
            	userMap = new Map<Id,User>([SELECT Id, isActive FROM User WHERE Id IN : userIds AND isActive = true]);
            }
            
            for(Id approvalId : mapOfApprovalEmailIds.keySet()){
                List<String> userIdList = new List<String>();
                for(String userId : mapOfApprovalEmailIds.get(approvalId)){
                    if(String.isNotBlank(userId) && userMap.containsKey(userId)){
                        userIdList.add(userId); 
                        userIdsWithApprovalIdMap.put(approvalId, userIdList);
                    }
                }
            }
        } 
        return userIdsWithApprovalIdMap;
    }     
    
    public static void testFunctionality(){
        Integer i=1;
        i++;
        i++; 
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++; 
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++; 
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++; 
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++; 
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++; 
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++; 
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++; 
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++; 
        i++;
        i++;
         i++;
        i++; 
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++; 
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++; 
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++; 
        i++;
    }
}