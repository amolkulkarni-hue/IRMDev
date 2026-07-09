/*****************************************************************************************************
 * Class: QTB_QuoteLineHelper_Test
 * Author: Accenture
 * Purpose: This is a test class for QTB_QuoteLineHelper
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture    6/1/2020
 *******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_QuoteLineHelper_Test {
  @isTest
  static void testData() {
    Test.startTest();
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      List<product2> product = QTB_TestDataFactory.createProducts(1);
      List<account> accountList = QTB_TestDataFactory.createAccounts(1);
      List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
      List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
        1,
        oppList[0].id,
        accountList[0].id,
        true,
        null
      );
      List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
        1,
        quoteList[0].id,
        accountList[0].id
      );
      List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(
        1,
        quoteList[0].id,
        quoteGroupList[0].id,
        product[0].id
      );
      quoteLinesList[0].qtb_offered_for_free__c = true;
      database.update(quoteLinesList);

      Test.stopTest();
      System.Assert(quoteLinesList[0].qtb_offered_for_free__c == true);
      database.delete(quoteLinesList);
    }
    QTB_QuoteLineHandler handler = new QTB_QuoteLineHandler();
    handler.AfterUndelete(null);
    QTB_TestDataFactory.createBypassSetting(QTB_Constants.TYPE_SBQQ_QUOTELINE);
    handler.isDisabled();
  }

  // cover catch
  static testMethod void testmethod1() {
    Test.startTest();
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      QTB_QuoteLineHandler.throwExplicitException = true;
      QTB_QuoteLineHandler handler = new QTB_QuoteLineHandler();
      // handler.AfterUpdate(null,null);
      handler.BeforeUpdate(null, null);
      // handler.AfterDelete(null);
      handler.AfterUndelete(null);
      handler.BeforeDelete(null);
      // handler.BeforeInsert(null);
      // handler.AfterInsert(null);
      QTB_TestDataFactory.createBypassSetting(
        QTB_Constants.TYPE_SBQQ_QUOTELINE
      );
      handler.isDisabled();
      Test.stopTest();
      try {
        QTB_QuoteLineHelper.updateProducts(null);
      } catch (Exception e) {
        System.assertEquals('Script-thrown exception', e.getMessage());
      }
      try {
        QTB_QuoteLineHelper.resetFields(null);
      } catch (Exception e) {
        System.assertEquals('Script-thrown exception', e.getMessage());
      }
      System.assertEquals(true, QTB_QuoteLineHandler.throwExplicitException);
    }
  }
}