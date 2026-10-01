@isTest
private class VR_PRISM_Qual_Estimated_CuFt_Test {
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
    o.Primary_Product_Line__c = 'Records Management';
    return o;
  }

  @isTest
  static void test_blocked_when_Expected_CuFt_blank() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.Expected_CuFt__c = null;
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Estimated CuFt'),
        'Expected the VR_PRISM_Qual_Estimated_CuFt error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Qual_Estimated_CuFt should block save when Expected_CuFt__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_Expected_CuFt_populated() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.Expected_CuFt__c = 100;
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
    Opportunity o = buildInScopeOpp('Solutioning', 'Rate Change');
    o.Expected_CuFt__c = null;
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Qual_Estimated_CuFt should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
