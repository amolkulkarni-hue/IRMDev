@IsTest(SeeAllData=true)
private class AceDijonPricebookAccessTest {
  // Diagnostic for Opportunity_Creation_from_Account_Flow fault (debug log 07LWJ00000W45Bi2AJ):
  // validation passes, then the insert fails with INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY.
  // The "Opportunity - Set Default Price Book" before-save flow overwrites Pricebook2Id with
  // 01sWJ000003imlZYAQ. SeeAllData=true because Pricebook2 rows are not visible to tests otherwise.

  private static final Id DEFAULT_PRICEBOOK_ID = '01sWJ000003imlZYAQ';
  private static final Id ABC_ACCOUNT_ID = '001WJ000012NjdtYAC';

  @IsTest
  static void testAceCanSeeDefaultPricebook() {
    User ace = [
      SELECT Id
      FROM User
      WHERE Username = 'ace@digitalae.irm.com.newprism'
      LIMIT 1
    ];

    Integer visible = -1;
    String err = '';
    System.runAs(ace) {
      try {
        visible = [
            SELECT Id
            FROM Pricebook2
            WHERE Id = :DEFAULT_PRICEBOOK_ID
            WITH USER_MODE
          ]
          .size();
      } catch (Exception e) {
        err = e.getMessage();
      }
    }

    System.debug('###ACE_PRICEBOOK_VISIBLE: count=' + visible + ' err=' + err);
    Assert.areEqual(
      1,
      visible,
      'Ace should be able to read the default price book ' +
        DEFAULT_PRICEBOOK_ID +
        ' (err=' +
        err +
        ')'
    );
  }

  @IsTest
  static void testAceCanCreateOpportunityWithDefaultPricebook() {
    User ace = [
      SELECT Id
      FROM User
      WHERE Username = 'ace@digitalae.irm.com.newprism'
      LIMIT 1
    ];
    Opportunity opp = new Opportunity(
      Name = 'ABC Account - Ace Pricebook Test Opp',
      AccountId = ABC_ACCOUNT_ID,
      OwnerId = ace.Id,
      RecordTypeId = App_Constants.FRAMEWORK_PARENT_OPPORTUNITY_RECTYPE_ID,
      Type = 'New Deal',
      StageName = 'Qualification',
      CloseDate = Date.today().addDays(30),
      Pricebook2Id = DEFAULT_PRICEBOOK_ID,
      Amount = 1000,
      Primary_Product_Line__c = 'Clean Start',
      Digital_BU__c = true
    );

    String err = '';
    System.runAs(ace) {
      try {
        insert as user opp;
      } catch (Exception e) {
        err = e.getMessage();
      }
    }

    System.debug('###ACE_OPP_WITH_DEFAULT_PRICEBOOK: err=' + err);
    Assert.areEqual(
      '',
      err,
      'Ace should be able to create the Opportunity with the default price book'
    );
  }
}
