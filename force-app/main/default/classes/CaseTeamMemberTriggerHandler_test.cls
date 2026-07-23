@isTest
private class CaseTeamMemberTriggerHandler_test {

    @isTest
    static void secondaryRoleMemberTriggersEmailNotification() {
        Case testCase = new Case(Subject = 'Test case for secondary team notification');
        insert testCase;

        CaseTeamRole role = [SELECT Id FROM CaseTeamRole WHERE Name = 'Compliance Advisor' LIMIT 1];

        Integer emailInvocationsBefore = Limits.getEmailInvocations();

        Test.startTest();
        insert new CaseTeamMember(
            ParentId = testCase.Id,
            MemberId = UserInfo.getUserId(),
            TeamRoleId = role.Id
        );
        Test.stopTest();

        System.assertEquals(
            emailInvocationsBefore + 1,
            Limits.getEmailInvocations(),
            'Adding a CaseTeamMember with a secondary role should send exactly one email notification'
        );
    }

    @isTest
    static void nonSecondaryRoleMemberDoesNotTriggerEmail() {
        Case testCase = new Case(Subject = 'Test case for non-secondary team member');
        insert testCase;

        CaseTeamRole role = [SELECT Id FROM CaseTeamRole WHERE Name = 'Case View' LIMIT 1];

        Integer emailInvocationsBefore = Limits.getEmailInvocations();

        Test.startTest();
        insert new CaseTeamMember(
            ParentId = testCase.Id,
            MemberId = UserInfo.getUserId(),
            TeamRoleId = role.Id
        );
        Test.stopTest();

        System.assertEquals(
            emailInvocationsBefore,
            Limits.getEmailInvocations(),
            'Adding a CaseTeamMember with a non-secondary role should not send any email notification'
        );
    }
}
