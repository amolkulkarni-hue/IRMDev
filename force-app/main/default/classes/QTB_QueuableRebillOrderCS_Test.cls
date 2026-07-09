@isTest(seealldata=false)
private class QTB_QueuableRebillOrderCS_Test {

   static testMethod void testMethod1() {
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
       
			List<opportunity> oppList = QTB_TestDataFactory.createOpps(
				accountList
			);
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
			quoteLinesList[0].SBQQ__ChargeType__c = 'Recurring';
			quoteLinesList[0].SBQQ__BillingType__c = 'Arrears';
			update quoteLinesList;
        ConsumptionSchedule consumption = new ConsumptionSchedule(
				Name = 'dummy',
				RatingMethod = 'Tier',
				Type = 'Range',
				SBQQ__Category__c = 'Rates',
				BillingTerm = 10,
				BillingTermUnit = 'Month'
			);
			insert consumption;

			ConsumptionRate conrate = new ConsumptionRate(
				ProcessingOrder = 1,
				PricingMethod = 'PerUnit',
				LowerBound = 1,
				Price = 100,
				ConsumptionScheduleId = consumption.Id
			);
			insert conrate;

			consumption.IsActive = true;
			update consumption;

			insert new ProductConsumptionSchedule(ConsumptionScheduleId = consumption.Id, ProductId =product[0].id);

            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
				1,
				quoteList[0].Id,
				accountList[0].id
			);
            
          List<orderitem>orderproduct = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].id, quoteLinesList,standardPrice);
        	SBQQ__OrderItemConsumptionSchedule__c ordCS = new SBQQ__OrderItemConsumptionSchedule__c(
				SBQQ__BillingTermUnit__c = 'Month',
				SBQQ__BillingTerm__c = 4,
				SBQQ__Category__c = 'Rates',
				SBQQ__RatingMethod__c = 'Tier',
				SBQQ__Type__c = 'Range',
				SBQQ__ConsumptionSchedule__c = consumption.Id,
				blng__BillingRule__c = billingRule.Id,
				blng__TaxRule__c = taxRule.Id,
				blng__RevenueRecognitionRule__c = revenueRule.Id,
				SBQQ__OrderItem__c = orderProduct[0].Id
			);			
            insert ordCS;
			SBQQ__OrderItemConsumptionRate__c ordRate = new SBQQ__OrderItemConsumptionRate__c(
				SBQQ__ProcessingOrder__c = 1,
				SBQQ__PricingMethod__c = 'PerUnit',
				SBQQ__LowerBound__c = 1,
				SBQQ__Price__c = 100,
				SBQQ__OrderItemConsumptionSchedule__c = ordCS.Id
			);
            insert ordRate; 
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(
        accountList
      );

     orderitem product1=[Select id from orderitem limit 1];
        Order ord=[Select id,OrderNumber from Order Limit 1];
        blng__Invoice__c invoice =[Select id from blng__Invoice__c limit 1];
        map<id,orderitem> orderitemMap = new map<id,orderitem>();
        orderitemMap.put(product1.id,product1);
        QTB_QueuableRebillOrderCS obj = new  QTB_QueuableRebillOrderCS(orderitemMap ,ord.OrderNumber,invoice.id,ord);
          System.enqueueJob(obj);
          Test.stopTest();
 
    }
    }
}