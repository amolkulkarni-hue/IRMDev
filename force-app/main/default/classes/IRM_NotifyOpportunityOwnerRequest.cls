// Top-level (not inner) by requirement — Flow's Apex-Defined Data Type variables don't
// support inner classes, and this type is built as a collection variable in
// Case_Exit_Doc_Checklist_Creation_Flow to bulk-call IRM_NotifyOpportunityOwnerAction.
public class IRM_NotifyOpportunityOwnerRequest {
    @InvocableVariable(label='Opportunity Id' required=true)
    public Id opportunityId;
    @InvocableVariable(label='Opportunity Owner Id' required=true)
    public Id opportunityOwnerId;
    @InvocableVariable(label='Record Id' required=true)
    public Id recordId;
    @InvocableVariable(label='Record Label (e.g. Case, Document Checklist)' required=true)
    public String recordLabel;
}
