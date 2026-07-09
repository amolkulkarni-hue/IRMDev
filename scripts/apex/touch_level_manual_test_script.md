# Touch Level Manual Test Script (v23.0 Apex recalculation)

## Setup

Run `load_touch_level_manual_test_record.apex` (same folder) once via:

```
sf apex run --file scripts/apex/load_touch_level_manual_test_record.apex -o IRMDev
```

(Or paste it into Developer Console → Debug → Open Execute Anonymous Window.) The debug log prints the Opportunity Id and a direct link. Re-running the script at any time deletes and recreates the record, resetting you back to Step 0.

This uses the **real, already-active** `Touch_Level_Criteria__c` records in this org (`TLC-Q-*` at Qualification, `TLC-S-*` at Solutioning) — no new criteria are created. In practice these are pure Amount thresholds (their extra OR'd conditions reference `Strategic_Account__c` / `Bid_RFP__c` / `Account_Segment__c`, none of which exist on Opportunity in this org, so those branches are always false):

| Stage | Amount | Touch Level |
|---|---|---|
| Qualification | < 100,000 | Low Touch |
| Qualification | 100,000 – 499,999 | Medium Touch |
| Qualification | ≥ 500,000 | High Touch |
| Solutioning | < 100,000 | **No Touch** (no Low Touch rule defined at this stage) |
| Solutioning | 100,000 – 499,999 | Medium Touch |
| Solutioning | ≥ 500,000 | High Touch |

Open the Opportunity record and make sure `Touch_Level__c`, `Touch_Level_Calculated__c`, and `Touch_Level_Criteria_Matched__c` are visible (add them to the page layout / a related list panel if they aren't already showing).

## Test Steps

| # | What to change | Save | Expected `Touch_Level__c` | Expected `Touch_Level_Calculated__c` | Why |
|---|---|---|---|---|---|
| 0 | (starting state after running the script) | — | `Low Touch` | `Low Touch` | Insert always triggers calculation. Amount = 50,000 at Qualification matches `TLC-Q-LT-003`. |
| 1 | Change **Stage** from `Qualification` to `Solutioning`. Leave Amount at 50,000. | Save | `No Touch` | `No Touch` | Proves a **Stage change alone** triggers recalculation. At Solutioning, 50,000 doesn't meet either Solutioning rule's threshold, and there's no Solutioning Low-Touch rule — so it resolves to No Touch. `Touch_Level_Criteria_Matched__c` should now be blank. |
| 2 | Change **Amount** to `150000`. Leave Stage at Solutioning. | Save | `Medium Touch` | `Medium Touch` | Proves an **Amount change alone** (no stage change) triggers recalculation — matches `TLC-S-MT-002`. |
| 3 | Change **Amount** to `600000`. | Save | `High Touch` | `High Touch` | Further Amount-driven escalation — matches `TLC-S-HT-001`. |
| 4 | Change **Amount** back down to `50000`. | Save | `High Touch` (unchanged) | `No Touch` | **No-downgrade rule**: once High Touch, the displayed value never auto-downgrades. `Touch_Level_Calculated__c` still shows the true recalculated value underneath, for audit purposes — this is the visible proof the recalculation *did* run, it just didn't overwrite the displayed field. |
| 5 | Use the **"Override Touch Level"** Quick Action (or set `Touch_Level_Override__c` = checked directly): pick e.g. `Medium Touch`, enter a reason, save. | Save | `Medium Touch` | `No Touch` (unchanged from step 4) | Manual override takes effect immediately. |
| 6 | With override still on, change **Amount** to `600000` again. | Save | `Medium Touch` (unchanged) | `No Touch` (unchanged) | Proves **override fully bypasses recalculation** — neither field updates while `Touch_Level_Override__c` is checked. |
| 7 (optional) | Uncheck `Touch_Level_Override__c`, then change **Amount** to `1` (any change to re-trigger). | Save | `High Touch`* | `No Touch` | Recalculation resumes once override is off. *No-downgrade still applies if the field's prior displayed value was High Touch before the override — check what's currently in `Touch_Level__c` before this step and adjust your expectation accordingly. |

## Optional: Record-Type Scoping Check

Create a second test Opportunity with a **different Record Type** (e.g. "IME Standard Opportunity" or "CPQ Sales Opportunity" — anything other than "Standard Opportunity" or "Framework Parent Opportunity"), set Amount to 600,000 and Stage to Qualification, and save.

**Expected:** `Touch_Level__c`, `Touch_Level_Calculated__c`, and `Touch_Level_Criteria_Matched__c` all stay **blank**, no matter what Stage/Amount you set — proving Touch Level calculation is scoped to only Standard Opportunity and Framework Parent Opportunity record types (v23.0).

## Notes

- All recalculation now happens synchronously in Apex (`OpportunityTriggerHandler` → `TouchLevelEvaluatorAction.recalculateBeforeSave`) — you'll see the new value immediately on save, no delay.
- If a Stage change fails with a validation error about a required field (Budget Validated, Champion, Business Problem, etc.), the seed script already populates all of these — if you cloned the record instead of using the script fresh, re-run the script.
- Step 1's "No Touch" result is a real, pre-existing gap in the production criteria config (no Low-Touch rule defined for Solutioning) — not something introduced by this change. Worth flagging to whoever owns `Touch_Level_Criteria__c` if it's unintended.
