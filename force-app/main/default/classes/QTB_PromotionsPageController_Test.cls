/*****************************************************************************************************
 * Class: QTB_PromotionsPageController_Test
 * Author: Accenture
 * Purpose: This is a test class for QTB_PromotionsPageController
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture   24/12/2020
 *******************************************************************************************************/

@isTest(seealldata=false)
public class QTB_PromotionsPageController_Test {
    @testSetup

	static void setup() {
		List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
		System.runAs(userList[0]) {
			List<account> accountList = QTB_TestDataFactory.createAccounts(1);
			accountList[0].BillingCountry = 'India';
			accountList[0].QTB_Legal_Entity_Country__c = 'India';
			update accountList;

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
			database.update(product);

			Id pricebookId = Test.getStandardPricebookId();
			PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
				product[0]
			);

			// Update the pricebook of opportunity
			List<opportunity> oppList = QTB_TestDataFactory.createOpps(
				accountList
			);
			oppList[0].Pricebook2Id = pricebookId;
			database.update(oppList);

			List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
				1,
				oppList[0].id,
				accountList[0].id,
				true,
				null
			);
			quoteList[0].SBQQ__PriceBook__c = pricebookId;
			quoteList[0].SBQQ__Type__c = 'Quote';
			quoteList[0].SBQQ__StartDate__c = System.Today() + 1;

			database.update(quoteList);

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
			quoteLinesList[0].QTB_Promo_Amount__c = null;
			quoteLinesList[0].QTB_Promo_Percent__c = null;
			quoteLinesList[0].SBQQ__AdditionalDiscountAmount__c = null;
			quoteLinesList[0].SBQQ__Discount__c = null;
			database.update(quoteLinesList);

			// create promotion for Product
			QTB_Promotion__c promo1 = new QTB_Promotion__c(
				QTB_Start_Date__c = System.Today(),
				QTB_Quote_Type__c = 'Quote',
				QTB_Promo_Inactive__c = false,
				QTB_Promo_Percent__c = 10,
				QTB_End_Date__c = System.today() + 30,
				QTB_Promo_Description__c = '10% off',
				QTB_Product__c = product[0].Id,
				Name = 'Spring 10% Offer'
			);
			// create promotion for Quote
			QTB_Promotion__c promo2 = new QTB_Promotion__c(
				QTB_Start_Date__c = System.Today(),
				QTB_Quote_Type__c = 'Quote',
				QTB_Promo_Inactive__c = false,
				QTB_Promo_Percent__c = 3,
				QTB_End_Date__c = System.today() + 30,
				QTB_Promo_Description__c = '3% off',
				Name = 'Friday 3% Overall Discount'
			);
            
