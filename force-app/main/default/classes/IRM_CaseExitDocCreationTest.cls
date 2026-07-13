/**
 * IRM_CaseExitDocCreationTest
 * US-EXITDOC: Exit Document Checklist Auto-Creation on Case Insert
 *
 * Flow under test: Case_Exit_Doc_Checklist_Creation_Flow (After Insert — Case)
 * Also exercises: Case_Exit_Document_Validation_Flow (Before Update — Case)
 * Must be ACTIVE in Setup → Flows before running.
 *
 * Config: Case_Exit_Doc_Requirement__c records are inserted in @TestSetup
 * (custom object — DML allowed in tests, unlike Custom Metadata Types).
 */
@IsTest
private class IRM_CaseExitDocCreationTest {

    @TestSetup
    static void setup() {
        IM_Country__c testCountry = new IM_Country__c(Name = 'United States');
        insert testCountry;
        insert new IM_Alternative_Country_Name__c(
            IM_Country__c = testCountry.Id, Alternative_Name__c = 'United States'
        );
        insert new Country_Settings__c(Name = 'United States', Object_Name__c = 'Opportunity', SetupOwnerId = UserInfo.getOrganizationId());
        insert new List<Opportunity_Security__c>{
            new Opportunity_Security__c(Name = 'Primary CDE',          Field_Name__c = 'Primary_CDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'R', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Original Lead Owner',  Field_Name__c = 'IM_Original_Lead_Owner__c', Object_Name__c = 'Opportunity', Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Primary BDE',          Field_Name__c = 'Primary_BDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId())
        };
        insert new OpportunityProductSelection__c(Name = 'CloudSolutionsProduct',
            Product_Class_Name__c = 'Cloud', Product_Line_Name__c = 'Cloud Solutions');
        insert new List<SVStatus__c>{
            new SVStatus__c(Name = 'New Deal',   Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Renewal',    Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Add-On',     Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Expansion',  Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId())
        };
        Account acc = new Account(
            Name = 'IRM Exit Doc Creation Test Co',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;
        insert new Contact(LastName = 'ExitDocContact', AccountId = acc.Id);

        insert new Case_Exit_Doc_Requirement__c(
            Case_Record_Type_Dev_Name__c = 'Deal_Support',
            Case_Type__c                 = 'SA Assignment',
            Document_Category__c         = 'Scoping & Technical',
            Document_Type__c             = 'Technical Scoping Form',
            Is_Active__c                 = true
        );
    }

    private static Account getAccount() {
        return [SELECT Id FROM Account LIMIT 1];
    }

    private static Id getContactId() {
        return [SELECT Id FROM Contact LIMIT 1].Id;
    }

    private static Id getDealSupportRecordTypeId() {
        return [SELECT Id FROM RecordType WHERE DeveloperName = 'Deal_Support' AND SObjectType = 'Case'].Id;
    }

    // ── US-EXITDOC AC1/AC2: Draft checklists created on Case insert ──────────

    @IsTest
    static void test_draftChecklistsCreatedOnCaseInsert() {
        Id rtId = getDealSupportRecordTypeId();

        Test.startTest();
        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'Exit Doc Creation Test', Status = 'New',
            RecordTypeId = rtId, Case_Type__c = 'SA Assignment'
        );
        insert c;
        Test.stopTest();

        List<Document_Checklist__c> docs = [
            SELECT Id, Status__c, IsRequired__c, DocumentType__c
            FROM Document_Checklist__c
            WHERE Case__c = :c.Id
        ];
        System.debug('TEST: docs found=' + docs.size());

        System.assert(!docs.isEmpty(),
            'US-EXITDOC AC1: Case_Exit_Doc_Checklist_Creation_Flow should auto-create Document_Checklist__c records linked to Case. Found 0. '
            + 'Check flow is Active and Case_Exit_Doc_Requirement__c config exists for Deal_Support + SA Assignment.');
        System.assertEquals('Draft', docs[0].Status__c,
            'US-EXITDOC AC2: Auto-created checklist should have Status__c = Draft. Got: ' + docs[0].Status__c);
        System.assertEquals(true, docs[0].IsRequired__c,
            'US-EXITDOC AC2: Auto-created checklist should have IsRequired__c = true.');
    }

    // ── US-EXITDOC AC1: Checklist count matches config record count ──────────

    @IsTest
    static void test_checklistCountMatchesConfigRecords() {
        Id rtId = getDealSupportRecordTypeId();

        // Add a second config record for the same Case type
        insert new Case_Exit_Doc_Requirement__c(
            Case_Record_Type_Dev_Name__c = 'Deal_Support',
            Case_Type__c                 = 'SA Assignment',
            Document_Category__c         = 'Scoping & Technical',
            Document_Type__c             = 'Complexity Assessment',
            Is_Active__c                 = true
        );

        Integer configCount = [SELECT COUNT() FROM Case_Exit_Doc_Requirement__c
            WHERE Case_Record_Type_Dev_Name__c = 'Deal_Support' AND Case_Type__c = 'SA Assignment' AND Is_Active__c = true];

        Test.startTest();
        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'Count Check Test', Status = 'New',
            RecordTypeId = rtId, Case_Type__c = 'SA Assignment'
        );
        insert c;
        Test.stopTest();

        Integer docCount = [SELECT COUNT() FROM Document_Checklist__c WHERE Case__c = :c.Id];
        System.debug('TEST: config records=' + configCount + ' | checklists created=' + docCount);

        System.assertEquals(configCount, docCount,
            'US-EXITDOC AC1: Number of Document_Checklist__c records should match active config records. Expected=' + configCount + ' Got=' + docCount);
    }

