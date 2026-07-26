// Top-level (not inner) by requirement — Flow's Apex-Defined Data Type variables don't
// support inner classes. Carries both the new and prior Account snapshot so
// CaseCreationRuleEvaluatorAction.reevaluateForAccountChanges can diff watched Account
// fields itself, rather than duplicating that logic in Case_Creation_Account_Reevaluation_Flow's
// entry criteria (which would otherwise need manual upkeep every time an admin adds a new
// "Account.<field>" condition).
public class CaseCreationAccountReevaluationRequest {
    @InvocableVariable(label='New Account' required=true)
    public Account newAccount;
    @InvocableVariable(label='Prior Account')
    public Account oldAccount;
}
