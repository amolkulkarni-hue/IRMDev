// Flow-facing wrapper around CaseCreationRuleEvaluatorAction.reevaluateForAccountChanges —
// kept in its own class because CaseCreationRuleEvaluatorAction already exposes evaluate()
// as an @InvocableMethod, and Flow can only unambiguously address one invocable method per
// Apex class. Called from Case_Creation_Account_Reevaluation_Flow (Account, record-triggered,
// after save).
public with sharing class CaseCreationAccountReevaluationAction {

    @InvocableMethod(
        label='Reevaluate Case Creation For Account Changes'
        description='Re-evaluates Case Creation Rules for a changed Account''s open Opportunities when a watched Account field changed.'
        category='IRM Touch Level'
    )
    public static void reevaluateForAccountChanges(List<CaseCreationAccountReevaluationRequest> requests) {
        CaseCreationRuleEvaluatorAction.reevaluateForAccountChanges(requests);
    }
}
