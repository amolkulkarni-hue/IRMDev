/*****************************************************************************************************
 * Class: QTB_WorkOrderBatch_Test
 * Author: Accenture
 * Purpose: Test Class for QTB_WorkOrderBatch
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture   10/08/2020
 *******************************************************************************************************/
@isTest(seeAlldata=false)
private with sharing class QTB_WorkOrderBatch_Test {
  @testSetup
  static void setup() {
    Test.startTest();
    SBQQ.TriggerControl.disable();
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      blng__LegalEntity__c entityList = QTB_TestDataFactory.createLegalEntity(
        'Norway'
      );
      List<account> accountList = QTB_TestDataFactory.createAccounts(
        2,
        'Billing Account'
      );
      accountList[0].QTB_WorkOrderTieringStartDate__c = system.today() - 2;
      accountList[0].QTB_Work_Order_Tier_Flag__c = true;
      accountList[0].QTB_Hold_Billing__c = false;
      accountList[0].BillingCountry = 'Norway';
      accountList[0].QTB_Bill_Cycle_Day__c = 'Norway-26th';
      accountList[0].QTB_Create_Parent_Billing_Account__c = false;
      accountList[0].ParentId = accountList[1].Id;
      accountList[0].QTB_Contract_Entity__c = entityList.Id;
      accountList[0].QTB_Invoice_Delivery_Options__c = 'Email';
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
      product[0].QTB_Storage_Product__c = true;
      product[0].SBQQ__ChargeType__c = 'Recurring';
      product[0].SBQQ__BillingType__c ='Advance'; 
      product[0].SBQQ__HasConsumptionSchedule__c =true;
      product[0].recordTypeId = QTB_Utils.GLOBAL_SALES_RECTYPEID;
      product[0].QTB_Oracle_GL_Account_Code__c='4565';
      product[0].QTB_Oracle_Product_Code__c = '123';  
      update product;

      Id pricebookId = Test.getStandardPricebookId();
      PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
        product[0]
      );

      List<QTB_WorkOrderTiers__c> workOrderList = QTB_TestDataFactory.createWorkOrderTiers(
        1,
        accountList[0].id,
        product[0].id
      );
      system.debug('workOrderList Test>' + workOrderList);
      List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
      oppList[0].Pricebook2Id = pricebookId;
      update oppList;

     /* List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
        1,
        oppList[0].id,
        accountList[0].id,
        true,
        null
      );
      quoteList[0].SBQQ__PriceBook__c = pricebookId;
      quoteList[0].SBQQ__StartDate__c = System.Today();
      update quoteList; */
        
        
        
            //Legal Entity
        blng__LegalEntity__c indiaEntity = new blng__LegalEntity__c();
        indiaEntity.Name = 'Test Legal Entity United States';
        indiaEntity.blng__Active__c = true;
        indiaEntity.blng__Country__c = 'United States';
        indiaEntity.QTB_Type__c = 'Contract';
        // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert indiaEntity;

        
        
         //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].QTB_IM_Legal_Entity__c = indiaEntity.id;
        quoteList[0].QTB_Opportunity_Billing_Country__c = 'United States';
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
      quoteLinesList[0].SBQQ__PricebookEntryId__c = 'test';
      update quoteLinesList;
      SBQQ.TriggerControl.disable();
      List<Order> orderList = QTB_TestDataFactory.createCPQOrders(
        1,
        quoteList[0].Id,
        accountList[0].id
      );
      orderList[0].blng__InvoiceBatch__c = 'Norway-26th';
      update orderList;

      List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(
        orderList[0].Id,
        product[0].Id,
        quoteLinesList,
        standardPrice
      );

      blng__InvoiceScheduler__c blngInvoice = QTB_TestDataFactory.createInvoiceScheduler(
        'Norway-26th',
        'Once'
      );
      Test.stopTest();
      List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(
        1,
        accountList[0],
        orderList[0],
        orderItemList[0]
      );
      usageSum[0].blng__Subtotal__c = 310;
      usageSum[0].blng__Status__c = 'Queued For Invoice';
      usageSum[0].blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
      update usageSum;
      List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(
        4,
        accountList[0],
        usageSum[0]
      );
   //   usageList[0].blng__PreratedAmount__c = 0;
   //  usageList[0].blng__PreratedQuantity__c = 0;
      usageList[0].blng__Quantity__c = 15;
      usageList[0].QTB_Invoice_Quantity__c = 10;
      usageList[0].QTB_WO_Usage__c=true;
      usageList[0].QTB_Work_Order_ID__c = workOrderList[0].id;
      usageList[0].blng__OrderProduct__c = orderItemList[0].id;

   //   usageList[1].blng__PreratedAmount__c = 0;
    //  usageList[1].blng__PreratedQuantity__c = 0;
      usageList[1].blng__Quantity__c = 12;
      usageList[1].QTB_Invoice_Quantity__c = 11;
      usageList[1].blng__MatchingId__c = '1234';
      usageList[1].blng__Status__c = 'Processed';
         usageList[1].QTB_WO_Usage__c=true;
      usageList[1].QTB_Work_Order_ID__c = workOrderList[0].id;
      usageList[2].blng__Quantity__c = 15;
      usageList[2].QTB_Invoice_Quantity__c = 10;   
    //    usageList[2].blng__PreratedAmount__c = 0;
   //  usageList[2].blng__PreratedQuantity__c = 0;
        usageList[2]. blng__UnitPrice__c=100;
        usageList[2].QTB_WO_Usage__c=true;
         usageList[3].blng__Quantity__c = 15;
      usageList[3].QTB_Invoice_Quantity__c = 10;   
   //     usageList[3].blng__PreratedAmount__c = 10;
   //   usageList[3].blng__PreratedQuantity__c =10;
        usageList[3]. blng__UnitPrice__c=100;
        usageList[3].QTB_WO_Usage__c=true;
          //usageList[2].QTB_Work_Order_ID__c = workOrderList[0].id;
      update usageList;
      System.Assert(usageSum[0].blng__Status__c == 'Queued For Invoice');
    }
  }

  static testMethod void testMethod1() {
     List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
     QTB_Bill_Flow_Controller__c prebillrunrecord = new QTB_Bill_Flow_Controller__c();
        insert prebillrunrecord;   
         Date targetDate = date.today();
    QTB_WorkOrderBatch obj = new QTB_WorkOrderBatch('Norway-26th',targetDate,prebillrunrecord.id);
    DataBase.executeBatch(obj);
    Test.stopTest();
    System.assertEquals(false, QTB_WorkOrderBatch.throwExplicitException);
  }
  }
  static testMethod void coverCatchBlock() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
    QTB_WorkOrderBatch.throwExplicitException = true;
     QTB_Bill_Flow_Controller__c prebillrunrecord = new QTB_Bill_Flow_Controller__c();
        insert prebillrunrecord;
        Date targetDate = date.today();
    QTB_WorkOrderBatch obj = new QTB_WorkOrderBatch('Norway-26th',targetDate,prebillrunrecord.id);
    obj.execute(null, null);
    Test.stopTest();
    System.assertEquals(true, QTB_WorkOrderBatch.throwExplicitException);
  }
}
}