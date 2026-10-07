import { createElement } from "lwc";
import NfDocumentChecklistUpload from "c/nfDocumentChecklistUpload";
import getChecklistItems from "@salesforce/apex/IRM_DocumentChecklistUploadController.getChecklistItems";
import finalizeUpload from "@salesforce/apex/IRM_DocumentChecklistUploadController.finalizeUpload";
import updateStatus from "@salesforce/apex/IRM_DocumentChecklistUploadController.updateStatus";
import saveBypass from "@salesforce/apex/IRM_DocumentChecklistUploadController.saveBypass";
import clearBypass from "@salesforce/apex/IRM_DocumentChecklistUploadController.clearBypass";

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
  "@salesforce/apex/IRM_DocumentChecklistUploadController.saveBypass",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/IRM_DocumentChecklistUploadController.clearBypass",
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

  describe("sorting", () => {
    it("lists unfinished rows first and Final rows last, keeping server order within each group", () => {
      const row = (id, status) => ({
        ...mockChecklistItems[0],
        checklistId: id,
        status
      });
      const element = createComponent();
      getChecklistItems.emit([
        row("a00000000000001AAA", "Final"),
        row("a00000000000002AAA", "Draft"),
        row("a00000000000003AAA", "Final"),
        row("a00000000000004AAA", "Draft")
      ]);

      return Promise.resolve().then(() => {
        const ids = Array.from(
          element.shadowRoot.querySelectorAll("tbody lightning-combobox")
        ).map((el) => el.dataset.checklistId);
        expect(ids).toEqual([
          "a00000000000002AAA",
          "a00000000000004AAA",
          "a00000000000001AAA",
          "a00000000000003AAA"
        ]);
      });
    });
  });

  describe("bypass", () => {
    const draftId = mockChecklistItems[0].checklistId;
    const flush = () =>
      Array.from({ length: 10 }).reduce(
        (p) => p.then(() => {}),
        Promise.resolve()
      );

    function find(element, selector) {
      return element.shadowRoot.querySelector(selector);
    }

    function setBypass(element, checked) {
      const checkbox = find(
        element,
        `lightning-input[data-checklist-id="${draftId}"]`
      );
      checkbox.checked = checked;
      checkbox.dispatchEvent(new CustomEvent("change"));
    }

    function typeJustification(element, value) {
      const textarea = find(
        element,
        `lightning-textarea[data-checklist-id="${draftId}"]`
      );
      textarea.value = value;
      textarea.dispatchEvent(new CustomEvent("change"));
    }

    function saveButton(element) {
      return find(element, `lightning-button[data-checklist-id="${draftId}"]`);
    }

    it("shows a required justification box and a disabled Save when Bypass is checked, and hides the uploader", async () => {
      const element = createComponent();
      getChecklistItems.emit(mockChecklistItems);
      await flush();

      setBypass(element, true);
      await flush();

      const textarea = find(
        element,
        `lightning-textarea[data-checklist-id="${draftId}"]`
      );
      expect(textarea).not.toBeNull();
      expect(textarea.required).toBe(true);
      expect(saveButton(element).disabled).toBe(true);
      expect(
        find(element, `lightning-file-upload[data-checklist-id="${draftId}"]`)
      ).toBeNull();
    });

    it("keeps Save disabled for a whitespace-only justification and enables it once text is entered", async () => {
      const element = createComponent();
      getChecklistItems.emit(mockChecklistItems);
      await flush();
      setBypass(element, true);
      await flush();

      typeJustification(element, "   ");
      await flush();
      expect(saveButton(element).disabled).toBe(true);

      typeJustification(element, "Not applicable");
      await flush();
      expect(saveButton(element).disabled).toBe(false);
    });

    it("saves the trimmed justification, marks the row Final and locks the status", async () => {
      saveBypass.mockResolvedValue();
      const element = createComponent();
      getChecklistItems.emit(mockChecklistItems);
      await flush();
      setBypass(element, true);
      await flush();
      typeJustification(element, "  Not applicable  ");
      await flush();

      saveButton(element).click();
      await flush();

      expect(saveBypass).toHaveBeenCalledWith({
        checklistId: draftId,
        justification: "Not applicable"
      });
      const combobox = find(
        element,
        `lightning-combobox[data-checklist-id="${draftId}"]`
      );
      expect(combobox.value).toBe("Final");
      expect(combobox.disabled).toBe(true);
      expect(
        find(element, `lightning-textarea[data-checklist-id="${draftId}"]`)
      ).toBeNull();
    });

    it("discards an unsaved bypass without calling Apex", async () => {
      const element = createComponent();
      getChecklistItems.emit(mockChecklistItems);
      await flush();
      setBypass(element, true);
      await flush();

      setBypass(element, false);
      await flush();

      expect(clearBypass).not.toHaveBeenCalled();
      expect(
        find(element, `lightning-textarea[data-checklist-id="${draftId}"]`)
      ).toBeNull();
    });

    it("undoes a saved bypass, returning the row to Draft with the uploader available", async () => {
      clearBypass.mockResolvedValue();
      const element = createComponent();
      getChecklistItems.emit([
        {
          ...mockChecklistItems[0],
          status: "Final",
          bypassRequirement: true,
          bypassJustification: "Not applicable"
        }
      ]);
      await flush();
      expect(
        find(element, `lightning-textarea[data-checklist-id="${draftId}"]`)
      ).toBeNull();

      setBypass(element, false);
      await flush();

      expect(clearBypass).toHaveBeenCalledWith({ checklistId: draftId });
      const combobox = find(
        element,
        `lightning-combobox[data-checklist-id="${draftId}"]`
      );
      expect(combobox.value).toBe("Draft");
      expect(combobox.disabled).toBe(false);
      expect(
        find(element, `lightning-file-upload[data-checklist-id="${draftId}"]`)
      ).not.toBeNull();
    });
  });
});
