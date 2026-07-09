/*****************************************************************************************************
* Class	: QTB_CreditReBillOrderCreation_Test
* Author	: IRM/TCS
* Purpose	: This is a test class for QTB_CreditReBillOrderCreation
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* IRM/TCS    07/11/2022      Gitlab US #9256 Credit & Rebill
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_CreditReBillOrderCreation_Test {
    @testSetup
    static void setup() {
        
		Credit_ReBill_InvoiceSchedulerValidation__c invSchCust = new Credit_ReBill_InvoiceSchedulerValidation__c();
        invSchCust.Name = 'United States';
        invSchCust.isRunning__c = false;
        insert invSchCust;
		
        //Billing Rule, Revenue Rule, Tax Rule
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
		//Product
        List<Product2> productList = new List<Product2>();
                
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        p1.blng__BillingRule__c = billingRule.id;
        p1.blng__RevenueRecognitionRule__c = revenueRule.id;
        p1.blng__TaxRule__c = taxRule.id;
        productList.add(p1);
        insert productList;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(productList[0]);
        
        //Account
        List<account> accountList = QTB_TestDataFactory.createAccounts(1);
        accountList[0].QTB_Legal_Entity_Country__c='United States';
        accountList[0].QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
        update accountList;
        
        //Legal Entity
        blng__LegalEntity__c indiaEntity = new blng__LegalEntity__c();
        indiaEntity.Name = 'Test Legal Entity United States';
        indiaEntity.blng__Active__c = true;
        indiaEntity.blng__Country__c = 'United States';
        indiaEntity.QTB_Type__c = 'Contract';
        // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert indiaEntity;
        
        //IM Country
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';        
        //im.Active__c = true;//billing country criteria not match issue getting
        insert im;
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
       // oppList[0].Legal_Entity__c = indiaEntity.id;
        oppList[0].Billing_Country__c = im.id;
        database.update(oppList);
        
        //QuoteTemplate
        SBQQ__QuoteTemplate__c quoteTemplate = new SBQQ__QuoteTemplate__c();
        quoteTemplate.Name = 'Price Quote';
        quoteTemplate.SBQQ__DeploymentStatus__c = 'Deployed';
        insert quoteTemplate;         
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].QTB_IM_Legal_Entity__c = indiaEntity.id;
        quoteList[0].QTB_Opportunity_Billing_Country__c = 'United States';
        database.update(quoteList);
        
        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[0].id);
        quoteLinesList[0].SBQQ__ChargeType__c = 'Recurring';
        quoteLinesList[0].SBQQ__BillingType__c = 'Arrears';
        update quoteLinesList;
        
        Test.startTest();
        //Order
        List<Order> orderList = new List<Order>();
        
        Order ord = new Order(
            SBQQ__Quote__c =  quoteList[0].Id,
            AccountId = accountList[0].id,
            blng__BillingDayOfMonth__c = '1',
            EffectiveDate = Date.today().addDays(5),
            Status = QTB_Constants.DRAFT_STATUS,
            Pricebook2Id = pricebookId,
            blng__InvoiceBatch__c = 'Rebill Run'
            //RecordTypeId = QTB_Utils.ORDER_BILL_RECTYPEID
        );        
        orderList.add(ord);
        System.debug('orderList@@'+orderList);
        insert orderList;
        
        SBQQ.TriggerControl.disable();
        
        //Order Product
        List<orderitem> orderproduct = new List<orderitem>();  
        orderitem ordI =  new orderitem(
            OrderId = orderList[0].Id,
            Quantity = 2.00,
            UnitPrice = 12.00,
            SBQQ__QuoteLine__c = quoteLinesList[0].id,
            PricebookEntryId = standardPrice.Id,
            SBQQ__ChargeType__c = 'One-Time',
            product2id = productList[0].id,
            //SBQQ__Activated__c = true,
            blng__BillingRule__c = billingRule.Id ,
            blng__RevenueRecognitionRule__c = revenueRule.Id,
            blng__TaxRule__c = taxRule.id
        );
        orderproduct.add(ordI);
        insert orderproduct;
        orderproduct[0].SBQQ__Activated__c = true;
        update orderproduct[0];
        
        //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
        invoiceList[0].QTB_ReBill_Status__c = 'Order Completed';
        invoiceList[0].QTB_ReBillOrderId__c =orderList[0].id;
        
        update invoiceList;
        
        //Invoice Line
        //
        Metadata_Activation_Settings__c cust = new Metadata_Activation_Settings__c();
        cust.SObject_API_Name__c = 'blng__InvoiceLine__c';
        cust.Disable_Trigger__c = true;
        insert cust;
        
        List<blng__InvoiceLine__c> invoiceLineList = new List<blng__InvoiceLine__c>();
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c(
            Name = productList[0].Name,
            blng__Invoice__c = invoiceList[0].Id,
            blng__Product__c = productList[0].Id,
            blng__OrderProduct__c = orderproduct[0].Id,
            blng__InvoiceLineStatus__c = 'Draft',
            blng__Quantity__c = 10,
            blng__UnitPrice__c = 5,
            blng__TaxPercentageApplied__c = 24,
            blng__Subtotal__c = 50,
            blng__TotalAmount__c = 50 * 0.24,
            blng__StartDate__c = System.today(),
            blng__EndDate__c = System.today() + 30
        );
        
        invoiceLineList.add(invoiceLine);
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c(
            Name = productList[0].Name,
            blng__Invoice__c = invoiceList[0].Id,
            blng__Product__c = productList[0].Id,
            blng__OrderProduct__c = orderproduct[0].Id,
            blng__InvoiceLineStatus__c = 'Draft',
            blng__Quantity__c = 10,
            blng__UnitPrice__c = 5,
            blng__TaxPercentageApplied__c = 24,
            blng__Subtotal__c = 50,
            blng__TotalAmount__c = 50 * 0.24,
            blng__StartDate__c = System.today(),
            blng__EndDate__c = System.today() + 30
        );
        invoiceLineList.add(invoiceLine1);
        insert invoiceLineList;
        Test.stopTest();
    }
    
    static testMethod void testmethodcreateRebillOrder() {
        Test.startTest();
        blng__Invoice__c inv = [select id from blng__Invoice__c limit 1];
        QTB_CreditReBillOrderCreation.createRebillOrder(inv.id, 'Account Creation','Internal Notes','Split','2'); 
        QTB_CreditReBillOrderCreation.checkExistingCreditNote(inv.id);
        QTB_CreditReBillOrderCreation.checkSubscritionBundleProducts(inv.id);
        QTB_CreditReBillOrderCreation.getUsageData(inv.id);
        QTB_CreditReBillOrderCreation.checkProductIdentifier(inv.id);
        Test.stopTest();
    }   
}