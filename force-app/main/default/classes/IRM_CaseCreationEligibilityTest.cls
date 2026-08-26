/**
 * IRM_CaseCreationEligibilityTest
 *
 * Proves the dynamic field-diffing fix for Case Creation eligibility: recalculation now fires
 * on ANY field referenced by an active Case_Creation_Condition__c (plus StageName), rather than
 * the old Case_Creation_Eligibility_Flow's hardcoded Touch_Level_Calculated__c-only trigger.
 * Also proves Phase 1 (Draft Document_Checklist__c creation) — previously an unfinished
 * Flow Builder stub — is now fully implemented in Apex.
 *
 * Recalculation source: OpportunityTriggerHandler.AfterInsert/AfterUpdate ->
 * CaseCreationRuleEvaluatorAction.createEligibleChecklistsAfterSave().
 *
 * None of these scenarios change StageName, so the "Qual_*_Required" stage-gate validation
 * rules (which only fire on a Qualification -> Solutioning transition) never trigger here —
 * the Opportunity setup is intentionally simpler than IRM_TouchLevelProgressionTest's.
 */
@IsTest
private class IRM_CaseCreationEligibilityTest {

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
        // Correctly-named SVStatus__c row (Name must be exactly 'SVStatusPassed') — genuinely
        // prevents the SVStatus.cls line 39 NPE on Amount/Type/StageName updates.
        insert new SVStatus__c(Name = 'SVStatusPassed', Amount__c = 0, SetupOwnerId = UserInfo.getOrganizationId());

        insert new Account(
            Name = 'IRM Case Creation Eligibility Test Co',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
    }

    private static Id getAccountId() {
        return [SELECT Id FROM Account LIMIT 1].Id;
    }

    private static Opportunity buildOpp(String productLine, Decimal amount) {
        return new Opportunity(
            Name = 'Case Creation Eligibility Test Opp',
            AccountId = getAccountId(),
            RecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
            Type = 'New',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(),
            Amount = amount,
            Primary_Product_Line__c = productLine
        );
    }

    private static Case_Creation_Rule__c makeRule(String caseType, String logicExpr) {
        Case_Creation_Rule__c rule = new Case_Creation_Rule__c(
            Stage__c = 'Qualification', Case_Type__c = caseType,
            Record_Type_Dev_Name__c = 'Deal_Support',
            Queue_Developer_Name__c = 'Solution_Specialist_Queue',
            Logic_Expression__c = logicExpr, Is_Active__c = true, Priority__c = 100
        );
        insert rule;
        return rule;
    }

    private static Integer checklistCount(Id oppId, Id ruleId, String docType) {
        return [
            SELECT COUNT() FROM Document_Checklist__c
            WHERE Opportunity__c = :oppId AND Case_Creation_Rule__c = :ruleId AND Doc_Type__c = :docType
        ];
    }

    // ── Scenario 1: dynamic field-change trigger — a Case_Creation_Condition__c field alone ──

    @IsTest
    static void test_dynamicFieldChange_conditionFieldAloneTriggersChecklistCreation() {
        Case_Creation_Rule__c rule = makeRule('Test Type A', '1');
        insert new Case_Creation_Condition__c(
            Rule__c = rule.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Primary_Product_Line__c', Operator__c = 'EQUALS', Value__c = 'Secure Shredding'
        );
        insert new Case_Creation_Doc_Requirement__c(
            Rule__c = rule.Id, Doc_Type__c = 'Business Problem Statement',
            Doc_Category__c = 'Scoping & Technical',
            Is_Required_To_Start__c = true, Is_Required_For_Case__c = true
        );

        Test.startTest();
        Opportunity opp = buildOpp('Data Centers', 50000); // does not match
        insert opp;
        System.assertEquals(0, checklistCount(opp.Id, rule.Id, 'Business Problem Statement'),
            'No checklist should exist before the condition field matches');

        opp.Primary_Product_Line__c = 'Secure Shredding'; // now matches — StageName untouched
        update opp;
        Test.stopTest();

        System.assertEquals(1, checklistCount(opp.Id, rule.Id, 'Business Problem Statement'),
            'Changing only Primary_Product_Line__c (a Case_Creation_Condition__c field, not watched by Touch Level) should trigger checklist creation — impossible under the old Touch_Level_Calculated__c-only trigger');
    }

    // ── Scenario 2: negative control — an unrelated field change does not re-trigger ──

    @IsTest
    static void test_negativeControl_unrelatedFieldChangeDoesNotDuplicateChecklist() {
        Case_Creation_Rule__c rule = makeRule('Test Type A', '1');
        insert new Case_Creation_Condition__c(
            Rule__c = rule.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Primary_Product_Line__c', Operator__c = 'EQUALS', Value__c = 'Secure Shredding'
        );
        insert new Case_Creation_Doc_Requirement__c(
            Rule__c = rule.Id, Doc_Type__c = 'Business Problem Statement',
            Doc_Category__c = 'Scoping & Technical',
            Is_Required_To_Start__c = true, Is_Required_For_Case__c = true
        );

        Test.startTest();
        Opportunity opp = buildOpp('Secure Shredding', 50000); // matches on insert
        insert opp;
        System.assertEquals(1, checklistCount(opp.Id, rule.Id, 'Business Problem Statement'),
            'Checklist should be created on insert since the rule matches immediately');

        opp.Description = 'Unrelated note not referenced by any active Case_Creation_Condition__c';
        update opp;
        Test.stopTest();

        System.assertEquals(1, checklistCount(opp.Id, rule.Id, 'Business Problem Statement'),
            'Changing only an unrelated field should not create a second checklist — proving precise diffing, not recalculate-on-every-save');
    }

