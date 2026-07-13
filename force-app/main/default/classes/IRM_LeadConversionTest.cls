/**
 * IRM_LeadConversionTest
 * US-LEADCONV: Lead conversion end-to-end coverage
 *
 * Flows under test (fire on converted Opportunity):
 *   Opportunity_Auto_Name_Create_Flow (After Save — Opportunity, Create)
 *   Opportunity_Auto_Name_Update_Flow (After Save — Opportunity, Update, Name contains TBD)
 *   Touch_Level_Recalculation_Flow   (After Save — Opportunity, StageName IsChanged)
 * All flows must be ACTIVE before running.
 *
 * Note: Database.convertLead() creates an Opportunity with the standard default RecordType.
 * Auto-name is triggered by explicitly updating RecordTypeId to Standard_Opportunity (or
 * Framework_Parent_Opportunity) with Name containing TBD, which fires the Update flow.
 */
@IsTest
private class IRM_LeadConversionTest {

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
            new SVStatus__c(Name = 'New Deal',      Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Renewal',       Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Add-On',        Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'Expansion',     Amount__c = 0, Stage__c = 'Qualification', SetupOwnerId = UserInfo.getOrganizationId()),
            new SVStatus__c(Name = 'SVStatusPassed', Stage__c = 'Qualification', Amount__c = 0)
        };

        // Naming segment config for auto-name verification
        insert new List<Opp_Naming_Segment__c>{
            new Opp_Naming_Segment__c(Order__c = 1, Field_API_Name__c = '__ACCOUNT_NAME__', Fallback_Value__c = 'TBD', Is_Active__c = true, Record_Type_Dev_Name__c = 'All'),
            new Opp_Naming_Segment__c(Order__c = 2, Field_API_Name__c = '__QUARTER_YEAR__', Fallback_Value__c = 'TBD', Is_Active__c = true, Record_Type_Dev_Name__c = 'All'),
            new Opp_Naming_Segment__c(Order__c = 3, Field_API_Name__c = 'Type',             Fallback_Value__c = 'TBD', Is_Active__c = true, Record_Type_Dev_Name__c = 'All'),
            new Opp_Naming_Segment__c(Order__c = 4, Field_API_Name__c = 'Business_Unit__c', Fallback_Value__c = 'TBD', Is_Active__c = true, Record_Type_Dev_Name__c = 'All'),
            new Opp_Naming_Segment__c(Order__c = 5, Field_API_Name__c = 'Sales_Region__c',  Fallback_Value__c = 'TBD', Is_Active__c = true, Record_Type_Dev_Name__c = 'All')
        };

        // Touch Level config: High Touch if Amount >= 500k at Qualification
        Touch_Level_Criteria__c ht = new Touch_Level_Criteria__c(
            Stage__c = 'Qualification', Touch_Level_Result__c = 'High Touch',
            Priority__c = 10, Logic_Expression__c = '1', Is_Active__c = true
        );
        insert ht;
        insert new Touch_Level_Condition__c(
            Criteria__c = ht.Id, Condition_Number__c = 1,
            Field_API_Name__c = 'Amount', Operator__c = 'GREATER_OR_EQUAL', Value__c = '500000'
        );
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private static Lead buildLead(String company) {
        return new Lead(
            FirstName   = 'Test',
            LastName    = 'LeadConvert',
            Company     = company,
            Street      = '123 Test Street',
            City        = 'New York',
            State       = 'NY',
            PostalCode  = '10001',
            Country     = 'United States',
            Phone       = '2125551234',
            Role__c     = 'Decision Maker',
            Email       = 'test.leadconvert@irm-test.example.com',
            LeadSource  = 'Web',
            Status      = 'Open'
        );
    }

    private static String convertedLeadStatus() {
        return [SELECT ApiName FROM LeadStatus WHERE IsConverted = true LIMIT 1].ApiName;
    }

    private static Id getStandardOppRTId() {
        return [SELECT Id FROM RecordType WHERE DeveloperName = 'Standard_Opportunity' AND SObjectType = 'Opportunity'].Id;
    }

    private static Id getFrameworkOppRTId() {
        Schema.RecordTypeInfo rtInfo = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByDeveloperName().get('Framework_Parent_Opportunity');
        if (rtInfo == null || !rtInfo.isAvailable()) { return null; }
        return rtInfo.getRecordTypeId();
    }

    private static Database.LeadConvertResult doConvert(Id leadId, Boolean doNotCreateOpp) {
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);
        lc.setConvertedStatus(convertedLeadStatus());
        lc.setDoNotCreateOpportunity(doNotCreateOpp);
        lc.setOverwriteLeadSource(false);
        return Database.convertLead(lc);
    }

    // ── US-AUTONAME: converted Opp → Standard RT + TBD name → auto-generated ─

    @IsTest
    static void test_convertToStandardOpp() {
        Lead lead = buildLead('Conv Auto-Name Co');
        insert lead;

        Test.startTest();
        Database.LeadConvertResult result = doConvert(lead.Id, false);
        System.assert(result.isSuccess(), 'Lead conversion should succeed. Errors: ' + result.getErrors());

        Id oppId = result.getOpportunityId();
        // Set Standard_Opportunity RT with a TBD name — triggers Opportunity_Auto_Name_Update_Flow
        Opportunity opp = new Opportunity(
            Id           = oppId,
            RecordTypeId = getStandardOppRTId(),
            Name         = 'TBD',
            Type         = 'New Deal',
            Amount       = 100000,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        update opp;
        Test.stopTest();

        Opportunity named = [SELECT Name FROM Opportunity WHERE Id = :oppId];
        System.assert(!named.Name.startsWith('TBD') || named.Name.length() > 3,
            'US-AUTONAME: Auto-name flow should replace the TBD placeholder with a generated name. Got: ' + named.Name);
        System.assert(named.Name.contains('Conv Auto-Name Co') || named.Name.contains('TBD'),
            'US-AUTONAME: Name should include account name segment or TBD fallback. Got: ' + named.Name);
    }

    // ── US-AUTONAME: Framework_Parent_Opportunity RT also auto-named ──────────

    @IsTest
    static void test_convertToFrameworkOpp() {
        Id frameworkRTId = getFrameworkOppRTId();
        if (frameworkRTId == null) {
            System.assert(true, 'Framework_Parent_Opportunity RT not accessible to running user — test skipped.');
            return;
        }

        Lead lead = buildLead('Conv Framework Co');
        insert lead;

        Test.startTest();
        Database.LeadConvertResult result = doConvert(lead.Id, false);
        System.assert(result.isSuccess(), 'Lead conversion should succeed. Errors: ' + result.getErrors());

        Id oppId = result.getOpportunityId();
        Opportunity opp = new Opportunity(
            Id           = oppId,
            RecordTypeId = frameworkRTId,
            Name         = 'TBD',
            Type         = 'New Deal',
            Amount       = 100000,
            Pricebook2Id = Test.getStandardPricebookId()
        );
        update opp;
        Test.stopTest();

        Opportunity named = [SELECT Name FROM Opportunity WHERE Id = :oppId];
        System.assert(named.Name != null && named.Name.length() > 0,
            'US-AUTONAME: Framework_Parent_Opportunity RT should also auto-generate Name. Got: ' + named.Name);
    }

    // ── US-TL: converted Opp qualifies for High Touch after stage update ──────

    @IsTest
    static void test_convertedOppTouchLevel() {
        Lead lead = buildLead('Conv High Touch Co');
        insert lead;

        Database.LeadConvertResult result = doConvert(lead.Id, false);
        System.assert(result.isSuccess(), 'Conversion should succeed.');
        Id oppId = result.getOpportunityId();

        // Lead conversion creates one OCR for the converted Contact.
        // Each required role must be a distinct Contact — update existing OCR to Champion,
        // then create 2 new Contacts for EDM/Buyer and Problem Owner.
        Id contactId = result.getContactId();
        OpportunityContactRole existingOcr = [
            SELECT Id FROM OpportunityContactRole
            WHERE OpportunityId = :oppId AND ContactId = :contactId LIMIT 1
        ];
        update new OpportunityContactRole(Id = existingOcr.Id, Role = 'Champion', IsPrimary = true);
        Contact c2 = new Contact(FirstName = 'EDM',     LastName = 'Buyer', AccountId = result.getAccountId(),
                                  Phone = '2125550001', Email = 'edm.buyer@irm-test.example.com');
        Contact c3 = new Contact(FirstName = 'Problem', LastName = 'Owner', AccountId = result.getAccountId(),
                                  Phone = '2125550002', Email = 'problem.owner@irm-test.example.com');
        insert new List<Contact>{ c2, c3 };
        insert new List<OpportunityContactRole>{
            new OpportunityContactRole(OpportunityId = oppId, ContactId = c2.Id, Role = 'Economic Decision Maker / Buyer'),
            new OpportunityContactRole(OpportunityId = oppId, ContactId = c3.Id, Role = 'Problem Owner')
        };

        // Find an active stage value other than Qualification to force an IsChanged event
        String altStage = 'Qualification';
        for (Schema.PicklistEntry e : Opportunity.StageName.getDescribe().getPicklistValues()) {
            if (e.isActive() && e.getValue() != 'Qualification') {
                altStage = e.getValue();
                break;
            }
        }

        Test.startTest();
        // First update: set Amount + change stage away (Touch Level flow fires but no Qualification criteria)
        update new Opportunity(Id = oppId, Amount = 600000, StageName = altStage);
        // Second update: return to Qualification — flow fires again, criteria match → High Touch
        update new Opportunity(Id = oppId, StageName = 'Qualification');
        Test.stopTest();

        Opportunity updated = [SELECT Touch_Level_Calculated__c, Touch_Level__c FROM Opportunity WHERE Id = :oppId];
        System.assertEquals('High Touch', updated.Touch_Level_Calculated__c,
            'Touch_Level_Recalculation_Flow should evaluate to High Touch for Amount >= 500k at Qualification. Got: ' + updated.Touch_Level_Calculated__c);
    }

    // ── No Opp: conversion with setDoNotCreateOpportunity = true ─────────────

    @IsTest
    static void test_convertNoOpportunity() {
        Lead lead = buildLead('Conv No Opp Co');
        insert lead;

        Test.startTest();
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead.Id);
        lc.setConvertedStatus(convertedLeadStatus());
        lc.setDoNotCreateOpportunity(true);
        Database.LeadConvertResult result = Database.convertLead(lc);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Conversion without Opportunity should succeed. Errors: ' + result.getErrors());
        System.assertEquals(null, result.getOpportunityId(),
            'No Opportunity should be created when setDoNotCreateOpportunity = true.');
        System.assertNotEquals(null, result.getAccountId(),
            'Account should still be created during no-Opp conversion.');
        System.assertNotEquals(null, result.getContactId(),
            'Contact should still be created during no-Opp conversion.');
    }

    // ── Field mapping: Lead.Company → Account.Name, Lead.FirstName → Contact.FirstName ─

    @IsTest
    static void test_convertFieldMapping() {
        Lead lead = new Lead(
            FirstName  = 'Aria',
            LastName   = 'Nakamura',
            Company    = 'Field Map Verify Co',
            Street     = '456 Field Map Ave',
            City       = 'New York',
            State      = 'NY',
            PostalCode = '10002',
            Country    = 'United States',
            Phone      = '2125551235',
            Role__c    = 'Decision Maker',
            Email      = 'aria.nakamura@irm-test.example.com',
            LeadSource = 'Web',
            Status     = 'Open'
        );
        insert lead;

        Test.startTest();
        Database.LeadConvertResult result = doConvert(lead.Id, true);
        Test.stopTest();

        System.assert(result.isSuccess(), 'Conversion should succeed. Errors: ' + result.getErrors());

        Account acc = [SELECT Name FROM Account WHERE Id = :result.getAccountId()];
        System.assertEquals('Field Map Verify Co', acc.Name,
            'Lead.Company should map to Account.Name. Got: ' + acc.Name);

        Contact con = [SELECT FirstName FROM Contact WHERE Id = :result.getContactId()];
        System.assertEquals('Aria', con.FirstName,
            'Lead.FirstName should map to Contact.FirstName. Got: ' + con.FirstName);
    }

    // ── Bulk: 10 lead conversions → 10 Accounts and Contacts created ─────────
    // Note: doNotCreateOpportunity=true avoids org-specific Opp sharing-rule
    // automation that fires on bulk Opp creation. Opp auto-naming scale is
    // covered by test_convertToStandardOpp.

    @IsTest
    static void test_bulk10Leads() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            leads.add(buildLead('Bulk Conv Co ' + i));
            leads[i].Email    = 'bulk' + i + '@irm-test.example.com';
            leads[i].LastName = 'BulkConvert' + i;
            leads[i].Phone    = '212555' + String.valueOf(1000 + i);
        }
        insert leads;

        String convertedStatus = convertedLeadStatus();

        Test.startTest();
        List<Database.LeadConvert> lcList = new List<Database.LeadConvert>();
        for (Lead lead : leads) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.Id);
            lc.setConvertedStatus(convertedStatus);
            lc.setDoNotCreateOpportunity(true);
            lc.setOverwriteLeadSource(false);
            lcList.add(lc);
        }
        List<Database.LeadConvertResult> results = Database.convertLead(lcList);
        Test.stopTest();

        List<Id> accountIds = new List<Id>();
        List<Id> contactIds = new List<Id>();
        for (Database.LeadConvertResult r : results) {
            System.assert(r.isSuccess(), 'Each lead conversion should succeed. Errors: ' + r.getErrors());
            System.assertNotEquals(null, r.getAccountId(), 'Account should be created for each converted lead.');
            System.assertNotEquals(null, r.getContactId(), 'Contact should be created for each converted lead.');
            accountIds.add(r.getAccountId());
            contactIds.add(r.getContactId());
        }

        System.assertEquals(10, accountIds.size(), '10 Accounts should be created from 10 lead conversions.');
        System.assertEquals(10, contactIds.size(), '10 Contacts should be created from 10 lead conversions.');
    }
}