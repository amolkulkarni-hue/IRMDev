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
// 2026-09-16: brought over to IRMNewDev and renamed every "All Cases" target field to the
// sheet's own NF_ prefix (per explicit direction) — the fields themselves were previously only
// deployed/verified in IRMDEV under non-prefixed names. Also added the Billing Country, Upsell
// Oracle Account ID#, the 5 BU checkboxes + Multi-BU flag, and Opportunity Touch Level mappings,
// which were confirmed missing on a fresh cross-check of this tab and had no mapping seeded yet.
//
// Run via: sf apex run --file scripts/apex/seed_case_field_mappings.apex -o IRMNewDev
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
    'All Cases - Opportunity Currency',
    'All Cases - Total Annual Amount',
    'All Cases - Opportunity Owner',
    'All Cases - Billing Country',
    'All Cases - Upsell Oracle Account ID',
    'All Cases - RIM BU',
    'All Cases - Digital BU',
    'All Cases - ALM BU',
    'All Cases - MAS BU',
    'All Cases - WL BU',
    'All Cases - Multi BU Flag',
    'All Cases - Opportunity Touch Level',
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
        Target_Field_API_Name__c = 'NF_Contract_Term_Months__c',
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
        Target_Field_API_Name__c = 'NF_Primary_Product_Line__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Opportunity Primary Product Line".'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Total Contract Value',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Total_Contract_Value_TCV__c',
        Target_Field_API_Name__c = 'NF_Total_Contract_Value__c',
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
        Name = 'All Cases - Opportunity Currency',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'CurrencyIsoCode',
        Target_Field_API_Name__c = 'NF_Opportunity_Currency__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Opportunity Currency". Distinct from the Case standard CurrencyIsoCode -- records what currency the source Opportunity was in.'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Total Annual Amount',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Amount',
        Target_Field_API_Name__c = 'NF_Opportunity_Amount__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Total Annual Amount (TAA)". Sheet cited a non-existent Opportunity_Total_Annual_Amount__c; per explicit direction this copies the standard Opportunity.Amount.'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Opportunity Owner',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'OwnerId',
        Target_Field_API_Name__c = 'NF_Opportunity_Owner__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Opportunity Owner".'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Billing Country',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Billing_Country__r.Name',
        Target_Field_API_Name__c = 'NF_Billing_Country__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Billing Country". Opportunity.Billing_Country__c is a Lookup(IM_Country__c); copies the related record'
            + '\'s Name onto a plain Text field on Case.'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Upsell Oracle Account ID',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'IM_Up_Sell_Sold_To__c',
        Target_Field_API_Name__c = 'NF_Oracle_Account_ID__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Upsell Oracle Account ID#". Sheet\'s own cited API name was malformed/incomplete; real source field is Opportunity.IM_Up_Sell_Sold_To__c.'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - RIM BU',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'RIM_BU__c',
        Target_Field_API_Name__c = 'NF_RIM_BU__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "RIM BU".'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Digital BU',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Digital_BU__c',
        Target_Field_API_Name__c = 'NF_Digital_BU__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Digital BU".'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - ALM BU',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'ALM_BU__c',
        Target_Field_API_Name__c = 'NF_ALM_BU__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "ALM BU".'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - MAS BU',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'MAS_BU__c',
        Target_Field_API_Name__c = 'NF_MAS_BU__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "MAS BU".'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - WL BU',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'W_L_BU__c',
        Target_Field_API_Name__c = 'NF_W_L_BU__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "W&L BU".'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Multi BU Flag',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Multi_BU_Flag__c',
        Target_Field_API_Name__c = 'NF_Multi_BU__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Multi-BU Flag".'
    ),
    new Case_Field_Mapping__c(
        Name = 'All Cases - Opportunity Touch Level',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Touch_Level__c',
        Target_Field_API_Name__c = 'NF_Opportunity_Touch_Level__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, All Cases section, row "Opportunity Touch Level" (sheet\'s own cited API name had a stray-space typo).'
    ),

    // ── B2B Implementation (Record Type-scoped, blank Case Type) ──
    // 2026-09-17: redirected all 3 to Target_Object__c = 'Case_Detail__c' with the real
    // B2B_-prefixed field names. They previously targeted plain, non-prefixed names directly on
    // Case, which never existed there -- CaseFieldMappingEngine only ever wrote to Case at the
    // time these were first seeded, and Target_Object__c wasn't read at all. Now that the engine
    // supports Case_Detail__c targets, point these at where the real fields actually live.
    new Case_Field_Mapping__c(
        Name = 'B2B Implementation - Forecast Billing Months',
        Record_Type_Developer_Name__c = 'B2B_Implementation',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'No_of_Forecast_Billing_Month__c',
        Target_Object__c = 'Case_Detail__c',
        Target_Field_API_Name__c = 'B2B_Forecast_Billing_Months__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, B2B Implementation section, row "Forecast Billing Months". Targets Case_Detail__c (the real B2B_Forecast_Billing_Months__c field lives there, not on Case).'
    ),
    new Case_Field_Mapping__c(
        Name = 'B2B Implementation - Sales Billing Estimate',
        Record_Type_Developer_Name__c = 'B2B_Implementation',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Total_Sales_Billing_Estimate__c',
        Target_Object__c = 'Case_Detail__c',
        Target_Field_API_Name__c = 'B2B_Sales_Billing_Estimate__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, B2B Implementation section, row "Sales Billing Estimate". Targets Case_Detail__c (the real B2B_Sales_Billing_Estimate__c field lives there, not on Case). Supersedes the older, separately-created "Case Detail - Sales Billing Estimate" mapping, which is deactivated.'
    ),
    new Case_Field_Mapping__c(
        Name = 'B2B Implementation - Delay Category',
        Record_Type_Developer_Name__c = 'B2B_Implementation',
        Source_Object__c = 'Opportunity',
        Source_Field_Path__c = 'Delay_Category__c',
        Target_Object__c = 'Case_Detail__c',
        Target_Field_API_Name__c = 'B2B_Delay_Category__c',
        Is_Active__c = true,
        Description__c = 'Case Fields sheet, B2B Implementation section, row "Delay Category". Targets Case_Detail__c (the real B2B_Delay_Category__c field lives there, not on Case).'
    )
};
insert mappings;

