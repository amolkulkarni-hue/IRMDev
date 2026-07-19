/**
 * IRM_NotifyOpportunityOwnerActionTest
 * Notify opportunity owner (Chatter + bell) on Case/Document Checklist creation.
 */
@IsTest
private class IRM_NotifyOpportunityOwnerActionTest {

    @TestSetup
    static void setup() {
        IM_Country__c testCountry = new IM_Country__c(Name = 'United States');
        insert testCountry;
        insert new IM_Alternative_Country_Name__c(
            IM_Country__c = testCountry.Id, Alternative_Name__c = 'United States'
        );
        // Required by OpportunityHelper.createOpportunityShare (Country_Settings__c and
        // Opportunity_Security__c are list custom settings read during Opportunity AfterInsert)
        insert new Country_Settings__c(Name = 'United States', Object_Name__c = 'Opportunity', SetupOwnerId = UserInfo.getOrganizationId());
        insert new List<Opportunity_Security__c>{
            new Opportunity_Security__c(Name = 'Primary CDE',          Field_Name__c = 'Primary_CDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'R', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Original Lead Owner',  Field_Name__c = 'IM_Original_Lead_Owner__c', Object_Name__c = 'Opportunity', Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Primary BDE',          Field_Name__c = 'Primary_BDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId())
        };
        // Required by OppPartnerAction (called from OpportunityTriggerHandler.BeforeUpdate
        // via "Update Pricebook On Opportunity" flow — queries this record by name)
        insert new OpportunityProductSelection__c(Name = 'CloudSolutionsProduct',
            Product_Class_Name__c = 'Cloud', Product_Line_Name__c = 'Cloud Solutions');
        Account acc = new Account(
            Name = 'IRM Notify Test Co',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;
        Opportunity opp = new Opportunity(
            Name = 'IRM Notify Test Opp', AccountId = acc.Id,
            Type = 'New Deal', StageName = 'Qualification', CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(), Amount = 100000,
            Bypass_Validation__c = true
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
