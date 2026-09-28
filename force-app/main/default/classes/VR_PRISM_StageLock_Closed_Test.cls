@isTest
private class VR_PRISM_StageLock_Closed_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenChangingStageAwayFromClosed() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Closed',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    o.StageName = 'Qualification';
    Boolean threw = false;
    Test.startTest();
    try {
      update o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('cannot have their Stage changed'),
        'Expected the VR_PRISM_StageLock_Closed error, got: ' + e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(threw, 'Should block changing Stage away from Closed.');
  }

  @isTest
  static void test_allowed_updatingOtherField_stageUnchanged() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Closed',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    o.Amount = 5000;
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT Amount FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      5000,
      r.Amount,
      'Should allow updating an unrelated field without changing Stage.'
    );
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
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      'Solutioning',
      r.StageName,
      'Should not fire when the prior stage was not Closed.'
    );
  }
}
