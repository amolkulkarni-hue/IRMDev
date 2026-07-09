/**
 * Trigger: UsageSuspenseTrigger 
 *
 * Author: Vinutha Iyengar
 *
 * Date Created: 25.08.2020
 *
 * Purpose: UsageSuspenseTrigger is an umbrella trigger QTB_Usage_Suspense__c object. All logic related to this trigger is in UsageSuspenseTriggerHandler
 * 
 */
Trigger UsageSuspenseTrigger on QTB_Usage_Suspense__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) 
{
    TriggerDispatcher.Run(new UsageSuspenseTriggerHandler()); 
}