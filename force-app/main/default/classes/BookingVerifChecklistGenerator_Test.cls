@isTest
private class BookingVerifChecklistGenerator_Test {

    private static Account testAccount() {
        Account a = new Account(Name = 'BVCG Test Acc');
        insert a;
        return a;
    }

    private static Opportunity testOpportunity(Id accountId, String suffix) {
        // Skip the real trigger handlers for this setup insert — this class is called
        // directly with hand-built Opportunity data below, so the trigger doesn't need
        // to fire, and skipping it avoids unrelated pre-existing automation issues.
        AccountTriggerHandler.skipTriggerExecutionTestClass = true;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        Opportunity opp = new Opportunity(
            Name = 'BVCG Test Opp ' + suffix,
            AccountId = accountId,
            StageName = '1 - Qualification',
            CloseDate = Date.today().addDays(30),
            Type = 'New Deal',
            CurrencyIsoCode = 'USD'
        );
        insert opp;
        return opp;
    }

    private static IM_Country__c testCountry(String isoCode) {
        IM_Country__c c = new IM_Country__c(Name = isoCode);
        insert c;
        return c;
    }

    // Template Items can only be added while the parent Template is Draft, so create
    // the Template as Draft, add its items, then flip it to Published.
    private static Booking_Verification_Template__c testTemplate(String bu, String dealType, String country) {
        Booking_Verification_Template__c t = new Booking_Verification_Template__c(
            Business_Unit__c = bu, Deal_Type__c = dealType, Country__c = country, Status__c = 'Draft'
        );
        insert t;
        return t;
    }

    private static void publishTemplate(Id templateId) {
        update new Booking_Verification_Template__c(Id = templateId, Status__c = 'Published');
    }

    // Matched template found: header, a Document-type item (docsToInsert branch), and a
    // Task-type item (the "when else" branch) all get created.
    @isTest
    static void test_generateAfterSave_MatchedTemplate_CreatesHeaderAndChildren() {
        Account acc = testAccount();
        Opportunity insertedOpp = testOpportunity(acc.Id, 'Match');
        IM_Country__c country = testCountry('CA');

        Booking_Verification_Template__c tmpl = testTemplate('RIM', 'New Deal', 'Canada');
        insert new List<Booking_Verification_Template_Item__c>{
            new Booking_Verification_Template_Item__c(
                Booking_Verification_Template__c = tmpl.Id, Name = 'Doc Item', Type__c = 'Document',
                Is_Mandatory__c = true, Sequence_Number__c = 1
            ),
            new Booking_Verification_Template_Item__c(
                Booking_Verification_Template__c = tmpl.Id, Name = 'Task Item', Type__c = 'Task',
                Is_Mandatory__c = false, Sequence_Number__c = 2
            )
        };
        publishTemplate(tmpl.Id);

        Opportunity newOpp = new Opportunity(
            Id = insertedOpp.Id, StageName = 'Booking Verification', Business_Unit__c = 'RIM',
            Type = 'New Deal', Billing_Country__c = country.Id
        );

        Test.startTest();
        BookingVerificationChecklistGenerator.generateAfterSave(new List<Opportunity>{newOpp}, null);
        Test.stopTest();

        List<Booking_Verification_Checklist__c> checklists = [
            SELECT Id, Status__c FROM Booking_Verification_Checklist__c WHERE Opportunity__c = :insertedOpp.Id
        ];
        System.assertEquals(1, checklists.size(), 'Should create one checklist header');
        System.assertEquals('Draft', checklists[0].Status__c);

        List<Booking_Verification_Checklist_Item__c> items = [
            SELECT Id FROM Booking_Verification_Checklist_Item__c WHERE Opportunity__c = :insertedOpp.Id
        ];
        System.assertEquals(2, items.size(), 'Should create both template items as checklist items');

        List<Document_Checklist__c> docs = [
            SELECT Id FROM Document_Checklist__c WHERE Opportunity__c = :insertedOpp.Id
        ];
        System.assertEquals(1, docs.size(), 'Only the Document-type item should also create a Document_Checklist__c');
    }

