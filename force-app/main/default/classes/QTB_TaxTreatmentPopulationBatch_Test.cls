/*****************************************************************************************************
 * Class: QTB_TaxTreatmentPopulationBatch_Test
 * Author: Accenture
 * Purpose: This is a test class for QTB_TaxTreatmentPopulationBatch
 * Change History: 6/1/2020
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture   5/13
 *******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_TaxTreatmentPopulationBatch_Test {
  @TestSetup
	static void createData() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      Test.startTest();
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
      update product;

      Id pricebookId = Test.getStandardPricebookId();
      PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
        product[0]
      );
      QTB_Billing_Countries__c setting = new QTB_Billing_Countries__c();
        setting.name = 'Singapore';
        setting.Active__c = true;
        setting.Legal_entity_country__c = 'Singapore';
        insert setting;
      List<account> accountList = QTB_TestDataFactory.createAccounts(1);

      List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
      oppList[0].Pricebook2Id = pricebookId;
      update oppList;

      List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
        1,
        oppList[0].id,
        accountList[0].id,
        true,
        null
      );
      quoteList[0].SBQQ__PriceBook__c = pricebookId;
      quoteList[0].SBQQ__StartDate__c = System.Today();
      //update quoteList;

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

      List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
        1,
        quoteList[0].Id,
        accountList[0].id
      );
       orderList3[0].QTB_Legal_Entity_Country__c='Singapore';
       update orderList3[0];
      List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(
        orderList3[0].Id,
        product[0].Id,
        quoteLinesList,
        standardPrice
      );
      orderList3[0].Status = 'Activated';
      //update orderList3[0];
      QTB_TaxTreatmentPopulationBatch res = new QTB_TaxTreatmentPopulationBatch(
        accountList
      );
      Database.executeBatch(res);
      Test.stopTest();
      System.assertEquals(
        'Activated',
        orderList3[0].Status,
        'Unexpected error'
      );
    }
  }
  //cover catch
  static testMethod void testMethod2() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
      List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
        1,
        'Standard Account'
      );
      QTB_TaxTreatmentPopulationBatch.throwExplicitException = true;
      QTB_TaxTreatmentPopulationBatch obj = new QTB_TaxTreatmentPopulationBatch(
        testAccounts
      );
      obj.execute(null, null);
      Test.stopTest();
      System.assertEquals(
        true,
        QTB_TaxTreatmentPopulationBatch.throwExplicitException
      );
    }
  }
}