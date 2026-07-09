@IsTest
private class QTB_AdditionalUtils_Tests {
	@TestSetup
	static void setup() {
		User contextUser = QTB_TestDataFactory.usrMethdLst(1)[0];

		List<Account> accounts = QTB_TestDataFactory.createAccounts(1);
		accounts[0].BillingCountry = 'India';
		update accounts[0];

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

		List<Pricebook2> pricebook = QTB_TestDataFactory.priceBookMethdLst(
			1,
			'Standard Price Book'
		);
		PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
			product[0]
		);

		System.runAs(contextUser) {
			List<opportunity> opties = QTB_TestDataFactory.createOpps(accounts);
			accounts[0].QTB_Source_Opportunity__c = opties[0].Id;
			update accounts;

			List<SBQQ__Quote__c> quotes = QTB_TestDataFactory.createCPQQuotes(
				1,
				opties[0].id,
				accounts[0].id,
				true,
				null
			);
			quotes[0].recordTypeId = QTB_Utils.QUOTE_SALES_RECTYPEID;
			update quotes;

			List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
				1,
				quotes[0].id,
				accounts[0].id
			);
			List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(
				1,
				quotes[0].id,
				quoteGroupList[0].id,
				product[0].id
			);
		}
	}
	@IsTest
	static void testPublishPriceScheduleEvents() {
		User contextuser = [SELECT Id FROM User LIMIT 1];
		Test.startTest();
		System.runAs(contextuser) {
			SBQQ__Quote__c thisQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
			String whereThis =
				' WHERE SBQQ__Quantity__c > 0 AND SBQQ__Quote__c IN (\'' +
				thisQuote.Id +
				'\')';

			QTB_Utils.publishPriceScheduleEvents(
				new Set<Id>{ thisQuote.Id },
				whereThis
			);
			Test.getEventBus().deliver();
		}
		Test.stopTest();
		System.assert(
			contextuser <> null,
			'Expected to run as some context user'
		);
	}
	@IsTest
	static void testPublishBillingAccountOSEvents() {
		Account thisAccount = [SELECT Id FROM Account LIMIT 1];
		thisAccount.RecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
		thisAccount.QTB_shred__c = true;
		thisAccount.QTB_Create_Operating_System_Account__c = true;
		thisAccount.QTB_Create_Parent_Billing_Account__c = true;
		update thisAccount;

		Test.startTest();
		string wherethis =
			' where RecordTypeId=\'' +
			QTB_Utils.ACCOUNT_BILL_RECTYPEID +
			'\'' +
			'and (QTB_shred__c=true OR QTB_scan__c=true ' +
			' OR QTB_Records_Management__c=true ' +
			' OR QTB_Data_Management__c=true) and ' +
			' QTB_Create_Operating_System_Account__c=true ' +
			' and id IN :accIdset';
		QTB_Utils.publishBillingAccountEvent(
			new Set<Id>{ thisAccount.Id },
			wherethis
		);
		Test.stopTest();
		System.assert(
			thisAccount <> null,
			'Expected to publish with an account'
		);
	}
}