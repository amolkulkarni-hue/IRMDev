@isTest
private class VR_PRISM_Qual_Business_Problem_Test {
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
  static void test_blocked_when_Business_Problem_Evidenced_blank() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.Business_Problem_Evidenced__c = null;
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Business Problem'),
        'Expected the VR_PRISM_Qual_Business_Problem error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Qual_Business_Problem should block save when Business_Problem_Evidenced__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_Business_Problem_Evidenced_populated() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.Business_Problem_Evidenced__c = 'Improve Efficiency or Reduce Manual Work';
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
    o.Business_Problem_Evidenced__c = null;
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Qual_Business_Problem should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
