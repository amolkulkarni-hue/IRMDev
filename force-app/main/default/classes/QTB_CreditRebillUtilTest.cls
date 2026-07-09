/*****************************************************************************************************
* Test Class    : QTB_CreditRebillUtilTest
* Author        : IRM/Virtusa
* Purpose       : This test class for to cover all sceanrio of QTB_CreditRebillUtil apex class
* Requirement   : 
* Change History:  09/14/2022
* Developer        Date             Description
* -------------------------------------------------------------------------------------------
* Shailesh     09/14/2022      Gitlab US #9256 Credit & Rebill
*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_CreditRebillUtilTest {
    @testSetup
    static void setup() {
        String userCurrency = System.UserInfo.getDefaultCurrency();
        Credit_ReBill_InvoiceSchedulerValidation__c invSchCust = new Credit_ReBill_InvoiceSchedulerValidation__c();
        invSchCust.Name = 'Canada-45000';
        invSchCust.isRunning__c = true;
        invSchCust.Date_Time__c = System.now();
        insert invSchCust;
        
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');       
        
        List<product2> product = new List<Product2>();
        Product2 p1 = new Product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.blng__BillingRule__c = billingRule.id;
        p1.blng__RevenueRecognitionRule__c = revenueRule.id;
        p1.blng__TaxRule__c = taxRule.id;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        product.add(p1);
        
        Database.insert(product);
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
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
        insert new ProductConsumptionSchedule(ConsumptionScheduleId = consumption.Id,ProductId = product[0].Id);   
        
        blng__LegalEntity__c CanadaEntity = QTB_TestDataFactory.createLegalEntity('Canada');
        
        //Account
        List<Account> accountList = new List<Account>();
        
        Account billAcc = new Account();
        billAcc.Name = 'Test Billing Account';
        billAcc.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
        billAcc.QTB_Create_Parent_Billing_Account__c = true;
        billAcc.BillingCountry = 'India';
        billAcc.BillingPostalCode = '11209';
        billAcc.BillingState = 'TN';
        billAcc.Registration_Number__c = 'Reg';
        billAcc.ShippingCountry = 'India';
        billAcc.QTB_Legal_Entity_Country__c='Canada';
        billAcc.QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
        billAcc.CurrencyISOCode = userCurrency;
        billAcc.QTB_SITAD__c = true;
        //billAcc.IM_Hierarchy_Level__c = 'Billing Account';
        billAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Standard Account').getRecordTypeId();
        billAcc.IM_Hierarchy_Level__c = 'Sales (Site)';
        billAcc.QTB_Contract_Entity__c = CanadaEntity.id;
        accountList.add(billAcc);
        
        Database.insert(accountList);
        
        //Legal Entity
        blng__LegalEntity__c USEntity = new blng__LegalEntity__c();
        USEntity.Name = 'Iron Mountain Information Management, LLC';
        USEntity.blng__Active__c = true;
        USEntity.blng__Country__c = 'United States';
        USEntity.QTB_Type__c = 'Contract';
        //indiaEntity.QTB_Legal_Entity_Number__c = '45000';
		USEntity.QTB_Tax_Applicability__c =	'Product Based';        
        insert USEntity;
        
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = userCurrency;
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';  
        //im.Active__c = true;//billing country criteria not match issue getting
        insert im;
        
        //opportunity
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
         //oppList[0].Legal_Entity__c = USEntity.id;
         opp.Billing_Country__c = im.id;
         opp.CurrencyISOCode = userCurrency;
         oppList.add(opp);
         database.insert(oppList);
        
        //Quote      
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Opportunity2__c = oppList[0].id;
        quote.SBQQ__Account__c = accountList[0].id;
        quote.SBQQ__Type__c = QTB_Constants.QUOTE_TYPE_STANDARD;
        quote.SBQQ__Status__c = 'Draft';
        quote.SBQQ__QuoteLanguage__c = 'English';
        quote.SBQQ__ExpirationDate__c = date.today();
        quote.SBQQ__Primary__c = true;
        quote.SBQQ__PrimaryContact__c = null;
        quote.SBQQ__StartDate__c = date.today();
        quote.CurrencyISOCode = userCurrency;
        quoteList.add(quote);
        
       // Database.insert(quoteList);
        
        
        //QuoteLineGroup   
       // List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //Quote Line
        //List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
        
        //Parent & Rebill Invoices - Order         
        List<Order> orderList = new List<Order>();
        
        //Parent Invoice - Order 
        Order parentOrders = new Order();
       // parentOrders.SBQQ__Quote__c = quoteList[0].Id;
        parentOrders.AccountId = accountList[0].id;
        parentOrders.blng__BillingDayOfMonth__c = '1';
        parentOrders.EffectiveDate = Date.today().addDays(5);
        parentOrders.Status = QTB_Constants.DRAFT_STATUS;
        parentOrders.Pricebook2Id = pricebookId;
        parentOrders.blng__InvoiceBatch__c = 'Denmark-26th';
        parentOrders.recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        parentOrders.CurrencyIsoCode=userCurrency;
        parentOrders.QTB_Legal_Entity_Country__c ='Denmark';
        orderList.add(parentOrders);
        
        //Rebill Invoice - Order
        Order rebillOrders = new Order();
        //rebillOrders.SBQQ__Quote__c = quoteList[0].Id;
        rebillOrders.AccountId = accountList[0].id;
        rebillOrders.blng__BillingDayOfMonth__c = '1';
        rebillOrders.EffectiveDate = Date.today().addDays(5);
        rebillOrders.Status = QTB_Constants.DRAFT_STATUS;
        rebillOrders.Pricebook2Id = pricebookId;
        rebillOrders.blng__InvoiceBatch__c = 'Denmark-26th';
        rebillOrders.recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        rebillOrders.CurrencyIsoCode=userCurrency;
        rebillOrders.QTB_OrderCategory__c = 'Rebill';
        rebillOrders.QTB_Legal_Entity_Country__c ='Denmark';
        orderList.add(rebillOrders);
        
        Database.insert(orderList);
        
        SBQQ.TriggerControl.disable();
        
        //Parent,Rebill Invoices - Order Product list
        List<OrderItem> orderItemList = new  List<OrderItem>();
        
        //Parent Invoice - Order Product
        OrderItem parentOrderItem = new OrderItem();
        parentOrderItem.OrderId = orderList[0].Id;
        parentOrderItem.Quantity = 2.00;
        parentOrderItem.UnitPrice = 12.00;
        //parentOrderItem.SBQQ__QuoteLine__c = quoteLinesList[0].id;
        parentOrderItem.PricebookEntryId = standardPrice.Id;
        parentOrderItem.SBQQ__ChargeType__c = 'One-Time';
        parentOrderItem.product2id = product[0].Id;
        parentOrderItem.SBQQ__Activated__c = true;
        parentOrderItem.blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').id;
        parentOrderItem.blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').id;
        parentOrderItem.blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id;
        orderItemList.add(parentOrderItem);      
        
        //Rebill Invoice - Order Product
        OrderItem rebillOrderItem = new OrderItem();
        rebillOrderItem.OrderId = orderList[0].Id;
        rebillOrderItem.Quantity = 2.00;
        rebillOrderItem.UnitPrice = 12.00;
        //rebillOrderItem.SBQQ__QuoteLine__c = quoteLinesList[0].id;
        rebillOrderItem.PricebookEntryId = standardPrice.Id;
        rebillOrderItem.SBQQ__ChargeType__c = 'One-Time';
        rebillOrderItem.product2id = product[0].Id;
        rebillOrderItem.SBQQ__Activated__c = true;
        rebillOrderItem.blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').id;
        rebillOrderItem.blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').id;
        rebillOrderItem.blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id;
        orderItemList.add(rebillOrderItem);   
        
        database.insert(orderItemList);
        
        //Parent Invoice  
        //Test.startTest();  
        Metadata_Activation_Settings__c cust = new Metadata_Activation_Settings__c();
        cust.SObject_API_Name__c = 'blng__Invoice__c';
        cust.Disable_Trigger__c = true;
        insert cust;                   
        List<blng__Invoice__c> parentInvoiceList = QTB_TestDataFactory.createInvoices(accountList); 
        parentInvoiceList[0].blng__InvoiceDate__c = System.today();    
        parentInvoiceList[0].blng__InvoiceDate__c = System.today();
        parentInvoiceList[0].QTB_Invoice_Type__c = 'New'; 
        parentInvoiceList[0].CurrencyIsoCode = userCurrency;
        parentInvoiceList[0].QTB_Case_Number__c = 'test';
        parentInvoiceList[0].QTB_Purchase_Order__c = 'test';
        parentInvoiceList[0].QTB_Site_Number__c = 'test';
        parentInvoiceList[0].blng__InvoiceStatus__c = 'Posted';
        database.update(parentInvoiceList);
   
        //Rebill Invoice                       
        List<blng__Invoice__c> rebillInvoiceList1 = QTB_TestDataFactory.createInvoices(accountList);       
        rebillInvoiceList1[0].blng__InvoiceDate__c = System.today();    
        rebillInvoiceList1[0].blng__InvoiceDate__c = System.today();
        rebillInvoiceList1[0].QTB_Invoice_Type__c = 'ReBill';
        //rebillInvoiceList1[0].QTB_Rebill_Type__c = 'Split';
        rebillInvoiceList1[0].QTB_Parent_Invoice__c = parentInvoiceList[0].id;  
        rebillInvoiceList1[0].blng__InvoiceStatus__c = 'Draft';
        rebillInvoiceList1[0].CurrencyIsoCode=userCurrency;
        database.update(rebillInvoiceList1);
        /*
        //Product
        List<product2> productList = new List<product2>();
        //Product1 -- usage
        product2 p11 = new product2();
        p11.Name = 'Test Product11';
        p11.isActive = true;
        p11.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p11.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p11);        
        insert productList;
        
        //IM Country
        IM_Country__c imc = new IM_Country__c();
        imc.Name = 'United States';
        imc.CurrencyIsoCode = 'USD';
        imc.Region__c = 'North America';
        imc.AlternativeNames__c = 'United States';
        imc.Iso31662Code__c ='US';
        imc.Iso31663Code__c ='USA';        
        insert imc;*/
        
        QTB_Bill_Code_Product_Lookup__c productLookup = new QTB_Bill_Code_Product_Lookup__c(
            QTB_Source_Bill_Code__c = 'VALID_CODE',
            QTB_Country__c = im.Id,
            QTB_Product2__c = product[0].id
        );
        insert productLookup;
        
        //  Test.startTest();
        //Parent Invoice Usage Summary
        List<blng__UsageSummary__c> parentInvUsageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList[0],orderItemList[0]);
        blng__UsageSummary__c usagesummary = parentInvUsageSum[0];        
        usagesummary.blng__Status__c = 'Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary.blng__Subtotal__c = 100;
        usagesummary.blng__TotalQuantity__c = 10;
        usagesummary.blng__PreratedQuantity__c = 20;
        usagesummary.blng__UnbilledQuantity__c = 1;
        usagesummary.blng__UnitPrice__c = 400;
        usagesummary.blng__PreratedAmount__c = 22;
        usagesummary.blng__Invoice__c = parentInvoiceList[0].id; 
        usagesummary.CurrencyIsoCode = userCurrency;
        database.update(usagesummary);
        
        //Rebill Invoice Usage Summary
        List<blng__UsageSummary__c> rebillInvUsageSum1 = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList[1],orderItemList[1]);
        blng__UsageSummary__c usagesummary1 = rebillInvUsageSum1[0];        
        usagesummary1.blng__Status__c = 'Queued For Invoice';
        usagesummary1.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary1.blng__Subtotal__c = 100;
        usagesummary1.blng__TotalQuantity__c = 10;
        usagesummary1.blng__PreratedQuantity__c = 20;
        usagesummary1.blng__UnbilledQuantity__c = 1;
        usagesummary1.blng__UnitPrice__c = 400;
        usagesummary1.blng__PreratedAmount__c = 22;
        usagesummary1.blng__Invoice__c = rebillInvoiceList1[0].id; 
        usagesummary1.CurrencyIsoCode = userCurrency;
        database.update(usagesummary1);
        
        //Parent Invoice Usage
        Test.startTest();
        List<blng__Usage__c> parentInvUageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
        parentInvUageList[0].QTB_System_Generated__c = true;
        parentInvUageList[0].blng__PreratedAmount__c = 100;
        parentInvUageList[0].blng__PreratedQuantity__c = 10;
        parentInvUageList[0].QTB_Start_Date_MRC__c = Date.newInstance(2022,03,01);
        parentInvUageList[0].QTB_end_Date_MRC__c = Date.newInstance(2022,31,01); 
        parentInvUageList[0].blng__UsageSummary__c = usagesummary.id;
        parentInvUageList[0].CurrencyIsoCode = userCurrency;
        parentInvUageList[0].QTB_Product_Identifier_1__c =  productLookup.id;
        database.update(parentInvUageList);
        
        //Rebill Invoice Usage
        List<blng__Usage__c> rebillInvUsgList1 = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary1);
        rebillInvUsgList1[0].QTB_System_Generated__c = true;
        rebillInvUsgList1[0].blng__PreratedAmount__c = 100;
        rebillInvUsgList1[0].blng__PreratedQuantity__c = 10;
        rebillInvUsgList1[0].QTB_Start_Date_MRC__c = Date.newInstance(2022,03,01);
        rebillInvUsgList1[0].QTB_end_Date_MRC__c = Date.newInstance(2022,31,01); 
        rebillInvUsgList1[0].blng__UsageSummary__c = usagesummary1.id;
        rebillInvUsgList1[0].CurrencyIsoCode = userCurrency;
        rebillInvUsgList1[0].QTB_Product_Identifier_1__c =  productLookup.id;
        database.update(rebillInvUsgList1);
        
        //Invoice Scheduler
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'test';
        schedule.blng__Type__c = 'Once';
        schedule.blng__InvoiceBatches__c = 'Rebill Run';
        schedule.CurrencyIsoCode = userCurrency;
        schedule.blng__StartDateTime__c = System.now();
        schedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        schedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
        schedule.QTB_Legal_Entity__c = USEntity.id;
        insert schedule;
        
        //Invoice Run
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__InvoiceScheduler__c = schedule.id;
        invoiceRun.blng__Status__c = 'Started';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2021-09-01');
        insert invoiceRun;
        
        //Tax Integration
        blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
        taxIntegration.blng__TaxEngine__c = 'Standard';
        taxIntegration.blng__Active__c = true;
        database.insert(taxIntegration);
        
        //Tax Treatment
        blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
        blngTax.blng__TaxLegalEntity__c = USEntity.id;
        blngTax.blng__TaxIntegration__c = taxIntegration.id;
        blngTax.blng__TaxRule__c = taxRule.id;
        blngTax.blng__TaxCode__c = 'STD-CGST';
        database.insert(blngTax);
        
        //Tax Rate
        blng__TaxRate__c taxRate = new blng__TaxRate__c();
        taxRate.blng__LegalEntity__c = USEntity.id;
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
        database.insert(taxRate);
        
        //Parent InvoiceLine              
        //List<blng__InvoiceLine__c> parentInvLineList = QTB_TestDataFactory.createInvoiceLine(1,parentInvoiceList,product);
        blng__InvoiceLine__c parentInvLineList = new blng__InvoiceLine__c();
        parentInvLineList.Name = product[0].Name;
        parentInvLineList.blng__Invoice__c = parentInvoiceList[0].Id;
        parentInvLineList.blng__Product__c = product[0].Id;
        parentInvLineList.blng__InvoiceLineStatus__c = 'Draft';
        parentInvLineList.blng__Quantity__c = 10;
        parentInvLineList.blng__UnitPrice__c = 5;
        parentInvLineList.blng__TaxPercentageApplied__c = 24;
        parentInvLineList.blng__OrderProduct__c = orderItemList[0].id;
        parentInvLineList.blng__UsageSummary__c = usagesummary.id;
        parentInvLineList.blng__InvoiceLineStatus__c = 'Posted';
        parentInvLineList.blng__TaxAmount__c = 50;
        parentInvLineList.blng__TaxCountry__c = 'India';
        parentInvLineList.blng__TaxState__c = 'TN';
        parentInvLineList.blng__TaxCity__c = 'Chennai';
        parentInvLineList.blng__TaxZipCode__c = '500032';
        parentInvLineList.blng__TaxTreatment__c = blngTax.id;
        parentInvLineList.blng__LegalEntity__c = USEntity.id;
        parentInvLineList.blng__Subtotal__c = 5000;
        parentInvLineList.blng__TotalAmount__c = 1000;
        parentInvLineList.blng__TaxStatus__c = 'Completed';
        parentInvLineList.CurrencyIsoCode = userCurrency;
        database.insert(parentInvLineList);
        
        //RebillInvoiceLine
        //List<blng__InvoiceLine__c> rebillInvLineList1 = QTB_TestDataFactory.createInvoiceLine(1,rebillInvoiceList1,product);
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = product[0].Name;
        invoiceLine.blng__Invoice__c = rebillInvoiceList1[0].Id;
        invoiceLine.blng__Product__c = product[0].Id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;
        invoiceLine.blng__TaxPercentageApplied__c = 24;
        invoiceLine.blng__OrderProduct__c = orderItemList[1].id;
        invoiceLine.blng__UsageSummary__c = usagesummary1.id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
        invoiceLine.blng__TaxAmount__c = 50;
        invoiceLine.blng__TaxCountry__c = 'India';
        invoiceLine.blng__TaxState__c = 'TN';
        invoiceLine.blng__TaxCity__c = 'Chennai';
        invoiceLine.blng__TaxZipCode__c = '500032';
        invoiceLine.blng__TaxTreatment__c = blngTax.id;
        invoiceLine.blng__LegalEntity__c = USEntity.id;
        invoiceLine.blng__Subtotal__c = 6000;
        invoiceLine.blng__TotalAmount__c = 1000;
        invoiceLine.blng__TaxStatus__c = 'Completed';
        invoiceLine.CurrencyIsoCode = userCurrency;
        database.insert(invoiceLine);
        
        //Update Parent Invoice status        
        parentInvoiceList[0].blng__InvoiceStatus__c = 'Posted';        
        update parentInvoiceList[0]; 
        //Update parent invoice line status
        parentInvLineList.blng__InvoiceLineStatus__c = 'Posted';        
        update parentInvLineList;        
        
        //CreditNote 
        //   Test.startTest();          
        List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);
        creditNotes[0].blng__RelatedInvoice__c = parentInvoiceList[0].id;
        creditNotes[0].QTB_Reason_Code__c = 'Inventory';
        creditNotes[0].blng__CreditNoteDate__c = system.today();
        creditNotes[0].blng__EffectiveTaxDate__c = system.today();  
        creditNotes[0].CurrencyIsoCode = userCurrency;
        database.update(creditNotes);
        
        //CreditNoteLines
        List<blng__CreditNoteLine__c> CreditNoteLine = new List<blng__CreditNoteLine__c>();
        blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
        cnl.QTB_Account__c = accountList[0].id;
        cnl.blng__CreditNote__c = creditNotes[0].id;
        cnl.QTB_Invoice__c = parentInvoiceList[0].Id;
        cnl.QTB_InvoiceLine__c = parentInvLineList.id;
        cnl.blng__Product__c = product[0].id;
        cnl.QTB_Credit_Quantity__c = 0;
        cnl.blng__CalculateTax__c = true;
        //cnl.blng__Subtotal__c = 0;
        CreditNoteLine.add(cnl);
        
              //insert CreditNoteLine; 
        Test.stopTest();
    }
    
    static testMethod void handleCreditRebillInvoiceScenario() {
        Test.startTest();
        List<OrderItem>ordI = [Select id,OrderItemNumber,product2Id,product2.ProductCode,product2.name,PricebookEntry.UnitPrice, ListPrice,QTB_OriginalConsumptionID__c,PricebookEntryId,blng__BillingRule__c,blng__RevenueRecognitionRule__c,blng__TaxRule__c,blng__HoldBilling__c,SBQQ__Activated__c from orderitem Limit 1];
        
        OrderItem ordrItem = new OrderItem();
        ordrItem.id = ordI[0].id;
        ordrItem.blng__HoldBilling__c = 'Yes';
        ordrItem.SBQQ__Activated__c = false;
        update ordrItem;
        
        List<blng__Invoice__c> invoiceList = [SELECT Id,QTB_Parent_Invoice__c,blng__Account__c,blng__Subtotal__c,QTB_Parent_Invoice__r.blng__Subtotal__c,QTB_ReBill_Credit_Reason__c,CurrencyIsoCode,QTB_Parent_Invoice__r.QTB_ReBill_Credit_Reason__c 
                                              From blng__Invoice__c 
                                              WHERE QTB_Parent_Invoice__c!= null LIMIT 1]; 
        Set<id> invId = new  Set<id>();
        for(blng__Invoice__c invoice : invoiceList){
            invId.add(invoice.Id);
        }
        
        
        List<blng__InvoiceLine__c> invoiceLineList = [Select ID,blng__ChargeType__c,QTB_Charge_Type__c, Name,blng__Invoice__c,QTB_Taxable_Amount__c,QTB_Allocated_Revenue_Amount__c,QTB_HasConsumptionSchedule__c,blng__Invoice__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__UsageSummary__c,
                                                      blng__Product__r.QTB_Oracle_GL_Account_Code__c,blng__Product__r.IM_Product_Class__c,blng__Product__r.QTB_Tax_Category__c,blng__Product__r.Name,blng__Product__r.ProductCode,blng__TotalAmount__c, blng__Invoice__r.blng__Account__c,blng__Invoice__r.blng__Account__r.Name,
                                                      blng__Subtotal__c,blng__Invoice__r.blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Invoice__r.blng__Account__r.CurrencyIsoCode,
                                                      blng__Invoice__r.blng__Account__r.ShippingCity,blng__Invoice__r.blng__Account__r.ShippingPostalCode,blng__Invoice__r.blng__Account__r.ShippingState,
                                                      blng__Invoice__r.blng__Account__r.IME_Display_Division__c,blng__Invoice__r.blng__Account__r.ShippingCountry,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                      blng__OrderProduct__r.Id, blng__OrderProduct__r.Order.OrderNumber,blng__Product__r.Bill_Code__c,blng__TaxErrorMessage__c                          
                                                      From blng__InvoiceLine__c where  blng__Invoice__c IN : invId  ];
        // Product2 prd = [Select ID, Name,SBQQ__HasConsumptionSchedule__c from Product2 where SBQQ__HasConsumptionSchedule__c = true limit 1 ];
        if(invoiceLineList.size()>0)
        {
            blng__InvoiceLine__c invl = new blng__InvoiceLine__c();
            invl.id = invoiceLineList[0].id;
            //  invl.blng__Product__c = prd.id;
            invl.blng__OrderProduct__c = ordrItem.id ;
            //invl.blng__Subtotal__c = 100;
            update invl; 
        }
        
        
        List<blng__CreditNote__c> crList = [Select Id, NAme,blng__Status__c,blng__Account__c,blng__RelatedInvoice__c,QTB_Reason_Code__c,QTB_Internal_Notes__c,blng__CreditNoteDate__c,blng__EffectiveTaxDate__c,CurrencyIsoCode
                                            From blng__CreditNote__c limit 1];
        
        Set<id> CrNoteId = new  Set<id>();
        for(blng__CreditNote__c creditNote : crList){
            CrNoteId.add(creditNote.Id);
        }
        
        List<blng__CreditNoteLine__c> existingCreditNoteLines = [SELECT ID,blng__CreditNote__c,blng__CreditNote__r.blng__Subtotal__c,blng__CreditNote__r.blng__Status__c,QTB_Credit_Quantity__c,
                                                                 blng__Subtotal__c,QTB_Invoice__c,blng__Product__c,QTB_InvoiceLine__c,QTB_Invoice__r.QTB_ReBill_Status__c,
                                                                 blng__CreditNote__r.QTB_ReBill_Credit_Amount__c
                                                                 FROM blng__CreditNoteLine__c
                                                                 WHERE blng__CreditNote__c  IN :CrNoteId and  QTB_Invoice__c  IN:invId ];
        
        blng__CreditNoteLine__c CrdNotlines = new blng__CreditNoteLine__c();
        if(existingCreditNoteLines.size()>0){
            CrdNotlines.id = existingCreditNoteLines[0].id;
            //CrdNotlines.blng__Subtotal__c = 0;
            update CrdNotlines;
        }
        
        System.debug('handleCreditRebillInvoiceScenario@@'+invoiceList);
        QTB_CreditRebillUtil.handleInvoiceHelperCreditRebill(invId,true);
        QTB_CreditRebillUtil.handleInvoiceHelperCreditRebill(invId,false);
        QTB_CreditRebillUtil.calculateRebillAmountsOnSplitRebillInvoice(invId);
        Test.stopTest();
    }
    
    static testMethod void handleCreditRebillInvoiceScenarioisFalse() {
        Test.startTest();
        List<OrderItem>ordI = [Select id,OrderItemNumber,product2Id,product2.ProductCode,product2.name,
                               PricebookEntry.UnitPrice, ListPrice,QTB_OriginalConsumptionID__c,PricebookEntryId,
                               blng__BillingRule__c,blng__RevenueRecognitionRule__c,blng__TaxRule__c,
                               blng__HoldBilling__c,SBQQ__Activated__c from orderitem Limit 1];
        
        OrderItem ordrItem = new OrderItem();
        ordrItem.id = ordI[0].id;
        ordrItem.blng__HoldBilling__c = 'Yes';
        ordrItem.SBQQ__Activated__c = false;
        update ordrItem;
        
        List<blng__Invoice__c> invoiceList = [SELECT Id,QTB_Parent_Invoice__c,blng__Account__c,blng__Subtotal__c,QTB_Parent_Invoice__r.blng__Subtotal__c,QTB_ReBill_Credit_Reason__c,CurrencyIsoCode,QTB_Parent_Invoice__r.QTB_ReBill_Credit_Reason__c  
                                              From blng__Invoice__c 
                                              WHERE (QTB_Parent_Invoice__c!= null and QTB_Parent_Invoice__r.blng__Subtotal__c > 0) LIMIT 1]; 
        
        Set<id> invId = new  Set<id>();
        for(blng__Invoice__c invoice : invoiceList){
            invId.add(invoice.Id);
        }
        
        List<blng__InvoiceLine__c> invoiceLineList = [Select ID,blng__ChargeType__c,QTB_Charge_Type__c, Name,blng__Invoice__c,QTB_Taxable_Amount__c,QTB_Allocated_Revenue_Amount__c,QTB_HasConsumptionSchedule__c,blng__Invoice__r.Id,blng__Invoice__r.blng__InvoiceStatus__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__UsageSummary__c,
                                                      blng__Product__r.QTB_Oracle_GL_Account_Code__c,blng__Product__r.IM_Product_Class__c,blng__Product__r.QTB_Tax_Category__c,blng__Product__r.Name,blng__Product__r.ProductCode,blng__TotalAmount__c, blng__Invoice__r.blng__Account__c,blng__Invoice__r.blng__Account__r.Name,
                                                      blng__Subtotal__c,blng__Invoice__r.blng__Account__r.QTB_Billing_Account_Invoice_Name__c,blng__Invoice__r.blng__Account__r.CurrencyIsoCode,
                                                      blng__Invoice__r.blng__Account__r.ShippingCity,blng__Invoice__r.blng__Account__r.ShippingPostalCode,blng__Invoice__r.blng__Account__r.ShippingState,
                                                      blng__Invoice__r.blng__Account__r.IME_Display_Division__c,blng__Invoice__r.blng__Account__r.ShippingCountry,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                      blng__OrderProduct__r.Id, blng__OrderProduct__r.Order.OrderNumber,blng__Product__r.Bill_Code__c,blng__TaxErrorMessage__c                          
                                                      From blng__InvoiceLine__c where  blng__Invoice__c IN : invId  ];
        // Product2 prd = [Select ID, Name,SBQQ__HasConsumptionSchedule__c from Product2 where SBQQ__HasConsumptionSchedule__c = true limit 1 ];
        if(invoiceLineList.size()>0)
        {
            blng__InvoiceLine__c invl = new blng__InvoiceLine__c();
            invl.id = invoiceLineList[0].id;
            //  invl.blng__Product__c = prd.id;
            invl.blng__OrderProduct__c = ordrItem.id ;
            //invl.blng__Subtotal__c = 100;
            update invl; 
        }
        
        List<blng__CreditNote__c> crList = [Select Id, NAme,blng__Status__c,blng__Account__c,blng__RelatedInvoice__c,QTB_Reason_Code__c,QTB_Internal_Notes__c,blng__CreditNoteDate__c,blng__EffectiveTaxDate__c,CurrencyIsoCode
                                            From blng__CreditNote__c limit 1];
        Set<id> CrNoteId = new  Set<id>();
        for(blng__CreditNote__c creditNote : crList){
            CrNoteId.add(creditNote.Id);
        }
        
        List<blng__CreditNoteLine__c> existingCreditNoteLines = new List<blng__CreditNoteLine__c>();
        /*[SELECT ID,blng__CreditNote__c,blng__CreditNote__r.blng__Subtotal__c,blng__CreditNote__r.blng__Status__c,QTB_Credit_Quantity__c,
blng__Subtotal__c,QTB_Invoice__c,blng__Product__c,QTB_InvoiceLine__c,QTB_Invoice__r.QTB_ReBill_Status__c,
blng__CreditNote__r.QTB_ReBill_Credit_Amount__c
FROM blng__CreditNoteLine__c
WHERE blng__CreditNote__c  IN :CrNoteId and  QTB_Invoice__c  IN:invId ];*/
        
        blng__CreditNoteLine__c CrdNotlines = new blng__CreditNoteLine__c();
        if(existingCreditNoteLines.size()>0){
            CrdNotlines.id = existingCreditNoteLines[0].id;
            //CrdNotlines.blng__Subtotal__c = 0;
            update CrdNotlines;
        }
        
        System.debug('handleCreditRebillInvoiceScenario@@'+invoiceList);
        QTB_CreditRebillUtil.handleInvoiceHelperCreditRebill(invId,false);
        QTB_CreditRebillUtil.calculateRebillAmountsOnSplitRebillInvoice(invId);
        Test.stopTest();
    }
    static testMethod void testMethod1(){
        Test.startTest();
        List<blng__Invoice__c> allInvoiceList = new List<blng__Invoice__c>();
        
        //Rebill Invoice
        List<blng__Invoice__c> rebillInvoiceList = [SELECT Id, Name, QTB_Rebill_Type__c,CurrencyISOCode,blng__TotalAmount__c,QTB_Parent_Invoice__r.QTB_ReBill_Credit_Reason__c 
                                                    FROM blng__Invoice__c 
                                                    WHERE QTB_Invoice_Type__c = 'ReBill'];
        blng__Invoice__c rebillInvoice = new blng__Invoice__c();
        rebillInvoice.Id = rebillInvoiceList[0].id;
        rebillInvoice.QTB_Rebill_Type__c = 'Split';        
        allInvoiceList.add(rebillInvoice);
        
        //Parent Invoice
        List<blng__Invoice__c> parentInvoiceList = [SELECT Id, Name, QTB_Rebill_Type__c,CurrencyISOCode
                                                    FROM blng__Invoice__c 
                                                    WHERE QTB_Invoice_Type__c = 'New'];
        blng__Invoice__c parentInv = new blng__Invoice__c();
        parentInv.Id = parentInvoiceList[0].Id;
        parentInv.QTB_ReBill_Invoice_With_Total__c = 'INV-123 = '+ rebillInvoiceList[0].CurrencyISOCode+' '+rebillInvoiceList[0].blng__TotalAmount__c;
        allInvoiceList.add(parentInv); 
        update allInvoiceList;
        
        Set<Id> rebillInvoiceIds = new Set<Id>();
        rebillInvoiceIds.add(rebillInvoice.Id);
        QTB_CreditRebillUtil.handleInvoiceHelperCreditRebill(rebillInvoiceIds,false);        
        
        //No Tax Rule
        blng__TaxRule__c noTaxRule = new blng__TaxRule__c();
        noTaxRule.Name = 'No Tax Rule';
        noTaxRule.blng__Active__c = true;
        noTaxRule.blng__TaxableYesNo__c = 'No';
        insert noTaxRule;
        
        //Rebill InvoiceLine
        LisT<blng__InvoiceLine__c> rebillInvoiceLineList = [Select Id, Name,blng__TaxRule__c 
                                                            FROM blng__InvoiceLine__c
                                                            WHERE blng__Invoice__c = :rebillInvoiceList[0].id ];
        blng__InvoiceLine__c rebillInvLine = new blng__InvoiceLine__c();
        rebillInvLine.Id = rebillInvoiceLineList[0].Id;
        rebillInvLine.blng__TaxRule__c = noTaxRule.Id;
        update rebillInvLine;
        
        QTB_CreditRebillUtil.calculateRebillAmountsOnSplitRebillInvoice(rebillInvoiceIds);
        
        //Handling exception
        QTB_CreditRebillUtil.throwExplicitException = true;
        try{
            QTB_CreditRebillUtil.handleInvoiceHelperCreditRebill(rebillInvoiceIds,false);  
        }Catch(Exception e){
            System.debug('inside exception');
        }
        
        try{
            QTB_CreditRebillUtil.calculateRebillAmountsOnSplitRebillInvoice(rebillInvoiceIds);
        }catch(Exception e){
            System.debug('inside exception');
        }        
        Test.stopTest();
    } 
}