# Impact Analysis: Renaming Opportunity.Type "New Deal" → "New"

**Prepared:** 2026-07-16
**Scope:** IRM Salesforce org (source: local `force-app` metadata, last synced with IRMDEV sandbox 2026-07-12)
**Method:** Full-repo search across every automation and metadata type for hardcoded references to the Opportunity.Type picklist value `New Deal`, cross-checked line-by-line to exclude false positives (e.g. the unrelated `Deal_Type__c` field, `Deal_Review__c` object, Case fields).

---

## ⚠️ Critical Pre-Flight Finding — must be resolved before any change

The org's master **OpportunityType standard value set** (`standardValueSets/OpportunityType.standardValueSet-meta.xml`, as retrieved from the sandbox on 2026-07-12) **already contains a distinct value called `New`**, currently flagged as the *default* value — separate from `New Deal`:

```xml
<standardValue><fullName>New</fullName><default>true</default><label>New</label></standardValue>
```

`New Deal` is not itself present in this master list — it only appears as a restricted/available value inside individual Record Types (Standard_Opportunity, IME_Standard_Opportunity, CPQ_Sales_Opportunity, etc.).

**Why this matters:** renaming `New Deal` → `New` is not a simple label edit. Because a distinct `New` value already exists org-wide, this change is either:
1. **Blocked** — Setup will not allow two picklist values with the same value/label, or
2. A **merge**, if the client picks "also update existing records" — every Opportunity currently on `New Deal` gets reassigned to `New`, and reporting/history will no longer be able to distinguish records that were originally `New` from records that were originally `New Deal`.

**Recommendation (working hypothesis, pending validation):** Before any of the automation updates below are made, confirm with the client/solution architect:
- Is `New` an actively-used, distinct value today (run `SELECT COUNT(Id), Type FROM Opportunity WHERE Type IN ('New','New Deal') GROUP BY Type` in the sandbox to size the blast radius)?
- Is the intent a **true rename** (requires first retiring/repurposing the existing `New` value, or choosing a different target label to avoid collision) or an intentional **merge** of the two categories?
- This decision changes the entire migration plan and should be signed off before implementation — flagging per NeuraFlash governance as a pending-review architecture decision, not something to resolve unilaterally.

---

## Automation Inventory by Type

Everything below assumes the collision above gets resolved and the literal value going forward is `New`. Each table lists what currently hardcodes `New Deal` and what must change.

### 1. Validation Rules

