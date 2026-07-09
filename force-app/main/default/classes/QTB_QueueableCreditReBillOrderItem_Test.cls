/*****************************************************************************************************
* Class		: QTB_QueueableCreditReBillOrderItem_Test
* Author	: IRM/VIRTUSA
* Purpose	: This is a test class for QTB_QueueableCreditReBillOrderItem
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Ramesh     07/14/2022      Gitlab US #9256 Credit & Rebill
* TCS		28/02/2025		 Gitlab US #29364 code coverage
*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_QueueableCreditReBillOrderItem_Test {
    
    @testSetup
    static void setup() {
        Id pricebookId = Test.getStandardPricebookId();
        
        //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p1);    
        
        //Product2 -- Usage
        product2 p2 = new product2();
        p2.Name = 'Test Product2';
        p2.isActive = true;
        p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p2.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p2); 
        
        //Product3  -- Bundle Header
        product2 p3 = new product2();
        p3.Name = 'Test Product3';
        p3.isActive = true;
        p3.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p3.SBQQ__HasConsumptionSchedule__c = false;
        productList.add(p3);
        
        insert productList;
        
        //Price Book creation for all product
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(productList[0]);                
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[1]);
        
        IM_Country__c country = new IM_Country__c(Name = 'United States',Iso31662Code__c='US');
        database.insert(country);
        //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c='United States';
        //accountList[0].CurrencyIsoCode = 'USD';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        accountList[0].ShippingCity = 'New York';
        accountList[0].ShippingState = 'New York';
        accountList[0].ShippingPostalCode = '22131';
        accountList[0].ShippingCountry = 'United States';
        //accountList[0].IM_Hierarchy_Level__c = 'Sales (Site)';

        update accountList;
        
        System.debug('0@@'+Limits.getLimitQueries());
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        database.update(oppList);
        
        //Quote Template
        SBQQ__QuoteTemplate__c template = new SBQQ__QuoteTemplate__c();
        template.Name = QTB_Constants.DRAFT_PRICE;
        insert template;
        
        SBQQ.TriggerControl.disable();
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        database.update(quoteList);
        
        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList = new List<SBQQ__QuoteLine__c>();
        for (Integer i = 0; i <= 1; i++) {
            quoteLinesList.add(
                new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quoteList[0].id,
                    QTB_Offered_for_free__c = true,
                    SBQQ__Group__c = quoteGroupList[0].id,
                    SBQQ__Product__c = productList[i].id
                )
            );
        }
        
        if (!quoteLinesList.isEmpty()) {
            insert quoteLinesList;
        }

        List<Order> orderListFinal = new List<Order>();
        for (Integer i = 0; i < 1; i++) {
            orderListFinal.add(
                new Order(
                    SBQQ__Quote__c = quoteList[0].Id,
                    AccountId = accountList[0].id,
                    blng__BillingDayOfMonth__c = '1',
                    EffectiveDate = Date.today().addDays(5),
                    Status = QTB_Constants.DRAFT_STATUS,
                    Pricebook2Id = pricebookId,
                    blng__InvoiceBatch__c = 'Denmark-26th',
                    QTB_Legal_Entity_Country__c = 'Norway',
                    recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID
                )
            );
        }
        if (!orderListFinal.isEmpty()) {
            insert orderListFinal;
        }
        
        
        List<OrderItem> orderItemFinal = new List<OrderItem>();
        for (Integer i = 0; i < quoteLinesList.size(); i++) {
            orderItemFinal.add(
                new OrderItem(
                    OrderId = orderListFinal[0].Id,
                    Quantity = 2.00,
                    UnitPrice = 12.00,
                    SBQQ__QuoteLine__c = quoteLinesList[i].id,
                    PricebookEntryId = standardPrice2.Id,
                    SBQQ__ChargeType__c = 'One-Time',
                    product2id = productList[i].Id,
                    SBQQ__Activated__c = true,
                    blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').id,
                    blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').id,
                    blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id
                )
            );
        }
        if (!orderItemFinal.isEmpty()) {
            system.debug('orderitemsToReturn@@' + orderItemFinal);
            insert orderItemFinal;
        }
        
        Test.startTest();
        List<blng__Invoice__c> invoiceListFinal = new List<blng__Invoice__c>();
        for (Integer i = 0; i<= 1; i++) {
            blng__Invoice__c invoiceTemp = new blng__Invoice__c();
            invoiceTemp.blng__Account__c = accountList[0].Id;
            invoiceTemp.blng__InvoiceStatus__c = 'Draft';
            //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
            invoiceListFinal.add(invoiceTemp);
        }
        if (!invoiceListFinal.isEmpty()) {
            insert invoiceListFinal;
        }
        
        System.debug('1@@'+Limits.getLimitQueries());
        
        //UsageSummary for Invoice
        List<blng__UsageSummary__c> usageSumFinal = new List<blng__UsageSummary__c>();
        for (Integer i = 0; i <= 1; i++) {
            blng__UsageSummary__c usageSum = new blng__UsageSummary__c();
            usageSum.blng__Order__c = orderListFinal[0].id;
            usageSum.blng__Account__c = accountList[0].id;
            usageSum.blng__OrderProduct__c = orderItemFinal[i].id;
            usageSum.blng__SummaryEndDate__c = DATE.newInstance(2021, 1, 26);
            usageSum.blng__SummaryStartDate__c = DATE.newInstance(2021, 1, 1);
            usageSum.blng__MatchingId__c = '1234';
            usageSum.blng__Status__c = 'Queued For Invoice';
            usageSum.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
            usageSum.blng__Status__c = 'Queued For Invoice';
            usageSum.blng__InvoiceRunProcessingStatus__c = 'In Progress';
            usageSum.blng__Subtotal__c = 100;
            usageSum.blng__TotalQuantity__c = 10;
            usageSum.blng__PreratedQuantity__c = 20;
            usageSum.blng__UnbilledQuantity__c = 1;
            usageSum.blng__UnitPrice__c = 400;
            usageSum.blng__PreratedAmount__c = 22;
            usageSum.blng__SummaryStartDate__c = Date.valueOf('2021-07-27');
            usageSum.blng__Invoice__c = invoiceListFinal[i].id;
            
            usageSumFinal.add(usageSum);
        }
        if (!usageSumFinal.isEmpty()) {
            insert usageSumFinal;
        }
        
        List<blng__Usage__c> usagesFinal = new List<blng__Usage__c>();
        for (Integer i = 0; i <= 1; i++) {
            blng__Usage__c usage = new blng__Usage__c();
            usage.blng__UsageSummary__c = usageSumFinal[i].id;
            usage.blng__Account__c = accountList[0].id;
            usage.blng__MatchingId__c = '111'+i;
            usage.blng__EndDateTime__c = date.today() + 1;
            usage.blng__StartDateTime__c = date.today();
            usage.QTB_System_Generated__c = true;
            usage.blng__PreratedAmount__c = 100;
            usage.blng__PreratedQuantity__c = 10;
            usage.QTB_Service_District__c = '44147';
            usage.blng__Subtotal__c = 50;
            usage.blng__OrderProduct__c = orderItemFinal[i].id; 
            usagesFinal.add(usage);
        }
        if (!usagesFinal.isEmpty()) {
            Database.insert(usagesFinal, false);
        }
        
        System.debug('2@@'+Limits.getLimitQueries());
        
        invoiceListFinal[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceListFinal[0].blng__InvoiceStatus__c = 'Draft';
        
//        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
        
        blng__LegalEntity__c entityList = QTB_TestDataFactory.createLegalEntity(
                'Norway'
            );
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        
        invoiceListFinal[1].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceListFinal[1].blng__InvoiceStatus__c = 'Posted';       
        invoiceListFinal[1].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        update invoiceListFinal;
        
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;
        System.debug('3@@'+Limits.getLimitQueries());
        List<blng__InvoiceLine__c> invLineListFinal = new List<blng__InvoiceLine__c>();
        for (blng__Invoice__c inv : invoiceListFinal) {
            for (Integer i = 0; i <= 1; i++) {
                blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
                invoiceLine.Name = productList[i].Name;
                invoiceLine.blng__Invoice__c = invoiceListFinal[i].Id;
                invoiceLine.blng__Product__c = productList[i].Id;
                invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
                invoiceLine.blng__Quantity__c = 10;
                invoiceLine.blng__UnitPrice__c = 5;
                invoiceLine.blng__TaxPercentageApplied__c = 24;
                invoiceLine.blng__OrderProduct__c = orderItemFinal[0].id;
                invoiceLine.blng__UsageSummary__c = usageSumFinal[i].id;
                if(i == 0){
                    invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
                }else{
                    invoiceLine.blng__InvoiceLineStatus__c = 'Posted';
                }
                invoiceLine.blng__TaxAmount__c = 50;
                invoiceLine.blng__TaxCountry__c = 'Norway';
                invoiceLine.blng__TaxState__c = 'TN';
                invoiceLine.blng__TaxCity__c = 'Chennai';
                invoiceLine.blng__TaxZipCode__c = '500032';
                invoiceLine.blng__LegalEntity__c = entityList.id;
                invoiceLine.blng__Subtotal__c = 1000;
                invoiceLine.blng__TaxRule__c = taxRule.id;
                invoiceLine.QTB_Inc_Quantity__c = 10;
                invoiceLine.QTB_Taxable_Amount__c = 10; 
                invLineListFinal.add(invoiceLine);
            }
        }
        if (!invLineListFinal.isEmpty()) {
            insert invLineListFinal;
        }
    }
    
    
    
    static testMethod void testMethod1() {
     //   List<User> userList = QTB_TestDataFactory.usrMethdLst(1);        
       // System.runAs(userList[0]) {
            Test.startTest();
            blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
                'Yes'
            );
            blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
            );
          //  blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
          
         blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;
            
            List<product2> product = QTB_TestDataFactory.createProducts(1);
            product[0].blng__BillingRule__c = billingRule.id;
            product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
            product[0].blng__TaxRule__c = taxRule.id;
            product[0].ProductCode = '123';
            
            update product;
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
                product[0]
            );
            blng__LegalEntity__c entityList = QTB_TestDataFactory.createLegalEntity(
                'Norway'
            );
            List<account> accountList = QTB_TestDataFactory.createAccounts(1);
            accountList[0].BillingCountry = 'Norway';
            update accountList;
            
         /*   List<opportunity> oppList = QTB_TestDataFactory.createOpps(
                accountList
            );
            oppList[0].Pricebook2Id = pricebookId;
            update oppList; */
			
             IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';        
        insert im;
            
			 List<opportunity> oppList =new  List<opportunity>();
        opportunity  op=New opportunity();
        op.recordtypeid= QTB_Utils.OPP_BILL_RECTYPEID;
       // op.Pricebook2Id = pricebookId;
        op.Primary_Product_Line__c='Data Management';
        op.Name = 'Test';
        op.AccountId = accountList[0].id;
        op.CloseDate = Date.today();
        op.StageName = '1 - Qualification';
        op.Amount = 500;
        op.Billing_Country__c = im.Id;        
       oppList.add(op);
        
       database.insert(oppList);
       system.debug('71 ');
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
            update quoteList;
             system.debug('85 ');
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
            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
                1,
                quoteList[0].Id,
                accountList[0].id
            );
            orderList3[0].blng__InvoiceBatch__c = 'Norway-26th';
            orderList3[0].EffectiveDate = System.Today();
            try{
                
                update orderList3;
            }
            catch(Exception e){
                 System.assertNotEquals('Script-thrown exception', e.getMessage());
            }
             system.debug('115 ');
            List<orderitem>orderproduct = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].id, quoteLinesList,standardPrice);
            system.debug('117 ');
            List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(
                accountList
            );
        system.debug('120 ');
        
     
            List<OrderItem>ordI=[Select id,OrderItemNumber,product2Id,product2.ProductCode,product2.name,PricebookEntry.UnitPrice, ListPrice,QTB_OriginalConsumptionID__c,PricebookEntryId,blng__BillingRule__c,blng__RevenueRecognitionRule__c,blng__TaxRule__c,SBQQ__BillingFrequency__c from orderitem Limit 1];
            
            blng__Invoice__c inv1=[Select id from blng__Invoice__c limit 1];
            blng__InvoiceLine__c inv=[Select id,blng__Product__c,blng__StartDate__c, blng__EndDate__c,blng__Subtotal__c from blng__InvoiceLine__c limit 1];
            Order order1=[Select id,OrderNumber,QTB_OrderCategory__c,blng__InvoiceBatch__c,QTB_Rebill_Type__c from Order Limit 1];
            
            map<id,order> orderMap = new map<id,order>();
            orderMap.put(order1.id,order1);
            map<id,blng__InvoiceLine__c> invoiceMap = new map<ID,blng__InvoiceLine__c>();
            
            invoiceMap.put(ordI[0].product2Id,inv);
            Test.stopTest();
            QTB_QueueableCreditReBillOrderItem.doChainJob = false;
            Map<Id,Date> productIdWithStartDateMap = new Map<Id,Date>();
            Map<Id,Date> productIdWithEndDateMap = new Map<Id,Date>();
            productIdWithStartDateMap.put(inv.blng__Product__c, inv.blng__StartDate__c);
            productIdWithEndDateMap.put(inv.blng__Product__c, inv.blng__EndDate__c);
            Date startDate = inv.blng__StartDate__c;
            Date endDate = inv.blng__EndDate__c;
		    Integer splitRebillCount = 1;
			string rebillType = 'split';
            try{  
                QTB_QueueableCreditReBillOrderItem obj = new  QTB_QueueableCreditReBillOrderItem(ordI,order1,orderMap,order1.OrderNumber,invoiceMap,inv1.id,productIdWithStartDateMap,productIdWithEndDateMap,startDate,endDate,splitRebillCount,rebillType);
                System.enqueueJob(obj); 
                QTB_QueueableCreditReBillOrderItem.insertReBillOrderItems(null,null,null);
            }
            catch(Exception e){
                 System.assertNotEquals('Script-thrown exception', e.getMessage());
            }
       // }
    }
}