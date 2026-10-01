@isTest
private class VR_PRISM_LowMedTouch_Regress_Reason_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenMediumTouchRegresses_reasonBlank() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Negotiation',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Touch_Level_Override__c = true;
    o.Touch_Level__c = 'Medium Touch';
    insert o;
    o.StageName = 'Solutioning';
    VR_PRISM_TestSupport.applyStageDefaults(o, 'Solutioning');
    Boolean threw = false;
    Test.startTest();
    try {
      update o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Regression Reason is required'),
        'Expected the VR_PRISM_LowMedTouch_Regress_Reason error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block a Medium Touch regression without a reason.'
    );
  }

  @isTest
  static void test_allowed_whenMediumTouchRegresses_reasonPopulated() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Negotiation',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Touch_Level_Override__c = true;
    o.Touch_Level__c = 'Medium Touch';
    insert o;
    o.StageName = 'Solutioning';
    VR_PRISM_TestSupport.applyStageDefaults(o, 'Solutioning');
    o.Stage_Regression_Reason__c = 'Budget approval delayed.';
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      'Solutioning',
      r.StageName,
      'Should allow the regression once a reason is provided.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_highTouch() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Negotiation',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Touch_Level_Override__c = true;
    o.Touch_Level__c = 'High Touch';
    insert o;
    o.StageName = 'Solutioning';
    VR_PRISM_TestSupport.applyStageDefaults(o, 'Solutioning');
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      'Solutioning',
      r.StageName,
      'Should not fire for a High Touch Opportunity (this rule only covers Low/Medium Touch).'
    );
  }
}
