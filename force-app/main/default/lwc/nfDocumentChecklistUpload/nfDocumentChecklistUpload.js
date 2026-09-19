import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getChecklistItems from "@salesforce/apex/IRM_DocumentChecklistUploadController.getChecklistItems";
import finalizeUpload from "@salesforce/apex/IRM_DocumentChecklistUploadController.finalizeUpload";

export default class NfDocumentChecklistUpload extends LightningElement {
  @api recordId;

  items = [];
  isLoading = true;

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
    return {
      ...item,
      hasExistingFile: !!item.existingContentDocumentId,
      isFinalizing: false,
      uploadLabel: item.existingContentDocumentId
        ? "Replace File"
        : "Upload File"
    };
  }

  get hasItems() {
    return this.items.length > 0;
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
