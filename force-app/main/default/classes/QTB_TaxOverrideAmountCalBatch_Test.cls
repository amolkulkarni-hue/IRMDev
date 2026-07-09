/*****************************************************************************************************
 * Class: QTB_TaxOverrideAmountCalBatch_Test
 * Author: Virtusa
 * Purpose: This is a test class for QTB_TaxOverrideAmountCalculationBatch
 * Requirement:
 * Change History: 
 * Developer     	Date           Description
 * -------------------------------------------------------------------------------------------
 * Parth(Virtusa)   08/10/2025         
 *******************************************************************************************************/
@isTest(seealldata=false)
    private class QTB_TaxOverrideAmountCalBatch_Test {
  @testSetup
    static void setup() {
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
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
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
        
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
        
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
                invoiceLine.blng__OrderProduct__c = orderItemFinal[0].ID;
                invoiceLine.blng__UsageSummary__c = usageSumFinal[i].ID;
                //invoiceLine.QTB_Payment_Term__c = '120';
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
        invLineListFinal[0].blng__OrderProduct__c = orderItemFinal[0].ID;
        invLineListFinal[0].blng__UsageSummary__c = usageSumFinal[0].ID;
        //invLineListFinal[0].blng__InvoiceLineStatus__c = 'Posted';       
        invLineListFinal[0].blng__Subtotal__c =123;
        accountList[0].SBQQ__TaxExempt__c = 'No';
      //invLineList[0].blng__InvoiceLineStatus__c = 'Cancelled';
        invLineListFinal[0].blng__TaxStatus__c = 'Completed';
        update invoiceListFinal;
        Map<ID,blng__InvoiceLine__c> poInvMap = new Map<ID,blng__InvoiceLine__c>();
       for(blng__InvoiceLine__c Invllist2:invLineListFinal){
            if(Invllist2.blng__InvoiceLineStatus__c == 'Posted'){
                poInvMap.put(Invllist2.ID,Invllist2);
            }
        } 
        
        // Create Credit Note
        List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);
        System.debug('Test_creditNotes@@'+creditNotes);
        
        List<blng__CreditNoteLine__c> CreditNoteLine = new List<blng__CreditNoteLine__c>();
        blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
        cnl.QTB_Account__c = accountList[0].Id;
        cnl.blng__CreditNote__c = creditNotes[0].ID;
        cnl.QTB_Invoice__c = invoiceListFinal[1].ID;
        cnl.QTB_InvoiceLine__c = invLineListFinal[1].ID;
        cnl.blng__Product__c = productList[0].Id;
        //cnl.blng__Subtotal__c = 50;
        //cnl.blng__CalculateTax__c=true;
        CreditNoteLine.add(cnl);
        if(CreditNoteLine.size() > 0){
            try{
              insert CreditNoteLine;
            }catch(Exception e){
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
        Billcode.QTB_Country__c =country.ID;
        Billcode.QTB_Source_Bill_Code__c='201';
         //Database.insert(billcode);
        
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
        serviceLoc.Customer_Id__c = customer.ID;
        serviceLoc.Owning_District_Id__c =market.ID;
        insert serviceLoc;
        Set<String> addressComparison = new Set<String>();
        blng__TaxRate__c taxRate = new blng__TaxRate__c();
        taxRate.blng__LegalEntity__c = indiaEntity.ID;
        taxRate.blng__Priority__c = '1';
        taxRate.blng__Country__c = 'India';
        taxRate.blng__State__c = 'TN';
        taxRate.blng__City__c = 'Chennai';
        taxRate.blng__ZipCode__c = '500032';
        taxRate.blng__TaxCode__c = 'STD-CGST';
        taxRate.blng__Rate__c = 10;
        taxRate.blng__AddressComparison__c =
            taxRate.blng__Country__c +
            '-' +
            taxRate.blng__State__c +
            '-' +
            taxRate.blng__City__c +
            '-' +
            taxRate.blng__ZipCode__c +
            '-' +
            taxRate.blng__TaxCode__c +
            '-' +
            taxRate.blng__LegalEntity__c;
        taxRate.blng__Rate__c = 9;
        Database.insert(taxRate);
        addressComparison.add(taxRate.blng__AddressComparison__c);

        
        //Database.update(accountList);
        //QTB_InvoiceLineHelperUtils.updateInvcAndInvocLineWithTaxOverride(poInvMap,addressComparison);
        
        
         
      //Test.stopTest();
      QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
      //Database.update(invLineList);
      //System.Assert(invLineList[0].blng__InvoiceLineStatus__c == 'Cancelled');
    }
  //}

    
 static testMethod void testmethod3() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        Test.startTest();
        QTB_InvoiceTriggerHandler.throwExplicitException = false;
        Set<String> addressComparison = new Set<String>();
        List<blng__TaxRate__c> taxRate = [SELECT Id,blng__TaxCode__c,blng__LegalEntity__c,blng__Rate__c,blng__Priority__c,blng__AddressComparison__c,
                                         blng__Country__c,blng__State__c,blng__City__c,blng__ZipCode__c,QTB_TaxDisplay__c
                                         FROM blng__TaxRate__c ORDER BY blng__LegalEntity__c];
        
        List<blng__InvoiceLine__c> invLine = [SELECT ID,blng__TaxAmount__c,blng__Invoice__r.ID,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__InvoiceLineStatus__c,blng__Invoice__r.blng__Subtotal__c,
                                                              blng__LegalEntity__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,
                                                              blng__Invoice__c,blng__TaxTreatment__r.ID,blng__Invoice__r.blng__Account__r.ID,blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,blng__LegalEntity__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                                              QTB_Tax_Code__c,blng__Invoice__r.blng__TaxAmount__c ,blng__Invoice__r.QTB_Invoice_Type__c,blng__LegalEntity__r.QTB_Tax_Applicability__c,
                                                              blng__Invoice__r.blng__TotalAmount__c,blng__Invoice__r.QTB_Tax_Override_Amount__c
                                                              FROM blng__InvoiceLine__c];
        Account acc = [SELECT ID ,SBQQ__TaxExempt__c FROM Account WHERE ID =:invLine[0].blng__Invoice__r.blng__Account__r.ID LIMIT 1];
        acc.SBQQ__TaxExempt__c = 'No';
        update acc;
        
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
          blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
        taxIntegration.blng__TaxEngine__c = 'Standard';
        taxIntegration.blng__Active__c = true;
        Database.insert(taxIntegration);
        
        blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
        blngTax.blng__TaxLegalEntity__c = taxRate[0].blng__LegalEntity__c;
        blngTax.blng__TaxIntegration__c = taxIntegration.ID;
        blngTax.blng__TaxRule__c = taxRule.ID;
        blngTax.blng__TaxCode__c = 'STD-CGST';
        Database.insert(blngTax);
        /*blng__LegalEntity__c LegalEntity = new blng__LegalEntity__c();
        LegalEntity.Name = 'Test Legal Entity ' + 'Thailand';
        LegalEntity.blng__Active__c = true;
        LegalEntity.blng__Country__c = 'Thailand';
        LegalEntity.QTB_Type__c = 'Contract';
        LegalEntity.QTB_Legal_Entity_Number__c = 45000;
        LegalEntity.QTB_Tax_Type__c = 'Flat Rate';
        insert LegalEntity;*/
         Map<ID,blng__InvoiceLine__c> poInvMap = new Map<ID,blng__InvoiceLine__c>();
       for(blng__InvoiceLine__c Invllist2:invLine){
            if(Invllist2.blng__InvoiceLineStatus__c == 'Posted'){
                poInvMap.put(Invllist2.ID,Invllist2);
            }
        } 
       blng__Invoice__c invc = [SELECT ID FROM blng__Invoice__c WHERE ID=:invLine[0].blng__Invoice__r.ID];
        invLine[0].blng__LegalEntity__c = taxRate[0].blng__LegalEntity__c;//LegalEntity.Id;
        //invLine[0].blng__Subtotal__c=12;
        //update invc;
        invLine[0].blng__TaxAmount__c = 29.5200;
        invLine[0].blng__TaxCountry__c = 'Canada';
        System.debug('!!!!@@@@@   11 '+invLine[0].blng__TaxTreatment__c);
        //invLine[0].blng__TaxTreatment__c = blngTax.ID;
        
          String naCountriesLabel = Label.QTB_NA_Countries;
        System.assertEquals('Canada', invLine[0].blng__TaxCountry__c, 'Assertion Message');
        update invLine[0];
        
        List<blng__InvoiceLine__c> invLine1 = [SELECT ID,QTB_Is_Legacy__c,blng__OrderProduct__r.OrderId,QTB_Tiered_Flag__c,blng__TaxAmount__c,blng__Invoice__r.ID,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Invoice__r.blng__Subtotal__c,
                                                blng__LegalEntity__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__Invoice__r.blng__TotalAmount__c,blng__Invoice__r.QTB_Tax_Override_Amount__c,blng__UsageSummary__c,
                                                blng__Invoice__c,blng__TaxTreatment__c,blng__Invoice__r.blng__Account__r.ID,blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,blng__LegalEntity__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                                QTB_Tax_Code__c,blng__Invoice__r.blng__TaxAmount__c ,blng__Invoice__r.QTB_Invoice_Type__c,blng__LegalEntity__r.QTB_Tax_Applicability__c
                                                FROM blng__InvoiceLine__c WHERE ID =:invLine[0].ID];
        /*Map<Id,blng__InvoiceLine__c> lstInvcLineMap = new Map<Id,blng__InvoiceLine__c>([SELECT ID,QTB_Tiered_Flag__c,blng__TaxAmount__c,blng__Invoice__r.ID,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Invoice__r.blng__Subtotal__c,
                                                              blng__LegalEntity__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__UsageSummary__r.QTB_Contracted_Currency_Rate__c,
                                                              blng__Invoice__c,blng__TaxTreatment__c,blng__Invoice__r.blng__Account__r.ID,blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,blng__LegalEntity__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                                              QTB_Tax_Code__c,blng__Invoice__r.blng__TaxAmount__c ,blng__Invoice__r.QTB_Invoice_Type__c,blng__LegalEntity__r.QTB_Tax_Applicability__c,
                                                              blng__Invoice__r.blng__TotalAmount__c,blng__Invoice__r.QTB_Tax_Override_Amount__c
                                                              FROM blng__InvoiceLine__c WHERE ID =:invLine[0].ID]);
        
         List<blng__InvoiceLine__c> lstInvcLine = [SELECT ID,blng__InvoiceLineStatus__c,QTB_Tiered_Flag__c,blng__UsageSummary__c,blng__UsageSummary__r.ID,blng__UsageSummary__r.blng__InvoiceRunProcessingStatus__c, 
                                                    blng__UsageSummary__r.blng__InvoiceRun__c,blng__UsageSummary__r.blng__InvoiceRunStartDate__c,
                                                    blng__Invoice__c, blng__Invoice__r.QTB_Invoice_Type__c, blng__Invoice__r.ID, blng__Invoice__r.blng__InvoiceRunCreatedBy__c, blng__Invoice__r.blng__Account__r.ID, blng__Invoice__r.blng__InvoiceStatus__c, blng__Invoice__r.blng__Account__c, blng__Invoice__r.blng__Account__r.QTB_Hold_Status__c,blng__Invoice__r.blng__Account__r.QTB_Hold_Billing__c
                                                    FROM blng__InvoiceLine__c LIMIT 5];*/                    

        System.debug(invLine);
        Set<ID> invcId = new Set<ID>();
     	Set<Id>invSchId = new Set<Id>();
        invcId.add(invLine1[0].blng__Invoice__c);
        addressComparison.add(taxRate[0].blng__AddressComparison__c);
        database.executeBatch(New QTB_TaxOverrideAmountCalculationBatch(invcId,invSchId));
        Test.stopTest();
    }
    static testMethod void testmethod4() {
      List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
      Test.startTest();
      QTB_InvoiceTriggerHandler.throwExplicitException = false;
        /*List<blng__InvoiceLine__c> invLine = [SELECT ID,blng__Invoice__r.ID,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Invoice__r.blng__Subtotal__c,
                                                              blng__LegalEntity__r.QTB_Tax_Type__c,blng__LegalEntity__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__TaxAmount__c,
                                                              blng__Invoice__c,blng__TaxTreatment__c,blng__Invoice__r.blng__Account__r.ID,blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,blng__LegalEntity__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                                              QTB_Tax_Code__c,blng__Invoice__r.blng__TaxAmount__c ,blng__Invoice__r.QTB_Invoice_Type__c,
                                                              blng__Invoice__r.blng__TotalAmount__c,blng__Invoice__r.QTB_Tax_Override_Amount__c
                                                              FROM blng__InvoiceLine__c];*/
        
      blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
      blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
      blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');

      List<Product2> product = [SELECT ID,Product2.Name,blng__BillingRule__c,blng__RevenueRecognitionRule__c,blng__TaxRule__c FROM Product2];//QTB_TestDataFactory.createProducts(1);
        
      Id pricebookId = Test.getStandardPricebookId();
      PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
                 //Legal Entity
      blng__LegalEntity__c indiaEntity = new blng__LegalEntity__c();
      indiaEntity.Name = 'Test Legal Entity United States';
      indiaEntity.blng__Active__c = true;
      indiaEntity.blng__Country__c = 'United States';
      indiaEntity.QTB_Type__c = 'Contract';
      indiaEntity.QTB_Tax_Applicability__c='Flat Rate';
      // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
      insert indiaEntity;
        
      Set<String> addressComparison = new Set<String>();
      blng__TaxRate__c taxRate = new blng__TaxRate__c();
      taxRate.blng__LegalEntity__c = indiaEntity.ID;
      taxRate.blng__Priority__c = '1';
      taxRate.blng__Country__c = 'India';
      taxRate.blng__State__c = 'TN';
      taxRate.blng__City__c = 'Chennai';
      taxRate.blng__ZipCode__c = '500032';
      taxRate.blng__TaxCode__c = 'STD-CGST';
      taxRate.blng__Rate__c = 10;
      /*taxRate.blng__AddressComparison__c =
            taxRate.blng__Country__c +'-' +taxRate.blng__State__c + '-' +
            taxRate.blng__City__c + '-' +
            taxRate.blng__ZipCode__c + '-' +
            taxRate.blng__TaxCode__c + '-' +
            taxRate.blng__LegalEntity__c; #29101 changed bec the blng__AddressComparison__c was already changed in the main class*/
      taxRate.blng__AddressComparison__c = taxRate.blng__Country__c +'----' +taxRate.blng__TaxCode__c +'-' + taxRate.blng__LegalEntity__c;
      taxRate.blng__Rate__c = 9;
      Database.insert(taxRate);
      addressComparison.add(taxRate.blng__AddressComparison__c);
        
      product[0].blng__BillingRule__c = billingRule.ID;
      product[0].blng__RevenueRecognitionRule__c = revenueRule.ID;
      product[0].blng__TaxRule__c = taxRule.ID;
      update product[0];
        
      blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
      taxIntegration.blng__TaxEngine__c = 'Standard';
      taxIntegration.blng__Active__c = true;
      Database.insert(taxIntegration);
      
      blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
      blngTax.blng__TaxLegalEntity__c = indiaEntity.ID;
      blngTax.blng__TaxIntegration__c = taxIntegration.ID;
      blngTax.blng__TaxRule__c = taxRule.ID;
      blngTax.blng__TaxCode__c = 'STD-CGST';
      Database.insert(blngTax);
           //blng__Invoice__c invc = [SELECT ID,blng__TaxAmount__c FROM blng__Invoice__c WHERE ID=:invLine[0].blng__Invoice__r.ID];
        //invc.blng__TaxAmount__c = 25.23;
        //update invc;
      List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
      Account acc = [SELECT ID ,SBQQ__TaxExempt__c FROM Account WHERE ID =:accountList[0].ID LIMIT 1];
      acc.SBQQ__TaxExempt__c = 'No';
      update acc;    
      List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
        

      blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
      invoiceLine.Name = product[0].Name;
      invoiceLine.blng__Invoice__c = invoiceList[0].Id;
      invoiceLine.blng__TaxCountry__c = 'Canada';
      invoiceLine.blng__Product__c = product[0].Id;
      invoiceLine.blng__TaxTreatment__c = blngTax.ID;
      invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
      invoiceLine.blng__LegalEntity__c = indiaEntity.Id;
      invoiceLine.blng__Quantity__c = 10;
      invoiceLine.blng__UnitPrice__c = 5;          
      invoiceLine.blng__TaxPercentageApplied__c = 24;
      invoiceLine.blng__TaxStatus__c = 'Processing';
      //invoiceLine.blng__InvoiceLineStatus__c = QTB_Constants.INVOICELINE_STATUS_DRAFT;
      String naCountriesLabel = Label.QTB_NA_Countries;
      System.assertEquals('Canada', invoiceLine.blng__TaxCountry__c, 'Assertion Message');
      insert invoiceLine;
    
    
      invoiceLine.blng__TaxAmount__c = 29.52000000;
      update invoiceLine;
       
        
      /*List<blng__InvoiceLine__c> invLine1 = [SELECT ID,QTB_Tiered_Flag__c,blng__TaxAmount__c,blng__Invoice__r.ID,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Invoice__r.blng__Subtotal__c,
                                                              blng__InvoiceLine__c.blng__TaxTreatment__c,blng__LegalEntity__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,
                                                              blng__Invoice__c,blng__Invoice__r.blng__Account__r.ID,blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,blng__LegalEntity__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                                              QTB_Tax_Code__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c,blng__Invoice__r.blng__TaxAmount__c ,blng__Invoice__r.QTB_Invoice_Type__c,
                                                              blng__Invoice__r.blng__TotalAmount__c,blng__LegalEntity__r.QTB_Tax_Applicability__c,blng__Invoice__r.QTB_Tax_Override_Amount__c
                                                              FROM blng__InvoiceLine__c WHERE ID =:invoiceLine.ID];*/
        
      /*Map<Id,blng__InvoiceLine__c> lstInvcLineMap = new Map<Id,blng__InvoiceLine__c>([SELECT ID,QTB_Tiered_Flag__c,blng__TaxAmount__c,blng__Invoice__r.ID,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Invoice__r.blng__Subtotal__c,
                                                              blng__InvoiceLine__c.blng__TaxTreatment__c,blng__LegalEntity__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__UsageSummary__r.QTB_Contracted_Currency_Rate__c,
                                                              blng__Invoice__c,blng__Invoice__r.blng__Account__r.ID,blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,blng__LegalEntity__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                                              QTB_Tax_Code__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c,blng__Invoice__r.blng__TaxAmount__c ,blng__Invoice__r.QTB_Invoice_Type__c,
                                                              blng__Invoice__r.blng__TotalAmount__c,blng__LegalEntity__r.QTB_Tax_Applicability__c,blng__Invoice__r.QTB_Tax_Override_Amount__c
                                                              FROM blng__InvoiceLine__c WHERE ID =:invoiceLine.ID]);*/
        
        Set<Id>invcId = new Set<Id>();
        Set<Id>invSchId = new Set<Id>();
        invcId.add(invoiceList[0].Id);
        QTB_TaxOverrideAmountCalculationBatch.throwExplicitException = true;
        database.executeBatch(New QTB_TaxOverrideAmountCalculationBatch(invcId,invSchId));
        Test.stopTest();
    }  
    static testMethod void testmethod5() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        Test.startTest();
         /*List<blng__Usage__c> usages = new List<blng__Usage__c>([SELECT ID,QTB_System_Generated__c,QTB_System_Cancelled__c,
                                                                        blng__Quantity__c,blng__PreratedQuantity__c,
                                                                        blng__Subtotal__c,blng__PreratedAmount__c,blng__UsageSummary__c,
                                                                        blng__UsageSummary__r.blng__Subtotal__c,blng__UsageSummary__r.blng__PreratedAmount__c,
                                                                        blng__UsageSummary__r.blng__TotalQuantity__c,blng__UsageSummary__r.blng__UnbilledQuantity__c,
                                                                        blng__UsageSummary__r.blng__PreratedQuantity__c
                                                                        FROM blng__Usage__c WHERE QTB_System_Generated__c=TRUE]);
        Set<ID> setIds = new Set<ID>();
        System.debug('457 Test usages[0].blng__UsageSummary__c '+usages[0].blng__UsageSummary__c);
        setIds.add(usages[0].blng__UsageSummary__c);
        list<blng__InvoiceLine__c> invLine = [Select id,blng__UsageSummary__c,blng__InvoiceLineStatus__c from blng__InvoiceLine__c where blng__UsageSummary__c in :setIds];
        for(blng__InvoiceLine__c invln :invLine){
            invln.blng__InvoiceLineStatus__c = 'cancelled';
        }
        sbqq.TriggerControl.disable();
        update invLine;
        sbqq.TriggerControl.enable();
        
        System.debug('459 Test '+setIds);
        //QTB_InvoiceLineHelper.cancelMinCharges(setIds);
        
        QTB_InvoiceTriggerHandler.throwExplicitException = false;
        List<blng__InvoiceLine__c> invLine = [SELECT ID,blng__Invoice__r.ID,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Invoice__r.blng__Subtotal__c,
                                                              blng__LegalEntity__r.QTB_Tax_Type__c,blng__LegalEntity__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__TaxAmount__c,
                                                              blng__Invoice__c,blng__TaxTreatment__c,blng__Invoice__r.blng__Account__r.ID,blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,blng__LegalEntity__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                                              QTB_Tax_Code__c,blng__Invoice__r.blng__TaxAmount__c ,blng__Invoice__r.QTB_Invoice_Type__c,
                                                              blng__Invoice__r.blng__TotalAmount__c,blng__Invoice__r.QTB_Tax_Override_Amount__c
                                                              FROM blng__InvoiceLine__c];*/
        
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');

        List<Product2> product = [SELECT ID,Product2.Name,blng__BillingRule__c,blng__RevenueRecognitionRule__c,blng__TaxRule__c FROM Product2];//QTB_TestDataFactory.createProducts(1);
      
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
                //Legal Entity
        blng__LegalEntity__c indiaEntity = new blng__LegalEntity__c();
        indiaEntity.Name = 'Test Legal Entity United States';
        indiaEntity.blng__Active__c = true;
        indiaEntity.blng__Country__c = 'United States';
        indiaEntity.QTB_Type__c = 'Contract';
        indiaEntity.QTB_Tax_Applicability__c='Flat Rate';
        // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert indiaEntity;
        
        Set<String> addressComparison = new Set<String>();
        blng__TaxRate__c taxRate = new blng__TaxRate__c();
        taxRate.blng__LegalEntity__c = indiaEntity.ID;
        taxRate.blng__Priority__c = '1';
        taxRate.blng__Country__c = 'India';
        taxRate.blng__State__c = 'TN';
        taxRate.blng__City__c = 'Chennai';
        taxRate.blng__ZipCode__c = '500032';
        taxRate.blng__TaxCode__c = 'STD-CGST';
        taxRate.blng__Rate__c = 10;
        /* taxRate.blng__AddressComparison__c =
            taxRate.blng__Country__c +
            '-' +
            taxRate.blng__State__c +
            '-' +
            taxRate.blng__City__c +
            '-' +
            taxRate.blng__ZipCode__c +
            '-' +
            taxRate.blng__TaxCode__c +
            '-' +
            taxRate.blng__LegalEntity__c; #29101 changed bec the blng__AddressComparison__c was already changed in the main class*/
        taxRate.blng__AddressComparison__c = taxRate.blng__Country__c +'----' +taxRate.blng__TaxCode__c +'-' + taxRate.blng__LegalEntity__c;
        taxRate.blng__Rate__c = 9; 

        Database.insert(taxRate);
        addressComparison.add(taxRate.blng__AddressComparison__c);
        
        product[0].blng__BillingRule__c = billingRule.ID;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.ID;
        product[0].blng__TaxRule__c = taxRule.ID;
        update product[0];
          
        blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
        taxIntegration.blng__TaxEngine__c = 'Standard';
        taxIntegration.blng__Active__c = true;
        Database.insert(taxIntegration);
      
        blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
        blngTax.blng__TaxLegalEntity__c = indiaEntity.ID;
        blngTax.blng__TaxIntegration__c = taxIntegration.ID;
        blngTax.blng__TaxRule__c = taxRule.ID;
        blngTax.blng__TaxCode__c = 'STD-CGST';
        Database.insert(blngTax);
          //blng__Invoice__c invc = [SELECT ID,blng__TaxAmount__c FROM blng__Invoice__c WHERE ID=:invLine[0].blng__Invoice__r.ID];
        //invc.blng__TaxAmount__c = 25.23;
        //update invc;
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        Account acc = [SELECT ID ,SBQQ__TaxExempt__c FROM Account WHERE ID =:accountList[0].ID LIMIT 1];
        acc.SBQQ__TaxExempt__c = 'No';
        update acc;    
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = product[0].Name;
        invoiceLine.blng__Invoice__c = invoiceList[0].Id;
        invoiceLine.blng__Product__c = product[0].Id;
        invoiceLine.blng__TaxTreatment__c = blngTax.ID;
        invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
        invoiceLine.blng__LegalEntity__c = indiaEntity.Id;
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;          
        invoiceLine.blng__TaxPercentageApplied__c = 24;
        invoiceLine.blng__TaxStatus__c = 'Processing';
        invoiceLine.blng__TaxCountry__c = 'India';
        invoiceLine.blng__TaxState__c = 'TN';
        invoiceLine.blng__TaxCity__c = 'Chennai';
        invoiceLine.blng__TaxZipCode__c = '500032';
        invoiceLine.blng__Subtotal__c = 24;
        //invoiceLine.blng__InvoiceLineStatus__c = QTB_Constants.INVOICELINE_STATUS_DRAFT;
        insert invoiceLine;
      
        invoiceLine.blng__TaxAmount__c = 29.52000000;
        update invoiceLine;
        
        /*List<blng__InvoiceLine__c> invLine1 = [SELECT ID,QTB_Tiered_Flag__c,blng__TaxAmount__c,blng__Invoice__r.ID,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Invoice__r.blng__Subtotal__c,
                                                            blng__InvoiceLine__c.blng__TaxTreatment__c,blng__LegalEntity__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,
                                                            blng__Invoice__c,blng__Invoice__r.blng__Account__r.ID,blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,blng__LegalEntity__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                                            QTB_Tax_Code__c,blng__LegalEntity__r.QTB_Tax_Applicability__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c,blng__Invoice__r.blng__TaxAmount__c ,blng__Invoice__r.QTB_Invoice_Type__c,
                                                            blng__Invoice__r.blng__TotalAmount__c,blng__Invoice__r.QTB_Tax_Override_Amount__c
                                                            FROM blng__InvoiceLine__c WHERE ID =:invoiceLine.ID];
      
        Map<Id,blng__InvoiceLine__c> lstInvcLineMap = new Map<Id,blng__InvoiceLine__c>([SELECT ID,QTB_Tiered_Flag__c,blng__TaxAmount__c,blng__Invoice__r.ID,blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Invoice__r.blng__Subtotal__c,
                                                              blng__InvoiceLine__c.blng__TaxTreatment__c,blng__LegalEntity__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__UsageSummary__r.QTB_Contracted_Currency_Rate__c,
                                                              blng__Invoice__c,blng__Invoice__r.blng__Account__r.ID,blng__Invoice__r.blng__Account__r.SBQQ__TaxExempt__c,blng__LegalEntity__c,blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                                              QTB_Tax_Code__c,blng__LegalEntity__r.QTB_Tax_Applicability__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c,blng__Invoice__r.blng__TaxAmount__c ,blng__Invoice__r.QTB_Invoice_Type__c,
                                                              blng__Invoice__r.blng__TotalAmount__c,blng__Invoice__r.QTB_Tax_Override_Amount__c
                                                              FROM blng__InvoiceLine__c WHERE ID =:invoiceLine.ID]);*/
        
       blng__LegalEntity__c usEntity = new blng__LegalEntity__c();
        usEntity.Name = 'Test Legal Entity United States';
        usEntity.blng__Active__c = true;
        usEntity.blng__Country__c = 'United States';
        usEntity.QTB_Type__c = 'Contract';
        usEntity.QTB_Tax_Applicability__c = 'Flat Rate';
        usEntity.QTB_Service_Date_on_Invoice__c = 'Service Range';
        usEntity.QTB_Storage_Date_on_Invoice__c = 'Regular Storage';
        insert usEntity;
        
        blng__FinanceBook__c financeBook = new blng__FinanceBook__c();
        financeBook.Name = 'Accounting Finance Book';
        financeBook.blng__FinancePeriodDuration__c = 'Monthly';
        financeBook.blng__Active__c = true;
        financeBook.blng__PeriodType__c='Accounting';
        insert financeBook;

		blng__FinancePeriod__c financePeriod = new blng__FinancePeriod__c();
        financePeriod.Name = 'singapore Mar 2024';
        financePeriod.blng__FinanceBook__c = financeBook.ID;
        financePeriod.blng__PeriodStartDate__c = System.today().toStartofMonth();
        financePeriod.blng__PeriodEndDate__c = System.today().addMonths(1).toStartofMonth().addDays(-1);
        financePeriod.blng__LegalEntity__c = usEntity.ID;
        financePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert financePeriod;
        
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'Test123456';
        schedule.blng__Type__c = 'Once';
        //schedule.blng__InvoiceBatches__c = 'United States-DM-1st-EOM Manual';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.today().addDays(1);
        schedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        schedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        schedule.QTB_Legal_Entity__c  = usEntity.ID;
        schedule.QTB_Invoice_Period__c = financePeriod.ID ;
        insert schedule;
        set<Id>invSchId = new Set<Id>();
        invSchId.add(schedule.Id);
        Set<Id>invcId = new Set<Id>();
        invcId.add(invoiceList[0].Id);
        database.executeBatch(New QTB_TaxOverrideAmountCalculationBatch(invcId,invSchId));
        Test.stopTest();
    }
    
      

}