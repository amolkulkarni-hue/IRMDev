/**
 * IRM_CaseRoutingTest
 * US-1500: Case Queue Routing via Support_Engagement_Case_Assignment_Flow
 * and Touch_Level_Case_Routing__c
 *
 * Flow under test: Support_Engagement_Case_Assignment_Flow (After Insert — Case)
 * Must be ACTIVE in Setup → Flows before running.
 * Touch_Level_Case_Routing__c replaces the former Touch_Level_Case_Mapping__mdt Custom
 * Metadata Type (migrated so mapping changes carry field history tracking) — as a regular
 * custom object, its rows are seeded in @TestSetup below rather than relying on deployed
 * CMT default records.
 */
@IsTest
private class IRM_CaseRoutingTest {

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
            Name = 'IRM Routing Test Co',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;
        // Case VR: "Please enter a value for either the Contact or IM Employee" — need ContactId
        insert new Contact(LastName = 'CaseContact', AccountId = acc.Id);

        // Touch_Level_Case_Routing__c seed data — Support_Engagement_Case_Assignment_Flow reads
        // these by Case_Type__c to resolve the routing Queue. Intentionally no row for
        // 'Unmapped Type'/'Unmapped Case Type' (used by the negative-path tests below).
        insert new List<Touch_Level_Case_Routing__c>{
            new Touch_Level_Case_Routing__c(Name = 'SA Assignment Mapping', Case_Type__c = 'SA Assignment', Queue_Developer_Name__c = 'Solution_Specialist_Queue', Is_Active__c = true),
            new Touch_Level_Case_Routing__c(Name = 'Pricing Mapping',       Case_Type__c = 'Pricing',       Queue_Developer_Name__c = 'DOC_Pricing_Queue',            Is_Active__c = true),
            new Touch_Level_Case_Routing__c(Name = 'Legal Review Mapping',  Case_Type__c = 'Legal Review',  Queue_Developer_Name__c = 'Legal_GCCS_Queue',             Is_Active__c = true),
            new Touch_Level_Case_Routing__c(Name = 'InfoSec Mapping',       Case_Type__c = 'InfoSec Security Review', Queue_Developer_Name__c = 'InfoSec_Queue',      Is_Active__c = true)
        };
    }

    private static Account getAccount() {
        return [SELECT Id FROM Account LIMIT 1];
    }

    private static Id getContactId() {
        return [SELECT Id FROM Contact LIMIT 1].Id;
    }

    private static Id getQueueId(String developerName) {
        List<Group> queues = [SELECT Id FROM Group
                              WHERE DeveloperName = :developerName AND Type = 'Queue'];
        System.debug('Queue lookup: DeveloperName=' + developerName
            + ' | found=' + queues.size() + (queues.isEmpty() ? ' (QUEUE NOT FOUND — check deployment)' : ' | Id=' + queues[0].Id));
        return queues.isEmpty() ? null : queues[0].Id;
    }

    // ── US-1500 AC1: SA Assignment → Solution Specialist Queue ───────────────

    @IsTest
    static void test_saAssignmentRoutedToSolutionSpecialistQueue() {
        Id queueId = getQueueId('Solution_Specialist_Queue');
        System.debug('TEST: Inserting Case with Type=SA Assignment. Expect OwnerId=' + queueId);
        System.assert(queueId != null,
            'PRE-CONDITION: Solution_Specialist_Queue must exist in org. Was the queue deployment successful?');

        Test.startTest();
        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'SA Routing Test', Type = 'SA Assignment', Status = 'New'
        );
        insert c;
        Test.stopTest();

        Case r = [SELECT Id, OwnerId, Type FROM Case WHERE Id = :c.Id];
        System.debug('RESULT: Case Id=' + r.Id + ' | Type=' + r.Type + ' | OwnerId=' + r.OwnerId + ' | Expected=' + queueId);

        System.assertEquals(queueId, r.OwnerId,
            'US-1500: SA Assignment Case should be routed to Solution_Specialist_Queue. OwnerId=' + r.OwnerId + ' Expected=' + queueId
            + '. Check the Touch_Level_Case_Routing__c seed data and that the flow is active.');
    }

    // ── US-1500 AC2: Pricing → DOC Pricing Queue ─────────────────────────────

    @IsTest
    static void test_pricingRoutedToDOCPricingQueue() {
        Id queueId = getQueueId('DOC_Pricing_Queue');
        System.debug('TEST: Inserting Case with Type=Pricing. Expect OwnerId=' + queueId);
        System.assert(queueId != null, 'PRE-CONDITION: DOC_Pricing_Queue must exist in org.');

        Test.startTest();
        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'Pricing Routing Test', Type = 'Pricing', Status = 'New'
        );
        insert c;
        Test.stopTest();

        Case r = [SELECT OwnerId FROM Case WHERE Id = :c.Id];
        System.debug('RESULT: OwnerId=' + r.OwnerId + ' | Expected=' + queueId);

        System.assertEquals(queueId, r.OwnerId,
            'US-1500: Pricing Case should be routed to DOC_Pricing_Queue. OwnerId=' + r.OwnerId + ' Expected=' + queueId);
    }

    // ── US-1500 AC3: Legal Review → Legal GCCS Queue ─────────────────────────

    @IsTest
    static void test_legalReviewRoutedToLegalGCCSQueue() {
        Id queueId = getQueueId('Legal_GCCS_Queue');
        System.debug('TEST: Inserting Case with Type=Legal Review. Expect OwnerId=' + queueId);
        System.assert(queueId != null, 'PRE-CONDITION: Legal_GCCS_Queue must exist in org.');

        Test.startTest();
        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'Legal Routing Test', Type = 'Legal Review', Status = 'New'
        );
        insert c;
        Test.stopTest();

        Case r = [SELECT OwnerId FROM Case WHERE Id = :c.Id];
        System.debug('RESULT: OwnerId=' + r.OwnerId + ' | Expected=' + queueId);

        System.assertEquals(queueId, r.OwnerId,
            'US-1500: Legal Review Case should be routed to Legal_GCCS_Queue. OwnerId=' + r.OwnerId + ' Expected=' + queueId);
    }

    // ── US-1500 AC4: InfoSec → InfoSec Queue ─────────────────────────────────

    @IsTest
    static void test_infoSecRoutedToInfoSecQueue() {
        Id queueId = getQueueId('InfoSec_Queue');
        System.debug('TEST: Inserting Case with Type=InfoSec Security Review. Expect OwnerId=' + queueId);
        System.assert(queueId != null, 'PRE-CONDITION: InfoSec_Queue must exist in org.');

        Test.startTest();
        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'InfoSec Routing Test', Type = 'InfoSec Security Review', Status = 'New'
        );
        insert c;
        Test.stopTest();

        Case r = [SELECT OwnerId FROM Case WHERE Id = :c.Id];
        System.debug('RESULT: OwnerId=' + r.OwnerId + ' | Expected=' + queueId);

        System.assertEquals(queueId, r.OwnerId,
            'US-1500: InfoSec Security Review Case should be routed to InfoSec_Queue. OwnerId=' + r.OwnerId + ' Expected=' + queueId);
    }

    // ── US-1500 AC5: Unmapped Case Type inserts without error ────────────────

    @IsTest
    static void test_unmappedCaseTypeDoesNotError() {
        // 'Booking Verification' is a real, active Type value with no Touch_Level_Case_Routing__c
        // mapping row seeded above — exercises the "no mapping found" path without an invalid picklist value.
        System.debug('TEST: Inserting Case with Type=Booking Verification. No mapping row for this. Expect successful insert, no routing applied.');

        Test.startTest();
        Boolean errored = false;
        Case c;
        try {
            c = new Case(
                AccountId = getAccount().Id, ContactId = getContactId(),
                Subject = 'Unmapped Routing Test', Type = 'Booking Verification', Status = 'New'
            );
            insert c;
        } catch (Exception e) {
            errored = true;
            System.debug('EXCEPTION: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        Test.stopTest();

        System.assertEquals(false, errored,
            'US-1500: Case with an unmapped Type should insert without error. Flow should handle missing mapping gracefully.');
        System.assertNotEquals(null, [SELECT Id FROM Case WHERE Id = :c.Id].Id,
            'US-1500: Case should exist after insert.');
    }

    // ── US-1500 Bulk: 200 cases all routed ──────────────────────────────────

    @IsTest
    static void test_bulk200CasesRouted() {
        Id queueId = getQueueId('Solution_Specialist_Queue');
        System.assert(queueId != null, 'PRE-CONDITION: Solution_Specialist_Queue must exist in org.');

        Account acc = getAccount();
        Id contactId = getContactId();
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 200; i++) {
            cases.add(new Case(
                AccountId = acc.Id, ContactId = contactId,
                Subject = 'Bulk Case ' + i, Type = 'SA Assignment', Status = 'New'
            ));
        }

        System.debug('TEST: Bulk inserting 200 SA Assignment cases. Expect all routed to Solution_Specialist_Queue=' + queueId);

        Test.startTest();
        insert cases;
        Test.stopTest();

        List<Case> results = [SELECT Id, OwnerId FROM Case WHERE AccountId = :acc.Id];
        System.debug('RESULT: Total cases=' + results.size());

        Integer misrouted = 0;
        for (Case r : results) {
            if (r.OwnerId != queueId) misrouted++;
        }
        System.debug('Misrouted cases=' + misrouted + ' out of ' + results.size());

        System.assertEquals(0, misrouted,
            'Bulk US-1500: ' + misrouted + ' out of ' + results.size() + ' cases were not routed to Solution_Specialist_Queue.');
    }
}