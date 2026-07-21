/**
 * IRM_UserStoryTest
 *
 * Covers all deployed user stories end-to-end. Each test maps to an acceptance
 * criterion and exercises either a Record-Triggered Flow, an Apex Invocable Action,
 * or both together.
 *
 * Pre-existing org fields assumed present (not in this deployment package):
 *   Opportunity: Touch_Level__c, Touch_Level_Calculated__c
 *   Opportunity: Touch_Level_Override__c, Touch_Level_Override_Reason__c (deployed)
 *   Case:        Type (standard field — the routing/case-creation engine no longer uses
 *                the custom Case_Type__c field), Opportunity__c
 *   Document_Checklist__c: Status__c (picklist: Draft/Final/Archived), Opportunity__c
 *   Reference_Threshold__c: Financial_Year__c, Region__c, Cluster__c, Country__c, Volume_Profile__c
 *
 * Touch Level recalculation is driven by OpportunityTriggerHandler.BeforeInsert/BeforeUpdate ->
 * TouchLevelEvaluatorAction.recalculateBeforeSave() (Apex), not a Flow — Touch_Level_Recalculation_Flow
 * has been retired (see manifest/destructiveChanges).
 *
 * Case creation is Case-first: CaseCreationRuleEvaluatorAction (Apex, called from
 * OpportunityTriggerHandler.AfterInsert/AfterUpdate) creates the Case and every Document
 * Checklist together the moment an Opportunity qualifies. Case_Creation_Trigger_Flow no
 * longer creates the Case — it only maintains the Case.All_Start_Docs_Final__c indicator.
 *
 * Flows under test (must be ACTIVE in Setup → Flows before running):
 *   Case_Creation_Trigger_Flow              (After Update – Document_Checklist__c; docs-final indicator only)
 *   Case_Exit_Document_Validation_Flow      (Before Update – Case)
 *   Reference_Threshold_Key_Flow            (Before Save – Reference_Threshold__c)
 *
 * Case queue assignment (US-1500) is a single source of truth: Case_Creation_Rule__c.Queue_Developer_Name__c,
 * resolved and stamped onto Case.OwnerId at creation time by CaseCreationRuleEvaluatorAction.createCasesForPairs
 * (with ReassertCaseOwnerJob, a Queueable, correcting OwnerId if an inherited Sforce-Auto-Assign header lets
 * the org's native Case Assignment Rule override it during the insert). Support_Engagement_Case_Assignment_Flow
 * and Touch_Level_Case_Routing__c (a second, independent Case.Type-keyed queue lookup) have been retired —
 * they duplicated this resolution and could drift out of sync with Case_Creation_Rule__c (see
 * manifest/destructiveChanges).
 */
@IsTest
private class IRM_UserStoryTest {

    // ─────────────────────────────────────────────────────────────────────────
    // Shared setup
    // ─────────────────────────────────────────────────────────────────────────

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
        // SVStatus__c is looked up by a single fixed key, SVStatus__c.getValues('SVStatusPassed')
        // — this correctly-named row prevents the SVStatus.cls line 39 NPE on Opportunity updates.
        insert new SVStatus__c(Name = 'SVStatusPassed', Amount__c = 0, SetupOwnerId = UserInfo.getOrganizationId());

