/*****************************************************************************************************
* Class: QTB_OrderProductUtils_Test
* Author: Virtusa
* Purpose: Test Class for QTB_OrderProductUtils
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture    5/5/2020
*******************************************************************************************************/
@isTest(seeAllData=false)
private class QTB_OrderProductUtils_Test {
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
        //blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes'); 
        blng__TaxRule__c taxRule=new blng__TaxRule__c();
        taxRule.Name = 'Standard Taxable Rule';
        taxRule.blng__Active__c = true; 
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;
        
        blng__LegalEntity__c LglEntity = QTB_TestDataFactory.createLegalEntity('Singapore');
        LglEntity.CurrencyIsoCode='SGD';
        update LglEntity;
        
        blng__TaxTreatment__c taxTreatment = new blng__TaxTreatment__c();
        taxTreatment.Name ='Finland Tax Treatment';// 'Singapore Increase Tax';
        taxTreatment.blng__TaxIntegration__c = taxIntegration.id;
        taxTreatment.blng__TaxLegalEntity__c = LglEntity.id;
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
        p1.QTB_Price_Schedule_Category__c = 'Services';
        productList.add(p1);    
        
        //Product2 -- Usage
        product2 p2 = new product2();
        p2.Name = 'Test Product2';
        p2.isActive = true;
        p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p2.SBQQ__HasConsumptionSchedule__c = true;
        p2.QTB_Price_Schedule_Category__c = 'Services';
        productList.add(p2); 
        
        //Product3  -- Bundle Header
        product2 p3 = new product2();
        p3.Name = 'Test Product3';
        p3.isActive = true;
        p3.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p3.SBQQ__HasConsumptionSchedule__c = false;
        p3.QTB_Price_Schedule_Category__c = 'Services';
        productList.add(p3);
        
        insert productList;
        
       
        
