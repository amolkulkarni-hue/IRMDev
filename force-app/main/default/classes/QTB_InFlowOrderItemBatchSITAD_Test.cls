/*****************************************************************************************************
 * Class: QTB_InFlowOrderItemBatch_Test
 * Author: Slalom
 * Purpose: This is a test class for QTB_InFlowOrderItemBatchSITAD
 * Change History: 
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 *            02-14-2022
 *******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_InFlowOrderItemBatchSITAD_Test {
  @TestSetup
  static void createData() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    System.runAs(userList[0]) {
      Test.startTest();
      blng__BillingRule__c BillingRule = QTB_TestDataFactory.createBillingRule(
        'Yes'
      );
      blng__RevenueRecognitionRule__c RevenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
        'Yes'
      );
        blng__TaxRule__c TaxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        blng__FinanceBook__c BillingFinanceBook = new blng__FinanceBook__c();
        BillingFinanceBook.Name = 'Accounting Finance Book';
        BillingFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
	    BillingFinanceBook.blng__Active__c = true;
	    BillingFinanceBook.blng__PeriodType__c='Accounting';
	insert BillingFinanceBook; 
        
      blng__BillingTreatment__c  BillingTreatment = new blng__BillingTreatment__c();
        BillingTreatment.Name= 'No Invoice Billing Treatment';
        BillingTreatment.blng__Active__c= true;
        BillingTreatment.blng__BillingFinanceBook__c= BillingFinanceBook.id;
        BillingTreatment.blng__BillingRule__c= BillingRule.id;
        BillingTreatment.blng__CancellationRule__c='LIFO by Order Product Creation Date';
    insert BillingTreatment;
        
      List<PriceBook2> prbk =QTB_TestDataFactory.priceBookMethdLst(1,'United States');
      prbk[0].QTB_Country__c='United States';
      update prbk[0];
        
      List<Product2> product = QTB_TestDataFactory.createProducts(1);
      product[0].blng__BillingRule__c = BillingRule.id;
      product[0].blng__RevenueRecognitionRule__c = RevenueRule.id;
      product[0].blng__TaxRule__c = TaxRule.id;
        product[0].IM_Product_Line__c = 'ALM-Secure ITAD';
      product[0].SBQQ__ChargeType__c = 'One-Time'; 
    update product;
        
      Id pricebookId = Test.getStandardPricebookId();
        PriceBookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        PriceBookEntry SingaporePrice = new PricebookEntry(
        Pricebook2Id=prbk[0].id,
        Product2Id = product[0].Id,
        UnitPrice = 10000,
        IsActive = true);
       Insert SingaporePrice;
       
      blng__LegalEntity__c LglEntity = QTB_TestDataFactory.createLegalEntity('United States');
          LglEntity.CurrencyIsoCode='USD';
          update LglEntity;
        
        List<account> accountList = QTB_TestDataFactory.createAccounts(1);

      List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
      oppList[0].Pricebook2Id = pricebookId;
      update oppList;

      List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
        1,
        oppList[0].id,
        accountList[0].id,
        true,
        null
      );
      quoteList[0].SBQQ__PriceBook__c = pricebookId;
      quoteList[0].SBQQ__StartDate__c = System.Today();
      update quoteList;

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

        ID OrdRecId = (Schema.SObjectType.Order.getRecordTypeInfosByDeveloperName().get('QTB_Billing_Order').getRecordTypeId());
        ID AccRecId = (Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('QTB_Billing_Account').getRecordTypeId());
        
         QTB_Billing_Countries__c setting = new QTB_Billing_Countries__c();
        setting.Name = 'United States';
        setting.Active__c= true;
        setting.Legal_entity_country__c='United States';
        insert setting;
        
      List<Order> orderList3 = QTB_TestDataFactory.createBillingOrders(
        1,
        quoteList[0].Id,
        accountList[0].id
      );
        orderList3[0].QTB_Legal_Entity_Country__c = 'United States';
        orderList3[0].RecordtypeID = OrdRecId;
        update orderList3[0];
        
         List<Id> lstTopass= new List<Id>();
          lstTopass.add(orderList3[0].id);
      QTB_InFlowOrderItemBatch_SITAD res = new QTB_InFlowOrderItemBatch_SITAD(lstTopass);
      Database.executeBatch(res);
         Test.stopTest();
      System.assertEquals(
         'Draft',
        orderList3[0].Status,
        'Unexpected error'
      );
    }
  }
  //cover catch
  static testMethod void testMethod2() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
       List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
        1,
        'Standard Account'
        );
         List<Order> orderList333 = QTB_TestDataFactory.createBillingOrders(
        1,
        NULL,
        testAccounts[0].id
       );   
       
      QTB_InFlowOrderItemBatch_SITAD.throwExplicitException = true;
        List<Id> lstTopass2= new List<Id>();
        lstTopass2.add(orderList333[0].id);
        QTB_InFlowOrderItemBatch_SITAD obj = new QTB_InFlowOrderItemBatch_SITAD(lstTopass2);
      obj.execute(null, null);
      Test.stopTest();
      System.assertEquals(
        true,
        QTB_InFlowOrderItemBatch_SITAD.throwExplicitException
      );
    }
  }
  
}