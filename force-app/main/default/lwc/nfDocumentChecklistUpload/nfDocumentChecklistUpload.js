import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";
import getChecklistItems from "@salesforce/apex/IRM_DocumentChecklistUploadController.getChecklistItems";
import finalizeUpload from "@salesforce/apex/IRM_DocumentChecklistUploadController.finalizeUpload";
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
  statusOptions = STATUS_OPTIONS;

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
      hasExistingFile,
      showFileUpload: !hasExistingFile,
      isFinalizing: false,
      uploadLabel: hasExistingFile ? "Replace File" : "Upload File",
      isSellerDoc: item.docSource === "SELLER",
      isExitDoc: item.docSource === "EXIT",
      showCaseLink: !!(item.caseId && item.caseNumber),
      caseUrl: item.caseId ? `/lightning/r/Case/${item.caseId}/view` : null,
      caseLabel: item.caseSubject
        ? `Case ${item.caseNumber} - ${item.caseSubject}`
        : `Case ${item.caseNumber}`,
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

  // Display order only: items keeps its original order so the row indexes
  // captured by async handlers stay valid. Array.sort is stable, so each group
  // keeps the server's category/type order.
  get sortedItems() {
    return [...this.visibleItems].sort(
      (a, b) => Number(a.status === "Final") - Number(b.status === "Final")
    );
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
