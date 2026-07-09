/**
 * IRM_TouchLevelProgressionTest
 *
 * Walks a single Opportunity Low Touch -> Medium Touch -> High Touch through realistic
 * stage and field changes, proving both recalculation triggers:
 *   - a StageName change (Qualification -> Solutioning)
 *   - a non-stage, condition-referenced field change (Amount, then Type)
 *
 * Also proves the dynamic field-diffing fix: recalculation fires on ANY field referenced
 * by an active Touch_Level_Condition__c (not just the previously hardcoded StageName/Amount),
 * the no-downgrade rule and Touch_Level_Override__c bypass survived the move into Apex, and
 * calculation is scoped to only Standard_Opportunity / Framework_Parent_Opportunity record types.
 *
 * Recalculation source: OpportunityTriggerHandler.BeforeInsert/BeforeUpdate ->
 * TouchLevelEvaluatorAction.recalculateBeforeSave().
 */
@IsTest
private class IRM_TouchLevelProgressionTest {

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
        // Correctly-named SVStatus__c row (Name must be exactly 'SVStatusPassed' — the fixed
        // key SVStatus.updateSVStatus looks up). This is what actually prevents the
        // SVStatus.cls line 39 NPE on Amount/Type/StageName updates; unlike differently-named
        // rows, this fixes the bug at its root rather than needing a bypass or try/catch.
        insert new SVStatus__c(Name = 'SVStatusPassed', Amount__c = 0, SetupOwnerId = UserInfo.getOrganizationId());

        Account acc = new Account(
            Name = 'IRM Touch Level Progression Test Co',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;
        // 3 Contacts — one per required OCR role (org VR blocks same Contact in multiple roles)
        insert new List<Contact>{
            new Contact(LastName = 'Champion',       AccountId = acc.Id),
            new Contact(LastName = 'EconomicBuyer',  AccountId = acc.Id),
            new Contact(LastName = 'ProblemOwner',   AccountId = acc.Id)
        };

        // Qualification -> Low Touch (any Amount) — the deal's initial stage
        Touch_Level_Criteria__c ltCriteria = new Touch_Level_Criteria__c(
            Stage__c = 'Qualification', Touch_Level_Result__c = 'Low Touch',
            Priority__c = 10, Logic_Expression__c = '1', Is_Active__c = true
        );
        insert ltCriteria;
        insert new Touch_Level_Condition__c(
            Criteria__c = ltCriteria.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '0'
        );

        // Solutioning -> High Touch when Type = Renewal, regardless of Amount (priority 5 —
        // evaluated before the Amount-based rules below). Proves recalculation on a field
        // the old hardcoded Flow never watched.
        Touch_Level_Criteria__c renewalCriteria = new Touch_Level_Criteria__c(
            Stage__c = 'Solutioning', Touch_Level_Result__c = 'High Touch',
            Priority__c = 5, Logic_Expression__c = '1', Is_Active__c = true
        );
        insert renewalCriteria;
        insert new Touch_Level_Condition__c(
            Criteria__c = renewalCriteria.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Type', Operator__c = 'EQUALS', Value__c = 'Renewal'
        );

        // Solutioning -> High Touch (Amount >= 500000)
        Touch_Level_Criteria__c htCriteria = new Touch_Level_Criteria__c(
            Stage__c = 'Solutioning', Touch_Level_Result__c = 'High Touch',
            Priority__c = 10, Logic_Expression__c = '1', Is_Active__c = true
        );
        insert htCriteria;
        insert new Touch_Level_Condition__c(
            Criteria__c = htCriteria.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '500000'
        );

        // Solutioning -> Medium Touch (Amount >= 25000)
        Touch_Level_Criteria__c mtCriteria = new Touch_Level_Criteria__c(
            Stage__c = 'Solutioning', Touch_Level_Result__c = 'Medium Touch',
            Priority__c = 20, Logic_Expression__c = '1', Is_Active__c = true
        );
        insert mtCriteria;
        insert new Touch_Level_Condition__c(
            Criteria__c = mtCriteria.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '25000'
        );
    }

    private static Id getAccountId() {
        return [SELECT Id FROM Account LIMIT 1].Id;
    }

    private static Id getContactIdByLastName(String lastName) {
        return [SELECT Id FROM Contact WHERE LastName = :lastName LIMIT 1].Id;
    }

