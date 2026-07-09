/*****************************************************************************************************
 * Class: QTB_QueueBillingAmend_Test
 * Author: Accenture
 * Purpose: This is a test class for QTB_QueueBillingAmend
 * Change History: 4/21/2021
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture
 *******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_QueueBillingAmend_Test {
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
			Contract testContract = [select id,name,SBQQ__Order__c From Contract LIMIT 1];
            List<contract> testContracts = new list<Contract>{testContract};
            map<id,contract> testContractMap = new map<id,contract>();
            testContractMap.put(testContract.id,testContract);
            QTB_QueueBillingAmend billingAmend = new QTB_QueueBillingAmend(testContracts,testContractMap);
            system.enqueueJob(billingAmend);
            test.stopTest();
		}
	}
}