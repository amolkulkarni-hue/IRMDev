/**
* Class: OpportunityTriggerHandler 
*
* Author: Vinutha Iyengar
*
* Date Created: 04.05.2020
*
* Purpose: OpportunityTriggerHandler is a handler class for all business logic related to opportunity object
* 
*/
public class OpportunityTriggerHandler implements ITriggerHandler
{
    public static Boolean isTriggerDisabled = false;
    public static final String Opportunity = 'Opportunity';
    //to avoid the limit issues from the QTB test classes
    public static boolean skipTriggerExecutionTestClass = false;
    public static boolean throwExplicitException = false;
    public static final String DELIMITERS = '[;,]';
   // SObjectType triggerType = trigger.isDelete ? Trigger.old.getSObjectType() : Trigger.new.getSObjectType();
   // testInCountry1.InCountryReplicationTriggerHandler.registerExecution(triggerType);
   // testInCountry1.InCountryReplicationTriggerHandler handler = new testInCountry1.InCountryReplicationTriggerHandler(triggerType.getDescribe().getName());
    //Method to disable trigger execution from custom settings - Metadata_Activation_Settings__c
    public Boolean IsDisabled(){ 
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if(custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
                                 || (String.isNotBlank(custSetting.SObject_API_Name__c) && 
                                     custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.TYPE_OPPORTUNITY)
                                     && custSetting.Disable_Trigger__c) )){     
                                         return true;
                                     }
        else{ 
            return isTriggerDisabled;
        }
    }
    public void BeforeInsert(List<SObject> newItems)
    {
        if(!OpportunityTriggerHandler.skipTriggerExecutionTestClass){
            OpportunityHelper.OpportunityBeforeInsert(newItems);
        }
        // Touch Level calculation — deliberately outside the skip flag above, so it stays
        // active even when tests bypass unrelated legacy helper logic via that flag.
        TouchLevelEvaluatorAction.recalculateBeforeSave((List<Opportunity>) newItems, null);
        // Method to Auto populate Amend Opportunity fields on Amendment
        // OpportunityHelper.autoPopulateAmendOpp(newList);
        // OpportunityHelper.populateOriginalOpportunity(newList,null);
        QTB_OpportunityHelper.process(newItems, NULL, NULL, Trigger.operationType);
        
        /*   if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType)) {
         handler.handleBeforeInsert();
          System.debug('....46inserthandlar.....');
         } */
        
        
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {

     /*if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType)) {
         handler.handleBeforeInsert();
          System.debug('....66updatehandlar.....');

    }*/
        // Touch Level calculation — deliberately outside the skip flag and the
        // isBeforeUpdateTriggerExecuted recursion guard below, so it stays active on every
        // genuine BeforeUpdate invocation and even when tests bypass unrelated legacy helpers.
        TouchLevelEvaluatorAction.recalculateBeforeSave((List<Opportunity>) newItems.values(), (Map<Id, Opportunity>) oldItems);
        //Check to avoid multiple calls
        if(!OpportunityHelper.isBeforeUpdateTriggerExecuted){
            if(!OpportunityTriggerHandler.skipTriggerExecutionTestClass){
                OpportunityHelper.OpportunityBeforeUpdate(newItems.values(),(Map<Id, Opportunity>)oldItems,(Map<Id, Opportunity>)newItems);  
            }
            QTB_OpportunityHelper.process(newItems.values(), (Map<Id, Opportunity>)newItems, (Map<Id, Opportunity>)oldItems, Trigger.operationType);    
            if(!Test.isRunningTest()){
            OpportunityHelper.isBeforeUpdateTriggerExecuted = true;
            } 
       }
      /* if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType)) {
         handler.handleBeforeInsert();
          System.debug('....66updatehandlar.....');
        
    }*/
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems)
    {  
    }
    
    public void AfterInsert(List<SObject> newItems)
    {
        List<Opportunity> newOppList = newItems;
        if(!OpportunityTriggerHandler.skipTriggerExecutionTestClass){
            OpportunityHelper.OpportunityAfterInsert(newOppList);
        }
        // Case Creation eligibility — deliberately outside the skip flag above, so it stays
        // active even when tests bypass unrelated legacy helper logic via that flag.
        CaseCreationRuleEvaluatorAction.createEligibleChecklistsAfterSave(newOppList, null);

       /*  if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType)) {
        handler.handleAfterInsert();
            //testInCountry1.InCountryReplicationTriggerHandler.registerExecution(triggerType);
            
             System.debug('....85afterinserthandlar.....');
    } */
    
    }
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {
        // Case Creation eligibility — deliberately outside the skip flag and the
        // isAfterUpdateTriggerExecuted recursion guard below, so it stays active on every
        // genuine AfterUpdate invocation and even when tests bypass unrelated legacy helpers.
        CaseCreationRuleEvaluatorAction.createEligibleChecklistsAfterSave(
            (List<Opportunity>) newItems.values(), (Map<Id, Opportunity>) oldItems);
        //Check to avoid multiple calls
        if(!OpportunityHelper.isAfterUpdateTriggerExecuted){
            if(!OpportunityTriggerHandler.skipTriggerExecutionTestClass){
                OpportunityHelper.OpportunityAfterUpdate((Map<Id, Opportunity>)oldItems,newItems.values());    
            }
            
            QTB_OpportunityHelper.process(newItems.values(), (Map<Id, Opportunity>)newItems, (Map<Id, Opportunity>)oldItems, Trigger.operationType);        
            if(!Test.isRunningTest()){
            OpportunityHelper.isAfterUpdateTriggerExecuted = true;
            }
            
           /*   if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType)) {
        handler.handleAfterInsert();
            //testInCountry1.InCountryReplicationTriggerHandler.registerExecution(triggerType);
             System.debug('....106afterupdatehandlar.....');
    }*/
        } 
        
         /*  if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType)) {
        handler.handleAfterInsert();
            //testInCountry1.InCountryReplicationTriggerHandler.registerExecution(triggerType);
             System.debug('....106afterupdatehandlar.....');
    } */
             
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems)
    {
        if(!OpportunityTriggerHandler.skipTriggerExecutionTestClass){ 
            OpportunityHelper.deleteOpportunityRelatedContractAmount(oldItems.values());
        }
        
       /* if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType))
         {
           System.debug('.......105Beforeinsert.....');
           handler.handleAfterDelete();
          
        } */
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems) 
    {
    
   /* if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType))
         {
           System.debug('.......120Beforeinsert.....');
          handler.handleAfterUndelete();
                     
           
        } */
    }      
}