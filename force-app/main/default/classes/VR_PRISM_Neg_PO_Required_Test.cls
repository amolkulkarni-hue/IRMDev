@isTest
private class VR_PRISM_Neg_PO_Required_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  private static Opportunity buildInScopeOpp(String stage, String type) {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      stage,
      VR_PRISM_TestSupport.stdRecordTypeId(),
      type
    );
    o.Billing_Country__c = VR_PRISM_TestSupport.getUnitedStatesCountryId();
    return o;
  }

  @isTest
  static void test_blocked_when_PO_Required_blank() {
    Opportunity o = buildInScopeOpp('Booking Verification', 'New Deal');
    o.PO_Required__c = null;
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('PO Required?'),
        'Expected the VR_PRISM_Neg_PO_Required error, got: ' + e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Neg_PO_Required should block save when PO_Required__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_PO_Required_populated() {
    Opportunity o = buildInScopeOpp('Booking Verification', 'New Deal');
    o.PO_Required__c = 'No';
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Insert should succeed when the required field is populated.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_type() {
    Opportunity o = buildInScopeOpp('Booking Verification', 'Rate Change');
    o.PO_Required__c = null;
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Neg_PO_Required should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
