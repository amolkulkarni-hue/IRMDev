/**
 * IRM_DocumentChecklistUploadControllerTest
 * Tests for IRM_DocumentChecklistUploadController — the Apex controller behind
 * the nfDocumentChecklistUpload LWC quick action.
 *
 * Test coverage:
 *   AC1 — getChecklistItems returns rows related to an Opportunity
 *   AC2 — getChecklistItems returns rows related to a Case
 *   AC3 — getChecklistItems surfaces the existing attached file, when present
 *   AC4 — finalizeUpload (Opportunity-only row) links the file to the Opportunity and sets Status/Submitted Date
 *   AC5 — finalizeUpload (Case + Opportunity row) cross-links the file to both
 *   AC6 — finalizeUpload replaces a previous file: stale links removed, new link added
 */
@IsTest
private class IRM_DocumentChecklistUploadControllerTest {
  @TestSetup
  static void setup() {
    IM_Country__c testCountry = new IM_Country__c(Name = 'United States');
    insert testCountry;
    insert new IM_Alternative_Country_Name__c(
      IM_Country__c = testCountry.Id,
      Alternative_Name__c = 'United States'
    );
    insert new Country_Settings__c(
      Name = 'United States',
      Object_Name__c = 'Opportunity',
      SetupOwnerId = UserInfo.getOrganizationId()
    );
    insert new List<Opportunity_Security__c>{
      new Opportunity_Security__c(
        Name = 'Primary CDE',
        Field_Name__c = 'Primary_CDE__c',
        Object_Name__c = 'Account',
        Visibility_Access_Level__c = 'R',
        SetupOwnerId = UserInfo.getOrganizationId()
      ),
      new Opportunity_Security__c(
        Name = 'Original Lead Owner',
        Field_Name__c = 'IM_Original_Lead_Owner__c',
        Object_Name__c = 'Opportunity',
        Visibility_Access_Level__c = 'W',
        SetupOwnerId = UserInfo.getOrganizationId()
      ),
      new Opportunity_Security__c(
        Name = 'Primary BDE',
        Field_Name__c = 'Primary_BDE__c',
        Object_Name__c = 'Account',
        Visibility_Access_Level__c = 'W',
        SetupOwnerId = UserInfo.getOrganizationId()
      )
    };
    insert new OpportunityProductSelection__c(
      Name = 'CloudSolutionsProduct',
      Product_Class_Name__c = 'Cloud',
      Product_Line_Name__c = 'Cloud Solutions'
    );
    insert new List<SVStatus__c>{
      new SVStatus__c(
        Name = 'New Deal',
        Amount__c = 0,
        Stage__c = 'Qualification',
        SetupOwnerId = UserInfo.getOrganizationId()
      ),
      new SVStatus__c(
        Name = 'Renewal',
        Amount__c = 0,
        Stage__c = 'Qualification',
        SetupOwnerId = UserInfo.getOrganizationId()
      ),
      new SVStatus__c(
        Name = 'Add-On',
        Amount__c = 0,
        Stage__c = 'Qualification',
        SetupOwnerId = UserInfo.getOrganizationId()
      ),
      new SVStatus__c(
        Name = 'Expansion',
        Amount__c = 0,
        Stage__c = 'Qualification',
        SetupOwnerId = UserInfo.getOrganizationId()
      )
    };
    Account acc = new Account(
      Name = 'IRM DocChecklistUpload Test Co',
      BillingCountry = 'United States',
      BillingState = 'NY',
      BillingPostalCode = '11209'
    );
    insert acc;
    insert new Contact(
      LastName = 'DocChecklistUploadContact',
      AccountId = acc.Id
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  private static Account getAccount() {
    return [SELECT Id FROM Account LIMIT 1];
  }

  private static Id getContactId() {
    return [SELECT Id FROM Contact LIMIT 1].Id;
  }

  private static Opportunity makeOpp() {
    Opportunity opp = new Opportunity(
      Name = 'DocChecklistUpload Test Opp',
      AccountId = getAccount().Id,
      Type = 'New Deal',
      StageName = 'Qualification',
      CloseDate = Date.today().addDays(30),
      Pricebook2Id = Test.getStandardPricebookId(),
      Amount = 500000,
      Bypass_Validation__c = true
    );
    insert opp;
    return opp;
  }

  private static Case makeCase(Id accId, Id contactId, Id oppId) {
    Case c = new Case(
      AccountId = accId,
      ContactId = contactId,
      Subject = 'DocChecklistUpload Test Case',
      Status = 'In Progress',
      Opportunity__c = oppId
    );
    insert c;
    return c;
  }

  private static Document_Checklist__c makeDocChecklist(Id caseId, Id oppId) {
    Document_Checklist__c doc = new Document_Checklist__c(
      Case__c = caseId,
      Opportunity__c = oppId,
      Doc_Type__c = 'Technical Scoping Form',
      Doc_Category__c = 'Scoping & Technical',
      Status__c = 'Draft'
    );
    insert doc;
    return doc;
  }

  private static Id createContentDoc(String title) {
    ContentVersion cv = new ContentVersion(
      Title = title,
      PathOnClient = title + '.txt',
      VersionData = Blob.valueOf('Test content — ' + title),
      IsMajorVersion = true
    );
    insert cv;
    return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id]
    .ContentDocumentId;
  }

  private static void linkFile(Id contentDocId, Id entityId) {
    insert new ContentDocumentLink(
      ContentDocumentId = contentDocId,
      LinkedEntityId = entityId,
      ShareType = 'V',
      Visibility = 'AllUsers'
    );
  }

  private static Integer countLinks(Id contentDocId, Id entityId) {
    return [
      SELECT COUNT()
      FROM ContentDocumentLink
      WHERE ContentDocumentId = :contentDocId AND LinkedEntityId = :entityId
    ];
  }

  // ── AC1: getChecklistItems returns rows related to an Opportunity ──────────

  @IsTest
  static void test_getChecklistItemsReturnsRowsForOpportunity() {
    Opportunity opp = makeOpp();
    Document_Checklist__c doc = makeDocChecklist(null, opp.Id);

    Test.startTest();
    List<IRM_DocumentChecklistUploadController.ChecklistItem> items = IRM_DocumentChecklistUploadController.getChecklistItems(
      opp.Id
    );
    Test.stopTest();

    Assert.areEqual(
      1,
      items.size(),
      'AC1: Expected one checklist item for the Opportunity'
    );
    Assert.areEqual(
      doc.Id,
      items[0].checklistId,
      'AC1: Checklist Id should match'
    );
    Assert.areEqual(
      'Scoping & Technical',
      items[0].docCategory,
      'AC1: Doc_Category__c should be returned'
    );
    Assert.isNull(
      items[0].existingContentDocumentId,
      'AC1: No file has been uploaded yet'
    );
  }

  // ── AC2: getChecklistItems returns rows related to a Case ──────────────────

  @IsTest
  static void test_getChecklistItemsReturnsRowsForCase() {
    Opportunity opp = makeOpp();
    Case c = makeCase(getAccount().Id, getContactId(), opp.Id);
    Document_Checklist__c doc = makeDocChecklist(c.Id, opp.Id);

    Test.startTest();
    List<IRM_DocumentChecklistUploadController.ChecklistItem> items = IRM_DocumentChecklistUploadController.getChecklistItems(
      c.Id
    );
    Test.stopTest();

    Assert.areEqual(
      1,
      items.size(),
      'AC2: Expected one checklist item for the Case'
    );
    Assert.areEqual(
      doc.Id,
      items[0].checklistId,
      'AC2: Checklist Id should match'
    );
  }

  // ── AC3: getChecklistItems surfaces an existing attached file ──────────────

  @IsTest
  static void test_getChecklistItemsIncludesExistingFile() {
    Opportunity opp = makeOpp();
    Document_Checklist__c doc = makeDocChecklist(null, opp.Id);
    Id docFileId = createContentDoc('AC3_ExistingFile');
    linkFile(docFileId, doc.Id);

    Test.startTest();
    List<IRM_DocumentChecklistUploadController.ChecklistItem> items = IRM_DocumentChecklistUploadController.getChecklistItems(
      opp.Id
    );
    Test.stopTest();

    Assert.areEqual(1, items.size(), 'AC3: Expected one checklist item');
    Assert.areEqual(
      docFileId,
      items[0].existingContentDocumentId,
      'AC3: Existing file Id should be surfaced'
    );
    Assert.areEqual(
      'AC3_ExistingFile',
      items[0].existingFileName,
      'AC3: Existing file name should be surfaced'
    );
  }

  // ── AC4: finalizeUpload on an Opportunity-only row ──────────────────────────

  @IsTest
  static void test_finalizeUploadOpportunityOnlyLinksFileAndSetsStatus() {
    Opportunity opp = makeOpp();
    Document_Checklist__c doc = makeDocChecklist(null, opp.Id);
    Id newFileId = createContentDoc('AC4_NewFile');
    linkFile(newFileId, doc.Id);

    Test.startTest();
    IRM_DocumentChecklistUploadController.finalizeUpload(
      doc.Id,
      newFileId,
      null
    );
    Test.stopTest();

    Assert.areEqual(
      1,
      countLinks(newFileId, opp.Id),
      'AC4: File should be linked to the Opportunity'
    );

    Document_Checklist__c updated = [
      SELECT Status__c, Submitted_Date__c
      FROM Document_Checklist__c
      WHERE Id = :doc.Id
    ];
    Assert.areEqual('Final', updated.Status__c, 'AC4: Status should be Final');
    Assert.areEqual(
      Date.today(),
      updated.Submitted_Date__c,
      'AC4: Submitted Date should be today'
    );
  }

  // ── AC5: finalizeUpload on a Case + Opportunity row cross-links both ────────

  @IsTest
  static void test_finalizeUploadFromCaseCrossLinksToOpportunity() {
    Opportunity opp = makeOpp();
    Case c = makeCase(getAccount().Id, getContactId(), opp.Id);
    Document_Checklist__c doc = makeDocChecklist(c.Id, opp.Id);
    Id newFileId = createContentDoc('AC5_NewFile');
    linkFile(newFileId, doc.Id);

    Test.startTest();
    IRM_DocumentChecklistUploadController.finalizeUpload(
      doc.Id,
      newFileId,
      null
    );
    Test.stopTest();

    Assert.areEqual(
      1,
      countLinks(newFileId, c.Id),
      'AC5: File should be linked to the Case'
    );
    Assert.areEqual(
      1,
      countLinks(newFileId, opp.Id),
      'AC5: File should be cross-linked to the Opportunity'
    );
  }

  // ── AC6: finalizeUpload replaces a previous file ────────────────────────────

  @IsTest
  static void test_finalizeUploadReplacesPreviousFile() {
    Opportunity opp = makeOpp();
    Document_Checklist__c doc = makeDocChecklist(null, opp.Id);

    Id oldFileId = createContentDoc('AC6_OldFile');
    linkFile(oldFileId, doc.Id);
    linkFile(oldFileId, opp.Id);

    Id newFileId = createContentDoc('AC6_NewFile');
    linkFile(newFileId, doc.Id);

    Test.startTest();
    IRM_DocumentChecklistUploadController.finalizeUpload(
      doc.Id,
      newFileId,
      oldFileId
    );
    Test.stopTest();

    Assert.areEqual(
      0,
      countLinks(oldFileId, doc.Id),
      'AC6: Old file should be unlinked from the checklist'
    );
    Assert.areEqual(
      0,
      countLinks(oldFileId, opp.Id),
      'AC6: Old file should be unlinked from the Opportunity'
    );
    Assert.areEqual(
      1,
      countLinks(newFileId, opp.Id),
      'AC6: New file should be linked to the Opportunity'
    );
  }
}
