/*
 * InboundStorageTrigger
 * Handles updating opportunities to roll up their related inbound storages
 *
 * Ver No.     Resource                           Date         Changes
 * -----------------------------------------------------------------------------
 *   1.0       Charlie Xie(Bluewolf)        01/27/2014         Created
 *
 */ 
trigger InboundStorageTrigger on Inbound_Storage__c (after insert, after update, after delete) {
	if(Trigger.isAfter){
		if(Trigger.isInsert){
			InboundStorageTriggerHelper.rollupInboundstorages(null, Trigger.newMap);
		}
		if(Trigger.isUpdate){
			InboundStorageTriggerHelper.rollupInboundstorages(Trigger.oldMap, Trigger.newMap);
		}
		if(Trigger.isDelete){
			InboundStorageTriggerHelper.rollupInboundstorages(Trigger.oldMap,null);
		}
	}
}