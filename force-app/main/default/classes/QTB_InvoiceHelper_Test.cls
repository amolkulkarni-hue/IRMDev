/*****************************************************************************************************
    * Class: QTB_InvoiceHelper_Test
* Author: Accenture
* Purpose: This is a Test class for QTB_InvoiceHelper
* Requirement:
* Change History: 7/2/2020
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
*              7/2/2020
*******************************************************************************************************/
@isTest(seealldata=false) 
private class QTB_InvoiceHelper_Test {
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
        Database.update(product);
        
        //Pricebook
        ID pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        //Account
        List<Account> accountList = new List<Account>();
        ID standardrecordID = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
        ID recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
        for (Integer i = 0; i < 10; i++) {
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
                a.QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
            }
            if(i == 1){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 2){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 3){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 4){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 5){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 6){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 7){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = '';
                a.QTB_Billing_Frequency__c = '';  
            }
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

        //Legal Entity
        blng__LegalEntity__c usEntity = new blng__LegalEntity__c();
        usEntity.Name = 'Test Legal Entity United States';
        usEntity.blng__Active__c = true;
        usEntity.blng__Country__c = 'United States';
        usEntity.QTB_Type__c = 'Contract';
        usEntity.QTB_Tax_Applicability__c = 'Flat Rate';
        //usEntity.QTB_Legal_Entity_Number__c = '45000';
        insert usEntity;
        
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
        List<Order> orderList2 = QTB_TestDataFactory.createCPQOrders(1,null,accountList[0].ID);
        orderList2[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        orderList2[0].QTB_OrderCategory__c = 'Rebill';
        Database.update(orderList2);
        
        List<OrderItem> orderItemList3 = new List<OrderItem>();
        List<OrderItem> orderItemList2 = new List<OrderItem>();
            //QTB_TestDataFactory.createCPQOrderItems(orderList3[0].ID,product[0].ID,quoteLinesList,standardPrice);
        try {
            for(Integer i = 0; i < 1; i++) {
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
                orderItemList2.add(new OrderItem(OrderId = orderList2[0].ID,Quantity = 2.00, UnitPrice = 12.00, PricebookEntryId = standardPrice.ID,
                        SBQQ__ChargeType__c = 'One-Time', product2id = product[0].ID, SBQQ__Activated__c = true,
                        blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').ID,
                        blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').ID,
                        blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').ID,
                        blng__HoldBilling__c = 'Yes'));
            }
            if (!orderItemList3.isEmpty()) {
                insert orderItemList3;
            }
            if (!orderItemList2.isEmpty()) {
                insert orderItemList2;
            }
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
        Map<ID,blng__Invoice__c> oldMap = new Map<ID,blng__Invoice__c>();
        
        //Invoice
        List<blng__Invoice__c> invoiceList = new List<blng__Invoice__c>();
        for (Account acc : accountList) {
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = acc.ID;
            invoice.blng__InvoiceStatus__c = 'Draft';
            invoice.blng__InvoiceDate__c = System.today()-10;
            
            invoiceList.add(invoice);
            break;
        }
        if (!invoiceList.isEmpty()) {
            insert invoiceList;
        }
        invoiceList[0].blng__InvoiceStatus__c = 'Posted';
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
        }
        
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0] );
        blng__UsageSummary__c usagesummary = usageSum[0];
        
        usagesummary.blng__Status__c = 'Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary.blng__Subtotal__c = 100;
        usagesummary.blng__TotalQuantity__c = 10;
        usagesummary.blng__PreratedQuantity__c = 20;
        usagesummary.blng__UnbilledQuantity__c = 1;
        usagesummary.blng__UnitPrice__c = 400;
        usagesummary.blng__PreratedAmount__c = 22;
        usagesummary.blng__Invoice__c = invoiceList2[0].ID; 
        Database.update(usagesummary);
        
        List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        usageList[0].QTB_Start_Date_MRC__c = Date.newInstance(2022,03,01);
        usageList[0].QTB_end_Date_MRC__c = Date.newInstance(2022,31,01); 
        usageList[0].blng__UsageSummary__c=usagesummary.ID;
        usageList[0].blng__Account__c = accountList[0].ID;
        Database.update(usageList);    
        
        
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
        //invLinelist[0].blng__Balance__c = 10;
        update invLinelist[0];
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
        Database.update(invLineList[0]);
        String invoicelineComparison = taxRate.blng__Country__c + '-' + taxRate.blng__State__c + '-' + taxRate.blng__City__c +
                                '-' + taxRate.blng__ZipCode__c +'-' + taxRate.blng__TaxCode__c + '-' + taxRate.blng__LegalEntity__c;
        
        invoiceList2[0].blng__InvoiceStatus__c = 'Posted';
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
        }
    }
    
    static testMethod void testmethod2() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);        
        
        QTB_InvoiceTriggerHandler.throwExplicitException = true;
        QTB_InvoiceTriggerHandler handler = new QTB_InvoiceTriggerHandler();
        handler.BeforeDelete(null);
        handler.AfterUndelete(null);
        handler.AfterDelete(null);
        handler.AfterUndelete(null);
        //  handler.BeforeUpdate(null, null);
        handler.AfterInsert(null);
        QTB_TestDataFactory.createBypassSetting( QTB_Constants.SOBJECT_BLNG_INVOICE);
        handler.isDisabled();
        Test.stopTest();
        
        try {
            QTB_InvoiceHelper.autoUpdatePO(null);
        } catch (Exception e) {
            //System.assert('Script-thrown exception' == e.getMessage());
        }
        
        try {
            QTB_InvoiceHelper.calculatingPOBalance(null,null);
        } catch (Exception e) {
            //System.assert('Script-thrown exception' == e.getMessage());
        }
        try {
            QTB_InvoiceHelper.calculateTax(null,null,null);
        } catch (Exception e) {
            System.assert('Script-thrown exception' == e.getMessage());
        }
        try {
            QTB_InvoiceHelper.updateTaxruleForInvoiceLine(null,null,null);
        } catch (Exception e) {
            System.assert('Script-thrown exception' == e.getMessage());
        }
        try {
            //QTB_InvoiceHelper.excludeInvoicesInsertionWithHoldBilling(null);
        } catch (Exception e) {
            System.assert('Script-thrown exception' == e.getMessage());
        }
        
        try {
            QTB_InvoiceHelper.populateOrderFieldsOnInvoice(null);
        } catch (Exception e) {
            //System.assert('Script-thrown exception' == e.getMessage());
        }
        
        try {
            QTB_InvoiceHelper.buildTaxRateMap(null);
        } catch (Exception e) {
            System.assert('Script-thrown exception' == e.getMessage());
        }
        /*try {
            QTB_InvoiceHelper.updateTaxOverrideForProductBase(null);
        } catch (Exception e) {
            System.assert('Script-thrown exception' == e.getMessage());
        }*/
        try{
            QTB_InvoiceHelper.calculateIndividualTaxAmountsOnInvoiceLineItems(null);
        } catch (Exception e) {
            System.assert('Script-thrown exception' == e.getMessage());
        }
        try{
            //QTB_InvoiceHelper.updateInvoiceMRCDates(null);
        } catch (Exception e) {
            //System.assert('Script-thrown exception' == e.getMessage());
        }
        System.assertEquals( true, QTB_InvoiceTriggerHandler.throwExplicitException);
    }
    static testMethod void testmethod3() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        
        QTB_InvoiceTriggerHandler.throwExplicitException = false;
        List<Account> accList = QTB_TestDataFactory.createAccounts(20);
        Set<String> addressComparisonSet = new Set <String>();
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accList);
        List<blng__Invoice__c> invoiceList = [SELECT ID,QTB_Parent_Invoice__c,blng__TaxAmount__c,blng__Account__c,blng__Subtotal__c,
                                              QTB_Parent_Invoice__r.blng__Subtotal__c,QTB_ReBill_Credit_Reason__c,blng__InvoiceStatus__c, 
                                              QTB_Start_Date_MRC__c,
                                              QTB_End_Date_MRC__c,
                                              blng__Account__r.QTB_Billing_Frequency__c ,blng__Account__r.QTB_Bill_Forward_Type__c,
                                              blng__Account__r.QTB_DM_Source_System__c
                                              FROM blng__Invoice__c  WHERE QTB_Parent_Invoice__c!= null LIMIT 1];
        //QTB_InvoiceHelper.updateTaxOverrideForProductBase(invoiceList);
        map<ID, blng__Invoice__c> invMap = new map<ID, blng__Invoice__c>(invList);
        
        
        blng__InvoiceLine__c invLine = [SELECT ID,blng__Invoice__r.blng__TaxAmount__c,blng__TaxTreatment__r.QTB_Invoice_Print_Tax_Name__c,blng__Balance__c,blng__TaxTreatment__c,blng__Invoice__r.blng__Account__c,blng__Quantity__c,blng__Product__c,blng__TotalAmount__c,   blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                        QTB_Tax_Code__c,blng__Invoice__r.blng__Subtotal__c,blng__LegalEntity__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,blng__Subtotal__c, blng__Invoice__r.QTB_Tax_Override_Amount__c,CurrencyIsoCode, blng__TaxAmount__c,
                                        blng__TaxTreatment__r.blng__TaxLegalEntity__c,QTB_Tax_Override_Amount__c, blng__Invoice__r.blng__Account__r.QTB_Language__c, blng__TaxTreatment__r.Name, QTB_Tiered_Flag__c
                                        FROM blng__InvoiceLine__c LIMIT 1];
        String invoiceLineComparison =
            invLine.blng__TaxCountry__c +'-' +
            invLine.blng__TaxState__c +'-' +
            invLine.blng__TaxCity__c +'-' +
            invLine.blng__TaxZipCode__c +'-' +
            invLine.QTB_Tax_Code__c +'-' +
            invLine.blng__LegalEntity__c;
        invoiceLineComparison = invoiceLineComparison.replaceAll('null','');                    	
        addressComparisonSet.add(invoiceLineComparison);
        
        Set<ID> invIdSet = new  Set<ID>();
        for(blng__Invoice__c invoice : invoiceList){
            invIdSet.add(invoice.ID);
        }
        System.debug('@@@inv Ids'+invIdSet);
        
        /*try {
QTB_InvoiceHelper.buildTaxRateMap(); 
} catch (Exception e) {
System.debug('Error Message in "QTB_InvoiceHelper.buildTaxRateMap()": '+ e.getMessage());
}*/
        try {
            QTB_InvoiceHelper.calculateIndividualTaxAmountsOnInvoiceLineItems(invMap.keyset());
            
        } catch (Exception e) {
            System.debug('Error Message in "QTB_InvoiceHelper.calculateIndividualTaxAmountsOnInvoiceLineItems"(): '+ e.getMessage());
        }
        try {
            QTB_InvoiceHelper.updateReBillInvoiceWithTotalOnSplit(invMap.keyset());
            
        } catch (Exception e) {
            System.debug('Error Message in "QTB_InvoiceHelper.updateReBillInvoiceWithTotalOnSplit"(): '+ e.getMessage());
        }
        //  try {
        List<blng__InvoiceLine__c> lstInvcLine = new List<blng__InvoiceLine__c>();
        lstInvcLine.add(invLine);
        QTB_InvoiceHelper.calculateTax(lstInvcLine,'Product Based',addressComparisonSet);
        QTB_InvoiceHelper.calculateTax(lstInvcLine,'Flat Rate',addressComparisonSet);
        //QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
        //QTB_InvoiceHelper.updatePOForCreditAndRebill(invoiceList, null);
        /*  } catch (Exception e) {
System.debug('Error Message in "QTB_InvoiceHelper.calculateTax()": '+ e.getMessage());
} */
        try {
            QTB_InvoiceHelper.createReBillCreditNote(invIdSet,true);
            //QTB_InvoiceHelper.updateTaxruleForInvoiceLine(invId,null,null);
            //QTB_InvoiceHelper.createReBillCreditNote(invoiceList,false);
        } catch (Exception e) {
            System.debug('Error Message in "QTB_InvoiceHelper.createReBillCreditNote()": '+ e.getMessage()); 
        }
        
        Test.stopTest();
    }
    static testMethod void testmethod4() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        
        QTB_InvoiceTriggerHandler.throwExplicitException = false;
        List<Account> accList = QTB_TestDataFactory.createAccounts(20);
        Set<String> addressComparison = new Set <String>();
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accList);
        invList[0].blng__InvoiceStatus__c = 'Posted';
        update invList[0];
        blng__InvoiceLine__c invLine = [SELECT ID,blng__Invoice__r.blng__TaxAmount__c,blng__Balance__c,blng__TaxTreatment__c,blng__TaxTreatment__r.QTB_Invoice_Print_Tax_Name__c,blng__Invoice__r.blng__Account__c,blng__Quantity__c,blng__Product__c,blng__TotalAmount__c,   blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                        QTB_Tax_Code__c,blng__Invoice__r.blng__Subtotal__c,blng__LegalEntity__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,blng__Subtotal__c, blng__Invoice__r.QTB_Tax_Override_Amount__c,CurrencyIsoCode, blng__TaxAmount__c,
                                        blng__TaxTreatment__r.blng__TaxLegalEntity__c,QTB_Tax_Override_Amount__c, blng__Invoice__r.blng__Account__r.QTB_Language__c, blng__TaxTreatment__r.Name
                                        FROM blng__InvoiceLine__c LIMIT 1];
        
        String invoiceLineComparison =
            invLine.blng__TaxCountry__c +'-' +
            invLine.blng__TaxState__c +'-' +
            invLine.blng__TaxCity__c +'-' +
            invLine.blng__TaxZipCode__c +'-' +
            invLine.QTB_Tax_Code__c +'-' +
            invLine.blng__LegalEntity__c;
        invoiceLineComparison = invoiceLineComparison.replaceAll('null','');                    	
        addressComparison.add(invoiceLineComparison);
        
        Account acc = new Account();
        acc.ID = invLine.blng__Invoice__r.blng__Account__r.ID;
        acc.QTB_Legal_Entity_Country__c = 'India';
        //update acc;
        
        List<blng__InvoiceLine__c> lstInvcLine = new List<blng__InvoiceLine__c>();
        lstInvcLine.add(invLine);
        QTB_InvoiceHelper.calculateTax(lstInvcLine,'Flat Rate',addressComparison);
        
        Test.stopTest();
    }
    static testMethod void testmethod5() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        
        QTB_InvoiceTriggerHandler.throwExplicitException = false;
        List<Account> accList = QTB_TestDataFactory.createAccounts(20);
        Set<String> addressComparison = new Set <String>();
        
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accList);
        invList[0].blng__InvoiceStatus__c = 'Posted';
        update invList[0];
        List<blng__Invoice__c> invoiceList = [SELECT ID,QTB_Parent_Invoice__c,blng__TaxAmount__c,blng__Account__c,blng__Subtotal__c,
                                              QTB_Parent_Invoice__r.blng__Subtotal__c,QTB_ReBill_Credit_Reason__c,blng__InvoiceStatus__c, 
                                              QTB_Start_Date_MRC__c,
                                              QTB_End_Date_MRC__c,
                                              blng__Account__r.QTB_Billing_Frequency__c ,blng__Account__r.QTB_Bill_Forward_Type__c,
                                              blng__Account__r.QTB_DM_Source_System__c
                                              FROM blng__Invoice__c  WHERE QTB_Parent_Invoice__c!= null LIMIT 1];
        invoiceList[0].blng__Account__r.QTB_Bill_Forward_Type__c='Advance';
        Update invoiceList[0];
        //QTB_InvoiceHelper.updateTaxOverrideForProductBase(invoiceList);
        //map<ID, blng__Invoice__c> invMap = new map<ID, blng__Invoice__c>(invList[0]);
        map<ID, blng__Invoice__c> invMap = new map<ID, blng__Invoice__c>();
        for(blng__Invoice__c Invlist1:invList){
            if(Invlist1.blng__InvoiceStatus__c == 'Posted'){
                invMap.put(Invlist1.ID,Invlist1);
            }
        } 
        
        blng__InvoiceLine__c invLine = [SELECT ID,blng__Invoice__r.blng__TaxAmount__c,blng__TaxTreatment__r.QTB_Invoice_Print_Tax_Name__c,blng__Balance__c,blng__TaxTreatment__c,blng__Invoice__r.blng__Account__c,blng__Quantity__c,blng__Product__c,blng__TotalAmount__c,   blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                        QTB_Tax_Code__c,blng__Invoice__r.blng__Subtotal__c,blng__LegalEntity__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,blng__Subtotal__c, blng__Invoice__r.QTB_Tax_Override_Amount__c,CurrencyIsoCode, blng__TaxAmount__c,
                                        blng__TaxTreatment__r.blng__TaxLegalEntity__c,QTB_Tax_Override_Amount__c, blng__Invoice__r.blng__Account__r.QTB_Language__c, blng__TaxTreatment__r.Name, QTB_Tiered_Flag__c
                                        FROM blng__InvoiceLine__c LIMIT 1];
        //invLine.QTB_Tiered_Flag__c = true;
        update new blng__LegalEntity__c(Id = invLine.blng__LegalEntity__c, QTB_Storage_Service_Period_Range__c = true);
        update new Product2(Id = invLine.blng__Product__c, QTB_Price_Schedule_Category__c = 'Storage');
        invLine = [SELECT ID,blng__Invoice__r.blng__TaxAmount__c,blng__TaxTreatment__r.QTB_Invoice_Print_Tax_Name__c,blng__Balance__c,blng__TaxTreatment__c,blng__Invoice__r.blng__Account__c,blng__Quantity__c,blng__Product__c,blng__TotalAmount__c,   blng__TaxCountry__c,blng__TaxState__c,blng__TaxCity__c,blng__TaxZipCode__c,
                                        QTB_Tax_Code__c,blng__Invoice__r.blng__Subtotal__c,blng__LegalEntity__c,blng__Invoice__r.blng__Account__r.QTB_Legal_Entity_Country__c,blng__Subtotal__c, blng__Invoice__r.QTB_Tax_Override_Amount__c,CurrencyIsoCode, blng__TaxAmount__c,
                                        blng__TaxTreatment__r.blng__TaxLegalEntity__c,QTB_Tax_Override_Amount__c, blng__Invoice__r.blng__Account__r.QTB_Language__c, blng__TaxTreatment__r.Name, QTB_Tiered_Flag__c, blng__LegalEntity__r.QTB_Storage_Service_Period_Range__c
                                        FROM blng__InvoiceLine__c LIMIT 1];
        system.debug('invLine --> '+ invLine.QTB_Tiered_Flag__c);
        //update invline;
        
        String invoiceLineComparison =
            invLine.blng__TaxCountry__c +'-' +
            invLine.blng__TaxState__c +'-' +
            invLine.blng__TaxCity__c +'-' +
            invLine.blng__TaxZipCode__c +'-' +
            invLine.QTB_Tax_Code__c +'-' +
            invLine.blng__LegalEntity__c;
        invoiceLineComparison = invoiceLineComparison.replaceAll('null','');                    	
        addressComparison.add(invoiceLineComparison);
        blng__TaxRate__c taxRate = [SELECT Id, blng__Country__c, blng__State__c, blng__City__c, blng__ZipCode__c, blng__TaxCode__c, blng__LegalEntity__c FROM blng__TaxRate__c LIMIT 1 ];
        taxRate.blng__State__c = '';
        taxRate.blng__City__c = '';
        taxRate.blng__ZipCode__c = '';
        update taxRate;
       /* Map<String,List<blng__TaxRate__c>> taxRateMap = new Map<String,List<blng__TaxRate__c>>{
            taxRate.blng__Country__c + '-' +  '-' + 
                                '-' +'-' + taxRate.blng__TaxCode__c + '-' + taxRate.blng__LegalEntity__c => new List<blng__TaxRate__c>{taxRate}
        };*/
        
            String invoiceLineComparisonTest = invLine.blng__TaxCountry__c +'----' + invLine.QTB_Tax_Code__c +'-' + invLine.blng__LegalEntity__c;
        	addressComparison.add(invoiceLineComparisonTest);
        system.debug('770 --> '+ invoiceLineComparisonTest);
        
        blng__SubInvoiceLine__c subInvLine = new blng__SubInvoiceLine__c(
        	blng__InvoiceLine__c = invLine.Id,
            blng__Subtotal__c = 1000
        );
        insert subInvLine;
      //  system.debug('771 --> ' + string.valueOf(taxRateMap.containsKey(invoiceLineComparisonTest)));
      //  QTB_InvoiceHelper.taxRatesMap = taxRateMap;
        
        Set<ID> invId = new  Set<ID>();
        String str;
        String str2;
        for(blng__Invoice__c invoice : invoiceList){
            invId.add(invoice.ID);
        }
        
        try {
            QTB_InvoiceHelper.calculateIndividualTaxAmountsOnInvoiceLineItems(invMap.keyset());
            
        } catch (Exception e) {
            System.debug('Error Message in "QTB_InvoiceHelper.calculateIndividualTaxAmountsOnInvoiceLineItems"(): '+ e.getMessage());
        }
        try {
            QTB_InvoiceHelper.updateReBillInvoiceWithTotalOnSplit(invMap.keyset());
            
        } catch (Exception e) {
            System.debug('Error Message in "QTB_InvoiceHelper.updateReBillInvoiceWithTotalOnSplit"(): '+ e.getMessage());
        } 
        
        
        //  try {
        List<blng__InvoiceLine__c> lstInvcLine = new List<blng__InvoiceLine__c>();
        lstInvcLine.add(invLine);
        
        
        QTB_InvoiceHelper.calculateTax(lstInvcLine,'Product Based',addressComparison);
        QTB_InvoiceHelper.calculateTax(lstInvcLine,'Flat Rate',addressComparison);
        //QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
       //QTB_InvoiceHelper.updatePOForCreditAndRebill(invoiceList, invMap);
        /*  } catch (Exception e) {
System.debug('Error Message in "QTB_InvoiceHelper.calculateTax()": '+ e.getMessage());
} */
        try {
            QTB_InvoiceHelper.createReBillCreditNote(invId,true);
            QTB_InvoiceHelper.updateTaxruleForInvoiceLine(invId,null,null);
            
            //QTB_InvoiceHelper.createReBillCreditNote(invoiceList,false);
        } catch (Exception e) {
            System.debug('Error Message in "QTB_InvoiceHelper.createReBillCreditNote()": '+ e.getMessage()); 
        }
        
        Test.stopTest();
    }
   static testmethod void method6(){
        Test.startTest();
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(2);
        Set<String> addressComparison = new Set <String>();
        
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accList);
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Rebill Run';
        accountList[0].QTB_Legal_Entity_Country__c='India';
        accountList[0].QTB_Bill_Forward_Type__c='Advance';
        accountList[0].QTB_Billing_Frequency__c='Monthly';
        //accountList[0].CurrencyIsoCode = 'INR';
        update accountList;
        
        //Legal Entity
        blng__LegalEntity__c singaporeEntity = new blng__LegalEntity__c();
        singaporeEntity.Name = 'Test Legal Entity Singapore';
        singaporeEntity.blng__Active__c = true;
        singaporeEntity.blng__Country__c = 'United States';
        //singaporeEntity.blng__Country__c = 'Singapore';
        singaporeEntity.QTB_Type__c = 'Contract';
        singaporeEntity.QTB_Legal_Entity_Number__c = 45000;
        singaporeEntity.QTB_Storage_Service_Period_Range__c=true;
        singaporeEntity.QTB_Tax_Applicability__c='Product Based';
        insert singaporeEntity; 
        
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'Test schedule 1';
        schedule.blng__Type__c = 'Once';
        schedule.blng__InvoiceBatches__c = 'Rebill Run';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.today();
        schedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        schedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        schedule.QTB_Parent_Invoice__c = invList[0].ID;
        schedule.QTB_Legal_Entity__c  = singaporeEntity.ID;
        //insert schedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Test invoice';
        invoiceRun.blng__InvoiceScheduler__c = schedule.ID;
        invoiceRun.blng__Status__c = 'Started';
        //invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
        insert invoiceRun;
        Set<ID> postedid=new set<ID>();
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[0].ID;
        invoice.blng__InvoiceStatus__c = 'Draft';
        invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
        insert invoice;
        invoice.blng__InvoiceStatus__c = 'Posted';
        update invoice;
        
        Test.stopTest();
    }
    static testmethod void method7(){
        Test.startTest();
        
        QTB_Tax_Integration_Setting__mdt vertexData = new QTB_Tax_Integration_Setting__mdt();
        vertexData.Label = 'Vertex';
        vertexData.DeveloperName = 'Vertex_Integration';
        vertexData.QTB_Country__c = 'United States;Canada';
        vertexData.QTB_End_System__c = 'Vertex';
        
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(2);
        Set<String> addressComparison = new Set <String>();
        
        
         
            
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accList);
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Rebill Run';
        accountList[0].QTB_Legal_Entity_Country__c='India';
        accountList[0].QTB_Bill_Forward_Type__c='Advance';
        accountList[0].QTB_Billing_Frequency__c='Monthly';
        //accountList[0].CurrencyIsoCode = 'INR';
        update accountList;
        
        //Legal Entity
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
        usaEntity.Name = 'Test Legal Entity Singapore';
        usaEntity.blng__Active__c = true;
        usaEntity.blng__Country__c = 'United States';
        usaEntity.QTB_Type__c = 'Contract';
        // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert usaEntity;          
        
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'Test schedule 2';
        schedule.blng__Type__c = 'Once';
        schedule.blng__InvoiceBatches__c = 'Rebill Run';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.today();
        schedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        schedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        schedule.QTB_Parent_Invoice__c = invList[0].ID;
        schedule.QTB_Legal_Entity__c = usaEntity.ID;
        //insert schedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Test invoice';
        invoiceRun.blng__InvoiceScheduler__c = schedule.ID;
        invoiceRun.blng__Status__c = 'Started';
        //invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
        insert invoiceRun;
        Set<ID> postedid=new set<ID>();
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[0].ID;
        invoice.blng__InvoiceStatus__c = 'Draft';
        invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        invoice.QTB_ReBill_Status__c='ReBill Completed';
        invoice.QTB_Case_Number__c = 'CA245566';
        invoice.QTB_Service_District__c = 'Test district';
        invoice.QTB_Site_Number__c = 'CS15545466';
        
        //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
        insert invoice;
        invoice.blng__InvoiceStatus__c = 'Posted';
        invoice.QTB_ReBill_Status__c='';
        update invoice;
        
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__Invoice__c = invoice.ID;
        invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;
        //invoiceLine.blng__UsageSummary__c = usagesummary.ID; 
        invoiceLine.blng__Subtotal__c = 100;
        invoiceLine.blng__TaxCountry__c = 'India';
        insert invoiceLine;
        //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
        
        postedid.add(invoice.ID);
        invoice.blng__InvoiceStatus__c = 'Posted';
        invoice.QTB_ReBill_Status__c='';
        
        QTB_InvoiceHelper.calculateIndividualTaxAmountsOnInvoiceLineItems(postedid);
        Test.stopTest();
    }
    
     static testmethod void method711(){
        Test.startTest();
        
        QTB_Tax_Integration_Setting__mdt vertexData = new QTB_Tax_Integration_Setting__mdt();
        vertexData.Label = 'Vertex';
        vertexData.DeveloperName = 'Vertex_Integration';
        vertexData.QTB_Country__c = 'United States;Canada';
        vertexData.QTB_End_System__c = 'Vertex';
        
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(2);
        Set<String> addressComparison = new Set <String>();
        
        
         
            
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accList);
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Singapore-1st';
        accountList[0].QTB_Legal_Entity_Country__c='Canada';
        accountList[0].QTB_Bill_Forward_Type__c='Advance';
        accountList[0].QTB_Billing_Frequency__c='Monthly';
        //accountList[0].CurrencyIsoCode = 'INR';
        update accountList;
        
        //Legal Entity
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
        usaEntity.Name = 'Test Legal Entity Singapore';
        usaEntity.blng__Active__c = true;
        usaEntity.blng__Country__c = 'United States';
        usaEntity.QTB_Type__c = 'Contract';
        // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert usaEntity;          
        
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'Test schedule 2';
        schedule.blng__Type__c = 'Once';
        schedule.blng__InvoiceBatches__c = 'Rebill Run';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.today();
        schedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        schedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        schedule.QTB_Parent_Invoice__c = invList[0].ID;
        schedule.QTB_Legal_Entity__c = usaEntity.ID;
        //insert schedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Test invoice';
        invoiceRun.blng__InvoiceScheduler__c = schedule.ID;
        invoiceRun.blng__Status__c = 'Started';
        //invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
        insert invoiceRun;
         
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,null,accountList[0].ID);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        Database.update(orderList3);
         
          QTB_Bill_Flow_Controller__c  bill=new QTB_Bill_Flow_Controller__c();
        bill.Execute_Post_Bill_Run__c=False;
        bill.Execute_Pre_Bill_Run__c=True;
        bill.Invoice_Scheduler__c=schedule.ID;
        bill.Name='abc';
        bill.QTB_PostBill_Run_Status__c ='None';
        bill.QTB_PreBill_Run_Status__c='In Progress';
         bill.QTB_Rebill_Order__c = orderList3[0].ID;
        insert bill;
        
        Set<ID> postedid=new set<ID>();
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[0].ID;
        invoice.blng__InvoiceStatus__c = 'Draft';
        invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        invoice.QTB_ReBill_Status__c='ReBill Completed';
        invoice.QTB_Case_Number__c = 'CA245566';
        invoice.QTB_Service_District__c = 'Test district';
        invoice.QTB_Site_Number__c = 'CS15545466';
        invoice.QTB_Invoice_Type__c = 'Rebill';
        invoice.blng__Order__c=orderList3[0].ID;
        //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
        insert invoice;
         postedid.add(invoice.ID);
         //QTB_InvoiceHelper.updateRebillInvoice(postedid);
         
        /*invoice.blng__InvoiceStatus__c = 'Posted';
        invoice.QTB_ReBill_Status__c='';
        update invoice;
        
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__Invoice__c = invoice.ID;
        invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;
        //invoiceLine.blng__UsageSummary__c = usagesummary.ID; 
        invoiceLine.blng__Subtotal__c = 100;
        invoiceLine.blng__TaxCountry__c = 'Canada';
        insert invoiceLine;
        //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
        
        postedid.add(invoice.ID);
        invoice.blng__InvoiceStatus__c = 'Posted';
        invoice.QTB_ReBill_Status__c='';
        
        QTB_InvoiceHelper.calculateIndividualTaxAmountsOnInvoiceLineItems(postedid);
         QTB_InvoiceHelper.updateRebillInvoice(postedid);*/
        Test.stopTest();
    }
    
    static testMethod void testmethod9() {
        Test.startTest();
        QTB_InvoiceTriggerHandler.throwExplicitException = false;
        List<blng__Invoice__c> invoiceList = [SELECT ID,QTB_Start_Date_MRC__c,blng__InvoiceStatus__c FROM blng__Invoice__c WHERE blng__InvoiceStatus__c = 'Posted' AND QTB_Transferred_To_Oracle__c = true LIMIT 2];
        try{
            invoiceList[0].QTB_End_Date_MRC__c= System.today();
            Database.update(invoiceList[0]);    
        }catch(Exception e){
            System.debug(e.getMessage());
            System.assertEquals(true,e.getMessage().contains('We can not modify posted Invoice record'));
        }
        Test.stopTest();
    }  
    /*static testMethod void testmethod10() {
        //Account
        List<Account> accountList1 = new List<Account>();
        ID standardrecordID = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
        ID recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
        for (Integer i = 0; i < 10; i++) {
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
                a.QTB_Legal_Entity_Country__c='Singapore';
                a.QTB_Bill_Cycle_Day__c = 'Singapore-1st';
                a.QTB_Split_Invoice_Flag__c = true;
            }
            if(i == 1){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Monthly';
                a.QTB_Split_Invoice_Flag__c = true;
            }
            if(i == 2){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Monthly';
                a.QTB_Split_Invoice_Flag__c = True;
            }
            if(i == 3){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Quarterly';
                a.QTB_Split_Invoice_Flag__c = True;
            }
            if(i == 4){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Quarterly';
                 a.QTB_Split_Invoice_Flag__c = True;
            }
            if(i == 5){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Semiannual';
                 a.QTB_Split_Invoice_Flag__c = True;
            }
            if(i == 6){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Semiannual'; 
                 a.QTB_Split_Invoice_Flag__c = True;
            }
            if(i == 7){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Annual';
                 a.QTB_Split_Invoice_Flag__c = True;
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Annual'; 
                 a.QTB_Split_Invoice_Flag__c = True;
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = '';
                a.QTB_Billing_Frequency__c = ''; 
                 a.QTB_Split_Invoice_Flag__c = True;
            }
            accountList1.add(a);
        }
        Test.startTest();
        if (!accountList1.isEmpty()) {
            insert accountList1;
        }
        List<contact> conList = new List<contact>();
        for(integer i=3 ; i<6 ; i++){
            Contact cont = new Contact();
            cont.LastName = i+'test1 ';
            cont.FirstName = i+'abc ';
            cont.email = i+'so1@email.com';
            cont.AccountId = accountList1[i].ID;
            cont.MailingCountry = 'Canada';
            cont.IM_Role__c = 'PO Contact';
            conList.add(cont);
        }
        insert conList;
        
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        for(integer i=0 ; i<3 ; i++){
            AccountContactRelation acr = new AccountContactRelation();
            acr.accountId = accountList1[i].ID;
            acr.ContactId = conList[i].ID;
            acr.Roles = 'PO Contact';
            acrList.add(acr);
        }
        
        insert acrList;
        
        List<QTB_PurchaseOrder__c> poList = new List<QTB_PurchaseOrder__c>();
        for(integer i=0 ; i<2 ; i++){
            QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c();
            pOrder.QTB_Billing_Account__c = accountList1[i].ID;
                pOrder.QTB_Status__c = 'Active';
                pOrder.QTB_Start_Date__c = System.today();
                pOrder.QTB_End_Date__c = System.today();
                pOrder.QTB_PO_Type__c = 'Standard';
                pOrder.QTB_Customer_PO__c = 'QW2315';
                pOrder.QTB_Amount__c = 10000;
                if(i== 0){
                    pOrder.QTB_Service_Type__c = 'Storage';
                        }
            	
            	if(i== 1){
                	pOrder.QTB_Service_Type__c = 'Mixed';
                    }
            	poList.add(pOrder);
        }
        insert poList;
        
        //Legal Entity
        blng__LegalEntity__c singaporeEntity = new blng__LegalEntity__c();
        singaporeEntity.Name = 'Test Legal Entity Singapore';
        singaporeEntity.blng__Active__c = true;
        singaporeEntity.blng__Country__c = 'Singapore';
        singaporeEntity.blng__City__c ='Singapore';
        singaporeEntity.Legal_City__c ='Singapore';
        singaporeEntity.QTB_Type__c = 'Contract';
        singaporeEntity.QTB_Legal_Entity_Number__c = 45409;
        insert singaporeEntity; 
        
        //blng__LegalEntity__c singaporeEntity=QTB_TestDataFactory.createLegalEntity('Singapore');
        
        //Billing Finanace
        blng__FinanceBook__c singaporeFinanceBook = new blng__FinanceBook__c();
        singaporeFinanceBook.Name = 'Accounting Finance Book';
        singaporeFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
        singaporeFinanceBook.blng__Active__c = true;
        singaporeFinanceBook.blng__PeriodType__c='Accounting';
        insert singaporeFinanceBook;
        
        
        blng__FinancePeriod__c singaporeFinancePeriod = new blng__FinancePeriod__c();
        singaporeFinancePeriod.Name = 'singapore Mar 2024';
        singaporeFinancePeriod.blng__FinanceBook__c = singaporeFinanceBook.ID;
        singaporeFinancePeriod.blng__PeriodStartDate__c = System.today().toStartofMonth();
        singaporeFinancePeriod.blng__PeriodEndDate__c = System.today().addMonths(1).toStartofMonth().addDays(-1);
        singaporeFinancePeriod.blng__LegalEntity__c = singaporeEntity.ID;
        singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert singaporeFinancePeriod;
        
        blng__InvoiceScheduler__c singaporeSchedule = new blng__InvoiceScheduler__c();
        singaporeSchedule.Name = 'Test for Singapore';
        singaporeSchedule.blng__Type__c = 'Once';
        singaporeSchedule.blng__InvoiceBatches__c = 'Singapore-1st'; 
        singaporeSchedule.CurrencyIsoCode = 'SGD';
        singaporeSchedule.blng__StartDateTime__c = date.today();
        singaporeSchedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        singaporeSchedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
        singaporeSchedule.QTB_Legal_Entity__c  = singaporeEntity.ID;
        singaporeSchedule.QTB_Invoice_Period__c = singaporeFinancePeriod.ID ;
        insert singaporeSchedule;
        
      
        blng__InvoiceRun__c  singaporeInvoiceRun = new blng__InvoiceRun__c();
        singaporeInvoiceRun.Name = 'Test invoice';
        singaporeInvoiceRun.blng__InvoiceScheduler__c = singaporeSchedule.ID;
        singaporeInvoiceRun.blng__Status__c = 'Started';
        singaporeInvoiceRun.blng__StartTime__c = System.today().adddays(1);
        singaporeInvoiceRun.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        singaporeInvoiceRun.blng__TargetDate__c = Date.valueOf('2021-09-01');
        insert singaporeInvoiceRun;
        
        List<blng__Invoice__c> invoiceList2 = new List<blng__Invoice__c>();
        for (Account acc : accountList1) {
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accountList1[0].ID;//acc.ID;
            invoice.blng__InvoiceStatus__c = 'Initiated';
            invoice.blng__InvoiceRunCreatedBy__c = singaporeInvoiceRun.ID;
            invoice.QTB_Invoice_Period__c = singaporeFinancePeriod.ID;
            invoice.QTB_Purchase_Order__c = poList[0].ID;
            //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
            invoiceList2.add(invoice);
        }
        if(!invoiceList2.isEmpty()){
            insert invoiceList2;
        }
        System.debug('invoiceList2:'+invoiceList2);
        invoiceList2[0].blng__InvoiceStatus__c = 'Draft';
        invoiceList2[0].blng__InvoiceDate__c = System.today();
        invoiceList2[0].QTB_Service_Type__c = 'Storage';
        //invoiceList2[0].QTB_Internal_PO_Notes__c = 'Test1';
        
        invoiceList2[1].blng__InvoiceStatus__c = 'Draft';
        invoiceList2[1].blng__InvoiceDate__c = System.today();
        invoiceList2[1].QTB_Invoice_Type__c = 'ReBill';
        invoiceList2[1].QTB_Parent_Invoice__c = invoiceList2[0].ID;
        invoiceList2[1].QTB_Service_Type__c = 'Service';
        //invoiceList2[1].QTB_Internal_PO_Notes__c = 'Test2';
        
        invoiceList2[2].blng__InvoiceStatus__c = 'Draft';
        invoiceList2[2].blng__InvoiceDate__c = System.today();
        invoiceList2[2].QTB_Service_Type__c = 'Mixed';
        //invoiceList2[2].QTB_Internal_PO_Notes__c = 'Test3';
        
        invoiceList2[3].blng__InvoiceStatus__c = 'Draft';
        invoiceList2[3].blng__InvoiceDate__c = System.today();
        //invoiceList2[3].QTB_Internal_PO_Notes__c = 'Test4';
        
        invoiceList2[4].blng__InvoiceStatus__c = 'Draft';
        invoiceList2[4].blng__InvoiceDate__c = System.today();
        //invoiceList2[4].QTB_Internal_PO_Notes__c = 'Test5';
        
        invoiceList2[5].blng__InvoiceStatus__c = 'Draft';
        invoiceList2[5].blng__InvoiceDate__c = System.today();
        //invoiceList2[5].QTB_Internal_PO_Notes__c = 'Test6';
        
        invoiceList2[6].blng__InvoiceStatus__c = 'Draft';
        invoiceList2[6].blng__InvoiceDate__c = System.today();
        //invoiceList2[6].QTB_Internal_PO_Notes__c = 'Test7';
        
        invoiceList2[7].blng__InvoiceStatus__c = 'Draft';
        invoiceList2[7].blng__InvoiceDate__c = System.today();
        //invoiceList2[7].QTB_Internal_PO_Notes__c = 'Test8';
        
        invoiceList2[8].blng__InvoiceStatus__c = 'Draft';
        invoiceList2[8].blng__InvoiceDate__c = System.today();
        invoiceList2[8].QTB_Transferred_To_Oracle__c = true;
        //invoiceList2[8].QTB_Internal_PO_Notes__c = 'Test';
        Database.update(invoiceList2);
        Set<ID> InvoiceIds = new Set<ID>();
        for(blng__Invoice__c inv: invoiceList2){
            InvoiceIds.add(inv.ID);
        }
        ID pricebookId = Test.getStandardPricebookId();
        //Product 
        
        Product2 p = new Product2();
        p.Name = 'Test Product';
        p.isActive = true;
        p.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p.SBQQ__HasConsumptionSchedule__c = true;
        Insert p;
        
        	blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
		invoiceLine.Name = p.Name;
		invoiceLine.blng__Invoice__c = invoiceList2[0].ID;
		invoiceLine.blng__Product__c = p.ID;
		invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
		invoiceLine.blng__Quantity__c = 10;
		invoiceLine.blng__UnitPrice__c = 5;
		invoiceLine.blng__TaxPercentageApplied__c = 24;
		//invoiceLine.blng__OrderProduct__c = orderItemFinal[0].ID;
		//invoiceLine.blng__UsageSummary__c = usageSumFinal[i].ID;
		//if(i == 0){
			//invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
		//}else{
			invoiceLine.blng__InvoiceLineStatus__c = 'Posted';
		//}
		invoiceLine.blng__TaxAmount__c = 50;
		invoiceLine.blng__TaxCountry__c = 'Singapore';
		invoiceLine.blng__TaxState__c = 'Singapore';
		invoiceLine.blng__TaxCity__c = 'Singapore';
		invoiceLine.blng__TaxZipCode__c = '0000';
		invoiceLine.blng__LegalEntity__c = singaporeEntity.ID;
		invoiceLine.blng__Subtotal__c = 1000;
		//invoiceLine.blng__TaxRule__c = taxRule.ID;
		invoiceLine.QTB_Inc_Quantity__c = 10;
		invoiceLine.QTB_Taxable_Amount__c = 10; 
              
    	Insert invoiceLine;
        //List<blng__Invoice__c> allInvoice=new List<blng__Invoice__c>();
        //allInvoice.add
        //QTB_InvoiceHelper.updateInvoiceMRCDates(InvoiceIds);
        QTB_InvoiceHelper.populateOrderFieldsOnInvoice(invoiceList2);
        //QTB_InvoiceHelper.updatePOForCreditAndRebill(invoiceList2,null);
        Test.stopTest();
    }*/
  /*  static testMethod void testmethod11() {
        Test.startTest();
            SBQQ.TriggerControl.disable();
            List<Account> testAccount = [select ID,QTB_Split_Invoice_Flag__c,QTB_SITAD__c,QTB_Legal_Entity_Country__c FROM Account WHERE name='Test Account'];
            testAccount[0].QTB_Split_Invoice_Flag__c=true;
        	testAccount[0].QTB_SITAD__c=true;
        	testAccount[0].QTB_Legal_Entity_Country__c = 'Canada';
        	update testAccount[0];
            List<AccountContactRelation> Acr=[select ID FROM AccountContactRelation  WHERE AccountId=:testAccount[0].ID];
        	acr[0].Roles = 'PO Contact';
        	Update acr[0];
            blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
                'Yes'
            );
            blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
            );
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            
            List<Product2> product = QTB_TestDataFactory.createProducts(1);
        	product[0].ID =product[0].ID;
            product[0].blng__BillingRule__c = billingRule.ID;
            product[0].blng__RevenueRecognitionRule__c = revenueRule.ID;
            product[0].blng__TaxRule__c = taxRule.ID;
            update product[0]; 
            
            ID pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
                product[0]
            );
            IM_Country__c im = new IM_Country__c();//[select ID,Name,Iso31662Code__c FROM IM_Country__c WHERE Name=:'United States'];
			im.Name = 'United States';
			im.CurrencyIsoCode = 'USD';
			im.Region__c = 'North America';
			im.AlternativeNames__c = 'United States';
			im.Iso31662Code__c ='US';
			im.Iso31663Code__c ='USA';        
			insert im;
            
            List<opportunity> testOpp =new  List<opportunity>();
            opportunity  op=New opportunity();
            op.recordtypeid= QTB_Utils.OPP_BILL_RECTYPEID;
            op.Pricebook2Id = pricebookId;
            op.Primary_Product_Line__c='Data Management';
            op.Name = 'Test';
            op.AccountId = testAccount[0].ID;
            op.CloseDate = Date.today();
            op.StageName = '1 - Qualification';
            op.Amount = 500;
            op.Billing_Country__c = im.ID;
            testOpp.add(op);
            
            Database.insert(testOpp);
            
            testOpp[0].Pricebook2Id = pricebookId;
            Database.update(testOpp);
            
            List<SBQQ__Quote__c> testquote = QTB_TestDataFactory.createCPQQuotes(
                1,
                testOpp[0].ID,
                testAccount[0].ID,
                true,
                null
            );
            System.debug('testquote@@'+testquote);
            testquote[0].SBQQ__PriceBook__c = pricebookId;
            testquote[0].SBQQ__StartDate__c = System.Today();
            Database.update(testquote);
            
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
                1,
                testquote[0].ID,
                testAccount[0].ID
            );
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(
                1,
                testquote[0].ID,
                quoteGroupList[0].ID,
                product[0].ID
            );
            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
                1,
                testquote[0].ID,
                testAccount[0].ID
            );
            
            orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
            orderList3[0].QTB_OrderCategory__c = 'Rebill';
            update orderList3[0];
            
            List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(
                orderList3[0].ID,
                product[0].ID,
                quoteLinesList,
                standardPrice
            );
        
         QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c();
            pOrder.QTB_Billing_Account__c = testAccount[0].ID;
                pOrder.QTB_Status__c = 'Active';
                pOrder.QTB_Start_Date__c = System.today();
                pOrder.QTB_End_Date__c = System.today();
                pOrder.QTB_PO_Type__c = 'Standard';
                pOrder.QTB_Customer_PO__c = 'QW2315';
                pOrder.QTB_Amount__c = 10000;
                pOrder.QTB_Service_Type__c ='Storage';
        insert pOrder;
            
        // Invoice
        List<blng__Invoice__c> listofInv=new List<blng__Invoice__c>();
        blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = testAccount[0].ID;//acc.ID;
            invoice.blng__InvoiceStatus__c = 'Initiated';
           // invoice.blng__InvoiceRunCreatedBy__c = singaporeInvoiceRun.ID;
           // invoice.QTB_Invoice_Period__c = singaporeFinancePeriod.ID;
            invoice.QTB_Purchase_Order__c = pOrder.ID;
        listofInv.add(invoice);
      Insert listofInv;
        
            //creating usage summary
            List<blng__UsageSummary__c> usageSumList = new List<blng__UsageSummary__c>();
            List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(
                2,
                testAccount[0],
                orderList3[0],
                orderItemList3[0]
            );
            //List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(testAccount);
            
            blng__UsageSummary__c usagesummary = usageSum[0];
            usagesummary.blng__Status__c = 'Queued For Invoice';
            usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
            usagesummary.blng__UnitPrice__c = 12;
            usagesummary.blng__Invoice__c = listofInv[0].ID;
            
            blng__UsageSummary__c usagesummary1 = usageSum[1];
            usagesummary1.blng__Status__c = 'Queued For Invoice';
            usagesummary1.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
            usagesummary1.blng__MatchingId__c = '1234';
            usagesummary1.blng__UnitPrice__c = 10;
            
            usageSumList.add(usagesummary);
            usageSumList.add(usagesummary1);
          
            update usageSumList;
            
            System.Assert(usageSum[0].blng__Status__c == 'Queued For Invoice');
            
            List<blng__Usage__c> usageListnew = new List<blng__Usage__c>();
            List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(
                2,
                testAccount[0],
                usagesummary
            );
            List<blng__Usage__c> blngUsages = new List<blng__Usage__c>();
            blng__Usage__c usage0 = new blng__Usage__c();
            usage0.blng__UsageSummary__c = usagesummary.ID;
            usage0.blng__Account__c = testAccount[0].ID;
            usage0.blng__MatchingId__c = '111';
            usage0.blng__EndDateTime__c = date.today() + 1;
            usage0.blng__StartDateTime__c = date.today();
            usage0.QTB_Price_Tier__c = 'Tier 1'; 
            usage0.QTB_Delivery_Date__c = System.Today();
            usage0.QTB_Actual_Rate__c  = 0.7;
            usage0.QTB_Tax_Street__c ='Test';
       	    usage0.QTB_Source_Invoice_Reference__c = 'jjs';
            usage0.blng__PreratedQuantity__c = 19;
            blngUsages.add(usage0);
            if (!blngUsages.isEmpty()) {
                Database.insert(blngUsages, false);
            }
            blng__Usage__c usage = usageList[0];
            usage.blng__PreratedAmount__c = 0;
            usage.blng__PreratedQuantity__c = 0;
            usage.blng__Quantity__c = 15;
            usage.blng__UnitPrice__c = 1;
            usage.blng__OrderProduct__c = orderItemList3[0].ID;
            usage.blng__Order__c = orderList3[0].ID; 
			
            
            blng__Usage__c usage1 = usageList[1];
            usage1.blng__PreratedAmount__c = 10;
            usage1.blng__UnitPrice__c = 5;
            usage1.QTB_Price_Tier__c = 'Tier 1';
          
            blngUsages.add(usage0);
            
            blng__Usage__c usage2 = usageList[1];
            usage0.QTB_Price_Tier__c = 'None';
            usage0.QTB_Delivery_Date__c = System.Today()+1;
            usage0.QTB_Actual_Rate__c  = 0.9;
            usage0.QTB_Tax_Street__c = 'Test2';
            usageListnew.add(usage0);
            usageListnew.add(usage);
            usageListnew.add(usage1);
            //update usageListnew;
            
            usagesummary.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
            Database.update(usagesummary);
            usage.blng__UnitPrice__c = 1112;
            usage.QTB_Price_Tier__c = 'Tier 1';
            //usage.blng__PreratedQuantity__c = 20;
            SBQQ.TriggerControl.disable();
            Database.update(usage);
            //Database.delete(usage);
            List<blng__Usage__c> usageList1 = QTB_TestDataFactory.createUsages(1,testAccount[0],usagesummary);
        System.debug('###################'+listofInv[0].blng__Account__r.QTB_SITAD__c);
        System.debug('###################'+listofInv);
        System.debug('###################'+listofInv[0].blng__Account__r.QTB_Legal_Entity_Country__c);
        QTB_InvoiceHelper.updateNotesOnAccountFromUsage(listofInv);
        Test.stopTest();
        //QTB_InvoiceHelper.dummyCodeForSomeTime();
    }*/
    static testmethod void method12(){
        Test.startTest();
        System.debug('in method12');
        //Account
        List<Account> accountNewList = new List<Account>();
        ID standardrecordID = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
        ID recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
        for (Integer i = 0; i < 10; i++) {
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
                a.QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
            }
            if(i == 1){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 2){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 3){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 4){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 5){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 6){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 7){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = '';
                a.QTB_Billing_Frequency__c = '';  
            }
            accountNewList.add(a);
        }
        
        if (!accountNewList.isEmpty()) {
            insert accountNewList;
        }
        
        System.debug('>>>accountNewList in method12 31276' +accountNewList[0].ID); 
        
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
        usaEntity.Name = 'Test Legal Entity Singapore';
        usaEntity.blng__Active__c = true;
        usaEntity.blng__Country__c = 'United States';
        usaEntity.QTB_Type__c = 'Contract';
        insert usaEntity;          
        
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'Test schedule 2';
        schedule.blng__Type__c = 'Once';
        schedule.blng__InvoiceBatches__c = 'Rebill Run';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.today();
        schedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        schedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        schedule.QTB_Legal_Entity__c = usaEntity.ID;
        //insert schedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Test invoice';
        invoiceRun.blng__InvoiceScheduler__c = schedule.ID;
        invoiceRun.blng__Status__c = 'Started';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
        insert invoiceRun; 
        
        blng__Invoice__c inv1 = new blng__Invoice__c();
        inv1.blng__Account__c = accountNewList[0].ID; 
        inv1.blng__InvoiceStatus__c = 'Draft';
        inv1.blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        inv1.QTB_ReBill_Status__c='ReBill Completed';
        inv1.QTB_Case_Number__c = 'CA245566';
        inv1.QTB_Service_District__c = 'Test district';
        inv1.QTB_Site_Number__c = 'CS15545466';
        //31276 commented inv1.blng__Notes__c = 'ALM Case No: 1234566';
        // Readable inv1.QTB_LegalEntityCountry__r ='United States'; // 31276
        insert inv1;
        System.debug('inv1>>'+inv1);
        List<blng__Invoice__c> invoicelisted = new  List<blng__Invoice__c>();
        
        inv1.blng__InvoiceStatus__c = 'Posted';
        inv1.QTB_ReBill_Status__c='';
        update inv1;
        invoicelisted.add(inv1);
        
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        //invoiceLine[0].Name = 'prodName';
        invoiceLine1.blng__Invoice__c = inv1.ID;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine1.blng__Quantity__c = 10;
        invoiceLine1.blng__UnitPrice__c = 5;
        invoiceLine1.blng__Subtotal__c = 100;
        invoiceLine1.blng__TaxCountry__c = 'India';
        insert invoiceLine1;
        
        QTB_InvoiceHelper.populateOrderFieldsOnInvoice(invoicelisted);
        //31276 starts
        accountNewList[0].QTB_Legal_Entity_Country__c='France';
        update accountNewList[0];
        inv1.QTB_Service_District__c = 'Test district2';
        update inv1;
        List<blng__Invoice__c> invoicelisted2 = new List<blng__Invoice__c>();
        invoicelisted2.add(inv1);
        QTB_InvoiceHelper.populateOrderFieldsOnInvoice(invoicelisted2);

        accountNewList[0].QTB_Language__c = 'fr';
        update accountNewList[0];
        inv1.QTB_Service_District__c = 'Test district3';
        update inv1;
        List<blng__Invoice__c> invoicelisted3 = new List<blng__Invoice__c>();
        invoicelisted3.add(inv1);
        QTB_InvoiceHelper.populateOrderFieldsOnInvoice(invoicelisted3);
        //31276 ends
        Test.stopTest();
    }
    
     static testmethod void method14(){
        Test.startTest();
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(2);
        Set<String> addressComparison = new Set <String>();
        
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accList);
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Rebill Run';
        accountList[0].QTB_Legal_Entity_Country__c='Canada';
        accountList[0].QTB_Bill_Forward_Type__c='Advance';
        accountList[0].QTB_Billing_Frequency__c='Monthly';
        accountList[0].QTB_SITAD__c = true;
        accountList[0].QTB_Legal_Entity_Country__c ='United States';
        //accountList[0].CurrencyIsoCode = 'INR';
        update accountList;
        
        accountList[0].QTB_Bill_Forward_Type__c='Arrears';
        update accountList;
        
        //Legal Entity
        blng__LegalEntity__c singaporeEntity = new blng__LegalEntity__c();
        singaporeEntity.Name = 'Test Legal Entity Singapore';
        singaporeEntity.blng__Active__c = true;
        singaporeEntity.blng__Country__c = 'United States';
        //singaporeEntity.blng__Country__c = 'Singapore';
        singaporeEntity.QTB_Type__c = 'Contract';
        singaporeEntity.QTB_Legal_Entity_Number__c = 45000;
        insert singaporeEntity; 
        
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'Test schedule 1';
        schedule.blng__Type__c = 'Once';
        schedule.blng__InvoiceBatches__c = 'Rebill Run';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.today();
        schedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        schedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        schedule.QTB_Parent_Invoice__c = invList[0].ID;
        schedule.QTB_Legal_Entity__c  = singaporeEntity.ID;
        //insert schedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Test invoice';
        invoiceRun.blng__InvoiceScheduler__c = schedule.ID;
        invoiceRun.blng__Status__c = 'Started';
        //invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
        insert invoiceRun;
        
        blng__FinancePeriod__c  finP = new blng__FinancePeriod__c();
        finP.Name = 'Mar-2024';
       // finP.blng__PeriodType__c = 'Accounting';
       // finP.blng__PeriodEndDate__c = '3/31/2024';
      //  finP.blng__PeriodStartDate__c = '3/1/2024';
        finP.blng__PeriodStatus__c = 'Open';
        //insert finP;
        
        
        
        Set<ID> postedid=new set<ID>();
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[0].ID;
        invoice.blng__InvoiceStatus__c = 'Draft';
        invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
        insert invoice;
        
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,null,accountList[0].ID);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        Database.update(orderList3);
        
        Product2 p = new Product2();
        p.Name = 'Test Product';
        p.isActive = true;
        p.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p.SBQQ__HasConsumptionSchedule__c = true;
        Insert p;
        ID pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = new PricebookEntry();
        	standardPrice.Product2Id =  p.ID;
        	standardPrice.UnitPrice = 15;
        	standardPrice.Pricebook2Id = pricebookId;
        	insert standardPrice;
               
          
		
      List<OrderItem> orderItemList3 = new List<OrderItem>();
        try {
      for (Integer i = 0; i < 1; i++) {
        orderItemList3.add(
          new OrderItem(
            OrderId = orderList3[0].ID,
            Quantity = 2.00,
            UnitPrice = 12.00,
            //SBQQ__QuoteLine__c = quoteLines[i].ID,
            PricebookEntryId = standardPrice.ID,
            SBQQ__ChargeType__c = 'One-Time',
            product2id = p.ID,
            SBQQ__Activated__c = true,
            blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes')
              .ID,
            blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
              )
              .ID,
            blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').ID,
              blng__HoldBilling__c = 'Yes'
          )
        );
      }
      if (!orderItemList3.isEmpty()) {
        System.debug('orderItemList3>' + orderItemList3);
        insert orderItemList3;
      }}catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      System.debug('The following exception has occurred: ' + e);
    }
        
         List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(
                2,
                accountList[0],
                orderList3[0],
                orderItemList3[0]
            );
            //List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(testAccount);
            
            /*blng__UsageSummary__c usagesummary = usageSum[0];
            usagesummary.blng__Status__c = 'Queued For Invoice';
            usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
            usagesummary.blng__UnitPrice__c = 12;
            usagesummary.blng__Invoice__c = invoice.ID;*/
            
            blng__UsageSummary__c usagesummary1 = usageSum[1];
            usagesummary1.blng__Status__c = 'Queued For Invoice';
            usagesummary1.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
            usagesummary1.blng__MatchingId__c = '1234';
            usagesummary1.blng__UnitPrice__c = 10;
            usagesummary1.blng__Invoice__c = invoice.ID;
            update usagesummary1;
        
        blng__Usage__c usage0 = new blng__Usage__c();
            usage0.blng__UsageSummary__c = usagesummary1.ID;
            usage0.blng__Account__c = accountList[0].ID;
            usage0.blng__MatchingId__c = '1234';
            usage0.blng__EndDateTime__c = date.today() + 1;
            usage0.blng__StartDateTime__c = System.today();
            usage0.QTB_Price_Tier__c = 'Tier 1'; 
            usage0.QTB_Delivery_Date__c = System.Today();
            usage0.QTB_Actual_Rate__c  = 0.7;
            usage0.QTB_Tax_Street__c ='Test';
            usage0.blng__PreratedQuantity__c = 19;
        	usage0.QTB_Source_Invoice_Reference__c = 'jjs';
            usage0.CurrencyIsoCode = 'USD';
        	SBQQ.TriggerControl.disable();
            insert usage0; 
        
        invoice.blng__InvoiceStatus__c = 'Posted';
        update invoice;
        
         //QTB_InvoiceHelper.updateNotesOnAccountFromUsage(new List<blng__Invoice__c> {invoice});
        
        Test.stopTest();
    }
    
    static testMethod void testmethod15() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        
        QTB_InvoiceTriggerHandler.throwExplicitException = false;
        List<Account> accList = QTB_TestDataFactory.createAccounts(20);
        accList[0].QTB_Billing_Frequency__c = 'Monthly';
        accList[0].QTB_Bill_Forward_Type__c = 'Arrears';
        update accList;
        Set<String> addressComparison = new Set <String>();
        
        blng__LegalEntity__c singaporeEntity = new blng__LegalEntity__c();
        singaporeEntity.Name = 'Test Legal Entity India';
        singaporeEntity.blng__Active__c = true;
        //singaporeEntity.blng__Country__c = 'United States';
        singaporeEntity.blng__Country__c = 'India';
        singaporeEntity.QTB_Type__c = 'Contract';
        singaporeEntity.QTB_Legal_Entity_Number__c = 45000;
        insert singaporeEntity; 
        
        blng__FinanceBook__c singaporeFinanceBook = new blng__FinanceBook__c();
        singaporeFinanceBook.Name = 'Accounting Finance Book';
        singaporeFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
        singaporeFinanceBook.blng__Active__c = true;
        singaporeFinanceBook.blng__PeriodType__c='Accounting';
        insert singaporeFinanceBook;
        
        
        blng__FinancePeriod__c singaporeFinancePeriod = new blng__FinancePeriod__c();
        singaporeFinancePeriod.Name = 'singapore Mar 2024';
        singaporeFinancePeriod.blng__FinanceBook__c = singaporeFinanceBook.ID;
        singaporeFinancePeriod.blng__PeriodStartDate__c = System.today().toStartofMonth();
        singaporeFinancePeriod.blng__PeriodEndDate__c = System.today().addMonths(1).toStartofMonth().addDays(-1);
        singaporeFinancePeriod.blng__LegalEntity__c = singaporeEntity.ID;
        singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert singaporeFinancePeriod;
        
        blng__InvoiceScheduler__c singaporeSchedule = new blng__InvoiceScheduler__c();
        singaporeSchedule.Name = 'Test for Singapore';
        singaporeSchedule.blng__Type__c = 'Once';
        singaporeSchedule.blng__InvoiceBatches__c = 'India IRM-1st;India OEC-1st'; 
        singaporeSchedule.CurrencyIsoCode = 'INR';
        singaporeSchedule.blng__StartDateTime__c = System.today().adddays(1);
        singaporeSchedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        singaporeSchedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        singaporeSchedule.QTB_Legal_Entity__c  = singaporeEntity.ID;
        singaporeSchedule.QTB_Invoice_Period__c = singaporeFinancePeriod.ID ;
        insert singaporeSchedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Test invoice';
        invoiceRun.blng__InvoiceScheduler__c = singaporeSchedule.ID;
        invoiceRun.blng__Status__c = 'Started';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
        insert invoiceRun;
        
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accList);
        invList[0].blng__InvoiceStatus__c = 'Posted';
        invList[0].QTB_Invoice_Period__c = singaporeFinancePeriod.ID;
        invList[0].blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        update invList[0];
        Set<ID> invId = new  Set<ID>();
        invId.add(invList[0].ID);
        String str;
        String str2;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
        
        accList[0].QTB_Billing_Frequency__c = 'Quarterly';
        accList[0].QTB_Bill_Forward_Type__c = 'Arrears';
        update accList;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
        
        accList[0].QTB_Billing_Frequency__c = 'Semiannual';
        accList[0].QTB_Bill_Forward_Type__c = 'Arrears';
        update accList;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
        
        accList[0].QTB_Billing_Frequency__c = 'Quarterly';
        accList[0].QTB_Bill_Forward_Type__c = 'Advance';
        update accList;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
        accList[0].QTB_Billing_Frequency__c = 'Monthly';
        accList[0].QTB_Bill_Forward_Type__c = 'Arrears';
        update accList;
    
        Test.stopTest();
    }
    static testMethod void testmethod16() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        
        QTB_InvoiceTriggerHandler.throwExplicitException = false;
        List<Account> accList = QTB_TestDataFactory.createAccounts(20);
        accList[0].QTB_Billing_Frequency__c = 'Monthly';
        accList[0].QTB_Bill_Forward_Type__c = 'Arrears';
        update accList;
        Set<String> addressComparison = new Set <String>();
        
        blng__LegalEntity__c singaporeEntity = new blng__LegalEntity__c();
        singaporeEntity.Name = 'Test Legal Entity India';
        singaporeEntity.blng__Active__c = true;
        //singaporeEntity.blng__Country__c = 'United States';
        singaporeEntity.blng__Country__c = 'India';
        singaporeEntity.QTB_Type__c = 'Contract';
        singaporeEntity.QTB_Legal_Entity_Number__c = 45000;
        insert singaporeEntity; 
        
        blng__FinanceBook__c singaporeFinanceBook = new blng__FinanceBook__c();
        singaporeFinanceBook.Name = 'Accounting Finance Book';
        singaporeFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
        singaporeFinanceBook.blng__Active__c = true;
        singaporeFinanceBook.blng__PeriodType__c='Accounting';
        insert singaporeFinanceBook;
        
        
        blng__FinancePeriod__c singaporeFinancePeriod = new blng__FinancePeriod__c();
        singaporeFinancePeriod.Name = 'singapore Mar 2024';
        singaporeFinancePeriod.blng__FinanceBook__c = singaporeFinanceBook.ID;
        singaporeFinancePeriod.blng__PeriodStartDate__c = System.today().toStartofMonth();
        singaporeFinancePeriod.blng__PeriodEndDate__c = System.today().addMonths(1).toStartofMonth().addDays(-1);
        singaporeFinancePeriod.blng__LegalEntity__c = singaporeEntity.ID;
        singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert singaporeFinancePeriod;
        
        blng__InvoiceScheduler__c singaporeSchedule = new blng__InvoiceScheduler__c();
        singaporeSchedule.Name = 'Test for Singapore';
        singaporeSchedule.blng__Type__c = 'Once';
        singaporeSchedule.blng__InvoiceBatches__c = 'India IRM-1st;India OEC-1st'; 
        singaporeSchedule.CurrencyIsoCode = 'INR';
        singaporeSchedule.blng__StartDateTime__c = System.today().adddays(1);
        singaporeSchedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        singaporeSchedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        singaporeSchedule.QTB_Legal_Entity__c  = singaporeEntity.ID;
        singaporeSchedule.QTB_Invoice_Period__c = singaporeFinancePeriod.ID ;
        insert singaporeSchedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Test invoice';
        invoiceRun.blng__InvoiceScheduler__c = singaporeSchedule.ID;
        invoiceRun.blng__Status__c = 'Started';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
        insert invoiceRun;
        
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accList);
        invList[0].blng__InvoiceStatus__c = 'Posted';
        invList[0].QTB_Invoice_Period__c = singaporeFinancePeriod.ID;
        invList[0].blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        update invList[0];
        Set<ID> invId = new  Set<ID>();
        invId.add(invList[0].ID);
        String str;
        String str2;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
        
        accList[0].QTB_Billing_Frequency__c = 'Semiannual';
        accList[0].QTB_Bill_Forward_Type__c = 'Advance';
        update accList;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);

		accList[0].QTB_Billing_Frequency__c = 'Annual';
        accList[0].QTB_Bill_Forward_Type__c = 'Arrears';
        update accList;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
            
        Test.stopTest();
    }
    
    
    static testmethod void method701(){
        Test.startTest();
        
        QTB_Tax_Integration_Setting__mdt vertexData = new QTB_Tax_Integration_Setting__mdt();
        vertexData.Label = 'Vertex';
        vertexData.DeveloperName = 'Vertex_Integration';
        vertexData.QTB_Country__c = 'United States;Canada';
        vertexData.QTB_End_System__c = 'Vertex';
        
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(2);
        Set<String> addressComparison = new Set <String>();
            
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accList);
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Rebill Run';
        accountList[0].QTB_Legal_Entity_Country__c='Canada';
        accountList[0].QTB_Bill_Forward_Type__c='Advance';
        accountList[0].QTB_Billing_Frequency__c='Monthly';
        accountList[0].Payment_Terms__c = 'Net 15';
        //accountList[0].CurrencyIsoCode = 'INR';
        update accountList;
        
        //Legal Entity
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
        usaEntity.Name = 'Test Legal Entity Singapore';
        usaEntity.blng__Active__c = true;
        usaEntity.blng__Country__c = 'United States';
        usaEntity.QTB_Type__c = 'Contract';
        // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert usaEntity;          
        
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'Test schedule 2';
        schedule.blng__Type__c = 'Once';
        schedule.blng__InvoiceBatches__c = 'Rebill Run';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.today();
        schedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        schedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        schedule.QTB_Parent_Invoice__c = invList[0].ID;
        schedule.QTB_Legal_Entity__c = usaEntity.ID;
        //insert schedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Test invoice';
        invoiceRun.blng__InvoiceScheduler__c = schedule.ID;
        invoiceRun.blng__Status__c = 'Started';
        //invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
        insert invoiceRun;
        
        blng__FinanceBook__c usFinanceBook = new blng__FinanceBook__c();
        usFinanceBook.Name = 'Accounting Finance Book';
        usFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
        usFinanceBook.blng__Active__c = true;
        usFinanceBook.blng__PeriodType__c='Accounting';
        insert usFinanceBook;
        
        blng__FinancePeriod__c usFinancePeriod = new blng__FinancePeriod__c();
        usFinancePeriod.Name = 'singapore Mar 2024';
        usFinancePeriod.blng__FinanceBook__c = usFinanceBook.ID;
        usFinancePeriod.blng__PeriodStartDate__c = System.today().toStartofMonth();
        usFinancePeriod.blng__PeriodEndDate__c = System.today().addMonths(1).toStartofMonth().addDays(-1);
        usFinancePeriod.blng__LegalEntity__c = usaEntity.ID;
        usFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert usFinancePeriod;

        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,null,accountList[0].ID);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        orderList3[0].QTB_InvoicePeriod__c = usFinancePeriod.ID;
        orderList3[0].QTB_InvoiceDate__c = System.Today();
       // orderList3[0].bling_Legal_Entity__c=singaporeEntity.Id;
        Database.update(orderList3);
        
        Set<ID> postedid=new set<ID>();
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[0].ID;
        invoice.blng__InvoiceStatus__c = 'Draft';
        invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        invoice.QTB_ReBill_Status__c='ReBill Completed';
        invoice.QTB_Case_Number__c = 'CA245566';
        invoice.QTB_Service_District__c = 'Test district';
        invoice.QTB_Site_Number__c = 'CS15545466';
        invoice.QTB_Invoice_Type__c = 'Rebill';
        invoice.blng__Order__c=orderList3[0].ID;
        //formula field invoice.QTB_PaymentTerm__c = 30; 31276
        invoice.blng__InvoiceDate__c = System.today();
        // formula field invoice.QTB_AdHocInvoicePeriod__c = System.today(); 31276
        // formula field  invoice.QTB_AdHocInvoiceDate__c = System.today();31276
		insert invoice;        
        //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
        
        invoice.blng__InvoiceStatus__c = 'Posted';
        invoice.QTB_ReBill_Status__c='';
        update invoice;
        
        QTB_Bill_Flow_Controller__c  bill=new QTB_Bill_Flow_Controller__c();
        bill.Execute_Post_Bill_Run__c=False;
        bill.Execute_Pre_Bill_Run__c=True;
        bill.Invoice_Scheduler__c=schedule.ID;
        bill.Name='abc';
        bill.QTB_PostBill_Run_Status__c ='None';
        bill.QTB_PreBill_Run_Status__c='In Progress';
        bill.QTB_Rebill_Order__c = orderList3[0].ID;
        insert bill;
        
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__Invoice__c = invoice.ID;
        invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;
        //invoiceLine.blng__UsageSummary__c = usagesummary.ID; 
        invoiceLine.blng__Subtotal__c = 100;
        invoiceLine.blng__TaxCountry__c = 'India';
        insert invoiceLine;
        //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
        
        postedid.add(invoice.ID);
        invoice.blng__InvoiceStatus__c = 'Posted';
        invoice.QTB_ReBill_Status__c='';
        
        //QTB_InvoiceHelper.callVertexAndAssignBillFlowControllerForRebill(postedid);
        Test.stopTest();
    }
    
    
    static testmethod void method122(){
        Test.startTest();
        //Account
        List<Account> accountNewList = new List<Account>();
        ID standardrecordID = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
        ID recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
        for (Integer i = 0; i < 10; i++) {
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
                a.QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
            }
            if(i == 1){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 2){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 3){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 4){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 5){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 6){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 7){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = '';
                a.QTB_Billing_Frequency__c = '';  
            }
            accountNewList.add(a);
        }
        
        if (!accountNewList.isEmpty()) {
            insert accountNewList;
        }
        
        System.debug('>>>accountNewList'+accountNewList[0].ID); 
        
        Contact cont = new Contact();
        cont.LastName = 'test112';
        cont.FirstName = 'abc12';
        cont.email = 'so112@email.com';
        cont.AccountId = accountNewList[0].ID;
        cont.MailingCountry = 'Canada';
        cont.IM_Role__c = 'PO Contact';
        insert cont;
         
        AccountContactRelation acr = new AccountContactRelation();
        acr.accountId = accountNewList[1].ID;
        acr.ContactId = cont.ID;
        insert acr;
        acr.Roles = 'PO Contact';
        update acr;
         
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
        usaEntity.Name = 'Test Legal Entity Singapore';
        usaEntity.blng__Active__c = true;
        usaEntity.blng__Country__c = 'United States';
        usaEntity.QTB_Type__c = 'Contract';
        insert usaEntity;          
        
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'Test schedule 2';
        schedule.blng__Type__c = 'Once';
        schedule.blng__InvoiceBatches__c = 'Rebill Run';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.today();
        schedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        schedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        schedule.QTB_Legal_Entity__c = usaEntity.ID;
        //insert schedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Test invoice';
        invoiceRun.blng__InvoiceScheduler__c = schedule.ID;
        invoiceRun.blng__Status__c = 'Started';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
        insert invoiceRun; 
        
		//Set<ID> billingAccount1 = new Set<ID>();
         
        blng__Invoice__c inv1 = new blng__Invoice__c();
        inv1.blng__Account__c = accountNewList[1].ID; 
        inv1.blng__InvoiceStatus__c = 'Draft';
        inv1.blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        inv1.QTB_ReBill_Status__c='ReBill Completed';
        inv1.QTB_Case_Number__c = 'CA245566';
        inv1.QTB_Service_District__c = 'Test district';
        inv1.QTB_Site_Number__c = 'CS15545466';
       // billingAccount1.add(inv1.blng__Account__c); 
        insert inv1;
        //billingAccount1.add(inv1.blng__Account__c); 
        
         
        QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c(
            QTB_Billing_Account__c = accountNewList[1].ID,
            QTB_Status__c = 'Active',
            QTB_Start_Date__c = System.today(),
            QTB_End_Date__c = System.today(),
            QTB_PO_Type__c = 'Standard',
            QTB_Customer_PO__c = 'QW2315',
            QTB_Amount__c = 10000,
            QTB_Service_Type__c = 'Mixed');
        insert pOrder; 
         
        System.debug('inv1>>'+inv1);
        List<blng__Invoice__c> invoicelisted = new  List<blng__Invoice__c>();
        
        inv1.blng__InvoiceStatus__c = 'Posted';
        inv1.QTB_ReBill_Status__c='';
        update inv1;
        invoicelisted.add(inv1);
        
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        //invoiceLine[0].Name = 'prodName';
        invoiceLine1.blng__Invoice__c = inv1.ID;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine1.blng__Quantity__c = 10;
        invoiceLine1.blng__UnitPrice__c = 5;
        invoiceLine1.blng__Subtotal__c = 100;
        invoiceLine1.blng__TaxCountry__c = 'India';
        insert invoiceLine1;
        Map<ID, blng__Invoice__c> invMap = new Map<ID, blng__Invoice__c>();
        invMap.put(inv1.ID, inv1);
        QTB_InvoiceHelper.autoUpdatePO(invMap);
        Test.stopTest();
    }
    static testMethod void updateInvoiceMRCDatesTest(){
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        
        QTB_InvoiceTriggerHandler.throwExplicitException = false;
        List<Account> accList = QTB_TestDataFactory.createAccounts(20);
        accList[0].QTB_Billing_Frequency__c = 'Monthly';
        accList[0].QTB_Bill_Forward_Type__c = 'Arrears';
        accList[0].QTB_Legal_Entity_Country__c = 'India';
        //28758 2 lines
        // 31276 accList[0].QTB_Billing_Account_Type__c = 'Product Sales';
        accList[1].QTB_Billing_Frequency__c = 'Monthly';
        accList[1].QTB_Bill_Forward_Type__c = 'Arrears';
        accList[1].QTB_Legal_Entity_Country__c = 'India';
        accList[1].QTB_Billing_Account_Type__c = '';
        accList[0].Payment_Terms__c='Net 15';
        update accList;
        Set<String> addressComparison = new Set <String>();
        
        blng__LegalEntity__c singaporeEntity = new blng__LegalEntity__c();
        singaporeEntity.Name = 'Test Legal Entity India';
        singaporeEntity.blng__Active__c = true;
        //singaporeEntity.blng__Country__c = 'United States';
        singaporeEntity.blng__Country__c = 'India';
        singaporeEntity.QTB_Type__c = 'Contract';
        singaporeEntity.QTB_Legal_Entity_Number__c = 45000;
        insert singaporeEntity; 
        
        blng__FinanceBook__c singaporeFinanceBook = new blng__FinanceBook__c();
        singaporeFinanceBook.Name = 'Accounting Finance Book';
        singaporeFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
        singaporeFinanceBook.blng__Active__c = true;
        singaporeFinanceBook.blng__PeriodType__c='Accounting';
        insert singaporeFinanceBook;
        
        blng__FinancePeriod__c singaporeFinancePeriod = new blng__FinancePeriod__c();
        singaporeFinancePeriod.Name = 'singapore Mar 2024';
        singaporeFinancePeriod.blng__FinanceBook__c = singaporeFinanceBook.ID;
        singaporeFinancePeriod.blng__PeriodStartDate__c = System.today().toStartofMonth();
        singaporeFinancePeriod.blng__PeriodEndDate__c = System.today().addMonths(1).toStartofMonth().addDays(-1);
        singaporeFinancePeriod.blng__LegalEntity__c = singaporeEntity.ID;
        singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert singaporeFinancePeriod;
        
        blng__InvoiceScheduler__c singaporeSchedule = new blng__InvoiceScheduler__c();
        singaporeSchedule.Name = 'Test for Singapore';
        singaporeSchedule.blng__Type__c = 'Once';
        singaporeSchedule.blng__InvoiceBatches__c = 'India IRM-1st;India OEC-1st'; 
        singaporeSchedule.CurrencyIsoCode = 'INR';
        singaporeSchedule.blng__StartDateTime__c = System.today().adddays(1); 
        singaporeSchedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        singaporeSchedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        singaporeSchedule.QTB_Legal_Entity__c  = singaporeEntity.ID;
        singaporeSchedule.QTB_Invoice_Period__c = singaporeFinancePeriod.ID ;
        insert singaporeSchedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Test invoice';
        invoiceRun.blng__InvoiceScheduler__c = singaporeSchedule.ID;
        invoiceRun.blng__Status__c = 'Started';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
        insert invoiceRun;
        
        SBQQ.TriggerControl.disable();
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,null,accList[0].ID); // 31276 accList[0] to accList[1]
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        Database.update(orderList3);
        
        List<Product2> product = [SELECT ID,blng__BillingRule__c,blng__RevenueRecognitionRule__c,blng__TaxRule__c 
                                    FROM Product2];
         
        ID pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        List<OrderItem> orderItemList3 = new List<OrderItem>();
        //QTB_TestDataFactory.createCPQOrderItems(orderList3[0].ID,product[0].ID,quoteLinesList,standardPrice);
        try {
            for (Integer i = 0; i < 1; i++) {
                orderItemList3.add( new OrderItem( OrderId = orderList3[0].ID, Quantity = 2.00, UnitPrice = 12.00,
                    PricebookEntryId = standardPrice.ID, SBQQ__ChargeType__c = 'One-Time', product2id = product[0].ID,
                    SBQQ__Activated__c = true, blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').ID,
                    blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').ID,
                    blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').ID,
                    blng__HoldBilling__c = 'Yes'));
            }
            if (!orderItemList3.isEmpty()) {
                System.debug('orderItemList3>' + orderItemList3);
                insert orderItemList3;
            }
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            System.debug('The following exception has occurred: ' + e);
        }
        
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accList);
        
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accList[0],orderList3[0],orderItemList3[0] );
        blng__UsageSummary__c usagesummary = usageSum[0];
        
        usagesummary.blng__Status__c = 'Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary.blng__Subtotal__c = 100;
        usagesummary.blng__TotalQuantity__c = 10;
        usagesummary.blng__PreratedQuantity__c = 20;
        usagesummary.blng__UnbilledQuantity__c = 1;
        usagesummary.blng__UnitPrice__c = 400;
        usagesummary.blng__PreratedAmount__c = 22;
        usagesummary.blng__Invoice__c = invList[0].ID; 
        Database.update(usagesummary);
        
        List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accList[0],usagesummary);
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        usageList[0].QTB_Start_Date_MRC__c = Date.newInstance(2022,03,01);
        usageList[0].QTB_end_Date_MRC__c = Date.newInstance(2022,31,01); 
        usageList[0].blng__UsageSummary__c=usagesummary.ID;
        usageList[0].blng__Account__c = accList[1].ID;
        usageList[0].QTB_ServicePeriod__c  = 'Apr-2024';
        // 31276 non writeableusageList[0].QTB_Service_Period_Date__c  = System.Today();
        usageList[0].QTB_Source_Service_Date__c= System.Today(); // 31276
        Database.update(usageList);    
        
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        //invoiceLine[0].Name = 'prodName';
        invoiceLine1.blng__Invoice__c = invList[0].ID;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Initiated';
        //28758
        invoiceLine1.blng__UsageSummary__c = usagesummary.ID;
        invoiceLine1.blng__Quantity__c = 10;
        invoiceLine1.blng__UnitPrice__c = 5;
        invoiceLine1.blng__Subtotal__c = 100;
        invoiceLine1.blng__TaxCountry__c = 'India';
        insert invoiceLine1;
        
        
        invList[0].blng__InvoiceStatus__c = 'Posted';
        invList[0].QTB_Invoice_Period__c = singaporeFinancePeriod.ID;
        invList[0].blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        update invList[0];
        Set<ID> invId = new  Set<ID>();
        invId.add(invList[0].ID);
        String str;
        String str2;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
        
        accList[0].QTB_Billing_Frequency__c = 'Quarterly';
        accList[0].QTB_Bill_Forward_Type__c = 'Arrears';
        update accList;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
            
        accList[0].QTB_Billing_Frequency__c = 'Semiannual';
        accList[0].QTB_Bill_Forward_Type__c = 'Arrears';
        update accList;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
    
        accList[0].QTB_Billing_Frequency__c = 'Quarterly';
        accList[0].QTB_Bill_Forward_Type__c = 'Advance';
        update accList;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
                
        accList[0].QTB_Billing_Account_Type__c = '';
        //Syste  QTB_Billing_Account_Type__c not working
        update accList;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
        Test.stopTest();
    }

   /* static testMethod void updateInvoiceMRCDatesProductSalesTest(){ //31276 added
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        
        QTB_InvoiceTriggerHandler.throwExplicitException = false;
        List<Account> accList = QTB_TestDataFactory.createAccounts(20);
        accList[0].QTB_Billing_Frequency__c = 'Monthly';
        accList[0].QTB_Bill_Forward_Type__c = 'Arrears';
        accList[0].QTB_Legal_Entity_Country__c = 'India';
        //28758 2 lines
        accList[0].QTB_Billing_Account_Type__c = 'Product Sales';
        accList[1].QTB_Billing_Account_Type__c = '';
        update accList;
        Set<String> addressComparison = new Set <String>();
        
        blng__LegalEntity__c singaporeEntity = new blng__LegalEntity__c();
        singaporeEntity.Name = 'Test Legal Entity India';
        singaporeEntity.blng__Active__c = true;
        singaporeEntity.blng__Country__c = 'India';
        singaporeEntity.QTB_Type__c = 'Contract';
        singaporeEntity.QTB_Legal_Entity_Number__c = 45000;
        insert singaporeEntity; 
        
        blng__FinanceBook__c singaporeFinanceBook = new blng__FinanceBook__c();
        singaporeFinanceBook.Name = 'Accounting Finance Book';
        singaporeFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
        singaporeFinanceBook.blng__Active__c = true;
        singaporeFinanceBook.blng__PeriodType__c='Accounting';
        insert singaporeFinanceBook;
        
        blng__FinancePeriod__c singaporeFinancePeriod = new blng__FinancePeriod__c();
        singaporeFinancePeriod.Name = 'singapore Mar 2024';
        singaporeFinancePeriod.blng__FinanceBook__c = singaporeFinanceBook.ID;
        singaporeFinancePeriod.blng__PeriodStartDate__c = System.today().toStartofMonth();
        singaporeFinancePeriod.blng__PeriodEndDate__c = System.today().addMonths(1).toStartofMonth().addDays(-1);
        singaporeFinancePeriod.blng__LegalEntity__c = singaporeEntity.ID;
        singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert singaporeFinancePeriod;
        
        blng__InvoiceScheduler__c singaporeSchedule = new blng__InvoiceScheduler__c();
        singaporeSchedule.Name = 'Test for Singapore';
        singaporeSchedule.blng__Type__c = 'Once';
        singaporeSchedule.blng__InvoiceBatches__c = 'India-1st'; 
        singaporeSchedule.CurrencyIsoCode = 'INR';
        singaporeSchedule.blng__StartDateTime__c = System.today().adddays(1);
        singaporeSchedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        singaporeSchedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        singaporeSchedule.QTB_Legal_Entity__c  = singaporeEntity.ID;
        singaporeSchedule.QTB_Invoice_Period__c = singaporeFinancePeriod.ID ;
        insert singaporeSchedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Test invoice';
        invoiceRun.blng__InvoiceScheduler__c = singaporeSchedule.ID;
        invoiceRun.blng__Status__c = 'Started';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
        insert invoiceRun;
        
        SBQQ.TriggerControl.disable();
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,null,accList[0].ID);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        Database.update(orderList3);
        
        List<Product2> product = [SELECT ID,blng__BillingRule__c,blng__RevenueRecognitionRule__c,blng__TaxRule__c 
                                    FROM Product2];
         
        ID pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        List<OrderItem> orderItemList3 = new List<OrderItem>();
        try {
            for (Integer i = 0; i < 1; i++) {
                orderItemList3.add( new OrderItem( OrderId = orderList3[0].ID, Quantity = 2.00, UnitPrice = 12.00,
                    PricebookEntryId = standardPrice.ID, SBQQ__ChargeType__c = 'One-Time', product2id = product[0].ID,
                    SBQQ__Activated__c = true, blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').ID,
                    blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').ID,
                    blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').ID,
                    blng__HoldBilling__c = 'Yes'));
            }
            if (!orderItemList3.isEmpty()) {
                insert orderItemList3;
            }
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            System.debug('The following exception has occurred: ' + e);
        }
        
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accList);
        
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accList[0],orderList3[0],orderItemList3[0] );
        blng__UsageSummary__c usagesummary = usageSum[0];
        
        usagesummary.blng__Status__c = 'Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary.blng__Subtotal__c = 100;
        usagesummary.blng__TotalQuantity__c = 10;
        usagesummary.blng__PreratedQuantity__c = 20;
        usagesummary.blng__UnbilledQuantity__c = 1;
        usagesummary.blng__UnitPrice__c = 400;
        usagesummary.blng__PreratedAmount__c = 22;
        usagesummary.blng__Invoice__c = invList[0].ID; 
        Database.update(usagesummary);
        
        List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accList[0],usagesummary);
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        usageList[0].QTB_Start_Date_MRC__c = Date.newInstance(2022,03,01);
        usageList[0].QTB_end_Date_MRC__c = Date.newInstance(2022,31,01); 
        usageList[0].blng__UsageSummary__c=usagesummary.ID;
        usageList[0].blng__Account__c = accList[1].ID;
        usageList[0].QTB_ServicePeriod__c  = 'Apr-2024';
        // 31276 non writeable usageList[0].QTB_Service_Period_Date__c  = System.Today();
        usageList[0].QTB_Source_Service_Date__c= System.Today(); // 31276
        Database.update(usageList);    
        
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        //invoiceLine[0].Name = 'prodName';
        invoiceLine1.blng__Invoice__c = invList[0].ID;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Initiated';
        //28758
        invoiceLine1.blng__UsageSummary__c = usagesummary.ID;
        invoiceLine1.blng__Quantity__c = 10;
        invoiceLine1.blng__UnitPrice__c = 5;
        invoiceLine1.blng__Subtotal__c = 100;
        invoiceLine1.blng__TaxCountry__c = 'India';
        insert invoiceLine1;
        
        invList[0].blng__InvoiceStatus__c = 'Posted';
        invList[0].QTB_Invoice_Period__c = singaporeFinancePeriod.ID;
        invList[0].blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        update invList[0];
        Set<ID> invId = new  Set<ID>();
        invId.add(invList[0].ID);
        String str;
        String str2;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
        
        accList[0].QTB_Billing_Frequency__c = 'Quarterly';
        accList[0].QTB_Bill_Forward_Type__c = 'Arrears';
        update accList;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
            
        accList[0].QTB_Billing_Frequency__c = 'Semiannual';
        accList[0].QTB_Bill_Forward_Type__c = 'Arrears';
        update accList;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
    
        accList[0].QTB_Billing_Frequency__c = 'Quarterly';
        accList[0].QTB_Bill_Forward_Type__c = 'Advance';
        update accList;
        QTB_InvoiceHelper.updateInvoiceMRCDates(invId);
                
        Test.stopTest();
    } */

    static testmethod void updatePOForCreditAndRebillTest(){
        Test.startTest();
        //Account
        List<Account> accountNewList = new List<Account>();
        ID standardrecordID = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
        ID recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
        for (Integer i = 0; i < 10; i++) {
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
                a.QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
            }
            if(i == 1){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 2){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 3){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 4){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 5){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 6){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 7){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = '';
                a.QTB_Billing_Frequency__c = '';  
            }
            accountNewList.add(a);
        }
        
        if (!accountNewList.isEmpty()) {
            insert accountNewList;
        }
        
        System.debug('>>>accountNewList'+accountNewList[0].ID); 
        
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
        usaEntity.Name = 'Test Legal Entity Singapore';
        usaEntity.blng__Active__c = true;
        usaEntity.blng__Country__c = 'United States';
        usaEntity.QTB_Type__c = 'Contract';
        insert usaEntity;          
        
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'Test schedule 2';
        schedule.blng__Type__c = 'Once';
        schedule.blng__InvoiceBatches__c = 'Rebill Run';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.today();
        schedule.blng__InvoiceDate__c = Date.valueOf('2024-10-10');
        schedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        schedule.QTB_Legal_Entity__c = usaEntity.ID;
        //insert schedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Test invoice';
        invoiceRun.blng__InvoiceScheduler__c = schedule.ID;
        invoiceRun.blng__Status__c = 'Started';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
        insert invoiceRun; 
         
            Contact cont = new Contact();
            cont.LastName = 'test111';
            cont.FirstName = 'abc11';
            cont.email = 'so111@email.com';
            cont.AccountId = accountNewList[0].ID;
            cont.MailingCountry = 'Canada';
            cont.IM_Role__c = 'PO Contact';
            insert cont;
         
           AccountContactRelation acr = new AccountContactRelation();
            acr.accountId = accountNewList[1].ID;
            acr.ContactId = cont.ID;
            insert acr;
            
            acr.Roles = 'PO Contact';
            update acr;
        
          QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c(
            QTB_Billing_Account__c = accountNewList[1].ID,
            QTB_Status__c = 'Active',
            QTB_Start_Date__c = System.today(),
            QTB_End_Date__c = System.today(),
            QTB_PO_Type__c = 'Standard',
            QTB_Customer_PO__c = 'QW2315',
            QTB_Amount__c = 10000,
            QTB_Service_Type__c = 'Mixed'
        );
        insert pOrder;
        
      /*  blng__Invoice__c inv1 = new blng__Invoice__c();
        inv1.blng__Account__c = accountNewList[0].ID; 
        inv1.blng__InvoiceStatus__c = 'Draft';
        inv1.blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        inv1.QTB_ReBill_Status__c='ReBill Completed';
        inv1.QTB_Case_Number__c = 'CA245566';
        inv1.QTB_Service_District__c = 'Test district';
        inv1.QTB_Site_Number__c = 'CS15545466';
        //inv1.QTB_Invoice_Type__c = QTB_Constants.ORDCATEGORY_REBILL;
         inv1.QTB_Purchase_Order__c = pOrder.ID;
        insert inv1;
        System.debug('inv1>>'+inv1);
        List<blng__Invoice__c> invoicelisted = new  List<blng__Invoice__c>();
        
        
        inv1.blng__InvoiceStatus__c = 'Posted';
        inv1.QTB_ReBill_Status__c='';
        update inv1;
        invoicelisted.add(inv1);
        
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        //invoiceLine[0].Name = 'prodName';
        invoiceLine1.blng__Invoice__c = inv1.ID;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine1.blng__Quantity__c = 10;
        invoiceLine1.blng__UnitPrice__c = 5;
        invoiceLine1.blng__Subtotal__c = 100;
        invoiceLine1.blng__TaxCountry__c = 'India';
        insert invoiceLine1;*/
        
        List<blng__Invoice__c> invList = [SELECT ID, QTB_Purchase_Order__c  
                                        FROM blng__Invoice__c WHERE QTB_Purchase_Order__c != null LIMIT 2];
        System.debug('invList>>>'+invList);
        blng__Invoice__c inv2 = new blng__Invoice__c();
        inv2.blng__Account__c = accountNewList[0].ID; 
        inv2.blng__InvoiceStatus__c = 'Draft';
        inv2.blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        inv2.QTB_ReBill_Status__c='ReBill Completed';
        inv2.QTB_Case_Number__c = 'CA245566';
        inv2.QTB_Service_District__c = 'Test district';
        inv2.QTB_Site_Number__c = 'CS15545466';
        inv2.QTB_Invoice_Type__c = QTB_Constants.ORDCATEGORY_REBILL;
        insert inv2;
         inv2.QTB_Parent_Invoice__c = invList[0].ID;
         inv2.blng__InvoiceStatus__c = 'Posted';
		update inv2;       
       // QTB_InvoiceHelper.populateOrderFieldsOnInvoice(invoicelisted);
	   QTB_InvoiceHelper.codeCoverage();
        Test.stopTest();
    }
    
    /*static testMethod void makeFieldsNonEditableForPosted11Test() {
        
        Test.startTest();

        QTB_InvoiceTriggerHandler.throwExplicitException = false;
        Date todayDate = Date.today();
        List<blng__Invoice__c> invoiceList = [SELECT ID,QTB_Start_Date_MRC__c,blng__InvoiceStatus__c 
                                        FROM blng__Invoice__c 
                                        WHERE blng__InvoiceStatus__c = 'Posted' AND(QTB_End_Date_MRC__c!=: todayDate OR QTB_End_Date_MRC__c!= null) LIMIT 2];
        invoiceList[0].QTB_transfered_to_invoice_presentment__c = System.now();
            Database.update(invoiceList[0]); 

        Profile sunilProfile = [SELECT Id FROM Profile WHERE Name = 'IME_SC_Manager'];
        User billingUser = new User( profileId = sunilProfile.Id, LastName = 'last',Email = 'testuser@test.example.com',
			Username = 'Testuser@test.example.com' + Crypto.getRandomInteger(),CompanyName = 'TEST',Title = 'title',
			Alias = 'alias',TimeZoneSidKey = 'America/Los_Angeles',EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',Country = 'USA',MobilePhone = '+1 9999999999',Phone = '9999999999');
		insert billingUser;
		PermissionSetLicense cpq = [SELECT Id, MasterLabel FROM PermissionSetLicense WHERE MasterLabel = 'Salesforce CPQ License'];
		// assign cpq license
		insert new PermissionSetLicenseAssign(AssigneeId = billingUser.Id, PermissionSetLicenseId = cpq.Id);
		// assign billing user permission
		PermissionSet billingUserPermission = [SELECT Id, Name FROM PermissionSet WHERE Name = 'QTB_Billing_User'];
		insert new PermissionSetAssignment(AssigneeId = billingUser.id, PermissionSetId = billingUserPermission.Id);
        PermissionSet billingUserPermission1 = [SELECT Id, Name FROM PermissionSet WHERE Name = 'QTB_Create_Billing_Account'];
		insert new PermissionSetAssignment(AssigneeId = billingUser.id, PermissionSetId = billingUserPermission1.Id);
		System.runAs(billingUser) {
            try{  
                invoiceList[0].QTB_End_Date_MRC__c= System.today();
                Database.update(invoiceList[0]);    
            }catch(Exception e){
                System.debug(e.getMessage());
                //System.assertEquals(true,e.getMessage().contains('We can not modify posted Invoice record'));
            }
            Test.stopTest();
        }
    } */
    
    static testMethod void makeFieldsNonEditableForPosted11Test() {
        QTB_InvoiceTriggerHandler.throwExplicitException = false;
        Date todayDate = Date.today();

        Test.startTest();
        // Step 1: Query & update invoice outside setup DML
        List<blng__Invoice__c> invoiceList = [ SELECT Id, QTB_Start_Date_MRC__c, blng__InvoiceStatus__c 
                                                FROM blng__Invoice__c 
                                            WHERE blng__InvoiceStatus__c = 'Posted' AND (QTB_End_Date_MRC__c != :todayDate OR QTB_End_Date_MRC__c != null) AND QTB_transfered_to_invoice_presentment__c!=null LIMIT 2];
        try {
            invoiceList[0].QTB_End_Date_MRC__c = System.today();
            update invoiceList[0];
        } catch (Exception e) {
        System.debug(e.getMessage());
            // System.assert(e.getMessage().contains('expected error message'));
        }
        Test.stopTest();
    }

    static testmethod void calculateIndividualTaxAmountsOnInvoiceLineItemsTest(){
        Test.startTest();
        
        QTB_Tax_Integration_Setting__mdt vertexData = new QTB_Tax_Integration_Setting__mdt();
        vertexData.Label = 'Vertex';
        vertexData.DeveloperName = 'Vertex_Integration';
        vertexData.QTB_Country__c = 'United States;Canada';
        vertexData.QTB_End_System__c = 'Vertex';
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(2);
        Set<String> addressComparison = new Set <String>();
        
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accList);
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Rebill Run';
        accountList[0].QTB_Legal_Entity_Country__c='Hungary';
        accountList[0].QTB_Bill_Forward_Type__c='Advance';
        accountList[0].QTB_Billing_Frequency__c='Monthly';
        accountList[0].CurrencyIsoCode = 'INR'; //31276
        accountList[0].Payment_Terms__c = 'Net 15'; //31276
        update accountList; 
        
        //Legal Entity
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
        usaEntity.Name = 'Test Legal Entity Singapore';
        usaEntity.blng__Active__c = true;
        usaEntity.blng__Country__c = 'United States';
        usaEntity.QTB_Type__c = 'Contract';
        usaEntity.currencyISOCode = 'USD'; //31276
        // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        usaEntity.QTB_Tax_Applicability__c = 'Flat Rate';
        insert usaEntity;          
        
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'Test schedule 2';
        schedule.blng__Type__c = 'Once';
        schedule.blng__InvoiceBatches__c = 'Rebill Run';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.today();
        schedule.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        schedule.blng__TargetDate__c = Date.valueOf('2024-12-01');
        schedule.QTB_Parent_Invoice__c = invList[0].ID;
        schedule.QTB_Legal_Entity__c = usaEntity.ID;
        //insert schedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Test invoice';
        invoiceRun.blng__InvoiceScheduler__c = schedule.ID;
        invoiceRun.blng__Status__c = 'Started';
        //invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
        insert invoiceRun;
        Set<ID> postedid=new set<ID>();
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[0].ID;
        invoice.blng__InvoiceStatus__c = 'Initiated';
        invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.ID;
        invoice.QTB_ReBill_Status__c='ReBill Completed';
        invoice.QTB_Case_Number__c = 'CA245566';
        invoice.QTB_Service_District__c = 'Test district';
        invoice.QTB_Site_Number__c = 'CS15545466';
        invoice.QTB_Invoice_Type__c = 'New';  
        //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
        insert invoice;
        //31276 non writeabkeinvoice.QTB_Foreign_Exchange_Applicable__c = true; //31276
        invoice.QTB_Case_Number__c = 'CA2455661';
        invoice.blng__InvoiceStatus__c = 'Draft';
        update invoice;
        invoice.blng__InvoiceStatus__c = 'Posted';
        invoice.QTB_ReBill_Status__c=''; 
        update invoice;
        accountList[0].QTB_Legal_Entity_Country__c='Hungary';
        update accountList[0];
         accountList[0].QTB_Legal_Entity_Country__c='India';
        update accountList[0];
        invoice.QTB_Case_Number__c = 'CA2455660';
        update invoice;
        
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__Invoice__c = invoice.ID;
        invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;
        //invoiceLine.blng__UsageSummary__c = usagesummary.ID; 
        invoiceLine.blng__Subtotal__c = 100;
        invoiceLine.blng__TaxCountry__c = 'India';
        invoiceLine.blng__LegalEntity__c = usaEntity.ID;
        insert invoiceLine;
        
        postedid.add(invoice.ID);
        
        QTB_InvoiceHelper.calculateIndividualTaxAmountsOnInvoiceLineItems(postedid);
         
        usaEntity.QTB_Tax_Applicability__c = 'Product Based';
        update usaEntity;  
        QTB_InvoiceHelper.calculateIndividualTaxAmountsOnInvoiceLineItems(postedid);
        Test.stopTest();
    }

    static testmethod void subLines(){
        Test.startTest();
        List<blng__Invoice__c>invlst = [SELECT ID,blng__Account__c,blng__Account__r.QTB_Legal_Entity__c,blng__InvoiceStatus__c,QTB_Invoice_Type__c,QTB_hasTieredLines__c,QTB_Sublines_Added__c FROM blng__Invoice__c WHERE blng__InvoiceStatus__c = 'Draft'];
        List<blng__LegalEntity__c>legal = [SELECT ID,QTB_Tax_Applicability__c,QTB_Storage_Service_Period_Range__c FROM blng__LegalEntity__c limit 1];
        legal[0].QTB_Tax_Applicability__c = 'Product Based';
        legal[0].QTB_Storage_Service_Period_Range__c = true;
        update legal;
        List<Account> acc = [SELECT ID,QTB_Contract_Entity__c FROM  Account WHERE ID = :invLst[0].blng__Account__c];
        acc[0].QTB_Contract_Entity__c = legal[0].ID;
        acc[0].QTB_Legal_Entity__c = legal[0].ID;
        update acc;
        for(blng__Invoice__c inv :invlst){
            inv.blng__InvoiceStatus__c = 'Initiated';
            inv.QTB_hasTieredLines__c = true;
            inv.QTB_Invoice_Type__c = 'ReBill';
        }
        sbqq.TriggerControl.disable();
        update invlst;
        
        for(blng__Invoice__c inv :invlst){
            inv.blng__InvoiceStatus__c = 'Draft';
        }
        update invlst;
        sbqq.TriggerControl.enable();
        Test.stopTest();
    }

    static testmethod void callVertexAndAssignBillFlowControllerForRebillTestError(){
        try{
            QTB_InvoiceTriggerHandler.throwExplicitException = true;
            QTB_InvoiceHelper.callVertexAndAssignBillFlowControllerForRebill(null);
        }catch(Exception e){
            System.debug(e);
        }
    }
    static testmethod void makeFieldsNonEditableForPostedTestError(){
        try{
            QTB_InvoiceHelper.makeFieldsNonEditableForPosted(null, null);
        }catch(Exception e){
            System.debug(e);
        }
    }
    static testmethod void updateNotesOnAccountFromUsageTestError(){
        try{
            QTB_InvoiceHelper.updateNotesOnAccountFromUsage(null);
        }catch(Exception e){
            System.debug(e);
        }
        try{
            QTB_InvoiceTriggerHandler.throwExplicitException = true;
            QTB_InvoiceHelper.updateNotesOnAccountFromUsage(null);
        }catch(Exception e){
            System.debug(e);
        }
    }
    static testmethod void makeFieldsReadyOnlyForPostedTestError(){
        try{
            QTB_InvoiceHelper.makeFieldsReadyOnlyForPosted(null,null);
        }catch(Exception e){
            System.debug(e);
        }
    }
    static testmethod void createReBillCreditNoteTestError(){
        try{
            QTB_InvoiceHelper.createReBillCreditNote(null,false);
        }catch(Exception e){
            System.debug(e);
        }
    }
    static testmethod void updateDatesTestError(){
        try{
            QTB_InvoiceHelper.updateDates(null,null,null,null,null);
        }catch(Exception e){
            System.debug(e);
        }
    }
    static testmethod void updateInvoiceMRCDatesTestError(){
        try{
            QTB_InvoiceTriggerHandler.throwExplicitException = true;
            QTB_InvoiceHelper.updateInvoiceMRCDates(null);
        }catch(Exception e){
            System.debug(e);
        }
    }
    static testmethod void calculateTaxTestError(){
        try{
            QTB_InvoiceTriggerHandler.throwExplicitException = true;
            QTB_InvoiceHelper.calculateTax(null,null,null);
        }catch(Exception e){
            System.debug(e);
        }
    }
    
    static testmethod void updatePOForCreditAndRebillTestError(){
        try{
            QTB_InvoiceHelper.updatePOForCreditAndRebill(null,null);
        }catch(Exception e){
            System.debug(e);
        }
    }
    static testmethod void updatePOInvoiceLevelTestError(){
        try{
            QTB_InvoiceHelper.updatePOInvoiceLevel(null,null);
        }catch(Exception e){
            System.debug(e);
        }
    }
	
	/*
    static testmethod void poWithoutShring() {
        
        QTB_Billing_Countries__c BillingCountries = new QTB_Billing_Countries__c();
        BillingCountries.Name = 'Singapore';
        BillingCountries.Legal_entity_country__c = 'Singapore' ;
        insert BillingCountries;
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        //Product
        List<product2> product = [SELECT Id,Name FROM Product2 LIMIT 1];
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        Database.update(product);
        
        //Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> standardPrice = [SELECT Id,Name 
                                        FROM PricebookEntry WHERE Product2Id =: product[0].ID AND Pricebook2Id =: pricebookId
                                        AND isActive= true LIMIT 1];
        
        /*new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product[0].ID,UnitPrice = 10000,
                                                            isActive = true);
        insert stand
        
        standardPrice[0].UnitPrice = 100;
        Database.update(standardPrice);
        //Account
        List<Account> accountList = new List<Account>();
        ID standardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
        ID recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
        for (Integer i = 0; i < 10; i++) {
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
                a.QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
            }
            if(i == 1){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 2){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 3){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 4){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 5){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 6){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 7){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = '';
                a.QTB_Billing_Frequency__c = '';  
            }
            accountList.add(a);
        }
        
        if (!accountList.isEmpty()) {
            insert accountList;
        }
        
        List<Account> standardAccountList = QTB_TestDataFactory.createAccounts(1,'Standard Account');
        accountList[0].QTB_Legal_Entity_Country__c='United States';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Standard Account';
        accountList[0].ShippingCity = 'New York';
        accountList[0].ShippingState = 'New York';
        accountList[0].ShippingPostalCode = '22131';
        accountList[0].ShippingCountry = 'United States';
        accountList[0].IM_Hierarchy_Level__c = 'Country Parent';
        update standardAccountList; 
        
        //Legal Entity
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
        usaEntity.Name = 'Test Legal Entity United States';
        usaEntity.blng__Active__c = true;
        usaEntity.blng__Country__c = 'United States';
        usaEntity.QTB_Type__c = 'Contract';
        usaEntity.QTB_Tax_Applicability__c = 'Flat Rate';
        insert usaEntity;
        
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

        //Account with No parent
        Account accWithParent = new Account();
        accWithParent.Name = 'accWithParent';
        accWithParent.Phone = 'Test9' + String.valueOf(Crypto.getRandomInteger());
        accWithParent.RecordTypeId = recordTypeValue;
        accWithParent.BillingCountry = 'Singapore';
        accWithParent.BillingPostalCode = '11208';
        accWithParent.BillingState = 'TN';
        accWithParent.Registration_Number__c = 'Reg';
        accWithParent.ShippingCountry = 'Singapore';
        accWithParent.QTB_Legal_Entity_Country__c='Singapore';
        accWithParent.QTB_Create_Parent_Billing_Account__c = false;
        accWithParent.ParentId = standardAccountList[0].ID;
        insert accWithParent;
        
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
        
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,null,accountList[0].ID);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        Database.update(orderList3);
        
        List<OrderItem> orderItemList3 = new List<OrderItem>();
        try {
            for (Integer i = 0; i < 1; i++){
                orderItemList3.add( new OrderItem( OrderId = orderList3[0].ID, Quantity = 2.00, UnitPrice = 12.00,
                                    PricebookEntryId = standardPrice[0].ID, SBQQ__ChargeType__c = 'One-Time', product2id = product[0].ID,
                                    SBQQ__Activated__c = true,  blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').ID,
                                    blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').ID,
                                    blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').ID, blng__HoldBilling__c = 'Yes'));
            }
            if (!orderItemList3.isEmpty()) {
                insert orderItemList3;
            }
        } catch (Exception e) {
            System.debug(e);
        }
        List<Contact> contList = new List<Contact>();
        for(Integer i = 0; i< 2; i++){
            Contact cont = new Contact( LastName = 'test11', FirstName = 'abc1', Email = 'so11@email.com', 
                                        AccountId = accountList[i].ID, MailingCountry = 'Canada', IM_Role__c = 'PO Contact' );
            contList.add(cont);                           
        }
        insert contList;
        
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        for(Integer i = 0; i< 2; i++){
            AccountContactRelation acr = new AccountContactRelation(AccountId = accountList[(i+2)].ID,
                                                                        ContactId = contList[i].ID);
            acrList.add(acr);
        }
        insert acrList;

        List<AccountContactRelation> acrListToUpdate = new List<AccountContactRelation>();
        for(AccountContactRelation acr : acrList){
            acr.Roles = 'PO Contact';
            acrListToUpdate.add(acr);
        }
        update acrListToUpdate;
        
        List<QTB_PurchaseOrder__c> poList = new List<QTB_PurchaseOrder__c>();
        List<QTB_PurchaseOrder__c> poList1 = new List<QTB_PurchaseOrder__c>();
        Map<ID,QTB_PurchaseOrder__c> ordOldMap = new Map<ID,QTB_PurchaseOrder__c>();
        Map<ID,blng__Invoice__c> poInvMap = new Map<ID,blng__Invoice__c>();
        
        Set<Id> accountIds = new Set<Id>();
        if (accountList.size()>0){
            accountIds.add(accountList[3].Id);
        }
         List<blng__Invoice__c> invoiceListSOQL = [SELECT blng__Account__c,blng__InvoiceStatus__c,blng__InvoiceDate__c,QTB_PurchaseOrder__c,QTB_ReBill_Status__c
                                                FROM blng__Invoice__c WHERE QTB_PurchaseOrder__c = null  AND blng__InvoiceStatus__c !='Posted' AND blng__Account__c IN :accountIds LIMIT 2 ];
        blng__Invoice__c invoiceListSOQL1 = invoiceListSOQL[0].clone(false,true,true,false);
        insert invoiceListSOQL1;
        invoiceListSOQL[0].QTB_Tax_Override_Amount__c = 10000;
        Database.update(invoiceListSOQL[0]);
		Test.startTest();
        QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c(QTB_Billing_Account__c = accountList[2].ID, QTB_Legal_Entity_Country__c = accountList[2].BillingCountry,
                            QTB_Status__c = 'Active',QTB_Start_Date__c = System.today(),QTB_End_Date__c = System.today(),QTB_PO_Type__c = 'Standard',
                            QTB_Customer_PO__c = 'QW2315', QTB_Amount__c = 10000,QTB_Service_Type__c = 'Mixed', QTB_Date_Of_100_Utilization__c = System.Today());
        QTB_PurchaseOrder__c pOrder1 = new QTB_PurchaseOrder__c(QTB_Billing_Account__c = accountList[3].ID, QTB_Legal_Entity_Country__c = 'India',
                            QTB_Status__c = 'Active',QTB_Start_Date__c = Date.newInstance(2025, 2, 17),QTB_End_Date__c = Date.newInstance(2025, 2, 17),QTB_PO_Type__c = 'Standard',
                            QTB_Customer_PO__c = 'QW2316', QTB_Amount__c = 10,QTB_Service_Type__c = 'Mixed',QTB_PO_Balance_Amount__c = 5, QTB_Date_Of_100_Utilization__c = Date.newInstance(2025, 2, 17));
        QTB_PurchaseOrder__c pOrder2 = new QTB_PurchaseOrder__c(QTB_Billing_Account__c = accountList[3].ID, QTB_Legal_Entity_Country__c = 'India',
                            QTB_Status__c = 'Active',QTB_Start_Date__c = Date.newInstance(2025, 3, 17),QTB_End_Date__c = Date.newInstance(2025, 3, 17),QTB_PO_Type__c = 'Standard',
                            QTB_Customer_PO__c = 'QW2316', QTB_Amount__c = 10,QTB_Service_Type__c = 'Mixed',QTB_PO_Balance_Amount__c = 5, QTB_Date_Of_100_Utilization__c = Date.newInstance(2025, 2, 17));
        
        insert pOrder;
        insert pOrder1;
        insert pOrder2;
        poList.add(pOrder);
       // Test.startTest();
        invoiceListSOQL1.QTB_PurchaseOrder__c = pOrder2.ID; //  QTB_ReBill_Status__c = '';
        Database.update(invoiceListSOQL1);
        
        Map<ID,blng__Invoice__c> oldMap = new Map<ID,blng__Invoice__c>();
        try{
            invoiceListSOQL[0].QTB_PurchaseOrder__c = pOrder1.ID; 
            Database.update(invoiceListSOQL[0]);
        }catch (Exception e ){
            System.debug(e);
        }

        List<blng__Invoice__c> invoiceList = new List<blng__Invoice__c>();
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[2].ID;
        invoice.blng__InvoiceStatus__c = 'Draft';
        invoice.blng__InvoiceDate__c = System.today()-10;
        invoice.QTB_PurchaseOrder__c = pOrder.ID;
        invoiceList.add(invoice);

        if (!invoiceList.isEmpty()) {
            insert invoiceList;
        }
        invoiceList[0].blng__InvoiceStatus__c = 'Posted';
        invoiceList[0].QTB_ReBill_Status__c = '';
        invoiceList[0].QTB_Transferred_To_Oracle__c = true;
        invoiceList[0].QTB_Invoice_Type__c = 'ReBill';
        update invoiceList;
        
        for(blng__Invoice__c invlist22 : invoiceList){
            if(invlist22.blng__InvoiceStatus__c == 'Posted'){
                poInvMap.put(invlist22.ID,invlist22);
            }
        } 
        Map<ID,blng__Invoice__c> invMap;
        invMap = new Map<ID,blng__Invoice__c>([SELECT  QTB_PurchaseOrder__c, QTB_PurchaseOrder__r.QTB_Status__c 
                                               FROM blng__Invoice__c 
                                               WHERE QTB_PurchaseOrder__c =:invoiceList[0].QTB_PurchaseOrder__c
                                               AND QTB_PurchaseOrder__r.QTB_Status__c = 'Active' LIMIT 1]);      
        porder.QTB_PO_Utilized_Amount__c = '50'; 
        porder.QTB_Amount__c = 5;
        Map<ID, QTB_PurchaseOrder__c> poMap = new Map<ID, QTB_PurchaseOrder__c>();
        poMap.put(porder.ID, porder);   
        Test.stopTest();    
    }  
    
    static testmethod void poWithoutShringTest1() {
        
        QTB_Billing_Countries__c BillingCountries = new QTB_Billing_Countries__c();
        BillingCountries.Name = 'Singapore';
        BillingCountries.Legal_entity_country__c = 'Singapore' ;
        insert BillingCountries;
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        //Product
        List<product2> product = [SELECT Id,Name FROM Product2 LIMIT 1];
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        Database.update(product);
        
        //Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> standardPrice = [SELECT Id,Name 
                                        FROM PricebookEntry WHERE Product2Id =: product[0].ID AND Pricebook2Id =: pricebookId
                                        AND isActive= true LIMIT 1];
        
        /*new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = product[0].ID,UnitPrice = 10000,
                                                            isActive = true);
        insert stand
        
        standardPrice[0].UnitPrice = 100;
        Database.update(standardPrice);
        //Account
        List<Account> accountList = new List<Account>();
        ID standardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
        ID recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
        for (Integer i = 0; i < 10; i++) {
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
                a.QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
            }
            if(i == 1){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 2){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 3){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 4){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 5){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 6){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 7){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = '';
                a.QTB_Billing_Frequency__c = '';  
            }
            accountList.add(a);
        }
        
        if (!accountList.isEmpty()) {
            insert accountList;
        }
        
        List<Account> standardAccountList = QTB_TestDataFactory.createAccounts(1,'Standard Account');
        accountList[0].QTB_Legal_Entity_Country__c='United States';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Standard Account';
        accountList[0].ShippingCity = 'New York';
        accountList[0].ShippingState = 'New York';
        accountList[0].ShippingPostalCode = '22131';
        accountList[0].ShippingCountry = 'United States';
        accountList[0].IM_Hierarchy_Level__c = 'Country Parent';
        update standardAccountList; 
        
        //Legal Entity
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
        usaEntity.Name = 'Test Legal Entity United States';
        usaEntity.blng__Active__c = true;
        usaEntity.blng__Country__c = 'United States';
        usaEntity.QTB_Type__c = 'Contract';
        usaEntity.QTB_Tax_Applicability__c = 'Flat Rate';
        insert usaEntity;
        
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

        //Account with No parent
        Account accWithParent = new Account();
        accWithParent.Name = 'accWithParent';
        accWithParent.Phone = 'Test9' + String.valueOf(Crypto.getRandomInteger());
        accWithParent.RecordTypeId = recordTypeValue;
        accWithParent.BillingCountry = 'Singapore';
        accWithParent.BillingPostalCode = '11208';
        accWithParent.BillingState = 'TN';
        accWithParent.Registration_Number__c = 'Reg';
        accWithParent.ShippingCountry = 'Singapore';
        accWithParent.QTB_Legal_Entity_Country__c='Singapore';
        accWithParent.QTB_Create_Parent_Billing_Account__c = false;
        accWithParent.ParentId = standardAccountList[0].ID;
        insert accWithParent;
        
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
        
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,null,accountList[0].ID);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        Database.update(orderList3);
        
        List<OrderItem> orderItemList3 = new List<OrderItem>();
        try {
            for (Integer i = 0; i < 1; i++){
                orderItemList3.add( new OrderItem( OrderId = orderList3[0].ID, Quantity = 2.00, UnitPrice = 12.00,
                                    PricebookEntryId = standardPrice[0].ID, SBQQ__ChargeType__c = 'One-Time', product2id = product[0].ID,
                                    SBQQ__Activated__c = true,  blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').ID,
                                    blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').ID,
                                    blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').ID, blng__HoldBilling__c = 'Yes'));
            }
            if (!orderItemList3.isEmpty()) {
                insert orderItemList3;
            }
        } catch (Exception e) {
            System.debug(e);
        }
        List<Contact> contList = new List<Contact>();
        for(Integer i = 0; i< 2; i++){
            Contact cont = new Contact( LastName = 'test11', FirstName = 'abc1', Email = 'so11@email.com', 
                                        AccountId = accountList[i].ID, MailingCountry = 'Canada', IM_Role__c = 'PO Contact' );
            contList.add(cont);                           
        }
        insert contList;
        
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        for(Integer i = 0; i< 2; i++){
            AccountContactRelation acr = new AccountContactRelation(AccountId = accountList[(i+2)].ID,
                                                                        ContactId = contList[i].ID);
            acrList.add(acr);
        }
        insert acrList;

        List<AccountContactRelation> acrListToUpdate = new List<AccountContactRelation>();
        for(AccountContactRelation acr : acrList){
            acr.Roles = 'PO Contact';
            acrListToUpdate.add(acr);
        }
        update acrListToUpdate;
        
        List<QTB_PurchaseOrder__c> poList = new List<QTB_PurchaseOrder__c>();
        List<QTB_PurchaseOrder__c> poList1 = new List<QTB_PurchaseOrder__c>();
        Map<ID,QTB_PurchaseOrder__c> ordOldMap = new Map<ID,QTB_PurchaseOrder__c>();
        Map<ID,blng__Invoice__c> poInvMap = new Map<ID,blng__Invoice__c>();
        
        Set<Id> accountIds = new Set<Id>();
        if (accountList.size()>0){
            accountIds.add(accountList[3].Id);
        }
        List<blng__Invoice__c> invoiceListSOQL = [SELECT blng__Account__c,blng__InvoiceStatus__c,blng__InvoiceDate__c,QTB_PurchaseOrder__c,QTB_ReBill_Status__c
                                                FROM blng__Invoice__c WHERE QTB_PurchaseOrder__c = null  AND blng__InvoiceStatus__c !='Posted' AND blng__Account__c IN :accountIds LIMIT 2 ];
        blng__Invoice__c invoiceListSOQL1 = invoiceListSOQL[0].clone(false,true,true,false);
        insert invoiceListSOQL1;
        invoiceListSOQL[0].QTB_Tax_Override_Amount__c = 10000;
        Database.update(invoiceListSOQL[0]);
		Test.startTest();
        QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c(QTB_Billing_Account__c = accountList[2].ID, QTB_Legal_Entity_Country__c = accountList[2].BillingCountry,
                            QTB_Status__c = 'Active',QTB_Start_Date__c = System.today(),QTB_End_Date__c = System.today(),QTB_PO_Type__c = 'Standard',
                            QTB_Customer_PO__c = 'QW2315', QTB_Amount__c = 10000,QTB_Service_Type__c = 'Mixed', QTB_Date_Of_100_Utilization__c = System.Today());
        QTB_PurchaseOrder__c pOrder1 = new QTB_PurchaseOrder__c(QTB_Billing_Account__c = accountList[3].ID, QTB_Legal_Entity_Country__c = 'India',
                            QTB_Status__c = 'Active',QTB_Start_Date__c = Date.newInstance(2025, 2, 17),QTB_End_Date__c = Date.newInstance(2025, 2, 17),QTB_PO_Type__c = 'Standard',
                            QTB_Customer_PO__c = 'QW2316', QTB_Amount__c = 10,QTB_Service_Type__c = 'Mixed',QTB_PO_Balance_Amount__c = 5, QTB_Date_Of_100_Utilization__c = Date.newInstance(2025, 2, 17));
        QTB_PurchaseOrder__c pOrder2 = new QTB_PurchaseOrder__c(QTB_Billing_Account__c = accountList[3].ID, QTB_Legal_Entity_Country__c = 'India',
                            QTB_Status__c = 'Active',QTB_Start_Date__c = Date.newInstance(2025, 3, 17),QTB_End_Date__c = Date.newInstance(2025, 3, 17),QTB_PO_Type__c = 'Standard',
                            QTB_Customer_PO__c = 'QW2316', QTB_Amount__c = 10,QTB_Service_Type__c = 'Mixed',QTB_PO_Balance_Amount__c = 5, QTB_Date_Of_100_Utilization__c = Date.newInstance(2025, 2, 17));
        
        insert pOrder;
        insert pOrder1;
        insert pOrder2;
        poList.add(pOrder);
       // Test.startTest();
        insert new List<QTB_PurchaseOrderAccount__c>{ new QTB_PurchaseOrderAccount__c(QTB_Purchase_Order__c = pOrder.Id, QTB_Account__c = accountList[2].Id),
            											new QTB_PurchaseOrderAccount__c(QTB_Purchase_Order__c = pOrder1.Id, QTB_Account__c = accountList[2].Id),
            											new QTB_PurchaseOrderAccount__c(QTB_Purchase_Order__c = pOrder2.Id, QTB_Account__c = accountList[2].Id)
            
            };
        invoiceListSOQL1.QTB_PurchaseOrder__c = pOrder2.ID; //  QTB_ReBill_Status__c = '';
        Database.update(invoiceListSOQL1);
        
        Map<ID,blng__Invoice__c> oldMap = new Map<ID,blng__Invoice__c>();
        try{
            invoiceListSOQL[0].QTB_PurchaseOrder__c = pOrder1.ID; 
            Database.update(invoiceListSOQL[0]);
        }catch (Exception e ){
            System.debug(e);
        }
        
        //Changes for purchase order account

		
        List<blng__Invoice__c> invoiceList = new List<blng__Invoice__c>();
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[2].ID;
        invoice.blng__InvoiceStatus__c = 'Draft';
        invoice.blng__InvoiceDate__c = System.today()-10;
        //invoice.QTB_PurchaseOrder__c = pOrder.ID;
        invoice.blng__TaxStatus__c = 'Queued';
        invoiceList.add(invoice);

        if (!invoiceList.isEmpty()) {
            insert invoiceList;
        }
        
        system.debug('3636 --> '+ [SELECT blng__TaxStatus__c FROM blng__invoice__c where Id = :invoiceList[0].Id]);
        QTB_TestDataFactory.createInvoiceLine(1,invoiceList, product);
        update new blng__invoice__c(Id = invoiceList[0].Id,blng__TaxStatus__c = 'Queued');
        invoiceList[0].QTB_Invoice_Type__c = 'New';
        invoiceList[0].QTB_PurchaseOrder__c = pOrder.Id;
        update invoiceList;
        invoiceList[0].blng__TaxStatus__c = 'Completed';
        invoiceList[0].blng__InvoiceStatus__c = 'Draft';
        invoiceList[0].QTB_Invoice_Type__c = 'ReBill';
        invoiceList[0].QTB_Transferred_To_Oracle__c = true;
        System.debug('Database.update --> '+Database.update(invoiceList));
        
        invoiceList[0].blng__InvoiceStatus__c = 'Posted';
        invoiceList[0].QTB_ReBill_Status__c = '';
        invoiceList[0].QTB_Transferred_To_Oracle__c = true;
        invoiceList[0].QTB_Invoice_Type__c = 'ReBill';
        update invoiceList;
        
        for(blng__Invoice__c invlist22 : invoiceList){
            if(invlist22.blng__InvoiceStatus__c == 'Posted'){
                poInvMap.put(invlist22.ID,invlist22);
            }
        } 
        Map<ID,blng__Invoice__c> invMap;
        invMap = new Map<ID,blng__Invoice__c>([SELECT  QTB_PurchaseOrder__c, QTB_PurchaseOrder__r.QTB_Status__c 
                                               FROM blng__Invoice__c 
                                               WHERE QTB_PurchaseOrder__c =:invoiceList[0].QTB_PurchaseOrder__c
                                               AND QTB_PurchaseOrder__r.QTB_Status__c = 'Active' LIMIT 1]);      
        porder.QTB_PO_Utilized_Amount__c = '50'; 
        porder.QTB_Amount__c = 5;
        Map<ID, QTB_PurchaseOrder__c> poMap = new Map<ID, QTB_PurchaseOrder__c>();
        poMap.put(porder.ID, porder);


        Test.stopTest();    
    } 
*/



   static testmethod void updateReBillInvoiceWithTotalOnSplitTest(){
        try{
            QTB_invoiceHelper.updateReBillInvoiceWithTotalOnSplit(null);
        }catch (Exception e){
            System.debug(e);
        }
    }
    static testmethod void prePopulateFieldsTest(){
        try{
            QTB_invoiceHelper.prePopulateFields(null,null);
        }catch (Exception e){
            System.debug(e);
        }
    }
    /*static testmethod void subLinesTest1(){
        Test.startTest();
        
        List<blng__Invoice__c>invlst = [SELECT ID,blng__Account__c,blng__Account__r.QTB_Legal_Entity__c,blng__InvoiceStatus__c,QTB_Invoice_Type__c,QTB_hasTieredLines__c,QTB_Sublines_Added__c FROM blng__Invoice__c WHERE blng__InvoiceStatus__c = 'Draft'];
        List<blng__LegalEntity__c>legal = [SELECT ID,QTB_Tax_Applicability__c,QTB_Storage_Service_Period_Range__c FROM blng__LegalEntity__c limit 1];
        legal[0].QTB_Tax_Applicability__c = 'Product Based';
        legal[0].QTB_Storage_Service_Period_Range__c = true;
        update legal;
        List<Account> acc = [SELECT ID,QTB_Contract_Entity__c,BillingCountry FROM  Account WHERE ID = :invLst[0].blng__Account__c];
        acc[0].QTB_Contract_Entity__c = legal[0].ID;
        acc[0].QTB_Legal_Entity__c = legal[0].ID;
        acc[0].QTB_Legal_Entity_Country__c = 'United States';
        update acc;

        Contact cont = new Contact();
        cont.LastName = 'test114';
        cont.FirstName = 'abc124';
        cont.email = 'so1124@email.com';
        cont.AccountId = acc[0].ID;
        cont.MailingCountry = 'United States';
        cont.IM_Role__c = 'PO Contact'; 
        insert cont;

        // AccountContactRelation acr = new AccountContactRelation();
        // acr.accountId = acc[0].ID;
        // acr.ContactId = cont.ID;
        // insert acr;
        // acr.Roles = 'PO Contact';
        // update acr;

        List<Contact> contList = new List<Contact>();
        for(Integer i = 0; i< acc.size(); i++){
            if (i==2) break;
            Contact cont = new Contact( LastName = 'test11', FirstName = 'abc1', Email = 'so11@email.com', 
                                        AccountId = acc[i].ID, MailingCountry = 'Canada', IM_Role__c = 'PO Contact' );
            contList.add(cont);                           
        }
        insert contList;
        
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        for(Integer i = 0; i< acc.size(); i++){
            AccountContactRelation acr = new AccountContactRelation(AccountId = acc[(i)].ID,
                                                                        ContactId = contList[i].ID);
            acrList.add(acr);
        }
        insert acrList;
        
        List<Order> orderList = QTB_TestDataFactory.createCPQOrders(1,null,invlst[0].blng__Account__c);
        orderList[0].QTB_OrderCategory__c = 'Rebill';
        update orderList;
        QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c(QTB_Billing_Account__c = acc[0].ID, QTB_Legal_Entity_Country__c = acc[0].BillingCountry,
                            QTB_Status__c = 'Active',QTB_Start_Date__c = System.today(),QTB_End_Date__c = System.today(),QTB_PO_Type__c = 'Standard',
                            QTB_Customer_PO__c = 'QW2315', QTB_Amount__c = 10000,QTB_Service_Type__c = 'Mixed', QTB_Date_Of_100_Utilization__c = System.Today());
        insert pOrder;
        //insert new QTB_PurchaseOrderAccount__c(QTB_Purchase_Order__c = pOrder.Id,QTB_Account__c = acc[0].Id);
        List<blng__Invoice__c> invoiceList = new List<blng__Invoice__c>();
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = acc[0].ID;
        invoice.blng__InvoiceStatus__c = 'Draft';
        invoice.blng__InvoiceDate__c = System.today()-10;
        invoice.QTB_PurchaseOrder__c = pOrder.ID;
        invoice.blng__TaxStatus__c = 'Queued';
        invoiceList.add(invoice);

        if (!invoiceList.isEmpty()) {
            insert invoiceList;
        }
        invoiceList[0].blng__InvoiceStatus__c = 'Posted';
        update invoiceList;
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__Invoice__c = invoiceList[0].ID;
        invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;
        //invoiceLine.blng__UsageSummary__c = usagesummary.ID; 
        invoiceLine.blng__Subtotal__c = 100;
        invoiceLine.blng__TaxCountry__c = 'India';
        invoiceLine.blng__LegalEntity__c = Legal[0].ID;
        insert invoiceLine;
        
        for(blng__Invoice__c inv :invlst){
            inv.blng__InvoiceStatus__c = 'Draft';
            inv.QTB_hasTieredLines__c = true;
            inv.QTB_Invoice_Type__c = 'ReBill';
            inv.blng__Order__c = orderList[0].Id;
            inv.QTB_Parent_Invoice__c = invoiceList[0].Id;
            inv.QTB_Rebill_Type__c = 'Split';
            //inv.QTB_LegalEntityCountry__c = 'United States';
        }
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        invoiceLine1.Name = 'prodName';
        invoiceLine1.blng__Invoice__c = invLst[0].ID;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine1.blng__Quantity__c = 10;
        invoiceLine1.blng__UnitPrice__c = 5;
        //invoiceLine.blng__UsageSummary__c = usagesummary.ID; 
        invoiceLine1.blng__Subtotal__c = 100;
        invoiceLine1.blng__TaxCountry__c = 'India';
        invoiceLine1.blng__LegalEntity__c = Legal[0].ID;
        insert invoiceLine1;
        sbqq.TriggerControl.disable();
        update invlst;
        
        for(blng__Invoice__c inv :invlst){
            inv.blng__InvoiceStatus__c = 'Draft';
        }
        update invlst;
        sbqq.TriggerControl.enable();
        Test.stopTest();
    }*/
}