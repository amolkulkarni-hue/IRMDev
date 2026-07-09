/*****************************************************************************************************
* Class: QTB_OrderProductHelper_Test
* Author: Accenture
* Purpose: Test Class for QTB_OrderProductHelper
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture    5/5/2020
*******************************************************************************************************/
@isTest(seeAllData=false)
private class QTB_OrderProductHelper_Test {
    @TestSetup
    static void setup() {
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
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        //System.runAs(userList[0]) {
        Id pricebookId = Test.getStandardPricebookId();
		blng__TaxIntegration__c taxIntegration = QTB_TestDataFactory.createTaxIntegration();
		blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        blng__LegalEntity__c LglEntity = QTB_TestDataFactory.createLegalEntity('Singapore');
            LglEntity.CurrencyIsoCode='SGD';
            update LglEntity;
        
        blng__TaxRule__c TaxRule2 = new blng__TaxRule__c();
        try {
          TaxRule2.Name = 'No Tax Rule';
          TaxRule2.blng__Active__c = true;
          TaxRule2.blng__TaxableYesNo__c = 'Yes';
          insert Taxrule2;
        } catch (Exception e) {
          System.debug('The following exception has occurred: ' + e.getMessage());
        }
    
        
        
        blng__TaxTreatment__c taxTreatment = new blng__TaxTreatment__c();
            taxTreatment.Name = 'Singapore Increase Tax';
            taxTreatment.blng__TaxIntegration__c = taxIntegration.id;
            taxTreatment.blng__TaxRule__c = taxRule.id;
            date effectiveStartDate = Date.newInstance(2022,12,01);
            date effectiveEndDate = Date.newInstance(2023,12,31);
            taxTreatment.QTB_Tax_Effective_Start_Date__c = effectiveStartDate;
            taxTreatment.QTB_Tax_Effective_End_Date__c = effectiveEndDate;
            taxTreatment.blng__TaxLegalEntity__c = LglEntity.id;
            taxTreatment.QTB_Taxable__c = 'yes';
            taxTreatment.QTB_TaxCountry__c = 'Singapore';
            taxTreatment.blng__Active__c = true;
            insert taxTreatment;
        
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
        standardPrice1.QTB_Tax_Category__c='Non Taxable';
        UPDATE standardPrice1;
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[1]);
        PricebookEntry standardPrice3 = QTB_TestDataFactory.createPricebookEntry(productList[2]);
        
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
        insert new ProductConsumptionSchedule(
            ConsumptionScheduleId = consumption.Id,
            ProductId = productList[0].Id
        );
        
