@isTest
private class VR_PRISM_ReasonLost_Comments_Reqd_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_movingToLost_reasonAndCommentsBlank() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    o.StageName = 'Lost';
    Boolean threw = false;
    Test.startTest();
    try {
      update o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Reason Lost and Lost Comments'),
        'Expected the VR_PRISM_ReasonLost_Comments_Required error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block moving to Lost without Reason Lost and Lost Comments.'
    );
  }

  @isTest
  static void test_allowed_movingToLost_reasonAndCommentsPopulated() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    o.StageName = 'Lost';
    o.IM_Reason_Lost__c = 'Competitor';
    o.IM_Lost_Comments__c = 'Lost to a lower-priced competitor.';
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT StageName FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      'Lost',
      r.StageName,
      'Update should succeed when Reason Lost and Lost Comments are populated.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_notMovingToLost() {
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
      'Should not fire when not moving into Lost.'
    );
  }
}
