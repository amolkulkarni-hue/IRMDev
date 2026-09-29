@isTest
private class VR_PRISM_Lock_All_Fields_During_BV_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenUpdatingNonStageField_duringBV() {
    // This rule is also gated on NOT($Permission.Booking_Verification_Access) - the
    // default test-running (admin) user has that permission granted org-wide, so the
    // rule would never fire for them. Run as a user who lacks it instead.
    User plainUser = VR_PRISM_TestSupport.getSalesAccountManagementUser();
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booking Verification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    o.Amount = 5000;
    Boolean threw = false;
    Test.startTest();
    System.runAs(plainUser) {
      try {
        update o;
      } catch (DmlException e) {
        threw = true;
        System.assert(
          e.getMessage().contains('cannot be updated'),
          'Expected the VR_PRISM_Lock_All_Fields_During_BV error, got: ' +
          e.getMessage()
        );
      }
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block a non-Stage field update while in Booking Verification.'
    );
  }

  @isTest
  static void test_allowed_whenChangingStage_duringBV() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booking Verification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    o.StageName = 'Booked';
    Test.startTest();
    update o; // Stage changes are explicitly allowed during BV - must not throw
    Test.stopTest();
    Opportunity r = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      'Booked',
      r.StageName,
      'Stage changes should be allowed out of Booking Verification.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_stage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    o.Amount = 5000;
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT Amount FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      5000,
      r.Amount,
      'Should not fire outside Booking Verification.'
    );
  }
}
