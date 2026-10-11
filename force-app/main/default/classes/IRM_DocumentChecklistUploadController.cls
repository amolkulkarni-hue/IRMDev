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
  public static final String SOURCE_SELLER = 'SELLER';
  public static final String SOURCE_EXIT = 'EXIT';

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
    @AuraEnabled
    public Boolean bypassRequirement;
    @AuraEnabled
    public String bypassJustification;
    @AuraEnabled
    public Id caseId;
    @AuraEnabled
    public String caseNumber;
    @AuraEnabled
    public String caseSubject;
    @AuraEnabled
    public String docSource;
  }

  // Same line the platform flows draw: a row created by the Case Creation Rule engine
  // (Case_Creation_Rule__c set, stamped 'Sales') is a seller-supplied intake document; any other
  // Case-linked row is a support-provided exit document that must be Final before the Case closes.
  // Rows with no Case have no source.
  @TestVisible
  private static String sourceFor(Document_Checklist__c row) {
    if (row.Case__c == null) {
      return null;
    }
    if (
      row.Case_Creation_Rule__c != null ||
      row.Case_Type_Context__c == 'Sales'
    ) {
      return SOURCE_SELLER;
    }
    return SOURCE_EXIT;
  }

  @AuraEnabled(cacheable=true)
  public static List<ChecklistItem> getChecklistItems(Id recordId) {
    try {
      Map<Id, ChecklistItem> itemsByChecklistId = new Map<Id, ChecklistItem>();

      // Case-linked rows often have no Opportunity__c; find them through the Case's Opportunity.
      Set<Id> opportunityCaseIds = new Set<Id>();
      if (canReadCaseOpportunity()) {
        for (Case c : [
          SELECT Id
          FROM Case
          WHERE Opportunity__c = :recordId
          WITH USER_MODE
        ]) {
          opportunityCaseIds.add(c.Id);
        }
      }

      for (Document_Checklist__c row : [
        SELECT
          Id,
          Doc_Category__c,
          Doc_Type__c,
          Status__c,
          Due_Date__c,
          IsRequired__c,
          Bypass_Requirement__c,
          Bypass_Justification__c,
          Case__c,
          Case_Creation_Rule__c,
          Case_Type_Context__c
        FROM Document_Checklist__c
        WHERE
          Opportunity__c = :recordId
          OR Case__c = :recordId
          OR Case__c IN :opportunityCaseIds
        WITH USER_MODE
        ORDER BY Doc_Category__c, Doc_Type__c
      ]) {
        ChecklistItem item = new ChecklistItem();
        item.checklistId = row.Id;
        item.docCategory = row.Doc_Category__c;
        item.docType = row.Doc_Type__c;
        item.status = row.Status__c;
        item.dueDate = row.Due_Date__c;
        item.isRequired = row.IsRequired__c;
        item.bypassRequirement = row.Bypass_Requirement__c;
        item.bypassJustification = row.Bypass_Justification__c;
        item.caseId = row.Case__c;
        item.docSource = sourceFor(row);
        itemsByChecklistId.put(row.Id, item);
      }

      // Case details only when the user can read Cases; Opportunity-only users still get the
      // list, just without the Case label.
      Set<Id> caseIds = new Set<Id>();
      for (ChecklistItem item : itemsByChecklistId.values()) {
        if (item.caseId != null) {
          caseIds.add(item.caseId);
        }
      }
      if (!caseIds.isEmpty() && Schema.sObjectType.Case.isAccessible()) {
        Map<Id, Case> casesById = new Map<Id, Case>(
          [
            SELECT Id, CaseNumber, Subject
            FROM Case
            WHERE Id IN :caseIds
            WITH USER_MODE
          ]
        );
        for (ChecklistItem item : itemsByChecklistId.values()) {
          Case c = casesById.get(item.caseId);
          if (c != null) {
            item.caseNumber = c.CaseNumber;
            item.caseSubject = c.Subject;
          }
        }
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

  private static Boolean canReadCaseOpportunity() {
    return Schema.sObjectType.Case.isAccessible() &&
      Schema.sObjectType.Case.fields.Opportunity__c.isAccessible();
  }

  private static Id opportunityForCase(Id caseId) {
    if (caseId == null || !canReadCaseOpportunity()) {
      return null;
    }
    List<Case> cases = [
      SELECT Opportunity__c
      FROM Case
      WHERE Id = :caseId
      WITH USER_MODE
      LIMIT 1
    ];
    return cases.isEmpty() ? null : cases[0].Opportunity__c;
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
        WITH USER_MODE
        LIMIT 1
      ];

      Id opportunityId = doc.Opportunity__c != null
        ? doc.Opportunity__c
        : opportunityForCase(doc.Case__c);

      if (previousContentDocumentId != null) {
        Set<Id> staleTargetIds = new Set<Id>{ doc.Id };
        if (opportunityId != null) {
          staleTargetIds.add(opportunityId);
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

      String targetRecordId = doc.Case__c != null ? doc.Case__c : opportunityId;
      String additionalTargetRecordId = (doc.Case__c != null &&
        opportunityId != null)
        ? opportunityId
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

  @AuraEnabled
  public static void saveBypass(Id checklistId, String justification) {
    try {
      update as user new Document_Checklist__c(
        Id = checklistId,
        Bypass_Requirement__c = true,
        Bypass_Justification__c = justification,
        Status__c = 'Final'
      );
    } catch (DmlException dmlEx) {
      throw new AuraHandledException(dmlEx.getDmlMessage(0));
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static void clearBypass(Id checklistId) {
    try {
      update as user new Document_Checklist__c(
        Id = checklistId,
        Bypass_Requirement__c = false,
        Bypass_Justification__c = null,
        Status__c = 'Draft'
      );
    } catch (DmlException dmlEx) {
      throw new AuraHandledException(dmlEx.getDmlMessage(0));
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static void updateDocumentType(
    Id checklistId,
    String docCategory,
    String docType
  ) {
    try {
      update as user new Document_Checklist__c(
        Id = checklistId,
        Doc_Category__c = docCategory,
        Doc_Type__c = docType
      );
    } catch (DmlException dmlEx) {
      throw new AuraHandledException(dmlEx.getDmlMessage(0));
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static void updateStatus(Id checklistId, String status) {
    try {
      update as user new Document_Checklist__c(
        Id = checklistId,
        Status__c = status
      );
    } catch (DmlException dmlEx) {
      throw new AuraHandledException(dmlEx.getDmlMessage(0));
    } catch (Exception ex) {
      throw new AuraHandledException(ex.getMessage());
    }
  }
}
