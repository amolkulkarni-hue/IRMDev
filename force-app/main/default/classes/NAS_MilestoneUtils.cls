/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Milestone utils class. Completes a Case Milestone.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public without sharing class NAS_MilestoneUtils {
    public static void completeMilestone(List<Id> caseIds, String milestoneName, DateTime complDate) {  
        List<CaseMilestone> cmsToUpdate = [SELECT Id, CompletionDate FROM CaseMilestone
                                           WHERE CaseId IN :caseIds AND MilestoneType.Name = 
                                           :milestoneName AND CompletionDate = null];
        if(cmsToUpdate.isEmpty() == false) {
            for(CaseMilestone cm : cmsToUpdate) {
                cm.completionDate = complDate;
            }
            update cmsToUpdate;
        }
    }
}