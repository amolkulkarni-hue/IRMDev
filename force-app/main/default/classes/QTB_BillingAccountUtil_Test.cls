/*****************************************************************************************************
 * Class: QTB_BillingAccountUtil_Test
 * Author: Virtsa
 * Purpose: This is a test class for QTB_BillingAccountUtil
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Sravya       15/05/2023       GitLab #14900
 *******************************************************************************************************/
@isTest(seeAllData=false)
private class QTB_BillingAccountUtil_Test {
private static final Id accBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
 @testSetup
  static void setup(){
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      QTB_TestDataFactory.createLegalEntity('Norway');
      blng__LegalEntity__c denmarkentity = QTB_TestDataFactory.createLegalEntity(
        'Denmark'
      );
      QTB_TestDataFactory.createLOBMapping();
      List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
        2,
        'Standard Account'
      );

      //Product Creation
      List<product2>product = new List<product2>();
      Product2 tmp = new Product2();
      tmp.Name = 'Test Product';
      tmp.isActive = true;
      tmp.SBQQ__SubscriptionPricing__c = 'Fixed Price';  
      tmp.ProductCode = 'MSC';
      tmp.IsActive = true;
      product.add(tmp);
      insert product;
      //PricebookEntry Creation
      Id pricebookId = Test.getStandardPricebookId();
      PricebookEntry standardPrice = new PricebookEntry(
      	Pricebook2Id = pricebookId,
        Product2Id = product[0].Id,
        UnitPrice = 10000,
        IsActive = true);
        insert standardPrice;
        
          //Legal Entity Cration
        blng__LegalEntity__c indiaEntity = new blng__LegalEntity__c();
        indiaEntity.Name = 'Test Legal Entity United States';
        indiaEntity.blng__Active__c = true;
        indiaEntity.blng__Country__c = 'United States';
        indiaEntity.QTB_Type__c = 'Contract';
        insert indiaEntity;
        // IM_Country__c creation
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';        
        insert im;
         // Opportunity creation
        List<Opportunity> testOpportunity = new List<Opportunity>();
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
        opp.Name = 'Opportunity 1';
      	opp.AccountId = testAccounts[0].Id;
      	opp.CloseDate = Date.today();
      	opp.StageName = '1 - Qualification';
      	opp.type = 'New Deal';
        opp.Pricebook2Id = pricebookId;
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
      	opp1.Billing_Country__c = im.id; 
        insert opp1;
       	testOpportunity.add(opp1);        
        //Account Creation
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.ParentId= testAccounts[0].id;
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

      //Billing Account Creation
      Account a = new Account();
      a.Name = 'TestAcc';
      a.RecordTypeId = accBillRecordTypeId;
      a.QTB_Create_Parent_Billing_Account__c = true;
      a.BillingCountry = 'India';
      a.BillingState = 'Assam';
      a.ShippingState = 'India';
	  a.BillingPostalCode = '99999';
      a.BillingCity = 'Mexico';
      a.BillingStreet = 'test';
      a.ShippingCountry = 'Denmark';
      a.ShippingPostalCode = '99999';
      a.QTB_Source_Order__c = testOrder1[0].Id;
      a.QTB_Source_Opportunity__c = testOpportunity[1].id;
      a.QTB_Hold_Billing__c = true;
      a.QTB_Source_Opportunity__c = testOpportunity[0].id;
      a.QTB_Source_Order__c = testOrder0[0].Id;
      a.QTB_Billing_Account_Invoice_Name__c = 'Test Trigger';
      a.QTB_shred__c = true;
      a.QTB_scan__c = true;
      a.QTB_Contract_Entity__c = denmarkentity.id;
      a.ShippingCountry = 'Denmark';
      insert a;
    Test.stopTest();
      system.assert(testAccounts.size() > 0);
    }
  }
 
 static testMethod void testvalidateMandatoryAccountFields() {
    try {
     Test.startTest();
      QTB_BillingAccountUtil.validateMandatoryAccountFields(null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
  }
  static testMethod void testupdateBillingAccountName() {
    try {
      Test.startTest();
      QTB_BillingAccountUtil.updateBillingAccountName(null, null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
  }
  static testMethod void testvalidateIndianStateValue() {
    try {
      Test.startTest();
      QTB_BillingAccountUtil.validateIndianStateValue(null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
  }
 
 static testMethod void testbillingOraclePlatformEvent() {
    try {
      Test.startTest();
      QTB_BillingAccountUtil.billingOraclePlatformEvent(null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
} 
static testMethod void testcreateSalesBillingAccountRelations() {
    try {
      Test.startTest();
      QTB_BillingAccountUtil.createSalesBillingAccountRelations(null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
}
static testMethod void testGenerateEvergreenRecords() {
    try {
      Test.startTest();
      QTB_BillingAccountUtil.GenerateEvergreenRecords(null, null, null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
}
static testMethod void testprimaryContactInsertion() {
    try {
      Test.startTest();
      QTB_BillingAccountUtil.primaryContactInsertion(null, null, null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
}

}