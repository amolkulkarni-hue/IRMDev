/**
 * IRM_CaseCompletionTest
 * US-CASECOMP: Case % Completion field driven by Case_Status_Progress__c config
 *
 * Flows under test:
 *   Case_Completion_Update_Flow (After Save — Case, Update, Status/All_Exit_Docs_Final__c changed)
 *   Doc_Checklist_Completion_Sync_Flow (After Save — Document_Checklist__c, Create/Update)
 * Both flows must be ACTIVE before running.
 *
 * Config: Case_Status_Progress__c records are inserted in @TestSetup (custom object — DML allowed).
 * Note: Status_Value__c must match valid Case Status picklist values in the target org.
 *       If a test fails with "invalid picklist value", update @TestSetup status strings accordingly.
 */
@IsTest
private class IRM_CaseCompletionTest {

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
        insert new List<SVStatus__c>{
            new SVStatus__c(Name = 'New Deal',  Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Renewal',   Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Add-On',    Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Expansion', Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId())
        };
        insert new Account(
            Name = 'Case Completion Test Co',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );

        // Config: Deal_Support status → weight mapping
        // Status_Value__c must match valid Case.Status picklist values in the org
        insert new List<Case_Status_Progress__c>{
            new Case_Status_Progress__c(Case_Record_Type_Dev_Name__c = 'Deal_Support', Status_Value__c = 'New',     Progress_Pct__c = 0),
            new Case_Status_Progress__c(Case_Record_Type_Dev_Name__c = 'Deal_Support', Status_Value__c = 'Working', Progress_Pct__c = 50),
            new Case_Status_Progress__c(Case_Record_Type_Dev_Name__c = 'Deal_Support', Status_Value__c = 'Closed',  Progress_Pct__c = 90)
        };
    }

    private static Account getAccount() {
        return [SELECT Id FROM Account LIMIT 1];
    }

    private static Id getDealSupportRTId() {
        return [SELECT Id FROM RecordType WHERE DeveloperName = 'Deal_Support' AND SObjectType = 'Case'].Id;
    }

    private static Case insertCase(String status) {
        Case c = new Case(
            AccountId = getAccount().Id,
            Subject = 'Completion Test — ' + status,
            Status = status,
            Origin = 'Web',
            RecordTypeId = getDealSupportRTId()
        );
        insert c;
        return c;
    }

    // ── Status → Pct: status change sets completion from config ─────────────

