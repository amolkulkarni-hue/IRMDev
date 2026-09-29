@isTest
private class VR_PRISM_FBD_Not_Past_Open_Stages_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenFirstBillDateInPast_openStage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.IM_Booked_Date__c = Date.today().addDays(-5);
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('First Bill Date cannot be in the past'),
        'Expected the VR_PRISM_FBD_Not_Past_Open_Stages error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block a past First Bill Date while in Qualification.'
    );
  }

  @isTest
  static void test_allowed_whenFirstBillDateFuture_openStage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.IM_Booked_Date__c = o.CloseDate.addDays(10);
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Insert should succeed with a future First Bill Date.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_bookedStage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booked',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.IM_Booked_Date__c = Date.today().addDays(-5);
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Should not fire once past the open stages (Booked).'
    );
  }
}
