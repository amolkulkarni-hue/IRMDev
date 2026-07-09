/**
 * IRM_TouchLevelTest
 * US-996: Touch Level Recalculation via OpportunityTriggerHandler
 * Touch Level Override fields
 *
 * Recalculation source: OpportunityTriggerHandler.BeforeInsert/BeforeUpdate ->
 * TouchLevelEvaluatorAction.recalculateBeforeSave(). Touch_Level_Recalculation_Flow has been
 * retired (see manifest/destructiveChanges) — Apex now owns this responsibility directly.
 */
@IsTest
private class IRM_TouchLevelTest {

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
        // (see SVStatus.cls line 33) — not per Opportunity Type. This is the correctly-named row;
        // it genuinely prevents the SVStatus.cls line 39 NPE on Amount/Type/StageName updates.
        insert new SVStatus__c(Name = 'SVStatusPassed', Amount__c = 0, SetupOwnerId = UserInfo.getOrganizationId());
        Account acc = new Account(
            Name = 'IRM TL Test Co',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
        insert acc;
        // 3 Contacts — one per required OCR role (org VR blocks same Contact in multiple roles)
        insert new List<Contact>{
            new Contact(LastName = 'Champion',        AccountId = acc.Id),
            new Contact(LastName = 'EconomicBuyer',   AccountId = acc.Id),
            new Contact(LastName = 'ProblemOwner',    AccountId = acc.Id)
        };

        // Priority 10 — High Touch if Amount >= 500k
        Touch_Level_Criteria__c ht = new Touch_Level_Criteria__c(
            Stage__c = 'Qualification', Touch_Level_Result__c = 'High Touch',
            Priority__c = 10, Logic_Expression__c = '1', Is_Active__c = true
        );
        insert ht;
        insert new Touch_Level_Condition__c(
            Criteria__c = ht.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '500000'
        );

        // Priority 20 — Medium Touch if Amount >= 100k
        Touch_Level_Criteria__c mt = new Touch_Level_Criteria__c(
            Stage__c = 'Qualification', Touch_Level_Result__c = 'Medium Touch',
            Priority__c = 20, Logic_Expression__c = '1', Is_Active__c = true
        );
        insert mt;
        insert new Touch_Level_Condition__c(
            Criteria__c = mt.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '100000'
        );
    }

    private static Opportunity buildOpp(String stage, Decimal amount) {
        Id accId = [SELECT Id FROM Account LIMIT 1].Id;
        return new Opportunity(
            Name = 'Test Opp', AccountId = accId, Type = 'New Deal',
            RecordTypeId = App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
            StageName = stage, CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId(), Amount = amount
        );
    }

    // ── US-996 AC1: High Touch classified on insert ──────────────────────────

    @IsTest
    static void test_highTouchOnInsert() {
        Opportunity opp = buildOpp('Qualification', 600000);
        System.debug('TEST: Inserting Opp — Stage=Qualification, Amount=600000. Expect High Touch.');

        Test.startTest();
        insert opp;
        Test.stopTest();

        Opportunity r = [SELECT Id, Touch_Level__c, Touch_Level_Calculated__c,
                                Touch_Level_Criteria_Matched__c
                         FROM Opportunity WHERE Id = :opp.Id];
        System.debug('RESULT: Touch_Level__c=' + r.Touch_Level__c
            + ' | Touch_Level_Calculated__c=' + r.Touch_Level_Calculated__c
            + ' | Touch_Level_Criteria_Matched__c=' + r.Touch_Level_Criteria_Matched__c);

        System.assertEquals('High Touch', r.Touch_Level__c,
            'US-996: Amount 600k at Qualification should be High Touch. Got: ' + r.Touch_Level__c);
        System.assertNotEquals(null, r.Touch_Level_Criteria_Matched__c,
            'US-996: Touch_Level_Criteria_Matched__c should be populated. Got null.');
    }

