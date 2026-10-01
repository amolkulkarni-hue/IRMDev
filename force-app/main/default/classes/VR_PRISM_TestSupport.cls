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

  private static final Set<String> SOLUTIONING_PLUS = new Set<String>{
    'Solutioning',
    'Negotiation',
    'Booking Verification',
    'Booked',
    'Setup',
    'Closed'
  };
  private static final Set<String> NEGOTIATION_PLUS = new Set<String>{
    'Negotiation',
    'Booking Verification',
    'Booked',
    'Setup',
    'Closed'
  };
  private static final Set<String> BV_PLUS = new Set<String>{
    'Booking Verification',
    'Booked',
    'Setup',
    'Closed'
  };
  private static final Set<String> WON_STAGES = new Set<String>{
    'Booked',
    'Setup',
    'Closed'
  };

  /**
   * Minimally-valid Opportunity for exercising a single VR_PRISM rule. All BU flags
   * default false and Amount defaults low (1000) so BU-gated / amount-threshold rules
   * don't fire unless a test deliberately overrides them. Callers set whatever
   * additional fields their specific rule cares about (PPL, country, target field, ...)
   * on the returned record before insert.
   *
   * Also defensively satisfies OTHER still-active validation rules (both pre-existing
   * legacy rules and the other 60 VR_PRISM rules deployed alongside this one) that would
   * otherwise block the insert/update before the rule actually under test gets evaluated,
   * based on the stage passed in. A handful of these defaulted fields are themselves the
   * *target* field of one specific VR_PRISM rule's own test class - that test's "blocked"
   * scenario explicitly nulls the field back out after calling this method.
   */
  public static Opportunity baseOpp(
    String stage,
    Id recordTypeId,
    String type
  ) {
    Opportunity o = new Opportunity(
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
    applyStageDefaults(o, stage);
    return o;
  }

  /**
   * Applies every stage-gated baseline field this org's other active validation rules
   * (legacy and sibling VR_PRISM_*) require once an Opportunity reaches a given stage.
   * baseOpp() calls this for the insert-time stage; any test that later moves an
   * existing Opportunity to a DIFFERENT stage via `o.StageName = X; update o;` must
   * call this again with the new stage first - the insert-time defaults don't
   * retroactively cover a stage the record didn't start at.
   */
  public static void applyStageDefaults(Opportunity o, String stage) {
    // VR_Opp_S1_Qual_Checklist_Fields-style legacy requirement: Budget Validated and
    // Business Problem must be populated from Solutioning onward.
    if (SOLUTIONING_PLUS.contains(stage)) {
      o.Budget_Validated__c = 'Yes';
      o.Business_Problem_Evidenced__c = 'Improve Efficiency or Reduce Manual Work';
    }
    // The 22 other VR_PRISM_Qual_*/Sol_* "field required from stage X onward" rules
    // (Category A) all gate on PPL/BU/Type combinations that baseOpp() itself never
    // turns on - but several test classes' own "extra" setters (e.g. setting
    // Primary_Product_Line__c to satisfy their OWN target field's gate) incidentally
    // satisfy a SIBLING rule's gate too, tripping it before the rule under test is
    // even reached. Defaulting all of them here mirrors an Opportunity that a real
    // user actually advanced through the process cleanly, and is harmless for tests
    // whose own gate never opens. Skips Is_InSight_being_proposed__c, a picklist
    // dependent on Primary_Product_Line__c - not safe to default without knowing PPL.
    if (SOLUTIONING_PLUS.contains(stage)) {
      o.Billing_Country__c = getUnitedStatesCountryId();
      o.Add_On__c = 'Workflow';
      o.Digital_Deal_Archetype__c = 'Custom Software solution';
      o.InSight_Opportunities__c = 'Invoice Processing';
      o.Expected_CuFt__c = 100;
      o.US_Federal_GSA_Pricing__c = 'No';
      o.Multi_Country__c = 'Yes';
      o.Remarketing_Required__c = 'Yes';
      o.Service_Address__Street__s = '123 Main St';
      o.IM_Unit_of_Measure__c = 'Cubic Ft';
      o.IM_Up_Sell_Detail__c = 'Additional storage racks';
      o.IM_Up_Sell_Sold_To__c = 'ORCL-12345';
      o.IM_Up_Sell_Quantity__c = 5;
      o.Upsell_Customer_ID__c = getCustomerAccountId();
      o.NextStep = 'Follow up call';
      o.Next_Step_Date__c = Date.today().addDays(7);
    }
    // CT_Required_in_BV_and_Negotiation / TCV_Required_in_BV_and_Negotiation: both
    // required (Contract Term >= 13, TCV >= 1) from Negotiation onward.
    if (NEGOTIATION_PLUS.contains(stage)) {
      o.Contract_Term_months__c = 24;
      o.Total_Contract_Value_TCV__c = 100000;
      o.PO_Required__c = 'No';
      o.Cloud_Provider__c = 'AWS';
      o.IM_Booked_Date__c = Date.today().addDays(45);
      o.No_of_Forecast_Billing_Month__c = '1';
      o.Free_Storage_Period__c = '1 month';
      o.Fuel_Surcharge_Waiver__c = 'Yes';
      o.Marketplace__c = 'Yes';
      o.Marketplace_Details__c = 'Marketplace details for testing';
      o.IM_Servicing_Region__c = 'Aberdeen';
    }
    // When_Opty_is_Won_Reason_Won_is_Required (legacy, Booked only) and this rule's own
    // sibling VR_PRISM_Neg_Reason_Won (Booking Verification onward) both need this.
    if (BV_PLUS.contains(stage)) {
      o.IME_Reason_Won__c = 'Price';
    }
    // Forecast_Category_Validation_Rule / Forecast_Category_cant_be_closed_till_4
    // (legacy) and this rule's own VR_PRISM_FCST_Cat_* siblings all enforce the same
    // Stage <-> Forecast Category mapping.
    if (WON_STAGES.contains(stage)) {
      o.ForecastCategoryName = 'Closed';
    } else if (stage == 'Lost') {
      o.ForecastCategoryName = 'Omitted';
    } else {
      o.ForecastCategoryName = 'Pipeline';
    }
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
