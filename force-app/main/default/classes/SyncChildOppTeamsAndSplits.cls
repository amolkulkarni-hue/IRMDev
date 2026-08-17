public without sharing class SyncChildOppTeamsAndSplits {

    public class SyncException extends Exception {}

    // ==========================================
    // CONSTANTS
    // ==========================================
    
    // Role Names
    private static final String ROLE_SOLUTION_EXECUTIVE = 'Solution Executive';
    private static final String ROLE_GMD = 'Global - Managing Director';
    private static final String ROLE_CLIENT_PARTNER = 'Client Partner';
    private static final String ROLE_ENTERPRISE_ISR = 'Enterprise ISR';
    private static final String ROLE_CSM = 'Customer Success Manager (CSM)';
    private static final String ROLE_GAD = 'Global - Account Director';
    private static final String ROLE_ALM_SDE = 'ALM SDE(Solution Development Executive)';
    private static final String ROLE_RIM_SDE = 'RIM SDE';
    private static final String ROLE_DBU_SDE = 'DBU SDE';

    // Business Units
    private static final String BU_RIM = 'RIM';
    private static final String BU_ALM = 'ALM';
    private static final String BU_DIGITAL = 'Digital';

    // Access Levels
    private static final String ACCESS_EDIT = 'Edit';
    private static final String ACCESS_READ = 'Read';

    // System Settings & Thresholds
    private static final String SPLIT_TYPE_OVERLAY = 'Overlay';
    private static final Decimal SPLIT_PERCENTAGE_FULL = 100.0;
    private static final Decimal MIN_VOLUME_CUBIC_FEET = 5000;
    private static final Decimal MIN_AMOUNT_RIM = 25000;

    // ==========================================
    // INVOCABLE VARIABLES
    // ==========================================
    public class SyncRequest {
        @InvocableVariable(label='Account Record' description='Pass {!$Record} if triggering from Account Flow')
        public Account accountRecord;
        
        @InvocableVariable(label='Opportunity ID' description='Pass {!$Record.Id} if triggering from Opportunity Flow')
        public Id oppId;

        @InvocableVariable(label='Deleted Opp Product ID' description='Pass {!$Record.Id} ONLY from a Before Delete Opportunity Product Flow')
        public Id deletedOliId;
    }

    // ==========================================
    // MAIN LOGIC
    // ==========================================
    @InvocableMethod(label='Sync Child Opp Teams & Splits' description='Pass Account Record OR Opportunity ID to sync Teams/Splits.')
    public static void syncTeamsAndSplits(List<SyncRequest> requests) {
        if (requests == null || requests.isEmpty()) return;

        Map<Id, Account> accountDataMap = new Map<Id, Account>();
        Set<Id> oppInputIds = new Set<Id>();
        Set<Id> deletedOliIds = new Set<Id>();

        for (SyncRequest req : requests) {
            if (req.accountRecord != null) {
                accountDataMap.put(req.accountRecord.Id, req.accountRecord);
            }
            if (req.oppId != null) {
                oppInputIds.add(req.oppId);
            }
            if (req.deletedOliId != null) {
                deletedOliIds.add(req.deletedOliId);
            }
        }

        try {
            System.debug('--- Executing Query 1: Opportunities ---');
            List<Opportunity> openOpps = new List<Opportunity>();
            
            if (!accountDataMap.isEmpty()) {
                Set<Id> accIds = accountDataMap.keySet();
                openOpps = [
                    SELECT Id, AccountId, Amount, Cubic_Feet__c,
                           Account.Solution_Executive__c, Account.Program_Designation__c, Account.Global_Account__c, 
                           Account.Global_IMGA_Owner__c, Account.AMD__c, Account.Enterprise_ISR__c, 
                           Account.Tele_CDE__c, Account.Global_Account_Director__c,
                           Account.DMS_Owner__c, Account.RIM_SDE__c, Account.Information_Governance_Rep__c, Account.Primary_Local_Market_Rep_1__c
                    FROM Opportunity 
                    WHERE AccountId IN :accIds AND IsClosed = false
                ];
            } 
            else if (!oppInputIds.isEmpty()) {
                openOpps = [
                    SELECT Id, AccountId, Amount, Cubic_Feet__c,
                           Account.Solution_Executive__c, Account.Program_Designation__c, Account.Global_Account__c, 
                           Account.Global_IMGA_Owner__c, Account.AMD__c, Account.Enterprise_ISR__c, 
                           Account.Tele_CDE__c, Account.Global_Account_Director__c,
                           Account.DMS_Owner__c, Account.RIM_SDE__c, Account.Information_Governance_Rep__c, Account.Primary_Local_Market_Rep_1__c
                    FROM Opportunity 
                    WHERE Id IN :oppInputIds AND IsClosed = false
                ];
            }

            if (openOpps.isEmpty()) return;

            Set<Id> oppIds = new Set<Id>();
            for (Opportunity opp : openOpps) {
                oppIds.add(opp.Id);
            }

            System.debug('--- Executing Query 2: Split Type ---');
            Id overlaySplitTypeId = [SELECT Id FROM OpportunitySplitType WHERE MasterLabel = :SPLIT_TYPE_OVERLAY LIMIT 1].Id;

            System.debug('--- Executing Query 3: Opportunity Line Items ---');
            Map<Id, Set<String>> oppBUs = new Map<Id, Set<String>>();
            
            List<OpportunityLineItem> lineItems = [
                SELECT OpportunityId, Product_Business_Unit__c 
                FROM OpportunityLineItem 
                WHERE OpportunityId IN :oppIds 
                AND Id NOT IN :deletedOliIds
            ];
            
            for (OpportunityLineItem oli : lineItems) {
                if (!oppBUs.containsKey(oli.OpportunityId)) {
                    oppBUs.put(oli.OpportunityId, new Set<String>());
                }
                if (oli.Product_Business_Unit__c != null) {
                    oppBUs.get(oli.OpportunityId).add(oli.Product_Business_Unit__c);
                }
            }

            System.debug('--- Executing Query 4: Existing OTMs ---');
            Map<Id, Map<String, OpportunityTeamMember>> existingOtmMap = new Map<Id, Map<String, OpportunityTeamMember>>();
            List<OpportunityTeamMember> existingOtms = [SELECT Id, OpportunityId, CreatedByRole__c, UserId FROM OpportunityTeamMember WHERE OpportunityId IN :oppIds AND IsSystemGenerated__c = true];
            for (OpportunityTeamMember otm : existingOtms) {
                if (!existingOtmMap.containsKey(otm.OpportunityId)) {
                    existingOtmMap.put(otm.OpportunityId, new Map<String, OpportunityTeamMember>());
                }
                existingOtmMap.get(otm.OpportunityId).put(otm.CreatedByRole__c, otm);
            }
            
            System.debug('--- Executing Query 5: Existing Splits ---');
            Map<Id, Map<String, OpportunitySplit>> existingSplitMap = new Map<Id, Map<String, OpportunitySplit>>();
            List<OpportunitySplit> existingSplits = [SELECT Id, OpportunityId, CreatedByRole__c, SplitOwnerId FROM OpportunitySplit WHERE OpportunityId IN :oppIds AND IsSystemGenerated__c = true];
            for (OpportunitySplit split : existingSplits) {
                 if (!existingSplitMap.containsKey(split.OpportunityId)) {
                    existingSplitMap.put(split.OpportunityId, new Map<String, OpportunitySplit>());
                }
                existingSplitMap.get(split.OpportunityId).put(split.CreatedByRole__c, split);
            }

            // --- IN MEMORY PROCESSING ---
            List<OpportunityTeamMember> otmsToInsert = new List<OpportunityTeamMember>();
            List<OpportunityTeamMember> otmsToDelete = new List<OpportunityTeamMember>();
            List<OpportunitySplit> splitsToInsert = new List<OpportunitySplit>();
            List<OpportunitySplit> splitsToDelete = new List<OpportunitySplit>();

            for (Opportunity opp : openOpps) {
                // Safely retrieve the Account using containsKey
                Account acc = accountDataMap.containsKey(opp.AccountId) ? accountDataMap.get(opp.AccountId) : opp.Account;
                
                Map<String, OpportunityTeamMember> oppOtms = existingOtmMap.containsKey(opp.Id) ? existingOtmMap.get(opp.Id) : new Map<String, OpportunityTeamMember>();
                Map<String, OpportunitySplit> oppSplits = existingSplitMap.containsKey(opp.Id) ? existingSplitMap.get(opp.Id) : new Map<String, OpportunitySplit>();
                Set<String> bus = oppBUs.containsKey(opp.Id) ? oppBUs.get(opp.Id) : new Set<String>();
                
                // Initialize required IDs to null by default
                Id requiredSE = null, requiredGMD = null, requiredCP = null, requiredEISR = null, requiredCSM = null, requiredGAD = null;
                Id requiredALM = null, requiredRIM = null, requiredDigital = null;

                // NULL CHECK: Only evaluate Account fields if the Opportunity is actually linked to an Account
                if (acc != null) {
                    Boolean isVolumeMet = (opp.Cubic_Feet__c != null && opp.Cubic_Feet__c >= MIN_VOLUME_CUBIC_FEET);
                    Boolean isAmountMet = (opp.Amount != null && opp.Amount >= MIN_AMOUNT_RIM && bus.contains(BU_RIM));
                    
                    requiredSE = (isVolumeMet || isAmountMet) ? acc.Solution_Executive__c : null;
                    requiredGMD = (acc.Program_Designation__c == 'Global Account' && acc.Global_Account__c == true) ? acc.Global_IMGA_Owner__c : null;
                    requiredCP = acc.AMD__c;
                    requiredEISR = acc.Enterprise_ISR__c;
                    requiredCSM = acc.Tele_CDE__c;
                    requiredGAD = acc.Global_Account_Director__c;

                    requiredALM = (bus.contains(BU_ALM)) ? acc.DMS_Owner__c : null;
                    requiredRIM = (bus.contains(BU_RIM)) ? acc.RIM_SDE__c : null;
                    requiredDigital = (bus.contains(BU_DIGITAL)) ? acc.Information_Governance_Rep__c : null;
                }

                // --- SYNC ROLES ---
                syncRole(opp.Id, requiredSE, ROLE_SOLUTION_EXECUTIVE, ROLE_SOLUTION_EXECUTIVE, ACCESS_EDIT, true, false, overlaySplitTypeId, oppOtms.get(ROLE_SOLUTION_EXECUTIVE), oppSplits.get(ROLE_SOLUTION_EXECUTIVE), otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);
                syncRole(opp.Id, requiredGMD, ROLE_GMD, ROLE_GMD, ACCESS_EDIT, true, true, overlaySplitTypeId, oppOtms.get(ROLE_GMD), oppSplits.get(ROLE_GMD), otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);
                syncRole(opp.Id, requiredCP, ROLE_CLIENT_PARTNER, ROLE_CLIENT_PARTNER, ACCESS_EDIT, true, true, overlaySplitTypeId, oppOtms.get(ROLE_CLIENT_PARTNER), oppSplits.get(ROLE_CLIENT_PARTNER), otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);
                syncRole(opp.Id, requiredEISR, ROLE_ENTERPRISE_ISR, ROLE_ENTERPRISE_ISR, ACCESS_EDIT, false, false, null, oppOtms.get(ROLE_ENTERPRISE_ISR), null, otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);
                syncRole(opp.Id, requiredCSM, ROLE_CSM, ROLE_CSM, ACCESS_READ, false, false, null, oppOtms.get(ROLE_CSM), null, otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);
                syncRole(opp.Id, requiredGAD, ROLE_GAD, ROLE_GAD, ACCESS_EDIT, false, false, null, oppOtms.get(ROLE_GAD), null, otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);

                syncRole(opp.Id, requiredALM, ROLE_ALM_SDE, ROLE_ALM_SDE, ACCESS_EDIT, false, false, null, oppOtms.get(ROLE_ALM_SDE), null, otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);
                syncRole(opp.Id, requiredRIM, ROLE_RIM_SDE, ROLE_RIM_SDE, ACCESS_EDIT, false, false, null, oppOtms.get(ROLE_RIM_SDE), null, otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);
                syncRole(opp.Id, requiredDigital, ROLE_DBU_SDE, ROLE_DBU_SDE, ACCESS_EDIT, false, false, null, oppOtms.get(ROLE_DBU_SDE), null, otmsToInsert, otmsToDelete, splitsToInsert, splitsToDelete);
            }

            System.debug('--- Executing DML Statements ---');
            if (!splitsToDelete.isEmpty()) Database.delete(splitsToDelete,false);
            if (!otmsToDelete.isEmpty()) Database.delete(otmsToDelete,false);
            if (!otmsToInsert.isEmpty()) Database.insert(otmsToInsert, false); 
            if (!splitsToInsert.isEmpty()) Database.insert(splitsToInsert, false);
            System.debug('--- Sync Completed Successfully ---');

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error Message: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Line Number: ' + e.getLineNumber());
            throw new SyncException('Sync failed at Line ' + e.getLineNumber() + ': ' + e.getMessage());
        }
    }

    private static void syncRole(Id oppId, Id requiredUserId, String teamRole, String createdByRole, String accessLevel, Boolean requiresSplit, Boolean isStatic, Id splitTypeId, 
                                 OpportunityTeamMember existingOtm, OpportunitySplit existingSplit, 
                                 List<OpportunityTeamMember> otmsToInsert, List<OpportunityTeamMember> otmsToDelete, 
                                 List<OpportunitySplit> splitsToInsert, List<OpportunitySplit> splitsToDelete) {
        
        if (isStatic && existingOtm != null) return;

        if (existingOtm != null && (requiredUserId == null || existingOtm.UserId != requiredUserId)) {
            otmsToDelete.add(existingOtm);
            if (existingSplit != null) splitsToDelete.add(existingSplit);
        }

        if (requiredUserId != null && (existingOtm == null || existingOtm.UserId != requiredUserId)) {
            otmsToInsert.add(new OpportunityTeamMember(
                OpportunityId = oppId, UserId = requiredUserId, TeamMemberRole = teamRole, 
                CreatedByRole__c = createdByRole, OpportunityAccessLevel = accessLevel, IsSystemGenerated__c = true
            ));
            
            if (requiresSplit) {
                splitsToInsert.add(new OpportunitySplit(
                    OpportunityId = oppId, SplitOwnerId = requiredUserId, SplitTypeId = splitTypeId, 
                    SplitPercentage = SPLIT_PERCENTAGE_FULL, IsSystemGenerated__c = true, CreatedByRole__c = createdByRole
                ));
            }
        }
    }
}