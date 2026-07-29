// Seeds Case_Field_Mapping__c with the Opportunity -> Case field copies confirmed against the
// client's "IRM Opportunty Routing Score Calculation Template Final.xlsx" -> "Case Fields" tab.
//
// The other 10 Deal_Support sections (Bid Management, Remarketing, Solution Architects, Deal
// Desk, InfoSecurity, Revenue Management, GCCS, Booking Verification, Legal, Managed Service
// Program) have now been fully triaged against the real schema (row-by-row: Required column ==
// 'Auto-populated' AND Lookup Object == Opportunity/Account) and contribute ZERO additional
// mappings — every Auto-populated row in those sections sources from CPQ or Deal Review, not
// Opportunity/Account, and every Opportunity/Account Lookup Object reference in those sections
// (rows 75, 170, 178) is manually filled, not system-populated. Nothing further to seed from
// them unless that scope changes.
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
    'All Cases - Eligible Annual Amount',
    'All Cases - Opportunity Owner',
    'B2B Implementation - Forecast Billing Months',
    'B2B Implementation - Sales Billing Estimate',
    'B2B Implementation - Delay Category'
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
    new Case_Field_Mapping__c(
        Name = 'All Cases - Eligible Annual Amount',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Amount',
        Target_Field_API_Name__c = 'Eligible_Annual_Amount__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Total Annual Amount (TAA)". Sheet cited a non-existent Opportunity_Total_Annual_Amount__c; per explicit direction this copies Opportunity.Amount into a new Case field labeled "Eligible Annual Amount".'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Opportunity Owner',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'OwnerId',
        Target_Field_API_Name__c = 'Opportunity_Owner__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Opportunity Owner".'
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
    ),
    new Case_Field_Mapping__c(
        Name = 'B2B Implementation - Delay Category',
        Record_Type_Developer_Name__c = 'B2B_Implementation',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Delay_Category__c',
        Target_Field_API_Name__c = 'Delay_Category__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, B2B Implementation section, row "Delay Category".'
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

// NOTE: "Customer Account" (All Cases) needed no new mapping - confirmed to be the same
// concept as "Account Name"/"Related Opportunity", already handled by the existing
// AccountId = opp.AccountId assignment in CaseCreationRuleEvaluatorAction.createCasesForPairs().
//
// Still open: the Solution Architects section's own inline note (row 106) flags that Digital
// Use Case, Add-On, and Cloud Provider are captured on the Opportunity but undecided whether/
// how they should appear on the Case - not seeded pending that decision.
