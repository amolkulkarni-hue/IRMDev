@isTest
private class VR_PRISM_BV_Required_Before_Booked_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_advancingToBooked_bvNotPass() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booking Verification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o; // Deal_Validation__c left blank
    o.StageName = 'Booked';
    VR_PRISM_TestSupport.applyStageDefaults(o, 'Booked');
    Boolean threw = false;
    Test.startTest();
    try {
      update o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Booking Verification is required'),
        'Expected the VR_PRISM_BV_Required_Before_Booked error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(threw, 'Should block advancing to Booked before BV = Pass.');
  }

  @isTest
  static void test_allowed_advancingToBooked_bvPass() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booking Verification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Deal_Validation__c = 'Pass';
    insert o;
    o.StageName = 'Booked';
    VR_PRISM_TestSupport.applyStageDefaults(o, 'Booked');
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      'Booked',
      r.StageName,
      'Should allow advancing to Booked once BV = Pass.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_priorStageNotBV() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Negotiation',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    o.StageName = 'Booked';
    VR_PRISM_TestSupport.applyStageDefaults(o, 'Booked');
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      'Booked',
      r.StageName,
      'Should not fire when the prior stage was not Booking Verification.'
    );
  }
}
