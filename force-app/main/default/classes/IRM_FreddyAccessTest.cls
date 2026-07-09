/**
 * IRM_FreddyAccessTest
 * Verifies that the demo user (freddy.acevedo) can perform all IRM demo operations:
 *   US-CASECOMP  — Case completion pct updates when Status changes
 *   US-EXITDOC   — All_Exit_Docs_Final__c gates completion at 90% until docs are Final
 *   US-TL        — Touch Level calculated on Opportunity stage/amount change
 *   US-AUTONAME  — Opportunity Name auto-generated on RT + TBD update
 *   US-LEADCONV  — Lead converts successfully with required field mapping
 *
 * Uses System.runAs(frederickUser) so all DML and flow assertions execute under
 * Freddy's profile + IRM_Sales_Admin_PS combined permissions.
 */
@IsTest
private class IRM_FreddyAccessTest {

    static User freddyUser;

    @TestSetup
    static void setup() {
        // ── Freddy's user record (read-only reference, not modified) ────────
        // No DML on User — just assert he exists and is active.

        // ── Shared config inserted by admin (visible to all test methods) ───
        IM_Country__c testCountry = new IM_Country__c(Name = 'United States');
        insert testCountry;
        insert new IM_Alternative_Country_Name__c(
            IM_Country__c = testCountry.Id, Alternative_Name__c = 'United States'
        );
        insert new Country_Settings__c(Name = 'United States', Object_Name__c = 'Opportunity',
            SetupOwnerId = UserInfo.getOrganizationId());
        insert new List<Opportunity_Security__c>{
            new Opportunity_Security__c(Name = 'Primary CDE',         Field_Name__c = 'Primary_CDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'R', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Original Lead Owner', Field_Name__c = 'IM_Original_Lead_Owner__c', Object_Name__c = 'Opportunity', Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId()),
            new Opportunity_Security__c(Name = 'Primary BDE',         Field_Name__c = 'Primary_BDE__c',            Object_Name__c = 'Account',     Visibility_Access_Level__c = 'W', SetupOwnerId = UserInfo.getOrganizationId())
        };
        insert new OpportunityProductSelection__c(Name = 'CloudSolutionsProduct',
            Product_Class_Name__c = 'Cloud', Product_Line_Name__c = 'Cloud Solutions');
        insert new List<SVStatus__c>{
            new SVStatus__c(Name = 'New Deal',      Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Renewal',       Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Add-On',        Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Expansion',     Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'SVStatusPassed', Stage__c = 'Qualification', Amount__c = 0)
        };
        insert new List<Opp_Naming_Segment__c>{
            new Opp_Naming_Segment__c(Order__c = 1, Field_API_Name__c = '__ACCOUNT_NAME__', Fallback_Value__c = 'TBD', Is_Active__c = true, Record_Type_Dev_Name__c = 'All'),
            new Opp_Naming_Segment__c(Order__c = 2, Field_API_Name__c = '__QUARTER_YEAR__', Fallback_Value__c = 'TBD', Is_Active__c = true, Record_Type_Dev_Name__c = 'All'),
            new Opp_Naming_Segment__c(Order__c = 3, Field_API_Name__c = 'Type',             Fallback_Value__c = 'TBD', Is_Active__c = true, Record_Type_Dev_Name__c = 'All')
        };
        Touch_Level_Criteria__c ht = new Touch_Level_Criteria__c(
            Stage__c = 'Qualification', Touch_Level_Result__c = 'High Touch',
            Priority__c = 10, Logic_Expression__c = '1', Is_Active__c = true
        );
        insert ht;
        insert new Touch_Level_Condition__c(
            Criteria__c = ht.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '500000'
        );
        insert new List<Case_Status_Progress__c>{
            new Case_Status_Progress__c(Case_Record_Type_Dev_Name__c = 'Deal_Support', Status_Value__c = 'New',     Progress_Pct__c = 0),
            new Case_Status_Progress__c(Case_Record_Type_Dev_Name__c = 'Deal_Support', Status_Value__c = 'Working', Progress_Pct__c = 50),
            new Case_Status_Progress__c(Case_Record_Type_Dev_Name__c = 'Deal_Support', Status_Value__c = 'Closed',  Progress_Pct__c = 90)
        };
        insert new Account(
            Name = 'Freddy Demo Account',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
    }

    private static User getFreddy() {
        return [SELECT Id FROM User WHERE Username = 'freddy.acevedo@ironmountain.com.prjprism26' LIMIT 1];
    }

    private static Id getDealSupportRTId() {
        return [SELECT Id FROM RecordType WHERE DeveloperName = 'Deal_Support' AND SObjectType = 'Case'].Id;
    }

    // ── US-CASECOMP: Freddy updates Case Status → Completion Pct updates ────

    @IsTest
    static void test_freddy_caseCompletionPctUpdates() {
        User freddy = getFreddy();
        Id acctId   = [SELECT Id FROM Account LIMIT 1].Id;
        Id rtId     = getDealSupportRTId();

        Case c;
        System.runAs(freddy) {
            c = new Case(AccountId = acctId, Subject = 'Freddy Demo Case',
                         Status = 'New', Origin = 'Web', RecordTypeId = rtId);
            insert c;

            Test.startTest();
            update new Case(Id = c.Id, Status = 'Working');
            Test.stopTest();
        }

        Case updated = [SELECT Case_Completion_Pct__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(50, updated.Case_Completion_Pct__c,
            'US-CASECOMP: Freddy should see 50% after Status=Working. Got: ' + updated.Case_Completion_Pct__c);
    }

    // ── US-EXITDOC: Freddy creates Draft doc → gate blocks 100%; finalize → 100% ─

    @IsTest
    static void test_freddy_exitDocGateAndFinalize() {
        User freddy = getFreddy();
        Id acctId   = [SELECT Id FROM Account LIMIT 1].Id;
        Id rtId     = getDealSupportRTId();

        // Insert Case + Draft doc OUTSIDE startTest so sync flow fires immediately
        Case c;
        Document_Checklist__c doc;
        System.runAs(freddy) {
            c = new Case(AccountId = acctId, Subject = 'Freddy Exit Doc Demo',
                         Status = 'Closed', Origin = 'Web', RecordTypeId = rtId);
            insert c;
            doc = new Document_Checklist__c(
                Case__c = c.Id, Status__c = 'Draft',
                Document_Category__c = 'Scoping & Technical'
            );
            insert doc;
        }

        Case at90 = [SELECT Case_Completion_Pct__c, All_Exit_Docs_Final__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(false, at90.All_Exit_Docs_Final__c, 'Draft doc should set gate=false');
        System.assertEquals(90, at90.Case_Completion_Pct__c, 'Draft doc + Closed → should cap at 90. Got: ' + at90.Case_Completion_Pct__c);

        // Finalize inside startTest/stopTest
        System.runAs(freddy) {
            Test.startTest();
            update new Document_Checklist__c(Id = doc.Id, Status__c = 'Final', Submitted_Date__c = Date.today());
            Test.stopTest();
        }

        Case at100 = [SELECT Case_Completion_Pct__c, All_Exit_Docs_Final__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(true,  at100.All_Exit_Docs_Final__c, 'Final doc should set gate=true');
        System.assertEquals(100,   at100.Case_Completion_Pct__c, 'All docs Final → should upgrade to 100. Got: ' + at100.Case_Completion_Pct__c);
    }

    // ── US-TL: Freddy converts a Lead → Opp Touch Level evaluates at Qualification ─

    @IsTest
    static void test_freddy_touchLevelAfterLeadConversion() {
        User freddy = getFreddy();

        // Lead insert + conversion + OCR setup all OUTSIDE startTest to stay under SOQL limit
        Database.LeadConvertResult result;
        System.runAs(freddy) {
            Lead lead = new Lead(
                FirstName = 'Freddy', LastName = 'DemoConvert',
                Company = 'Freddy Demo Corp',
                Street = '1 Iron Way', City = 'Boston', State = 'MA',
                PostalCode = '02101', Country = 'United States',
                Phone = '6175550001', Role__c = 'Decision Maker',
                Email = 'freddy.demo@irm-test.example.com',
                LeadSource = 'Web', Status = 'New'
            );
            insert lead;

            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.Id);
            lc.setConvertedStatus([SELECT ApiName FROM LeadStatus WHERE IsConverted = true LIMIT 1].ApiName);
            lc.setDoNotCreateOpportunity(false);
            lc.setOverwriteLeadSource(false);
            result = Database.convertLead(lc);
            System.assert(result.isSuccess(), 'Freddy: Lead conversion should succeed. ' + result.getErrors());

            // Org VR requires Champion, EDM/Buyer, Problem Owner before advancing to Qualification.
            Id oppId = result.getOpportunityId();
            OpportunityContactRole existingOcr = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :oppId LIMIT 1];
            update new OpportunityContactRole(Id = existingOcr.Id, Role = 'Champion', IsPrimary = true);
            Contact c2 = new Contact(FirstName = 'EDM',     LastName = 'Buyer',  AccountId = result.getAccountId(), Phone = '6175550010', Email = 'edm.tl@irm-test.example.com');
            Contact c3 = new Contact(FirstName = 'Problem', LastName = 'OwnerX', AccountId = result.getAccountId(), Phone = '6175550011', Email = 'po.tl@irm-test.example.com');
            insert new List<Contact>{ c2, c3 };
            insert new List<OpportunityContactRole>{
                new OpportunityContactRole(OpportunityId = oppId, ContactId = c2.Id, Role = 'Economic Decision Maker / Buyer'),
                new OpportunityContactRole(OpportunityId = oppId, ContactId = c3.Id, Role = 'Problem Owner')
            };
        }

        // Only the stage updates (the actual touch-level trigger) go inside startTest
        System.runAs(freddy) {
            Id oppId = result.getOpportunityId();
            String altStage = 'Qualification';
            for (Schema.PicklistEntry e : Opportunity.StageName.getDescribe().getPicklistValues()) {
                if (e.isActive() && e.getValue() != 'Qualification') { altStage = e.getValue(); break; }
            }
            Test.startTest();
            update new Opportunity(Id = oppId, Amount = 750000, StageName = altStage);
            update new Opportunity(Id = oppId, StageName = 'Qualification');
            Test.stopTest();
        }

        Opportunity opp = [SELECT Touch_Level_Calculated__c FROM Opportunity WHERE Id = :result.getOpportunityId()];
        System.assertEquals('High Touch', opp.Touch_Level_Calculated__c,
            'US-TL: Freddy should see High Touch for Amount >= 500k at Qualification. Got: ' + opp.Touch_Level_Calculated__c);
    }

    // ── US-AUTONAME: Freddy converts a Lead → updates RT to Standard → Name auto-generated ─

    @IsTest
    static void test_freddy_oppAutoName() {
        User freddy = getFreddy();

        Database.LeadConvertResult result;
        System.runAs(freddy) {
            // Freddy inserts the Lead (he owns it → can convert it)
            Lead lead = new Lead(
                FirstName = 'Demo', LastName = 'AutoName',
                Company = 'Freddy AutoName Co',
                Street = '2 Iron Way', City = 'Boston', State = 'MA',
                PostalCode = '02101', Country = 'United States',
                Phone = '6175550002', Role__c = 'Decision Maker',
                Email = 'demo.autoname@irm-test.example.com',
                LeadSource = 'Web', Status = 'New'
            );
            insert lead;

            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.Id);
            lc.setConvertedStatus([SELECT ApiName FROM LeadStatus WHERE IsConverted = true LIMIT 1].ApiName);
            lc.setDoNotCreateOpportunity(false);
            lc.setOverwriteLeadSource(false);

            Test.startTest();
            result = Database.convertLead(lc);
            System.assert(result.isSuccess(), 'Freddy: AutoName lead conversion should succeed. ' + result.getErrors());

            Id stdRTId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Standard_Opportunity' AND SObjectType = 'Opportunity'].Id;
            update new Opportunity(Id = result.getOpportunityId(),
                RecordTypeId = stdRTId, Name = 'TBD', Type = 'New Deal',
                Amount = 100000, Pricebook2Id = Test.getStandardPricebookId());
            Test.stopTest();
        }

        Opportunity named = [SELECT Name FROM Opportunity WHERE Id = :result.getOpportunityId()];
        System.assert(named.Name != null && named.Name.length() > 0,
            'US-AUTONAME: Freddy should see auto-generated Opp Name. Got: ' + named.Name);
        System.assert(!named.Name.startsWith('TBD') || named.Name.length() > 3,
            'US-AUTONAME: Name should not remain TBD. Got: ' + named.Name);
    }
}
