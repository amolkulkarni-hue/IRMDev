/*****************************************************************************************************
* Class: QTB_InvoiceHelperUtils_Test
* Author: Accenture
* Purpose: This is a test class for QTB_InvoiceHelperUtils
* Requirement:
* Change History: 20/05/2024
* Developer				Date           Description
* -------------------------------------------------------------------------------------------
* Parth(Virtusa)        20/05/2024
*******************************************************************************************************/
@isTest
public class QTB_InvoiceHelperUtils_Test {
    @testSetup()
    static void setup(){
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
        custSetting.SObject_API_Name__c = 'Opportunity;blng__UsageSummary__c;blng__Usage__c;SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__InvoiceScheduler__c';
        custSetting.Disable_VR__c = true;
        custSetting.Disable_PB__c = true;
        custSetting.Disable_Trigger__c = true;
        // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
        insert custSetting;
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        QTB_Billing_Countries__c BillingCountries = new QTB_Billing_Countries__c();
        BillingCountries.Name = 'Singapore';
        BillingCountries.Legal_entity_country__c = 'Singapore' ;
        insert BillingCountries;
        
        //Product
        List<product2> product = QTB_TestDataFactory.createProducts(3);
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        product[0].QTB_Price_Schedule_Category__c = 'Storage';
        database.update(product);
        
        //Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);

    //Legal Entity
        blng__LegalEntity__c USEntity = new blng__LegalEntity__c();
        USEntity.Name = 'Test Legal Entity United States';
        USEntity.blng__Active__c = true;
        USEntity.blng__Country__c = 'United States';
        USEntity.QTB_Type__c = 'Contract';
        USEntity.QTB_Storage_Service_Period_Range__c = true;
        USEntity.QTB_Tax_Applicability__c = 'Product Based';
        USEntity.QTB_FX_Tax_Rate_Type__c = 'RO National Bank Rate';
        USEntity.QTB_FX_Rate_For_Rebill__c = 'System Date';
        insert USEntity;
        
        //Account
        List<Account> accountList = new List<Account>();
        ID StandardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
        Id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
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
            a.ShippingCountry = 'India';
            a.QTB_Legal_Entity_Country__c='Romania';
            a.QTB_Language__c = 'ro';
            a.QTB_Split_Invoice_Flag__c = true;
            //a.IM_Hierarchy_Level__c = 'Sales (Site)';
            a.QTB_Legal_Entity__c = USEntity.id;            
            accountList.add(a);
        }
        
