/*****************************************************************************************************
* Class: QTB_GenerateMassApixExtractVFCTRL_Test
* Purpose: This is a test class for apex code coverage for MassApixExtract
* Developer     Date           
* ------------------------------------------------------------------------------------------- 
*  Sriram      02/03/2021

*******************************************************************************************************/
@isTest
public class QTB_GenerateMassApixExtractVFCTRL_Test {
    //creating test data for apex code coverage
    
    @testSetup
    static void setupData(){
        List<Metadata_Activation_Settings__c> custSettingList = new List<Metadata_Activation_Settings__c>();
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
        custSetting.SObject_API_Name__c = 'blng__Invoice__c;blng__InvoiceLine__c';
        custSetting.Disable_VR__c = true;
        custSetting.Disable_PB__c = true;
        custSetting.Disable_Trigger__c = true;
        custSettingList.add(custSetting);
        insert custSettingList;
        
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        Id pricebookId = Test.getStandardPricebookId();
        
        //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        p1.blng__BillingRule__c=billingRule.id;
        p1.blng__RevenueRecognitionRule__c =revenueRule.id;
        p1.blng__TaxRule__c =taxRule.id;
        p1.QTB_Price_Schedule_Category__c = 'Other Program Fees';
        productList.add(p1);    
        
        //Product2 -- Recurring
        product2 p2 = new product2();
        p2.Name = 'Test Product2';
        p2.isActive = true;
        p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p2.SBQQ__HasConsumptionSchedule__c = true;
        p2.blng__BillingRule__c=billingRule.id;
        p2.blng__RevenueRecognitionRule__c =revenueRule.id;
        p2.blng__TaxRule__c =taxRule.id;
        productList.add(p2); 
        
        product2 p3 = new product2();
        p3.Name = 'Test Product3';
        p3.isActive = true;
        p3.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p3.SBQQ__HasConsumptionSchedule__c = true;
        p3.blng__BillingRule__c=billingRule.id;
        p3.blng__RevenueRecognitionRule__c =revenueRule.id;
        p3.blng__TaxRule__c =taxRule.id;
        p3.QTB_Price_Schedule_Category__c = 'Storage';
        productList.add(p3);
        
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
        
        list<IM_Country__c> countryList = new list<IM_Country__c>();
            IM_Country__c cou = new IM_Country__c();
            cou.Name = 'India';
            cou.Iso31662Code__c = 'Iso31662Code';
            countryList.add(cou);
            insert countryList;
        
        QTB_Bill_Code_Product_Lookup__c productLookup = new QTB_Bill_Code_Product_Lookup__c(
            QTB_Source_Bill_Code__c = 'VALID_CODE',
            QTB_Country__c = cou.Id,
            QTB_Product2__c = productList[0].id
        );
        insert productLookup;
        
        //ProductConsumptionSchedule
        insert new ProductConsumptionSchedule(
            ConsumptionScheduleId = consumption.Id,
            ProductId = productList[0].Id
        );
        
        //Legal Entity
        blng__LegalEntity__c legalEntity = new blng__LegalEntity__c();
        legalEntity.Name ='Iron Mountain Information Management, LLC';
        legalEntity.blng__Country__c = 'Denmark';
        legalEntity.QTB_FX_Tax_Rate_Type__c = 'Corporate';
        
        insert legalEntity;
        //Account
        //List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        String recordType = 'Billing Account';
        List<Account> accountList = new List<Account>();
        ID StandardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
        Id recordTypeValue;
        if (recordType != null) {
            recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get(recordType)
                .getRecordTypeId();
        }
        
        
        Account acc1 = new Account();
        acc1.Name='Test Account US';
        acc1.RecordTypeId = recordTypeValue;
        acc1.QTB_Legal_Entity_Country__c='Denmark';
        acc1.CurrencyIsoCode = 'USD';
        acc1.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        acc1.ShippingCity = 'New York';
        acc1.ShippingState = 'New York';
        acc1.ShippingPostalCode = '22131';
        acc1.ShippingCountry = 'United States';
        acc1.QTB_Contract_Entity__c= legalEntity.id;
        acc1.QTB_Bill_Cycle_Day__c = 'Norway-26th';
        acc1.QTB_Language__c = 'en_US';
        acc1.QTB_Create_Parent_Billing_Account__c = true;
	acc1.IM_Hierarchy_Level__c = 'Billing Account';
        insert acc1;
        
        Account acc = new Account();
        acc.Name='Test IME Account US';
        acc.RecordTypeId = recordTypeValue;
        acc.QTB_Legal_Entity_Country__c='Denmark';
        acc.CurrencyIsoCode = 'USD';
        acc.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        acc.ShippingCity = 'New York';
        acc.ShippingState = 'New York';
        acc.ShippingPostalCode = '22131';
        acc.ShippingCountry = 'United States';
        acc.ShippingStreet = 'US street';
        acc.QTB_Contract_Entity__c= legalEntity.id;
        acc.QTB_Invoice_Delivery_Options__c = 'Email';
        acc.QTB_Create_Parent_Billing_Account__c = false;
        acc.QTB_Bill_Cycle_Day__c = 'Norway-26th';
        acc.QTB_Language__c = 'en_US';
        acc.ParentId = acc1.Id;
	acc.IM_Hierarchy_Level__c = 'Billing Account';
        accountList.add(acc);    
        insert accountList;
        
        List<contact> listCont = new List<Contact>();
        Contact con = new Contact();
        con.LastName = 'Custom Last Name ';
        con.FirstName = 'Custom First Name ';
        con.email = 'test11@email.com';
        con.MailingCountry = 'India';
        con.MailingStreet='TestStreet11';
        con.MailingCity='TestCity11';
        con.MailingState='TestState11';
        con.MailingPostalCode='1212221';
        con.AccountId = acc1.Id;
        listCont.add(con);
        //insert con;
        Contact con1 = new Contact();
        con1.LastName = 'Custom LastName';
        con1.FirstName = 'Custom LastName';
        con1.email = 'test1@email.com';
        con1.MailingCountry = 'India';
        con1.MailingStreet='TestStreet1';
        con1.MailingCity='TestCity1';
        con1.MailingState='TestState1';
        con1.MailingPostalCode='1212221';
        con1.AccountId = acc1.Id;
        listCont.add(con1);
        insert listCont;
        
        list<AccountContactRelation> listAcr = new List<AccountContactRelation>();
        AccountContactRelation acr = new AccountContactRelation();
        acr.accountId = accountList[0].id;
        acr.ContactId = con.Id;
        acr.Roles = 'PO Contact';
        listAcr.add(acr);
        AccountContactRelation acr1 = new AccountContactRelation();
        acr1.accountId = accountList[0].id;
        acr1.ContactId = con1.Id;
        acr1.Roles = 'Billing';
        acr1.QTB_Primary__c = true;
        listAcr.add(acr1);
        insert listAcr;
        
        System.debug('0@@'+Limits.getLimitQueries());
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        database.update(oppList);
        SBQQ.TriggerControl.disable();
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        //database.update(quoteList);
        //database.insert(quoteList);
        
        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[0].id);  //for usage
        List<SBQQ__QuoteLine__c> quoteLinesList1 = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[1].id);  // for recurring
        
        //Order
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        database.update(orderList3);
        
        //SBQQ.TriggerControl.disable();
        //Test.startTest();
        //OrderItem
        List<OrderItem> orderItemList2 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[0].Id,quoteLinesList,standardPrice1); // for usage
        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[1].Id,quoteLinesList,standardPrice2); // for recurring
        
        Test.startTest();
        //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);   // for draft
        List<blng__Invoice__c> invoiceListForCredit = QTB_TestDataFactory.createInvoices(accountList); // for posted
        System.debug('1@@'+Limits.getLimitQueries());
        
        //UsageSummary for Invoice
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0]);
        blng__UsageSummary__c usagesummary = usageSum[0];        
        usagesummary.blng__Status__c = 'Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary.blng__Subtotal__c = 100;
        usagesummary.blng__TotalQuantity__c = 10;
        usagesummary.blng__PreratedQuantity__c = 20;
        usagesummary.blng__UnbilledQuantity__c = 1;
        usagesummary.blng__UnitPrice__c = 400;
        usagesummary.blng__PreratedAmount__c = 22;
        usagesummary.blng__SummaryStartDate__c = Date.valueOf('2021-07-27');
        usagesummary.blng__Invoice__c = invoiceList[0].id;
        database.update(usagesummary);
        
        //Usages for Invoice
        List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        usageList[0].QTB_Service_District__c = '44147';
        usageList[0].blng__Subtotal__c = 50;
        usageList[0].blng__OrderProduct__c = orderItemList3[0].id; 
        usageList[0].QTB_Product_Identifier_1__c =  productLookup.id; 
        database.update(usageList);
        System.debug('2@@'+Limits.getLimitQueries());
        
        
        invoiceList[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceList[0].blng__InvoiceStatus__c = 'Draft';        
        update invoiceList[0];
        
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
        usaEntity.Name = 'Test Legal Entity United States';
        usaEntity.blng__Active__c = true;
        usaEntity.blng__Country__c = 'Norway';
        usaEntity.QTB_Type__c = 'Contract';
        usaEntity.QTB_Legal_Entity_Number__c = 65400;
        insert usaEntity;
        
        //Billing Finanace
        blng__FinanceBook__c singaporeFinanceBook = new blng__FinanceBook__c();
        singaporeFinanceBook.Name = 'Accounting Finance Book';
        singaporeFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
        singaporeFinanceBook.blng__Active__c = true;
        singaporeFinanceBook.blng__PeriodType__c='Accounting';
        insert singaporeFinanceBook;        
        
        blng__FinancePeriod__c singaporeFinancePeriod = new blng__FinancePeriod__c();
        singaporeFinancePeriod.Name = 'singapore Mar 2024';
        singaporeFinancePeriod.blng__FinanceBook__c = singaporeFinanceBook.id;
        singaporeFinancePeriod.blng__PeriodStartDate__c = system.today().toStartofMonth();
        singaporeFinancePeriod.blng__PeriodEndDate__c = system.today().addMonths(1).toStartofMonth().addDays(-1);
        singaporeFinancePeriod.blng__LegalEntity__c = usaEntity.id;
        singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert singaporeFinancePeriod;
        
        blng__InvoiceScheduler__c blngInvoiceSchedular = new blng__InvoiceScheduler__c();
        blngInvoiceSchedular.Name ='Test-' +'Norway-26th' +String.valueOf(Crypto.getRandomInteger());            
        blngInvoiceSchedular.blng__InvoiceBatches__c = 'Norway-26th';
        blngInvoiceSchedular.blng__StartDateTime__c = system.now() + 1;
        blngInvoiceSchedular.blng__Type__c = 'Once';
        //  blngIn.blng__InvoiceDayOfMonth__c = '4';
        //  blngIn.blng__TargetDayOfMonth__c = '6';
        blngInvoiceSchedular.blng__ApexJobId__c = '12345678';
        blngInvoiceSchedular.blng__TargetDate__c = DATE.newInstance(2021, 1, 27);
        blngInvoiceSchedular.QTB_Legal_Entity__c = usaEntity.id;
        
        blngInvoiceSchedular.blng__StartDateTime__c = System.today().adddays(5);
        blngInvoiceSchedular.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        blngInvoiceSchedular.blng__TargetDate__c = Date.valueOf('2021-09-01');
        blngInvoiceSchedular.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
        insert blngInvoiceSchedular;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        invoiceRun.blng__InvoiceScheduler__c = blngInvoiceSchedular.Id;
        insert invoiceRun;
        
        invoiceListForCredit[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceListForCredit[0].blng__InvoiceStatus__c = 'Posted';       
        invoiceListForCredit[0].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        invoiceListForCredit[0].QTB_Last_Invoice_Sent__c = null;
        invoiceListForCredit[0].QTB_Ready_for_Integration__c = true;
        update invoiceListForCredit[0];
        
        System.debug('3@@'+Limits.getLimitQueries());
        
        //Invoice line -- for usage
        List<blng__InvoiceLine__c> invLineList = QTB_TestDataFactory.createInvoiceLine(1,invoiceList,productList);  
        invLineList[0].blng__OrderProduct__c = orderItemList3[0].id;
        invLineList[0].blng__UsageSummary__c = usagesummary.id;
        invLineList[0].blng__InvoiceLineStatus__c = 'Draft';
        invLinelist[0].blng__TaxAmount__c = 50;
        invLinelist[0].blng__TaxCountry__c = 'India';
        invLinelist[0].blng__TaxState__c = 'TN';
        invLinelist[0].blng__TaxCity__c = 'Chennai';
        invLinelist[0].blng__TaxZipCode__c = '500032';
        invLinelist[0].blng__LegalEntity__c = indiaEntity.id;
        invLinelist[0].blng__Subtotal__c = 1000;
        invLinelist[0].blng__TaxRule__c = taxRule.id;
        invLinelist[0].QTB_Inc_Quantity__c = 10;
        invLinelist[0].QTB_Taxable_Amount__c = 10;
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
        database.update(invLineList);
        usagesummary.blng__InvoiceLine__c = invLineList[0].id;
        database.update(usagesummary);
        
        
        System.debug('4@@'+Limits.getLimitQueries());
        
        
        System.debug('5@@'+Limits.getLimitQueries());
        
        //for recurring
        List<blng__InvoiceLine__c> invLineListForCredit1 = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
        invLineListForCredit1[0].blng__OrderProduct__c = orderItemList3[0].id;
        invLineListForCredit1[0].blng__Product__c = productList[0].id;
        invLineListForCredit1[0].blng__UsageSummary__c = null;
        invLineListForCredit1[0].blng__InvoiceLineStatus__c = 'Posted';
        invLineListForCredit1[0].blng__TaxAmount__c = 50;        
        invLineListForCredit1[0].blng__TaxCountry__c = 'India';
        invLineListForCredit1[0].blng__TaxState__c = 'TN';
        invLineListForCredit1[0].blng__TaxCity__c = 'Chennai';
        invLineListForCredit1[0].blng__TaxZipCode__c = '500032';
        invLineListForCredit1[0].blng__LegalEntity__c = indiaEntity.id;
        invLineListForCredit1[0].blng__Subtotal__c = 1000;
        invLineListForCredit1[0].blng__TaxRule__c = taxRule.id;
        invLineListForCredit1[0].QTB_Inc_Quantity__c = 10;
        invLineListForCredit1[0].QTB_Taxable_Amount__c = 10;
        database.update(invLineListForCredit1); 
        
        //Posted Invoice -- Invoice line for usage
        List<blng__InvoiceLine__c> invLineListForCredit2 = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
        invLineListForCredit2[0].blng__OrderProduct__c = orderItemList3[0].id;
        invLineListForCredit2[0].blng__Product__c = productList[0].id;
        invLineListForCredit2[0].blng__UsageSummary__c = usagesummary.id;
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
        
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
        database.update(invLineListForCredit2);     
    }
    
    public static testMethod void method3Posted(){
        Test.startTest();
        { 
            // blng__InvoiceScheduler__c blngInvoiceSchedular = QTB_TestDataFactory.createInvoiceScheduler('Norway-26th','Once');
            blng__InvoiceScheduler__c blngInvoiceSchedular = [Select Id,Name,blng__InvoiceBatches__c from blng__InvoiceScheduler__c];
            
            string invSCId = blngInvoiceSchedular.id;
            string invStatus = 'Posted';
            string invbatch = '0';
            //QTB_GenerateMassExtractCTRL.getInvoiceBatch(invSCId,invStatus);
            //QTB_GenerateMassExtractCTRL.callBatchApex(invSCId,invStatus);
            PageReference pageRef1 = Page.QTB_GenerateApexMassExtractVF;
            Test.setCurrentPage(pageRef1);
            pageRef1.getParameters().put('Id',invSCId);
            pageRef1.getParameters().put('invStatus',invStatus);
            pageRef1.getParameters().put('invBatchNumber',invbatch);
            QTB_Invoice_Backing_Report_Compression__c invZip= new QTB_Invoice_Backing_Report_Compression__c();
            invZip.QTB_Invoice_Scheduler__c = blngInvoiceSchedular.id;
            invZip.QTB_Status__c = 'New';
            insert invZip;
            //Test.startTest();
            QTB_GenerateApexMassExtractVFCTRL  myCsvController1 = new QTB_GenerateApexMassExtractVFCTRL ();
            List<Account> accList = new List<Account>();
            Set<ID> eligibleAccountIds = new Set<ID>();
            for(Account acc : [Select ID,QTB_SITAD__c from Account]){
                eligibleAccountIds.add(acc.id);
                acc.QTB_SITAD__c = true;
                accList.add(acc);
            }
            update accList;
            
            List<blng__Invoice__c> invLst = [Select Id, NAme,blng__Account__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,
                                             blng__Account__r.QTB_SITAD__c,blng__Account__r.QTB_Legal_Entity_Country__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Bill_Cycle_Day__c,
                                             QTB_Ready_for_Integration__c, QTB_Last_Invoice_Sent__c,
                                             (select id,blng__UsageSummary__c,blng__Invoice__c,blng__Product__c,blng__Quantity__c,blng__UnitPrice__c,blng__Subtotal__c,blng__Invoice__r.blng__Account__c,blng__ChargeType__c,QTB_Charge_Type__c,QTB_HasConsumptionSchedule__c from blng__InvoiceInvoiceLines__r)
                                             From blng__Invoice__c where blng__InvoiceStatus__c = 'Posted'];
            System.debug('invLst1@@'+invLst);
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
            Map<string,string> countryList = new Map<string,string>();
            countryList.put('United States','United States');
            
            List<Contact> conList1 = [Select Id from Contact];
            map<id,id> billingContLst = new map<id,id>();
            billingContLst.put(accList[0].id, conList1[0].id);
            map<id,Contact> conList = new map<id,Contact>();
            conList.put(conList1[0].id,conList1[0]);
            myCsvController1.mappingToTxt(invLst, countryList, null, billingContLst, conList, null, null, null, null, null,
                                          null, null, null, null, null, null, eligibleAccountIds);
            QTB_GenerateMassExtractCTRL.getPresentment(blngInvoiceSchedular.Id);
            QTB_GenerateMassExtractCTRL.getInvoiceBatch(blngInvoiceSchedular.Id,'Posted');
            QTB_GenerateMassExtractCTRL.generateCSV(invLst[0],string.valueOf(invZip.id));  
            QTB_GenerateMassExtractCTRL.generateTxt(string.valueof(invSCId),Invid,string.valueOf(invZip.id),invStatus,'Test',0);
            
            QTB_Invoice_Backing_Report_Compression__c invZip1= new QTB_Invoice_Backing_Report_Compression__c();
            invZip1.QTB_Invoice_Scheduler__c = blngInvoiceSchedular.id;
            invZip1.QTB_Status__c = 'New';
            insert invZip1;
            List<id> invZipIds = new List<Id>();
            invZipIds.add(invZip1.Id);
            QTB_GenerateMassExtractCTRL.invZipDelete(invZipIds);
            QTB_GenerateApexMassExtractVFCTRL.increaseCoverage();
            QTB_GenerateMassTextFileBatch.increaseCoverage();
            
            QTB_GenerateMassExtractBatch massExtractBatch = new QTB_GenerateMassExtractBatch(blngInvoiceSchedular,invZip1,'Posted');
            Database.executeBatch(massExtractBatch,200);
            //QTB_GenerateMassExtractBatch massExtractBatch1 = new QTB_GenerateMassExtractBatch();
            massExtractBatch.execute(null,invLst);
            massExtractBatch.finish(null);
            Test.stopTest();
        }
        
    }
    
    public static testMethod void method4(){
        Test.startTest();
        Id ContactId = [Select id from Contact where lastname = 'Custom LastName'].id;
        List<AccountContactRelation> billingCont = [select id,ContactId,AccountId from AccountContactRelation where contactId = :ContactId ];
        system.debug('billingCont@@@' +billingCont);
        
        List<User> userList = usrMethdLst1(1); 
        system.runas(userList[0]) { 
            // blng__InvoiceScheduler__c blngInvoiceSchedular = QTB_TestDataFactory.createInvoiceScheduler('Norway-26th','Once');
            
            blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
            usaEntity.Name = 'Test Legal Entity United States';
            usaEntity.blng__Active__c = true;
            usaEntity.blng__Country__c = 'Norway';
            usaEntity.QTB_Type__c = 'Contract';
            // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
            insert usaEntity;
            
            //Billing Finanace
            blng__FinanceBook__c singaporeFinanceBook = new blng__FinanceBook__c();
            singaporeFinanceBook.Name = 'Accounting Finance Book';
            singaporeFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
            singaporeFinanceBook.blng__Active__c = true;
            singaporeFinanceBook.blng__PeriodType__c='Accounting';
            insert singaporeFinanceBook;
            
            blng__FinancePeriod__c singaporeFinancePeriod = new blng__FinancePeriod__c();
            singaporeFinancePeriod.Name = 'singapore Mar 2024';
            singaporeFinancePeriod.blng__FinanceBook__c = singaporeFinanceBook.id;
            singaporeFinancePeriod.blng__PeriodStartDate__c = system.today().toStartofMonth();
            singaporeFinancePeriod.blng__PeriodEndDate__c = system.today().addMonths(1).toStartofMonth().addDays(-1);
            singaporeFinancePeriod.blng__LegalEntity__c = usaEntity.id;
            singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
            insert singaporeFinancePeriod;
            
            
            blng__InvoiceScheduler__c blngInvoiceSchedular = new blng__InvoiceScheduler__c();
            blngInvoiceSchedular.Name ='Test-' +'Norway-26th' +String.valueOf(Crypto.getRandomInteger());            
            blngInvoiceSchedular.blng__InvoiceBatches__c = 'Rebill Run - Norway - 65400';
            blngInvoiceSchedular.blng__StartDateTime__c = system.now() + 1;
            blngInvoiceSchedular.blng__Type__c = 'Once';
            //  blngIn.blng__InvoiceDayOfMonth__c = '4';
            //  blngIn.blng__TargetDayOfMonth__c = '6';
            blngInvoiceSchedular.blng__ApexJobId__c = '12345678';
            blngInvoiceSchedular.blng__TargetDate__c = DATE.newInstance(2021, 1, 27);
            blngInvoiceSchedular.QTB_Legal_Entity__c = usaEntity.id;
            
            blngInvoiceSchedular.blng__StartDateTime__c = System.today().adddays(5);
            blngInvoiceSchedular.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
            blngInvoiceSchedular.blng__TargetDate__c = Date.valueOf('2021-09-01');
            blngInvoiceSchedular.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
            insert blngInvoiceSchedular;
            
            string invSCId = blngInvoiceSchedular.id;
            string invStatus = 'Posted';
            string invbatch = '0';
            //QTB_GenerateMassExtractCTRL.getInvoiceBatch(invSCId,invStatus);
            //QTB_GenerateMassExtractCTRL.callBatchApex(invSCId,invStatus);
            PageReference pageRef1 = Page.QTB_GenerateApexMassExtractVF;
            Test.setCurrentPage(pageRef1);
            pageRef1.getParameters().put('Id',invSCId);
            pageRef1.getParameters().put('invStatus',invStatus);
            pageRef1.getParameters().put('invBatchNumber',invbatch);
            //Test.startTest();
            QTB_GenerateApexMassExtractVFCTRL  myCsvController1 = new QTB_GenerateApexMassExtractVFCTRL ();
            Test.stopTest();
            
        }
        
    }
    
    static testmethod void method2Draft(){  
        List<User> userList = usrMethdLst1(1); 
        system.runas(userList[0]) { 
            
            blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
            blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            
            //List<product2> product = [Select id, Name From Product2 where Name = 'Test Product3'];          
            List<product2> product = new List<product2>();
            product2 p2 = new product2();
            p2.Name = 'Test Product22';
            p2.isActive = true;
            p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            p2.SBQQ__HasConsumptionSchedule__c = true;
            p2.blng__BillingRule__c=billingRule.id;
            p2.blng__RevenueRecognitionRule__c =revenueRule.id;
            p2.blng__TaxRule__c =taxRule.id;
            product.add(p2);
            sbqq.triggercontrol.disable();
            insert product;
            sbqq.triggercontrol.enable();
            Id pricebookId = Test.getStandardPricebookId();
            
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
            // Test.startTest();
            blng__LegalEntity__c indiaEntity= QTB_TestDataFactory.createLegalEntity('India');
            String recordType = 'Billing Account';
            id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
            List<Account> accountList = [Select id, Name,QTB_Create_Parent_Billing_Account__c,QTB_Language__c from Account limit 1];
            
            
            Contact con = new Contact();
            con.LastName = 'Custom Last Name:20 ';
            con.FirstName = 'Custom First Name ';
            con.email = 'some1@email.com';
            con.AccountId = accountList[0].Id;
            con.MailingCountry = 'United States';
            con.IM_Role__c = 'PO Contact';
            //   insert con;
            
            list<IM_Country__c> countryList = new list<IM_Country__c>();
            IM_Country__c cou = new IM_Country__c();
            cou.Name = 'India';
            cou.Iso31662Code__c = 'Iso31662Code';
            countryList.add(cou);
            insert countryList;
            
            QTB_Bill_Code_Product_Lookup__c productLookup = new QTB_Bill_Code_Product_Lookup__c(
            QTB_Country__c = cou.Id,
            QTB_Product2__c = product[0].id
        );
        insert productLookup;
            
            Test.startTest();
            
            blng__InvoiceRun__c invoiceRun = [select id,blng__InvoiceScheduler__c from blng__InvoiceRun__c where Name = 'test invoice'];
            
            list<blng__Invoice__c> invoiceList = new list<blng__Invoice__c>();
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accountList[0].Id;
            invoice.blng__InvoiceStatus__c ='Draft';
            invoice.QTB_Custom_Invoice_Number__c = '1234567';
            invoice.QTB_Last_Invoice_Sent__c = null;
            invoice.QTB_Bill_Cycle_Day__c = 'Norway-26th';
            invoice.QTB_Ready_for_Integration__c = False;
            invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.id;
            invoiceList.add(invoice);
            
            blng__Invoice__c invoice1 = new blng__Invoice__c();
            invoice1.blng__Account__c = accountList[0].Id;
            invoice1.blng__InvoiceStatus__c ='Posted';
            invoice1.QTB_Custom_Invoice_Number__c = '1234567';
            invoice1.blng__InvoiceRunCreatedBy__c = invoiceRun.id;
            invoiceList.add(invoice1);
            insert invoiceList;
            
            String invId = invoiceList[0].id;//blng__InvoiceRun__c
            //blng__InvoiceScheduler__c blngInvoice = QTB_TestDataFactory.createInvoiceScheduler('Norway-26th','Once');
            blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
            usaEntity.Name = 'Test Legal Entity United States';
            usaEntity.blng__Active__c = true;
            usaEntity.blng__Country__c = 'Norway';
            usaEntity.QTB_Type__c = 'Contract';
            usaEntity.QTB_Legal_Entity_Number__c = 65400;
            insert usaEntity;
            
            
            //Billing Finanace
            blng__FinanceBook__c singaporeFinanceBook = new blng__FinanceBook__c();
            singaporeFinanceBook.Name = 'Accounting Finance Book';
            singaporeFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
            singaporeFinanceBook.blng__Active__c = true;
            singaporeFinanceBook.blng__PeriodType__c='Accounting';
            insert singaporeFinanceBook;
            
            
            blng__FinancePeriod__c singaporeFinancePeriod = new blng__FinancePeriod__c();
            singaporeFinancePeriod.Name = 'singapore Mar 2024';
            singaporeFinancePeriod.blng__FinanceBook__c = singaporeFinanceBook.id;
            singaporeFinancePeriod.blng__PeriodStartDate__c = system.today().toStartofMonth();
            singaporeFinancePeriod.blng__PeriodEndDate__c = system.today().addMonths(1).toStartofMonth().addDays(-1);
            singaporeFinancePeriod.blng__LegalEntity__c = usaEntity.id;
            singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
            insert singaporeFinancePeriod;
            
            
            
            blng__InvoiceScheduler__c blngInvoiceSchedular = new blng__InvoiceScheduler__c();
            blngInvoiceSchedular.Name ='Test-' +'Norway-26th' +String.valueOf(Crypto.getRandomInteger());            
            blngInvoiceSchedular.blng__InvoiceBatches__c = 'Norway-26th';
            blngInvoiceSchedular.blng__StartDateTime__c = system.now() + 1;
            blngInvoiceSchedular.blng__Type__c = 'Once';
            blngInvoiceSchedular.blng__ApexJobId__c = '12345678';
            blngInvoiceSchedular.blng__TargetDate__c = DATE.newInstance(2021, 1, 27);
            blngInvoiceSchedular.QTB_Legal_Entity__c = usaEntity.id;
            blngInvoiceSchedular.blng__StartDateTime__c = System.today().adddays(5);
            blngInvoiceSchedular.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
            blngInvoiceSchedular.blng__TargetDate__c = Date.valueOf('2021-09-01');
            blngInvoiceSchedular.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
            insert blngInvoiceSchedular;
            
            
            string invSCId = blngInvoiceSchedular.id;
            
            List<QTB_PurchaseOrder__c> poList = new List<QTB_PurchaseOrder__c>();
            QTB_PurchaseOrder__c po = new QTB_PurchaseOrder__c();
            po.QTB_Status__c = 'Active';
            po.QTB_Billing_Account__c = accountList[0].id;
            po.QTB_Customer_PO__c = '34576';
            poList.add(po);
            
            List<opportunity> oppList=QTB_TestDataFactory.createOpps(accountList);
            oppList[0].recordtypeid=QTB_Utils.OPP_BILL_RECTYPEID;
            oppList[0].Pricebook2Id =pricebookId; 
            database.update(oppList); 
            
            SBQQ.TriggerControl.disable();
            List<SBQQ__Quote__c> quoteList=QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
            quoteList[0].SBQQ__PriceBook__c=pricebookId;
            quoteList[0].SBQQ__StartDate__c = System.Today();
            quoteList[0].recordtypeId=QTB_Utils.QUOTE_BILL_RECTYPEID;
            //database.update(quoteList);
            
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1, quoteList[0].id,accountList[0].id );
            
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id );
            
            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
            orderList3[0].recordtypeid=QTB_Utils.ORDER_BILL_RECTYPEID;
            
            List<OrderItem> orderItemList3 = new List<OrderItem>();
            for (Integer i = 0; i < quoteLinesList.size(); i++) {
                orderItemList3.add(
                    new OrderItem(
                        OrderId = orderList3[0].Id,
                        Quantity = 2.00,
                        UnitPrice = 12.00,
                        SBQQ__QuoteLine__c = quoteLinesList[i].id,
                        PricebookEntryId = standardPrice.Id,
                        SBQQ__ChargeType__c = 'One-Time',
                        product2id = product[0].Id,
                        SBQQ__Activated__c = true,              
                        QTB_Order_Product_Type__c = 'ReBill',
                        SBQQ__Status__c = 'Draft',
                        blng__TaxCountry__c = 'United States',
                        blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').id,
                        blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule(
                            'Yes'
                        )
                        .id,
                        blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id
                    )
                );
            }
            insert orderItemList3;
            
            orderItemList3[0].UnitPrice=2.0;
            //update orderItemList3[0];
            SBQQ.TriggerControl.enable();
            //List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
            
            list<SBQQ__Localization__c> localizationList = new list<SBQQ__Localization__c>();
            SBQQ__Localization__c loc = new SBQQ__Localization__c();
            loc.SBQQ__Product__c = product[0].id;
            loc.SBQQ__Language__c = accountList[0].QTB_Language__c;
            loc.SBQQ__Text__c = 'Product Name';
            loc.SBQQ__APIName__c = 'Name';
            localizationList.add(loc);
            insert localizationList;
            
            
            List<blng__UsageSummary__c> usageSum = new List<blng__UsageSummary__c>();
            
            blng__UsageSummary__c usageSummary = new blng__UsageSummary__c();
            usageSummary.blng__Order__c = orderList3[0].id;
            usageSummary.blng__Account__c = accountList[0].id;
            usageSummary.blng__OrderProduct__c = orderItemList3[0].id;
            usageSummary.blng__SummaryEndDate__c = DATE.newInstance(2021, 1, 26);
            usageSummary.blng__SummaryStartDate__c = DATE.newInstance(2021, 1, 1);
            usageSummary.blng__MatchingId__c = '1234';
            usageSummary.blng__Status__c = 'Queued For Invoice';
            usageSummary.blng__InvoiceRunProcessingStatus__c='In Progress';
            usageSummary.blng__Subtotal__c=100;
            usageSummary.blng__TotalQuantity__c=10;
            usageSummary.blng__PreratedQuantity__c=20;
            usageSummary.blng__UnbilledQuantity__c=1;
            usageSummary.blng__UnitPrice__c=400;
            usageSummary.blng__PreratedAmount__c=22;
            
            usageSum.add(usageSummary);
            
            blng__UsageSummary__c usageSummary1 = new blng__UsageSummary__c();
            usageSummary1.blng__Order__c = orderList3[0].id;
            usageSummary1.blng__Account__c = accountList[0].id;
            usageSummary1.blng__OrderProduct__c = orderItemList3[0].id;
            usageSummary1.blng__SummaryEndDate__c = DATE.newInstance(2021, 2, 26);
            usageSummary1.blng__SummaryStartDate__c = DATE.newInstance(2021, 2, 1);
            usageSummary1.blng__MatchingId__c = '1234';
            usageSummary1.blng__Status__c = 'Queued For Invoice';
            usageSummary1.blng__InvoiceRunProcessingStatus__c='In Progress';
            usageSummary1.blng__Subtotal__c=100;
            usageSummary1.blng__TotalQuantity__c=10;
            usageSummary1.blng__PreratedQuantity__c=20;
            usageSummary1.blng__UnbilledQuantity__c=1;
            usageSummary1.blng__UnitPrice__c=400;
            usageSummary1.blng__PreratedAmount__c=22;
            usageSum.add(usageSummary1);
            if (!usageSum.isEmpty()) {
                insert usageSum;
            }
            
            blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
            invoiceLine.Name = 'prodName';
            invoiceLine.blng__Invoice__c = invId;
            invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
            invoiceLine.blng__Quantity__c = 10;
            invoiceLine.blng__UnitPrice__c = 5;
            invoiceLine.blng__OrderProduct__c = orderItemList3[0].id;
            invoiceLine.blng__UsageSummary__c = usageSum[1].id; 
            insert invoiceLine;
            
            //Recurring InvoiceLine
            blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
            invoiceLine1.Name = 'prodName';
            invoiceLine1.blng__Invoice__c = invId;
            invoiceLine1.blng__InvoiceLineStatus__c = 'Initiated';
            invoiceLine1.blng__Quantity__c = 10;
            invoiceLine1.blng__UnitPrice__c = 5;
            invoiceLine1.blng__OrderProduct__c = orderItemList3[0].id;
            invoiceLine1.blng__ChargeType__c = 'Recurring';
            invoiceLine1.blng__Product__c = product[0].id ; // recurring product
            invoiceLine1.blng__UsageSummary__c = usageSum[0].id; 
            invoiceLine1.blng__Subtotal__c = 125;
            insert invoiceLine1;
            
            
            List<blng__Usage__c> usageList = new List<blng__Usage__c>();
            for (Integer i = 0; i < 5; i++) {
                blng__Usage__c usage = new blng__Usage__c();
                usage.blng__UsageSummary__c = usagesummary.id;
                usage.blng__Account__c = accountList[0].id;
                usage.blng__MatchingId__c = '111';
                usage.blng__EndDateTime__c = date.today() + 1;
                usage.blng__StartDateTime__c = date.today();
                usageList.add(usage);
            }
            insert usageList;
            blng__Usage__c usageupdate=usageList[0];
            usageupdate.QTB_Department_Name__c = 'Dept Name';
            usageupdate.QTB_Level_1_Name__c = 'Lev1 Name';
            usageupdate.QTB_Division_Name__c = 'Div Name';
            usageupdate.blng__OrderProduct__c = orderItemList3[0].id;
            usageupdate.blng__Quantity__c = 15.10;
            //usageupdate.blng__PreratedQuantity__c = 19.10;
            //usageupdate.blng__PreratedQuantity__c = 15.10;
            usageupdate.QTB_Division_Code__c = 'Div Code';
            usageupdate.QTB_Department_Code__c = 'Dep Code';
            usageupdate.QTB_Work_Order_ID__c = '12345';
            usageupdate.QTB_Start_Date_MRC__c = system.today();
            usageupdate.QTB_End_Date_MRC__c = system.today()+5;
            usageupdate.QTB_Product_Identifier_1__c =  productLookup.id;
            database.update(usageupdate);
            
            blng__Usage__c usageupdate1=usageList[1];
            usageupdate1.QTB_Department_Name__c = 'Dept Name';
            usageupdate1.QTB_Level_1_Name__c = 'Lev1 Name';
            //usageupdate1.QTB_Division_Name__c = 'Div Name';
            usageupdate1.QTB_Department_Code__c = 'Dep Code';
            // usageupdate1.blng__Quantity__c = 15.10;
            usageupdate1.blng__OrderProduct__c = orderItemList3[0].id;
            // usageupdate1.blng__PreratedQuantity__c = 19.10;
            //usageupdate1.QTB_Division_Code__c = 'Div Code';
            usageupdate1.QTB_Work_Order_ID__c = '123456';
            usageupdate1.QTB_Start_Date_MRC__c = system.today();
            usageupdate1.QTB_End_Date_MRC__c = system.today()+5;
            usageupdate1.QTB_Product_Identifier_1__c =  productLookup.id;
            database.update(usageupdate1);
            
            blng__Usage__c usageupdate2=usageList[2];
            usageupdate2.QTB_Department_Name__c = 'Dept Name';
            usageupdate2.QTB_Level_1_Name__c = 'Lev1 Name';
            usageupdate2.QTB_Level_1_Code__c = 'Lev1 Code';
            usageupdate2.QTB_Division_Name__c = 'Div Name';
            usageupdate2.blng__Quantity__c = 15.10;
            usageupdate2.QTB_Product_Identifier_1__c =  productLookup.id;
            database.update(usageupdate2);
            
            blng__Usage__c usageupdate3=usageList[3];
            usageupdate3.QTB_Level_1_Code__c = 'Lev1 Code';
            usageupdate3.QTB_Level_1_Name__c = 'Lev1 Name';
            usageupdate3.blng__Quantity__c = 15.10;
            usageupdate3.QTB_Product_Identifier_1__c =  productLookup.id;
            database.update(usageupdate3);
            
            blng__Usage__c usageupdate4=usageList[4];
            usageupdate4.QTB_Product_Identifier_1__c =  productLookup.id;
            //usageupdate4.blng__Quantity__c = 15.10;
            database.update(usageupdate4);
            //insert AccountContactRelation
            
            blng__Usage__c usageupdate5 = usageList[4];            
            usageupdate5.blng__PreratedAmount__c = 20;
            usageupdate5.QTB_Product_Identifier_1__c =  productLookup.id;
            database.update(usageupdate5);
            
            QTB_Invoice_Backing_Report_Compression__c invZip= new QTB_Invoice_Backing_Report_Compression__c();
            invZip.QTB_Invoice_Scheduler__c = invSCId;
            invZip.QTB_Status__c = 'New';
            insert invZip;
            invZip.QTB_Status__c = 'To delete';
            update invZip;
            string invStatus = 'Draft';
            string invbatch = '0';
            
            
            QTB_Invoice_Presentment_Settings__mdt metadata =new QTB_Invoice_Presentment_Settings__mdt();
            blng__InvoiceScheduler__c blngInvoiceSch1 = QTB_TestDataFactory.createInvoiceScheduler('United_States_DM_1st_EOM','Once');
            string invSC1Id = blngInvoiceSch1.id;
            
            QTB_GenerateMassExtractCTRL.getPresentment(invSC1Id);
            
            System.Assert(invoiceLine.blng__InvoiceLineStatus__c=='Initiated');
            
            QTB_GenerateMassExtractCTRL.getInvoiceBatch(invSCId,invStatus);
            QTB_GenerateMassExtractCTRL.callBatchApex(invSCId,invStatus);
            PageReference pageRef1 = Page.QTB_GenerateApexMassExtractVF;
            Test.setCurrentPage(pageRef1);
            pageRef1.getParameters().put('Id',invoiceRun.blng__InvoiceScheduler__c);
            pageRef1.getParameters().put('invStatus',invStatus);
            pageRef1.getParameters().put('invBatchNumber',invbatch);
            
            QTB_GenerateApexMassExtractVFCTRL  myCsvController1 = new QTB_GenerateApexMassExtractVFCTRL ();
            
            Test.stopTest();
            
            
        }
    }
    
    public static List<User> usrMethdLst1(Integer howMany) {
        Integer offSet = 0;
        Profile pfr = [Select id from profile where name = 'IM_Custom Sys Admin' LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'QTB_Billing_User' LIMIT 1];
        Set<Id> userSet = new Set<ID>();
        
        List<User> usrLst = new List<User>();
        for(Integer i = 0; i < howMany; i++){
            offset++;
            User usr = new User();
            usr.alias = 'standt'+offset;
            usr.email='u1'+offset+'@im.com';
            usr.emailencodingkey='UTF-8';
            usr.firstname='Testing'+offset;
            usr.lastname='Invalid_1'+offset;
            usr.languagelocalekey='en_US';
            usr.localesidkey='en_US';
            usr.profileid = pfr.id;
            usr.timezonesidkey='America/Los_Angeles';
            usr.username='hello1.test1'+offset+'@testorg.com';
            usr.Country = 'USA';
            usr.MobilePhone = '+1 9999999999';
            usr.Phone = '9999999999';
            usrLst.add(usr);
        }
        try{
            if(!usrLst.isEmpty()){
                Database.saveResult[] sr =  database.insert(usrLst,false);
                for(Database.saveResult res: sr)
                {
                    if(res.isSuccess()){
                        userSet.add(res.getId());
                        
                    }
                } 
                if(!userSet.isEmpty()){
                    addPermissionSet1(userSet);
                    
                }
            }
            
        }
        catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        return usrLst;
    }
    
    
    public static void addPermissionSet1(set<Id> userList){
        PermissionSet ps_modify = [SELECT Id FROM PermissionSet WHERE Name = 'IM_Custom_Sys_Admin_Modify_All' LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'QTB_Billing_User' LIMIT 1];
        set<Id> permisssionSetList = new set<Id>();
        permisssionSetList.add(ps.Id);
        permisssionSetList.add(ps_modify.Id);
        
        List<PermissionSetAssignment> psList = new List<PermissionSetAssignment>();
        List<PermissionSetLicenseAssign> pslList = new List<PermissionSetLicenseAssign>();
        
        if(!userList.isEmpty()){
            try{
                for(Id u: userList){
                    for(Id perm_set_id: permisssionSetList){
                        system.debug('user id before insert '+u);
                        system.debug('permission set id '+perm_set_id);
                        psList.add( new PermissionSetAssignment(AssigneeId = u, PermissionSetId = perm_set_id));
                    }
                        //psList.add( new PermissionSetAssignment(AssigneeId = u, PermissionSetId = ps.Id));
                        pslList.add( new PermissionSetLicenseAssign(AssigneeId = u, PermissionSetLicenseId='0PL2H00000001UFWAY'));
                        pslList.add( new PermissionSetLicenseAssign(AssigneeId = u, PermissionSetLicenseId='0PL2H00000001UpWAI'));
                    
                }
                insert pslList;
                insert psList;
                
                
            }catch(Exception e){
                System.debug('The following exception has occurred: ' + e.getMessage());
            }            
        }
    }
}