@isTest
private class VR_PRISM_FCST_Cat_Not_Closed_Open_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenOpenStage_forecastClosed() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.ForecastCategoryName = 'Closed';
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('cannot be'),
        'Expected the VR_PRISM_FCST_Cat_Not_Closed_Open error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block Forecast Category = Closed while in an open stage (Qualification).'
    );
  }

  @isTest
  static void test_allowed_whenOpenStage_forecastPipeline() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.ForecastCategoryName = 'Pipeline';
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Insert should succeed with a non-Closed Forecast Category in an open stage.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_lateStage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booked',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.ForecastCategoryName = 'Closed';
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Should not fire once past the open-stage list (Booked).'
    );
  }
}