    // No published template matches this Business Unit / Deal Type / Country combo —
    // a warning Chatter post is created instead.
    @isTest
    static void test_generateAfterSave_NoMatchingTemplate_PostsChatterWarning() {
        Account acc = testAccount();
        Opportunity insertedOpp = testOpportunity(acc.Id, 'NoMatch');
        IM_Country__c country = testCountry('ZZ');

        Opportunity newOpp = new Opportunity(
            Id = insertedOpp.Id, StageName = 'Booking Verification', Business_Unit__c = 'ALM',
            Type = 'New Deal', Billing_Country__c = country.Id
        );

        Test.startTest();
        BookingVerificationChecklistGenerator.generateAfterSave(new List<Opportunity>{newOpp}, null);
        Test.stopTest();

        List<FeedItem> posts = [SELECT Id FROM FeedItem WHERE ParentId = :insertedOpp.Id];
        System.assertEquals(1, posts.size(), 'Should post a warning Chatter item when no template matches');

        List<Booking_Verification_Checklist__c> checklists = [
            SELECT Id FROM Booking_Verification_Checklist__c WHERE Opportunity__c = :insertedOpp.Id
        ];
        System.assertEquals(0, checklists.size(), 'No checklist should be created without a matching template');
    }

    // An Opportunity that already has a checklist (from a prior pass through Booking
    // Verification) moving back into that stage should reset the existing header and
    // its previously-rejected items back to Draft instead of creating a duplicate.
    @isTest
    static void test_generateAfterSave_ExistingChecklist_TriggersResubmission() {
        Account acc = testAccount();
        Opportunity insertedOpp = testOpportunity(acc.Id, 'Resub');
        IM_Country__c country = testCountry('CA');

        Booking_Verification_Checklist__c existingChk = new Booking_Verification_Checklist__c(
            Opportunity__c = insertedOpp.Id, OwnerId = UserInfo.getUserId(),
            Status__c = 'Completed - Rejected', Review_Cycle__c = 1
        );
        insert existingChk;
        // NOTE: not pre-seeding a Status__c = 'Rejected' item here. A validation rule
        // on Booking_Verification_Checklist_Item__c requires a Rejection_Reason__c value
        // whenever Status__c = 'Rejected', but that field doesn't exist on the object at
        // all — so no value can ever satisfy it. That makes the itemsToReset sub-branch
        // of the resubmission logic untestable until that field is created; this test
        // still covers the header-level reset (Status__c/Review_Cycle__c), which is the
        // part that is reachable.

        Opportunity oldOpp = new Opportunity(Id = insertedOpp.Id, StageName = '1 - Qualification');
        Opportunity newOpp = new Opportunity(
            Id = insertedOpp.Id, StageName = 'Booking Verification', Business_Unit__c = 'RIM',
            Type = 'New Deal', Billing_Country__c = country.Id
        );

        Test.startTest();
        BookingVerificationChecklistGenerator.generateAfterSave(
            new List<Opportunity>{newOpp}, new Map<Id, Opportunity>{insertedOpp.Id => oldOpp}
        );
        Test.stopTest();

        Booking_Verification_Checklist__c reloaded = [
            SELECT Status__c, Review_Cycle__c FROM Booking_Verification_Checklist__c WHERE Id = :existingChk.Id
        ];
        System.assertEquals('Draft', reloaded.Status__c, 'Resubmission should reset the header to Draft');
        System.assertEquals(2, reloaded.Review_Cycle__c, 'Resubmission should increment the review cycle');

    }

    // No candidate Opportunities (none moving into Booking Verification) — the method
    // should return immediately without doing any further work.
    @isTest
    static void test_generateAfterSave_NoCandidates_ReturnsEarly() {
        Account acc = testAccount();
        Opportunity insertedOpp = testOpportunity(acc.Id, 'NoCandidate');

        Opportunity sameStageOpp = new Opportunity(Id = insertedOpp.Id, StageName = '1 - Qualification');
        Opportunity oldOpp = new Opportunity(Id = insertedOpp.Id, StageName = '1 - Qualification');

        Test.startTest();
        BookingVerificationChecklistGenerator.generateAfterSave(
            new List<Opportunity>{sameStageOpp}, new Map<Id, Opportunity>{insertedOpp.Id => oldOpp}
        );
        Test.stopTest();

        List<Booking_Verification_Checklist__c> checklists = [
            SELECT Id FROM Booking_Verification_Checklist__c WHERE Opportunity__c = :insertedOpp.Id
        ];
        System.assertEquals(0, checklists.size(), 'No checklist should be created when stage does not change to Booking Verification');
    }
}