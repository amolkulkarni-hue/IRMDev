import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";
import {
  getObjectInfo,
  getPicklistValuesByRecordType
} from "lightning/uiObjectInfoApi";
import DOCUMENT_CHECKLIST_OBJECT from "@salesforce/schema/Document_Checklist__c";
import getChecklistItems from "@salesforce/apex/IRM_DocumentChecklistUploadController.getChecklistItems";
import finalizeUpload from "@salesforce/apex/IRM_DocumentChecklistUploadController.finalizeUpload";
import updateDocumentType from "@salesforce/apex/IRM_DocumentChecklistUploadController.updateDocumentType";
import updateStatus from "@salesforce/apex/IRM_DocumentChecklistUploadController.updateStatus";
import saveBypass from "@salesforce/apex/IRM_DocumentChecklistUploadController.saveBypass";
import clearBypass from "@salesforce/apex/IRM_DocumentChecklistUploadController.clearBypass";

const STATUS_OPTIONS = [
  { label: "Draft", value: "Draft" },
  { label: "Final", value: "Final" }
];

export default class NfDocumentChecklistUpload extends LightningElement {
  @api recordId;

  items = [];
  isLoading = true;
  showExitDocs = false;
  sectionOverrides = {};
  completedOverrides = {};
  statusOptions = STATUS_OPTIONS;
  recordTypeId;
  categoryOptions = [];
  typeValues = [];
  typeControllerValues = {};

  @wire(getObjectInfo, { objectApiName: DOCUMENT_CHECKLIST_OBJECT })
  wiredObjectInfo({ data }) {
    if (data) {
      this.recordTypeId = data.defaultRecordTypeId;
    }
  }

  // Document Type is dependent on Document Category, so keep the controlling-value index and filter
  // the type list per row.
  @wire(getPicklistValuesByRecordType, {
    objectApiName: DOCUMENT_CHECKLIST_OBJECT,
    recordTypeId: "$recordTypeId"
  })
  wiredPicklistValues({ data }) {
    if (data) {
      const categories = data.picklistFieldValues.Doc_Category__c;
      const types = data.picklistFieldValues.Doc_Type__c;
      this.categoryOptions = categories.values.map(({ label, value }) => ({
        label,
        value
      }));
      this.typeValues = types.values;
      this.typeControllerValues = types.controllerValues;
      this.items = this.items.map((row) => this.withTypeOptions(row));
    }
  }

  typeOptionsFor(category) {
    const index = this.typeControllerValues[category];
    return this.typeValues
      .filter((type) => type.validFor.includes(index))
      .map(({ label, value }) => ({ label, value }));
  }

  withTypeOptions(row) {
    return { ...row, typeOptions: this.typeOptionsFor(row.docCategory) };
  }

  get canEditDocType() {
    return this.categoryOptions.length > 0;
  }

  @wire(getChecklistItems, { recordId: "$recordId" })
  wiredChecklistItems({ data, error }) {
    this.isLoading = false;
    if (data) {
      this.items = data.map((item) => this.toRow(item));
    } else if (error) {
      this.showError(error);
    }
  }

  toRow(item) {
    const hasExistingFile = !!item.existingContentDocumentId;
    const bypassSaved = !!item.bypassRequirement;
    return {
      ...item,
      savedCategory: item.docCategory,
      savedType: item.docType,
      typePending: false,
      isSavingType: false,
      typeOptions: this.typeOptionsFor(item.docCategory),
      hasExistingFile,
      showFileUpload: !hasExistingFile,
      isFinalizing: false,
      uploadLabel: hasExistingFile ? "Replace File" : "Upload File",
      isSellerDoc: item.docSource === "SELLER",
      isExitDoc: item.docSource === "EXIT",
      bypassSaved,
      bypassChecked: bypassSaved,
      bypassJustification: item.bypassJustification || "",
      saveBypassDisabled: true,
      isSavingBypass: false
    };
  }

  // Standard Case key prefix. From a Case every document is shown; from anything else (an
  // Opportunity) Support exit documents are hidden until the user turns them on.
  get isCaseContext() {
    return !!this.recordId && this.recordId.startsWith("500");
  }

  get exitDocCount() {
    return this.items.filter((item) => item.isExitDoc).length;
  }

  get showExitToggle() {
    return !this.isCaseContext && this.exitDocCount > 0;
  }

  get exitToggleLabel() {
    return `Show Support exit documents (${this.exitDocCount})`;
  }

  get visibleItems() {
    const hideExitDocs = !this.isCaseContext && !this.showExitDocs;
    return hideExitDocs
      ? this.items.filter((item) => !item.isExitDoc)
      : this.items;
  }

  get hasVisibleItems() {
    return this.visibleItems.length > 0;
  }

  get emptyMessage() {
    return this.items.length === 0
      ? "No document checklist items found for this record."
      : "No seller-supplied documents for this record. Turn on Show Support exit documents to see the rest.";
  }

  handleExitToggle(event) {
    this.showExitDocs = event.target.checked;
  }

