@isTest
private class VR_PRISM_InSight_Not_Proposed_Expl_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenNotProposed_explanationBlank() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Primary_Product_Line__c = 'Digitization';
    o.Is_InSight_being_proposed__c = 'No - Price';
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('explanation is required'),
        'Expected the VR_PRISM_InSight_Not_Proposed_Expl error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block when Insight is not proposed and the explanation is blank.'
    );
  }

  @isTest
  static void test_allowed_whenNotProposed_explanationPopulated() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Primary_Product_Line__c = 'Digitization';
    o.Is_InSight_being_proposed__c = 'No - Price';
    o.InSight_not_in_proposal_Explanation__c = 'Customer preferred a lower-cost alternative.';
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Insert should succeed when the explanation is populated.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_proposed() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Primary_Product_Line__c = 'Digitization';
    o.Is_InSight_being_proposed__c = 'Yes - InSight Enterprise Edition is part of the proposal';
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Should not fire when Insight is being proposed, even with the explanation blank.'
    );
  }
}
