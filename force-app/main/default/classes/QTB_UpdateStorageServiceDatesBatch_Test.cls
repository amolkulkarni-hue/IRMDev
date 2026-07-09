/*****************************************************************************************************
* Class: QTB_UpdateStorageServiceDatesBatch_Test
* Author: Virtusa
* Purpose: This is a test class for QTB_UpdateStorageServiceDatesOnInvBatch
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Virtusa    25/04.2025
*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_UpdateStorageServiceDatesBatch_Test {
     @testSetup
    static void setup() {
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
      custSetting.SObject_API_Name__c = 'SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;AccountContactRelation;blng__Usage__c;blng__UsageSummary__c;order;OrderItem;Opportunity;blng__InvoiceLine__c;blng__CreditNote__c';
      custSetting.Disable_VR__c = true;
      custSetting.Disable_PB__c = true;
      custSetting.Disable_Trigger__c = true;
      // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      insert custSetting;
        Credit_ReBill_InvoiceSchedulerValidation__c invSchCust = new Credit_ReBill_InvoiceSchedulerValidation__c();
        invSchCust.Name = 'Finland';
        invSchCust.isRunning__c = false;
        insert invSchCust;
        
        QTB_Billing_Countries__c BillingCountries = new QTB_Billing_Countries__c();
        BillingCountries.Name = 'Singapore';
        BillingCountries.Legal_entity_country__c = 'Singapore' ;
        insert BillingCountries;
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        //Product
        List<Product2> product = QTB_TestDataFactory.createProducts(1);
        product[0].blng__BillingRule__c = billingRule.ID;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.ID;
        product[0].blng__TaxRule__c = taxRule.ID;
        product[0].QTB_Price_Schedule_Category__c = 'Services';
        Database.update(product);
        
        //Pricebook
        ID pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        //Legal Entity
        blng__LegalEntity__c usEntity = new blng__LegalEntity__c();
        usEntity.Name = 'Test Legal Entity United States';
        usEntity.blng__Active__c = true;
        usEntity.blng__Country__c = 'United States';
        usEntity.QTB_Type__c = 'Contract';
        usEntity.QTB_Tax_Applicability__c = 'Flat Rate';
        usEntity.QTB_Service_Date_on_Invoice__c = 'Service Range';
        usEntity.QTB_Storage_Date_on_Invoice__c = 'Regular Storage';
        insert usEntity;
        
        //Account
        List<Account> accountList = new List<Account>();
        ID standardrecordID = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
        ID recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
        for (Integer i = 0; i < 2; i++) {
            Account a = new Account();
            a.Name = (a.Name == null ? 'Test' : a.Name) + i;
            a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
            a.RecordTypeId = recordTypeValue;
            a.QTB_Create_Parent_Billing_Account__c = true;
            a.Name = 'Test Account';
            a.BillingCountry = 'Singapore';
            a.BillingPostalCode = '11209';
            a.BillingState = 'TN';
            a.Registration_Number__c = 'Reg';
            a.ShippingCountry = 'Singapore';
            a.QTB_Legal_Entity_Country__c='Singapore';
            if(i == 0){
                a.QTB_Legal_Entity_Country__c='United States';
                a.QTB_Bill_Cycle_Day__c = 'Denmark-26th';
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Quarterly';
                a.QTB_Legal_Entity__c = usEntity.Id;
                a.QTB_Contract_Entity__c = usEntity.Id;
            }
            /*if(i == 1){
                a.QTB_Legal_Entity_Country__c='United States';
                a.QTB_Bill_Cycle_Day__c = 'Denmark-26th';
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Monthly';
                a.QTB_Billing_Account_Type__c = 'Product Sales';
            }
            if(i == 2){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Monthly';
                a.QTB_Billing_Account_Type__c = 'Product Sales';
            }
            if(i == 3){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Quarterly';
                a.QTB_Billing_Account_Type__c = 'Product Sales';
            }
            if(i == 4){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Quarterly';
                a.QTB_Billing_Account_Type__c = 'Product Sales';
            }
            if(i == 5){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Semiannual';
                a.QTB_Billing_Account_Type__c = 'Product Sales';
            }
            if(i == 6){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Semiannual';
                a.QTB_Billing_Account_Type__c = 'Product Sales';
            }
            if(i == 7){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Annual';
                a.QTB_Billing_Account_Type__c = 'Product Sales';
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Annual';
                a.QTB_Billing_Account_Type__c = 'Product Sales';
            }*/
            accountList.add(a);
        }
        
        if (!accountList.isEmpty()) {
            insert accountList;
        }
        
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

        
        
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';    
        im.Active__c = true;
        insert im;
        //Account
          Account a = new Account();
            a.Name = 'testdata123';
            a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
            a.RecordTypeId = recordTypeValue;
            a.QTB_Create_Parent_Billing_Account__c = true;
            a.Name = 'Test Account';
            a.BillingCountry = 'Singapore';
            a.BillingPostalCode = '11209';
            a.BillingState = 'TN';
            a.Registration_Number__c = 'Reg';
            a.ShippingCountry = 'Singapore';
            a.QTB_Legal_Entity_Country__c='Singapore';
         insert a;
        //opportunity
        /*List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        //oppList[0].Legal_Entity__c = usEntity.ID;
        oppList[0].Billing_Country__c = im.ID;
        Database.update(oppList);*/
        
        List<Opportunity> oppList = new List<Opportunity>();
        
        Opportunity insOpp = new Opportunity();
        insOpp.name = 'testOpp';
        insOpp.AccountId = standardAccountList[0].ID;
        insOpp.CloseDate = Date.today();
        insOpp.StageName = '1 - Qualification';
        insOpp.RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
        insOpp.Amount = 500;
        insOpp.Pricebook2Id=pricebookId;
        oppList.add(insOpp);
        
        insert oppList;
        
        //Quote
        /*List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].ID,accountList[0].ID,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].QTB_IM_Legal_Entity__c = usEntity.ID;
        quoteList[0].QTB_Opportunity_Billing_Country__c = 'United States';
        Database.update(quoteList);
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].ID,accountList[0].ID);
        
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].ID,quoteGroupList[0].ID,product[0].ID);
        */
        SBQQ.TriggerControl.disable();
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,null,accountList[0].ID);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        Database.update(orderList3);
        /*List<Order> orderList2 = QTB_TestDataFactory.createCPQOrders(1,null,accountList[1].ID);
        orderList2[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        orderList2[0].QTB_OrderCategory__c = 'Rebill';
        Database.update(orderList2);*/
        
        List<OrderItem> orderItemList3 = new List<OrderItem>();
        List<OrderItem> orderItemList2 = new List<OrderItem>();
            //QTB_TestDataFactory.createCPQOrderItems(orderList3[0].ID,product[0].ID,quoteLinesList,standardPrice);
        try {
            for(Integer i = 0; i < 2; i++) {
                orderItemList3.add( new OrderItem(
                    OrderId = orderList3[0].ID,
                    Quantity = 2.00,
                    UnitPrice = 12.00,
                    //SBQQ__QuoteLine__c = quoteLines[i].ID,
                    PricebookEntryId = standardPrice.ID,
                    SBQQ__ChargeType__c = 'One-Time',
                    product2id = product[0].ID,
                    SBQQ__Activated__c = true,
                    blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').ID,
                    blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').ID,
                    blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').ID,
                    blng__HoldBilling__c = 'Yes'));
                //31276 
                /*orderItemList2.add(new OrderItem(OrderId = orderList2[0].ID,Quantity = 2.00, UnitPrice = 12.00, PricebookEntryId = standardPrice.ID,
                        SBQQ__ChargeType__c = 'One-Time', product2id = product[0].ID, SBQQ__Activated__c = true,
                        blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').ID,
                        blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').ID,
                        blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').ID,
                        blng__HoldBilling__c = 'Yes'));*/
            }
            if (!orderItemList3.isEmpty()) {
                insert orderItemList3;
            }
            /*if (!orderItemList2.isEmpty()) {
                insert orderItemList2;
            }*/
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        /*orderItemList3[0].blng__HoldBilling__c = 'Yes';
        update orderItemList3;*/
        Contact cont = new Contact();
        cont.LastName = 'test11 ';
        cont.FirstName = 'abc1 ';
        cont.email = 'so11@email.com';
        cont.AccountId = accountList[0].ID;
        cont.MailingCountry = 'Canada';
        cont.IM_Role__c = 'PO Contact';
        insert cont;
         
        Test.startTest();
       /* AccountContactRelation acr = new AccountContactRelation();
        acr.accountId = accountList[1].ID;
        acr.ContactId = cont.ID;
        acr.Roles = 'PO Contact';
        QTB_AccountContactRelationHandler accHandler = new QTB_AccountContactRelationHandler();
        accHandler.IsDisabled();
        insert acr;*/
        
         AccountContactRelation acr = new AccountContactRelation();
            acr.accountId = accountList[1].ID;
            acr.ContactId = cont.ID;
            insert acr;
            
            acr.Roles = 'PO Contact';
            update acr;
        
        List<QTB_PurchaseOrder__c> poList = new List<QTB_PurchaseOrder__c>();
        List<QTB_PurchaseOrder__c> poList1 = new List<QTB_PurchaseOrder__c>();
        Map<ID,QTB_PurchaseOrder__c> ordOldMap = new Map<ID,QTB_PurchaseOrder__c>();
        Map<ID,blng__Invoice__c> poInvMap = new Map<ID,blng__Invoice__c>();
        
        QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c(
            QTB_Billing_Account__c = accountList[1].ID,
            QTB_Status__c = 'Active',
            QTB_Start_Date__c = System.today(),
            QTB_End_Date__c = System.today(),
            QTB_PO_Type__c = 'Standard',
            QTB_Customer_PO__c = 'QW2315',
            QTB_Amount__c = 10000,
            QTB_Service_Type__c = 'Mixed');
        insert pOrder;
        poList.add(Porder);
        
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
        //Invoice
        List<blng__Invoice__c> invoiceList = new List<blng__Invoice__c>();
        //for (Account acc : accountList[0]) {
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accountList[0].ID;
            invoice.blng__InvoiceStatus__c = 'Draft';
            invoice.blng__InvoiceDate__c = System.today()-10;
            invoice.QTB_Invoice_Period__c = financePeriod.ID;
            
            invoiceList.add(invoice);
            
        
        if (!invoiceList.isEmpty()) {
            insert invoiceList;
        }
        system.debug('invoiceList - '+invoiceList);
        /*invoiceList[0].blng__InvoiceStatus__c = 'Posted';
        invoiceList[0].QTB_ReBill_Status__c = '';
        invoiceList[0].QTB_Purchase_Order__c = poList[0].ID;
        invoiceList[0].QTB_Transferred_To_Oracle__c = true;
        invoiceList[0].QTB_transfered_to_invoice_presentment__c = System.now();
        update invoiceList;
        
        for(blng__Invoice__c invlist2:invoiceList){
            if(invlist2.blng__InvoiceStatus__c == 'Posted'){
                poInvMap.put(invlist2.ID,invlist2);
            }
        } 
        
        Set<ID> invId = new  Set<ID>();
        for(blng__Invoice__c invoice : invoiceList){
            invId.add(invoice.ID);
        }
        
        System.debug('@@@inv Ids'+invId);
        
        //QTB_InvoiceHelper.makeFieldsNonEditableForPosted(invoiceList, poInvMap);
        QTB_InvoiceHelper.populateOrderFieldsOnInvoice(invoiceList);        
        
        QTB_InvoiceHelper.calculatingPOBalance(invoiceList, poInvMap);
        QTB_InvoiceHelper.updatePOForCreditAndRebill(invoiceList, poInvMap);
        //Invoice
        List<blng__Invoice__c> invoiceList2 = new List<blng__Invoice__c>();
        for (integer i = 0; i < accountList.size(); i++) {
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accountList[i].ID;
            invoice.blng__InvoiceStatus__c = 'Draft';
            if(i == 0){
                invoice.QTB_Parent_Invoice__c = invoiceList[0].ID;
                invoice.QTB_ReBill_Credit_Reason__c = '';
            }
            if(i == 1 ){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
            }
            if(i == 2){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
                invoice.QTB_Invoice_Type__c = 'ReBill';
                invoice.QTB_Parent_Invoice__c = invoiceList[0].ID;
                invoice.blng__Order__c = orderList2[0].ID; // 31276
            }
            if(i == 3 || i == 4 || i == 5 || i == 6 || i == 7 || i == 8 ){
                invoice.blng__InvoiceStatus__c = 'Posted';
                invoice.blng__InvoiceDate__c = System.today();
            }
            invoiceList2.add(invoice);
        }
        if (!invoiceList2.isEmpty()) {
            insert invoiceList2;
        }*/
        
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0] );
        //List<blng__UsageSummary__c>usageSum1 = QTB_TestDataFactory.createUsageSummary(1,accountList[1],orderList2[0],orderItemList2[0] );
        blng__UsageSummary__c usagesummary = usageSum[0];
        //blng__UsageSummary__c usagesummary1 = usageSum1[0];
        usagesummary.blng__Status__c = 'Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary.blng__Subtotal__c = 100;
        usagesummary.blng__TotalQuantity__c = 10;
        usagesummary.blng__PreratedQuantity__c = 20;
        usagesummary.blng__UnbilledQuantity__c = 1;
        usagesummary.blng__UnitPrice__c = 400;
        usagesummary.blng__PreratedAmount__c = 22;
        usagesummary.blng__Invoice__c = invoiceList[0].ID; 
        
        /*usagesummary1.blng__Status__c = 'Queued For Invoice';
        usagesummary1.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary1.blng__Subtotal__c = 100;
        usagesummary1.blng__TotalQuantity__c = 10;
        usagesummary1.blng__PreratedQuantity__c = 20;
        usagesummary1.blng__UnbilledQuantity__c = 1;
        usagesummary1.blng__UnitPrice__c = 400;
        usagesummary1.blng__PreratedAmount__c = 22;
        usagesummary1.blng__Invoice__c = invoiceList[1].ID;
        system.debug('US insert Test');*/
        Database.update(usagesummary);
        //database.update(usagesummary1);
        
        List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
        /*List<blng__Usage__c> usageList1 = QTB_TestDataFactory.createUsages(1,accountList[1],usagesummary1);
        usageList1[0].QTB_System_Generated__c = true;
        usageList1[0].blng__PreratedAmount__c = 100;
        usageList1[0].blng__PreratedQuantity__c = 10;
        usageList1[0].QTB_ServicePeriod__c = 'Apr-2025';
        usageList1[0].QTB_Start_Date_MRC__c = Date.newInstance(2022,03,01);
        usageList1[0].QTB_end_Date_MRC__c = Date.newInstance(2022,31,01);
        usageList1[0].QTB_Source_Service_Date__c = Date.newInstance(2022,03,01);
        usageList1[0].blng__UsageSummary__c=usagesummary1.ID;
        usageList1[0].blng__Account__c = accountList[1].ID;*/
        
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        usageList[0].QTB_ServicePeriod__c = 'Apr-2025';
        usageList[0].QTB_Source_Service_Date__c = Date.newInstance(2022,03,01);
        //usageList[0].QTB_end_Date_MRC__c = Date.newInstance(2022,31,01); 
        usageList[0].blng__UsageSummary__c=usagesummary.ID;
        usageList[0].blng__Account__c = accountList[0].ID;
        Database.update(usageList);    
        //Database.update(usageList1);
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'Test';
        schedule.blng__Type__c = 'Once';
        //schedule.blng__InvoiceBatches__c = 'United States-DM-1st-EOM Manual';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.today();
        schedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        schedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        schedule.QTB_Legal_Entity__c  = usEntity.ID;
        schedule.QTB_Invoice_Period__c = financePeriod.ID ;
        insert schedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Test invoice';
        invoiceRun.blng__InvoiceScheduler__c = schedule.ID;
        invoiceRun.blng__Status__c = 'Started';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
        insert invoiceRun;
        
        blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
        taxIntegration.blng__TaxEngine__c = 'Standard';
        taxIntegration.blng__Active__c = true;
        Database.insert(taxIntegration);
        
        blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
        blngTax.blng__TaxLegalEntity__c = usEntity.ID;
        blngTax.blng__TaxIntegration__c = taxIntegration.ID;
        blngTax.blng__TaxRule__c = taxRule.ID;
        blngTax.blng__TaxCode__c = 'STD-CGST';
        blngTax.QTB_Invoice_Print_Tax_Name__c = 'GST';
        Database.insert(blngTax);
        
        blng__TaxRate__c taxRate = new blng__TaxRate__c();
        taxRate.blng__LegalEntity__c = usEntity.ID;
        taxRate.blng__Priority__c = '1';
        taxRate.blng__Country__c = 'India';
        taxRate.blng__State__c = 'TN';
        taxRate.blng__City__c = 'Chennai';
        taxRate.blng__ZipCode__c = '500032';
        taxRate.blng__TaxCode__c = 'STD-CGST';
        taxRate.blng__Rate__c = 10;
        taxRate.blng__Rate__c = 9;        
        Database.insert(taxRate);
        taxRate.blng__AddressComparison__c = taxRate.blng__Country__c + '-' + taxRate.blng__State__c + '-' + taxRate.blng__City__c +
                                '-' + taxRate.blng__ZipCode__c +'-' + taxRate.blng__TaxCode__c + '-' + taxRate.blng__LegalEntity__c;
               
        Database.update(taxRate); //31276 modified
        
        // Invoice run to satisfy condn for taxratemap and invoice line both        
        List<blng__InvoiceLine__c> invLineList = QTB_TestDataFactory.createInvoiceLine(1,invoiceList,product);
        //List<blng__InvoiceLine__c> invLineList1 = QTB_TestDataFactory.createInvoiceLine(1,invoiceList,product);
        invLineList[0].blng__OrderProduct__c = orderItemList3[0].ID;
        invLineList[0].blng__UsageSummary__c = usagesummary.ID;
        invLineList[0].blng__InvoiceLineStatus__c = 'Draft';
        invLinelist[0].blng__TaxAmount__c = 50;
        invLinelist[0].blng__TaxCountry__c = 'India';
        invLinelist[0].blng__TaxState__c = 'TN';
        invLinelist[0].blng__TaxCity__c = 'Chennai';
        invLinelist[0].blng__TaxZipCode__c = '500032';
        //31276 non writeable invLinelist[0].QTB_Tax_Code__c='STD-CGST'; 
        invLinelist[0].blng__TaxTreatment__c = blngTax.ID;
        invLinelist[0].blng__TaxRule__c  = taxRule.ID;
        invLinelist[0].blng__LegalEntity__c = usEntity.ID;
        invLinelist[0].blng__Subtotal__c = 100;
        invLinelist[0].blng__TotalAmount__c = 1000;
        
        /*invLineList1[0].blng__OrderProduct__c = orderItemList2[0].ID;
        invLineList1[0].blng__UsageSummary__c = usagesummary.ID;
        invLineList1[0].blng__InvoiceLineStatus__c = 'Draft';
        invLinelist1[0].blng__TaxAmount__c = 50;
        invLinelist1[0].blng__TaxCountry__c = 'India';
        invLinelist1[0].blng__TaxState__c = 'TN';
        invLinelist1[0].blng__TaxCity__c = 'Chennai';
        invLinelist1[0].blng__TaxZipCode__c = '500032';
        invLinelist1[0].blng__TaxTreatment__c = blngTax.ID;
        invLinelist1[0].blng__TaxRule__c  = taxRule.ID;
        invLinelist1[0].blng__LegalEntity__c = usEntity.ID;
        invLinelist1[0].blng__Subtotal__c = 100;
        invLinelist1[0].blng__TotalAmount__c = 1000;*/
        update invLinelist[0];
        //update invLinelist1[0];
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
        Database.update(invLineList[0]);
        //Database.update(invLineList1[0]);
        String invoicelineComparison = taxRate.blng__Country__c + '-' + taxRate.blng__State__c + '-' + taxRate.blng__City__c +
                                '-' + taxRate.blng__ZipCode__c +'-' + taxRate.blng__TaxCode__c + '-' + taxRate.blng__LegalEntity__c;
        
        /*invoiceList2[0].blng__InvoiceStatus__c = 'Posted';
        invoiceList2[0].CurrencyIsoCode='SGD';
        update invoiceList2;
        
        
        
        QTB_InvoiceHelper.updateTaxruleForInvoiceLine(invId,taxRule.ID,blngTax.ID);
        List<QTB_Tax_Detail__c> testTax = new List<QTB_Tax_Detail__c>();
        QTB_Tax_Detail__c taxDet1 = new QTB_Tax_Detail__c(); 
        
        taxDet1.QTB_Individual_Tax_Amount__c = invLineList[0].blng__Subtotal__c *(taxRate.blng__Rate__c / 100);
        taxDet1.QTB_Invoice_Line__c = invLineList[0].ID;
        taxDet1.QTB_CalculatedTax__c = invLineList[0].blng__TaxAmount__c;
        taxDet1.QTB_Tax_Code__c = taxRate.blng__TaxCode__c;
        taxDet1.QTB_EffectiveRate__c = taxRate.blng__Rate__c;
        taxDet1.QTB_Invoice_Line_Subtotal__c = invLineList[0].blng__Subtotal__c;
        taxDet1.CurrencyIsoCode = invLineList[0].CurrencyIsoCode;
        taxDet1.QTB_TaxRateId__c = taxRate.ID;
        taxDet1.QTB_TaxType__c = taxRate.QTB_TaxDisplay__c;
        testTax.add(taxDet1);
        insert testTax;
        
        List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);
        creditNotes[0].blng__RelatedInvoice__c = invoiceList2[0].ID;
        creditNotes[0].QTB_Reason_Code__c = 'Inventory';
        creditNotes[0].blng__CreditNoteDate__c = System.today();
        creditNotes[0].blng__EffectiveTaxDate__c = System.today();
        creditNotes[0].QTB_Credit_Note_Type__c ='ReBill';
        creditNotes[0].ApprovalStatus__c = 'Approved';
        creditNotes[0].blng__Status__c = 'Posted';
        creditNotes[0].QTB_Purchase_Order__c = poList[0].ID;
        
        Database.update(creditNotes);
        List<blng__CreditNoteLine__c> creditNoteLine = new List<blng__CreditNoteLine__c>();
        blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
        cnl.QTB_Account__c = invLineList[0].blng__Invoice__r.blng__Account__c;
        cnl.blng__CreditNote__c = creditNotes[0].ID;
        cnl.QTB_Invoice__c = invLineList[0].blng__Invoice__c;
        cnl.QTB_InvoiceLine__c = invLineList[0].ID;
        cnl.blng__Product__c = invLineList[0].blng__Product__c;
        cnl.QTB_Credit_Quantity__c = invLineList[0].blng__Quantity__c;
        cnl.blng__CalculateTax__c = true;
        cnl.blng__Subtotal__c = invLineList[0].blng__Subtotal__c;
        //cnl.blng__Subtotal__c = 50;
        //cnl.blng__CalculateTax__c=true;
        creditNoteLine.add(cnl);
        if(creditNoteLine.size() > 0){
            try{
                insert creditNoteLine;
            }
            catch(Exception e){
                System.debug('Exception@@'+e.getMessage());
            }
            Test.stopTest();
            System.Assert(invLineList[0].blng__InvoiceLineStatus__c == 'Draft');
        }*/
    }
    static testMethod void testMethod1(){
        List<blng__invoice__c>invLst = [SELECT ID,blng__InvoiceStatus__c,
                                        QTB_LegalEntityCountry__c,QTB_InvoiceProductType__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,QTB_Service_Start_Date__c,
            QTB_Service_End_Date__c,blng__Account__c,blng__Account__r.QTB_Billing_Account_Type__c, blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Service_Period_Range__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c,
            blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Bill_Forward_Type__c,QTB_Invoice_Period__c,QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c,blng__Account__r.QTB_DM_Source_System__c,blng__InvoiceDate__c,blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Legal_Entity__c,QTB_Tax_Period_Start_Date__c,QTB_Tax_Period_End_Date__c 
            FROM blng__Invoice__c /*WHERE blng__InvoiceStatus__c = 'Draft' AND blng__Account__r.QTB_Billing_Frequency__c != null AND blng__Account__r.QTB_Bill_Forward_Type__c != null AND 
            blng__Account__r.QTB_Bill_Forward_Type__c != 'None' AND QTB_Invoice_Period__c != null  AND QTB_LegalEntityCountry__c != null*/];
        system.debug('invLst- '+invLst);
        Set<Id>invId = new Set<Id>();
        set<Id>invSchId = new Set<Id>();
        for(blng__invoice__c inv :invLst){
            invId.add(inv.Id);
        }
        database.executeBatch(new QTB_UpdateStorageServiceDatesOnInvBatch(invId,invSchId));
    }
    static testMethod void testMethod2(){
        List<blng__invoice__c>invLst = [SELECT ID,blng__InvoiceStatus__c,
                                        QTB_LegalEntityCountry__c,QTB_InvoiceProductType__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,QTB_Service_Start_Date__c,
            QTB_Service_End_Date__c,blng__Account__c,blng__Account__r.QTB_Billing_Account_Type__c, blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Service_Period_Range__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c,
            blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Bill_Forward_Type__c,QTB_Invoice_Period__c,QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c,blng__Account__r.QTB_DM_Source_System__c,blng__InvoiceDate__c,blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Legal_Entity__c,QTB_Tax_Period_Start_Date__c,QTB_Tax_Period_End_Date__c 
            FROM blng__Invoice__c /*WHERE blng__InvoiceStatus__c = 'Draft' AND blng__Account__r.QTB_Billing_Frequency__c != null AND blng__Account__r.QTB_Bill_Forward_Type__c != null AND 
            blng__Account__r.QTB_Bill_Forward_Type__c != 'None' AND QTB_Invoice_Period__c != null  AND QTB_LegalEntityCountry__c != null*/];
        system.debug('invLst- '+invLst);
        Set<Id>invId = new Set<Id>();
        set<Id>invSchId = new Set<Id>();
        for(blng__invoice__c inv :invLst){
            invId.add(inv.Id);
    }
      try {
            QTB_UpdateStorageServiceDatesOnInvBatch.throwExplicitException = true;
        database.executeBatch(new QTB_UpdateStorageServiceDatesOnInvBatch(invId,invSchId)); 
            
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        
    }
    static testMethod void testMethod3(){
        List<blng__invoice__c>invLst = [SELECT ID,blng__InvoiceStatus__c,
                                        QTB_LegalEntityCountry__c,QTB_InvoiceProductType__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,QTB_Service_Start_Date__c,
            QTB_Service_End_Date__c,blng__Account__c,blng__Account__r.QTB_Billing_Account_Type__c, blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Service_Period_Range__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c,
            blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Bill_Forward_Type__c,QTB_Invoice_Period__c,QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c,blng__Account__r.QTB_DM_Source_System__c,blng__InvoiceDate__c,blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Legal_Entity__c,QTB_Tax_Period_Start_Date__c,QTB_Tax_Period_End_Date__c 
            FROM blng__Invoice__c /*WHERE blng__InvoiceStatus__c = 'Draft' AND blng__Account__r.QTB_Billing_Frequency__c != null AND blng__Account__r.QTB_Bill_Forward_Type__c != null AND 
            blng__Account__r.QTB_Bill_Forward_Type__c != 'None' AND QTB_Invoice_Period__c != null  AND QTB_LegalEntityCountry__c != null*/];
        system.debug('invLst- '+invLst);
        Set<Id>invId = new Set<Id>();
        set<Id>AccountIdset = new Set<Id>();
        for(blng__invoice__c inv :invLst){
            invId.add(inv.Id);
            AccountIdSet.add(inv.blng__Account__c);
        }
        List<account>accLst = [Select Id,QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c,QTB_Bill_Forward_Type__c,QTB_Billing_Frequency__c,QTB_Billing_Account_Type__c from Account where Id in :AccountIdSet];
        for(account a :accLst){
            system.debug('Service Date-->'+a.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c);
            a.QTB_Bill_Forward_Type__c = 'Arrears';
            a.QTB_Billing_Frequency__c = 'Monthly';
            //a.QTB_Billing_Account_Type__c = 'Product Sales';
        }
        
        set<Id>USIDs = new Set<ID>();
        for(blng__InvoiceLine__c invln :[Select blng__UsageSummary__c from blng__InvoiceLine__c where blng__Invoice__c in :invLst]){
            USIDs.add(invln.blng__UsageSummary__c);
        }
        List<blng__Usage__c> usgLst = [Select Id,QTB_Delivery_Date__c,QTB_Source_Service_Date__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c from blng__Usage__c where blng__UsageSummary__c in :USIDs];
        for(blng__Usage__c usg :usgLst){
          usg.QTB_End_Date_MRC__c = null;
          usg.QTB_Start_Date_MRC__c = null;
          usg.QTB_Source_Service_Date__c = null;
          usg.QTB_Delivery_Date__c = Date.valueOf('2024-10-01');
        }
        sbqq.TriggerControl.disable();
        update accLst;
        update usgLst;
        sbqq.TriggerControl.enable();
        set<Id>invSchId = new Set<Id>();
        database.executeBatch(new QTB_UpdateStorageServiceDatesOnInvBatch(invId,invSchId));
    }
    static testMethod void testMethod4(){
        List<blng__invoice__c>invLst = [SELECT ID,blng__InvoiceStatus__c,
                                        QTB_LegalEntityCountry__c,QTB_InvoiceProductType__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,QTB_Service_Start_Date__c,
            QTB_Service_End_Date__c,blng__Account__c,blng__Account__r.QTB_Billing_Account_Type__c, blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Service_Period_Range__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c,
            blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Bill_Forward_Type__c,QTB_Invoice_Period__c,QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c,blng__Account__r.QTB_DM_Source_System__c,blng__InvoiceDate__c,blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Legal_Entity__c,QTB_Tax_Period_Start_Date__c,QTB_Tax_Period_End_Date__c 
            FROM blng__Invoice__c /*WHERE blng__InvoiceStatus__c = 'Draft' AND blng__Account__r.QTB_Billing_Frequency__c != null AND blng__Account__r.QTB_Bill_Forward_Type__c != null AND 
            blng__Account__r.QTB_Bill_Forward_Type__c != 'None' AND QTB_Invoice_Period__c != null  AND QTB_LegalEntityCountry__c != null*/];
        system.debug('invLst- '+invLst);
        Set<Id>invId = new Set<Id>();
        set<Id>AccountIdset = new Set<Id>();
        for(blng__invoice__c inv :invLst){
            invId.add(inv.Id);
            AccountIdSet.add(inv.blng__Account__c);
        }
        List<account>accLst = [Select Id,QTB_Bill_Forward_Type__c,QTB_Billing_Frequency__c,QTB_Billing_Account_Type__c from Account where Id in :AccountIdSet];
        for(account a :accLst){
            a.QTB_Bill_Forward_Type__c = 'Advance';
            a.QTB_Billing_Frequency__c = 'Monthly';
            //a.QTB_Billing_Account_Type__c = 'Product Sales';
        }
        
        set<Id>USIDs = new Set<ID>();
        for(blng__InvoiceLine__c invln :[Select blng__UsageSummary__c from blng__InvoiceLine__c where blng__Invoice__c in :invLst]){
            USIDs.add(invln.blng__UsageSummary__c);
        }
        List<blng__Usage__c> usgLst = [Select Id,QTB_Delivery_Date__c,QTB_Source_Service_Date__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c from blng__Usage__c where blng__UsageSummary__c in :USIDs];
        for(blng__Usage__c usg :usgLst){
          usg.QTB_End_Date_MRC__c = Date.valueOf('2024-10-31');
          usg.QTB_Start_Date_MRC__c = Date.valueOf('2024-10-01');
          usg.QTB_Source_Service_Date__c = null;
          usg.QTB_Delivery_Date__c = Date.valueOf('2024-10-01');
        }
        sbqq.TriggerControl.disable();
        update accLst;
        update usgLst;
        sbqq.TriggerControl.enable();
        set<Id>invSchId = new Set<Id>();
        database.executeBatch(new QTB_UpdateStorageServiceDatesOnInvBatch(invId,invSchId));
    }
    static testMethod void testMethod5(){
        List<blng__invoice__c>invLst = [SELECT ID,blng__InvoiceStatus__c,
                                        QTB_LegalEntityCountry__c,QTB_InvoiceProductType__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,QTB_Service_Start_Date__c,
            QTB_Service_End_Date__c,blng__Account__c,blng__Account__r.QTB_Billing_Account_Type__c, blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Service_Period_Range__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c,
            blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Bill_Forward_Type__c,QTB_Invoice_Period__c,QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c,blng__Account__r.QTB_DM_Source_System__c,blng__InvoiceDate__c,blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Legal_Entity__c,QTB_Tax_Period_Start_Date__c,QTB_Tax_Period_End_Date__c 
            FROM blng__Invoice__c /*WHERE blng__InvoiceStatus__c = 'Draft' AND blng__Account__r.QTB_Billing_Frequency__c != null AND blng__Account__r.QTB_Bill_Forward_Type__c != null AND 
            blng__Account__r.QTB_Bill_Forward_Type__c != 'None' AND QTB_Invoice_Period__c != null  AND QTB_LegalEntityCountry__c != null*/];
        system.debug('invLst- '+invLst);
        Set<Id>invId = new Set<Id>();
        set<Id>AccountIdset = new Set<Id>();
        for(blng__invoice__c inv :invLst){
            invId.add(inv.Id);
            AccountIdSet.add(inv.blng__Account__c);
        }
        List<account>accLst = [Select Id,QTB_Legal_Entity_Country__c,QTB_Bill_Forward_Type__c,QTB_Billing_Frequency__c,QTB_Billing_Account_Type__c from Account where Id in :AccountIdSet];
        for(account a :accLst){
            a.QTB_Bill_Forward_Type__c = 'Arrears';
            a.QTB_Billing_Frequency__c = 'Quarterly';
            a.QTB_Legal_Entity_Country__c = 'Denmark';
            //a.QTB_Billing_Account_Type__c = 'Product Sales';
        }
        
        set<Id>USIDs = new Set<ID>();
        list<blng__InvoiceLine__c>invlnlst = new List<blng__InvoiceLine__c>();
        for(blng__InvoiceLine__c invln :[Select Id,QTB_ProductType__c,blng__UsageSummary__c from blng__InvoiceLine__c where blng__Invoice__c in :invLst]){
            invln.QTB_ProductType__c = 'Services';
            USIDs.add(invln.blng__UsageSummary__c);
            invlnlst.add(invln);
        }
        List<Product2>pr = [Select Id,QTB_Price_Schedule_Category__c from Product2];
        pr[0].QTB_Price_Schedule_Category__c = 'Services';
        update pr;
        List<blng__Usage__c> usgLst = [Select Id,QTB_Delivery_Date__c,QTB_Source_Service_Date__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c from blng__Usage__c where blng__UsageSummary__c in :USIDs];
        for(blng__Usage__c usg :usgLst){
          usg.QTB_End_Date_MRC__c = Date.valueOf('2024-10-31');
          usg.QTB_Start_Date_MRC__c = Date.valueOf('2024-10-01');
          usg.QTB_Source_Service_Date__c = Date.valueOf('2024-10-01');
          usg.QTB_Delivery_Date__c = Date.valueOf('2024-10-01');
        }
        sbqq.TriggerControl.disable();
        update accLst;
        update usgLst;
        sbqq.TriggerControl.enable();
        set<Id>invSchId = new Set<Id>();
        database.executeBatch(new QTB_UpdateStorageServiceDatesOnInvBatch(invId,invSchId));
    }
    static testMethod void testMethod6(){
        List<blng__invoice__c>invLst = [SELECT ID,blng__InvoiceStatus__c,
                                        QTB_LegalEntityCountry__c,QTB_InvoiceProductType__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,QTB_Service_Start_Date__c,
            QTB_Service_End_Date__c,blng__Account__c,blng__Account__r.QTB_Billing_Account_Type__c, blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Service_Period_Range__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c,
            blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Bill_Forward_Type__c,QTB_Invoice_Period__c,QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c,blng__Account__r.QTB_DM_Source_System__c,blng__InvoiceDate__c,blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Legal_Entity__c,QTB_Tax_Period_Start_Date__c,QTB_Tax_Period_End_Date__c 
            FROM blng__Invoice__c /*WHERE blng__InvoiceStatus__c = 'Draft' AND blng__Account__r.QTB_Billing_Frequency__c != null AND blng__Account__r.QTB_Bill_Forward_Type__c != null AND 
            blng__Account__r.QTB_Bill_Forward_Type__c != 'None' AND QTB_Invoice_Period__c != null  AND QTB_LegalEntityCountry__c != null*/];
        system.debug('invLst- '+invLst);
        Set<Id>invId = new Set<Id>();
        set<Id>AccountIdset = new Set<Id>();
        for(blng__invoice__c inv :invLst){
            invId.add(inv.Id);
            AccountIdSet.add(inv.blng__Account__c);
        }
        List<Product2>pr = [Select Id,QTB_Price_Schedule_Category__c from Product2];
        for(Product2 prd :pr){
            prd.QTB_Price_Schedule_Category__c = 'Storage';
        }
        
        List<account>accLst = [Select Id,QTB_Legal_Entity_Country__c,QTB_Bill_Forward_Type__c,QTB_Billing_Frequency__c,QTB_Billing_Account_Type__c from Account where Id in :AccountIdSet];
        for(account a :accLst){
            a.QTB_Bill_Forward_Type__c = 'Arrears';
            a.QTB_Billing_Frequency__c = 'Monthly';
            a.QTB_Billing_Account_Type__c = 'Product Sales';
            a.QTB_Legal_Entity_Country__c = 'Denmark';
        }
        
        set<Id>USIDs = new Set<ID>();
        list<blng__InvoiceLine__c>invlnlst = new List<blng__InvoiceLine__c>();
        for(blng__InvoiceLine__c invln :[Select Id,QTB_ProductType__c,blng__UsageSummary__c from blng__InvoiceLine__c where blng__Invoice__c in :invLst]){
            invln.QTB_ProductType__c = 'Storage';
            USIDs.add(invln.blng__UsageSummary__c);
            invlnlst.add(invln);
        }
        
        List<blng__Usage__c> usgLst = [Select Id,QTB_Delivery_Date__c,QTB_Source_Service_Date__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c from blng__Usage__c where blng__UsageSummary__c in :USIDs];
        for(blng__Usage__c usg :usgLst){
          usg.QTB_End_Date_MRC__c = null;
          usg.QTB_Start_Date_MRC__c = null;
          usg.QTB_Source_Service_Date__c = null;
          usg.QTB_Delivery_Date__c = Date.valueOf('2024-10-01');
          usg.QTB_Storage_Type__c = 'Regular';
        }
        list<blng__LegalEntity__c>legal = [Select Id,QTB_Storage_Date_on_Invoice__c from blng__LegalEntity__c ];
        for(blng__LegalEntity__c le :legal){
            le.QTB_Storage_Date_on_Invoice__c = 'Storage Range';
        }
        update pr;sbqq.TriggerControl.disable();
        update accLst;
        update usgLst;
        update legal;
        update invlnlst;
        update accLst;
        sbqq.TriggerControl.enable();
        set<Id>invSchId = new Set<Id>();
        database.executeBatch(new QTB_UpdateStorageServiceDatesOnInvBatch(invId,invSchId));
    }
    static testMethod void testMethod8(){
        List<blng__invoice__c>invLst = [SELECT ID,blng__InvoiceStatus__c,
                                        QTB_LegalEntityCountry__c,QTB_InvoiceProductType__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,QTB_Service_Start_Date__c,
            QTB_Service_End_Date__c,blng__Account__c,blng__Account__r.QTB_Billing_Account_Type__c, blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Service_Period_Range__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c,
            blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Bill_Forward_Type__c,QTB_Invoice_Period__c,QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c,blng__Account__r.QTB_DM_Source_System__c,blng__InvoiceDate__c,blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Legal_Entity__c,QTB_Tax_Period_Start_Date__c,QTB_Tax_Period_End_Date__c 
            FROM blng__Invoice__c /*WHERE blng__InvoiceStatus__c = 'Draft' AND blng__Account__r.QTB_Billing_Frequency__c != null AND blng__Account__r.QTB_Bill_Forward_Type__c != null AND 
            blng__Account__r.QTB_Bill_Forward_Type__c != 'None' AND QTB_Invoice_Period__c != null  AND QTB_LegalEntityCountry__c != null*/];
        system.debug('invLst- '+invLst);
        Set<Id>invId = new Set<Id>();
        set<Id>AccountIdset = new Set<Id>();
        for(blng__invoice__c inv :invLst){
            invId.add(inv.Id);
            AccountIdSet.add(inv.blng__Account__c);
        }
        List<account>accLst = [Select Id,QTB_Legal_Entity_Country__c,QTB_Bill_Forward_Type__c,QTB_Billing_Frequency__c,QTB_Billing_Account_Type__c from Account where Id in :AccountIdSet];
        for(account a :accLst){
            a.QTB_Bill_Forward_Type__c = 'Arrears';
            a.QTB_Billing_Frequency__c = 'Semiannual';
            a.QTB_Legal_Entity_Country__c = 'Denmark';
            //a.QTB_Billing_Account_Type__c = 'Product Sales';
        }
        
        set<Id>USIDs = new Set<ID>();
        list<blng__InvoiceLine__c>invlnlst = new List<blng__InvoiceLine__c>();
        for(blng__InvoiceLine__c invln :[Select Id,QTB_ProductType__c,blng__UsageSummary__c from blng__InvoiceLine__c where blng__Invoice__c in :invLst]){
            invln.QTB_ProductType__c = 'Services';
            USIDs.add(invln.blng__UsageSummary__c);
            invlnlst.add(invln);
        }
        List<Product2>pr = [Select Id,QTB_Price_Schedule_Category__c from Product2];
        pr[0].QTB_Price_Schedule_Category__c = 'Services';
        update pr;
        List<blng__Usage__c> usgLst = [Select Id,QTB_Delivery_Date__c,QTB_Source_Service_Date__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c from blng__Usage__c where blng__UsageSummary__c in :USIDs];
        for(blng__Usage__c usg :usgLst){
          usg.QTB_End_Date_MRC__c = Date.valueOf('2024-10-31');
          usg.QTB_Start_Date_MRC__c = Date.valueOf('2024-10-01');
          usg.QTB_Source_Service_Date__c = Date.valueOf('2024-10-01');
          usg.QTB_Delivery_Date__c = Date.valueOf('2024-10-01');
        }
        sbqq.TriggerControl.disable();
        update accLst;
        update usgLst;
        sbqq.TriggerControl.enable();
        set<Id>invSchId = new Set<Id>();
        database.executeBatch(new QTB_UpdateStorageServiceDatesOnInvBatch(invId,invSchId));
    }
    static testMethod void testMethod9(){
        List<blng__invoice__c>invLst = [SELECT ID,blng__InvoiceStatus__c,
                                        QTB_LegalEntityCountry__c,QTB_InvoiceProductType__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c,QTB_Service_Start_Date__c,
            QTB_Service_End_Date__c,blng__Account__c,blng__Account__r.QTB_Billing_Account_Type__c, blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Service_Period_Range__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Storage_Date_on_Invoice__c,
            blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Bill_Forward_Type__c,QTB_Invoice_Period__c,QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__Account__r.QTB_Contract_Entity__r.QTB_Service_Date_on_Invoice__c,blng__Account__r.QTB_DM_Source_System__c,blng__InvoiceDate__c,blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Invoice_Period__r.blng__PeriodEndDate__c,
            blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__r.QTB_Legal_Entity__c,QTB_Tax_Period_Start_Date__c,QTB_Tax_Period_End_Date__c 
            FROM blng__Invoice__c /*WHERE blng__InvoiceStatus__c = 'Draft' AND blng__Account__r.QTB_Billing_Frequency__c != null AND blng__Account__r.QTB_Bill_Forward_Type__c != null AND 
            blng__Account__r.QTB_Bill_Forward_Type__c != 'None' AND QTB_Invoice_Period__c != null  AND QTB_LegalEntityCountry__c != null*/];
        system.debug('invLst- '+invLst);
        Set<Id>invId = new Set<Id>();
        set<Id>AccountIdset = new Set<Id>();
        for(blng__invoice__c inv :invLst){
            invId.add(inv.Id);
            AccountIdSet.add(inv.blng__Account__c);
        }
        List<account>accLst = [Select Id,QTB_Legal_Entity_Country__c,QTB_Bill_Forward_Type__c,QTB_Billing_Frequency__c,QTB_Billing_Account_Type__c from Account where Id in :AccountIdSet];
        for(account a :accLst){
            a.QTB_Bill_Forward_Type__c = 'Arrears';
            a.QTB_Billing_Frequency__c = 'Annual';
            a.QTB_Legal_Entity_Country__c = 'Denmark';
            //a.QTB_Billing_Account_Type__c = 'Product Sales';
        }
        
        set<Id>USIDs = new Set<ID>();
        list<blng__InvoiceLine__c>invlnlst = new List<blng__InvoiceLine__c>();
        for(blng__InvoiceLine__c invln :[Select Id,QTB_ProductType__c,blng__UsageSummary__c from blng__InvoiceLine__c where blng__Invoice__c in :invLst]){
            invln.QTB_ProductType__c = 'Services';
            USIDs.add(invln.blng__UsageSummary__c);
            invlnlst.add(invln);
        }
        List<Product2>pr = [Select Id,QTB_Price_Schedule_Category__c from Product2];
        pr[0].QTB_Price_Schedule_Category__c = 'Services';
        update pr;
        List<blng__Usage__c> usgLst = [Select Id,QTB_Delivery_Date__c,QTB_Source_Service_Date__c,QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c from blng__Usage__c where blng__UsageSummary__c in :USIDs];
        for(blng__Usage__c usg :usgLst){
          usg.QTB_End_Date_MRC__c = Date.valueOf('2024-10-31');
          usg.QTB_Start_Date_MRC__c = Date.valueOf('2024-10-01');
          usg.QTB_Source_Service_Date__c = Date.valueOf('2024-10-01');
          usg.QTB_Delivery_Date__c = Date.valueOf('2024-10-01');
        }
        sbqq.TriggerControl.disable();
        update accLst;
        update usgLst;
        sbqq.TriggerControl.enable();
        set<Id>invSchId = new Set<Id>();
        database.executeBatch(new QTB_UpdateStorageServiceDatesOnInvBatch(invId,invSchId));
    }

}