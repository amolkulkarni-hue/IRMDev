@isTest
private class VR_PRISM_Booked_Date_Locked_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenChangingBookedDate_atLockedStage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booked',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Deal_Booked_Date__c = Date.today();
    insert o;
    o.Deal_Booked_Date__c = Date.today().addDays(1);
    Boolean threw = false;
    Test.startTest();
    try {
      update o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Booked Date is locked'),
        'Expected the VR_PRISM_Booked_Date_Locked error, got: ' + e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block changing Booked Date while in Booked stage.'
    );
  }

  @isTest
  static void test_allowed_updatingOtherField_bookedDateUnchanged() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booked',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Deal_Booked_Date__c = Date.today();
    insert o;
    o.Amount = 5000;
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT Amount FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      5000,
      r.Amount,
      'Should allow updating an unrelated field without changing Booked Date.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_earlyStage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Deal_Booked_Date__c = Date.today();
    insert o;
    o.Deal_Booked_Date__c = Date.today().addDays(1);
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [
      SELECT Deal_Booked_Date__c
      FROM Opportunity
      WHERE Id = :o.Id
    ];
    System.assertEquals(
      o.Deal_Booked_Date__c,
      r.Deal_Booked_Date__c,
      'Should not fire outside the locked stage list (Qualification).'
    );
  }
}
