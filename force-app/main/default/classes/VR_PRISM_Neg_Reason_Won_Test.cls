@isTest
private class VR_PRISM_Neg_Reason_Won_Test {
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
    return o;
  }

  @isTest
  static void test_blocked_when_IME_Reason_Won_blank() {
    Opportunity o = buildInScopeOpp('Booking Verification', 'New Deal');
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Reason Won'),
        'Expected the VR_PRISM_Neg_Reason_Won error, got: ' + e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Neg_Reason_Won should block save when IME_Reason_Won__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_IME_Reason_Won_populated() {
    Opportunity o = buildInScopeOpp('Booking Verification', 'New Deal');
    o.IME_Reason_Won__c = 'Price';
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
    Opportunity o = buildInScopeOpp('Booking Verification', 'Price Change');
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Neg_Reason_Won should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
