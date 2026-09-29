@isTest
private class VR_PRISM_Marketplace_Details_Required_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenMarketplaceSelected_detailsBlank() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Marketplace__c = 'Yes';
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Marketplace Details'),
        'Expected the VR_PRISM_Marketplace_Details_Required error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block when Marketplace is selected and Details is blank.'
    );
  }

  @isTest
  static void test_allowed_whenMarketplaceSelected_detailsPopulated() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Marketplace__c = 'Yes';
    o.Marketplace_Details__c = 'Listed on AWS Marketplace';
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Insert should succeed when Marketplace Details is populated.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_marketplaceBlank() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Should not fire when Marketplace itself is blank.'
    );
  }
}
