@isTest
private class VR_PRISM_Lock_All_Fields_When_Lost_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  // Note: unlike the BV/Booked/Setup variants, this rule has no Stage-change carve-out
  // and no profile gate - any update at all while Lost is blocked (absent the
  // Sales_Operations_Bypass custom permission, which cannot be granted in an Apex test).
  // There is therefore no "allowed update while Lost" scenario to test here; the second
  // scenario below covers the out-of-scope (not Lost) case instead.
  @isTest
  static void test_blocked_whenUpdatingAnyField_atLost() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Lost',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    o.Amount = 5000;
    Boolean threw = false;
    Test.startTest();
    try {
      update o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('cannot be updated'),
        'Expected the VR_PRISM_Lock_All_Fields_When_Lost error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(threw, 'Should block any field update while in Lost stage.');
  }

  @isTest
  static void test_notBlocked_outOfScope_stage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
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
      'Should not fire outside the Lost stage.'
    );
  }
}
