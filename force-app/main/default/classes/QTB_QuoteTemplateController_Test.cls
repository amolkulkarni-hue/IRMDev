/*****************************************************************************************************
 * Class: QTB_QuoteTemplateController_Test
 * Author: Accenture
 * Purpose: Test Class for QTB_QuoteTemplateController
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture
 *******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_QuoteTemplateController_Test {
  @testSetup
  static void setup()  {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      List<account> accountList = QTB_TestDataFactory.createAccounts(1);
      blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
        'Yes'
      );
      blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
        'Yes'
      );
      blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
      List<product2> product = QTB_TestDataFactory.createProducts(10);
      for (product2 prod : product) {
        prod.blng__BillingRule__c = billingRule.id;
        prod.blng__RevenueRecognitionRule__c = revenueRule.id;
        prod.blng__TaxRule__c = taxRule.id;
        prod.IM_Product_Class__c = QTB_Constants.SECURE_SHREDDING;
      }

      product[0].QTB_Price_Schedule_Category__c = 'Services';
      product[1].QTB_Price_Schedule_Category__c = 'Services Off-Site';
      product[2].QTB_Price_Schedule_Category__c = 'Services On-Site';
      product[3].QTB_Price_Schedule_Category__c = 'Storage';
      product[4].QTB_Price_Schedule_Category__c = 'Supplies';
      product[5].QTB_Price_Schedule_Category__c = 'Other Program Fees';
      product[6].QTB_Price_Schedule_Category__c = 'Transportation';
      update product;

      Id pricebookId = Test.getStandardPricebookId();
      PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
        product[0]
      );

      List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
      oppList[0].Pricebook2Id = pricebookId;
      database.update(oppList);
      Test.startTest();
      List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
        1,
        oppList[0].id,
        accountList[0].id,
        true,
        null
      );
      quoteList[0].SBQQ__PriceBook__c = pricebookId;
      quoteList[0].SBQQ__StartDate__c = date.today();
      quoteList[0].QTB_Minimum_Charges_Start_Date__c = date.today() + 10;
      quoteList[0].QTB_Minimum_Storage_Charges__c = 100;
      quoteList[0].QTB_Invoice_Minimum_Start_Date__c = date.today() + 10;
      quoteList[0].QTB_Invoice_Minimum_Charges__c = 100;
      quoteList[0].QTB_Work_Order_Minimum_Start_Date__c = date.today() + 10;
      quoteList[0].QTB_Work_Order_Minimum_Charges__c = 100;
      quoteList[0].SBQQ__Type__c = QTB_Constants.QUOTE_TYPE_AMEND;
      quoteList[0].QTB_Year_2_Uplift__c = 5;
      quoteList[0].QTB_Year_3_Uplift__c = 5;
      quoteList[0].QTB_Year_4_Uplift__c = 5;
      quoteList[0].QTB_Year_5_Uplift__c = 5;
      quoteList[0].QTB_Year_6_Uplift__c = 5;
      quoteList[0].QTB_Year_7_Uplift__c = 5;
      quoteList[0].QTB_Year_8_Uplift__c = 5;
      quoteList[0].QTB_Year_9_Uplift__c = 5;
      quoteList[0].QTB_Year_10_Uplift__c = 5;
      quoteList[0].QTB_Opportunity_Billing_Country__c = 'Hong Kong';
      database.update(quoteList);
      Test.stopTest();
      List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
        1,
        quoteList[0].id,
        accountList[0].id
      );
      List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(
        2,
        quoteList[0].id,
        quoteGroupList[0].id,
        product[0].id
      );
      quoteLinesList[0].QTB_Display_in_Price_Schedule__c = true;
      quoteLinesList[0].QTB_Unit_of_Measure__c = 'CF';
      quoteLinesList[1].QTB_Display_in_Price_Schedule__c = true;
      quoteLinesList[1].QTB_Unit_of_Measure__c = 'Box';
      update quoteLinesList;

      SBQQ__QuoteTemplate__c template = new SBQQ__QuoteTemplate__c();
      template.Name = QTB_Constants.DRAFT_PRICE;
      insert template;

      List<QTB_Customer_Billing_Account_Lookup__c> billingAccountList = QTB_TestDataFactory.imsightsToQuote(
        1,
        quoteList[0].id,
        accountList[0].id
      );
         System.assertEquals('Box', quoteLinesList[1].QTB_Unit_of_Measure__c);
        
      
    }
  }
   static testMethod void testmethod1(){
        Test.startTest();
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) { 
         List<SBQQ__Quote__c> quoteList=[Select id from SBQQ__Quote__c limit 1];
       PageReference pageRef = page.QTB_QuoteTemplate_Tables;
      pageRef.getParameters().put('qid', string.valueof(quoteList[0].id));
      pageRef.getParameters().put('language', 'zh_TW');
      Test.setCurrentPage(pageRef);
      QTB_QuoteTemplateController con = new QTB_QuoteTemplateController(
        new ApexPages.StandardController(quoteList[0])
      );
      con.fetchQuotelineData();
      QTB_QuoteTemplateController.throwExplicitException = false;
        Test.stopTest();
      System.assertEquals(
        false,
        QTB_QuoteTemplateController.throwExplicitException,
        'Expected Exception'
      );
    }
   }

  // cover catch
  static testMethod void testmethod5() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
      QTB_QuoteTemplateController.throwExplicitException = true;
      QTB_QuoteTemplateController quoteControl = new QTB_QuoteTemplateController(
        null
      );
      quoteControl.fetchQuotelineData();
      Test.stopTest();
      System.assertEquals(
        true,
        QTB_QuoteTemplateController.throwExplicitException,
        'Expected Exception'
      );
    }
  }
}