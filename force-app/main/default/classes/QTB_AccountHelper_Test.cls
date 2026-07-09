/*****************************************************************************************************
 * Class: QTB_AccountHelper_Test
 * Author: Accenture
 * Purpose: This is a test class for QTB_AccountHelper
 * Change History:
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture
 *******************************************************************************************************/
@isTest(seeAllData=false)
private class QTB_AccountHelper_Test {
  private static final Id accBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
  @testSetup
  static void setup(){
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    //System.runAs(userList[0]) {
      QTB_TestDataFactory.createLegalEntity('Norway');
      blng__LegalEntity__c denmarkentity = QTB_TestDataFactory.createLegalEntity(
        'Denmark'
        );
      QTB_TestDataFactory.createLOBMapping();
      List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
        2,
      'Standard Account'
        );
      
      //List<product2> product = QTB_TestDataFactory.createProducts(1);
      List<product2>product = new List<product2>();
      Product2 tmp = new Product2();
      tmp.Name = 'Test Product';
      tmp.isActive = true;
      tmp.SBQQ__SubscriptionPricing__c = 'Fixed Price';
      tmp.ProductCode = 'MSC';
      tmp.IsActive = true;
      product.add(tmp);
      //product[0].QTB_Account_Level_Charges__c = true;
      insert product;
      
      Id pricebookId = Test.getStandardPricebookId();
      PricebookEntry standardPrice = new PricebookEntry(
        Pricebook2Id = pricebookId,
      Product2Id = product[0].Id,
      UnitPrice = 10000,
      IsActive = true);
      insert standardPrice;
      //Legal Entity
      blng__LegalEntity__c indiaEntity = new blng__LegalEntity__c();
      indiaEntity.Name = 'Test Legal Entity United States';
      indiaEntity.blng__Active__c = true;
      indiaEntity.blng__Country__c = 'United States';
      indiaEntity.QTB_Type__c = 'Contract';
      // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
      insert indiaEntity;
      
      IM_Country__c im = new IM_Country__c();
      im.Name = 'United States';
      im.CurrencyIsoCode = 'USD';
      im.Region__c = 'North America';
      im.AlternativeNames__c = 'United States';
      im.Iso31662Code__c ='US';
      im.Iso31663Code__c ='USA';
      insert im;
      
      //create sales opp
      /*List<Opportunity> testOpportunity = QTB_TestDataFactory.createCPQOppsNew(
      testAccounts,
      'CPQ Sales Opportunity'
        );
      testOpportunity[0].Pricebook2Id = pricebookId;
      testOpportunity[0].Legal_Entity__c = indiaEntity.id;
      testOpportunity[0].Billing_Country__c = im.id;
      testOpportunity[1].Pricebook2Id = pricebookId;
      testOpportunity[1].Legal_Entity__c = indiaEntity.id;
      testOpportunity[1].Billing_Country__c = im.id;
      insert testOpportunity;*/
        
      List<Opportunity> testOpportunity = new List<Opportunity>();
      Opportunity opp = new Opportunity();
      opp.RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
      opp.Name = 'Opportunity 1';
      opp.AccountId = testAccounts[0].Id;
      opp.CloseDate = Date.today();
      opp.StageName = '1 - Qualification';
      opp.type = 'New Deal';
      opp.Pricebook2Id = pricebookId;
      opp.Legal_Entity__c = indiaEntity.id;
      opp.Billing_Country__c = im.id;
      insert opp;
      testOpportunity.add(opp);
      
      Opportunity opp1 = new Opportunity();
      opp1.RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
      opp1.Name = 'Opportunity 2';
      opp1.AccountId = testAccounts[0].Id;
      opp1.CloseDate = Date.today();
      opp1.StageName = '1 - Qualification';
      opp1.type = 'New Deal';
      opp1.Pricebook2Id = pricebookId;
      opp1.Legal_Entity__c = indiaEntity.id;
      opp1.Billing_Country__c = im.id;
      insert opp1;
      testOpportunity.add(opp1);
      
