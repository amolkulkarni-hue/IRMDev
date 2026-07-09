@isTest
public class QTB_GenerateMassInvBckngRprtBatch_Test {
    @testSetup
    static void setupData(){
        
        Id pricebookId = Test.getStandardPricebookId();        
        
        //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p1);    
        
        //Product2 -- Recurring
        product2 p2 = new product2();
        p2.Name = 'Test Product2';
        p2.isActive = true;
        p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p2.SBQQ__HasConsumptionSchedule__c = false;
        productList.add(p2); 
        
        insert productList;
        
        //Price Book creation for all product
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(productList[0]); // for Usage              
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[1]); // for Recurring      
        
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
        
        //Legal Entity
        blng__LegalEntity__c legalEntity = new blng__LegalEntity__c();
        legalEntity.Name ='Iron Mountain Information Management, LLC';
        legalEntity.blng__Country__c = 'India';
        legalEntity.QTB_FX_Tax_Rate_Type__c = 'Corporate';
        legalEntity.QTB_Legal_Entity_Number__c = 45000;
        insert legalEntity;
        
        //Account
        List<Account> accountList = new List<Account>();
        String recordType = 'Billing Account';
        ID recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
        if (String.isNotBlank(recordType) && String.isNotEmpty(recordType)) {
            acc.RecordTypeId = recordTypeValue;
            if (('Billing Account').equals(recordType)) {
                acc.QTB_Create_Parent_Billing_Account__c = true;
            }
        } 
        acc.QTB_Legal_Entity_Country__c='United States';
        acc.QTB_Contract_Entity__c = legalEntity.id;
        acc.CurrencyIsoCode = 'USD';
        acc.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        acc.ShippingCity = 'New York';
        acc.ShippingState = 'New York';
        acc.ShippingPostalCode = '22131';
        acc.ShippingCountry = 'United States';
        acc.QTB_Bill_Cycle_Day__c = 'India IRM-1st';
        acc.QTB_Language__c = 'en_US';
        accountList.add(acc);
        insert accountList;
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        database.update(oppList);
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        database.update(quoteList);
        
        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[0].id);  //for usage
        List<SBQQ__QuoteLine__c> quoteLinesList1 = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[1].id);  // for recurring
        
        //Order
        List<Order> orderList = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        database.update(orderList);
        
        SBQQ.TriggerControl.disable();
        Test.startTest();
        //OrderItem
        List<OrderItem> orderItemList1 = QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,productList[0].Id,quoteLinesList,standardPrice1); // for usage
        List<OrderItem> orderItemList2 = QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,productList[1].Id,quoteLinesList,standardPrice2); // for recurring

       //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);   // for draft
        //List<blng__Invoice__c> invoiceListForCredit = QTB_TestDataFactory.createInvoices(accountList); // for posted
        
        //UsageSummary for Invoice
        List<blng__UsageSummary__c> usageSumList = new List<blng__UsageSummary__c>(); 
        blng__UsageSummary__c usagesummary = new blng__UsageSummary__c();
        usagesummary.blng__Order__c = orderList[0].id;
        usagesummary.blng__Account__c = accountList[0].id;
        usagesummary.blng__OrderProduct__c = orderItemList1[0].id;
        usagesummary.blng__SummaryEndDate__c = DATE.newInstance(2021, 1, 26);
        usagesummary.blng__SummaryStartDate__c = DATE.newInstance(2021, 1, 1);
        usagesummary.blng__MatchingId__c = '1234';
        usagesummary.blng__Status__c = 'Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';  
        usagesummary.blng__Subtotal__c = 100;
        usagesummary.blng__TotalQuantity__c = 10;
        usagesummary.blng__PreratedQuantity__c = 20;
        usagesummary.blng__UnbilledQuantity__c = 1;
        usagesummary.blng__UnitPrice__c = 400;
        usagesummary.blng__PreratedAmount__c = 22;
        usagesummary.blng__Invoice__c = invoiceList[0].id;
        usageSumList.add(usagesummary);
        insert usageSumList;
        
        //Usages for Invoice
        List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(3,accountList[0],usagesummary);
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        usageList[0].QTB_Service_District__c = '44147';
        usageList[0].blng__Subtotal__c = 50;
        usageList[0].blng__OrderProduct__c = orderItemList1[0].id;          
        database.update(usageList);
        
        invoiceList[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceList[0].blng__InvoiceStatus__c = 'Draft';        
        update invoiceList[0];
        
         //Billing Finanace
        blng__FinanceBook__c denmarkFinanceBook = new blng__FinanceBook__c();
        denmarkFinanceBook.Name = 'Accounting Finance Book';
        denmarkFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
        denmarkFinanceBook.blng__Active__c = true;
        denmarkFinanceBook.blng__PeriodType__c='Accounting';
        insert denmarkFinanceBook;
        
        
        blng__FinancePeriod__c denmarkFinancePeriod = new blng__FinancePeriod__c();
        denmarkFinancePeriod.Name = 'Mar 2024';
        denmarkFinancePeriod.blng__FinanceBook__c = denmarkFinanceBook.id;
        denmarkFinancePeriod.blng__PeriodStartDate__c = system.today().toStartofMonth();
        denmarkFinancePeriod.blng__PeriodEndDate__c = system.today().addMonths(1).toStartofMonth().addDays(-1);
        denmarkFinancePeriod.blng__LegalEntity__c = legalEntity.id;
        denmarkFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert denmarkFinancePeriod;
        
                
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'test12345abcd';
        schedule.blng__Type__c = 'Once';
        schedule.blng__InvoiceBatches__c ='India IRM-1st';
        //schedule.blng__InvoiceBatches__c = 'United States-DM-1st-EOM Manual';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.now().addHours(1);
        schedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        schedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
        schedule.QTB_Legal_Entity__c = legalEntity.id;
        schedule.QTB_Invoice_Period__c = denmarkFinancePeriod.Id;
        insert schedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.blng__InvoiceScheduler__c = schedule.Id;
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        
        invoiceList[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
       // invoiceList[0].blng__InvoiceStatus__c = 'Posted';       
        invoiceList[0].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        update invoiceList[0];
        
        
        List<blng__InvoiceLine__c> invLineList = new List<blng__InvoiceLine__c>();
        
        //Invoice line -- for usage
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = productList[0].Name;
        invoiceLine.blng__Invoice__c = invoiceList[0].Id;
        invoiceLine.blng__Product__c = productList[0].Id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;
        invoiceLine.blng__TaxPercentageApplied__c = 24;
        invoiceLine.blng__OrderProduct__c = orderItemList1[0].id;
        invoiceLine.blng__UsageSummary__c = usagesummary.id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
        invoiceLine.blng__TaxAmount__c = 50;
        invoiceLine.blng__TaxCountry__c = 'India';
        invoiceLine.blng__TaxState__c = 'TN';
        invoiceLine.blng__TaxCity__c = 'Chennai';
        invoiceLine.blng__TaxZipCode__c = '500032';
        invoiceLine.blng__LegalEntity__c = legalEntity.id;
        invoiceLine.blng__Subtotal__c = 1000;
        //invoiceLine.blng__TaxRule__c = taxRule.id;
        invoiceLine.QTB_Inc_Quantity__c = 10;
        invoiceLine.QTB_Taxable_Amount__c = 10;
        invLineList.add(invoiceLine);
        
        //for recurring
        blng__InvoiceLine__c invoiceLineRecurring = new blng__InvoiceLine__c();
        invoiceLineRecurring.Name = productList[1].Name;
        invoiceLineRecurring.blng__Invoice__c = invoiceList[0].Id;
        invoiceLineRecurring.blng__Product__c = productList[1].Id;
        invoiceLineRecurring.blng__InvoiceLineStatus__c = 'Draft';
        invoiceLineRecurring.blng__Quantity__c = 10;
        invoiceLineRecurring.blng__UnitPrice__c = 5;
        invoiceLineRecurring.blng__TaxPercentageApplied__c = 24;
        invoiceLineRecurring.blng__OrderProduct__c = orderItemList2[0].id;
        invoiceLineRecurring.blng__Product__c = productList[1].id;
        invoiceLineRecurring.blng__UsageSummary__c = null;
        invoiceLineRecurring.blng__InvoiceLineStatus__c = 'Posted';
        invoiceLineRecurring.blng__TaxAmount__c = 50;        
        invoiceLineRecurring.blng__TaxCountry__c = 'India';
        invoiceLineRecurring.blng__TaxState__c = 'TN';
        invoiceLineRecurring.blng__TaxCity__c = 'Chennai';
        invoiceLineRecurring.blng__TaxZipCode__c = '500032';
        invoiceLineRecurring.blng__LegalEntity__c = legalEntity.id;
        invoiceLineRecurring.blng__Subtotal__c = 1000;
        //invoiceLineRecurring.blng__TaxRule__c = taxRule.id;
        invoiceLineRecurring.QTB_Inc_Quantity__c = 10;
        invoiceLineRecurring.QTB_Taxable_Amount__c = 10;
        invLineList.add(invoiceLineRecurring);       
        insert invLineList;
        
        usagesummary.blng__InvoiceLine__c = invLineList[0].id;
        database.update(usagesummary);
        /*
List<blng__InvoiceLine__c> invLineListForCredit2 = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
invLineListForCredit2[0].blng__OrderProduct__c = orderItemList3[0].id;
invLineListForCredit2[0].blng__Product__c = productList[0].id;
invLineListForCredit2[0].blng__UsageSummary__c = usagesummary1.Id;
invLineListForCredit2[0].blng__InvoiceLineStatus__c = 'Posted';
invLineListForCredit2[0].blng__TaxAmount__c = 50;        
invLineListForCredit2[0].blng__TaxCountry__c = 'India';
invLineListForCredit2[0].blng__TaxState__c = 'TN';
invLineListForCredit2[0].blng__TaxCity__c = 'Chennai';
invLineListForCredit2[0].blng__TaxZipCode__c = '500032';
invLineListForCredit2[0].blng__LegalEntity__c = indiaEntity.id;
invLineListForCredit2[0].blng__Subtotal__c = 1000;
invLineListForCredit2[0].blng__TaxRule__c = taxRule.id;
invLineListForCredit2[0].QTB_Inc_Quantity__c = 10;
invLineListForCredit2[0].QTB_Taxable_Amount__c = 10;
database.update(invLineListForCredit2); */
        Test.stopTest();
    }
    
    public static testMethod void methodPosted1(){
        Test.startTest();
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
        usaEntity.Name = 'Test Legal Entity Finland';
        usaEntity.blng__Active__c = true;
        usaEntity.blng__Country__c = 'India';
        usaEntity.QTB_Type__c = 'Contract';
        usaEntity.QTB_Legal_Entity_Number__c = 45000;
        insert usaEntity;
        
        //Billing Finanace
        blng__FinanceBook__c denmarkFinanceBook = new blng__FinanceBook__c();
        denmarkFinanceBook.Name = 'Accounting Finance Book';
        denmarkFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
        denmarkFinanceBook.blng__Active__c = true;
        denmarkFinanceBook.blng__PeriodType__c='Accounting';
        insert denmarkFinanceBook;
        
        
        blng__FinancePeriod__c denmarkFinancePeriod = new blng__FinancePeriod__c();
        denmarkFinancePeriod.Name = 'Mar 2024';
        denmarkFinancePeriod.blng__FinanceBook__c = denmarkFinanceBook.id;
        denmarkFinancePeriod.blng__PeriodStartDate__c = system.today().toStartofMonth();
        denmarkFinancePeriod.blng__PeriodEndDate__c = system.today().addMonths(1).toStartofMonth().addDays(-1);
        denmarkFinancePeriod.blng__LegalEntity__c = usaEntity.id;
        denmarkFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert denmarkFinancePeriod;
        
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'test12345abcd';
        schedule.blng__Type__c = 'Once';
        schedule.blng__InvoiceBatches__c ='India IRM-1st';
        //schedule.blng__InvoiceBatches__c = 'United States-DM-1st-EOM Manual';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.now().addHours(1);
        schedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        schedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
        schedule.QTB_Legal_Entity__c = usaEntity.id;
        schedule.QTB_Invoice_Period__c = denmarkFinancePeriod.Id;
        insert schedule;
        
        //blng__InvoiceScheduler__c blngInvoiceSchedular = QTB_TestDataFactory.createInvoiceScheduler('Norway-26th','Once');
        string invSCId = schedule.id;
        string invStatus = 'Draft';
        string invbatch = 'India IRM-1st';
        PageReference pageRef1 = Page.QTB_GenerateApexMassExtractVF;
        Test.setCurrentPage(pageRef1);
        pageRef1.getParameters().put('Id',invSCId);
        pageRef1.getParameters().put('invStatus',invStatus);
        pageRef1.getParameters().put('invBatchNumber',invbatch);
        QTB_Invoice_Backing_Report_Compression__c invZip= new QTB_Invoice_Backing_Report_Compression__c();
        invZip.QTB_Invoice_Scheduler__c = schedule.id;
        invZip.QTB_Status__c = 'New';
        insert invZip;
        
        QTB_GenerateApexMassExtractVFCTRL  myCsvController1 = new QTB_GenerateApexMassExtractVFCTRL ();
        List<blng__Invoice__c> invLst = [Select Id, Name,blng__InvoiceStatus__c, blng__Account__c,blng__Account__r.QTB_Contract_Entity__c,
                                         blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,blng__Account__r.QTB_Bill_Cycle_Day__c,
                                         blng__Account__r.QTB_SITAD__c From blng__Invoice__c];
        set<Id> Invid = new set<Id>();
        List<id> invoicesid = new List<id>();
        Map<integer, List<blng__Invoice__c>> finalMaps = new Map<integer, List<blng__Invoice__c>>();
        integer i = invLst.size();
        for(blng__Invoice__c Inv :invLst)
        {
            Invid.add(Inv.Id);
            invoicesid.add(Inv.id);
            finalMaps.put(i,new List<blng__Invoice__c>{Inv});
        }
        
        QTB_GenerateMassInvBckngRprtBatch Backrep = new QTB_GenerateMassInvBckngRprtBatch(schedule,invZip,'Draft',invoicesid);
        Backrep.start(null);
        Backrep.execute(null, invLst);
        backrep.finish(null);
        Test.stopTest();
    }
    
    public static testMethod void methodPosted2(){
        Test.startTest();
        
        blng__InvoiceScheduler__c schedule = [select id,Name,blng__InvoiceBatches__c from blng__InvoiceScheduler__c limit 1 ];
        
        //blng__InvoiceScheduler__c blngInvoiceSchedular = QTB_TestDataFactory.createInvoiceScheduler('Norway-26th','Once');
        string invSCId = schedule.id;
        string invStatus = 'Posted';
        string invbatch = 'India IRM-1st';
        PageReference pageRef1 = Page.QTB_GenerateApexMassExtractVF;
        Test.setCurrentPage(pageRef1);
        pageRef1.getParameters().put('Id',invSCId);
        pageRef1.getParameters().put('invStatus',invStatus);
        pageRef1.getParameters().put('invBatchNumber',invbatch);
        QTB_Invoice_Backing_Report_Compression__c invZip= new QTB_Invoice_Backing_Report_Compression__c();
        invZip.QTB_Invoice_Scheduler__c = schedule.id;
        invZip.QTB_Status__c = 'New';
        insert invZip;
        
        QTB_GenerateApexMassExtractVFCTRL  myCsvController1 = new QTB_GenerateApexMassExtractVFCTRL ();
        List<blng__Invoice__c> invLst = [Select Id, Name,blng__InvoiceStatus__c, blng__Account__c,blng__Account__r.QTB_Contract_Entity__c,
                                         blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,blng__Account__r.QTB_Bill_Cycle_Day__c,
                                         blng__Account__r.QTB_SITAD__c From blng__Invoice__c];
        invLst[0].blng__InvoiceStatus__c = 'Posted';
        update invLst;
        set<Id> Invid = new set<Id>();
        List<id> invoicesid = new List<id>();
        Map<integer, List<blng__Invoice__c>> finalMaps = new Map<integer, List<blng__Invoice__c>>();
        integer i = invLst.size();
        for(blng__Invoice__c Inv :invLst)
        {
            Invid.add(Inv.Id);
            invoicesid.add(Inv.id);
            finalMaps.put(i,new List<blng__Invoice__c>{Inv});
        }
        
        QTB_GenerateMassInvBckngRprtBatch Backrep = new QTB_GenerateMassInvBckngRprtBatch(schedule,invZip,invStatus,invoicesid);
        Backrep.start(null);
        Backrep.execute(null, invLst);
        backrep.finish(null);
        Test.stopTest();
    }
}