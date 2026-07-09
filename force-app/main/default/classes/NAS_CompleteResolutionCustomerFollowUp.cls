/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Milestone utils class. Completes a Resolution / Customer Follow Up Case Milestone.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public without sharing class NAS_CompleteResolutionCustomerFollowUp {
    /**
     * @name completeResolutionCustomerFollowUpMilestone
     * @description Invocable method to Close Resolution / Customer Follow Up Milestone.
     * This method is called from a Visual Workflow once conditions are met.
    **/
    @InvocableMethod(label='Close Resolution / Customer Follow Up Milestone' 
                     description='Close Resolution / Customer Follow Up Milestone.')
    public static void completeResolutionCustomerFollowUpMilestone(List<Id> caseIds) {
        NAS_MilestoneUtils.completeMilestone(caseIds, NAS_Constants.Milestone_Name_Resln_Cust_Folowup, 
                                            System.now());
    }
}