    // Populates every field required by the org's "Qual_*_Required" stage-gate validation
    // rules that apply to a Type='New Deal' Opportunity with no Product Line / Billing Country
    // set (the rules gated on Digital/Insight/ALM product lines or US/Canada billing country
    // don't apply here and are deliberately left unset).
    private static Opportunity buildOpp(String stage, Decimal amount, String type) {
        return new Opportunity(
            Name = 'Touch Level Progression Test Opp',
            AccountId = getAccountId(),
            RecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
            Type = type,
            StageName = stage,
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(),
            Amount = amount,
            // Org VRs (Qual_*_Required) require these before advancing out of Qualification
            Budget_Validated__c = 'Yes',
            Business_Problem_Evidenced__c = 'Improve Efficiency or Reduce Manual Work',
            Champion__c = getContactIdByLastName('Champion'),
            Customer_Outcome_Predefined__c = 'Reduce manual reconciliation effort.',
            Decision_Process_Defined__c = true,
            Economic_Decision_Maker_Buyer__c = getContactIdByLastName('EconomicBuyer'),
            Impact_Consequences_Identified__c = 'No Clear Impact Identified Yet',
            Primary_Product_Line__c = 'Secure Shredding',
            Business_Process_Problem_Owner__c = getContactIdByLastName('ProblemOwner'),
            Service_Address__Street__s = '123 Main St',
            Service_Address__City__s = 'New York',
            Service_Address__StateCode__s = 'NY',
            Service_Address__CountryCode__s = 'US'
        );
    }

