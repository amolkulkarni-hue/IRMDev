/**
 * IRM_ExitValidationTest
 * US-1502: Case Exit Document Validation via Case_Exit_Document_Validation_Flow
 *
 * Flow under test: Case_Exit_Document_Validation_Flow (Before Update — Case)
 * Must be ACTIVE in Setup → Flows before running.
 *
 * Flow logic: When Case Status changes to a Closed value, the flow checks if any
 * Document_Checklist__c records linked via Opportunity__c are not Final.
 * If non-Final docs exist, it calls addError() to block the save.
 */
@IsTest
private class IRM_ExitValidationTest {

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
        insert new List<SVStatus__c>{
            new SVStatus__c(Name = 'New Deal',   Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Renewal',    Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Add-On',     Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Expansion',  Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId())
        };
        Account acc = new Account(
            Name = 'IRM Exit Validation Test Co',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;
        // Case VR: "Please enter a value for either the Contact or IM Employee"
        insert new Contact(LastName = 'CaseContact', AccountId = acc.Id);
    }

    private static Account getAccount() {
        return [SELECT Id FROM Account LIMIT 1];
    }

    private static Id getContactId() {
        return [SELECT Id FROM Contact LIMIT 1].Id;
    }

    private static Opportunity makeOpp() {
        Opportunity opp = new Opportunity(
            Name = 'Exit Validation Opp', AccountId = getAccount().Id,
            Type = 'New Deal', StageName = 'Qualification', CloseDate = Date.today().addDays(30), Pricebook2Id = Test.getStandardPricebookId(), Amount = 600000,
            Bypass_Validation__c = true
        );
        insert opp;
        return opp;
    }

    // ── US-1502 AC1: Case close BLOCKED with non-Final docs ──────────────────

    @IsTest
    static void test_caseCloseBlockedWithDraftDoc() {
        Opportunity opp = makeOpp();

        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'Blocked Close Test', Status = 'In Progress', Opportunity__c = opp.Id
        );
        insert c;

        Document_Checklist__c doc = new Document_Checklist__c(
            Case__c = c.Id, Status__c = 'Draft', Document_Category__c = 'Scoping & Technical'
        );
        insert doc;

        System.debug('TEST: Attempting to close Case to Closed - Approved with 1 Draft doc linked to Case. Expect DML exception.');
        System.debug('Case Id=' + c.Id + ' | Opp Id=' + opp.Id + ' | Doc Id=' + doc.Id + ' | Doc Status=' + doc.Status__c);

        Test.startTest();
        Boolean blocked = false;
        String errorMsg = '';
        try {
            c.Status = 'Closed - Approved';
            update c;
        } catch (DmlException e) {
            blocked = true;
            errorMsg = e.getMessage();
            System.debug('EXCEPTION CAUGHT (expected): ' + errorMsg);
        }
        Test.stopTest();

        System.debug('RESULT: blocked=' + blocked + ' | errorMsg=' + errorMsg);

        System.assertEquals(true, blocked,
            'US-1502: Closing Case to Closed - Approved with a Draft Document Checklist should throw DmlException. '
            + 'If not blocked, check Case_Exit_Document_Validation_Flow is active and checks Opportunity__c.Document_Checklist__c records where Status != Final.');
    }

    @IsTest
    static void test_caseCloseBlockedWithArchivedDoc() {
        Opportunity opp = makeOpp();

        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'Archived Doc Block Test', Status = 'In Progress', Opportunity__c = opp.Id
        );
        insert c;

        // Status 'Rejected' used here because 'Archived' is not yet deployed in org schema (Draft/Approved/Rejected).
        // 'Rejected' maps to the same intent: doc is not in a final approved state, so close should be blocked.
        Document_Checklist__c doc = new Document_Checklist__c(
            Case__c = c.Id, Status__c = 'Archived/Do Not Use', Notes__c = 'Archiving document.', Document_Category__c = 'Scoping & Technical'
        );
        insert doc;

        System.debug('TEST: Attempting close with 1 Rejected doc (maps to Archived in future schema). Not Final/Approved — expect block.');

        Test.startTest();
        Boolean blocked = false;
        String errorMsg = '';
        try {
            c.Status = 'Closed - Approved';
            update c;
        } catch (DmlException e) {
            blocked = true;
            errorMsg = e.getMessage();
            System.debug('EXCEPTION CAUGHT (expected): ' + errorMsg);
        }
        Test.stopTest();

        System.debug('RESULT: blocked=' + blocked);

