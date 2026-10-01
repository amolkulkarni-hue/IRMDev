@IsTest
private class AceDijonOpportunityAccessVerificationTest {
  // Reproduces the "insufficient access rights on cross-reference id" error Ace Dijon
  // (ace@digitalae.irm.com.newprism, Sales & Account Management profile / Digital AE role)
  // hits creating an Opportunity against ABC Account in production: the Account is owned
  // by a user outside his role hierarchy and nothing shares it back to him. `insert as user`
  // forces full sharing/FLS enforcement under his context so the check is actually
  // exercised here, not just assumed from reading his permission set/profile grants.

  private static User getAce() {
    return [
      SELECT Id
      FROM User
      WHERE Username = 'ace@digitalae.irm.com.newprism'
      LIMIT 1
    ];
  }

  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  @IsTest
  static void testAceCanCreateOpportunityUnderAbcAccount() {
    User ace = getAce();

    // Owned by the default test-running (admin) user, outside Ace's role hierarchy and
    // not shared with him - mirrors the real ABC Account he's blocked on in production.
    Account acc = new Account(
      Name = 'ABC Account',
      BillingCountry = 'United States',
      BillingState = 'NY',
      BillingPostalCode = '11209'
    );
    insert acc;

    Opportunity opp = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.stdRecordTypeId(),
      'New Deal'
    );
    opp.Name = 'ABC Account - Ace Access Test Opp';
    opp.AccountId = acc.Id;
    opp.OwnerId = ace.Id;

    Boolean createOk = false;
    String createError = '';
    System.runAs(ace) {
      try {
        insert as user opp;
        createOk = true;
      } catch (Exception e) {
        createError = e.getMessage();
      }
    }

    System.debug(
      '###ACE_CREATE_OPP_UNDER_ABC_ACCOUNT: ok=' +
        createOk +
        ' err=' +
        createError
    );

    Assert.isTrue(
      createOk,
      'Ace Dijon (ace@digitalae.irm.com.newprism) should be able to create an ' +
        'Opportunity under ABC Account, but the insert was blocked: ' +
        createError
    );
  }
}
