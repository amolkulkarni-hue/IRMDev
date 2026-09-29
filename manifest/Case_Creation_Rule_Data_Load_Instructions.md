# Case Creation Rule Data Load — Deployment Instructions

**Scope:** loading Case Creation Rule configuration data (`Case_Creation_Rule__c`,
`Case_Creation_Condition__c`, `Case_Creation_Doc_Requirement__c`,
`Case_Exit_Doc_Requirement__c`) into a new/target Salesforce org. This does not
cover Touch Level Classification seed data (`Touch_Level_Criteria__c`,
`Touch_Level_Condition__c`) or any other object — those are unchanged and out
of scope for this load.

**Files provided (in this `manifest/` folder):**

| File                                          | Rows | Join key                                                                                    |
| --------------------------------------------- | ---- | ------------------------------------------------------------------------------------------- |
| `load-only-Case_Creation_Rule.csv`            | 35   | `Rule_Name` → maps to `Name`                                                                |
| `load-only-Case_Creation_Condition.csv`       | 135  | `Rule_Name` (lookup, not a stored field)                                                    |
| `load-only-Case_Creation_Doc_Requirement.csv` | 41   | `Rule_Name` (lookup, not a stored field)                                                    |
| `load-only-Case_Exit_Doc_Requirement.csv`     | 16   | `Case_Type__c` + `Case_Record_Type_Dev_Name__c` (no rule link — this object is independent) |

None of these files contain org-specific record Ids. All relationships are
represented by Name/Case Type text so they can be loaded into any org where
the prerequisite metadata below already exists.

---

## 1. Prerequisites — confirm before loading any data

The following metadata must already be deployed to the target org. If any of
it is missing, conditions will either fail to insert (bad field API name) or
insert but never evaluate correctly at runtime — load will "succeed" while
the rules silently don't work, which is worse than a load error.

- **Objects:** `Case_Creation_Rule__c`; `Case_Creation_Condition__c` and
  `Case_Creation_Doc_Requirement__c` (both Master-Detail children of
  `Case_Creation_Rule__c`); `Case_Exit_Doc_Requirement__c` (standalone, no
  parent link).
- **Opportunity fields referenced in conditions:** `Amount_USD__c`,
  `ALM_BU__c` / `RIM_BU__c` / `Digital_BU__c` / `W_L_BU__c` / `MAS_BU__c`,
  `RFx_RFI_RFQ_RFP__c`, `Remarketing_Required__c`,
  `Custom_Solution_Required__c`, `Multi_BU_Flag__c`, `Multi_Country__c`,
  `IM_Sales_Event__c`, `Type`, `Region__c`, `Primary_Product_Line__c`,
  `Expected_CuFt__c`.
- **Account fields referenced in conditions:** `Sales_Strategic_Account__c`,
  `IM_Industry__c`, `Sector__c`.
- **Record Type:** `Framework_Parent_Opportunity` must exist on Opportunity
  with that exact DeveloperName. (One condition compares `RecordTypeId` — the
  data file stores the _source org's_ Id as a literal value; see Step 2a,
  this needs to be re-resolved per target org, it is not portable as-is.)
- **Queues:** the 10 canonical queues per SDD v26.9 §8.5
  (`Solution_Architects_Queue`, `Bid_Management_Queue`, `Remarketing_Queue`,
  `Deal_Desk_Queue`, `InfoSec_Queue`, `Revenue_Management_Queue`,
  `Legal_GCCS_Queue`, `Managed_Services_Queue`, `Finance_Commercial_Queue`,
  `B2B_Implementation_Queue`), plus any BU sub-queues referenced by name in
  the data (e.g. `ALM_Deal_Desk`).
