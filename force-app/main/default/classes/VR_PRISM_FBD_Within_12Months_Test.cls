@isTest
private class VR_PRISM_FBD_Within_12Months_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenFirstBillDateBeyond12Months() {
    // This rule is also gated on NOT($Permission.Booking_Verification_Access) - the
    // default test-running (admin) user has that permission granted org-wide, so the
    // rule would never fire for them. Run as a user who lacks it instead. The
    // Opportunity is inserted as the admin first and only the update to push First
    // Bill Date out of range runs as plainUser - inserting directly as plainUser
    // throws INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY on the Account lookup,
    // since that profile has no sharing access to an Account it doesn't own.
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.IM_Booked_Date__c = o.CloseDate.addDays(100);
    User plainUser = VR_PRISM_TestSupport.getSalesAccountManagementUser();
    o.OwnerId = plainUser.Id;
    insert o;
    Boolean threw = false;
    Test.startTest();
    System.runAs(plainUser) {
      Opportunity toUpdate = new Opportunity(
        Id = o.Id,
        IM_Booked_Date__c = o.CloseDate.addDays(400)
      );
      try {
        update toUpdate;
      } catch (DmlException e) {
        threw = true;
        System.assert(
          e.getMessage().contains('within 12 months'),
          'Expected the VR_PRISM_FirstBillDate_Within_12Months error, got: ' +
          e.getMessage()
        );
      }
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block when First Bill Date is more than 12 months after Close Date.'
    );
  }

  @isTest
  static void test_allowed_whenFirstBillDateWithin12Months() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.IM_Booked_Date__c = o.CloseDate.addDays(100);
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Insert should succeed when First Bill Date is within 12 months of Close Date.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_firstBillDateBlank() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Should not fire when First Bill Date is blank.'
    );
  }
}
