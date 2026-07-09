/*****************************************************************************************************
 * Class: QTB_CreditNoteExtController_Test
 * Author: Accenture
 * Purpose: Test Class for QTB_CreditNoteExtController
 * Change History: 5/30/2020
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture
 *******************************************************************************************************/
@isTest(seeAllData=false)
private class QTB_CreditNoteExtController_Test {
  @testSetup
  static void testSetupMethod() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      Test.startTest();
      List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
        1,
        'Standard Account'
      );
        testaccounts[0].QTB_Legal_Entity_Country__c='India';
        update testAccounts;
      List<blng__CreditNote__c> creditNote = QTB_TestDataFactory.createCreditNote(
        testAccounts
      );
      Test.stopTest();
      System.Assert(testAccounts.size() == 1);
    }
  }
  @isTest
  static void testSubmit() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
      blng__CreditNote__c crednote = [
        SELECT id, ApprovalStatus__c
        FROM blng__CreditNote__c
        LIMIT 1
      ];
      QTB_CreditNoteExtController con = new QTB_CreditNoteExtController(
        new ApexPages.StandardController(crednote)
      );
        try{
            con.onSubmit();
        }
        catch (Exception e) {
        System.assertNotEquals('Script-thrown exception', e.getMessage());
      }
      con.onRecall();
      Test.stopTest();
      System.assertEquals(
        'Draft',
        crednote.ApprovalStatus__c,
        'Unexpected result'
      );
    }
  }
  @isTest
  static void testmethod1() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
      QTB_CreditNoteExtController.throwExplicitException = true;
      blng__CreditNote__c crednote = [
        SELECT ID
        FROM blng__CreditNote__c
        LIMIT 1
      ];
      QTB_CreditNoteExtController con = new QTB_CreditNoteExtController(
        new ApexPages.StandardController(crednote)
      );
      Test.stopTest();
      try {
        con.onSubmit();
      } catch (Exception e) {
        //System.assert('Script-thrown exception' == e.getMessage());
      }
      try {
        con.onRecall();
      } catch (Exception e) {
        //System.assert('Script-thrown exception' == e.getMessage());
      }
    }
  }
}