        //Price Book creation for all product
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(productList[0]);                
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[1]);
        PricebookEntry standardPrice3 = QTB_TestDataFactory.createPricebookEntry(productList[2]);
        standardPrice2.QTB_Tax_Category__c = '5 Percent Tax';
        UPDATE standardPrice2;
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
        accountList[0].QTB_Language__c='en_US';
        accountList[0].QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM';
        //#32975
        //update accountList
        
        //Legal Entity
        blng__LegalEntity__c indiaEntity = new blng__LegalEntity__c();
        indiaEntity.Name = 'Test Legal Entity United States';
        indiaEntity.blng__Active__c = true;
        indiaEntity.blng__Country__c = 'United States';
        indiaEntity.QTB_Type__c = 'Contract';
        //indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert indiaEntity;
        
        accountList[0].QTB_Contract_Entity__c=indiaEntity.id;
        update accountList;
        
        list<SBQQ__Localization__c> localizationList = new list<SBQQ__Localization__c>();
        SBQQ__Localization__c loc = new SBQQ__Localization__c();
        loc.SBQQ__Product__c = productList[0].id;
        loc.SBQQ__Language__c = accountList[0].QTB_Language__c;
        loc.SBQQ__Text__c = 'Product Name';
        loc.SBQQ__APIName__c = 'Name';
        localizationList.add(loc);
        insert localizationList;
        
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';        
        insert im;
        
        blng__TaxTreatment__c taxTreatment2 = new blng__TaxTreatment__c();
        taxTreatment2.Name ='Finland Tax Treatment';// 'Singapore Increase Tax';
        taxTreatment2.blng__TaxIntegration__c = taxIntegration.id;
        taxTreatment2.blng__TaxLegalEntity__c = indiaEntity.id;
        taxTreatment2.blng__TaxRule__c = taxRule.id;
        // date effectiveStartDate = Date.newInstance(2022,12,01);
        // date effectiveEndDate = Date.newInstance(2023,12,31);
        taxTreatment2.QTB_Tax_Effective_Start_Date__c = effectiveStartDate;
        taxTreatment2.QTB_Tax_Effective_End_Date__c = effectiveEndDate;
        taxTreatment2.blng__TaxLegalEntity__c = LglEntity.id;
        taxTreatment2.QTB_Taxable__c = 'yes';
        taxTreatment2.QTB_TaxCountry__c = 'Singapore';
        taxTreatment2.blng__Active__c = true;
        
        insert taxTreatment2;
        
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
                insert quoteList;
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
            insert quoteGroupList;
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
            insert quoteLinesList;
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
            insert quoteLinesList1;
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
                    SBQQ__Quote__c = quoteList[0].Id,
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
        orderList3[0].QTB_Legal_Entity_Country__c = 'Singapore';
        orderList3[0].QTB_OrderCategory__c = 'Rebill';
        database.update(orderList3);
        
        //Finland
        List<Order> orderList3_Fin = new List<Order>();
        //Id pricebookId1 = Test.getStandardPricebookId();
        
        for (Integer i = 0; i < 1; i++) {
            orderList3_Fin.add(
                new Order(
                    SBQQ__Quote__c = quoteList[0].Id,
                    AccountId = accountList[0].id,
                    blng__BillingDayOfMonth__c = '1',
                    EffectiveDate = Date.today().addDays(5),
                    Status = QTB_Constants.DRAFT_STATUS,
                    Pricebook2Id = pricebookId1,
                    blng__InvoiceBatch__c = 'Denmark-26th',
                    QTB_Legal_Entity_Country__c = 'Finland',
                    recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID
                )
            );
        }
        if (!orderList3_Fin.isEmpty()) {
            insert orderList3_Fin;
        }
        orderList3_Fin[0].QTB_Legal_Entity_Country__c = 'Finland';
        orderList3_Fin[0].QTB_OrderCategory__c = 'Rebill';
        database.update(orderList3_Fin);
        
        
        
        SBQQ.TriggerControl.disable();
        
        // finland OrderItem
        List<OrderItem> orderItemList_fin = new List<OrderItem>();
        try {
            for (Integer i = 0; i < quoteLinesList.size(); i++) {
                orderItemList_fin.add( 
                    new OrderItem(
                        OrderId = orderList3_Fin[0].Id,
                        Quantity = 2.00,
                        UnitPrice = 12.00,
                        SBQQ__QuoteLine__c = quoteLinesList[i].id,
                        SBQQ__Status__c = 'Draft',
                        //blng__TaxCountry__c = 'Singapore',
                        PricebookEntryId = standardPrice1.Id,
                        SBQQ__ChargeType__c = 'One-Time',
                        product2id = productList[0].Id,
                        SBQQ__Activated__c = true,
                        //SBQQ__Status__c = 'Draft',
                        blng__TaxCountry__c = 'Finland',
                        QTB_Order_Product_Type__c = 'ReBill',
                        QTB_Final_Unit_Price__c = 10,
                        blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes')
                        .id,
                        blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule(
                            'Yes'
                        )
                        .id,
                        blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id
                    )
                );
            }
            if (!orderItemList_fin.isEmpty()) {
                insert orderItemList_fin;
                
            }
            
        } 
        catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            System.debug('The following exception has occurred: ' + e);
        }
        
        //End
        
        //OrderItem
        //List<OrderItem> orderItemList2 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[0].Id,quoteLinesList,standardPrice1);
        List<OrderItem> orderItemList2 = new List<OrderItem>();
        try {
            for (Integer i = 0; i < quoteLinesList.size(); i++) {
                orderItemList2.add(
                    new OrderItem(
                        OrderId = orderList3[0].Id,
                        Quantity = 2.00,
                        UnitPrice = 12.00,
                        SBQQ__QuoteLine__c = quoteLinesList[i].id,
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
                        blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id
                    )
                );
            }
            if (!orderItemList2.isEmpty()) {
                insert orderItemList2;
                
            }
            
        } 
        catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            System.debug('The following exception has occurred: ' + e);
        }
        
        
        //List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[1].Id,quoteLinesList,standardPrice2);
        List<OrderItem> orderItemList3 = new List<OrderItem>();
        try {
            for (Integer i = 0; i < quoteLinesList.size(); i++) {
                orderItemList3.add(
                    new OrderItem(
                        OrderId = orderList3[0].Id,
                        Quantity = 2.00,
                        UnitPrice = 12.00,
                        SBQQ__QuoteLine__c = quoteLinesList[i].id,
                        PricebookEntryId = standardPrice2.Id,
                        SBQQ__ChargeType__c = 'One-Time',
                        product2id = productList[1].id,
                        SBQQ__Activated__c = true,
                        blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes')
                        .id,
                        blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule(
                            'Yes'
                        )
                        .id,
                        blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id
                    )
                );
            }
            if (!orderItemList3.isEmpty()) {
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
            for (Integer i = 0; i < quoteLinesList1.size(); i++) {
                orderItemList4.add(
                    new OrderItem(
                        OrderId = orderList3[0].id,
                        Quantity = 2.00,
                        UnitPrice = 12.00,
                        SBQQ__QuoteLine__c = quoteLinesList1[i].id,
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
                        blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id
                    )
                );
            }
            if (!orderItemList4.isEmpty()) {
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
        
        QTB_Billing_Countries__c setting_Fin = new QTB_Billing_Countries__c();
        setting_Fin.name = 'Finland';
        setting_Fin.Active__c = true;
        setting_Fin.Legal_entity_country__c = 'Finland';
        insert setting_Fin;
        
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
            }
        } 
        catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }       
        
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
    
    static testMethod void testmethod1(){
        test.startTest();
        List<OrderItem> ordProduct1 = [select id,orderId,QTB_Order_Product_Type__c,SBQQ__Status__c,blng__TaxCountry__c,order.QTB_Legal_Entity_Country__c from orderItem 
                                       where QTB_Order_Product_Type__c = 'Rebill' AND SBQQ__Status__c = 'Draft'  AND order.QTB_Legal_Entity_Country__c = 'Singapore'];
        list<order>orderIdLst = [select id,QTB_OrderCategory__c from order where Id = :ordProduct1[0].orderId];
        Set<Id> orderPrdtSet = new Set<Id>();
        for(orderItem o: ordProduct1){
            orderPrdtSet.add(o.id);
        }
        orderIdLst[0].QTB_OrderCategory__c = 'Evergreen';
       // update orderIdLst;
        QTB_OrderProductUtils.updateSingaporeOrdProductTaxRuleAndTreatment(orderPrdtSet);
        orderIdLst[0].QTB_OrderCategory__c = 'Ad-Hoc';
        update orderIdLst;
        QTB_OrderProductUtils.updateSingaporeOrdProductTaxRuleAndTreatment(orderPrdtSet);
        test.stopTest();
    }
    static testMethod void testmethod2(){
        test.startTest();
        List<OrderItem> ordProduct1 = [select id,orderId,order.Accountid,QTB_Order_Product_Type__c,SBQQ__Status__c,blng__TaxCountry__c,order.QTB_Legal_Entity_Country__c from orderItem 
                                       where QTB_Order_Product_Type__c = 'Rebill' AND SBQQ__Status__c = 'Draft'  AND order.QTB_Legal_Entity_Country__c = 'Finland'];
        list<order>orderIdLst = [select id,QTB_OrderCategory__c,Accountid,Account.Name,Account.QTB_Contract_Entity__c,QTB_Legal_Entity_Country__c from order where Id = :ordProduct1[0].orderId];
        orderIdLst[0].QTB_Legal_Entity_Country__c ='Finland';
        Update orderIdLst[0];
        
        //list<blng__TaxTreatment__c> ss=[select id from blng__TaxTreatment__c where name='Finland Tax Treatment' ];
        list<blng__TaxTreatment__c> ss=[select id ,blng__TaxRule__r.Name,blng__Active__c from blng__TaxTreatment__c where blng__TaxRule__r.Name='Standard Taxable Rule' and blng__Active__c=TRUE ];
        
        ss[0].blng__TaxLegalEntity__c = orderIdLst[0].Account.QTB_Contract_Entity__c;
        update ss[0];
        
        Set<Id> orderPrdtSet = new Set<Id>();
        for(orderItem o: ordProduct1){
            orderPrdtSet.add(o.orderId);
        }
        orderIdLst[0].QTB_OrderCategory__c = 'Evergreen';
        //update orderIdLst;
        ordProduct1[0].order.QTB_Legal_Entity_Country__c = 'Finland';
        orderIdLst[0].QTB_OrderCategory__c = 'Ad-Hoc';
        update orderIdLst;        
        test.stopTest();
    }
    static testmethod void testmethod3(){
        
        
        
        test.startTest();
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        //System.runAs(userList[0]) {
        Id pricebookId = Test.getStandardPricebookId();
        blng__TaxIntegration__c taxIntegration = QTB_TestDataFactory.createTaxIntegration();
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        blng__LegalEntity__c LglEntity = QTB_TestDataFactory.createLegalEntity('Singapore');
        LglEntity.CurrencyIsoCode='SGD';
        update LglEntity;
        
        
        //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Test Dev1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p1);    
        
        //Product2 -- Usage
        product2 p2 = new product2();
        p2.Name = 'Test Dev2';
        p2.isActive = true;
        p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p2.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p2); 
        
        //Product3  -- Bundle Header
        product2 p3 = new product2();
        p3.Name = 'Test Dev';
        p3.isActive = true;
        p3.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p3.SBQQ__HasConsumptionSchedule__c = false;
        productList.add(p3);
        
        insert productList;
        
        //Price Book creation for all product
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(productList[0]);                
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[1]);
        PricebookEntry standardPrice3 = QTB_TestDataFactory.createPricebookEntry(productList[2]);
        
        //Consumption schedule
        ConsumptionSchedule consumption = new ConsumptionSchedule();
        consumption.Name = 'dummy';
        consumption.RatingMethod = 'Tier';
        consumption.Type = 'Range';
        consumption.SBQQ__Category__c = 'Rates';
        consumption.UnitOfMeasure = 'S7130';
        consumption.BillingTerm = 10;
        consumption.BillingTermUnit = 'Month';
        consumption.QTB_UOM_Description__c = 'Storage';
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
        accountList[0].QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM';
        //#32975
        //update accountList;
        
        //Legal Entity
        blng__LegalEntity__c indiaEntity = new blng__LegalEntity__c();
        indiaEntity.Name = 'Test Legal Entity United States';
        indiaEntity.blng__Active__c = true;
        indiaEntity.blng__Country__c = 'United States';
        indiaEntity.QTB_Type__c = 'Contract';
        //indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert indiaEntity;
        
        accountList[0].QTB_Contract_Entity__c=indiaEntity.id;
        update accountList;
        
        IM_Country__c im =[select id from IM_Country__c where name='United States' limit 1];
        
        blng__TaxTreatment__c taxTreatment2 = new blng__TaxTreatment__c();
        taxTreatment2.Name ='Finland Tax Treatment';// 'Singapore Increase Tax';
        taxTreatment2.blng__TaxIntegration__c = taxIntegration.id;
        taxTreatment2.blng__TaxLegalEntity__c = indiaEntity.id;
        taxTreatment2.blng__TaxRule__c = taxRule.id;
        date effectiveStartDate = Date.newInstance(2022,12,01);
        date effectiveEndDate = Date.newInstance(2023,12,31);
        taxTreatment2.QTB_Tax_Effective_Start_Date__c = effectiveStartDate;
        taxTreatment2.QTB_Tax_Effective_End_Date__c = effectiveEndDate;
        taxTreatment2.blng__TaxLegalEntity__c = LglEntity.id;
        taxTreatment2.QTB_Taxable__c = 'yes';
        taxTreatment2.QTB_TaxCountry__c = 'Finland';
        taxTreatment2.blng__Active__c = true;
        
        insert taxTreatment2;
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        //oppList[0].Legal_Entity__c = indiaEntity.id;
        oppList[0].Billing_Country__c = im.id;
        database.update(oppList);
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
                insert quoteList;
            }
        } 
        catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        
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
            insert quoteGroupList;
        }
        
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
            insert quoteLinesList;
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
            insert quoteLinesList1;
            SBQQ.TriggerControl.enable();
        }
        
        //Finland
        List<Order> orderList3_Fin = new List<Order>();
        Id pricebookId1 = Test.getStandardPricebookId();
        
        for (Integer i = 0; i < 1; i++) {
            orderList3_Fin.add(
                new Order(
                    SBQQ__Quote__c = quoteList[0].Id,
                    AccountId = accountList[0].id,
                    blng__BillingDayOfMonth__c = '1',
                    EffectiveDate = Date.today().addDays(5),
                    Status = QTB_Constants.DRAFT_STATUS,
                    Pricebook2Id = pricebookId1,
                    blng__InvoiceBatch__c = 'Denmark-26th',
                    QTB_Legal_Entity_Country__c = 'Finland',
                    recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID
                )
            );
        }
        if (!orderList3_Fin.isEmpty()) {
            insert orderList3_Fin;
        }
        orderList3_Fin[0].QTB_Legal_Entity_Country__c = 'Finland';
        orderList3_Fin[0].QTB_OrderCategory__c = 'Rebill';
        database.update(orderList3_Fin);
        
        
        
        SBQQ.TriggerControl.disable();
        
        // finland OrderItem
        List<OrderItem> orderItemList_fin = new List<OrderItem>();
        try {
            for (Integer i = 0; i < quoteLinesList.size(); i++) {
                orderItemList_fin.add( 
                    new OrderItem(
                        OrderId = orderList3_Fin[0].Id,
                        Quantity = 2.00,
                        UnitPrice = 12.00,
                        SBQQ__QuoteLine__c = quoteLinesList[i].id,
                        SBQQ__Status__c = 'Draft',
                        //blng__TaxCountry__c = 'Singapore',
                        PricebookEntryId = standardPrice1.Id,
                        SBQQ__ChargeType__c = 'One-Time',
                        product2id = productList[0].Id,
                        SBQQ__Activated__c = true,
                        //SBQQ__Status__c = 'Draft',
                        blng__TaxCountry__c = 'Finland',
                        QTB_Order_Product_Type__c = 'ReBill',
                        QTB_Final_Unit_Price__c = 10,
                        blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes')
                        .id,
                        blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule(
                            'Yes'
                        )
                        .id,
                        blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id
                    )
                );
            }
            if (!orderItemList_fin.isEmpty()) {
                insert orderItemList_fin;
                
            }
            
        } 
        catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            System.debug('The following exception has occurred: ' + e);
        }
        
        //End
        test.stopTest();
        
    }
    static testMethod void testmethod4(){
        List<OrderItem> ordProductList = [select id,QTB_Tax_Category__c,
                                          order.Account.QTB_Special_Tax_Condition__c,blng__InvoiceGroupId__c, 
                                          blng__LegalEntity__r.QTB_Legal_Entity_Number__c,
                                          blng__TaxCountry__c,order.Account.SBQQ__TaxExempt__c,Order.QTB_Legal_Entity_Country__c,order.Account.QTB_Hold_Billing__c
                                          from orderitem where QTB_Tax_Category__c!=null LIMIT 1];
        /*ordProductList[1].blng__InvoiceGroupId__c='Metal Scrap';
        update ordProductList[1];*/
        system.debug('ordProductList:'+ordProductList);
        Test.startTest();
        QTB_OrderProductUtils.updateTaxCategoryBasedTaxTreatments(ordProductList);
        Test.stopTest();
        
    }
    static testMethod void testmethod5(){
        List<OrderItem> ordProductList = [select id,Product2Id,QTB_Price_Schedule_Category__c,
                                          order.Account.QTB_Special_Tax_Condition__c,blng__InvoiceGroupId__c,QTB_Legal_Entity_Country__c,
                                          blng__LegalEntity__r.QTB_Legal_Entity_Number__c,QTB_Language__c,
                                          blng__TaxCountry__c,order.Account.SBQQ__TaxExempt__c,Order.QTB_Legal_Entity_Country__c,order.Account.QTB_Hold_Billing__c
                                          from orderitem];
        Set<String> countries = New Set<String>();
        for(OrderItem oi : ordProductList){
            countries.add(oi.QTB_Legal_Entity_Country__c);
        }
                
        List<Account> accList = [select id,QTB_Language__c from Account];
        Test.startTest();
         QTB_OrderProductUtils.setLocalisedProductName(ordProductList,null);
         QTB_OrderProductUtils.setLocalisedProductName(null,accList);
         QTB_OrderProductUtils.updateUOMDescription(ordProductList,countries);
         QTB_OrderProductUtils.setTranslatedProductGroup(ordProductList,null);
        QTB_OrderProductUtils.setTranslatedProductGroup(null,accList);
      	
        try {
           QTB_OrderProductUtils.setLocalisedProductName(null,null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
        try {
           QTB_OrderProductUtils.setTranslatedProductGroup(null,null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
        try {
           QTB_OrderProductUtils.updateUOMDescription(null,null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
        try {
           QTB_OrderProductUtils.UpdateAccountHoldBillingStatus(null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
        try {
           QTB_OrderProductUtils.updateTaxCategoryBasedTaxTreatments(null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
        Test.stopTest();
    }
    static testmethod void testmethod6(){
                test.startTest();
        List<OrderItem> ordProduct1 = [select id,orderId,order.Accountid,QTB_Order_Product_Type__c,SBQQ__Status__c,blng__TaxCountry__c,order.QTB_Legal_Entity_Country__c from orderItem 
                                       where QTB_Order_Product_Type__c = 'Rebill' AND SBQQ__Status__c = 'Draft'  AND order.QTB_Legal_Entity_Country__c = 'Finland'];
        list<order>orderIdLst = [select id,QTB_OrderCategory__c,Accountid,Account.Name,Account.QTB_Contract_Entity__c,QTB_Legal_Entity_Country__c from order where Id = :ordProduct1[0].orderId];
        orderIdLst[0].QTB_Legal_Entity_Country__c ='Finland';
        Update orderIdLst[0];
        List<Account> lstAcc = [select id,name,QTB_Hold_Billing__c from account where id=:orderIdLst[0].Accountid];
        lstAcc[0].QTB_Hold_Billing__c = true;
        update lstAcc[0];
        //list<blng__TaxTreatment__c> ss=[select id from blng__TaxTreatment__c where name='Finland Tax Treatment' ];
        list<blng__TaxTreatment__c> ss=[select id ,blng__TaxRule__r.Name,blng__Active__c from blng__TaxTreatment__c where blng__TaxRule__r.Name='Standard Taxable Rule' and blng__Active__c=TRUE ];
        
        ss[0].blng__TaxLegalEntity__c = orderIdLst[0].Account.QTB_Contract_Entity__c;
        update ss[0];
        
        Set<Id> orderPrdtSet = new Set<Id>();
        for(orderItem o: ordProduct1){
            orderPrdtSet.add(o.orderId);
        }
        orderIdLst[0].QTB_OrderCategory__c = 'Evergreen';
        //update orderIdLst;
        ordProduct1[0].order.QTB_Legal_Entity_Country__c = 'Finland';
        orderIdLst[0].QTB_OrderCategory__c = 'Ad-Hoc';
        update orderIdLst;
        
        QTB_OrderProductUtils.UpdateAccountHoldBillingStatus(orderPrdtSet);
        
        test.stopTest();
}
    //#32975
    static testMethod void updateUOMDescription() {
        Test.startTest();
    try {
            QTB_OrderProductHandler.throwExplicitException = true;
            QTB_OrderProductUtils.updateUOMDescription(null,null);
        } catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }
        try {
            QTB_OrderProductHandler.throwExplicitException = true;
           QTB_OrderProductUtils.updateSingaporeOrdProductTaxRuleAndTreatment(null);
        } catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }
        Test.stopTest();
    }

}