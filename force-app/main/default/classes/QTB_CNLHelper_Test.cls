/*****************************************************************************************************
* Class: QTB_CNLHelper_Test
* Author: Accenture
* Purpose: Test Class for QTB_CNLHelper, QTB_CNLTriggerHandler and QTB_CNLTrigger
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture   5/9/2020
* Virtusa     12/09/2021       #5703 Credit Note for Subscription Bundles
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_CNLHelper_Test {
    @testSetup
    static void setup(){
        
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
      custSetting.SObject_API_Name__c = 'SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNote__c';
      custSetting.Disable_VR__c = true;
      custSetting.Disable_PB__c = true;
      custSetting.Disable_Trigger__c = true;
      // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      insert custSetting;
        
        Id pricebookId = Test.getStandardPricebookId();
        //Product 
        //Usage
        List<product2> productList = new List<product2>();
        product2 p = new product2();
        p.Name = 'Test Product';
        p.isActive = true;
        p.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p); 
        
        //Bundle Header
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = false;
        productList.add(p1);
        
        //Recurring Product
        product2 p2 = new product2();
        p2.Name = 'Recurring';
        p2.isActive = true;
        p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p2.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p2);
        insert productList;
        
        //ProductOption
        List<SBQQ__ProductOption__c> prdOptionList = new List<SBQQ__ProductOption__c>();
        
        SBQQ__ProductOption__c prdOption = new SBQQ__ProductOption__c();
        prdOption.SBQQ__Number__c = 1;
        prdOption.SBQQ__ConfiguredSKU__c = productList[1].id;
        prdOption.SBQQ__OptionalSKU__c = productList[2].id;
        prdOption.SBQQ__Type__c = 'Component';
        prdOption.SBQQ__Bundled__c = true;
        prdOptionList.add(prdOption);
        
        //ProductOption
        SBQQ__ProductOption__c prdOption1 = new SBQQ__ProductOption__c();
        prdOption1.SBQQ__Number__c = 1;
        prdOption1.SBQQ__ConfiguredSKU__c = productList[1].id;
        prdOption1.SBQQ__OptionalSKU__c = productList[0].id;
        prdOption1.SBQQ__Type__c = 'Component';
        prdOption1.SBQQ__Bundled__c = true;
        prdOptionList.add(prdOption1);
        insert prdOptionList;
        
        //PriceBook
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(productList[0]);
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(productList[1]);
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[2]);
        
        ConsumptionSchedule consumption = new ConsumptionSchedule();
        consumption.Name = 'dummy';
        consumption.RatingMethod = 'Tier';
        consumption.Type = 'Range';
        consumption.SBQQ__Category__c = 'Rates';
        consumption.BillingTerm = 10;
        consumption.BillingTermUnit = 'Month';
        insert consumption;
        
        ConsumptionRate conrate = new ConsumptionRate();
        conrate.ProcessingOrder = 1;
        conrate.PricingMethod = 'PerUnit';
        conrate.LowerBound = 1;
        conrate.Price = 100;
        conrate.ConsumptionScheduleId = consumption.Id;
        insert conrate;
        
        consumption.IsActive = true;
        update consumption;
        
        insert new ProductConsumptionSchedule(ConsumptionScheduleId = consumption.Id,ProductId = productList[0].Id);
        
        List<Account> accountList = new List<Account>();
        string recordType = 'Standard Account';
        ID StandardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;   
        string recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        try {
            Account a = new Account();
            a.Name = 'Test';
            a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
            if (String.isNotBlank(recordType) && String.isNotEmpty(recordType)) {
                a.RecordTypeId = recordTypeValue;
                if (('Billing Account').equals(recordType)) {
                    a.QTB_Create_Parent_Billing_Account__c = true;
                }
            } else {
                a.RecordTypeId = StandardrecordId;
            }
            a.Name = 'Test Account';
            a.BillingCountry = 'India';
            a.BillingPostalCode = '11209';
            a.BillingState = 'TN';
            a.Registration_Number__c = 'Reg';
            a.ShippingCountry = 'India';
            a.QTB_Legal_Entity_Country__c='India';
            a.CurrencyIsoCode = 'USD';
            a.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
            a.IM_Hierarchy_Level__c = 'Sales (Site)';
            accountList.add(a);
            if (!accountList.isEmpty()) {
                insert accountList;
            }
        }
        catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
        
        //Legal Entity
        blng__LegalEntity__c USEntity = new blng__LegalEntity__c();
        USEntity.Name = 'Test Legal Entity United States';
        USEntity.blng__Active__c = true;
        USEntity.blng__Country__c = 'United States';
        USEntity.QTB_Type__c = 'Contract';
        //USEntity.QTB_Legal_Entity_Number__c = '45000';
        insert USEntity;
        
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
        Metadata_Activation_Settings__c custs = new Metadata_Activation_Settings__c();
        custs.SObject_API_Name__c = 'Opportunity';
        custs.Disable_VR__c = true;
        custs.Disable_Trigger__c = true;
        //List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.AccountId = accountList[0].Id;
        opp.CloseDate = Date.today();
        opp.StageName = '1 - Qualification';
        opp.RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
        opp.Amount = 500; 
        opp.Pricebook2Id = pricebookId;
        opp.Legal_Entity__c = USEntity.id;
        opp.Billing_Country__c = im.id;   
        oppList.add(opp); 
        database.insert(oppList);
        custs.Disable_VR__c = false;
        custs.Disable_Trigger__c = false;
        
        SBQQ.TriggerControl.disable();
        //Quote
        //List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c q = new SBQQ__Quote__c();
        q.SBQQ__Opportunity2__c = oppList[0].Id;
        q.SBQQ__Account__c = accountList[0].Id;
        q.SBQQ__Type__c = QTB_Constants.QUOTE_TYPE_STANDARD;
        q.SBQQ__Status__c = 'Draft';
        q.SBQQ__QuoteLanguage__c = 'English';
        q.SBQQ__ExpirationDate__c = date.today();
        q.SBQQ__Primary__c = true;
        //q.SBQQ__PrimaryContact__c = '003g000002AhYrNAAV';
        q.SBQQ__StartDate__c = date.today();
        q.SBQQ__PriceBook__c = pricebookId;
        q.SBQQ__StartDate__c = System.Today();
        q.QTB_IM_Legal_Entity__c = USEntity.id;
        q.QTB_Opportunity_Billing_Country__c = 'United States';
        quoteList.add(q);
        database.insert(QuoteList);
        //Database.SaveResult[] srList =  database.insert(quoteList,false);
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[0].id);//for Usage
        List<SBQQ__QuoteLine__c> quoteLinesList1 = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[1].id);//for BundleHeader
        List<SBQQ__QuoteLine__c> quoteLinesList2 = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[2].id);//for Recurring
        
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        //database.update(orderList3);
        
        
    
        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[0].Id,quoteLinesList,standardPrice);
        List<OrderItem> orderItemList4 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[1].Id,quoteLinesList1,standardPrice1);
        List<OrderItem> orderItemList5 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[2].Id,quoteLinesList2,standardPrice2);
        
        Test.startTest();
        //List<blng__Invoice__c> invoiceListForCredit = QTB_TestDataFactory.createInvoices(accountList);
        List<blng__Invoice__c> invoiceListForCredit = New List<blng__Invoice__c>();
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[0].Id;
        invoice.blng__InvoiceStatus__c = 'Draft';
        invoiceListForCredit.add(invoice);
        database.insert(invoiceListForCredit);
        
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0]);
        blng__UsageSummary__c usagesummary = usageSum[0];   
        usageSum[0].blng__Status__c = 'Queued For Invoice';
        usageSum[0].blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usageSum[0].blng__Subtotal__c = 100;
        usageSum[0].blng__TotalQuantity__c = 10;
        usageSum[0].blng__PreratedQuantity__c = 20;
        usageSum[0].blng__UnbilledQuantity__c = 1;
        usageSum[0].blng__UnitPrice__c = 400;
        usageSum[0].blng__PreratedAmount__c = 22;
        usageSum[0].blng__SummaryStartDate__c = Date.valueOf('2023-04-27');
        usageSum[0].blng__Invoice__c = invoiceListForCredit[0].id;
        database.update(usageSum[0]);
        
        List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usageSum[0]);
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        usageList[0].QTB_Service_District__c = '44147';
        usageList[0].blng__Subtotal__c = 0;
        usageList[0].blng__OrderProduct__c = orderItemList3[0].id;
        usageList[0].QTB_Product_Identifier_1__c =  productLookup.id;
        database.update(usageList[0]);           
        
        //Invoice Run
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        
        invoiceListForCredit[0].blng__InvoiceDate__c = Date.valueOf('2023-04-27');
        invoiceListForCredit[0].blng__InvoiceStatus__c = 'Posted';       
        invoiceListForCredit[0].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        invoiceListForCredit[0].QTB_ReBill_Status__c = 'Usage Completed';
        update invoiceListForCredit[0];
        
        //Tax Rule
        List<blng__TaxRule__c> taxRuleList = new List<blng__TaxRule__c>();
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';            
        taxRuleList.add(taxRule);
        
        blng__TaxRule__c taxRule1 = new blng__TaxRule__c();
        taxRule1.Name = 'No Tax Rule';
        taxRule1.blng__Active__c = true;
        taxRule1.blng__TaxableYesNo__c = 'Yes';
        taxRuleList.add(taxRule1);
        insert taxRuleList;
        
        //Usage Summary
        List<blng__UsageSummary__c> usageSum2 = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0]);
        blng__UsageSummary__c usagesummary2 = usageSum2[0];        
        usagesummary2.blng__Status__c = 'Queued For Invoice';
        usagesummary2.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary2.blng__Subtotal__c = 100;
        usagesummary2.blng__TotalQuantity__c = 10;
        usagesummary2.blng__PreratedQuantity__c = 20;
        usagesummary2.blng__UnbilledQuantity__c = 1;
        usagesummary2.blng__UnitPrice__c = 400;
        usagesummary2.blng__PreratedAmount__c = 22;
        usagesummary2.blng__SummaryStartDate__c = Date.valueOf('2023-04-27');
        usagesummary2.blng__Invoice__c = invoiceListForCredit[0].id;
        database.update(usagesummary2);
        
        //Usages
        List<blng__Usage__c> usageList2 = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary2);
        usageList2[0].QTB_System_Generated__c = true;
        usageList2[0].blng__PreratedAmount__c = 100;
        usageList2[0].blng__PreratedQuantity__c = 10;
        usageList2[0].QTB_Service_District__c = '44147';
        usageList2[0].blng__Subtotal__c = 0;
        usageList2[0].blng__OrderProduct__c = orderItemList3[0].id; 
        usageList2[0].QTB_Product_Identifier_1__c =  productLookup.id;
        database.update(usageList2);
        
        //Invoice Line-1
        List<blng__InvoiceLine__c> allInvLineListForCredit = new List<blng__InvoiceLine__c>();
        QTB_TestDataFactory.createBypassSetting('blng__InvoiceLine__c');
        List<blng__InvoiceLine__c> invLineListForCredit1 = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
        invLineListForCredit1[0].blng__OrderProduct__c = orderItemList3[0].id;
        invLineListForCredit1[0].blng__Product__c = productList[0].id;
        invLineListForCredit1[0].blng__UsageSummary__c = usagesummary2.id;
        invLineListForCredit1[0].blng__InvoiceLineStatus__c = 'Posted';
        invLineListForCredit1[0].blng__UnitPrice__c = 1;
        invLineListForCredit1[0].blng__TaxAmount__c = 50;        
        invLineListForCredit1[0].blng__TaxCountry__c = 'India';
        invLineListForCredit1[0].blng__TaxState__c = 'TN';
        invLineListForCredit1[0].blng__TaxCity__c = 'Chennai';
        invLineListForCredit1[0].blng__TaxZipCode__c = '500032';
        invLineListForCredit1[0].blng__LegalEntity__c = indiaEntity.id;
        invLineListForCredit1[0].blng__Subtotal__c = 50000;
        invLineListForCredit1[0].blng__TaxRule__c = taxRuleList[0].id;
        invLineListForCredit1[0].blng__TotalAmount__c = 1000;
        invLineListForCredit1[0].blng__TaxPercentageApplied__c = 0;
        invLineListForCredit1[0].blng__UnitPrice__c = 1;           
        //database.update(invLineListForCredit1);
        allInvLineListForCredit.add(invLineListForCredit1[0]);
        
        //Invoice Line-2
        List<blng__InvoiceLine__c> invLineListForCredit2 = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
        invLineListForCredit2[0].blng__OrderProduct__c = orderItemList3[0].id;
        invLineListForCredit2[0].blng__Product__c = productList[0].id;
        invLineListForCredit2[0].blng__UsageSummary__c = usagesummary.id;
        invLineListForCredit2[0].blng__InvoiceLineStatus__c = 'Posted';
        invLineListForCredit2[0].blng__UnitPrice__c = 1;
        invLineListForCredit2[0].blng__TaxAmount__c = 50;        
        invLineListForCredit2[0].blng__TaxCountry__c = 'India';
        invLineListForCredit2[0].blng__TaxState__c = 'TN';
        invLineListForCredit2[0].blng__TaxCity__c = 'Hyderabad';
        invLineListForCredit2[0].blng__TaxZipCode__c = '500032';
        invLineListForCredit2[0].blng__LegalEntity__c = indiaEntity.id;
        invLineListForCredit2[0].blng__Subtotal__c = 10000;
        invLineListForCredit2[0].blng__TaxRule__c = taxRuleList[0].id;
        invLineListForCredit2[0].blng__TotalAmount__c = 500;
        invLineListForCredit2[0].blng__TaxPercentageApplied__c = 0;
        invLineListForCredit2[0].blng__UnitPrice__c = 1; 
        //database.update(invLineListForCredit2);
        allInvLineListForCredit.add(invLineListForCredit2[0]);
        
        //Invoice Line-3
        List<blng__InvoiceLine__c> invLineListForCredit3 = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
        invLineListForCredit3[0].blng__OrderProduct__c = orderItemList3[0].id;
        invLineListForCredit3[0].blng__Product__c = productList[0].id;
        invLineListForCredit3[0].blng__UsageSummary__c = usagesummary.id;
        invLineListForCredit3[0].blng__InvoiceLineStatus__c = 'Posted';
        invLineListForCredit3[0].blng__UnitPrice__c = 1;
        invLineListForCredit3[0].blng__TaxAmount__c = 50;        
        invLineListForCredit3[0].blng__TaxCountry__c = 'India';
        invLineListForCredit3[0].blng__TaxState__c = 'TN';
        invLineListForCredit3[0].blng__TaxCity__c = 'Hyderabad';
        invLineListForCredit3[0].blng__TaxZipCode__c = '500032';
        invLineListForCredit3[0].blng__LegalEntity__c = indiaEntity.id;
        invLineListForCredit3[0].blng__Subtotal__c = 10000;
        invLineListForCredit3[0].blng__TaxRule__c = taxRuleList[0].id;
        invLineListForCredit3[0].blng__TotalAmount__c = 500;
        invLineListForCredit3[0].blng__TaxPercentageApplied__c = 0;
        invLineListForCredit3[0].blng__UnitPrice__c = 1; 
        //database.update(invLineListForCredit3);
        allInvLineListForCredit.add(invLineListForCredit3[0]);
        
        //Invoice Line-4 --> For BundleHeader
        List<blng__InvoiceLine__c> invLineListForCredit4 = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
        invLineListForCredit4[0].blng__OrderProduct__c = orderItemList4[0].id;
        invLineListForCredit4[0].Name = productList[1].Name;
        invLineListForCredit4[0].blng__Product__c = productList[1].id; //Bundle Header Product 
        //invLineListForCredit1[0].blng__UsageSummary__c = usagesummary2.id;
        invLineListForCredit4[0].blng__InvoiceLineStatus__c = 'Posted';
        invLineListForCredit4[0].blng__UnitPrice__c = 1;
        invLineListForCredit4[0].blng__TaxAmount__c = 50;        
        invLineListForCredit4[0].blng__TaxCountry__c = 'United States';
        invLineListForCredit4[0].blng__TaxState__c = 'TN';
        invLineListForCredit4[0].blng__TaxCity__c = 'Chennai';
        invLineListForCredit4[0].blng__TaxZipCode__c = '500032';
        invLineListForCredit4[0].blng__LegalEntity__c = USEntity.id;
        invLineListForCredit4[0].blng__Subtotal__c = 5000000;
        invLineListForCredit4[0].blng__TaxRule__c = taxRuleList[1].id; //No Tax Rule
        invLineListForCredit4[0].blng__TotalAmount__c = 5000000;
        invLineListForCredit4[0].blng__TaxPercentageApplied__c = 0;
        invLineListForCredit4[0].blng__UnitPrice__c = 1;            
        // database.update(invLineListForCredit4);
        allInvLineListForCredit.add(invLineListForCredit4[0]);
        
        //Invoice Line-5 -->For Recurring
        List<blng__InvoiceLine__c> invLineListForCredit5 = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
        invLineListForCredit5[0].blng__OrderProduct__c = orderItemList4[0].id;
        invLineListForCredit5[0].Name = productList[2].Name;
        invLineListForCredit5[0].blng__Product__c = productList[2].id; //Recurring Product 
        invLineListForCredit1[0].blng__UsageSummary__c = null;
        invLineListForCredit5[0].blng__InvoiceLineStatus__c = 'Posted';
        invLineListForCredit5[0].blng__UnitPrice__c = 1;
        invLineListForCredit5[0].blng__TaxAmount__c = 50;        
        invLineListForCredit5[0].blng__TaxCountry__c = 'United States';
        invLineListForCredit5[0].blng__TaxState__c = 'TN';
        invLineListForCredit5[0].blng__TaxCity__c = 'Chennai';
        invLineListForCredit5[0].blng__TaxZipCode__c = '500032';
        invLineListForCredit5[0].blng__LegalEntity__c = USEntity.id;
        invLineListForCredit5[0].blng__Subtotal__c = 11;
        invLineListForCredit5[0].QTB_Taxable_Amount__c = 10;
        invLineListForCredit5[0].blng__TaxRule__c = taxRuleList[0].id; //No Tax Rule
        invLineListForCredit5[0].blng__TotalAmount__c = 21;
        invLineListForCredit5[0].blng__TaxPercentageApplied__c = 0;
        invLineListForCredit5[0].blng__UnitPrice__c = 11;            
        //database.update(invLineListForCredit5);
        allInvLineListForCredit.add(invLineListForCredit5[0]);
        
        database.update(allInvLineListForCredit);
        
        // Create Credit Note
        List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);
        creditNotes[0].blng__RelatedInvoice__c = invoiceListForCredit[0].id;
        creditNotes[0].QTB_Commercial_Credit__c = true;
        update creditNotes;
        System.debug('Test_creditNotes@@'+creditNotes);
        
        List<blng__CreditNoteLine__c> CreditNoteLine = new List<blng__CreditNoteLine__c>();
        
        //Insert -- subtotal & quantity not present, only invoice line
        blng__CreditNoteLine__c cnl1 = new blng__CreditNoteLine__c();
        cnl1.QTB_Account__c = accountList[0].Id;
        cnl1.blng__CreditNote__c = creditNotes[0].id;
        cnl1.QTB_Invoice__c = invoiceListForCredit[0].id;
        cnl1.QTB_InvoiceLine__c = invLineListForCredit3[0].id;
        cnl1.blng__Product__c = productList[0].Id;                        
        cnl1.blng__CalculateTax__c=false;
        cnl1.blng__TotalAmount__c = 10;
        // insert cnl1;
        
        //subtotal 
        blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
        cnl.QTB_Account__c = accountList[0].Id;
        cnl.blng__CreditNote__c = creditNotes[0].id;
        cnl.QTB_Invoice__c = invoiceListForCredit[0].id;
        cnl.QTB_InvoiceLine__c = invLineListForCredit1[0].id;
        cnl.blng__Product__c = productList[0].Id;
        //cnl.blng__Subtotal__c = 0; 
        cnl.QTB_Credit_Quantity__c = 1;
        cnl.blng__CalculateTax__c=false;
        cnl.blng__TotalAmount__c = 10;
        CreditNoteLine.add(cnl);
        
        //Insert -- subtotal = 0 & quantity = null
        blng__CreditNoteLine__c cnl2 = new blng__CreditNoteLine__c();
        cnl2.QTB_Account__c = accountList[0].Id;
        cnl2.blng__CreditNote__c = creditNotes[0].id;
        cnl2.QTB_Invoice__c = invoiceListForCredit[0].id;
        cnl2.QTB_InvoiceLine__c = invLineListForCredit2[0].id;
        cnl2.blng__Product__c = productList[0].Id;                        
        cnl2.blng__CalculateTax__c=false;
        //cnl2.blng__Subtotal__c = 0;  
        cnl2.QTB_Credit_Quantity__c = 1;
        cnl2.blng__TotalAmount__c = 10;
        CreditNoteLine.add(cnl2);
        
        //Insert -- subtotal = 0 & quantity != null
        blng__CreditNoteLine__c cnl3 = new blng__CreditNoteLine__c();
        cnl3.QTB_Account__c = accountList[0].Id;
        cnl3.blng__CreditNote__c = creditNotes[0].id;
        cnl3.QTB_Invoice__c = invoiceListForCredit[0].id;
        cnl3.QTB_InvoiceLine__c = invLineListForCredit1[0].id;
        cnl3.blng__Product__c = productList[0].Id;                        
        cnl3.blng__CalculateTax__c=false;
        //cnl3.blng__Subtotal__c = 0;  
        cnl3.QTB_Credit_Quantity__c = 1;
        cnl3.blng__TotalAmount__c = 10;
        CreditNoteLine.add(cnl3);
        
        //Insert -- CreditNoteLine for Bundle Header
        blng__CreditNoteLine__c cnl4 = new blng__CreditNoteLine__c();
        cnl4.QTB_Account__c = accountList[0].Id;
        cnl4.blng__CreditNote__c = creditNotes[0].id;
        cnl4.QTB_Invoice__c = invoiceListForCredit[0].id;
        cnl4.QTB_InvoiceLine__c = invLineListForCredit4[0].id;
        cnl4.blng__Product__c = productList[1].Id;                        
        cnl4.blng__CalculateTax__c=false;
        //cnl3.blng__Subtotal__c = 0;  
        cnl3.QTB_Credit_Quantity__c = 1;
        cnl3.blng__TotalAmount__c = 30;
        if(CreditNoteLine.size() > 0){
            insert CreditNoteLine;
        }
        Test.stopTest();        
    }
    
    static testMethod void testmethod1() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[1]) {
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            
            // handler.BeforeDelete(null);
            handler.AfterDelete(null);
            handler.AfterUndelete(null);
            // handler.AfterInsert(null);
            handler.AfterUpdate(null, null);
            QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_CNL);
            //handler.isDisabled();
            Test.stopTest();
            try{
                QTB_CNLHelper.updateCNL(null, null, null);
            }  
            catch (Exception e) {
                System.debug('testmethod1_Exception4@@'+ e.getMessage());
            }
            System.assertEquals(true, QTB_CNLTriggerHandler.throwExplicitException);
        }
    }
    
    static testmethod void testmethod2() {
        Test.startTest();
        List<blng__InvoiceLine__c> invLine = [Select id,blng__Product__c,
                                              blng__LegalEntity__c,
                                              blng__LegalEntity__r.blng__Country__c,
                                              blng__Subtotal__c,
                                              blng__TaxPercentageApplied__c,
                                              blng__Balance__c,
                                              blng__TaxRule__c,
                                              blng__TaxTreatment__c,
                                              blng__BillingRule__c,
                                              QTB_Unit_Price__c,
                                              blng__TotalAmount__c,
                                              blng__Quantity__c,
                                              QTB_Charge_Type__c From blng__InvoiceLine__c ];
        System.debug('testmethod2_invLine@@'+invLine);
        List<blng__CreditNoteLine__c> cnlList1=[select id,blng__Status__c,blng__Subtotal__c,QTB_Credit_Quantity__c,QTB_Invoice__c,QTB_InvoiceLine__r.blng__TotalAmount__c,QTB_InvoiceLine__c,blng__CalculateTax__c,QTB_InvoiceLine__r.blng__TaxPercentageApplied__c,QTB_Credit_Note_Type__c 
                                                from blng__CreditNoteLine__c
                                                where blng__Status__c != 'Posted' limit 1];
        System.debug('testmethod2_cnlList1@@'+cnlList1);
        sbqq.TriggerControl.disable();
        /*
        //Invoice Line, Subtotal & Quantity change
        cnlList1[0].QTB_InvoiceLine__c = invLine[0].id;
        cnlList1[0].QTB_Credit_Quantity__c = 4;
        cnlList1[0].blng__Subtotal__c = 44;
        // cnlList1[0].blng__CalculateTax__c = true;
        update cnlList1;
        
        //subtotal change 
        cnlList1[0].blng__Subtotal__c = 11;
        // cnlList1[0].blng__CalculateTax__c = true;
        update cnlList1;
        
        //invoice line change 
        cnlList1[0].QTB_InvoiceLine__c = invLine[0].id;
        // cnlList1[0].blng__CalculateTax__c = true;
        update cnlList1;
        
        //Quantity change
        cnlList1[0].QTB_Credit_Quantity__c = 2;
        // cnlList1[0].blng__CalculateTax__c = true;
        update cnlList1;
        
        //subtotal,qunatity change 
        cnlList1[0].blng__Subtotal__c = 33;
        cnlList1[0].QTB_Credit_Quantity__c = 3;
        //  cnlList1[0].blng__CalculateTax__c = true;
        update cnlList1;
        
        //Invoice Line, & Quantity change
        cnlList1[0].QTB_InvoiceLine__c = invLine[0].id;
        cnlList1[0].QTB_Credit_Quantity__c = 3;
        //   cnlList1[0].blng__CalculateTax__c = true;
        
        // update cnlList1;     
        cnlList1[0].blng__CalculateTax__c = false; 
        update cnlList1; */
        
        List<blng__CreditNote__c> cr = [Select Id, NAme,blng__Status__c From blng__CreditNote__c where blng__Status__c != 'Posted' ];
        cr[0].blng__Status__c = '';
        update cr[0];
        sbqq.TriggerControl.enable();
        //status changed
        cnlList1[0].blng__Status__c = '';   
        try {
            //update cnlList1[0];
            //Invoice Line, & Quantity change
            //cnlList1[0].QTB_InvoiceLine__c = invLine[1].id;  
            cnlList1[0].blng__CalculateTax__c = true; 
            update cnlList1[0]; 
        } catch (Exception e) {
            System.debug('testMethod2_Exception@@'+e.getMessage());
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }
    
    static testmethod void testMethod3(){
        Test.startTest();
        List<blng__InvoiceLine__c> invLine = [Select id,blng__Product__c,
                                              blng__LegalEntity__c,
                                              blng__LegalEntity__r.blng__Country__c,
                                              blng__Subtotal__c,
                                              blng__TaxPercentageApplied__c,
                                              blng__Balance__c,
                                              blng__TaxRule__c,
                                              blng__TaxTreatment__c,
                                              blng__BillingRule__c,
                                              QTB_Unit_Price__c,
                                              blng__TotalAmount__c,
                                              blng__Quantity__c,
                                              QTB_Charge_Type__c From blng__InvoiceLine__c ];
        System.debug('testMethod3'+invLine);
        List<blng__CreditNoteLine__c> cnlList1=[select id,blng__Status__c,blng__CreditNote__c,blng__CreditNote__r.QTB_IsReBill__c,blng__Subtotal__c,QTB_Credit_Quantity__c,QTB_Invoice__c,QTB_InvoiceLine__c,QTB_InvoiceLine__r.blng__TotalAmount__c,blng__CalculateTax__c,QTB_InvoiceLine__r.blng__TaxPercentageApplied__c,QTB_Credit_Note_Type__c 
                                                from blng__CreditNoteLine__c
                                                where blng__Status__c != 'Posted' limit 1];        
        
        //update invoice line... Quantity & subtotal both are same
        cnlList1[0].QTB_InvoiceLine__c = invLine[1].id;
        //cnlList1[0].QTB_Credit_Quantity__c = 4;
        //cnlList1[0].blng__Subtotal__c = 44;
        cnlList1[0].blng__CalculateTax__c = false;
        try{
            update cnlList1[0]; 
        }
        Catch(Exception e){
            System.debug('testMethod3_Exception@@'+e.getMessage());
        }
        
        Test.stopTest();
    }
    
    static testmethod void testMethod4(){
        Test.startTest();
        List<blng__CreditNoteLine__c> oldCNL = new List<blng__CreditNoteLine__c>();
        Map<id, blng__CreditNoteLine__c> oldMap = new Map<id, blng__CreditNoteLine__c>();
        List<blng__CreditNoteLine__c> cnlList1=[select id,blng__Status__c,blng__Subtotal__c,QTB_Credit_Quantity__c,QTB_Invoice__c,QTB_InvoiceLine__r.blng__TotalAmount__c,QTB_InvoiceLine__c,blng__CalculateTax__c,QTB_InvoiceLine__r.blng__TaxPercentageApplied__c,QTB_Credit_Note_Type__c 
                                                from blng__CreditNoteLine__c
                                                where blng__Status__c != 'Posted'];
        for(blng__CreditNoteLine__c cnl :cnlList1 ){
            oldCNL.add(cnl);
            oldMap.put(cnl.id,cnl);
        }
        try {
            QTB_CNLHelper.validateCNLDelete(oldCNL,oldMap);
            QTB_CNLHelper.CNL_checkRestrictedFields(oldCNL,oldMap,'QTB_Credit_Quantity__c');
            //  QTB_CNLHelper.testFunctionality();
            delete cnlList1;
        } catch (Exception e) {
            System.debug('testMethod4_Exception@@'+e.getMessage());
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
        QTB_CNLHelper.dummyCode();
        Test.stopTest();
    }
    
    static testmethod void testMethod5(){
        Test.startTest();
        List<blng__InvoiceLine__c> invLine = [Select id,Name,blng__Product__c, blng__LegalEntity__c,blng__LegalEntity__r.blng__Country__c,
                                              blng__Subtotal__c,blng__TaxPercentageApplied__c,blng__Balance__c,blng__TaxRule__c,blng__TaxTreatment__c,
                                              blng__BillingRule__c,QTB_Unit_Price__c,blng__TotalAmount__c,blng__Quantity__c,blng__Invoice__c,
                                              QTB_Taxable_Amount__c,blng__Product__r.Name,QTB_Charge_Type__c
                                              From blng__InvoiceLine__c  ];
        System.debug('testMethod5_invLine@@'+invLine);
        
        List<blng__CreditNoteLine__c> cnlList1=[select id,blng__Status__c,blng__CreditNote__c,blng__Subtotal__c,QTB_Credit_Quantity__c,QTB_Invoice__c,QTB_InvoiceLine__c,QTB_InvoiceLine__r.blng__TotalAmount__c,
                                                blng__CalculateTax__c,QTB_InvoiceLine__r.blng__TaxPercentageApplied__c,QTB_Credit_Note_Type__c,blng__InvoiceLine__r.blng__Product__c,
                                                blng__InvoiceLine__r.blng__Product__r.Name
                                                from blng__CreditNoteLine__c
                                                where blng__Status__c != 'Posted' limit 1];
        System.debug('testMethod5_cnlList1@@'+cnlList1);
        //update -- invoice line & subtotal change,
        //cnlList1[0].QTB_InvoiceLine__c = invLine[1].id;
        //cnlList1[0].blng__Subtotal__c = 5;
        cnlList1[0].blng__CalculateTax__c = false;
        //update cnlList1[0];
        
        Map<Id, List<SBQQ__ProductOption__c>> productToProductOptionsMap = new Map<Id, List<SBQQ__ProductOption__c>>();
        List<SBQQ__ProductOption__c> prdOptList = [Select Id, SBQQ__OptionalSKU__c, SBQQ__ConfiguredSKU__c From SBQQ__ProductOption__c ];
        System.debug('testMethod5_prdOptList@@'+prdOptList);
        List<SBQQ__ProductOption__c> prdOptList1 = new List<SBQQ__ProductOption__c>();
        for(SBQQ__ProductOption__c prd : prdOptList){
            prdOptList1.add(prd);
            productToProductOptionsMap.put(prd.SBQQ__OptionalSKU__c,prdOptList1); 
        }       
        
        Map<Id, List<blng__InvoiceLine__c>> invoiceIdToInvoiceLineMap = new Map<Id, List<blng__InvoiceLine__c>>();
        List<blng__InvoiceLine__c> invLineList = new List<blng__InvoiceLine__c>();
        system.debug('invLine' +invLine[0].id);
        for(blng__InvoiceLine__c invl : invLine){
            if(invl.QTB_Charge_Type__c=='Recurring'){
                invLineList.add(invl);
                invoiceIdToInvoiceLineMap.put(invl.blng__Invoice__c,invLineList); 
            }
        }
        try{
            System.debug('cnlList1@@'+cnlList1);
            System.debug('invLineList@@'+invLineList);
            if(invoiceIdToInvoiceLineMap.isEmpty()){
                invoiceIdToInvoiceLineMap.put(invLine[0].blng__Invoice__c,invLine); 
            }
            QTB_CNLHelper.checkBundleHeaderInvoiceLines(cnlList1[0].Id,cnlList1[0].blng__CreditNote__c, invLine[0],productToProductOptionsMap,invoiceIdToInvoiceLineMap);
        }Catch(Exception e){
            System.debug('testMethod5_Exception@@'+e.getMessage());
        }
        Test.stopTest();
    }
    
    static testmethod void testMethod6(){
        Test.startTest();
        List<blng__InvoiceLine__c> invLine = [Select id,blng__Product__c,
                                              blng__LegalEntity__c,
                                              blng__LegalEntity__r.blng__Country__c,
                                              blng__Subtotal__c,
                                              blng__TaxPercentageApplied__c,
                                              blng__Balance__c,
                                              blng__TaxRule__c,
                                              blng__TaxTreatment__c,
                                              blng__BillingRule__c,
                                              QTB_Unit_Price__c,
                                              blng__TotalAmount__c,
                                              blng__Quantity__c,
                                              QTB_Charge_Type__c From blng__InvoiceLine__c where QTB_Charge_Type__c ='Usage' ];
        System.debug('testMethod6_invLine@@'+invLine);
        
        List<blng__CreditNoteLine__c> cnlList1=[select id,blng__CreditNote__c,blng__Status__c,blng__Subtotal__c,QTB_Credit_Quantity__c,QTB_Invoice__c,QTB_InvoiceLine__c,QTB_InvoiceLine__r.blng__TotalAmount__c,blng__CalculateTax__c,QTB_InvoiceLine__r.blng__TaxPercentageApplied__c,QTB_Credit_Note_Type__c 
                                                from blng__CreditNoteLine__c
                                                where blng__Status__c != 'Posted' and QTB_InvoiceLine__r.QTB_Charge_Type__c ='Usage' limit 1];
        System.debug('testMethod6_cnlList1@@'+cnlList1);
        sbqq.TriggerControl.disable();
        /*
        //update -- invoice line & subtotal change,
        //cnlList1[0].QTB_InvoiceLine__c = invLine[0].id;
        //cnlList1[0].blng__Subtotal__c = 10;
        //cnlList1[0].QTB_Credit_Quantity__c = null;
        cnlList1[0].blng__CalculateTax__c = false;
        update cnlList1[0];
        
        //update -- invoice line & subtotal change,
        cnlList1[0].QTB_InvoiceLine__c = invLine[1].id;
        cnlList1[0].blng__Subtotal__c = 10;
        cnlList1[0].QTB_Credit_Quantity__c = 10;
        cnlList1[0].blng__CalculateTax__c = false;
        update cnlList1[0];*/
        sbqq.TriggerControl.enable();
        Test.stopTest();
        try{
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelper.validateCNLDelete(null,null);
        }  
        catch (Exception e) {
            System.debug('testmethod6_Exception@@'+ e.getMessage());
        }
        try{
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelper.CNL_checkRestrictedFields(null,null,'');
        }  
        catch (Exception e) {
            System.debug('testmethod6_Exception@@'+ e.getMessage());
        }
    }
    
    static testmethod void testMethod7(){
        Test.startTest();
        List<blng__InvoiceLine__c> invLine = [Select id,blng__Product__c,
                                              blng__LegalEntity__c,
                                              blng__LegalEntity__r.blng__Country__c,
                                              blng__Subtotal__c,
                                              blng__TaxPercentageApplied__c,
                                              blng__Balance__c,
                                              blng__TaxRule__c,
                                              blng__TaxTreatment__c,
                                              blng__BillingRule__c,
                                              QTB_Unit_Price__c,
                                              blng__TotalAmount__c,
                                              blng__Quantity__c,
                                              QTB_Charge_Type__c From blng__InvoiceLine__c ];
        System.debug('testMethod7_invLine@@'+invLine);
        List<blng__CreditNoteLine__c> cnlList1=[select id,blng__CreditNote__c,blng__Status__c,blng__Subtotal__c,QTB_Credit_Quantity__c,QTB_Invoice__c,QTB_InvoiceLine__c,QTB_InvoiceLine__r.blng__TotalAmount__c,blng__CalculateTax__c,QTB_InvoiceLine__r.blng__TaxPercentageApplied__c,QTB_Credit_Note_Type__c 
                                                from blng__CreditNoteLine__c
                                                where blng__Status__c != 'Posted' limit 1];
        System.debug('testMethod7_cnlList1@@'+cnlList1);
        sbqq.TriggerControl.disable();
        //update
        //cnlList1[0].QTB_InvoiceLine__c = invLine[0].id;
        //cnlList1[0].QTB_Credit_Quantity__c = 4;
        //cnlList1[0].blng__Subtotal__c = 44;
        cnlList1[0].blng__CalculateTax__c = false;
        update cnlList1[0];
        sbqq.TriggerControl.enable();
        Test.stopTest();
        
        try{
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelper.updateRevenueAllocationOnCreditNoteLine(null,null);
        }  
        catch (Exception e) {
            System.debug('testmethod1_Exception3@@'+ e.getMessage());
        }
    } 
    
   /* static testMethod void testMethod8(){
        Test.startTest();
        List<blng__InvoiceLine__c> invLine = [Select id,blng__Product__c,
                                              blng__LegalEntity__c,
                                              blng__LegalEntity__r.blng__Country__c,
                                              blng__Subtotal__c,
                                              blng__TaxPercentageApplied__c,
                                              blng__Balance__c,
                                              blng__TaxRule__c,
                                              blng__TaxTreatment__c,
                                              blng__BillingRule__c,
                                              QTB_Unit_Price__c,
                                              blng__TotalAmount__c,
                                              blng__Quantity__c,
                                              QTB_Charge_Type__c From blng__InvoiceLine__c ];
        System.debug('testMethod8_invLine@@'+invLine);
        List<blng__CreditNoteLine__c> cnlList1=[select id,blng__Status__c,blng__Subtotal__c,QTB_Credit_Quantity__c,QTB_Invoice__c,QTB_InvoiceLine__c,QTB_InvoiceLine__r.blng__TotalAmount__c,blng__CalculateTax__c,QTB_InvoiceLine__r.blng__TaxPercentageApplied__c,QTB_Credit_Note_Type__c 
                                                from blng__CreditNoteLine__c
                                                where blng__Status__c != 'Posted' limit 1];
        System.debug('testMethod8_cnlList1@@'+cnlList1);
        sbqq.TriggerControl.disable();
        //update -- invoice line & subtotal change, and subtotal is 0
        cnlList1[0].QTB_InvoiceLine__c = invLine[0].id;
        cnlList1[0].blng__Subtotal__c = 0;
        cnlList1[0].blng__CalculateTax__c = false;
        update cnlList1[0];
        sbqq.TriggerControl.enable();        
        /*     try {
QTB_CNLTriggerHandler.throwExplicitException = true;
QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
QTB_CNLHelper.createCNLforBundle(null,null,null,null);

} catch (Exception e) {
System.debug('testmethod1_Exception1@@'+ e.getMessage());
}        
        Test.stopTest();
    } */
    
    static testmethod void testmethod9(){   
        Test.startTest();
        List<blng__InvoiceLine__c> invLine = [Select id,blng__Product__c,
                                              blng__LegalEntity__c,
                                              blng__LegalEntity__r.blng__Country__c,
                                              blng__Subtotal__c,
                                              blng__TaxPercentageApplied__c,
                                              blng__Balance__c,
                                              blng__TaxRule__c,
                                              blng__TaxTreatment__c,
                                              blng__BillingRule__c,
                                              QTB_Unit_Price__c,
                                              blng__TotalAmount__c,
                                              blng__Quantity__c,blng__Invoice__c,
                                              QTB_Charge_Type__c From blng__InvoiceLine__c where QTB_Charge_Type__c ='Usage' ];
        System.debug('testmethod9_invLine@@'+invLine);
        List<blng__CreditNoteLine__c> cnlList1=[select id,blng__Status__c,blng__Subtotal__c,QTB_Credit_Quantity__c,QTB_Invoice__c,
                                                QTB_InvoiceLine__r.blng__TotalAmount__c,QTB_InvoiceLine__c,blng__CalculateTax__c,QTB_InvoiceLine__r.blng__TaxPercentageApplied__c,QTB_Credit_Note_Type__c,
                                                QTB_Account__c,QTB_On_Account_Credit_Note_Line__c
                                                from blng__CreditNoteLine__c
                                                where blng__Status__c != 'Posted'and QTB_InvoiceLine__r.QTB_Charge_Type__c ='Usage'  limit 1];
        System.debug('testmethod9_cnlList1@@'+cnlList1);        
        sbqq.TriggerControl.disable();
        /*
        //Quantity change
        //cnlList1[0].QTB_Credit_Quantity__c = 2;
        //  cnlList1[0].blng__CalculateTax__c = true;
        update cnlList1;
        
        //subtotal,qunatity change 
        cnlList1[0].blng__Subtotal__c = 33;
        //cnlList1[0].QTB_Credit_Quantity__c = 3;
        //  cnlList1[0].blng__CalculateTax__c = true;
        update cnlList1;
        
        //Invoice Line, & Quantity change
        cnlList1[0].QTB_InvoiceLine__c = invLine[0].id;
        cnlList1[0].QTB_Credit_Quantity__c = 3;
        // cnlList1[0].blng__CalculateTax__c = true;
        
        // update cnlList1;  
        cnlList1[0].blng__CalculateTax__c = false; 
        update cnlList1; 
        
        
        List<blng__CreditNote__c> cr = [Select Id, NAme,blng__Status__c From blng__CreditNote__c where blng__Status__c != 'Posted' and QTB_Credit_Note_Type__c = null ];
        cr[0].blng__Status__c = '';
        update cr;
        
        //status changed
        //cnlList1[0].blng__Status__c = 'Posted';   
        //update cnlList1;
        
        //Invoice Line, & Quantity change
        cnlList1[0].QTB_InvoiceLine__c = invLine[1].id;  
        //  cnlList1[0].blng__CalculateTax__c = true; 
        update cnlList1; */
        sbqq.TriggerControl.enable();
        Set<ID> invoiceIds = new Set<Id>();
        Set<ID> invoiceLineId = new Set<Id>();
        List<blng__CreditNoteLine__c> newCnl = new List<blng__CreditNoteLine__c>();
        Map<id, blng__CreditNoteLine__c> oldMap = new Map<id, blng__CreditNoteLine__c>();
        
        invoiceIds.add(invLine[0].blng__Invoice__c);
        invoiceLineId.add(invLine[0].Id);
        newCnl.add(cnlList1[0]);
        oldMap.put(cnlList1[0].Id,cnlList1[0]);
        
        //Set<ID> invoiceIds,Set<ID> invoiceLineId,List<blng__CreditNoteLine__c> newCnl,Map<id, blng__CreditNoteLine__c> oldMap
        QTB_CNLTriggerHandler.throwExplicitException = false;
        QTB_CNLHelper.createCNLforBundle(invoiceIds,invoiceLineId,newCnl,oldMap);
        Test.stopTest();
        try {
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelper.checkBundleHeaderInvoiceLines(null,null,null,null,null);            
        } catch (Exception e) {
            System.debug('testmethod9_Exception1@@'+ e.getMessage());
        }
        
        try {
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelper.createCNLforBundle(null,null,null,null);            
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
    }
    
    static testmethod void testmethod10(){
        Test.startTest();
        Id recordTypeValue;
        string recordType = 'Standard Account';
        ID StandardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;            
        recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        List<Account> accountList = new List<Account>();
        Account a = new Account();
        a.Name = 'Test';
        a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
        if (String.isNotBlank(recordType) && String.isNotEmpty(recordType)) {
            a.RecordTypeId = recordTypeValue;
            if (('Billing Account').equals(recordType)) {
                a.QTB_Create_Parent_Billing_Account__c = true;
            }
        } else {
            a.RecordTypeId = StandardrecordId;
        }
        a.Name = 'Test Account';
        a.BillingCountry = 'India';
        a.BillingPostalCode = '11209';
        a.BillingState = 'TN';
        a.Registration_Number__c = 'Reg';
        a.ShippingCountry = 'India';
        a.QTB_Legal_Entity_Country__c='India';
        a.CurrencyIsoCode = 'INR';
        a.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        a.QTB_SITAD__c = true;
        accountList.add(a);
        if (!accountList.isEmpty()) {
            insert accountList;
        }
        List<Product2> productList = [Select Id from Product2];
        // Create Credit Note
        blng__CreditNote__c creditNote = new blng__CreditNote__c();
        creditNote.blng__Account__c = accountList[0].Id;
        creditNote.blng__CreditNoteDate__c = date.today();
        creditNote.QTB_Reason_Code__c = 'Legacy Credit';
        creditNote.blng__Status__c = 'Draft';
        creditNote.CurrencyIsoCode = 'EUR';
        creditNote.QTB_On_Account_Credit__c = true;
        insert creditNote;
        
        //Insert -- CreditNoteLine for Bundle Header
        blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
        cnl.QTB_Account__c = accountList[0].Id;
        cnl.blng__CreditNote__c = creditNote.id;
        cnl.blng__Product__c = productList[0].Id;
        cnl.blng__Subtotal__c = 1;
        cnl.blng__CalculateTax__c=false;
        insert cnl;
        Test.stopTest();
    }  
    
    static testmethod void testmethod11(){
        Test.startTest();
        Id recordTypeValue;
        string recordType = 'Standard Account';
        ID StandardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;            
        recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        List<Account> accountList = new List<Account>();
        Account a = new Account();
        a.Name = 'Test';
        a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
        if (String.isNotBlank(recordType) && String.isNotEmpty(recordType)) {
            a.RecordTypeId = recordTypeValue;
            if (('Billing Account').equals(recordType)) {
                a.QTB_Create_Parent_Billing_Account__c = true;
            }
        } else {
            a.RecordTypeId = StandardrecordId;
        }
        a.Name = 'Test Account';
        a.BillingCountry = 'India';
        a.BillingPostalCode = '11209';
        a.BillingState = 'TN';
        a.Registration_Number__c = 'Reg';
        a.ShippingCountry = 'India';
        a.QTB_Legal_Entity_Country__c='India';
        a.CurrencyIsoCode = 'INR';
        a.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        a.QTB_SITAD__c = true;
        accountList.add(a);
        if (!accountList.isEmpty()) {
            insert accountList;
        }
        List<Product2> productList = [Select Id from Product2];
        // Create Credit Note
        blng__CreditNote__c creditNote = new blng__CreditNote__c();
        creditNote.blng__Account__c = accountList[0].Id;
        creditNote.blng__CreditNoteDate__c = date.today();
        creditNote.QTB_Reason_Code__c = 'Legacy Credit';
        creditNote.blng__Status__c = 'Draft';
        creditNote.CurrencyIsoCode = 'EUR';
        creditNote.QTB_On_Account_Credit__c = true;
        insert creditNote;
        
        //Insert -- CreditNoteLine for Bundle Header
        blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
        cnl.QTB_Account__c = accountList[0].Id;
        cnl.blng__CreditNote__c = creditNote.id;
        cnl.blng__Product__c = productList[0].Id; 
        cnl.blng__Subtotal__c = 1;
        cnl.blng__CalculateTax__c=true;
        insert cnl;
        blng__TaxRule__c Tx =[select id,name from blng__TaxRule__c where name='No Tax Rule' limit 1];
        //Quantity change
        //cnl.QTB_Credit_Quantity__c = 2;
        //cnl.blng__TaxRule__c = tx.id;
        cnl.blng__TaxStatus__c = 'Completed';
        cnl.QTB_Invoice__c = Null;
        //  cnlList1[0].blng__CalculateTax__c = true;
        update cnl;
        Test.stopTest();
    }
    static testmethod void testmethod12(){
        QTB_CNLTriggerHandler.throwExplicitException = true;
        try{
            QTB_CNLHelper.validateCNLDelete(null,null);
        }catch(exception e){
            system.debug('validateCNLDelete method exception -'+e.getMessage());
        }
        try{
            QTB_CNLHelper.updateRevenueAllocationOnCreditNoteLine(null,null);
        }catch(exception e){
            system.debug('updateRevenueAllocationOnCreditNoteLine method exception -'+e.getMessage());
        }
        try{
            QTB_CNLHelper.updateRevenueAllocationOnCreditNoteLine(null,null);
        }catch(exception e){
            system.debug('updateRevenueAllocationOnCreditNoteLine method exception -'+e.getMessage());
        }
        try{
            QTB_CNLHelper.createCNLforBundle(null,null,null,null);
        }catch(exception e){
            system.debug('createCNLforBundle method exception -'+e.getMessage());
        }
        
    }
    
    /*static testmethod void testmethod12(){   
        Test.startTest();
        List<blng__InvoiceLine__c> invLine = [Select id,blng__Product__c,
                                              blng__LegalEntity__c,
                                              blng__LegalEntity__r.blng__Country__c,
                                              blng__Subtotal__c,
                                              blng__TaxPercentageApplied__c,
                                              blng__Balance__c,
                                              blng__TaxRule__c,
                                              blng__TaxTreatment__c,
                                              blng__BillingRule__c,
                                              QTB_Unit_Price__c,
                                              blng__TotalAmount__c,
                                              blng__Quantity__c,blng__Invoice__c,
                                              QTB_Charge_Type__c From blng__InvoiceLine__c where QTB_Charge_Type__c ='Usage' ];
        System.debug('testmethod9_invLine@@'+invLine);
        List<blng__CreditNoteLine__c> cnlList1=[select id,blng__Status__c,blng__Subtotal__c,QTB_Credit_Quantity__c,QTB_Invoice__c,
                                                QTB_InvoiceLine__r.blng__TotalAmount__c,QTB_InvoiceLine__c,blng__CalculateTax__c,QTB_InvoiceLine__r.blng__TaxPercentageApplied__c,QTB_Credit_Note_Type__c,
                                                QTB_Account__c,QTB_On_Account_Credit_Note_Line__c
                                                from blng__CreditNoteLine__c
                                                where blng__Status__c != 'Posted'  and QTB_InvoiceLine__r.QTB_Charge_Type__c ='Usage'  limit 1];
        System.debug('testmethod9_cnlList1@@'+cnlList1);        
        sbqq.TriggerControl.disable();
        //Quantity change
        cnlList1[0].QTB_Credit_Quantity__c = 2;
        //  cnlList1[0].blng__CalculateTax__c = true;
        update cnlList1;
        
        //subtotal,qunatity change 
        cnlList1[0].blng__Subtotal__c = 33;
        cnlList1[0].QTB_Credit_Quantity__c = 3;
        //  cnlList1[0].blng__CalculateTax__c = true;
        update cnlList1;
        
        //Invoice Line, & Quantity change
        cnlList1[0].QTB_InvoiceLine__c = invLine[0].id;
        cnlList1[0].QTB_Credit_Quantity__c = 3;
        // cnlList1[0].blng__CalculateTax__c = true;
        
        // update cnlList1;  
        cnlList1[0].blng__CalculateTax__c = false; 
        update cnlList1; 
        sbqq.TriggerControl.disable();
        List<blng__CreditNote__c> cr = [Select Id, NAme,blng__Status__c From blng__CreditNote__c where blng__Status__c != 'Posted' and QTB_Credit_Note_Type__c = null ];
        cr[0].blng__Status__c = 'Posted';
        //QTB_TestDataFactory.createBypassSetting('blng__CreditNote__c');
        update cr;
        blng__TaxRule__c Tx =[select id,name from blng__TaxRule__c where name='No Tax Rule' limit 1];
        sbqq.TriggerControl.disable();
        //Quantity change
        cnlList1[0].QTB_InvoiceLine__c = invLine[1].id;  
        cnlList1[0].QTB_Credit_Quantity__c = 2;
        cnlList1[0].blng__TaxRule__c = tx.id;
        cnlList1[0].blng__TaxStatus__c = 'Completed';
        //  cnlList1[0].blng__CalculateTax__c = true;
        update cnlList1; 
        
        Set<ID> invoiceIds = new Set<Id>();
        Set<ID> invoiceLineId = new Set<Id>();
        List<blng__CreditNoteLine__c> newCnl = new List<blng__CreditNoteLine__c>();
        Map<id, blng__CreditNoteLine__c> oldMap = new Map<id, blng__CreditNoteLine__c>();
        
        invoiceIds.add(invLine[0].blng__Invoice__c);
        invoiceLineId.add(invLine[0].Id);
        newCnl.add(cnlList1[0]);
        oldMap.put(cnlList1[0].Id,cnlList1[0]);
        
        //Set<ID> invoiceIds,Set<ID> invoiceLineId,List<blng__CreditNoteLine__c> newCnl,Map<id, blng__CreditNoteLine__c> oldMap
        QTB_CNLTriggerHandler.throwExplicitException = false;
        QTB_CNLHelper.createCNLforBundle(invoiceIds,invoiceLineId,newCnl,oldMap);
        Test.stopTest();
        sbqq.TriggerControl.enable();
        try {
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelper.checkBundleHeaderInvoiceLines(null,null,null,null,null);            
        } catch (Exception e) {
            System.debug('testmethod12_Exception1@@'+ e.getMessage());
        }
        try {
            QTB_CNLTriggerHandler.throwExplicitException = true;
            QTB_CNLTriggerHandler handler = new QTB_CNLTriggerHandler();
            QTB_CNLHelper.createCNLforBundle(null,null,null,null);            
        } catch (Exception e) {
            System.debug('testmethod12_Exception1@@'+ e.getMessage());
        }
        try {
            List<blng__CreditNoteLine__c> cnlList2=[select id From blng__CreditNoteLine__c limit 1];
            QTB_CNLHelper.validate_CNL_Subtotal(cnlList2);            
        } catch (Exception e) {
            System.debug('testmethod12_Exception1@@'+ e.getMessage());
        }
    }*/
}