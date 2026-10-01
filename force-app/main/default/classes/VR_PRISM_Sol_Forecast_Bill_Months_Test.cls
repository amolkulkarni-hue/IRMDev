@isTest
private class VR_PRISM_Sol_Forecast_Bill_Months_Test {
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
    o.Amount = 50000;
    return o;
  }

  @isTest
  static void test_blocked_when_No_of_Forecast_Billing_Month_blank() {
    Opportunity o = buildInScopeOpp('Negotiation', 'New Deal');
    o.No_of_Forecast_Billing_Month__c = null;
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Forecast Billing Months'),
        'Expected the VR_PRISM_Sol_Forecast_Billing_Months error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Sol_Forecast_Billing_Months should block save when No_of_Forecast_Billing_Month__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_No_of_Forecast_Billing_Month_populated() {
    Opportunity o = buildInScopeOpp('Negotiation', 'New Deal');
    o.No_of_Forecast_Billing_Month__c = '1';
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
    o.No_of_Forecast_Billing_Month__c = null;
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Sol_Forecast_Billing_Months should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
