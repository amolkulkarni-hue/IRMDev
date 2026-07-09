/*****************************************************************************************************
* Class: QTB_OpportunityTeamHandler
* Author: Accenture
* Purpose: This is a handler class for all business logic related to OpportunityTeam object
* Requirement:
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
*              29/5/2020
*******************************************************************************************************/
public with sharing class QTB_OpportunityTeamHandler implements ITriggerHandler{
    
    public static final String DELIMITERS = '[;,]';
    public static boolean throwExplicitException = false;
    /*****************************************************************************************************************
* Author:      Accenture
* Date:        28-05-2020
* Parameters:  None
* Return:      void
* Description: Method is used to disable trigger execution from custom setting- Metadata_Activation_Settings__c
*****************************************************************************************************************/
    public Boolean IsDisabled(){ 
        Boolean isTriggerDisabled = false;
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if(custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
                                 || (String.isNotBlank(custSetting.SObject_API_Name__c) 
                                     && custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.SOBJECT_OPPORTUNITYTEAM)
                                     && custSetting.Disable_Trigger__c) )){      
                                         isTriggerDisabled =true;
    	}
        return isTriggerDisabled;
    }
    
    /*******************************************************************************************************************
* Author:      Accenture
* Date:        29-05-2020
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for before insert event on the OpportunityTeam object.
********************************************************************************************************************/
    public void BeforeInsert(List<SObject> newItems){
        QTB_OpportunityTeamHelper.process(newItems,null,trigger.operationType);
    }
    
    /*******************************************************************************************************************
* Author:      Accenture
* Date:        29-05-2020
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for before update event on the OpportunityTeam object.
********************************************************************************************************************/ 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<id,OpportunityTeamMember> oldItemsMap = (Map<id,OpportunityTeamMember>)oldItems;
        Map<id,OpportunityTeamMember> newItemsMap = (Map<id,OpportunityTeamMember>)newItems;
        QTB_OpportunityTeamHelper.process((list<OpportunityTeamMember>)newItemsMap.values(),oldItemsMap,trigger.operationType);
    }
    
    /*******************************************************************************************************************
* Author:      Accenture
* Date:        29-05-2020
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for before delete event on the OpportunityTeam object.
********************************************************************************************************************/
    public void BeforeDelete(Map<Id, SObject> oldItems){
        Map<id,OpportunityTeamMember> oldItemsMap = (Map<id,OpportunityTeamMember>)oldItems;
        QTB_OpportunityTeamHelper.process(oldItemsMap.values(),oldItemsMap,trigger.operationType);
    }
    
    /*******************************************************************************************************************
* Author:      Accenture
* Date:        29-05-2020
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for after insert event on the OpportunityTeam object.
********************************************************************************************************************/
    public void AfterInsert(List<SObject> newItems) {
        //no action
    }
    
    /*******************************************************************************************************************
* Author:      Accenture
* Date:        29-05-2020
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for after update event on the OpportunityTeam object.
********************************************************************************************************************/
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        //no action
    }
    
    /*******************************************************************************************************************
* Author:      Accenture
* Date:        29-05-2020
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for after delete event on the OpportunityTeam object.
********************************************************************************************************************/
    public void AfterDelete(Map<Id, SObject> oldItems){
        Map<id,OpportunityTeamMember> oldItemsMap = (Map<id,OpportunityTeamMember>)oldItems;
        QTB_OpportunityTeamHelper.process(oldItemsMap.values(),oldItemsMap,trigger.operationType);
    }
    
    /*******************************************************************************************************************
* Author:      Accenture
* Date:        29-05-2020
* Parameters:  None
* Return:      void
* Description: This method is used to handle business logic for after undelete event on the OpportunityTeam object.
********************************************************************************************************************/
    public void AfterUndelete(Map<Id, SObject> oldItems){
        //no action
    }      
}