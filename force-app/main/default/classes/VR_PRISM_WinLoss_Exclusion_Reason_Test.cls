@isTest
private class VR_PRISM_WinLoss_Exclusion_Reason_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenExcluded_reasonBlank() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Exclude_from_Win_Loss_Feedback__c = true;
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Reason for Win Loss Exclusion'),
        'Expected the VR_PRISM_WinLoss_Exclusion_Reason error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block when excluded from Win Loss Feedback and the reason is blank.'
    );
  }

  @isTest
  static void test_allowed_whenExcluded_reasonPopulated() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Exclude_from_Win_Loss_Feedback__c = true;
    o.Reason_for_win_loss_exclusion__c = 'Internal test opportunity';
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Insert should succeed when the reason is populated.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_notExcluded() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Exclude_from_Win_Loss_Feedback__c = false;
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Should not fire when the Opportunity is not excluded from Win Loss Feedback.'
    );
  }
}
