/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Milestone utils class. Completes a Agent Validation Case Milestone.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public without sharing class NAS_CompleteAgentValidationMilestone {
    /**
     * @name completeAgentValidationMilestone
     * @description Invocable method to Close Agent Validation Milestone.
     * This method is called from a Visual Workflow once conditions are met.
    **/
    @InvocableMethod(label='Close Agent Validation Milestone' 
                     description='Close Agent Validation Milestone.')
    public static void completeAgentValidationMilestone(List<Id> caseIds) {
        NAS_MilestoneUtils.completeMilestone(caseIds, NAS_Constants.Milestone_Name_Agent_Validation, 
                                            System.now());
    }
}