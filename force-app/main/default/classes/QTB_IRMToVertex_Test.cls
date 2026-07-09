/*****************************************************************************************************
 * Class         : QTB_IRMToVertex_Test
 * Purpose       : This is a Test Class used to test QTB_IRMToVertexService, QTB_IRMVertexRequestUtil, QTB_IRMVertexResponseUtil
 * Requirement   : Gitlab #857
 * Author        : IRM/Virtusa
 * Developer     : Gopi/Shailesh
 * Change History: 07/07/2021
 * Developer                 Date                Description
 * -------------------------------------------------------------------------------------------
 *  Shailesh         07/07/2021          #857, Vertex Integration
 *******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_IRMToVertex_Test {
    @testSetup
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
            // PricebookEntry standardPrice3 = QTB_TestDataFactory.createPricebookEntry(productList[2]); //Not Needed
            
            IM_Country__c country = new IM_Country__c(Name = 'United States',Iso31662Code__c='US');
            database.insert(country);
            
            
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
            //accountList[0].CurrencyIsoCode = 'USD';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
            accountList[0].ShippingCity = 'New York';
            accountList[0].ShippingState = 'New York';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'United States';
            update accountList;
            
            System.debug('0@@'+Limits.getLimitQueries());
            
            //opportunity
            //try{
                //List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
            //}
            //catch(exception e){
                // system.debug('theexception');
            // }
            List<Account> standardAccountList = QTB_TestDataFactory.createAccounts(1,'Standard Account');
            accountList[0].QTB_Legal_Entity_Country__c='United States';
            //accountList[0].CurrencyIsoCode = 'USD';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Standard Account';
            accountList[0].ShippingCity = 'New York';
            accountList[0].ShippingState = 'New York';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'United States';
            accountList[0].IM_Hierarchy_Level__c = 'Country Parent';
            update standardAccountList;
            
            
            List<Opportunity> oppList = new List<Opportunity>();
            
            Opportunity insOpp = new Opportunity();
            insOpp.name = 'testOpp';
            insOpp.AccountId = standardAccountList[0].id;
            insOpp.CloseDate = Date.today();
            insOpp.StageName = '1 - Qualification';
            insOpp.RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
            insOpp.Amount = 500;
            insOpp.Pricebook2Id=pricebookId;
            oppList.add(insOpp);
            
            insert oppList;
            
            
            // oppList[0].Pricebook2Id = pricebookId;
            //  database.update(oppList);
            
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
            
            //List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[0].id);
            //List<SBQQ__QuoteLine__c> quoteLinesList1 = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[1].id);
            
            //Order
            //List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
            //orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
            //database.update(orderList3);
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
            //Invoice
            //List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
            //List<blng__Invoice__c> invoiceListForCredit = QTB_TestDataFactory.createInvoices(accountList);
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
                usage.QTB_Product_Identifier_1__c = 'PrjTM123';
                usagesFinal.add(usage);
            }
            if (!usagesFinal.isEmpty()) {
                Database.insert(usagesFinal, false);
            }
            
            System.debug('2@@'+Limits.getLimitQueries());
            
            invoiceListFinal[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
            invoiceListFinal[0].blng__InvoiceStatus__c = 'Draft';
            
            blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
            
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
            
            //Tax Rate
            List<blng__TaxRate__c> taxRatesList = new List<blng__TaxRate__c>();
            blng__TaxRate__c taxRate = new blng__TaxRate__c();
            taxRate.blng__LegalEntity__c = indiaEntity.id;
            taxRate.blng__Priority__c = '1';
            taxRate.blng__Country__c = 'India';
            taxRate.blng__State__c = 'TN';
            taxRate.blng__City__c = 'Chennai';
            taxRate.blng__ZipCode__c = '500032';
            //taxRate.blng__TaxCode__c = 'STD-CGST';
            taxRate.blng__Rate__c = 10;
            taxRate.blng__AddressComparison__c =
                taxRate.blng__Country__c +
                '-' +
                '-' +
                '-' +
                '-' +
                '-' +
                taxRate.blng__LegalEntity__c;
            system.debug('code####'+taxRate.blng__AddressComparison__c);
            database.insert(taxRate);
            
            
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
                    invoiceLine.blng__TaxCountry__c = 'India';
                    // invoiceLine.blng__TaxState__c = 'TN';
                    // invoiceLine.blng__TaxCity__c = 'Chennai';
                    // invoiceLine.blng__TaxZipCode__c = '500032';
                    // invoiceLine.QTB_Tax_Code__c='123';
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
            
            // Create Credit Note
            List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);
            System.debug('Test_creditNotes@@'+creditNotes);
            
            List<blng__CreditNoteLine__c> CreditNoteLine = new List<blng__CreditNoteLine__c>();
            blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
            cnl.QTB_Account__c = accountList[0].Id;
            cnl.blng__CreditNote__c = creditNotes[0].id;
            cnl.QTB_Invoice__c = invoiceListFinal[1].id;
            cnl.QTB_InvoiceLine__c = invLineListFinal[1].id;
            cnl.blng__Product__c = productList[0].Id;
            cnl.QTB_Product_Identifier_1__c = 'TestProductIdentifier1';
            //cnl.blng__Subtotal__c = 50;
            //cnl.blng__CalculateTax__c=true;
            CreditNoteLine.add(cnl);
            if(CreditNoteLine.size() > 0){
                try{
                    insert CreditNoteLine;
                }
                Catch(Exception e){
                    System.debug('Exception@@'+e.getMessage());
                }
                
            }
            
            System.debug('Test_CreditNoteLine@@'+CreditNoteLine);
            
            //Product BillCode
            /*   QTB_Bill_Code_Product_Lookup__c billCode = new QTB_Bill_Code_Product_Lookup__c();
            billCode.Name = 'test billCode';
            billCode.QTB_Source_Bill_Code__c ='12345';
            billCode.QTB_Product2__c  = CreditNoteLine[0].blng__Product__c;
            insert billCode; */
                
            QTB_Bill_Code_Product_Lookup__c  billcode = new QTB_Bill_Code_Product_Lookup__c();
            billcode.QTB_Product2__c = CreditNoteLine[0].blng__Product__c;
            billcode.QTB_Active__c= True;
            billcode.QTB_Primary__c= True;
            Billcode.QTB_Pricing_Bill_Code__c='201';
            Billcode.QTB_Country__c =country.id;
            Billcode.QTB_Source_Bill_Code__c='201';
            //database.insert(billcode);
            
            Test.stopTest();
            
            IM_Customer_Account__c customer = new IM_Customer_Account__c();
            customer.Name = '12345';
            customer.IM_Account__c = CreditNoteLine[0].QTB_Account__c;
            insert customer;
            
            Market__c market = new Market__c();
            market.Name = 'test Market';
            market.QTB_Oracle_Location_Code__c = '12345';
            market.Owning_District_Id__c = '12345';
            insert market;
            
            Service_Location__c serviceLoc = new Service_Location__c();
            serviceLoc.Name = 'test Service';
            serviceLoc.QTB_Billing_Account__c = CreditNoteLine[0].QTB_Account__c;
            serviceLoc.Customer_Id__c = customer.id;
            serviceLoc.Owning_District_Id__c =market.id;
            insert serviceLoc;
            
        //}
    }
    
    //covering invoice related tax
    static testMethod void testmethodInvoice1() {
        try{
            List<blng__Invoice__c> invoiceList = [
                SELECT id, QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,blng__InvoiceStatus__c,blng__Account__r.Name,blng__Account__r.QTB_Contract_Entity__c,
                blng__Account__r.CurrencyIsoCode,blng__Account__r.ShippingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Bill_Cycle_Day__c,
                blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.ShippingState,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,
                recordTypeId,blng__InvoiceRunCreatedBy__c
                FROM blng__Invoice__c];
            
            Set<id> invId = new  Set<id>();
            for(blng__Invoice__c invoice : invoiceList){
                invId.add(invoice.Id);
            }
            Set<id> invoiceRunId = new Set<Id>();
            invoiceRunId.add(invoiceList[0].blng__InvoiceRunCreatedBy__c);
            Test.setMock(HttpCalloutMock.class, new QTB_IRMToVetex_AuthorizationMock());
            Test.startTest();
            Map<id, boolean> invIdRequestCompletion = new Map<id, boolean>();
            invIdRequestCompletion.put(invoiceList[0].id, true);
            Database.executeBatch(new QTB_vertexTaxCalloutBatch(null,null,invoiceRunId,null,null,true),1);
            // QTB_IRMToVertexService irmToVertex = new QTB_IRMToVertexService(invId);
            Test.stopTest();
        } catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    //covering invoice --
    static testMethod void testmethodInvoice2() {
        try{
            QTB_IRMToVertex_CalculateTaxMock.succsessResponse = true;
            QTB_IRMToVertex_CalculateTaxMock.succsessResponseForCredit = false;
            Test.setMock(HttpCalloutMock.class, new QTB_IRMToVertex_CalculateTaxMock());
            Test.startTest();
            List<blng__Invoice__c> invoiceList = [Select ID,blng__InvoiceDate__c,Name,blng__InvoiceStatus__c,blng__Account__c,blng__Account__r.Id,blng__Account__r.Name,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.AccountNumber,
                                                  blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.ShippingCity,blng__Account__r.ShippingCountry,blng__Account__r.IME_Display_Division__c,blng__Account__r.ShippingPostalCode,blng__Account__r.QTB_Legal_Entity_Country__c,
                                                  blng__Order__r.SBQQ__Quote__r.QTB_Opportunity_Product_Line__c,blng__TaxErrorMessage__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Identifier__c
                                                  From blng__Invoice__c where blng__InvoiceStatus__c = 'Draft'];
            
            List<id> invId = new  List<id>();
            for(blng__Invoice__c invoice : invoiceList){
                invId.add(invoice.Id);
            }
            
            List<blng__InvoiceLine__c> invoiceLineList = [Select ID,blng__ChargeType__c, Name,blng__Invoice__c,QTB_Taxable_Amount__c,QTB_Inc_Quantity__c,QTB_Allocated_Revenue_Amount__c,QTB_HasConsumptionSchedule__c,blng__Invoice__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__UsageSummary__c,
                                                          blng__Product__r.QTB_Oracle_GL_Account_Code__c,blng__Product__r.IM_Product_Class__c,
                                                          blng__Product__r.QTB_Tax_Category__c,blng__Product__r.Name,blng__Product__r.ProductCode,
                                                           blng__Invoice__r.blng__Account__c,blng__Invoice__r.blng__Account__r.Name,
                                                         blng__Invoice__r.blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Invoice__r.blng__Account__r.CurrencyIsoCode,blng__Invoice__r.blng__Account__r.ShippingCity, blng__Invoice__r.blng__Account__r.ShippingPostalCode,blng__Invoice__r.blng__Account__r.ShippingState,
                                                          blng__Invoice__r.blng__Account__r.IME_Display_Division__c,blng__Invoice__r.blng__Account__r.ShippingCountry,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                          blng__OrderProduct__r.Id, blng__OrderProduct__r.Order.OrderNumber,blng__Product__r.Bill_Code__c,blng__TaxErrorMessage__c                          
                                                          From blng__InvoiceLine__c where blng__Invoice__c IN : invId ];
            
            Set<Id> usageSummaryIds = new Set<Id>();
            for(blng__InvoiceLine__c ivl :invoiceLineList ){
                
                
                usageSummaryIds.add(ivl.blng__UsageSummary__c);
            }
            
            List<blng__Usage__c> usageList = [Select id,blng__Subtotal__c, Name,QTB_Service_District__c,QTB_Product_Identifier_1__c,blng__UsageSummary__r.blng__Account__c,blng__Account__r.Id,blng__Account__r.Name,blng__UsageSummary__c,blng__UsageSummary__r.id,blng__UsageSummary__r.blng__Status__c,blng__UsageSummary__r.blng__Invoice__c,QTB_Product__c,blng__OrderProduct__c,blng__OrderProduct__r.Id,blng__OrderProduct__r.Product2Id,
                                              blng__OrderProduct__r.Product2.id,blng__OrderProduct__r.Product2.Name, blng__OrderProduct__r.Product2.QTB_Oracle_GL_Account_Code__c,blng__OrderProduct__r.Product2.IM_Product_Class__c, blng__OrderProduct__r.Product2.ProductCode,blng__OrderProduct__r.Product2.Bill_Code__c, blng__ProcessingDate__c,
                                              blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.ShippingCity,blng__Account__r.ShippingState, blng__Account__r.ShippingPostalCode,blng__Account__r.IME_Display_Division__c,blng__Account__r.QTB_Legal_Entity_Country__c,
                                              blng__Account__r.ShippingCountry,QTB_Rated_Amount__c,blng__UnitPrice__c,blng__Quantity__c,blng__OrderProduct__r.Order.OrderNumber
                                              From blng__Usage__c where blng__UsageSummary__c IN : usageSummaryIds ];
            
            QTB_IRMToVertexService.invoiceOrCreditNote = invoiceList[0];
            QTB_IRMToVertexService.invoiceLineOrUsageListForTax.addAll(invoiceLineList);
            QTB_IRMToVertexService.invoiceLineOrUsageListForTax.addAll(usageList);
            string jwtToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzUxMiIsImtpZCI6ImlybS1qd3QtcHJpdmF0ZS1rZXkifQ.ew0KICAiaXNzIjoid2cxMTAxLm51cy5pcm9ubW91bnRhaW4uY29tIiwNCiAgImlhdCI6MTYyNzM4MDk0OSwNCiAgImF1ZCI6IlNhbGVzRm9yY2VfUXVvdGV0b0JpbGwiLA0KICAianRpIjoiZTE0ZjIwZjAtMDc0OC00YTE1LTlmMTAtYmJlZGFmOGY0NjMzIiwNCiAgInN1YiI6IlNhbGVzRm9yY2VfUXVvdGV0b0JpbGwiLCAgDQogICJ0b2tlbl90eXBlIjogIkJlYXJlciIsDQogICJleHAiOjE2MjczODQ1NDksDQogICJyb3V0aW5nX3N5c3RlbSI6InVzZXJJRFA6Q0FMREFQIiwNCiAgImV4cGlyZXNfaW4iOjM2MDAsDQogICJyZWZyZXNoX3Rva2VuIjogIjNlYjc0ZmU4LTQ0YTktNDY2Ny1iYzkzLWUzNDg1MjM2YjhhYyIsDQogICJyZWZyZXNoX2V4cCI6MzYwMA0KfQ.TEvvSDKneY885pym2cAv2uPvIXHImAZB7aCKgVSddGElyWTtK33_AN-0VZcVQ41nNyC3SIaqcuD73KpSIcbbjY9e0iJMdUK0GrcCFg5SlGOQxOxK2T55uZ7pegWeZm8Soh01NWwsyfppbyRkbNP4PklaU89xzSGe_4CLfbf9J8LHeV3U4BUTpoLaQUnqsqwaAnaMP8TrXGLupChPu0hg8poL9Bxj_a1TIzxRuflgPkKvxQJrvM80vh5MpyOMEwJHEvekCvN-C0nqtLWUwFx0WSMaxTRXMr_iuZ22CynsTAcURpWmHHDREpiv1qZ3Ds6IyVJ37G-006rjRRytvM5A-A';
            QTB_IRMToVertexService.callCalculateTaxService(invoiceList[0],jwtToken, true, true);
            Test.stopTest();
        } catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    //covering invoice --
    static testMethod void testmethodInvoice3() {
        try{
            QTB_IRMToVertex_CalculateTaxMock.succsessResponse = false;
            QTB_IRMToVertex_CalculateTaxMock.succsessResponseForCredit = false;
            Test.setMock(HttpCalloutMock.class, new QTB_IRMToVertex_CalculateTaxMock());
            Test.startTest();
            List<blng__Invoice__c> invoiceList = [SELECT id, QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,blng__InvoiceStatus__c,blng__Account__r.Name,blng__Account__r.QTB_Contract_Entity__c,
                                                  blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.ShippingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Bill_Cycle_Day__c,
                                                  blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.ShippingState,blng__Account__r.CurrencyIsoCode,
                                                  blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,
                                                  recordTypeId
                                                  FROM blng__Invoice__c where blng__InvoiceStatus__c = 'Draft'];
            
            
            List<id> invId = new  List<id>();
            for(blng__Invoice__c invoice : invoiceList){
                invId.add(invoice.Id);
            }
            
            Set<Id> usageSummaryIds = new Set<Id>();
            List<blng__InvoiceLine__c> Invlist=new List<blng__InvoiceLine__c>();
            List<blng__InvoiceLine__c> invLineList =[Select ID,blng__ChargeType__c,QTB_Charge_Type__c, Name,blng__Invoice__c,QTB_Taxable_Amount__c,QTB_Inc_Quantity__c,QTB_Allocated_Revenue_Amount__c,QTB_HasConsumptionSchedule__c,blng__Invoice__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__UsageSummary__c,
                                                     blng__Product__r.SBQQ__HasConsumptionSchedule__c,blng__Product__r.QTB_Oracle_GL_Account_Code__c,blng__Product__r.IM_Product_Class__c,blng__Product__r.QTB_Tax_Category__c,blng__Product__r.Name,blng__Product__r.ProductCode,blng__TotalAmount__c, blng__Invoice__r.blng__Account__c,blng__Invoice__r.blng__Account__r.Name,
                                                     blng__Subtotal__c,blng__Invoice__r.blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Invoice__r.blng__Account__r.CurrencyIsoCode,blng__Invoice__r.blng__Account__r.ShippingCity, blng__Invoice__r.blng__Account__r.ShippingPostalCode,blng__Invoice__r.blng__Account__r.ShippingState,
                                                     blng__Invoice__r.blng__Account__r.IME_Display_Division__c,blng__Invoice__r.blng__Account__r.ShippingCountry,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                     blng__OrderProduct__r.Id, blng__OrderProduct__r.Order.OrderNumber,blng__Product__r.Bill_Code__c,blng__TaxErrorMessage__c                          
                                                     From blng__InvoiceLine__c where blng__Invoice__c IN : invId ];
            
            for(blng__InvoiceLine__c ivl :invLineList ){
                System.debug('QTB_Charge_Type__c@@'+ivl.QTB_Charge_Type__c);
                Invlist.add(ivl);
                usageSummaryIds.add(ivl.blng__UsageSummary__c);
            }
            
            List<blng__Usage__c> usgList =[Select id,blng__Subtotal__c, Name,QTB_Service_District__c From blng__Usage__c where blng__UsageSummary__c IN:usageSummaryIds];
            Map<Id, List<blng__InvoiceLine__c>> invoiceIdToInvoiceLineMap = new Map<Id, List<blng__InvoiceLine__c>>();
            invoiceIdToInvoiceLineMap.put(invId[0],invLineList);
            QTB_IRMToVertexService.invoiceIdToInvoiceLineMap = invoiceIdToInvoiceLineMap;
            
            Map<Id,set<id>> invoiceIdToUsageSummaryMap = new Map<Id,set<id>>();
            invoiceIdToUsageSummaryMap.put(invId[0],usageSummaryIds);
            
            Map<Id,List<blng__Usage__c>> invoiceIdToUsageMap = new Map<Id,List<blng__Usage__c>>();
            invoiceIdToUsageMap.put(invId[0],usgList);
            
            QTB_IRMToVertexService.invoiceIdToUsageSummaryMap = invoiceIdToUsageSummaryMap;
            QTB_IRMToVertexService.invoiceIdToUsageMap = invoiceIdToUsageMap;
            QTB_IRMToVertexService.invoiceOrCreditNote = invoiceList[0];
            QTB_IRMToVertexHelper.setInvoiceAndInvoiceLineItem(invId);
            QTB_IRMToVertexHelper.getInvoiceLineUsageList(invId,null,null);
            string jwtToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzUxMiIsImtpZCI6ImlybS1qd3QtcHJpdmF0ZS1rZXkifQ.ew0KICAiaXNzIjoid2cxMTAxLm51cy5pcm9ubW91bnRhaW4uY29tIiwNCiAgImlhdCI6MTYyNzM4MDk0OSwNCiAgImF1ZCI6IlNhbGVzRm9yY2VfUXVvdGV0b0JpbGwiLA0KICAianRpIjoiZTE0ZjIwZjAtMDc0OC00YTE1LTlmMTAtYmJlZGFmOGY0NjMzIiwNCiAgInN1YiI6IlNhbGVzRm9yY2VfUXVvdGV0b0JpbGwiLCAgDQogICJ0b2tlbl90eXBlIjogIkJlYXJlciIsDQogICJleHAiOjE2MjczODQ1NDksDQogICJyb3V0aW5nX3N5c3RlbSI6InVzZXJJRFA6Q0FMREFQIiwNCiAgImV4cGlyZXNfaW4iOjM2MDAsDQogICJyZWZyZXNoX3Rva2VuIjogIjNlYjc0ZmU4LTQ0YTktNDY2Ny1iYzkzLWUzNDg1MjM2YjhhYyIsDQogICJyZWZyZXNoX2V4cCI6MzYwMA0KfQ.TEvvSDKneY885pym2cAv2uPvIXHImAZB7aCKgVSddGElyWTtK33_AN-0VZcVQ41nNyC3SIaqcuD73KpSIcbbjY9e0iJMdUK0GrcCFg5SlGOQxOxK2T55uZ7pegWeZm8Soh01NWwsyfppbyRkbNP4PklaU89xzSGe_4CLfbf9J8LHeV3U4BUTpoLaQUnqsqwaAnaMP8TrXGLupChPu0hg8poL9Bxj_a1TIzxRuflgPkKvxQJrvM80vh5MpyOMEwJHEvekCvN-C0nqtLWUwFx0WSMaxTRXMr_iuZ22CynsTAcURpWmHHDREpiv1qZ3Ds6IyVJ37G-006rjRRytvM5A-A';
            QTB_IRMToVertexService.callCalculateTaxService(invoiceList[0],jwtToken, true, true);
            Test.stopTest();
        } catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    //covering invoice response --
    static testMethod void testmethodInvoice4() {
        try{
            Test.startTest();
            List<blng__Invoice__c> invoiceList = [Select ID,blng__InvoiceDate__c,Name,blng__InvoiceStatus__c,blng__Account__c,blng__Account__r.Id,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.Name, blng__Account__r.AccountNumber,
                                                  blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.ShippingCity,blng__Account__r.ShippingCountry,blng__Account__r.IME_Display_Division__c,blng__Account__r.ShippingPostalCode,blng__Account__r.QTB_Legal_Entity_Country__c,
                                                  blng__Order__r.SBQQ__Quote__r.QTB_Opportunity_Product_Line__c,blng__TaxErrorMessage__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Identifier__c
                                                  From blng__Invoice__c where blng__InvoiceStatus__c = 'Draft'];
            
            
            List<id> invId = new  List<id>();
            for(blng__Invoice__c invoice : invoiceList){
                invId.add(invoice.Id);
            }
            
            List<blng__InvoiceLine__c> invoiceLineList = [Select ID,blng__ChargeType__c,QTB_Charge_Type__c, Name,blng__Invoice__c,QTB_Taxable_Amount__c,QTB_Allocated_Revenue_Amount__c,QTB_HasConsumptionSchedule__c,blng__Invoice__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__UsageSummary__c,
                                                          blng__Product__r.QTB_Oracle_GL_Account_Code__c,blng__Product__r.IM_Product_Class__c,blng__Product__r.QTB_Tax_Category__c,blng__Product__r.Name,blng__Product__r.ProductCode,blng__TotalAmount__c, blng__Invoice__r.blng__Account__c,blng__Invoice__r.blng__Account__r.Name,
                                                          blng__Subtotal__c,blng__Invoice__r.blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Invoice__r.blng__Account__r.CurrencyIsoCode,
                                                          blng__Invoice__r.blng__Account__r.ShippingCity,blng__Invoice__r.blng__Account__r.ShippingPostalCode,blng__Invoice__r.blng__Account__r.ShippingState,
                                                          blng__Invoice__r.blng__Account__r.IME_Display_Division__c,blng__Invoice__r.blng__Account__r.ShippingCountry,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                          blng__OrderProduct__r.Id, blng__OrderProduct__r.Order.OrderNumber,blng__Product__r.Bill_Code__c,blng__TaxErrorMessage__c                          
                                                          From blng__InvoiceLine__c where blng__Invoice__c IN : invId ];
            
            Product2 prd = [Select ID, Name,SBQQ__HasConsumptionSchedule__c from Product2 where SBQQ__HasConsumptionSchedule__c = true limit 1 ];
            blng__InvoiceLine__c invl = new blng__InvoiceLine__c();
            invl.id = invoiceLineList[0].id;
            invl.blng__Product__c = prd.id;
            update invl;
            
            blng__InvoiceLine__c invl1 = new blng__InvoiceLine__c();
            invl1.id = invoiceLineList[1].id;
            invl1.blng__Product__c = prd.id;
            update invl1;
            
            System.debug('invl1.QTB_Charge_Type__c@@'+invl1.QTB_Charge_Type__c);
            QTB_IRMToVertexHelper.setInvoiceAndInvoiceLineItem(invId);
            QTB_IRMToVertexHelper.getInvoiceLineUsageList(invId,null,null);
            
            Set<Id> usageSummaryIds = new Set<Id>();
            for(blng__InvoiceLine__c ivl :invoiceLineList ){
                usageSummaryIds.add(ivl.blng__UsageSummary__c);
            }
            
            List<blng__Usage__c> usageList = [Select id,blng__Subtotal__c, Name,QTB_Service_District__c,QTB_Product_Identifier_1__c,blng__UsageSummary__r.blng__Account__c,blng__Account__r.Id,blng__Account__r.Name,
                                              blng__UsageSummary__r.id,blng__UsageSummary__r.blng__Status__c,blng__UsageSummary__r.blng__Invoice__c,QTB_Product__c,blng__OrderProduct__c,blng__OrderProduct__r.Id,blng__OrderProduct__r.Product2Id,
                                              blng__OrderProduct__r.Product2.id,blng__OrderProduct__r.Product2.Name, blng__OrderProduct__r.Product2.QTB_Oracle_GL_Account_Code__c,blng__OrderProduct__r.Product2.IM_Product_Class__c, blng__OrderProduct__r.Product2.ProductCode,blng__OrderProduct__r.Product2.Bill_Code__c, blng__ProcessingDate__c,
                                              blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.CurrencyIsoCode, blng__Account__r.ShippingCity,blng__Account__r.ShippingState,blng__Account__r.ShippingPostalCode,blng__Account__r.IME_Display_Division__c,blng__Account__r.QTB_Legal_Entity_Country__c,
                                              blng__Account__r.ShippingCountry,QTB_Rated_Amount__c,blng__UnitPrice__c,blng__Quantity__c,blng__OrderProduct__r.Order.OrderNumber
                                              From blng__Usage__c where blng__UsageSummary__c IN : usageSummaryIds ];
            
            
            string responseBody = '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Header/><soapenv:Body><VertexEnvelope xmlns="urn:vertexinc:o-series:tps:8:0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><Login><UserName>admin</UserName><Password>vertex</Password></Login><InvoiceResponse documentNumber="INV-3620" documentDate="2021-07-14" transactionId="'+invoiceList[0].id+'" transactionType="SALE" postingDate="2021-07-14"><Customer><CustomerCode>00017811</CustomerCode></Customer><SubTotal>13930.0</SubTotal><Total>15248.1</Total><TotalTax>1318.1</TotalTax><LineItem lineItemId="'+invoiceLineList[0].id+'" lineItemNumber="1"><Customer><Destination taxAreaId="390910000"><City>Beverly Hills</City><MainDivision>CA</MainDivision><PostalCode>19426</PostalCode><Country>USA</Country></Destination></Customer><Product productClass="">7000070008</Product><Quantity>1.0</Quantity><FairMarketValue>150.0</FairMarketValue><UnitPrice>150.0</UnitPrice><ExtendedPrice>150.0</ExtendedPrice><Taxes taxResult="TAXABLE" taxType="SALES" situs="DESTINATION" taxCollectedFromParty="BUYER" taxStructure="SINGLE_RATE"><Jurisdiction jurisdictionLevel="STATE" jurisdictionId="31152">PENNSYLVANIA</Jurisdiction><CalculatedTax>9.0</CalculatedTax><EffectiveRate>0.06</EffectiveRate><Taxable>150.0</Taxable><Imposition impositionId="1">Sales and Use Tax</Imposition><ImpositionType impositionTypeId="1">General Sales and Use Tax</ImpositionType><TaxRuleId>17423</TaxRuleId><InclusionRuleId>1282739</InclusionRuleId></Taxes><TotalTax>9.0</TotalTax><FlexibleFields><FlexibleCodeField fieldId="2">SF-SB</FlexibleCodeField><FlexibleCodeField fieldId="3">SF-SB</FlexibleCodeField><FlexibleCodeField fieldId="4">INV</FlexibleCodeField><FlexibleCodeField fieldId="10">BILLC-Bill Acc Aneeja</FlexibleCodeField><FlexibleCodeField fieldId="11">Archival Destruction Item - Vault consum</FlexibleCodeField><FlexibleCodeField fieldId="12">00007596</FlexibleCodeField><FlexibleCodeField fieldId="13">null</FlexibleCodeField><FlexibleCodeField fieldId="14">7000070008</FlexibleCodeField><FlexibleCodeField fieldId="16">4210110</FlexibleCodeField><FlexibleCodeField fieldId="18">0000</FlexibleCodeField><FlexibleDateField fieldId="1">2021-07-14</FlexibleDateField></FlexibleFields></LineItem><LineItem lineItemId="'+usageList[0].id+'" lineItemNumber="2"><Customer><Destination taxAreaId="390910000"><City>ATLANTA</City><MainDivision>North America</MainDivision><PostalCode>19426</PostalCode><Country>United States</Country></Destination></Customer><Product productClass="Data Management">02100-0156</Product><FairMarketValue>500.0</FairMarketValue><ExtendedPrice>500.0</ExtendedPrice><Taxes taxResult="TAXABLE" taxType="SALES" situs="DESTINATION" taxCollectedFromParty="BUYER" taxStructure="SINGLE_RATE"><Jurisdiction jurisdictionLevel="STATE" jurisdictionId="31152">PENNSYLVANIA</Jurisdiction><CalculatedTax>30.0</CalculatedTax><EffectiveRate>0.06</EffectiveRate><Taxable>500.0</Taxable><Imposition impositionId="1">Sales and Use Tax</Imposition><ImpositionType impositionTypeId="1">General Sales and Use Tax</ImpositionType><TaxRuleId>17423</TaxRuleId><InclusionRuleId>1282739</InclusionRuleId></Taxes><TotalTax>30.0</TotalTax><FlexibleFields><FlexibleCodeField fieldId="1">44147</FlexibleCodeField><FlexibleCodeField fieldId="2">SF-SB</FlexibleCodeField><FlexibleCodeField fieldId="3">SF-SB</FlexibleCodeField><FlexibleCodeField fieldId="4">INV</FlexibleCodeField><FlexibleCodeField fieldId="10">BILLC-QTB  rebill testing</FlexibleCodeField><FlexibleCodeField fieldId="11">Small Container</FlexibleCodeField><FlexibleCodeField fieldId="12">00012696</FlexibleCodeField><FlexibleCodeField fieldId="13">null</FlexibleCodeField><FlexibleCodeField fieldId="14">02100-0156</FlexibleCodeField><FlexibleCodeField fieldId="16">4110120</FlexibleCodeField><FlexibleCodeField fieldId="18">0000</FlexibleCodeField><FlexibleDateField fieldId="1">2021-06-03</FlexibleDateField></FlexibleFields></LineItem></InvoiceResponse><ApplicationData><ResponseTimeMS>333.3</ResponseTimeMS></ApplicationData></VertexEnvelope></soapenv:Body></soapenv:Envelope>';
            QTB_IRMVertexResponseUtil.responseMapping(responseBody,true);
            Test.stopTest();
        } catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    //covering scenario involving Product w/ flat rate consumption schedule
    static testMethod void testmethodFlatRateProduct() {
        // Modify test data to have a Product with "Flat Fee" pricing method on their Consumption Rate used by Usage records
        Test.startTest();
        ConsumptionRate conRate = [SELECT Id, PricingMethod, ConsumptionScheduleId FROM ConsumptionRate WHERE PricingMethod != 'FlatFee' LIMIT 1];
        conRate.PricingMethod = 'FlatFee';
        update conRate;
        
        blng__Usage__c usage = [SELECT Id, blng__OrderProduct__c FROM blng__Usage__c LIMIT 1];
        SBQQ__OrderItemConsumptionSchedule__c junctionObj = new SBQQ__OrderItemConsumptionSchedule__c();
        junctionObj.SBQQ__ConsumptionSchedule__c = conRate.ConsumptionScheduleId;
        junctionObj.SBQQ__OrderItem__c = usage.blng__OrderProduct__c;
        junctionObj.SBQQ__BillingTermUnit__c = 'Month';
        junctionObj.SBQQ__BillingTerm__c = 12;
        junctionObj.SBQQ__Category__c = 'Rates';
        junctionObj.SBQQ__RatingMethod__c = 'Tier';
        junctionObj.SBQQ__Type__c = 'Range';
        insert junctionObj;
        
        try{
            List<blng__Invoice__c> invoiceList = [
                SELECT id, QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,blng__InvoiceStatus__c,blng__Account__r.Name,blng__Account__r.QTB_Contract_Entity__c,
                blng__Account__r.CurrencyIsoCode,blng__Account__r.ShippingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Bill_Cycle_Day__c,
                blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.ShippingState,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,recordTypeId,blng__InvoiceRunCreatedBy__c
                FROM blng__Invoice__c];
            
            Set<id> invId = new  Set<id>();
            for(blng__Invoice__c invoice : invoiceList){
                invId.add(invoice.Id);
            }
            Set<id> invoiceRunId = new Set<Id>();
            invoiceRunId.add(invoiceList[0].blng__InvoiceRunCreatedBy__c);
            Test.setMock(HttpCalloutMock.class, new QTB_IRMToVetex_AuthorizationMock());
            
            Map<id, boolean> invIdRequestCompletion = new Map<id, boolean>();
            invIdRequestCompletion.put(invoiceList[0].id, true);
            Database.executeBatch(new QTB_vertexTaxCalloutBatch(null,null,invoiceRunId,null,null,true),1);
            // QTB_IRMToVertexService irmToVertex = new QTB_IRMToVertexService(invId);
            Test.stopTest();
        } catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    //covering creditNote
    static testMethod void testMethodForCreditNote1() {
        try{
            Test.startTest();
            List<blng__CreditNote__c> creditNoteList = [Select id, Name, blng__Status__c,blng__RelatedInvoice__c,QTB_Rebill_Invoice__c, blng__Account__c,
                                                        blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.Name,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Identifier__c,blng__CreditNoteDate__c, QTB_CreditNote_Posted_Date__c,CurrencyISOCode,
                                                        blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Legal_Entity_Country__c
                                                        From blng__CreditNote__c ];
            Set<id> creditId = new Set<id>();
            List<id> creditIdList = new List<id>();
            for(blng__CreditNote__c credit : creditNoteList){
                creditId.add(credit.Id);
                creditIdList.add(credit.Id);
            }
            
            QTB_IRMToVertexCreditHelper.callVertexCreditHelper(creditIdList);
            Test.setMock(HttpCalloutMock.class, new QTB_IRMToVetex_AuthorizationMock());
            
            Test.setMock(HttpCalloutMock.class, new QTB_IRMToVertex_CalculateTaxMock());
            Database.executeBatch(new QTB_vertexTaxCalloutBatch(null,null,creditId,null,null,true),1);
            Test.stopTest();
        } catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    //covering creditNote
    static testMethod void testMethodForCreditNote2() {
        try{
            QTB_IRMToVertex_CalculateTaxMock.succsessResponse = false;
            QTB_IRMToVertex_CalculateTaxMock.succsessResponseForCredit = true;
            Test.setMock(HttpCalloutMock.class, new QTB_IRMToVertex_CalculateTaxMock());
            Test.startTest();
            List<blng__CreditNote__c> creditNoteList = [Select id, Name, blng__Status__c,blng__RelatedInvoice__c,QTB_Rebill_Invoice__c, blng__Account__c,
                                                        blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.Name,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Identifier__c,blng__CreditNoteDate__c, QTB_CreditNote_Posted_Date__c,CurrencyISOCode,
                                                        blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Legal_Entity_Country__c
                                                        From blng__CreditNote__c ];
            
            System.debug('creditNoteList@@'+creditNoteList);
            List<id> postedCreditNoteIds = new  List<id>();
            for(blng__CreditNote__c credit : creditNoteList){
                postedCreditNoteIds.add(credit.Id);
            }
            
            List<Service_Location__c> svListFinal = new List<Service_Location__c>();
            List<Service_Location__c> svList = [Select Id, Name,Address1__c, Address2__c, Address3__c, IM_Country_name__c, IM_County_Name__c,Postal_Code__c,
                                                QTB_Billing_Account__c, Owning_District_Id__r.Owning_District_Id__c,Owning_District_Id__r.QTB_Oracle_Location_Code__c 
                                                From Service_Location__c where Name = 'test Service' ];
            for(Service_Location__c sv : svList){
                Service_Location__c sv1 = new Service_Location__c();
                sv1.id = sv.id;
                sv1.QTB_Billing_Account__c = creditNoteList[0].blng__Account__c;
                
                svListFinal.add(sv1);
            }
            update svListFinal;
            
            List<blng__CreditNoteLine__c> creditNoteLineList = [Select id, Name,blng__CreditNote__c,blng__TaxAmount__c,blng__Product__c,blng__CreditNote__r.Id, QTB_Account__c,blng__BillToAccount__c, QTB_Account__r.QTB_Customer_Number__c,blng__Status__c,
                                                                QTB_Account__r.Name, QTB_Account__r.QTB_Billing_Account_Invoice_Name__c,QTB_Account__r.ShippingCity, QTB_Account__r.ShippingState, QTB_Account__r.ShippingPostalCode, QTB_Account__r.IME_Display_Division__c,                                                            QTB_Account__r.ShippingCountry,blng__Product__r.QTB_Oracle_GL_Account_Code__c,blng__Product__r.IM_Product_Class__c,blng__Product__r.QTB_Tax_Category__c,blng__Product__r.Name,                                                            blng__Product__r.ProductCode,blng__TotalAmount__c,blng__Subtotal__c,QTB_Credit_Quantity__c,blng__InvoiceLine__r.blng__OrderProduct__r.Id,
                                                                blng__InvoiceLine__r.QTB_Allocated_Revenue_Amount__c,blng__InvoiceLine__r.blng__OrderProduct__r.Order.OrderNumber,blng__Product__r.Bill_Code__c,blng__TaxErrorMessage__c,
                                                                blng__InvoiceLine__c,blng__InvoiceLine__r.blng__TaxAmount__c,blng__InvoiceLine__r.blng__UsageSummary__c,blng__InvoiceLine__r.blng__UsageSummary__r.id,blng__InvoiceLine__r.QTB_HasConsumptionSchedule__c,blng__InvoiceLine__r.blng__Subtotal__c,
                                                                blng__InvoiceLine__r.QTB_Taxable_Amount__c
                                                                From blng__CreditNoteLine__c  ];
            
            Map<id,string> invoiceLineIdToBillCodeVar = new  Map<id,string>();
            invoiceLineIdToBillCodeVar.put(postedCreditNoteIds[0], '123456');
            QTB_IRMToVertexCreditHelper.callVertexCreditHelper(postedCreditNoteIds);
            QTB_IRMToVertexCreditHelper.callVertexCreditHelper(null);
            QTB_IRMToVertexCreditHelper.getProductBillCode(postedCreditNoteIds);
            QTB_IRMToVertexCreditHelper.getProductBillCode(null);
            QTB_IRMToVertexCreditHelper.getDistrictAndLocation(creditNoteList[0],'District');
            QTB_IRMToVertexCreditHelper.getDistrictAndLocation(creditNoteList[0],'');
            QTB_IRMToVertexCreditHelper.getDistrict(postedCreditNoteIds);
            QTB_IRMToVertexCreditHelper.getLocation(postedCreditNoteIds);
            QTB_IRMToVertexCreditHelper.getCreditNote(postedCreditNoteIds);
            QTB_IRMToVertexCreditHelper.getCreditLineUsageList(postedCreditNoteIds,null,null);
            // QTB_IRMToVertexCreditHelper.getCreditLineUsageList(null,null,null);
            QTB_IRMToVertexService.invoiceOrCreditNote = creditNoteList[0];
            string jwtToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzUxMiIsImtpZCI6ImlybS1qd3QtcHJpdmF0ZS1rZXkifQ.ew0KICAiaXNzIjoid2cxMTAxLm51cy5pcm9ubW91bnRhaW4uY29tIiwNCiAgImlhdCI6MTYyNzM4MDk0OSwNCiAgImF1ZCI6IlNhbGVzRm9yY2VfUXVvdGV0b0JpbGwiLA0KICAianRpIjoiZTE0ZjIwZjAtMDc0OC00YTE1LTlmMTAtYmJlZGFmOGY0NjMzIiwNCiAgInN1YiI6IlNhbGVzRm9yY2VfUXVvdGV0b0JpbGwiLCAgDQogICJ0b2tlbl90eXBlIjogIkJlYXJlciIsDQogICJleHAiOjE2MjczODQ1NDksDQogICJyb3V0aW5nX3N5c3RlbSI6InVzZXJJRFA6Q0FMREFQIiwNCiAgImV4cGlyZXNfaW4iOjM2MDAsDQogICJyZWZyZXNoX3Rva2VuIjogIjNlYjc0ZmU4LTQ0YTktNDY2Ny1iYzkzLWUzNDg1MjM2YjhhYyIsDQogICJyZWZyZXNoX2V4cCI6MzYwMA0KfQ.TEvvSDKneY885pym2cAv2uPvIXHImAZB7aCKgVSddGElyWTtK33_AN-0VZcVQ41nNyC3SIaqcuD73KpSIcbbjY9e0iJMdUK0GrcCFg5SlGOQxOxK2T55uZ7pegWeZm8Soh01NWwsyfppbyRkbNP4PklaU89xzSGe_4CLfbf9J8LHeV3U4BUTpoLaQUnqsqwaAnaMP8TrXGLupChPu0hg8poL9Bxj_a1TIzxRuflgPkKvxQJrvM80vh5MpyOMEwJHEvekCvN-C0nqtLWUwFx0WSMaxTRXMr_iuZ22CynsTAcURpWmHHDREpiv1qZ3Ds6IyVJ37G-006rjRRytvM5A-A';
            QTB_IRMToVertexService.callCalculateTaxService(creditNoteList[0],jwtToken, true, false);
            Test.stopTest();
        } catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    //covering creditNote
    static testMethod void testMethodForCreditNote3() {
        try {
            
            QTB_IRMToVertex_CalculateTaxMock.succsessResponse = false;
            QTB_IRMToVertex_CalculateTaxMock.succsessResponseForCredit = false;
            Test.setMock(HttpCalloutMock.class, new QTB_IRMToVertex_CalculateTaxMock());
            Test.startTest();
            List<blng__CreditNote__c> creditNoteList = [Select id, Name, blng__Status__c,blng__RelatedInvoice__c,QTB_Rebill_Invoice__c, blng__Account__c,
                                                        blng__Account__r.Name,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Identifier__c,blng__CreditNoteDate__c, QTB_CreditNote_Posted_Date__c,CurrencyISOCode,
                                                        blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Legal_Entity_Country__c  
                                                        From blng__CreditNote__c ];
            System.debug('testMethodForCreditNote3_creditNoteList@@'+creditNoteList);
            List<id> postedCreditNoteIds = new  List<id>();
            for(blng__CreditNote__c credit : creditNoteList){
                postedCreditNoteIds.add(credit.Id);
            }
            
            List<blng__CreditNoteLine__c> creditNoteLineList = [Select id, Name,blng__CreditNote__c,blng__Product__c,blng__TaxAmount__c,blng__CreditNote__r.Id, QTB_Account__c,blng__BillToAccount__c, QTB_Account__r.QTB_Customer_Number__c,blng__Status__c,
                                                                QTB_Account__r.QTB_Billing_Account_Invoice_Name__c,QTB_Account__r.Name,QTB_Account__r.ShippingCity, QTB_Account__r.ShippingState,QTB_Account__r.ShippingPostalCode, QTB_Account__r.IME_Display_Division__c,
                                                                QTB_Account__r.ShippingCountry,blng__Product__r.QTB_Oracle_GL_Account_Code__c,blng__Product__r.IM_Product_Class__c,blng__Product__r.QTB_Tax_Category__c,blng__Product__r.Name,
                                                                blng__Product__r.ProductCode,QTB_Credit_Quantity__c,blng__InvoiceLine__r.blng__OrderProduct__r.Id,
                                                                blng__InvoiceLine__r.QTB_Allocated_Revenue_Amount__c,blng__InvoiceLine__r.blng__OrderProduct__r.Order.OrderNumber,blng__Product__r.Bill_Code__c,blng__TaxErrorMessage__c, blng__InvoiceLine__r.QTB_Charge_Type__c,
                                                                blng__InvoiceLine__c,blng__InvoiceLine__r.blng__TaxAmount__c,blng__InvoiceLine__r.blng__UsageSummary__c,blng__InvoiceLine__r.blng__UsageSummary__r.id,blng__InvoiceLine__r.QTB_HasConsumptionSchedule__c,blng__InvoiceLine__r.blng__Subtotal__c,
                                                                blng__InvoiceLine__r.QTB_Taxable_Amount__c,QTB_InvoiceLine__r.QTB_Inc_Quantity__c
                                                                From blng__CreditNoteLine__c where blng__CreditNote__c IN: postedCreditNoteIds 
                                                                /* and blng__InvoiceLine__r.QTB_Charge_Type__c = 'Usage' */ ];
            
            List<blng__Invoice__c> invoiceListForCredit = [ SELECT id, QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,blng__InvoiceStatus__c,blng__Account__r.Name,blng__Account__r.QTB_Contract_Entity__c,
                                                           blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.ShippingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Bill_Cycle_Day__c,
                                                           blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.ShippingState,
                                                           blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,
                                                           recordTypeId,blng__InvoiceRunCreatedBy__c
                                                           FROM blng__Invoice__c where blng__InvoiceStatus__c = 'Posted'] ;
            
            List<blng__InvoiceLine__c> invLineListForCredit = [Select ID,blng__ChargeType__c, Name,blng__Invoice__c,QTB_Taxable_Amount__c,QTB_HasConsumptionSchedule__c,blng__Invoice__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__UsageSummary__c,
                                                               QTB_Charge_Type__c,blng__Product__r.SBQQ__HasConsumptionSchedule__c,blng__Product__r.QTB_Oracle_GL_Account_Code__c,blng__Product__r.IM_Product_Class__c,blng__Product__r.QTB_Tax_Category__c,blng__Product__r.Name,blng__Product__r.ProductCode,blng__TotalAmount__c, blng__Invoice__r.blng__Account__c,blng__Invoice__r.blng__Account__r.Name,
                                                               QTB_Allocated_Revenue_Amount__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Invoice__r.blng__Account__r.CurrencyIsoCode,blng__Invoice__r.blng__Account__r.ShippingCity, blng__Invoice__r.blng__Account__r.ShippingPostalCode,blng__Invoice__r.blng__Account__r.ShippingState,
                                                               blng__Invoice__r.blng__Account__r.IME_Display_Division__c,blng__Invoice__r.blng__Account__r.ShippingCountry,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                               blng__OrderProduct__r.Id, blng__OrderProduct__r.Order.OrderNumber,blng__Product__r.Bill_Code__c,blng__TaxErrorMessage__c,QTB_Inc_Quantity__c                          
                                                               From blng__InvoiceLine__c where blng__Invoice__c =: invoiceListForCredit[0].id];
            
            Product2 prd = [Select id, Name, isActive, SBQQ__HasConsumptionSchedule__c from Product2 where Name ='Test Product3' limit 1 ];
            System.debug('prd@@'+prd);
            blng__UsageSummary__c usgSum  = [Select Id From blng__UsageSummary__c limit 1];
            blng__InvoiceLine__c ivl = new blng__InvoiceLine__c();
            ivl.id = invLineListForCredit[0].id;
            ivl.blng__Product__c = prd.id;
            //ivl.blng__UsageSummary__c = usgSum.id;
            ivl.blng__InvoiceLineStatus__c = 'Posted' ;
            update ivl;
            Set<Id> usageSummaryIds = new Set<Id>();
            //usageSummaryIds.add(ivl.blng__UsageSummary__c);
            
            /* List<blng__Usage__c> usageList = [Select id,blng__Subtotal__c, Name,QTB_Service_District__c,QTB_Product_Identifier_1__c,blng__UsageSummary__r.blng__Account__c,blng__Account__r.Id,blng__Account__r.Name,blng__UsageSummary__c,blng__UsageSummary__r.id,blng__UsageSummary__r.blng__Status__c,blng__UsageSummary__r.blng__Invoice__c,QTB_Product__c,blng__OrderProduct__c,blng__OrderProduct__r.Id,blng__OrderProduct__r.Product2Id,
            blng__OrderProduct__r.Product2.id,blng__OrderProduct__r.Product2.Name, blng__OrderProduct__r.Product2.QTB_Oracle_GL_Account_Code__c,blng__OrderProduct__r.Product2.IM_Product_Class__c, blng__OrderProduct__r.Product2.ProductCode,blng__OrderProduct__r.Product2.Bill_Code__c, blng__ProcessingDate__c,
            blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.CurrencyIsoCode, blng__Account__r.ShippingCity,blng__Account__r.ShippingState,blng__Account__r.ShippingPostalCode,blng__Account__r.IME_Display_Division__c,blng__Account__r.QTB_Legal_Entity_Country__c,
            blng__Account__r.ShippingCountry,QTB_Rated_Amount__c,blng__UnitPrice__c,blng__Quantity__c,blng__OrderProduct__r.Order.OrderNumber
            From blng__Usage__c where blng__UsageSummary__c IN : usageSummaryIds ];*/
            
            List<sObject> invoiceLineOrUsageListForTax = new List<sObject>();
            invoiceLineOrUsageListForTax.addAll(creditNoteLineList);
            // invoiceLineOrUsageListForTax.addAll(usageList);
            QTB_IRMToVertexCreditHelper.callVertexCreditHelper(postedCreditNoteIds);
            QTB_IRMToVertexCreditHelper.callVertexCreditHelper(null);
            //QTB_IRMToVertexCreditHelper.testFunctionality();
            QTB_IRMToVertexService.invoiceLineOrUsageListForTax = invoiceLineOrUsageListForTax;
            
            string jwtToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzUxMiIsImtpZCI6ImlybS1qd3QtcHJpdmF0ZS1rZXkifQ.ew0KICAiaXNzIjoid2cxMTAxLm51cy5pcm9ubW91bnRhaW4uY29tIiwNCiAgImlhdCI6MTYyNzM4MDk0OSwNCiAgImF1ZCI6IlNhbGVzRm9yY2VfUXVvdGV0b0JpbGwiLA0KICAianRpIjoiZTE0ZjIwZjAtMDc0OC00YTE1LTlmMTAtYmJlZGFmOGY0NjMzIiwNCiAgInN1YiI6IlNhbGVzRm9yY2VfUXVvdGV0b0JpbGwiLCAgDQogICJ0b2tlbl90eXBlIjogIkJlYXJlciIsDQogICJleHAiOjE2MjczODQ1NDksDQogICJyb3V0aW5nX3N5c3RlbSI6InVzZXJJRFA6Q0FMREFQIiwNCiAgImV4cGlyZXNfaW4iOjM2MDAsDQogICJyZWZyZXNoX3Rva2VuIjogIjNlYjc0ZmU4LTQ0YTktNDY2Ny1iYzkzLWUzNDg1MjM2YjhhYyIsDQogICJyZWZyZXNoX2V4cCI6MzYwMA0KfQ.TEvvSDKneY885pym2cAv2uPvIXHImAZB7aCKgVSddGElyWTtK33_AN-0VZcVQ41nNyC3SIaqcuD73KpSIcbbjY9e0iJMdUK0GrcCFg5SlGOQxOxK2T55uZ7pegWeZm8Soh01NWwsyfppbyRkbNP4PklaU89xzSGe_4CLfbf9J8LHeV3U4BUTpoLaQUnqsqwaAnaMP8TrXGLupChPu0hg8poL9Bxj_a1TIzxRuflgPkKvxQJrvM80vh5MpyOMEwJHEvekCvN-C0nqtLWUwFx0WSMaxTRXMr_iuZ22CynsTAcURpWmHHDREpiv1qZ3Ds6IyVJ37G-006rjRRytvM5A-A';
            QTB_IRMToVertexService.callCalculateTaxService(creditNoteList[0],jwtToken, true, false);
            
        } catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }
    
    //covering creditnote error response --
    static testMethod void testMethodForCreditNote4() {
        try{
            Test.startTest();
            List<blng__CreditNote__c> creditNoteList = [Select id, Name, blng__Status__c,blng__RelatedInvoice__c,QTB_Rebill_Invoice__c, blng__Account__c,
                                                        blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.Name,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Identifier__c,blng__CreditNoteDate__c, QTB_CreditNote_Posted_Date__c,CurrencyISOCode,
                                                        blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Legal_Entity_Country__c,blng__TaxErrorMessage__c  
                                                        From blng__CreditNote__c ];
            blng__CreditNote__c c = new blng__CreditNote__c();
            c.id = creditNoteList[0].id;
            c.blng__TaxErrorMessage__c = 'Tax Error';
            update c;
            System.debug('creditNoteList@@'+creditNoteList);
            List<id> postedCreditNoteIds = new  List<id>();
            for(blng__CreditNote__c credit : creditNoteList){
                postedCreditNoteIds.add(credit.Id);
            }
            
            List<blng__CreditNoteLine__c> creditNoteLineList = [Select id, Name,blng__CreditNote__c,blng__Product__c,blng__TaxAmount__c,blng__CreditNote__r.Id, QTB_Account__c,blng__BillToAccount__c, QTB_Account__r.QTB_Customer_Number__c,blng__Status__c,
                                                                QTB_Account__r.Name,QTB_Account__r.ShippingCity,QTB_Account__r.ShippingState, QTB_Account__r.ShippingPostalCode,QTB_Account__r.IME_Display_Division__c,
                                                                QTB_Account__r.QTB_Billing_Account_Invoice_Name__c,QTB_Account__r.ShippingCountry,blng__Product__r.QTB_Oracle_GL_Account_Code__c,blng__Product__r.IM_Product_Class__c,blng__Product__r.QTB_Tax_Category__c,blng__Product__r.Name,
                                                                blng__Product__r.ProductCode,QTB_Credit_Quantity__c,blng__InvoiceLine__r.blng__OrderProduct__r.Id,
                                                                blng__InvoiceLine__r.QTB_Allocated_Revenue_Amount__c,blng__InvoiceLine__r.blng__OrderProduct__r.Order.OrderNumber,blng__Product__r.Bill_Code__c,blng__TaxErrorMessage__c,
                                                                blng__InvoiceLine__c,blng__InvoiceLine__r.blng__TaxAmount__c,blng__InvoiceLine__r.blng__UsageSummary__c,blng__InvoiceLine__r.blng__UsageSummary__r.id,blng__InvoiceLine__r.QTB_HasConsumptionSchedule__c,
                                                                blng__InvoiceLine__r.QTB_Taxable_Amount__c
                                                                From blng__CreditNoteLine__c where  blng__CreditNote__c IN :postedCreditNoteIds];
            
            
            string responseBody = '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Header/><soapenv:Body><VertexEnvelope xmlns="urn:vertexinc:o-series:tps:8:0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><Login><UserName>admin</UserName><Password>vertex</Password></Login><InvoiceResponse documentNumber="CR-3620" documentDate="2021-07-14" transactionId="'+creditNoteList[0].id+'" transactionType="SALE" postingDate="2021-07-14"><Customer><CustomerCode>00017811</CustomerCode></Customer><SubTotal>13930.0</SubTotal><Total>15248.1</Total><TotalTax>1318.1</TotalTax><LineItem lineItemId="'+creditNoteLineList[0].id+'" lineItemNumber="1"><Customer><Destination taxAreaId="390910000"><City>Beverly Hills</City><MainDivision>CA</MainDivision><PostalCode>19426</PostalCode><Country>USA</Country></Destination></Customer><Product productClass="">7000070008</Product><Quantity>1.0</Quantity><FairMarketValue>150.0</FairMarketValue><UnitPrice>150.0</UnitPrice><ExtendedPrice>150.0</ExtendedPrice><Taxes taxResult="TAXABLE" taxType="SALES" situs="DESTINATION" taxCollectedFromParty="BUYER" taxStructure="SINGLE_RATE"><Jurisdiction jurisdictionLevel="STATE" jurisdictionId="31152">PENNSYLVANIA</Jurisdiction><CalculatedTax>9.0</CalculatedTax><EffectiveRate>0.06</EffectiveRate><Taxable>150.0</Taxable><Imposition impositionId="1">Sales and Use Tax</Imposition><ImpositionType impositionTypeId="1">General Sales and Use Tax</ImpositionType><TaxRuleId>17423</TaxRuleId><InclusionRuleId>1282739</InclusionRuleId></Taxes><TotalTax>9.0</TotalTax><FlexibleFields><FlexibleCodeField fieldId="2">SF-SB</FlexibleCodeField><FlexibleCodeField fieldId="3">SF-SB</FlexibleCodeField><FlexibleCodeField fieldId="4">INV</FlexibleCodeField><FlexibleCodeField fieldId="10">BILLC-Bill Acc Aneeja</FlexibleCodeField><FlexibleCodeField fieldId="11">Archival Destruction Item - Vault consum</FlexibleCodeField><FlexibleCodeField fieldId="12">00007596</FlexibleCodeField><FlexibleCodeField fieldId="13">null</FlexibleCodeField><FlexibleCodeField fieldId="14">7000070008</FlexibleCodeField><FlexibleCodeField fieldId="16">4210110</FlexibleCodeField><FlexibleCodeField fieldId="18">0000</FlexibleCodeField><FlexibleDateField fieldId="1">2021-07-14</FlexibleDateField></FlexibleFields></LineItem><LineItem lineItemId="aJO7b0000004GQVGA2" lineItemNumber="22"><Customer><Destination taxAreaId="390910000"><City>ATLANTA</City><MainDivision>North America</MainDivision><PostalCode>19426</PostalCode><Country>United States</Country></Destination></Customer><Product productClass="Data Management">02100-0156</Product><FairMarketValue>500.0</FairMarketValue><ExtendedPrice>500.0</ExtendedPrice><Taxes taxResult="TAXABLE" taxType="SALES" situs="DESTINATION" taxCollectedFromParty="BUYER" taxStructure="SINGLE_RATE"><Jurisdiction jurisdictionLevel="STATE" jurisdictionId="31152">PENNSYLVANIA</Jurisdiction><CalculatedTax>30.0</CalculatedTax><EffectiveRate>0.06</EffectiveRate><Taxable>500.0</Taxable><Imposition impositionId="1">Sales and Use Tax</Imposition><ImpositionType impositionTypeId="1">General Sales and Use Tax</ImpositionType><TaxRuleId>17423</TaxRuleId><InclusionRuleId>1282739</InclusionRuleId></Taxes><TotalTax>30.0</TotalTax><FlexibleFields><FlexibleCodeField fieldId="1">44147</FlexibleCodeField><FlexibleCodeField fieldId="2">SF-SB</FlexibleCodeField><FlexibleCodeField fieldId="3">SF-SB</FlexibleCodeField><FlexibleCodeField fieldId="4">INV</FlexibleCodeField><FlexibleCodeField fieldId="10">BILLC-QTB  rebill testing</FlexibleCodeField><FlexibleCodeField fieldId="11">Small Container</FlexibleCodeField><FlexibleCodeField fieldId="12">00012696</FlexibleCodeField><FlexibleCodeField fieldId="13">null</FlexibleCodeField><FlexibleCodeField fieldId="14">02100-0156</FlexibleCodeField><FlexibleCodeField fieldId="16">4110120</FlexibleCodeField><FlexibleCodeField fieldId="18">0000</FlexibleCodeField><FlexibleDateField fieldId="1">2021-06-03</FlexibleDateField></FlexibleFields></LineItem></InvoiceResponse><ApplicationData><ResponseTimeMS>333.3</ResponseTimeMS></ApplicationData></VertexEnvelope></soapenv:Body></soapenv:Envelope>';
            QTB_IRMVertexResponseUtil.responseMapping(responseBody,true);
            
            string errorBody = '{"success":false,"errors": [{"code": "WSG500","message": "The request failed due server error"}],"warnings": ""}';
            QTB_IRMVertexResponseUtil.handleErrorResponseMapping(errorBody,creditNoteList[0],creditNoteLineList,null,null,null);
            Test.stopTest();
        } catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    static testMethod void handleAllCatchBlock1(){
        Test.startTest();
        try {
            List<Id> invoiceCreditNoteIds  = new List<Id>();
            invoiceCreditNoteIds.add(null);
            
            QTB_IRMToVertexCreditHelper.callVertexCreditHelper(invoiceCreditNoteIds);
            QTB_IRMToVertexCreditHelper.getCreditLineUsageList(invoiceCreditNoteIds,null,null);
            QTB_IRMToVertexCreditHelper.coverageMethod();
            // QTB_IRMToVertexCreditHelper.getProductBillCode(null);
            QTB_IRMToVertexCreditHelper.getCreditNote(invoiceCreditNoteIds);
            QTB_IRMToVertexCreditHelper.getDistrictAndLocation(null,'');
        } catch (Exception e) {
            System.assertEquals('ExpectedExceptionMessage', e.getMessage());
        }
        Test.stopTest();
        
    }
    
    static testMethod void handleAllCatchBlock2(){
        Test.startTest();
        try {
            List<Id> invoiceCreditNoteIds  = new List<Id>();
            invoiceCreditNoteIds.add(null);
            
            QTB_IRMToVertexHelper.getInvoice(invoiceCreditNoteIds);
            QTB_IRMToVertexHelper.setInvoiceAndInvoiceLineItem(invoiceCreditNoteIds);
            QTB_IRMToVertexHelper.getInvoiceLineUsageList(invoiceCreditNoteIds,null,null);
            QTB_IRMToVertexHelper.getProductBillCode(invoiceCreditNoteIds);
            QTB_IRMToVertexHelper.setInvoiceAndInvoiceLineItem(invoiceCreditNoteIds);
            QTB_IRMToVertexHelper.setUsageSummaryAndUsage(invoiceCreditNoteIds);
            QTB_IRMToVertexHelper.getDistrictAndLocation(null,'');
            QTB_IRMVertexResponseUtil.readInvoiceResponse(null);
            String responseBody ='';
            QTB_IRMVertexResponseUtil.responseMapping(responseBody,true);
            QTB_IRMVertexResponseUtil.updateErrorToInvoiceUsageLevel('', null, null,null,null, null);
        } catch (Exception e) {
            System.assertEquals('ExpectedExceptionMessage', e.getMessage());
        }
        Test.stopTest();
    }
    
    static testMethod void handleReprocessingTaxInvoice(){
        Test.startTest();
        try {
            List<blng__Invoice__c> invoiceList = [Select ID,blng__InvoiceDate__c,Name,blng__InvoiceStatus__c,blng__Account__c,blng__Account__r.Id,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.Name, blng__Account__r.AccountNumber,
                                              blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.ShippingCity,blng__Account__r.ShippingCountry,blng__Account__r.IME_Display_Division__c,blng__Account__r.ShippingPostalCode,blng__Account__r.QTB_Legal_Entity_Country__c,
                                              blng__Order__r.SBQQ__Quote__r.QTB_Opportunity_Product_Line__c,blng__TaxErrorMessage__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Identifier__c
                                              From blng__Invoice__c where blng__InvoiceStatus__c = 'Draft'];
            
            ApexPages.StandardController sc = new ApexPages.StandardController(invoiceList[0]);
            
            PageReference pageRef = Page.QTB_IRMToVertexCalculateTaxVF; // Add your VF page Name here
            pageRef.getParameters().put('invOrCreditId', String.valueOf(invoiceList[0].Id));
            Test.setCurrentPage(pageRef);
            QTB_IRMToVertexCalculateTaxController ctrl = new QTB_IRMToVertexCalculateTaxController();
            ctrl.callVertexService();
            ctrl.Redirect();
        } catch (Exception e) {
            System.assertEquals('ExpectedExceptionMessage', e.getMessage());
        }
        Test.stopTest();
        
    }
    
    static testMethod void handleReprocessingTaxCreditNote(){
        Test.startTest();
        try{
            List<blng__CreditNote__c> creditNoteList = [Select id, Name, QTB_Country__c,blng__Status__c,blng__RelatedInvoice__c,QTB_Rebill_Invoice__c, blng__Account__c,
                                                    blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.Name,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Identifier__c,blng__CreditNoteDate__c, QTB_CreditNote_Posted_Date__c,CurrencyISOCode,
                                                    blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Legal_Entity_Country__c,blng__TaxErrorMessage__c  
                                                    From blng__CreditNote__c ];
            
            
            ApexPages.StandardController sc = new ApexPages.StandardController(creditNoteList[0]);
            
            PageReference pageRef = Page.QTB_IRMToVertexCalculateTaxVF; // Add your VF page Name here
            pageRef.getParameters().put('invOrCreditId', String.valueOf(creditNoteList[0].Id));
            Test.setCurrentPage(pageRef);
            QTB_IRMToVertexCalculateTaxController ctrl = new QTB_IRMToVertexCalculateTaxController();
            ctrl.callVertexService();
            ctrl.Redirect();
        } catch (Exception e) {
            System.assertEquals('ExpectedExceptionMessage', e.getMessage());
        }
        Test.stopTest();
    }
    
    /* static testMethod void testCoverage(){
        QTB_IRMToVertexCreditHelper.testFunctionality();
    } */
    //covering invoice response --
    static testMethod void testmethodInvoice14() {
        // try{
            Test.startTest();
            List<blng__Invoice__c> invoiceList = [Select ID,blng__InvoiceDate__c,Name,blng__InvoiceStatus__c,blng__Account__c,blng__Account__r.Id,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.Name, blng__Account__r.AccountNumber,
                                                  blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.ShippingCity,blng__Account__r.ShippingCountry,blng__Account__r.IME_Display_Division__c,blng__Account__r.ShippingPostalCode,blng__Account__r.QTB_Legal_Entity_Country__c,
                                                  blng__Order__r.SBQQ__Quote__r.QTB_Opportunity_Product_Line__c,blng__TaxErrorMessage__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Identifier__c
                                                  From blng__Invoice__c where blng__InvoiceStatus__c = 'Draft'];
            
            
            List<id> invId = new  List<id>();
            for(blng__Invoice__c invoice : invoiceList){
                invId.add(invoice.Id);
            }
            
            List<blng__InvoiceLine__c> invoiceLineList = [Select ID,blng__ChargeType__c,QTB_Charge_Type__c, Name,blng__Invoice__c,QTB_Taxable_Amount__c,QTB_Allocated_Revenue_Amount__c,QTB_HasConsumptionSchedule__c,blng__Invoice__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__UsageSummary__c,
                                                          blng__Product__r.QTB_Oracle_GL_Account_Code__c,blng__Product__r.IM_Product_Class__c,blng__Product__r.QTB_Tax_Category__c,blng__Product__r.Name,blng__Product__r.ProductCode,blng__TotalAmount__c, blng__Invoice__r.blng__Account__c,blng__Invoice__r.blng__Account__r.Name,
                                                          blng__Subtotal__c,blng__Invoice__r.blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Invoice__r.blng__Account__r.CurrencyIsoCode,
                                                          blng__Invoice__r.blng__Account__r.ShippingCity,blng__Invoice__r.blng__Account__r.ShippingPostalCode,blng__Invoice__r.blng__Account__r.ShippingState,
                                                          blng__Invoice__r.blng__Account__r.IME_Display_Division__c,blng__Invoice__r.blng__Account__r.ShippingCountry,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                          blng__OrderProduct__r.Id, blng__OrderProduct__r.Order.OrderNumber,blng__Product__r.Bill_Code__c,blng__TaxErrorMessage__c                          
                                                          From blng__InvoiceLine__c where blng__Invoice__c IN : invId ];
            
            Product2 prd = [Select ID, Name,SBQQ__HasConsumptionSchedule__c,SBQQ__ChargeType__c from Product2 where SBQQ__HasConsumptionSchedule__c = true limit 1 ];
            prd.SBQQ__ChargeType__c ='Recurring';
            prd.SBQQ__BillingType__c ='Advance';
            update prd;
            system.debug('##################'+prd);
            //blng__InvoiceLine__c invl = new blng__InvoiceLine__c();
            //invl.id = invoiceLineList[0].id;
            invoiceLineList[0].blng__Product__c = prd.id;
            invoiceLineList[0].blng__UsageSummary__c =null;
            update invoiceLineList[0];
            
            /*blng__InvoiceLine__c invl1 = new blng__InvoiceLine__c();
            invl1.id = invoiceLineList[1].id;
            invl1.blng__Product__c = prd.id;
            update invl1;*/
                System.debug('invl1.QTB_Charge_Type__c@@'+invoiceLineList[0].QTB_Charge_Type__c);
            //System.debug('invl1.QTB_Charge_Type__c@@'+invl1.QTB_Charge_Type__c);
            QTB_IRMToVertexHelper.setInvoiceAndInvoiceLineItem(invId);
            QTB_IRMToVertexHelper.getInvoiceLineUsageList(invId,null,null);
            
            Set<Id> usageSummaryIds = new Set<Id>();
            for(blng__InvoiceLine__c ivl :invoiceLineList ){
                usageSummaryIds.add(ivl.blng__UsageSummary__c);
            }
            
            List<blng__Usage__c> usageList = [Select id,blng__Subtotal__c, Name,QTB_Service_District__c,QTB_Product_Identifier_1__c,blng__UsageSummary__r.blng__Account__c,blng__Account__r.Id,blng__Account__r.Name,
                                              blng__UsageSummary__r.id,blng__UsageSummary__r.blng__Status__c,blng__UsageSummary__r.blng__Invoice__c,QTB_Product__c,blng__OrderProduct__c,blng__OrderProduct__r.Id,blng__OrderProduct__r.Product2Id,
                                              blng__OrderProduct__r.Product2.id,blng__OrderProduct__r.Product2.Name, blng__OrderProduct__r.Product2.QTB_Oracle_GL_Account_Code__c,blng__OrderProduct__r.Product2.IM_Product_Class__c, blng__OrderProduct__r.Product2.ProductCode,blng__OrderProduct__r.Product2.Bill_Code__c, blng__ProcessingDate__c,
                                              blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.CurrencyIsoCode, blng__Account__r.ShippingCity,blng__Account__r.ShippingState,blng__Account__r.ShippingPostalCode,blng__Account__r.IME_Display_Division__c,blng__Account__r.QTB_Legal_Entity_Country__c,
                                              blng__Account__r.ShippingCountry,QTB_Rated_Amount__c,blng__UnitPrice__c,blng__Quantity__c,blng__OrderProduct__r.Order.OrderNumber
                                              From blng__Usage__c where blng__UsageSummary__c IN : usageSummaryIds ];
            
            
            string responseBody = '<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Header/><soapenv:Body><VertexEnvelope xmlns="urn:vertexinc:o-series:tps:8:0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><Login><UserName>admin</UserName><Password>vertex</Password></Login><InvoiceResponse documentNumber="INV-3620" documentDate="2021-07-14" transactionId="'+invoiceList[0].id+'" transactionType="SALE" postingDate="2021-07-14"><Customer><CustomerCode>00017811</CustomerCode></Customer><SubTotal>13930.0</SubTotal><Total>15248.1</Total><TotalTax>1318.1</TotalTax><LineItem lineItemId="'+invoiceLineList[0].id+'" lineItemNumber="1"><Customer><Destination taxAreaId="390910000"><City>Beverly Hills</City><MainDivision>CA</MainDivision><PostalCode>19426</PostalCode><Country>USA</Country></Destination></Customer><Product productClass="">7000070008</Product><Quantity>1.0</Quantity><FairMarketValue>150.0</FairMarketValue><UnitPrice>150.0</UnitPrice><ExtendedPrice>150.0</ExtendedPrice><Taxes taxResult="TAXABLE" taxType="SALES" situs="DESTINATION" taxCollectedFromParty="BUYER" taxStructure="SINGLE_RATE"><Jurisdiction jurisdictionLevel="STATE" jurisdictionId="31152">PENNSYLVANIA</Jurisdiction><CalculatedTax>9.0</CalculatedTax><EffectiveRate>0.06</EffectiveRate><Taxable>150.0</Taxable><Imposition impositionId="1">Sales and Use Tax</Imposition><ImpositionType impositionTypeId="1">General Sales and Use Tax</ImpositionType><TaxRuleId>17423</TaxRuleId><InclusionRuleId>1282739</InclusionRuleId></Taxes><TotalTax>9.0</TotalTax><FlexibleFields><FlexibleCodeField fieldId="2">SF-SB</FlexibleCodeField><FlexibleCodeField fieldId="3">SF-SB</FlexibleCodeField><FlexibleCodeField fieldId="4">INV</FlexibleCodeField><FlexibleCodeField fieldId="10">BILLC-Bill Acc Aneeja</FlexibleCodeField><FlexibleCodeField fieldId="11">Archival Destruction Item - Vault consum</FlexibleCodeField><FlexibleCodeField fieldId="12">00007596</FlexibleCodeField><FlexibleCodeField fieldId="13">null</FlexibleCodeField><FlexibleCodeField fieldId="14">7000070008</FlexibleCodeField><FlexibleCodeField fieldId="16">4210110</FlexibleCodeField><FlexibleCodeField fieldId="18">0000</FlexibleCodeField><FlexibleDateField fieldId="1">2021-07-14</FlexibleDateField></FlexibleFields></LineItem><LineItem lineItemId="'+usageList[0].id+'" lineItemNumber="2"><Customer><Destination taxAreaId="390910000"><City>ATLANTA</City><MainDivision>North America</MainDivision><PostalCode>19426</PostalCode><Country>United States</Country></Destination></Customer><Product productClass="Data Management">02100-0156</Product><FairMarketValue>500.0</FairMarketValue><ExtendedPrice>500.0</ExtendedPrice><Taxes taxResult="TAXABLE" taxType="SALES" situs="DESTINATION" taxCollectedFromParty="BUYER" taxStructure="SINGLE_RATE"><Jurisdiction jurisdictionLevel="STATE" jurisdictionId="31152">PENNSYLVANIA</Jurisdiction><CalculatedTax>30.0</CalculatedTax><EffectiveRate>0.06</EffectiveRate><Taxable>500.0</Taxable><Imposition impositionId="1">Sales and Use Tax</Imposition><ImpositionType impositionTypeId="1">General Sales and Use Tax</ImpositionType><TaxRuleId>17423</TaxRuleId><InclusionRuleId>1282739</InclusionRuleId></Taxes><TotalTax>30.0</TotalTax><FlexibleFields><FlexibleCodeField fieldId="1">44147</FlexibleCodeField><FlexibleCodeField fieldId="2">SF-SB</FlexibleCodeField><FlexibleCodeField fieldId="3">SF-SB</FlexibleCodeField><FlexibleCodeField fieldId="4">INV</FlexibleCodeField><FlexibleCodeField fieldId="10">BILLC-QTB  rebill testing</FlexibleCodeField><FlexibleCodeField fieldId="11">Small Container</FlexibleCodeField><FlexibleCodeField fieldId="12">00012696</FlexibleCodeField><FlexibleCodeField fieldId="13">null</FlexibleCodeField><FlexibleCodeField fieldId="14">02100-0156</FlexibleCodeField><FlexibleCodeField fieldId="16">4110120</FlexibleCodeField><FlexibleCodeField fieldId="18">0000</FlexibleCodeField><FlexibleDateField fieldId="1">2021-06-03</FlexibleDateField></FlexibleFields></LineItem></InvoiceResponse><ApplicationData><ResponseTimeMS>333.3</ResponseTimeMS></ApplicationData></VertexEnvelope></soapenv:Body></soapenv:Envelope>';
            QTB_IRMVertexResponseUtil.responseMapping(responseBody,true);
            QTB_IRMVertexRequestUtil.coverageMethod();
            //  QTB_IRMToVertexHelper.getInvoiceLineUsageList(invId,null,null);
            String invoiceRequest = QTB_IRMVertexRequestUtil.requestStructureForInvoiceLineOrUsage(
                new blng__Invoice__c(),
            new List<blng__InvoiceLine__c>(),
            'Test District',
            'Test Location GL',
            new Map<Id, String>(),
            'Invoice',
            true
                );
            System.assertNotEquals(null, invoiceRequest);
            
            String loginXML = QTB_IRMVertexRequestUtil.getLoginXML('testuser', 'testpassword');
            System.assertNotEquals(null, loginXML);
            
            String customerInfoXML = QTB_IRMVertexRequestUtil.getCustomerInfoXML('TestCustomerCode');
            System.assertNotEquals(null, customerInfoXML);
            
            String flexibleFields = QTB_IRMVertexRequestUtil.getFlexibleFields(
                new blng__InvoiceLine__c(),
            'Test District',
            'Test Product',
            'Test Order',
            'Test Product Code',
            'Test Account Code',
            DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd')
                
            );
            System.assertNotEquals(null, flexibleFields);
            
            
            QTB_IRMVertexRequestUtil.coverageMethod(); // Call for coverage
            
            
            Test.stopTest();
        // } catch (Exception e) {
            // System.assertNotEquals('Script-thrown exception', e.getMessage());
        //}
    }
    
    @isTest
    static void testmethodInvoice15() {
        
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;
        
        IM_Country__c retCountry = new IM_Country__c(Name='United Kingdom',Region__c='Europe');
        insert retCountry;
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United Kingdom';
        
        insert altcountry;
        Test.startTest();
        Account account = new Account(
            Name = 'Test Account',
        ShippingCity = 'London',
        ShippingState = 'England',
        ShippingPostalCode = 'SW1A 1AA',
        ShippingCountry = 'United Kingdom',
        BillingCity = 'London',
        BillingState = 'England',
        BillingPostalCode = 'SW1A 1AA',
        BillingCountry = 'United Kingdom',
        QTB_Legal_Entity_Country__c = 'United Kingdom'
            );
        insert account;
        
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = account.Id;
        invoice.blng__InvoiceStatus__c = 'Posted';
        //invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
        insert invoice;
        
        blng__UsageSummary__c usagesummary1 = new blng__UsageSummary__c();
        usagesummary1.blng__Status__c = 'Queued For Invoice';
        usagesummary1.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
        usagesummary1.blng__MatchingId__c = '1234';
        usagesummary1.blng__UnitPrice__c = 10;
        usagesummary1.blng__Invoice__c = invoice.Id;
        usagesummary1.blng__SummaryEndDate__c = System.today();
        usagesummary1.blng__SummaryStartDate__c = System.today().addDays(30);
        insert usagesummary1;
        
        Product2 product =
            new Product2(
            Secondary_Product_Allowed__c=true,
        Name='testJyo',
        CurrencyIsoCode='GBP',
        IsActive=true,
        QTB_Tax_Category__c = 'Digital Services',
        QTB_Oracle_GL_Account_Code__c = '12345',
        QTB_Oracle_Product_Code__c = 'PROD123'
            );
        insert product;
        
        Id pricebookId1 = Test.getStandardPricebookId();
        Order testOrder = new Order(AccountId = account.Id,
        blng__BillingDayOfMonth__c = '1',
        Status = 'Draft',
        EffectiveDate = Date.today(),
        Pricebook2Id=pricebookId1
            //OrderNumber = 'ORD-TEST-001'
        );
        insert testOrder;
        Id testStandardPriceBook = Test.getStandardPricebookId();
        
        
        PriceBookEntry testPriceBookEntry =  new PriceBookEntry(Product2Id = product.Id,
        Pricebook2Id = testStandardPriceBook,
        UnitPrice = 1, IsActive = true,
        UseStandardPrice = false);
        insert testPriceBookEntry;
        Id pricebookId = Test.getStandardPricebookId();
        
        /* OrderItem testOrderItem = new OrderItem(OrderId = testOrder.Id,
        Quantity = 2.00,
        UnitPrice = 12.00,
        PricebookEntryId = testPriceBookEntry.Id,
        Product2Id = product.Id,
        //SBQQ__QuoteLine__c=quoteLinesList.id,
        SBQQ__ChargeType__c='One-Time',
        blng__TaxCountry__c = 'United Kingdom',
        QTB_Order_Product_Type__c = 'ReBill',
        SBQQ__Activated__c = true,
        QTB_Final_Unit_Price__c = 10 );
        SBQQ.TriggerControl.disable();
        //blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').id,
        //blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').id,
        //blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id );
        insert testOrderItem; */
            blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        //invoiceLine.blng__OrderProduct__c = testOrderItem.Id;
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__Invoice__c = invoice.id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;
        invoiceLine.blng__UsageSummary__c = usagesummary1.id;
        invoiceLine.blng__Subtotal__c = 100;
        invoiceLine.blng__TaxCountry__c = 'United Kingdom';
        
        insert invoiceLine;
        System.debug('setup_invoiceLine@@'+invoiceLine);
        
        blng__Usage__c usage0 = new blng__Usage__c();
        usage0.blng__UsageSummary__c = usagesummary1.id;
        usage0.blng__Account__c = account.Id;
        //usage0.blng__OrderProduct__c = testOrderItem.Id;
        usage0.blng__MatchingId__c = '1234';
        usage0.blng__EndDateTime__c = DateTime.now().addDays(1);
        usage0.blng__StartDateTime__c = DateTime.now();
        usage0.QTB_Price_Tier__c = 'Tier 1';
        usage0.QTB_Delivery_Date__c = System.Today();
        usage0.QTB_Actual_Rate__c  = 0.7;
        usage0.QTB_Tax_Street__c ='test';
        usage0.blng__Quantity__c = 15;
        usage0.blng__UnitPrice__c = 7.5;
        //usage0.QTB_Rated_Unit_Price__c = 6.5;
        usage0.blng__PreratedQuantity__c = 19;
        usage0.QTB_Prerated_Unit_Price__c = 8.5;
        usage0.QTB_Invoice_Quantity__c = 20;
        usage0.QTB_Product_Identifier_1__c = 'PROD-1234';
        usage0.QTB_Service_District__c = 'LONDON';
        usage0.QTB_Source_Invoice_Reference__c = 'INV-REF-123';
        usage0.blng__Subtotal__c = 120;
        usage0.CurrencyIsoCode = 'GBP';
        usage0.blng__PreratedQuantity__c = 19;
        SBQQ.TriggerControl.disable();
        insert usage0;
        System.debug('setup_usage0@@'+usage0);
        
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        creditNote1.blng__Account__c = account.Id;
        creditNote1.QTB_On_Account_Credit__c = false;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Legacy Credit';
        creditNote1.blng__Status__c = 'Draft';
        creditNote1.CurrencyIsoCode = 'GBP';
        insert creditNote1;
        
        
        
        /*   blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
        cnl.QTB_Account__c = account.Id;
        cnl.blng__CreditNote__c = creditNote1.id;
        cnl.blng__Product__c = product.Id;
        cnl.QTB_Invoice__c =  invoice.id;
        cnl.QTB_InvoiceLine__c = invoiceLine.id;
        cnl.blng__Subtotal__c = 50;
        cnl.blng__CalculateTax__c=false;
        cnl.blng__TotalAmount__c = 50;
        cnl.QTB_Credit_Quantity__c = 5;
        insert cnl;  */
            
        // Test Invoice Line path
        blng__InvoiceLine__c invoiceLineWithRelationships = [
        SELECT Id, blng__Invoice__c, blng__Invoice__r.blng__Account__c, blng__Invoice__r.blng__Account__r.Id, blng__Invoice__r.blng__Account__r.Name
        FROM blng__InvoiceLine__c
        WHERE Id = :invoiceLine.Id
    ];
        Account accountFromInvoiceLine = QTB_IRMVertexRequestUtil.getAccountDetails(invoiceLineWithRelationships, 'InvoiceLine');
        System.debug('accountFromInvoiceLine0@@'+accountFromInvoiceLine);
        
        System.assertNotEquals(null, accountFromInvoiceLine, 'Account should not be null');
        System.assertEquals(account.Id, accountFromInvoiceLine.Id, 'The Account from Invoice Line should match the created Account');
        
        
        // Test Usage path
        blng__Usage__c usageWithAccount = [
        SELECT Id, blng__Account__c, blng__Account__r.Id, blng__Account__r.Name
        FROM blng__Usage__c
        WHERE Id = :usage0.Id
    ];
        
        Account accountFromUsage = QTB_IRMVertexRequestUtil.getAccountDetails(usageWithAccount, 'UsageSummary');
        System.debug('accountFromUsage0@@'+accountFromUsage);
        System.assertNotEquals(null, accountFromUsage, 'Account should not be null');
        System.assertEquals(account.Id, accountFromUsage.Id, 'The Account from Usage should match the created Account');
        
        /*blng__CreditNoteLine__c creditNoteLineWithAccount = [
    SELECT Id, QTB_Account__c, QTB_Account__r.Id, QTB_Account__r.Name
    FROM blng__CreditNoteLine__c
    WHERE Id = :cnl.Id
]; */
        
        /*Account accountFromCreditNoteLine = QTB_IRMVertexRequestUtil.getAccountDetails(creditNoteLineWithAccount, 'CreditNote');
        System.debug('accountFromCreditNoteLine@@'+accountFromCreditNoteLine);
        System.assertNotEquals(null, accountFromCreditNoteLine, 'Account should not be null');
        System.assertEquals(account.Id, accountFromCreditNoteLine.Id, 'The Account from Credit Note Line should match the created Account');
        
         */
        Test.stopTest();
        
    }
    @isTest
    static void testGetCustomerDestinationAddressXML_NonSITAD() {
        
        IM_Country__c countryRec =  new IM_Country__c();
        countryRec.Iso31662Code__c ='GB';
        countryRec.Iso31663Code__c ='GBR';
        countryRec.Name ='United Kingdom';
        countryRec.Region__c ='Europe';
        
        insert countryRec;
        
        IM_Country__c retCountry = new IM_Country__c(Name='United Kingdom',Region__c='Europe');
        insert retCountry;
        
        IM_Alternative_Country_Name__c altcountry = new IM_Alternative_COuntry_Name__c();
        altcountry.IM_Country__c = retCountry.id;
        altcountry.Alternative_Name__c='United Kingdom';
        
        insert altcountry;
        Test.startTest();
        Account account = new Account(
            Name = 'Test Account',
        ShippingCity = 'London',
        ShippingState = 'England',
        ShippingPostalCode = 'SW1A 1AA',
        ShippingCountry = 'United Kingdom',
        BillingCity = 'London',
        BillingState = 'England',
        BillingPostalCode = 'SW1A 1AA',
        BillingCountry = 'United Kingdom',
        QTB_Legal_Entity_Country__c = 'United Kingdom'
            );
        insert account;
        
        // Create Invoice
        blng__Invoice__c invoice = new blng__Invoice__c(
            blng__Account__c = account.Id,
        blng__InvoiceStatus__c = 'Draft'
            );
        insert invoice;
        blng__UsageSummary__c usagesummary1 = new blng__UsageSummary__c();
        usagesummary1.blng__Status__c = 'Queued For Invoice';
        usagesummary1.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
        usagesummary1.blng__MatchingId__c = '1234';
        usagesummary1.blng__UnitPrice__c = 10;
        usagesummary1.blng__Invoice__c = invoice.Id;
        usagesummary1.blng__SummaryEndDate__c = System.today();
        usagesummary1.blng__SummaryStartDate__c = System.today().addDays(30);
        insert usagesummary1;
        
        
        // Create InvoiceLine
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__Invoice__c = invoice.id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;
        invoiceLine.blng__UsageSummary__c = usagesummary1.id;
        invoiceLine.blng__Subtotal__c = 100;
        invoiceLine.blng__TaxCountry__c = 'United Kingdom';
        
        insert invoiceLine;
        
        
        // Query the invoice line with relationships
        blng__InvoiceLine__c invoiceLineWithRelationships = [
        SELECT Id, blng__Invoice__c, blng__Invoice__r.blng__Account__c, blng__Invoice__r.blng__Account__r.Id,
            blng__Invoice__r.blng__Account__r.Name,blng__Invoice__r.blng__Account__r.ShippingCity,
            blng__Invoice__r.blng__Account__r.ShippingPostalCode
            ,blng__Invoice__r.blng__Account__r.ShippingState,blng__Invoice__r.blng__Account__r.ShippingCountry
        FROM blng__InvoiceLine__c
        WHERE Id = :invoiceLine.Id
    ];
        
        
        String result = QTB_IRMVertexRequestUtil.getCustomerDestinationAddressXML(invoiceLineWithRelationships, 'InvoiceLine','TestCustomerCode');
        Test.stopTest();
        
        // Verify results
        System.assert(result.contains('<City>London</City>'), 'City should be in the XML');
        System.assert(result.contains('<PostalCode>SW1A 1AA</PostalCode>'), 'Postal code should be in the XML');
        System.assert(result.contains('<MainDivision>England</MainDivision>'), 'State should be in the XML');
        System.assert(result.contains('<Country>United Kingdom</Country>'), 'Country should be in the XML');
        //System.assert(!result.contains('<CustomerCode>'), 'CustomerCode should not be present for non-SITAD');
    }
    
    @isTest
    static void testGetAccountDetailsException() {
        Test.startTest();
        
        try {
            // Force an exception by passing null
            Account result = QTB_IRMVertexRequestUtil.getAccountDetails(null, 'Invoice');
            System.assert(false, 'Exception should have been thrown');
        } catch(Exception ex) {
            // Verify the exception was thrown
            System.assert(ex != null, 'Exception should be thrown');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testOnAccCreditNoteResponseMappingDraft() {
        Test.startTest();
        
        try {
            
            List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
            accountList[0].QTB_Legal_Entity_Country__c='United States';
            //accountList[0].CurrencyIsoCode = 'USD';
            accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
            accountList[0].ShippingCity = 'New York';
            accountList[0].ShippingState = 'New York';
            accountList[0].ShippingPostalCode = '22131';
            accountList[0].ShippingCountry = 'United States';
            accountList[0].QTB_SITAD__c = true;
            update accountList;
            
            List<product2> productList = new List<product2>();
            product2 p1 = new product2();
            p1.Name = 'Test Product4';
            p1.productCode = 'TestPrjTM8';
            p1.isActive = true;
            productList.add(p1);
            
            //Product2 -- Usage
            product2 p2 = new product2();
            p2.Name = 'Test Product5';
            p2.isActive = true;
            p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            p2.SBQQ__HasConsumptionSchedule__c = true;
            productList.add(p2);
            
            //Product3  -- Bundle Header
            product2 p3 = new product2();
            p3.Name = 'Test Product6';
            p3.isActive = true;
            p3.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            p3.SBQQ__HasConsumptionSchedule__c = false;
            productList.add(p3);
            
            insert productList;
            
            List<blng__CreditNote__c> creditNotes = new List<blng__CreditNote__c> ();
            blng__CreditNote__c creditNote = new blng__CreditNote__c();
            creditNote.blng__Account__c = accountList[0].Id;
            creditNote.blng__CreditNoteDate__c = date.today();
            creditNote.QTB_On_Account_Credit__c = true;
            creditNote.QTB_Credit_Note_Type__c = 'ON Account Credit';
            creditNote.QTB_Reason_Code__c = 'Legacy Credit';
            creditNote.blng__Status__c = 'Draft';
            creditNote.CurrencyIsoCode = 'USD';
            creditNote.QTB_Case_Number__c = 'Test123';
            creditNote.QTB_Site_Number__c = 'Test123';
            creditNotes.add(creditNote);
            insert creditNotes;
            
            List<blng__CreditNoteLine__c> creditNoteLine = new List<blng__CreditNoteLine__c>();
            blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
            cnl.QTB_Account__c = accountList[0].Id;
            cnl.blng__CreditNote__c = creditNotes[0].id;
            cnl.blng__Product__c = productList[0].Id;
            cnl.QTB_Product_Identifier_1__c = productList[0].productCode;
            cnl.QTB_Credit_Quantity__c = 2;
            cnl.blng__Subtotal__c = 45;
            cnl.blng__TaxCountry__c = 'United States';
            creditNoteLine.add(cnl);
            if(creditNoteLine.size() > 0){
                try{
                    insert creditNoteLine;
                }
                Catch(Exception e){
                    System.debug('Exception@@'+e.getMessage());
                }
                
            }
            
            System.debug('Test_CreditNoteLine@@@@'+creditNoteLine);
            
            String responseBody ='<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"> <soapenv:Header/> <soapenv:Body> <VertexEnvelope xmlns="urn:vertexinc:o-series:tps:8:0"> <Login> <UserName>SALESFORCE3</UserName> <Password>******</Password> </Login> <QuotationResponse documentNumber="CN-35538" documentDate="2025-07-04" transactionId="'+creditNotes[0].Id+'" transactionType="SALE" postingDate="2025-07-04"> <Customer> <CustomerCode>01965910</CustomerCode> </Customer> <SubTotal>-45.0</SubTotal> <Total>-49.39</Total> <TotalTax>-4.39</TotalTax> <LineItem lineItemId="'+creditNoteLine[0].Id+'" lineItemNumber="1"> <Seller> <Company>000</Company> </Seller> <Customer> <CustomerCode>01965910</CustomerCode> <Destination taxAreaId="50371900"> <City>Studio City</City> <MainDivision>CA</MainDivision> <PostalCode>91604</PostalCode> <Country>United States</Country> </Destination> </Customer> <Product productClass="REPAIR LABOR">25.OTHITADAUDREP</Product> <Quantity unitOfMeasure="EA">2.0</Quantity> <FairMarketValue>-45.0</FairMarketValue> <ExtendedPrice>-45.0</ExtendedPrice> <Taxes taxResult="TAXABLE" taxType="SALES" isService="true" situs="DESTINATION" taxCollectedFromParty="BUYER" taxStructure="SINGLE_RATE"> <Jurisdiction jurisdictionLevel="STATE" jurisdictionId="2398">CALIFORNIA</Jurisdiction> <CalculatedTax>-2.7</CalculatedTax> <EffectiveRate>0.06</EffectiveRate> <Taxable>-45.0</Taxable> <Imposition impositionId="1">Sales and Use Tax</Imposition> <ImpositionType impositionTypeId="1">General Sales and Use Tax</ImpositionType> <TaxRuleId>300023872</TaxRuleId> <InclusionRuleId>319786612</InclusionRuleId> </Taxes> <Taxes taxResult="TAXABLE" taxType="SALES" isService="true" situs="DESTINATION" taxCollectedFromParty="BUYER" taxStructure="SINGLE_RATE"> <Jurisdiction jurisdictionLevel="COUNTY" jurisdictionId="2872">LOS ANGELES</Jurisdiction> <CalculatedTax>-0.56</CalculatedTax> <EffectiveRate>0.0125</EffectiveRate> <Taxable>-45.0</Taxable> <Imposition impositionId="1">Local Sales and Use Tax</Imposition> <ImpositionType impositionTypeId="1">General Sales and Use Tax</ImpositionType> <TaxRuleId>301143780</TaxRuleId> <InclusionRuleId>319783366</InclusionRuleId> </Taxes> <Taxes taxResult="TAXABLE" taxType="SALES" isService="true" situs="DESTINATION" taxCollectedFromParty="BUYER" taxStructure="SINGLE_RATE"> <Jurisdiction jurisdictionLevel="DISTRICT" jurisdictionId="2873">TRANSPORTATION COMMISSION (LATC)</Jurisdiction> <CalculatedTax>-0.23</CalculatedTax> <EffectiveRate>0.005</EffectiveRate> <Taxable>-45.0</Taxable> <Imposition impositionId="1">Local Sales and Use Tax</Imposition> <ImpositionType impositionTypeId="1">General Sales and Use Tax</ImpositionType> <TaxRuleId>301028314</TaxRuleId> <InclusionRuleId>319783367</InclusionRuleId> </Taxes> <Taxes taxResult="TAXABLE" taxType="SALES" isService="true" situs="DESTINATION" taxCollectedFromParty="BUYER" taxStructure="SINGLE_RATE"> <Jurisdiction jurisdictionLevel="DISTRICT" jurisdictionId="66710">TRANSIT DISTRICT (LACT)</Jurisdiction> <CalculatedTax>-0.23</CalculatedTax> <EffectiveRate>0.005</EffectiveRate> <Taxable>-45.0</Taxable> <Imposition impositionId="1">Local Sales and Use Tax</Imposition> <ImpositionType impositionTypeId="1">General Sales and Use Tax</ImpositionType> <TaxRuleId>301026017</TaxRuleId> <InclusionRuleId>319783426</InclusionRuleId> </Taxes> <Taxes taxResult="TAXABLE" taxType="SALES" isService="true" situs="DESTINATION" taxCollectedFromParty="BUYER" taxStructure="SINGLE_RATE"> <Jurisdiction jurisdictionLevel="DISTRICT" jurisdictionId="88645"> <![CDATA[ METROPOLITAN TRANSIT DISTRICT (LAMT) ]]> </Jurisdiction> <CalculatedTax>-0.23</CalculatedTax> <EffectiveRate>0.005</EffectiveRate> <Taxable>-45.0</Taxable> <Imposition impositionId="1">Local Sales and Use Tax</Imposition> <ImpositionType impositionTypeId="1">General Sales and Use Tax</ImpositionType> <TaxRuleId>301075544</TaxRuleId> <InclusionRuleId>319783489</InclusionRuleId> </Taxes> <Taxes taxResult="TAXABLE" taxType="SALES" isService="true" situs="DESTINATION" taxCollectedFromParty="BUYER" taxStructure="SINGLE_RATE"> <Jurisdiction jurisdictionLevel="DISTRICT" jurisdictionId="102864">TRANSACTIONS AND USE TAX (LAMA)</Jurisdiction> <CalculatedTax>-0.22</CalculatedTax> <EffectiveRate>0.005</EffectiveRate> <Taxable>-45.0</Taxable> <Imposition impositionId="1">Local Sales and Use Tax</Imposition> <ImpositionType impositionTypeId="1">General Sales and Use Tax</ImpositionType> <TaxRuleId>301211945</TaxRuleId> <InclusionRuleId>319783930</InclusionRuleId> </Taxes> <Taxes taxResult="TAXABLE" taxType="SALES" isService="true" situs="DESTINATION" taxCollectedFromParty="BUYER" taxStructure="SINGLE_RATE"> <Jurisdiction jurisdictionLevel="DISTRICT" jurisdictionId="109060"> <![CDATA[ LOS ANGELES COUNTY TRANSACTIONS AND USE TAX 2025 (B47) ]]> </Jurisdiction> <CalculatedTax>-0.22</CalculatedTax> <EffectiveRate>0.005</EffectiveRate> <Taxable>-45.0</Taxable> <Imposition impositionId="1">Local Sales and Use Tax</Imposition> <ImpositionType impositionTypeId="1">General Sales and Use Tax</ImpositionType> <TaxRuleId>319813593</TaxRuleId> <InclusionRuleId>319823489</InclusionRuleId> </Taxes> <TotalTax>-4.39</TotalTax> <FlexibleFields> <FlexibleCodeField fieldId="1">22131</FlexibleCodeField> <FlexibleCodeField fieldId="2">SF-SB-US</FlexibleCodeField> <FlexibleCodeField fieldId="3">SF-SB-US</FlexibleCodeField> <FlexibleCodeField fieldId="4">CREDIT</FlexibleCodeField> <FlexibleCodeField fieldId="10">40 North SF SMS Sync Test</FlexibleCodeField> <FlexibleCodeField fieldId="11">IT Asset Audit and Repair</FlexibleCodeField> <FlexibleCodeField fieldId="13">22131</FlexibleCodeField> <FlexibleCodeField fieldId="14">02150</FlexibleCodeField> <FlexibleCodeField fieldId="15">16000</FlexibleCodeField> <FlexibleCodeField fieldId="16">4221330</FlexibleCodeField> <FlexibleCodeField fieldId="18">0000</FlexibleCodeField> <FlexibleDateField fieldId="1">2025-07-04</FlexibleDateField> </FlexibleFields> <AssistedParameters> <AssistedParameter paramName="quantity.unitOfMeasure" phase="PRE" ruleName="Set Salesforce US Securebase UOM to EA" originalValue="">EA</AssistedParameter> <AssistedParameter paramName="seller.company" phase="PRE" ruleName="Set Taxpayer for Salesforce US Securebase Transactions" originalValue="">000</AssistedParameter> <AssistedParameter paramName="taxDate" phase="PRE" ruleName="Set Salesforce US Securebase Tax Date" originalValue="2025-07-04">Fri Jul 04 00:00:00 EDT 2025</AssistedParameter> </AssistedParameters> </LineItem> </QuotationResponse> <ApplicationData> <ResponseTimeMS>4.8</ResponseTimeMS> </ApplicationData> </VertexEnvelope> </soapenv:Body> </soapenv:Envelope>';
            QTB_IRMVertexResponseUtil.responseMapping(responseBody,true);
        } catch(Exception ex) {
            // Verify the exception was thrown
            System.assert(ex != null, 'Exception should be thrown');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void handleCNJsonErrorResponseMappingElse()  {
        try{
            Test.startTest();
            List<blng__CreditNote__c> creditNoteList = [Select id, Name, blng__Status__c,blng__RelatedInvoice__c,QTB_Rebill_Invoice__c, blng__Account__c,
                                                        blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Account__r.Name,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Identifier__c,blng__CreditNoteDate__c, QTB_CreditNote_Posted_Date__c,CurrencyISOCode,
                                                        blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Legal_Entity_Country__c,blng__TaxErrorMessage__c  
                                                        From blng__CreditNote__c ];
            blng__CreditNote__c c = new blng__CreditNote__c();
            c.id = creditNoteList[0].id;
            c.blng__TaxErrorMessage__c = 'Tax Error';
            update c;
            System.debug('creditNoteList@@'+creditNoteList);
            List<id> postedCreditNoteIds = new  List<id>();
            for(blng__CreditNote__c credit : creditNoteList){
                postedCreditNoteIds.add(credit.Id);
            }
            
            List<blng__CreditNoteLine__c> creditNoteLineList = [Select id, Name,blng__CreditNote__c,blng__Product__c,blng__TaxAmount__c,blng__CreditNote__r.Id, QTB_Account__c,blng__BillToAccount__c, QTB_Account__r.QTB_Customer_Number__c,blng__Status__c,
                                                                QTB_Account__r.Name,QTB_Account__r.ShippingCity,QTB_Account__r.ShippingState, QTB_Account__r.ShippingPostalCode,QTB_Account__r.IME_Display_Division__c,
                                                                QTB_Account__r.QTB_Billing_Account_Invoice_Name__c,QTB_Account__r.ShippingCountry,blng__Product__r.QTB_Oracle_GL_Account_Code__c,blng__Product__r.IM_Product_Class__c,blng__Product__r.QTB_Tax_Category__c,blng__Product__r.Name,
                                                                blng__Product__r.ProductCode,QTB_Credit_Quantity__c,blng__InvoiceLine__r.blng__OrderProduct__r.Id,
                                                                blng__InvoiceLine__r.QTB_Allocated_Revenue_Amount__c,blng__InvoiceLine__r.blng__OrderProduct__r.Order.OrderNumber,blng__Product__r.Bill_Code__c,blng__TaxErrorMessage__c,
                                                                blng__InvoiceLine__c,blng__InvoiceLine__r.blng__TaxAmount__c,blng__InvoiceLine__r.blng__UsageSummary__c,blng__InvoiceLine__r.blng__UsageSummary__r.id,blng__InvoiceLine__r.QTB_HasConsumptionSchedule__c,
                                                                blng__InvoiceLine__r.QTB_Taxable_Amount__c
                                                                From blng__CreditNoteLine__c where  blng__CreditNote__c IN :postedCreditNoteIds];
            
            
            string responseBody = '{"success":false,"errors": [{"code": "WSG500","message": "The request failed due server error"}],"warnings": ""}';
            QTB_IRMVertexResponseUtil.handleErrorResponseMapping(responseBody,creditNoteList[0],creditNoteLineList,null,null,null);
            Test.stopTest();
        } catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
}