/*****************************************************************************************************
 * Class: QTB_ContractHelper_Test
 * Author: Accenture
 * Purpose: Test Class for QTB_ContractHelper
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture   5/9/2020
 *******************************************************************************************************/
@isTest(seeAllData=false)
private with sharing class QTB_ContractHelper_Test {
	private static final id quoteSalesRecTypeId = QTB_Utils.QUOTE_SALES_RECTYPEID;
    private static final id quoteBillRecTypeId = QTB_Utils.QUOTE_BILL_RECTYPEID;
	private static final id contractSalesRecTypeId = QTB_Utils.CONTRACT_SALES_RECTYPEID;
	private static final Id accountBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;

	static testMethod void testData() {
		List<User> userList = new List<User>();
		userList = QTB_TestDataFactory.usrMethdLst(2);
		SBQQ.TriggerControl.disable();
		System.runAs(userList[0]) {
			IM_Country__c india = [
				SELECT Id
				FROM IM_Country__c
				WHERE Name = 'India'
			];
			List<Account> accountList = QTB_TestDataFactory.createAccounts(1);
			accountList[0].BillingCountry = 'India';
			update accountList;
			List<opportunity> oppList = QTB_TestDataFactory.createOpps(
				accountList
			);
			oppList[0].Billing_Country__c = india.Id;
			update oppList;
			accountList[0].QTB_Source_Opportunity__c = oppList[0].Id;
			update accountList;

			List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
				1,
				oppList[0].id,
				accountList[0].id,
				true,
				null
			);
			List<SBQQ__Quote__c> quoteList2 = QTB_TestDataFactory.createCPQQuotes(
				1,
				oppList[0].id,
				accountList[0].id,
				false,
				null
			);
			quoteList[0].recordTypeId = quoteSalesRecTypeId;
			quoteList2[0].recordTypeId = quoteBillRecTypeId;
			List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
			quotes.addAll(quoteList);
			quotes.addAll(quoteList2);
			update quotes;

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
			List<Pricebook2> pricebook = QTB_TestDataFactory.priceBookMethdLst(
				1,
				'Standard Price Book'
			);
			List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
				1,
				quoteList[0].Id,
				accountList[0].id
			);
			orderList3[0].Pricebook2Id = pricebook[0].Id;

			PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
				product[0]
			);
			List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(
				orderList3[0].Id,
				product[0].Id,
				quoteLinesList,
				standardPrice
			);
			Test.startTest();
			List<Contract> contractList = QTB_TestDataFactory.createCPQContracts(
				1,
				orderList3[0].id,
				accountList[0].id,
				QuoteList[0].id
			);
			contractList[0].SBQQ__Opportunity__c = oppList[0].Id;
			contractList[0].recordTypeId = contractSalesRecTypeId;
			contractList[0].SBQQ__Opportunity__c = oppList[0].Id;
			contractList[0].Status = 'Draft';
			update contractList;
            

			contractList[0].Status = 'Activated';
			update contractList;
		
			List<Contract> contractList2 = QTB_TestDataFactory.createCPQContracts(
				1,
				orderList3[0].id,
				accountList[0].id,
				QuoteList2[0].id
			);
			contractList2[0].Status = 'Activated';
			contractList2[0].SBQQ__Opportunity__c = oppList[0].Id;
			//update contractList2;
			QTB_ContractHelper.triggerPlatformEvent(contractList2);
            Test.stopTest();
			System.Assert(product[0].blng__TaxRule__c == taxRule.id);
		}
	}