| Object | Rule | Formula / Message Reference | Status | Change Needed |
|---|---|---|---|---|
| Opportunity | `Tier_2_Minimum_Billing` | `ISPICKVAL(Type, "New Deal")`; error msg "Tier 2 New Deals" | Active | Update formula literal + message text |
| Opportunity | `Tier_1_Minimum_Billing` | `ISPICKVAL(Type, "New Deal")`; error msg "Tier 1 New Deals" | Active | Update formula literal + message text |
| Opportunity | `Tier_1_Grace_Period` | `ISPICKVAL(Type, "New Deal")`; error msg "Tier 1 New Deals" | Active | Update formula literal + message text |
| Opportunity | `Tier_2_Grace_Period` | `ISPICKVAL(Type, "New Deal")`; error msg "Tier 2 New Deals" | Active | Update formula literal + message text |
| Opportunity | `FCST_Line_Validation_to_Move_Stage_5` | `OR(ISPICKVAL(Type,'Up-Sell'), ISPICKVAL(Type,'New Deal'))` | Active | Update formula literal |
| Opportunity | `Qual_RemarketingRequired_Required` | `OR(ISPICKVAL(Type,'New Deal'), ISPICKVAL(Type,'Upsell'), ISPICKVAL(Type,'Framework'))` | Active | Update formula literal |
| Opportunity | `Sol_SolutionApproachValidated_Required` | Same OR pattern; error msg spells out "Type: New Deal, Upsell, or Framework" | Active | Update formula literal + message text |
| Opportunity | `QTB_Restrict_Opp_Type_for_NA` | `NOT(ISPICKVAL(Type,'New Deal'))`; error msg "...only for Type - New Deal" | **Inactive** | Update formula + message before re-activating |
| Opportunity | `QTB_New_Deal_Billing_Country_Required` | `ISPICKVAL(Type, "New Deal")` | Active | Update formula literal (rule name itself references "New_Deal" — cosmetic, optional) |
| Opportunity | `VR_Qual_ServiceAddress_Required` | `OR(ISPICKVAL(Type,'New Deal'), ISPICKVAL(Type,'Upsell'))`; error msg "...for New Deal and Upsell opportunities" | Active | Update formula literal + message text |
| Opportunity | `Deal_Review_Oppty_Stage_Verification` | `OR(ISPICKVAL(Type,"New Deal"), ISPICKVAL(Type,"Renewal"))` | **Inactive** | Update formula before re-activating |
| Opportunity | `First_Bill_Date_on_Stage_5_for_newupsell` | `OR(ISPICKVAL(Type,'Up-Sell'), ISPICKVAL(Type,'New Deal'))` | **Inactive** | Update formula before re-activating |
| Customer_Profile__c | `Matching_Deal_and_Opportunity_Type` | Cross-object: `ISPICKVAL(Opportunity__r.Type, "New Deal")` vs. `Deal_Type__c` | Active | Update formula literal (reaches Opportunity.Type via lookup — easy to miss) |
| Sales_Support_Request__c | `Additional_info_session_is_required` | Cross-object: `ISPICKVAL(Related_Opportunity__r.Type, "New Deal")` | **Inactive** | Update formula before re-activating |

*Not impacted (reference `ISCHANGED(Type)` or blank-checks only, no literal value): `Restrict_Type_Change_after_Negotiation`, `Lock_Opportunity_Type_in_Closed_Stages`, `Require_Type_For_Negotiation`.*

### 2. Flows

| Flow | Element | Reference | Change Needed |
|---|---|---|---|
| `Deal_Review_Accepted_Update_and_Error_Message_Display` | Start entry criteria (record-triggered) | `ISPICKVAL({!$Record.Type}, 'New Deal')` | Update literal |
| `Opportunity_Stage_1_to_4_Post_to_Global_chatter_Group_1` | Formula `formula_TRUE_myRule_1` | `ISPICKVAL({!$Record.Type}, 'New Deal')` | Update literal |
| `Opportunity_Stage_1_to_4_Post_to_Global_chatter_Group` | Formulas `formula_myRule_1` + legacy `originalFormula` metadata (4 occurrences: current/old record × 2 conditions) | `ISPICKVAL(...Type , 'New Deal')` | Update all 4 occurrences, including the stored legacy process-metadata text |
| `QTB_Opportunity_Billing_Account_Creation` | Decision rule `QTB_OPP_New_Deal` ("OPP New Deal or Renewal") | `Type EqualTo "New Deal"` | Update literal |
| `Billing_Account_SUB_FLOW_for_SBS_and_SP_opportunity` | Decision `QTB_Check_Opportunity_Type`, rule `QTB_OPP_New_Deal` | `Type EqualTo "New Deal"` | Update literal (duplicate logic of the flow above — update both) |
| `Tier_2_Grace_Period_and_Minimum_Billing_Value` | Start filter | `<field>Type</field><value>New Deal</value>` | Update literal — flow won't trigger otherwise |
| `Tier_1_Grace_Period_and_Minimum_Billing_Value` | Decision rules `Equals_to_Tier1`, `Equals_to_Tier2` + start filter formula | `Type EqualTo "New Deal"` (×2) + `ISPICKVAL({!$Record.Type}, 'New Deal')` | Update all 3 occurrences |
| `Forecast_Owner_Field_to_Enable_Clari_Functionality` | Rules `Opportunity_Owner_Update_Logic_Check`, `Global_Industries_is_true`, `Global_Industries_is_false` | `Type EqualTo "New Deal"` (×3) | Update all 3 |
| `Submit_To_Booking_Process` | Decision `If_amount_less_than_total_sales_billing_estimate` | `TypeCheck EqualTo "New Deal"` (`TypeCheck` populated from Opportunity.Type lookup) | Update literal |
| `IMNA_Sales_NeuraFlash_VoiceCall_Case` | Screen Choice `New_Deal` → feeds `recordCreates` field `Type` on Opportunity | `choiceText`/`stringValue` = "New Deal" | Update choice text/value so the screen selection still creates a valid Type |
| `IMNA_Sales_NeuraFlash_VoiceCall_Lead_Opportunity` | Orphaned Choice `New_Deal` | Not wired to any field currently used | No functional impact today; clean up or update if ever wired |

