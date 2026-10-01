@IsTest
private class AceDijonOppAccessVerificationTest {
  // Isolates why ace@digitalae.irm.com.newprism (Sales & Account Management profile) hits
  // INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY in Opportunity_Creation_from_Account_Flow
  // (Create_Opportunity element, debug log 07LWJ00000W45Bi2AJ) when creating an Opportunity
  // from ABC Account. `insert as user` forces sharing/FLS enforcement under his context.
  // Setup is self-contained on purpose: VR_PRISM_TestSupport is shared and in flux.

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
    insert new SVStatus__c(
      Name = 'SVStatusPassed',
      Amount__c = 0,
      SetupOwnerId = UserInfo.getOrganizationId()
    );
    insert new Country_Settings__c(
      Name = 'United States',
      Object_Name__c = 'Opportunity',
      SetupOwnerId = UserInfo.getOrganizationId()
    );
    insert new List<Opportunity_Security__c>{
      new Opportunity_Security__c(
        Name = 'Primary CDE',
        Field_Name__c = 'Primary_CDE__c',
        Object_Name__c = 'Account',
        Visibility_Access_Level__c = 'R',
        SetupOwnerId = UserInfo.getOrganizationId()
      ),
      new Opportunity_Security__c(
        Name = 'Original Lead Owner',
        Field_Name__c = 'IM_Original_Lead_Owner__c',
        Object_Name__c = 'Opportunity',
        Visibility_Access_Level__c = 'W',
        SetupOwnerId = UserInfo.getOrganizationId()
      ),
      new Opportunity_Security__c(
        Name = 'Primary BDE',
        Field_Name__c = 'Primary_BDE__c',
        Object_Name__c = 'Account',
        Visibility_Access_Level__c = 'W',
        SetupOwnerId = UserInfo.getOrganizationId()
      )
    };
    insert new OpportunityProductSelection__c(
      Name = 'CloudSolutionsProduct',
      Product_Class_Name__c = 'Cloud',
      Product_Line_Name__c = 'Cloud Solutions'
    );

    IM_Country__c testCountry = new IM_Country__c(
      Name = 'United States',
      Active__c = true,
      Region__c = 'North America'
    );
    insert testCountry;
    insert new IM_Alternative_Country_Name__c(
      IM_Country__c = testCountry.Id,
      Alternative_Name__c = 'United States'
    );

    // Owned by the default test-running (admin) user, outside Ace's role hierarchy -
    // mirrors the real ABC Account he's launching the flow from.
    Account acc = new Account(
      Name = 'ABC Account',
      BillingCountry = 'United States',
      BillingState = 'NY',
      BillingPostalCode = '11209'
    );
    insert acc;
    insert new IM_Customer_Account__c(
      Name = 'ACE-TEST-001',
      IM_Account__c = acc.Id
    );
  }

  private static Opportunity newOpp(Id recordTypeId, String name, User ace) {
    Account acc = [SELECT Id FROM Account WHERE Name = 'ABC Account' LIMIT 1];
    return new Opportunity(
      Name = name,
      AccountId = acc.Id,
      OwnerId = ace.Id,
      RecordTypeId = recordTypeId,
      Type = 'New Deal',
      StageName = 'Qualification',
      CloseDate = Date.today().addDays(30),
      Pricebook2Id = Test.getStandardPricebookId(),
      Amount = 1000,
      ForecastCategoryName = 'Pipeline',
      ALM_BU__c = false,
      RIM_BU__c = false,
      MAS_BU__c = false,
      Digital_BU__c = false,
      W_L_BU__c = false
    );
  }

  private static String insertAsAce(User ace, Opportunity opp) {
    String err = '';
    System.runAs(ace) {
      try {
        insert as user opp;
      } catch (Exception e) {
        err = e.getMessage();
      }
    }
    return err;
  }

  @IsTest
  static void testAceCanCreateOpportunityUnderAbcAccount() {
    User ace = getAce();
    Opportunity opp = newOpp(
      App_Constants.STD_OPPORTUNITY_RECTYPE_ID,
      'ABC Account - Ace Standard RT Test Opp',
      ace
    );

    String err = insertAsAce(ace, opp);

    System.debug('###ACE_STANDARD_RT: err=' + err);
    Assert.areEqual(
      '',
      err,
      'Ace should be able to create a Standard Opportunity under ABC Account'
    );
  }

  @IsTest
  static void testAceCanCreateFrameworkParentOpportunityUnderAbcAccount() {
    User ace = getAce();
    Opportunity opp = newOpp(
      App_Constants.FRAMEWORK_PARENT_OPPORTUNITY_RECTYPE_ID,
      'ABC Account - Ace Framework RT Test Opp',
      ace
    );

    Boolean frameworkRtAvailable;
    System.runAs(ace) {
      for (
        Schema.RecordTypeInfo rt : Opportunity.SObjectType.getDescribe()
          .getRecordTypeInfos()
      ) {
        if (
          rt.getRecordTypeId() ==
          App_Constants.FRAMEWORK_PARENT_OPPORTUNITY_RECTYPE_ID
        ) {
          frameworkRtAvailable = rt.isAvailable();
        }
      }
    }
    String err = insertAsAce(ace, opp);

    System.debug(
      '###ACE_FRAMEWORK_RT: frameworkRtAvailableToProfile=' +
        frameworkRtAvailable +
        ' err=' +
        err
    );
    Assert.areEqual(
      '',
      err,
      'Ace should be able to create a Framework Parent Opportunity under ABC Account ' +
        '(record type available to his profile: ' +
        frameworkRtAvailable +
        ')'
    );
  }

  // The flow copies Get_Account.Division (Global, 02d800000004CzGAAU) onto the new
  // Opportunity; no other test sets Division.
  @IsTest
  static void testAceCanCreateOpportunityWithGlobalDivision() {
    User ace = getAce();
    Division globalDivision = [
      SELECT Id
      FROM Division
      WHERE Name = 'Global'
      LIMIT 1
    ];
    Opportunity opp = newOpp(
      App_Constants.FRAMEWORK_PARENT_OPPORTUNITY_RECTYPE_ID,
      'ABC Account - Ace Division Test Opp',
      ace
    );
    opp.put('Division', globalDivision.Id);

    String err = insertAsAce(ace, opp);

    System.debug('###ACE_GLOBAL_DIVISION: err=' + err);
    Assert.areEqual(
      '',
      err,
      'Ace should be able to create an Opportunity with Division = Global'
    );
  }
}
