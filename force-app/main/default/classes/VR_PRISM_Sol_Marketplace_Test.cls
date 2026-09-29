@isTest
private class VR_PRISM_Sol_Marketplace_Test {
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
    o.Primary_Product_Line__c = 'Digitization';
    return o;
  }

  @isTest
  static void test_blocked_when_Marketplace_blank() {
    Opportunity o = buildInScopeOpp('Negotiation', 'New Deal');
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Marketplace'),
        'Expected the VR_PRISM_Sol_Marketplace error, got: ' + e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Sol_Marketplace should block save when Marketplace__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_Marketplace_populated() {
    Opportunity o = buildInScopeOpp('Negotiation', 'New Deal');
    o.Marketplace__c = 'Yes';
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
    Opportunity o = buildInScopeOpp('Negotiation', 'Rate Change');
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Sol_Marketplace should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
