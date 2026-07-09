/****Prevent Deletion of Opportunity Team Member if added to TSU Field****/
//Created Date: June 4,2014
//Case # :- 02488334
//Auhtor      : Apurva Dutta
//Description : This trigger is defined IMNA opportunities. This trigger will prevent deletion of Opportunity Team member if a user is added to Opportunity team member and same on TSU field. 
// #25042 Blocking edits on Opp Team when Opp is in Stage 5/6/7, Added bypass logics via permission sets

trigger IMNA_preventTeamMemberDelete on OpportunityTeamMember (before delete) {

    
    public String preventTeamMemberDelete = null;
    List<Trigger_Activation_Settings__c> customSettings = Trigger_Activation_Settings__c.getAll().values();
    for (Trigger_Activation_Settings__c cs : customSettings) {
        if (cs.Object__c == 'OpportunityTeamMember') {
            if (cs.Trigger__c == 'preventTeamMemberDelete') {
                preventTeamMemberDelete = cs.Value__c;
            }
        }
    }

    Set<Id> oppIds = new Set<Id>();
    for (OpportunityTeamMember otmObj : Trigger.old) {
        oppIds.add(otmObj.OpportunityId);
    }
    Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity>([
        Select Id, TSU__c, StageName 
        from Opportunity 
        where Id IN :oppIds
    ]);
    Profile currentUserProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];

    if (Trigger.isDelete) {
        for (OpportunityTeamMember teamMem : Trigger.old) {
            Opportunity relatedOppty = opptyMap.get(teamMem.OpportunityId);

            
            Boolean isRestrictedStage = relatedOppty.StageName == '5 - Signed/PO in' || 
                                        relatedOppty.StageName == '6 - Setup' || 
                                        relatedOppty.StageName == '7 - Closed';

            Boolean isNotCustomSysAdmin = currentUserProfile.Name != 'IM_Custom Sys Admin';

            Boolean lacksPermission = !FeatureManagement.checkPermission('Update_Splits_and_Team_members_on_Closed_Oppty');

     
            if (preventTeamMemberDelete == 'True') {
                if (relatedOppty.TSU__c != null && relatedOppty.TSU__c == teamMem.UserId) {
   
                    teamMem.addError('You cannot delete this team member unless you delete them from the TSU field on the Opportunity.');
                }
            }
            if (isNotCustomSysAdmin && isRestrictedStage && lacksPermission) {
                teamMem.addError('Opportunity Team cannot be updated or deleted on a Closed Opportunity. Need Help? Please contact your Business Partner.');
            }
            
        }
    }
}