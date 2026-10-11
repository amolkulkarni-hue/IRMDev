import { createElement } from "lwc";
import NfDocumentChecklistUpload from "c/nfDocumentChecklistUpload";
import getChecklistItems from "@salesforce/apex/IRM_DocumentChecklistUploadController.getChecklistItems";
import finalizeUpload from "@salesforce/apex/IRM_DocumentChecklistUploadController.finalizeUpload";
import updateStatus from "@salesforce/apex/IRM_DocumentChecklistUploadController.updateStatus";
import updateDocumentType from "@salesforce/apex/IRM_DocumentChecklistUploadController.updateDocumentType";
import {
  getObjectInfo,
  getPicklistValuesByRecordType
} from "lightning/uiObjectInfoApi";
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
  "@salesforce/apex/IRM_DocumentChecklistUploadController.updateDocumentType",
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

  function createComponent(recordId = "006000000000001AAA") {
    const element = createElement("c-nf-document-checklist-upload", {
      is: NfDocumentChecklistUpload
    });
    element.recordId = recordId;
    document.body.appendChild(element);
    return element;
  }

  const flush = () =>
    Array.from({ length: 10 }).reduce(
      (p) => p.then(() => {}),
      Promise.resolve()
    );

  // Finalized documents sit under a collapsed "Completed (n)" fold in each section.
  async function openCompleted(element) {
    element.shadowRoot
      .querySelectorAll("lightning-button-icon[data-section-key]")
      .forEach((button) => {
        if (button.iconName === "utility:chevronright") {
          button.click();
        }
      });
    await flush();
    element.shadowRoot
      .querySelectorAll("lightning-button[data-section-key]")
      .forEach((button) => button.click());
    await flush();
  }

  function sectionTitles(element) {
    return Array.from(
      element.shadowRoot.querySelectorAll(".section-header")
    ).map((header) => {
      const link = header.querySelector("lightning-formatted-url");
      return link
        ? link.label
        : header.querySelector(".slds-text-title_caps").textContent.trim();
    });
  }

  it("shows outstanding documents and folds finalized ones under Completed", async () => {
    const element = createComponent();
    getChecklistItems.emit(mockChecklistItems);
    await flush();
    expect(element.shadowRoot.querySelectorAll(".doc-block")).toHaveLength(1);

    await openCompleted(element);
    expect(element.shadowRoot.querySelectorAll(".doc-block")).toHaveLength(
      mockChecklistItems.length
    );
  });

  it("lays each document out as a stacked block, not a table, with the due date and required marker in the details", () => {
    const element = createComponent();
    getChecklistItems.emit(mockChecklistItems);

    return Promise.resolve().then(() => {
      expect(element.shadowRoot.querySelector("table")).toBeNull();

      const block = element.shadowRoot.querySelector(".doc-block");
      expect(block.textContent).toContain("Due 2026-10-01");
      expect(block.querySelector("abbr.slds-required")).not.toBeNull();
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
    it("shows the existing file name and hides the file picker by default", async () => {
      const element = createComponent();
      getChecklistItems.emit(mockChecklistItems);
      await flush();
      await openCompleted(element);

      const names = Array.from(
        element.shadowRoot.querySelectorAll(".file-name")
      ).map((el) => el.textContent.trim());
      expect(names.some((text) => text.includes("signed-sow.pdf"))).toBe(true);
      expect(
        element.shadowRoot.querySelector(
          `lightning-file-upload[data-checklist-id="${mockChecklistItems[1].checklistId}"]`
        )
      ).toBeNull();
    });

    it("reveals the file picker only after clicking Replace File", async () => {
      const element = createComponent();
      getChecklistItems.emit(mockChecklistItems);
      await flush();
      await openCompleted(element);

      element.shadowRoot
        .querySelector(
          `lightning-button[data-checklist-id="${mockChecklistItems[1].checklistId}"]`
        )
        .click();
      await flush();

      expect(
        element.shadowRoot.querySelector(
          `lightning-file-upload[data-checklist-id="${mockChecklistItems[1].checklistId}"]`
        )
      ).not.toBeNull();
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

  it("saves the new value when the Status combobox changes", async () => {
    updateStatus.mockResolvedValue();
    const element = createComponent();
    getChecklistItems.emit(mockChecklistItems);
    await flush();

    const combobox = element.shadowRoot.querySelector(
      `lightning-combobox[data-checklist-id="${mockChecklistItems[0].checklistId}"]`
    );
    combobox.dispatchEvent(
      new CustomEvent("change", { detail: { value: "Final" } })
    );

    expect(updateStatus).toHaveBeenCalledWith({
      checklistId: mockChecklistItems[0].checklistId,
      status: "Final"
    });
  });

  describe("sorting", () => {
    it("lists unfinished rows first, with Final rows folded under Completed after them", async () => {
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
      await flush();
      const ids = () =>
        Array.from(
          element.shadowRoot.querySelectorAll("lightning-combobox")
        ).map((el) => el.dataset.checklistId);
      expect(ids()).toEqual(["a00000000000002AAA", "a00000000000004AAA"]);

      await openCompleted(element);
      expect(ids()).toEqual([
        "a00000000000002AAA",
        "a00000000000004AAA",
        "a00000000000001AAA",
        "a00000000000003AAA"
      ]);
    });
  });

  describe("bypass", () => {
    const draftId = mockChecklistItems[0].checklistId;

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
      await openCompleted(element);

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
      await openCompleted(element);
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

  describe("case context", () => {
    const base = mockChecklistItems[0];
    const seller = {
      ...base,
      checklistId: "a00000000000011AAA",
      caseId: "500000000000001AAA",
      caseNumber: "00012345",
      caseSubject: "Onboarding",
      docSource: "SELLER"
    };
    const exit = {
      ...base,
      checklistId: "a00000000000012AAA",
      caseId: "500000000000001AAA",
      caseNumber: "00012345",
      caseSubject: "Onboarding",
      docSource: "EXIT"
    };
    const plain = { ...base, checklistId: "a00000000000013AAA" };

    function rowFor(element, id) {
      return Array.from(element.shadowRoot.querySelectorAll(".doc-item")).find(
        (item) =>
          item.querySelector(`lightning-combobox[data-checklist-id="${id}"]`)
      );
    }

    it("labels seller documents and support exit documents, and nothing else", () => {
      const element = createComponent("500000000000001AAA");
      getChecklistItems.emit([seller, exit, plain]);

      return Promise.resolve().then(() => {
        const labels = (id) =>
          Array.from(
            rowFor(element, id).querySelectorAll("lightning-badge")
          ).map((b) => b.label);
        expect(labels(seller.checklistId)).toEqual(["Seller-supplied"]);
        expect(labels(exit.checklistId)).toEqual(["Support exit doc"]);
        expect(labels(plain.checklistId)).toEqual([]);
      });
    });

    it("shows which Case the document is for as a link in the section header", () => {
      const element = createComponent();
      getChecklistItems.emit([seller]);

      return Promise.resolve().then(() => {
        const link = element.shadowRoot.querySelector(
          ".section-header lightning-formatted-url"
        );
        expect(link.label).toBe("Case 00012345 - Onboarding");
        expect(link.value).toBe("/lightning/r/Case/500000000000001AAA/view");
      });
    });

    it("keeps the source label but omits the Case link when the Case is not readable", () => {
      const element = createComponent("500000000000001AAA");
      getChecklistItems.emit([
        { ...exit, caseNumber: null, caseSubject: null }
      ]);

      return Promise.resolve().then(() => {
        const row = rowFor(element, exit.checklistId);
        expect(row.querySelector("lightning-formatted-url")).toBeNull();
        expect(row.querySelector("lightning-badge").label).toBe(
          "Support exit doc"
        );
      });
    });
  });

  describe("which documents show", () => {
    const base = mockChecklistItems[0];
    const sellerDoc = {
      ...base,
      checklistId: "a00000000000021AAA",
      docSource: "SELLER"
    };
    const opportunityDoc = { ...base, checklistId: "a00000000000022AAA" };
    const exitDoc = {
      ...base,
      checklistId: "a00000000000023AAA",
      docSource: "EXIT"
    };
    const caseId = "500000000000001AAA";

    function shownIds(element) {
      return Array.from(
        element.shadowRoot.querySelectorAll("lightning-combobox")
      ).map((el) => el.dataset.checklistId);
    }

    function toggle(element) {
      return (
        Array.from(element.shadowRoot.querySelectorAll("lightning-input")).find(
          (el) => el.type === "toggle"
        ) || null
      );
    }

    it("from an Opportunity, hides Support exit documents by default but keeps seller and Opportunity-level documents", () => {
      const element = createComponent();
      getChecklistItems.emit([sellerDoc, opportunityDoc, exitDoc]);

      return Promise.resolve().then(() => {
        expect(shownIds(element)).toEqual([
          sellerDoc.checklistId,
          opportunityDoc.checklistId
        ]);
        expect(toggle(element).label).toBe("Show Support exit documents (1)");
        expect(toggle(element).checked).toBe(false);
      });
    });

    it("from an Opportunity, the toggle reveals the Support exit documents and hides them again", () => {
      const element = createComponent();
      getChecklistItems.emit([sellerDoc, opportunityDoc, exitDoc]);

      return Promise.resolve()
        .then(() => {
          const t = toggle(element);
          t.checked = true;
          t.dispatchEvent(new CustomEvent("change"));
        })
        .then(() => {
          expect(shownIds(element)).toEqual([
            sellerDoc.checklistId,
            opportunityDoc.checklistId,
            exitDoc.checklistId
          ]);
          const t = toggle(element);
          t.checked = false;
          t.dispatchEvent(new CustomEvent("change"));
        })
        .then(() => {
          expect(shownIds(element)).toEqual([
            sellerDoc.checklistId,
            opportunityDoc.checklistId
          ]);
        });
    });

    it("from a Case, shows every document and no toggle", () => {
      const element = createComponent(caseId);
      getChecklistItems.emit([sellerDoc, opportunityDoc, exitDoc]);

      return Promise.resolve().then(() => {
        expect(shownIds(element)).toHaveLength(3);
        expect(toggle(element)).toBeNull();
      });
    });

    it("from an Opportunity with only exit documents, explains why the list is empty and still offers the toggle", () => {
      const element = createComponent();
      getChecklistItems.emit([exitDoc]);

      return Promise.resolve().then(() => {
        expect(shownIds(element)).toEqual([]);
        expect(toggle(element).label).toBe("Show Support exit documents (1)");
        expect(
          element.shadowRoot.querySelector("p.slds-text-color_weak").textContent
        ).toContain("No seller-supplied documents");
      });
    });

    it("from an Opportunity with no exit documents, shows no toggle", () => {
      const element = createComponent();
      getChecklistItems.emit([sellerDoc, opportunityDoc]);

      return Promise.resolve().then(() => {
        expect(shownIds(element)).toHaveLength(2);
        expect(toggle(element)).toBeNull();
      });
    });
  });

  describe("sections by Case", () => {
    const base = mockChecklistItems[0];
    const row = (id, status, caseNo, subject) => ({
      ...base,
      checklistId: id,
      status,
      docSource: caseNo ? "SELLER" : null,
      caseId: caseNo ? `500${caseNo}AAA` : null,
      caseNumber: caseNo ? `000${caseNo}` : null,
      caseSubject: subject || null
    });
    const oppDoc = row("a00000000000031AAA", "Draft");
    const a1 = row("a00000000000032AAA", "Draft", "000000010", "Alpha");
    const a2 = row("a00000000000033AAA", "Final", "000000010", "Alpha");
    const b1 = row("a00000000000034AAA", "Final", "000000005", "Beta");
    const b2 = row("a00000000000035AAA", "Final", "000000005", "Beta");
    const c1 = row("a00000000000036AAA", "Draft", "000000020", "Gamma");

    function shownIds(element) {
      return Array.from(
        element.shadowRoot.querySelectorAll("lightning-combobox")
      ).map((el) => el.dataset.checklistId);
    }

    it("makes one section per Case with Opportunity-level documents first and a fully finalized Case last, even if its number is lower", async () => {
      const element = createComponent();
      getChecklistItems.emit([b1, a2, b2, oppDoc, a1]);
      await flush();

      expect(sectionTitles(element)).toEqual([
        "Opportunity-level documents",
        "Case 000000000010 - Alpha",
        "Case 000000000005 - Beta"
      ]);
      const progress = Array.from(
        element.shadowRoot.querySelectorAll(
          ".section-header span.slds-text-color_weak"
        )
      ).map((el) => el.textContent.trim());
      expect(progress).toEqual([
        "0 of 1 final",
        "1 of 2 final",
        "2 of 2 final"
      ]);
      expect(shownIds(element)).toEqual([oppDoc.checklistId, a1.checklistId]);
    });

    it("keeps a fully finalized section collapsed until it is opened, then offers its Completed fold", async () => {
      const element = createComponent();
      getChecklistItems.emit([a1, b1, b2]);
      await flush();
      expect(shownIds(element)).toEqual([a1.checklistId]);

      element.shadowRoot
        .querySelector(
          'lightning-button-icon[data-section-key="500000000005AAA"]'
        )
        .click();
      await flush();
      expect(shownIds(element)).toEqual([a1.checklistId]);
      const folds = Array.from(
        element.shadowRoot.querySelectorAll(
          "lightning-button[data-section-key]"
        )
      );
      expect(folds.map((b) => b.label)).toEqual(["Completed (2)"]);

      folds[0].click();
      await flush();
      expect(shownIds(element)).toEqual([
        a1.checklistId,
        b1.checklistId,
        b2.checklistId
      ]);
    });

    it("shows a header with the Case link once, even for a single Case, and no link on the rows", async () => {
      const element = createComponent();
      getChecklistItems.emit([a1, a2]);
      await flush();

      expect(sectionTitles(element)).toEqual(["Case 000000000010 - Alpha"]);
      expect(
        element.shadowRoot.querySelectorAll("lightning-formatted-url")
      ).toHaveLength(1);
    });

    it("moves a section below the others once its last unfinished document is finalized", async () => {
      finalizeUpload.mockResolvedValue();
      const element = createComponent();
      getChecklistItems.emit([a1, c1]);
      await flush();
      expect(sectionTitles(element)).toEqual([
        "Case 000000000010 - Alpha",
        "Case 000000000020 - Gamma"
      ]);

      element.shadowRoot
        .querySelector(
          `lightning-file-upload[data-checklist-id="${a1.checklistId}"]`
        )
        .dispatchEvent(
          new CustomEvent("uploadfinished", {
            detail: {
              files: [{ documentId: "069000000000077AAA", name: "x.pdf" }]
            }
          })
        );
      await flush();

      expect(sectionTitles(element)).toEqual([
        "Case 000000000020 - Gamma",
        "Case 000000000010 - Alpha"
      ]);
      expect(shownIds(element)).toEqual([c1.checklistId]);
    });
  });

  describe("document category and type", () => {
    const picklistData = {
      picklistFieldValues: {
        Doc_Category__c: {
          controllerValues: {},
          values: [
            { label: "Scoping & Technical", value: "Scoping & Technical" },
            { label: "SOW & Contracts", value: "SOW & Contracts" }
          ]
        },
        Doc_Type__c: {
          controllerValues: { "Scoping & Technical": 0, "SOW & Contracts": 1 },
          values: [
            {
              label: "Technical Scoping Form",
              value: "Technical Scoping Form",
              validFor: [0]
            },
            {
              label: "DRMS Scoping Form",
              value: "DRMS Scoping Form",
              validFor: [0]
            },
            {
              label: "SOW Exhibit",
              value: "SOW Exhibit",
              validFor: [1]
            }
          ]
        }
      }
    };

    async function setup() {
      const element = createComponent();
      getObjectInfo.emit({ defaultRecordTypeId: "012000000000000AAA" });
      getPicklistValuesByRecordType.emit(picklistData);
      getChecklistItems.emit([mockChecklistItems[0]]);
      await flush();
      return element;
    }

    const combo = (element, label) =>
      Array.from(
        element.shadowRoot.querySelectorAll("lightning-combobox")
      ).find((c) => c.label === label);

    const choose = async (element, label, value) => {
      combo(element, label).dispatchEvent(
        new CustomEvent("change", { detail: { value } })
      );
      await flush();
    };

    it("pre-populates both fields from the record and limits types to the category", async () => {
      const element = await setup();
      expect(combo(element, "Document Category").value).toBe(
        "Scoping & Technical"
      );
      expect(combo(element, "Document Type").value).toBe(
        "Technical Scoping Form"
      );
      expect(
        combo(element, "Document Type").options.map((o) => o.value)
      ).toEqual(["Technical Scoping Form", "DRMS Scoping Form"]);
    });

    it("saves a new type for the same category", async () => {
      updateDocumentType.mockResolvedValue();
      const element = await setup();
      await choose(element, "Document Type", "DRMS Scoping Form");
      expect(updateDocumentType).toHaveBeenCalledWith({
        checklistId: mockChecklistItems[0].checklistId,
        docCategory: "Scoping & Technical",
        docType: "DRMS Scoping Form"
      });
    });

    it("clears the type and holds the upload until a type is chosen for a new category", async () => {
      updateDocumentType.mockResolvedValue();
      const element = await setup();
      await choose(element, "Document Category", "SOW & Contracts");

      expect(updateDocumentType).not.toHaveBeenCalled();
      expect(combo(element, "Document Type").value).toBeNull();
      expect(
        combo(element, "Document Type").options.map((o) => o.value)
      ).toEqual(["SOW Exhibit"]);
      expect(
        element.shadowRoot.querySelector("lightning-file-upload")
      ).toBeNull();

      await choose(element, "Document Type", "SOW Exhibit");
      expect(updateDocumentType).toHaveBeenCalledWith({
        checklistId: mockChecklistItems[0].checklistId,
        docCategory: "SOW & Contracts",
        docType: "SOW Exhibit"
      });
      expect(
        element.shadowRoot.querySelector("lightning-file-upload")
      ).not.toBeNull();
    });

    it("puts the saved category and type back when the save fails", async () => {
      updateDocumentType.mockRejectedValue({ body: { message: "nope" } });
      const element = await setup();
      await choose(element, "Document Category", "SOW & Contracts");
      await choose(element, "Document Type", "SOW Exhibit");

      expect(combo(element, "Document Category").value).toBe(
        "Scoping & Technical"
      );
      expect(combo(element, "Document Type").value).toBe(
        "Technical Scoping Form"
      );
    });
  });
});