            QTB_Promotion__c promo3 = new QTB_Promotion__c(
				QTB_Start_Date__c = System.Today(),
				QTB_Quote_Type__c = 'Amendment',
				QTB_Promo_Inactive__c = false,
				QTB_Promo_Percent__c = 3,
				QTB_End_Date__c = System.today() + 30,
				QTB_Promo_Description__c = '3% off',
				Name = 'Friday 3% Overall Discount'
			);
			insert new List<QTB_Promotion__c>{ promo1, promo2, promo3 };
		}
	}

	@IsTest
	static void testApplyPromotion() {
		// get the quote
		SBQQ__Quote__c[] quotes = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
		// get the original promotions
		QTB_Promotion__c[] promotions = [
			SELECT
				Id,
				Name,
				QTB_Country__c,
				QTB_Start_Date__c,
				QTB_End_Date__c,
				QTB_Product__c,
				QTB_Quote_Type__c,
				QTB_Promo_Inactive__c,
				QTB_Promo_Code__c,
				QTB_Promo_Description__c,
				QTB_Promo_Percent__c,
				QTB_Promo_Amount__c,
				QTB_Promo_Term__c,
				CurrencyIsoCode,
				QTB_Minimum_Quote__c
			FROM QTB_Promotion__c
			LIMIT 2
		];
		List<QTB_PromotionsPageController.PromoWrapper> promos = new List<QTB_PromotionsPageController.PromoWrapper>();
		// create a list of promotions, mock that the user has selected all of those
		for (QTB_Promotion__c thisPromo : promotions) {
			promos.add(
				new QTB_PromotionsPageController.PromoWrapper(
					thisPromo,
					true,
					false
				)
			);
		}
		PageReference pageRef = page.QTB_PromotionsPage;
		pageRef.getParameters().put('id', string.valueof(quotes[0].id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		QTB_PromotionsPageController controller = new QTB_PromotionsPageController();
		// set the promotions with selected promotions
		controller.promotions = promos;
		// mock apply promotion click
		controller.save();
		Test.stopTest();
		Integer quotePromotionRecordsOnSelectCount = [
			SELECT COUNT()
			FROM QTB_Quote_Promotion__c
			WHERE QTB_Quote__c IN :quotes
		];
		System.assertEquals(
			2,
			quotePromotionRecordsOnSelectCount,
			'Expected 2 quote promotion records to be created'
		);
		// clear the list, so that new unselected promotions can be added
		promos.clear();
		// create list of unselected promotions
		for (QTB_Promotion__c thisPromo : promotions) {
			promos.add(
				new QTB_PromotionsPageController.PromoWrapper(
					thisPromo,
					false,
					true
				)
			);
		}
		controller = new QTB_PromotionsPageController();
		// set the promotions to the unslected promotions
		controller.promotions = promos;
		// mock apply promotion click
		controller.save();
		Integer quotePromotionRecordsAfterUnselectCount = [
			SELECT COUNT()
			FROM QTB_Quote_Promotion__c
			WHERE QTB_Quote__c IN :quotes
		];
		System.assertEquals(
			0,
			quotePromotionRecordsAfterUnselectCount,
			'Expected 0 quote promotion records'
		);
		controller.cancel();
	}

	@IsTest
	static void testMultipleQuotePromotionSelection() {
		// get the quote
		SBQQ__Quote__c[] quotes = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
		// get the original promotions
		QTB_Promotion__c[] promotions = [
			SELECT
				Id,
				Name,
				QTB_Country__c,
				QTB_Start_Date__c,
				QTB_End_Date__c,
				QTB_Product__c,
				QTB_Quote_Type__c,
				QTB_Promo_Inactive__c,
				QTB_Promo_Code__c,
				QTB_Promo_Description__c,
				QTB_Promo_Percent__c,
				QTB_Promo_Amount__c,
				QTB_Promo_Term__c,
				CurrencyIsoCode,
				QTB_Minimum_Quote__c
			FROM QTB_Promotion__c
			LIMIT 2
		];
		// create promotion for Product
		QTB_Promotion__c promo1 = new QTB_Promotion__c(
			QTB_Start_Date__c = System.Today(),
			QTB_Quote_Type__c = 'Quote',
			QTB_Promo_Inactive__c = false,
			QTB_Promo_Amount__c = 50,
			QTB_End_Date__c = System.today() + 30,
			QTB_Promo_Description__c = '50$ off',
			QTB_Product__c = promotions[0].QTB_Product__c <> null
				? promotions[0].QTB_Product__c
				: promotions[1].QTB_Product__c,
			Name = 'Spring 50$ off Offer'
		);
		promotions.add(promo1);
		insert promo1;
		List<QTB_PromotionsPageController.PromoWrapper> promos = new List<QTB_PromotionsPageController.PromoWrapper>();
		// create a list of promotions, mock that the user has selected all of those
		for (QTB_Promotion__c thisPromo : promotions) {
			promos.add(
				new QTB_PromotionsPageController.PromoWrapper(
					thisPromo,
					true,
					false
				)
			);
		}
		PageReference pageRef = page.QTB_PromotionsPage;
		pageRef.getParameters().put('id', string.valueof(quotes[0].id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		QTB_PromotionsPageController controller = new QTB_PromotionsPageController();
		// set the promotions with selected promotions
		controller.promotions = promos;
		// mock apply promotion click
		controller.save();
		Test.stopTest();
		Integer quotePromotionRecordsAfterSelectCount = [
			SELECT COUNT()
			FROM QTB_Quote_Promotion__c
			WHERE QTB_Quote__c IN :quotes
		];
		System.assertEquals(
			0,
			quotePromotionRecordsAfterSelectCount,
			'Expected 0 quote promotion records'
		);
		promos.clear();
		// create promotion for Quote
		QTB_Promotion__c promo2 = new QTB_Promotion__c(
			QTB_Start_Date__c = System.Today(),
			QTB_Quote_Type__c = 'Quote',
			QTB_Promo_Inactive__c = false,
			QTB_Promo_Percent__c = 7.7,
			QTB_End_Date__c = System.today() + 30,
			QTB_Promo_Description__c = '7% off',
			Name = 'Friday 7% Lucky Discount'
		);
		insert promo2;
		promotions.add(promo2);
		// create a list of promotions, mock that the user has selected all of those
		for (QTB_Promotion__c thisPromo : promotions) {
			promos.add(
				new QTB_PromotionsPageController.PromoWrapper(
					thisPromo,
					true,
					false
				)
			);
		}
		controller = new QTB_PromotionsPageController();
		// set the promotions to the unslected promotions
		controller.promotions = promos;
		// mock apply promotion click
		controller.save();
	}
    
    @IsTest
	static void testApplyPromotionAmend() {
		// get the quote
		SBQQ__Quote__c[] quotes = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        quotes[0].SBQQ__Type__c = 'Amendment';
        update quotes;
		// get the original promotions
		QTB_Promotion__c[] promotions = [
			SELECT
				Id,
				Name,
				QTB_Country__c,
				QTB_Start_Date__c,
				QTB_End_Date__c,
				QTB_Product__c,
				QTB_Quote_Type__c,
				QTB_Promo_Inactive__c,
				QTB_Promo_Code__c,
				QTB_Promo_Description__c,
				QTB_Promo_Percent__c,
				QTB_Promo_Amount__c,
				QTB_Promo_Term__c,
				CurrencyIsoCode,
				QTB_Minimum_Quote__c
			FROM QTB_Promotion__c
			WHERE QTB_Quote_Type__c = 'Amendment'
		];
		List<QTB_PromotionsPageController.PromoWrapper> promos = new List<QTB_PromotionsPageController.PromoWrapper>();
		// create a list of promotions, mock that the user has selected all of those
		for (QTB_Promotion__c thisPromo : promotions) {
			promos.add(
				new QTB_PromotionsPageController.PromoWrapper(
					thisPromo,
					true,
					false
				)
			);
		}
		PageReference pageRef = page.QTB_PromotionsPage;
		pageRef.getParameters().put('id', string.valueof(quotes[0].id));
		Test.setCurrentPage(pageRef);
		Test.startTest();
		QTB_PromotionsPageController controller = new QTB_PromotionsPageController();
		// set the promotions with selected promotions
		controller.promotions = promos;
		// mock apply promotion click
		controller.save();
		Test.stopTest();
		Integer quotePromotionRecordsOnSelectCount = [
			SELECT COUNT()
			FROM QTB_Quote_Promotion__c
			WHERE QTB_Quote__c IN :quotes
		];
		
		// clear the list, so that new unselected promotions can be added
		promos.clear();
		// create list of unselected promotions
		for (QTB_Promotion__c thisPromo : promotions) {
			promos.add(
				new QTB_PromotionsPageController.PromoWrapper(
					thisPromo,
					false,
					true
				)
			);
		}
		controller = new QTB_PromotionsPageController();
		// set the promotions to the unslected promotions
		controller.promotions = promos;
		// mock apply promotion click
		controller.save();
		Integer quotePromotionRecordsAfterUnselectCount = [
			SELECT COUNT()
			FROM QTB_Quote_Promotion__c
			WHERE QTB_Quote__c IN :quotes
		];
		System.assertEquals(
			0,
			quotePromotionRecordsAfterUnselectCount,
			'Expected 0 quote promotion records'
		);
		controller.cancel();
	}
}