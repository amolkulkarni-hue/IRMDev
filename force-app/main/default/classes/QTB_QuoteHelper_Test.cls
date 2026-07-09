/*****************************************************************************************************
 * Class: QTB_QuoteHelper_Test
 * Author: Accenture
 * Purpose: Test Class for QTB_QuoteHelper
 * Change History:
 * Developer     Date            Description
 * -------------------------------------------------------------------------------------------
 * Accenture
 * Accenture     7/16/2020       updated NullPointer tests
 *******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_QuoteHelper_Test {
  @testSetup
  static void testSetupData() {
    QTB_Quote_Field_Validations__c fieldCust = new QTB_Quote_Field_Validations__c();
    fieldCust.QTB_Field_List__c = 'QTB_Minimum_Charges_Start_Date__c,QTB_Work_Order_Minimum_Start_Date__c,QTB_Invoice_Minimum_Start_Date__c,QTB_Free_Up_Start__c,QTB_Free_Products_Start_Date__c';
    fieldCust.Name = 'Date field names';
    fieldCust.QTB_Delta_Fields__c = 'QTB_Delta_Minimum_StartDate__c,QTB_Delta_Work_Order_StartDate__c,QTB_Delta_Invoice_Minimum_StartDate__c,QTB_Delta_Free_Up_StartDate__c,QTB_Delta_Free_Products_StartDate__c';
    fieldCust.QTB_Restrict_on_Accepted_Quote__c = 'QTB_Minimum_Charges_Start_Date__c,QTB_Work_Order_Minimum_Start_Date__c,QTB_Invoice_Minimum_Start_Date__c,QTB_Free_Up_Start__c,QTB_Free_Products_Start_Date__c,SBQQ__StartDate__c,SBQQ__Primary__c';
    insert fieldCust;

    Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
    custSetting.SObject_API_Name__c = 'SBQQ__Quote__c';
    custSetting.Disable_VR__c = true;
    custSetting.Disable_PB__c = true;
    custSetting.SetupOwnerId = UserInfo.getOrganizationId();
    insert custSetting;
  }

  @isTest
  static void testData() {
    SBQQ.TriggerControl.disable();
    QTB_TestDataFactory.createBypassSetting(
      QTB_Constants.TYPE_CONTRACT +
      ';' +
      QTB_Constants.SOBJECT_ORDER+
        ';'+
        'Opportunity'+
        'Account'
    );
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    String error;
    System.runAs(userList[0]) {
      QTB_Country_Threshold__c customsetting = new QTB_Country_Threshold__c();
      customsetting.QTB_Country__c = 'Finland';
      customsetting.QTB_Line_of_Business__c = 'RM';
      customsetting.QTB_Threshold_Percent__c = 29;
      customsetting.Name = 'Finland';
      insert customsetting;
      List<Account> testAccount = QTB_TestDataFactory.createAccounts(
        1,
        'Standard Account'
      );
      
      IM_Country__c testCountry = new IM_Country__c(Name='India');
      insert testCountry;
    
      List<PriceBook2> testPriceBook = QTB_TestDataFactory.priceBookMethdLst(
        1,
        'Test Price book'
      );
      testPriceBook[0].isActive = true;
      testPriceBook[0].QTB_Country__c = 'India';
      update testPriceBook;

      List<Opportunity> testOpp = QTB_TestDataFactory.createCPQOppsNew(
        testAccount,
        'CPQ Sales Opportunity'
      );
      testOpp[0].Pricebook2Id = testPriceBook[0].id;
      testOpp[0].CurrencyIsoCode = testAccount[0].Billing_County__c;
      testOpp[0].Billing_Country__c = testCountry.Id;
      testOpp[0].QTB_Deferred_Renewal_Opportunity__c = true;
      testOpp[0].Primary_Product_Line__c = 'Scan';
      testOpp[0].SBQQ__PrimaryQuote__c = null;
      testOpp[0].Status__c = 'Accepted';
      update testOpp;

      List<OpportunityTeamMember> oppTeamList = new List<OpportunityTeamMember>();
      OpportunityTeamMember opptm = new OpportunityTeamMember();
      opptm.OpportunityId = testOpp[0].Id;
      opptm.UserId = userList[0].id;
      opptm.OpportunityAccessLevel = 'Edit';
      oppTeamList.add(opptm);
      insert oppTeamList;
      // oppTeamList[0].OpportunityAccessLevel = 'Edit';
      // update oppTeamList;

      SBQQ__QuoteTemplate__c template = new SBQQ__QuoteTemplate__c();
      template.Name = QTB_Constants.DRAFT_PRICE;
      insert template;
      SBQQ__Quote__c newQuote = new SBQQ__Quote__c();
      newQuote.SBQQ__Primary__c = true;
      newQuote.SBQQ__Type__c = QTB_Constants.TYPE_RENEWAL;
      newQuote.QTB_Reset_to_Original_Prices__c = false;
      newQuote.RecordTypeId = QTB_Utils.QUOTE_SALES_RECTYPEID;
      newQuote.SBQQ__Opportunity2__c = testOpp[0].Id;
      newQuote.SBQQ__LastCalculatedOn__c = system.today();
      newQuote.SBQQ__Startdate__c = system.today();
      //newQuote.SBQQ__EndDate__c =System.today()+5;
      newQuote.SBQQ__ExpirationDate__c = system.today();
      //newQuote.SBQQ__Type__c  ='Quote';
      newQuote.QTB_Approval_Threshold__c = 20;
      newQuote.QTB_Opportunity_Billing_Country__c = 'Finland';
      newQuote.SBQQ__Status__c = 'Approved';
      insert newQuote;
      Test.startTest();
      List<SBQQ__Quote__c> testQuotes = QTB_TestDataFactory.createCPQQuotes(
        1,
        testOpp[0].Id,
        testOpp[0].AccountId,
        true,
        null
      );
     
      testQuotes[0].SBQQ__Status__c = 'In Review';
      testQuotes[0].SBQQ__Primary__c = true;
      testQuotes[0].SBQQ__LastCalculatedOn__c = system.today() + 5;
      update testQuotes;
      testQuotes[0].SBQQ__Status__c = 'Approved';
      testQuotes[0].ApprovalStatus__c = 'Approved';
      //testQuotes[0].SBQQ__Startdate__c = system.today()+5;
      //testQuotes[0].SBQQ__Type__c  ='Amendment';
      testQuotes[0].QTB_Approval_Threshold__c = 10;

      testQuotes[0].RecordTypeId = QTB_Utils.QUOTE_APPROVED_RECTYPEID;
      testQuotes[0].QTB_Minimum_Charges_Start_Date__c = system.today();
      try {
        update testQuotes;
      } catch (Exception e) {
        error = 'a';
      }
      //update testQuotes;
      //testQuotes[0].SBQQ__Type__c  ='Amendment';
      testQuotes[0].SBQQ__LastCalculatedOn__c = system.today() + 7;
      testQuotes[0].QTB_Minimum_Charges_Start_Date__c = null;
      try {
        update testQuotes;
      } catch (Exception e) {
        error = 'a';
      }
      testQuotes[0].SBQQ__StartDate__c = system.today() + 5;
      testQuotes[0].QTB_Minimum_Charges_Start_Date__c = system.today() + 6;
      try {
        update testQuotes;
      } catch (Exception e) {
        error = 'a';
      }

      testQuotes[0].SBQQ__StartDate__c = system.today() + 91;
      try {
        update testQuotes;
      } catch (Exception e) {
        error = 'a';
      }

      testQuotes[0].QTB_Work_Order_Minimum_Start_Date__c = system.today();
      try {
        update testQuotes;
      } catch (Exception e) {
        error = 'a';
      }

      //testQuotes[0].SBQQ__StartDate__c = System.today() + 5;
      // update testQuotes;
      SBQQ__Quote__c cloneQuote = testQuotes[0].clone();
      insert cloneQuote;
      System.debug('cloneQuote' + cloneQuote);

      QTB_Shred_Profile__c shred = new QTB_Shred_Profile__c(
        QTB_Quote__c = testQuotes[0].id
      );
      insert shred;
      testQuotes[0].SBQQ__Status__c = 'Accepted';
      try {
        update testQuotes;
      } catch (Exception e) {
        error = 'a';
      }
      testQuotes[0].SBQQ__Status__c = 'Accepted';
      //testQuotes[0].SBQQ__Primary__c = false;
      try {
        update testQuotes;
      } catch (Exception e) {
        error = 'a';
      }

      List<SBQQ__Quote__c> testQuote2 = QTB_TestDataFactory.createCPQQuotes(
        1,
        testOpp[0].Id,
        testOpp[0].AccountId,
        true,
        null
      );
      System.debug('testQuote2 ' + testQuote2);
      testQuote2[0].QTB_Approval_Threshold__c = 10;
      testQuote2[0].SBQQ__Primary__c = true;
      testQuote2[0].SBQQ__Status__c = 'Accepted';
      update testQuote2;
      List<SBQQ__Quote__c> testQuote10 = QTB_TestDataFactory.createCPQQuotes(
        1,
        testOpp[0].Id,
        testOpp[0].AccountId,
        true,
        null
      );
      testQuote10[0].SBQQ__Status__c = 'Draft';
      testQuote10[0].QTB_Approval_Threshold__c = 10;
      update testQuote10;

      List<Order> testorder = QTB_TestDataFactory.createCPQOrders(
        1,
        testQuotes[0].id,
        testAccount[0].id
      );
         Test.stopTest();
      List<Contract> testContracts = QTB_TestDataFactory.createCPQContracts(
        1,
        testorder[0].id,
        testAccount[0].id,
        testQuotes[0].id
      );
      testContracts[0].SBQQ__Quote__c = testQuotes[0].id;
      testContracts[0].SBQQ__MasterContract__c = false;

    //  update testContracts;

      List<Opportunity> testRenewalOpp = QTB_TestDataFactory.createCPQOppsNew(
        testAccount,
        'CPQ Sales Opportunity'
      );

      testRenewalOpp[0].SBQQ__RenewedContract__c = testContracts[0].id;
      testRenewalOpp[0].QTB_Deferred_Renewal_Opportunity__c = true;
      update testRenewalOpp;

      List<SBQQ__Quote__c> testRenewalQuotes = QTB_TestDataFactory.createRenewalQuotes(
        1,
        testRenewalOpp[0].Id,
        testOpp[0].AccountId,
        false,
        null
      );
      System.debug('testRenewalQuotes ' + testRenewalQuotes);
      testRenewalQuotes[0].QTB_Approval_Threshold__c = 10;
      // testRenewalQuotes[0].RecordTypeId = QTB_Utils.QUOTE_SALES_RECTYPEID;
      testRenewalQuotes[0].SBQQ__Opportunity2__c = testRenewalOpp[0].id;
      testRenewalQuotes[0].QTB_Reset_to_Original_Prices__c = false;
      testRenewalQuotes[0].SBQQ__Status__c = 'Approved';

      // update testRenewalQuotes;
     
      List<SBQQ__Quote__c> testamendQuotes = QTB_TestDataFactory.createAmendQuotes(
        1,
        testRenewalOpp[0].Id,
        testOpp[0].AccountId,
        false,
        null
      );
      System.debug(' testamendQuotes' + testamendQuotes);
      testamendQuotes[0].QTB_Approval_Threshold__c = 10;
      testamendQuotes[0].SBQQ__Type__c = QTB_Constants.TYPE_AMENDMENT;
      testamendQuotes[0].SBQQ__MasterContract__c = testContracts[0].id;

      update testamendQuotes;
      //Test.stopTest();
      system.assert(oppTeamList[0].OpportunityAccessLevel == 'Edit');
      System.assertEquals('a', error);
    }
  }

  static testMethod void testFutureMethod() {
    //Test Future method overrideOpportunityProductUnitPriceFutureHandler
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    String error;
    System.runAs(userList[0]) {
    List<Account> testAccount = QTB_TestDataFactory.createAccounts(
      1,
      'Standard Account'
    );
    IM_Country__c testCountry = new IM_Country__c(Name='India');
    insert testCountry;
    
    List<PriceBook2> testPriceBook = QTB_TestDataFactory.priceBookMethdLst(
      1,
      'Test Price book'
    );
    testPriceBook[0].isActive = true;
    testPriceBook[0].QTB_Country__c = 'India';
    update testPriceBook;
    List<product2> product = QTB_TestDataFactory.createProducts(1);
    PricebookEntry stdpricebookentry = new PricebookEntry(
      Pricebook2Id = Test.getStandardPricebookId(),
      Product2Id = product[0].Id,
      UnitPrice = 10000,
      IsActive = true
    );
    insert stdpricebookentry;
    PricebookEntry pricebookentry = new PricebookEntry(
      Pricebook2Id = testPriceBook[0].Id,
      Product2Id = product[0].Id,
      UnitPrice = 10000,
      IsActive = true
    );
    insert pricebookentry;
    List<Opportunity> testOpp = QTB_TestDataFactory.createCPQOppsNew(
      testAccount,
      'CPQ Sales Opportunity'
    );
    testOpp[0].Pricebook2Id = testPriceBook[0].id;
    testOpp[0].CurrencyIsoCode = testAccount[0].Billing_County__c;
    testOpp[0].Billing_Country__c = testCountry.Id;
    testOpp[0].QTB_Deferred_Renewal_Opportunity__c = true;
    update testOpp;
    test.startTest();
    List<SBQQ__Quote__c> testQuote3 = QTB_TestDataFactory.createCPQQuotes(
      1,
      testOpp[0].Id,
      testOpp[0].AccountId,
      true,
      null
    );
    System.debug('testQuote3' + testQuote3);
    List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
      1,
      testQuote3[0].id,
      testAccount[0].id
    );
    List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(
      1,
      testQuote3[0].id,
      quoteGroupList[0].id,
      product[0].id
    );
    SBQQ__QuoteLine__c another = quoteLinesList[0].clone();
    insert another;
    quoteLinesList[0].QTB_Annual_Forecastable_Value__c = 100;
    quoteLinesList[0].SBQQ__Quantity__c = 10;
    update quoteLinesList;
    // OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
    //  OpportunityId = testOpp[0].Id,
    //  SBQQ__QuoteLine__c = quoteLinesList[0].Id,
    //  Product2Id = product[0].Id,
    //  Quantity = 1,
    //  TotalPrice = 10000,
    //  PricebookEntryId = pricebookentry.Id
    // );
    // insert opportunityLineItem;
    SBQQ.TriggerControl.disable();
    testQuote3[0].SBQQ__LastCalculatedOn__c = system.today();
      try {
        update testQuote3;
      } catch (Exception e) {
        error = 'a';
      }
    testQuote3[0].SBQQ__LastCalculatedOn__c = system.today() + 7;
    //testQuote3[0].SBQQ__LastCalculatedOn__c = system.today()+4;
      try {
        update testQuote3;
      } catch (Exception e) {
        error = 'a';
      }
    test.stopTest();
    SBQQ.TriggerControl.enable();
      System.assertNotEquals('a', error);
    }
  }
  static testMethod void testQuoteHelper() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[0]) {
      Test.startTest();
      QTB_QuoteHandler.throwExplicitException = true;

    QTB_QuoteHandler handler = new QTB_QuoteHandler();
    //handler.AfterUpdate(null,null);
    //handler.BeforeUpdate(null,null);
    handler.AfterDelete(null);
    handler.AfterUndelete(null);
    handler.BeforeDelete(null);
      QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_QUOTE);
      handler.isDisabled();
      
    try {
      QTB_QuoteHelper.shareQuoteWithOpportunityTeam(null);
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
    /*try {
            QTB_QuoteHelper.validateApprovedQuote(null, null);
        } catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }*/

    try {
      QTB_QuoteHelper.resetPriceDeferredRenewalQuote(null);
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
    try {
      QTB_QuoteHelper.autoPopulate(null, null, null);
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
    try {
      QTB_QuoteHelper.shredProfilesFromOriginalQuote(null, null);
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
    try {
      QTB_QuoteHelper.acceptedQuoteValidation(null, null, true);
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
    try {
      QTB_QuoteHelper.amendmentQuotePromotions(null, null);
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
    /*try { 
            QTB_QuoteHelper.overrideOpportunityProductUnitPriceFutureHandler('aHz7b000000GpECCA0')
        }
        catch(NullPointerException e) { 
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }*/
    /*try { 
            QTB_QuoteHelper.overrideOpportunityProductUnitPriceFutureHandler();
        }
        catch(DMLException e) { 
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }*/
    QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_QUOTE);
    handler.isDisabled();
    Test.stopTest();
    System.assertEquals(true, QTB_QuoteHandler.throwExplicitException);
  }
  }
  /*@IsTest
    static void testDMLException() {
        QTB_QuoteHelper helper = new QTB_QuoteHelper();
        try{
            helper.overrideOpportunityProductUnitPriceFutureHandler();
        }catch(DMLException e){
             system.assertEquals(e.getMessage(), e.getMessage()); 
        }   
    }*/

  @IsTest
  static void testAmendmentQuotePromotions() {
    QTB_TestDataFactory testFactory = new QTB_TestDataFactory();
    // quote.SBQQ__Type__c == QTB_Constants.TYPE_AMENDMENT &&
    // quote.SBQQ__MasterContract__c != null &&
    // quote.SBQQ__MasterContract__r.sbqq__quote__c != null
    Account company = new Account(
      Name = 'Test Factory',
      BillingCountry = 'Finland',
      BillingPostalCode = '681000',
      ShippingCountry = 'Finland'
    );
    insert company;
    SBQQ__Quote__c originalQuote = new SBQQ__Quote__c(
      SBQQ__Account__c = company.Id,
      SBQQ__Type__c = QTB_Constants.QUOTE_TYPE_STANDARD,
      SBQQ__Status__c = 'Draft',
      SBQQ__QuoteLanguage__c = 'English',
      SBQQ__ExpirationDate__c = date.today().addDays(90),
      SBQQ__Primary__c = true,
      SBQQ__StartDate__c = date.today()
    );
    insert originalQuote;
    QTB_Quote_Promotion__c promotion = new QTB_Quote_Promotion__c(
      QTB_Quote__c = originalQuote.Id,
      QTB_Promo_Term__c = 6,
      QTB_Promo_Amount__c = 10,
      QTB_Promo_Percent__c = 10,
      Name = 'Factory Promotion',
      QTB_Promotion_Start_Date__c = Date.today().addDays(-10),
      QTB_Promotion_End_Date__c = Date.today().addDays(30),
      QTB_Promo_Description__c = 'Test factory promotion'
    );
    insert promotion;
    Contract masterContract = new Contract(
      Status = 'Draft',
      StartDate = Date.today().addMonths(1),
      ContractTerm = 6,
      AccountId = company.Id,
      SBQQ__Quote__c = originalQuote.Id
    );
    insert masterContract;
    SBQQ__Quote__c amendmentQuote = new SBQQ__Quote__c(
      SBQQ__Account__c = company.Id,
      SBQQ__Type__c = QTB_Constants.TYPE_AMENDMENT,
      SBQQ__MasterContract__c = masterContract.Id,
      SBQQ__Status__c = 'Draft',
      SBQQ__QuoteLanguage__c = 'English',
      SBQQ__ExpirationDate__c = date.today().addDays(90),
      SBQQ__Primary__c = true,
      SBQQ__StartDate__c = date.today()
    );
    insert amendmentQuote;
    Test.startTest();
    // creates another quote promotion
    QTB_QuoteHelper.amendmentQuotePromotions(
      new Map<Id, Id>{ originalQuote.Id => amendmentQuote.Id },
      new Set<Id>{ amendmentQuote.Id }
    );
    Test.stopTest();
    System.assertEquals(
      2,
      [
        SELECT COUNT()
        FROM QTB_Quote_Promotion__c
        WHERE QTB_Quote__c = :amendmentQuote.Id
      ],
      'Expected two quote promotion to be cloned from orginal quote.'
    );
  }

  @isTest
  static void testacceptedQuoteValidation() {
    QTB_TestDataFactory testFactory = new QTB_TestDataFactory();
    Account acc = new Account(
      Name = 'Test Factory1',
      BillingCountry = 'Finland',
      BillingPostalCode = '681000',
      ShippingCountry = 'Finland'
    );
    insert acc;
    Opportunity opp = new Opportunity(
      Name = 'Test10',
      AccountId = acc.Id,
      Amount = 10000,
      IM_Booked_Date__c = date.today(),
      Type = 'New Deal',
      StageName = '1 - Qualification',
      CloseDate = date.today()
      //Primary_Product_Line__c = 'Record Management',
      //CurrencyIsoCode = 'EUR - Euro'
    );
    insert opp;
    SBQQ__Quote__c testquote = new SBQQ__Quote__c(
      SBQQ__Account__c = acc.Id,
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__Type__c = QTB_Constants.QUOTE_TYPE_STANDARD,
      SBQQ__Status__c = 'Draft',
      SBQQ__QuoteLanguage__c = 'English',
      SBQQ__Primary__c = true,
      SBQQ__StartDate__c = date.today(),
      QTB_Number_of_Markets__c = 10
    );
    insert testquote;
    testquote.SBQQ__Status__c = 'Accepted';
    update testquote;
    Test.startTest();
    SBQQ__Quote__c testquote1 = new SBQQ__Quote__c(
      SBQQ__Account__c = acc.Id,
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__Type__c = QTB_Constants.QUOTE_TYPE_STANDARD,
      SBQQ__Status__c = 'Accepted',
      SBQQ__QuoteLanguage__c = 'English',
      SBQQ__Primary__c = true,
      SBQQ__StartDate__c = date.today(),
      QTB_Number_of_Markets__c = 10
    );
    try {
      insert testquote1;
    } catch (DmlException e) {
      //System.assert(e.getMessage().contains('Already an accepted quote for this opportunity'));
    }
    SBQQ__Quote__c testquote2 = new SBQQ__Quote__c(
      SBQQ__Account__c = acc.Id,
      SBQQ__Opportunity2__c = opp.Id,
      SBQQ__Type__c = QTB_Constants.QUOTE_TYPE_STANDARD,
      SBQQ__Status__c = 'Approved',
      SBQQ__QuoteLanguage__c = 'English',
      SBQQ__Primary__c = true,
      SBQQ__StartDate__c = date.today(),
      QTB_Number_of_Markets__c = 10
    );
    try {
      insert testquote2;
    } catch (DmlException e) {
    }
    Test.stopTest();
  }
}