@isTest
private class VR_PRISM_Qual_Remarketing_Required_Test {
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
    o.ALM_BU__c = true;
    o.ALM_EAA__c = 1000;
    return o;
  }

  @isTest
  static void test_blocked_when_Remarketing_Required_blank() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Remarketing'),
        'Expected the VR_PRISM_Qual_Remarketing_Required error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Qual_Remarketing_Required should block save when Remarketing_Required__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_Remarketing_Required_populated() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.Remarketing_Required__c = 'Yes';
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
      'VR_PRISM_Qual_Remarketing_Required should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
