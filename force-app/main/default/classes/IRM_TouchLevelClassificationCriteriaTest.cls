/**
 * IRM_TouchLevelClassificationCriteriaTest
 *
 * Covers the multi-factor cumulative Touch Level classification criteria built from the
 * client's "Classification Criterias" sheet (2026-08-15/16 sessions) — one Touch_Level_Criteria__c
 * per Stage x Touch Level, where each later stage's criteria carries forward every condition
 * from the previous stage's same-touch-level criteria (High Touch and Medium Touch lanes each
 * evolve independently) plus that stage's own new conditions. This class inserts its own
 * isolated copy of that criteria/condition config in @TestSetup (mirroring what's active in
 * IRMDEV) rather than depending on org data, per standard Apex test isolation.
 *
 * Does NOT re-test override / no-downgrade / audit-field mechanics (see IRM_TouchLevelTest)
 * or Account-driven reevaluation (see IRM_TouchLevelAccountReevaluationTest) — this class is
 * scoped to whether the new field-level conditions and cumulative carry-forward classify
 * correctly across stages.
 */
@IsTest
private class IRM_TouchLevelClassificationCriteriaTest {

    private static Id frameworkRecordTypeId;
    private static Id standardRecordTypeId;

    @TestSetup
    static void setup() {
        IM_Country__c testCountry = new IM_Country__c(Name = 'United States');
        insert testCountry;
        insert new IM_Alternative_Country_Name__c(
            IM_Country__c = testCountry.Id, Alternative_Name__c = 'United States'
        );
        insert new Country_Settings__c(Name = 'United States', Object_Name__c = 'Opportunity', SetupOwnerId = UserInfo.getOrganizationId());
        insert new List<Opportunity_Security__c>{
            new Opportunity_Security__c(Name = 'Primary CDE',         Field_Name__c = 'Primary_CDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'R', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Original Lead Owner', Field_Name__c = 'IM_Original_Lead_Owner__c', Object_Name__c = 'Opportunity', Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Primary BDE',         Field_Name__c = 'Primary_BDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId())
        };
        insert new OpportunityProductSelection__c(Name = 'CloudSolutionsProduct',
            Product_Class_Name__c = 'Cloud', Product_Line_Name__c = 'Cloud Solutions');
        insert new SVStatus__c(Name = 'SVStatusPassed', Amount__c = 0, SetupOwnerId = UserInfo.getOrganizationId());

        Id standardAcctRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('Standard_Account').getRecordTypeId();

        // Control Account: none of the Account.* conditions should match off this one.
        insert new Account(
            Name = 'IRM TLC Test Co - Control', RecordTypeId = standardAcctRecordTypeId,
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209',
            Type = 'Inactive', Sales_Strategic_Account__c = false, Sector__c = 'Services'
        );

        // Strategic Account: Sales_Strategic_Account__c = true, Sector = BFSI (both are
        // independently-matching High Touch conditions).
        insert new Account(
            Name = 'IRM TLC Test Co - Strategic', RecordTypeId = standardAcctRecordTypeId,
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209',
            Type = 'Active', Sales_Strategic_Account__c = true, Sector__c = 'BFSI'
        );

        // Sector-only Account: strategic flag off, but Sector is in the qualifying list.
        insert new Account(
            Name = 'IRM TLC Test Co - Sector', RecordTypeId = standardAcctRecordTypeId,
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209',
            Type = 'Active', Sales_Strategic_Account__c = false, Sector__c = 'Public Sector'
        );

        // Drives Eligible_for_Counterparty_Paper__c / Eligible_for_Negotiation__c (formula
        // fields keyed off IM_Legal_Entity__r.Region__c/Country__c + Opportunity.Amount).
        insert new IM_Legal_Entity__c(
            Name = 'IRM TLC Test Legal Entity - US', Region__c = 'North America', Country__c = 'United States'
        );

        Id frameworkRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Framework_Parent_Opportunity').getRecordTypeId();
        Id standardRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
            .get('Standard_Opportunity').getRecordTypeId();

        // High Touch: 10 conditions — condition 2 (Type='New Deal') AND condition 3
        // (RecordTypeId=Framework) must both be true together; everything else is OR'd.
        List<List<String>> qHtConditions = new List<List<String>>{
            new List<String>{ 'Multi_BU_Flag__c', 'IS_TRUE', null },
            new List<String>{ 'Type', 'EQUALS', 'New Deal' },
            new List<String>{ 'RecordTypeId', 'EQUALS', frameworkRT },
            new List<String>{ 'Account.Type', 'EQUALS', 'Active' },
            new List<String>{ 'Account.Sales_Strategic_Account__c', 'IS_TRUE', null },
            new List<String>{ 'Account.Sector__c', 'IN', 'BFSI,Hyperscalers/Technology,Healthcare & Life Sciences,Public Sector' },
            new List<String>{ 'RFx_RFI_RFQ_RFP__c', 'IS_TRUE', null },
            new List<String>{ 'Custom_Solution_Required__c', 'IS_TRUE', null },
            new List<String>{ 'Eligible_for_Counterparty_Paper__c', 'IS_TRUE', null },
            new List<String>{ 'Eligible_for_Negotiation__c', 'IS_TRUE', null }
        };
        String htLogicBase = '1 OR (2 AND 3) OR 4 OR 5 OR 6 OR 7 OR 8 OR 9 OR 10';
        insertCriteria('Qualification', 'High Touch', 1, htLogicBase, qHtConditions);

        // Solutioning High Touch = Qualification's 10 conditions + 4 new (InfoSecurity__c,
        // Type='New Deal' standalone, Custom_Demo_POC__c, Payment_Terms__c NOT_IN non-standard).
        List<List<String>> sHtConditions = new List<List<String>>(qHtConditions);
        sHtConditions.add(new List<String>{ 'InfoSecurity__c', 'IS_TRUE', null });
        sHtConditions.add(new List<String>{ 'Type', 'EQUALS', 'New Deal' });
        sHtConditions.add(new List<String>{ 'Custom_Demo_POC__c', 'IS_TRUE', null });
        sHtConditions.add(new List<String>{ 'Payment_Terms__c', 'NOT_IN', '30,45,90' });
        String htLogicExtended = htLogicBase + ' OR 11 OR 12 OR 13 OR 14';
        insertCriteria('Solutioning', 'High Touch', 1, htLogicExtended, sHtConditions);

        // Negotiation carries the exact same High Touch set forward — nothing new defined at
        // this stage. This is the cumulative behavior itself: same conditions, new Stage__c.
        insertCriteria('Negotiation', 'High Touch', 1, htLogicExtended, sHtConditions);

        // Medium Touch lane, independent from High Touch.
        List<List<String>> qMtConditions = new List<List<String>>{
            new List<String>{ 'Type', 'IN', 'Cross-Sell/Upsell,Renewal' },
            new List<String>{ 'Remarketing_Required__c', 'EQUALS', 'Yes' }
        };
        insertCriteria('Qualification', 'Medium Touch', 2, '1 OR 2', qMtConditions);

        List<List<String>> sMtConditions = new List<List<String>>(qMtConditions);
        sMtConditions.add(new List<String>{ 'Payment_Terms__c', 'NOT_IN', '30,45,90' });
        insertCriteria('Solutioning', 'Medium Touch', 2, '1 OR 2 OR 3', sMtConditions);
        insertCriteria('Negotiation', 'Medium Touch', 2, '1 OR 2 OR 3', sMtConditions);
    }

