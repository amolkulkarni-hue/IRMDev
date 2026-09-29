@isTest
private class VR_PRISM_FCST_Cat_Closed_Late_Stage_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenLateStage_forecastNotClosed() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booked',
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
        'Expected the VR_PRISM_FCST_Cat_Closed_Late_Stage error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block a non-Closed Forecast Category while Booked.'
    );
  }

  @isTest
  static void test_allowed_whenLateStage_forecastClosed() {
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
      'Insert should succeed with Forecast Category = Closed while Booked.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_openStage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Negotiation',
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
      'Should not fire outside the late-stage list (Negotiation).'
    );
  }
}