System.debug('=== SEEDED ' + mappings.size() + ' Case_Field_Mapping__c records ===');

// ── Deactivate stray legacy records superseded by the B2B Implementation mappings above ──
// "Case Detail - Sales Billing Estimate" and "Case Detail - Name" predate this script (created
// directly, not via a prior run of it -- outside the seedNames cleanup set above) and were both
// broken: the first targeted a field name that never existed on Case_Detail__c (real field is
// B2B_Sales_Billing_Estimate__c, now covered by "B2B Implementation - Sales Billing Estimate"
// above); the second targeted Case_Detail__c.Name, a read-only AutoNumber that can never be a
// valid mapping target under any field name. Deactivated rather than deleted, to preserve them
// as a record of what was tried. Done before the validation check below so its report reflects
// the final, fixed state.
List<Case_Field_Mapping__c> legacyToDeactivate = [
    SELECT Id, Is_Active__c FROM Case_Field_Mapping__c
    WHERE Name IN ('Case Detail - Sales Billing Estimate', 'Case Detail - Name') AND Is_Active__c = true
];
for (Case_Field_Mapping__c m : legacyToDeactivate) {
    m.Is_Active__c = false;
}
if (!legacyToDeactivate.isEmpty()) {
    update legacyToDeactivate;
    System.debug('=== Deactivated ' + legacyToDeactivate.size() + ' stray legacy Case_Field_Mapping__c record(s) ===');
}

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
// NOTE: "Rejection Reason" and "Actual Labor Hours" (All Cases) are marked Track History = Yes
// in the sheet but have no Opportunity/Account source at all -- they are Case-native fields,
// not mirrors, and were never built. Out of scope for this mapping engine.
//
// Still open: the Solution Architects section's own inline note (row 106) flags that Digital
// Use Case, Add-On, and Cloud Provider are captured on the Opportunity but undecided whether/
// how they should appear on the Case - not seeded pending that decision.
