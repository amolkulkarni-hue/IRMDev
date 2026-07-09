/*
    @Trigger : OpportunityLineItemTrigger
    @Author : Gouthami Redlapalli
    @BuildDate :  05.05.2020
    @Description : OpportunityLineItem Trigger that will call the Methods of TriggerDispatcher class
    @Company : BahwanCyberTek
*/

trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
   TriggerDispatcher.Run(new OpportunityLineItemTriggerHandler());
  
     System.debug('OpportunityLineItem Trigger Executing');
 }