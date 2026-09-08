@IsTest
private class CaseOwnershipAndSubmitFlowTest {

    @TestSetup
    static void setup() {
        // Required by OpportunityHelper.createOpportunityShare — see CaseCreationEndToEndTest
        // for the full explanation of why every Opportunity-inserting test needs this.
        insert new Country_Settings__c(Name = 'United States', Object_Name__c = 'Opportunity', SetupOwnerId = UserInfo.getOrganizationId());
        // See CaseCreationEndToEndTest for why this second seed row is also required.
        insert new OpportunityProductSelection__c(Name = 'CloudSolutionsProduct', Product_Class_Name__c = 'Cloud Solutions', Product_Line_Name__c = 'Cloud Solutions');

        Account acc = new Account(Name = 'CaseOwnershipE2E Account');
        insert acc;
        insert new Contact(LastName = 'CaseOwnershipE2E', AccountId = acc.Id);
    }

    private static Id dealSupportRTId() {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Deal_Support' LIMIT 1].Id;
    }

    private static Case_Creation_Rule__c makeUnconditionalRule(String queueDevName) {
        Case_Creation_Rule__c rule = new Case_Creation_Rule__c(
            Stage__c = 'Qualification',
            Case_Type__c = 'Remarketing',
            Record_Type_Dev_Name__c = 'Deal_Support',
            Queue_Developer_Name__c = queueDevName,
            Is_Active__c = true,
            Priority__c = 1
        );
        insert rule;
        return rule;
    }

    @IsTest
    static void testCaseOwnedBySellerNotQueueAtCreation() {
        // GAP: per the approved design (Story 6 / IMICC9S-1871), a Case created by the rule
        // engine should be owned by the matched Opportunity's Owner (the seller) at creation,
        // not the support queue — the queue reassignment is supposed to happen only when the
        // seller clicks "Submit to Support". CaseCreationRuleEvaluatorAction.assignRuleMetadata()
        // still sets Case.OwnerId to the resolved queue at creation time; this change was never
        // made. This test documents that gap and is expected to fail until it's fixed.
        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        Opportunity opp = new Opportunity(
            Name = 'CaseOwnershipE2E Opp', AccountId = con.AccountId, StageName = 'Qualification',
            CloseDate = Date.today().addDays(30), Amount = 250000, OwnerId = UserInfo.getUserId()
        );
        insert opp;
        makeUnconditionalRule('Remarketing_Queue');

        Test.startTest();
        CaseCreationRuleEvaluatorAction.createEligibleChecklistsAfterSave(new List<Opportunity>{ opp }, null);
        Test.stopTest();

        List<Case> created = [SELECT Id, OwnerId FROM Case WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, created.size(), 'Expected exactly one Case created for the matched rule.');
        System.assertEquals(opp.OwnerId, created[0].OwnerId,
            'A newly created Case should be owned by the Opportunity Owner (the seller), not the support queue, until Submit to Support is used.');
    }

    @IsTest
    static void testSubmitToSupportFlowReassignsOwnerAndSetsSubmittedFlagWithoutTouchingStatus() {
        Group queue = [SELECT Id FROM Group WHERE DeveloperName = 'Remarketing_Queue' AND Type = 'Queue' LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Case_Creation_Rule__c rule = makeUnconditionalRule('Remarketing_Queue');
        Case c = new Case(
            RecordTypeId = dealSupportRTId(),
            Type = 'Remarketing',
            ContactId = con.Id,
            Case_Creation_Rule__c = rule.Id,
            OwnerId = UserInfo.getUserId(),
            Status = 'New'
        );
        insert c;
        String statusBefore = [SELECT Status FROM Case WHERE Id = :c.Id].Status;

        Test.startTest();
        Map<String, Object> inputs = new Map<String, Object>{ 'recordId' => c.Id };
        Flow.Interview.createInterview('Case_Submit_To_Support_Flow', inputs).start();
        Test.stopTest();

        Case afterSubmit = [SELECT Id, OwnerId, Status, Submitted_To_Support__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(queue.Id, afterSubmit.OwnerId,
            'Case_Submit_To_Support_Flow should reassign the Case to the queue resolved from its Case_Creation_Rule__c.Queue_Developer_Name__c.');
        System.assertEquals(true, afterSubmit.Submitted_To_Support__c,
            'Case_Submit_To_Support_Flow should set Submitted_To_Support__c = true.');
        System.assertEquals(statusBefore, afterSubmit.Status,
            'Case_Submit_To_Support_Flow must never change Case.Status.');
    }

    @IsTest
    static void testSubmitToSupportFlowShowsErrorScreenWhenNoRuleLinked() {
        // A Case with no Case_Creation_Rule__c (e.g., created manually, not by the rule
        // engine) has nothing to resolve a queue from. The flow should reach its Error_Screen
        // path rather than throwing unhandled — verified indirectly here by confirming
        // OwnerId/Submitted_To_Support__c are left untouched rather than erroring the test.
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Case c = new Case(
            RecordTypeId = dealSupportRTId(), Type = 'Remarketing', ContactId = con.Id,
            OwnerId = UserInfo.getUserId(), Status = 'New'
        );
        insert c;

        Test.startTest();
        Map<String, Object> inputs = new Map<String, Object>{ 'recordId' => c.Id };
        Flow.Interview.createInterview('Case_Submit_To_Support_Flow', inputs).start();
        Test.stopTest();

        Case afterSubmit = [SELECT OwnerId, Submitted_To_Support__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(UserInfo.getUserId(), afterSubmit.OwnerId,
            'With no linked Case_Creation_Rule__c, the flow should not reassign ownership.');
        System.assertEquals(false, afterSubmit.Submitted_To_Support__c,
            'With no linked Case_Creation_Rule__c, Submitted_To_Support__c should remain false.');
    }
}
