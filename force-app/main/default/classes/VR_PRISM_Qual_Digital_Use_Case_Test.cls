@isTest
private class VR_PRISM_Qual_Digital_Use_Case_Test {
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
  static void test_blocked_when_InSight_Opportunities_blank() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.InSight_Opportunities__c = null;
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Digital Use Case'),
        'Expected the VR_PRISM_Qual_Digital_Use_Case error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Qual_Digital_Use_Case should block save when InSight_Opportunities__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_InSight_Opportunities_populated() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.InSight_Opportunities__c = 'Invoice Processing';
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
    o.InSight_Opportunities__c = null;
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Qual_Digital_Use_Case should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
