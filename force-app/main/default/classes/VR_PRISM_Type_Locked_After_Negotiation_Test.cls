@isTest
private class VR_PRISM_Type_Locked_After_Negotiation_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenChangingType_atOrPastNegotiation() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Negotiation',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    o.Type = 'Renewal';
    Boolean threw = false;
    Test.startTest();
    try {
      update o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Type is locked'),
        'Expected the VR_PRISM_Type_Locked_After_Negotiation error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(threw, 'Should block changing Type once in Negotiation.');
  }

  @isTest
  static void test_allowed_updatingOtherField_typeUnchanged() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Negotiation',
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
      'Should allow updating an unrelated field without changing Type.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_earlyStage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    o.Type = 'Renewal';
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT Type FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      'Renewal',
      r.Type,
      'Should not fire before Negotiation (Qualification).'
    );
  }
}
