/**
 * IRM_DocumentChecklistUploadController
 * Powers the nfDocumentChecklistUpload LWC quick action on Opportunity and Case.
 *
 * Lists the Document_Checklist__c rows already related to the Opportunity/Case
 * (rows are pre-generated elsewhere — this controller never creates one), and
 * finalizes a per-row file upload once lightning-file-upload has linked the
 * file to the Document_Checklist__c record: cross-links the same file to the
 * parent Opportunity (and Case, when applicable) via IRM_AttachFilesAction,
 * removes the previous file's links when a row's file is being replaced, and
 * marks the row Final.
 */
public with sharing class IRM_DocumentChecklistUploadController {
  public class ChecklistItem {
    @AuraEnabled
    public Id checklistId;
    @AuraEnabled
    public String docCategory;
    @AuraEnabled
    public String docType;
    @AuraEnabled
    public String status;
    @AuraEnabled
    public Date dueDate;
    @AuraEnabled
    public Boolean isRequired;
    @AuraEnabled
    public Id existingContentDocumentId;
    @AuraEnabled
    public String existingFileName;
  }

  @AuraEnabled(cacheable=true)
  public static List<ChecklistItem> getChecklistItems(Id recordId) {
    try {
      Map<Id, ChecklistItem> itemsByChecklistId = new Map<Id, ChecklistItem>();

      for (Document_Checklist__c row : [
        SELECT
          Id,
          Doc_Category__c,
          Doc_Type__c,
          Status__c,
          Due_Date__c,
          IsRequired__c
        FROM Document_Checklist__c
        WHERE Opportunity__c = :recordId OR Case__c = :recordId
        WITH SECURITY_ENFORCED
        ORDER BY Doc_Category__c, Doc_Type__c
      ]) {
        ChecklistItem item = new ChecklistItem();
        item.checklistId = row.Id;
        item.docCategory = row.Doc_Category__c;
        item.docType = row.Doc_Type__c;
        item.status = row.Status__c;
        item.dueDate = row.Due_Date__c;
        item.isRequired = row.IsRequired__c;
        itemsByChecklistId.put(row.Id, item);
      }

      if (!itemsByChecklistId.isEmpty()) {
        for (ContentDocumentLink link : [
          SELECT ContentDocumentId, LinkedEntityId, ContentDocument.Title
          FROM ContentDocumentLink
          WHERE LinkedEntityId IN :itemsByChecklistId.keySet()
        ]) {
          ChecklistItem item = itemsByChecklistId.get(link.LinkedEntityId);
          item.existingContentDocumentId = link.ContentDocumentId;
          item.existingFileName = link.ContentDocument.Title;
        }
      }

      return itemsByChecklistId.values();
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static void finalizeUpload(
    Id checklistId,
    Id newContentDocumentId,
    Id previousContentDocumentId
  ) {
    try {
      Document_Checklist__c doc = [
        SELECT Id, Opportunity__c, Case__c
        FROM Document_Checklist__c
        WHERE Id = :checklistId
        WITH SECURITY_ENFORCED
        LIMIT 1
      ];

      if (previousContentDocumentId != null) {
        Set<Id> staleTargetIds = new Set<Id>{ doc.Id };
        if (doc.Opportunity__c != null) {
          staleTargetIds.add(doc.Opportunity__c);
        }
        if (doc.Case__c != null) {
          staleTargetIds.add(doc.Case__c);
        }

        List<ContentDocumentLink> staleLinks = [
          SELECT Id
          FROM ContentDocumentLink
          WHERE
            ContentDocumentId = :previousContentDocumentId
            AND LinkedEntityId IN :staleTargetIds
        ];
        if (!staleLinks.isEmpty()) {
          delete as user staleLinks;
        }
      }

      String targetRecordId = doc.Case__c != null
        ? doc.Case__c
        : doc.Opportunity__c;
      String additionalTargetRecordId = (doc.Case__c != null &&
        doc.Opportunity__c != null)
        ? doc.Opportunity__c
        : null;

      if (String.isNotBlank(targetRecordId)) {
        IRM_AttachFilesAction.AttachRequest req = new IRM_AttachFilesAction.AttachRequest();
        req.contentDocumentIds = new List<String>{ newContentDocumentId };
        req.targetRecordId = targetRecordId;
        req.additionalTargetRecordId = additionalTargetRecordId;
        IRM_AttachFilesAction.attachFiles(
          new List<IRM_AttachFilesAction.AttachRequest>{ req }
        );
      }

      doc.Status__c = 'Final';
      doc.Submitted_Date__c = Date.today();
      update as user doc;
    } catch (DmlException dmlEx) {
      throw new AuraHandledException(dmlEx.getDmlMessage(0));
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }
}
