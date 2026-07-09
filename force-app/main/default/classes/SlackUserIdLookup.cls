public class SlackUserIdLookup{
    @InvocableMethod(label='Get Slack User IDs' description='Returns Slack User IDs given Salesforce IDs')
    public static List<String> getSlackUserIDs(List<String> salesforceIDs) {
        String teamId = System.Label.Slack_TeamId;
        List<String> slackUserIDs = new List<String>();
        slackUserIDs.add(Slack.UserMappingService.getSlackUserId(salesforceIDs[0], teamId));
        return slackUserIDs;
    }
}