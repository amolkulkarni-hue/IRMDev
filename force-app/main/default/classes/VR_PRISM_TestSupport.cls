/**
 * Shared test-support utilities for the VR_PRISM_* validation-rule test classes.
 * Not itself a test class - each *_Test class calls these from its own @TestSetup /
 * test methods (Apex @TestSetup cannot be inherited or shared directly across classes).
 *
 * setupCommonTestData() exists because inserting ANY Opportunity in this org's test
 * context runs into automation (Touch Level calc, sharing, SVStatus) that NPEs without
 * this scaffolding - it has nothing to do with the VR_PRISM rules themselves, but every
 * one of the 61 new test classes needs it just to get an insert to succeed at all.
 */
@isTest
public class VR_PRISM_TestSupport {
  public static void setupCommonTestData() {
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
    // Second country, outside North America, for rules that gate on a non-NA Region
    // (e.g. VR_PRISM_Qual_UpSell_Oracle_Acct_ID). QTB_Billing_Country_Name__c and
    // Region__c on Opportunity are both formulas off Billing_Country__c - not directly
    // writeable - so tests set Billing_Country__c to one of these two records instead.
    insert new IM_Country__c(
      Name = 'Ireland',
      Active__c = true,
      Region__c = 'Europe'
    );

    Account testAccount = new Account(
      Name = 'VR_PRISM Test Account',
      BillingCountry = 'United States',
      BillingState = 'NY',
      BillingPostalCode = '11209'
    );
    insert testAccount;

    // IM_Account__c is Master-Detail to Account, so it's required.
    insert new IM_Customer_Account__c(
      Name = 'VR-PRISM-TEST-001',
      IM_Account__c = testAccount.Id
    );
  }

  public static Id getAccountId() {
    return [SELECT Id FROM Account WHERE Name = 'VR_PRISM Test Account' LIMIT 1]
    .Id;
  }

  public static Id getCustomerAccountId() {
    return [
      SELECT Id
      FROM IM_Customer_Account__c
      WHERE Name = 'VR-PRISM-TEST-001'
      LIMIT 1
    ]
    .Id;
  }

  public static Id getUnitedStatesCountryId() {
    return [SELECT Id FROM IM_Country__c WHERE Name = 'United States' LIMIT 1]
    .Id;
  }

  public static Id getIrelandCountryId() {
    return [SELECT Id FROM IM_Country__c WHERE Name = 'Ireland' LIMIT 1].Id;
  }

  /**
   * Minimally-valid Opportunity for exercising a single VR_PRISM rule. All BU flags
   * default false and Amount defaults low (1000) so BU-gated / amount-threshold rules
   * don't fire unless a test deliberately overrides them. Callers set whatever
   * additional fields their specific rule cares about (PPL, country, target field, ...)
   * on the returned record before insert.
   */
  public static Opportunity baseOpp(
    String stage,
    Id recordTypeId,
    String type
  ) {
    return new Opportunity(
      Name = 'VR PRISM Test Opportunity',
      AccountId = getAccountId(),
      RecordTypeId = recordTypeId,
      Type = type,
      StageName = stage,
      CloseDate = Date.today().addDays(30),
      Pricebook2Id = Test.getStandardPricebookId(),
      Amount = 1000,
      ALM_BU__c = false,
      RIM_BU__c = false,
      MAS_BU__c = false,
      Digital_BU__c = false,
      W_L_BU__c = false
    );
  }

  // Standard_Opportunity is the default record type used by tests that don't care
  // which of the two (Standard vs Framework Parent) applies.
  public static Id stdRecordTypeId() {
    return App_Constants.STD_OPPORTUNITY_RECTYPE_ID;
  }

  public static Id frameworkParentRecordTypeId() {
    return App_Constants.FRAMEWORK_PARENT_OPPORTUNITY_RECTYPE_ID;
  }

  // One-time (per test run) Sales Revenue Forecast child record, needed only by the
  // VR_PRISM_Neg_Sales_Billing_Estimate positive test: Total_Sales_Billing_Estimate__c
  // is a roll-up summary field on Opportunity and cannot be set directly via DML.
  public static void addSalesRevenueForecast(
    Id opportunityId,
    Decimal estimate
  ) {
    insert new Sales_Revenue_Forecast__c(
      Name = 'VR PRISM Test Forecast',
      Forecast_Opportunity__c = opportunityId,
      Sales_Billing_Estimate__c = estimate
    );
  }

  // For the 3 VR_PRISM_Lock_All_Fields_When_{Booked,Closed,Setup} rules, which are
  // additionally gated on $Profile.Name = 'Sales & Account Management' - there is no
  // way to test that branch except by actually running the DML as a user with that
  // profile (custom permissions/profile checks in formulas can't be toggled directly
  // in a test context). Creates (once) and returns a user with that profile.
  public static User getSalesAccountManagementUser() {
    List<User> existing = [
      SELECT Id
      FROM User
      WHERE Username = 'vr.prism.sam.testuser@irmdev.test.invalid'
      LIMIT 1
    ];
    if (!existing.isEmpty()) {
      return existing[0];
    }
    Profile p = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Sales & Account Management'
      LIMIT 1
    ];
    User u = new User(
      FirstName = 'VR PRISM',
      LastName = 'Sales AM Test User',
      Alias = 'vrpsam',
      Email = 'vr.prism.sam.testuser@irmdev.test.invalid',
      Username = 'vr.prism.sam.testuser@irmdev.test.invalid',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/New_York',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
    insert u;
    return u;
  }
}
