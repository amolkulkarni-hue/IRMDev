@isTest
private class BookingVerifChecklistGeneratorTest {

    // AccountHelper.preventAccountCreation rejects Account inserts from any profile outside the
    // IM_Admin_Profiles label, so these tests can't depend on whichever user happens to run them.
    // IM_Custom Sys Admin is on that list and carries Modify All Data, which covers every object
    // touched here. The user also gets the Booking Verification Specialists PSG so it runs with the
    // same permission sets as a real BV team member. The username is randomized so parallel runs
    // never collide.
    private static User testRunnerUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin'];
        User u = new User(
            Alias = 'bvcgtest',
            Email = 'bvcgtest@malkosus.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'BVCG',
            LastName = 'TestRunner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'bvcgtest.' + Math.abs(Crypto.getRandomLong()) + '@malkosus.com',
            IsActive = true,
            Country = 'United Kingdom'
        );
        insert u;

        PermissionSetGroup bvPsg = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'Booking_Verification_Specialists_PSG'];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetGroupId = bvPsg.Id);
        return u;
    }

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

    // Doc_Type__c is a dependent picklist controlled by Doc_Category__c, so every Document-type
    // item created here needs a matching category — every test in this class uses the
    // Compliance, Risk & Privacy doc types, so it's hardcoded rather than threaded through as a
    // parameter.
    private static Booking_Verification_Template_Item__c testDocTemplateItem(Id templateId, String name, String docType, Boolean mandatory, Decimal seq) {
        Booking_Verification_Template_Item__c item = new Booking_Verification_Template_Item__c(
            Booking_Verification_Template__c = templateId, Name = name, Type__c = 'Document',
            Doc_Type__c = docType, Doc_Category__c = 'Compliance, Risk & Privacy',
            Is_Mandatory__c = mandatory, Sequence_Number__c = seq
        );
        insert item;
        return item;
    }

    // Matched template found: header, a Document-type item (docsToInsert branch), and a
    // Task-type item (the "when else" branch) all get created.
    @isTest
    static void test_generateAfterSave_MatchedTemplate_CreatesHeaderAndChildren() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'Match');
            IM_Country__c country = testCountry('US');

            Booking_Verification_Template__c tmpl = testTemplate('RIM', 'New Deal', 'United States');
            insert new List<Booking_Verification_Template_Item__c>{
                new Booking_Verification_Template_Item__c(
                    Booking_Verification_Template__c = tmpl.Id, Name = 'Doc Item', Type__c = 'Document',
                    Doc_Type__c = 'Customer Security Questionnaire', Doc_Category__c = 'Compliance, Risk & Privacy',
                    Is_Mandatory__c = true, Sequence_Number__c = 1
                ),
                new Booking_Verification_Template_Item__c(
                    Booking_Verification_Template__c = tmpl.Id, Name = 'Task Item', Type__c = 'Task',
                    Is_Mandatory__c = false, Sequence_Number__c = 2
                )
            };
            publishTemplate(tmpl.Id);

            Opportunity newOpp = new Opportunity(
                Id = insertedOpp.Id, StageName = 'Solutioning', Business_Unit__c = 'RIM',
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
                SELECT Id, Doc_Type__c, Doc_Category__c FROM Document_Checklist__c WHERE Opportunity__c = :insertedOpp.Id
            ];
            System.assertEquals(1, docs.size(), 'Only the Document-type item should also create a Document_Checklist__c');
            System.assertEquals('Customer Security Questionnaire', docs[0].Doc_Type__c, 'Generated document should carry the template item\'s Doc_Type__c');
            System.assertEquals('Compliance, Risk & Privacy', docs[0].Doc_Category__c, 'Generated document should carry the Doc_Category__c derived from its Doc_Type__c');
        }
    }

    // No published template matches this Business Unit / Deal Type / Country combo —
    // a warning Chatter post is created instead.
    @isTest
    static void test_generateAfterSave_NoMatchingTemplate_PostsChatterWarning() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'NoMatch');
            IM_Country__c country = testCountry('ZZ');

            Opportunity newOpp = new Opportunity(
                Id = insertedOpp.Id, StageName = 'Solutioning', Business_Unit__c = 'ALM',
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
    }

    // An Opportunity whose checklist was rejected, then regressed and re-advanced into Booking
    // Verification, should reset the existing header and its previously-rejected items back to
    // Draft instead of creating a duplicate.
    @isTest
    static void test_generateAfterSave_ExistingChecklist_TriggersResubmission() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'Resub');
            IM_Country__c country = testCountry('CA');

            Booking_Verification_Checklist__c existingChk = new Booking_Verification_Checklist__c(
                Opportunity__c = insertedOpp.Id, OwnerId = UserInfo.getUserId(),
                Status__c = 'Completed - Rejected', Review_Cycle__c = 1
            );
            insert existingChk;

            Booking_Verification_Checklist_Item__c rejectedItem = new Booking_Verification_Checklist_Item__c(
                Booking_Verification_Checklist__c = existingChk.Id, Opportunity__c = insertedOpp.Id,
                Checklist_Item_Name__c = 'Item 1', Status__c = 'Rejected',
                Rejection_Reason__c = 'Missing Customer Signature',
                Comments__c = 'Customer signature page is missing from the uploaded contract.',
                Is_Mandatory__c = true
            );
            insert rejectedItem;

            Opportunity oldOpp = new Opportunity(Id = insertedOpp.Id, StageName = 'Negotiation');
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

            Booking_Verification_Checklist_Item__c reloadedItem = [
                SELECT Status__c FROM Booking_Verification_Checklist_Item__c WHERE Id = :rejectedItem.Id
            ];
            System.assertEquals('Draft', reloadedItem.Status__c, 'A previously Rejected item should reset to Draft on resubmission');
        }
    }

    // Entering Booking Verification with an existing checklist that is Draft/In Progress/Completed
    // (i.e. never rejected) must NOT trigger a reset — otherwise every deal's ordinary first-time
    // entry into Booking Verification would spuriously bump Review_Cycle__c.
    @isTest
    static void test_generateAfterSave_BookingVerification_DraftStatus_NoResubmission() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'BVDraft');

            Booking_Verification_Checklist__c existingChk = new Booking_Verification_Checklist__c(
                Opportunity__c = insertedOpp.Id, OwnerId = UserInfo.getUserId(), Status__c = 'Draft'
            );
            insert existingChk;

            Opportunity oldOpp = new Opportunity(Id = insertedOpp.Id, StageName = 'Negotiation');
            Opportunity newOpp = new Opportunity(Id = insertedOpp.Id, StageName = 'Booking Verification');

            Test.startTest();
            BookingVerificationChecklistGenerator.generateAfterSave(
                new List<Opportunity>{newOpp}, new Map<Id, Opportunity>{insertedOpp.Id => oldOpp}
            );
            Test.stopTest();

            Booking_Verification_Checklist__c reloaded = [
                SELECT Status__c, Review_Cycle__c FROM Booking_Verification_Checklist__c WHERE Id = :existingChk.Id
            ];
            System.assertEquals('Draft', reloaded.Status__c, 'A never-rejected Draft checklist should be left untouched');
            System.assertEquals(null, reloaded.Review_Cycle__c, 'Review_Cycle__c should not be bumped for a normal first-time entry');
        }
    }

    // Same as above for a checklist actively In Progress — still not eligible for resubmission.
    @isTest
    static void test_generateAfterSave_BookingVerification_InProgressStatus_NoResubmission() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'BVInProgress');

            Booking_Verification_Checklist__c existingChk = new Booking_Verification_Checklist__c(
                Opportunity__c = insertedOpp.Id, OwnerId = UserInfo.getUserId(), Status__c = 'In Progress'
            );
            insert existingChk;

            Opportunity oldOpp = new Opportunity(Id = insertedOpp.Id, StageName = 'Negotiation');
            Opportunity newOpp = new Opportunity(Id = insertedOpp.Id, StageName = 'Booking Verification');

            Test.startTest();
            BookingVerificationChecklistGenerator.generateAfterSave(
                new List<Opportunity>{newOpp}, new Map<Id, Opportunity>{insertedOpp.Id => oldOpp}
            );
            Test.stopTest();

            Booking_Verification_Checklist__c reloaded = [
                SELECT Status__c, Review_Cycle__c FROM Booking_Verification_Checklist__c WHERE Id = :existingChk.Id
            ];
            System.assertEquals('In Progress', reloaded.Status__c, 'An In Progress checklist should be left untouched');
            System.assertEquals(null, reloaded.Review_Cycle__c, 'Review_Cycle__c should not be bumped');
        }
    }

    // Same as above for a checklist already Completed (approved) — still not eligible for
    // resubmission.
    @isTest
    static void test_generateAfterSave_BookingVerification_CompletedStatus_NoResubmission() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'BVCompleted');

            Booking_Verification_Checklist__c existingChk = new Booking_Verification_Checklist__c(
                Opportunity__c = insertedOpp.Id, OwnerId = UserInfo.getUserId(), Status__c = 'Completed'
            );
            insert existingChk;

            Opportunity oldOpp = new Opportunity(Id = insertedOpp.Id, StageName = 'Negotiation');
            Opportunity newOpp = new Opportunity(Id = insertedOpp.Id, StageName = 'Booking Verification');

            Test.startTest();
            BookingVerificationChecklistGenerator.generateAfterSave(
                new List<Opportunity>{newOpp}, new Map<Id, Opportunity>{insertedOpp.Id => oldOpp}
            );
            Test.stopTest();

            Booking_Verification_Checklist__c reloaded = [
                SELECT Status__c, Review_Cycle__c FROM Booking_Verification_Checklist__c WHERE Id = :existingChk.Id
            ];
            System.assertEquals('Completed', reloaded.Status__c, 'A Completed checklist should be left untouched');
            System.assertEquals(null, reloaded.Review_Cycle__c, 'Review_Cycle__c should not be bumped');
        }
    }

    // An Opportunity reaching Booking Verification with no checklist at all (e.g. it never passed
    // through Solutioning) should be a no-op — out of scope, matches today's lack of a fallback.
    @isTest
    static void test_generateAfterSave_BookingVerification_NoExistingChecklist_NoError() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'BVNoChecklist');

            Opportunity oldOpp = new Opportunity(Id = insertedOpp.Id, StageName = 'Negotiation');
            Opportunity newOpp = new Opportunity(Id = insertedOpp.Id, StageName = 'Booking Verification');

            Test.startTest();
            BookingVerificationChecklistGenerator.generateAfterSave(
                new List<Opportunity>{newOpp}, new Map<Id, Opportunity>{insertedOpp.Id => oldOpp}
            );
            Test.stopTest();

            List<Booking_Verification_Checklist__c> checklists = [
                SELECT Id FROM Booking_Verification_Checklist__c WHERE Opportunity__c = :insertedOpp.Id
            ];
            System.assertEquals(0, checklists.size(), 'No checklist should be created or found when entering Booking Verification with none pre-existing');
        }
    }

    // Re-entering Solutioning with an existing checklist must not create a duplicate header AND
    // must not trigger a resubmission reset — resubmission only fires on entering Booking
    // Verification now.
    @isTest
    static void test_generateAfterSave_ReenterSolutioning_ExistingChecklist_NoNewHeaderNoResubmission() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'ReenterSolutioning');
            IM_Country__c country = testCountry('US');

            Booking_Verification_Checklist__c existingChk = new Booking_Verification_Checklist__c(
                Opportunity__c = insertedOpp.Id, OwnerId = UserInfo.getUserId(),
                Status__c = 'Completed - Rejected', Review_Cycle__c = 1
            );
            insert existingChk;

            Opportunity oldOpp = new Opportunity(Id = insertedOpp.Id, StageName = 'Booking Verification');
            Opportunity newOpp = new Opportunity(
                Id = insertedOpp.Id, StageName = 'Solutioning', Business_Unit__c = 'RIM',
                Type = 'New Deal', Billing_Country__c = country.Id
            );

            Test.startTest();
            BookingVerificationChecklistGenerator.generateAfterSave(
                new List<Opportunity>{newOpp}, new Map<Id, Opportunity>{insertedOpp.Id => oldOpp}
            );
            Test.stopTest();

            List<Booking_Verification_Checklist__c> checklists = [
                SELECT Status__c, Review_Cycle__c FROM Booking_Verification_Checklist__c WHERE Opportunity__c = :insertedOpp.Id
            ];
            System.assertEquals(1, checklists.size(), 'Re-entering Solutioning should not create a duplicate checklist');
            System.assertEquals('Completed - Rejected', checklists[0].Status__c, 'Re-entering Solutioning should not trigger a resubmission reset');
            System.assertEquals(1, checklists[0].Review_Cycle__c, 'Review_Cycle__c should not be bumped on re-entering Solutioning');
        }
    }

    // No candidate Opportunities (none moving into Booking Verification) — the method
    // should return immediately without doing any further work.
    @isTest
    static void test_generateAfterSave_NoCandidates_ReturnsEarly() {
        System.runAs(testRunnerUser()) {
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

    // A Document Checklist created on the Opportunity before this checklist existed (e.g. during
    // Qualification) shares the new checklist's matching Document-type Doc_Type__c — it should be
    // linked to the new header/template item instead of a duplicate being generated, and the
    // template's Is_Mandatory__c should promote the existing document's IsRequired__c.
    @isTest
    static void test_generateAfterSave_LinksExistingUnassociatedDocument_NoDuplicateCreated() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'LinkExisting');
            IM_Country__c country = testCountry('US');

            Booking_Verification_Template__c tmpl = testTemplate('RIM', 'New Deal', 'United States');
            Booking_Verification_Template_Item__c docItem = testDocTemplateItem(tmpl.Id, 'Doc Item', 'Customer Security Questionnaire', true, 1);
            publishTemplate(tmpl.Id);

            Document_Checklist__c existingDoc = new Document_Checklist__c(
                Opportunity__c = insertedOpp.Id, Doc_Type__c = 'Customer Security Questionnaire',
                Doc_Category__c = 'Compliance, Risk & Privacy', Status__c = 'Draft', IsRequired__c = false
            );
            insert existingDoc;

            Opportunity newOpp = new Opportunity(
                Id = insertedOpp.Id, StageName = 'Solutioning', Business_Unit__c = 'RIM',
                Type = 'New Deal', Billing_Country__c = country.Id
            );

            Test.startTest();
            BookingVerificationChecklistGenerator.generateAfterSave(new List<Opportunity>{newOpp}, null);
            Test.stopTest();

            List<Document_Checklist__c> docs = [
                SELECT Id, Booking_Verification_Checklist__c, Booking_Verification_Checklist_Item__c, IsRequired__c
                FROM Document_Checklist__c WHERE Opportunity__c = :insertedOpp.Id
            ];
            System.assertEquals(1, docs.size(), 'The pre-existing document should be reused, not duplicated');
            System.assertNotEquals(null, docs[0].Booking_Verification_Checklist__c, 'Existing document should be linked to the new checklist');

            Booking_Verification_Checklist_Item__c generatedItem = [
                SELECT Id FROM Booking_Verification_Checklist_Item__c WHERE Template_Item__c = :docItem.Id AND Opportunity__c = :insertedOpp.Id
            ];
            System.assertEquals(generatedItem.Id, docs[0].Booking_Verification_Checklist_Item__c, 'Existing document should be linked to the checklist item generated from the matching template item');
            System.assertEquals(true, docs[0].IsRequired__c, 'A mandatory template item should promote IsRequired__c on the linked document');
        }
    }

    // The pre-existing document's Doc_Type__c does not match the template's Document item —
    // it must be left alone and a new Document_Checklist__c generated as before.
    @isTest
    static void test_generateAfterSave_NonMatchingDocType_CreatesNewDocument() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'NonMatch');
            IM_Country__c country = testCountry('US');

            Booking_Verification_Template__c tmpl = testTemplate('RIM', 'New Deal', 'United States');
            testDocTemplateItem(tmpl.Id, 'Doc Item', 'Customer Security Questionnaire', true, 1);
            publishTemplate(tmpl.Id);

            Document_Checklist__c existingDoc = new Document_Checklist__c(
                Opportunity__c = insertedOpp.Id, Doc_Type__c = 'Completed Security Questionnaire',
                Doc_Category__c = 'Compliance, Risk & Privacy', Status__c = 'Draft'
            );
            insert existingDoc;

            Opportunity newOpp = new Opportunity(
                Id = insertedOpp.Id, StageName = 'Solutioning', Business_Unit__c = 'RIM',
                Type = 'New Deal', Billing_Country__c = country.Id
            );

            Test.startTest();
            BookingVerificationChecklistGenerator.generateAfterSave(new List<Opportunity>{newOpp}, null);
            Test.stopTest();

            List<Document_Checklist__c> docs = [
                SELECT Id FROM Document_Checklist__c WHERE Opportunity__c = :insertedOpp.Id
            ];
            System.assertEquals(2, docs.size(), 'A new document should be created since the doc type does not match');

            Document_Checklist__c reloadedExisting = [
                SELECT Booking_Verification_Checklist__c FROM Document_Checklist__c WHERE Id = :existingDoc.Id
            ];
            System.assertEquals(null, reloadedExisting.Booking_Verification_Checklist__c, 'Non-matching document should remain unassociated');
        }
    }

    // A template Document item with a blank Doc_Type__c (today's default state — see the
    // Booking Verification Template data-prerequisite noted in the plan) can never match anything —
    // a new Document_Checklist__c is still generated, matching today's behavior.
    @isTest
    static void test_generateAfterSave_BlankTemplateDocType_CreatesNewDocument() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'BlankType');
            IM_Country__c country = testCountry('US');

            Booking_Verification_Template__c tmpl = testTemplate('RIM', 'New Deal', 'United States');
            insert new Booking_Verification_Template_Item__c(
                Booking_Verification_Template__c = tmpl.Id, Name = 'Doc Item', Type__c = 'Document',
                Is_Mandatory__c = true, Sequence_Number__c = 1
            );
            publishTemplate(tmpl.Id);

            Document_Checklist__c existingDoc = new Document_Checklist__c(
                Opportunity__c = insertedOpp.Id, Doc_Type__c = 'Customer Security Questionnaire',
                Doc_Category__c = 'Compliance, Risk & Privacy', Status__c = 'Draft'
            );
            insert existingDoc;

            Opportunity newOpp = new Opportunity(
                Id = insertedOpp.Id, StageName = 'Solutioning', Business_Unit__c = 'RIM',
                Type = 'New Deal', Billing_Country__c = country.Id
            );

            Test.startTest();
            BookingVerificationChecklistGenerator.generateAfterSave(new List<Opportunity>{newOpp}, null);
            Test.stopTest();

            List<Document_Checklist__c> docs = [
                SELECT Id FROM Document_Checklist__c WHERE Opportunity__c = :insertedOpp.Id
            ];
            System.assertEquals(2, docs.size(), 'A blank template Doc Type should never match — a new document is still created');
        }
    }

    // A document marked Archived/Do Not Use should not be reused even if its Doc_Type__c matches.
    @isTest
    static void test_generateAfterSave_ArchivedDocument_Ignored() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'Archived');
            IM_Country__c country = testCountry('US');

            Booking_Verification_Template__c tmpl = testTemplate('RIM', 'New Deal', 'United States');
            testDocTemplateItem(tmpl.Id, 'Doc Item', 'Customer Security Questionnaire', true, 1);
            publishTemplate(tmpl.Id);

            Document_Checklist__c archivedDoc = new Document_Checklist__c(
                Opportunity__c = insertedOpp.Id, Doc_Type__c = 'Customer Security Questionnaire',
                Doc_Category__c = 'Compliance, Risk & Privacy',
                Status__c = 'Archived/Do Not Use', Notes__c = 'Retired during scoping'
            );
            insert archivedDoc;

            Opportunity newOpp = new Opportunity(
                Id = insertedOpp.Id, StageName = 'Solutioning', Business_Unit__c = 'RIM',
                Type = 'New Deal', Billing_Country__c = country.Id
            );

            Test.startTest();
            BookingVerificationChecklistGenerator.generateAfterSave(new List<Opportunity>{newOpp}, null);
            Test.stopTest();

            List<Document_Checklist__c> docs = [
                SELECT Id FROM Document_Checklist__c WHERE Opportunity__c = :insertedOpp.Id
            ];
            System.assertEquals(2, docs.size(), 'An archived document should not be reused — a new document is created');

            Document_Checklist__c reloadedArchived = [
                SELECT Booking_Verification_Checklist__c FROM Document_Checklist__c WHERE Id = :archivedDoc.Id
            ];
            System.assertEquals(null, reloadedArchived.Booking_Verification_Checklist__c, 'Archived document should remain unassociated');
        }
    }

    // A document already linked to a Booking Verification Checklist (here, one on an unrelated
    // Opportunity, standing in for "already claimed") is excluded from matching even though its
    // Doc_Type__c matches — the SOQL filter only considers unlinked documents.
    @isTest
    static void test_generateAfterSave_DocLinkedToAnotherChecklist_Ignored() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'AlreadyLinked');
            IM_Country__c country = testCountry('US');

            Account otherAcc = testAccount();
            Opportunity otherOpp = testOpportunity(otherAcc.Id, 'AlreadyLinkedOther');
            Booking_Verification_Checklist__c otherChecklist = new Booking_Verification_Checklist__c(
                Opportunity__c = otherOpp.Id, OwnerId = UserInfo.getUserId(), Status__c = 'Draft'
            );
            insert otherChecklist;

            Booking_Verification_Template__c tmpl = testTemplate('RIM', 'New Deal', 'United States');
            testDocTemplateItem(tmpl.Id, 'Doc Item', 'Customer Security Questionnaire', true, 1);
            publishTemplate(tmpl.Id);

            Document_Checklist__c linkedDoc = new Document_Checklist__c(
                Opportunity__c = insertedOpp.Id, Doc_Type__c = 'Customer Security Questionnaire',
                Doc_Category__c = 'Compliance, Risk & Privacy',
                Status__c = 'Draft', Booking_Verification_Checklist__c = otherChecklist.Id
            );
            insert linkedDoc;

            Opportunity newOpp = new Opportunity(
                Id = insertedOpp.Id, StageName = 'Solutioning', Business_Unit__c = 'RIM',
                Type = 'New Deal', Billing_Country__c = country.Id
            );

            Test.startTest();
            BookingVerificationChecklistGenerator.generateAfterSave(new List<Opportunity>{newOpp}, null);
            Test.stopTest();

            List<Document_Checklist__c> docs = [
                SELECT Id FROM Document_Checklist__c WHERE Opportunity__c = :insertedOpp.Id
            ];
            System.assertEquals(2, docs.size(), 'A new document should be created since the existing one is already claimed elsewhere');

            Document_Checklist__c reloadedLinked = [
                SELECT Booking_Verification_Checklist__c FROM Document_Checklist__c WHERE Id = :linkedDoc.Id
            ];
            System.assertEquals(otherChecklist.Id, reloadedLinked.Booking_Verification_Checklist__c, 'Already-linked document should keep its original link');
        }
    }

    // Two pre-existing documents share the same Doc Type as one template item — both should be
    // linked to that same Template Item, and no duplicate Document_Checklist__c is created.
    @isTest
    static void test_generateAfterSave_MultipleMatchingDocuments_AllLinkedToSameTemplateItem() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'MultiMatch');
            IM_Country__c country = testCountry('US');

            Booking_Verification_Template__c tmpl = testTemplate('RIM', 'New Deal', 'United States');
            Booking_Verification_Template_Item__c docItem = testDocTemplateItem(tmpl.Id, 'Doc Item', 'Customer Security Questionnaire', true, 1);
            publishTemplate(tmpl.Id);

            Document_Checklist__c doc1 = new Document_Checklist__c(
                Opportunity__c = insertedOpp.Id, Doc_Type__c = 'Customer Security Questionnaire',
                Doc_Category__c = 'Compliance, Risk & Privacy', Status__c = 'Draft'
            );
            Document_Checklist__c doc2 = new Document_Checklist__c(
                Opportunity__c = insertedOpp.Id, Doc_Type__c = 'Customer Security Questionnaire',
                Doc_Category__c = 'Compliance, Risk & Privacy', Status__c = 'Draft'
            );
            insert new List<Document_Checklist__c>{doc1, doc2};

            Opportunity newOpp = new Opportunity(
                Id = insertedOpp.Id, StageName = 'Solutioning', Business_Unit__c = 'RIM',
                Type = 'New Deal', Billing_Country__c = country.Id
            );

            Test.startTest();
            BookingVerificationChecklistGenerator.generateAfterSave(new List<Opportunity>{newOpp}, null);
            Test.stopTest();

            List<Document_Checklist__c> docs = [
                SELECT Id, Booking_Verification_Checklist__c, Booking_Verification_Checklist_Item__c
                FROM Document_Checklist__c WHERE Opportunity__c = :insertedOpp.Id
            ];
            System.assertEquals(2, docs.size(), 'No duplicate document should be created — both pre-existing documents are reused');

            Booking_Verification_Checklist_Item__c generatedItem = [
                SELECT Id FROM Booking_Verification_Checklist_Item__c WHERE Template_Item__c = :docItem.Id AND Opportunity__c = :insertedOpp.Id
            ];
            for (Document_Checklist__c dc : docs) {
                System.assertNotEquals(null, dc.Booking_Verification_Checklist__c, 'Every matching document should be linked');
                System.assertEquals(generatedItem.Id, dc.Booking_Verification_Checklist_Item__c, 'Every matching document should be linked to the same generated checklist item');
            }
        }
    }

    // On the resubmission path (Opportunity re-enters Booking Verification with a rejected
    // checklist that already exists), a document added on the Opportunity after the checklist
    // was created should still get swept up and linked to the existing (reset) header.
    @isTest
    static void test_generateAfterSave_ResubmissionPath_LinksExistingDocument() {
        System.runAs(testRunnerUser()) {
            Account acc = testAccount();
            Opportunity insertedOpp = testOpportunity(acc.Id, 'ResubLink');

            Booking_Verification_Template__c tmpl = testTemplate('RIM', 'New Deal', 'United States');
            Booking_Verification_Template_Item__c docItem = testDocTemplateItem(tmpl.Id, 'Doc Item', 'Customer Security Questionnaire', true, 1);

            Booking_Verification_Checklist__c existingChk = new Booking_Verification_Checklist__c(
                Opportunity__c = insertedOpp.Id, OwnerId = UserInfo.getUserId(),
                Status__c = 'Completed - Rejected', Review_Cycle__c = 1, Template__c = tmpl.Id
            );
            insert existingChk;

            // The checklist item generated from the template's Document item when the checklist was
            // first created — needed so the resubmission path has a real Checklist Item to link the
            // newly-added document to.
            Booking_Verification_Checklist_Item__c existingItem = new Booking_Verification_Checklist_Item__c(
                Booking_Verification_Checklist__c = existingChk.Id, Opportunity__c = insertedOpp.Id,
                Checklist_Item_Name__c = docItem.Name, Status__c = 'Approved',
                Is_Mandatory__c = true, Template_Item__c = docItem.Id
            );
            insert existingItem;

            Document_Checklist__c newlyAddedDoc = new Document_Checklist__c(
                Opportunity__c = insertedOpp.Id, Doc_Type__c = 'Customer Security Questionnaire',
                Doc_Category__c = 'Compliance, Risk & Privacy', Status__c = 'Draft'
            );
            insert newlyAddedDoc;

            Opportunity oldOpp = new Opportunity(Id = insertedOpp.Id, StageName = 'Negotiation');
            Opportunity newOpp = new Opportunity(Id = insertedOpp.Id, StageName = 'Booking Verification');

            Test.startTest();
            BookingVerificationChecklistGenerator.generateAfterSave(
                new List<Opportunity>{newOpp}, new Map<Id, Opportunity>{insertedOpp.Id => oldOpp}
            );
            Test.stopTest();

            Document_Checklist__c reloaded = [
                SELECT Booking_Verification_Checklist__c, Booking_Verification_Checklist_Item__c FROM Document_Checklist__c WHERE Id = :newlyAddedDoc.Id
            ];
            System.assertEquals(existingChk.Id, reloaded.Booking_Verification_Checklist__c, 'Document should be linked to the existing (reset) checklist');
            System.assertEquals(existingItem.Id, reloaded.Booking_Verification_Checklist_Item__c, 'Document should be linked to the existing checklist item generated from the matching template item');
        }
    }
}