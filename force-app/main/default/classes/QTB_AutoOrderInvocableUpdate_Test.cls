/*****************************************************************************************************
 * Class: QTB_AutoOrderInvocableUpdate_Test
 * Author: Accenture
 * Purpose: This is a test class for QTB_AutoOrderInvocableUpdate 
 * Change History: 26/3/2021
 * Developer     Date           Description
 * -------------------------------------------------------------------------------------------
 * Accenture
 *******************************************************************************************************/
@IsTest
private class QTB_AutoOrderInvocableUpdate_Test {
    @testSetup
    static void loadData() {
         List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
       Id pricebookId = Test.getStandardPricebookId();
        List<Account> accountList = QTB_TestDataFactory.createAccounts(
            1,
            'Billing Account'
        );
        
        List<PriceBook2> testPriceBook = QTB_TestDataFactory.priceBookMethdLst(
            1,
            'Test Price book'
        );

        testPriceBook[0].isActive = true;
        testPriceBook[0].QTB_Country__c = accountList[0].Billing_County__c;
        update testPriceBook;
        
        /*List<Opportunity> testOpp = QTB_TestDataFactory.createCPQOppsNew(
            accountList,
            'CPQ Billing Opportunity'
        );*/
        
         List<opportunity> testOpp =new  List<opportunity>();
        opportunity  op=New opportunity();
        op.recordtypeid= QTB_Utils.OPP_BILL_RECTYPEID;
        // op.Pricebook2Id = pricebookId;
        op.Primary_Product_Line__c='Records Management';
        op.Name = 'Test';
        op.AccountId = accountList[0].id;
        op.CloseDate = Date.today();
        op.StageName = '1 - Qualification';
        op.Amount = 500;
        
        testOpp.add(op);
        
        database.insert(testOpp);
        
        testOpp[0].Pricebook2Id = pricebookId;
        database.update(testOpp);
        
        List<SBQQ__Quote__c> testquote = QTB_TestDataFactory.createCPQQuotes(
            1,
            testOpp[0].id,
            accountList[0].id,
            true,
            null
        );
        
     


        List<Order> orderList = QTB_TestDataFactory.createSalesOrders(
            1,
            testquote[0].id,
            accountList[0].id,
            testOpp[0].id
        );
        System.debug('flow.id' + orderlist);
        
         order o =  new Order(
            SBQQ__Quote__c = testquote[0].id,
             QTB_OrderCategory__c='Evergreen',
             //status='Activated',
            opportunityId = testOpp[0].id,
            AccountId = accountList[0].id,
            blng__BillingDayOfMonth__c = '1',
            EffectiveDate = Date.today().addDays(5),
            Status = QTB_Constants.DRAFT_STATUS,
            Pricebook2Id = testPriceBook[0].id,
            blng__InvoiceBatch__c = 'Denmark-26th',
            RecordTypeId = QTB_Utils.ORDER_SALES_RECTYPEID
          );
             insert o;
                
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity(
            'India'
        );
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
            'Yes'
        );
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
            'Yes'
        );
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');

        List<product2> product = QTB_TestDataFactory.createProducts(1);
        product[0].SBQQ__SubscriptionTerm__c = 10;
        product[0].SBQQ__SubscriptionTerm__c = 4;
        product[0].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        product[0].ProductCode = '01100-1002';
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        update product[0];

        PricebookEntry standardpricebook = QTB_TestDataFactory.createPricebookEntry(
            product[0]
        );

        ConsumptionSchedule consumption = new ConsumptionSchedule();
        consumption.Name = 'dummy';
        consumption.RatingMethod = 'Tier';
        consumption.Type = 'Range';
        consumption.SBQQ__Category__c = 'Rates';
        consumption.BillingTerm = 10;
        consumption.BillingTermUnit = 'Month';
        insert consumption;

        ConsumptionRate conrate = new ConsumptionRate();
        conrate.ProcessingOrder = 1;
        conrate.PricingMethod = 'PerUnit';
        conrate.LowerBound = 1;
        conrate.Price = 100;
        conrate.ConsumptionScheduleId = consumption.Id;
        insert conrate;

        consumption.IsActive = true;
        update consumption;

        insert new ProductConsumptionSchedule(
            ConsumptionScheduleId = consumption.Id,
            ProductId = product[0].Id
        );
            List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
            1,
            testOpp[0].id,
            accountList[0].id,
            true,
            null
        );
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].recordtypeId = QTB_Utils.QUOTE_BILL_RECTYPEID;
        quoteList[0].QTB_IM_Legal_Entity__c= indiaEntity.id;
        //database.update(quoteList[0]);
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
            1,
            testquote[0].id,
            accountList[0].id
        );

        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(
            1,
            testquote[0].id,
            quoteGroupList[0].id,
            product[0].id
        );
        
         
        

        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(
            orderList[0].Id,
            product[0].Id,
            quoteLinesList,
            standardpricebook
        );

        SBQQ__OrderItemConsumptionSchedule__c ordCS = new SBQQ__OrderItemConsumptionSchedule__c();
        ordCS.SBQQ__BillingTermUnit__c = 'Month';
        ordCS.SBQQ__BillingTerm__c = 4;
        ordCS.SBQQ__Category__c = 'Rates';
        ordCS.SBQQ__RatingMethod__c = 'Tier';
        ordCS.SBQQ__Type__c = 'Range';
        ordCS.SBQQ__ConsumptionSchedule__c = consumption.Id;
        ordCS.blng__BillingRule__c = billingRule.Id;
        ordCS.blng__TaxRule__c = taxRule.Id;
        ordCS.blng__RevenueRecognitionRule__c = revenueRule.Id;
        ordCS.SBQQ__OrderItem__c = orderItemList3[0].Id;
        insert ordCS;

        SBQQ__OrderItemConsumptionRate__c ordRate = new SBQQ__OrderItemConsumptionRate__c(
            SBQQ__ProcessingOrder__c = 1,
            SBQQ__PricingMethod__c = 'PerUnit',
            SBQQ__LowerBound__c = 1,
            SBQQ__Price__c = 100,
            SBQQ__OrderItemConsumptionSchedule__c = ordCS.Id
        );
        insert ordRate;
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
            1,
            quoteList[0].Id,
            accountList[0].id
        );
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        orderList3[0].Status='Activated';
        orderList3[0].QTB_OrderCategory__c='Evergreen';
        orderList3[0].AccountId=accountList[0].id;
         List<OrderItem> orderItemList4 = QTB_TestDataFactory.createCPQOrderItems(
            orderList3[0].Id,
            product[0].Id,
            quoteLinesList,
            standardpricebook
        );
        SBQQ.TriggerControl.disable();
        database.update(orderList3);
        order ord = [select status from order where blng__InvoiceBatch__c = 'Denmark-26th' limit 1];
        
        ord.Status='Activated';
        ord.QTB_OrderCategory__c='Evergreen';
        ord.AccountId=accountList[0].id;
        
        //update ord;
    }
        
        @IsTest
    static void testOrderItemCSDetailsPositive() {
        
        List<Order> orderList = [select id from order]; 
        List<product2> product =[select id from product2];
        List<OrderItem> orderItemList3 =[select id from OrderItem];
        

        Test.startTest();
        QTB_AutoOrderInvocableUpdate.FlowInputs aflow = new QTB_AutoOrderInvocableUpdate.FlowInputs();
        aflow.newOrderCreatedId = orderList[0].id;
        List<OrderItem> codes = new List<OrderItem>();
        codes.Add(orderItemList3[0]);
        aflow.orderItemCollections = codes;
        aflow.matchingAtrribute='123456';
        aflow.productCode=product[0].id;
        aflow.startDate=system.today();
        aflow.endDate=system.today()+1;
        QTB_AutoOrderInvocableUpdate.justIncrement();
        QTB_AutoOrderInvocableUpdate.updateOrderItemCSDetails(
            new List<QTB_AutoOrderInvocableUpdate.flowInputs>{ aflow }
        );
        Test.stopTest();
    
    }
}