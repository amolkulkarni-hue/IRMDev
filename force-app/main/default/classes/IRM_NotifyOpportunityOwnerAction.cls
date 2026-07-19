public with sharing class IRM_NotifyOpportunityOwnerAction {

    public class Request {
        @InvocableVariable(label='Opportunity Id' required=true)
        public Id opportunityId;
        @InvocableVariable(label='Opportunity Owner Id' required=true)
        public Id opportunityOwnerId;
        @InvocableVariable(label='Record Id' required=true)
        public Id recordId;
        @InvocableVariable(label='Record Label (e.g. Case, Document Checklist)' required=true)
        public String recordLabel;
    }

    private static final String NOTIFICATION_TYPE_DEV_NAME = 'Notify_Opportunity_Owner_Doc_Checklist';

    @InvocableMethod(
        label='Notify Opportunity Owner'
        description='Posts a Chatter update to the Opportunity and sends a bell notification to the Opportunity owner when a Case or Document Checklist is created on their Opportunity.'
        category='IRM Touch Level'
    )
    public static void notifyInvocable(List<Request> requests) {
        notify(requests);
    }

    // Bulk entry point — callable directly from Apex (CaseCreationRuleEvaluatorAction) or via the
    // @InvocableMethod above from Flow (Case_Exit_Doc_Checklist_Creation_Flow).
    public static void notify(List<Request> requests) {
        if (requests == null || requests.isEmpty()) return;

        Id notificationTypeId = getNotificationTypeId();
        List<FeedItem> feedItems = new List<FeedItem>();

        for (Request req : requests) {
            if (req.opportunityId == null || req.opportunityOwnerId == null || req.recordId == null) continue;

            feedItems.add(new FeedItem(
                ParentId = req.opportunityId,
                Body     = 'A new ' + req.recordLabel + ' was created on this Opportunity and requires your attention.'
            ));

            if (notificationTypeId != null) {
                try {
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('New ' + req.recordLabel + ' on Your Opportunity');
                    notification.setBody('A new ' + req.recordLabel + ' was created on your Opportunity and requires your attention.');
                    notification.setNotificationTypeId(notificationTypeId);
                    notification.setTargetId(req.recordId);
                    notification.send(new Set<String>{ req.opportunityOwnerId });
                } catch (Exception e) {
                    // Best-effort — bell-notification delivery (e.g. a per-transaction send limit)
                    // must never block the Chatter post or the Case/Checklist creation that already committed.
                }
            }
        }

        if (!feedItems.isEmpty()) Database.insert(feedItems, false);
    }

    private static Id getNotificationTypeId() {
        List<CustomNotificationType> types = [
            SELECT Id FROM CustomNotificationType WHERE DeveloperName = :NOTIFICATION_TYPE_DEV_NAME LIMIT 1
        ];
        return types.isEmpty() ? null : types[0].Id;
    }
}
