/**
 * @description Invocable Apex Action (7/29 Updated Logic)
 * 1. Identifies single active OPL with highest EAA__c.
 * 2. Sets Is_Primary__c = true on winning record, false on all others.
 * 3. Stamps Opportunity.Business_Unit__c with winning record's BU.
 * 4. Recalculates Opportunity.Multi_BU_Flag__c (Count of Active OPLs > 1).
 */
public with sharing class PrimaryBURecalcAction {

    private static final Set<String> FROZEN_OPP_STAGES = new Set<String>{
        'Closed',
        'Lost',
        'Booked'
    };

    @InvocableMethod(
        label='Recalculate Primary BU and Multi-BU Flag'
        description='Recalculates Primary Business Unit, sets Is_Primary__c flags, and updates Multi-BU indicator on Opportunity.'
        category='Opportunity Product Line'
    )
    public static void recalculatePrimaryBU(List<Id> oppIds) {
        if (oppIds == null || oppIds.isEmpty()) {
            return;
        }

        Set<Id> uniqueOppIds = new Set<Id>(oppIds);
        uniqueOppIds.remove(null);

        if (!uniqueOppIds.isEmpty()) {
            executeRecalculation(uniqueOppIds);
        }
    }

    private static void executeRecalculation(Set<Id> oppIds) {
        // 1. Fetch eligible Opportunities excluding frozen stages
        Map<Id, Opportunity> oppsToProcess = new Map<Id, Opportunity>(
            [SELECT Id, StageName, Amount, Business_Unit__c, Multi_BU_Flag__c, Primary_Product_Line__c
             FROM Opportunity
             WHERE Id IN :oppIds
               AND StageName NOT IN :FROZEN_OPP_STAGES]
        );

        if (oppsToProcess.isEmpty()) {
            return;
        }

        // 1a. Count OLIs per Opportunity. Amount is only writable while zero OLIs exist;
        //     once OLIs are present, native Salesforce owns Amount (sum of OLI TotalPrice).
        Map<Id, Integer> oliCountByOpp = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT OpportunityId oppId, COUNT(Id) cnt
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppsToProcess.keySet()
            GROUP BY OpportunityId
        ]) {
            oliCountByOpp.put((Id) ar.get('oppId'), (Integer) ar.get('cnt'));
        }

        // 2. Query all Active OPL records ordered by EAA__c DESC and LastModifiedDate DESC (Tie-breaker)
        List<Opportunity_Product_Line__c> activeOPLs = [
            SELECT Id, Opportunity__c, Business_Unit__c, EAA__c, Is_Primary__c, LastModifiedDate,Product_Line__c, Is_Active__c
            FROM Opportunity_Product_Line__c
            WHERE Opportunity__c IN :oppsToProcess.keySet()
              AND Is_Active__c = true
            ORDER BY Opportunity__c, EAA__c DESC, LastModifiedDate DESC
        ];

        // 3. Group OPL records by Opportunity ID
        Map<Id, List<Opportunity_Product_Line__c>> oppToOPLMap = new Map<Id, List<Opportunity_Product_Line__c>>();
        for (Opportunity_Product_Line__c opl : activeOPLs) {
            if (!oppToOPLMap.containsKey(opl.Opportunity__c)) {
                oppToOPLMap.put(opl.Opportunity__c, new List<Opportunity_Product_Line__c>());
            }
            oppToOPLMap.get(opl.Opportunity__c).add(opl);
        }

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Opportunity_Product_Line__c> oplsToUpdate = new List<Opportunity_Product_Line__c>();

        // 4. Process each Opportunity
        for (Id oppId : oppsToProcess.keySet()) {
            Opportunity opp = oppsToProcess.get(oppId);
            List<Opportunity_Product_Line__c> oppOPLs = oppToOPLMap.get(oppId);

            Boolean hasNoOLIs = !oliCountByOpp.containsKey(oppId);

            // Handle scenario where all OPL records were deleted or deactivated
            if (oppOPLs == null || oppOPLs.isEmpty()) {
                Boolean oppChanged = false;
                if (opp.Business_Unit__c != null) {
                    opp.Business_Unit__c = null; oppChanged = true;
                }
                if (opp.Multi_BU_Flag__c != false) {
                    opp.Multi_BU_Flag__c = false; oppChanged = true;
                }
                // Only touch Amount while native OLI rollup is not in control.
                if (hasNoOLIs && opp.Amount != null) {
                    opp.Amount = null; oppChanged = true;
                }
                if (oppChanged) {
                    oppsToUpdate.add(opp);
                }
                continue;
            }

            // Step A: First record is winner (due to ORDER BY EAA__c DESC, LastModifiedDate DESC)
            Opportunity_Product_Line__c winningOPL = oppOPLs[0];
            String winningBU = winningOPL.Business_Unit__c;
            String winningProductLine = winningOPL.Product_Line__c;
            
            // Step B: Multi-BU flag is true if active child count > 1
            Boolean isMultiBU = (oppOPLs.size() > 1);

            // Step B2: Sum EAA across all active OPLs (roll up to Amount only when no OLIs exist)
            Decimal eaaTotal = 0;
            for (Opportunity_Product_Line__c opl : oppOPLs) {
                if (opl.EAA__c != null ) {
                    eaaTotal += opl.EAA__c;
                }
            }

            // Step C: Update parent Opportunity if fields changed
            Boolean oppChanged = false;
            if (opp.Business_Unit__c != winningBU || opp.Multi_BU_Flag__c != isMultiBU || opp.Primary_Product_Line__c != winningProductLine) {
                opp.Business_Unit__c = winningBU;
                opp.Multi_BU_Flag__c = isMultiBU;
                opp.Primary_Product_Line__c = winningProductLine;
                oppChanged = true;
            }
            // Amount is writable only while zero OLIs exist; once OLIs are added,
            // native Salesforce owns Amount (sum of OLI TotalPrice).
            if (hasNoOLIs && opp.Amount != eaaTotal) {
                opp.Amount = eaaTotal;
                oppChanged = true;
            }
            if (oppChanged) {
                oppsToUpdate.add(opp);
            }

            // Step D: Explicitly set Is_Primary__c = true on winner, and false on ALL other records
            for (Opportunity_Product_Line__c opl : oppOPLs) {
                Boolean shouldBePrimary = (opl.Id == winningOPL.Id);
                if (opl.Is_Primary__c != shouldBePrimary) { opl.Is_Primary__c = shouldBePrimary; oplsToUpdate.add(opl); System.debug('BU:' + opl.Business_Unit__c + ', Primary__c: ' + opl.Is_Primary__c); }
            }
        }
        system.debug(LoggingLevel.INFO, 'PrimaryBURecalcAction: oppsToUpdate size=' + oppsToUpdate.size() + ', oplsToUpdate size=' + oplsToUpdate.size());
        // 5. Secure DML Updates
        if (!oppsToUpdate.isEmpty()) {
            Database.update(oppsToUpdate, false);
        }

        if (!oplsToUpdate.isEmpty()) {
            List<Opportunity_Product_Line__c> cleanUpdateList = new List<Opportunity_Product_Line__c>();

            for (Opportunity_Product_Line__c existingOpl : oplsToUpdate) {
                // Instantiate a clean record using ONLY the Id and modified fields
                Opportunity_Product_Line__c cleanOpl = new Opportunity_Product_Line__c(
                    Id = existingOpl.Id,
                    Is_Primary__c = existingOpl.Is_Primary__c
                    // DO NOT include Opportunity__c here
                );
                cleanUpdateList.add(cleanOpl);
            }

            // Execute update in System Mode
            Database.SaveResult[] results = Database.update(cleanUpdateList, false, AccessLevel.SYSTEM_MODE);

            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    System.debug(LoggingLevel.ERROR,
                        'OPL update failed: ' + results[i].getErrors()[0].getMessage()
                    );
                }
            }
        }
    }
}