    // ── US-EXITDOC AC3: No checklists when no mapping exists ────────────────

    @IsTest
    static void test_noChecklistsWhenNoMappingExists() {
        Id rtId = getDealSupportRecordTypeId();

        Test.startTest();
        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'Unmapped Type Test', Status = 'New',
            RecordTypeId = rtId, Case_Type__c = 'Pricing'  // no config for this type
        );
        insert c;
        Test.stopTest();

        Integer docCount = [SELECT COUNT() FROM Document_Checklist__c WHERE Case__c = :c.Id];
        System.debug('TEST: docs created for unmapped Case Type=' + docCount);

        System.assertEquals(0, docCount,
            'US-EXITDOC AC3: No Document_Checklist__c should be created when no config exists for the Case Type. Got=' + docCount);
    }

    // ── US-EXITDOC: Inactive config records are skipped ─────────────────────

    @IsTest
    static void test_inactiveConfigRecordSkipped() {
        Id rtId = getDealSupportRecordTypeId();

        // Mark the default config record inactive
        Case_Exit_Doc_Requirement__c req = [SELECT Id FROM Case_Exit_Doc_Requirement__c LIMIT 1];
        req.Is_Active__c = false;
        update req;

        Test.startTest();
        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'Inactive Config Test', Status = 'New',
            RecordTypeId = rtId, Case_Type__c = 'SA Assignment'
        );
        insert c;
        Test.stopTest();

        Integer docCount = [SELECT COUNT() FROM Document_Checklist__c WHERE Case__c = :c.Id];
        System.debug('TEST: docs created with inactive config=' + docCount);

        System.assertEquals(0, docCount,
            'US-EXITDOC: Inactive Case_Exit_Doc_Requirement__c records should be skipped. Got=' + docCount);
    }

    // ── US-EXITDOC AC4: Close blocked by auto-created Draft docs ────────────

    @IsTest
    static void test_closeBlockedByAutoCreatedDrafts() {
        Id rtId = getDealSupportRecordTypeId();
        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'Close Block Test', Status = 'New',
            RecordTypeId = rtId, Case_Type__c = 'SA Assignment'
        );
        insert c;

        Integer exitDocCount = [SELECT COUNT() FROM Document_Checklist__c WHERE Case__c = :c.Id AND Status__c = 'Draft'];
        System.debug('TEST: auto-created Draft exit docs=' + exitDocCount + '. Attempting to close Case. Expect DML exception.');

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

        System.assert(exitDocCount > 0, 'US-EXITDOC: Expected auto-created Draft exit docs to exist before close attempt.');
        System.assertEquals(true, blocked,
            'US-EXITDOC AC4: Case close should be blocked when auto-created exit doc checklists are still Draft. '
            + 'Check Case_Exit_Document_Validation_Flow is Active. Error: ' + errorMsg);
    }

    // ── US-EXITDOC AC5: Close allowed after finalizing all exit docs ─────────

    @IsTest
    static void test_closeAllowedAfterFinalizingAutoCreatedDocs() {
        Id rtId = getDealSupportRecordTypeId();
        Case c = new Case(
            AccountId = getAccount().Id, ContactId = getContactId(),
            Subject = 'Close Allowed Test', Status = 'New',
            RecordTypeId = rtId, Case_Type__c = 'SA Assignment'
        );
        insert c;

        List<Document_Checklist__c> exitDocs = [SELECT Id FROM Document_Checklist__c WHERE Case__c = :c.Id];
        System.debug('TEST: finalizing ' + exitDocs.size() + ' auto-created exit docs, then closing Case.');

        for (Document_Checklist__c d : exitDocs) {
            d.Status__c = 'Final';
            d.Submitted_Date__c = Date.today();
        }
        update exitDocs;

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

        System.assert(!exitDocs.isEmpty(), 'US-EXITDOC: Expected auto-created exit docs to exist before finalization.');
        System.assertEquals(false, blocked,
            'US-EXITDOC AC5: Case close should be allowed after all exit doc checklists are Final. Got unexpected DmlException: ' + errorMsg);
    }

    // ── US-EXITDOC: Bulk — 200 Cases all get exit doc checklists ────────────

    @IsTest
    static void test_bulk200Cases() {
        Id rtId = getDealSupportRecordTypeId();
        Account acc = getAccount();
        Id contactId = getContactId();

        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 200; i++) {
            cases.add(new Case(
                AccountId = acc.Id, ContactId = contactId,
                Subject = 'Bulk Test ' + i, Status = 'New',
                RecordTypeId = rtId, Case_Type__c = 'SA Assignment'
            ));
        }

        Test.startTest();
        insert cases;
        Test.stopTest();

        List<Id> caseIds = new List<Id>();
        for (Case c : cases) caseIds.add(c.Id);

        Integer docCount = [SELECT COUNT() FROM Document_Checklist__c WHERE Case__c IN :caseIds AND Status__c = 'Draft'];
        System.debug('TEST: bulk 200 cases — total exit doc checklists created=' + docCount);

        System.assertEquals(200, docCount,
            'US-EXITDOC: Each of the 200 Cases should have 1 Draft exit doc checklist (1 active config record). Got=' + docCount);
    }
}