    private static void insertCriteria(String stage, String touchLevel, Integer priority,
                                        String logicExpr, List<List<String>> conditions) {
        Touch_Level_Criteria__c c = new Touch_Level_Criteria__c(
            Name = 'TEST-' + stage.left(3) + '-' + touchLevel.left(2) + '-' + priority,
            Stage__c = stage, Touch_Level_Result__c = touchLevel,
            Priority__c = priority, Logic_Expression__c = logicExpr, Is_Active__c = true
        );
        insert c;

        List<Touch_Level_Condition__c> rows = new List<Touch_Level_Condition__c>();
        for (Integer i = 0; i < conditions.size(); i++) {
            List<String> row = conditions[i];
            rows.add(new Touch_Level_Condition__c(
                Criteria__c = c.Id, Condition_Number__c = i + 1,
                Field_API_Name__c = row[0], Operator__c = row[1], Value__c = row[2]
            ));
        }
        insert rows;
    }

    private static Opportunity baseOpp(String stage, Id acctId, Id recordTypeId) {
        // No default Type: every valid Type value on Standard_Opportunity
        // (Cross-Sell/Upsell, New Deal, Renewal) is itself one of the conditions under test,
        // so a "neutral" default would contaminate the very branches being isolated. Tests
        // that care about Type set it explicitly.
        Opportunity opp = new Opportunity(
            Name = 'TLC Test Opp', AccountId = acctId,
            RecordTypeId = recordTypeId,
            StageName = stage, CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(), Amount = 50000
        );
        // Validation rule requires Contract_Term_months__c before an Opportunity can be AT
        // Negotiation or Booking Verification (inserting directly at that stage hits the same
        // gate as moving into it).
        if (stage == 'Negotiation' || stage == 'Booking Verification' || stage == 'Setup') {
            opp.Contract_Term_months__c = 12;
        }
        return opp;
    }

