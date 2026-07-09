@isTest
private class M4AggregateStorageRevenueBatchTest {
    /*
	static Map<Id, Id> imgaToCA = new Map<Id, Id>();
	static Map<Id, List<Id>> pbmToBms = new Map<Id, List<Id>>();
	static Integer startPeriod = Integer.valueOf(label.BoB_M4_End_Period);
    static Integer invalidPeriod = Math.mod(startPeriod + 1, 12);
    static Integer startYear = Integer.valueOf(label.current_Commission_Year);
    

	static List<Account> setupIMGAccounts(Integer num) 
	{
		List<User> reps;
		System.runAs(TestingUtils.ADMIN_USER) 
		{
			reps = IMGAUtilities.insertSalesReps();
		}
		return IMGAUtilities.instantiateImgaAccounts(num, reps[0].Id, reps[1].Id);
	}

	static List<IM_Customer_Account__c> setupCustomerAccounts(List<Account> imgaccounts)
	{
		List<IM_Customer_Account__c> customerAccounts = new List<IM_Customer_Account__c>();
		for (Account acc : imgaccounts)
		{
			IM_Customer_Account__c customerAccount = new IM_Customer_Account__c ();    
            customerAccount.IM_Account__c      = acc.Id;
            customerAccount.IM_Status__c       = 'Active';
            customerAccount.Name               = acc.Name + ' CID 00';
            customerAccount.Source_System__c   = 'SKP NA';
            customerAccounts.add(customerAccount);
		}
		return customerAccounts;
	}

	static List<Parent_Billing_Market__c> setupParentBillingMarkets(Integer num) 
	{
		return TestingUtils.createParentBillingMarketRecords(num, false);
	}

	static List<Billing_Market__c> setupBillingMarkets(List<Parent_Billing_Market__c> pbms, Integer num)
	{
		List<Billing_Market__c> bms = new List<Billing_Market__c>();
		for (Parent_Billing_Market__c pbm : pbms)
		{
			for (Integer i=0; i<num; i++) 
			{
				bms.add(TestingUtils.createBillingMarket('Billing Market '+i, 'Market '+i, pbm.Id, false));
			}
		}
		return bms;
	}

	static List<Product2> setupProductsWithClass(Integer num, String className) 
	{
		List<Product2> products = new List<Product2>();
		for (Integer i=0; i<num; i++) 
		{
			Product2 pd = TestingUtils.createProduct('IM Product '+ className, false);
			pd.IM_Product_Class__c = className;
            pd.Include_in_M4_Coverage__c = true;
			products.add(pd);
		}
		return products;
	}

	static void setupBillings() 
	{
		List<Account> accounts = setupIMGAccounts(5);
		insert accounts;

		List<IM_Customer_Account__c> customerAccounts = setupCustomerAccounts(accounts);
		insert customerAccounts;

		for (IM_Customer_Account__c ca : customerAccounts) 
		{
			imgaToCA.put(ca.IM_Account__c, ca.Id);
		}

		List<Parent_Billing_Market__c> pbms = setupParentBillingMarkets(3);
		insert pbms;

		Parent_Billing_Market__c pbmWithoutMatchingM4 = setupParentBillingMarkets(1)[0];
		pbmWithoutMatchingM4.Name = 'Not matching PBM0';
		pbmWithoutMatchingM4.Country_Coverage__c = 'United States';
		insert pbmWithoutMatchingM4;

		List<Billing_Market__c> bms = setupBillingMarkets(pbms, 3);
		insert bms;

		for (Billing_Market__c bm : bms) 
		{
			if (pbmToBms.containsKey(bm.Parent_Billing_Market__c))
				pbmToBms.get(bm.Parent_Billing_Market__c).add(bm.Id);
			else
				pbmToBms.put(bm.Parent_Billing_Market__c, new List<Id>{bm.Id});
		}

		List<Billing_Market__c> bmsUnderUnmatchingPBM = setupBillingMarkets(new List<Parent_Billing_Market__c>{pbmWithoutMatchingM4}, 3);
		insert bmsUnderUnmatchingPBM;

		Product2 testProduct = setupProductsWithClass(1, 'RM')[0];
		insert testProduct;		 

		List<M4_Revenue_Coverage__c> m4s = new List<M4_Revenue_Coverage__c>();
		List<Billings__c> billings = new List<Billings__c>();
		for (IM_Customer_Account__c cAcc : customerAccounts)
		{
			for (Id pbmId : pbmToBms.keySet()) 
			{
				// Create M4 for each PBM
				m4s.add(IMGAUtilities.createTestM4(cAcc.IM_Account__c, pbmId, 'North America', 'RM'));

				for (Id bmId : pbmToBms.get(pbmId)) 
				{
					// Create Billings that match M4 via Parent Billing Market
					billings.add(IMGAUtilities.createTestBilling(cAcc.Id, Date.newInstance(startYear, 3, 5), bmId, testProduct.Id));
				}
				// Create a Billing that is not within the range of billing months
				billings.add(IMGAUtilities.createTestBilling(cAcc.Id, Date.newInstance(startYear, invalidPeriod, 5), pbmToBms.get(pbmId)[0], testProduct.Id));
			}
			// Create M4 without PBM
			m4s.add(IMGAUtilities.createTestM4(cAcc.IM_Account__c, null, 'North America', 'RM'));
			for (Integer i=0; i<3; i++) 
			{
				billings.add(IMGAUtilities.createTestBilling(cAcc.Id, Date.newInstance(startYear, startPeriod, 5), bmsUnderUnmatchingPBM[i].Id, testProduct.Id));
			}
			// Create a Billing that is not within the range of billing months
			billings.add(IMGAUtilities.createTestBilling(cAcc.Id, Date.newInstance(startYear, invalidPeriod, 5), bmsUnderUnmatchingPBM[0].Id, testProduct.Id));

		}
		insert m4s;
		insert billings;


		List<Account> actualAccounts = [SELECT Id FROM Account];
		System.assertEquals(5, actualAccounts.size());
		List<IM_Customer_Account__c> actualCustomerAccounts = [SELECT Id FROM IM_Customer_Account__c];
		System.assertEquals(5, actualCustomerAccounts.size());
		List<Billings__c> actualBillings = [SELECT Id, IMGA_Name_Formula__c, Billing_Period__c, Parent_Billing_Market__c, Customer_Account__r.IM_Account__c, Customer_Account__c FROM Billings__c];
		System.assertEquals(80, actualBillings.size());
		Set<Id> uniqueAccounts = new Set<Id>();
		for (Billings__c billing : actualBillings)
			uniqueAccounts.add(billing.Customer_Account__r.IM_Account__c);
		System.assertEquals(5, uniqueAccounts.size());
		List<M4_Revenue_Coverage__c> actualM4s = [SELECT Id FROM M4_Revenue_Coverage__c];
		System.assertEquals(20, actualM4s.size());
	}

	static void setupBillings2() 
	{
		List<Account> accounts = setupIMGAccounts(1);
		insert accounts;

		IM_Customer_Account__c customerAccount = setupCustomerAccounts(accounts)[0];
		insert customerAccount;

		List<Parent_Billing_Market__c> pbms = setupParentBillingMarkets(3);
		insert pbms;

		List<Billing_Market__c> bms = setupBillingMarkets(pbms, 10);
		insert bms;

		for (Billing_Market__c bm : bms) 
		{
			if (pbmToBms.containsKey(bm.Parent_Billing_Market__c))
				pbmToBms.get(bm.Parent_Billing_Market__c).add(bm.Id);
			else
				pbmToBms.put(bm.Parent_Billing_Market__c, new List<Id>{bm.Id});
		}

		Product2 testProduct = setupProductsWithClass(1, 'RM')[0];
		insert testProduct;		

		List<M4_Revenue_Coverage__c> m4s = new List<M4_Revenue_Coverage__c>();
		List<Billings__c> billings = new List<Billings__c>();
		for (Parent_Billing_Market__c pbm : pbms) 
		{
			// Create M4 for each PBM
			m4s.add(IMGAUtilities.createTestM4(customerAccount.IM_Account__c, pbm.Id, 'North America', 'RM'));

			for (Integer i=0; i<65; i++) 
			{
				// Create Billings that match M4 via Parent Billing Market
				billings.add(IMGAUtilities.createTestBilling(customerAccount.Id, Date.newInstance(startYear, startPeriod, 5), pbmToBms.get(pbm.Id)[Math.mod(i, 10)], testProduct.Id));
			}
			// Create a Billing that is not within the range of billing months
			billings.add(IMGAUtilities.createTestBilling(customerAccount.Id, Date.newInstance(startYear, invalidPeriod, 5), bms[0].Id, testProduct.Id));
		}
		insert m4s;
		insert billings;

		List<Account> actualAccounts = [SELECT Id FROM Account];
		System.assertEquals(1, actualAccounts.size());
		List<IM_Customer_Account__c> actualCustomerAccounts = [SELECT Id FROM IM_Customer_Account__c];
		System.assertEquals(1, actualCustomerAccounts.size());
		List<Billings__c> actualBillings = [SELECT Id, IMGA_Name_Formula__c, Billing_Period__c, Parent_Billing_Market__c, Customer_Account__r.IM_Account__c,Customer_Account__c FROM Billings__c];
		System.assertEquals(66*3, actualBillings.size());
		Set<Id> uniqueAccounts = new Set<Id>();
		for (Billings__c billing : actualBillings)
			uniqueAccounts.add(billing.Customer_Account__r.IM_Account__c);
		System.assertEquals(1, uniqueAccounts.size());
		List<M4_Revenue_Coverage__c> actualM4s = [SELECT Id FROM M4_Revenue_Coverage__c];
		System.assertEquals(3, actualM4s.size());
	}

	static void setupBillings3() 
	{
		List<Account> accounts = setupIMGAccounts(1);
		insert accounts;

		IM_Customer_Account__c customerAccount = setupCustomerAccounts(accounts)[0];
		insert customerAccount;

		List<Parent_Billing_Market__c> pbms = setupParentBillingMarkets(3);
		insert pbms;

		List<Billing_Market__c> bms = setupBillingMarkets(pbms, 10);
		insert bms;

		for (Billing_Market__c bm : bms) 
		{
			if (pbmToBms.containsKey(bm.Parent_Billing_Market__c))
				pbmToBms.get(bm.Parent_Billing_Market__c).add(bm.Id);
			else
				pbmToBms.put(bm.Parent_Billing_Market__c, new List<Id>{bm.Id});
		}

		Product2 testProductRM = setupProductsWithClass(1, 'RM')[0];
		Product2 testProductDM = setupProductsWithClass(1, 'DM')[0];
		insert testProductRM;	
		insert testProductDM;	

		List<M4_Revenue_Coverage__c> m4s = new List<M4_Revenue_Coverage__c>();
		List<Billings__c> billings = new List<Billings__c>();
		for (Parent_Billing_Market__c pbm : pbms) 
		{
			// Create M4 for each PBM
			m4s.add(IMGAUtilities.createTestM4(customerAccount.IM_Account__c, pbm.Id, 'North America', 'RM;DM'));

			// Create Billings that match M4 via Parent Billing Market
			billings.add(IMGAUtilities.createTestBilling(customerAccount.Id, Date.newInstance(startYear, startPeriod, 5), pbmToBms.get(pbm.Id)[0], testProductRM.Id));
			billings.add(IMGAUtilities.createTestBilling(customerAccount.Id, Date.newInstance(startYear, startPeriod, 5), pbmToBms.get(pbm.Id)[1], testProductRM.Id));
			billings.add(IMGAUtilities.createTestBilling(customerAccount.Id, Date.newInstance(startYear, startPeriod, 5), pbmToBms.get(pbm.Id)[2], testProductDM.Id));
			billings.add(IMGAUtilities.createTestBilling(customerAccount.Id, Date.newInstance(startYear, startPeriod, 5), pbmToBms.get(pbm.Id)[3], testProductDM.Id));
			billings.add(IMGAUtilities.createTestBilling(customerAccount.Id, Date.newInstance(startYear, startPeriod, 5), pbmToBms.get(pbm.Id)[4], testProductDM.Id));

			// Create a Billing that is not within the range of billing months
			billings.add(IMGAUtilities.createTestBilling(customerAccount.Id, Date.newInstance(startYear, invalidPeriod, 5), bms[0].Id, testProductDM.Id));
		}
		insert m4s;
		insert billings;

		List<Account> actualAccounts = [SELECT Id FROM Account];
		System.assertEquals(1, actualAccounts.size());
		List<IM_Customer_Account__c> actualCustomerAccounts = [SELECT Id FROM IM_Customer_Account__c];
		System.assertEquals(1, actualCustomerAccounts.size());
		List<Billings__c> actualBillings = [SELECT Id, IMGA_Name_Formula__c, Billing_Period__c, Parent_Billing_Market__c, Customer_Account__r.IM_Account__c, Customer_Account__c FROM Billings__c];
		System.assertEquals(18, actualBillings.size());
		Set<Id> uniqueAccounts = new Set<Id>();
		for (Billings__c billing : actualBillings)
			uniqueAccounts.add(billing.Customer_Account__r.IM_Account__c);
		System.assertEquals(1, uniqueAccounts.size());
		List<M4_Revenue_Coverage__c> actualM4s = [SELECT Id FROM M4_Revenue_Coverage__c];
		System.assertEquals(3, actualM4s.size());
	}

	static void setupM4s() 
	{

	}

	static testMethod void testBatch_3BillingsPerM4() {
		setupBillings();

		Test.startTest();
			Database.executeBatch(new M4AggregateStorageRevenueBatch('M4_CY_YTD_Q1_Q2__c', 'CY YTD Q1 Q2'), 200);
			//Database.executeBatch(new M4AggregateStorageRevenueBatch('M4_CY_YTD_Q3_Q4__c', 'CY YTD Q3 Q4'), 200);
		Test.stopTest();

		List<Aggregate_Storage_Revenue__c> actualAS = 	[SELECT Id, Amount__c FROM Aggregate_Storage_Revenue__c];
	/*	System.assertEquals(20, actualAS.size(), 
			'A total of 20 Aggregate Storage records should be created. 1 for each M4 for the month of May');
		for (Aggregate_Storage_Revenue__c aas : actualAS) 
		{
			System.assertEquals(33, aas.Amount__c, 
				'Since each billing has a total price of 11, and there are 3 billings under each aggregate, the total should be 33');
		}* /
	}

	static testMethod void testBatch_65BillingsUnder3M4s() {
		setupBillings2();

		Test.startTest();
			Database.executeBatch(new M4AggregateStorageRevenueBatch('M4_CY_YTD_Q1_Q2__c', 'CY YTD Q1 Q2'), 200);
        	//Database.executeBatch(new M4AggregateStorageRevenueBatch('M4_CY_YTD_Q3_Q4__c', 'CY YTD Q3 Q4'), 200);
		Test.stopTest();

	/*	List<Aggregate_Storage_Revenue__c> actualAS = 	[SELECT Id, Amount__c FROM Aggregate_Storage_Revenue__c];
		System.assertEquals(3, actualAS.size(), 
			'A total of 3 Aggregate Storage records should be created. 1 for each M4 for the month of May');
		for (Aggregate_Storage_Revenue__c aas : actualAS) 
		{
			System.assertEquals(715, aas.Amount__c, 
				'Since each billing has a total price of 11, and there are 65 billings under each aggregtea, the total should be 715');
		}* /
	}

	static testMethod void testBatch_2AggregatesForEachM4() {
		setupBillings3();

		Test.startTest();
			Database.executeBatch(new M4AggregateStorageRevenueBatch('M4_CY_YTD_Q1_Q2__c', 'CY YTD Q1 Q2'), 200);
			//Database.executeBatch(new M4AggregateStorageRevenueBatch('M4_CY_YTD_Q3_Q4__c', 'CY YTD Q3 Q4'), 200);        
		Test.stopTest();

	/*	List<Aggregate_Storage_Revenue__c> actualAS = 	[SELECT Id, Amount__c, Product_Class__c FROM Aggregate_Storage_Revenue__c];
		System.assertEquals(6, actualAS.size(), 
			'A total of 3 Aggregate Storage records should be created. 1 for each M4 for the month of May. Actual: '+actualAs);
		for (Aggregate_Storage_Revenue__c aas : actualAS) 
		{
			if (aas.Product_Class__c == 'RM')
				System.assertEquals(22, aas.Amount__c, 
					'Since each billing has a total price of 11, and there are 2 RM billings under RM aggregtes, the total should be 22');
			else
				System.assertEquals(33, aas.Amount__c, 
					'Since each billing has a total price of 11, and there are 3 DM billings under DM aggregtes, the total should be 33');

		}* /
	}
	*/
}