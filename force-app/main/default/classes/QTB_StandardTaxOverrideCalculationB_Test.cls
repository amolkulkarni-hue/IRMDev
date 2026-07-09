@isTest(seealldata=false)
public class QTB_StandardTaxOverrideCalculationB_Test {
 @testSetup
    static void setup() {
        try{
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
        custSetting.SObject_API_Name__c = 'Opportunity;SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;AccountContactRelation;blng__InvoiceRun__c;blng__Usage__c;Order';
        custSetting.Disable_VR__c = true;
        custSetting.Disable_PB__c = true;
        custSetting.Disable_Trigger__c = true;
        // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
        insert custSetting;
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
        
        //List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        //System.runAs(userList[0]) {
        Id pricebookId = Test.getStandardPricebookId();
        
        //Product1 -- usage
        List<Product2> productList = new List<Product2>();
        Product2 p1 = new Product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p1);    
        
        //Product2 -- Usage
        Product2 p2 = new Product2();
        p2.Name = 'Test Product2';
        p2.isActive = true;
        p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p2.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p2); 
        
        //Product3  -- Bundle Header
        Product2 p3 = new Product2();
        p3.Name = 'Test Product3';
        p3.isActive = true;
        p3.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p3.SBQQ__HasConsumptionSchedule__c = false;
        productList.add(p3);
        
        insert productList;
        