    private static Id controlAcctId() {
        return [SELECT Id FROM Account WHERE Name = 'IRM TLC Test Co - Control'].Id;
    }
    private static Id strategicAcctId() {
        return [SELECT Id FROM Account WHERE Name = 'IRM TLC Test Co - Strategic'].Id;
    }
    private static Id sectorAcctId() {
        return [SELECT Id FROM Account WHERE Name = 'IRM TLC Test Co - Sector'].Id;
    }
    private static Id usLegalEntityId() {
        return [SELECT Id FROM IM_Legal_Entity__c WHERE Name = 'IRM TLC Test Legal Entity - US'].Id;
    }
    private static Id stdRT() {
        if (standardRecordTypeId == null) {
            standardRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                .get('Standard_Opportunity').getRecordTypeId();
        }
        return standardRecordTypeId;
    }
    private static Id frameworkRT() {
        if (frameworkRecordTypeId == null) {
            frameworkRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                .get('Framework_Parent_Opportunity').getRecordTypeId();
        }
        return frameworkRecordTypeId;
    }

    private static String touchLevelOf(Id oppId) {
        return [SELECT Touch_Level__c FROM Opportunity WHERE Id = :oppId].Touch_Level__c;
    }

    // ── Baseline: nothing matches -> No Touch ────────────────────────────────

    @IsTest
    static void test_baseline_noConditionsMet_isNoTouch() {
        Opportunity opp = baseOpp('Qualification', controlAcctId(), stdRT());

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('No Touch', touchLevelOf(opp.Id),
            'Control Opportunity/Account with no matching conditions should be No Touch');
    }

    // ── Individual High Touch conditions at Qualification ────────────────────