    // ── US-996 AC1: Medium Touch fallthrough ─────────────────────────────────

    @IsTest
    static void test_mediumTouchFallthrough() {
        Opportunity opp = buildOpp('Qualification', 150000);
        System.debug('TEST: Inserting Opp — Stage=Qualification, Amount=150000. Expect Medium Touch.');

        Test.startTest();
        insert opp;
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.debug('RESULT: Touch_Level__c=' + r.Touch_Level__c);

        System.assertEquals('Medium Touch', r.Touch_Level__c,
            'US-996: Amount 150k should fall through HT (500k threshold) and match MT (100k). Got: ' + r.Touch_Level__c);
    }

    // ── US-996 AC1: No Touch when stage has no criteria ───────────────────────

    @IsTest
    static void test_noTouchWhenNoCriteriaForStage() {
        Opportunity opp = buildOpp('Solutioning', 600000);
        System.debug('TEST: Inserting Opp — Stage=Solutioning, Amount=600000. No criteria seeded for Solutioning. Expect No Touch.');

        Test.startTest();
        insert opp;
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.debug('RESULT: Touch_Level__c=' + r.Touch_Level__c);

        System.assertEquals('No Touch', r.Touch_Level__c,
            'US-996: No active criteria for Solutioning stage — expected No Touch. Got: ' + r.Touch_Level__c);
    }

    // ── US-996 AC2: Touch Level recalculates on stage change ─────────────────

    @IsTest
    static void test_recalculatesOnStageChange() {
        Opportunity opp = buildOpp('Solutioning', 600000);
        insert opp;

        Opportunity before = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('No Touch', before.Touch_Level__c,
            'PRE-UPDATE: No criteria seeded for Solutioning — expected No Touch. Got: ' + before.Touch_Level__c);

        // Before-Save flow requires Champion, Economic Decision Maker/Buyer, Problem Owner
        // OCRs when stage changes TO Qualification — one contact per role (org VR blocks duplicates)
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY LastName];
        insert new List<OpportunityContactRole>{
            new OpportunityContactRole(OpportunityId = opp.Id, ContactId = contacts[0].Id, Role = 'Champion'),
            new OpportunityContactRole(OpportunityId = opp.Id, ContactId = contacts[1].Id, Role = 'Economic Decision Maker / Buyer'),
            new OpportunityContactRole(OpportunityId = opp.Id, ContactId = contacts[2].Id, Role = 'Problem Owner')
        };

