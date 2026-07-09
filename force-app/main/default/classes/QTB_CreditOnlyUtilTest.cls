/*****************************************************************************************************
* Test Class    : QTB_CreditOnlyUtilTest
* Author        : IRM/Virtusa
* Purpose       : This test class for to cover all sceanrio of QTB_CreditRebillUtil apex class
* Requirement   : 
* Change History:  09/14/2022
* Developer        Date             Description
* -------------------------------------------------------------------------------------------
* Shailesh     09/14/2022      Gitlab US #9256 Credit & Rebill
*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_CreditOnlyUtilTest {
    @testSetup
    static void setup() {
        String userCurrency = System.UserInfo.getDefaultCurrency();
        Credit_ReBill_InvoiceSchedulerValidation__c invSchCust = new Credit_ReBill_InvoiceSchedulerValidation__c();
        invSchCust.Name = 'United States';
        invSchCust.isRunning__c = false;
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
        
        database.insert(product);
        System.debug('product@@'+product);
        
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
        billAcc.QTB_Legal_Entity_Country__c='United States';
        //billAcc.QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
        billAcc.CurrencyISOCode = userCurrency;
        billAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
        accountList.add(billAcc);
        
        Database.insert(accountList);
        
        List<Account> salesAccountList = new List<Account>();
        
        Account salesAcc = new Account();
        salesAcc.Name = 'Test Sales Account';
        salesAcc.IM_Hierarchy_Level__c = 'Sales (Site)';
        salesAcc.CurrencyISOCode = userCurrency;
        //salesAcc.Division = 'Europe';
         salesAccountList.add(salesAcc);        
        
        Database.insert(salesAccountList);
        
        
        //Legal Entity
        blng__LegalEntity__c USEntity = new blng__LegalEntity__c();
        USEntity.Name = 'Test Legal Entity United States';
        USEntity.blng__Active__c = true;
        USEntity.blng__Country__c = 'United States';
        USEntity.QTB_Type__c = 'Contract';
        //indiaEntity.QTB_Legal_Entity_Number__c = '45000';
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
        
        QTB_Bill_Code_Product_Lookup__c productLookup = new QTB_Bill_Code_Product_Lookup__c(
            QTB_Source_Bill_Code__c = 'VALID_CODE',
            QTB_Country__c = im.Id,
            QTB_Product2__c = product[0].id
        );
        insert productLookup;
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(salesAccountList);
        oppList[0].Pricebook2Id = pricebookId;
        //oppList[0].Legal_Entity__c = USEntity.id;
        oppList[0].Billing_Country__c = im.id;
        oppList[0].CurrencyISOCode = userCurrency;
        database.update(oppList);
        
        /*List<opportunity> oppList =  = new List<Opportunity>();
        Opportunity op = new Opportunity();
            op.Name = 'Testopp',
            op.AccountId = accountList[0].Id;
            op.CloseDate = Date.today();
            op.StageName = '1 - Qualification';
            op.RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
            op.Amount = 500;
            op.Pricebook2Id = pricebookId;
            op.Billing_Country__c = im.id;
            op.CurrencyISOCode = userCurrency;
                oppList.add(op);
        SBQQ.TriggerControl.disable();
        insert oppList;
        SBQQ.TriggerControl.enable();*/
        
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
        
        //Database.insert(quoteList);
        
        
        //QuoteLineGroup   
        //List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //Quote Line
        //List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
        
        //Parent & Rebill Invoices - Order         
        List<Order> orderList = new List<Order>();
        
        //Parent Invoice - Order 
        Order parentOrders = new Order();
        //parentOrders.SBQQ__Quote__c = quoteList[0].Id;
        parentOrders.AccountId = accountList[0].id;
        parentOrders.blng__BillingDayOfMonth__c = '1';
        parentOrders.EffectiveDate = Date.today().addDays(5);
        parentOrders.Status = QTB_Constants.DRAFT_STATUS;
        parentOrders.Pricebook2Id = pricebookId;
        parentOrders.blng__InvoiceBatch__c = 'Denmark-26th';
        parentOrders.recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        parentOrders.CurrencyIsoCode=userCurrency;
        orderList.add(parentOrders);        
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
        Test.startTest();                   
        /* List<blng__Invoice__c> parentInvoiceList = QTB_TestDataFactory.createInvoices(accountList); 
parentInvoiceList[0].blng__InvoiceDate__c = System.today();    
// parentInvoiceList[0].blng__InvoiceDate__c = System.today();
parentInvoiceList[0].QTB_Invoice_Type__c = 'New'; 
parentInvoiceList[0].CurrencyIsoCode=userCurrency;
parentInvoiceList[0].blng__InvoiceStatus__c = 'Posted'; 
//parentInvoiceList[0].blng__Account__c=accountList[0].Id;                         
database.update(parentInvoiceList); */
        
        
        
        List<blng__Invoice__c> invoiceListFinal = new List<blng__Invoice__c>();
        for (Integer i = 0; i< 1; i++) {
            blng__Invoice__c invoiceTemp = new blng__Invoice__c();
            invoiceTemp.blng__Account__c = accountList[0].Id;
            invoiceTemp.blng__InvoiceStatus__c = 'Draft';
            //invoiceTemp.QTB_Invoice_Type__c = 'Legacy invoice';
            //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
            invoiceListFinal.add(invoiceTemp);
        }
        if (!invoiceListFinal.isEmpty()) {
            insert invoiceListFinal;
            system.debug('invoiceListFinal[0].Id--->'+invoiceListFinal[0].Id);
        }
        
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
        usagesummary.blng__Invoice__c = invoiceListFinal[0].id; 
        usagesummary.CurrencyIsoCode = userCurrency;
        usagesummary.blng__Invoice__c = invoiceListFinal[0].id;
        database.update(usagesummary);
        system.debug('usagesummary.blng__Invoice__c--->'+usagesummary.blng__Invoice__c);
        
        //Parent Invoice Usage
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
        system.debug('parentInvUageList[0].blng__UsageSummary__c-->'+parentInvUageList[0].blng__UsageSummary__c);
        
        invoiceListFinal[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceListFinal[0].blng__InvoiceStatus__c = 'Draft';
        
        //Invoice Scheduler
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'test';
        schedule.blng__Type__c = 'Once';
        schedule.blng__InvoiceBatches__c = 'Rebill Run';
        schedule.CurrencyIsoCode = userCurrency;
        schedule.blng__StartDateTime__c = System.now();
        schedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        schedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
        schedule.QTB_Legal_Entity__c = USEntity.Id;
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
        List<blng__InvoiceLine__c> parentInvLineList = new List<blng__InvoiceLine__c>();
        for (blng__Invoice__c inv : invoiceListFinal) {
          //Product2 prod = product[0].id;
          blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
          invoiceLine.Name = product[0].Name;
          invoiceLine.blng__Invoice__c = inv.Id;
          invoiceLine.blng__Product__c = product[0].id;
          invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
          invoiceLine.blng__Quantity__c = 10;
          invoiceLine.blng__UnitPrice__c = 5;
          invoiceLine.blng__TaxPercentageApplied__c = 24;
          invoiceLine.blng__UsageSummary__c = usagesummary.id;
          invoiceLine.blng__TaxCountry__c = 'United States';
          //invoiceLine.blng__InvoiceLineStatus__c = QTB_Constants.INVOICELINE_STATUS_DRAFT;
          parentInvLineList.add(invoiceLine);
      }
      if (!parentInvLineList.isEmpty()) {
        //SBQQ.TriggerControl.disable();
        insert parentInvLineList;
        //SBQQ.TriggerControl.enable();
      }
        system.debug('parentInvLineList:'+parentInvLineList);
        parentInvLineList[0].blng__OrderProduct__c = orderItemList[0].id;
        parentInvLineList[0].blng__UsageSummary__c = usagesummary.id;
        parentInvLineList[0].blng__InvoiceLineStatus__c = 'Posted';
        parentInvLineList[0].blng__TaxAmount__c = 50;
        parentInvLineList[0].blng__TaxCountry__c = 'India';
        parentInvLineList[0].blng__TaxState__c = 'TN';
        parentInvLineList[0].blng__TaxCity__c = 'Chennai';
        parentInvLineList[0].blng__TaxZipCode__c = '500032';
        parentInvLineList[0].blng__TaxTreatment__c = blngTax.id;
        parentInvLineList[0].blng__LegalEntity__c = USEntity.id;
        parentInvLineList[0].blng__Subtotal__c = 5000;
        parentInvLineList[0].blng__TotalAmount__c = 1000;
        parentInvLineList[0].blng__TaxStatus__c = 'Completed';
        parentInvLineList[0].CurrencyIsoCode = userCurrency;
        SBQQ.TriggerControl.disable();
        database.update(parentInvLineList[0]);
        SBQQ.TriggerControl.enable();
        
        //Update Parent Invoice status        
        invoiceListFinal[0].blng__InvoiceStatus__c = 'Posted';
        SBQQ.TriggerControl.disable();        
        update invoiceListFinal[0];
        SBQQ.TriggerControl.enable(); 
        System.debug('invoiceListFinal[0]@@'+invoiceListFinal[0]);
        
        //Update parent invoice line status
        parentInvLineList[0].blng__InvoiceLineStatus__c = 'Posted';        
        update parentInvLineList[0];
        System.debug('parentInvLineList[0]@@'+parentInvLineList[0]);
        blng__InvoiceLine__c invLine = [Select ID, blng__Product__c,blng__Product__r.SBQQ__HasConsumptionSchedule__c, QTB_Charge_Type__c,blng__UsageSummary__c from blng__InvoiceLine__c
                                        where id = :parentInvLineList[0].Id ];
        System.debug('invLine@@'+invLine);
        
        
        list<QTB_Tax_Detail__c> testTax = new list<QTB_Tax_Detail__c>();
        QTB_Tax_Detail__c test1 = new QTB_Tax_Detail__c();
        test1.QTB_Invoice_Line__c  = parentInvLineList[0].id;
        test1.QTB_Jurisdiction__c = 'Test1';
        test1.QTB_Imposition__c  = 'Test2';
        test1.QTB_CalculatedTax__c = 23.00;
        testTax.add(test1);
        
        QTB_Tax_Detail__c test2 = new QTB_Tax_Detail__c();
        test2.QTB_Invoice_Line__c  = parentInvLineList[0].id;
        test2.QTB_Jurisdiction__c = 'Test11';
        test2.QTB_Imposition__c  = 'Test22';
        test2.QTB_CalculatedTax__c = 24.00;
        testTax.add(test2);

        insert testTax;
        Test.stopTest();
    }
    
    static testMethod void handleCreditOnly() {
        blng__Invoice__c inv= [SELECT Id,blng__InvoiceStatus__c,QTB_Parent_Invoice__c,blng__Subtotal__c, QTB_Parent_Invoice__r.blng__Subtotal__c,CurrencyIsoCode,blng__Account__r.QTB_Legal_Entity_Country__c,
                               QTB_Parent_Invoice__r.QTB_ReBill_Status__c,QTB_Rebill_Type__c,QTB_Parent_Invoice__r.QTB_SplitRebillSubtotalOnParentInvoice__c,
                               QTB_ReBill_Credit_Reason__c,QTB_ReBill_CreditNote_Internal_Note__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c
                               FROM blng__Invoice__c
                               WHERE blng__InvoiceStatus__c = 'posted'  limit 1];
        
        Test.startTest();
        Date creditnotedate = system.today();
        QTB_CreditOnlyUtil.handleCreditOnlyUtil(inv.id,true,'Account Creation','Internal Notes',creditnotedate);
        QTB_CreditOnlyUtil.handleCreditOnlyUtil(inv.id,false,'Account Creation','Internal Notes',creditnotedate);
        Test.stopTest();
    }
    static testMethod void createTaxDetails() {
        Test.startTest();
        sbqq.TriggerControl.disable();
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
        indiaEntity.QTB_Tax_Applicability__c = 'Flat Rate';
        update indiaEntity;
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(3,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c = 'India';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        accountList[0].ShippingCity = 'TN';
        accountList[0].ShippingState = 'Chennai';
        accountList[0].ShippingPostalCode = '500032';
        accountList[0].ShippingCountry = 'India';
        accountList[0].QTB_Records_Management__c = true;
        accountList[0].Payment_Terms__c = 'Net 30';
        accountList[0].QTB_Legal_Entity__c = indiaEntity.Id;
        accountList[0].QTB_Contract_Entity__c = indiaEntity.Id;
        accountList[1].QTB_Legal_Entity_Country__c = 'India';
        accountList[1].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        accountList[1].ShippingCity = 'TN';
        accountList[1].ShippingState = 'Chennai';
        accountList[1].ShippingPostalCode = '500032';
        accountList[1].ShippingCountry = 'India';
        accountList[1].QTB_Records_Management__c = true;
        accountList[1].Payment_Terms__c = 'Net 30';
        accountList[1].QTB_Legal_Entity__c = indiaEntity.Id;
        accountList[1].QTB_Contract_Entity__c = indiaEntity.Id;
        accountList[1].QTB_SITAD__c = true;
        
        
        accountList[2].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        accountList[2].ShippingCity = 'TN';
        accountList[2].ShippingState = 'Chennai';
        accountList[2].ShippingPostalCode = '500032';
        accountList[2].ShippingCountry = 'India';
        accountList[2].QTB_Records_Management__c = true;
        accountList[2].Payment_Terms__c = 'Net 30';
        accountList[2].QTB_Legal_Entity__c = indiaEntity.Id;
        accountList[2].QTB_Contract_Entity__c = indiaEntity.Id;
        accountList[2].QTB_SITAD__c = true;
        Update accountList;
        
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Fair Market Value';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        p1.blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').id;
        p1.blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id;
        p1.blng__RevenueRecognitionRule__c= QTB_TestDataFactory.createRevenueRecognitionRule('Yes').id;
        productList.add(p1);
        insert productList;
        
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[0].Id;
        invoice.blng__InvoiceStatus__c = 'Posted';
        invoice.QTB_Tax_Override_Amount__c = 10;
        invoice.QTB_Invoice_Type__c = 'New';
        sbqq.TriggerControl.disable();
        insert invoice;
        
        blng__Invoice__c sitadInvoice = new blng__Invoice__c();
        sitadInvoice.blng__Account__c = accountList[2].Id;
        sitadInvoice.blng__InvoiceStatus__c = 'Posted';
        sitadInvoice.QTB_Tax_Override_Amount__c = 10;
        sitadInvoice.QTB_Invoice_Type__c = 'New';
        sbqq.TriggerControl.disable();
        insert sitadInvoice;
        
        blng__Invoice__c legacyInvoice = new blng__Invoice__c();
        legacyInvoice.blng__Account__c = accountList[1].Id;
        legacyInvoice.blng__InvoiceStatus__c = 'Posted';
        legacyInvoice.QTB_Tax_Override_Amount__c = 10;
        legacyInvoice.QTB_Invoice_Type__c = 'Legacy Invoice';
        sbqq.TriggerControl.disable();
        insert legacyInvoice;
       
         Product2 prod = productList[0];
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = prod.Name;
        invoiceLine.blng__Invoice__c = invoice.Id;
        invoiceLine.blng__Product__c = prod.Id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Posted';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__Subtotal__c = 50;
        invoiceLine.blng__UnitPrice__c = 5;
        invoiceLine.blng__TaxPercentageApplied__c = 24;
        //invoiceLine.blng__InvoiceLineStatus__c = QTB_Constants.INVOICELINE_STATUS_DRAFT;
        invoiceLine.QTB_Tax_Override_Amount__c = 10;
        invoiceLine.blng__TaxCountry__c = 'India';
        insert invoiceLine;
        
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;
        
         blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
        taxIntegration.blng__TaxEngine__c = 'Standard';
        taxIntegration.blng__Active__c = true;
        insert taxIntegration;
        
        blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
        blngTax.blng__TaxLegalEntity__c = indiaEntity.id;
        blngTax.blng__TaxIntegration__c = taxIntegration.id;
        blngTax.blng__TaxRule__c = taxRule.id;
        blngTax.blng__TaxCode__c = 'STD-CGST';
        insert blngTax;
        
        List<blng__CreditNote__c> creditNotesList = new List<blng__CreditNote__c>();
        
        blng__CreditNote__c creditNote2 = new blng__CreditNote__c();
        creditNote2.blng__Account__c = accountList[0].Id;
        creditNote2.QTB_On_Account_Credit__c = false;
        creditNote2.blng__CreditNoteDate__c = date.today();
        creditNote2.QTB_Reason_Code__c = 'Bankruptcy';
        creditNote2.blng__Status__c = 'Draft';
        creditNote2.CurrencyIsoCode = 'INR';
        creditNotesList.add(creditNote2);
        System.debug('setup_creditNotesList@@'+creditNotesList);
        insert creditNotesList;
        
        List<blng__CreditNoteLine__c> creditNoteLineList = new List<blng__CreditNoteLine__c>();
        
        blng__CreditNoteLine__c cnl2 = new blng__CreditNoteLine__c();
        cnl2.QTB_Account__c = accountList[0].Id;
        cnl2.blng__CreditNote__c = creditNotesList[0].id;
        cnl2.blng__InvoiceLine__c = invoiceLine.id;
        cnl2.QTB_InvoiceLine__c = invoiceLine.id;
        cnl2.QTB_Invoice__c = invoice.Id;
        cnl2.blng__TaxTreatment__c = blngTax.Id;
        cnl2.blng__TaxCountry__c = 'India';
        cnl2.blng__TaxState__c = 'TN';
        cnl2.blng__TaxCity__c = 'Chennai';
        cnl2.blng__TaxZipCode__c = '500032';
        cnl2.blng__LegalEntity__c = indiaEntity.Id;
        cnl2.blng__CalculateTax__c = true;
        cnl2.blng__TaxPercentageApplied__c = 24;
        //cnl2.blng__Subtotal__c = 50;
        cnl2.QTB_Credit_Quantity__c = 10;
        //cnl2.QTB_Credit_Note_Type__c = 'Split ReBill';
        creditNoteLineList.add(cnl2);
        System.debug('setup_creditNoteLineList1@@'+creditNoteLineList);
        sbqq.TriggerControl.disable();
        insert creditNoteLineList;
        
        List<QTB_Tax_Detail__c> taxDetailList =new List<QTB_Tax_Detail__c>();
        QTB_Tax_Detail__c taxDetail = new QTB_Tax_Detail__c();
                taxDetail.QTB_Credit_Note__c = creditNotesList[0].id;
                taxDetail.QTB_Credit_Note_Line__c = creditNoteLineList[0].Id;
                taxDetail.QTB_Usage__c = null;
                taxDetail.QTB_Invoice__c = invoice.Id;
                taxDetail.QTB_Invoice_Line__c = invoiceLine.id; 
                taxDetail.OwnerId = System.UserInfo.getUserId();
        taxDetailList.add(taxDetail);
        Database.insert(taxDetailList);
        
        QTB_CreditOnlyUtil.createTaxDetails(creditNoteLineList);
        //QTB_CreditOnlyUtil.createCreditNoteLines(invoice.id, creditNotesList[0].id,true);
        Date creditnotedate = system.today();
        QTB_CreditOnlyUtil.handleCreditOnlyUtil(sitadInvoice.id,true,'Account Creation','Internal Notes',creditnotedate);
        QTB_CreditOnlyUtil.handleCreditOnlyUtil(legacyInvoice.id,true,'Account Creation','Internal Notes',creditnotedate);
        Test.stopTest();
        
        
    }    
    
}