/*****************************************************************************************************
* Class         : QTB_QueuableCreateCreditRebillOrdCS_Test
* Purpose       : This test class covers methods to support credit & Rebill Process
* Requirement   : Gitlab #9256
* Author        : IRM/Virtusa
* Developer      Date           Description
* ----------------------------------------------------------------------------------------------------
* Sravya       12/07/2022      Gitlab US #9256 Credit & Rebill  -- Test class
*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_QueuableCreateCreditRebillOrdCS_Test {
    @testsetup
    static void setup(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);	
        
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product = QTB_TestDataFactory.createProducts(1);
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        
        update product;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        List<account> accountList = QTB_TestDataFactory.createAccounts(1);
        
       //Legal Entity
        blng__LegalEntity__c indiaEntity = new blng__LegalEntity__c();
        indiaEntity.Name = 'Test Legal Entity United States';
        indiaEntity.blng__Active__c = true;
        indiaEntity.blng__Country__c = 'United States';
        indiaEntity.QTB_Type__c = 'Contract';
        //indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert indiaEntity;
        
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';        
        insert im;
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        oppList[0].Legal_Entity__c = indiaEntity.id;
        oppList[0].Billing_Country__c = im.id;
        database.update(oppList);
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].QTB_IM_Legal_Entity__c = indiaEntity.id;
        quoteList[0].QTB_Opportunity_Billing_Country__c = 'United States';
        database.update(quoteList);
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
            1,
            quoteList[0].id,
            accountList[0].id
        );
        
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
        quoteLinesList[0].SBQQ__ChargeType__c = 'Recurring';
        quoteLinesList[0].SBQQ__BillingType__c = 'Arrears';
        update quoteLinesList;
        ConsumptionSchedule consumption = new ConsumptionSchedule(
            Name = 'dummy',
            RatingMethod = 'Tier',
            Type = 'Range',
            SBQQ__Category__c = 'Rates',
            BillingTerm = 10,
            BillingTermUnit = 'Month'
        );
        insert consumption;
        
        ConsumptionRate conrate = new ConsumptionRate(
            ProcessingOrder = 1,
            PricingMethod = 'PerUnit',
            LowerBound = 1,
            Price = 100,
            ConsumptionScheduleId = consumption.Id
        );
        insert conrate;
        
        consumption.IsActive = true;
        update consumption;
        
        insert new ProductConsumptionSchedule(ConsumptionScheduleId = consumption.Id, ProductId =product[0].id);
        
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
            1,
            quoteList[0].Id,
            accountList[0].id
        );
         SBQQ.TriggerControl.disable();
        List<orderitem>orderproduct = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].id, quoteLinesList,standardPrice);
        SBQQ__OrderItemConsumptionSchedule__c ordCS = new SBQQ__OrderItemConsumptionSchedule__c(
            SBQQ__BillingTermUnit__c = 'Month',
            SBQQ__BillingTerm__c = 4,
            SBQQ__Category__c = 'Rates',
            SBQQ__RatingMethod__c = 'Tier',
            SBQQ__Type__c = 'Range',
            SBQQ__ConsumptionSchedule__c = consumption.Id,
            blng__BillingRule__c = billingRule.Id,
            blng__TaxRule__c = taxRule.Id,
            blng__RevenueRecognitionRule__c = revenueRule.Id,
            SBQQ__OrderItem__c = orderProduct[0].Id
        );			
        insert ordCS;
        SBQQ__OrderItemConsumptionRate__c ordRate = new SBQQ__OrderItemConsumptionRate__c(
            SBQQ__ProcessingOrder__c = 1,
            SBQQ__PricingMethod__c = 'PerUnit',
            SBQQ__LowerBound__c = 1,
            SBQQ__Price__c = 100,
            SBQQ__OrderItemConsumptionSchedule__c = ordCS.Id
        );
        insert ordRate; 
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(
            accountList
        );
    }
    static testMethod void testMethodCrRebillCS(){
        List<orderitem> product1=[Select id,blng__InvoiceGroupId__c from orderitem limit 1];
        //Order ord=[Select id,OrderNumber from Order Limit 1];
       // blng__Invoice__c invoice =[Select id from blng__Invoice__c limit 1];
        Test.startTest();
       map<Id, List<orderitem>> orderitemMap = new map<id, List<orderitem>>();
        orderitemMap.put(product1[0].id,product1);
		string prefixMatchingID = 'prefixMatchingID';
        QTB_QueuableCreateCreditRebillOrderCS obj = new  QTB_QueuableCreateCreditRebillOrderCS(orderitemMap ,prefixMatchingID);
        System.enqueueJob(obj);
        Test.stopTest();
    }
}