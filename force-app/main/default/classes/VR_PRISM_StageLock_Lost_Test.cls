@isTest
private class VR_PRISM_StageLock_Lost_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenChangingStageAwayFromLost() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Lost',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    o.StageName = 'Qualification';
    VR_PRISM_TestSupport.applyStageDefaults(o, 'Qualification');
    Boolean threw = false;
    Test.startTest();
    try {
      update o;
    } catch (DmlException e) {
      threw = true;
    }
    Test.stopTest();
    System.assert(threw, 'Should block changing Stage away from Lost.');
  }

  @isTest
  static void test_notBlocked_outOfScope_differentPriorStage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
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
      'Should not fire when the prior stage was not Lost.'
    );
  }
}
