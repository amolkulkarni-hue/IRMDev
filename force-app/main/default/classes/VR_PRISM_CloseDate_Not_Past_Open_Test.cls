@isTest
private class VR_PRISM_CloseDate_Not_Past_Open_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenCloseDateInPast_openStage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.CloseDate = Date.today().addDays(-5);
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Close Date cannot be in the past'),
        'Expected the VR_PRISM_CloseDate_Not_Past_Open_Stages error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block a past Close Date while in Qualification.'
    );
  }

  @isTest
  static void test_allowed_whenCloseDateFuture_openStage() {
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
      'Insert should succeed with a future Close Date.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_negotiationOnInsert() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Negotiation',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.CloseDate = Date.today().addDays(-5);
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'A bare insert directly into Negotiation is not gated (only a transition into it is) - should not fire.'
    );
  }
}
