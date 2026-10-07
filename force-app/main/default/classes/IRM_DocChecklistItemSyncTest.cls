/**
 * IRM_DocChecklistItemSyncTest
 * Tests the BV item sync in Doc_Checklist_Completion_Sync_Flow: a Document Checklist row linked
 * to a Booking_Verification_Checklist_Item__c drives that item's System_Validated__c.
 *
 *   AC1 — a Final, non-bypassed row validates its item; moving it back to Draft clears it
 *   AC2 — a bypassed Final row does not validate its item
 *   AC3 — a row created through Ironclad validates its item as soon as it exists
 */
@IsTest
private class IRM_DocChecklistItemSyncTest {
  // AccountHelper rejects Account inserts from profiles outside IM_Admin_Profiles, so the tests
  // run as IM_Custom Sys Admin, the same approach BookingVerifChecklistGeneratorTest uses.
  private static User testRunnerUser() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin'];
    User u = new User(
      Alias = 'dcsync',
      Email = 'dcsync@malkosus.com',
      EmailEncodingKey = 'UTF-8',
      FirstName = 'DCSync',
      LastName = 'TestRunner',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      Username = 'dcsync.' + Math.abs(Crypto.getRandomLong()) + '@malkosus.com',
      IsActive = true,
      Country = 'United Kingdom'
    );
    insert u;
    return u;
  }

  private static Booking_Verification_Checklist_Item__c makeItem() {
    AccountTriggerHandler.skipTriggerExecutionTestClass = true;
    OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

    Account acc = new Account(Name = 'DCSync Test Acc');
    insert acc;
    Opportunity opp = new Opportunity(
      Name = 'DCSync Test Opp',
      AccountId = acc.Id,
      StageName = '1 - Qualification',
      CloseDate = Date.today().addDays(30),
      Type = 'New Deal',
      CurrencyIsoCode = 'USD'
    );
    insert opp;

    Booking_Verification_Checklist__c chk = new Booking_Verification_Checklist__c(
      Opportunity__c = opp.Id,
      OwnerId = UserInfo.getUserId()
    );
    insert chk;

    Booking_Verification_Checklist_Item__c item = new Booking_Verification_Checklist_Item__c(
      Booking_Verification_Checklist__c = chk.Id,
      Opportunity__c = opp.Id,
      Checklist_Item_Name__c = 'Signed contract',
      Is_Mandatory__c = true
    );
    insert item;
    return item;
  }

  private static Document_Checklist__c makeDoc(
    Booking_Verification_Checklist_Item__c item,
    Id ironcladContractId
  ) {
    Document_Checklist__c doc = new Document_Checklist__c(
      Opportunity__c = item.Opportunity__c,
      Booking_Verification_Checklist__c = item.Booking_Verification_Checklist__c,
      Booking_Verification_Checklist_Item__c = item.Id,
      Ironclad_Contract__c = ironcladContractId,
      Doc_Category__c = 'Scoping & Technical',
      Doc_Type__c = 'Technical Scoping Form',
      Status__c = 'Draft'
    );
    insert doc;
    return doc;
  }

  private static Boolean systemValidated(Id itemId) {
    return [
      SELECT System_Validated__c
      FROM Booking_Verification_Checklist_Item__c
      WHERE Id = :itemId
    ]
    .System_Validated__c;
  }

  // ── AC1 ────────────────────────────────────────────────────────────────────

  @IsTest
  static void test_finalNotBypassedValidatesItemAndDraftClearsIt() {
    System.runAs(testRunnerUser()) {
      Booking_Verification_Checklist_Item__c item = makeItem();
      Document_Checklist__c doc = makeDoc(item, null);
      Assert.isFalse(
        systemValidated(item.Id),
        'AC1: A Draft row should not validate the item'
      );

      Test.startTest();
      doc.Status__c = 'Final';
      doc.Submitted_Date__c = Date.today();
      update doc;
      Test.stopTest();

      Assert.isTrue(
        systemValidated(item.Id),
        'AC1: A Final, non-bypassed row should validate the item'
      );

      doc.Status__c = 'Draft';
      update doc;
      Assert.isFalse(
        systemValidated(item.Id),
        'AC1: Moving the row back to Draft should clear System Validated'
      );
    }
  }

  // ── AC2 ────────────────────────────────────────────────────────────────────

  @IsTest
  static void test_bypassedFinalRowDoesNotValidateItem() {
    System.runAs(testRunnerUser()) {
      Booking_Verification_Checklist_Item__c item = makeItem();
      Document_Checklist__c doc = makeDoc(item, null);

      Test.startTest();
      doc.Bypass_Requirement__c = true;
      doc.Bypass_Justification__c = 'Not applicable for this deal';
      doc.Status__c = 'Final';
      update doc;
      Test.stopTest();

      Assert.isFalse(
        systemValidated(item.Id),
        'AC2: A bypassed Final row is not a document and must not validate the item'
      );
    }
  }

  // ── AC3 ────────────────────────────────────────────────────────────────────

  @IsTest
  static void test_ironcladRowValidatesItemOnCreate() {
    System.runAs(testRunnerUser()) {
      Booking_Verification_Checklist_Item__c item = makeItem();
      // No Opportunity on the contract, so the Ironclad trigger creates no checklist row itself.
      ironclad__Ironclad_Contract__c contract = new ironclad__Ironclad_Contract__c();
      insert contract;

      Test.startTest();
      makeDoc(item, contract.Id);
      Test.stopTest();

      Assert.isTrue(
        systemValidated(item.Id),
        'AC3: A row created through Ironclad should validate the item immediately'
      );
    }
  }
}
