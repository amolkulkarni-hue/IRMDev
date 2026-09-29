@isTest
private class VR_PRISM_Lock_All_Fields_When_Booked_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
    VR_PRISM_TestSupport.getSalesAccountManagementUser();
  }

  private static User getSamUser() {
    return [
      SELECT Id
      FROM User
      WHERE Username = 'vr.prism.sam.testuser@irmdev.test.invalid'
      LIMIT 1
    ];
  }

  @isTest
  static void test_blocked_whenSalesAMProfile_atStage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booked',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    User samUser = getSamUser();
    Boolean threw = false;
    Test.startTest();
    System.runAs(samUser) {
      Opportunity toUpdate = new Opportunity(Id = o.Id, Amount = 5000);
      try {
        update toUpdate;
      } catch (DmlException e) {
        threw = true;
        System.assert(
          e.getMessage().contains('cannot be updated'),
          'Expected the VR_PRISM_Lock_All_Fields_When_Booked error, got: ' +
          e.getMessage()
        );
      }
    }
    Test.stopTest();
    System.assert(
      threw,
      'Should block a Sales & Account Management user from updating an Opportunity in Booked.'
    );
  }

  @isTest
  static void test_allowed_whenDefaultProfile_atStage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Booked',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    o.Amount = 5000;
    Test.startTest();
    update o; // running as the default (non-Sales AM) test user - must not throw
    Test.stopTest();
    Opportunity r = [SELECT Amount FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      5000,
      r.Amount,
      'A non-Sales-AM-profile user should be able to update at this stage.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_stage() {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      'Negotiation',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    insert o;
    User samUser = getSamUser();
    Test.startTest();
    System.runAs(samUser) {
      Opportunity toUpdate = new Opportunity(Id = o.Id, Amount = 5000);
      update toUpdate; // must not throw - Stage is not Booked
    }
    Test.stopTest();
    Opportunity r = [SELECT Amount FROM Opportunity WHERE Id = :o.Id];
    System.assertEquals(
      5000,
      r.Amount,
      'Should not fire outside the Booked stage.'
    );
  }
}
