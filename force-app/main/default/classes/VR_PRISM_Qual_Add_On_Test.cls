@isTest
private class VR_PRISM_Qual_Add_On_Test {
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
  static void test_blocked_when_Add_On_blank() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.Add_On__c = null;
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Add-On'),
        'Expected the VR_PRISM_Qual_Add_On error, got: ' + e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Qual_Add_On should block save when Add_On__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_Add_On_populated() {
    Opportunity o = buildInScopeOpp('Solutioning', 'New Deal');
    o.Add_On__c = 'Workflow';
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
    o.Add_On__c = null;
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Qual_Add_On should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
