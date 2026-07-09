@isTest(seealldata=false)
private class QTB_RunBillNowQueueable_Test {

   static testMethod void testMethod1() {
    List<User> userList = QTB_TestDataFactory.usrMethdLst(1);   
    System.runAs(userList[0]) {
            Test.startTest();
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
        
            update product;
          
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
                product[0]
            );
             
            List<account> accountList = QTB_TestDataFactory.createAccounts(1);
       
            List<opportunity> oppList = QTB_TestDataFactory.createOpps(
                accountList
            );
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
    /*     List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(
        1,
        accountList[0],
        orderList3[0],
        orderproduct[0]
      );
        // usageSum[0].blng__NextBillingDate__c = system.today();
        usageSum[0].blng__NextBillingDate__c = usageSum[0].blng__SummaryEndDate__c;
        update usageSum[0];
        
        system.debug('usageSum@@' +usageSum);
        
        */
        
         //creating usage summary
        List<blng__UsageSummary__c> usageSumList = new List<blng__UsageSummary__c>();
      //  List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(2,testAccount[0],orderList3[0],orderItemList3[0]);
        blng__UsageSummary__c usagesummary = new blng__UsageSummary__c();
        usagesummary.blng__Order__c = orderList3[0].id;
        usagesummary.blng__Account__c = accountList[0].id;
        usagesummary.blng__OrderProduct__c = orderproduct[0].id;
        usagesummary.blng__SummaryEndDate__c = DATE.newInstance(2021, 1, 26);
        usagesummary.blng__SummaryStartDate__c = DATE.newInstance(2021, 1, 1);
        usagesummary.blng__MatchingId__c = '1234';
        usagesummary.blng__Status__c = 'Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
        
        
        blng__UsageSummary__c usagesummary1 = new blng__UsageSummary__c();
         usagesummary1.blng__Order__c = orderList3[0].id;
        usagesummary1.blng__Account__c = accountList[0].id;
        usagesummary1.blng__OrderProduct__c = orderproduct[0].id;
        usagesummary1.blng__SummaryEndDate__c = system.today();
        usagesummary1.blng__SummaryStartDate__c = system.today() -1 ;
        usagesummary1.blng__MatchingId__c = '1234';
        usagesummary1.blng__Status__c = 'Queued For Invoice';
        usagesummary1.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
        
        usageSumList.add(usagesummary);
        usageSumList.add(usagesummary1);
        insert usageSumList;
        
        usageSumList[1].blng__NextBillingDate__c = usageSumList[1].blng__SummaryEndDate__c ;
        update usageSumList;
        
        
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(
        accountList
      );

     orderitem product1=[Select id from orderitem limit 1];
        Order ord=[Select id,OrderNumber from Order Limit 1];
        list<id> ordid = new list<id>();
        ordid.add(ord.id);
       QTB_RunBillNowQueueable objq = new QTB_RunBillNowQueueable(ordid);
        System.enqueueJob(objq);
        Test.stopTest(); 
    }
    }
    

	
}