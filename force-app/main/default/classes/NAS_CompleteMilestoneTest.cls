/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Test Class for Complete milestone functionality.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
@isTest
private class NAS_CompleteMilestoneTest {
    /**
     * @name setupTestData
     * @description Sets up Test data needed for all test cases in this Test Class.
    **/
	@testSetup
    public static void setupTestData()
    {
        NAS_TestDataFactory.setupTestData(1);
    	NAS_TestDataFactory.createCase(1, NAS_Constants.NAS_GENERAL_SUPPORT_CASE_RECORDTYPE, 
                                       true, NAS_TestConstants.Milestone_Test_Status_1);
        Case c = [SELECT Id FROM Case Limit 1];
        c.Type = NAS_TestConstants.Milestone_Test_Case_Type;
        update c;
    }
    @isTest
    public static void testCompleteTCOPEnrichmentMilestone(){
        Case c = [SELECT Id FROM Case Limit 1];
        List<CaseMilestone> cmsToUpdateBeforeUpdate = [SELECT Id, CompletionDate
                    FROM CaseMilestone WHERE CaseId = :c.Id AND MilestoneType.Name = 
                    :NAS_Constants.Milestone_Name_TCOP_Enrichment
                    AND CompletionDate = null];
        System.assertEquals(1, cmsToUpdateBeforeUpdate.size(), 'Incorrect number of Open Case Milestone');
        Test.startTest();
        c.Status = NAS_TestConstants.Milestone_Test_Status_2;
        NAS_CompleteTCOPEnrichmentMilestone.completeTCOPEnrichmentMilestone(new List<Id>{c.id});
        update c;
        Test.stopTest();
        List<CaseMilestone> cmsToUpdateAfterUpdate = [SELECT Id, CompletionDate
                    FROM CaseMilestone WHERE CaseId = :c.Id AND MilestoneType.Name = 
                    :NAS_Constants.Milestone_Name_TCOP_Enrichment
                    AND CompletionDate = null];
        System.assertEquals(0, cmsToUpdateAfterUpdate.size(), 'Incorrect number of Open Case Milestone');
    }
    @isTest
    public static void testCompleteAgentValidationMilestone(){
        Case c = [SELECT Id FROM Case Limit 1];
        c.Status = NAS_TestConstants.Milestone_Test_Status_2;
        update c;
        List<CaseMilestone> cmsToUpdateBeforeUpdate = [SELECT Id, CompletionDate
                    FROM CaseMilestone WHERE CaseId = :c.Id AND MilestoneType.Name = 
                    :NAS_Constants.Milestone_Name_Agent_Validation
                    AND CompletionDate = null];
        System.assertEquals(1, cmsToUpdateBeforeUpdate.size(), 'Incorrect number of Open Case Milestone');
        update c;
        Test.startTest();
        c.Status = NAS_TestConstants.Milestone_Test_Status_3;
        NAS_CompleteAgentValidationMilestone.completeAgentValidationMilestone(new List<Id>{c.id});
        update c;
        Test.stopTest();
        List<CaseMilestone> cmsToUpdateAfterUpdate = [SELECT Id, CompletionDate
                    FROM CaseMilestone WHERE CaseId = :c.Id AND MilestoneType.Name = 
                    :NAS_Constants.Milestone_Name_Agent_Validation
                    AND CompletionDate = null];
        System.assertEquals(0, cmsToUpdateAfterUpdate.size(), 'Incorrect number of Open Case Milestone');
    }
    @isTest
    public static void testCompleteResolutionCustomerFollowUp() {
        Case c = [SELECT Id FROM Case Limit 1];
        c.Status = NAS_TestConstants.Milestone_Test_Status_2;
        update c;
        c.Status = NAS_TestConstants.Milestone_Test_Status_3;
        update c;
        List<CaseMilestone> cmsToUpdateBeforeUpdate = [SELECT Id, CompletionDate
                    FROM CaseMilestone WHERE CaseId = :c.Id and MilestoneType.Name = 
                    :NAS_Constants.Milestone_Name_Resln_Cust_Folowup AND CompletionDate = null];
        System.assertEquals(1, cmsToUpdateBeforeUpdate.size(), 'Incorrect number of Open Case Milestone');
        Test.startTest();
        c.Status = NAS_TestConstants.Milestone_Test_Status_4;
        c.NAS_Root_Cause_Reason__c = NAS_TestConstants.Milestone_Test_Root_Cause;
        NAS_CompleteResolutionCustomerFollowUp.completeResolutionCustomerFollowUpMilestone(new List<Id>{c.id});
        update c;
        Test.stopTest();
        List<CaseMilestone> cmsToUpdateAfterUpdate = [SELECT Id, CompletionDate
                    FROM CaseMilestone WHERE CaseId = :c.Id and MilestoneType.Name = 
                    :NAS_Constants.Milestone_Name_Resln_Cust_Folowup AND CompletionDate = null];
        System.assertEquals(0, cmsToUpdateAfterUpdate.size(), 'Incorrect number of Open Case Milestone');
    }
}