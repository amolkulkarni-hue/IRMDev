@isTest
private class VR_PRISM_Qual_Is_Insight_Proposed_Test {
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
    return o;
  }

  @isTest
  static void test_blocked_when_Is_InSight_being_proposed__c_blank() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Insight Being Proposed'),
        'Expected the VR_PRISM_Qual_Is_Insight_Proposed error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Qual_Is_Insight_Proposed should block save when Is_InSight_being_proposed__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_Is_InSight_being_proposed__c_populated() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.Is_InSight_being_proposed__c = 'Yes - InSight Enterprise Edition is part of the proposal';
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
      'VR_PRISM_Qual_Is_Insight_Proposed should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
