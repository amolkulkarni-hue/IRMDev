@isTest
private class VR_PRISM_No_Skipping_Stages_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  // This rule is date-gated (DATEVALUE(CreatedDate) > DATE(2026, 11, 9)) and today's
  // real date is still before that cutover, so every Opportunity created by this test
  // run is - correctly - out of the rule's scope. Test.setCreatedDate() can move
  // CreatedDate into the FUTURE, but any subsequent DML then stamps LastModifiedDate to
  // the real current time, which fails Salesforce's own LastModifiedDate >= CreatedDate
  // integrity check (FIELD_INTEGRITY_EXCEPTION) - there is no equivalent test hook to
  // back-date LastModifiedDate, so the "blocked" (post-cutover) branch genuinely cannot
  // be exercised via an integration test until the real calendar date passes 2026-11-09.
  // This single test instead confirms today's actual, correct behavior.
  @isTest
  static void test_notBlocked_beforeCutoverDate_stagesSkippable() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o; // CreatedDate is "today" - before the 2026-11-09 cutover
    o.StageName = 'Booking Verification'; // would be a skip (Solutioning, Negotiation), if the rule applied
    Test.startTest();
    update o; // must not throw
    Test.stopTest();
    Opportunity r = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      'Booking Verification',
      r.StageName,
      'Should not fire for Opportunities created before the cutover date.'
    );
  }
}
