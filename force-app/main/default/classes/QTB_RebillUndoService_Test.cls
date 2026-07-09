/**
 * This test is responsible for unit tests of QTB_RebillUndoService and
 * QTB_BatchableUsageRemovalService classes.
 * @author Accenture
 * @since 06/07/2021
 * @requirement GitLab # 3483
 */
@IsTest
private class QTB_RebillUndoService_Test {
	@TestSetup
	static void createData() {
		Profile customSysAdmin = [
			SELECT Id
			FROM Profile
			WHERE Name = 'System Administrator'//'IM_Custom Sys Admin'
		];
		// create user
		User billingUser = new User(
			profileId = customSysAdmin.Id,
			LastName = 'last',
			Email = 'testuser@test.example.com',
			Username = 'Testuser@test.example.com' + Crypto.getRandomInteger(),
			CompanyName = 'TEST',
			Title = 'title',
			Alias = 'alias',
			TimeZoneSidKey = 'America/Los_Angeles',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			Country = 'USA',
			MobilePhone = '+1 9999999999',
			Phone = '9999999999'
		);
		insert billingUser;
		PermissionSetLicense cpq = [
			SELECT Id, MasterLabel
			FROM PermissionSetLicense
			WHERE MasterLabel = 'Salesforce CPQ License'
		];
		// assign cpq license
		insert new PermissionSetLicenseAssign(
			AssigneeId = billingUser.Id,
			PermissionSetLicenseId = cpq.Id
		);
		// assign billing user permission
		PermissionSet billingUserPermission = [
			SELECT Id, Name
			FROM PermissionSet
			WHERE Name = 'QTB_Billing_User'
		];
		insert new PermissionSetAssignment(
			AssigneeId = billingUser.id,
			PermissionSetId = billingUserPermission.Id
		);
		Test.startTest();
		System.runAs(billingUser) {
			IM_Country__c finland = new IM_Country__c(
				Iso31662Code__c = 'FI',
				Iso31663Code__c = 'FIN',
				Name = 'Finland',
				Region__c = 'Europe'
			);
			insert finland;
			insert new IM_Alternative_Country_Name__c(
				IM_Country__c = finland.Id,
				Alternative_Name__c = finland.Name
			);
			Account company = new Account(
				Name = 'Test Factory',
				BillingCountry = 'Finland',
				BillingPostalCode = '681000',
				ShippingCountry = 'Finland'
			);
			insert company;
			blng__BillingRule__c billingRule = new blng__BillingRule__c(
				Name = 'Factory Billing Rule',
				blng__Active__c = true,
				blng__GenerateInvoices__c = 'Yes',
				blng__InitialBillingTrigger__c = 'Order Product Activation Date'
			);
			insert billingRule;
			blng__TaxRule__c taxRule = new blng__TaxRule__c(
				Name = 'Factory Tax Rule',
				blng__Active__c = true,
				blng__TaxableYesNo__c = 'Yes'
			);
			insert taxRule;
			blng__RevenueRecognitionRule__c revenueRule = new blng__RevenueRecognitionRule__c(
				Name = 'Test Recognition Rule',
				blng__Active__c = true,
				blng__CreateRevenueSchedule__c = 'Yes'
			);
			insert revenueRule;
			ConsumptionSchedule consumption = new ConsumptionSchedule(
				Name = 'dummy',
				RatingMethod = 'Tier',
				Type = 'Range',
				SBQQ__Category__c = 'Rates',
				BillingTerm = 10,
				BillingTermUnit = 'Month',
				blng__BillingRule__c = billingRule.Id,
				blng__TaxRule__c = taxRule.Id,
				blng__RevenueRecognitionRule__c = revenueRule.Id
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

			Product2 product = new Product2(
				Name = 'Rebill Product',
				isActive = true,
				SBQQ__SubscriptionPricing__c = 'Fixed Price',
				SBQQ__ChargeType__c = 'Recurring',
				SBQQ__BillingType__c = 'Arrears',
				SBQQ__BillingFrequency__c = 'Monthly',
				SBQQ__SubscriptionTerm__c = 1,
				blng__BillingRule__c = billingRule.Id,
				blng__TaxRule__c = taxRule.Id,
				blng__RevenueRecognitionRule__c = revenueRule.Id
			);
			insert product;
			insert new ProductConsumptionSchedule(
				ConsumptionScheduleId = consumption.Id,
				ProductId = product.Id
			);
			PricebookEntry pbe = new PricebookEntry(
				Pricebook2Id = Test.getStandardPricebookId(),
				Product2Id = product.Id,
				UnitPrice = 10,
				IsActive = true
			);
			insert pbe;
			Order order = new Order(
				AccountId = company.Id,
				blng__BillingDayOfMonth__c = '27',
				EffectiveDate = Date.today().addDays(5),
				Status = QTB_Constants.DRAFT_STATUS,
				Pricebook2Id = Test.getStandardPricebookId(),
                QTB_Legal_Entity_Country__c = 'India',
				blng__InvoiceBatch__c = 'Finland-26th'
			);
			insert order;
			OrderItem orderProduct = new OrderItem(
				OrderId = order.Id,
				Quantity = 1.00,
				UnitPrice = 10.00,
				PricebookEntryId = pbe.Id,
				SBQQ__ChargeType__c = 'Recurring',
				SBQQ__BillingType__c = 'Arrears',
				SBQQ__BillingFrequency__c = 'Monthly',
				product2id = product.Id,
				SBQQ__Activated__c = true,
				blng__BillingRule__c = billingRule.Id,
				blng__RevenueRecognitionRule__c = revenueRule.Id,
				blng__TaxRule__c = taxRule.Id,
				QTB_Ready_Activation__c = true,
				SBQQ__DefaultSubscriptionTerm__c = 1,
				ServiceDate = Date.today().addDays(5),
                blng__TaxCountry__c = 'India',
				EndDate = Date.today().addDays(125)
			);
			insert orderProduct;
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
				SBQQ__OrderItem__c = orderProduct.Id
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
			order.Status = 'Activated';
			update order;
            blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
			blng__Invoice__c invoice = new blng__Invoice__c(
				blng__Account__c = company.Id,
				blng__InvoiceStatus__c = 'Draft'
			);
			insert invoice;
			/*blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c(
				Name = product.Name,
				blng__Invoice__c = invoice.Id,
				blng__Product__c = product.Id,
				blng__OrderProduct__c = orderProduct.Id,
				blng__InvoiceLineStatus__c = 'Draft',
				blng__Quantity__c = 10,
				blng__UnitPrice__c = 5,
				blng__TaxPercentageApplied__c = 24,
				blng__Subtotal__c = 50,
				blng__TotalAmount__c = 50 * 0.24,
				blng__StartDate__c = Date.today().addDays(-30),
				blng__EndDate__c = Date.today().addDays(-1),
                blng__TaxCountry__c = 'India',
                blng__TaxState__c = 'TN',
                blng__TaxCity__c = 'Chennai',
                blng__TaxZipCode__c = '500032',
                blng__LegalEntity__c = indiaEntity.id,
                blng__TaxRule__c = taxRule.id,
                QTB_Inc_Quantity__c = 10,
                QTB_Taxable_Amount__c = 10
			);
			insert invoiceLine;*/
			// SBQQ.TriggerControl.disable();
			// invoice.blng__InvoiceStatus__c = 'Posted';
			// update invoice;
		}
		Test.stopTest();
	}

	@IsTest
	static void testRemoveInvoicesPositive() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		Map<Id, blng__Invoice__c> invoiceById = new Map<Id, blng__Invoice__c>(
			[SELECT Id FROM blng__Invoice__c]
		);
		System.assert(
			invoiceById.values().size() >= 1,
			'Expected a single invoice in the database'
		);
		Test.startTest();
		System.runAs(contextuser) {
			new QTB_RebillUndoService()
				.removeInvoices(new List<Id>(invoiceById.keySet()));
		}
		Test.stopTest();
		System.assertNotEquals(
			invoiceById.keySet().size(),
			[SELECT COUNT() FROM blng__Invoice__c],
			'Expected some invoices to be deleted from the database'
		);
	}