  handleSectionToggle(event) {
    const key = event.target.dataset.sectionKey;
    const section = this.sections.find((candidate) => candidate.key === key);
    if (!section) {
      return;
    }
    this.sectionOverrides = {
      ...this.sectionOverrides,
      [key]: !section.isOpen
    };
  }

  handleCompletedToggle(event) {
    const key = event.target.dataset.sectionKey;
    this.completedOverrides = {
      ...this.completedOverrides,
      [key]: this.completedOverrides[key] !== true
    };
  }

  // Display order and grouping only: items keeps its original order so the row indexes captured by
  // async handlers stay valid. Rows are grouped into one section per Case (Opportunity-level rows
  // first); sections that still have unfinished documents come before fully finalized ones. Inside a
  // section the unfinished documents are listed and the Final ones sit under a collapsed
  // "Completed (n)" fold; a section with nothing left to do starts collapsed. Array.sort is stable,
  // so the server's category/type order is kept inside each tier.
  get sections() {
    const isFinal = (item) => item.status === "Final";
    const groups = new Map();
    this.visibleItems.forEach((item) => {
      const key = item.caseId || "none";
      if (!groups.has(key)) {
        groups.set(key, {
          key,
          caseId: item.caseId,
          caseNumber: item.caseNumber || "",
          caseSubject: item.caseSubject,
          items: []
        });
      }
      groups.get(key).items.push(item);
    });

    const hasOutstanding = (group) =>
      group.items.some((item) => !isFinal(item));
    const ordered = [...groups.values()].sort(
      (a, b) =>
        Number(!hasOutstanding(a)) - Number(!hasOutstanding(b)) ||
        Number(!!a.caseId) - Number(!!b.caseId) ||
        a.caseNumber.localeCompare(b.caseNumber)
    );

    const asRow = (item) => ({
      ...item,
      key: item.checklistId,
      isFoldHeader: false
    });

    return ordered.map((group) => {
      const outstanding = group.items.filter((item) => !isFinal(item));
      const completed = group.items.filter(isFinal);
      const isOpen =
        group.key in this.sectionOverrides
          ? this.sectionOverrides[group.key]
          : outstanding.length > 0;
      const completedOpen = this.completedOverrides[group.key] === true;

      const rows = outstanding.map(asRow);
      if (completed.length > 0) {
        rows.push({
          key: `${group.key}-completed`,
          isFoldHeader: true,
          sectionKey: group.key,
          foldLabel: `Completed (${completed.length})`,
          foldIcon: completedOpen
            ? "utility:chevrondown"
            : "utility:chevronright"
        });
        if (completedOpen) {
          rows.push(...completed.map(asRow));
        }
      }

      let title = "Opportunity-level documents";
      if (group.caseId) {
        title = group.caseNumber
          ? `Case ${group.caseNumber}${group.caseSubject ? ` - ${group.caseSubject}` : ""}`
          : "Case (details not available)";
      }

      return {
        key: group.key,
        title,
        showCaseLink: !!(group.caseId && group.caseNumber),
        caseUrl: group.caseId ? `/lightning/r/Case/${group.caseId}/view` : null,
        progressLabel: `${completed.length} of ${group.items.length} final`,
        isOpen,
        toggleIcon: isOpen ? "utility:chevrondown" : "utility:chevronright",
        rows
      };
    });
  }

  handleClose() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  handleReplaceClick(event) {
    const checklistId = event.target.dataset.checklistId;
    const rowIndex = this.items.findIndex(
      (row) => row.checklistId === checklistId
    );
    if (rowIndex === -1) {
      return;
    }
    this.setRow(rowIndex, { showFileUpload: true });
  }

  handleCancelReplace(event) {
    const checklistId = event.target.dataset.checklistId;
    const rowIndex = this.items.findIndex(
      (row) => row.checklistId === checklistId
    );
    if (rowIndex === -1) {
      return;
    }
    this.setRow(rowIndex, { showFileUpload: false });
  }

  handleCategoryChange(event) {
    const rowIndex = this.rowIndexFor(event);
    if (rowIndex === -1) {
      return;
    }
    const docCategory = event.detail.value;
    const row = this.items[rowIndex];
    if (docCategory === row.docCategory) {
      return;
    }
    // The old type may not belong to the new category, so it is cleared and the user picks again;
    // nothing is saved until a valid type is chosen.
    this.setRow(rowIndex, {
      docCategory,
      docType: null,
      typeOptions: this.typeOptionsFor(docCategory),
      typePending: true
    });
  }

  handleTypeChange(event) {
    const rowIndex = this.rowIndexFor(event);
    if (rowIndex === -1) {
      return;
    }
    const docType = event.detail.value;
    const { checklistId, docCategory, savedCategory, savedType } =
      this.items[rowIndex];
    this.setRow(rowIndex, { docType, isSavingType: true });

    updateDocumentType({ checklistId, docCategory, docType })
      .then(() => {
        this.setRow(rowIndex, {
          savedCategory: docCategory,
          savedType: docType,
          typePending: false
        });
        this.showSuccess("Document type updated.");
      })
      .catch((error) => {
        this.setRow(rowIndex, {
          docCategory: savedCategory,
          docType: savedType,
          typeOptions: this.typeOptionsFor(savedCategory),
          typePending: false
        });
        this.showError(error);
      })
      .finally(() => {
        this.setRow(rowIndex, { isSavingType: false });
      });
  }