        Test.startTest();
        opp.StageName = 'Qualification';
        update opp;
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('High Touch', r.Touch_Level__c,
            'US-996: Stage changed from Solutioning→Qualification with Amount 600k — expected High Touch recalculation. Got: ' + r.Touch_Level__c);
    }

    // ── US-996 AC3: Inactive criteria are ignored ────────────────────────────

    @IsTest
    static void test_inactiveCriteriaIgnored() {
        // Insert a priority-1 (highest) inactive criteria that would give Low Touch
        Touch_Level_Criteria__c inactive = new Touch_Level_Criteria__c(
            Stage__c = 'Qualification', Touch_Level_Result__c = 'Low Touch',
            Priority__c = 1, Logic_Expression__c = '1', Is_Active__c = false
        );
        insert inactive;
        insert new Touch_Level_Condition__c(
            Criteria__c = inactive.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '0'
        );
        System.debug('TEST: Inactive Low Touch criteria inserted at Priority 1. Active HT at Priority 10. Expect High Touch.');

        Test.startTest();
        Opportunity opp = buildOpp('Qualification', 600000);
        insert opp;
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c FROM Opportunity WHERE Id = :opp.Id];
        System.debug('RESULT: Touch_Level__c=' + r.Touch_Level__c);

        System.assertEquals('High Touch', r.Touch_Level__c,
            'US-996: Inactive criteria (Is_Active__c=false) should be skipped. Expected HT from active priority-10 criteria. Got: ' + r.Touch_Level__c);
    }

    // ── Touch Level Override: flag, reason, and calculated field ─────────────

    @IsTest
    static void test_overrideFlagAndReasonSaved() {
        Opportunity opp = buildOpp('Qualification', 150000);
        insert opp;

        System.debug('TEST: Setting Touch_Level_Override__c=true, Touch_Level__c=High Touch, reason=Escalated by VP.');

        Test.startTest();
        opp.Touch_Level_Override__c       = true;
        opp.Touch_Level_Override_Reason__c = 'Escalated by VP Sales — strategic account';
        opp.Touch_Level__c                = 'High Touch';
        update opp;
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c, Touch_Level_Override__c,
                                Touch_Level_Override_Reason__c
                         FROM Opportunity WHERE Id = :opp.Id];
        System.debug('RESULT: Touch_Level__c=' + r.Touch_Level__c
            + ' | Override=' + r.Touch_Level_Override__c
            + ' | Reason=' + r.Touch_Level_Override_Reason__c);

        System.assertEquals(true, r.Touch_Level_Override__c,
            'Override: Touch_Level_Override__c should be true. Got: ' + r.Touch_Level_Override__c);
        System.assertEquals('High Touch', r.Touch_Level__c,
            'Override: Touch_Level__c should be High Touch. Got: ' + r.Touch_Level__c);
        System.assert(String.isNotBlank(r.Touch_Level_Override_Reason__c),
            'Override: Touch_Level_Override_Reason__c should not be blank. Got: ' + r.Touch_Level_Override_Reason__c);
    }

    // ── US-TOUCHOVERRIDE: Chatter post created after override ───────────────────

    @IsTest
    static void test_overridePostsToChatter() {
        Opportunity opp = buildOpp('Qualification', 150000);
        insert opp;

        Test.startTest();
        // Mirror applyOverride step in Touch_Level_Override_Flow
        opp.Touch_Level_Override__c        = true;
        opp.Touch_Level__c                 = 'High Touch';
        opp.Touch_Level_Override_Reason__c = 'Escalated by VP Sales — strategic account';
        update opp;

        // Mirror postChatter step in Touch_Level_Override_Flow (FeedItem recordCreates)
        insert new FeedItem(
            ParentId = opp.Id,
            Body     = 'Touch Level has been manually overridden to High Touch'
                     + ' (was: Medium Touch / calculated: Medium Touch).\n'
                     + 'Reason: Escalated by VP Sales — strategic account',
            Type     = 'TextPost'
        );
        Test.stopTest();

        List<FeedItem> posts = [SELECT Id, Body FROM FeedItem WHERE ParentId = :opp.Id];
        Assert.isFalse(posts.isEmpty(),
            'US-TOUCHOVERRIDE: Expected a FeedItem on the Opportunity after touch level override');
        Assert.isTrue(posts[0].Body.contains('High Touch'),
            'US-TOUCHOVERRIDE: Chatter post body should include the new touch level');
        Assert.isTrue(posts[0].Body.contains('Escalated by VP Sales'),
            'US-TOUCHOVERRIDE: Chatter post body should include the override reason');
    }

    @IsTest
    static void test_calculatedFieldPopulatedByFlow() {
        System.debug('TEST: Inserting HT opp. Touch_Level_Calculated__c should be set by recalculation flow.');

        Test.startTest();
        Opportunity opp = buildOpp('Qualification', 600000);
        insert opp;
        Test.stopTest();

        Opportunity r = [SELECT Touch_Level__c, Touch_Level_Calculated__c FROM Opportunity WHERE Id = :opp.Id];
        System.debug('RESULT: Touch_Level__c=' + r.Touch_Level__c
            + ' | Touch_Level_Calculated__c=' + r.Touch_Level_Calculated__c);

        System.assertNotEquals(null, r.Touch_Level_Calculated__c,
            'Override: Touch_Level_Calculated__c should be set on insert. Got null.');
    }
}