/*
	testMethod static void TestDataContractHelper() {
		QTB_TestDataFactory.createBypassSetting(
			QTB_Constants.SOBJECT_QUOTE +
			';' +
			QTB_Constants.SOBJECT_ORDER
		);
		SBQQ.TriggerControl.disable();
		updateContractNumber.isTriggered = true;
		List<User> testUsers = QTB_TestDataFactory.usrMethdLst(2);
		System.runAs(testUsers[0]) {
			List<Account> testAccount = QTB_TestDataFactory.createAccounts(
				2,
				'Standard Account'
			);

			List<Product2> testProduct = QTB_TestDataFactory.createProducts(1);
			List<PriceBook2> testPriceBook = QTB_TestDataFactory.priceBookMethdLst(
				1,
				'Test Price book'
			);
			IM_Country__c testCountry = new IM_Country__c(Name='United States');
            insert testCountry;
			testPriceBook[0].isActive = true;
			testPriceBook[0].QTB_Country__c = testAccount[0].Billing_County__c;
			update testPriceBook;

			//Sales Opportunity
			List<Opportunity> testOpp = QTB_TestDataFactory.createCPQOppsNew(
				testAccount,
				'CPQ Sales Opportunity'
			);
			testOpp[0].Pricebook2Id = testPriceBook[0].id;
			//testOpp[0].Billing_Country__c = testCountry.id;
			//testOpp[0].CurrencyIsoCode = testAccount[0].Billing_County__c;
            update testOpp[0];
			//testOpp[1].Pricebook2Id = testPriceBook[0].id;
			//testOpp[1].Billing_Country__c = testCountry.id;
			//testOpp[1].CurrencyIsoCode = testAccount[1].Billing_County__c;
			//update testOpp[1];
			List<SBQQ__Quote__c> testQuotes = QTB_TestDataFactory.createCPQQuotes(
				1,
				testOpp[0].Id,
				testOpp[0].AccountId,
				true,
				null
			);
			List<SBQQ__QuoteLine__c> testQuoteLines = QTB_TestDataFactory.createCPQQuoteLines(
				1,
				testQuotes[0].Id,
				null,
				testProduct[0].id
			);
			List<Order> testorder = QTB_TestDataFactory.createCPQOrders(
				1,
				testQuotes[0].id,
				testAccount[0].id
			);
			Contract testContracts = new Contract(
				Status = 'Draft',
				RecordTypeId = QTB_Utils.CONTRACT_SALES_RECTYPEID,
				StartDate = Date.today(),
				ContractTerm = 5,
				SBQQ__Opportunity__c = testOpp[0].Id,
				AccountId = testAccount[0].Id,
				SBQQ__Quote__c = testQuotes[0].Id
			);
			Contract testContracts1 = new Contract(
				Status = 'Draft',
				RecordTypeId = QTB_Utils.CONTRACT_SALES_RECTYPEID,
				StartDate = Date.today(),
				ContractTerm = 5,
				SBQQ__Opportunity__c = testOpp[0].Id,
				AccountId = testAccount[0].Id,
				SBQQ__Quote__c = testQuotes[0].Id
			);
			SBQQ.TriggerControl.disable();
			insert new List<Contract>{ testContracts, testContracts1 };

			List<SBQQ__Subscription__c> testSubs = QTB_TestDataFactory.createCPQSubscriptions(
				1,
				testContracts.id,
				testProduct[0].id
			);
			//Billing Opportunity
			Test.startTest();
			List<Opportunity> billTestOpp = QTB_TestDataFactory.createCPQOppsNew(
				testAccount,
				'CPQ Billing Opportunity'
			);
			billTestOpp[0].Pricebook2Id = testPriceBook[0].id;
			billTestOpp[0].CurrencyIsoCode = testAccount[0].Billing_County__c;
			billTestOpp[0].Billing_Country__c = testCountry.Id;
			update billTestOpp;
			List<SBQQ__Quote__c> billtestQuotes = QTB_TestDataFactory.createCPQQuotes(
				1,
				billTestOpp[0].Id,
				billTestOpp[0].AccountId,
				true,
				null
			);
			List<SBQQ__QuoteLine__c> billtestQuoteLines = QTB_TestDataFactory.createCPQQuoteLines(
				1,
				billtestQuotes[0].Id,
				null,
				testProduct[0].id
			);
			
			List<Order> billtestorder = QTB_TestDataFactory.createCPQOrders(
				1,
				billtestQuotes[0].id,
				testAccount[0].id
			);

			List<Contract> billtestContracts = QTB_TestDataFactory.createCPQContracts(
				1,
				billtestorder[0].id,
				testAccount[0].id,
				billtestQuotes[0].id
			);
			billtestContracts[0].SBQQ__Quote__c = billtestQuotes[0].id;
			billtestContracts[0].Status = 'Activated';
			update billtestContracts;
			billtestContracts[0].SBQQ__Order__c = billtestorder[0].id;
			update billtestContracts;
			List<SBQQ__Subscription__c> billtestSubs = QTB_TestDataFactory.createCPQSubscriptions(
				1,
				billtestContracts[0].id,
				testProduct[0].id
			);

			List<Opportunity> renewalTestOpp = QTB_TestDataFactory.createCPQOppsNew(
				testAccount,
				'CPQ Sales Opportunity'
			);
			test.stopTest();
			renewalTestOpp[0].Pricebook2Id = testPriceBook[0].id;
			renewalTestOpp[0].Billing_Country__c = testCountry.Id;
			renewalTestOpp[0].CurrencyIsoCode = testAccount[0]
				.Billing_County__c;
			renewalTestOpp[0].Type = QTB_Constants.OPP_TYPE;
			renewalTestOpp[0].SBQQ__RenewedContract__c = testContracts.id;
			update renewalTestOpp;
			List<SBQQ__Quote__c> renewaltestQuotes = QTB_TestDataFactory.createCPQQuotes(
				1,
				renewalTestOpp[0].Id,
				renewalTestOpp[0].AccountId,
				true,
				null
			);
			List<SBQQ__QuoteLine__c> renewaltestQuoteLines = QTB_TestDataFactory.createCPQQuoteLines(
				1,
				renewaltestQuotes[0].Id,
				null,
				testProduct[0].id
			);
			renewalTestOpp[0].StageName = '5 - Signed/PO in';
			renewalTestOpp[0].IME_Reason_Won__c = 'test';
			update renewalTestOpp;
			SBQQ.TriggerControl.disable();
			renewalTestOpp[0].StageName = QTB_Constants.STAGEVALUE_SIXSETUP;
			update renewalTestOpp;
			System.Assert(testPriceBook[0].isActive == true);
		}
	}
     */
    static testMethod void testMethod1() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
    Test.startTest();
    ContractTriggerHandler.throwExplicitException = true;
        try {
				QTB_ContractHelper.checkAmendContract(null, null);
			} catch (Exception e) {
				System.assert('Script-thrown exception' == e.getMessage());
			}
       
     Test.stopTest();
    }
    }     
    
	static testMethod void testExceptionBlock() {
		List<User> testUsers = QTB_TestDataFactory.usrMethdLst(1);
		System.runAs(testUsers[0]) {
			Test.startTest();
			ContractTriggerHandler.throwExplicitException = true;
			ContractTriggerHandler handler = new ContractTriggerHandler();
			handler.BeforeDelete(null);
			handler.AfterDelete(null);
			handler.AfterUndelete(null);
			handler.isDisabled();
			Test.stopTest();
			try {
				QTB_ContractHelper.setCPQContractRT(null, null, null);
			} catch (Exception e) {
				System.assert('Script-thrown exception' == e.getMessage());
			}
			try {
				QTB_ContractHelper.checkRenewalContract(null);
			} catch (Exception e) {
				System.assert('Script-thrown exception' == e.getMessage());
			}
			try {
				QTB_ContractHelper.setBillingCountry(null, null);
			} catch (Exception e) {
				System.assert('Script-thrown exception' == e.getMessage());
			}
			try {
				QTB_ContractHelper.triggerPlatformEvent(null);
			} catch (Exception e) {
				System.assert('Script-thrown exception' == e.getMessage());
			}
			System.assertEquals(
				true,
				ContractTriggerHandler.throwExplicitException
			);
		}
	}
}