@isTest
private class VR_PRISM_Sol_First_Bill_Date_Test {
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
  static void test_blocked_when_IM_Booked_Date_blank() {
    Opportunity o = buildInScopeOpp('Negotiation', 'New Deal');
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('First Bill Date'),
        'Expected the VR_PRISM_Sol_First_Bill_Date error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Sol_First_Bill_Date should block save when IM_Booked_Date__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_IM_Booked_Date_populated() {
    Opportunity o = buildInScopeOpp('Negotiation', 'New Deal');
    o.IM_Booked_Date__c = Date.today().addDays(45);
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
      'VR_PRISM_Sol_First_Bill_Date should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
