@IsTest
private class QTB_CreditRebillLinkerService_Test {
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
			QTB_Manage_Contract_Scheduler__c cust = new QTB_Manage_Contract_Scheduler__c();
        	cust.Name = 'FirstRecord';
        	cust.QTB_Scheduler_Hold_Time_In_Min__c = 5;
        	insert cust;
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
            blng__LegalEntity__c LglEntity = QTB_TestDataFactory.createLegalEntity('Singapore');
            LglEntity.CurrencyIsoCode='SGD';
            update LglEntity;
            QTB_Billing_Countries__c setting = new QTB_Billing_Countries__c();
            setting.name = 'Singapore';
            setting.Active__c = true;
            setting.Legal_entity_country__c = 'Singapore';
            insert setting;
			Account company = new Account(
				Name = 'Test Factory',
				BillingCountry = 'Finland',
				BillingPostalCode = '681000',
				ShippingCountry = 'Finland',
                QTB_Legal_Entity_Country__c='Finland'
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
				SBQQ__ChargeType__c = 'Recurring',
				SBQQ__BillingType__c = 'Arrears',
				SBQQ__BillingFrequency__c = 'Monthly',
				SBQQ__SubscriptionTerm__c = 1,
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
			Order order = new Order(
				AccountId = company.Id,
				blng__BillingDayOfMonth__c = '27',
				EffectiveDate = Date.today().addDays(5),
				Status = QTB_Constants.DRAFT_STATUS,
				Pricebook2Id = Test.getStandardPricebookId(),
				blng__InvoiceBatch__c = 'Finland-26th'
			);
			insert order;
            order.QTB_Legal_Entity_Country__c = 'Singapore';
            order.QTB_OrderCategory__c = 'Rebill';
            database.update(order);
			OrderItem orderProduct = new OrderItem(
				OrderId = order.Id,
				Quantity = 1.00,
				UnitPrice = 10.00,
				PricebookEntryId = pbe.Id,
				SBQQ__ChargeType__c = 'One-Time',
				product2id = product.Id,
				SBQQ__Activated__c = true,
				blng__BillingRule__c = billingRule.Id,
				blng__RevenueRecognitionRule__c = revenueRule.Id,
				blng__TaxRule__c = taxRule.Id,
				QTB_Ready_Activation__c = true,
				SBQQ__DefaultSubscriptionTerm__c = 1,
				ServiceDate = Date.today().addDays(5),
				EndDate = System.today().addDays(126),
                QTB_Order_Product_Type__c = 'ReBill',
                blng__TaxCountry__c = 'Singapore'
			);
			insert orderProduct;
			order.Status = 'Activated';
			update order;
			blng__Invoice__c invoice = new blng__Invoice__c(
				blng__Account__c = company.Id,
				blng__InvoiceStatus__c = 'Draft'
			);
			insert invoice;
            blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
			blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c(
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
			insert invoiceLine;
			SBQQ.TriggerControl.disable();
			invoice.blng__InvoiceStatus__c = 'Posted';
			update invoice;
			Order rebillorder = order.clone(false, false, false, false);
			rebillorder.Status = 'Draft';
			rebillorder.QTB_OriginalRebillInvoice__c = invoice.Id;
			insert rebillorder;
			OrderItem rebillorderProduct = orderProduct.clone(
				false,
				false,
				false,
				false
			);
			rebillorderProduct.OrderId = rebillorder.Id;
			insert rebillorderProduct;
			rebillorder.Status = 'Activated';
			update rebillorder;
			company.QTB_Bill_Cycle_Day__c = 'Rebill Run';
			update company;
			blng__Invoice__c rebillinvoice = invoice.clone(
				false,
				false,
				false,
				false
			);
            rebillinvoice.QTB_Bill_Cycle_Day__c = 'Rebill Run';
			insert rebillinvoice;
			blng__InvoiceLine__c rebillinvoiceline = invoiceLine.clone(
				false,
				false,
				false,
				false
			);
			rebillinvoiceline.blng__Invoice__c = rebillinvoice.Id;
			rebillinvoiceline.blng__OrderProduct__c = rebillorderProduct.Id;
			insert rebillinvoiceline;
		}
		Test.stopTest();
	}

