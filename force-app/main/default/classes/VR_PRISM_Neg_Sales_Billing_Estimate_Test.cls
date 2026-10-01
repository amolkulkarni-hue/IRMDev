@isTest
private class VR_PRISM_Neg_Sales_Billing_Estimate_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenBillingEstimateBlank_atBV_amountAboveThreshold() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booking Verification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Amount = 50000; // above the $25K USD threshold
    Boolean threw = false;
    Test.startTest();
    try {
      insert o; // no Sales_Revenue_Forecast__c child - rollup stays blank
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Sales Billing Estimates must be updated'),
        'Expected the VR_PRISM_Neg_Sales_Billing_Estimate error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block save when Total Sales Billing Estimate is blank in Booking Verification above the amount threshold.'
    );
  }

  @isTest
  static void test_allowed_whenBillingEstimatePopulated_atBV_amountAboveThreshold() {
    // Total_Sales_Billing_Estimate__c is a roll-up (from Sales_Revenue_Forecast__c) and
    // cannot be set directly, so insert at an ungated stage first, populate the rollup
    // via a child record, then move into Booking Verification.
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Amount = 50000;
    insert o;
    VR_PRISM_TestSupport.addSalesRevenueForecast(o.Id, 30000);
    o.StageName = 'Booking Verification';
    VR_PRISM_TestSupport.applyStageDefaults(o, 'Booking Verification');
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      'Booking Verification',
      r.StageName,
      'Should allow the move to Booking Verification once the rolled-up estimate is populated.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_belowAmountThreshold() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booking Verification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Amount = 1000; // below the $25K USD threshold
    Test.startTest();
    insert o; // no forecast child, but the amount threshold isn't met
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Should not fire when Amount is below the $25K USD threshold.'
    );
  }
}
