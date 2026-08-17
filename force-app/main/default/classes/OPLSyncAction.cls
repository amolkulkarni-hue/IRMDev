public with sharing class OPLSyncAction {

    @InvocableMethod(label='Sync Opportunity Product Lines' category='Opportunity')
    public static void syncOPLs(List<Id> oppIds) {
        if (oppIds == null || oppIds.isEmpty()) return;

        // 1. Stage Check Safeguard (Defense-in-depth)
        Set<String> lockedStages = new Set<String>{'Qualification', 'Closed', 'Lost', 'Booked'};
        Set<Id> validOppIds = new Map<Id, Opportunity>([
            SELECT Id FROM Opportunity 
            WHERE Id IN :oppIds AND StageName NOT IN :lockedStages
        ]).keySet();

        if (validOppIds.isEmpty()) return;

        // 2. Query existing OPL records to map existing IDs by sync key
        Map<String, Opportunity_Product_Line__c> existingOPLMap = new Map<String, Opportunity_Product_Line__c>();
        for (Opportunity_Product_Line__c opl : [
            SELECT Id, OPL_Sync_Key__c, Opportunity__c, Business_Unit__c, Is_Active__c, Is_Primary__c 
            FROM Opportunity_Product_Line__c 
            WHERE Opportunity__c IN :validOppIds
        ]) {
            existingOPLMap.put(opl.OPL_Sync_Key__c, opl);
        }

        // 3. Query all OLIs for valid Opportunities
        List<OpportunityLineItem> allOLIs = [
            SELECT Id, OpportunityId, Opportunity_Product_Line__c, Product_Business_Unit__c, TotalPrice 
            FROM OpportunityLineItem 
            WHERE OpportunityId IN :validOppIds 
              AND Product_Business_Unit__c != NULL
        ];

        // Grouping & Aggregation Maps
        Map<String, Decimal> eaaSumBySyncKey = new Map<String, Decimal>();
        Map<Id, Set<String>> activeBUsByOpp = new Map<Id, Set<String>>();
        Map<String, List<OpportunityLineItem>> olisBySyncKey = new Map<String, List<OpportunityLineItem>>();

        for (OpportunityLineItem oli : allOLIs) {
            String syncKey = oli.OpportunityId + '_' + oli.Product_Business_Unit__c;

            // Sum TotalPrice (EAA)
            Decimal currentEAA = eaaSumBySyncKey.containsKey(syncKey) ? eaaSumBySyncKey.get(syncKey) : 0;
            eaaSumBySyncKey.put(syncKey, currentEAA + (oli.TotalPrice != null ? oli.TotalPrice : 0));

            // Track active BUs per Opportunity
            if (!activeBUsByOpp.containsKey(oli.OpportunityId)) {
                activeBUsByOpp.put(oli.OpportunityId, new Set<String>());
            }
            activeBUsByOpp.get(oli.OpportunityId).add(oli.Product_Business_Unit__c);

            // Track OLIs mapped to sync key
            if (!olisBySyncKey.containsKey(syncKey)) {
                olisBySyncKey.put(syncKey, new List<OpportunityLineItem>());
            }
            olisBySyncKey.get(syncKey).add(oli);
        }

        // 4. Identify Primary BU (highest EAA) per Opportunity
        Map<Id, String> primarySyncKeyPerOpp = new Map<Id, String>();
        Map<Id, Decimal> maxEaaPerOpp = new Map<Id, Decimal>();

        for (String syncKey : eaaSumBySyncKey.keySet()) {
            List<String> keyParts = syncKey.split('_');
            Id oppId = (Id)keyParts[0];
            Decimal currentEAA = eaaSumBySyncKey.get(syncKey);

            if (!maxEaaPerOpp.containsKey(oppId) || currentEAA > maxEaaPerOpp.get(oppId)) {
                maxEaaPerOpp.put(oppId, currentEAA);
                primarySyncKeyPerOpp.put(oppId, syncKey);
            }
        }

        List<Opportunity_Product_Line__c> oplsToInsert = new List<Opportunity_Product_Line__c>();
        List<Opportunity_Product_Line__c> cleanUpdateList = new List<Opportunity_Product_Line__c>();

        // 5. Process Active BUs: Set Is_Primary__c dynamically
        for (String syncKey : eaaSumBySyncKey.keySet()) {
            List<String> keyParts = syncKey.split('_');
            Id oppId = (Id)keyParts[0];
            Decimal totalEAA = eaaSumBySyncKey.get(syncKey);
            Boolean isPrimary = (syncKey == primarySyncKeyPerOpp.get(oppId));

            if (existingOPLMap.containsKey(syncKey)) {
                // EXISTING RECORD: Instantiate clean update object
                Opportunity_Product_Line__c cleanOpl = new Opportunity_Product_Line__c(
                    Id = existingOPLMap.get(syncKey).Id,
                    EAA__c = totalEAA,
                    EAA_Source__c = 'CPQ Derived',
                    Is_Active__c = true,
                    Is_Primary__c = isPrimary
                );
                cleanUpdateList.add(cleanOpl);
            } else {
                // NEW RECORD: Include Master-Detail Opportunity__c
                Opportunity_Product_Line__c newOpl = new Opportunity_Product_Line__c(
                    OPL_Sync_Key__c = syncKey,
                    Opportunity__c = keyParts[0],
                    Business_Unit__c = keyParts[1],
                    EAA__c = totalEAA,
                    EAA_Source__c = 'CPQ Derived',
                    Is_Active__c = true,
                    Is_Primary__c = isPrimary
                );
                oplsToInsert.add(newOpl);
            }
        }

        // 6. Handle Deactivation for Removed BUs (Ensure Is_Primary__c = false)
        for (Opportunity_Product_Line__c existingOPL : existingOPLMap.values()) {
            Set<String> activeBUs = activeBUsByOpp.get(existingOPL.Opportunity__c);
            Boolean isStillActive = activeBUs != null && activeBUs.contains(existingOPL.Business_Unit__c);

            if (!isStillActive && existingOPL.Is_Active__c) {
                Opportunity_Product_Line__c cleanDeactivatedOpl = new Opportunity_Product_Line__c(
                    Id = existingOPL.Id,
                    Is_Active__c = false,
                    Is_Primary__c = false,
                    EAA__c = 0
                );
                cleanUpdateList.add(cleanDeactivatedOpl);
            }
        }

        // 7. Execute DML Operations in SYSTEM_MODE
        if (!oplsToInsert.isEmpty()) {
            Database.insert(oplsToInsert, false, AccessLevel.SYSTEM_MODE);
        }

        if (!cleanUpdateList.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(cleanUpdateList, false, AccessLevel.SYSTEM_MODE);
            for (Integer i = 0; i < updateResults.size(); i++) {
                if (!updateResults[i].isSuccess()) {
                    System.debug(LoggingLevel.ERROR, 'OPL update failed: ' + updateResults[i].getErrors()[0].getMessage());
                }
            }
        }

        // 8. Back-populate Lookup field on OLIs
        Map<String, Id> oplIdBySyncKey = new Map<String, Id>();

        for (Opportunity_Product_Line__c opl : oplsToInsert) {
            if (opl.Id != null) {
                oplIdBySyncKey.put(opl.OPL_Sync_Key__c, opl.Id);
            }
        }
        for (Opportunity_Product_Line__c opl : existingOPLMap.values()) {
            oplIdBySyncKey.put(opl.OPL_Sync_Key__c, opl.Id);
        }

        List<OpportunityLineItem> olisToUpdate = new List<OpportunityLineItem>();
        for (String syncKey : olisBySyncKey.keySet()) {
            Id oplId = oplIdBySyncKey.get(syncKey);
            if (oplId == null) continue;

            for (OpportunityLineItem oli : olisBySyncKey.get(syncKey)) {
                if (oli.Opportunity_Product_Line__c != oplId) {
                    oli.Opportunity_Product_Line__c = oplId;
                    olisToUpdate.add(oli);
                }
            }
        }

        if (!olisToUpdate.isEmpty()) {
            Database.update(olisToUpdate, false, AccessLevel.SYSTEM_MODE);
        }
    }
}