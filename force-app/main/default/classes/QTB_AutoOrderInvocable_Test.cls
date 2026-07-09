/*****************************************************************************************************
 * Class: QTB_AutoOrderInvocable_Test 
 * Author: Accenture
 * Purpose: This is a test class for QTB_AutoOrderInvocable
 * Change History: 26/3/2021
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture
 *******************************************************************************************************/

@isTest(seealldata=false)
private class QTB_AutoOrderInvocable_Test {
	@IsTest
	static void testUpdateOrderItemDetailsPositive() {
		
		List<Account> accountList = QTB_TestDataFactory.createAccounts(
			1,
			'Billing Account'
		);
		
		List<PriceBook2> testPriceBook = QTB_TestDataFactory.priceBookMethdLst(
			1,
			'Test Price book'
		);

		testPriceBook[0].isActive = true;
		testPriceBook[0].QTB_Country__c = accountList[0].Billing_County__c;
		update testPriceBook;
		
		List<Opportunity> testOpp = QTB_TestDataFactory.createCPQOppsNew(
			accountList,
			'CPQ Billing Opportunity'
		);
		
		List<SBQQ__Quote__c> testquote = QTB_TestDataFactory.createCPQQuotes(
			1,
			testOpp[0].id,
			accountList[0].id,
			true,
			null
		);

		List<Order> orderlist = QTB_TestDataFactory.createSalesOrders(
			1,
			testquote[0].id,
			accountList[0].id,
			testOpp[0].id
		);

		blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
			'Yes'
		);
		blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
			'Yes'
		);
		blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');

		List<product2> product = QTB_TestDataFactory.createProducts(1);
		product[0].SBQQ__SubscriptionTerm__c = 10;
		product[0].SBQQ__SubscriptionTerm__c = 4;
		product[0].SBQQ__SubscriptionPricing__c = 'Fixed Price';
		product[0].ProductCode = '01100-1002';
		product[0].blng__BillingRule__c = billingRule.id;
		product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
		product[0].blng__TaxRule__c = taxRule.id;
		update product[0];

		PricebookEntry standardpricebook = QTB_TestDataFactory.createPricebookEntry(
			product[0]
		);

		PricebookEntry details = [
			SELECT Pricebook2Id, CurrencyIsoCode
			FROM PriceBookEntry
			WHERE Id = :standardpricebook.Id
		];

		orderlist[0].Pricebook2Id = details.Pricebook2Id;
		orderlist[0].CurrencyIsoCode = details.CurrencyIsoCode;
		update orderlist;

		ConsumptionSchedule consumption = new ConsumptionSchedule();
		consumption.Name = 'dummy';
		consumption.RatingMethod = 'Tier';
		consumption.Type = 'Range';
		consumption.SBQQ__Category__c = 'Rates';
		consumption.BillingTerm = 10;
		consumption.BillingTermUnit = 'Month';
		insert consumption;

		ConsumptionRate conrate = new ConsumptionRate();
		conrate.ProcessingOrder = 1;
		conrate.PricingMethod = 'PerUnit';
		conrate.LowerBound = 1;
		conrate.Price = 100;
		conrate.ConsumptionScheduleId = consumption.Id;
		insert conrate;

		consumption.IsActive = true;
		update consumption;

		insert new ProductConsumptionSchedule(
			ConsumptionScheduleId = consumption.Id,
			ProductId = product[0].Id
		);

		List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
			1,
			testquote[0].id,
			accountList[0].id
		);

		List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(
			1,
			testquote[0].id,
			quoteGroupList[0].id,
			product[0].id
		);

		List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(
			orderList[0].Id,
			product[0].Id,
			quoteLinesList,
			standardpricebook
		);

		SBQQ__OrderItemConsumptionSchedule__c ordCS = new SBQQ__OrderItemConsumptionSchedule__c();
		ordCS.SBQQ__BillingTermUnit__c = 'Month';
		ordCS.SBQQ__BillingTerm__c = 4;
		ordCS.SBQQ__Category__c = 'Rates';
		ordCS.SBQQ__RatingMethod__c = 'Tier';
		ordCS.SBQQ__Type__c = 'Range';
		ordCS.SBQQ__ConsumptionSchedule__c = consumption.Id;
		ordCS.blng__BillingRule__c = billingRule.Id;
		ordCS.blng__TaxRule__c = taxRule.Id;
		ordCS.blng__RevenueRecognitionRule__c = revenueRule.Id;
		ordCS.SBQQ__OrderItem__c = orderItemList3[0].Id;
		insert ordCS;

		SBQQ__OrderItemConsumptionRate__c ordRate = new SBQQ__OrderItemConsumptionRate__c(
			SBQQ__ProcessingOrder__c = 1,
			SBQQ__PricingMethod__c = 'PerUnit',
			SBQQ__LowerBound__c = 1,
			SBQQ__Price__c = 100,
			SBQQ__OrderItemConsumptionSchedule__c = ordCS.Id
		);
		insert ordRate;

		Test.startTest();
		QTB_AutoOrderInvocable auto = new QTB_AutoOrderInvocable();
		QTB_AutoOrderInvocable.flowInputs aflow = new QTB_AutoOrderInvocable.flowInputs();

		aflow.billingAccount = accountList[0];
		aflow.oldOrderData = orderlist[0];
		aflow.oldOrderItemData = orderItemList3[0];
		aflow.orderProductStartDate = System.today();
		aflow.orderProductEndDate = System.today() + 5;
		aflow.newOrderCreatedId = orderlist[0].id;
		List<string> codes = new List<string>();
		codes.Add('01100-1002');
		aflow.productCodes = codes;
		List<QTB_AutoOrderInvocable.flowInputs> fl = new List<QTB_AutoOrderInvocable.flowInputs>{
			aflow
		};
		QTB_AutoOrderInvocable.updateOrderItemDetails(fl);
		Test.stopTest();
	}
}