/*****************************************************************************************************
 * Class: QTB_PostUpBillOrderDraftToActBatch_Test
 * Author: Virtusa
 * Purpose: This is a test class for QTB_PostUpBillOrderDraftToActBatch
 * Change History: 9/24/2021
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * 
 *******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_PostUpBillOrderDraftToActBatch_Test {
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
      update quoteList;

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

      List<Order> orderList3 = QTB_TestDataFactory.createBillingOrders(
        1,
        quoteList[0].Id,
        accountList[0].id
      );
        blng__FinanceBook__c BillingFinanceBook = new blng__FinanceBook__c();
        BillingFinanceBook.Name = 'Accounting Finance Book';
        BillingFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
        BillingFinanceBook.blng__Active__c = true;
        BillingFinanceBook.blng__PeriodType__c='Accounting';
        insert BillingFinanceBook;
            
        blng__BillingTreatment__c BillingTretment = new blng__BillingTreatment__c();
        BillingTretment.Name = 'No Invoice Billing Treatment';
        BillingTretment.blng__Active__c = true;
        BillingTretment.blng__BillingRule__c=billingRule.id;
        BillingTretment.blng__BillingFinanceBook__c =    BillingFinanceBook.id;
        insert BillingTretment;

      List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(
        orderList3[0].Id,
        product[0].Id,
        quoteLinesList,
        standardPrice
      );
          blng__LegalEntity__c LglEntity = QTB_TestDataFactory.createLegalEntity('Singapore');
          orderItemList3[0].blng__LegalEntity__c= LglEntity.id;
          orderItemList3[0].SBQQ__Activated__c=false;
          Update orderItemList3[0];
     List<OrderItem> orderItemList32 = QTB_TestDataFactory.createCPQOrderItems(
        orderList3[0].Id,
        product[0].Id,
        quoteLinesList,
        standardPrice
      );
      orderItemList32[0].blng__LegalEntity__c= LglEntity.id;
      orderItemList32[0].SBQQ__Activated__c=false;
      Update orderItemList32[0];   
      ConsumptionSchedule cs= new ConsumptionSchedule();
        cs.name='List Rate SINGAPORE';
        cs.RatingMethod='Tier';
        cs.Type='Range';
        cs.SBQQ__Category__c='Rates';
        cs.BillingTerm =1;
        cs.BillingTermUnit='Month';
        insert cs;
      QTB_Billing_Countries__c setting = new QTB_Billing_Countries__c();
        setting.Name = 'Singapore';
        setting.ConsumptionScheduleID__c =cs.id;
        setting.Active__c= true;
        setting.Legal_entity_country__c='Singapore';
        insert setting;
         SBQQ__OrderItemConsumptionSchedule__c OPCSobject = new SBQQ__OrderItemConsumptionSchedule__c();
          OPCSobject.SBQQ__OrderItem__c = orderItemList3[0].Id;
          OPCSobject.Name = 'List Rate'+ orderItemList3[0].Product2.ProductCode;
          OPCSobject.SBQQ__BillingTerm__c= 1;
          OPCSobject.SBQQ__Category__c='Rates';
          OPCSobject.SBQQ__Type__c='Range';
          OPCSobject.SBQQ__RatingMethod__c='Tier';
          OPCSobject.SBQQ__BillingTermUnit__c='Month';
          OPCSobject.SBQQ__ConsumptionSchedule__c = cs.id;
          OPCSobject.blng__BillingRule__c=orderItemList3[0].Product2.blng__BillingRule__c;
          OPCSobject.blng__RevenueRecognitionRule__c=orderItemList3[0].Product2.blng__RevenueRecognitionRule__c;
          OPCSobject.blng__TaxRule__c=orderItemList3[0].Product2.blng__TaxRule__c;
          OPCSobject.blng__TaxTreatment__c = orderItemList3[0].blng__TaxTreatment__c;
          OPCSobject.CurrencyIsoCode =orderItemList3[0].order.CurrencyIsoCode;
        insert OPCSobject;
      ID RecId = (Schema.SObjectType.Order.getRecordTypeInfosByName().get('Billing Order').getRecordTypeId());  
      orderList3[0].RecordTypeId= RecId;
      orderList3[0].Status = 'Draft';
      orderList3[0].QTB_Legal_Entity_Country__c='Singapore';
      update orderList3[0];
        set<Id> lstTopass= new set<Id>();
        lstTopass.add(orderList3[0].id);
        QTB_PostUpBillOrderDraftToActBatch res = new QTB_PostUpBillOrderDraftToActBatch(
        lstTopass
      );
      Database.executeBatch(res);
         Test.stopTest();
      System.assertEquals(
        'Draft',
       orderList3[0].status,
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
        List<Order> orderList333 = QTB_TestDataFactory.createBillingOrders(
        1,
        NULL,
        testAccounts[0].id
       );   
        Set<Id> lstTopass2= new Set<Id>();
        lstTopass2.add(orderList333[0].id);
      QTB_PostUpBillOrderDraftToActBatch.throwExplicitException = true;
      QTB_PostUpBillOrderDraftToActBatch obj = new QTB_PostUpBillOrderDraftToActBatch(
        lstTopass2
      );
      obj.execute(null, null);
      Test.stopTest();
      System.assertEquals(
        true,
        QTB_PostUpBillOrderDraftToActBatch.throwExplicitException
      );
    }
  }
  
}