*Not impacted — confirmed unrelated field (`Deal_Type__c`), unrelated object (`Deal_Review__c`), unrelated field (`NCSP_Opportunity_Type__c` on Case), or label/description text only: `Opportunity_Auto_Name_Update_Flow`, `NCSP_ALM_OTO_Program_Billing_Operational_Account_Creation`, `SF_Case_To_MuleSoft_Flow`, `NCSP_CaseContractStatus_DocumentAccepted`, `Mulesoft_NCSP_Customer_Creation`, `QTB_Create_Customer_Profile_and_Case`, `Deal_Review_Manual_Input_Error_Message_Dispaly`, `Deal_Review_Primary_Flow_with_Duplication`, `Populate_Deal_Booked_Date`, `NCSP_Audit_Process`, `NCSP_Audit_Process_1`, `Create_New_Deal_Review_From_Project_ScreenFlow`, `Deal_Review_ORB_Subflow`.*

### 3. Workflow Rules

| Object | Rule | Criteria | Status | Change Needed |
|---|---|---|---|---|
| Opportunity | `Tier_1_Grace_Period_Value` | `Opportunity.Type equals New Deal` | **Inactive** | Update criteria before re-activating |
| Opportunity | `Tier_1_Minimum_Billing_Percent_Value` | `Opportunity.Type equals New Deal` | **Inactive** | Update criteria before re-activating |
| Opportunity | `Tier_2_Grace_Period_Value` | `Opportunity.Type equals New Deal` | **Inactive** | Update criteria before re-activating |
| Opportunity | `Tier_2_Minimum_Billing_Percent_Value` | `Opportunity.Type equals New Deal` | **Inactive** | Update criteria before re-activating |

All four live in `workflows/Opportunity.workflow-meta.xml` and are currently inactive, but ship in metadata and would break silently the moment anyone reactivates them without also updating the literal.

### 4. Apex — Production Logic (highest risk — breaks silently, no deploy error)

