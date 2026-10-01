@isTest
private class VR_PRISM_Qual_Billing_Account_Test {
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
    o.Primary_Product_Line__c = 'ITAD';
    o.Billing_Country__c = VR_PRISM_TestSupport.getUnitedStatesCountryId();
    return o;
  }

  @isTest
  static void test_blocked_when_Billing_Account_blank() {
    Opportunity o = buildInScopeOpp('Solutioning', 'Cross-Sell/Upsell');
    o.Billing_Account__c = null;
    Boolean threw = false;
    Test.startTest();
    try {
      insert o;
    } catch (DmlException e) {
      threw = true;
      System.assert(
        e.getMessage().contains('Billing Account'),
        'Expected the VR_PRISM_Qual_Billing_Account error, got: ' +
        e.getMessage()
      );
    }
    Test.stopTest();
    System.assert(
      threw,
      'VR_PRISM_Qual_Billing_Account should block save when Billing_Account__c is blank while in scope.'
    );
  }

  @isTest
  static void test_allowed_when_Billing_Account_populated() {
    Opportunity o = buildInScopeOpp('Solutioning', 'Cross-Sell/Upsell');
    o.Billing_Account__c = VR_PRISM_TestSupport.getAccountId();
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
    o.Billing_Account__c = null;
    Test.startTest();
    insert o;
    Test.stopTest();
    System.assertNotEquals(
      null,
      o.Id,
      'VR_PRISM_Qual_Billing_Account should not fire for an out-of-scope Type even with the field blank.'
    );
  }
}