        Account acc = new Account(
            Name = 'IRM Test Co',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;
        // 3 Contacts — one per required OCR role (org VR blocks same Contact in multiple roles)
        insert new List<Contact>{
            new Contact(LastName = 'Champion',      AccountId = acc.Id),
            new Contact(LastName = 'EconomicBuyer', AccountId = acc.Id),
            new Contact(LastName = 'ProblemOwner',  AccountId = acc.Id)
        };

        // ── Touch Level criteria: Qualification → High Touch (Amount >= 500k) ──
        Touch_Level_Criteria__c htCriteria = new Touch_Level_Criteria__c(
            Stage__c            = 'Qualification',
            Touch_Level_Result__c = 'High Touch',
            Priority__c         = 10,
            Logic_Expression__c = '1',
            Is_Active__c        = true
        );
        insert htCriteria;
        insert new Touch_Level_Condition__c(
            Criteria__c           = htCriteria.Id,
            Condition_Number__c   = 1,
            Field_API_Name__c     = 'Amount',
            Operator__c           = 'GREATER_OR_EQUAL',
            Value__c              = '500000'
        );

        // ── Touch Level criteria: Qualification → Medium Touch (Amount >= 100k) ──
        Touch_Level_Criteria__c mtCriteria = new Touch_Level_Criteria__c(
            Stage__c            = 'Qualification',
            Touch_Level_Result__c = 'Medium Touch',
            Priority__c         = 20,
            Logic_Expression__c = '1',
            Is_Active__c        = true
        );
        insert mtCriteria;
        insert new Touch_Level_Condition__c(
            Criteria__c           = mtCriteria.Id,
            Condition_Number__c   = 1,
            Field_API_Name__c     = 'Amount',
            Operator__c           = 'GREATER_OR_EQUAL',
            Value__c              = '100000'
        );

        // ── Case Creation Rule: Qualification → SA Assignment (Amount >= 500k) ──
        Case_Creation_Rule__c saRule = new Case_Creation_Rule__c(
            Stage__c                  = 'Qualification',
            Case_Type__c              = 'SA Assignment',
            Record_Type_Dev_Name__c   = 'Deal_Support',
            Queue_Developer_Name__c   = 'Solution_Specialist_Queue',
            Logic_Expression__c       = '1',
            Is_Active__c              = true,
            Priority__c               = 10
        );
        insert saRule;
        insert new Case_Creation_Condition__c(
            Rule__c               = saRule.Id,
            Condition_Number__c   = 1,
            Field_API_Name__c     = 'Amount',
            Operator__c           = 'GREATER_OR_EQUAL',
            Value__c              = '500000'
        );
        insert new Case_Creation_Doc_Requirement__c(
            Rule__c                   = saRule.Id,
            Document_Type__c          = 'Business Problem Statement',
            Document_Category__c      = 'Scoping and Technical Documents',
            Is_Required_To_Start__c   = true,
            Is_Required_For_Case__c   = true
        );
    }

    private static Account getAccount() {
        return [SELECT Id FROM Account LIMIT 1];
    }

    private static Opportunity makeOpp(String stage, Decimal amount) {
        Opportunity opp = new Opportunity(
            Name        = 'Test Opp - ' + stage,
            AccountId   = getAccount().Id,
            RecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
            Type        = 'New Deal',
            StageName   = stage,
            CloseDate   = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(),
            Amount      = amount,
            Bypass_Validation__c = true
        );
        insert opp;
        return opp;
    }

