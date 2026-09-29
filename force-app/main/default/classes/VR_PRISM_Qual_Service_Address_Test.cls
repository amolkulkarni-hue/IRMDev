@isTest
private class VR_PRISM_Qual_Service_Address_Test {
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
  static void test_blocked_when_Service_Address_Street_s_blank() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Service Address'),
        'Expected the VR_PRISM_Qual_Service_Address error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Qual_Service_Address should block save when Service_Address__Street__s is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_Service_Address_Street_s_populated() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.Service_Address__Street__s = '123 Main St';
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
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Qual_Service_Address should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
