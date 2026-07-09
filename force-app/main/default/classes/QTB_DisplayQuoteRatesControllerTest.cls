@isTest
public class QTB_DisplayQuoteRatesControllerTest {
    static testMethod void testmethod1() {
        Test.startTest();
        Account acnt = new Account();
        acnt.Name = 'testAcc';
        acnt.Billing_County__c = 'India';
        acnt.QTB_Create_Parent_Billing_Account__c = true;
        Id billingRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
        acnt.RecordTypeId = billingRecordType;
        insert acnt;
        list<Account> acntList = new list<Account>();
        acntList.add(acnt);
        
        List<product2> product = QTB_TestDataFactory.createProducts(1);
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
            product[0]
        );
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
            'Yes'
        );
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
            'Yes'
        );
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        database.update(product);
      
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(acntList);
        
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
            1,
            oppList[0].id,
            acnt.id,
            true,
            null
        );
        
        SBQQ__QuoteLine__c qline = new SBQQ__QuoteLine__c();
        qline.SBQQ__Quote__c = quoteList[0].id;
        qline.SBQQ__Product__c = product[0].id;
        qline.SBQQ__HasConsumptionSchedule__c = false;
        insert qline;
        
        List<Order> orderList1 = QTB_TestDataFactory.createCPQOrders(
            2,
            quoteList[0].Id,
            acnt.id
        );
        list<Order> ordersToUpdate = new list<Order>();
        
        Order oi1 = new Order();
        oi1.SBQQ__Quote__c = quoteList[0].id;
        oi1.id = orderList1[1].id;
        ordersToUpdate.add(oi1);
        
        Order oi2 = new Order();
        oi2.QTB_Order_OriginatorId__c = orderList1[1].id;
        oi2.id = orderList1[0].id;
        ordersToUpdate.add(oi2);
        update ordersToUpdate;
        
        OrderItem testOi = new OrderItem();
        testOi.ServiceDate = orderList1[0].EffectiveDate;
        testOi.EndDate = System.today()+10;
        testOi.OrderId = orderList1[0].Id;
        testOi.PricebookEntryId = standardPrice.id;
        testOi.SBQQ__ChargeType__c = 'Recurring';
        testOi.SBQQ__BillingFrequency__c = 'Monthly';
        testOi.UnitPrice = 0;
        testOi.QTB_Final_Unit_Price__c = 0;
        testOi.SBQQ__BillingType__c = 'Arrears';
        testOi.Quantity = 1;
        testOi.SBQQ__QuoteLine__c = qline.id;
        insert testOi;

        blng__Invoice__c invTest = new blng__Invoice__c();
        invTest.blng__Account__c = acnt.id;
        insert invTest;

        blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
        invLine.blng__Invoice__c = invTest.id;
        invLine.blng__OrderProduct__c = testOi.id;
        insert invLine;
        
        List<QTB_DisplayQuoteRatesController.wrapQuoteRates> returnQuotes = QTB_DisplayQuoteRatesController.getQuoteRates(String.valueOf(invTest.id));
        Test.stopTest();
    }
    
    static testMethod void testmethod2() {
        Test.startTest();
        List<QTB_DisplayQuoteRatesController.wrapQuoteRates> returnQuotes = QTB_DisplayQuoteRatesController.getQuoteRates(null);
        System.assertEquals(0, returnQuotes.size());
        Test.stopTest();
    }
    
    static testMethod void testmethod3() {
        Test.startTest();
        List<QTB_DisplayQuoteRatesController.wrapQuoteRates> returnQuotes = new List<QTB_DisplayQuoteRatesController.wrapQuoteRates>();
        QTB_DisplayQuoteRatesController.wrapQuoteRates rec1 = new QTB_DisplayQuoteRatesController.wrapQuoteRates();
        rec1.OpportunityName = 'TestOpty1';
        rec1.QuoteNumber = 'TestQte1';
        rec1.Product = 'TestPrd1';
        rec1.Consumption_ScheduleName = 'TestCS1';
        rec1.Lower_Bound = '1';
        rec1.Upper_Bound = '2';
        rec1.Price = '20';
        rec1.Price_Type = 'Per Unit';
        returnQuotes.add(rec1);
        
        QTB_DisplayQuoteRatesController.wrapQuoteRates rec2 = new QTB_DisplayQuoteRatesController.wrapQuoteRates();
        rec2.OpportunityName = 'TestOpty2';
        rec2.QuoteNumber = 'TestQte2';
        rec2.Product = 'TestPrd1';
        rec2.Consumption_ScheduleName = 'TestCS2';
        rec2.Lower_Bound = '3';
        rec2.Upper_Bound = '5';
        rec2.Price = '40';
        rec2.Price_Type = 'Per Unit';
        returnQuotes.add(rec2);
        
        QTB_DisplayQuoteRatesController.wrapQuoteRates rec3 = new QTB_DisplayQuoteRatesController.wrapQuoteRates();
        rec3.OpportunityName = 'TestOpty2';
        rec3.QuoteNumber = 'TestQte2';
        rec3.Product = 'TestPrd2';
        rec3.Consumption_ScheduleName = 'TestCS2';
        rec3.Lower_Bound = '6';
        rec3.Upper_Bound = '7';
        rec3.Price = '70';
        rec3.Price_Type = 'Per Unit';
        rec3.invoiceName = 'TEST_INV';
        returnQuotes.add(rec3);
        
        returnQuotes.sort();
       
        System.assertEquals(3, returnQuotes.size());
        Test.stopTest();
    }
}