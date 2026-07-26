// Flow-facing wrapper around TouchLevelEvaluatorAction.reevaluateForAccountChanges — kept
// in its own class because TouchLevelEvaluatorAction already exposes evaluate() as an
// @InvocableMethod, and Flow can only unambiguously address one invocable method per Apex
// class. Called from Case_Creation_Account_Reevaluation_Flow (Account, record-triggered,
// after save), ahead of the Case Creation reevaluation action so a freshly recalculated
// Touch_Level__c is visible to it.
public with sharing class TouchLevelAccountReevaluationAction {

    @InvocableMethod(
        label='Reevaluate Touch Level For Account Changes'
        description='Recomputes Touch Level for a changed Account''s open, eligible Opportunities when a watched Account field changed.'
        category='IRM Touch Level'
    )
    public static void reevaluateForAccountChanges(List<TouchLevelAccountReevaluationRequest> requests) {
        TouchLevelEvaluatorAction.reevaluateForAccountChanges(requests);
    }
}
