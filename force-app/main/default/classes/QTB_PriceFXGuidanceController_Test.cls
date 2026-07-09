/*****************************************************************************************************
 * Class: QTB_priceFXGuidanceController_Test
 * Author: Accenture
 * Purpose: This is a test class for QTB_OrderHelper
 * Change History: 6/15/2020
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture
 *******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_PriceFXGuidanceController_Test {
  @TestSetup
  static void testData() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
      custSetting.SObject_API_Name__c = 'SBQQ__Quote__c;SBQQ__QuoteLine__c;Account';
      custSetting.Disable_VR__c = true;
      custSetting.Disable_PB__c = true;
      custSetting.Disable_Trigger__c = true;
      // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      insert custSetting;

      List<account> accountList = QTB_TestDataFactory.createAccounts(4);
      accountList[0].IM_Industry__c = 'NonClassifable Establishment';
      database.update(accountList);

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

      IM_Country__c country = new IM_Country__c(
        Name = 'United States',
        Iso31662Code__c = 'US'
      );
      database.insert(country);
      Market__c market = new Market__c(
        Name = 'Atlanta',
        District_NAME__c = 'Atlanta'
      );
      database.insert(market);

      List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
      oppList[0].Pricebook2Id = pricebookId;
      oppList[0].billing_country__c = country.id;
      oppList[0].recordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
      oppList[0].Primary_Product_Line__c = 'Records Management';
      oppList[0].type = 'New Deal';

      oppList[3].Pricebook2Id = pricebookId;
      oppList[3].billing_country__c = country.id;
      oppList[3].recordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
      oppList[3].Primary_Product_Line__c = 'SMB Packages';
      oppList[3].type = 'New Deal';

      oppList[1].Pricebook2Id = pricebookId;
      oppList[1].billing_country__c = country.id;
      oppList[1].recordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
      oppList[1].Primary_Product_Line__c = 'Data Management';
      oppList[1].type = 'New Deal';

      oppList[2].Pricebook2Id = pricebookId;
      oppList[2].billing_country__c = country.id;
      oppList[2].recordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
      oppList[2].Primary_Product_Line__c = 'Shred';
      oppList[2].type = 'New Deal';

      database.update(oppList);

      List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
        1,
        oppList[0].id,
        accountList[0].id,
        true,
        null
      );
      quoteList[0].SBQQ__PriceBook__c = pricebookId;
      quoteList[0].SBQQ__StartDate__c = System.Today();
      quoteList[0].QTB_Number_of_markets__c = 3;
      quoteList[0].SBQQ__Status__c = 'Draft';
      quoteList[0].QTB_Quantity__c = 1000000;
      database.update(quoteList);

      List<SBQQ__Quote__c> quoteList2 = QTB_TestDataFactory.createCPQQuotes(
        2,
        oppList[1].id,
        accountList[0].id,
        true,
        null
      );
      quoteList2[0].SBQQ__PriceBook__c = pricebookId;
      quoteList2[0].SBQQ__StartDate__c = System.Today();
      quoteList2[0].QTB_Number_of_markets__c = 3;
      quoteList2[0].SBQQ__Status__c = 'Draft';
      quoteList2[0].QTB_Quantity__c = 1000000;
      quoteList2[0].QTB_Primary_Market__c = market.id;
      database.update(quoteList2);

      List<SBQQ__Quote__c> quoteList6 = QTB_TestDataFactory.createCPQQuotes(
        1,
        oppList[1].id,
        accountList[0].id,
        true,
        null
      );
      quoteList6[0].SBQQ__PriceBook__c = pricebookId;
      quoteList6[0].SBQQ__StartDate__c = System.Today();
      quoteList6[0].SBQQ__Status__c = 'Draft';
      database.update(quoteList6);

      List<SBQQ__Quote__c> quoteList3 = QTB_TestDataFactory.createCPQQuotes(
        1,
        oppList[2].id,
        accountList[0].id,
        true,
        null
      );
      List<SBQQ__Quote__c> quoteList4 = QTB_TestDataFactory.createCPQQuotes(
        2,
        oppList[0].id,
        accountList[0].id,
        true,
        null
      );
      List<SBQQ__Quote__c> quoteList5 = QTB_TestDataFactory.createCPQQuotes(
        2,
        oppList[2].id,
        accountList[0].id,
        true,
        null
      );
      List<SBQQ__Quote__c> quoteList7 = QTB_TestDataFactory.createCPQQuotes(
        1,
        oppList[3].id,
        accountList[0].id,
        true,
        null
      );

      quoteList4[0].SBQQ__Status__c = 'Approved';
      database.update(quoteList4);
      Test.startTest();
      quoteList5[0].QTB_Price_FX_Date__c = system.today();
      database.update(quoteList5);

      List<QTB_Shred_Profile__c> shredList = QTB_TestDataFactory.createShredProfile(
        1,
        quoteList3[0].id
      );
      shredList[0].QTB_Number_of_Bins_Per_Stop__c = 5;
      shredList[0].QTB_Average_Distance_to_Depot__c = 20;
      ShredList[0].QTB_Expected_Annual_Revenue__c = 100000;
      shredList[0].QTB_Primary_Market__c = market.id;
      database.update(shredList);

      List<QTB_Shred_Profile__c> shredList2 = QTB_TestDataFactory.createShredProfile(
        1,
        quoteList5[0].id
      );

      SBQQ.TriggerControl.disable();
      List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
        1,
        quoteList[0].id,
        accountList[0].id
      );
      List<SBQQ__QuoteLineGroup__c> quoteGroupList2 = QTB_TestDataFactory.createCPQQuoteLineGroups(
        1,
        quoteList2[0].id,
        accountList[0].id
      );
      List<SBQQ__QuoteLineGroup__c> quoteGroupList3 = QTB_TestDataFactory.createCPQQuoteLineGroups(
        1,
        quoteList3[0].id,
        accountList[0].id
      );

      List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(
        1,
        quoteList[0].id,
        quoteGroupList[0].id,
        product[0].id
      );
      List<SBQQ__QuoteLine__c> quoteLinesList2 = QTB_TestDataFactory.createCPQQuoteLines(
        1,
        quoteList2[0].id,
        quoteGroupList2[0].id,
        product[0].id
      );
      List<SBQQ__QuoteLine__c> quoteLinesList3 = QTB_TestDataFactory.createCPQQuoteLines(
        1,
        quoteList3[0].id,
        quoteGroupList3[0].id,
        product[0].id
      );
      QTB_TestDataFactory.createBypassSetting(
        QTB_Constants.TYPE_CONTRACT +
        ';' +
        QTB_Constants.SOBJECT_ORDER
      );
      List<Order> testorder = QTB_TestDataFactory.createCPQOrders(
        1,
        quoteList[0].id,
        accountList[0].id
      );
      QTB_TestDataFactory.createBypassSetting(
        QTB_Constants.TYPE_SBQQ_QUOTELINE +
        ';' +
        QTB_Constants.TYPE_CONTRACT
      );
      List<Contract> testContracts = QTB_TestDataFactory.createCPQContracts(
        1,
        testorder[0].id,
        accountList[0].id,
        quoteList[0].id
      );
      testContracts[0].SBQQ__Quote__c = quoteList[0].id;
      database.update(testContracts);

      List<Opportunity> testRenewalOpp = QTB_TestDataFactory.createCPQOppsNew(
        accountList,
        'CPQ Sales Opportunity'
      );
      testRenewalOpp[0].SBQQ__RenewedContract__c = testContracts[0].id;
      testRenewalOpp[0].QTB_Deferred_Renewal_Opportunity__c = true;
      testRenewalOpp[0].QTB_Original_Quote__c = quoteList[0].id;
      testRenewalOpp[0].billing_country__c = country.id;
      testRenewalOpp[0].Primary_Product_Line__c = 'Records Management';
      database.update(testRenewalOpp);

      List<SBQQ__Quote__c> testRenewalQuotes = QTB_TestDataFactory.createRenewalQuotes(
        1,
        testRenewalOpp[0].Id,
        oppList[0].AccountId,
        false,
        null
      );
      testRenewalQuotes[0].SBQQ__Opportunity2__c = testRenewalOpp[0].id;
      testRenewalQuotes[0].QTB_Reset_to_Original_Prices__c = false;
      testRenewalQuotes[0].SBQQ__Status__c = 'Draft';
      testRenewalQuotes[0].QTB_Number_of_Markets__c = 6;
      testRenewalQuotes[0].QTB_Quantity__c = 1000000;
      database.update(testRenewalQuotes);
      List<SBQQ__QuoteLineGroup__c> quoteGroupList4 = QTB_TestDataFactory.createCPQQuoteLineGroups(
        1,
        testRenewalQuotes[0].id,
        accountList[0].id
      );
      SBQQ.TriggerControl.disable();

      List<SBQQ__QuoteLine__c> quoteLinesList4 = QTB_TestDataFactory.createCPQQuoteLines(
        1,
        testRenewalQuotes[0].id,
        quoteGroupList4[0].id,
        product[0].id
      );
      quoteLinesList4[0].SBQQ__ListPrice__c = 10;
      quoteLinesList4[0].QTB_Floor_Price__c = 0;
      quoteLinesList4[0].QTB_Target_Price__c = 0;
      quoteLinesList4[0].QTB_Expert_Price__c = 0;
      quoteLinesList4[0].SBQQ__AdditionalDiscountAmount__c = 0;
      
      database.update(quoteLinesList4);

      List<QTB_Bill_Code_Product_Lookup__c> billcode = QTB_TestDataFactory.createBillCodeTable(
        1,
        product[0].id
      );
      billcode[0].QTB_Active__c = true;
      billcode[0].QTB_Primary__c = true;
      Billcode[0].QTB_Pricing_Bill_Code__c = '201';
      Billcode[0].QTB_Source_Bill_Code__c = '201';
      Billcode[0].QTB_Country__c = country.id;
      database.update(billcode);
      
      QTB_PriceFXGuidancePageController.CurrentRateInfo curRate = new QTB_PriceFXGuidancePageController.CurrentRateInfo();
      curRate.targetPrice = -5;
      QTB_PriceFXGuidancePageController.quoteLineMap = new Map<Id,SBQQ__QuoteLine__c>();
      QTB_PriceFXGuidancePageController.disPercentage = 10;
      QTB_PriceFXGuidancePageController.renewalQuotelines(quoteLinesList4[0],curRate);
      
      QTB_PriceFXGuidancePageController.BillCodeRates bic = new QTB_PriceFXGuidancePageController.BillCodeRates();
      bic.targetPrice = -2;
      QTB_PriceFXGuidancePageController.disPercentage = 10;
      QTB_PriceFXGuidancePageController.quoteLineMap = new Map<Id,SBQQ__QuoteLine__c>();
      QTB_PriceFXGuidancePageController.newcustomerQuotelines(quoteLinesList4[0],bic);
      
      Test.stopTest();
      List<IM_Customer_Account__c> customerAccount = QTB_TestDataFactory.createCustomerAccount(
        1,
        accountList[0].id
      );
      customerAccount[0].Billing_Country__c = country.id;
      database.update(customerAccount);

      List<QTB_Customer_Billing_Account_Lookup__c> customerTable = QTB_TestDataFactory.imsightsToQuote(
        1,
        quoteList[0].id,
        customerAccount[0].id
      );
      customerTable[0].QTB_Pricefx_Customer_ID__c = '140AI';
      database.update(customerTable);
    }

  }

  static testMethod void testCallout() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      SBQQ__Quote__c testQuote = [
        SELECT
          Id,
          name,
          SBQQ__Status__c,
          QTB_Opportunity_Product_Line__c,
          SBQQ__BillingCountry__c,
          RecordTypeId,
          QTB_Primary_Market__c,
          SBQQ__Account__r.IM_Industry__c,
          SBQQ__Account__r.billingCountry,
          SBQQ__Type__c,
          SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.sbqq__quote__c,
          QTB_Number_of_Markets__c,
          QTB_Primary_Market__r.District_name__c,
          QTB_Price_FX_Date__c,
          SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c,
          QTB_Quantity__c,
          SBQQ__Opportunity2__r.billing_country__r.name,
          SBQQ__Opportunity2__r.billing_country__c,
          (
            SELECT
              Id,
              name,
              QTB_Number_of_Bins_Per_Stop__c,
              QTB_Average_Distance_to_Depot__c,
              QTB_Expected_Annual_Revenue__c,
              QTB_Primary_Market__c,
              QTB_Primary_Market__r.District_name__c
            FROM Shred_Profiles__r
            LIMIT 1
          ),
          (
            SELECT
              Id,
              name,
              SBQQ__Quantity__c,
              SBQQ__ProductCode__c,
              SBQQ__ListPrice__c,
              SBQQ__AdditionalDiscountAmount__c,
              SBQQ__Product__r.name,
              SBQQ__Product__r.bill_code__c,
              QTB_Target_Price__c,
              QTB_Floor_Price__c,
              QTB_Expert_Price__c
            FROM SBQQ__LineItems__r
            LIMIT 1
          )
        FROM SBQQ__Quote__c
        WHERE
          SBQQ__Type__c != 'Renewal'
          AND QTB_Opportunity_Product_Line__c = 'Records Management'
        LIMIT 1
      ];

      PageReference pageRef = page.QTB_PriceFXGuidancePage;
      pageRef.getParameters().put('id', string.valueof(testQuote.id));
      Test.setCurrentPage(pageRef);
      Test.startTest();
      new QTB_PriceFXGuidancePageController();
      Test.setMock(HttpCalloutMock.class, new QTB_MockPricefxCallout());
      QTB_PriceFXGuidancePageController.getPricefxandRedirect();
      QTB_PriceFXGuidancePageController.goBack();
      Test.stopTest();
      system.assertEquals(
        'Records Management',
        testQuote.QTB_Opportunity_Product_Line__c
      );
    }
  }
  static testMethod void testCallout2() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      SBQQ__Quote__c testQuote = [
        SELECT
          Id,
          name,
          SBQQ__Status__c,
          QTB_Opportunity_Product_Line__c,
          SBQQ__BillingCountry__c,
          RecordTypeId,
          QTB_Primary_Market__c,
          SBQQ__Account__r.IM_Industry__c,
          SBQQ__Account__r.billingCountry,
          SBQQ__Type__c,
          SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.sbqq__quote__c,
          QTB_Number_of_Markets__c,
          QTB_Primary_Market__r.District_name__c,
          QTB_Price_FX_Date__c,
          SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c,
          QTB_Quantity__c,
          SBQQ__Opportunity2__r.billing_country__r.name,
          SBQQ__Opportunity2__r.billing_country__c,
          (
            SELECT
              Id,
              name,
              QTB_Number_of_Bins_Per_Stop__c,
              QTB_Average_Distance_to_Depot__c,
              QTB_Expected_Annual_Revenue__c,
              QTB_Primary_Market__c,
              QTB_Primary_Market__r.District_name__c
            FROM Shred_Profiles__r
            LIMIT 1
          ),
          (
            SELECT
              Id,
              name,
              SBQQ__Quantity__c,
              SBQQ__ProductCode__c,
              SBQQ__ListPrice__c,
              SBQQ__AdditionalDiscountAmount__c,
              SBQQ__Product__r.name,
              SBQQ__Product__r.bill_code__c,
              QTB_Target_Price__c,
              QTB_Floor_Price__c,
              QTB_Expert_Price__c
            FROM SBQQ__LineItems__r
            LIMIT 1
          )
        FROM SBQQ__Quote__c
        WHERE
          QTB_Opportunity_Product_Line__c = 'Data Management'
          AND QTB_Number_of_markets__c != NULL
        LIMIT 1
      ];
      Test.startTest();
      PageReference pageRef = page.QTB_PriceFXGuidancePage;
      pageRef.getParameters().put('id', string.valueof(testQuote.id));
      Test.setCurrentPage(pageRef);
      new QTB_PriceFXGuidancePageController();
      Test.setMock(HttpCalloutMock.class, new QTB_MockPricefxCallout());
      QTB_PriceFXGuidancePageController.getPricefxandRedirect();
      QTB_PriceFXGuidancePageController.goBack();
      Test.StopTest();
      system.assertEquals(
        'Data Management',
        testQuote.QTB_Opportunity_Product_Line__c
      );
    }
  }
  static testMethod void testCallout3() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      SBQQ__Quote__c testQuote = [
        SELECT
          Id,
          name,
          SBQQ__Status__c,
          QTB_Opportunity_Product_Line__c,
          SBQQ__BillingCountry__c,
          RecordTypeId,
          QTB_Primary_Market__c,
          SBQQ__Account__r.IM_Industry__c,
          SBQQ__Account__r.billingCountry,
          SBQQ__Type__c,
          SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.sbqq__quote__c,
          QTB_Number_of_Markets__c,
          QTB_Primary_Market__r.District_name__c,
          QTB_Price_FX_Date__c,
          SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c,
          QTB_Quantity__c,
          SBQQ__Opportunity2__r.billing_country__r.name,
          SBQQ__Opportunity2__r.billing_country__c,
          (
            SELECT
              Id,
              name,
              QTB_Number_of_Bins_Per_Stop__c,
              QTB_Average_Distance_to_Depot__c,
              QTB_Expected_Annual_Revenue__c,
              QTB_Primary_Market__c,
              QTB_Primary_Market__r.District_name__c
            FROM Shred_Profiles__r
            LIMIT 1
          ),
          (
            SELECT
              Id,
              name,
              SBQQ__Quantity__c,
              SBQQ__ProductCode__c,
              SBQQ__ListPrice__c,
              SBQQ__AdditionalDiscountAmount__c,
              SBQQ__Product__r.name,
              SBQQ__Product__r.bill_code__c,
              QTB_Target_Price__c,
              QTB_Floor_Price__c,
              QTB_Expert_Price__c
            FROM SBQQ__LineItems__r
            LIMIT 1
          )
        FROM SBQQ__Quote__c
        WHERE QTB_Opportunity_Product_Line__c = 'Shred'
        LIMIT 1
      ];
      Test.startTest();
      PageReference pageRef = page.QTB_PriceFXGuidancePage;
      pageRef.getParameters().put('id', string.valueof(testQuote.id));
      Test.setCurrentPage(pageRef);
      new QTB_PriceFXGuidancePageController();
      Test.setMock(HttpCalloutMock.class, new QTB_MockPricefxCallout());
      QTB_PriceFXGuidancePageController.getPricefxandRedirect();
      QTB_PriceFXGuidancePageController.goBack();
      Test.StopTest();
      system.assertEquals('Shred', testQuote.QTB_Opportunity_Product_Line__c);
    }
  }
  static testMethod void testCallout4() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      SBQQ__Quote__c testQuote = [
        SELECT
          Id,
          name,
          SBQQ__Status__c,
          QTB_Opportunity_Product_Line__c,
          SBQQ__BillingCountry__c,
          RecordTypeId,
          QTB_Primary_Market__c,
          SBQQ__Account__r.IM_Industry__c,
          SBQQ__Account__r.billingCountry,
          SBQQ__Type__c,
          SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.sbqq__quote__c,
          QTB_Number_of_Markets__c,
          QTB_Primary_Market__r.District_name__c,
          QTB_Price_FX_Date__c,
          SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c,
          QTB_Quantity__c,
          SBQQ__Opportunity2__r.billing_country__r.name,
          SBQQ__Opportunity2__r.billing_country__c,
          SBQQ__Opportunity2__r.QTB_Original_Quote__c,
          (
            SELECT
              Id,
              name,
              QTB_Number_of_Bins_Per_Stop__c,
              QTB_Average_Distance_to_Depot__c,
              QTB_Expected_Annual_Revenue__c,
              QTB_Primary_Market__c,
              QTB_Primary_Market__r.District_name__c
            FROM Shred_Profiles__r
            LIMIT 1
          ),
          (
            SELECT
              Id,
              name,
              SBQQ__Quantity__c,
              SBQQ__ProductCode__c,
              SBQQ__ListPrice__c,
              SBQQ__AdditionalDiscountAmount__c,
              SBQQ__Product__r.name,
              SBQQ__Product__r.bill_code__c,
              QTB_Target_Price__c,
              QTB_Floor_Price__c,
              QTB_Expert_Price__c
            FROM SBQQ__LineItems__r
            LIMIT 1
          )
        FROM SBQQ__Quote__c
        WHERE SBQQ__Type__c = 'Renewal'
        LIMIT 1
      ];
      PageReference pageRef = page.QTB_PriceFXGuidancePage;
      pageRef.getParameters().put('id', string.valueof(testQuote.id));
      Test.setCurrentPage(pageRef);
      Test.startTest();
      new QTB_PriceFXGuidancePageController();
      Test.setMock(HttpCalloutMock.class, new QTB_MockPricefxCalloutRenewal());
      QTB_PriceFXGuidancePageController.getPricefxandRedirect();
      Test.StopTest();
      system.assertEquals('Renewal', testQuote.SBQQ__Type__c);
    }
  }
  static testMethod void testCalloutError() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      SBQQ__Quote__c testQuote = [
        SELECT
          Id,
          name,
          SBQQ__Status__c,
          QTB_Opportunity_Product_Line__c,
          SBQQ__BillingCountry__c,
          RecordTypeId,
          QTB_Primary_Market__c,
          SBQQ__Account__r.IM_Industry__c,
          SBQQ__Account__r.billingCountry,
          SBQQ__Type__c,
          SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.sbqq__quote__c,
          QTB_Number_of_Markets__c,
          QTB_Primary_Market__r.District_name__c,
          QTB_Price_FX_Date__c,
          SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c,
          QTB_Quantity__c,
          SBQQ__Opportunity2__r.billing_country__r.name,
          SBQQ__Opportunity2__r.billing_country__c,
          (
            SELECT
              Id,
              name,
              QTB_Number_of_Bins_Per_Stop__c,
              QTB_Average_Distance_to_Depot__c,
              QTB_Expected_Annual_Revenue__c,
              QTB_Primary_Market__c,
              QTB_Primary_Market__r.District_name__c
            FROM Shred_Profiles__r
            LIMIT 1
          ),
          (
            SELECT
              Id,
              name,
              SBQQ__Quantity__c,
              SBQQ__ProductCode__c,
              SBQQ__ListPrice__c,
              SBQQ__AdditionalDiscountAmount__c,
              SBQQ__Product__r.name,
              SBQQ__Product__r.bill_code__c,
              QTB_Target_Price__c,
              QTB_Floor_Price__c,
              QTB_Expert_Price__c
            FROM SBQQ__LineItems__r
            LIMIT 1
          )
        FROM SBQQ__Quote__c
        WHERE
          QTB_Opportunity_Product_Line__c = 'Records Management'
          AND QTB_Number_of_Markets__c = NULL
        LIMIT 1
      ];

      PageReference pageRef = page.QTB_PriceFXGuidancePage;
      pageRef.getParameters().put('id', string.valueof(testQuote.id));
      Test.setCurrentPage(pageRef);
      Test.startTest();
      new QTB_PriceFXGuidancePageController();
      Test.setMock(HttpCalloutMock.class, new QTB_MockPricefxCalloutRenewal());
      QTB_PriceFXGuidancePageController.getPricefxandRedirect();
      Test.StopTest();
      system.assertEquals(
        'Records Management',
        testQuote.QTB_Opportunity_Product_Line__c
      );
    }
  }
  static testMethod void testCalloutError2() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      SBQQ__Quote__c testQuote = [
        SELECT
          Id,
          name,
          SBQQ__Status__c,
          QTB_Opportunity_Product_Line__c,
          SBQQ__BillingCountry__c,
          RecordTypeId,
          QTB_Primary_Market__c,
          SBQQ__Account__r.IM_Industry__c,
          SBQQ__Account__r.billingCountry,
          SBQQ__Type__c,
          SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.sbqq__quote__c,
          QTB_Number_of_Markets__c,
          QTB_Primary_Market__r.District_name__c,
          QTB_Price_FX_Date__c,
          SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c,
          QTB_Quantity__c,
          SBQQ__Opportunity2__r.billing_country__r.name,
          SBQQ__Opportunity2__r.billing_country__c,
          (
            SELECT
              Id,
              name,
              QTB_Number_of_Bins_Per_Stop__c,
              QTB_Average_Distance_to_Depot__c,
              QTB_Expected_Annual_Revenue__c,
              QTB_Primary_Market__c,
              QTB_Primary_Market__r.District_name__c
            FROM Shred_Profiles__r
            LIMIT 1
          ),
          (
            SELECT
              Id,
              name,
              SBQQ__Quantity__c,
              SBQQ__ProductCode__c,
              SBQQ__ListPrice__c,
              SBQQ__AdditionalDiscountAmount__c,
              SBQQ__Product__r.name,
              SBQQ__Product__r.bill_code__c,
              QTB_Target_Price__c,
              QTB_Floor_Price__c,
              QTB_Expert_Price__c
            FROM SBQQ__LineItems__r
            LIMIT 1
          )
        FROM SBQQ__Quote__c
        WHERE QTB_Price_FX_Date__c != NULL
        LIMIT 1
      ];
      Test.startTest();
      PageReference pageRef = page.QTB_PriceFXGuidancePage;
      pageRef.getParameters().put('id', string.valueof(testQuote.id));
      Test.setCurrentPage(pageRef);
      new QTB_PriceFXGuidancePageController();
      Test.setMock(HttpCalloutMock.class, new QTB_MockPricefxCalloutRenewal());
      QTB_PriceFXGuidancePageController.getPricefxandRedirect();
      Test.StopTest();
      system.assert(testQuote.QTB_Price_FX_Date__c != null);
    }
  }
  static testMethod void testCalloutError3() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      SBQQ__Quote__c testQuote = [
        SELECT
          Id,
          name,
          SBQQ__Status__c,
          QTB_Opportunity_Product_Line__c,
          SBQQ__BillingCountry__c,
          RecordTypeId,
          QTB_Primary_Market__c,
          SBQQ__Account__r.IM_Industry__c,
          SBQQ__Account__r.billingCountry,
          SBQQ__Type__c,
          SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.sbqq__quote__c,
          QTB_Number_of_Markets__c,
          QTB_Primary_Market__r.District_name__c,
          QTB_Price_FX_Date__c,
          SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c,
          QTB_Quantity__c,
          SBQQ__Opportunity2__r.billing_country__r.name,
          SBQQ__Opportunity2__r.billing_country__c,
          (
            SELECT
              Id,
              name,
              QTB_Number_of_Bins_Per_Stop__c,
              QTB_Average_Distance_to_Depot__c,
              QTB_Expected_Annual_Revenue__c,
              QTB_Primary_Market__c,
              QTB_Primary_Market__r.District_name__c
            FROM Shred_Profiles__r
            LIMIT 1
          ),
          (
            SELECT
              Id,
              name,
              SBQQ__Quantity__c,
              SBQQ__ProductCode__c,
              SBQQ__ListPrice__c,
              SBQQ__AdditionalDiscountAmount__c,
              SBQQ__Product__r.name,
              SBQQ__Product__r.bill_code__c,
              QTB_Target_Price__c,
              QTB_Floor_Price__c,
              QTB_Expert_Price__c
            FROM SBQQ__LineItems__r
            LIMIT 1
          )
        FROM SBQQ__Quote__c
        WHERE
          QTB_Opportunity_Product_Line__c = 'Data Management'
          AND QTB_Number_of_markets__c = NULL
        LIMIT 1
      ];
      Test.startTest();
      PageReference pageRef = page.QTB_PriceFXGuidancePage;
      pageRef.getParameters().put('id', string.valueof(testQuote.id));
      Test.setCurrentPage(pageRef);
      new QTB_PriceFXGuidancePageController();
      Test.setMock(HttpCalloutMock.class, new QTB_MockPricefxCallout());
      QTB_PriceFXGuidancePageController.getPricefxandRedirect();
      QTB_PriceFXGuidancePageController.goBack();
      Test.StopTest();
      system.assertEquals(
        'Data Management',
        testQuote.QTB_Opportunity_Product_Line__c
      );
    }
  }
  static testMethod void testException() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      QTB_PriceFXGuidancePageController.throwExplicitException = true;
      SBQQ__Quote__c testQuote = [
        SELECT
          Id,
          name,
          SBQQ__Status__c,
          QTB_Opportunity_Product_Line__c,
          SBQQ__BillingCountry__c,
          RecordTypeId,
          QTB_Primary_Market__c,
          SBQQ__Account__r.IM_Industry__c,
          SBQQ__Account__r.billingCountry,
          SBQQ__Type__c,
          SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.sbqq__quote__c,
          QTB_Number_of_Markets__c,
          QTB_Primary_Market__r.District_name__c,
          QTB_Price_FX_Date__c,
          SBQQ__Opportunity2__r.billing_country__r.Iso31662Code__c,
          QTB_Quantity__c,
          SBQQ__Opportunity2__r.billing_country__r.name,
          SBQQ__Opportunity2__r.billing_country__c,
          (
            SELECT
              Id,
              name,
              QTB_Number_of_Bins_Per_Stop__c,
              QTB_Average_Distance_to_Depot__c,
              QTB_Expected_Annual_Revenue__c,
              QTB_Primary_Market__c,
              QTB_Primary_Market__r.District_name__c
            FROM Shred_Profiles__r
            LIMIT 1
          ),
          (
            SELECT
              Id,
              name,
              SBQQ__Quantity__c,
              SBQQ__ProductCode__c,
              SBQQ__ListPrice__c,
              SBQQ__AdditionalDiscountAmount__c,
              SBQQ__Product__r.name,
              SBQQ__Product__r.bill_code__c,
              QTB_Target_Price__c,
              QTB_Floor_Price__c,
              QTB_Expert_Price__c
            FROM SBQQ__LineItems__r
            LIMIT 1
          )
        FROM SBQQ__Quote__c
        WHERE
          SBQQ__Type__c != 'Renewal'
          AND QTB_Opportunity_Product_Line__c = 'SMB Packages'
        LIMIT 1
      ];
      Test.startTest();
      PageReference pageRef = page.QTB_PriceFXGuidancePage;
      pageRef.getParameters().put('id', string.valueof(testQuote.id));
      Test.setCurrentPage(pageRef);
      new QTB_PriceFXGuidancePageController();
      Test.setMock(HttpCalloutMock.class, new QTB_MockPricefxCallout());
      QTB_PriceFXGuidancePageController.getPricefxandRedirect();
      QTB_PriceFXGuidancePageController.goBack();
      Test.StopTest();
      system.assertEquals(
        'SMB Packages',
        testQuote.QTB_Opportunity_Product_Line__c
      );
    }

  }
  
  
}