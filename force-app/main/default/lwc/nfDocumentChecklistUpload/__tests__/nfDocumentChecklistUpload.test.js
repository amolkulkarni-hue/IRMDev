import { createElement } from "lwc";
import NfDocumentChecklistUpload from "c/nfDocumentChecklistUpload";
import getChecklistItems from "@salesforce/apex/IRM_DocumentChecklistUploadController.getChecklistItems";
import finalizeUpload from "@salesforce/apex/IRM_DocumentChecklistUploadController.finalizeUpload";
import updateStatus from "@salesforce/apex/IRM_DocumentChecklistUploadController.updateStatus";

const mockChecklistItems = [
  {
    checklistId: "a00000000000001AAA",
    docCategory: "Scoping & Technical",
    docType: "Technical Scoping Form",
    status: "Draft",
    dueDate: "2026-10-01",
    isRequired: true,
    existingContentDocumentId: null,
    existingFileName: null
  },
  {
    checklistId: "a00000000000002AAA",
    docCategory: "SOW & Contracts",
    docType: "Standardized SOW Template",
    status: "Final",
    dueDate: "2026-10-15",
    isRequired: false,
    existingContentDocumentId: "069000000000001AAA",
    existingFileName: "signed-sow.pdf"
  }
];

jest.mock(
  "@salesforce/apex/IRM_DocumentChecklistUploadController.getChecklistItems",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/IRM_DocumentChecklistUploadController.finalizeUpload",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/IRM_DocumentChecklistUploadController.updateStatus",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "lightning/actions",
  () => ({
    CloseActionScreenEvent: class CloseActionScreenEvent extends CustomEvent {
      constructor() {
        super("close", { bubbles: true, composed: true });
      }
    }
  }),
  { virtual: true }
);

describe("c-nf-document-checklist-upload", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent() {
    const element = createElement("c-nf-document-checklist-upload", {
      is: NfDocumentChecklistUpload
    });
    element.recordId = "006000000000001AAA";
    document.body.appendChild(element);
    return element;
  }

  it("renders one row per checklist item", () => {
    const element = createComponent();
    getChecklistItems.emit(mockChecklistItems);

    return Promise.resolve().then(() => {
      const rows = element.shadowRoot.querySelectorAll("tbody tr");
      expect(rows.length).toBe(mockChecklistItems.length);
    });
  });

  it("shows an empty-state message when there are no checklist items", () => {
    const element = createComponent();
    getChecklistItems.emit([]);

    return Promise.resolve().then(() => {
      const emptyState = element.shadowRoot.querySelector(
        "p.slds-text-color_weak"
      );
      expect(emptyState.textContent).toContain(
        "No document checklist items found"
      );
    });
  });

  it("dispatches CloseActionScreenEvent when Close is clicked", () => {
    const element = createComponent();
    getChecklistItems.emit(mockChecklistItems);

    const closeHandler = jest.fn();
    element.addEventListener("close", closeHandler);

    return Promise.resolve().then(() => {
      const closeButton = element.shadowRoot.querySelector(
        'lightning-button[slot="actions"]'
      );
      closeButton.click();
      expect(closeHandler).toHaveBeenCalled();
    });
  });

  describe("a row that already has a file", () => {
    it("shows the existing file name and hides the file picker by default", () => {
      const element = createComponent();
      getChecklistItems.emit(mockChecklistItems);

      return Promise.resolve().then(() => {
        const fileNameEls =
          element.shadowRoot.querySelectorAll("td p.slds-truncate");
        const fileNames = Array.from(fileNameEls).map((el) =>
          el.textContent.trim()
        );
        expect(fileNames.some((text) => text.includes("signed-sow.pdf"))).toBe(
          true
        );

        const fileUpload = element.shadowRoot.querySelector(
          `lightning-file-upload[data-checklist-id="${mockChecklistItems[1].checklistId}"]`
        );
        expect(fileUpload).toBeNull();
      });
    });

    it("reveals the file picker only after clicking Replace File", () => {
      const element = createComponent();
      getChecklistItems.emit(mockChecklistItems);

      return Promise.resolve().then(() => {
        const replaceButton = element.shadowRoot.querySelector(
          `lightning-button[data-checklist-id="${mockChecklistItems[1].checklistId}"]`
        );
        replaceButton.click();

        return Promise.resolve().then(() => {
          const fileUpload = element.shadowRoot.querySelector(
            `lightning-file-upload[data-checklist-id="${mockChecklistItems[1].checklistId}"]`
          );
          expect(fileUpload).not.toBeNull();
        });
      });
    });
  });

  it("finalizes the upload for the row that raised uploadfinished", () => {
    finalizeUpload.mockResolvedValue();
    const element = createComponent();
    getChecklistItems.emit(mockChecklistItems);

    return Promise.resolve().then(() => {
      const fileUpload = element.shadowRoot.querySelector(
        `lightning-file-upload[data-checklist-id="${mockChecklistItems[0].checklistId}"]`
      );
      fileUpload.dispatchEvent(
        new CustomEvent("uploadfinished", {
          detail: {
            files: [{ documentId: "069000000000099AAA", name: "new-file.pdf" }]
          }
        })
      );

      expect(finalizeUpload).toHaveBeenCalledWith({
        checklistId: mockChecklistItems[0].checklistId,
        newContentDocumentId: "069000000000099AAA",
        previousContentDocumentId: null
      });
    });
  });

  it("saves the new value when the Status combobox changes", () => {
    updateStatus.mockResolvedValue();
    const element = createComponent();
    getChecklistItems.emit(mockChecklistItems);

    return Promise.resolve().then(() => {
      const combobox = element.shadowRoot.querySelector(
        `lightning-combobox[data-checklist-id="${mockChecklistItems[1].checklistId}"]`
      );
      combobox.dispatchEvent(
        new CustomEvent("change", { detail: { value: "Draft" } })
      );

      expect(updateStatus).toHaveBeenCalledWith({
        checklistId: mockChecklistItems[1].checklistId,
        status: "Draft"
      });
    });
  });
});
