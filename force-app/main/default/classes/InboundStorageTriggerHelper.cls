/**
 * Helper class for InboundStorageTrigger 
 * Handles updating opportunities to roll up their related inbound storages
 *
 * Ver No.     Resource                           Date         Changes
 * -----------------------------------------------------------------------------
 *   1.0         Charlie Xie(Bluewolf)      01/27/2014         Created
 *
 */ 
public with sharing class InboundStorageTriggerHelper {
	public static void rollupInboundstorages(Map<ID,Inbound_Storage__c> oldMap, Map<ID,Inbound_Storage__c> newMap){
		Set<ID> opportunityIdSet = new Set<ID>();
		if(oldMap!=null && newMap!=null){//isUpdate
			for(Id inbsId : newMap.keySet()){
				Id opportunityIdfromOldMap = oldMap.get(inbsId).Opportunity__c;
				Id opportunityIdfromNewMap = newMap.get(inbsId).Opportunity__c;
				if(opportunityIdfromOldMap == null && opportunityIdfromNewMap == null) continue;
				//lookup field to opportunity got changed
				if(opportunityIdfromOldMap != opportunityIdfromNewMap){
					if(opportunityIdfromOldMap == null && opportunityIdfromNewMap != null){
						opportunityIdSet.add(opportunityIdfromNewMap); 
					}else if(opportunityIdfromOldMap != null && opportunityIdfromNewMap == null){
						opportunityIdSet.add(opportunityIdfromOldMap); 
					}else{//opportunityIdfromNewMap != null && opportunityIdfromNewMap != null
						opportunityIdSet.add(opportunityIdfromOldMap);
						opportunityIdSet.add(opportunityIdfromNewMap); 
					}
				}else{//opportunityIdfromOldMap == opportunityIdfromNewMap and both of them != null
					Inbound_Storage__c oldInbS =  oldMap.get(inbsId);
					Inbound_Storage__c newInbS =  newMap.get(inbsId);
					Double oldTotalVolume = oldInbS.Total_Volume__c;
					Double newTotalVolume = newInbS.Total_Volume__c;
					Double oldTotalRevenue = oldInbS.Total_Revenue__c;
					Double newTotalRevenue = newInbS.Total_Revenue__c;
					String oldStatus = oldInbS.Association_to_Opportunity_Status__c;
					String newStatus = newInbS.Association_to_Opportunity_Status__c;

					if(oldTotalVolume!=newTotalVolume 
						|| oldTotalRevenue!=newTotalRevenue
						|| oldStatus!=newStatus){
						opportunityIdSet.add(opportunityIdfromNewMap); 
					}
				}
			}
		}
		else if(oldMap == null && newMap != null){//isInsert
			for(Inbound_Storage__c inbstorage : newMap.values()){
				if(inbstorage.Opportunity__c!=null && inbstorage.Association_to_Opportunity_Status__c == 'Matched - Approved'){
				   opportunityIdSet.add(inbstorage.Opportunity__c);
				}
			}
		}
		else if(oldMap != null && newMap == null){//isDelete
			for(Inbound_Storage__c inbstorage : oldMap.values()){
				if(inbstorage.Opportunity__c!=null && inbstorage.Association_to_Opportunity_Status__c == 'Matched - Approved'){
				   opportunityIdSet.add(inbstorage.Opportunity__c);
				}
			}
		}
		else{
			//oldMap == null && newMap == null
		}

		if(opportunityIdSet.size()>0){
			updateOpportunities(opportunityIdSet);
		}
	}

	public static void updateOpportunities(Set<ID> opportunityIdSet){
		List<Opportunity> opportunitiesToUpdate;
		Map<Id, List<Inbound_Storage__c>> oppoIdToInboundStorages = new Map<Id, List<Inbound_Storage__c>>();
		if(opportunityIdSet.size()>0){
			//loop all related inboundStorages to build the opportunity to inboundStorage Map 
			for(Inbound_Storage__c inbstorage : [SELECT Id, Opportunity__c, Total_Volume__c,Association_to_Opportunity_Status__c, Total_Revenue__c 
												 FROM Inbound_Storage__c 
												 WHERE Opportunity__c IN : opportunityIdSet AND Association_to_Opportunity_Status__c = 'Matched - Approved']){
				if(oppoIdToInboundStorages.containsKey(inbstorage.Opportunity__c)){
					oppoIdToInboundStorages.get(inbstorage.Opportunity__c).add(inbstorage);
				}else{
					List<Inbound_Storage__c> inbsLst = new List<Inbound_Storage__c>();	
					inbsLst.add(inbstorage);
					oppoIdToInboundStorages.put(inbstorage.Opportunity__c,inbsLst);
				}
			}
			//Opportunity sObjects
			opportunitiesToUpdate = [SELECT Id, Total_Inbound_Storage_Received__c,Total_Storage_Revenue_Received__c FROM Opportunity WHERE Id IN : opportunityIdSet];
			for(Opportunity op : opportunitiesToUpdate){
				Double totalInboundStorageReceived = 0.0;
				Double totalRevenueReveived = 0.0;
				//Those Opportunities with 0 inboundstorage wasn't put into the map.
				if(oppoIdToInboundStorages.containsKey(op.Id)){
					for(Inbound_Storage__c inbstorage : oppoIdToInboundStorages.get(op.Id)){
						totalInboundStorageReceived += inbstorage.Total_Volume__c;
						totalRevenueReveived += inbstorage.Total_Revenue__c;
					}
				}
				op.Total_Inbound_Storage_Received__c = totalInboundStorageReceived;
				op.Total_Storage_Revenue_Received__c = totalRevenueReveived;
			}
			update opportunitiesToUpdate;
		}
	}
}