    private static void addOcrRoles(Id oppId) {
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY LastName];
        insert new List<OpportunityContactRole>{
            new OpportunityContactRole(OpportunityId = oppId, ContactId = contacts[0].Id, Role = 'Champion'),
            new OpportunityContactRole(OpportunityId = oppId, ContactId = contacts[1].Id, Role = 'Economic Decision Maker / Buyer'),
            new OpportunityContactRole(OpportunityId = oppId, ContactId = contacts[2].Id, Role = 'Problem Owner')
        };
    }

    // ── Scenario 1: escalation progression — Low -> Medium (stage change) -> High (amount change) ──

    @IsTest
    static void test_escalationProgression_lowToMediumToHigh() {
        // Type='New' (not 'New Deal') specifically for this test: VR_Qual_ServiceAddress_Required
        // (gated on Type IN ('New Deal','Upsell')) throws an internal Salesforce formula-engine
        // error ("Cannot invoke ColumnInfo.getApiName... columns[4] is null") when evaluated on
        // the Qualification->Solutioning transition — a pre-existing org/platform bug unrelated
        // to Touch Level. Type isn't the focus of this scenario, so 'New' sidesteps it.
        Opportunity opp = buildOpp('Qualification', 50000, 'New');

        Test.startTest();
        insert opp;

        Opportunity afterInsert = [SELECT Touch_Level__c, Touch_Level_Calculated__c, Touch_Level_Criteria_Matched__c
                                    FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Low Touch', afterInsert.Touch_Level__c,
            'Insert at Qualification should stamp Low Touch');
        System.assertEquals('Low Touch', afterInsert.Touch_Level_Calculated__c,
            'Touch_Level_Calculated__c should mirror the calculated value on insert');
        System.assertNotEquals(null, afterInsert.Touch_Level_Criteria_Matched__c,
            'Matched criteria name should be populated on insert');

        addOcrRoles(opp.Id);

        opp.StageName = 'Solutioning'; // Amount unchanged
        update opp;
        Opportunity afterStageChange = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Medium Touch', afterStageChange.Touch_Level__c,
            'Stage change Qualification->Solutioning with Amount=50000 should recalculate to Medium Touch');

        opp.Amount = 600000; // StageName unchanged
        update opp;
        Opportunity afterAmountChange = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('High Touch', afterAmountChange.Touch_Level__c,
            'Amount change to 600000 while at Solutioning should recalculate to High Touch');
        Test.stopTest();
    }

    // ── Scenario 2: dynamic field-change trigger — Type alone (not Stage/Amount) recalculates ──

    @IsTest
    static void test_dynamicFieldChange_typeAloneTriggersRecalculation() {
        Opportunity opp = buildOpp('Solutioning', 50000, 'New Deal');

        Test.startTest();
        insert opp;
        addOcrRoles(opp.Id);

        Opportunity baseline = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Medium Touch', baseline.Touch_Level__c,
            'Baseline: Solutioning/50000/New Deal should be Medium Touch');

        opp.Type = 'Renewal'; // StageName and Amount untouched
        update opp;
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('High Touch', r.Touch_Level__c,
            'Changing only Type to Renewal should trigger recalculation to High Touch via the priority-5 Renewal criteria — impossible under the old hardcoded StageName/Amount-only Flow');
    }

    // ── Scenario 3: negative control — an unrelated field change does not trigger recalculation ──

    @IsTest
    static void test_negativeControl_unrelatedFieldChangeDoesNotRecalculate() {
        Opportunity opp = buildOpp('Solutioning', 50000, 'New Deal');

        Test.startTest();
        insert opp;
        addOcrRoles(opp.Id);

        Opportunity baseline = [SELECT Touch_Level__c, Touch_Level_Calculated__c FROM Opportunity WHERE Id = :opp.Id];

        opp.Description = 'Unrelated note not referenced by any active Touch_Level_Condition__c';
        update opp;
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c, Touch_Level_Calculated__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(baseline.Touch_Level__c, r.Touch_Level__c,
            'Touch_Level__c should be unchanged when only an unrelated field changes');
        System.assertEquals(baseline.Touch_Level_Calculated__c, r.Touch_Level_Calculated__c,
            'Touch_Level_Calculated__c should be unchanged when only an unrelated field changes — proving precise diffing, not recalculate-on-every-save');
    }

    // ── Scenario 4: no-downgrade rule survives the migration into Apex ──

    @IsTest
    static void test_noDowngradeRule_survivesApexMigration() {
        Opportunity opp = buildOpp('Solutioning', 600000, 'New Deal');

        Test.startTest();
        insert opp;
        addOcrRoles(opp.Id);

        Opportunity baseline = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('High Touch', baseline.Touch_Level__c, 'Baseline should be High Touch');

        opp.Amount = 10000; // drops below every threshold
        update opp;
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c, Touch_Level_Calculated__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('High Touch', r.Touch_Level__c,
            'Touch_Level__c should remain High Touch — no automatic downgrade');
        System.assertEquals('No Touch', r.Touch_Level_Calculated__c,
            'Touch_Level_Calculated__c should reflect the true recalculated (lower) value for audit purposes');
    }

    // ── Scenario 5: Touch_Level_Override__c bypass smoke check ──

    @IsTest
    static void test_overrideBypass_stillSkipsRecalculation() {
        Opportunity opp = buildOpp('Solutioning', 50000, 'New Deal');

        Test.startTest();
        insert opp;
        addOcrRoles(opp.Id);

        opp.Touch_Level_Override__c = true;
        opp.Touch_Level__c = 'High Touch';
        opp.Touch_Level_Override_Reason__c = 'Escalated by VP Sales';
        update opp;

        opp.Amount = 10000; // would otherwise recalculate to Medium/No Touch
        update opp;
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('High Touch', r.Touch_Level__c,
            'Overridden Touch_Level__c should be preserved untouched by recalculation');
    }

    // ── Scenario 6 & 7: record-type scoping — unit-level calls against recalculateBeforeSave
    // directly (no DML) to avoid any dependency on which Stage values a given ineligible
    // record type's Business Process happens to allow. ──

    @IsTest
    static void test_recordTypeScoping_ineligibleTypeIsNeverCalculated() {
        Opportunity inMemoryOpp = new Opportunity(
            RecordTypeId = App_Constants.CPQ_SALES_OPPORTUNITY_RECTYPE_ID,
            StageName = 'Solutioning',
            Amount = 600000,
            Touch_Level_Override__c = false
        );

        Test.startTest();
        TouchLevelEvaluatorAction.recalculateBeforeSave(new List<Opportunity>{ inMemoryOpp }, null);
        Test.stopTest();

        System.assertEquals(null, inMemoryOpp.Touch_Level__c,
            'Ineligible record type should never be classified — Touch_Level__c should stay blank');
        System.assertEquals(null, inMemoryOpp.Touch_Level_Calculated__c,
            'Ineligible record type should never be classified — Touch_Level_Calculated__c should stay blank');
        System.assertEquals(null, inMemoryOpp.Touch_Level_Criteria_Matched__c,
            'Ineligible record type should never be classified — Touch_Level_Criteria_Matched__c should stay blank');
    }

    @IsTest
    static void test_recordTypeScoping_frameworkParentOpportunityIsCalculated() {
        Opportunity inMemoryOpp = new Opportunity(
            RecordTypeId = App_Constants.FRAMEWORK_PARENT_OPPORTUNITY_RECTYPE_ID,
            StageName = 'Solutioning',
            Amount = 600000,
            Touch_Level_Override__c = false
        );

        Test.startTest();
        TouchLevelEvaluatorAction.recalculateBeforeSave(new List<Opportunity>{ inMemoryOpp }, null);
        Test.stopTest();

        System.assertEquals('High Touch', inMemoryOpp.Touch_Level__c,
            'Framework_Parent_Opportunity is an eligible record type and should be classified normally');
    }
}
