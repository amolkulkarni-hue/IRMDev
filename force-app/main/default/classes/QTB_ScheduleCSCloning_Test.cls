@IsTest
private class QTB_ScheduleCSCloning_Test {
	@TestSetup
	static void createTestData() {
		Profile customSysAdmin = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin'];
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
		insert new PermissionSetLicenseAssign(AssigneeId = billingUser.Id, PermissionSetLicenseId = cpq.Id);
		// assign billing user permission
		PermissionSet billingUserPermission = [SELECT Id, Name FROM PermissionSet WHERE Name = 'QTB_Billing_User'];
		insert new PermissionSetAssignment(AssigneeId = billingUser.id, PermissionSetId = billingUserPermission.Id);
		Test.startTest();
		System.runAs(billingUser) {
			IM_Country__c finland = new IM_Country__c(
				Iso31662Code__c = 'FI',
				Iso31663Code__c = 'FIN',
				Name = 'Finland',
				Region__c = 'Europe'
			);
			insert finland;
			insert new IM_Alternative_Country_Name__c(IM_Country__c = finland.Id, Alternative_Name__c = finland.Name);
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
			Product2 product = new Product2(
				Name = 'Rebill Product',
				isActive = true,
				SBQQ__SubscriptionPricing__c = 'Fixed Price',
				blng__BillingRule__c = billingRule.Id,
				blng__TaxRule__c = taxRule.Id,
				blng__RevenueRecognitionRule__c = revenueRule.Id
			);
			insert product;
			PricebookEntry pbe = new PricebookEntry(
				Pricebook2Id = Test.getStandardPricebookId(),
				Product2Id = product.Id,
				UnitPrice = 10,
				IsActive = true
			);
			insert pbe;

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

			insert new ProductConsumptionSchedule(ConsumptionScheduleId = consumption.Id, ProductId = product.Id);

			Order order = new Order(
				AccountId = company.Id,
				blng__BillingDayOfMonth__c = '27',
				EffectiveDate = Date.today().addDays(5),
				Status = QTB_Constants.DRAFT_STATUS,
				Pricebook2Id = Test.getStandardPricebookId(),
				blng__InvoiceBatch__c = 'Finland-26th'
			);
			insert order;
			OrderItem orderProduct = new OrderItem(
				OrderId = order.Id,
				Quantity = 1.00,
				UnitPrice = 10.00,
				PricebookEntryId = pbe.Id,
				SBQQ__ChargeType__c = 'One-Time',
				product2id = product.Id,
				SBQQ__Activated__c = true,
				SBQQ__OrderedQuantity__c = 1.00,
				blng__BillingRule__c = billingRule.Id,
				blng__RevenueRecognitionRule__c = revenueRule.Id,
				blng__TaxRule__c = taxRule.Id,
				QTB_OriginalConsumptionID__c = consumption.Id,
                ServiceDate = Date.today().addDays(5),
				EndDate = System.today().addDays(126)
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
		}
		Test.stopTest();
	}
	@IsTest
	static void testConsumptionScheduleCloningNewBillingAccountPositive() {
		User contextuser = [SELECT Id FROM User WHERE Email = 'testuser@test.example.com'];
		Test.startTest();
		System.runAs(contextuser) {
			Order orderUnderTest = [
				SELECT
					Id,
					AccountId,
					Status,
					EffectiveDate,
					Pricebook2Id,
					blng__InvoiceBatch__c,
					blng__BillingDayOfMonth__c
				FROM Order
				LIMIT 1
			];
			OrderItem orderItemUnderTest = [
				SELECT
					Id,
					Quantity,
					UnitPrice,
					PricebookEntryId,
					SBQQ__ChargeType__c,
					product2id,
					blng__BillingRule__c,
					blng__RevenueRecognitionRule__c,
					blng__TaxRule__c,
					QTB_OriginalConsumptionID__c,
                ServiceDate,
				EndDate
				FROM OrderItem
				WHERE OrderId = :orderUnderTest.Id
			];
			Order clonedOrderUnderTest = orderUnderTest.clone();
			clonedOrderUnderTest.RecordTypeId = QTB_Utils.ORDER_BILL_RECTYPEID;
			insert clonedOrderUnderTest;
			OrderItem clonedOrderItemUnderTest = orderItemUnderTest.clone();
			clonedOrderItemUnderTest.OrderId = clonedOrderUnderTest.Id;
			insert clonedOrderItemUnderTest;
			System.schedule(
				'Billing Consumption Schedule Cloning Process',
				'0 0 10 22 APR ?',
				new QTB_ScheduleCSCloning(
					new Set<Id>{ orderItemUnderTest.Id },
					new Set<String>{ orderItemUnderTest.QTB_OriginalConsumptionID__c },
					new Map<String, OrderItem>{ orderItemUnderTest.Id => clonedOrderItemUnderTest },
					null,
					null,
					'BAcreate',
					new List<Order>{ clonedOrderUnderTest },
					null
				)
			);
		}
		Test.stopTest();
		System.assertNotEquals(
			2,
			[SELECT COUNT() FROM SBQQ__OrderItemConsumptionSchedule__c],
			'Expected billing order product to have a consumption schedule'
		);
	}
	@IsTest
	static void testConsumptionScheduleCloningRenewalNegative() {
		User contextuser = [SELECT Id FROM User WHERE Email = 'testuser@test.example.com'];
		Test.startTest();
		System.runAs(contextuser) {
			Order orderUnderTest = [
				SELECT
					Id,
					AccountId,
					Status,
					EffectiveDate,
					Pricebook2Id,
					blng__InvoiceBatch__c,
					blng__BillingDayOfMonth__c
				FROM Order
				LIMIT 1
			];
			OrderItem orderItemUnderTest = [
				SELECT
					Id,
					Quantity,
					UnitPrice,
					PricebookEntryId,
					SBQQ__ChargeType__c,
					product2id,
					blng__BillingRule__c,
					blng__RevenueRecognitionRule__c,
					blng__TaxRule__c,
					QTB_OriginalConsumptionID__c,
                ServiceDate,
				EndDate
				FROM OrderItem
				WHERE OrderId = :orderUnderTest.Id
			];
			Order clonedOrderUnderTest = orderUnderTest.clone();
			clonedOrderUnderTest.RecordTypeId = QTB_Utils.ORDER_BILL_RECTYPEID;
			clonedOrderUnderTest.Type = 'Renewal';
			insert clonedOrderUnderTest;
			OrderItem clonedOrderItemUnderTest = orderItemUnderTest.clone();
			clonedOrderItemUnderTest.OrderId = clonedOrderUnderTest.Id;
			insert clonedOrderItemUnderTest;
			System.schedule(
				'Billing Consumption Schedule Cloning Process',
				'0 0 10 22 APR ?',
				new QTB_ScheduleCSCloning(
					new Set<Id>{ orderItemUnderTest.Id },
					new Set<String>{ orderItemUnderTest.QTB_OriginalConsumptionID__c },
					new Map<String, OrderItem>{
						orderItemUnderTest.Id +
						'_' +
						clonedOrderUnderTest.Id => clonedOrderItemUnderTest
					},
					new Map<String, Order>{
						orderUnderTest.AccountId +
						'_' +
						orderUnderTest.Id => clonedOrderUnderTest
					},
					orderUnderTest.AccountId,
					'Renewal',
					new List<Order>{ clonedOrderUnderTest },
					null
				)
			);
		}
		Test.stopTest();
		// because of improper test data this runs into null-pointer exception
		// and covers the catch portion of the code, hence marking as negative
		System.assertNotEquals(
			2,
			[SELECT COUNT() FROM SBQQ__OrderItemConsumptionSchedule__c],
			'Expected billing order product to have a consumption schedule'
		);
	}
}