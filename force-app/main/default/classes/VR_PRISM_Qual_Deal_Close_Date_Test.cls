@isTest
private class VR_PRISM_Qual_Deal_Close_Date_Test {
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
  static void test_blocked_when_CloseDate_blank() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.CloseDate = null;
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Close Date'),
        'Expected the VR_PRISM_Qual_Deal_Close_Date error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Qual_Deal_Close_Date should block save when CloseDate is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_CloseDate_populated() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.CloseDate = Date.today().addDays(30);
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
    o.CloseDate = null;
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Qual_Deal_Close_Date should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
