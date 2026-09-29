@isTest
private class VR_PRISM_CloseDate_Lock_Signature_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @isTest
  static void test_blocked_whenLockedAndCloseDateChanged() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booking Verification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Deal_Close_Date_Locked__c = true;
    insert o;
    o.CloseDate = o.CloseDate.addDays(10);
    Boolean threw = false;
    Test.startTest();
    try {
      update o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Close Date is locked'),
        'Expected the VR_PRISM_CloseDate_Lock_On_Signature error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block changing Close Date once locked, in Booking Verification.'
    );
  }

  @isTest
  static void test_allowed_whenNotLocked_closeDateChanged() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booking Verification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Deal_Close_Date_Locked__c = false;
    insert o;
    o.CloseDate = o.CloseDate.addDays(10);
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT CloseDate FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      o.CloseDate,
      r.CloseDate,
      'Should allow the Close Date change when not locked.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_stage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Solutioning',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    o.Deal_Close_Date_Locked__c = true;
    insert o;
    o.CloseDate = o.CloseDate.addDays(10);
    Test.startTest();
    update o;
    Test.stopTest();
    Opportunity r = [SELECT CloseDate FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      o.CloseDate,
      r.CloseDate,
      'Should not fire outside the locked stage list (Solutioning).'
    );
  }
}
