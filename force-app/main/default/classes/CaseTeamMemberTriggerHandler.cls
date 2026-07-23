public class CaseTeamMemberTriggerHandler implements ITriggerHandler {

    private static final Set<String> SECONDARY_ROLE_NAMES = new Set<String>{
        'Legal Reviewer', 'Legal Approver', 'Compliance Advisor', 'Risk Advisor',
        'Privacy Advisor', 'Channel Partner Advisor', 'CARE Onboarding Specialist',
        'Operations Coordinator', 'Customer Delivery Liaison', 'Finance Reviewer',
        'B2B Analyst', 'Implementation Specialist'
    };

    public void BeforeInsert(List<SObject> newItems) {
    }

    public void AfterInsert(List<SObject> newItems) {
        notifySecondaryRoleMembers((List<CaseTeamMember>) newItems);
    }

    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }

    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }

    public void BeforeDelete(Map<Id, SObject> oldItems) {
    }

    public void AfterDelete(Map<Id, SObject> oldItems) {
    }

    public void AfterUndelete(Map<Id, SObject> oldItems) {
    }

    public Boolean IsDisabled() {
        return false;
    }

    private void notifySecondaryRoleMembers(List<CaseTeamMember> newItems) {
        List<CaseTeamMember> members = [
            SELECT Id, MemberId, TeamRole.Name, Parent.CaseNumber, Parent.Subject
            FROM CaseTeamMember
            WHERE Id IN :newItems AND TeamRole.Name IN :SECONDARY_ROLE_NAMES
        ];
        if (members.isEmpty()) {
            return;
        }

        Set<Id> userIds = new Set<Id>();
        for (CaseTeamMember member : members) {
            userIds.add(member.MemberId);
        }

        Map<Id, User> usersById = new Map<Id, User>([SELECT Id, Email FROM User WHERE Id IN :userIds]);

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (CaseTeamMember member : members) {
            User recipient = usersById.get(member.MemberId);
            if (recipient == null || String.isBlank(recipient.Email)) {
                continue;
            }
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ recipient.Email });
            email.setSubject('You\'ve been added to Case ' + member.Parent.CaseNumber + ' as ' + member.TeamRole.Name);
            email.setPlainTextBody(
                'You have been added to Case ' + member.Parent.CaseNumber +
                ' ("' + member.Parent.Subject + '") as ' + member.TeamRole.Name + '. ' +
                'You can view this Case from the "My Case Teams" list view on the Cases tab.'
            );
            emails.add(email);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}
