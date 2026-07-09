@IsTest
private class QTB_AmendBillingHelper_Test { 
    private static final id quoteSalesRecTypeId = QTB_Utils.QUOTE_SALES_RECTYPEID;
    private static final id quoteBillRecTypeId = QTB_Utils.QUOTE_BILL_RECTYPEID;
    private static final id contractSalesRecTypeId = QTB_Utils.CONTRACT_SALES_RECTYPEID;
    private static final Id accBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
                                           
	@TestSetup
	static void createTestData() {
		Profile customSysAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
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
            blng__LegalEntity__c LglEntity = QTB_TestDataFactory.createLegalEntity('Singapore');
            LglEntity.CurrencyIsoCode='SGD';
            update LglEntity;
            QTB_Billing_Countries__c setting = new QTB_Billing_Countries__c();
            setting.name = 'Singapore';
            setting.Active__c = true;
            setting.Legal_entity_country__c = 'Singapore';
            insert setting;
            
            //Legal Entity
            blng__LegalEntity__c indiaEntity = new blng__LegalEntity__c();
            indiaEntity.Name = 'Test Legal Entity United States';
            indiaEntity.blng__Active__c = true;
            indiaEntity.blng__Country__c = 'United States';
            indiaEntity.QTB_Type__c = 'Contract';
            //indiaEntity.QTB_Legal_Entity_Number__c = '45000';
            insert indiaEntity;
            
            IM_Country__c im = new IM_Country__c();
            im.Name = 'United States';
            im.CurrencyIsoCode = 'USD';
            im.Region__c = 'North America';
            im.AlternativeNames__c = 'United States';
            im.Iso31662Code__c ='US';
            im.Iso31663Code__c ='USA';        
            insert im;
            
			Account company = new Account(
				Name = 'Test Factory',
				RecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID,
				QTB_Create_Parent_Billing_Account__c = true
			);
			insert company;
            company.QTB_Legal_Entity_Country__c='United States';
        	company.QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
        	update company;
             QTB_TestDataFactory.createBypassSetting(QTB_Constants.TYPE_OPPORTUNITY);
            Opportunity billingOpportunity = new opportunity(
            Name ='testBillingOpportunity',
            accountid = company.id, CloseDate = Date.today(),
            StageName = '1 - Qualification',
            recordTypeId = QTB_Utils.OPP_BILL_RECTYPEID,
            Amount = 500);
            insert billingOpportunity;
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
			Order order = new Order(
				AccountId = company.Id,
				blng__BillingDayOfMonth__c = '27',
				EffectiveDate = Date.today().addDays(5),
				Status = QTB_Constants.DRAFT_STATUS,
				Pricebook2Id = Test.getStandardPricebookId(),
				blng__InvoiceBatch__c = 'Finland-26th',
                OpportunityId = billingOpportunity.id,
				Type = QTB_Constants.ORDER_TYPE_AMENDMENT,
                RecordTypeId = QTB_Utils.ORDER_SALES_RECTYPEID
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
				SBQQ__OrderedQuantity__c = 1.00,
				blng__BillingRule__c = billingRule.Id, 
				blng__RevenueRecognitionRule__c = revenueRule.Id,
				blng__TaxRule__c = taxRule.Id,
                ServiceDate = Date.today().addDays(5),
				EndDate = System.today().addDays(126),
                SBQQ__ProrateMultiplier__c=1,
                QTB_Order_Product_Type__c = 'ReBill',
                blng__TaxCountry__c = 'Singapore'
			);
            insert orderProduct;
			Contract contract = new Contract(
				Status = 'Draft',
				StartDate = Date.today(),
				ContractTerm = 12,
				SBQQ__Order__c = order.Id,
				AccountId = company.Id,
				RecordTypeId = QTB_Utils.CONTRACT_SALES_RECTYPEID
			);
			insert contract;
		}
		Test.stopTest();
	}
	@IsTest
	static void testAmendBillingClonePositive() {
		User contextuser = [SELECT Id FROM User WHERE Email = 'testuser@test.example.com'];
		Test.startTest();
		System.runAs(contextuser) {
			Contract contractUnderTest = [SELECT Id, SBQQ__Order__c FROM Contract LIMIT 1];
			Order orderUnderTest = [
				SELECT
					Id,
					AccountId,
					Status,
					EffectiveDate,
					Pricebook2Id,
					blng__InvoiceBatch__c,
					blng__BillingDayOfMonth__c
				FROM Order Where OpportunityId != NULL
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
                ServiceDate,
				EndDate 
				FROM OrderItem
				WHERE OrderId = :orderUnderTest.Id
			];
			Order clonedOrderUnderTest = orderUnderTest.clone();
			insert clonedOrderUnderTest;
			OrderItem clonedOrderItemUnderTest = orderItemUnderTest.clone();
			clonedOrderItemUnderTest.OrderId = clonedOrderUnderTest.Id;
			clonedOrderItemUnderTest.Quantity = 10;
			clonedOrderItemUnderTest.SBQQ__OrderedQuantity__c = 10;
			insert clonedOrderItemUnderTest;
			orderUnderTest.QTB_Order_OriginatorId__c = clonedOrderUnderTest.Id;
			update orderUnderTest;
			QTB_AmendBillingHelper.amendBillingClone(
				new Map<Id, Contract>{ contractUnderTest.SBQQ__Order__c => contractUnderTest },
				new Map<Id, Id>{ clonedOrderUnderTest.Id => contractUnderTest.SBQQ__Order__c },
				new List<Contract>{ contractUnderTest },
				new Map<Id, Contract>{ contractUnderTest.Id => contractUnderTest }
			);
		}
		Test.stopTest();
	//	System.assertNotEquals(2, [SELECT COUNT() FROM Order], 'Expected order clones to be created');
	}
    
    @isTest
    static void testMethod2(){
         Test.startTest();
        QTB_QueueRenewalBilling.throwExplicitException = true;
        QTB_AmendBillingHelper.collectAllBillingAccounts(null,null);
        QTB_AmendBillingHelper.AmendBillingClone(null,null,null,null);
         QTB_AmendBillingHelper.wait(5);
        Test.stopTest();
    }

   @IsTest
	static void testAmendBillingClonePositive1() {
		User contextuser = [SELECT Id FROM User WHERE Email = 'testuser@test.example.com'];
        Order orderUnderTest = [
				SELECT
					Id,
					AccountId,
					Status,
					EffectiveDate,
					Pricebook2Id,
					blng__InvoiceBatch__c,
                	QTB_OrderCategory__c,
					blng__BillingDayOfMonth__c
				FROM Order Where OpportunityId != NULL
				LIMIT 1
			];
        orderUnderTest.QTB_OrderCategory__c='Evergreen';
        update orderUnderTest;
		Test.startTest();
		System.runAs(contextuser) {
			Contract contractUnderTest = [SELECT Id, SBQQ__Order__c FROM Contract LIMIT 1];
			
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
                SBQQ__ProrateMultiplier__c,
                ServiceDate,
				EndDate 
				FROM OrderItem
				WHERE OrderId = :orderUnderTest.Id
			];
			Order clonedOrderUnderTest = orderUnderTest.clone();
			insert clonedOrderUnderTest;
			OrderItem clonedOrderItemUnderTest = orderItemUnderTest.clone();
			clonedOrderItemUnderTest.OrderId = clonedOrderUnderTest.Id;
			clonedOrderItemUnderTest.Quantity = 10;
			clonedOrderItemUnderTest.SBQQ__OrderedQuantity__c = 10;
			insert clonedOrderItemUnderTest;
			orderUnderTest.QTB_Order_OriginatorId__c = clonedOrderUnderTest.Id;
			update orderUnderTest;
			QTB_AmendBillingHelper.amendBillingClone(
				new Map<Id, Contract>{ contractUnderTest.SBQQ__Order__c => contractUnderTest },
				new Map<Id, Id>{ clonedOrderUnderTest.Id => contractUnderTest.SBQQ__Order__c },
				new List<Contract>{ contractUnderTest },
				new Map<Id, Contract>{ contractUnderTest.Id => contractUnderTest }
			);
		}
		Test.stopTest();
	//	System.assertNotEquals(2, [SELECT COUNT() FROM Order], 'Expected order clones to be created');
	}
}