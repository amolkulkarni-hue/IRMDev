public class CaseTeamSecondaryRoleNotificationScheduler implements Schedulable {

    @TestVisible
    private static final String CHECKPOINT_NAME = 'CaseTeamSecondaryRoleNotification';

    private static final Set<String> SECONDARY_ROLE_NAMES = new Set<String>{
        'Legal Reviewer', 'Legal Approver', 'Compliance Advisor', 'Risk Advisor',
        'Privacy Advisor', 'Channel Partner Advisor', 'CARE Onboarding Specialist',
        'Operations Coordinator', 'Customer Delivery Liaison', 'Finance Reviewer',
        'B2B Analyst', 'Implementation Specialist'
    };

    public void execute(SchedulableContext context) {
        run();
    }

    @TestVisible
    private void run() {
        Datetime runStartedAt = Datetime.now();
        Case_Team_Notification_Checkpoint__c checkpoint = getOrCreateCheckpoint();
        Datetime sinceDatetime = checkpoint.Last_Run_DateTime__c != null
            ? checkpoint.Last_Run_DateTime__c
            : runStartedAt.addDays(-1);

        List<CaseTeamMember> members = [
            SELECT Id, MemberId, TeamRole.Name, Parent.CaseNumber, Parent.Subject
            FROM CaseTeamMember
            WHERE CreatedDate > :sinceDatetime AND TeamRole.Name IN :SECONDARY_ROLE_NAMES
        ];

        sendNotifications(members);

        checkpoint.Last_Run_DateTime__c = runStartedAt;
        upsert checkpoint;
    }

    private Case_Team_Notification_Checkpoint__c getOrCreateCheckpoint() {
        List<Case_Team_Notification_Checkpoint__c> existing = [
            SELECT Id, Last_Run_DateTime__c
            FROM Case_Team_Notification_Checkpoint__c
            WHERE Name = :CHECKPOINT_NAME
            LIMIT 1
        ];
        if (!existing.isEmpty()) {
            return existing[0];
        }
        return new Case_Team_Notification_Checkpoint__c(Name = CHECKPOINT_NAME);
    }

    private void sendNotifications(List<CaseTeamMember> members) {
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
