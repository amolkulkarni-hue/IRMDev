@IsTest
private class AceDijonOppAccessVerificationTest {
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

  // Debug log 07LWJ00000W45Bi2AJ shows Opportunity_Creation_from_Account_Flow's
  // Create_Opportunity element failing with INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY
  // when Ace creates an Opportunity from ABC Account with RecordTypeId =
  // Framework_Parent_Opportunity (012WJ000002GcueYAC) - the flow's fRecordTypeId formula
  // resolves to that record type whenever the user doesn't pick "Standard"/"Choice Standard
  // Opp". The test above proves AccountId and Standard_Opportunity aren't the blocker;
  // this isolates RecordTypeId by swapping only that field in, confirming whether Ace's
  // profile (Sales & Account Management) simply isn't assigned the Framework Parent
  // Opportunity record type.
  @IsTest
  static void testAceCanCreateFrameworkParentOpportunityUnderAbcAccount() {
    User ace = getAce();

    Account acc = new Account(
      Name = 'ABC Account',
      BillingCountry = 'United States',
      BillingState = 'NY',
      BillingPostalCode = '11209'
    );
    insert acc;

    Opportunity opp = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.frameworkParentRecordTypeId(),
      'New Deal'
    );
    opp.Name = 'ABC Account - Ace Framework RT Test Opp';
    opp.AccountId = acc.Id;
    opp.OwnerId = ace.Id;

    Boolean createOk = false;
    String createError = '';
    Boolean frameworkRtAvailable;
    System.runAs(ace) {
      for (
        Schema.RecordTypeInfo rt : Opportunity.SObjectType.getDescribe()
          .getRecordTypeInfos()
      ) {
        if (
          rt.getRecordTypeId() ==
          VR_PRISM_TestSupport.frameworkParentRecordTypeId()
        ) {
          frameworkRtAvailable = rt.isAvailable();
        }
      }
      try {
        insert as user opp;
        createOk = true;
      } catch (Exception e) {
        createError = e.getMessage();
      }
    }

    System.debug(
      '###ACE_CREATE_FRAMEWORK_PARENT_OPP_UNDER_ABC_ACCOUNT: ok=' +
        createOk +
        ' frameworkRtAvailableToProfile=' +
        frameworkRtAvailable +
        ' err=' +
        createError
    );

    Assert.isTrue(
      createOk,
      'Ace Dijon (ace@digitalae.irm.com.newprism) should be able to create a ' +
        'Framework Parent Opportunity under ABC Account, but the insert was blocked ' +
        '(Framework Parent Opportunity record type available to his profile: ' +
        frameworkRtAvailable +
        '): ' +
        createError
    );
  }

  // The two tests above pass, so neither AccountId nor RecordTypeId is the blocker. The flow
  // also copies Get_Account.Division (Global, 02d800000004CzGAAU) onto the new Opportunity
  // (see log 07LWJ00000W45Bi2AJ); no earlier test set Division.
  @IsTest
  static void testAceCanCreateOpportunityWithGlobalDivision() {
    User ace = getAce();
    Division globalDivision = [
      SELECT Id
      FROM Division
      WHERE Name = 'Global'
      LIMIT 1
    ];

    Account acc = new Account(
      Name = 'ABC Account',
      BillingCountry = 'United States',
      BillingState = 'NY',
      BillingPostalCode = '11209'
    );
    insert acc;

    Opportunity opp = VR_PRISM_TestSupport.baseOpp(
      'Qualification',
      VR_PRISM_TestSupport.frameworkParentRecordTypeId(),
      'New Deal'
    );
    opp.Name = 'ABC Account - Ace Division Test Opp';
    opp.AccountId = acc.Id;
    opp.OwnerId = ace.Id;
    opp.put('Division', globalDivision.Id);

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
      '###ACE_CREATE_OPP_GLOBAL_DIVISION: ok=' +
        createOk +
        ' err=' +
        createError
    );

    Assert.isTrue(
      createOk,
      'Ace Dijon should be able to create an Opportunity with Division = Global, ' +
        'but the insert was blocked: ' +
        createError
    );
  }
}
