@isTest
private class VR_PRISM_Qual_Unit_Of_Measure_Test {
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
  static void test_blocked_when_IM_Unit_of_Measure_blank() {
    Opportunity o = buildInScopeOpp('Solutioning', 'Cross-Sell/Upsell');
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Unit of Measure'),
        'Expected the VR_PRISM_Qual_Unit_Of_Measure error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Qual_Unit_Of_Measure should block save when IM_Unit_of_Measure__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_IM_Unit_of_Measure_populated() {
    Opportunity o = buildInScopeOpp('Solutioning', 'Cross-Sell/Upsell');
    o.IM_Unit_of_Measure__c = 'Cubic Ft';
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
    Opportunity o = buildInScopeOpp('Solutioning', 'Price Change');
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Qual_Unit_Of_Measure should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