        if (!accountList.isEmpty()) {
            insert accountList;
        }
        
        
    
        
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';    
        im.Active__c = true;
        insert im;
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        //oppList[0].Legal_Entity__c = USEntity.id;
        oppList[0].Billing_Country__c = im.id;
        database.update(oppList);
        test.startTest();
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].QTB_IM_Legal_Entity__c = USEntity.id;
        quoteList[0].QTB_Opportunity_Billing_Country__c = 'United States';
        database.update(quoteList);
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
        
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        
        database.update(orderList3);
        
        SBQQ.TriggerControl.disable();
        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].Id,quoteLinesList,standardPrice);
        orderItemList3[0].blng__HoldBilling__c = 'Yes';
        orderItemList3[0].blng__InvoiceGroupId__c = 'Non-Storage';
        update orderItemList3;
        Contact cont = new Contact();
        cont.LastName = 'test1 ';
        cont.FirstName = 'abc ';
        cont.email = 'so1@email.com';
        cont.AccountId = accountList[0].Id;
        cont.MailingCountry = 'United States';
        cont.IM_Role__c = 'PO Contact';
        insert cont;
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.accountId = accountList[1].id;
        acr.ContactId = cont.Id;
        acr.Roles = 'PO Contact';
        insert acr;
        
        set<id> invoiceIds = new set<id>();
        //Invoice
        List<blng__Invoice__c> invoiceList = new List<blng__Invoice__c>();
        for (Account acc : accountList) {
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = acc.Id;
            invoice.blng__InvoiceStatus__c = 'Draft';
            invoice.blng__InvoiceDate__c = System.today()-10;
            invoice.QTB_Service_Type__c = 'Service';
            invoice.QTB_Exchange_Rate__c = 2;
            invoiceList.add(invoice);
            invoiceIds.add(invoice.id);
            break;
        }
        if (!invoiceList.isEmpty()) {
            insert invoiceList;
        }
        QTB_Invoice_For_EU__c rec2 = new QTB_Invoice_For_EU__c();
        rec2.Name = 'india';
        insert rec2;
        QTB_InvoiceHelperUtils.updateInvoiceNote(invoiceIds);
       /* List<blng__InvoiceLine__c> invLineList = QTB_TestDataFactory.createInvoiceLine(1,invoiceList,product);
        invLineList[0].blng__OrderProduct__c = orderItemList3[0].Id;
        invLineList[0].blng__TaxCountry__c = 'United States';
        update invLineList;
        test.stopTest();*/
        
        //creating usage summary
            List<blng__UsageSummary__c> usageSumList = new List<blng__UsageSummary__c>();
            List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(
                2,
                accountList[0],
                orderList3[0],
                orderItemList3[0]
            );
            blng__UsageSummary__c usagesummary = usageSum[0];
            usagesummary.blng__Status__c = 'Queued For Invoice';
            usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
            usagesummary.blng__UnitPrice__c = 12;
            usagesummary.blng__TotalQuantity__c = 10;
            usagesummary.blng__NextBillingDate__c = System.now().date().addDays(-5);
            usagesummary.blng__PreratedAmount__c = 1000;
            usagesummary.blng__Subtotal__c = 1000;
            
            blng__UsageSummary__c usagesummary1 = usageSum[1];
            usagesummary1.blng__TotalQuantity__c = 10;
            usagesummary1.blng__PreratedAmount__c = 1000;
            usagesummary1.blng__Status__c = 'Queued For Invoice';
            usagesummary1.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
            usagesummary1.blng__MatchingId__c = '1234';
            usagesummary1.blng__Subtotal__c = 1000;
            usagesummary1.blng__UnitPrice__c = 10;
            usagesummary1.blng__NextBillingDate__c = System.now().date().addDays(-5);
            usageSumList.add(usagesummary);
            usageSumList.add(usagesummary1);
            update usageSumList;
            
            List<blng__Usage__c> usageListnew = new List<blng__Usage__c>();
            List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(
                2,
                accountList[0],
                usagesummary
            );
            blng__Usage__c usage = usageList[0];
            usage.blng__PreratedAmount__c = 100;
            usage.blng__PreratedQuantity__c = 10;
            usage.QTB_Contracted_Currency_Amount__c = 100;
            usage.blng__UnitPrice__c = 10;
        	usage.QTB_Prerated_Unit_Price__c = 10;
            usage.blng__OrderProduct__c = orderItemList3[0].id;
            usage.blng__Order__c = orderList3[0].id;
            usage.QTB_Start_Date_MRC__c = date.today().addDays(-30);
            usage.QTB_End_Date_MRC__c= date.today();
            
            
            blng__Usage__c usage1 = usageList[1];
            usage1.blng__PreratedAmount__c = 100;
            usage1.blng__PreratedQuantity__c = 10;
            usage1.QTB_Contracted_Currency_Amount__c = 100;
            usage1.blng__PreratedQuantity__c = 10;
            usage1.blng__MatchingId__c = '1234';
            usage1.blng__Status__c = 'Processed';
            usage1.blng__UnitPrice__c = 5;
        	usage1.QTB_Prerated_Unit_Price__c = 5;
            usage1.QTB_Price_Tier__c = 'Tier 1';
            
            usageListnew.add(usage);
            usageListnew.add(usage1);
            update usageListnew;
        
        List<blng__InvoiceLine__c> invLineList = QTB_TestDataFactory.createInvoiceLine(1,invoiceList,product);
            invLineList[0].blng__OrderProduct__c = orderItemList3[0].id;
            invLineList[0].blng__UsageSummary__c = usagesummary.id;
            invLineList[0].currencyISOCode = 'INR';
            invLineList[0].blng__InvoiceLineStatus__c = 'Draft';
            invLinelist[0].blng__TaxAmount__c = 50;
            invLineList[0].QTB_Tax_Override_Amount__c = 50;
            invLineList[0].blng__UnitPrice__c = 10;
            invLineList[0].blng__Quantity__c = 10;
            invLinelist[0].blng__TaxCountry__c = 'India';
            invLinelist[0].blng__TaxState__c = 'TN';
            invLinelist[0].blng__TaxCity__c = 'Chennai';
            invLinelist[0].blng__TaxZipCode__c = '500032';
            invLinelist[0].blng__TaxRule__c  = taxRule.id;
            invLinelist[0].blng__LegalEntity__c = USEntity.id;
            invLinelist[0].blng__Subtotal__c = 200;
            invLinelist[0].blng__TotalAmount__c = 250;
            database.update(invLineList[0]);
    }
        static testMethod void test6(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        Test.startTest();
        //Map<String, QTB_Invoice_For_EU__c> lstEuCountries = QTB_Invoice_For_EU__c.getAll();
        QTB_Invoice_For_EU__c rec2 = new QTB_Invoice_For_EU__c();
        rec2.Name = 'romania';
        insert rec2;
		QTB_Invoice_Note_Labels__c noteLabels = new QTB_Invoice_Note_Labels__c();
        noteLabels.Name = 'romania/en_us';
        noteLabels.Exchange_rate__c = 'Exchange Rate';
        noteLabels.Total__c = 'Total in Local Currency';
        noteLabels.Sub_Total__c = 'Sub Total in Local Currency';
        noteLabels.VAT__c = 'VAT in Local Currency';
        insert noteLabels;
        List<blng__Invoice__c> listInvoice = [Select id,QTB_Exchange_Rate__c,blng__Account__r.QTB_Contract_Currency__c,blng__Account__r.CurrencyIsoCode,
                                                      blng__Account__r.QTB_Legal_Entity__r.QTB_FX_Tax_Rate_Type__c,QTB_Contracted_Currency_Rate__c,
                                                      blng__Account__r.QTB_Legal_Entity_Country__c ,QTB_Subtotal_local_currency__c,
                                                      QTB_Tax_Override_Amt_Local__c,QTB_Total_Amt_Tax_Override_local__c,
                                                      blng__Account__r.QTB_Language__c from blng__invoice__c];
            set<id> lst = new set<id>();
            lst.add(listInvoice[0].id);
            QTB_InvoiceHelperUtils.updateInvoiceNote(lst);
        Test.stopTest();
    }
    //Added #26654
     @isTest
    static void testMethod3(){
        //Product1 -- usage
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
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            CurrencyIsoCode = 'INR',
            QTB_country__c = 'India',
            IsActive = true);
        update standardPricebook;
        
        List<priceBook2> prbk = QTB_TestDataFactory.priceBookMethdLst(1,'India');
        prbk[0].QTB_Country__c = 'India';
        prbk[0].currencyISOCode = 'INR';
        prbk[0].IsActive = true;
        update prbk[0];
        system.debug('prbk--->'+prbk[0].Id +' country--->'+prbk[0].QTB_Country__c);
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = productList[0].Id, UnitPrice = 10000, IsActive = true,  currencyISOCode = 'INR' );
        insert standardPrice;
        System.debug('**standardPrice'+standardPrice+'Currency >>>'+standardPrice.CurrencyIsoCode);
        PriceBookEntry IndiaPrice= new PricebookEntry(pricebook2id = prbk[0].id, product2Id = productList[0].id, unitPrice=2000, isActive = true, currencyISOCode = 'INR');
        insert IndiaPrice;
        System.debug('**IndiaPrice--->'+IndiaPrice+' Currency--->'+IndiaPrice.CurrencyIsoCode+' pricebookCountry--->'+IndiaPrice.pricebook2.QTB_country__c);
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
        indiaEntity.QTB_Tax_Applicability__c = 'Flat Rate';
        indiaEntity.CurrencyIsoCode = 'EUR';
        indiaEntity.QTB_FX_Tax_Rate_Type__c = 'Corporate';
        indiaEntity.QTB_FX_Rate_For_Rebill__c = 'System Date';
        update indiaEntity;
        //Billing Account
        List<Account> accountList = new List<Account>();
        Account acc = new Account();
        acc.name = 'test Acc';
        acc.QTB_Legal_Entity_Country__c = 'India';
        acc.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        acc.ShippingCity = 'TN';
        acc.ShippingState = 'Chennai';
        acc.ShippingPostalCode = '500032';
        acc.ShippingCountry = 'India';
        acc.QTB_Records_Management__c = true;
        acc.Payment_Terms__c = 'Net 30';
        acc.QTB_Legal_Entity__c = indiaEntity.Id;
        acc.QTB_Contract_Entity__c = indiaEntity.Id;
        acc.CurrencyIsoCode = 'INR';
        insert acc;
        accountList.add(acc);
        
        
        QTB_Foreign_Exchange__c fe = new QTB_Foreign_Exchange__c();
        fe.QTB_Start_Date__c = system.today().adddays(-100);
        fe.QTB_End_Date__c = system.today().adddays(100);
        fe.QTB_Currency_From__c = 'INR';
        fe.QTB_Currency_To__c = 'EUR';
        fe.QTB_Rate__c = 10;
        fe.QTB_Tax_Rate_Type__c = 'Corporate';
        insert fe;
        
        //Tax Rule
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;
        
        //Tax Integration
        blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
        taxIntegration.blng__TaxEngine__c = 'Standard';
        taxIntegration.blng__Active__c = true;
        insert taxIntegration;
        
        //Tax Treatment
        blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
        blngTax.blng__TaxLegalEntity__c = indiaEntity.id;
        blngTax.blng__TaxIntegration__c = taxIntegration.id;
        blngTax.blng__TaxRule__c = taxRule.id;
        blngTax.blng__TaxCode__c = 'STD-CGST';
        insert blngTax;
        
        //Tax Rate
        blng__TaxRate__c taxRate = new blng__TaxRate__c();
        taxRate.blng__LegalEntity__c = indiaEntity.id;
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
        insert taxRate;  
        Map<Id,blng__Invoice__c> invMap = new Map<Id,blng__Invoice__c>();
        List<blng__Invoice__c> invList = new List<blng__Invoice__c>();
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[0].Id;
        invoice.blng__InvoiceStatus__c = 'Posted';
        invoice.QTB_Tax_Override_Amount__c = 10;
        invoice.blng__InvoiceDate__c = System.today();
        //26371
        invoice.blng__DueDate__c = System.today();
        sbqq.TriggerControl.disable();
        insert invoice;
        invList.add(invoice);
        for(blng__Invoice__c inv : invList){
            invMap.put(inv.id,inv);
        }
        QTB_InvoiceHelperUtils.updateExchangeRate(invMap);
        try {
           QTB_InvoiceHelperUtils.updateExchangeRate(null);
        } catch (Exception e) {
            System.debug('testmethod1_Exception1@@'+ e.getMessage());
        }
        
        system.debug('invoice-->'+invoice);
        //List<blng__InvoiceLine__c> invoiceLineListForCredit = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
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
        //insert invoiceLine;
        sbqq.TriggerControl.disable();
        system.debug('invoiceLine--->'+invoiceLine);
        //system.debug('invoiceLineListForCredit->'+invoiceLineListForCredit[0]);
        /*invoiceLineListForCredit[0].QTB_Tax_Override_Amount__c = 10;
List<blng__CreditNote__c> creditNoteWithInvRefList = QTB_TestDataFactory.createCreditNote(accountList);
List<blng__CreditNoteLine__c> cnlWithInvLst = QTB_TestDataFactory.createCreditNoteLine(1,accountList[0],creditNoteWithInvRefList[0],invoiceListForCredit[0],invoiceLineListForCredit[0],productList[0]);
system.debug('cnlWithInvLst->'+cnlWithInvLst[0]);
system.debug('cnlWithInvLst->'+cnlWithInvLst[0].QTB_invoiceline__c);*/
        
        Test.startTest();
    }
    static testMethod void test1(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        Map<Id,blng__Invoice__c>invMap = new MAp<Id,blng__Invoice__c>([Select id,QTB_Service_Type__c,blng__Account__c,blng__Account__r.QTB_Split_Invoice_Flag__c,
                                                                       (select id,blng__OrderProduct__c,blng__OrderProduct__r.blng__InvoiceGroupId__c from blng__InvoiceInvoiceLines__r) from blng__invoice__c]);
        List<blng__InvoiceLine__c> invLineLst = [Select Id,blng__Invoice__c from blng__InvoiceLine__c];
        List<account>InvAccount = [Select Id,QTB_Split_Invoice_Flag__c from account];
        List<OrderItem> ordItm = [Select Id,blng__InvoiceGroupId__c From OrderItem ];
        Test.startTest();
        QTB_InvoiceHelperUtils.serviceTypeAssignment(invMap);
        ordItm[0].blng__InvoiceGroupId__c = 'Non-Storage';
        Update ordItm;
        QTB_InvoiceHelperUtils.serviceTypeAssignment(invMap);
        InvAccount[0].QTB_Split_Invoice_Flag__c = False;
        update InvAccount;
        QTB_InvoiceHelperUtils.serviceTypeAssignment(invMap);
        Test.stopTest();
        QTB_InvoiceLineTriggerHandler.throwExplicitException = True;
        try{
            QTB_InvoiceHelperUtils.serviceTypeAssignment(invMap);
        }catch(exception e){
            System.debug('message--->'+e.getMessage());
            system.assertEquals('Script-thrown exception',e.getMessage());
        }
        try{
            QTB_InvoiceHelperUtils.updateInvoiceNote(null);
        }catch(exception e){
            System.debug('message--->'+e.getMessage());
            system.assertEquals('Script-thrown exception',e.getMessage());
        }
    }
    static testMethod void test2(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
                Test.startTest();

        List<account>InvAccount = [Select Id,QTB_Split_Invoice_Flag__c,CurrencyIsoCode from account];
                List<OrderItem> ordItm = [Select Id,Orderid,blng__InvoiceGroupId__c From OrderItem ];
        system.debug('17333  '+InvAccount);

		  blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = InvAccount[0].Id;
            invoice.blng__InvoiceStatus__c = 'Draft';
            invoice.blng__InvoiceDate__c = System.today()-10;
            invoice.QTB_Service_Type__c = 'Service';
            //invoice.QTB_Custom_Invoice_Number__c ='00000001';

            insert invoice;
        
        Map<Id,blng__Invoice__c> mapCustmInvcNumberInvc = new Map<Id,blng__Invoice__c>();
        set<Id> invcId = new set<Id>();
        list<Id> invcIds = new list<Id>();

            mapCustmInvcNumberInvc.put(invoice.QTB_Custom_Invoice_Number__c,invoice);
            invcId.add(invoice.id);
            invcIds.add(invoice.id);
        
        product2 p2 = new product2();
        p2.Name = 'Fair Market Value';
        p2.isActive = true;
        p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p2.SBQQ__HasConsumptionSchedule__c = true;
        insert p2;
        
        
        
        blng__UsageSummary__c usage = new blng__UsageSummary__c();
        usage.blng__Order__c = ordItm[0].Orderid;
        usage.blng__Account__c = InvAccount[0].id;
        usage.blng__OrderProduct__c = ordItm[0].id;
        usage.blng__SummaryEndDate__c = DateTime.now().date().addDays(30);
        usage.blng__SummaryStartDate__c = DateTime.now().date();//date.today();
        usage.blng__MatchingId__c = '1234';
        usage.blng__Status__c = 'Queued For Invoice';
        usage.blng__MatchingAttribute__c ='11234';
        usage.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
        usage.blng__UnitOfMeasure__c ='Each';
        //usage.CurrencyIsoCode = 'SGP';
        
        INSERT usage;
        system.debug('2111  '+usage.id);
        
        blng__Usage__c usage1 = new blng__Usage__c();
        //usage1.blng__UsageSummary__c = usage.id;
        usage1.blng__Account__c = InvAccount[0].id;
        usage1.blng__MatchingId__c = '1234';
        usage1.blng__UnitOfMeasure__c = 'Each';
        usage1.blng__MatchingAttribute__c = '11234';
        usage1.blng__EndDateTime__c = DateTime.now().addDays(30);
        usage1.blng__StartDateTime__c = DateTime.now();
        usage1.blng__PreratedAmount__c=100;
        usage1.blng__PreratedQuantity__c=10;
        usage1.QTB_Usage_Category__c='EOM';
        //usage1.CurrencyIsoCode = 'SGP';
        INSERT usage1;

		system.debug('@@@33333  '+usage1.blng__UsageSummary__c);        
        system.debug('@@@4444 '+usage1); 
        
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = p2.Name;
        invoiceLine.blng__UsageSummary__c = usage.id;
        
        invoiceLine.blng__Invoice__c = invoice.id;
        invoiceLine.blng__Product__c = p2.Id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;
        invoiceLine.blng__TaxPercentageApplied__c = 24;
        //insert invoiceLine;
        
        usage.blng__InvoiceLine__c = invoiceLine.id;
        update usage;
        
        List<blng__UsageSummary__c> lstUsgSmr = [Select id,name,blng__InvoiceRun__c,blng__InvoiceLine__c,blng__InvoiceLine__r.blng__Invoice__c,blng__InvoiceLine__r.blng__Invoice__r.QTB_Custom_Invoice_Number__c,blng__InvoiceLine__r.blng__Invoice__r.QTB_Service_Type__c,(select id,blng__UsageSummary__c,QTB_ServicePeriod__c,QTB_Usage_Category__c from blng__Usages__r where QTB_Usage_Category__c='EOM' Limit 1) from blng__UsageSummary__c where blng__InvoiceLine__r.blng__Invoice__c  =:invcIds[0]];  
        system.debug('@@@!!!!!    '+lstUsgSmr);
        
        Map<Id,blng__Invoice__c> mapCustmInvcNumberInvc1 = new Map<Id,blng__Invoice__c>();
        set<Id> invcId1 = new set<Id>();
        for(blng__UsageSummary__c us:lstUsgSmr){
            blng__Invoice__c invc = new blng__Invoice__c();
            invc.id = us.blng__InvoiceLine__r.blng__Invoice__c;  
            invc.QTB_Service_Type__c = us.blng__InvoiceLine__r.blng__Invoice__r.QTB_Service_Type__c;
            mapCustmInvcNumberInvc1.put(invc.Id,invc);
            invcId1.add(invc.id);
        }
        //QTB_InvoiceHelperUtils.linkBoxSummary(mapCustmInvcNumberInvc1.keySet()); 
       
        QTB_InvoiceLineTriggerHandler.throwExplicitException = True;
        
        /*try{
            QTB_InvoiceHelperUtils.linkBoxSummary(null);
        }catch(exception e){
            System.debug('message--->'+e.getMessage());
            system.assertEquals('Script-thrown exception',e.getMessage());
        }*/
         Test.stopTest();
    }
    static testMethod void test7(){
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        Test.startTest();
        //Map<String, QTB_Invoice_For_EU__c> lstEuCountries = QTB_Invoice_For_EU__c.getAll();
        QTB_Invoice_For_EU__c rec2 = new QTB_Invoice_For_EU__c();
        rec2.Name = 'Romania';
        insert rec2;
        QTB_Invoice_Note_Labels__c noteLabels = new QTB_Invoice_Note_Labels__c();
        noteLabels.Name = 'romania/en_us';
        noteLabels.Exchange_rate__c = 'Exchange Rate';
        noteLabels.Total__c = 'Total in Local Currency';
        noteLabels.Sub_Total__c = 'Sub Total in Local Currency';
        noteLabels.VAT__c = 'VAT in Local Currency';
        insert noteLabels;

        List<blng__Invoice__c> listInvoice = [Select id,QTB_Exchange_Rate__c,blng__Account__r.QTB_Contract_Currency__c,blng__Account__r.CurrencyIsoCode,
                                                      blng__Account__r.QTB_Legal_Entity__r.QTB_FX_Tax_Rate_Type__c,QTB_Contracted_Currency_Rate__c,
                                                      blng__Account__r.QTB_Legal_Entity_Country__c ,QTB_Subtotal_local_currency__c,
                                                      QTB_Tax_Override_Amt_Local__c,QTB_Total_Amt_Tax_Override_local__c,
                                                      blng__Account__r.QTB_Language__c from blng__invoice__c];
            set<id> lst = new set<id>();
            lst.add(listInvoice[0].id);
            QTB_InvoiceHelperUtils.updateInvoiceNote(lst);
        Test.stopTest();
    }
    static testMethod void test4(){
        set<Id>invId = new Set<Id>();
        QTB_InvoiceHelperUtils.createSubLinesAndUpdateInvAndInvLine(invId);
        for(blng__Invoice__c inv :[Select Id from blng__Invoice__c]){
            invId.add(inv.Id);
        }
        QTB_InvoiceHelperUtils.createSubLinesAndUpdateInvAndInvLine(invId);
        QTB_InvoiceTriggerHandler.throwExplicitException = true;
        try{
            QTB_InvoiceHelperUtils.createSubLinesAndUpdateInvAndInvLine(invId);
        }catch(exception e){
            system.debug('exception->'+e.getMessage());
        }
    }
}