	@IsTest
	static void testGetRebilledInvoiceIdByRebillingInvoiceId() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		List<blng__Invoice__c> invoices = [
			SELECT Id, QTB_Bill_Cycle_Day__c
			FROM blng__Invoice__c
			WHERE QTB_Bill_Cycle_Day__c = 'Rebill Run'
		];
		System.assert(
			invoices.size() > 0,
			'Expected at least one rebill invoice'
		);
		Map<Id, Id> mapUnderTest;
		Test.startTest();
		System.runAs(contextuser) {
			mapUnderTest = new QTB_CreditRebillLinkerService()
				.getRebilledInvoiceIdByRebillingInvoiceId(
					new List<Id>{ invoices.get(0).Id }
				);
		}
		Test.stopTest();
		System.assert(mapUnderTest <> null, 'Expected the map to be populated');
		System.assert(
			!mapUnderTest.isEmpty(),
			'Expected the map to have some entries'
		);
		System.assert(
			mapUnderTest.get(invoices.get(0).Id) <> null,
			'Expected the rebill invoice to have a rebilled invoice'
		);
	}

	@IsTest
	static void testGetRebillCreditNoteByRebilledInvoiceId() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		List<blng__Invoice__c> invoices = [
			SELECT Id, QTB_Bill_Cycle_Day__c, blng__Account__c
			FROM blng__Invoice__c
			WHERE QTB_Bill_Cycle_Day__c != 'Rebill Run'
		];
		System.assert(
			invoices.size() > 0,
			'Expected at least one rebill invoice'
		);
		blng__CreditNote__c creditNote = new blng__CreditNote__c(
			blng__Account__c = invoices.get(0).blng__Account__c,
			blng__RelatedInvoice__c = invoices.get(0).Id,
			blng__CreditNoteDate__c = System.today(),
			blng__EffectiveTaxDate__c = System.today(),
			QTB_For_Rebill__c = true
		);
		insert creditNote;
		Map<Id, Id> mapUnderTest;
		Test.startTest();
		System.runAs(contextuser) {
			mapUnderTest = new QTB_CreditRebillLinkerService()
				.getRebillCreditNoteByRebilledInvoiceId(
					new List<Id>{ invoices.get(0).Id }
				);
		}
		Test.stopTest();
		System.assert(mapUnderTest <> null, 'Expected the map to be populated');
		System.assert(
			!mapUnderTest.isEmpty(),
			'Expected the map to have some entries'
		);
		System.assertEquals(
			creditNote.Id,
			mapUnderTest.get(invoices.get(0).Id),
			'Expected the rebill invoice to have a rebill credit note'
		);
	}

	@IsTest
	static void testEnqueueCreditRebillLinkerService() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		List<blng__Invoice__c> invoices = [
			SELECT Id, QTB_Bill_Cycle_Day__c, blng__Account__c
			FROM blng__Invoice__c
			WHERE QTB_Bill_Cycle_Day__c != 'Rebill Run'
		];
		System.assert(
			invoices.size() > 0,
			'Expected at least one rebill invoice'
		);
		blng__CreditNote__c creditNote = new blng__CreditNote__c(
			blng__Account__c = invoices.get(0).blng__Account__c,
			blng__RelatedInvoice__c = invoices.get(0).Id,
			blng__CreditNoteDate__c = System.today(),
			blng__EffectiveTaxDate__c = System.today(),
			QTB_For_Rebill__c = true
		);
		insert creditNote;
		List<blng__Invoice__c> rebillinvoices = [
			SELECT Id, QTB_Bill_Cycle_Day__c, blng__Account__c
			FROM blng__Invoice__c
			WHERE QTB_Bill_Cycle_Day__c = 'Rebill Run'
		];
		Test.startTest();
		System.runAs(contextuser) {
			System.enqueueJob(
				new QTB_CreditRebillLinkerService(
					new List<Id>{ rebillinvoices.get(0).Id }
				)
			);
		}
		Test.stopTest();
		System.assertEquals(
			rebillinvoices.get(0).Id,
			[
				SELECT Id, QTB_Rebill_Invoice__c
				FROM blng__CreditNote__c
				WHERE Id = :creditNote.Id
			]
			.QTB_Rebill_Invoice__c,
			'Expected the rebill invoice id on credit note to match'
		);
	}

	@IsTest
	static void testInitiateLinkerFromInvoiceTrigger() {
		User contextuser = [
			SELECT Id
			FROM User
			WHERE Email = 'testuser@test.example.com'
		];
		List<blng__Invoice__c> invoices = [
			SELECT Id, QTB_Bill_Cycle_Day__c, blng__Account__c
			FROM blng__Invoice__c
			WHERE QTB_Bill_Cycle_Day__c != 'Rebill Run'
		];
		System.assert(
			invoices.size() > 0,
			'Expected at least one rebill invoice'
		);
		blng__CreditNote__c creditNote = new blng__CreditNote__c(
			blng__Account__c = invoices.get(0).blng__Account__c,
			blng__RelatedInvoice__c = invoices.get(0).Id,
			blng__CreditNoteDate__c = System.today(),
			blng__EffectiveTaxDate__c = System.today()
		);
		insert creditNote;
		List<Account> accounts = [
			SELECT Id, QTB_Bill_Cycle_Day__c
			FROM Account
			WHERE QTB_Bill_Cycle_Day__c = 'Rebill Run'
			LIMIT 1
		];
		System.assert(
			accounts.size() > 0,
			'Expected at least one account with bill cycle day set as rebill run'
		);
		Test.startTest();
		System.runAs(contextuser) {
			insert new blng__Invoice__c(
				blng__Account__c = accounts.get(0).Id,
				blng__InvoiceStatus__c = 'Draft',
				QTB_Bill_Cycle_Day__c = 'Rebill Run'
			);
		}
		Test.stopTest();
	}
}