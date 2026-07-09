/*****************************************************************************************************
* Class         : QTB_OrderProductsForRebill_Test
* Purpose       : This is a Test Class used to test This class handle all operation performed of Credit & Rebill Order Product Screen
* Requirement   : Gitlab #9256
* Author        : IRM/Virtusa
* Developer            Date           Description
* -----------------------------------------------------------------------------------------------------
* Sravya       07/10/2022      Initial Version - Gitlab US #9256 Credit & Rebill
*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_OrderProductsForRebill_Test {
    @testsetup
    static void setup(){
        List<QTB_VertexServiceConfigs__c> vertexList = new List<QTB_VertexServiceConfigs__c>();
        QTB_VertexServiceConfigs__c vertex = new QTB_VertexServiceConfigs__c();
        vertex.Name = 'SandboxIntegrationDetails';
        vertex.QTB_UserName__c = 'SalesForce_QuotetoBill';
        vertex.QTB_Password__c = 'Mar@2021';
        vertex.QTB_IRM_APP_ID__c ='VRTX';
        vertex.QTB_ClientKey__c = 'SalesForce_QuotetoBill';
        vertex.QTB_ClientSecret__c ='aa79a4a3-f2e9-4fa9-ac66-8b42470ac31f';
        vertex.QTB_EndpointAuthURL__c = 'https://api-preprod-extl.ironmountain.com/user/login';
        vertex.QTB_EndpointCalculateTaxURL__c = 'https://api-preprod-extl.ironmountain.com/vertex/services/CalculateTax80';
        vertex.QTB_MAX_REQUEST_TIMEOUT__c = 12000;      
        vertexList.add(vertex);
        
        QTB_VertexServiceConfigs__c vertex1 = new QTB_VertexServiceConfigs__c();
        vertex1.Name = 'ProductionIntegrationDetails';
        vertex1.QTB_UserName__c = 'SalesForce_QuotetoBill';
        vertex1.QTB_Password__c = 'Mar@2021';
        vertex1.QTB_IRM_APP_ID__c ='VRTX';
        vertex1.QTB_ClientKey__c = 'SalesForce_QuotetoBill';
        vertex1.QTB_ClientSecret__c ='aa79a4a3-f2e9-4fa9-ac66-8b42470ac31f';
        vertex1.QTB_EndpointAuthURL__c = 'https://api-preprod-extl.ironmountain.com/user/login';
        vertex1.QTB_EndpointCalculateTaxURL__c = 'https://api-preprod-extl.ironmountain.com/vertex/services/CalculateTax80';
        vertex1.QTB_MAX_REQUEST_TIMEOUT__c = 12000;
        vertexList.add(vertex1);        
        insert vertexList;
        
        //Billing Rule
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        billingRule.name = 'No Invoice Rule';
        update billingRule;
        
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        //Billing Finanace
        blng__FinanceBook__c BillingFinanceBook = new blng__FinanceBook__c();
        BillingFinanceBook.Name = 'Accounting Finance Book';
        BillingFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
        BillingFinanceBook.blng__Active__c = true;
        BillingFinanceBook.blng__PeriodType__c='Accounting';
        insert BillingFinanceBook; 
        
        //Billing Treatment
        blng__BillingTreatment__c  BillingTreatment = new blng__BillingTreatment__c();
        BillingTreatment.Name= 'No Invoice Billing Treatment';
        BillingTreatment.blng__Active__c= true;
        BillingTreatment.blng__BillingFinanceBook__c= BillingFinanceBook.id;
        BillingTreatment.blng__BillingRule__c= billingRule.id;
        BillingTreatment.blng__CancellationRule__c='LIFO by Order Product Creation Date';
        insert BillingTreatment;
        
        //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c='United States';
        accountList[0].QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
        accountList[0].QTB_Minimum_Storage_Charges__c = 1000;
        accountList[0].QTB_Minimum_Charges_Start_Date__c = system.today() - 2;
        accountList[0].QTB_Apply_Minimum_Storage_Charges__c = true;
        accountList[0].QTB_Records_Management__c = true;
        accountList[0].QTB_Hold_Billing__c = false;
        update accountList[0];
        
        //Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(),IsActive = true,QTB_Country__c ='Singapore');
        system.debug('standardPricebook@@' +standardPricebook);
        //Execute an update DML on the Pricebook2 record, to make IsStandard to true
        Update standardPricebook;
        
        Id pricebookId = standardPricebook.Id;
        
        //Product
        List<product2> productList = new List<product2>();
        //Product1 -- usage
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        p1.IM_Product_Class__c = 'Records Management';
        p1.QTB_Storage_Product__c = true;
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
        
        insert productList; //insert all products
        
        //Price Book creation for all product
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = pricebookId,Product2Id = productList[0].Id,UnitPrice = 10000,IsActive = true);
        insert standardPrice1;
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[1]);
        PricebookEntry standardPrice3 = QTB_TestDataFactory.createPricebookEntry(productList[2]);        
        
        //Consumption schedule
        ConsumptionSchedule consumption = new ConsumptionSchedule();
        consumption.Name = 'List Rate 02100-0252';
        consumption.RatingMethod = 'Tier';
        consumption.Type = 'Range';
        consumption.SBQQ__Category__c = 'Rates';
        consumption.BillingTerm = 12;
        consumption.BillingTermUnit = 'Month';
        insert consumption;
        
        //Consumption Rate
        ConsumptionRate conrate = new ConsumptionRate();
        conrate.ProcessingOrder = 1;
        conrate.PricingMethod = 'PerUnit';
        conrate.LowerBound = 1;
        conrate.Price = 100;
        conrate.ConsumptionScheduleId = consumption.Id;
        conrate.CurrencyISOCode = 'USD';
        insert conrate;
        
        //Activating Consumption schedule after creation of consumption rate
        consumption.IsActive = true;
        update consumption;
        
        //ProductConsumptionSchedule
        List<ProductConsumptionSchedule> prdCSList = new List<ProductConsumptionSchedule>();
        
        ProductConsumptionSchedule pp1 = new ProductConsumptionSchedule(ConsumptionScheduleId = consumption.Id,ProductId = productList[0].Id);
        prdCSList.add(pp1);
        
        ProductConsumptionSchedule pp2 = new ProductConsumptionSchedule(ConsumptionScheduleId = consumption.Id,ProductId = productList[1].Id);
        prdCSList.add(pp2);
        
        ProductConsumptionSchedule pp3 = new ProductConsumptionSchedule(ConsumptionScheduleId = consumption.Id,ProductId = productList[2].Id);
        prdCSList.add(pp3);
        insert prdCSList;
        
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
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        //oppList[0].Legal_Entity__c = USEntity.id;
        oppList[0].Billing_Country__c = im.id;
        database.update(oppList);
        
        Test.startTest();
        
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
        
        //Order -- Split
        List<Order> orderList = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        orderList[0].QTB_Rebill_Type__c = 'Split';
        database.update(orderList);
        
        //Order -- Regular 
        List<Order> orderList1 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList1[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        orderList1[0].QTB_Rebill_Type__c = 'Regular';
        database.update(orderList1);
        
        SBQQ.TriggerControl.disable();
        
        //OrderItem
        List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,productList[0].Id,quoteLinesList,standardPrice1);
        orderItemList[0].QTB_Order_Product_Type__c = 'ReBill';
        orderItemList[0].QTB_Final_Unit_Price__c = 10;
        orderItemList[0].blng__InvoiceGrouping__c = 'Invoice Group ID';
        orderItemList[0].blng__InvoiceGroupId__c = '123';
        orderItemList[0].blng__TaxRule__c = taxRule.id;
        update orderItemList[0];
        
        //Invoice
        List<blng__Invoice__c> invoiceListFinal = new List<blng__Invoice__c>();
        for (Integer i = 0; i<= 1; i++) {
            blng__Invoice__c invoiceTemp = new blng__Invoice__c();
            invoiceTemp.blng__Account__c = accountList[0].Id;
            invoiceTemp.blng__InvoiceStatus__c = 'Draft';
            //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
            invoiceTemp.blng__InvoiceDate__c = Date.valueOf('2021-07-27');
            invoiceTemp.blng__InvoiceStatus__c = 'Draft';
            invoiceListFinal.add(invoiceTemp);
        }
        if (!invoiceListFinal.isEmpty()) {
            insert invoiceListFinal;
        }
        
        //LegalEntity
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
        
        //Invoice Run
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        
        //Updating Invoice
        invoiceListFinal[1].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceListFinal[1].blng__InvoiceStatus__c = 'Posted';       
        invoiceListFinal[1].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        invoiceListFinal[1].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        invoiceListFinal[1].QTB_Parent_Invoice__c = invoiceListFinal[0].id;
        update invoiceListFinal;
        
        //UsageSummary for Invoice
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList[0],orderItemList[0]);
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
        database.update(usagesummary);
        
        //Usages for
        List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        usageList[0].QTB_Service_District__c = '44147';
        usageList[0].blng__Subtotal__c = 50;
        usageList[0].blng__OrderProduct__c = orderItemList[0].id;          
        database.update(usageList);
        
        update orderItemList[0];
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
                invoiceLine.blng__OrderProduct__c = orderItemList[0].id;
                invoiceLine.blng__UsageSummary__c = usagesummary.id;
                if(i == 0){
                    invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
                }else{
                    invoiceLine.blng__InvoiceLineStatus__c = 'Posted';
                }
                invoiceLine.blng__TaxAmount__c = 50;
                invoiceLine.blng__TaxCountry__c = 'India';
                invoiceLine.blng__TaxState__c = 'TN';
                invoiceLine.blng__TaxCity__c = 'Chennai';
                invoiceLine.blng__TaxZipCode__c = '500032';
                invoiceLine.blng__LegalEntity__c = indiaEntity.id;
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
        Test.stopTest();
    }
    
    /***********************************************************************************************************
* Method      : test_getProduct_getOrderProductMethod
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to cover QTB_OrderProductsForRebill class functionality
**************************************************************************************************************/        
    static testMethod void test_getProduct_getOrderProductMethod(){
        Test.startTest();
        List<Order> ordList = [Select Id,QTB_Legal_Entity_Country__c,QTB_Rebill_Type__c From Order  ];
        List<Order> ordList1 = [Select Id,QTB_Legal_Entity_Country__c From Order where QTB_Rebill_Type__c != 'Split'];
        List<id> OrdsId = new  List<id>();
        for(Order Orders : ordList){
            OrdsId.add(Orders.Id);
        }
        
        List<OrderItem> orderProductlist = [Select Id,Product2Id,blng__InvoiceGroupId__c,Order.QTB_Rebill_Type__c,blng__TaxCountry__c,blng__TaxRule__c,PricebookEntry.Pricebook2id,
                                            Product2.IM_Product_Class__c, CurrencyIsoCode, PricebookEntry.Pricebook2.QTB_Country__c, Product2.QTB_Oracle_Product_Code__c,
                                            PricebookEntry.Pricebook2.IsActive,Product2.ProductCode 
                                            From OrderItem 
                                            where orderId IN :OrdsId and blng__InvoiceGroupId__c != null];
        
        List<blng__Invoice__c> invoiceList = [Select ID,blng__InvoiceDate__c,Name,blng__InvoiceStatus__c,blng__Account__c,blng__Account__r.Id,blng__Account__r.Name,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.AccountNumber,
                                              blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.ShippingCity,blng__Account__r.ShippingCountry,blng__Account__r.IME_Display_Division__c,blng__Account__r.ShippingPostalCode,blng__Account__r.QTB_Legal_Entity_Country__c,
                                              blng__Order__r.SBQQ__Quote__r.QTB_Opportunity_Product_Line__c,blng__TaxErrorMessage__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Identifier__c
                                              From blng__Invoice__c ]; 
        
        List<id> invId = new  List<id>();
        for(blng__Invoice__c invoice : invoiceList){
            invId.add(invoice.Id);
        }
        
        QTB_OrderProductsForRebill.getProducts(ordList[0].id, invoiceList[0].id);
        QTB_OrderProductsForRebill.getProducts(ordList1[0].id, invoiceList[0].id);
        QTB_OrderProductsForRebill.getOrderProducts(ordList[0].id,true);
        QTB_OrderProductsForRebill.getOrderProducts(ordList1[0].id,true);
        QTB_OrderProductsForRebill.getOrderProducts(ordList[0].id,false);
        QTB_OrderProductsForRebill.getOrderProducts(ordList1[0].id,false);
        
        ordList[0].QTB_Legal_Entity_Country__c = 'Singapore';
        update ordList[0];
        
        QTB_OrderProductsForRebill.getProducts(ordList[0].Id,invoiceList[0].id);//covering billingonly country else condition logic
        Test.stopTest();        
    }
    /***********************************************************************************************************
* Method      : testOrderItemCreateUpdateDeleteMethod
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to cover QTB_OrderProductsForRebill class functionality
**************************************************************************************************************/        
    static testMethod void testOrderItemCreateUpdateDeleteMethod(){
        Test.startTest();
        QTB_OrderProductsForRebill.throwExplicitException = false;
        
        //Custom Setting -- BillingOnlyCountry
        QTB_Billing_Countries__c billingOnly = new QTB_Billing_Countries__c();
        billingOnly.Name = 'Singapore';
        billingOnly.Active__c	= true;
        billingOnly.ConsumptionScheduleID__c = 'abc';
        billingOnly.Legal_entity_country__c = 'Singapore';
        insert billingOnly;
        List<SBQQ__Quote__c> quoteList = [Select Id from SBQQ__Quote__c];
        List<Account> accountList = [Select Id from Account];
        List<Order> orderWithoutOrderItemList = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        
        List<Order> ordList = [Select Id,QTB_Legal_Entity_Country__c,QTB_Rebill_Type__c From Order where QTB_Legal_Entity_Country__c = 'United States'];
        system.debug('QTB_Legal_Entity_Country__c' +ordList[0].QTB_Legal_Entity_Country__c);
        List<Order> ordList1 = [Select Id,QTB_Legal_Entity_Country__c From Order where QTB_Rebill_Type__c != 'Split'];
        List<blng__BillingRule__c> noInvoiceBillingRuleList = [SELECT Id FROM  blng__BillingRule__c WHERE NAME = 'No Invoice Rule' limit 1];
        List<OrderItem> orderProductlist1 = [Select Id,blng__InvoiceGroupId__c,Product2.ProductCode From OrderItem where Order.QTB_Rebill_Type__c != 'Split' ];
        List<Product2> productList = [Select Id from Product2];
        List<blng__Invoice__c> invoiceList = [Select ID,blng__InvoiceDate__c,Name,blng__InvoiceStatus__c,blng__Account__c,blng__Account__r.Id,blng__Account__r.Name,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.AccountNumber,
                                              blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.ShippingCity,blng__Account__r.ShippingCountry,blng__Account__r.IME_Display_Division__c,blng__Account__r.ShippingPostalCode,blng__Account__r.QTB_Legal_Entity_Country__c,
                                              blng__Order__r.SBQQ__Quote__r.QTB_Opportunity_Product_Line__c,blng__TaxErrorMessage__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Identifier__c
                                              From blng__Invoice__c ]; 
        string Incs = invoiceList[0].id;
        
        List<id> OrdsId = new  List<id>();
        for(Order Orders : ordList){
            OrdsId.add(Orders.Id);
        }
        
        List<OrderItem> orderProductlist = [Select Id,Product2Id,blng__InvoiceGroupId__c,Order.QTB_Rebill_Type__c,blng__TaxCountry__c,blng__TaxRule__c,PricebookEntry.Pricebook2id,
                                            Product2.IM_Product_Class__c, CurrencyIsoCode, PricebookEntry.Pricebook2.QTB_Country__c, Product2.QTB_Oracle_Product_Code__c,
                                            PricebookEntry.Pricebook2.IsActive,Product2.ProductCode  
                                            From OrderItem 
                                            where orderId IN :OrdsId and blng__InvoiceGroupId__c != null];
        
        List<id> invId = new  List<id>();
        for(blng__Invoice__c invoice : invoiceList){
            invId.add(invoice.Id);
        }
        
        
        productList[0].blng__BillingRule__c = noInvoiceBillingRuleList[0].Id;
        update productList[0];
        QTB_OrderProductsForRebill.createRetrunOrderProducts(productList,ordList[0].id,invoiceList[0].id); 
        QTB_OrderProductsForRebill.createRetrunOrderProducts(productList,orderWithoutOrderItemList[0].id,invoiceList[0].id); 
        QTB_OrderProductsForRebill.validateInvoiceGroupForOrderProduct(ordList[0].id);
        QTB_OrderProductsForRebill.updateOrderProductList(orderProductlist);
        QTB_OrderProductsForRebill.updateOrderProductList(orderProductlist1);
        QTB_OrderProductsForRebill.deleteSelectedOrderProducts(orderProductlist);    
        QTB_OrderProductsForRebill.deleteSelectedOrderProducts(orderProductlist1); 
        QTB_OrderProductsForRebill.getUpdatedOrderProduct(orderProductlist,ordList[0].id);
        QTB_OrderProductsForRebill.getUpdatedOrderProduct(orderProductlist1,ordList1[0].id);
        QTB_OrderProductsForRebill.getInvoiceDetails(Incs);
        
        Test.stopTest();
    }
    
    /***********************************************************************************************************
* Method      : testOrderItemCreateUpdateDeleteExceptions
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to cover excpetion of QTB_OrderProductsForRebill class functionality
**************************************************************************************************************/    
    static testMethod void testOrderItemCreateUpdateDeleteExceptions1(){
        try{
            Test.startTest();
            QTB_OrderProductsForRebill.throwExplicitException = true;
            QTB_OrderProductsForRebill.getOrderProducts(null,null);           
            QTB_OrderProductsForRebill.updateOrderProductList(null);           
            QTB_OrderProductsForRebill.deleteSelectedOrderProducts(null);           
            QTB_OrderProductsForRebill.getProducts(null,null);
            QTB_OrderProductsForRebill.getInvoiceDetails('');
            Test.stopTest();
        }
        catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
        
     
    }
    
    
    /***********************************************************************************************************
* Method      : testOrderItemCreateUpdateDeleteExceptions
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to cover excpetion of QTB_OrderProductsForRebill class functionality
**************************************************************************************************************/    
    static testMethod void testOrderItemCreateUpdateDeleteExceptions2(){
        try{
            Test.startTest();
            QTB_OrderProductsForRebill.throwExplicitException = true;
            QTB_OrderProductsForRebill.createRetrunOrderProducts(null,null,null);
            QTB_OrderProductsForRebill.getUpdatedOrderProduct(null,null);
            QTB_OrderProductsForRebill.validateInvoiceGroupForOrderProduct(null);
            Test.stopTest();
        }
        catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    } 
    
    
    /***********************************************************************************************************
* Method      : testdeleteSelectedOrderProducts
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to cover QTB_OrderProductsForRebill class functionality
**************************************************************************************************************/        
    static testMethod void testdeleteSelectedOrderProducts(){
        Test.startTest();
        QTB_OrderProductsForRebill.throwExplicitException = false;
        List<Order> ordList = [Select Id,QTB_Legal_Entity_Country__c From Order where Status = 'draft' ];    
       
        List<id> OrdsId = new  List<id>();
        for(Order Orders : ordList){
            OrdsId.add(Orders.Id);
        }
        
        List<OrderItem> orderProductlist = [Select Id,Product2Id,blng__InvoiceGroupId__c,Order.QTB_Rebill_Type__c,blng__TaxCountry__c,blng__TaxRule__c,PricebookEntry.Pricebook2id,
                                            Product2.IM_Product_Class__c, CurrencyIsoCode, PricebookEntry.Pricebook2.QTB_Country__c, Product2.QTB_Oracle_Product_Code__c,
                                            PricebookEntry.Pricebook2.IsActive,SBQQ__Status__c From OrderItem where orderId IN :OrdsId /* and SBQQ__Status__c = 'draft' */ ];
											
		List<SBQQ__OrderItemConsumptionSchedule__c> Opcs  =[SELECT id,Name,SBQQ__OrderItem__c,SBQQ__OrderItem__r.OrderItemNumber,SBQQ__OrderItem__r.blng__InvoiceGroupId__c,
		SBQQ__OrderItem__r.Order.QTB_Rebill_Type__c,SBQQ__OrderItem__r.QTB_PrefixMatchingID__c
		FROM SBQQ__OrderItemConsumptionSchedule__c                                                                   
		WHERE SBQQ__OrderItem__c IN : orderProductlist ];

        QTB_OrderProductsForRebill.updateOrderProductList(orderProductlist);
        QTB_OrderProductsForRebill.deleteSelectedOrderProducts(orderProductlist);        
        QTB_OrderProductsForRebill.getUpdatedOrderProduct(orderProductlist,ordList[0].id);
        QTB_OrderProductsForRebill.validateInvoiceGroupForOrderProduct(ordList[0].id);        
        Test.stopTest();
    }    
}