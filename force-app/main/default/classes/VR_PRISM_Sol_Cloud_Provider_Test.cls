@isTest
private class VR_PRISM_Sol_Cloud_Provider_Test {
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
    o.Is_InSight_being_proposed__c = 'Yes - InSight Enterprise Edition is part of the proposal';
    return o;
  }

  @isTest
  static void test_blocked_when_Cloud_Provider_blank() {
    Opportunity o = buildInScopeOpp('Negotiation', 'New Deal');
    o.Cloud_Provider__c = null;
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Cloud Provider'),
        'Expected the VR_PRISM_Sol_Cloud_Provider error, got: ' + e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Sol_Cloud_Provider should block save when Cloud_Provider__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_Cloud_Provider_populated() {
    Opportunity o = buildInScopeOpp('Negotiation', 'New Deal');
    o.Cloud_Provider__c = 'AWS';
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
    o.Cloud_Provider__c = null;
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Sol_Cloud_Provider should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
