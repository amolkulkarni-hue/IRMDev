@isTest
private class VR_PRISM_No_Skipping_Stages_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenSkippingStages_afterCutoverDate() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    Test.setCreatedDate(o.Id, DateTime.newInstance(2026, 11, 10, 0, 0, 0));
    o.StageName = 'Booking Verification'; // skips Solutioning and Negotiation
    Boolean threw = false;
    Test.startTest();
    try {
      update o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Stage skipping is not allowed'),
        'Expected the VR_PRISM_No_Skipping_Stages error, got: ' + e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block skipping stages for an Opportunity created after the cutover date.'
    );
  }

  @isTest
  static void test_allowed_singleStepProgression_afterCutoverDate() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    Test.setCreatedDate(o.Id, DateTime.newInstance(2026, 11, 10, 0, 0, 0));
    o.StageName = 'Solutioning'; // single valid step
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      'Solutioning',
      r.StageName,
      'A single-step stage progression should be allowed.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_beforeCutoverDate() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o; // CreatedDate is "today" in this test run, before the 2026-11-09 cutover
    o.StageName = 'Booking Verification'; // would skip stages, but the rule isn't active yet for this record
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      'Booking Verification',
      r.StageName,
      'Should not fire for Opportunities created before the cutover date.'
    );
  }
}