	@IsTest
	static void testGetOrdersPositive() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		Map<Id, blng__Invoice__c> invoiceById = new Map<Id, blng__Invoice__c>(
			[SELECT Id FROM blng__Invoice__c]
		);
		Map<Id, Order> ordersById = new Map<Id, Order>([SELECT Id FROM Order]);
		List<Id> orderIdsReturned;
		Test.startTest();
		System.runAs(contextuser) {
			orderIdsReturned = new QTB_RebillUndoService()
				.getOrders(new List<Id>(invoiceById.keySet()));
		}
		Test.stopTest();
		System.assert(
			ordersById.keySet().containsAll(orderIdsReturned),
			'Expected all order ids to be returned'
		);
	}

	@IsTest
	static void testGetOrderItemConsumptionSchedulesPositive() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		Map<Id, Order> ordersById = new Map<Id, Order>([SELECT Id FROM Order]);
		List<SBQQ__OrderItemConsumptionSchedule__c> schedulesReturned;
		Test.startTest();
		System.runAs(contextuser) {
			schedulesReturned = new QTB_RebillUndoService()
				.getOrderItemConsumptionSchedules(
					new List<Id>(ordersById.keySet())
				);
		}
		Test.stopTest();
		System.assert(
			schedulesReturned <> null,
			'Expected some consumption schedules to be returned'
		);
	}

	@IsTest
	static void testGetUsageSummariesPositive() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		Map<Id, Order> ordersById = new Map<Id, Order>([SELECT Id FROM Order]);
		List<blng__UsageSummary__c> usageSummariesReturned;
		Test.startTest();
		System.runAs(contextuser) {
			usageSummariesReturned = new QTB_RebillUndoService()
				.getUsageSummaries(new List<Id>(ordersById.keySet()));
		}
		Test.stopTest();
		System.assert(
			usageSummariesReturned <> null,
			'Expected some usage summaries to be returned'
		);
	}

	@IsTest
	static void testDeactivateOrdersPositive() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		Map<Id, Order> activeOrdersById = new Map<Id, Order>(
			[SELECT Id FROM Order WHERE Status = 'Activated']
		);
		System.assertNotEquals(
			0,
			activeOrdersById.keySet().size(),
			'Expected at least one activated order'
		);
		Test.startTest();
		System.runAs(contextuser) {
			new QTB_RebillUndoService()
				.deactivateOrders(new List<Id>(activeOrdersById.keySet()));
		}
		Test.stopTest();
		System.assert(
			activeOrdersById.keySet().size() ==
			[SELECT COUNT() FROM Order WHERE Status = 'Draft'],
			'Expected activated orders to be updated as draft'
		);
	}

	@IsTest
	static void testRemoveOrdersPositive() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		Map<Id, Order> activeOrdersById = new Map<Id, Order>(
			[SELECT Id FROM Order WHERE Status = 'Activated']
		);
		System.assertNotEquals(
			0,
			activeOrdersById.keySet().size(),
			'Expected at least one activated order'
		);
		Test.startTest();
		System.runAs(contextuser) {
			QTB_RebillUndoService rebillUndoService = new QTB_RebillUndoService();
			rebillUndoService.removeUsageSummaries(
				rebillUndoService.getUsageSummaries(
					new List<Id>(activeOrdersById.keySet())
				)
			);
			rebillUndoService.deactivateOrders(
				new List<Id>(activeOrdersById.keySet())
			);
			rebillUndoService.removeOrders(
				new List<Id>(activeOrdersById.keySet())
			);
		}
		Test.stopTest();
		System.assert(
			[SELECT COUNT() FROM Order WHERE Status = 'Draft'] == 0,
			'Expected all activated orders to be deleted'
		);
	}

	@IsTest
	static void testRemoveUsagesPositive() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		List<OrderItem> orderProducts = [
			SELECT Id, OrderId, Order.AccountId
			FROM OrderItem
			LIMIT 1
		];
		blng__UsageSummary__c usageSummary = new blng__UsageSummary__c(
			blng__Order__c = orderProducts.get(0).OrderId,
			blng__Account__c = orderProducts.get(0).Order.AccountId,
			blng__OrderProduct__c = orderProducts.get(0).Id,
			blng__SummaryEndDate__c = System.today(),
			blng__SummaryStartDate__c = System.today().addDays(30),
			blng__MatchingId__c = '12345',
			blng__Status__c = 'Queued For Invoice',
			blng__InvoiceRunProcessingStatus__c = 'Pending Billing'
		);
		insert usageSummary;
		blng__Usage__c usage = new blng__Usage__c(
			blng__MatchingId__c = usageSummary.blng__MatchingId__c,
			blng__StartDateTime__c = System.now(),
			blng__EndDateTime__c = System.now(),
			blng__Quantity__c = 10,
            blng__UsageSummary__c=usageSummary.id
		);
		insert usage;
		Test.startTest();
		System.runAs(contextuser) {
			new QTB_RebillUndoService()
				.removeUsages(new List<blng__Usage__c>{ usage });
		}
		Test.stopTest();
		System.assert(
			[SELECT COUNT() FROM blng__Usage__c] == 0,
			'Expected the usage to be deleted'
		);
	}

	@IsTest
	static void testRemoveOrderItemConsumptionSchedules() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		List<SBQQ__OrderItemConsumptionSchedule__c> schedules = [
			SELECT Id
			FROM SBQQ__OrderItemConsumptionSchedule__c
		];
		System.assert(
			schedules.size() > 0,
			'Expected at least one consumption schedule under order product'
		);
		Test.startTest();
		System.runAs(contextuser) {
			new QTB_RebillUndoService()
				.removeOrderItemConsumptionSchedules(schedules);
		}
		Test.stopTest();
		System.assert(
			[SELECT COUNT() FROM SBQQ__OrderItemConsumptionSchedule__c] == 0,
			'Expected the consumption schedules to be deleted'
		);
	}

	@IsTest
	static void testRemoveUsageSummariesPositive() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		List<OrderItem> orderProducts = [
			SELECT Id, OrderId, Order.AccountId
			FROM OrderItem
			LIMIT 1
		];
		blng__UsageSummary__c usageSummary = new blng__UsageSummary__c(
			blng__Order__c = orderProducts.get(0).OrderId,
			blng__Account__c = orderProducts.get(0).Order.AccountId,
			blng__OrderProduct__c = orderProducts.get(0).Id,
			blng__SummaryEndDate__c = System.today(),
			blng__SummaryStartDate__c = System.today().addDays(30),
			blng__MatchingId__c = '12345',
			blng__Status__c = 'Queued For Invoice',
			blng__InvoiceRunProcessingStatus__c = 'Pending Billing'
		);
		insert usageSummary;
		Test.startTest();
		System.runAs(contextuser) {
			new QTB_RebillUndoService()
				.removeUsageSummaries(
					new List<blng__UsageSummary__c>{ usageSummary }
				);
		}
		Test.stopTest();
		System.assert(
			[
				SELECT COUNT()
				FROM blng__UsageSummary__c
				WHERE Id = :usageSummary.Id
			] == 0,
			'Expected the usage summaries to be deleted'
		);
	}

	@IsTest
	static void testRemoveUsagesNegativeWithEmptyInput() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		List<OrderItem> orderProducts = [
			SELECT Id, OrderId, Order.AccountId
			FROM OrderItem
			LIMIT 1
		];
		blng__UsageSummary__c usageSummary = new blng__UsageSummary__c(
			blng__Order__c = orderProducts.get(0).OrderId,
			blng__Account__c = orderProducts.get(0).Order.AccountId,
			blng__OrderProduct__c = orderProducts.get(0).Id,
			blng__SummaryEndDate__c = System.today(),
			blng__SummaryStartDate__c = System.today().addDays(30),
			blng__MatchingId__c = '12345',
			blng__Status__c = 'Queued For Invoice',
			blng__InvoiceRunProcessingStatus__c = 'Pending Billing'
		);
		insert usageSummary;
		blng__Usage__c usage = new blng__Usage__c(
			blng__MatchingId__c = usageSummary.blng__MatchingId__c,
			blng__StartDateTime__c = System.now(),
			blng__EndDateTime__c = System.now(),
			blng__Quantity__c = 10
		);
		insert usage;
		Test.startTest();
		System.runAs(contextuser) {
			new QTB_RebillUndoService()
				.removeUsages(new List<blng__Usage__c>());
		}
		Test.stopTest();
		System.assert(
			[SELECT COUNT() FROM blng__Usage__c] > 0,
			'Expected no usages to be deleted'
		);
	}

	@IsTest
	static void testEnqueActionRemoveInvoices() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		Test.startTest();
		System.runAs(contextuser) {
			System.enqueueJob(
				new QTB_RebillUndoService()
					.setAction('removeInvoices')
					.setParam('invoiceIds', new List<Id>())
			);
		}
		Test.stopTest();
		System.assert(
			[SELECT COUNT() FROM blng__Invoice__c] > 0,
			'Expected no invoices to be deleted'
		);
	}
	@IsTest
	static void testEnqueActionRemoveUsages() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		Test.startTest();
		System.runAs(contextuser) {
			System.enqueueJob(
				new QTB_RebillUndoService()
					.setAction('removeUsages')
					.setParam('orderIds', new List<Id>())
			);
		}
		Test.stopTest();
         System.assertEquals(0,[SELECT COUNT() FROM blng__Usage__c]); 
        
	}
	@IsTest
	static void testEnqueActionRemoveSchedules() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		Test.startTest();
		System.runAs(contextuser) {
			System.enqueueJob(
				new QTB_RebillUndoService()
					.setAction('removeConsumptionSchedules')
					.setParam('orderIds', new List<Id>())
			);
		}
		Test.stopTest();
		System.assert(
			[SELECT COUNT() FROM SBQQ__OrderItemConsumptionSchedule__c] > 0,
			'Expected no consumption schedules to be deleted'
		);
	}
	@IsTest
	static void testEnqueActionRemoveUsageSummaries() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		Test.startTest();
		System.runAs(contextuser) {
			System.enqueueJob(
				new QTB_RebillUndoService()
					.setAction('removeUsageSummaries')
					.setParam('orderIds', new List<Id>())
			);
		}
		Test.stopTest();
        System.assert(
			[SELECT COUNT() FROM blng__UsageSummary__c] > 0,
			'Expected no usage summaries to be deleted'
		);
	}
	@IsTest
	static void testEnqueActionRemoveOrders() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		Test.startTest();
		System.runAs(contextuser) {
			System.enqueueJob(
				new QTB_RebillUndoService()
					.setAction('removeOrders')
					.setParam('orderIds', new List<Id>())
			);
		}
		Test.stopTest();
		System.assert(
			[SELECT COUNT() FROM Order] > 0,
			'Expected no orders to be deleted'
		);
	}
    
    @IsTest
	static void testEnqueActionRemoveOrders1() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		Test.startTest();
		System.runAs(contextuser) {
    		List<Order> orders = [SELECT Id FROM Order]; // This still returns List<Order>
            List<Id> orderIds = new List<Id>();
            for (Order ord : orders) {
                orderIds.add(ord.Id);
            }
			Database.executeBatch(new QTB_BatchableUsageRemovalService(orderIds));
        }
		Test.stopTest();
	}
}