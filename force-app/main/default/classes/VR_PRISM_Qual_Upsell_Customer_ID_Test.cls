@isTest
private class VR_PRISM_Qual_Upsell_Customer_ID_Test {
  @TestSetup
  static void setup() {
    VR_PRISM_TestSupport.setupCommonTestData();
  }

  private static Opportunity buildInScopeOpp(String stage, String type) {
    Opportunity o = VR_PRISM_TestSupport.baseOpp(
      stage,
      VR_PRISM_TestSupport.stdRecordTypeId(),
      type
    );
    o.Billing_Country__c = VR_PRISM_TestSupport.getUnitedStatesCountryId();
    o.Primary_Product_Line__c = 'Records Management';
    return o;
  }

  @isTest
  static void test_blocked_when_Upsell_Customer_ID_blank() {
    Opportunity o = buildInScopeOpp('Solutioning', 'Cross-Sell/Upsell');
    o.Upsell_Customer_ID__c = null;
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Upsell Customer ID'),
        'Expected the VR_PRISM_Qual_Upsell_Customer_ID error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Qual_Upsell_Customer_ID should block save when Upsell_Customer_ID__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_Upsell_Customer_ID_populated() {
    Opportunity o = buildInScopeOpp('Solutioning', 'Cross-Sell/Upsell');
    o.Upsell_Customer_ID__c = VR_PRISM_TestSupport.getCustomerAccountId();
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'Insert should succeed when the required field is populated.'
    );
  }

  @isTest
  static void test_notBlocked_outOfScope_type() {
    Opportunity o = buildInScopeOpp('Solutioning', 'Rate Change');
    o.Upsell_Customer_ID__c = null;
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Qual_Upsell_Customer_ID should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
