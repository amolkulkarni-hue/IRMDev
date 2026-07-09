@isTest(seealldata=false)
public class QTB_OrderUsageSummaryMA_Test {
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
        
        //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        p1.IM_Product_Line__c = 'ALM-Secure ITAD';

        productList.add(p1);    
        
        //Product2 -- Usage
        product2 p2 = new product2();
        p2.Name = 'Test Product2';
        p2.isActive = true;
        p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p2.SBQQ__HasConsumptionSchedule__c = true;
        p2.IM_Product_Line__c = 'ALM-Secure ITAD';

        productList.add(p2); 
        
        //Product3  -- Bundle Header
        product2 p3 = new product2();
        p3.Name = 'Test Product3';
        p3.isActive = true;
        p3.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p3.SBQQ__HasConsumptionSchedule__c = false;
        p3.IM_Product_Line__c = 'ALM-Secure ITAD';

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
        update accountList;
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
        /*oppList[0].Pricebook2Id = pricebookId;
        //oppList[0].Legal_Entity__c = indiaEntity.id;
        oppList[0].Billing_Country__c = im.id;
        update oppList;*/
        //database.update(oppList);
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        /*quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].QTB_IM_Legal_Entity__c = indiaEntity.id;
        quoteList[0].QTB_Opportunity_Billing_Country__c = 'United States';
        update quoteList;*/
        //database.update(quoteList);
        
        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[0].id);
        List<SBQQ__QuoteLine__c> quoteLinesList1 = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[1].id);
        Test.startTest();
        //Order
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
            1,
            quoteList[0].Id,
            accountList[0].id
        );
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        orderList3[0].QTB_Case_Number__c = '123456';
        update orderList3;
        //database.update(orderList3);
        
        SBQQ.TriggerControl.disable();
        
        //OrderItem
        List<OrderItem> orderItemList2 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[0].Id,quoteLinesList,standardPrice1);
        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[1].Id,quoteLinesList,standardPrice2);
        List<OrderItem> orderItemList4 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[1].Id,quoteLinesList1,standardPrice2);
        orderItemList2[0].QTB_Order_Product_Type__c = 'ReBill';
        orderItemList2[0].QTB_Final_Unit_Price__c = 10;
        update orderItemList2[0];
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
        
         //UsageSummary for Invoice
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0]);
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
        update usagesummary;
        //database.update(usagesummary);
        
        //Usages for Invoice
        List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
        usageList[0].blng__OrderProduct__c = orderItemList2[0].Id;
        usageList[0].blng__Order__c = orderList3[0].Id;
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        usageList[0].QTB_Service_District__c = '44147';
        usageList[0].blng__Subtotal__c = 50;
        usageList[0].blng__OrderProduct__c = orderItemList3[0].id;          
        update usageList;
        //database.update(usageList);
    }
                  
    static testMethod void testMethod1() {
        Test.startTest();        
        List<OrderItem> ordProduct = [Select Id,OrderId,SBQQ__ChargeType__c,SBQQ__Status__c,QTB_OriginalConsumptionID__c,blng__BillableUnitPrice__c,UnitPrice,blng__HoldBilling__c,
                                      Product2Id,Product2.ProductCode, QTB_Order_Product_Type__c From OrderItem];
        List<Order> ordList = [Select Id,QTB_OrderCategory__c,CurrencyISOCode,SBQQ__PaymentTerm__c,Account.QTB_Contract_Entity__c From Order];
        List<Id> orderId = new List<Id>();
        for(Order ord : ordList){
            orderId.add(ord.Id);
        }
        QTB_OrderUsageSummaryMatchingAttribute.updateMatchingAttribute(orderId);
		List<blng__UsageSummary__c> matchingAttributeList = [Select id, blng__MatchingAttribute__c from blng__UsageSummary__c];
        Assert.isNotNull(matchingAttributeList[0].blng__MatchingAttribute__c);
        
        Test.stopTest();
    }     
    
    /*
    static testMethod void testmethodFoundAUsage() {
        Order ord = new Order();
        ord.QTB_Case_Number__c = '1234';
        List<Account> accId = [select id, name from account];
        System.debug(accId);
        ord.AccountId = accId[0].id;
        ord.EffectiveDate = Date.newInstance(2022, 5, 17);
        ord.status = 'Activated';
   
        List<Order> lOrd = new List<Order>();
        lOrd.add(ord);
        insert lOrd;
        
        Product2 prod1 = new Product2();
        prod1.name = 'Fair Market Value';
        prod1.IM_Product_Line__c = 'ALM-Secure ITAD';
     	insert prod1;
        
        /*Product2 prod2 = new Product2();
        prod2.IM_Product_Line__c = 'NOT - ALM-Secure ITAD';
     	insert prod2;*/
        
        /*OrderItem ordItem1 = new OrderItem();
        ordItem1.OrderId = lOrd[0].id; //lookup to order
        ordItem1.Product2Id = prod1.id; //lookup to product
        ordItem1.SBQQ__ChargeType__c ='One-Time';//insert charge type 
        ordItem1.PricebookEntryId = '01u7b00000UItOiAAL';
        insert ordItem1;*/
        
        /*OrderItem ordItem2 = new OrderItem();
        ordItem2.OrderId = lOrd[0].id; //lookup to order
        ordItem2.Product2Id = prod2.id; //lookup to product
        insert ordItem2;*/
        
        /*blng__UsageSummary__c usageSum = new blng__UsageSummary__c();
        usageSum.blng__MatchingAttribute__c = '';
        insert usageSum;
        
        Test.startTest();
        Order order1 = [Select Id, QTB_Case_Number__c from Order];
        List<OrderItem> orderItems = [SELECT Id, QTB_Product_Line__c from OrderItem where Order.id =: order1.id AND QTB_Product_Line__c like 'ALM-Secure ITAD']; 
		List<Id> orderItemsIds = new List<id>();
        for(OrderItem oI : [SELECT Id from OrderItem where Order.id =: order1.id AND QTB_Product_Line__c like 'ALM-Secure ITAD']) {
        	orderItemsIds.add(oI.id);
        } 
		QTB_OrderUsageSummaryMatchingAttribute.updateMatchingAttribute(orderItemsIds);
	
        Test.stopTest();
    }*/
    /*
    static testMethod void testmethodHandleException() {
        Order ord = new Order();
        ord.QTB_Case_Number__c = '1234';
        List<Account> accId = [select id, name from account];
        System.debug(accId);
        ord.AccountId = accId[0].id;
        ord.EffectiveDate = Date.newInstance(2022, 5, 17);
        ord.status = 'Draft';
        
        List<Order> lOrd = new List<Order>();
        lOrd.add(ord);
        insert lOrd;*/
        
        /*Product2 prod1 = new Product2();
        prod1.IM_Product_Line__c = 'ALM-Secure ITAD';
     	insert prod1;*/
        
        /*Product2 prod2 = new Product2();
        prod2.name = 'Fair Market Value';

        prod2.IM_Product_Line__c = 'NOT - ALM-Secure ITAD';

     	insert prod2;*/
        
        /*OrderItem ordItem1 = new OrderItem();
        ordItem1.OrderId = lOrd[0].id; //lookup to order
        ordItem1.Product2Id = prod1.id; //lookup to product
        insert ordItem1;*/
        
        /*OrderItem ordItem2 = new OrderItem();
        ordItem2.OrderId = lOrd[0].id; //lookup to order
        ordItem2.Product2Id = prod2.id; //lookup to product
        
        ordItem2.SBQQ__ChargeType__c ='One-Time';//insert charge type 
       
        ordItem2.PricebookEntryId = '01u7b00000UItOiAAL';

        insert ordItem2;
        
        blng__UsageSummary__c usageSum = new blng__UsageSummary__c();
        usageSum.blng__MatchingAttribute__c = '';
        insert usageSum;
        
        Test.startTest();
        Order order1 = [Select Id, QTB_Case_Number__c from Order];
        List<OrderItem> orderItems = [SELECT Id, QTB_Product_Line__c from OrderItem where Order.id =: order1.id AND QTB_Product_Line__c like 'ALM-Secure ITAD']; 
		List<Id> orderItemsIds = new List<id>();
        for(OrderItem oI : [SELECT Id from OrderItem where Order.id =: order1.id AND QTB_Product_Line__c like 'ALM-Secure ITAD']) {
        	orderItemsIds.add(oI.id);
        } 
        QTB_OrderUsageSummaryMatchingAttribute.updateMatchingAttribute(orderItemsIds);

        Test.stopTest();
    }*/
}