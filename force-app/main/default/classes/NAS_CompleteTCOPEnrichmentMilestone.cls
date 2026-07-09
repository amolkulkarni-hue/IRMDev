/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Milestone utils class. Completes a TCOP Enrichment Case Milestone.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public without sharing class NAS_CompleteTCOPEnrichmentMilestone {
    /**
     * @name completeTCOPEnrichmentMilestone
     * @description Invocable method to Close TCOP Enrichment Milestone.
     * This method is called from a Visual Workflow once conditions are met.
    **/
    @InvocableMethod(label='Close TCOP Enrichment Milestone' 
                     description='Close TCOP Enrichment Milestone.')
    public static void completeTCOPEnrichmentMilestone(List<Id> caseIds) {
        NAS_MilestoneUtils.completeMilestone(caseIds, NAS_Constants.Milestone_Name_TCOP_Enrichment, 
                                            System.now());
    }
}