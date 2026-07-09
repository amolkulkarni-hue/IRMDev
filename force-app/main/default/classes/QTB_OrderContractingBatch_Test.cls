/*****************************************************************************************************
* Class      : QTB_OrderContractingBatch_Test
* Author     : Accenture
* Purpose    : This is a Batch class for Sales Contract generation
* Requirement: Git#8. Gitlab US#20219
* Change History: 26/08/2020 
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Virtusa      12/12/2023     Gitlab US #20219 
*******************************************************************************************************/
@isTest(seeAlldata=false)
private class QTB_OrderContractingBatch_Test {
	@testSetup
	static void setup() {
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
		System.runAs(billingUser) {
            QTB_Manage_Contract_Scheduler__c cust = new QTB_Manage_Contract_Scheduler__c();
        	cust.Name = 'FirstRecord';
        	cust.QTB_Scheduler_Hold_Time_In_Min__c = 5;
        	insert cust;
            
			List<account> accountList = QTB_TestDataFactory.createAccounts(1, 'Standard Account');
			blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
			blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
			blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
			List<product2> product = QTB_TestDataFactory.createProducts(1);
			product[0].SBQQ__SubscriptionTerm__c = 10;
			product[0].SBQQ__SubscriptionTerm__c = 4;
			product[0].SBQQ__SubscriptionPricing__c = 'Fixed Price';
			product[0].ProductCode = '01100-1002';
			product[0].blng__BillingRule__c = billingRule.id;
			product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
			product[0].blng__TaxRule__c = taxRule.id;
			update product;
			Id pricebookId = Test.getStandardPricebookId();
			PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
			Test.startTest();
			Order order = new Order(
				AccountId = accountList[0].Id,
				blng__BillingDayOfMonth__c = '27',
				EffectiveDate = Date.today().addDays(-5),
				Status = QTB_Constants.DRAFT_STATUS,
				Pricebook2Id = Test.getStandardPricebookId(),
				blng__InvoiceBatch__c = 'Finland-26th',
				RecordTypeId = QTB_Utils.ORDER_SALES_RECTYPEID,
				QTB_Hold_Contracting__c = false,				
                QTB_Contract_Status__c = 'Contract Pending'
			);
			insert order;
			OrderItem orderProduct = new OrderItem(
				OrderId = order.Id,
				Quantity = 1.00,
				UnitPrice = 10.00,
				PricebookEntryId = standardPrice.Id,
				SBQQ__ChargeType__c = 'One-Time',
				product2id = product[0].Id,
				SBQQ__Activated__c = true,
				SBQQ__OrderedQuantity__c = 1.00,
				blng__BillingRule__c = billingRule.Id,
				blng__RevenueRecognitionRule__c = revenueRule.Id,
				blng__TaxRule__c = taxRule.Id,
				QTB_Ready_Activation__c = true,
				SBQQ__ProductSubscriptionType__c = QTB_Constants.SUBSCRIPTION_TYPE_RENEWABLE,
				SBQQ__SubscriptionType__c = QTB_Constants.SUBSCRIPTION_TYPE_RENEWABLE,
                ServiceDate = Date.today().addDays(5),
				EndDate = System.today().addDays(126)
			);
			insert orderProduct;
			Test.stopTest();
		}
	}
	// testmethod is being depricated so replaced with @IsTest
	/**
	 * This test method tests the contracting of order, when the order matches the start
	 * query of QTB_OrderContractingBatch
	 */
	@IsTest
	static void testOrderContractingPositive() {
		User contextuser = [SELECT Id FROM User WHERE Email = 'testuser@test.example.com'];
		Order order = [
			SELECT
				Id,
				Status,
				QTB_Failed_Contracting_Attempts__c,
				QTB_Hold_Contracting__c,
				SBQQ__Contracted__c,
				QTB_Active_Order_Product_Count__c,
				QTB_No_of_Order_Products__c
			FROM Order
			LIMIT 1
		];
		order.Status = QTB_Constants.ACTIVATED_STATUS;
		order.SBQQ__Contracted__c = false;
		update order; // making sure the order in the test context matches the start query
		System.runAs(contextuser) {
			// this custom setting controls the netrunmethod will be called or not
			// for this test context making the auto scheduler off by setting
			// QTB_Contract_Schedueler_On__c = false
			insert new QTB_Manage_Contract_Scheduler__c(
				Name = 'FirstRecord', 
				QTB_Contract_Schedueler_On__c = false,
				QTB_Scheduler_Hold_Time_In_Min__c = 25
			);
			QTB_OrderContractingBatch obj = new QTB_OrderContractingBatch();
			Test.startTest();
			DataBase.executeBatch(obj);
			// when we want to test a batch class we just need to call the database.execute method
			// no need to individually call each batch method
			QTB_OrderContractingBatch obj1 = new QTB_OrderContractingBatch();
            obj1.throwExplicitException = true;
            DataBase.executeBatch(obj1);
            Test.stopTest();
		}
		//System.assertNotEquals(0, contractedOrdersCount, 'Expected at least one contracted order');
	}
	/*@SuppressWarnings('pmd.ApexUnitTestClassShouldHaveAsserts')
	@IsTest
	static void testScheduleNextRun() {
		User contextuser = [SELECT Id FROM User WHERE Email = 'testuser@test.example.com'];
		Test.startTest();
		System.runAs(contextuser) {
			insert new QTB_Manage_Contract_Scheduler__c(
				Name = 'FirstRecord',
				QTB_Contract_Schedueler_On__c = false,
				QTB_Scheduler_Hold_Time_In_Min__c = 25
			);
			new QTB_OrderContractingBatch().scheduleForNextRun();
		}
		Test.stopTest();
	}*/
}