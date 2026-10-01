@isTest
private class VR_PRISM_Sol_Free_Storage_Period_Test {
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
  static void test_blocked_when_Free_Storage_Period_blank() {
    Opportunity o = buildInScopeOpp('Negotiation', 'New Deal');
    o.Free_Storage_Period__c = null;
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Free Storage Period'),
        'Expected the VR_PRISM_Sol_Free_Storage_Period error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Sol_Free_Storage_Period should block save when Free_Storage_Period__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_Free_Storage_Period_populated() {
    Opportunity o = buildInScopeOpp('Negotiation', 'New Deal');
    o.Free_Storage_Period__c = '1 month';
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
    o.Free_Storage_Period__c = null;
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Sol_Free_Storage_Period should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
