/**
 * IRM_DocChecklistTest
 * US-1501: Document Checklist status values (Draft / Final / Archived)
 * US-1136 (Case-first): Case + Document Checklists created together the moment an
 *   Opportunity qualifies for a Case_Creation_Rule__c — no longer gated behind any
 *   document reaching Final. Case_Creation_Trigger_Flow now only maintains the
 *   Case.All_Start_Docs_Final__c status indicator.
 * Bypass: mandatory-justification bypass of document requirements (Document_Checklist__c).
 *
 * Case-first path under test: OpportunityTriggerHandler.AfterInsert/AfterUpdate ->
 * CaseCreationRuleEvaluatorAction.createEligibleChecklistsAfterSave().
 * Indicator flow under test: Case_Creation_Trigger_Flow (After Update — Document_Checklist__c).
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
            Document_Category__c = 'Scoping and Technical Documents',
            Is_Required_To_Start__c = true, Is_Required_For_Case__c = true
        );
    }

    private static Account getAccount() {
        return [SELECT Id FROM Account LIMIT 1];
    }

    private static Case_Creation_Rule__c getRule() {
        return [SELECT Id FROM Case_Creation_Rule__c LIMIT 1];
    }

    private static Opportunity makeQualifyingOpp(String name, Decimal amount) {
        Opportunity opp = new Opportunity(
            Name = name, AccountId = getAccount().Id,
            Type = 'New Deal', StageName = 'Qualification', CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(), Amount = amount,
            Bypass_Validation__c = true
        );
        insert opp;
        return opp;
    }

    // ── US-1501: Status picklist values ──────────────────────────────────────

    @IsTest
    static void test_US1501_draftStatusAccepted() {
        Case_Creation_Rule__c rule = getRule();
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        Document_Checklist__c doc = new Document_Checklist__c(
            Opportunity__c = oppId, Case_Creation_Rule__c = rule.Id, Status__c = 'Draft', Document_Category__c = 'Scoping & Technical'
        );
        insert doc;
        Test.stopTest();

        Document_Checklist__c r = [SELECT Status__c FROM Document_Checklist__c WHERE Id = :doc.Id];
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

        Test.startTest();
        doc.Status__c = 'Final';
        doc.Submitted_Date__c = Date.today();
        update doc;
        Test.stopTest();

        Document_Checklist__c r = [SELECT Status__c FROM Document_Checklist__c WHERE Id = :doc.Id];
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

        Test.startTest();
        doc.Status__c = 'Archived/Do Not Use';
        doc.Notes__c = 'Archiving document.';
        update doc;
        Test.stopTest();

        Document_Checklist__c r = [SELECT Status__c FROM Document_Checklist__c WHERE Id = :doc.Id];
        System.assertEquals('Archived/Do Not Use', r.Status__c,
            'US-1501: Archived/Do Not Use should be a valid status value. Got: ' + r.Status__c);
    }

    // ── Case-first: Case + Document Checklist created together when the Opportunity qualifies ──

    @IsTest
    static void test_caseFirst_caseAndChecklistCreatedImmediatelyOnQualifyingInsert() {
        Case_Creation_Rule__c rule = getRule();

        Test.startTest();
        Opportunity opp = makeQualifyingOpp('Case-First Test', 600000);
        Test.stopTest();

        List<Case> cases = [SELECT Id, Case_Type__c, Status FROM Case WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, cases.size(),
            'Case-first: the Case should be created immediately when the Opportunity qualifies, before any document is Final.');
        System.assertEquals('New', cases[0].Status, 'Case-first: newly created Case should be Status=New.');
        System.assertEquals('SA Assignment', cases[0].Case_Type__c);

        List<Document_Checklist__c> checklists = [
            SELECT Id, Status__c, Case__c FROM Document_Checklist__c WHERE Opportunity__c = :opp.Id AND Case_Creation_Rule__c = :rule.Id
        ];
        System.assert(!checklists.isEmpty(), 'Case-first: Document Checklist(s) should be created alongside the Case.');
        for (Document_Checklist__c dc : checklists) {
            System.assertEquals('Draft', dc.Status__c);
            System.assertEquals(cases[0].Id, dc.Case__c,
                'Case-first: every Document Checklist must be linked (Case__c) to the newly created Case.');
        }
    }

    @IsTest
    static void test_caseFirst_noDuplicateCaseOnReEvaluation() {
        Opportunity opp = makeQualifyingOpp('No Dup Case Test', 600000);
        Integer casesAfterInsert = [SELECT COUNT() FROM Case WHERE Opportunity__c = :opp.Id];

        Test.startTest();
        opp.Amount = 700000; // still matches the rule — Amount is a watched field, re-triggers evaluation
        update opp;
        Test.stopTest();

        Integer casesAfterUpdate = [SELECT COUNT() FROM Case WHERE Opportunity__c = :opp.Id];
        System.assertEquals(casesAfterInsert, casesAfterUpdate,
            'Case-first: re-evaluating an Opportunity that still matches the same rule must not create a second Case.');
    }

    @IsTest
    static void test_caseFirst_allStartDocsFinalIndicatorTracksDocStatus() {
        Case_Creation_Rule__c rule = getRule();
        Opportunity opp = makeQualifyingOpp('Indicator Test', 600000);

        Case createdCase = [SELECT Id, All_Start_Docs_Final__c FROM Case WHERE Opportunity__c = :opp.Id];
        Document_Checklist__c dc = [
            SELECT Id, Status__c FROM Document_Checklist__c
            WHERE Opportunity__c = :opp.Id AND Case_Creation_Rule__c = :rule.Id LIMIT 1
        ];

        Test.startTest();
        dc.Status__c = 'Final';
        dc.Submitted_Date__c = Date.today();
        update dc;
        Test.stopTest();

        Case afterFinal = [SELECT Id, All_Start_Docs_Final__c FROM Case WHERE Id = :createdCase.Id];
        System.assertEquals(true, afterFinal.All_Start_Docs_Final__c,
            'Case_Creation_Trigger_Flow should set All_Start_Docs_Final__c = true once every required-for-case doc is Final.');
    }

    @IsTest
    static void test_caseFirst_indicatorStaysFalseWhilePartialDocsFinal() {
        Case_Creation_Rule__c rule = getRule();
        // Second required-for-case doc on the same rule
        insert new Case_Creation_Doc_Requirement__c(
            Rule__c = rule.Id, Document_Type__c = 'Technical Scoping Form',
            Document_Category__c = 'Scoping and Technical Documents',
            Is_Required_To_Start__c = false, Is_Required_For_Case__c = true
        );

        Opportunity opp = makeQualifyingOpp('Partial Docs Test', 600000);

        Case createdCase = [SELECT Id FROM Case WHERE Opportunity__c = :opp.Id];
        List<Document_Checklist__c> checklists = [
            SELECT Id FROM Document_Checklist__c WHERE Case__c = :createdCase.Id AND Case_Creation_Rule__c = :rule.Id
        ];
        System.assertEquals(2, checklists.size(), 'Both required-for-case doc types should have Draft checklists created up front.');

        Test.startTest();
        checklists[0].Status__c = 'Final';
        checklists[0].Submitted_Date__c = Date.today();
        update checklists[0];
        Test.stopTest();

        Case afterOneFinal = [SELECT Id, All_Start_Docs_Final__c FROM Case WHERE Id = :createdCase.Id];
        System.assertEquals(false, afterOneFinal.All_Start_Docs_Final__c,
            'Indicator should stay false while one of the two required-for-case docs is still Draft.');

        Integer caseCount = [SELECT COUNT() FROM Case WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, caseCount,
            'Case-first: only one Case should ever exist for this Opportunity+Rule, regardless of document status.');
    }

    // ── US-EXITDOC: Exit doc checklists created alongside the Case-first Case ───────

    @IsTest
    static void test_EXITDOC_exitDocChecklistsCreatedImmediatelyWithCase() {
        insert new Case_Exit_Doc_Requirement__c(
            Case_Record_Type_Dev_Name__c = 'Deal_Support',
            Case_Type__c                 = 'SA Assignment',
            Document_Category__c         = 'Scoping & Technical',
            Document_Type__c             = 'Technical Scoping Form',
            Is_Active__c                 = true
        );

        Test.startTest();
        Opportunity opp = makeQualifyingOpp('ExitDoc Cross-Flow Test', 600000);
        Test.stopTest();

        List<Case> cases = [SELECT Id FROM Case WHERE Opportunity__c = :opp.Id];
        System.assert(!cases.isEmpty(), 'US-EXITDOC: Expected Case to be Case-first created when the Opportunity qualifies. Found 0.');

        List<Document_Checklist__c> exitDocs = [
            SELECT Id, Status__c, IsRequired__c
            FROM Document_Checklist__c
            WHERE Case__c = :cases[0].Id AND Case_Creation_Rule__c = null
        ];
        System.assert(!exitDocs.isEmpty(),
            'US-EXITDOC: Expected Draft Document_Checklist records linked to the Case-first Case via Case_Exit_Doc_Checklist_Creation_Flow. Found 0. '
            + 'Check Case_Exit_Doc_Checklist_Creation_Flow is Active and Case_Exit_Doc_Requirement__c config exists for Deal_Support + SA Assignment.');
        System.assertEquals('Draft', exitDocs[0].Status__c);
        System.assertEquals(true, exitDocs[0].IsRequired__c,
            'US-EXITDOC: Auto-created exit doc checklist should have IsRequired__c = true.');
    }

    // ── Bypass document requirement with mandatory justification ────────────────────

    @IsTest
    static void test_bypass_blockedWithoutJustification() {
        Case_Creation_Rule__c rule = getRule();
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Document_Checklist__c doc = new Document_Checklist__c(
            Opportunity__c = oppId, Case_Creation_Rule__c = rule.Id, Status__c = 'Draft', Document_Category__c = 'Scoping & Technical'
        );
        insert doc;

        doc.Bypass_Requirement__c = true; // no justification provided
        Boolean threw = false;
        try {
            update doc;
        } catch (DmlException e) {
            threw = true;
            System.assert(e.getMessage().contains('written justification'),
                'Expected the Require_Justification_When_Bypassed error. Got: ' + e.getMessage());
        }
        System.assert(threw, 'Checking Bypass_Requirement__c without a justification should be blocked.');
    }

    @IsTest
    static void test_bypass_allowsFinalWithoutSubmittedDateWhenJustified() {
        Case_Creation_Rule__c rule = getRule();
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Document_Checklist__c doc = new Document_Checklist__c(
            Opportunity__c = oppId, Case_Creation_Rule__c = rule.Id, Status__c = 'Draft', Document_Category__c = 'Scoping & Technical'
        );
        insert doc;

        Test.startTest();
        doc.Bypass_Requirement__c = true;
        doc.Bypass_Justification__c = 'Client requested exception — deal at risk of slipping quarter, documentation to follow post-close.';
        doc.Status__c = 'Final'; // intentionally no Submitted_Date__c
        update doc;
        Test.stopTest();

        Document_Checklist__c r = [SELECT Status__c FROM Document_Checklist__c WHERE Id = :doc.Id];
        System.assertEquals('Final', r.Status__c,
            'Bypass with justification should allow Final without a Submitted Date.');
    }

    @IsTest
    static void test_bypass_stillBlockedWithoutBypassAndWithoutSubmittedDate() {
        Case_Creation_Rule__c rule = getRule();
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Document_Checklist__c doc = new Document_Checklist__c(
            Opportunity__c = oppId, Case_Creation_Rule__c = rule.Id, Status__c = 'Draft', Document_Category__c = 'Scoping & Technical'
        );
        insert doc;

        doc.Status__c = 'Final'; // no Submitted_Date__c, no bypass
        Boolean threw = false;
        try {
            update doc;
        } catch (DmlException e) {
            threw = true;
        }
        System.assert(threw, 'Without bypass, Final still requires Submitted Date (existing rule unchanged).');
    }
}
