@isTest(seealldata=false)
private with sharing class QTB_CRDN_Ready_for_integrati_BatchTest {
    
     @TestSetup
    static void createData() {
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
      custSetting.SObject_API_Name__c = 'User;blng__InvoiceLine__c;Account;blng__CreditNoteLine__c';
      custSetting.Disable_VR__c = true;
      custSetting.Disable_PB__c = true;
      custSetting.Disable_Trigger__c = true;
      // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      insert custSetting;
        Boolean onAccountCreditBillingCountry =false;
        QTB_Account_Level_Credit_Note_Setting__mdt accMdt=[select id,Label, NamespacePrefix, QTB_Acc_LegalEntityCntry__c from QTB_Account_Level_Credit_Note_Setting__mdt where Label='US_SITAD' limit 1];
        
        Id pricebookId = Test.getStandardPricebookId();
        
        //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = false;
        productList.add(p1);  
        
        //Product2 -- usage -- Fair Market Value
        product2 p2 = new product2();
        p2.Name = 'Fair Market Value';
        p2.isActive = true;
        p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p2.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p2);         
        insert productList;
        
        //Price Book creation for all product
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(productList[0]);  
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[1]); 
        
        IM_Country__c country = new IM_Country__c(Name = 'United States',Iso31662Code__c='US');
        database.insert(country);
        
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
        
        QTB_TestDataFactory.createCustomInvoiceNumber();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        List<QTB_CustomInvoiceNumber__c> invCustomSettToUpdate=new List<QTB_CustomInvoiceNumber__c>();
        entityList.add(QTB_TestDataFactory.createLegalEntity('singapore'));
        
        //custom settings
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'singapore';
        sweCustomSettings.QTB_Country__c = 'singapore';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '9000128488';
        insert sweCustomSettings; 

        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('singapore');
        indiaEntity.QTB_Tax_Applicability__c = 'Flat Rate';
        indiaEntity.blng__Country__c = 'singapore';
        Update indiaEntity;
        
        //Billing Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c='singapore';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        accountList[0].ShippingCity = 'test1';
        accountList[0].ShippingState = 'test1';
        accountList[0].ShippingPostalCode = '22131';
        accountList[0].ShippingCountry = 'singapore';
        accountList[0].QTB_Contract_Entity__c = indiaEntity.Id;
        update accountList;
        Contact con = new Contact();
            con.LastName = 'Custom Last Name:009 ';
            con.FirstName = 'Custom First Name ';
            con.email = 'some15@email.com';
            con.AccountId = accountList[0].Id;
            con.MailingCountry = 'United States';
            con.IM_Role__c = 'PO Contact';
            insert con;        
        AccountContactRelation acr = new AccountContactRelation();
            acr.accountId = accountList[1].id;
            acr.ContactId = con.Id;
            insert acr;
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        database.update(oppList);
        
        //Quote Template
        SBQQ__QuoteTemplate__c template = new SBQQ__QuoteTemplate__c();
        template.Name = QTB_Constants.DRAFT_PRICE;
        insert template;
        
        SBQQ.TriggerControl.disable();
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        database.update(quoteList);
        
        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[0].id);
        
        //Order
        List<Order> orderList = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        database.update(orderList);
        
        //OrderItem
        List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,productList[0].Id,quoteLinesList,standardPrice1);
        
        Test.startTest();
        invCustomSettToUpdate.add(sweCustomSettings);
        //Invoice
        //List<blng__Invoice__c> invoiceListForCredit = QTB_TestDataFactory.createInvoices(accountList);
        //Creating new instance and inserting invoiceline
        blng__Invoice__c invoiceListForCredit = new blng__Invoice__c();
        invoiceListForCredit.blng__Account__c = accountList[0].Id;
        invoiceListForCredit.blng__InvoiceStatus__c = 'Draft';
        insert invoiceListForCredit;
        
        //Usage Summary for CreditNote
        List<blng__UsageSummary__c> usageSum1 = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList[0],orderItemList[0]);
        blng__UsageSummary__c usagesummary1 = usageSum1[0];        
        usagesummary1.blng__Status__c = 'Queued For Invoice';
        usagesummary1.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary1.blng__Subtotal__c = 100;
        usagesummary1.blng__TotalQuantity__c = 10;
        usagesummary1.blng__PreratedQuantity__c = 20;
        usagesummary1.blng__UnbilledQuantity__c = 1;
        usagesummary1.blng__UnitPrice__c = 400;
        usagesummary1.blng__PreratedAmount__c = 22;
        usagesummary1.blng__SummaryStartDate__c = Date.valueOf('2023-05-27');
        usagesummary1.blng__Invoice__c = invoiceListForCredit.id;
        database.update(usagesummary1);        
        
        //Usage1 for CreditNote
        List<blng__Usage__c> usageList1 = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary1);
        usageList1[0].QTB_System_Generated__c = true;
        usageList1[0].blng__PreratedAmount__c = 100;
        usageList1[0].blng__PreratedQuantity__c = 10;
        usageList1[0].QTB_Service_District__c = '44147';
        usageList1[0].QTB_Product_Identifier_1__c = 'billUsage';
        usageList1[0].blng__Subtotal__c = 50;
        usageList1[0].blng__OrderProduct__c = orderItemList[0].id;          
        database.update(usageList1);    
        
        
        //Invoice Run
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        
        //Update Invoice
        invoiceListForCredit.blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceListForCredit.blng__InvoiceStatus__c = 'Posted';       
        invoiceListForCredit.blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        invoiceListForCredit.QTB_ReBill_Status__c = 'Usage Completed';
       invoiceListForCredit.QTB_Internal_PO_Notes__c='Testing';
        update invoiceListForCredit;
        System.debug('setup_invoiceListForCredit@@'+invoiceListForCredit);
        
        //Rebill Invoice
        List<blng__Invoice__c> rebillInvoiceList = QTB_TestDataFactory.createInvoices(accountList);
        rebillInvoiceList[0].QTB_Parent_Invoice__c = invoiceListForCredit.id;
        rebillInvoiceList[0].blng__InvoiceDate__c = Date.valueOf('2023-05-27');
        rebillInvoiceList[0].blng__InvoiceStatus__c = 'Draft';        
        //update rebillInvoiceList;
        System.debug('setup_rebillInvoiceList1@@'+rebillInvoiceList);
        
        //Rebill Invoice Lines
        List<blng__InvoiceLine__c> rebillInvoiceLineList = QTB_TestDataFactory.createInvoiceLine(3,rebillInvoiceList,productList);
        System.debug('setup_rebillInvoiceLineList1@@'+rebillInvoiceLineList);
        
        //Tax Rule
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;
        
        //Invoice Line for CreditNote
        List<blng__Invoice__c> invoiceListForCredit1 = new List<blng__Invoice__c>();
        invoiceListForCredit1.add(invoiceListForCredit);
        List<blng__InvoiceLine__c> invLineListForCredit = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit1,productList);
        invLineListForCredit[0].blng__OrderProduct__c = orderItemList[0].id;
        invLineListForCredit[0].blng__Product__c = productList[0].id;
        invLineListForCredit[0].blng__UsageSummary__c = usagesummary1.id;
        invLineListForCredit[0].blng__InvoiceLineStatus__c = 'Posted';
        invLineListForCredit[0].blng__TaxAmount__c = 50;
        invLineListForCredit[0].blng__TaxCountry__c = 'India';
        invLineListForCredit[0].blng__TaxState__c = 'TN';
        invLineListForCredit[0].blng__TaxCity__c = 'Chennai';
        invLineListForCredit[0].blng__TaxZipCode__c = '500032';
        invLineListForCredit[0].blng__LegalEntity__c = indiaEntity.id;
        invLineListForCredit[0].blng__Subtotal__c = 1000;
        invLineListForCredit[0].QTB_Inc_Quantity__c = 10;
        invLineListForCredit[0].blng__TaxRule__c = taxRule.id;
		QTB_TestDataFactory.createBypassSetting('blng__InvoiceLine__c');
        database.update(invLineListForCredit);
        System.debug('setup_invLineListForCredit@@'+invLineListForCredit);
        
        //Tax Integration
        blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
        taxIntegration.blng__TaxEngine__c = 'Standard';
        taxIntegration.blng__Active__c = true;
        database.insert(taxIntegration);
        
        //Tax Treatment
        blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
        blngTax.blng__TaxLegalEntity__c = indiaEntity.id;
        blngTax.blng__TaxIntegration__c = taxIntegration.id;
        blngTax.blng__TaxRule__c = taxRule.id;
        blngTax.blng__TaxCode__c = 'STD-CGST';
        database.insert(blngTax);
        
        // Create Credit Note
        List<blng__CreditNote__c> creditNotesList = new List<blng__CreditNote__c>();
        
        QTB_PurchaseOrder__c PO=new QTB_PurchaseOrder__c();
        PO.QTB_PO_Type__c ='Standard';
        PO.QTB_Customer_PO__c ='123';
        PO.QTB_Billing_Account__c =accountList[0].Id;
        PO.QTB_Amount__c =50000;
        PO.QTB_PO_Balance_Amount__c =4000;
        po.QTB_Service_Type__c ='Mixed';
        
        insert PO;
        //Test.startTest();
         //Regular CreditNote
         set<Id> crdtIDs=new set<Id>();
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        creditNote1.blng__Account__c = accountList[0].Id;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Account Creation';
        creditNote1.blng__Status__c = 'Draft';
        //creditNote1.CurrencyIsoCode = 'EUR';
        creditNote1.QTB_Tax_Override_Amount__c = 13; 
        creditNote1.blng__RelatedInvoice__c = invoiceListForCredit.Id;
        creditNote1.QTB_Rebill_Invoice__c = rebillInvoiceList[0].Id;
        creditNote1.QTB_Purchase_Order__c =PO.id;
        creditNotesList.add(creditNote1);
        insert creditNotesList;
        
        crdtIDs.add(creditNote1.Id);
        Test.stopTest();
        //Create CreditNoteLine for Regular CreditNote
        List<blng__CreditNoteLine__c> creditNoteLineList = new List<blng__CreditNoteLine__c>();
        blng__CreditNoteLine__c cnl1 = new blng__CreditNoteLine__c();
        cnl1.QTB_Account__c = accountList[0].Id;
        cnl1.blng__CreditNote__c = creditNotesList[0].id;
        cnl1.QTB_Invoice__c = invoiceListForCredit.id;
        cnl1.QTB_InvoiceLine__c = invLineListForCredit[0].id;
        cnl1.blng__Product__c = productList[0].Id;
        cnl1.blng__TaxTreatment__c = blngTax.Id;
        cnl1.blng__Status__c = 'Draft';
        //cnl1.CurrencyIsoCode = 'EUR';
        creditNoteLineList.add(cnl1);
        insert creditNoteLineList;
        // Create Approval Rule
        sbaa__ApprovalRule__c testRule = QTB_TestDataFactory.createApprovalRule();
        
        //Create Approvals
        List<sbaa__Approval__c> appList = new List<sbaa__Approval__c>();
        sbaa__Approval__c testApproval = new sbaa__Approval__c();
        testApproval.sbaa__Status__c = 'Approved';
        testApproval.sbaa__RecordField__c = 'Test1';
        testApproval.sbaa__ApprovalStep__c = 1;
        testApproval.QTB_Credit_Note__c = creditNotesList[0].Id;
        testApproval.sbaa__Rule__c = testRule.Id;
        appList.add(testApproval);
        
        sbaa__Approval__c testApproval2 = new sbaa__Approval__c();
        testApproval2.sbaa__Status__c = 'Rejected';
        testApproval2.sbaa__RecordField__c = 'Test2';
        testApproval2.sbaa__ApprovalStep__c = 1;
        testApproval2.QTB_Credit_Note__c = creditNotesList[0].Id;
        testApproval2.sbaa__Rule__c = testRule.Id;
        appList.add(testApproval2);
        
        sbaa__Approval__c testApproval3 = new sbaa__Approval__c();
        testApproval3.sbaa__Status__c = 'Requested';
        testApproval3.sbaa__RecordField__c = 'Test3';
        testApproval3.sbaa__ApprovalStep__c = 1;
        testApproval3.QTB_Credit_Note__c = creditNotesList[0].Id;
        testApproval3.sbaa__Rule__c = testRule.Id;
        appList.add(testApproval3);
        
        sbaa__Approval__c testApproval4 = new sbaa__Approval__c();
        testApproval4.sbaa__Status__c = 'Recalled';
        testApproval4.sbaa__RecordField__c = 'Test4';
        testApproval4.sbaa__ApprovalStep__c = 1;
        testApproval4.QTB_Credit_Note__c = creditNotesList[0].Id;
        testApproval4.sbaa__Rule__c = testRule.Id;
        appList.add(testApproval4);
        
        sbaa__Approval__c testApproval5 = new sbaa__Approval__c();
        testApproval5.sbaa__Status__c = 'Revoked';
        testApproval5.sbaa__RecordField__c = 'Test5';
        testApproval5.sbaa__ApprovalStep__c = 1;
        testApproval5.QTB_Credit_Note__c = creditNotesList[0].Id;
        testApproval5.sbaa__Rule__c = testRule.Id;
        appList.add(testApproval5);
        database.insert(appList);
        
        SBQQ.TriggerControl.disable();
        //Update Credit Note
        creditNotesList[0].ApprovalStatus__c = 'Pending';
        database.update(creditNotesList[0]);
        creditNotesList[0].ApprovalStatus__c = 'Approved';        
        creditNotesList[0].blng__Status__c = 'Posted';
        creditNotesList[0].QTB_Custom_Invoice_ID__c ='SGP9000090103';
        creditNotesList[0].QTB_Custom_Invoice_Number__c ='SGP9000090103';
        //creditNotesList[0].QTB_Commercial_Credit__c = true;
        database.update(creditNotesList[0]);
        creditNoteLineList[0].blng__Status__c = 'Posted';
         database.update(creditNoteLineList[0]);
        //tax detail
        list<QTB_Tax_Detail__c> testTax = new list<QTB_Tax_Detail__c>();
        QTB_Tax_Detail__c test1 = new QTB_Tax_Detail__c();
        //test1.QTB_Invoice_Line__c  = invLinesList1[0].id;
        test1.QTB_Credit_Note__c  = creditNotesList[0].Id;
        test1.QTB_Jurisdiction__c = 'Test1';
        test1.QTB_Imposition__c  = 'Test2';
        test1.QTB_CalculatedTax__c = 23.00;
        test1.QTB_Tax_Override_Amount__c =23.00;
        testTax.add(test1);
        insert  testTax;
        QTB_CreditNoteTriggerHandler.throwExplicitException = false;        
        //Test.stopTest();
        SBQQ.TriggerControl.enable();
        QTB_CRDN_Ready_for_integration_Batch obj = new QTB_CRDN_Ready_for_integration_Batch(null,null);
        Database.executeBatch(obj);	
        
        QTB_CRDN_Ready_for_integration_Batch obj2 = new QTB_CRDN_Ready_for_integration_Batch(crdtIDs,invCustomSettToUpdate);
        Database.executeBatch(obj2,1);	
        QTB_CRDN_Ready_for_integration_Batch obj1 = new QTB_CRDN_Ready_for_integration_Batch(null,null);
        obj1.execute(null, null);
        
    }
    @isTest
    static void testMethod3() {
    
    Test.startTest();
        List<Account> acc=[select id from account where ShippingCountry = 'singapore'];
        set<Id> crdtIDs=new set<Id>();
        for(blng__CreditNote__c crd:[select id From blng__CreditNote__c where blng__Account__c=:acc[0].id]){
            crdtIDs.Add(crd.id); 
        }
        system.debug('$$$$$$$$$$$$$$$$$'+crdtIDs);
        List<blng__CreditNote__c> creditNotes = [select Id,blng__Account__r.QTB_Legal_Entity_Country__c, QTB_Custom_Invoice_Number__c, QTB_Custom_Invoice_ID__c, QTB_CreditNoteRecordType__c, name, blng__Status__c, blng__Account__r.QTB_Contract_Entity__c, blng__Account__r.BillingCountry, blng__Account__r.QTB_Customer_Number__c,
        blng__Account__r.QTB_Contract_Entity__r.blng__Country__c, QTB_Transferred_To_Oracle__c, blng__Account__r.QTB_Hold_Invoice__c, blng__Account__r.BillingState, QTB_Tax_Override_Amount__c,
        blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c, QTB_Transferred_to_Invoice_Compliance__c, QTB_Purchase_Order__c,  blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
        recordTypeId, blng__Account__r.QTB_Market__r.QTB_State__c, QTB_Ready_for_Integration__c, QTB_Ready_for_Integration_Status__c From blng__CreditNote__c where blng__Status__c = 'Posted'];
        
        QTB_CRDN_Ready_for_integration_Batch obj = new QTB_CRDN_Ready_for_integration_Batch(crdtIDs,null);
        Database.executeBatch(obj,1);	
        QTB_CRDN_Ready_for_integration_Batch obj1 = new QTB_CRDN_Ready_for_integration_Batch(null,null);
        obj1.execute(null, null);
       
        Test.stopTest();
    
    }
   @isTest
    static void testMethod4() {
    
    Test.startTest();
        set<Id> crdtIDs=new set<Id>();
        for(blng__CreditNote__c crd:[select id From blng__CreditNote__c where blng__Status__c = 'Posted']){
            crdtIDs.Add(crd.id); 
        }
        system.debug('$$$$$$$$$$$$$$$$$'+crdtIDs);
        List<blng__CreditNote__c> creditNotes = [select Id,blng__Account__r.QTB_Legal_Entity_Country__c, QTB_Custom_Invoice_Number__c, QTB_Custom_Invoice_ID__c, QTB_CreditNoteRecordType__c, name, blng__Status__c, blng__Account__r.QTB_Contract_Entity__c, blng__Account__r.BillingCountry, blng__Account__r.QTB_Customer_Number__c,
        blng__Account__r.QTB_Contract_Entity__r.blng__Country__c, QTB_Transferred_To_Oracle__c, blng__Account__r.QTB_Hold_Invoice__c, blng__Account__r.BillingState, QTB_Tax_Override_Amount__c,
        blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c, QTB_Transferred_to_Invoice_Compliance__c, QTB_Purchase_Order__c,  blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
        recordTypeId, blng__Account__r.QTB_Market__r.QTB_State__c, QTB_Ready_for_Integration__c, QTB_Ready_for_Integration_Status__c From blng__CreditNote__c where blng__Status__c = 'Posted'];
        
        System.debug('>>credn'+creditNotes);
     
         List<blng__CreditNoteLine__c> lstCrdtNoteline = [select id,blng__TaxAmount__c,blng__Status__c,QTB_Tax_Override_Amount__c,
                                                                     blng__CreditNote__r.id,blng__Subtotal__c,
                                                                     blng__TaxPercentageApplied__c,blng__CreditNote__r.blng__Subtotal__c,
                                                                     blng__LegalEntity__r.Id,blng__CreditNote__r.blng__Status__c,
                                                                     blng__CreditNote__r.QTB_Transferred_to_Invoice_Compliance__c,
                                                                     blng__CreditNote__r.blng__Account__r.QTB_Legal_Entity_Country__c,
                                                                     blng__CreditNote__c,LastModifiedDate,
                                                                     blng__CreditNote__r.QTB_Custom_Invoice_Number__c,
                                                                     blng__CreditNote__r.QTB_Ready_for_Integration__c,
                                                                     blng__CreditNote__r.QTB_Ready_for_Integration_Status__c,
                                                                     blng__CreditNote__r.blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
                                                                     blng__CreditNote__r.blng__Account__r.QTB_Customer_Number__c
                                                                     from blng__CreditNoteLine__c 
                                                                     where blng__CreditNote__r.blng__Status__c = 'Posted'];
       
        QTB_CRDN_Ready_for_integration_Batch obj = new QTB_CRDN_Ready_for_integration_Batch(crdtIDs,null);
        Database.executeBatch(obj,1);
        QTB_CRDN_Ready_for_integration_Batch obj1 = new QTB_CRDN_Ready_for_integration_Batch(null,null);
        obj1.execute(null, null);
       
        Test.stopTest();
    
    } 
     //cover catch
    static testMethod void testMethod1() {

            Test.startTest();
            QTB_CRDN_Ready_for_integration_Batch.throwExplicitException = true;
            
            QTB_CRDN_Ready_for_integration_Batch obj = new QTB_CRDN_Ready_for_integration_Batch(null,null);
            obj.execute(null, null);
            QTB_CRDN_Ready_for_integration_Batch obj1 = new QTB_CRDN_Ready_for_integration_Batch(null,null);
            obj1.finish(null);
            
            QTB_CRDN_Ready_for_integration_Batch b1=new QTB_CRDN_Ready_for_integration_Batch(null,null);
            b1.execute(null, null);
            QTB_CRDN_Ready_for_integration_Batch b2=new QTB_CRDN_Ready_for_integration_Batch(null,null);
            b2.finish(null);
            Test.stopTest();
            System.assertEquals(true, QTB_CRDN_Ready_for_integration_Batch.throwExplicitException);
            //System.assertEquals(TRUE, QTB_CRDN_Ready_for_integration_Batch.throwExplicitException);
        
    }
 @isTest
    static void testMethod6() {
    Test.startTest();
      
        
        QTB_TestDataFactory.createCustomInvoiceNumber();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        List<QTB_CustomInvoiceNumber__c> customSettToUpdate=new List<QTB_CustomInvoiceNumber__c>();
        entityList.add(QTB_TestDataFactory.createLegalEntity('hong kong'));
         //custom settings
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        customSettToUpdate.add(sweCustomSettings);
        
        blng__LegalEntity__c ThailandEntity = QTB_TestDataFactory.createLegalEntity('hong kong');
        ThailandEntity.QTB_Tax_Applicability__c = 'Product Based';
        ThailandEntity.blng__Country__c = 'hong kong';
        Update ThailandEntity;
        system.debug('$$$$$$$$$$$$$$$$$'+ThailandEntity);
        
       
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Hong Kong-24th';
        accountList[0].QTB_Legal_Entity_Country__c='hong kong';
        accountList[0].QTB_Contract_Entity__c  = ThailandEntity.Id;
        //accountList[0].CurrencyIsoCode = 'USD';
        accountList[0].RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Operational Account').getRecordTypeId();
        update accountList;
        List<blng__Invoice__c> invList1 = QTB_TestDataFactory.createInvoices(
            accountList
        );
        invList1[0].blng__TaxStatus__c = QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
        invList1[0].QTB_Custom_Invoice_Number__c=null;
        invList1[0].QTB_KID__c=null;
        invList1[0].blng__InvoiceStatus__c='Posted';
        invList1[0].QTB_Bill_Cycle_Day__c ='1';
        update invList1;
        
		List<blng__Invoice__c> invList2 = QTB_TestDataFactory.createInvoices(
            accountList
        );
		
        invList2[0].blng__InvoiceStatus__c = 'Posted';
        //invList2[0].blng__InvoiceDate__c = System.today();
        invList2[0].QTB_Invoice_Type__c = 'ReBill';
        invList2[0].QTB_Rebilled__c = true;
        invList2[0].QTB_Parent_Invoice__c = invList1[0].id; 
        invList2[0].QTB_Ready_for_Integration__c = false;
        update invList2;
        
        List<blng__InvoiceLine__c> invLinesList1 = new List<blng__InvoiceLine__c>(); 
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        invoiceLine1.Name = 'prodName';
        invoiceLine1.blng__TaxCountry__c = 'Thailand';
        invoiceLine1.blng__Invoice__c = invList1[0].id;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Draft';
        invLinesList1.add(invoiceLine1);
        insert invLinesList1;
        
        list<QTB_Tax_Detail__c> testTax = new list<QTB_Tax_Detail__c>();
        QTB_Tax_Detail__c test1 = new QTB_Tax_Detail__c();
        //test1.QTB_Invoice_Line__c  = invLinesList1[0].id;
        test1.QTB_Invoice__c  = invList1[0].id;
        test1.QTB_Jurisdiction__c = 'Test1';
        test1.QTB_Imposition__c  = 'Test2';
        test1.QTB_CalculatedTax__c = 23.00;
        testTax.add(test1);
        
         //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Test Product122';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = false;
        productList.add(p1); 
        Insert productList;
        set<Id> crdtIDs=new set<Id>();
       
        
        List<blng__CreditNote__c> creditNotesList = new List<blng__CreditNote__c>();
        //Regular CreditNote
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        
        creditNote1.blng__Account__c = accountList[0].Id;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Account Creation';
        creditNote1.blng__Status__c = 'Draft';
        //creditNote1.CurrencyIsoCode = 'EUR';
        //creditNote1.QTB_Tax_Override_Amount__c =23.00;
        creditNotesList.add(creditNote1);
        System.debug('setup_creditNotesList@@'+creditNotesList);
        insert creditNotesList;
        
        blng__CreditNote__c creditNote2 = new blng__CreditNote__c();
        
        creditNote2.blng__Account__c = accountList[0].Id;
        creditNote2.blng__CreditNoteDate__c = date.today();
        creditNote2.QTB_Reason_Code__c = 'Account Creation';
        creditNote2.blng__Status__c = 'Draft';
        creditNote2.QTB_Custom_Invoice_ID__c ='INDMH0002544';
        creditNote2.QTB_Custom_Invoice_Number__c ='INDMH0002544';
        //creditNote1.CurrencyIsoCode = 'EUR';
        //creditNote1.QTB_Tax_Override_Amount__c =23.00;
        //creditNotesList.add(creditNote2);
        insert creditNote2;
        blng__CreditNoteLine__c cnl2 = new blng__CreditNoteLine__c();
        cnl2.QTB_Account__c = accountList[0].Id;
        cnl2.blng__CreditNote__c = creditNotesList[0].id;
        cnl2.QTB_Invoice__c = invList1[0].id;
        cnl2.QTB_InvoiceLine__c = invLinesList1[0].id;
        cnl2.blng__Product__c = productList[0].Id;
        cnl2.QTB_Tax_Override_Amount__c =23.00;
        cnl2.blng__Status__c = 'Draft';
        insert cnl2;
        
        creditNote2.blng__status__c ='posted';
        creditNote2.ApprovalStatus__c = 'Approved';
        SBQQ.TriggerControl.disable();
        update creditNote2;
        SBQQ.TriggerControl.enable();
        //crdtIDs.add(creditNote2.id);
        //Create CreditNoteLine for Regular CreditNote
        List<blng__CreditNoteLine__c> creditNoteLineList = new List<blng__CreditNoteLine__c>();
        blng__CreditNoteLine__c cnl1 = new blng__CreditNoteLine__c();
        cnl1.QTB_Account__c = accountList[0].Id;
        cnl1.blng__CreditNote__c = creditNotesList[0].id;
        cnl1.QTB_Invoice__c = invList1[0].id;
        cnl1.QTB_InvoiceLine__c = invLinesList1[0].id;
        cnl1.blng__Product__c = productList[0].Id;
        cnl1.QTB_Tax_Override_Amount__c =23.00;
        cnl1.blng__Status__c = 'Draft';
        //cnl1.CurrencyIsoCode = 'EUR';
        creditNoteLineList.add(cnl1);
        System.debug('setup_creditNoteLineList1@@'+creditNoteLineList);
        insert creditNoteLineList;
        System.debug('setup_creditNoteLineList2@@'+creditNoteLineList);
        
        // Create Approval Rule
        sbaa__ApprovalRule__c testRule = QTB_TestDataFactory.createApprovalRule();
        //Create Approvals
        List<sbaa__Approval__c> appList = new List<sbaa__Approval__c>();
        sbaa__Approval__c testApproval = new sbaa__Approval__c();
        testApproval.sbaa__Status__c = 'Approved';
        testApproval.sbaa__RecordField__c = 'Test1';
        testApproval.sbaa__ApprovalStep__c = 1;
        testApproval.QTB_Credit_Note__c = creditNotesList[0].Id;
        testApproval.sbaa__Rule__c = testRule.Id;
        appList.add(testApproval);
        
        Insert appList;
        
         SBQQ.TriggerControl.disable();
        //creditNotesList[0].blng__Status__c ='Posted';
         //Update Credit Note
        creditNotesList[0].ApprovalStatus__c = 'Pending';
        database.update(creditNotesList[0]);
        creditNotesList[0].ApprovalStatus__c = 'Approved';        
        creditNotesList[0].blng__Status__c = 'Posted';
        creditNotesList[0].QTB_Custom_Invoice_ID__c ='INDMH0002544';
        creditNotesList[0].QTB_Custom_Invoice_Number__c ='INDMH0002544';
        //creditNotesList[0].QTB_Commercial_Credit__c = true;
        database.update(creditNotesList[0]);
        
         SBQQ.TriggerControl.Enable();
        
        Map<id,blng__CreditNote__c> oldMapCred =  new Map<id,blng__CreditNote__c>();
        
        for(blng__CreditNote__c cred : creditNotesList)
        {
            crdtIDs.add(cred.id);
        }
        
        
		
		QTB_Tax_Detail__c test2 = new QTB_Tax_Detail__c();
        test2.QTB_Credit_Note_Line__c  = creditNoteLineList[0].id;
        test2.QTB_Jurisdiction__c = 'Test11';
        test2.QTB_Imposition__c  = 'Test22';
        test2.QTB_CalculatedTax__c = 23.00;
        testTax.add(test2);
        insert testTax;
        system.debug('testTax>>==='+testTax);        
        system.debug('++++++++++++++=='+accountList[0].QTB_Contract_Entity__c);
        
       
        QTB_CRDN_Ready_for_integration_Batch obj = new QTB_CRDN_Ready_for_integration_Batch(crdtIDs,customSettToUpdate);
        Database.executeBatch(obj);
        QTB_CRDN_Ready_for_integration_Batch obj1 = new QTB_CRDN_Ready_for_integration_Batch(crdtIDs,customSettToUpdate);
        obj.execute(null,null);
        obj.finish(null);
       
        Test.stopTest();
    
    } 
    @isTest
    static void testMethod7() {
    Test.startTest();
        QTB_TestDataFactory.createCustomInvoiceNumber();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        
        entityList.add(QTB_TestDataFactory.createLegalEntity('hong kong'));
         //custom settings
        List<QTB_CustomInvoiceNumber__c> customSettToUpdate=new List<QTB_CustomInvoiceNumber__c>();
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        customSettToUpdate.add(sweCustomSettings);
        
        blng__LegalEntity__c ThailandEntity = QTB_TestDataFactory.createLegalEntity('hong kong');
        ThailandEntity.QTB_Tax_Applicability__c = 'Product Based';
        ThailandEntity.blng__Country__c = 'hong kong';
        Update ThailandEntity;
        system.debug('$$$$$$$$$$$$$$$$$'+ThailandEntity);
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Hong Kong-24th';
        accountList[0].QTB_Legal_Entity_Country__c='Hong Kong';
        accountList[0].QTB_Contract_Entity__c  = ThailandEntity.Id;
        accountList[0].CurrencyIsoCode = 'HKD';
        accountList[0].RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Operational Account').getRecordTypeId();
        update accountList;
        List<blng__Invoice__c> invList1 = QTB_TestDataFactory.createInvoices(
            accountList
        );
        invList1[0].blng__TaxStatus__c = QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
        invList1[0].QTB_Custom_Invoice_Number__c=null;
        invList1[0].QTB_KID__c=null;
        invList1[0].blng__InvoiceStatus__c='Posted';
        invList1[0].QTB_Bill_Cycle_Day__c ='1';
        update invList1;
        
		List<blng__Invoice__c> invList2 = QTB_TestDataFactory.createInvoices(
            accountList
        );
		
        invList2[0].blng__InvoiceStatus__c = 'Posted';
        //invList2[0].blng__InvoiceDate__c = System.today();
        invList2[0].QTB_Invoice_Type__c = 'ReBill';
        invList2[0].QTB_Rebilled__c = true;
        invList2[0].QTB_Parent_Invoice__c = invList1[0].id; 
        invList2[0].QTB_Ready_for_Integration__c = false;
        update invList2;
        
        List<blng__InvoiceLine__c> invLinesList1 = new List<blng__InvoiceLine__c>(); 
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        invoiceLine1.Name = 'prodName';
        invoiceLine1.blng__TaxCountry__c = 'Hong Kong';
        invoiceLine1.blng__Invoice__c = invList1[0].id;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Draft';
        invLinesList1.add(invoiceLine1);
        insert invLinesList1;
        
        list<QTB_Tax_Detail__c> testTax = new list<QTB_Tax_Detail__c>();
        QTB_Tax_Detail__c test1 = new QTB_Tax_Detail__c();
        //test1.QTB_Invoice_Line__c  = invLinesList1[0].id;
        test1.QTB_Invoice__c  = invList1[0].id;
        test1.QTB_Jurisdiction__c = 'Test1';
        test1.QTB_Imposition__c  = 'Test2';
        test1.QTB_CalculatedTax__c = 23.00;
        testTax.add(test1);
        
         //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Test Product132';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = false;
        productList.add(p1); 
        Insert productList;
        set<Id> crdtIDs=new set<Id>();
       
        
        List<blng__CreditNote__c> creditNotesList = new List<blng__CreditNote__c>();
        //Regular CreditNote
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        
        creditNote1.blng__Account__c = accountList[0].Id;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Account Creation';
        creditNote1.blng__Status__c = 'Draft';
        //creditNote1.CurrencyIsoCode = 'EUR';
        creditNote1.QTB_Tax_Override_Amount__c =23.00;
        creditNotesList.add(creditNote1);
        System.debug('setup_creditNotesList@@'+creditNotesList);
        insert creditNotesList;
        
        //Create CreditNoteLine for Regular CreditNote
        List<blng__CreditNoteLine__c> creditNoteLineList = new List<blng__CreditNoteLine__c>();
        blng__CreditNoteLine__c cnl1 = new blng__CreditNoteLine__c();
        cnl1.QTB_Account__c = accountList[0].Id;
        cnl1.blng__CreditNote__c = creditNotesList[0].id;
        cnl1.QTB_Invoice__c = invList1[0].id;
        cnl1.QTB_InvoiceLine__c = invLinesList1[0].id;
        cnl1.blng__Product__c = productList[0].Id;
        cnl1.blng__Status__c = 'Draft';
        //cnl1.CurrencyIsoCode = 'EUR';
        creditNoteLineList.add(cnl1);
        System.debug('setup_creditNoteLineList1@@'+creditNoteLineList);
        insert creditNoteLineList;
        System.debug('setup_creditNoteLineList2@@'+creditNoteLineList);
        
        // Create Approval Rule
        sbaa__ApprovalRule__c testRule = QTB_TestDataFactory.createApprovalRule();
        //Create Approvals
        List<sbaa__Approval__c> appList = new List<sbaa__Approval__c>();
        sbaa__Approval__c testApproval = new sbaa__Approval__c();
        testApproval.sbaa__Status__c = 'Approved';
        testApproval.sbaa__RecordField__c = 'Test1';
        testApproval.sbaa__ApprovalStep__c = 1;
        testApproval.QTB_Credit_Note__c = creditNotesList[0].Id;
        testApproval.sbaa__Rule__c = testRule.Id;
        appList.add(testApproval);
        
        Insert appList;
        
         SBQQ.TriggerControl.disable();
        //creditNotesList[0].blng__Status__c ='Posted';
         //Update Credit Note
        creditNotesList[0].ApprovalStatus__c = 'Pending';
        //database.update(creditNotesList[0]);
        creditNotesList[0].ApprovalStatus__c = 'Approved';        
        creditNotesList[0].blng__Status__c = 'Posted';
        //creditNotesList[0].QTB_Commercial_Credit__c = true;
        
            //database.update(creditNotesList);
        creditNoteLineList[0].blng__Status__c='Posted';
        
        update creditNoteLineList;
        
        
         SBQQ.TriggerControl.Enable();
        
        Map<id,blng__CreditNote__c> oldMapCred =  new Map<id,blng__CreditNote__c>();
        
        for(blng__CreditNote__c cred : creditNotesList)
        {
            crdtIDs.add(cred.id);
        }
        
        
		
		QTB_Tax_Detail__c test2 = new QTB_Tax_Detail__c();
        test2.QTB_Credit_Note_Line__c  = creditNoteLineList[0].id;
        test2.QTB_Jurisdiction__c = 'Test11';
        test2.QTB_Imposition__c  = 'Test22';
        test2.QTB_CalculatedTax__c = 23.00;
        testTax.add(test2);
        insert testTax;
        system.debug('testTax>>==='+testTax);        
        system.debug('++++++++++++++=='+accountList[0].QTB_Contract_Entity__c);
        
       
        QTB_CRDN_Ready_for_integration_Batch obj = new QTB_CRDN_Ready_for_integration_Batch(crdtIDs,customSettToUpdate);
        Database.executeBatch(obj);
        QTB_CRDN_Ready_for_integration_Batch obj1 = new QTB_CRDN_Ready_for_integration_Batch(crdtIDs,customSettToUpdate);
        obj.execute(null,null);
        obj.finish(null);
       
        Test.stopTest();
    
    } 
    @isTest
    static void testMethod8() {
    Test.startTest();
        QTB_TestDataFactory.createCustomInvoiceNumber();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        
        entityList.add(QTB_TestDataFactory.createLegalEntity('hong kong'));
         //custom settings
        List<QTB_CustomInvoiceNumber__c> customSettToUpdate=new List<QTB_CustomInvoiceNumber__c>();
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        customSettToUpdate.add(sweCustomSettings);
        blng__LegalEntity__c ThailandEntity = QTB_TestDataFactory.createLegalEntity('hong kong');
        ThailandEntity.QTB_Tax_Applicability__c = 'Product Based';
        ThailandEntity.blng__Country__c = 'hong kong';
        Update ThailandEntity;
        system.debug('$$$$$$$$$$$$$$$$$'+ThailandEntity);
       
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Hong Kong-24th';
        accountList[0].QTB_Legal_Entity_Country__c='hong kong';
        accountList[0].QTB_Contract_Entity__c  = ThailandEntity.Id;
        //accountList[0].CurrencyIsoCode = 'USD';
        accountList[0].RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Operational Account').getRecordTypeId();
        update accountList;
        List<blng__Invoice__c> invList1 = QTB_TestDataFactory.createInvoices(
            accountList
        );
        invList1[0].blng__TaxStatus__c = QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
        invList1[0].QTB_Custom_Invoice_Number__c=null;
        invList1[0].QTB_KID__c=null;
        invList1[0].blng__InvoiceStatus__c='Posted';
        invList1[0].QTB_Bill_Cycle_Day__c ='1';
        update invList1;
        
		List<blng__Invoice__c> invList2 = QTB_TestDataFactory.createInvoices(
            accountList
        );
		
        invList2[0].blng__InvoiceStatus__c = 'Posted';
        //invList2[0].blng__InvoiceDate__c = System.today();
        invList2[0].QTB_Invoice_Type__c = 'ReBill';
        invList2[0].QTB_Rebilled__c = true;
        invList2[0].QTB_Parent_Invoice__c = invList1[0].id; 
        invList2[0].QTB_Ready_for_Integration__c = false;
        update invList2;
        
        List<blng__InvoiceLine__c> invLinesList1 = new List<blng__InvoiceLine__c>(); 
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        invoiceLine1.Name = 'prodName';
        invoiceLine1.blng__TaxCountry__c = 'Thailand';
        invoiceLine1.blng__Invoice__c = invList1[0].id;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Draft';
        invLinesList1.add(invoiceLine1);
        insert invLinesList1;
        
        list<QTB_Tax_Detail__c> testTax = new list<QTB_Tax_Detail__c>();
        QTB_Tax_Detail__c test1 = new QTB_Tax_Detail__c();
        //test1.QTB_Invoice_Line__c  = invLinesList1[0].id;
        test1.QTB_Invoice__c  = invList1[0].id;
        test1.QTB_Jurisdiction__c = 'Test1';
        test1.QTB_Imposition__c  = 'Test2';
        test1.QTB_CalculatedTax__c = 23.00;
        testTax.add(test1);
        
         //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Test Product142';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = false;
        productList.add(p1); 
        Insert productList;
        set<Id> crdtIDs=new set<Id>();
       
        
        List<blng__CreditNote__c> creditNotesList = new List<blng__CreditNote__c>();
        //Regular CreditNote
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        
        creditNote1.blng__Account__c = accountList[0].Id;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Account Creation';
        creditNote1.blng__Status__c = 'Draft';
        //creditNote1.CurrencyIsoCode = 'EUR';
        creditNote1.QTB_Tax_Override_Amount__c =23.00;
        creditNotesList.add(creditNote1);
        System.debug('setup_creditNotesList@@'+creditNotesList);
        insert creditNotesList;
         QTB_Tax_Detail__c test2 = new QTB_Tax_Detail__c();
        //test1.QTB_Invoice_Line__c  = invLinesList1[0].id;
        test2.QTB_credit_Note__c  = creditNotesList[0].id;
        test2.QTB_Jurisdiction__c = 'Test1';
        test2.QTB_Imposition__c  = 'Test2';
        test2.QTB_CalculatedTax__c = 23.00;
        Insert test2;
        //Create CreditNoteLine for Regular CreditNote
        List<blng__CreditNoteLine__c> creditNoteLineList = new List<blng__CreditNoteLine__c>();
        blng__CreditNoteLine__c cnl1 = new blng__CreditNoteLine__c();
        cnl1.QTB_Account__c = accountList[0].Id;
        cnl1.blng__CreditNote__c = creditNotesList[0].id;
        cnl1.QTB_Invoice__c = invList1[0].id;
        cnl1.QTB_InvoiceLine__c = invLinesList1[0].id;
        cnl1.blng__Product__c = productList[0].Id;
        cnl1.blng__Status__c = 'Draft';
        //cnl1.CurrencyIsoCode = 'EUR';
        creditNoteLineList.add(cnl1);
        System.debug('setup_creditNoteLineList1@@'+creditNoteLineList);
        insert creditNoteLineList;
        System.debug('setup_creditNoteLineList2@@'+creditNoteLineList);
        
        // Create Approval Rule
        sbaa__ApprovalRule__c testRule = QTB_TestDataFactory.createApprovalRule();
        //Create Approvals
        List<sbaa__Approval__c> appList = new List<sbaa__Approval__c>();
        sbaa__Approval__c testApproval = new sbaa__Approval__c();
        testApproval.sbaa__Status__c = 'Approved';
        testApproval.sbaa__RecordField__c = 'Test1';
        testApproval.sbaa__ApprovalStep__c = 1;
        testApproval.QTB_Credit_Note__c = creditNotesList[0].Id;
        testApproval.sbaa__Rule__c = testRule.Id;
        appList.add(testApproval);
        
        Insert appList;
        
         SBQQ.TriggerControl.disable();
        //creditNotesList[0].blng__Status__c ='Posted';
         //Update Credit Note
        creditNotesList[0].ApprovalStatus__c = 'Pending';
        database.update(creditNotesList[0]);
        creditNotesList[0].ApprovalStatus__c = 'Approved';        
        creditNotesList[0].blng__Status__c = 'Posted';
        //creditNotesList[0].QTB_Commercial_Credit__c = true;
        
        
        database.update(creditNotesList[0]);
        creditNoteLineList[0].blng__Status__c ='Posted';
        database.update(creditNoteLineList[0]);
        
         SBQQ.TriggerControl.Enable();
        
        Map<id,blng__CreditNote__c> oldMapCred =  new Map<id,blng__CreditNote__c>();
        
        QTB_Tax_Detail__c test3 = new QTB_Tax_Detail__c();
        test3.QTB_Credit_Note__c  = creditNotesList[0].id;
        test3.QTB_Jurisdiction__c = 'Test11';
        test3.QTB_Imposition__c  = 'Test22';
        test3.QTB_CalculatedTax__c = 23.00;
        test3.QTB_Tax_Override_Amount__c =23.00;
        testTax.add(test3);
        insert testTax;
        
        for(blng__CreditNote__c cred : creditNotesList)
        {
            crdtIDs.add(cred.id);
        }
        
        SBQQ.TriggerControl.disable();
		creditNotesList[0].blng__Status__c = 'Draft';
        database.update(creditNotesList[0]);
        SBQQ.TriggerControl.Enable();
		
        system.debug('testTax>>==='+testTax);        
        system.debug('++++++++++++++=='+accountList[0].QTB_Contract_Entity__c);
        
       
        QTB_CRDN_Ready_for_integration_Batch obj = new QTB_CRDN_Ready_for_integration_Batch(crdtIDs,customSettToUpdate);
        Database.executeBatch(obj);
        QTB_CRDN_Ready_for_integration_Batch obj1 = new QTB_CRDN_Ready_for_integration_Batch(crdtIDs,customSettToUpdate);
        obj.execute(null,null);
        obj.finish(null);
       
        Test.stopTest();
    
    }
	 @isTest
    static void testMethod9() {
    Test.startTest();
       QTB_TestDataFactory.createCustomInvoiceNumber();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        
        entityList.add(QTB_TestDataFactory.createLegalEntity('hong kong'));
         //custom settings
        List<QTB_CustomInvoiceNumber__c> customSettToUpdate=new List<QTB_CustomInvoiceNumber__c>();
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        customSettToUpdate.add(sweCustomSettings);
        
        blng__LegalEntity__c ThailandEntity = QTB_TestDataFactory.createLegalEntity('hong kong');
        ThailandEntity.QTB_Tax_Applicability__c = 'Product Based';
        ThailandEntity.blng__Country__c = 'hong kong';
        Update ThailandEntity;
        system.debug('$$$$$$$$$$$$$$$$$'+ThailandEntity);
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Hong Kong-24th';
        accountList[0].QTB_Legal_Entity_Country__c='Hong Kong';
        accountList[0].QTB_Contract_Entity__c  = ThailandEntity.Id;
        accountList[0].CurrencyIsoCode = 'HKD';
        accountList[0].RecordTypeId = Schema.sObjectType.Account.getRecordTypeInfosByName().get('Operational Account').getRecordTypeId();
        update accountList;
        List<blng__Invoice__c> invList1 = QTB_TestDataFactory.createInvoices(
            accountList
        );
        invList1[0].blng__TaxStatus__c = QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
        invList1[0].QTB_Custom_Invoice_Number__c=null;
        invList1[0].QTB_KID__c=null;
        invList1[0].blng__InvoiceStatus__c='Posted';
        invList1[0].QTB_Bill_Cycle_Day__c ='1';
        update invList1;
        
		List<blng__Invoice__c> invList2 = QTB_TestDataFactory.createInvoices(
            accountList
        );
		
        invList2[0].blng__InvoiceStatus__c = 'Posted';
        //invList2[0].blng__InvoiceDate__c = System.today();
        invList2[0].QTB_Invoice_Type__c = 'ReBill';
        invList2[0].QTB_Rebilled__c = true;
        invList2[0].QTB_Parent_Invoice__c = invList1[0].id; 
        invList2[0].QTB_Ready_for_Integration__c = false;
        update invList2;
        
        List<blng__InvoiceLine__c> invLinesList1 = new List<blng__InvoiceLine__c>(); 
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        invoiceLine1.Name = 'prodName';
        invoiceLine1.blng__TaxCountry__c = 'Hong Kong';
        invoiceLine1.blng__Invoice__c = invList1[0].id;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Draft';
        invLinesList1.add(invoiceLine1);
        insert invLinesList1;
        
        list<QTB_Tax_Detail__c> testTax = new list<QTB_Tax_Detail__c>();
        QTB_Tax_Detail__c test1 = new QTB_Tax_Detail__c();
        //test1.QTB_Invoice_Line__c  = invLinesList1[0].id;
        test1.QTB_Invoice__c  = invList1[0].id;
        test1.QTB_Jurisdiction__c = 'Test1';
        test1.QTB_Imposition__c  = 'Test2';
        test1.QTB_CalculatedTax__c = 23.00;
        testTax.add(test1);
        
         //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Test Product132';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = false;
        productList.add(p1); 
        Insert productList;
        set<Id> crdtIDs=new set<Id>();
       
        
        List<blng__CreditNote__c> creditNotesList = new List<blng__CreditNote__c>();
        //Regular CreditNote
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        
        creditNote1.blng__Account__c = accountList[0].Id;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Account Creation';
        creditNote1.blng__Status__c = 'Draft';
        //creditNote1.CurrencyIsoCode = 'EUR';
        creditNote1.QTB_Tax_Override_Amount__c =23.00;
        creditNotesList.add(creditNote1);
        System.debug('setup_creditNotesList@@'+creditNotesList);
        insert creditNotesList;
        
        //Create CreditNoteLine for Regular CreditNote
        List<blng__CreditNoteLine__c> creditNoteLineList = new List<blng__CreditNoteLine__c>();
        blng__CreditNoteLine__c cnl1 = new blng__CreditNoteLine__c();
        cnl1.QTB_Account__c = accountList[0].Id;
        cnl1.blng__CreditNote__c = creditNotesList[0].id;
        cnl1.QTB_Invoice__c = invList1[0].id;
        cnl1.QTB_InvoiceLine__c = invLinesList1[0].id;
        cnl1.blng__Product__c = productList[0].Id;
        cnl1.blng__Status__c = 'Draft';
        //cnl1.CurrencyIsoCode = 'EUR';
        creditNoteLineList.add(cnl1);
        System.debug('setup_creditNoteLineList1@@'+creditNoteLineList);
        insert creditNoteLineList;
        System.debug('setup_creditNoteLineList2@@'+creditNoteLineList);
        
        // Create Approval Rule
        sbaa__ApprovalRule__c testRule = QTB_TestDataFactory.createApprovalRule();
        //Create Approvals
        List<sbaa__Approval__c> appList = new List<sbaa__Approval__c>();
        sbaa__Approval__c testApproval = new sbaa__Approval__c();
        testApproval.sbaa__Status__c = 'Approved';
        testApproval.sbaa__RecordField__c = 'Test1';
        testApproval.sbaa__ApprovalStep__c = 1;
        testApproval.QTB_Credit_Note__c = creditNotesList[0].Id;
        testApproval.sbaa__Rule__c = testRule.Id;
        appList.add(testApproval);
        
        Insert appList;
        
         SBQQ.TriggerControl.disable();
        //creditNotesList[0].blng__Status__c ='Posted';
         //Update Credit Note
        creditNotesList[0].ApprovalStatus__c = 'Pending';
        //database.update(creditNotesList[0]);
        creditNotesList[0].ApprovalStatus__c = 'Approved';        
        creditNotesList[0].blng__Status__c = 'Posted';
        //creditNotesList[0].QTB_Commercial_Credit__c = true;
        
            //database.update(creditNotesList);
        creditNoteLineList[0].blng__Status__c='Posted';
        
        update creditNoteLineList;
        
        
         SBQQ.TriggerControl.Enable();
        
        Map<id,blng__CreditNote__c> oldMapCred =  new Map<id,blng__CreditNote__c>();
        
        for(blng__CreditNote__c cred : creditNotesList)
        {
            crdtIDs.add(cred.id);
        }
        
        QTB_Tax_Detail__c test2 = new QTB_Tax_Detail__c();
        test2.QTB_Credit_Note_Line__c  = creditNoteLineList[0].id;
        test2.QTB_Jurisdiction__c = 'Test11';
        test2.QTB_Imposition__c  = 'Test22';
        test2.QTB_CalculatedTax__c = 23.00;
        testTax.add(test2);
        insert testTax;
        system.debug('testTax>>==='+testTax);        
        system.debug('++++++++++++++=='+accountList[0].QTB_Contract_Entity__c);
        
       
        QTB_CRDN_Ready_for_integration_Batch obj = new QTB_CRDN_Ready_for_integration_Batch(crdtIDs,customSettToUpdate);
        Database.executeBatch(obj);
        QTB_CRDN_Ready_for_integration_Batch obj1 = new QTB_CRDN_Ready_for_integration_Batch(crdtIDs,customSettToUpdate);
        obj.execute(null,null);
        obj.finish(null);
       
        Test.stopTest();
    
    } 
}