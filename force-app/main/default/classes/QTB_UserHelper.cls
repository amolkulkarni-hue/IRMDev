/*****************************************************************************************************
* Class: QTB_UserHelper
* Author: Accenture
* Purpose: This is a helper class for all business logic related to User object
* Change History: 4/24/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture     5/29/2020      Updated to include the framework
*******************************************************************************************************/
public with sharing class QTB_UserHelper {
    private static final String CLASSNAME = QTB_UserHelper.class.getName();
    // private static final QTB_ExceptionLogger logger = new QTB_ExceptionLogger();
    /***********************************************************************************************************
* Method :      process
* Parameters:   List<User>,Map<Id, User>,System.TriggerOperation
* Return Type : void
* Description:  This method loops over the list of records to be processed 
**************************************************************************************************************/      
    public static void process(List<User> listOfNewUsers, Map<Id, User> mapOfNewUserDetails, 
                               Map<Id, User> mapOfOldUserDetails, System.TriggerOperation operationType) 
    {        
        /* Storage */
        /* updateApproverOnRelatedCreditNotes */        
        // set of new director or manager or supervisor user ids 
        Set<String> setOfUserIds;
        // set of user ids on which supervisor or manager or director is changed
        Set<Id> setOfCreatedByIds;
        /*************************************/
        try {
            if (QTB_UserTriggerHandler.throwExplicitException) { throw new NoAccessException(); }
            /* Process */
            for (User eachUser : (listOfNewUsers <> NULL) ? listOfNewUsers : mapOfOldUserDetails.values()) 
            {
                switch on operationType 
                {
                    when BEFORE_INSERT {}
                    when AFTER_INSERT {}
                    when BEFORE_UPDATE {}
                    when AFTER_UPDATE {
                        if (setOfUserIds == NULL) { setOfUserIds = new Set<String>(); }
                        if (setOfCreatedByIds == NULL) { setOfCreatedByIds = new Set<Id>(); }
                        if (String.isNotBlank(eachUser.QTB_Supervisor__c) && 
                            eachUser.QTB_Supervisor__c <> mapOfOldUserDetails.get(eachUser.Id).QTB_Supervisor__c) 
                        {
                            setOfUserIds.add(eachUser.QTB_Supervisor__c);
                            setOfCreatedByIds.add(eachUser.Id);
                        }
                        if (String.isNotBlank(eachUser.ManagerId) && 
                            eachUser.ManagerId <> mapOfOldUserDetails.get(eachUser.Id).ManagerId) 
                        {
                            setOfUserIds.add(eachUser.ManagerId);
                            setOfCreatedByIds.add(eachUser.Id);
                        }
                        if (String.isNotBlank(eachUser.IM_RSM__c) && eachUser.IM_RSM__c <> mapOfOldUserDetails.get(eachUser.Id).IM_RSM__c) 
                        {
                            setOfUserIds.add(eachUser.IM_RSM__c);
                            setOfCreatedByIds.add(eachUser.Id);
                        }
                    }
                    when BEFORE_DELETE {}
                    when AFTER_DELETE {}
                    when AFTER_UNDELETE {}
                    when else {}
                }
            }
            /* post processing */
            // update the approvers on credit note according to the change on user
            if (setOfUserIds <> NULL && !setOfUserIds.isEmpty()) { 
                updateApproverOnRelatedCreditNotes(setOfUserIds, setOfCreatedByIds, mapOfNewUserDetails); 
            }
        } catch(Exception e) {
            QTB_ExceptionLogger.createLog(e.getLineNumber(), e.getStackTraceString(), e.getMessage(), e.getTypeName(), CLASSNAME);
            // logger.log(e, CLASSNAME);
            throw e;
        }
    }
    /***********************************************************************************************************
* Method :      updateApproverOnRelatedCreditNotes
* Parameters:   Map<Id, User>, Map<Id, User>
* Return Type : void
* Requirement : SFCPQBLG-64 (QTB-41)
* Start Date :  4/24/2020
* Description:  This method updates Approvers on the Credit Notes created by the Users, whose supervisor or manager or director chaged
**************************************************************************************************************/
    private static void updateApproverOnRelatedCreditNotes(Set<String> setOfUserIds, Set<Id> setOfCreatedByIds, Map<Id, User> mapOfNewUserDetails) 
    {
        // Get matching approvers for the new users
        Map<String, Id> mapOfUserApproverId = QTB_CreditNoteHelper.getApproverIds(setOfUserIds);
        List<blng__CreditNote__c> listOfCreditNote = new List<blng__CreditNote__c>();
        // to handle too many records using efficient chunking
        for (List<blng__CreditNote__c> creditNotes : [SELECT Id, blng__Status__c,QTB_Supervisor_Approver__c, 
                                                      QTB_Manager_Approver__c, QTB_Director_Approver__c,CreatedById 
                                                      FROM blng__CreditNote__c 
                                                      WHERE CreatedById IN :setOfCreatedByIds AND blng__Status__c <> :QTB_Constants.CREDITNOTE_STATUS_POSTED])
        {
            listOfCreditNote.addAll(creditNotes);
        }
        // update the approvers as per the new user set up on the created by user's director or manager or supervisor field
        for (blng__CreditNote__c eachCreditNote : listOfCreditNote) 
        {
            User createdBy = mapOfNewUserDetails.get(eachCreditNote.CreatedById);
            eachCreditNote.QTB_Supervisor_Approver__c = mapOfUserApproverId.containsKey(createdBy.QTB_Supervisor__c) ? 
                mapOfUserApproverId.get(createdBy.QTB_Supervisor__c) : eachCreditNote.QTB_Supervisor_Approver__c;
            eachCreditNote.QTB_Manager_Approver__c = mapOfUserApproverId.containsKey(createdBy.ManagerId) ? 
                mapOfUserApproverId.get(createdBy.ManagerId) : eachCreditNote.QTB_Manager_Approver__c;
            eachCreditNote.QTB_Director_Approver__c = mapOfUserApproverId.containsKey(createdBy.IM_RSM__c) ? 
                mapOfUserApproverId.get(createdBy.IM_RSM__c) : eachCreditNote.QTB_Director_Approver__c;
        }
        Database.SaveResult[] results = Database.update(listOfCreditNote);
    }
}