        //Price Book creation for all product
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(productList[0]);                
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[1]);
        // PricebookEntry standardPrice3 = QTB_TestDataFactory.createPricebookEntry(productList[2]); //Not Needed
        
        IM_Country__c country = new IM_Country__c(Name = 'United States',Iso31662Code__c='US');
        Database.insert(country);
        
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
        accountList[0].QTB_Legal_Entity_Country__c='Turkey';
        //accountList[0].CurrencyIsoCode = 'USD';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        accountList[0].ShippingCity = 'New York';
        accountList[0].ShippingState = 'New York';
        accountList[0].ShippingPostalCode = '22131';
        accountList[0].ShippingCountry = 'United States';
        accountList[0].QTB_Withholding_Applicable__c = true;
        //accountList[0].IM_Hierarchy_Level__c = 'Sales (Site)';
        
        update accountList;
        
        System.debug('0@@'+Limits.getLimitQueries());
        
        //Opportunity
        List<Opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        Database.update(oppList);
        
        //Quote Template
        SBQQ__QuoteTemplate__c template = new SBQQ__QuoteTemplate__c();
        template.Name = QTB_Constants.DRAFT_PRICE;
        insert template;
        
        SBQQ.TriggerControl.disable();
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].ID,accountList[0].ID,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        Database.update(quoteList);
        
        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].ID,accountList[0].ID);
        
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList = new List<SBQQ__QuoteLine__c>();
        for (Integer i = 0; i <= 1; i++) {
            quoteLinesList.add(
                new SBQQ__QuoteLine__c(
                    SBQQ__Quote__c = quoteList[0].ID,
                    QTB_Offered_for_free__c = true,
                    SBQQ__Group__c = quoteGroupList[0].ID,
                    SBQQ__Product__c = productList[i].ID
                )
            );
        }
        
        if (!quoteLinesList.isEmpty()) {
            insert quoteLinesList;
        }
        
        //List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].ID,quoteGroupList[0].ID,productList[0].ID);
        //List<SBQQ__QuoteLine__c> quoteLinesList1 = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].ID,quoteGroupList[0].ID,productList[1].ID);
        
        //Order
        //List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].ID);
        //orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        //Database.update(orderList3);
        List<Order> orderListFinal = new List<Order>();
        for (Integer i = 0; i < 1; i++) {
            orderListFinal.add(
                new Order(
                    SBQQ__Quote__c = quoteList[0].Id,
                    AccountId = accountList[0].ID,
                    blng__BillingDayOfMonth__c = '1',
                    EffectiveDate = Date.today().addDays(5),
                    Status = QTB_Constants.DRAFT_STATUS,
                    Pricebook2Id = pricebookId,
                    blng__InvoiceBatch__c = 'Denmark-26th',
                    recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID
                )
            );
        }
        if (!orderListFinal.isEmpty()) {
            insert orderListFinal;
        }
        
        //OrderItem
        //List<OrderItem> orderItemList2 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[0].Id,quoteLinesList,standardPrice1);
        // List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderListFinal[0].Id,productList[1].Id,quoteLinesList,standardPrice2);
        //List<OrderItem> orderItemList4 = QTB_TestDataFactory.createCPQOrderItems(orderListFinal[0].Id,productList[1].Id,quoteLinesList,standardPrice2);
        
        List<OrderItem> orderItemFinal = new List<OrderItem>();
        for (Integer i = 0; i < quoteLinesList.size(); i++) {
            orderItemFinal.add(
                new OrderItem(
                    OrderId = orderListFinal[0].Id,
                    Quantity = 2.00,
                    UnitPrice = 12.00,
                    SBQQ__QuoteLine__c = quoteLinesList[i].ID,
                    PricebookEntryId = standardPrice2.Id,
                    SBQQ__ChargeType__c = 'One-Time',
                    product2id = productList[i].Id,
                    SBQQ__Activated__c = true,
                    blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').ID,
                    blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').ID,
                    blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').ID
                )
            );
        }
        if (!orderItemFinal.isEmpty()) {
            System.debug('orderitemsToReturn@@' + orderItemFinal);
            insert orderItemFinal;
        }
        
        Test.startTest();
        //Invoice
        //List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
        //List<blng__Invoice__c> invoiceListForCredit = QTB_TestDataFactory.createInvoices(accountList);
        List<blng__Invoice__c> invoiceListFinal = new List<blng__Invoice__c>();
        for (Integer i = 0; i<= 1; i++) {
            blng__Invoice__c invoiceTemp = new blng__Invoice__c();
            invoiceTemp.blng__Account__c = accountList[0].Id;
            invoiceTemp.blng__InvoiceStatus__c = 'Draft';
            invoiceTemp.blng__Order__c = orderListFinal[0].Id;
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
            usageSum.blng__Order__c = orderListFinal[0].ID;
            usageSum.blng__Account__c = accountList[0].ID;
            usageSum.blng__OrderProduct__c = orderItemFinal[i].ID;
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
            usageSum.blng__Invoice__c = invoiceListFinal[i].ID;
            
            usageSumFinal.add(usageSum);
        }
        if (!usageSumFinal.isEmpty()) {
            insert usageSumFinal;
        }
        
        List<blng__Usage__c> usagesFinal = new List<blng__Usage__c>();
        for (Integer i = 0; i <= 1; i++) {
            blng__Usage__c usage = new blng__Usage__c();
            usage.blng__UsageSummary__c = usageSumFinal[i].ID;
            usage.blng__Account__c = accountList[0].ID;
            usage.blng__MatchingId__c = '111'+i;
            usage.blng__EndDateTime__c = date.today() + 1;
            usage.blng__StartDateTime__c = date.today();
            usage.QTB_System_Generated__c = true;
            usage.blng__PreratedAmount__c = 100;
            usage.blng__PreratedQuantity__c = 10;
            usage.QTB_Service_District__c = '44147';
            usage.blng__Subtotal__c = 50;
            usage.blng__OrderProduct__c = orderItemFinal[i].ID; 
            usagesFinal.add(usage);
        }
        if (!usagesFinal.isEmpty()) {
            Database.insert(usagesFinal, false);
        }
        
        System.debug('2@@'+Limits.getLimitQueries());
        
        invoiceListFinal[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceListFinal[0].blng__InvoiceStatus__c = 'Draft';
        
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('Turkey');
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        
        invoiceListFinal[1].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceListFinal[1].blng__InvoiceStatus__c = 'Posted';       
        invoiceListFinal[1].blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        update invoiceListFinal;
        
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;
        System.debug('3@@'+invoiceListFinal);
        System.debug('4@@'+Limits.getLimitQueries());
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
                invoiceLine.blng__OrderProduct__c = orderItemFinal[0].ID;
                invoiceLine.blng__UsageSummary__c = usageSumFinal[i].ID;
                //invoiceLine.QTB_Payment_Term__c = '120';
                if(i == 0){
                    invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
                }else{
                    invoiceLine.blng__InvoiceLineStatus__c = 'Posted';
                }
                invoiceLine.blng__TaxAmount__c = 50;
                invoiceLine.blng__TaxCountry__c = 'Turkey';
                invoiceLine.blng__TaxState__c = 'TN';
                invoiceLine.blng__TaxCity__c = 'Chennai';
                invoiceLine.blng__TaxZipCode__c = '500032';
                invoiceLine.blng__LegalEntity__c = indiaEntity.ID;
                invoiceLine.blng__Subtotal__c = 1000;
                invoiceLine.blng__TaxRule__c = taxRule.ID;
                invoiceLine.QTB_Inc_Quantity__c = 10;
                invoiceLine.QTB_Taxable_Amount__c = 10; 
                invLineListFinal.add(invoiceLine);
            }
        }
        if (!invLineListFinal.isEmpty()) {
            insert invLineListFinal;
        }
            System.debug('5@@'+invLineListFinal);
        invLineListFinal[0].blng__OrderProduct__c = orderItemFinal[0].ID;
        invLineListFinal[0].blng__UsageSummary__c = usageSumFinal[0].ID;
        //invLineListFinal[0].blng__InvoiceLineStatus__c = 'Posted';       
        invLineListFinal[0].blng__Subtotal__c =123;
        accountList[0].SBQQ__TaxExempt__c = 'No';
        //invLineList[0].blng__InvoiceLineStatus__c = 'Cancelled';
        invLineListFinal[0].blng__TaxStatus__c = 'Completed';
        update invoiceListFinal;
            
            System.debug('6@@'+invoiceListFinal);
            System.debug('7@@'+invLineListFinal);
            System.debug('8@@'+invoiceListFinal[0].id);
            
        Map<id,Set<id>> mapOfInvcAndInvcLineSet = new Map<id,Set<id>>();
        set<id> invoiceLineIds = new set<id>();
            invoiceLineIds.add(invoiceListFinal[0].id);
            mapOfInvcAndInvcLineSet.put(invoiceListFinal[0].Id,invoiceLineIds);
            
        
        //List<blng__InvoiceLine__c> lst = [select id,blng__Invoice__c from blng__InvoiceLine__c where id =: invoiceListFinal[0].id];
        
        Map<ID,blng__InvoiceLine__c> poInvMap = new Map<ID,blng__InvoiceLine__c>();
        //for(blng__InvoiceLine__c Invllist2:lst){
            /*invoiceLineIds.add(Invllist2.id);
            if(mapOfInvcAndInvcLineSet.containsKey(Invllist2.blng__Invoice__c)){
                invoiceLineIds.addAll(mapOfInvcAndInvcLineSet.get(Invllist2.blng__Invoice__c));
            }
            mapOfInvcAndInvcLineSet.put(Invllist2.blng__Invoice__c,invoiceLineIds);
            system.debug('359@@@  '+mapOfInvcAndInvcLineSet);*/
       // if(Invllist2.blng__InvoiceLineStatus__c == 'Posted'){
       //     poInvMap.put(Invllist2.ID,Invllist2);
       //     }
        //}
    List<QTB_Tax_Detail__c>TaxDetailList = new List<QTB_Tax_Detail__c>();
    QTB_Tax_Detail__c td = new QTB_Tax_Detail__c (QTB_Invoice_Line__c = invLineListFinal[0].Id,QTB_Tax_Override_Amount__c = 100);
    TaxDetailList.add(Td);
    QTB_Tax_Detail__c td1 = new QTB_Tax_Detail__c (QTB_Invoice_Line__c = invLineListFinal[0].Id,QTB_Tax_Override_Amount__c = 100,QTB_Withholding_Tax_Rate__c = 10);
    TaxDetailList.add(Td1);
    insert TaxDetailList;
    QTB_StandardTaxOverrideCalculationBatch b=new QTB_StandardTaxOverrideCalculationBatch(mapOfInvcAndInvcLineSet);
    Database.executeBatch(b);  
            test.stopTest();
        }
        //}
        catch(Exception e){
            System.debug('Exception message:'+e.getMessage()); 
        }
    }
 
    static testMethod void testmethod2(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
        test.startTest();
        QTB_StandardTaxOverrideCalculationBatch.throwExplicitException = true;
        Map<id,Set<id>> mapOfInvcAndInvcLineSet = new Map<id,Set<id>>();
        try{
            QTB_StandardTaxOverrideCalculationBatch b=new QTB_StandardTaxOverrideCalculationBatch(mapOfInvcAndInvcLineSet);
            Database.executeBatch(b);
            b.execute(null, null);
        }catch(exception e){
                
            }
        test.stopTest();
        }
    }
}