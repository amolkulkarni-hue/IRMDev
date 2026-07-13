// Patches an existing Standard Opportunity so it can advance Negotiation -> Booking Verification
// without hitting the real (non-bypassable-by-Bypass_Validation__c... actually IS gated by it, but
// we're satisfying it for real here) stage-gate validation rules on that transition.
//
// Run via: sf apex run --file scripts/apex/patch_negotiation_to_booking_verification_gates.apex -o IRMDev
//
// For a Type='New', non-RIM Opportunity, the active Negotiation -> Booking Verification
// validation rules require:
//   Neg_SalesBillingEstimate_Required /            Total_Sales_Billing_Estimate__c (a roll-up
//   Validation_on_Sales_Billing_Estimate           SUM over Sales_Revenue_Forecast__c) > 0.
//                                                   No automation creates these child records for
//                                                   the new stage scheme (the only flow that does --
//                                                   Create_and_Delete_forecast_based_on_opportunity_stages
//                                                   -- is hard-coded to the legacy '4 - Negotiate'
//                                                   stage value, not 'Negotiation'), so one is
//                                                   inserted manually below.
//   Neg_FirstBillDate_Required                     IM_Booked_Date__c populated, > TODAY(), and
//                                                   > CloseDate.
//   Neg_ValueHypothesis_Required                   Value_Hypothesis_Scope_Reviewed__c = true
//                                                   (applies to Type New/Cross-Sell/Framework).
//   Neg_WinReason_Required                         Win_Reason__c non-blank.
// (Neg_FuelSurchargeWaiver_Required / Neg_FreeStoragePeriod_Required only apply when Primary or
// Secondary Product Line = 'RIM' -- not applicable here.)
//
// Note: Sales_Revenue_Forecast__c.Forecast_Revenue_Date__c is deliberately left unset -- a
// separate VR (No_Edit_Permission_on_B2B_Fields) restricts that field to a specific
// custom-permission holder and isn't required for the gates above.
//
// Safe to re-run: deletes any prior run's Sales_Revenue_Forecast__c for this Opportunity first.

Id oppId = '006gP00000CfZKfQAN'; // Northfield Data Systems QA Qualification Ready-for-Progression Test Opp

Opportunity opp = [SELECT Id, CloseDate FROM Opportunity WHERE Id = :oppId];

// ── Sales Revenue Forecast (Sales Billing Forecast) child record ───────────
delete [SELECT Id FROM Sales_Revenue_Forecast__c WHERE Forecast_Opportunity__c = :oppId];
insert new Sales_Revenue_Forecast__c(
    Forecast_Opportunity__c   = oppId,
    Sales_Billing_Estimate__c = 500000,
    Forecast_Revenue_Month__c = 'August',
    Forecast_Revenue_Year__c  = '2026'
);

// ── Remaining Negotiation -> Booking Verification gate fields ──────────────
update new Opportunity(
    Id                                    = oppId,
    IM_Booked_Date__c                     = opp.CloseDate.addDays(7), // after CloseDate and TODAY()
    Value_Hypothesis_Scope_Reviewed__c    = true,
    Win_Reason__c                         = 'Solution Fit'
);

Opportunity result = [SELECT Total_Sales_Billing_Estimate__c, IM_Booked_Date__c,
                              Value_Hypothesis_Scope_Reviewed__c, Win_Reason__c
                       FROM Opportunity WHERE Id = :oppId];
System.debug('=== BOOKING VERIFICATION GATE FIELDS PATCHED ===');
System.debug('Total_Sales_Billing_Estimate__c: ' + result.Total_Sales_Billing_Estimate__c + ' (expect > 0)');
System.debug('IM_Booked_Date__c: ' + result.IM_Booked_Date__c);
System.debug('Value_Hypothesis_Scope_Reviewed__c: ' + result.Value_Hypothesis_Scope_Reviewed__c);
System.debug('Win_Reason__c: ' + result.Win_Reason__c);
System.debug('Opportunity should now advance Negotiation -> Booking Verification cleanly in the UI.');
