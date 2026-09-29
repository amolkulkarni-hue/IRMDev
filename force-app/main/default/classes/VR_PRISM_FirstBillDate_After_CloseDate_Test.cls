@isTest
private class VR_PRISM_FirstBillDate_After_CloseDate_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenFirstBillDateBeforeCloseDate() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.IM_Booked_Date__c = o.CloseDate.addDays(-5);
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage()
          .contains('First Bill Date must be on or after the Close Date'),
        'Expected the VR_PRISM_FirstBillDate_After_CloseDate error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block when First Bill Date is before Close Date.'
    );
  }

  @isTest
  static void test_allowed_whenFirstBillDateOnOrAfterCloseDate() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.IM_Booked_Date__c = o.CloseDate.addDays(5);
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Insert should succeed when First Bill Date is on/after Close Date.'
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