    @IsTest
    static void test_statusChangeSetsCompletionPct() {
        Case c = insertCase('New');
        // Completion flow is Update-only — Pct stays null after Case INSERT

        Test.startTest();
        c.Status = 'Working';
        update c;
        Test.stopTest();

        Case updated = [SELECT Case_Completion_Pct__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(50, updated.Case_Completion_Pct__c,
            'Status "Working" should map to 50% from config. Got: ' + updated.Case_Completion_Pct__c);
    }

    // ── No config: status with no config record leaves Pct null ─────────────

    @IsTest
    static void test_noConfigRecordLeavesNullPct() {
        Case c = insertCase('New');

        Test.startTest();
        c.Status = 'Escalated'; // no Case_Status_Progress__c row for this status
        update c;
        Test.stopTest();

        Case updated = [SELECT Case_Completion_Pct__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(null, updated.Case_Completion_Pct__c,
            'Status with no config record should leave Completion Pct null (flow exits early). Got: ' + updated.Case_Completion_Pct__c);
    }

    // ── Doc gate: weight 90 + Draft doc present → capped at 90, not 100 ────

    @IsTest
    static void test_docGateCapsAt90WhenDocsNotFinal() {
        // INSERT Case with Status='Closed' — Before-Save validation only fires on UPDATE, not INSERT
        Case c = insertCase('Closed');

        // Inserting a Draft doc triggers: Sync flow → All_Exit_Docs_Final__c=false
        // → Completion flow fires (All_Exit_Docs_Final__c IsChanged) → Status='Closed' weight=90, gate=false → Pct=90
        Test.startTest();
        insert new Document_Checklist__c(
            Case__c = c.Id, Status__c = 'Draft',
            Document_Category__c = 'Scoping & Technical'
        );
        Test.stopTest();

        Case updated = [SELECT Case_Completion_Pct__c, All_Exit_Docs_Final__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(false, updated.All_Exit_Docs_Final__c,
            'All_Exit_Docs_Final__c should be false because a Draft doc exists.');
        System.assertEquals(90, updated.Case_Completion_Pct__c,
            'Weight 90 + docs not Final should stay at 90% (gate blocks upgrade to 100%). Got: ' + updated.Case_Completion_Pct__c);
    }

    // ── Doc gate lift: finalize all docs triggers upgrade to 100% ───────────

    @IsTest
    static void test_allDocsFinalUpgradesTo100() {
        Case c = insertCase('New');

        // Set Status to a high-weight value first (gates at 90 because no docs yet → gate=true → 100)
        c.Status = 'Closed';
        update c;

        // Insert a Draft doc: Sync flow → All_Exit_Docs_Final__c=false → Completion flow → Pct=90
        Document_Checklist__c doc = new Document_Checklist__c(
            Case__c = c.Id, Status__c = 'Draft',
            Document_Category__c = 'Scoping & Technical'
        );
        insert doc;

        Case beforeFinalize = [SELECT Case_Completion_Pct__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(90, beforeFinalize.Case_Completion_Pct__c,
            'Draft doc present + weight 90 should hold at 90% before finalization.');

        Test.startTest();
        doc.Status__c = 'Final';
        doc.Submitted_Date__c = Date.today();
        update doc;
        Test.stopTest();

        // Sync flow: All_Exit_Docs_Final__c → true → Completion flow: weight 90 + gate true → 100%
        Case updated = [SELECT Case_Completion_Pct__c, All_Exit_Docs_Final__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(true, updated.All_Exit_Docs_Final__c,
            'All_Exit_Docs_Final__c should be true after all docs are Final.');
        System.assertEquals(100, updated.Case_Completion_Pct__c,
            'Weight 90 + all docs Final should upgrade to 100%. Got: ' + updated.Case_Completion_Pct__c);
    }

    // ── No docs: All_Exit_Docs_Final__c defaults true → weight 90 → 100% ───

    @IsTest
    static void test_noDocsDefaultGateAllowsHundredPct() {
        Test.startTest();
        Case c = insertCase('New');
        c.Status = 'Closed'; // config Pct=90; no docs → All_Exit_Docs_Final__c=true → gate passes → 100%
        update c;
        Test.stopTest();

        Case updated = [SELECT Case_Completion_Pct__c, All_Exit_Docs_Final__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(true, updated.All_Exit_Docs_Final__c,
            'Case with no linked docs should have All_Exit_Docs_Final__c = true (default).');
        System.assertEquals(100, updated.Case_Completion_Pct__c,
            'Weight 90 + All_Exit_Docs_Final__c true (no docs) should yield 100%. Got: ' + updated.Case_Completion_Pct__c);
    }

    // ── Sync flow: inserting a Draft doc flips All_Exit_Docs_Final__c = false ─

    @IsTest
    static void test_newDraftDocFlipsGateToFalse() {
        Case c = insertCase('New');
        System.assertEquals(true, [SELECT All_Exit_Docs_Final__c FROM Case WHERE Id = :c.Id].All_Exit_Docs_Final__c,
            'All_Exit_Docs_Final__c should default to true on Case creation (no docs).');

        Test.startTest();
        insert new Document_Checklist__c(
            Case__c = c.Id, Status__c = 'Draft',
            Document_Category__c = 'Scoping & Technical'
        );
        Test.stopTest();

        System.assertEquals(false, [SELECT All_Exit_Docs_Final__c FROM Case WHERE Id = :c.Id].All_Exit_Docs_Final__c,
            'Doc_Checklist_Completion_Sync_Flow should flip All_Exit_Docs_Final__c to false when a Draft doc is created.');
    }
}
