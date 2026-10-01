@isTest
private class VR_PRISM_Sol_Fuel_Surcharge_Waiver_Test {
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
    o.RIM_BU__c = true;
    o.Billing_Country__c = VR_PRISM_TestSupport.getUnitedStatesCountryId();
    return o;
  }

  @isTest
  static void test_blocked_when_Fuel_Surcharge_Waiver_blank() {
    Opportunity o = buildInScopeOpp('Negotiation', 'New Deal');
    o.Fuel_Surcharge_Waiver__c = null;
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Fuel Surcharge Waiver'),
        'Expected the VR_PRISM_Sol_Fuel_Surcharge_Waiver error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Sol_Fuel_Surcharge_Waiver should block save when Fuel_Surcharge_Waiver__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_Fuel_Surcharge_Waiver_populated() {
    Opportunity o = buildInScopeOpp('Negotiation', 'New Deal');
    o.Fuel_Surcharge_Waiver__c = 'Yes';
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
    o.Fuel_Surcharge_Waiver__c = null;
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Sol_Fuel_Surcharge_Waiver should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
