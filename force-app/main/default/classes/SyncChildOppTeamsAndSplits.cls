public class SyncChildOppTeamsAndSplits {

    @InvocableMethod(label='Sync Child Opp Teams & Splits' description='Updates open Opportunities when Account team fields change.')
    public static void syncTeamsAndSplitsFromAccount(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) return;

        Map<Id, Account> accountMap = new Map<Id, Account>(accounts);

        // Get Open Opportunities associated with these Accounts
        List<Opportunity> openOpps = [
            SELECT Id, AccountId, Amount, Cubic_Feet__c
            FROM Opportunity 
            WHERE AccountId IN :accountMap.keySet() AND IsClosed = false
        ];

        if (openOpps.isEmpty()) return;
        Set<Id> oppIds = new Map<Id, Opportunity>(openOpps).keySet();

        Id overlaySplitTypeId = [SELECT Id FROM OpportunitySplitType WHERE MasterLabel = 'Overlay' LIMIT 1].Id;

        // Aggregate ALL Business Units present on the Opportunities
        Map<Id, Set<String>> oppBUs = new Map<Id, Set<String>>();
        for (OpportunityLineItem oli : [
            SELECT OpportunityId, Product_Business_Unit__c 
            FROM OpportunityLineItem 
            WHERE OpportunityId IN :oppIds
        ]) {
            if (!oppBUs.containsKey(oli.OpportunityId)) {
                oppBUs.put(oli.OpportunityId, new Set<String>());
            }
            if (oli.Product_Business_Unit__c != null) {
                oppBUs.get(oli.OpportunityId).add(oli.Product_Business_Unit__c);
            }
        }

        // Gather existing System-Generated records
        Map<Id, Map<String, OpportunityTeamMember>> existingOtmMap = new Map<Id, Map<String, OpportunityTeamMember>>();
        for (OpportunityTeamMember otm : [SELECT Id, OpportunityId, CreatedByRole_c__c, UserId FROM OpportunityTeamMember WHERE OpportunityId IN :oppIds AND IsSystemGenerated__c = true]) {
            if (!existingOtmMap.containsKey(otm.OpportunityId)) {
                existingOtmMap.put(otm.OpportunityId, new Map<String, OpportunityTeamMember>());
            }
            existingOtmMap.get(otm.OpportunityId).put(otm.CreatedByRole_c__c, otm);
        }
        
        Map<Id, Map<String, OpportunitySplit>> existingSplitMap = new Map<Id, Map<String, OpportunitySplit>>();
        for (OpportunitySplit split : [SELECT Id, OpportunityId, CreatedByRole__c, SplitOwnerId FROM OpportunitySplit WHERE OpportunityId IN :oppIds AND IsSystemGenerated__c = true]) {
             if (!existingSplitMap.containsKey(split.OpportunityId)) {
                existingSplitMap.put(split.OpportunityId, new Map<String, OpportunitySplit>());
            }
            existingSplitMap.get(split.OpportunityId).put(split.CreatedByRole__c, split);
        }

        List<OpportunityTeamMember> otmsToInsert = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> otmsToDelete = new List<OpportunityTeamMember>();
        List<OpportunitySplit> splitsToInsert = new List<OpportunitySplit>();
        List<OpportunitySplit> splitsToDelete = new List<OpportunitySplit>();

        for (Opportunity opp : openOpps) {
            Account acc = accountMap.get(opp.AccountId);
            Map<String, OpportunityTeamMember> oppOtms = existingOtmMap.containsKey(opp.Id) ? existingOtmMap.get(opp.Id) : new Map<String, OpportunityTeamMember>();
            Map<String, OpportunitySplit> oppSplits = existingSplitMap.containsKey(opp.Id) ? existingSplitMap.get(opp.Id) : new Map<String, OpportunitySplit>();
            
            // Helper set to see what BUs this Opp has
            Set<String> bus = oppBUs.containsKey(opp.Id) ? oppBUs.get(opp.Id) : new Set<String>();

            // --- ORIGINAL ROLES ---
            
            // Solution Executive (SE) - Dynamic (isStatic = false)
            Boolean isVolumeMet = (opp.Cubic_Feet__c != null && opp.Cubic_Feet__c >= 5000);
            Boolean isAmountMet = (opp.Amount != null && opp.Amount >= 25000 && bus.contains('RIM'));
            Id requiredSE = (isVolumeMet || isAmountMet) ? acc.Solution_Executive__c : null;
            syncRole(opp.Id, requiredSE, 'Solution Executive', 'Solution Executive', 'Edit', true, false, overlaySplitTypeId, oppOtms.get('Solution Executive'), oppSplits.get('Solution Executive'), otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);

            // Global Managing Director (GMD) - STATIC (isStatic = true) 
            Id requiredGMD = (acc.Program_Designation__c == 'Global Account' && acc.Global_Account__c == true) ? acc.Global_IMGA_Owner__c : null;
            syncRole(opp.Id, requiredGMD, 'MD', 'GMD', 'Edit', true, true, overlaySplitTypeId, oppOtms.get('GMD'), oppSplits.get('GMD'), otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);

            // Client Partner (CP) - STATIC (isStatic = true)
            syncRole(opp.Id, acc.AMD__c, 'AMD', 'CP', 'Edit', true, true, overlaySplitTypeId, oppOtms.get('CP'), oppSplits.get('CP'), otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);

            // Enterprise ISR (EISR) - Dynamic (isStatic = false)
            syncRole(opp.Id, acc.Enterprise_ISR__c, 'Enterprise ISR', 'EISR', 'Edit', false, false, null, oppOtms.get('EISR'), null, otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);
            
            // Customer Success Manager (CSM) - Dynamic (isStatic = false)
            syncRole(opp.Id, acc.Tele_CDE__c, 'Customer Success Manager (CSM)', 'CSM', 'Read', false, false, null, oppOtms.get('CSM'), null, otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);
            
            // Global Account Representative (GAR) - Dynamic (isStatic = false)
            syncRole(opp.Id, acc.Global_Account_Director__c, 'GAR', 'GAR', 'Edit', false, false, null, oppOtms.get('GAR'), null, otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);

            // --- BU-BASED ROLES ---

            // // ALM SE/AE
            // Id requiredALM = (bus.contains('ALM')) ? acc.ALM_SE_AE__c : null;
            // syncRole(opp.Id, requiredALM, 'ALM SE/AE', 'ALM SE/AE', 'Edit', false, false, null, oppOtms.get('ALM SE/AE'), null, otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);

            // // RIM SE/AE
            // Id requiredRIM = (bus.contains('RIM')) ? acc.RIM_SE_AE__c : null;
            // syncRole(opp.Id, requiredRIM, 'RIM SE/AE', 'RIM SE/AE', 'Edit', false, false, null, oppOtms.get('RIM SE/AE'), null, otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);

            // // Digital SE/AE
            // Id requiredDigital = (bus.contains('Digital')) ? acc.Digital_SE_AE__c : null;
            // syncRole(opp.Id, requiredDigital, 'Digital SE/AE', 'Digital SE/AE', 'Edit', false, false, null, oppOtms.get('Digital SE/AE'), null, otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);

            // // MAS Owner
            // Id requiredMAS = (bus.contains('MAS')) ? acc.MAS_Owner__c : null;
            // syncRole(opp.Id, requiredMAS, 'MAS Owner', 'MAS Owner', 'Edit', false, false, null, oppOtms.get('MAS Owner'), null, otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);
        }

        // Execute DML (Deletions before insertions)
        if (!splitsToDelete.isEmpty()) delete splitsToDelete;
        if (!otmsToDelete.isEmpty()) delete otmsToDelete;
        if (!otmsToInsert.isEmpty()) insert otmsToInsert; 
        if (!splitsToInsert.isEmpty()) insert splitsToInsert;
    }

    private static void syncRole(Id oppId, Id requiredUserId, String teamRole, String createdByRole, String accessLevel, Boolean requiresSplit, Boolean isStatic, Id splitTypeId, 
                                 OpportunityTeamMember existingOtm, OpportunitySplit existingSplit, 
                                 List<OpportunityTeamMember> otmsToInsert, List<OpportunityTeamMember> otmsToDelete, 
                                 List<OpportunitySplit> splitsToInsert, List<OpportunitySplit> splitsToDelete) {
        
        // If static and already exists, ignore
        if (isStatic && existingOtm != null) return;

        // Delete old mismatching records
        if (existingOtm != null && existingOtm.UserId != requiredUserId) {
            otmsToDelete.add(existingOtm);
            if (existingSplit != null) splitsToDelete.add(existingSplit);
        }

        // Insert new records if required
        if (requiredUserId != null && (existingOtm == null || existingOtm.UserId != requiredUserId)) {
            otmsToInsert.add(new OpportunityTeamMember(
                OpportunityId = oppId, UserId = requiredUserId, TeamMemberRole = teamRole, 
                CreatedByRole_c__c = createdByRole, OpportunityAccessLevel = accessLevel, IsSystemGenerated__c = true
            ));
            
            if (requiresSplit) {
                splitsToInsert.add(new OpportunitySplit(
                    OpportunityId = oppId, SplitOwnerId = requiredUserId, SplitTypeId = splitTypeId, 
                    SplitPercentage = 100.0, IsSystemGenerated__c = true, CreatedByRole__c = createdByRole
                ));
            }
        }
    }
}