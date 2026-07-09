/*****************************************************************************************************
* Class:          QTB_UserTriggerHandler
* Author:         Accenture
* Purpose:        This is a handler class for all business logic related to User object
* Requirement:    JIRA# (QTB-41)
* Change History: 4/24/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture     5/29/2020      Updated to include the framework
*******************************************************************************************************/
public with sharing class QTB_UserTriggerHandler implements ITriggerHandler {
    private static final String CLASSNAME = QTB_UserTriggerHandler.class.getName();
    private Boolean isTriggerDisabled = false;
    private static QTB_UserTriggerHandler instance = NULL;
    // private static QTB_ExceptionLogger logger = new QTB_ExceptionLogger();
    public static Boolean throwExplicitException = false; // to be used for test class
    // lazy loading
    public static QTB_UserTriggerHandler getInstance() {
        instance = (instance == NULL) ? new QTB_UserTriggerHandler() : instance;
        return instance;
    }
 
    public Boolean IsDisabled() {
        Metadata_Activation_Settings__c someSetting = Metadata_Activation_Settings__c.getInstance();
        this.isTriggerDisabled = ((String.isEmpty(someSetting.SObject_API_Name__c) ||
                                   someSetting.SObject_API_Name__c.split(';').contains(QTB_Constants.SOBJECT_USER)) && 
                                  someSetting.Disable_Trigger__c);
        return this.isTriggerDisabled;
    }
    
    public void BeforeInsert(List<SObject> newItems) {}
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {} 
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterInsert(List<SObject> newItems) {} 
 
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, User> mapOfNewUserDetails = (Map<Id, User>) newItems;
        Map<Id, User> mapOfOldUserDetails = (Map<Id, User>) oldItems;
        QTB_UserHelper.process(mapOfNewUserDetails.values(), mapOfNewUserDetails, mapOfOldUserDetails, Trigger.OperationType);
    }
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}  
}