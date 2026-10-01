@isTest
private class VR_PRISM_QualSol_Next_Step_Test {
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
    o.Touch_Level_Override__c = true;
    o.Touch_Level__c = 'High Touch';
    return o;
  }

  @isTest
  static void test_blocked_when_NextStep_blank() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.NextStep = null;
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Next Step'),
        'Expected the VR_PRISM_QualSol_Next_Step error, got: ' + e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_QualSol_Next_Step should block save when NextStep is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_NextStep_populated() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.NextStep = 'Follow up call';
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
    o.NextStep = null;
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_QualSol_Next_Step should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