        System.assertEquals(true, blocked,
            'US-1502: Rejected status (maps to Archived in future schema) is not Final/Approved — case close should still be blocked. Error: ' + errorMsg);
    }

    // ── US-1502 AC2: Case close ALLOWED when all docs are Final ──────────────

    @IsTest
    static void test_caseCloseAllowedWhenAllDocsFinal() {
        Opportunity opp = makeOpp();

        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'Allowed Close Test', Status = 'In Progress', Opportunity__c = opp.Id
        );
        insert c;

        Document_Checklist__c doc = new Document_Checklist__c(
            Case__c = c.Id, Status__c = 'Final', Submitted_Date__c = Date.today(), Document_Category__c = 'Scoping & Technical'
        );
        insert doc;

        System.debug('TEST: Attempting close with 1 Approved doc (maps to Final in future schema). Expect SUCCESS (no exception or flow not yet deployed).');

        Test.startTest();
        Boolean blocked = false;
        String errorMsg = '';
        try {
            c.Status = 'Closed - Approved';
            update c;
        } catch (DmlException e) {
            blocked = true;
            errorMsg = e.getMessage();
            System.debug('UNEXPECTED EXCEPTION: ' + errorMsg);
        }
        Test.stopTest();

        System.debug('RESULT: blocked=' + blocked);

        System.assertEquals(false, blocked,
            'US-1502: All docs are Final — case close should be allowed. Got unexpected DmlException: ' + errorMsg);
    }

    // ── US-1502 AC3: Case close ALLOWED with no linked docs ──────────────────

    @IsTest
    static void test_caseCloseAllowedWithNoLinkedDocs() {
        Opportunity opp = makeOpp();

        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'No Docs Close Test', Status = 'In Progress', Opportunity__c = opp.Id
        );
        insert c;
        // No Document_Checklist__c records inserted

        System.debug('TEST: Attempting close with NO Document_Checklist__c records on the Opp. Expect SUCCESS.');

        Test.startTest();
        Boolean blocked = false;
        String errorMsg = '';
        try {
            c.Status = 'Closed - Approved';
            update c;
        } catch (DmlException e) {
            blocked = true;
            errorMsg = e.getMessage();
            System.debug('UNEXPECTED EXCEPTION: ' + errorMsg);
        }
        Test.stopTest();

        System.debug('RESULT: blocked=' + blocked);

        System.assertEquals(false, blocked,
            'US-1502: No linked docs means nothing to block close — should succeed. Got: ' + errorMsg);
    }

    // ── US-1502 AC4: Case close ALLOWED when no linked Opportunity ────────────

    @IsTest
    static void test_caseCloseAllowedWithNoOpportunity() {
        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'No Opp Close Test', Status = 'In Progress'
            // No Opportunity__c
        );
        insert c;

        System.debug('TEST: Closing Case with no Opportunity__c. Expect SUCCESS — no docs to validate.');

        Test.startTest();
        Boolean blocked = false;
        String errorMsg = '';
        try {
            c.Status = 'Closed - Approved';
            update c;
        } catch (DmlException e) {
            blocked = true;
            errorMsg = e.getMessage();
            System.debug('UNEXPECTED EXCEPTION: ' + errorMsg);
        }
        Test.stopTest();

        System.debug('RESULT: blocked=' + blocked);

        System.assertEquals(false, blocked,
            'US-1502: Case without Opportunity should close freely. Got: ' + errorMsg);
    }

    // ── US-1502 AC5: Mixed docs — blocked if ANY are not Final ───────────────

    @IsTest
    static void test_caseCloseBlockedWhenMixedFinalAndDraft() {
        Opportunity opp = makeOpp();

        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'Mixed Docs Close Test', Status = 'In Progress', Opportunity__c = opp.Id
        );
        insert c;

        insert new List<Document_Checklist__c>{
            new Document_Checklist__c(Case__c = c.Id, Status__c = 'Final', Submitted_Date__c = Date.today(), Document_Category__c = 'Scoping & Technical'),
            new Document_Checklist__c(Case__c = c.Id, Status__c = 'Draft',                                   Document_Category__c = 'Scoping & Technical')
        };

        System.debug('TEST: 1 Final + 1 Draft doc. Should still be blocked (not ALL are Final).');

        Test.startTest();
        Boolean blocked = false;
        String errorMsg = '';
        try {
            c.Status = 'Closed - Approved';
            update c;
        } catch (DmlException e) {
            blocked = true;
            errorMsg = e.getMessage();
            System.debug('EXCEPTION CAUGHT (expected): ' + errorMsg);
        }
        Test.stopTest();

        System.debug('RESULT: blocked=' + blocked);

        System.assertEquals(true, blocked,
            'US-1502: Mixed Final+Draft docs should still block close. Got blocked=' + blocked + ' error=' + errorMsg);
    }
}