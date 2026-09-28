@isTest
private class VR_PRISM_FirstBillDate_Within_12Months_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenFirstBillDateBeyond12Months() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.IM_Booked_Date__c = o.CloseDate.addDays(400);
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('within 12 months'),
        'Expected the VR_PRISM_FirstBillDate_Within_12Months error, got: ' +
        e.getMessage()
      );
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
