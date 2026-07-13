/**
 * IRM_AttachFilesAction
 * US-DOCUPLOAD: Invocable action called by Upload_Document_Checklist_Flow.
 *
 * Creates ContentDocumentLink records for the given ContentDocumentIds on:
 *   1. targetRecordId (the Case or Opportunity the quick action was invoked from)
 *   2. additionalTargetRecordId (the linked Opportunity, only when invoked from a Case)
 *
 * The flow itself uploads files directly to the Document_Checklist__c record.
 * This action links those same files to the parent Case/Opp (always) and to the
 * Opportunity (when uploaded from a Case), per the cross-linking requirement.
 *
 * Deduplicates against existing ContentDocumentLinks to prevent DUPLICATE_VALUE errors.
 */
public class IRM_AttachFilesAction {

    public class AttachRequest {
        @InvocableVariable(required=true label='Content Document IDs')
        public List<String> contentDocumentIds;

        @InvocableVariable(required=true label='Target Record ID (Case or Opportunity)')
        public String targetRecordId;

        @InvocableVariable(required=false label='Additional Target Record ID (Opportunity, only when invoked from Case)')
        public String additionalTargetRecordId;
    }

    @InvocableMethod(
        label='Attach Files to Parent Record'
        description='Links uploaded files to the parent Case/Opp and optionally to the linked Opportunity (when invoked from Case). Called by Upload_Document_Checklist_Flow.'
    )
    public static void attachFiles(List<AttachRequest> requests) {
        List<ContentDocumentLink> linksToInsert = new List<ContentDocumentLink>();

        for (AttachRequest req : requests) {
            if (req.contentDocumentIds == null || req.contentDocumentIds.isEmpty()) {
                continue;
            }

            Set<String> docIds = new Set<String>(req.contentDocumentIds);
            Set<String> targetIds = new Set<String>{ req.targetRecordId };
            if (String.isNotBlank(req.additionalTargetRecordId)) {
                targetIds.add(req.additionalTargetRecordId);
            }

            Set<String> existingKeys = new Set<String>();
            for (ContentDocumentLink cdl : [
                SELECT ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE ContentDocumentId IN :docIds
                  AND LinkedEntityId IN :targetIds
            ]) {
                existingKeys.add((String) cdl.ContentDocumentId + '_' + (String) cdl.LinkedEntityId);
            }

            for (String docId : docIds) {
                String key = docId + '_' + req.targetRecordId;
                if (!existingKeys.contains(key)) {
                    linksToInsert.add(new ContentDocumentLink(
                        ContentDocumentId = docId,
                        LinkedEntityId = req.targetRecordId,
                        ShareType = 'V',
                        Visibility = 'AllUsers'
                    ));
                }
            }

            if (String.isNotBlank(req.additionalTargetRecordId)) {
                for (String docId : docIds) {
                    String key = docId + '_' + req.additionalTargetRecordId;
                    if (!existingKeys.contains(key)) {
                        linksToInsert.add(new ContentDocumentLink(
                            ContentDocumentId = docId,
                            LinkedEntityId = req.additionalTargetRecordId,
                            ShareType = 'V',
                            Visibility = 'AllUsers'
                        ));
                    }
                }
            }
        }

        if (!linksToInsert.isEmpty()) {
            insert linksToInsert;
        }
    }
}