    private static void addOcrRoles(Id oppId) {
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY LastName];
        insert new List<OpportunityContactRole>{
            new OpportunityContactRole(OpportunityId = oppId, ContactId = contacts[0].Id, Role = 'Champion'),
            new OpportunityContactRole(OpportunityId = oppId, ContactId = contacts[1].Id, Role = 'Economic Decision Maker / Buyer'),
            new OpportunityContactRole(OpportunityId = oppId, ContactId = contacts[2].Id, Role = 'Problem Owner')
        };
    }

    // ─────────────────────────────────────────────────────────────────────────
    // US-996: Touch Level Recalculation
    // AC1: On stage change (or Opp save), Touch Level is recalculated via flow
    // AC2: Touch_Level_Criteria_Matched__c is populated
    // AC3: Inactive criteria are ignored
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void test_US996_highTouchClassifiedOnInsert() {
        Test.startTest();
        Opportunity opp = makeOpp('Qualification', 600000);
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c, Touch_Level_Criteria_Matched__c
                         FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('High Touch', r.Touch_Level__c,
            'US-996: Amount >= 500k at Qualification should classify as High Touch');
        System.assertNotEquals(null, r.Touch_Level_Criteria_Matched__c,
            'US-996: Touch_Level_Criteria_Matched__c should be populated with the matching criteria name');
    }

    @IsTest
    static void test_US996_mediumTouchWhenBelowHighThreshold() {
        Test.startTest();
        Opportunity opp = makeOpp('Qualification', 150000); // >= 100k but < 500k
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Medium Touch', r.Touch_Level__c,
            'US-996: Amount between 100k and 500k should fall through to Medium Touch');
    }

    @IsTest
    static void test_US996_noTouchWhenNoCriteriaForStage() {
        Test.startTest();
        Opportunity opp = makeOpp('Solutioning', 600000); // no criteria seeded for this stage
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('No Touch', r.Touch_Level__c,
            'US-996: No active criteria for Solutioning should result in No Touch');
    }

    @IsTest
    static void test_US996_touchLevelRecalculatesOnStageChange() {
        Opportunity opp = makeOpp('Solutioning', 600000); // No Touch initially
        addOcrRoles(opp.Id); // required before advancing to Qualification (org VR)

        Test.startTest();
        opp.StageName = 'Qualification';
        update opp;
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('High Touch', r.Touch_Level__c,
            'US-996: Stage change to Qualification should trigger recalculation to High Touch');
    }

    @IsTest
    static void test_US996_inactiveCriteriaIgnored() {
        // Add a higher-priority inactive criteria that would give a different result
        Touch_Level_Criteria__c inactive = new Touch_Level_Criteria__c(
            Stage__c            = 'Qualification',
            Touch_Level_Result__c = 'Low Touch',
            Priority__c         = 1, // highest priority
            Logic_Expression__c = '1',
            Is_Active__c        = false  // inactive
        );
        insert inactive;
        insert new Touch_Level_Condition__c(
            Criteria__c = inactive.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '0'
        );

        Test.startTest();
        Opportunity opp = makeOpp('Qualification', 600000);
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('High Touch', r.Touch_Level__c,
            'US-996: Inactive criteria should be ignored — active priority-10 HT rule should win');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Touch Level Override
    // AC: Touch_Level_Override__c flag and reason field can be set
    // AC: Calculated vs manual touch level fields are independent
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void test_override_flagAndReasonCaptured() {
        Opportunity opp = makeOpp('Qualification', 150000); // would be Medium Touch

        Test.startTest();
        opp.Touch_Level_Override__c       = true;
        opp.Touch_Level_Override_Reason__c = 'Escalated by VP Sales — strategic account';
        opp.Touch_Level__c                = 'High Touch';
        update opp;
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c, Touch_Level_Override__c,
                                Touch_Level_Override_Reason__c
                         FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true,        r.Touch_Level_Override__c,    'Override flag should be true');
        System.assertEquals('High Touch', r.Touch_Level__c,             'Override touch level should be High Touch');
        System.assert(r.Touch_Level_Override_Reason__c.contains('Escalated'),
            'Override reason should be stored verbatim');
    }

    @IsTest
    static void test_override_calculatedFieldStillUpdatedByFlow() {
        Test.startTest();
        Opportunity opp = makeOpp('Qualification', 600000);
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c, Touch_Level_Calculated__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertNotEquals(null, r.Touch_Level_Calculated__c,
            'Touch_Level_Calculated__c should be set by the recalculation flow independently of override');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // US-1136: Phase 1 — Case Creation Rule Evaluation
    // AC: CaseCreationRuleEvaluatorAction correctly identifies matched rules
    //     and their document requirements for a given Opportunity
    // (Phase 1 flow creates Document_Checklist__c records — tested via Apex action
    //  since Case_Creation_Eligibility_Flow body must be configured in Flow Builder)
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void test_US1136_phase1_ruleEvaluatorReturnsMatchedRules() {
        Opportunity opp = makeOpp('Qualification', 600000);

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].hasMatches,
            'US-1136 Phase 1: SA Assignment rule should match a 600k Qualification opportunity');
        System.assertEquals(1, results[0].matchedRuleCount);

        List<Object> matched = (List<Object>) JSON.deserializeUntyped(results[0].matchedRulesJson);
        Map<String, Object> mr = (Map<String, Object>) matched[0];
        System.assertEquals('SA Assignment',            (String) mr.get('caseType'));
        System.assertEquals('Deal_Support',             (String) mr.get('recordTypeDeveloperName'));
        System.assertEquals('Solution_Specialist_Queue',(String) mr.get('queueDeveloperName'));
        System.assert(((String) mr.get('requiredDocTypes')).contains('Business Problem Statement'),
            'Phase 1: Required-to-start doc type should be in the response');
    }

    @IsTest
    static void test_US1136_phase1_noMatchWhenAmountTooLow() {
        Opportunity opp = makeOpp('Qualification', 50000); // below 500k threshold

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(false, results[0].hasMatches,
            'US-1136 Phase 1: 50k opportunity should not match the 500k SA Assignment rule');
    }

    @IsTest
    static void test_US1136_phase1_noMatchWhenWrongStage() {
        Opportunity opp = makeOpp('Solutioning', 600000); // rule is for Qualification only

        Test.startTest();
        CaseCreationRuleEvaluatorAction.Request req = new CaseCreationRuleEvaluatorAction.Request();
        req.opportunityId = opp.Id;
        List<CaseCreationRuleEvaluatorAction.Result> results =
            CaseCreationRuleEvaluatorAction.evaluate(
                new List<CaseCreationRuleEvaluatorAction.Request>{ req });
        Test.stopTest();

        System.assertEquals(false, results[0].hasMatches,
            'US-1136 Phase 1: Solutioning stage should not match a Qualification-only rule');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // US-1136: Case-first — Case + Document Checklist created together when the
    // Opportunity qualifies; Case_Creation_Trigger_Flow only maintains the
    // All_Start_Docs_Final__c status indicator once required-for-case docs go Final.
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void test_US1136_caseFirst_caseCreatedImmediatelyOnQualifyingOpp() {
        Test.startTest();
        Opportunity opp = makeOpp('Qualification', 600000);
        Test.stopTest();

        List<Case> cases = [SELECT Id, Type, Status FROM Case WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, cases.size(),
            'US-1136 Case-first: the Case should be created immediately when the Opportunity qualifies.');
        System.assertEquals('New', cases[0].Status);
        System.assertEquals('SA Assignment', cases[0].Type,
            'US-1136 Case-first: Created Case should have the correct Case Type from the rule');
    }

    @IsTest
    static void test_US1136_caseFirst_allStartDocsFinalIndicatorTracksDocStatus() {
        Opportunity opp = makeOpp('Qualification', 600000);
        Case_Creation_Rule__c rule = [SELECT Id FROM Case_Creation_Rule__c LIMIT 1];
        Case createdCase = [SELECT Id FROM Case WHERE Opportunity__c = :opp.Id];
        Document_Checklist__c doc = [
            SELECT Id FROM Document_Checklist__c
            WHERE Opportunity__c = :opp.Id AND Case_Creation_Rule__c = :rule.Id LIMIT 1
        ];

        Test.startTest();
        doc.Status__c = 'Final';
        doc.Submitted_Date__c = Date.today();
        update doc;
        Test.stopTest();

        Case afterFinal = [SELECT Id, All_Start_Docs_Final__c FROM Case WHERE Id = :createdCase.Id];
        System.assertEquals(true, afterFinal.All_Start_Docs_Final__c,
            'US-1136 Case-first: All_Start_Docs_Final__c should be true once every required-for-case doc is Final.');
    }

    @IsTest
    static void test_US1136_caseFirst_noDuplicateCaseOnReEvaluation() {
        Opportunity opp = makeOpp('Qualification', 600000);
        Integer casesAfterInsert = [SELECT COUNT() FROM Case WHERE Opportunity__c = :opp.Id];

        Test.startTest();
        opp.Amount = 700000; // still matches — Amount is a watched field, re-triggers evaluation
        update opp;
        Test.stopTest();

        Integer casesAfterUpdate = [SELECT COUNT() FROM Case WHERE Opportunity__c = :opp.Id];
        System.assertEquals(casesAfterInsert, casesAfterUpdate,
            'US-1136 Case-first: re-evaluating an Opportunity that still matches the same rule must not create a second Case.');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // US-1501: Document Checklist Status Values
    // AC: Status picklist supports Draft, Final, Archived
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void test_US1501_draftStatusAllowed() {
        Case_Creation_Rule__c rule = [SELECT Id FROM Case_Creation_Rule__c LIMIT 1];
        Opportunity opp = makeOpp('Qualification', 100000); // below the 500k rule threshold — no Case-first side effects
        Test.startTest();
        Document_Checklist__c doc = new Document_Checklist__c(
            Opportunity__c = opp.Id, Case_Creation_Rule__c = rule.Id, Status__c = 'Draft',
            Document_Category__c = 'Scoping & Technical'
        );
        insert doc;
        Test.stopTest();

        System.assertEquals('Draft',
            [SELECT Status__c FROM Document_Checklist__c WHERE Id = :doc.Id].Status__c,
            'US-1501: Draft is a valid Document Checklist status');
    }

    @IsTest
    static void test_US1501_finalStatusAllowed() {
        Case_Creation_Rule__c rule = [SELECT Id FROM Case_Creation_Rule__c LIMIT 1];
        Opportunity opp = makeOpp('Qualification', 100000);
        Document_Checklist__c doc = new Document_Checklist__c(
            Opportunity__c = opp.Id, Case_Creation_Rule__c = rule.Id, Status__c = 'Draft',
            Document_Category__c = 'Scoping & Technical'
        );
        insert doc;

        Test.startTest();
        doc.Status__c = 'Final';
        doc.Submitted_Date__c = Date.today();
        update doc;
        Test.stopTest();

        System.assertEquals('Final',
            [SELECT Status__c FROM Document_Checklist__c WHERE Id = :doc.Id].Status__c,
            'US-1501: Final is a valid Document Checklist status');
    }

    @IsTest
    static void test_US1501_archivedStatusAllowed() {
        Case_Creation_Rule__c rule = [SELECT Id FROM Case_Creation_Rule__c LIMIT 1];
        Opportunity opp = makeOpp('Qualification', 100000);
        Document_Checklist__c doc = new Document_Checklist__c(
            Opportunity__c = opp.Id, Case_Creation_Rule__c = rule.Id, Status__c = 'Final',
            Document_Category__c = 'Scoping & Technical', Submitted_Date__c = Date.today()
        );
        insert doc;

        Test.startTest();
        doc.Status__c = 'Archived/Do Not Use';
        doc.Notes__c = 'Archiving document.';
        update doc;
        Test.stopTest();

        System.assertEquals('Archived/Do Not Use',
            [SELECT Status__c FROM Document_Checklist__c WHERE Id = :doc.Id].Status__c,
            'US-1501: Archived/Do Not Use is a valid Document Checklist status');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // US-1502: Exit Document Validation
    // AC: Case cannot be closed to Closed - Approved if any linked
    //     Document_Checklist__c records are not Final
    // AC: Case CAN close when all linked checklists are Final
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void test_US1502_caseCloseBlockedWithNonFinalDocs() {
        Account acc   = getAccount();
        Opportunity opp = makeOpp('Qualification', 600000);

        Case c = new Case(
            AccountId    = acc.Id,
            ContactId    = [SELECT Id FROM Contact LIMIT 1].Id,
            Subject      = 'Exit Validation Test',
            Status       = 'In Progress',
            Opportunity__c = opp.Id
        );
        insert c;

        // Non-Final doc linked to the Case — Case_Exit_Document_Validation_Flow matches on Case__c
        insert new Document_Checklist__c(
            Case__c = c.Id, Opportunity__c = opp.Id, Status__c = 'Draft', Document_Category__c = 'Scoping & Technical'
        );

        Test.startTest();
        Boolean blocked = false;
        try {
            c.Status = 'Closed - Approved';
            update c;
        } catch (DmlException e) {
            blocked = true;
        }
        Test.stopTest();

        System.assertEquals(true, blocked,
            'US-1502: Closing Case to Closed - Approved with non-Final Document Checklists should be blocked');
    }

    @IsTest
    static void test_US1502_caseCloseAllowedWhenAllDocsFinal() {
        Account acc   = getAccount();
        Opportunity opp = makeOpp('Qualification', 600000);

        Case c = new Case(
            AccountId    = acc.Id,
            ContactId    = [SELECT Id FROM Contact LIMIT 1].Id,
            Subject      = 'All Docs Final Test',
            Status       = 'In Progress',
            Opportunity__c = opp.Id
        );
        insert c;

        // All docs are Final — linked to the Case, matching Case_Exit_Document_Validation_Flow's Case__c filter
        insert new Document_Checklist__c(
            Case__c = c.Id, Opportunity__c = opp.Id, Status__c = 'Final',
            Document_Category__c = 'Scoping & Technical', Submitted_Date__c = Date.today()
        );

        Test.startTest();
        Boolean blocked = false;
        try {
            c.Status = 'Closed - Approved';
            update c;
        } catch (DmlException e) {
            blocked = true;
        }
        Test.stopTest();

        System.assertEquals(false, blocked,
            'US-1502: Closing Case to Closed - Approved should be allowed when all Document Checklists are Final');
    }

    @IsTest
    static void test_US1502_caseCloseAllowedWithNoLinkedDocs() {
        Account acc   = getAccount();
        Opportunity opp = makeOpp('Qualification', 600000);

        Case c = new Case(
            AccountId    = acc.Id,
            ContactId    = [SELECT Id FROM Contact LIMIT 1].Id,
            Subject      = 'No Docs Test',
            Status       = 'In Progress',
            Opportunity__c = opp.Id
        );
        insert c;
        // No Document_Checklist__c records — nothing to block

        Test.startTest();
        Boolean blocked = false;
        try {
            c.Status = 'Closed - Approved';
            update c;
        } catch (DmlException e) {
            blocked = true;
        }
        Test.stopTest();

        System.assertEquals(false, blocked,
            'US-1502: Closing Case with no linked Document Checklists should be allowed');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // US-1500: Case Queue Routing via Case_Creation_Rule__c.Queue_Developer_Name__c
    // AC: When a Support Team Engagement Case is created off a matched Case_Creation_Rule__c,
    //     OwnerId is set to that rule's Queue_Developer_Name__c (single source of truth —
    //     Touch_Level_Case_Routing__c / Support_Engagement_Case_Assignment_Flow retired).
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void test_US1500_saAssignmentCaseRoutedToSolutionSpecialistQueue() {
        // Reuses the 'SA Assignment' Case_Creation_Rule__c seeded in @TestSetup
        // (Stage=Qualification, Amount >= 500000, Queue=Solution_Specialist_Queue).
        Group ssQueue = [SELECT Id FROM Group
                         WHERE DeveloperName = 'Solution_Specialist_Queue'
                           AND Type = 'Queue' LIMIT 1];

        Test.startTest();
        Opportunity opp = makeOpp('Qualification', 600000);
        Test.stopTest();

        Case c = [SELECT OwnerId FROM Case WHERE Opportunity__c = :opp.Id AND Type = 'SA Assignment' LIMIT 1];
        System.assertEquals(ssQueue.Id, c.OwnerId,
            'US-1500: SA Assignment Case should be routed to Solution_Specialist_Queue');
    }

    @IsTest
    static void test_US1500_pricingCaseRoutedToDOCPricingQueue() {
        Group docQueue = [SELECT Id FROM Group
                          WHERE DeveloperName = 'DOC_Pricing_Queue'
                            AND Type = 'Queue' LIMIT 1];

        Case_Creation_Rule__c pricingRule = new Case_Creation_Rule__c(
            Stage__c                = 'Qualification',
            Case_Type__c            = 'Pricing',
            Record_Type_Dev_Name__c = 'Deal_Support',
            Queue_Developer_Name__c = 'DOC_Pricing_Queue',
            Logic_Expression__c     = '1',
            Is_Active__c            = true,
            Priority__c             = 20
        );
        insert pricingRule;
        insert new Case_Creation_Condition__c(
            Rule__c = pricingRule.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '200000'
        );

        Test.startTest();
        // Amount is below the shared 'SA Assignment' rule's 500000 threshold so only Pricing matches.
        Opportunity opp = makeOpp('Qualification', 250000);
        Test.stopTest();

        Case c = [SELECT OwnerId FROM Case WHERE Opportunity__c = :opp.Id AND Type = 'Pricing' LIMIT 1];
        System.assertEquals(docQueue.Id, c.OwnerId,
            'US-1500: Pricing Case should be routed to DOC_Pricing_Queue');
    }

    @IsTest
    static void test_US1500_legalCaseRoutedToLegalGCCSQueue() {
        Group legalQueue = [SELECT Id FROM Group
                            WHERE DeveloperName = 'Legal_GCCS_Queue'
                              AND Type = 'Queue' LIMIT 1];

        Case_Creation_Rule__c legalRule = new Case_Creation_Rule__c(
            Stage__c                = 'Qualification',
            Case_Type__c            = 'Legal Review',
            Record_Type_Dev_Name__c = 'Deal_Support',
            Queue_Developer_Name__c = 'Legal_GCCS_Queue',
            Logic_Expression__c     = '1',
            Is_Active__c            = true,
            Priority__c             = 30
        );
        insert legalRule;
        insert new Case_Creation_Condition__c(
            Rule__c = legalRule.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '300000'
        );

        Test.startTest();
        // Amount is below the shared 'SA Assignment' rule's 500000 threshold so only Legal Review matches.
        Opportunity opp = makeOpp('Qualification', 350000);
        Test.stopTest();

        Case c = [SELECT OwnerId FROM Case WHERE Opportunity__c = :opp.Id AND Type = 'Legal Review' LIMIT 1];
        System.assertEquals(legalQueue.Id, c.OwnerId,
            'US-1500: Legal Review Case should be routed to Legal_GCCS_Queue');
    }

    @IsTest
    static void test_US1500_caseCreatedSuccessfullyWithUnresolvableQueueDevName() {
        // Rule references a queue Developer Name that doesn't exist in the org —
        // exercises the "no queue resolved" path (createCasesForPairs leaves OwnerId
        // unset when queueIdByDevName has no match) without an invalid picklist value.
        Case_Creation_Rule__c badQueueRule = new Case_Creation_Rule__c(
            Stage__c                = 'Qualification',
            Case_Type__c            = 'Booking Verification',
            Record_Type_Dev_Name__c = 'Deal_Support',
            Queue_Developer_Name__c = 'Nonexistent_Queue_Xyz',
            Logic_Expression__c     = '1',
            Is_Active__c            = true,
            Priority__c             = 40
        );
        insert badQueueRule;
        insert new Case_Creation_Condition__c(
            Rule__c = badQueueRule.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '400000'
        );

        Test.startTest();
        Opportunity opp = makeOpp('Qualification', 450000);
        Test.stopTest();

        Case c = [SELECT Id, OwnerId FROM Case WHERE Opportunity__c = :opp.Id AND Type = 'Booking Verification' LIMIT 1];
        System.assertNotEquals(null, c.Id,
            'US-1500: Case should still be created even when its rule\'s Queue_Developer_Name__c does not resolve to a real queue');
        System.assertNotEquals(null, c.OwnerId,
            'US-1500: Case should fall back to a default owner (not error) when the queue cannot be resolved');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Reference_Threshold_Key_Flow
    // AC: Unique_Key__c auto-generated on insert (Before Save)
    // AC: Unique_Key__c updates when any key field changes
    // AC: Duplicate key combination is rejected (unique field constraint)
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void test_referenceThreshold_keyGeneratedOnInsert() {
        Test.startTest();
        Reference_Threshold__c rt = new Reference_Threshold__c(
            Name             = 'Test Threshold',
            Financial_Year__c = 'FY2026',
            Region__c        = 'LATAM',
            Cluster__c       = 'ANZ',
            Country__c       = 'Mexico',
            Volume_Profile__c = 'High Volume / High Value',
            Large_Deal__c    = 500000
        );
        insert rt;
        Test.stopTest();

        Reference_Threshold__c r = [SELECT Unique_Key__c FROM Reference_Threshold__c WHERE Id = :rt.Id];
        System.assertNotEquals(null, r.Unique_Key__c,
            'Reference_Threshold_Key_Flow: Unique_Key__c should be auto-populated on insert');
        System.assert(r.Unique_Key__c.contains('FY2026'), 'Key should contain Financial Year');
        System.assert(r.Unique_Key__c.contains('LATAM'),  'Key should contain Region');
        System.assert(r.Unique_Key__c.contains('ANZ'),    'Key should contain Cluster');
        System.assert(r.Unique_Key__c.contains('Mexico'), 'Key should contain Country');
        // Reference_Threshold_Key_Flow's formula only substitutes spaces with underscores (not slashes)
        System.assert(r.Unique_Key__c.contains('High_Volume_/_High_Value'), 'Key should contain Volume Profile');
    }

    @IsTest
    static void test_referenceThreshold_keyUpdatesOnFieldChange() {
        Reference_Threshold__c rt = new Reference_Threshold__c(
            Name = 'Key Update Test',
            Financial_Year__c = 'FY2025', Region__c = 'Europe',
            Cluster__c = 'APAC', Country__c = 'United Kingdom', Volume_Profile__c = 'Low Volume / Low Value',
            Large_Deal__c = 250000
        );
        insert rt;

        Test.startTest();
        rt.Financial_Year__c = 'FY2026';
        update rt;
        Test.stopTest();

        Reference_Threshold__c r = [SELECT Unique_Key__c FROM Reference_Threshold__c WHERE Id = :rt.Id];
        System.assert(r.Unique_Key__c.contains('FY2026'),
            'Reference_Threshold_Key_Flow: Key should update when Financial_Year__c changes');
        System.assert(!r.Unique_Key__c.contains('FY2025'),
            'Old Financial Year should not appear in updated key');
    }

    @IsTest
    static void test_referenceThreshold_duplicateKeyRejected() {
        insert new Reference_Threshold__c(
            Name = 'Original', Financial_Year__c = 'FY2026',
            Region__c = 'LATAM', Cluster__c = 'ANZ', Country__c = 'Mexico', Volume_Profile__c = 'High Volume / High Value',
            Large_Deal__c = 500000
        );

        Test.startTest();
        Boolean rejected = false;
        try {
            insert new Reference_Threshold__c(
                Name = 'Duplicate', Financial_Year__c = 'FY2026',
                Region__c = 'LATAM', Cluster__c = 'ANZ', Country__c = 'Mexico', Volume_Profile__c = 'High Volume / High Value',
                Large_Deal__c = 500000
            );
        } catch (DmlException e) {
            rejected = true;
        }
        Test.stopTest();

        System.assertEquals(true, rejected,
            'Unique_Key__c uniqueness constraint should reject duplicate FY/Region/Cluster/Country/Volume combinations');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Governor limits / bulk safety
    // ─────────────────────────────────────────────────────────────────────────

    @IsTest
    static void test_bulk_200OpportunitiesClassified() {
        Account acc = getAccount();
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            opps.add(new Opportunity(
                Name      = 'Bulk Opp ' + i,
                AccountId = acc.Id,
                RecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
                Type      = 'New Deal',
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(30),
                Pricebook2Id = Test.getStandardPricebookId(),
                Amount    = 600000
            ));
        }

        Test.startTest();
        insert opps;
        Test.stopTest();

        for (Opportunity r : [SELECT Touch_Level__c FROM Opportunity WHERE AccountId = :acc.Id]) {
            System.assertEquals('High Touch', r.Touch_Level__c,
                'Bulk: every opportunity should be classified as High Touch');
        }
    }

    @IsTest
    static void test_bulk_200CasesRoutedToQueue() {
        Account acc = getAccount();
        Group ssQueue = [SELECT Id FROM Group
                         WHERE DeveloperName = 'Solution_Specialist_Queue'
                           AND Type = 'Queue' LIMIT 1];

        // Reuses the shared 'SA Assignment' Case_Creation_Rule__c (Amount >= 500000) from @TestSetup.
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            opps.add(new Opportunity(
                Name      = 'Bulk Queue Opp ' + i,
                AccountId = acc.Id,
                RecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
                Type      = 'New Deal',
                StageName = 'Qualification',
                CloseDate = Date.today().addDays(30),
                Pricebook2Id = Test.getStandardPricebookId(),
                Amount    = 600000,
                Bypass_Validation__c = true
            ));
        }

        Test.startTest();
        insert opps;
        Test.stopTest();

        List<Case> cases = [SELECT OwnerId FROM Case WHERE Opportunity__c IN :opps AND Type = 'SA Assignment'];
        System.assertEquals(200, cases.size(), 'Bulk: every Opportunity should produce its SA Assignment Case');
        for (Case r : cases) {
            System.assertEquals(ssQueue.Id, r.OwnerId,
                'Bulk: every SA Assignment case should be routed to Solution_Specialist_Queue');
        }
    }
}