    // ── Scenario 3: duplicate prevention — repeated relevant changes don't duplicate ──

    @IsTest
    static void test_duplicatePrevention_repeatedRelevantChangesDontDuplicate() {
        Case_Creation_Rule__c rule = makeRule('Test Type Dup', '1');
        insert new Case_Creation_Condition__c(
            Rule__c = rule.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '100000'
        );
        insert new Case_Creation_Doc_Requirement__c(
            Rule__c = rule.Id, Doc_Type__c = 'Technical Scoping Form',
            Doc_Category__c = 'Scoping & Technical',
            Is_Required_To_Start__c = true, Is_Required_For_Case__c = true
        );

        Test.startTest();
        Opportunity opp = buildOpp('Data Centers', 50000); // does not match
        insert opp;

        opp.Amount = 150000; // now matches — Amount is a watched field
        update opp;
        System.assertEquals(1, checklistCount(opp.Id, rule.Id, 'Technical Scoping Form'),
            'First relevant Amount change into matching range should create exactly one checklist');

        opp.Amount = 200000; // still matches, Amount changes again
        update opp;
        Test.stopTest();

        System.assertEquals(1, checklistCount(opp.Id, rule.Id, 'Technical Scoping Form'),
            'A second relevant field change should not create a duplicate checklist for the same (Opportunity, Rule, DocType)');
    }

    // ── Scenario 4: multiple simultaneous rule matches ──

    @IsTest
    static void test_multipleSimultaneousRuleMatches() {
        Case_Creation_Rule__c ruleX = makeRule('Test Type X', null); // unconditional
        insert new Case_Creation_Doc_Requirement__c(
            Rule__c = ruleX.Id, Doc_Type__c = 'Financial Sign-off',
            Doc_Category__c = 'Approvals & Sign-off',
            Is_Required_To_Start__c = true, Is_Required_For_Case__c = true
        );
        Case_Creation_Rule__c ruleY = makeRule('Test Type Y', null); // unconditional
        insert new Case_Creation_Doc_Requirement__c(
            Rule__c = ruleY.Id, Doc_Type__c = 'Governing Agreement',
            Doc_Category__c = 'Contract & Legal',
            Is_Required_To_Start__c = true, Is_Required_For_Case__c = true
        );

        Test.startTest();
        Opportunity opp = buildOpp('Data Centers', 50000);
        insert opp; // both unconditional rules match immediately
        Test.stopTest();

        System.assertEquals(1, checklistCount(opp.Id, ruleX.Id, 'Financial Sign-off'),
            'Unconditional Rule X should produce its own Draft checklist');
        System.assertEquals(1, checklistCount(opp.Id, ruleY.Id, 'Governing Agreement'),
            'Unconditional Rule Y should also produce its own Draft checklist — an Opportunity can trigger multiple Case Creation Rules at once');
    }

    // ── Scenario 5: resilience — a misconfigured doc requirement doesn't block the rest ──

    @IsTest
    static void test_resilience_missingDocCategoryDoesNotBlockOtherChecklists() {
        Case_Creation_Rule__c rule = makeRule('Test Type Z', null); // unconditional
        insert new Case_Creation_Doc_Requirement__c(
            Rule__c = rule.Id, Doc_Type__c = 'Risk Mitigation Plan',
            Doc_Category__c = null, // intentionally missing — Doc_Category__c is required
            Is_Required_To_Start__c = true, Is_Required_For_Case__c = true
        );
        insert new Case_Creation_Doc_Requirement__c(
            Rule__c = rule.Id, Doc_Type__c = 'Legal Risk Sign-off',
            Doc_Category__c = 'Approvals & Sign-off',
            Is_Required_To_Start__c = true, Is_Required_For_Case__c = true
        );

        Test.startTest();
        Opportunity opp = buildOpp('Data Centers', 50000);
        insert opp; // must not throw despite one bad doc requirement
        Test.stopTest();

        Opportunity saved = [SELECT Id FROM Opportunity WHERE Id = :opp.Id];
        System.assertNotEquals(null, saved.Id, 'The Opportunity insert itself must succeed despite one misconfigured doc requirement');

        System.assertEquals(0, checklistCount(opp.Id, rule.Id, 'Risk Mitigation Plan'),
            'The checklist missing a required Doc_Category__c should fail to insert (partial success), not exist');
        System.assertEquals(1, checklistCount(opp.Id, rule.Id, 'Legal Risk Sign-off'),
            'The properly-configured checklist in the same batch should still be created despite the other row failing');
    }

    // ── Scenario 6: Opportunity_Touch_Level__c is stamped on the created Case ──

    @IsTest
    static void test_opportunityTouchLevelStampedOnCase() {
        Case_Creation_Rule__c rule = makeRule('Test Type TL', null); // unconditional

        Test.startTest();
        Opportunity opp = buildOpp('Data Centers', 50000);
        insert opp;
        Test.stopTest();

        Opportunity savedOpp = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        Case createdCase = [
            SELECT Opportunity_Touch_Level__c FROM Case
            WHERE Opportunity__c = :opp.Id AND Case_Creation_Rule__c = :rule.Id
            LIMIT 1
        ];

        System.assertEquals(savedOpp.Touch_Level__c, createdCase.Opportunity_Touch_Level__c,
            'Case.Opportunity_Touch_Level__c should be stamped with the Opportunity\'s Touch Level at Case creation time. Got: '
            + createdCase.Opportunity_Touch_Level__c);
    }
}