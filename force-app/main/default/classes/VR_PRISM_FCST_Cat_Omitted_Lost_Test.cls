@isTest
private class VR_PRISM_FCST_Cat_Omitted_Lost_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenLost_forecastNotOmitted() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Lost',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.ForecastCategoryName = 'Pipeline';
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Forecast Category mismatch'),
        'Expected the VR_PRISM_FCST_Cat_Omitted_Lost error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block a non-Omitted Forecast Category while Lost.'
    );
  }

  @isTest
  static void test_allowed_whenLost_forecastOmitted() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Lost',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.ForecastCategoryName = 'Omitted';
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Insert should succeed with Forecast Category = Omitted while Lost.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_notLost() {
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
      'Should not fire outside the Lost stage.'
    );
  }
}