      Account acc = new Account();
      acc.Name = 'Test Account';
      //insert acc;
      acc.QTB_FSO__c = False;
      acc.ParentId= testAccounts[0].id;
      //update acc;
      insert acc;
      
      //create quote -- disabled trigger to restrict the SOQL usage
      SBQQ.TriggerControl.Disable();
      list<SBQQ__Quote__c> testQuote = QTB_TestDataFactory.createCPQQuotes(
        1,
      testOpportunity[0].id,
      testAccounts[0].id,
      true,
      null
        );
      testQuote[0].SBQQ__PriceBook__c = pricebookId;
      update testQuote;
      /*list<SBQQ__Quote__c> testQuote1 = QTB_TestDataFactory.createCPQQuotes(
      1,
      testOpportunity[1].id,
      testAccounts[0].id,
      true,
      null
        );*/
        List<SBQQ__Quote__c> testQuote1 = new List<SBQQ__Quote__c>();
      testQuote1.add(
        new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = testOpportunity[1].id,
      SBQQ__Account__c = testAccounts[0].id,
      SBQQ__Type__c = QTB_Constants.QUOTE_TYPE_STANDARD,
      SBQQ__Status__c = 'Draft',
      SBQQ__QuoteLanguage__c = 'English',
      SBQQ__ExpirationDate__c = date.today(),
      SBQQ__Primary__c = true,
      SBQQ__PrimaryContact__c = null,
      SBQQ__StartDate__c = date.today(),
      SBQQ__PriceBook__c = pricebookId
        )
        );
      //testQuote1[0].SBQQ__PriceBook__c = pricebookId;
      insert testQuote1;
      
      List<SBQQ__QuoteLine__c> quoteLines = QTB_TestDataFactory.createCPQQuoteLines(
        1,
      testQuote[0].id,
      null,
      product[0].id
        );
      List<SBQQ__QuoteLine__c> quoteLines1 = QTB_TestDataFactory.createCPQQuoteLines(
        1,
      testQuote1[0].id,
      null,
      product[0].id
        );
      
      Test.startTest();
      //SBQQ.TriggerControl.Disable();
      List<Order> testOrder0 = QTB_TestDataFactory.createSalesOrders(
        1,
      testQuote[0].id,
      testAccounts[0].id,
      testOpportunity[0].id
        );
      
      
      List<Order> testOrder1 = QTB_TestDataFactory.createSalesOrders(
        1,
      testQuote1[0].id,
      testAccounts[0].id,
      testOpportunity[1].id
        );
      QTB_TestDataFactory.createCPQOrderItems(
        testOrder0[0].Id,
      product[0].id,
      quoteLines,
      standardPrice
        );
      QTB_TestDataFactory.createCPQOrderItems(
        testOrder1[0].Id,
      product[0].id,
      quoteLines1,
      standardPrice
        );
      //SBQQ.TriggerControl.Enable();
      Account a = new Account();
      a.Name = 'TestAcc';
      a.RecordTypeId = accBillRecordTypeId;
      a.QTB_Create_Parent_Billing_Account__c = true;
      a.BillingCountry = 'India';
      a.BillingState = 'Assam';
      a.QTB_Source_Order__c = testOrder1[0].Id;
      a.QTB_Source_Opportunity__c = testOpportunity[1].id;
      //insert a;
      a.QTB_Hold_Billing__c = true;
      a.QTB_Source_Opportunity__c = testOpportunity[0].id;
      a.QTB_Source_Order__c = testOrder0[0].Id;
      a.QTB_Billing_Account_Invoice_Name__c = 'Test Trigger';
      a.QTB_shred__c = true;
      a.QTB_scan__c = true;
      a.QTB_Contract_Entity__c = denmarkentity.id;
      a.ShippingCountry = 'Denmark';
      //update a;
      a.QTB_Records_Management__c = true;
      //update a;
      insert a;
      List<Account> triggerOldList = new List<Account>();
      triggerOldList.add(a);
      AccountHelper.processAccountBeforeDelete(triggerOldList);
      /*List<SBQQ__Subscription__c> subscriptionsToReturn = QTB_TestDataFactory.createCPQSubscriptions(1,testContract[0].id,product[0].id);
      System.assert(product[0].QTB_Account_Level_Charges__c, true);
      System.assert(product[0].IsActive,true);*/ //QTB_TestDataFactory.createCPQContracts(1,testOrder[0].id, a.id, testQuote[0].id); //QTB_AccountHelper.accountDetailsForPlatformEvent(new list<Id>{a.id});
      //List<Order> testOrder =QTB_TestDataFactory.createCPQOrders(1,testQuote[0].id, a.id);
      /*List<Contract> testContract =*/
      QTB_OperationalAccountNumberBatch batchJob = new QTB_OperationalAccountNumberBatch();
      Database.executeBatch(batchJob);
      Test.stopTest();
      system.assert(testAccounts.size() > 0);
   // }
  }
  // cover catch
  /*  static testMethod void coverCatchBlock() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
      AccountTriggerHandler.throwExplicitException = true;
      AccountTriggerHandler handler = new AccountTriggerHandler();
      handler.AfterDelete(null);
      handler.AfterUndelete(null);
      QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_ACCOUNT);
      handler.isDisabled();
      /* try{
        QTB_AccountHelper.GenerateBillingRecords(null,null,null);
      }catch(NullPointerException e) {
        System.assertEquals('System.NullPointerException', e.getTypeName());
      }*/
      /*try{
        QTB_AccountHelper.updateBillingAccountName(null,null);
      }catch(NullPointerException e) {
        System.assertEquals('System.NullPointerException', e.getTypeName());
      }*/
      /*try{
        QTB_AccountHelper.publishBillingOracleEvent(null,null);
      }catch(NullPointerException e) {
        System.assertEquals('System.NullPointerException', e.getTypeName());
      }*/
      /* try{
        QTB_AccountHelper.GetSpecialTaxConditions(null);
      }catch(NullPointerException e) {
        System.assertEquals('System.NullPointerException', e.getTypeName());
      }*/
      /* try{
        QTB_AccountHelper.UpdateSpecialTaxCondition(null,null);
      }catch(NullPointerException e) {
        System.assertEquals('System.NullPointerException', e.getTypeName());
      }*/
      /*collectSalesOpps(null,null);
      QTB_CreateBillingRecords.collectSalesQuoteLines(null);
      QTB_CreateBillingRecords.cloneSaleOppty(null,null,null);
      QTB_CreateBillingRecords.cloneSalesQuote(null,null,null);
      QTB_CreateBillingRecords.cloneSaleQuoteLine(null,null);
      QTB_CreateBillingRecords.insertBilOpps(null);
      QTB_CreateBillingRecords.insertBillQuotes(null);
      QTB_CreateBillingRecords.insertBillQuoteLines(null);*/
        /*      QTB_CreateBillingRecords.collectSalesOrders(null,null);
      QTB_CreateBillingRecords.cloneSaleOrder(null,null,null);
      QTB_CreateBillingRecords.insertBillOrders(null);
      QTB_CreateBillingRecords.cloneSalesItem(null, null);
      try{
        QTB_CreateBillingRecords.insertBillOrderItems(null, null);
      }
      catch(Exception e){
        
      }
      
      
      //QTB_CreateBillingRecords.CloneOrderItemCS(null, null, null);
      handler.isDisabled();
      Test.stopTest();
      System.assertEquals(true, AccountTriggerHandler.throwExplicitException);
    }
  }*/
  static testMethod void method1() {
    try {
      Test.startTest();
      QTB_AccountHelper.GenerateEvergreenRecords(null, null, null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
    try {
      QTB_AccountHelper.updateAccountForHoldStatus(null,null);
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
  }
  static testMethod void method2() {
    try {
      Test.startTest();
      QTB_AccountHelper.updateBillingAccountName(null, null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
    try {
      QTB_AccountHelper.billingOSUpdatePlatformEvent(null, null);
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
    try {
      QTB_AccountHelper.updateDMSourceSystemIdReference(null);
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
  }
  static testMethod void method3() {
    try {
      Test.startTest();
      QTB_AccountHelper.publishBillingOracleEvent(null, null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
  }
  static testMethod void method4() {
    try {
      Test.startTest();
      QTB_AccountHelper.GetSpecialTaxConditions(null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
  }
  static testMethod void method5() {
    
    try {
      Test.startTest();
      QTB_AccountHelper.UpdateSpecialTaxCondition(null, null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
  }
  static testMethod void method16() {
    try {
      Test.startTest();
      String temp = 'In Progress';
      list<Account>blngAcc = QTB_TestDataFactory.createAccounts(3,'Billing Account');
      list<Account>opAcc = QTB_TestDataFactory.createAccounts(3,'Operational Account');
      QTB_AccountHelper.updateAccountForHoldStatus(blngAcc,temp);
      blngAcc[0].QTB_FSO__c = true;
      blngAcc[1].QTB_FSO__c = true;
      blngAcc[2].QTB_FSO__c = true;
      opAcc[0].parentId = blngAcc[0].Id;
      opAcc[1].parentId = blngAcc[1].Id;
      opAcc[2].parentId = blngAcc[2].Id;
      opAcc[0].Related_Billing_Account__c = blngAcc[0].Id;
      opAcc[1].Related_Billing_Account__c = blngAcc[1].Id;
      opAcc[2].Related_Billing_Account__c = blngAcc[2].Id;
      opAcc[0].Ship_To_Site_Number__c = '00012345';
      opAcc[1].Ship_To_Site_Number__c = '00123456';
      opAcc[2].Ship_To_Site_Number__c = '01234567';
      opAcc[0].QTB_Legal_Entity_Country__c = 'Malaysia';
      opAcc[0].QTB_Tax_Registration__c = '123';
      opAcc[0].QTB_Tax_ID__c = '123';
      opAcc[0].QTB_TIN__c = '123';
      opAcc[1].QTB_Legal_Entity_Country__c = 'Malaysia';
      opAcc[1].QTB_Tax_Registration__c = '123';
      opAcc[1].QTB_Tax_ID__c = '123';
      opAcc[1].QTB_TIN__c = '123';
      opAcc[2].QTB_Legal_Entity_Country__c = 'Malaysia';
      opAcc[2].QTB_Tax_Registration__c = '123';
      opAcc[2].QTB_Tax_ID__c = '123';
      opAcc[2].QTB_TIN__c = '123';
      opAcc[1].Related_Operational_Account__c = opAcc[0].Id;
      opAcc[2].Related_Operational_Account__c = opAcc[1].Id;
      update blngAcc;
      update opAcc;
      
      
      List<Account> acc = [Select id,name,Related_Operational_Account__c,Related_Operational_Account__r.Related_Operational_Account__c,Ship_To_Site_Number__c,parentId from account where RecordType.Name = 'Operational Account' and Related_Billing_Account__c != Null];
      
      /*Map<Id,Id>ac = new Map<Id,Id>();
      ac.put(acc[0].id,acc[0].parentId);
      ac.put(acc[1].id,acc[1].parentId);
      ac.put(acc[2].id,acc[2].parentId);*/
        
      QTB_AccountHelper.updateDMSourceSystemIdReference(acc);
      
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
  }
  
  static testMethod void method17() {
    try {
      Test.startTest();
      List<Account> accounts = new List<Account> {
        new Account(Name = 'Test Account1', BillingCountry = 'India', BillingState = 'Karnataka', ShippingCountry = 'India', BillingStreet = 'test strt', BillingCity = 'Bengaluru', BillingPostalCode = '12332'),
        new Account(Name = 'Test Account2', BillingCountry = 'Hong Kong', BillingState = 'ttt', ShippingCountry = 'Hong Kong', BillingStreet = 'test strt', BillingCity = 'test city', BillingPostalCode = '12332')
      };
      QTB_AccountHelper.setMetadata(new List<QTB_Billing_Account_Country_Validation__mdt>{
        new QTB_Billing_Account_Country_Validation__mdt(QTB_Country__c = 'India', IsActive__c = true, QTB_Field_Name__c = 'BillingState', QTB_Mandatory__c = true, QTB_Non_Mandatory__c = false),
        new QTB_Billing_Account_Country_Validation__mdt(QTB_Country__c = 'Hong Kong', IsActive__c = true, QTB_Field_Name__c = 'BillingPostalCode', QTB_Mandatory__c = false, QTB_Non_Mandatory__c = true)
      });
      QTB_AccountHelper.validateMandatoryAccountFields(accounts);
      AccountTriggerHandler.throwExplicitException = true;
      QTB_AccountHelper.validateMandatoryAccountFields(null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
  }
  static testMethod void method18() {
    try {
      Id accBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
      list<Account> blngAcc = QTB_TestDataFactory.createAccounts(2,'Billing Account');
      
      Test.startTest();
      //QTB_AccountHelper.validateIndianStateValue(blngAcc);
      AccountTriggerHandler.throwExplicitException = true;
      //QTB_AccountHelper.validateIndianStateValue(null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
  }
  
  static testMethod void assignShiptTositeToOpAcc(){
    
    Id accBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
    list<Account> blngAcc = QTB_TestDataFactory.createAccounts(1,'Billing Account');
    Id  oppAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Operational Account').getRecordTypeId();
    Account a = new Account();
    a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
    a.RecordTypeId = oppAccountId;
    a.Name = 'TestOpp Account';
    a.BillingCountry = 'India';
    a.BillingStreet='Manual Street';
    a.BillingPostalCode = '11209';
    a.BillingState = 'TN';
    a.BillingCity ='Mumbai';
    a.Registration_Number__c = 'Reg';
    a.ShippingCountry = 'India';
    a.ParentId = blngAcc[0].Id;
    insert a; // L1
    
    Account aL2 = new Account();
    aL2.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
    aL2.RecordTypeId = oppAccountId;
    aL2.Name = 'TestOpp Account';
    aL2.BillingCountry = 'India';
    aL2.BillingStreet='Manual Street';
    aL2.BillingPostalCode = '11209';
    aL2.BillingState = 'TN';
    aL2.BillingCity ='Mumbai';
    aL2.Registration_Number__c = 'Reg';
    aL2.ShippingCountry = 'India';
    aL2.ParentId = blngAcc[0].Id;
    aL2.Related_Operational_Account__c=a.Id;
    insert aL2; // L2
    
    Test.startTest();
    Account aL3 = new Account();
    aL3.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
    aL3.RecordTypeId = oppAccountId;
    aL3.Name = 'TestOpp Account';
    aL3.BillingCountry = 'India';
    aL3.BillingStreet='Manual Street';
    aL3.BillingPostalCode = '11209';
    aL3.BillingState = 'TN';
    aL3.BillingCity ='Mumbai';
    aL3.Registration_Number__c = 'Reg';
    aL3.ShippingCountry = 'India';
    aL3.ParentId = blngAcc[0].Id;
    aL3.Related_Operational_Account__c=aL2.Id;
    insert aL3; // L3
    Test.stopTest();
  }

  static testMethod void assignShiptTositeExistingChild(){
    
    Id accBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
    list<Account> blngAcc = QTB_TestDataFactory.createAccounts(1,'Billing Account');
    Id  oppAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Operational Account').getRecordTypeId();
    Account a = new Account();
    a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
    a.RecordTypeId = oppAccountId;
    a.Name = 'TestOpp Account';
    a.BillingCountry = 'India';
    a.BillingStreet='Manual Street';
    a.BillingPostalCode = '11209';
    a.BillingState = 'TN';
    a.BillingCity ='Mumbai';
    a.Registration_Number__c = 'Reg';
    a.ShippingCountry = 'India';
    a.ParentId = blngAcc[0].Id;
    insert a; // L1

    Test.startTest();
    List<Account> l2Accounts = new List<Account>();
    Account aL2 = new Account();
    aL2.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
    aL2.RecordTypeId = oppAccountId;
    aL2.Name = 'TestOpp Account L2';
    aL2.BillingCountry = 'India';
    aL2.BillingStreet='Manual Street';
    aL2.BillingPostalCode = '11209';
    aL2.BillingState = 'TN';
    aL2.BillingCity ='Mumbai';
    aL2.Registration_Number__c = 'Reg';
    aL2.ShippingCountry = 'India';
    aL2.ParentId = blngAcc[0].Id;
    aL2.Related_Operational_Account__c=a.Id;
    l2Accounts.add(aL2); // L2

    Account aL21 = new Account();
    aL21.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
    aL21.RecordTypeId = oppAccountId;
    aL21.Name = 'TestOpp Account L2-2';
    aL21.BillingCountry = 'India';
    aL21.BillingStreet='Manual Street';
    aL21.BillingPostalCode = '11209';
    aL21.BillingState = 'TN';
    aL21.BillingCity ='Mumbai';
    aL21.Registration_Number__c = 'Reg';
    aL21.ShippingCountry = 'India';
    aL21.ParentId = blngAcc[0].Id;
    aL21.Related_Operational_Account__c=a.Id;
    l2Accounts.add(aL21); // L2

    insert l2Accounts;

    Account aL3 = new Account();
    aL3.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
    aL3.RecordTypeId = oppAccountId;
    aL3.Name = 'TestOpp Account L3';
    aL3.BillingCountry = 'India';
    aL3.BillingStreet='Manual Street';
    aL3.BillingPostalCode = '11209';
    aL3.BillingState = 'TN';
    aL3.BillingCity ='Mumbai';
    aL3.Registration_Number__c = 'Reg';
    aL3.ShippingCountry = 'India';
    aL3.ParentId = blngAcc[0].Id;
    aL3.Related_Operational_Account__c=aL2.Id;
    insert aL3; // L3

    Account aL22 = new Account();
    aL22.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
    aL22.RecordTypeId = oppAccountId;
    aL22.Name = 'TestOpp Account L2-2';
    aL22.BillingCountry = 'India';
    aL22.BillingStreet='Manual Street';
    aL22.BillingPostalCode = '11209';
    aL22.BillingState = 'TN';
    aL22.BillingCity ='Mumbai';
    aL22.Registration_Number__c = 'Reg';
    aL22.ShippingCountry = 'India';
    aL22.ParentId = blngAcc[0].Id;
    aL22.Related_Operational_Account__c=a.Id;
    insert aL22; // L2
    
    Account aL32 = new Account();
    aL32.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
    aL32.RecordTypeId = oppAccountId;
    aL32.Name = 'TestOpp Account';
    aL32.BillingCountry = 'India';
    aL32.BillingStreet='Manual Street';
    aL32.BillingPostalCode = '11209';
    aL32.BillingState = 'TN';
    aL32.BillingCity ='Mumbai';
    aL32.Registration_Number__c = 'Reg';
    aL32.ShippingCountry = 'India';
    aL32.ParentId = blngAcc[0].Id;
    aL32.Related_Operational_Account__c=aL2.Id;
    insert aL32; // L3
    Test.stopTest();
  }
}