| Class / Trigger | Method | Snippet | Risk |
|---|---|---|---|
| `OpportunityHelper.cls` | `B2BIntegration()` (×3) | `if(op.Type=='New Deal'){` | B2B create/update-opportunity callout stops firing; customer-ID resolution and sync-date gating silently skipped |
| `triggers/OpportunityObject.trigger` | after-update (×3) | `if(op.Type=='New Deal'){` | Same B2B integration breakage, fired directly from the trigger |
| `createNewContract.cls` | `createNewContract()` | `oppty.Type != 'New Deal' \|\| oppty.StageName !='4 - Negotiate'` | Contract-creation VF page becomes permanently blocked with a stale error for the renamed type |
| `IRM_ScheduleAControllerExt_Lightning.cls` | `selectScheduleA()`, `applyRMDiscount()` (×4) | `opportunity.Type == 'New Deal'` | RM billcode reordering, messaging, and volume-tier discount validation stop applying |
| `IRM_ScheduleAControllerExt.cls` (classic) | `selectScheduleA()`, `applyRMDiscount()` (×4) | Same as Lightning twin | Same breakage on the classic VF controller |
| `SVStatus.cls` | `updateSVStatus()` (×3) | `OppNew.Type == 'New Deal' \|\| OppNew.Type == 'Up-Sell/Lift'` | SV Status auto-set ("Queued"/"Passed") stops triggering — commission-review workflow silently breaks |
| `triggers/CaseObject.trigger` | `oppValidation()` | `opp.Type=='New Deal'\|\|opp.Type=='Up-Sell/Lift'` | `IME_Vended_Unvended__c` auto-reset validation stops firing |
| `triggers/SKPOpportunitySync.trigger` | after-update | `ca.NCSP_Opportunity__r.Type=='New Deal'` | SKP B2B callout stops firing for new-deal opportunities |
| `BatchInboundStorageAssignment.cls` | `getStatus()` | `if(type == 'New Deal'){ return 'Matched - Approved'; }` | Falls back to "Matched - Pending" instead of "Matched - Approved" |
| `IRM_ScheduleAService.cls` | `createQuoteFromScheduleA()` | `else if(opp.Type == 'New Deal'){` | Quote tiering (storage volume/revenue proration) stops applying |
| `B2B_CreateOpportunity.cls` / `B2B_UpdateOpportunity.cls` | `CustomerDetailsobj` ctor | `if(OpptyParam.Type=='New Deal'){` | Customer ID / case-number resolution stops populating in the B2B payload |
| `NCSPWizardCtrl.cls` | class constant `NEW_DEAL`, ctor, `validateCustomerProfileStep3()` | `public static final String NEW_DEAL = 'New Deal';` + 3 usages | `isNewDeal` flag (drives wizard field visibility/validation) stops being set; autopay validation stops firing |
| `NCSPWizardCtrl_Lightning.cls` | class constant `NEW_DEAL`, both ctors, `validateCustomerProfileStep2()` | Same pattern, 5 usages | Same `isNewDeal` breakage + PO-Box service-address validation stops firing |
| `QTB_Constants.cls` | constant | `public static final String OPP_TYPE_NEWDEAL = 'New Deal';` | Central constant feeding two other classes below — must be updated first |
| `QTB_ContractHelper.cls` | `process()` | `...Type == QTB_Constants.OPP_TYPE_NEWDEAL` | Sales Contract `QTB_Latest_Opportunity__c` auto-population stops |
| `QTB_searchAccountController.cls` | `checkLatestOpportunityDetails()` | `opp.Type == QTB_Constants.OPP_TYPE_NEWDEAL \|\| ...` | "Contract Not Generated" warning stops surfacing |

**Fix order matters here**: update `QTB_Constants.OPP_TYPE_NEWDEAL` once and its two dependents inherit the fix automatically; every other class has its own inline literal and needs an individual edit.

### 4b. Apex — Test Data (won't break, but must be updated to keep tests meaningful)

Roughly 45 test classes assign `Type = 'New Deal'` directly on test-fixture Opportunities (full file list retained in the working analysis — includes `Test_SVStatus.cls`, `Test_OpportunityObjectTrigger.cls`, `OpportunityTrigger_Test.cls`, `B2B_Integration_test.cls`, `IRM_DocChecklistTest.cls`, `IRM_CaseCreationRuleTest.cls`, `TestNCSPWizardCtrl.cls`, `TestNCSPWizardCtrl_Lightning.cls`, and others). These should be bulk-updated to the new literal alongside the production fix so the test suite keeps exercising the real branches listed in 4a — otherwise tests keep passing but silently stop testing the New/New Deal code paths.

### 5. List Views

| List View | Filter |
|---|---|
| `APAC_Opportunities_200_000USD` | `OPPORTUNITY.TYPE equals "New Deal,Up-Sell/Lift"` |
| `COMMITTED_OPPTIES_LATAM` | same |
| `FULL_PIPELINE_THIS_YR_LATAM` | same |
| `My_Stage_5_Opps_Not_Submitted_To_Booking` | same |
| `My_Won_Opportunities_YTD` | same |
| `OLD_INACTIVE_OPPTIES_LATAM` | same |
| `OPEN_OPPTIES_THIS_QTR_LATAM_Past_Due` | same |
| `Oportunidades_Abiertas_EDN` | same |
| `PIPELINE_THIS_QTR_LATAM` | same |

