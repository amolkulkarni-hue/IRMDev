/**
 * IRM_NotifyOpportunityOwnerActionTest
 * Notify opportunity owner (Chatter + bell) on Case/Document Checklist creation.
 */
@IsTest
private class IRM_NotifyOpportunityOwnerActionTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'IRM Notify Test Co');
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'IRM Notify Test Opp', AccountId = acc.Id,
            StageName = 'Qualification', CloseDate = Date.today().addDays(30), Amount = 100000
        );
        insert opp;
    }

    private static Opportunity getOpp() {
        return [SELECT Id, OwnerId FROM Opportunity LIMIT 1];
    }

    private static IRM_NotifyOpportunityOwnerRequest makeRequest(Id oppId, Id ownerId, Id recordId, String label) {
        IRM_NotifyOpportunityOwnerRequest req = new IRM_NotifyOpportunityOwnerRequest();
        req.opportunityId = oppId;
        req.opportunityOwnerId = ownerId;
        req.recordId = recordId;
        req.recordLabel = label;
        return req;
    }

    @IsTest
    static void test_notify_postsChatterFeedItemForValidRequest() {
        Opportunity opp = getOpp();

        Test.startTest();
        IRM_NotifyOpportunityOwnerAction.notify(new List<IRM_NotifyOpportunityOwnerRequest>{
            makeRequest(opp.Id, opp.OwnerId, opp.Id, 'Case')
        });
        Test.stopTest();

        Integer feedCount = [SELECT COUNT() FROM FeedItem WHERE ParentId = :opp.Id];
        System.assertEquals(1, feedCount, 'Expected one Chatter FeedItem posted to the Opportunity.');
    }

    @IsTest
    static void test_notify_bulkCreatesOneFeedItemPerRequest() {
        Opportunity opp = getOpp();

        List<IRM_NotifyOpportunityOwnerRequest> requests = new List<IRM_NotifyOpportunityOwnerRequest>{
            makeRequest(opp.Id, opp.OwnerId, opp.Id, 'Case'),
            makeRequest(opp.Id, opp.OwnerId, opp.Id, 'Document Checklist'),
            makeRequest(opp.Id, opp.OwnerId, opp.Id, 'Document Checklist')
        };

        Test.startTest();
        IRM_NotifyOpportunityOwnerAction.notify(requests);
        Test.stopTest();

        Integer feedCount = [SELECT COUNT() FROM FeedItem WHERE ParentId = :opp.Id];
        System.assertEquals(3, feedCount, 'Expected one FeedItem per request, bulk-safe.');
    }

    @IsTest
    static void test_notify_nullOrEmptyListIsNoOp() {
        Test.startTest();
        IRM_NotifyOpportunityOwnerAction.notify(null);
        IRM_NotifyOpportunityOwnerAction.notify(new List<IRM_NotifyOpportunityOwnerRequest>());
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM FeedItem],
            'A null or empty request list should not create any FeedItem.');
    }

    @IsTest
    static void test_notify_skipsRequestMissingRequiredIds() {
        Opportunity opp = getOpp();

        Test.startTest();
        IRM_NotifyOpportunityOwnerAction.notify(new List<IRM_NotifyOpportunityOwnerRequest>{
            makeRequest(null, opp.OwnerId, opp.Id, 'Case'),
            makeRequest(opp.Id, null, opp.Id, 'Case'),
            makeRequest(opp.Id, opp.OwnerId, null, 'Case')
        });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM FeedItem],
            'Requests missing opportunityId, opportunityOwnerId, or recordId must be skipped without throwing.');
    }

    @IsTest
    static void test_notifyInvocable_delegatesToNotify() {
        Opportunity opp = getOpp();

        Test.startTest();
        IRM_NotifyOpportunityOwnerAction.notifyInvocable(new List<IRM_NotifyOpportunityOwnerRequest>{
            makeRequest(opp.Id, opp.OwnerId, opp.Id, 'Case')
        });
        Test.stopTest();

        Integer feedCount = [SELECT COUNT() FROM FeedItem WHERE ParentId = :opp.Id];
        System.assertEquals(1, feedCount, 'The @InvocableMethod entry point should delegate to notify().');
    }
}