  handleStatusChange(event) {
    const checklistId = event.target.dataset.checklistId;
    const newStatus = event.detail.value;
    const rowIndex = this.items.findIndex(
      (row) => row.checklistId === checklistId
    );
    if (rowIndex === -1) {
      return;
    }
    const previousStatus = this.items[rowIndex].status;
    this.setRow(rowIndex, { status: newStatus });

    updateStatus({ checklistId, status: newStatus })
      .then(() => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: "Status updated.",
            variant: "success"
          })
        );
      })
      .catch((error) => {
        this.setRow(rowIndex, { status: previousStatus });
        this.showError(error);
      });
  }

  handleBypassToggle(event) {
    const checked = event.target.checked;
    const rowIndex = this.rowIndexFor(event);
    if (rowIndex === -1) {
      return;
    }
    const row = this.items[rowIndex];

    if (checked) {
      this.setRow(rowIndex, {
        bypassChecked: true,
        bypassJustification: "",
        saveBypassDisabled: true
      });
      return;
    }

    if (!row.bypassSaved) {
      this.setRow(rowIndex, {
        bypassChecked: false,
        bypassJustification: "",
        saveBypassDisabled: true
      });
      return;
    }

    this.setRow(rowIndex, { bypassChecked: false, isSavingBypass: true });
    clearBypass({ checklistId: row.checklistId })
      .then(() => {
        this.setRow(rowIndex, {
          bypassSaved: false,
          bypassJustification: "",
          status: "Draft",
          showFileUpload: !row.hasExistingFile
        });
        this.showSuccess("Bypass removed.");
      })
      .catch((error) => {
        this.setRow(rowIndex, { bypassChecked: true });
        this.showError(error);
      })
      .finally(() => {
        this.setRow(rowIndex, { isSavingBypass: false });
      });
  }

  handleJustificationChange(event) {
    const rowIndex = this.rowIndexFor(event);
    if (rowIndex === -1) {
      return;
    }
    const value = event.target.value || "";
    this.setRow(rowIndex, {
      bypassJustification: value,
      saveBypassDisabled: !value.trim()
    });
  }

  handleSaveBypass(event) {
    const rowIndex = this.rowIndexFor(event);
    if (rowIndex === -1) {
      return;
    }
    const { checklistId } = this.items[rowIndex];
    const justification = this.items[rowIndex].bypassJustification.trim();
    if (!justification) {
      return;
    }
    this.setRow(rowIndex, { isSavingBypass: true, saveBypassDisabled: true });

    saveBypass({ checklistId, justification })
      .then(() => {
        this.setRow(rowIndex, {
          bypassSaved: true,
          bypassJustification: justification,
          status: "Final"
        });
        this.showSuccess("Bypass saved.");
      })
      .catch((error) => {
        this.setRow(rowIndex, { saveBypassDisabled: false });
        this.showError(error);
      })
      .finally(() => {
        this.setRow(rowIndex, { isSavingBypass: false });
      });
  }

  handleUploadFinished(event) {
    const checklistId = event.target.dataset.checklistId;
    const uploadedFile = event.detail.files[0];
    if (!uploadedFile) {
      return;
    }
    this.finalize(checklistId, uploadedFile.documentId, uploadedFile.name);
  }

  finalize(checklistId, newContentDocumentId, fileName) {
    const rowIndex = this.items.findIndex(
      (row) => row.checklistId === checklistId
    );
    if (rowIndex === -1) {
      return;
    }
    const previousContentDocumentId =
      this.items[rowIndex].existingContentDocumentId;
    this.setRow(rowIndex, { isFinalizing: true });

    finalizeUpload({
      checklistId,
      newContentDocumentId,
      previousContentDocumentId
    })
      .then(() => {
        this.setRow(rowIndex, {
          existingContentDocumentId: newContentDocumentId,
          existingFileName: fileName,
          hasExistingFile: true,
          showFileUpload: false,
          uploadLabel: "Replace File",
          status: "Final"
        });
        this.dispatchEvent(
          new ShowToastEvent({
            title: "Success",
            message: `${fileName} uploaded.`,
            variant: "success"
          })
        );
      })
      .catch((error) => this.showError(error))
      .finally(() => {
        this.setRow(rowIndex, { isFinalizing: false });
      });
  }

  rowIndexFor(event) {
    const checklistId = event.target.dataset.checklistId;
    return this.items.findIndex((row) => row.checklistId === checklistId);
  }

  setRow(rowIndex, changes) {
    const items = [...this.items];
    items[rowIndex] = { ...items[rowIndex], ...changes };
    this.items = items;
  }

  showSuccess(message) {
    this.dispatchEvent(
      new ShowToastEvent({ title: "Success", message, variant: "success" })
    );
  }

  showError(error) {
    const message = error?.body?.message || "An unexpected error occurred.";
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Error",
        message,
        variant: "error"
      })
    );
  }
}