All 9 list views filter on `Type equals New Deal,Up-Sell/Lift` — every one needs the literal updated or the view will silently stop returning new-deal opportunities.

### 6. Record Types — Picklist Value Availability

`New Deal` is enabled as an available `Type` value on these Record Types (each has its own `<picklistValues><picklist>Type</picklist>` block listing `New Deal`):

`ANZ_Standard_Opportunity`, `CPQ_Billing_Opportunity`, `CPQ_Sales_Opportunity`, `Deal_Registration`, `Framework_Parent_Opportunity`, `IMAP_Standard_Opportunity`, `IME_Standard_Opportunity`, `IMLA_Standard_Opportunity`, `Incubation_Record_type`, `NA_Renewal`, `Renewal_Record_Type`, `Standard_Opportunity`, `Standard_Opportunity_Record_type`.

**Change needed:** once the master value set is updated (see Critical Finding above), confirm each of these Record Types still has the correctly-named value enabled and set as needed (Salesforce keeps the `fullName` reference in record types in sync automatically when a value is renamed in place, but this must be verified post-change — it will **not** update automatically if the change is implemented as delete-old/add-new rather than an in-place rename).

*Separately, `Enterprise_Child` and `Enterprise_Opportunity` record types list `New Deal` against the **`Deal_Type__c`** picklist, not `Type` — confirmed unrelated to this change.*

*Note:* `ANZ_Standard_Opportunity`, `Framework_Parent_Opportunity`, `Incubation_Record_type`, `Renewal_Record_Type`, and `Standard_Opportunity_Record_type` also separately enable `ANZ SFDC - New Deal` — a distinct, ANZ-specific picklist value not in scope for this change.

### 7. Master Picklist Definition

`standardValueSets/OpportunityType.standardValueSet-meta.xml` — this is the single source-of-truth edit point. **See the Critical Pre-Flight Finding above before touching this file** — it already contains a separate `New` value today.

### Confirmed not impacted (checked, no reference found)
Approval Processes, Assignment Rules, Duplicate Rules, Matching Rules, Report Types, Page Layouts, Path Assistants, Custom Metadata Types, Global Value Sets, Permission Sets/Profiles, Quick Actions, Visualforce Pages, LWC/Aura components, Custom Labels.

---

## Recommended Execution Plan

1. **Resolve the New/New Deal collision (blocking, client decision required).** Run `SELECT COUNT(Id), Type FROM Opportunity WHERE Type IN ('New','New Deal') GROUP BY Type` in the sandbox to size both populations before deciding rename-in-place vs. merge vs. choosing a different target label.
2. **Update the master value set** (`OpportunityType` standard value set) to reflect the agreed approach.
3. **Update Apex first**, in dependency order: `QTB_Constants.cls` constant → its two dependents (`QTB_ContractHelper.cls`, `QTB_searchAccountController.cls`) → all other production classes/triggers in section 4a → all test classes in section 4b.
4. **Update Validation Rules** (section 1), paying attention to the 4 currently-inactive rules so they're correct before anyone reactivates them.
5. **Update Flows and Workflow Rules** (sections 2–3), including the legacy `originalFormula` metadata inside `Opportunity_Stage_1_to_4_Post_to_Global_chatter_Group`.
6. **Update List Views** (section 5).
7. **Verify Record Type picklist availability** (section 6) post-change.
8. **Run full regression**: all Apex test classes touching Opportunity.Type (section 4b) plus manual verification of the VF/LWC screens driven by `NCSPWizardCtrl`/`NCSPWizardCtrl_Lightning` and the Schedule A billcode/discount flows, since those carry the highest silent-failure risk.
9. Deploy through the standard NeuraFlash version-controlled path (sandbox first, then promote) — no direct org deploys.

This document reflects the metadata as of the last sandbox sync (2026-07-12). Re-verify against the live org before executing, since declarative changes made directly in Setup since that sync would not appear here.