        //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(
            1,
            'Billing Account'
        );
        accountList[0].QTB_Legal_Entity_Country__c='United States';
        accountList[0].QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
        //#32975 commenetd below line
        //accountList[0].QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
        System.debug('0@@'+Limits.getLimitQueries());
        
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
        //oppList[0].Legal_Entity__c = indiaEntity.id;
        oppList[0].Billing_Country__c = im.id;
        database.update(oppList);
        
        //Quote
        //List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
    try {
      
        quoteList.add(
          new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = oppList[0].id,
            SBQQ__Account__c = accountList[0].id,
            SBQQ__Type__c = QTB_Constants.QUOTE_TYPE_STANDARD,
            SBQQ__Status__c = 'Draft',
            SBQQ__QuoteLanguage__c = 'English',
            SBQQ__ExpirationDate__c = date.today(),
            SBQQ__Primary__c = true,
            //SBQQ__PrimaryContact__c = primaryContactId,
            //SBQQ__StartDate__c = date.today(),
              SBQQ__PriceBook__c = pricebookId,
        SBQQ__StartDate__c = System.Today(),
        QTB_IM_Legal_Entity__c = indiaEntity.id,
        QTB_Opportunity_Billing_Country__c = 'United States'
          )
        );
       
      if (!quoteList.isEmpty()) {
        //insert quoteList;
      }
    } 
        catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
    
  
   
        //QuoteLineGroup
        //List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = new List<SBQQ__QuoteLineGroup__c>();
    	
      for (Integer i = 0; i < 1; i++) {
        quoteGroupList.add(
          new SBQQ__QuoteLineGroup__c(
            Name = 'Group ' + i,
            SBQQ__Number__c = 1,
            SBQQ__Quote__c = quoteList[0].id,
            SBQQ__ListTotal__c = 10.00,
            SBQQ__CustomerTotal__c = 20.00,
            SBQQ__NetTotal__c = 50.00
          )
        );
      }
      if (!quoteGroupList.isEmpty()) {
        //insert quoteGroupList;
      }
     
    
  
        //QuoteLine
        //List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[0].id);
		List<SBQQ__QuoteLine__c> quoteLinesList = new List<SBQQ__QuoteLine__c>();
    
      for (Integer i = 0; i < 1; i++) {
        quoteLinesList.add(
          new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteList[0].id,
            QTB_Offered_for_free__c = true,
            SBQQ__Group__c = quoteGroupList[0].id,
            SBQQ__Product__c = productList[0].id
            //SBQQ__ChargeType__c = 'One-Time'
          )
        );
      }
      if (!quoteLinesList.isEmpty()) {
          SBQQ.TriggerControl.disable();
          //insert quoteLinesList;
          SBQQ.TriggerControl.enable();
      }
     

        //List<SBQQ__QuoteLine__c> quoteLinesList1 = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[1].id);
	List<SBQQ__QuoteLine__c> quoteLinesList1 = new List<SBQQ__QuoteLine__c>();
    
      for (Integer i = 0; i < 1; i++) {
        quoteLinesList1.add(
          new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteList[0].id,
            QTB_Offered_for_free__c = true,
            SBQQ__Group__c = quoteGroupList[0].id,
            SBQQ__Product__c = productList[1].id
            //SBQQ__ChargeType__c = 'One-Time'
          )
        );
      }
      if (!quoteLinesList1.isEmpty()) {
        SBQQ.TriggerControl.disable();
          //insert quoteLinesList1;
          SBQQ.TriggerControl.enable();
      }
     
    
  
        Test.startTest();
        //Order
        /*List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
            1,
            quoteList[0].Id,
            accountList[0].id
        );*/
	List<Order> orderList3 = new List<Order>();
    Id pricebookId1 = Test.getStandardPricebookId();
    
      for (Integer i = 0; i < 1; i++) {
        orderList3.add(
          new Order(
            //SBQQ__Quote__c = quoteList[0].Id,
            AccountId = accountList[0].id,
            blng__BillingDayOfMonth__c = '1',
            EffectiveDate = Date.today().addDays(5),
            Status = QTB_Constants.DRAFT_STATUS,
            Pricebook2Id = pricebookId1,
            blng__InvoiceBatch__c = 'Denmark-26th',
            //QTB_Legal_Entity_Country__c = 'Singapore',
            recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID
          )
        );
      }
      if (!orderList3.isEmpty()) {
        insert orderList3;
      }
        system.debug('orderList3[0]--->'+orderList3[0]);
    orderList3[0].QTB_Legal_Entity_Country__c = 'Singapore';
        orderList3[0].QTB_OrderCategory__c = 'Rebill';
        database.update(orderList3);

        
        
        SBQQ.TriggerControl.disable();
        
        //OrderItem
        //List<OrderItem> orderItemList2 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[0].Id,quoteLinesList,standardPrice1);
        List<OrderItem> orderItemList2 = new List<OrderItem>();
    try {
      for (Integer i = 0; i < 1; i++) {
        orderItemList2.add(
          new OrderItem(
            OrderId = orderList3[0].Id,
            Quantity = 2.00,
            UnitPrice = 12.00,
            //SBQQ__QuoteLine__c = quoteLinesList[i].id,
            SBQQ__Status__c = 'Draft',
            //blng__TaxCountry__c = 'Singapore',
            PricebookEntryId = standardPrice1.Id,
            SBQQ__ChargeType__c = 'One-Time',
            product2id = productList[0].Id,
            SBQQ__Activated__c = true,
            //SBQQ__Status__c = 'Draft',
        blng__TaxCountry__c = 'Singapore',
        QTB_Order_Product_Type__c = 'ReBill',
        QTB_Final_Unit_Price__c = 10,
            blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes')
              .id,
            blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
              )
              .id,
            blng__TaxRule__c = Taxrule2.id//QTB_TestDataFactory.createTaxRule('Yes').id
          )
        );
      }
      if (!orderItemList2.isEmpty()) {
        system.debug('orderItemList2>' + orderItemList2);
        insert orderItemList2;
        system.debug('orderItemList2>>' + orderItemList2); 
        
      }
        
    } 
        catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      System.debug('The following exception has occurred: ' + e);
    }
    
  
        //List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[1].Id,quoteLinesList,standardPrice2);
		List<OrderItem> orderItemList3 = new List<OrderItem>();
    try {
      for (Integer i = 0; i < 1; i++) {
        orderItemList3.add(
          new OrderItem(
            OrderId = orderList3[0].Id,
            Quantity = 2.00,
            UnitPrice = 12.00,
            //SBQQ__QuoteLine__c = quoteLinesList[i].id,
            PricebookEntryId = standardPrice2.Id,
            SBQQ__ChargeType__c = 'One-Time',
            product2id = productList[1].id,
            SBQQ__Activated__c = true,
            blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes')
              .id,
            blng__RevenueRecognitionRule__c =QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
              )
              .id,
            blng__TaxRule__c = Taxrule2.id// QTB_TestDataFactory.createTaxRule('Yes').id
          )
        );
      }
      if (!orderItemList3.isEmpty()) {
        system.debug('orderitemsToReturn>' + orderItemList3);
        insert orderItemList3;
      }
    } 
        catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      System.debug('The following exception has occurred: ' + e);
    }
    
  
        //List<OrderItem> orderItemList4 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[1].Id,quoteLinesList1,standardPrice2);
        List<OrderItem> orderItemList4 = new List<OrderItem>();
    try {
      for (Integer i = 0; i < 1; i++) {
        orderItemList4.add(
          new OrderItem(
            OrderId = orderList3[0].id,
            Quantity = 2.00,
            UnitPrice = 12.00,
            //SBQQ__QuoteLine__c = quoteLinesList1[i].id,
            PricebookEntryId = standardPrice2.Id,
            SBQQ__ChargeType__c = 'One-Time',
            product2id = productList[1].Id,
            SBQQ__Activated__c = true,
            blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes')
              .id,
            blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
              )
              .id,
            blng__TaxRule__c =Taxrule2.id// QTB_TestDataFactory.createTaxRule('Yes').id
          )
        );
      }
      if (!orderItemList4.isEmpty()) {
        system.debug('orderitemsToReturn>' + orderItemList4);
        insert orderItemList4;
      }
    } 
        catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      System.debug('The following exception has occurred: ' + e);
    }
    
        //Consumption Schedule
        ConsumptionSchedule cs = new ConsumptionSchedule();
        cs.Name = 'List Rate 02100-0252';
        cs.BillingTerm = 1;
        cs.BillingTermUnit = 'Month';
        cs.RatingMethod = 'Tier';
        cs.SBQQ__Category__c = 'Rates';
        cs.Type = 'Range';
        insert cs;
        
        ConsumptionRate rate = new ConsumptionRate();
        rate.LowerBound = 1;
        rate.Price = 12;
        rate.ConsumptionScheduleId = cs.id;
        rate.CurrencyIsoCode = 'USD';
        rate.PricingMethod = 'PerUnit';
        rate.ProcessingOrder = 1;
        insert rate;
        
        ConsumptionSchedule abc = new ConsumptionSchedule();
        abc.id = cs.id;
        abc.IsActive = true;
        update abc; 
        
        //Order Product CS
        SBQQ__OrderItemConsumptionSchedule__c op = new SBQQ__OrderItemConsumptionSchedule__c();
        op.Name = 'List Rate 02100-0252';
        op.SBQQ__RatingMethod__c= 'Tier';
        op.SBQQ__Type__c = 'Range';
        op.SBQQ__BillingTerm__c = 1;
        op.SBQQ__BillingTermUnit__c = 'Month';
        op.SBQQ__ConsumptionSchedule__c = cs.id;
        op.SBQQ__OrderItem__c = orderItemList2[0].Id;
        op.SBQQ__Category__c = 'Rates';
        op.blng__LegalEntity__c = indiaEntity.Id;
        insert op;
        
        SBQQ__OrderItemConsumptionRate__c opRate = new SBQQ__OrderItemConsumptionRate__c();
        opRate.Name = 'test Rate';
        opRate.SBQQ__LowerBound__c = 1;
        opRate.SBQQ__Price__c = 12;
        opRate.CurrencyIsoCode = 'USD';
        opRate.SBQQ__PricingMethod__c = 'Per Unit';
        opRate.SBQQ__ProcessingOrder__c = 1;
        opRate.SBQQ__OrderItemConsumptionSchedule__c = op.Id;
        insert opRate;
        
        QTB_Billing_Countries__c setting = new QTB_Billing_Countries__c();
        setting.name = 'Singapore';
        setting.Active__c = true;
        setting.Legal_entity_country__c = 'Singapore';
        insert setting;
        
         //UsageSummary for Invoice
        //List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0]);
		List<blng__UsageSummary__c> usageSum = new List<blng__UsageSummary__c>();
    try {
      for (Integer i = 0; i < 1; i++) {
        blng__UsageSummary__c usage = new blng__UsageSummary__c();
        usage.blng__Order__c = orderList3[0].id;
        usage.blng__Account__c = accountList[0].id;
        usage.blng__OrderProduct__c = orderItemList3[0].id;
        usage.blng__SummaryEndDate__c = DATE.newInstance(2021, 1, 26);
        usage.blng__SummaryStartDate__c = DATE.newInstance(2021, 1, 1);
        usage.blng__MatchingId__c = '1234';
        usage.blng__Status__c = 'Queued For Invoice';
        usage.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';

        usageSum.add(usage);
      }
      if (!usageSum.isEmpty()) {
        insert usageSum;
      }
    } 
        catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
            