- **Case Record Types:** `Deal_Support` and `Post_Sale_Support`.
- **Doc_Category__c / Doc_Type__c** global-value-set-backed dependent
  picklists on `Case_Creation_Doc_Requirement__c` and
  `Case_Exit_Doc_Requirement__c`, including the `"Solution Design Document
(SDD)"` value added under the Scoping & Technical category — see
  `Doc_Type_SDD_Value_Deployment_Tracker.csv` in this same folder for the
  exact metadata change and which objects it was (and wasn't) wired into.

## 2. Step 1 — Clean up existing data in the target org

Before reloading, delete **all existing records** for these 4 objects in the
target environment — even ones that look unrelated or pre-existing — so
there is no chance of duplicate or conflicting rules after the new data
lands.

a. **Delete all `Case_Creation_Rule__c` records first.** This cascades and
automatically deletes their child `Case_Creation_Condition__c` and
`Case_Creation_Doc_Requirement__c` records (both are Master-Detail
children). Do not attempt to delete the children separately first — the
cascade handles it, and deleting children independently first is
unnecessary extra work.

```
sf data query -o <targetOrg> -q "SELECT Id FROM Case_Creation_Rule__c" -r csv > old_rule_ids.csv
sf data delete bulk -o <targetOrg> -s Case_Creation_Rule__c -f old_rule_ids.csv --wait 10
```

b. **Delete all `Case_Exit_Doc_Requirement__c` records separately.** This
object has no parent link to `Case_Creation_Rule__c`, so it is _not_
touched by the cascade in step (a) — it must be cleaned up on its own.

```
sf data query -o <targetOrg> -q "SELECT Id FROM Case_Exit_Doc_Requirement__c" -r csv > old_exitdoc_ids.csv
sf data delete bulk -o <targetOrg> -s Case_Exit_Doc_Requirement__c -f old_exitdoc_ids.csv --wait 10
```

## 3. Step 2 — Load the new data, in this exact order

1. **Import `load-only-Case_Creation_Rule.csv` directly** into
   `Case_Creation_Rule__c` — map the `Rule_Name` column to the standard
   `Name` field.

   > **One field needs manual handling before this import:** any row whose
   > `Logic_Expression__c`/condition data implies a `RecordTypeId` comparison
   > (search the source rules for `RecordTypeId` in the condition list —
   > currently one Solution Architects rule, tied to `Framework_Parent_Opportunity`)
   > stores the **source org's** Record Type Id, which will not resolve in
   > the target org. Query the target org's own `Framework_Parent_Opportunity`
   > Id (`SELECT Id FROM RecordType WHERE SObjectType='Opportunity' AND
DeveloperName='Framework_Parent_Opportunity'`) and substitute it into
   > that condition's `Value__c` in `load-only-Case_Creation_Condition.csv`
   > before importing conditions in step 3.

2. **Query back the newly-inserted rules** to get the target org's new
   record Ids:
   ```
   sf data query -o <targetOrg> -q "SELECT Id, Name FROM Case_Creation_Rule__c" --json
   ```
3. **In `load-only-Case_Creation_Condition.csv` and
   `load-only-Case_Creation_Doc_Requirement.csv`, VLOOKUP-replace every
   `Rule_Name` value with the matching new `Case_Creation_Rule__c` Id** from
   step 2 (rename the column to `Rule__c` once replaced — that's the actual
   lookup field API name). Then import each into
   `Case_Creation_Condition__c` / `Case_Creation_Doc_Requirement__c`.
4. **Import `load-only-Case_Exit_Doc_Requirement.csv` directly** into
   `Case_Exit_Doc_Requirement__c` — no Id lookup needed, this object has no
   parent link.

## 4. Bulk API notes

- Include `--line-ending CRLF` on every `sf data import bulk` call in this
  load. It's not strictly required for this specific export (no embedded
  newlines in these particular values), but it's safe to always include and
  avoids the "LineEnding is invalid on user data" error seen elsewhere on
  this project when it's omitted and a value _does_ contain one.
- A blank `Value__c` cell in the Condition file is correct and expected for
  `IS_TRUE`/`IS_FALSE` operator rows — those don't compare against a value.
  Don't backfill or "fix" blanks there.

## 5. Verification after load

Re-query and confirm exact record counts match:

| Object                             | Expected count |
| ---------------------------------- | -------------- |
| `Case_Creation_Rule__c`            | 35             |
| `Case_Creation_Condition__c`       | 135            |
| `Case_Creation_Doc_Requirement__c` | 41             |
| `Case_Exit_Doc_Requirement__c`     | 16             |

Spot-check at least 2-3 rules whose `Logic_Expression__c` contains
parentheses (any Solution Architects rule is a good candidate) — confirm
every condition number referenced in the expression has a matching sibling
`Case_Creation_Condition__c` record with that `Condition_Number__c`, on the
correct parent rule.

## 6. Known open items — not load errors, already-accepted gaps

These were identified and explicitly deferred during the source build; they
are not something to fix during data load, just don't be surprised by them:

- `GCCS` and `Finance` Case Types have queues and Case Type values but no
  `Case_Creation_Rule__c` routing rule yet (no criteria supplied by the
  client as of this load).
- Two condition concepts (`Solution type` and `Revenue Type`, referenced in
  the client's original logic sheet) have no corresponding Opportunity field
  and were dropped from the loaded logic rather than guessed at.
- `Region__c` conditions compare against exact free-text values (`Latin
America`, `Europe`, `MENAT`, `North America`, `Asia Pacific`) confirmed by
  the client — there is no picklist constraint on this field, so a typo in
  real Opportunity data (e.g. "LATAM" instead of "Latin America") will
  silently fail to match rather than error.
