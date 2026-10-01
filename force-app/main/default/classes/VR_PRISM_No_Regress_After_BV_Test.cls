@isTest
private class VR_PRISM_No_Regress_After_BV_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenRegressing_afterBVPass() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booking Verification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Deal_Validation__c = 'Pass';
    insert o;
    o.StageName = 'Qualification';
    VR_PRISM_TestSupport.applyStageDefaults(o, 'Qualification');
    Boolean threw = false;
    Test.startTest();
    try {
      update o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Stage regression is not allowed'),
        'Expected the VR_PRISM_No_Regression_After_BV_Complete error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(threw, 'Should block regressing backwards once BV = Pass.');
  }

  @isTest
  static void test_allowed_whenRegressing_bvNotPass() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booking Verification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o; // Deal_Validation__c left blank (not 'Pass')
    o.StageName = 'Qualification';
    VR_PRISM_TestSupport.applyStageDefaults(o, 'Qualification');
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      'Qualification',
      r.StageName,
      'Should allow regression when BV is not yet Pass.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_priorStageNotBV() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Negotiation',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Deal_Validation__c = 'Pass';
    insert o;
    o.StageName = 'Qualification';
    VR_PRISM_TestSupport.applyStageDefaults(o, 'Qualification');
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      'Qualification',
      r.StageName,
      'Should not fire when the prior stage was not Booking Verification.'
    );
  }
}