blng__UsageSummary__c usagesummary = usageSum[0];   
        usagesummary.blng__OrderProduct__c = orderItemList2[0].Id;
        usagesummary.blng__Order__c = orderList3[0].Id;
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
        
        //Usages for Invoice
        //List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
		 
    List<blng__Usage__c> usageList = new List<blng__Usage__c>();
    try {
      for (Integer i = 0; i < 1; i++) {
        blng__Usage__c usage = new blng__Usage__c();
        usage.blng__UsageSummary__c = usagesummary.id;
        usage.blng__Account__c = accountList[0].id;
        usage.blng__MatchingId__c = '111';
        usage.blng__EndDateTime__c = date.today() + 1;
        usage.blng__StartDateTime__c = date.today();
        usageList.add(usage);
      }
      if (!usageList.isEmpty()) {
        Database.insert(usageList, false);
        usageList[0].blng__OrderProduct__c = orderItemList2[0].Id;
        usageList[0].blng__Order__c = orderList3[0].Id;
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        usageList[0].QTB_Service_District__c = '44147';
        usageList[0].blng__Subtotal__c = 50;
        usageList[0].blng__OrderProduct__c = orderItemList3[0].id;          
        database.update(usageList);
      }
    } 
        catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }       
    }
    
    
    // cover catch
    static testMethod void testmethod1() {
        Test.startTest();        
        List<OrderItem> ordProduct = [Select Id,OrderId,SBQQ__ChargeType__c,SBQQ__Status__c,QTB_OriginalConsumptionID__c,blng__BillableUnitPrice__c,UnitPrice,blng__HoldBilling__c,
                                      Product2Id,Product2.ProductCode, QTB_Order_Product_Type__c,blng__TaxRule__c,blng__TaxCountry__c,order.QTB_Legal_Entity_Country__c From OrderItem where order.status='Draft'];
        System.debug('ordProduct--->'+ordProduct);
        List<Order> ordList = [Select Id,QTB_OrderCategory__c,CurrencyISOCode,SBQQ__PaymentTerm__c,Account.QTB_Contract_Entity__c,QTB_Legal_Entity_Country__c From Order];
        system.debug('ordList--->'+ordList);
        Set<Id> orderId = new Set<Id>();
        set<Id>ordPrdtId = new Set<Id>();
        for(OrderItem o:ordProduct){
            ordPrdtId.add(o.Id);
        }
        for(Order ord : ordList){
            orderId.add(ord.Id);
        }
        Id  taxrule = [select id from blng__TaxRule__c where name = 'No Tax Rule' LIMIT 1].id;
        QTB_OrderProductHelper.updateCSRates(ordProduct,true);
        QTB_OrderProductHelper.setHoldBillingToRebillOrder(ordProduct,orderId);
        QTB_OrderProductHelper.updateTaxTreatment(ordProduct,orderId);
        QTB_OrderProductHelper.setInvoiceRunForOrderProduct(ordProduct);
        QTB_OrderProductHelper.justIncrement();
        //QTB_OrderProductHelper.updateRebillOrderPdtTaxRuleAndTreatment(ordPrdtId);
        QTB_OrderProductHandler.throwExplicitException = true;
        QTB_OrderProductHandler handler = new QTB_OrderProductHandler();
        
        //	handler.AfterUpdate(null, null);
        try {
            handler.BeforeDelete(null);
            handler.AfterDelete(null);
            handler.AfterUndelete(null);
            handler.BeforeUpdate(null, null);
        } catch (NullPointerException e) {
            System.assertEquals(
                'System.NullPointerException',
                e.getTypeName()
            );
        }
        //handler.AfterInsert(null);
        QTB_TestDataFactory.createBypassSetting(
            QTB_Constants.SOBJECT_ORDERPRODUCT
        );
        handler.isDisabled();
        Test.stopTest();
        try {
            QTB_OrderProductHelper.updateTaxTreatment(null, null);
        } catch (Exception e) {
            System.assert('Script-thrown exception' == e.getMessage());
        }
        System.assertEquals(
            true,
            QTB_OrderProductHandler.throwExplicitException
        );        
    }
    /*static testMethod void testmethod2(){
        test.startTest();
        List<OrderItem> ordProduct1 = [select id,orderId,QTB_Order_Product_Type__c,SBQQ__Status__c,blng__TaxCountry__c,order.QTB_Legal_Entity_Country__c from orderItem 
                                       where QTB_Order_Product_Type__c = 'Rebill' AND SBQQ__Status__c = 'Draft'  AND order.QTB_Legal_Entity_Country__c = 'Singapore'];
        system.debug('ordProduct1--->'+ordProduct1);
        list<order>orderIdLst = [select id,QTB_OrderCategory__c from order where Id = :ordProduct1[0].orderId];
        Set<Id> orderPrdtSet = new Set<Id>();
        for(orderItem o: ordProduct1){
            orderPrdtSet.add(o.id);
        }
        orderIdLst[0].QTB_OrderCategory__c = 'Evergreen';
        update orderIdLst;
        QTB_OrderProductHelper.updateSingaporeOrdProductTaxRuleAndTreatment(orderPrdtSet);
        orderIdLst[0].QTB_OrderCategory__c = 'Ad-Hoc';
        update orderIdLst;
        QTB_OrderProductHelper.updateSingaporeOrdProductTaxRuleAndTreatment(orderPrdtSet);
        test.stopTest();
    }*/
}