// Seeds Case_Field_Mapping__c with the Opportunity -> Case field copies confirmed against the
// client's "IRM Opportunty Routing Score Calculation Template Final.xlsx" -> "Case Fields" tab
// (All Cases + B2B Implementation sections only — the other 10 Deal_Support sections
// (Bid Management, Remarketing, Solution Architects, Deal Desk, InfoSecurity, Revenue
// Management, GCCS, Booking Verification, Legal, Managed Service Program) have not been
// triaged yet and are intentionally NOT seeded here).
//
// Run via: sf apex run --file scripts/apex/seed_case_field_mappings.apex -o IRMDEV
//
// Safe to re-run: deletes any prior run's rows first (matched by Name), so re-running after
// edits here won't create duplicates.

// ── Clean up any prior run ──────────────────────────────────────────────────
Set<String> seedNames = new Set<String>{
    'All Cases - Contract Term Months',
    'All Cases - Business Unit',
    'All Cases - Region',
    'All Cases - Cluster',
    'All Cases - Primary Product Line',
    'All Cases - Total Contract Value',
    'All Cases - Deal Type',
    'All Cases - Billing Currency',
    'B2B Implementation - Forecast Billing Months',
    'B2B Implementation - Sales Billing Estimate'
};
delete [SELECT Id FROM Case_Field_Mapping__c WHERE Name IN :seedNames];

// ── All Cases (blank Record Type + blank Case Type = applies to every eligible Case) ──
List<Case_Field_Mapping__c> mappings = new List<Case_Field_Mapping__c>{

    new Case_Field_Mapping__c(
        Name = 'All Cases - Contract Term Months',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Contract_Term_months__c',
        Target_Field_API_Name__c = 'Contract_Term_Months__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Contract Term (Months)".'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Business Unit',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Business_Unit__c',
        Target_Field_API_Name__c = 'Business_Unit__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Business Unit(s)". Confirmed as a simple 1:1 copy, not multi-value.'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Region',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Region__c',
        Target_Field_API_Name__c = 'Region__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Region".'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Cluster',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Cluster__c',
        Target_Field_API_Name__c = 'Cluster__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Cluster".'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Primary Product Line',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Primary_Product_Line__c',
        Target_Field_API_Name__c = 'Primary_Product_Line__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Primary Product Line".'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Total Contract Value',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Total_Contract_Value_TCV__c',
        Target_Field_API_Name__c = 'Total_Contract_Value__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Total Contract Value".'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Deal Type',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Type',
        Target_Field_API_Name__c = 'Deal_Type__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Type" (New/Upsell/Renewal). Targets the existing Case.Deal_Type__c, not Case.Type -- Case.Type is already used by Case_Creation_Rule__c for the business-category Case Type (Bid Management, Legal, etc.) and must not be overwritten.'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Billing Currency',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'CurrencyIsoCode',
        Target_Field_API_Name__c = 'CurrencyIsoCode',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Billing Currency". Sheet cited a non-existent Billing__Currency__c; standard multi-currency CurrencyIsoCode is the real equivalent on both objects.'
    ),

    // ── B2B Implementation (Record Type-scoped, blank Case Type) ──
    new Case_Field_Mapping__c(
        Name = 'B2B Implementation - Forecast Billing Months',
        Record_Type_Developer_Name__c = 'B2B_Implementation',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'No_of_Forecast_Billing_Month__c',
        Target_Field_API_Name__c = 'Forecast_Billing_Months__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, B2B Implementation section, row "Forecast Billing Months".'
    ),
    new Case_Field_Mapping__c(
        Name = 'B2B Implementation - Sales Billing Estimate',
        Record_Type_Developer_Name__c = 'B2B_Implementation',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Total_Sales_Billing_Estimate__c',
        Target_Field_API_Name__c = 'Sales_Billing_Estimate__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, B2B Implementation section, row "Sales Billing Estimate".'
    )
};
insert mappings;

System.debug('=== SEEDED ' + mappings.size() + ' Case_Field_Mapping__c records ===');

// ── Sanity check every seeded (and any other active) mapping against the real schema ──
List<String> problems = CaseFieldMappingEngine.validateActiveMappings();
if (problems.isEmpty()) {
    System.debug('=== validateActiveMappings(): all active mappings resolve cleanly ===');
} else {
    System.debug('=== validateActiveMappings(): ' + problems.size() + ' PROBLEM(S) FOUND ===');
    for (String p : problems) {
        System.debug(p);
    }
}

// NOTE: rows deliberately NOT seeded here, pending further input:
//   - "Customer Account" (All Cases) - unclear how it differs from Account Name / Related Opportunity.
//   - "Total Annual Amount (TAA)" (All Cases) - sheet cites Opportunity_Total_Annual_Amount__c,
//     which doesn't exist; only an unrelated Checkbox with a similar name (..._Test__c) does.
//   - "Delay Category" (B2B Implementation) - sheet's own comment flags this as an open,
//     unresolved multi-BU design question.
//   - "Opportunity Owner" (All Cases) - confirmed clear in intent (Opportunity.OwnerId) but
//     needs a new Lookup(User) field on Case, deferred from this pass.
//   - All 10 remaining Deal_Support sections (Bid Management, Remarketing, Solution Architects,
//     Deal Desk, InfoSecurity, Revenue Management, GCCS, Booking Verification, Legal, Managed
//     Service Program) have not been triaged against the real schema yet.
