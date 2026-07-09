/**
 * IRM_DocChecklistTest
 * US-1501: Document Checklist status values (Draft / Final / Archived)
 * US-1136 Phase 2: All required docs Final → Case created via Case_Creation_Trigger_Flow
 *
 * Flow under test: Case_Creation_Trigger_Flow (After Update — Document_Checklist__c)
 * Must be ACTIVE in Setup → Flows before running.
 */
@IsTest
private class IRM_DocChecklistTest {

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
            Name = 'IRM Doc Test Co',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;
        Opportunity setupOpp = new Opportunity(
            Name = 'IRM Doc Status Test', AccountId = acc.Id,
            Type = 'New Deal', StageName = 'Qualification', CloseDate = Date.today().addDays(30), Pricebook2Id = Test.getStandardPricebookId(), Amount = 100000,
            Bypass_Validation__c = true
        );
        insert setupOpp;

        Case_Creation_Rule__c rule = new Case_Creation_Rule__c(
            Stage__c = 'Qualification', Case_Type__c = 'SA Assignment',
            Record_Type_Dev_Name__c = 'Deal_Support',
            Queue_Developer_Name__c = 'Solution_Specialist_Queue',
            Logic_Expression__c = '1', Is_Active__c = true, Priority__c = 10
        );
        insert rule;
        insert new Case_Creation_Condition__c(
            Rule__c = rule.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '500000'
        );
        insert new Case_Creation_Doc_Requirement__c(
            Rule__c = rule.Id, Document_Type__c = 'Solution Assessment',
            Is_Required_To_Start__c = true, Is_Required_For_Case__c = true
        );
    }

    private static Account getAccount() {
        return [SELECT Id FROM Account LIMIT 1];
    }

    private static Case_Creation_Rule__c getRule() {
        return [SELECT Id FROM Case_Creation_Rule__c LIMIT 1];
    }

    // ── US-1501: Status picklist values ──────────────────────────────────────

    @IsTest
    static void test_US1501_draftStatusAccepted() {
        Case_Creation_Rule__c rule = getRule();
        System.debug('TEST: Creating Document_Checklist__c with Status=Draft.');

        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        Document_Checklist__c doc = new Document_Checklist__c(
            Opportunity__c = oppId, Case_Creation_Rule__c = rule.Id, Status__c = 'Draft', Document_Category__c = 'Scoping & Technical'
        );
        insert doc;
        Test.stopTest();

        Document_Checklist__c r = [SELECT Status__c FROM Document_Checklist__c WHERE Id = :doc.Id];
        System.debug('RESULT: Status__c=' + r.Status__c);

        System.assertEquals('Draft', r.Status__c,
            'US-1501: Draft should be a valid status value. Got: ' + r.Status__c);
    }

    @IsTest
    static void test_US1501_finalStatusAccepted() {
        Case_Creation_Rule__c rule = getRule();
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Document_Checklist__c doc = new Document_Checklist__c(
            Opportunity__c = oppId, Case_Creation_Rule__c = rule.Id, Status__c = 'Draft', Document_Category__c = 'Scoping & Technical'
        );
        insert doc;

        System.debug('TEST: Updating Document_Checklist__c Status Draft→Final.');

        Test.startTest();
        doc.Status__c = 'Final';
        doc.Submitted_Date__c = Date.today();
        update doc;
        Test.stopTest();

        Document_Checklist__c r = [SELECT Status__c FROM Document_Checklist__c WHERE Id = :doc.Id];
        System.debug('RESULT: Status__c=' + r.Status__c);

        System.assertEquals('Final', r.Status__c,
            'US-1501: Final should be a valid status value. Got: ' + r.Status__c);
    }

    @IsTest
    static void test_US1501_archivedStatusAccepted() {
        Case_Creation_Rule__c rule = getRule();
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Document_Checklist__c doc = new Document_Checklist__c(
            Opportunity__c = oppId, Case_Creation_Rule__c = rule.Id, Status__c = 'Draft', Document_Category__c = 'Scoping & Technical'
        );
        insert doc;

        System.debug('TEST: Updating Document_Checklist__c Status Draft→Archived/Do Not Use.');

        Test.startTest();
        doc.Status__c = 'Archived/Do Not Use';
        doc.Notes__c = 'Archiving document.';
        update doc;
        Test.stopTest();

        Document_Checklist__c r = [SELECT Status__c FROM Document_Checklist__c WHERE Id = :doc.Id];
        System.debug('RESULT: Status__c=' + r.Status__c);

        System.assertEquals('Archived/Do Not Use', r.Status__c,
            'US-1501: Archived/Do Not Use should be a valid status value. Got: ' + r.Status__c);
    }

    // ── US-1136 Phase 2: Case created when all required docs reach Final ─────

    @IsTest
    static void test_US1136_caseCreatedWhenAllDocsFinal() {
        Account acc = getAccount();
        Case_Creation_Rule__c rule = getRule();

        Opportunity opp = new Opportunity(
            Name = 'Phase2 Test', AccountId = acc.Id,
            Type = 'New Deal', StageName = 'Qualification', CloseDate = Date.today().addDays(30), Pricebook2Id = Test.getStandardPricebookId(), Amount = 600000,
            Bypass_Validation__c = true
        );
        insert opp;

        Document_Checklist__c doc = new Document_Checklist__c(
            Opportunity__c = opp.Id, Case_Creation_Rule__c = rule.Id,
            Status__c = 'Draft', Document_Category__c = 'Scoping & Technical'
        );
        insert doc;

        Integer casesBefore = [SELECT COUNT() FROM Case WHERE AccountId = :acc.Id];
        System.debug('TEST: Setting single required doc to Final. Cases before=' + casesBefore + '. Expect Case to be created.');

        Test.startTest();
        doc.Status__c = 'Final';
        doc.Submitted_Date__c = Date.today();
        update doc;
        Test.stopTest();

        Integer casesAfter = [SELECT COUNT() FROM Case WHERE AccountId = :acc.Id];
        System.debug('RESULT: Cases before=' + casesBefore + ' | Cases after=' + casesAfter);

        List<Case> created = [SELECT Id, Case_Type__c, OwnerId, Status FROM Case WHERE AccountId = :acc.Id];
        for (Case c : created) {
            System.debug('CREATED CASE: Id=' + c.Id + ' | Case_Type__c=' + c.Case_Type__c
                + ' | OwnerId=' + c.OwnerId + ' | Status=' + c.Status);
        }

        System.assert(casesAfter > casesBefore,
            'US-1136 Phase 2: Setting all required Document Checklists to Final should trigger Case creation. Before=' + casesBefore + ' After=' + casesAfter);
    }

    @IsTest
    static void test_US1136_caseHasCorrectCaseType() {
        Account acc = getAccount();
        Case_Creation_Rule__c rule = getRule();

        Opportunity opp = new Opportunity(
            Name = 'Case Type Test', AccountId = acc.Id,
            Type = 'New Deal', StageName = 'Qualification', CloseDate = Date.today().addDays(30), Pricebook2Id = Test.getStandardPricebookId(), Amount = 600000,
            Bypass_Validation__c = true
        );
        insert opp;

        Document_Checklist__c doc = new Document_Checklist__c(
            Opportunity__c = opp.Id, Case_Creation_Rule__c = rule.Id,
            Status__c = 'Draft', Document_Category__c = 'Scoping & Technical'
        );
        insert doc;

        System.debug('TEST: Setting doc to Final. Expect created Case to have Case_Type__c=SA Assignment.');

        Test.startTest();
        doc.Status__c = 'Final';
        doc.Submitted_Date__c = Date.today();
        update doc;
        Test.stopTest();

        List<Case> cases = [SELECT Id, Case_Type__c FROM Case WHERE AccountId = :acc.Id];
        System.debug('RESULT: Cases found=' + cases.size());
        for (Case c : cases) System.debug('Case Case_Type__c=' + c.Case_Type__c);

        System.assert(!cases.isEmpty(), 'US-1136 Phase 2: Expected at least one Case to be created. Found 0.');
        System.assertEquals('SA Assignment', cases[0].Case_Type__c,
            'US-1136 Phase 2: Case_Type__c should be SA Assignment from the matched rule. Got: ' + cases[0].Case_Type__c);
    }

    // ── US-EXITDOC: Exit doc checklists created on auto-generated Case ───────

    @IsTest
    static void test_EXITDOC_exitDocChecklistsCreatedAfterCaseAutoCreation() {
        Account acc = getAccount();
        Case_Creation_Rule__c rule = getRule();

        // Insert exit doc config for Deal_Support + SA Assignment
        insert new Case_Exit_Doc_Requirement__c(
            Case_Record_Type_Dev_Name__c = 'Deal_Support',
            Case_Type__c                 = 'SA Assignment',
            Document_Category__c         = 'Scoping & Technical',
            Document_Type__c             = 'Technical Scoping Form',
            Is_Active__c                 = true
        );

        Opportunity opp = new Opportunity(
            Name = 'ExitDoc Cross-Flow Test', AccountId = acc.Id,
            Type = 'New Deal', StageName = 'Qualification', CloseDate = Date.today().addDays(30), Pricebook2Id = Test.getStandardPricebookId(), Amount = 600000,
            Bypass_Validation__c = true
        );
        insert opp;

        Document_Checklist__c doc = new Document_Checklist__c(
            Opportunity__c = opp.Id, Case_Creation_Rule__c = rule.Id,
            Status__c = 'Draft', Document_Category__c = 'Scoping & Technical'
        );
        insert doc;

        System.debug('TEST: Setting doc to Final → Case_Creation_Trigger_Flow creates Case → Case_Exit_Doc_Checklist_Creation_Flow creates exit doc checklists.');

        Test.startTest();
        doc.Status__c = 'Final';
        doc.Submitted_Date__c = Date.today();
        update doc;
        Test.stopTest();

        List<Case> cases = [SELECT Id, Case_Type__c FROM Case WHERE AccountId = :acc.Id];
        System.assert(!cases.isEmpty(), 'US-EXITDOC: Expected Case to be auto-created by Case_Creation_Trigger_Flow. Found 0.');

        List<Document_Checklist__c> exitDocs = [
            SELECT Id, Status__c, IsRequired__c
            FROM Document_Checklist__c
            WHERE Case__c = :cases[0].Id AND Status__c = 'Draft'
        ];
        System.debug('RESULT: Exit doc checklists found=' + exitDocs.size());

        System.assert(!exitDocs.isEmpty(),
            'US-EXITDOC: Expected Draft Document_Checklist records linked to the auto-created Case. Found 0. '
            + 'Check Case_Exit_Doc_Checklist_Creation_Flow is Active and Case_Exit_Doc_Requirement__c config exists for Deal_Support + SA Assignment.');
        System.assertEquals(true, exitDocs[0].IsRequired__c,
            'US-EXITDOC: Auto-created exit doc checklist should have IsRequired__c = true.');
    }

    @IsTest
    static void test_US1136_caseNotCreatedWhenSomeDocsPending() {
        Account acc = getAccount();
        Case_Creation_Rule__c rule = getRule();

        Opportunity opp = new Opportunity(
            Name = 'Partial Docs Test', AccountId = acc.Id,
            Type = 'New Deal', StageName = 'Qualification', CloseDate = Date.today().addDays(30), Pricebook2Id = Test.getStandardPricebookId(), Amount = 600000,
            Bypass_Validation__c = true
        );
        insert opp;

        // Two docs — only one will be finalised
        Document_Checklist__c doc1 = new Document_Checklist__c(
            Opportunity__c = opp.Id, Case_Creation_Rule__c = rule.Id, Status__c = 'Draft', Document_Category__c = 'Scoping & Technical'
        );
        Document_Checklist__c doc2 = new Document_Checklist__c(
            Opportunity__c = opp.Id, Case_Creation_Rule__c = rule.Id, Status__c = 'Draft', Document_Category__c = 'Scoping & Technical'
        );
        insert new List<Document_Checklist__c>{ doc1, doc2 };

        Integer casesBefore = [SELECT COUNT() FROM Case WHERE AccountId = :acc.Id];
        System.debug('TEST: Setting 1 of 2 docs to Final. Cases before=' + casesBefore + '. Expect NO case creation (doc2 still Draft).');

        Test.startTest();
        doc1.Status__c = 'Final';
        doc1.Submitted_Date__c = Date.today();
        update doc1;
        Test.stopTest();

        Integer casesAfter = [SELECT COUNT() FROM Case WHERE AccountId = :acc.Id];
        System.debug('RESULT: Cases before=' + casesBefore + ' | Cases after=' + casesAfter);

        System.assertEquals(casesBefore, casesAfter,
            'US-1136 Phase 2: Case should NOT be created while doc2 is still Draft. Before=' + casesBefore + ' After=' + casesAfter);
    }
}