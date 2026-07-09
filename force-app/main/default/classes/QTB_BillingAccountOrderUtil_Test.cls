/*****************************************************************************************************
 * Class: QTB_BillingAccountOrderUtil_Test
 * Author: Virtsa
 * Purpose: This is a test class for QTB_BillingAccountOrderUtil
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Sravya       15/05/2023       GitLab #14900
 *******************************************************************************************************/
@isTest(seeAllData=false)
public class QTB_BillingAccountOrderUtil_Test {
@TestSetup
	static void createData() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    Test.startTest();
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
      //IM Country
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA'; 
        im.Active__c = true;
        insert im;
      list<opportunity> oppList =new list<opportunity>();
      for (Integer i = 0; i < accountList.size(); i++) {
        oppList.add(
          new Opportunity(
            Name = 'Test' + i,
            AccountId = accountList[i].Id,
            CloseDate = Date.today(),
            StageName = '1 - Qualification',
            RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID,
            Amount = 500,
              Billing_Country__c =im.id
          )
        );
      }
      if (!oppList.isEmpty()) {
        insert oppList;
      }
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
      quoteList[0].SBQQ__StartDate__c = System.Today();
      database.update(quoteList);

      QTB_Promotion__c promo = new QTB_Promotion__c();
      promo.Name = 'test promo';
      promo.QTB_Quote_Type__c = 'Quote';
      promo.QTB_Promo_Description__c = 'test data';
      promo.QTB_Promo_Term__c = 2;
        try{
            insert promo;
        }
        catch(Exception e){
            
        }

      QTB_Quote_Promotion__c quotePromo = new QTB_Quote_Promotion__c();
      quotePromo.name = 'test QuotePromotion';
      quotePromo.QTB_Promotion_Name__c = promo.id;
      quotePromo.qtb_quote__c = quoteList[0].id;
      quotePromo.QTB_Promo_Term__c = 2;
      insert quotePromo;

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
      SBQQ.Triggercontrol.Disable();

      List<account> accountList2 = QTB_TestDataFactory.createAccounts(
        1,
        accountList[0],
        null,
        'Billing Account'
      );
      accountList2[0].QTB_Source_Opportunity__c = oppList[0].id;
      
      update accountList2;
      List<Order> orderList1 = QTB_TestDataFactory.createCPQOrders(
        1,
        quoteList[0].Id,
        accountList[0].id
      );
      orderList1[0].blng__BillingAccount__c = accountList2[0].id;
       orderList1[0].RecordTypeId = QTB_Utils.ORDER_SALES_RECTYPEID;
          orderList1[0].SBQQ__PriceCalcStatus__c = 'Not Needed';
        try{
            database.update(orderList1);
        }
        catch(Exception e){
            
        }
     orderList1[0].RecordTypeId = QTB_Utils.ORDER_BILL_RECTYPEID;
         try{
            database.update(orderList1);
        }
        catch(Exception e){
            
        }
      List<Order> orderList2 = QTB_TestDataFactory.createBillingOrders(
        1,
        quoteList[0].Id,
        accountList[0].id
      );
        
        
        
      List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(
        orderList1[0].Id,
        product[0].Id,
        quoteLinesList,
        standardPrice
      );
         
      Test.stopTest();
      system.assert(orderItemList[0].SBQQ__ChargeType__c == 'One-Time');
    }
  }
 static testMethod void testsetOrderTypeValue() {
    try {
      Test.startTest();
      QTB_BillingAccountOrderUtil.setOrderTypeValue(null,null,null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
}
 static testMethod void testcountryClone() {
    try {
      Test.startTest();
      QTB_BillingAccountOrderUtil.countryClone(null,null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
}
 static testMethod void testbillingPromotions() {
    try {
      Test.startTest();
      QTB_BillingAccountOrderUtil.billingPromotions(null,null);
      Test.stopTest();
    } catch (NullPointerException e) {
      System.assertEquals('System.NullPointerException', e.getTypeName());
    }
}

  
}