/*****************************************************************************************************
 * Class: QTB_ApprovalSummaryCompController_Test
 * Author: Accenture
 * Purpose: This is a test class for QTB_ApprovalSummaryCompController
 * Change History: 9/30/2020
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture
 *******************************************************************************************************/
@isTest(seealldata=false)
public with sharing class QTB_ApprovalSummaryCompController_Test {
  @testSetup
  static void testData() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    Test.startTest();
    System.runAs(userList[0]) {
      List<account> accountList = QTB_TestDataFactory.createAccounts(1);
      accountList[0].BillingCountry = 'India';
      accountList[0].QTB_Legal_Entity_Country__c = 'India';
      update accountList;
      blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
        'Yes'
      );
      blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
        'Yes'
      );
      blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');

      List<product2> product = QTB_TestDataFactory.createProducts(1);
      product[0].blng__BillingRule__c = billingRule.id;
      product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
      product[0].blng__TaxRule__c = taxRule.id;
      database.update(product);

      Id pricebookId = Test.getStandardPricebookId();
      PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
        product[0]
      );

      // Update the pricebook of opportunity
      List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
      oppList[0].Pricebook2Id = pricebookId;
      database.update(oppList);

      List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
        1,
        oppList[0].id,
        accountList[0].id,
        true,
        null
      );
      quoteList[0].SBQQ__PriceBook__c = pricebookId;
      quoteList[0].SBQQ__StartDate__c = System.Today();
      database.update(quoteList);

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
    }
  }
  static testMethod void testMethod1() {
    Test.startTest();
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      SBQQ__Quote__c testquote = [SELECT id, name FROM sbqq__quote__c LIMIT 1];
      SBQQ__Quoteline__c testQuoteLine = [
        SELECT id, name
        FROM sbqq__quoteline__c
        LIMIT 1
      ];
      PageReference pageRef = page.QTB_ApprovalSummaryPage;
      pageRef.getParameters().put('id', string.valueof(testquote.id));
      pageRef.getParameters().put('target', 'editor');
      Test.setCurrentPage(pageRef);
      QTB_ApprovalSummaryCompController appContr = new QTB_ApprovalSummaryCompController();
      appContr.quoteId = testquote.id;
      appContr.quoteRecord.id = testquote.id;
      appContr.lines.add(testQuoteLine);
      Test.stopTest();
      System.Assert(userList.size() == 2);
    }
  }
   static testMethod void testMethod2() {
    Test.startTest();
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      SBQQ__Quote__c testquote = [SELECT id, name FROM sbqq__quote__c LIMIT 1];
      SBQQ__Quoteline__c testQuoteLine = [
        SELECT id, name
        FROM sbqq__quoteline__c
        LIMIT 1
      ];
      PageReference pageRef = page.QTB_ApprovalSummaryPage;
      pageRef.getParameters().put('id', string.valueof(testquote.id));
      pageRef.getParameters().put('target', 'editor');
      Test.setCurrentPage(pageRef);
      QTB_ApprovalSummaryCompController appContr = new QTB_ApprovalSummaryCompController();
      appContr.quoteId = testquote.id;
      appContr.quoteRecord.id = testquote.id;
      appContr.lines1.add(testQuoteLine);
      Test.stopTest();
      System.Assert(userList.size() == 2);
    }
  }
}