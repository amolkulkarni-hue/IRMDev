@isTest
private class CaseTeamSecondaryRoleNotificationScheduler_test {

    @isTest
    static void firstRunNotifiesExistingSecondaryRoleMembersWithinLookbackWindow() {
        Case testCase = new Case(Subject = 'Test case for scheduled secondary team notification');
        insert testCase;

        CaseTeamRole role = [SELECT Id FROM CaseTeamRole WHERE Name = 'Compliance Advisor' LIMIT 1];
        insert new CaseTeamMember(
            ParentId = testCase.Id,
            MemberId = UserInfo.getUserId(),
            TeamRoleId = role.Id
        );

        Integer emailInvocationsBefore = Limits.getEmailInvocations();

        Test.startTest();
        new CaseTeamSecondaryRoleNotificationScheduler().run();
        Test.stopTest();

        System.assertEquals(
            emailInvocationsBefore + 1,
            Limits.getEmailInvocations(),
            'A secondary-role CaseTeamMember created before the checkpoint existed should be caught by the first run'
        );

        Case_Team_Notification_Checkpoint__c checkpoint = [
            SELECT Last_Run_DateTime__c FROM Case_Team_Notification_Checkpoint__c
            WHERE Name = :CaseTeamSecondaryRoleNotificationScheduler.CHECKPOINT_NAME
            LIMIT 1
        ];
        System.assertNotEquals(null, checkpoint.Last_Run_DateTime__c, 'Checkpoint should be recorded after a run');
    }

    @isTest
    static void secondRunDoesNotReNotifyAlreadyProcessedMembers() {
        Case testCase = new Case(Subject = 'Test case for checkpoint dedup');
        insert testCase;

        CaseTeamRole role = [SELECT Id FROM CaseTeamRole WHERE Name = 'Risk Advisor' LIMIT 1];
        insert new CaseTeamMember(
            ParentId = testCase.Id,
            MemberId = UserInfo.getUserId(),
            TeamRoleId = role.Id
        );

        Test.startTest();
        new CaseTeamSecondaryRoleNotificationScheduler().run();
        Integer emailInvocationsAfterFirstRun = Limits.getEmailInvocations();
        new CaseTeamSecondaryRoleNotificationScheduler().run();
        Test.stopTest();

        System.assertEquals(
            emailInvocationsAfterFirstRun,
            Limits.getEmailInvocations(),
            'A second run with no new CaseTeamMembers should not send additional emails'
        );
    }

    @isTest
    static void nonSecondaryRoleMemberIsNotNotified() {
        Case testCase = new Case(Subject = 'Test case for non-secondary role');
        insert testCase;

        CaseTeamRole role = [SELECT Id FROM CaseTeamRole WHERE Name = 'Case View' LIMIT 1];
        insert new CaseTeamMember(
            ParentId = testCase.Id,
            MemberId = UserInfo.getUserId(),
            TeamRoleId = role.Id
        );

        Integer emailInvocationsBefore = Limits.getEmailInvocations();

        Test.startTest();
        new CaseTeamSecondaryRoleNotificationScheduler().run();
        Test.stopTest();

        System.assertEquals(
            emailInvocationsBefore,
            Limits.getEmailInvocations(),
            'A non-secondary role CaseTeamMember should never trigger a notification'
        );
    }
}
