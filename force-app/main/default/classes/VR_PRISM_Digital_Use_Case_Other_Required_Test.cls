@isTest
private class VR_PRISM_Digital_Use_Case_Other_Required_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenOtherSelected_explanationBlank() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.InSight_Opportunities__c = 'Other';
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Digital Use Case - Other'),
        'Expected the VR_PRISM_Digital_Use_Case_Other_Required error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block when Digital Use Case = Other and the Other explanation is blank.'
    );
  }

  @isTest
  static void test_allowed_whenOtherSelected_explanationPopulated() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.InSight_Opportunities__c = 'Other';
    o.Insight_Use_Case_Other__c = 'Custom scanning workflow';
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Insert should succeed when the Other explanation is populated.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_notOther() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.InSight_Opportunities__c = 'Invoice Automation';
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Should not fire when Digital Use Case is not Other, even with the explanation blank.'
    );
  }
}
