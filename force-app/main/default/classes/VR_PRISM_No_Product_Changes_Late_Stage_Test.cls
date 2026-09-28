@isTest
private class VR_PRISM_No_Product_Changes_Late_Stage_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
    Product2 prod = new Product2(
      Name = 'VR PRISM Test Product',
      IsActive = true
    );
    insert prod;
    insert new PricebookEntry(
      Product2Id = prod.Id,
      Pricebook2Id = Test.getStandardPricebookId(),
      UnitPrice = 100,
      IsActive = true
    );
  }

  private static Id getPricebookEntryId() {
    return [
      SELECT Id
      FROM PricebookEntry
      WHERE Pricebook2Id = :Test.getStandardPricebookId()
      LIMIT 1
    ]
    .Id;
  }

  @isTest
  static void test_blocked_addingProduct_atLateStage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booking Verification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    OpportunityLineItem oli = new OpportunityLineItem(
      OpportunityId = o.Id,
      PricebookEntryId = getPricebookEntryId(),
      Quantity = 1,
      UnitPrice = 100
    );
    Boolean threw = false;
    Test.startTest();
    try {
      insert oli;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Opportunity Products cannot be updated'),
        'Expected the VR_PRISM_No_Product_Changes_Late_Stage error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block adding a Product while the Opportunity is in Booking Verification.'
    );
  }

  @isTest
  static void test_allowed_addingProduct_earlyStage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    OpportunityLineItem oli = new OpportunityLineItem(
      OpportunityId = o.Id,
      PricebookEntryId = getPricebookEntryId(),
      Quantity = 1,
      UnitPrice = 100
    );
    Test.startTest();
    insert oli;
    Test.stopTest();
    System.assertNotEquals(
      null,
      oli.Id,
      'Should allow adding a Product while the Opportunity is in Qualification.'
    );
  }
}
