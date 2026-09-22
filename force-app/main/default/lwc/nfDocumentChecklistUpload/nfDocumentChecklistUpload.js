import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";
import getChecklistItems from "@salesforce/apex/IRM_DocumentChecklistUploadController.getChecklistItems";
import finalizeUpload from "@salesforce/apex/IRM_DocumentChecklistUploadController.finalizeUpload";
import updateStatus from "@salesforce/apex/IRM_DocumentChecklistUploadController.updateStatus";

const STATUS_OPTIONS = [
  { label: "Draft", value: "Draft" },
  { label: "Final", value: "Final" }
];

export default class NfDocumentChecklistUpload extends LightningElement {
  @api recordId;

  items = [];
  isLoading = true;
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
    return {
      ...item,
      hasExistingFile,
      showFileUpload: !hasExistingFile,
      isFinalizing: false,
      uploadLabel: hasExistingFile ? "Replace File" : "Upload File"
    };
  }

  get hasItems() {
    return this.items.length > 0;
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

  setRow(rowIndex, changes) {
    const items = [...this.items];
    items[rowIndex] = { ...items[rowIndex], ...changes };
    this.items = items;
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