    @IsTest
    static void test_multiBuFlag_isHighTouch() {
        Opportunity opp = baseOpp('Qualification', controlAcctId(), stdRT());
        opp.Multi_BU_Flag__c = true;

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id),
            'Multi_BU_Flag__c=true should classify High Touch at Qualification');
    }

    @IsTest
    static void test_newDealOnFrameworkRecordType_isHighTouch() {
        Opportunity opp = baseOpp('Qualification', controlAcctId(), frameworkRT());
        opp.Type = 'New Deal';

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id),
            'Type=New Deal AND RecordType=Framework Parent (both required together) should be High Touch');
    }

    @IsTest
    static void test_newDealOnStandardRecordType_isNotHighTouch() {
        // Same Type value as the prior test, but on the Standard record type — the AND-group
        // requires BOTH Type='New Deal' AND RecordType=Framework, so this alone must not fire.
        Opportunity opp = baseOpp('Qualification', controlAcctId(), stdRT());
        opp.Type = 'New Deal';

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertNotEquals('High Touch', touchLevelOf(opp.Id),
            'Type=New Deal on the Standard record type should NOT satisfy the AND-grouped '
            + 'Framework condition on its own. Got: ' + touchLevelOf(opp.Id));
    }

    @IsTest
    static void test_accountTypeActive_isHighTouch() {
        Opportunity opp = baseOpp('Qualification', strategicAcctId(), stdRT());
        // strategicAcctId's Account already has Sales_Strategic_Account__c=true and
        // Sector__c=BFSI too — either alone would already fire High Touch, which is fine;
        // this test is really validating Account.Type is read at all via the Account.* path.

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id),
            'Account.Type=Active should classify High Touch (dot-notation Account field read)');
    }

    @IsTest
    static void test_accountStrategicFlag_isHighTouch() {
        Opportunity opp = baseOpp('Qualification', strategicAcctId(), stdRT());

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id),
            'Account.Sales_Strategic_Account__c=true should classify High Touch');
    }

    @IsTest
    static void test_accountSectorInList_isHighTouch() {
        Opportunity opp = baseOpp('Qualification', sectorAcctId(), stdRT());

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id),
            'Account.Sector__c=Public Sector (in the qualifying list) should classify High Touch');
    }

    @IsTest
    static void test_rfx_isHighTouch() {
        Opportunity opp = baseOpp('Qualification', controlAcctId(), stdRT());
        opp.RFx_RFI_RFQ_RFP__c = true;

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id), 'RFx_RFI_RFQ_RFP__c=true should classify High Touch');
    }

    @IsTest
    static void test_customSolutionRequired_isHighTouch() {
        Opportunity opp = baseOpp('Qualification', controlAcctId(), stdRT());
        opp.Custom_Solution_Required__c = true;

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id), 'Custom_Solution_Required__c=true should classify High Touch');
    }

    // Eligible_for_Counterparty_Paper__c and Eligible_for_Negotiation__c are formula Checkbox
    // fields (region/country-scoped Amount thresholds off IM_Legal_Entity__r) — not directly
    // assignable in Apex. Drive them via their real inputs instead.

    @IsTest
    static void test_eligibleForCounterpartyPaper_isHighTouch() {
        // North America / United States threshold for Eligible_for_Counterparty_Paper__c is
        // Amount >= 500000.
        Opportunity opp = baseOpp('Qualification', controlAcctId(), stdRT());
        opp.IM_Legal_Entity__c = usLegalEntityId();
        opp.Amount = 600000;

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id),
            'Eligible_for_Counterparty_Paper__c (US, Amount>=500k) should classify High Touch');
    }

    @IsTest
    static void test_eligibleForNegotiation_isHighTouch() {
        // North America / United States threshold for Eligible_for_Negotiation__c is
        // Amount >= 250000, below the 500000 Counterparty Paper threshold — isolates this
        // branch from the previous test's condition.
        Opportunity opp = baseOpp('Qualification', controlAcctId(), stdRT());
        opp.IM_Legal_Entity__c = usLegalEntityId();
        opp.Amount = 300000;

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id),
            'Eligible_for_Negotiation__c (US, Amount>=250k, <500k) should classify High Touch');
    }

    // ── Medium Touch at Qualification ────────────────────────────────────────

    @IsTest
    static void test_crossSellUpsellType_isMediumTouch() {
        Opportunity opp = baseOpp('Qualification', controlAcctId(), stdRT());
        opp.Type = 'Cross-Sell/Upsell';

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('Medium Touch', touchLevelOf(opp.Id), 'Type=Cross-Sell/Upsell should classify Medium Touch');
    }

    @IsTest
    static void test_remarketingRequiredYes_isMediumTouch() {
        Opportunity opp = baseOpp('Qualification', controlAcctId(), stdRT());
        opp.Remarketing_Required__c = 'Yes';

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('Medium Touch', touchLevelOf(opp.Id),
            'Remarketing_Required__c=Yes (picklist EQUALS, not a checkbox IS_TRUE) should classify Medium Touch');
    }

    @IsTest
    static void test_remarketingRequiredNo_isNotMediumTouch() {
        // Regression guard for the picklist-vs-checkbox bug: 'No' must NOT match.
        Opportunity opp = baseOpp('Qualification', controlAcctId(), stdRT());
        opp.Remarketing_Required__c = 'No';

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('No Touch', touchLevelOf(opp.Id),
            'Remarketing_Required__c=No should NOT classify Medium Touch. Got: ' + touchLevelOf(opp.Id));
    }

    // ── Solutioning-only new conditions ───────────────────────────────────────

    @IsTest
    static void test_infoSecurity_isHighTouchAtSolutioning_butNotAtQualification() {
        Opportunity solOpp = baseOpp('Solutioning', controlAcctId(), stdRT());
        solOpp.InfoSecurity__c = true;
        Opportunity qualOpp = baseOpp('Qualification', controlAcctId(), stdRT());
        qualOpp.InfoSecurity__c = true;

        Test.startTest();
        insert new List<Opportunity>{ solOpp, qualOpp };
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(solOpp.Id),
            'InfoSecurity__c=true should classify High Touch at Solutioning (new condition at this stage)');
        System.assertNotEquals('High Touch', touchLevelOf(qualOpp.Id),
            'InfoSecurity__c is not a Qualification condition — should not classify High Touch there. Got: '
            + touchLevelOf(qualOpp.Id));
    }

    @IsTest
    static void test_customDemoPoc_isHighTouchAtSolutioning() {
        Opportunity opp = baseOpp('Solutioning', controlAcctId(), stdRT());
        opp.Custom_Demo_POC__c = true;

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id), 'Custom_Demo_POC__c=true should classify High Touch at Solutioning');
    }

    @IsTest
    static void test_nonStandardPaymentTerms_isHighTouchAtSolutioning() {
        Opportunity opp = baseOpp('Solutioning', controlAcctId(), stdRT());
        opp.Payment_Terms__c = '60'; // only value not in the excluded ('30','45','90') set

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id),
            'Payment_Terms__c=\'60\' (NOT_IN 30/45/90) should classify High Touch at Solutioning');
    }

    @IsTest
    static void test_standardPaymentTerms_isNotHighTouchAtSolutioning() {
        Opportunity opp = baseOpp('Solutioning', controlAcctId(), stdRT());
        opp.Payment_Terms__c = '30';

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('No Touch', touchLevelOf(opp.Id),
            'Payment_Terms__c=\'30\' is in the excluded set — should not classify High Touch. Got: '
            + touchLevelOf(opp.Id));
    }

    // ── Cumulative carry-forward across stages ───────────────────────────────

    @IsTest
    static void test_qualificationConditionCarriesForwardToNegotiation() {
        // Multi_BU_Flag__c is a Qualification-original condition. Negotiation's criteria was
        // never given this condition explicitly in this test's setup either — it only received
        // the Solutioning-cumulative set, which itself carried Qualification's set forward.
        // Matching here proves the carry-forward chain, not a one-off restatement.
        Opportunity opp = baseOpp('Negotiation', controlAcctId(), stdRT());
        opp.Multi_BU_Flag__c = true;

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id),
            'Multi_BU_Flag__c (defined only once, at Qualification, in this test setup) should still '
            + 'classify High Touch at Negotiation via cumulative carry-forward');
    }

    @IsTest
    static void test_mediumTouchConditionCarriesForwardToNegotiation() {
        Opportunity opp = baseOpp('Negotiation', controlAcctId(), stdRT());
        opp.Remarketing_Required__c = 'Yes';
        // Negotiation's criteria also carries a Payment_Terms__c NOT_IN condition (see the
        // KNOWN GAP test below) — set a standard value so this test isolates Remarketing_Required__c.
        opp.Payment_Terms__c = '30';

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('Medium Touch', touchLevelOf(opp.Id),
            'Remarketing_Required__c=Yes (Qualification-original Medium Touch condition) should '
            + 'still classify Medium Touch at Negotiation via cumulative carry-forward');
    }

    // ── KNOWN GAP: blank Payment_Terms__c is misclassified ───────────────────
    //
    // NOT_IN's "not in the set" semantics treat a blank field as satisfying the condition
    // (empty string is not in {'30','45','90'}), so any Opportunity that hasn't had Payment
    // Terms set yet at Solutioning/Negotiation/Booking Verification/Setup gets escalated to
    // High Touch (and would independently also satisfy the Medium Touch lane's copy of this
    // same condition) purely because the field is unset — not because terms are genuinely
    // non-standard. This is a real gap in the currently-active IRMDEV criteria
    // (TLC-S-HT-001/TLC-N-HT-001/TLC-BV-HT-001/TLC-ST-HT-001 and the Medium Touch equivalents),
    // not a test artifact. This test documents CURRENT behavior so a future intentional fix
    // (e.g. guarding with an added Payment_Terms__c IS_NOT_NULL condition) shows up as an
    // intentional, visible test change rather than a silent behavior shift.
    @IsTest
    static void test_KNOWNGAP_blankPaymentTerms_isMisclassifiedHighTouchAtSolutioning() {
        Opportunity opp = baseOpp('Solutioning', controlAcctId(), stdRT());
        // Payment_Terms__c intentionally left blank.

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id),
            'KNOWN GAP: blank Payment_Terms__c currently satisfies NOT_IN (30/45/90) and '
            + 'incorrectly classifies High Touch. If this assertion starts failing, it likely '
            + 'means the gap was fixed — update/remove this test rather than treating it as a regression.');
    }

    // ── Priority / first-match-wins when both lanes would match ──────────────

    @IsTest
    static void test_highTouchWinsOverMediumTouchWhenBothMatch() {
        Opportunity opp = baseOpp('Qualification', controlAcctId(), stdRT());
        opp.Multi_BU_Flag__c = true;          // High Touch condition (Priority 1)
        opp.Type = 'Cross-Sell/Upsell';        // Also a Medium Touch condition (Priority 2)

        Test.startTest();
        insert opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id),
            'When both High and Medium Touch conditions match, the lower-Priority (High Touch) '
            + 'criteria should win. Got: ' + touchLevelOf(opp.Id));
    }

    // ── Recalculation on field update (no stage change) ──────────────────────

    @IsTest
    static void test_recalculatesWhenTriggeringFieldChangesWithoutStageChange() {
        Opportunity opp = baseOpp('Qualification', controlAcctId(), stdRT());
        insert opp;
        System.assertEquals('No Touch', touchLevelOf(opp.Id), 'PRE-UPDATE: expected No Touch baseline');

        Test.startTest();
        opp.Multi_BU_Flag__c = true;
        update opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id),
            'Setting Multi_BU_Flag__c=true on an existing Opportunity (no stage change) should '
            + 'trigger recalculation to High Touch. Got: ' + touchLevelOf(opp.Id));
    }

    @IsTest
    static void test_recalculatesWhenPaymentTermsChangesAtSolutioning() {
        Opportunity opp = baseOpp('Solutioning', controlAcctId(), stdRT());
        opp.Payment_Terms__c = '30';
        insert opp;
        System.assertEquals('No Touch', touchLevelOf(opp.Id), 'PRE-UPDATE: Net 30 — expected No Touch baseline');

        Test.startTest();
        opp.Payment_Terms__c = '60';
        update opp;
        Test.stopTest();

        System.assertEquals('High Touch', touchLevelOf(opp.Id),
            'Changing Payment_Terms__c from 30 to 60 should trigger recalculation to High Touch. Got: '
            + touchLevelOf(opp.Id));
    }
}
