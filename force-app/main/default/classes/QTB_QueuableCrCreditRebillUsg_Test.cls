/*****************************************************************************************************
* Class		: QTB_QueuableCrCreditRebillUsg_Test
* Author	: IRM/VIRTUSA
* Purpose	: This is a test class for QTB_QueuableCreateCreditRebillUsages
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Ramesh    11/07/2022      Initial Version - Gitlab US #9256 Credit & Rebill  -- Test class
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_QueuableCrCreditRebillUsg_Test {
    
    @testsetup
    private static void setup() {
        //PriceBook
        Id pricebookId = Test.getStandardPricebookId();
        
        //Product
        List<product2> productList = new List<product2>();
        //Product1 -- usage
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p1);        
        insert productList;
        
        //Price Book creation for all product
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(productList[0]);     
        
        //Consumption schedule
        ConsumptionSchedule consumption = new ConsumptionSchedule();
        consumption.Name = 'dummy';
        consumption.RatingMethod = 'Tier';
        consumption.Type = 'Range';
        consumption.SBQQ__Category__c = 'Rates';
        consumption.BillingTerm = 10;
        consumption.BillingTermUnit = 'Month';
        insert consumption;
        
        //Consumption Rate
        ConsumptionRate conrate = new ConsumptionRate();
        conrate.ProcessingOrder = 1;
        conrate.PricingMethod = 'PerUnit';
        conrate.LowerBound = 1;
        conrate.Price = 100;
        conrate.ConsumptionScheduleId = consumption.Id;
        insert conrate;
        
        //Activating Consumption schedule after creation of consumption rate
        consumption.IsActive = true;
        update consumption;
        
        //ProductConsumptionSchedule
        insert new ProductConsumptionSchedule(ConsumptionScheduleId = consumption.Id,ProductId = productList[0].Id);
        
        //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c='United States';
        // accountList[0].CurrencyIsoCode = 'USD';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        accountList[0].ShippingCity = 'New York';
        accountList[0].ShippingState = 'New York';
        accountList[0].ShippingPostalCode = '22131';
        accountList[0].ShippingCountry = 'United States';
        update accountList;
        
        //Legal Entity
        blng__LegalEntity__c USEntity = new blng__LegalEntity__c();
        USEntity.Name = 'Test Legal Entity United States';
        USEntity.blng__Active__c = true;
        USEntity.blng__Country__c = 'United States';
        USEntity.QTB_Type__c = 'Contract';
        //USEntity.QTB_Legal_Entity_Number__c = '45000';
        insert USEntity;
        
        //IM Country
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';        
        insert im;
        
        QTB_Bill_Code_Product_Lookup__c productLookup = new QTB_Bill_Code_Product_Lookup__c(
            QTB_Source_Bill_Code__c = 'VALID_CODE',
            QTB_Country__c = im.Id,
            QTB_Product2__c = productList[0].id
        );
        insert productLookup;
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        //oppList[0].Legal_Entity__c = USEntity.id;
        oppList[0].Billing_Country__c = im.id;
        database.update(oppList);
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].QTB_IM_Legal_Entity__c = USEntity.id;
        quoteList[0].QTB_Opportunity_Billing_Country__c = 'United States';
        database.update(quoteList);
        
        
        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[0].id);
        
        Test.startTest();
        //Order
        List<Order> orderList = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        database.update(orderList);
        
        //Rebill Order
        List<Order> rebillOrderList = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        rebillOrderList[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        rebillOrderList[0].QTB_Rebill_Type__c = 'Regular';
        database.update(rebillOrderList);
        
        //Rebill Order
        List<Order> rebillOrderList1 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        rebillOrderList1[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        rebillOrderList1[0].QTB_Rebill_Type__c = 'Split';
        database.update(rebillOrderList1);
        SBQQ.TriggerControl.disable();
        
        SBQQ.TriggerControl.disable();
        //OrderItem
        List<OrderItem> orderItemList1 = QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,productList[0].Id,quoteLinesList,standardPrice1);
        
        //Rebill OrderItem
        List<OrderItem> rebillOrderItemList2 = QTB_TestDataFactory.createCPQOrderItems(rebillOrderList[0].Id,productList[0].Id,quoteLinesList,standardPrice1);                
        rebillOrderItemList2[0].SBQQ__RequiredBy__c = orderItemList1[0].Id;
        update rebillOrderItemList2;
        
        System.debug('orderItemList1@@'+orderItemList1);
        System.debug('rebillOrderItemList2@@'+rebillOrderItemList2);
        
        //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
        
        //UsageSummary for Invoice
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList[0],orderItemList1[0]);
        blng__UsageSummary__c usagesummary = usageSum[0];        
        usagesummary.blng__Status__c = 'Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary.blng__Subtotal__c = 100;
        usagesummary.blng__TotalQuantity__c = 10;
        usagesummary.blng__PreratedQuantity__c = 20;
        usagesummary.blng__UnbilledQuantity__c = 1;
        usagesummary.blng__UnitPrice__c = 400;
        usagesummary.blng__PreratedAmount__c = 22;
        usagesummary.blng__SummaryStartDate__c = Date.valueOf('2021-07-27');
        usagesummary.blng__Invoice__c = invoiceList[0].id;
        database.update(usagesummary);
        
        //Rebill UsageSummary
        List<blng__UsageSummary__c> rebillUsageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],rebillOrderList[0],rebillOrderItemList2[0]);
        blng__UsageSummary__c rebillUsageSummary = rebillUsageSum[0];        
        rebillUsageSummary.blng__Status__c = 'Queued For Invoice';
        rebillUsageSummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        rebillUsageSummary.blng__Subtotal__c = 100;
        rebillUsageSummary.blng__TotalQuantity__c = 10;
        rebillUsageSummary.blng__PreratedQuantity__c = 20;
        rebillUsageSummary.blng__UnbilledQuantity__c = 1;
        rebillUsageSummary.blng__UnitPrice__c = 400;
        rebillUsageSummary.blng__PreratedAmount__c = 22;
        rebillUsageSummary.blng__SummaryStartDate__c = Date.valueOf('2021-07-27');
        database.update(rebillUsageSummary);
        
        
        //Usages for Invoice
        List<blng__Usage__c> usageList1 = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
        usageList1[0].QTB_System_Generated__c = true;
        usageList1[0].blng__PreratedAmount__c = 100;
        usageList1[0].blng__PreratedQuantity__c = 10;
        usageList1[0].QTB_Service_District__c = '44147';
        usageList1[0].blng__Subtotal__c = 50;
        usageList1[0].blng__OrderProduct__c = orderItemList1[0].id;  
		usageList1[0].QTB_Product_Identifier_1__c =  productLookup.id;  
        usageList1[0].QTB_Start_Date_MRC__c = system.today();
         usageList1[0].QTB_End_Date_MRC__c = system.today() + 1;
        database.update(usageList1);
                
        invoiceList[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceList[0].blng__InvoiceStatus__c = 'Posted';
        invoiceList[0].QTB_Invoice_Type__c = 'ReBill';
        invoiceList[0].QTB_ReBill_Status__c = 'Usage In Progress';
         
        update invoiceList[0];
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        
        //Tax Rule
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;
        
        System.debug('3@@'+Limits.getLimitQueries());
        //Creation of InvoiceLine
         List<blng__InvoiceLine__c> invLineList = new List<blng__InvoiceLine__c>();
        blng__InvoiceLine__c invLineList1 = new blng__InvoiceLine__c();
        invLineList.add(invLineList1);
        //invLineList = QTB_TestDataFactory.createInvoiceLine(1,invoiceList,productList);
        invLineList1.blng__OrderProduct__c = orderItemList1[0].id;
        invLineList1.blng__UsageSummary__c = usagesummary.id;
        invLineList1.blng__Product__c = productList[0].id;
        invLineList1.blng__Invoice__c = invoiceList[0].id;
        invLineList1.blng__InvoiceLineStatus__c = 'Draft';
        invLinelist1.blng__TaxAmount__c = 50;
        invLinelist1.blng__TaxCountry__c = 'India';
        invLinelist1.blng__TaxState__c = 'TN';
        invLinelist1.blng__TaxCity__c = 'Chennai';
        invLinelist1.blng__TaxZipCode__c = '500032';
        invLinelist1.blng__LegalEntity__c = USEntity.id;
        invLinelist1.blng__Subtotal__c = 1000;
        invLinelist1.blng__TaxRule__c = taxRule.id;
        invLinelist1.QTB_Inc_Quantity__c = 10;
        invLinelist1.QTB_Taxable_Amount__c = 10;
        invLinelist1.blng__Quantity__c = 10;
        invLinelist1.blng__UnitPrice__c = 5;
        invLinelist1.blng__InvoiceLineStatus__c = 'Draft';
        invLinelist1.blng__TaxPercentageApplied__c = 24;
        
        insert invLineList;
        usagesummary.blng__InvoiceLine__c = invLineList[0].id;
        database.update(usagesummary);
        
        System.debug('4@@'+Limits.getLimitQueries());
        
        invoiceList[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceList[0].blng__InvoiceStatus__c = 'Posted';       
        invoiceList[0].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        update invoiceList[0];
        Test.stopTest();
    }    
    
    static testMethod void testMethodCrRebillUsage1(){
        Order rebillOrd = [Select id,OrderNumber from Order where QTB_Rebill_Type__c = 'Regular'OR QTB_Rebill_Type__c ='Split' limit 1 ];
        blng__Invoice__c inv1 = [Select id from blng__Invoice__c limit 1];
        Test.startTest();
        QTB_QueuableCreateCreditRebillUsages obj = new  QTB_QueuableCreateCreditRebillUsages(inv1.id,rebillOrd.id);
        System.enqueueJob(obj);
        Test.stopTest();        
    }
    
    static testMethod void testMethodCrRebillUsage2(){
        Order ord=[Select id,OrderNumber from Order limit 1 ];
        blng__Invoice__c inv1=[Select id from blng__Invoice__c limit 1];
        QTB_QueuableCreateCreditRebillUsages.throwExplicitException = true;
        Test.startTest();
        QTB_QueuableCreateCreditRebillUsages obj1 = new  QTB_QueuableCreateCreditRebillUsages(inv1.id,ord.id);
        System.enqueueJob(obj1); 
        Test.stopTest();
    }
}