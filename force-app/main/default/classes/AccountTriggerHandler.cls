/**
* Class: AccountTriggerHandler
*
* Author: Revathy Saminathan
*
* Date Created: 11.06.2020
*
* Purpose: AccountTriggerHandler is a handler class for all business logic related to Account object
*
*/
public class AccountTriggerHandler implements ITriggerHandler {
   
    public static Boolean isTriggerDisabled = false;
    public static final String Account = 'Account';
    public static boolean throwExplicitException = false;
    public static final String DELIMITERS = '[;,]';
    public static boolean skipTriggerExecutionTestClass = false;
   // SObjectType triggerType = trigger.isDelete ? Trigger.old.getSObjectType() : Trigger.new.getSObjectType();
   // testInCountry1.InCountryReplicationTriggerHandler handler = new testInCountry1.InCountryReplicationTriggerHandler(triggerType.getDescribe().getName());
   
    //Method to disable trigger execution from custom settings - Metadata_Activation_Settings__c
    public Boolean IsDisabled(){
        Metadata_Activation_Settings__c custSetting = Metadata_Activation_Settings__c.getInstance();
        if(custSetting!=null && ( (String.isBlank(custSetting.SObject_API_Name__c) && custSetting.Disable_Trigger__c)
                                 || (String.isNotBlank(custSetting.SObject_API_Name__c) &&
                                     custSetting.SObject_API_Name__c.split(DELIMITERS).contains(QTB_Constants.SOBJECT_ACCOUNT)
                                     && custSetting.Disable_Trigger__c) ))
        {    
               return true;
        }else{
            return isTriggerDisabled;
        }
    }
    public void BeforeInsert(List<SObject> newItems)
    {
        if(!AccountTriggerHandler.skipTriggerExecutionTestClass){
            AccountHelper.processAccountBeforeInsert(newItems);
            QTB_AccountHelper.process(newItems,null,null,Trigger.operationtype);
        }
       /* System.debug('..........trigger type.....'+triggerType);
        if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType)) {
           System.debug('.......29Beforeinsert.....');
           handler.handleBeforeInsert();
          // AccountHelper.CalledfromHandlar=true;
           System.debug('....32afterhandlar.....');
           
           
        } */
       
    }
   
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {  
       /*  if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType))
         {
           System.debug('.......44BBeforeupdate.....');
           handler.handleBeforeInsert();
          // AccountHelper.CalledfromHandlar=true;
           //System.debug('....47afterhandlar.....');          
           
        } */
        if(!AccountTriggerHandler.skipTriggerExecutionTestClass){
            AccountHelper.processAccountBeforeUpdate(newItems.values(),(Map<Id, Account>)oldItems);
            QTB_AccountHelper.process(newItems.values(),(Map<Id,Account>) oldItems,null,trigger.operationtype);
        }
       
    }
   
    public void BeforeDelete(Map<Id, SObject> oldItems)
    {
        if(!AccountTriggerHandler.skipTriggerExecutionTestClass){
            AccountHelper.processAccountBeforeDelete(oldItems.values());
        }
    }
   
    public void AfterInsert(List<SObject> newItems)
    {
      /* System.debug('..........trigger type.....'+triggerType);
        if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType)) {
           System.debug('.......54Beforeinsert.....');
           handler.handleAfterInsert();
           AccountHelper.CalledfromHandlar=true;
           System.debug('....57afterhandlar.....');
           
           
        } */
       
        if(!AccountTriggerHandler.skipTriggerExecutionTestClass){
            QTB_AccountHelper.process(newItems,null,null,Trigger.operationtype);
        }
    }
   
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems)
    {
       /*  if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType))
         {
           System.debug('.......54Beforeinsert.....');
           handler.handleAfterInsert();
           //AccountHelper.CalledfromHandlar=true;
           //System.debug('....57afterhandlar.....');          
           
        } */
        if(!AccountTriggerHandler.skipTriggerExecutionTestClass){
            QTB_AccountHelper.process(newItems.values(),(Map<Id,Account>)oldItems,(Map<Id,Account>)newItems,Trigger.operationtype);
        }
       
    }
   
    public void AfterDelete(Map<Id, SObject> oldItems)
    {
   /* if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType))
         {
           System.debug('.......105Beforeinsert.....');
           handler.handleAfterDelete();
           //AccountHelper.CalledfromHandlar=true;
           //System.debug('....57afterhandlar.....');          
           
        } */
   
   
    }
   
    public void AfterUndelete(Map<Id, SObject> oldItems)
    {
   
    /*if (!testInCountry1.InCountryReplicationTriggerHandler.disableTrigger && !testInCountry1.InCountryReplicationTriggerHandler.alreadyExecuted(triggerType))
         {
           System.debug('.......120Beforeinsert.....');
          handler.handleAfterUndelete();
           //AccountHelper.CalledfromHandlar=true;
           //System.debug('....57afterhandlar.....');          
           
        } */
   
    }      
}