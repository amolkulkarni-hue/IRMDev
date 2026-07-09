/*****************************************************************************************************
* Class: QTB_CreditNoteHelper_Test
* Author: Accenture
* Purpose: Test Class for QTB_CreditNoteHelper
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture   5/4/2020
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_CreditNoteHelper_Test { 
    
    @testSetup
    static void setup() {
        
       Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
      custSetting.SObject_API_Name__c = 'QTB_Bill_Flow_Controller__c;QTB_PurchaseOrder__c;SBQQ__Quote__c;blng__Invoice__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__InvoiceScheduler__c';
      custSetting.Disable_VR__c = true;
      custSetting.Disable_PB__c = true;
      custSetting.Disable_Trigger__c = true;
      // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      insert custSetting;
        QTB_Account_Level_Credit_Note_Setting__mdt accMdt=[select id,Label, NamespacePrefix, QTB_Acc_LegalEntityCntry__c from QTB_Account_Level_Credit_Note_Setting__mdt where Label='US_SITAD' limit 1];
        
        Id pricebookId = Test.getStandardPricebookId();
        
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        
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
        
         QTB_Bill_Code_Product_Lookup__c productLookup = new QTB_Bill_Code_Product_Lookup__c(
            QTB_Source_Bill_Code__c = 'VALID_CODE',
            QTB_Country__c = country.Id,
            QTB_Product2__c = productList[0].id
        );
        insert productLookup;
        
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
        
        //Standard Account
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
            2,
            'Standard Account'
        );

        
        //Billing Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c='United States';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        accountList[0].ShippingCity = 'New York';
        accountList[0].ShippingState = 'New York';
        accountList[0].ShippingPostalCode = '22131';
        accountList[0].ShippingCountry = 'United States';
        accountList[0].SBQQ__TaxExempt__c = 'Yes';
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
        
        /*//opportunity
          List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        database.update(oppList);*/
        List<Opportunity> oppList = new List<Opportunity>();
        
        for (Integer i = 0; i < testAccounts.size(); i++) {
            Opportunity newOpp = new Opportunity(
                Name = 'Test ' + (i + 1),
                AccountId = testAccounts[i].Id,
                CloseDate = Date.today(),
                StageName = '1 - Qualification',
                RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID,
                Amount = 500,
                Pricebook2Id = pricebookId
            );            
            oppList.add(newOpp);
        }
        
        if (!oppList.isEmpty()) {
            insert oppList; // insert oop
        }
        
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
        QTB_OrderTriggerHandler orderHandler = new QTB_OrderTriggerHandler();
        orderHandler.IsDisabled();
        database.update(orderList);
        
        //OrderItem
        List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,productList[0].Id,quoteLinesList,standardPrice1);
        
        Test.startTest();
        
        //Invoice
        List<blng__Invoice__c> invoiceListForCredit = QTB_TestDataFactory.createInvoices(accountList);
        
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
        usagesummary1.blng__Invoice__c = invoiceListForCredit[0].id;
        database.update(usagesummary1);        
        
        //Usage1 for CreditNote
        List<blng__Usage__c> usageList1 = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary1);
        usageList1[0].QTB_System_Generated__c = true;
        usageList1[0].blng__PreratedAmount__c = 100;
        usageList1[0].blng__PreratedQuantity__c = 10;
        usageList1[0].QTB_Service_District__c = '44147';
        usageList1[0].blng__Subtotal__c = 50;
        usageList1[0].blng__OrderProduct__c = orderItemList[0].id; 
        usageList1[0].QTB_Product_Identifier_1__c =  productLookup.id;
        database.update(usageList1);    
        
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
        
        //Invoice Run
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        
        //Update Invoice
        invoiceListForCredit[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceListForCredit[0].blng__InvoiceStatus__c = 'Posted';       
        invoiceListForCredit[0].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        invoiceListForCredit[0].QTB_ReBill_Status__c = 'Usage Completed';
       invoiceListForCredit[0].QTB_Internal_PO_Notes__c='Testing';
        update invoiceListForCredit[0];
        System.debug('setup_invoiceListForCredit@@'+invoiceListForCredit);
        
        //Rebill Invoice
        List<blng__Invoice__c> rebillInvoiceList = QTB_TestDataFactory.createInvoices(accountList);
        rebillInvoiceList[0].QTB_Parent_Invoice__c = invoiceListForCredit[0].id;
        rebillInvoiceList[0].blng__InvoiceDate__c = Date.valueOf('2023-05-27');
        rebillInvoiceList[0].blng__InvoiceStatus__c = 'Draft';        
        update rebillInvoiceList;
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
        List<blng__InvoiceLine__c> invLineListForCredit = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
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
        po.QTB_Service_Type__c = 'Mixed';        
        insert PO;
        
        //Regular CreditNote
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        creditNote1.blng__Account__c = accountList[0].Id;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Account Creation';
        creditNote1.blng__Status__c = 'Draft';
        creditNote1.CurrencyIsoCode = 'EUR';
        creditNote1.blng__RelatedInvoice__c = invoiceListForCredit[0].Id;
        creditNote1.QTB_Rebill_Invoice__c = rebillInvoiceList[0].Id;
        creditNote1.QTB_Purchase_Order__c =PO.id;
        creditNote1.QTB_On_Account_Credit__c = false;
        
        creditNote1.QTB_Credit_Note_Type__c = 'Credit Only';
        creditNote1.QTB_CreditNote_Posted_Date__c = null;
        creditNote1.QTB_Purchase_Order__c = null;
        creditNote1.QTB_Internal_PO_Notes__c = 'tetda';
        creditNotesList.add(creditNote1);
        System.debug('setup_creditNotesList@@'+creditNotesList);
        
        custSetting.SObject_API_Name__c = 'SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__CreditNote__c';
        update custSetting;
        insert creditNotesList;
        custSetting.SObject_API_Name__c = 'SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNoteLine__c';
        update custSetting;
        

       
        
        //Create CreditNoteLine for Regular CreditNote
        List<blng__CreditNoteLine__c> creditNoteLineList = new List<blng__CreditNoteLine__c>();
        blng__CreditNoteLine__c cnl1 = new blng__CreditNoteLine__c();
        cnl1.QTB_Account__c = accountList[0].Id;
        cnl1.blng__CreditNote__c = creditNotesList[0].id;
        cnl1.QTB_Invoice__c = invoiceListForCredit[0].id;
        cnl1.QTB_InvoiceLine__c = invLineListForCredit[0].id;
        cnl1.blng__Product__c = productList[0].Id;
        cnl1.blng__TaxTreatment__c = blngTax.Id;
        cnl1.blng__Status__c = 'Cancelled';
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
        
        //Update Credit Note
        //creditNotesList[0].ApprovalStatus__c = 'Rejected';
        //database.update(creditNotesList[0]);
        
        //Update Credit Note
        creditNotesList[0].ApprovalStatus__c = 'Approved';        
        creditNotesList[0].blng__Status__c = 'Posted';
        database.update(creditNotesList[0]);
        QTB_CreditNoteTriggerHandler.throwExplicitException = false;        
        Test.stopTest();
        SBQQ.TriggerControl.enable();
    }
    
    @isTest
    static void testMethod1() {
        Test.startTest();
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        QTB_CreditNoteTriggerHandler.throwExplicitException = true;
        QTB_CreditNoteTriggerHandler handler = new QTB_CreditNoteTriggerHandler();
        handler.BeforeDelete(null);
        handler.AfterDelete(null);
        handler.AfterUndelete(null);
        handler.isDisabled();
        handler.bypass();
        try {
            QTB_CreditNoteHelper.notifyAdditionalRecipientsOnApprovalSubmission(
                null,
                null
            );
        } catch (Exception e) {
            
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        try {
            QTB_CreditNoteHelper.setApprovers(null);
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        try {
            QTB_CreditNoteHelper.getApproverIds(null);
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        
     /*   try {
            QTB_CreditNoteHelper.onAccountCreditNote(null,null,null);
           
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        } */
        
        System.assertEquals(
            true,
            QTB_CreditNoteTriggerHandler.throwExplicitException
        );
        try {
            QTB_CreditNoteHelper.creditReBill(null,null,null,null);
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        /*QTB_CreditNoteTriggerHandler.throwExplicitException = false;
        try {
            QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass = false;
            QTB_CreditNoteHelper.creditReBill(null,null,'Update',null);
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }*/
        Test.stopTest();
    }
    
    @isTest
    static void testMethod2(){
        system.debug('*************==============');
      /*  List<Account> AccsList = [Select id,name from Account] ;
        set<id> accId = new set<id>();
        if(AccsList.size()>0){
           for(Account acs :AccsList)
        {
            accId.add(acs.id);
        } 
        } */
        Test.startTest();
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        
        List<blng__CreditNoteLine__c> finalCreditNoteLineList = new List<blng__CreditNoteLine__c>();
        List<blng__CreditNote__c> finalCreditNoteList = new List<blng__CreditNote__c>();
        Map<Id, blng__CreditNote__c> mapOfNewCreditNotes = new Map<Id, blng__CreditNote__c>();
        Map<Id, blng__CreditNote__c> mapOfOldCreditNotes = new Map<Id, blng__CreditNote__c>();
        List<blng__CreditNoteLine__c> ListCredirLines = [Select Id, blng__Subtotal__c,blng__TaxTreatment__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c from blng__CreditNoteLine__c ];
       
        for(blng__CreditNoteLine__c cnl : ListCredirLines){
            blng__CreditNoteLine__c crdline = new blng__CreditNoteLine__c();
            crdline.Id = cnl.Id;
            crdline.blng__Subtotal__c = 10;
            finalCreditNoteLineList.add(crdline);
        }
        // database.update(finalCreditNoteLineList);
        
      List <Account> AccList = [Select id,QTB_Data_Management__c,QTB_Records_Management__c,QTB_scan__c,QTB_shred__c,QTB_SITAD__c  from Account where ShippingCountry = 'United States'];
        system.debug('*************'+AccList);
        Set<Id> AccountId = new Set<Id> ();
        if(AccList.size()>0){
            for ( Account Accs : AccList)
            {
                AccountId.add(Accs.Id);
            }
        } 
        List<blng__CreditNote__c> creditNotes = [Select ID, Name, QTB_Country__c,QTB_IsReBill__c,blng__EffectiveTaxDate__c,blng__Status__c,blng__Account__c from blng__CreditNote__c where blng__Account__c =:AccList[0].id and blng__Status__c = 'Posted'];
        for(blng__CreditNote__c cn :creditNotes ){
            cn.blng__Notes__c = 'test';        
            finalCreditNoteList.add(cn);
            mapOfOldCreditNotes.put(cn.id,cn);
        }
        //update finalCreditNoteList;
        
        for(blng__CreditNote__c cn :finalCreditNoteList){
            mapOfNewCreditNotes.put(cn.id,cn);
        }
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        
        Set<String> setOfUserIdOrCountires = new  Set<String>();
        setOfUserIdOrCountires.add('United States');
        setOfUserIdOrCountires.add('India');
        setOfUserIdOrCountires.add('Canada');
        setOfUserIdOrCountires.add(userList[0].id);
        Map<String, Id> abc = QTB_CreditNoteHelper.getApproverIds(setOfUserIdOrCountires);
        QTB_CreditNoteHelper.CN_CheckRestrictedFields(finalCreditNoteList,mapOfOldCreditNotes, 'blng__EffectiveTaxDate__c');
        
        QTB_CreditNoteHelper.onAccountCreditNote(null,finalCreditNoteList,mapOfOldCreditNotes);
        //Cover All Exception
        QTB_CreditNoteTriggerHandler.throwExplicitException = true;
        try{
            QTB_CreditNoteHelper.process(null,null,null,null);    
            //QTB_CreditNoteHelper.CN_AutoUpdatePOBalance(null);
        }Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        try{
            QTB_CreditNoteHelper.getApproverIds(null);
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        try{
            QTB_CreditNoteHelper.setApprovers(null);
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        try{
            QTB_CreditNoteHelper.notifyAdditionalRecipientsOnApprovalSubmission(null,null);
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        try{
            QTB_CreditNoteHelper.autoUpdatePO(finalCreditNoteList);
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        try{
            QTB_CreditNoteHelper.creditReBill(null,null,null,null);
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }        
        try{
            QTB_CreditNoteHelper.CN_AutoUpdatePOBalance(finalCreditNoteList,mapOfOldCreditNotes);
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        try{
            //QTB_CreditNoteHelper.buildTaxRateMap();
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        try{
            //QTB_CreditNoteHelper.calculateTax(null); 
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        try{
            QTB_CreditNoteHelper.CN_ParentBillingAccount(null); 
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        try{
            QTB_CreditNoteHelper.CN_CheckRestrictedFields(null,null,'RecordTypeId'); 
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        try{
           QTB_CreditNoteHelper.onAccountCreditNote(AccountId,finalCreditNoteList,mapOfOldCreditNotes);
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        try{
            QTB_CreditNoteHelper.onAccountCreditNote(AccountId,finalCreditNoteList,null);
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        Test.stopTest();
    }
    
    @isTest
    static void testMethod3() {
        Test.startTest();
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        
        List<blng__CreditNote__c> creditNotes = [Select ID, Name, QTB_Country__c,blng__RelatedInvoice__c,QTB_ReBill_Credit_Amount__c,
                                                 QTB_IsReBill__c from blng__CreditNote__c where QTB_Country__c = '' limit 1];
        QTB_CreditNoteHelper.setApprovers(creditNotes);
        Test.stopTest();
    }
    
    @isTest
    static void testMethod4() {
        Test.startTest();
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
            1,
            'Billing Account'
        );
        
         //Legal Entity
        blng__LegalEntity__c singaporeEntity = new blng__LegalEntity__c();
        singaporeEntity.Name = 'Test Legal Entity Singapore';
        singaporeEntity.blng__Active__c = true;
        singaporeEntity.blng__Country__c = 'Singapore';
        singaporeEntity.QTB_Type__c = 'Contract';
        singaporeEntity.QTB_Legal_Entity_Number__c = 45409;
        insert singaporeEntity; 
        
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
        singaporeFinancePeriod.blng__LegalEntity__c = singaporeEntity.id;
        singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert singaporeFinancePeriod;
        
        blng__LegalEntity__c USEntity= QTB_TestDataFactory.createLegalEntity('Singapore');
        testaccounts[0].QTB_Legal_Entity_Country__c='Singapore';
        testaccounts[0].SBQQ__TaxExempt__c = 'No';
        update testAccounts;
        List<product2> product = QTB_TestDataFactory.createProducts(1);  
        Group groupinfo = [SELECT id FROM Group WHERE Name = 'QTB VP India'  LIMIT 1  ];
        
        sbaa__Approver__c testApp1 = QTB_TestDataFactory.createApprover();
        testApp1.sbaa__User__c = UserInfo.getUserId();
        
        sbaa__Approver__c testApp2 = QTB_TestDataFactory.createApprover();
        testApp2.sbaa__GroupId__c = groupinfo.id;
        testApp2.QTB_Approver_Country__c = 'Singapore';
        testApp2.QTB_Approver_Level__c = 'VP';
        
        sbaa__Approver__c testApp3 = QTB_TestDataFactory.createApprover();
        testApp3.sbaa__GroupId__c = groupinfo.id;
        testApp3.QTB_Approver_Country__c = 'Singapore';
        testApp3.QTB_Approver_Level__c = 'SVP';
        
        sbaa__Approver__c testApp4 = QTB_TestDataFactory.createApprover();
        testApp4.sbaa__GroupId__c = groupinfo.id;
        testApp4.QTB_Approver_Country__c = 'Singapore';
        testApp4.QTB_Approver_Level__c = 'EVP';
        
        sbaa__Approver__c testApp5 = QTB_TestDataFactory.createApprover();
        testApp5.sbaa__GroupId__c = groupinfo.id;
        testApp5.QTB_Approver_Country__c = 'Singapore';
        testApp5.QTB_Approver_Level__c = 'CFO';
        
        update new List<sbaa__Approver__c>{ testApp1, testApp2,testApp3,testApp4,testApp5 };
            
            //Parent Invoice  
          List<blng__Invoice__c> parentInvoiceList = QTB_TestDataFactory.createInvoices(testAccounts);            
        parentInvoiceList[0].QTB_ReBill_Status__c = 'Usage Completed';
        parentInvoiceList[0].blng__InvoiceStatus__c = 'Posted';    
        update parentInvoiceList;
        
        //Rebill Invoice
        List<blng__Invoice__c> rebillInvoiceList = QTB_TestDataFactory.createInvoices(testAccounts);
        rebillInvoiceList[0].QTB_Parent_Invoice__c = parentInvoiceList[0].id;
        rebillInvoiceList[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        rebillInvoiceList[0].blng__InvoiceStatus__c = 'Draft';        
        update rebillInvoiceList;
        
        //Rebill Invoice Lines
        List<blng__InvoiceLine__c> invoiceLineList = QTB_TestDataFactory.createInvoiceLine(3,rebillInvoiceList,product);
        
        //Invoice Schedular
       /* blng__InvoiceScheduler__c invSch = new blng__InvoiceScheduler__c();
        invSch.Name = 'Test123456789';
        invSch.blng__Type__c = 'Once';
        invSch.blng__InvoiceBatches__c = 'Rebill Run';
        invSch.CurrencyIsoCode = 'USD';
        invSch.blng__StartDateTime__c = System.now()+100;
        invSch.blng__InvoiceDate__c = system.today();
        invSch.blng__TargetDate__c = system.today();
        invSch.QTB_Parent_Invoice__c = parentInvoiceList[0].id;
        invSch.QTB_Invoice_Period__c =singaporeFinancePeriod.id;
        insert invSch; */
        
        blng__InvoiceScheduler__c singaporeSchedule = new blng__InvoiceScheduler__c();
        singaporeSchedule.Name = 'test for Singapore';
        singaporeSchedule.blng__Type__c = 'Once';
        singaporeSchedule.blng__InvoiceBatches__c = 'Singapore-1st';
        singaporeSchedule.CurrencyIsoCode = 'SGD';
        singaporeSchedule.blng__StartDateTime__c = System.today().adddays(2);
        singaporeSchedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        singaporeSchedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
        singaporeSchedule.QTB_Legal_Entity__c  = singaporeEntity.id;
        singaporeSchedule.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
        insert singaporeSchedule;
        
        //Invoice Run
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.blng__InvoiceScheduler__c = singaporeSchedule.id;
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        
        //Bill Flow Controller
        QTB_Bill_Flow_Controller__c bfc = new QTB_Bill_Flow_Controller__c();
        bfc.Name = 'Test';
        bfc.Execute_Pre_Bill_Run__c = true;
        bfc.Execute_Post_Bill_Run__c = false;
        bfc.QTB_PreBill_Run_Status__c = 'Completed';
        bfc.Invoice_Scheduler__c = singaporeSchedule.id;
        insert bfc;
        
        //rebillInvoiceList[0].blng__InvoiceDate__c = System.today();
        rebillInvoiceList[0].blng__InvoiceStatus__c = 'Posted';       
        rebillInvoiceList[0].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        update rebillInvoiceList[0];            
        
        // Create CreditNote
        List<blng__CreditNote__c> creditNotes = new List<blng__CreditNote__c>();
        blng__CreditNote__c creditNote = new blng__CreditNote__c();
        creditNote.blng__Account__c = testAccounts[0].Id;
        creditNote.blng__CreditNoteDate__c = date.today();
        creditNote.QTB_Reason_Code__c = 'Account Creation';
        creditNote.blng__Status__c = 'Draft';
        creditNote.CurrencyIsoCode = 'SGD';
        creditNote.QTB_Manager_Approver__c = testApp1.Id;
        creditNote.QTB_VP_Approver__c = testApp2.Id;
        creditNote.QTB_SVP_Approver__c = testApp2.Id;
        creditNote.blng__Status__c = 'Draft';  
        creditNote.blng__RelatedInvoice__c =  parentInvoiceList[0].Id;
        creditNote.QTB_ReBill_Credit_Amount__c = 200; 
        creditNotes.add(creditNote);
        insert creditNotes;
        creditNotes[0].blng__Status__c = 'Draft';
        creditNotes[0].ApprovalStatus__c='Draft';
        creditNotes[0].QTB_Internal_PO_Notes__c = 'testM4';
        update creditNotes[0];
        
        
        creditNotes[0].QTB_Credit_Note_Type__c = 'Credit Only';
        creditNotes[0].QTB_IRM_to_Vertex_Tax_Request__c  ='Test';
        update creditNotes[0];
        Set<Id> InvListIds = new Set<ID>();
        InvListIds.add(parentInvoiceList[0].Id);
        
        Set<Id> CreditnoteIds = new Set<Id>();
        CreditnoteIds.add(creditNotes[0].id);
        
        QTB_CreditNoteHelper.creditReBill(InvListIds,CreditnoteIds,'Insert',null);  
        QTB_CreditNoteHelper.creditReBill(InvListIds,CreditnoteIds,'Update',true); 
    //    QTB_CreditNoteHelper.testFunctionality();
     QTB_CreditNoteHelperUtils.updateFieldsForLegacyInvoiceOfPostedCNS(InvListIds);
        Test.stopTest();
    }
   
    @isTest
    static void testMethodTaxEstimate() {
        Test.startTest();
        
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
            1,
            'Billing Account'
        );
        
         //Legal Entity
        blng__LegalEntity__c singaporeEntity = new blng__LegalEntity__c();
        singaporeEntity.Name = 'Test Legal Entity Singapore';
        singaporeEntity.blng__Active__c = true;
        singaporeEntity.blng__Country__c = 'Singapore';
        singaporeEntity.QTB_Type__c = 'Contract';
        singaporeEntity.QTB_Legal_Entity_Number__c = 45409;
        insert singaporeEntity; 
        
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
        singaporeFinancePeriod.blng__LegalEntity__c = singaporeEntity.id;
        singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert singaporeFinancePeriod;
        
        blng__LegalEntity__c USEntity= QTB_TestDataFactory.createLegalEntity('Singapore');
        testaccounts[0].QTB_Legal_Entity_Country__c='Singapore';
        testaccounts[0].SBQQ__TaxExempt__c = 'YES';
        update testAccounts;
        
        List<product2> product = QTB_TestDataFactory.createProducts(1);  
        Group groupinfo = [SELECT id FROM Group WHERE Name = 'QTB VP India'  LIMIT 1  ];
        
        sbaa__Approver__c testApp1 = QTB_TestDataFactory.createApprover();
        testApp1.sbaa__User__c = UserInfo.getUserId();
        
        sbaa__Approver__c testApp2 = QTB_TestDataFactory.createApprover();
        testApp2.sbaa__GroupId__c = groupinfo.id;
        testApp2.QTB_Approver_Country__c = 'Singapore';
        testApp2.QTB_Approver_Level__c = 'VP';
        
        sbaa__Approver__c testApp3 = QTB_TestDataFactory.createApprover();
        testApp3.sbaa__GroupId__c = groupinfo.id;
        testApp3.QTB_Approver_Country__c = 'Singapore';
        testApp3.QTB_Approver_Level__c = 'SVP';
        
        sbaa__Approver__c testApp4 = QTB_TestDataFactory.createApprover();
        testApp4.sbaa__GroupId__c = groupinfo.id;
        testApp4.QTB_Approver_Country__c = 'Singapore';
        testApp4.QTB_Approver_Level__c = 'EVP';
        
        sbaa__Approver__c testApp5 = QTB_TestDataFactory.createApprover();
        testApp5.sbaa__GroupId__c = groupinfo.id;
        testApp5.QTB_Approver_Country__c = 'Singapore';
        testApp5.QTB_Approver_Level__c = 'CFO';
        
        update new List<sbaa__Approver__c>{ testApp1, testApp2,testApp3,testApp4,testApp5 };
            
            //Parent Invoice  
            List<blng__Invoice__c> parentInvoiceList = QTB_TestDataFactory.createInvoices(testAccounts);            
        parentInvoiceList[0].QTB_ReBill_Status__c = 'Usage Completed';
        parentInvoiceList[0].blng__InvoiceStatus__c = 'Posted';    
        update parentInvoiceList;
        
        //Rebill Invoice
        List<blng__Invoice__c> rebillInvoiceList = QTB_TestDataFactory.createInvoices(testAccounts);
        rebillInvoiceList[0].QTB_Parent_Invoice__c = parentInvoiceList[0].id;
        rebillInvoiceList[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        rebillInvoiceList[0].blng__InvoiceStatus__c = 'Draft';        
        update rebillInvoiceList;
        
        //Rebill Invoice Lines
        List<blng__InvoiceLine__c> invoiceLineList = QTB_TestDataFactory.createInvoiceLine(3,rebillInvoiceList,product);
        
        //Invoice Schedular
        /*blng__InvoiceScheduler__c invSch = new blng__InvoiceScheduler__c();
        invSch.Name = 'Test123456789';
        invSch.blng__Type__c = 'Once';
        invSch.blng__InvoiceBatches__c = 'Rebill Run';
        invSch.CurrencyIsoCode = 'USD';
        invSch.blng__StartDateTime__c = System.now()+100;
        invSch.blng__InvoiceDate__c = system.today();
        invSch.blng__TargetDate__c = system.today();
        invSch.QTB_Parent_Invoice__c = parentInvoiceList[0].id;
        invSch.QTB_Invoice_Period__c =singaporeFinancePeriod.id;
        insert invSch;*/
        blng__InvoiceScheduler__c singaporeSchedule = new blng__InvoiceScheduler__c();
        singaporeSchedule.Name = 'test for Singapore';
        singaporeSchedule.blng__Type__c = 'Once';
        singaporeSchedule.blng__InvoiceBatches__c = 'Singapore-1st';
        singaporeSchedule.CurrencyIsoCode = 'SGD';
        singaporeSchedule.blng__StartDateTime__c = System.today().adddays(2);
        singaporeSchedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        singaporeSchedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
        singaporeSchedule.QTB_Legal_Entity__c  = singaporeEntity.id;
        singaporeSchedule.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
        insert singaporeSchedule;
        
        //Invoice Run
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.blng__InvoiceScheduler__c = singaporeSchedule.id;
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        
        //Bill Flow Controller
        QTB_Bill_Flow_Controller__c bfc = new QTB_Bill_Flow_Controller__c();
        bfc.Name = 'Test';
        bfc.Execute_Pre_Bill_Run__c = true;
        bfc.Execute_Post_Bill_Run__c = false;
        bfc.QTB_PreBill_Run_Status__c = 'Completed';
        bfc.Invoice_Scheduler__c = singaporeSchedule.id;
        insert bfc;
        
        //rebillInvoiceList[0].blng__InvoiceDate__c = System.today();
        rebillInvoiceList[0].blng__InvoiceStatus__c = 'Posted';       
        rebillInvoiceList[0].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        update rebillInvoiceList[0];            
        
        // Create CreditNote
        List<blng__CreditNote__c> creditNotes = new List<blng__CreditNote__c>();
        blng__CreditNote__c creditNote = new blng__CreditNote__c();
        creditNote.blng__Account__c = testAccounts[0].Id;
        creditNote.blng__CreditNoteDate__c = date.today();
        creditNote.QTB_Reason_Code__c = 'Account Creation';
        creditNote.blng__Status__c = 'Draft';
        creditNote.CurrencyIsoCode = 'SGD';
        creditNote.QTB_Manager_Approver__c = testApp1.Id;
        creditNote.QTB_VP_Approver__c = testApp2.Id;
        creditNote.QTB_SVP_Approver__c = testApp2.Id;
        creditNote.blng__Status__c = 'Draft';  
        creditNote.blng__RelatedInvoice__c =  parentInvoiceList[0].Id;
        creditNote.QTB_ReBill_Credit_Amount__c = 200;
        creditNotes.add(creditNote);
        insert creditNotes;
        
        
        
        
        
        creditNotes[0].ApprovalStatus__c='Rejected';
        creditNote.blng__Status__c = 'Cancelled';
        update creditNotes[0];
        
        
        Set<Id> InvListIds = new Set<ID>();
        InvListIds.add(parentInvoiceList[0].Id);
        
        Set<Id> CreditnoteIds = new Set<Id>();
        CreditnoteIds.add(creditNotes[0].id);
         
        QTB_CreditNoteHelper.creditReBill(InvListIds,CreditnoteIds,'Update',true); 
        QTB_CreditNoteHelper.creditReBill(InvListIds,CreditnoteIds,'Insert',null);  
        
    //    QTB_CreditNoteHelper.testFunctionality();
        Test.stopTest();
    }
    
    @isTest
    static void testMethod5(){
        Test.startTest();
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        String result = 'Tax Estimated';
        List<blng__CreditNote__c> creditNoteList =  [Select Id,blng__Status__c From blng__CreditNote__c];
        List<blng__CreditNoteLine__c> creditNoteLineList5 = [Select Id, blng__TaxTreatment__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c
                                                             From blng__CreditNoteLine__c];
        List<blng__CreditNoteLine__c> crdlineFinal = new List<blng__CreditNoteLine__c>();
        for(blng__CreditNoteLine__c cnl : creditNoteLineList5){
            blng__CreditNoteLine__c cnlObj = new blng__CreditNoteLine__c();
            cnlObj.Id = cnl.Id;
            cnlObj.blng__CalculateTax__c = true;
            crdlineFinal.add(cnlObj);
        }
        
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
            1,
            'Billing Account'
        );
        /*
        QTB_PurchaseOrder__c PO=new QTB_PurchaseOrder__c();
        PO.QTB_PO_Type__c ='Standard';
        PO.QTB_Customer_PO__c ='123';
         PO.QTB_Billing_Account__c =testAccounts[0].Id;
        PO.QTB_Amount__c =50000;
        PO.QTB_PO_Balance_Amount__c =4000;
        po.QTB_Service_Type__c = 'Mixed';        
        insert PO;*/
        
        
        
        List<blng__InvoiceLine__c> Invline=[select id,blng__Invoice__c from blng__InvoiceLine__c where blng__TaxCountry__c = 'India'];
        System.debug('testMethod5_crdlineFinal1@@'+crdlineFinal); 
        //database.update(crdlineFinal);        
        System.debug('testMethod5_crdlineFinal2@@'+crdlineFinal);     
        
        blng__LegalEntity__c USEntity = [Select ID from blng__LegalEntity__c ];
        Set<Id> creditNoteId = new Set<Id>();
        Map<String, List<blng__TaxRate__c>> taxRatesMap = new Map<String, List<blng__TaxRate__c>>();
        
        for(blng__CreditNote__c  crd : creditNoteList){
            creditNoteId.add(crd.Id);
        }
         
        //Tax Rule
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;       
        
        //Tax Rate
        List<blng__TaxRate__c> taxRatesList = new List<blng__TaxRate__c>();
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
         database.insert(taxRate);        
        taxRatesList.add(taxRate);
        
        taxRatesMap.put(taxRate.blng__LegalEntity__c, taxRatesList);
        //QTB_CreditNoteHelper.taxRatesMap = taxRatesMap;
        
        List<Product2> productList = [Select Id,Name from Product2 where Name = 'Fair Market Value'];
        
        //SITAD Billing Account
        
        List<Account> sitadAccountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        sitadAccountList[0].QTB_Legal_Entity_Country__c='United States';
        sitadAccountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        sitadAccountList[0].ShippingCity = 'New York';
        sitadAccountList[0].ShippingState = 'New York';
        sitadAccountList[0].ShippingPostalCode = '22131';
        sitadAccountList[0].ShippingCountry = 'United States';
        sitadAccountList[0].QTB_SITAD__c = true;
        update sitadAccountList;
        
        Contact con = new Contact();
            con.LastName = 'Custom Last Name:20 ';
            con.FirstName = 'Custom First Name ';
            con.email = 'some1@email.com';
            con.AccountId = sitadAccountList[0].Id;
            con.MailingCountry = 'United States';
            con.IM_Role__c = 'PO Contact';
            insert con;
       set<Id> creditids=new set<id>();
         QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c(
                QTB_Billing_Account__c = sitadAccountList[0].Id,
                QTB_Status__c = 'Active',
                QTB_Start_Date__c = date.Today(),
                QTB_End_Date__c = date.today(),
                //QTB_PO_Type__c = 'Project',
                QTB_Customer_PO__c = 'QW2315',
                QTB_Amount__c = 10000,
                QTB_Service_Type__c = 'Mixed',
                QTB_PO_Type__c = 'Standard'
            );
            insert pOrder;
      //  System.runAs(userList[1]) {
            QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_INVOICE);
            QTB_InvoiceTriggerHandler.skipTriggerExecutionTestClass = true;
            List<blng__Invoice__c> parentInvoiceList = [Select id,blng__InvoiceStatus__c from blng__Invoice__c where blng__InvoiceStatus__c = 'Posted' Limit 1];           
            parentInvoiceList[0].QTB_ReBill_Status__c = 'Usage Completed';
            parentInvoiceList[0].blng__InvoiceStatus__c = 'Posted';
            parentInvoiceList[0].QTB_PurchaseOrder__c = pOrder.id;
            
          //  update parentInvoiceList;
            
            List<blng__CreditNote__c> creditList=new List<blng__CreditNote__c>();
            Map<id,blng__CreditNote__c> creditMap=new Map<id,blng__CreditNote__c>();
            //Account with CreditNote
            
           /*
            Metadata_Activation_Settings__c cs = new Metadata_Activation_Settings__c();
            cs.Disable_Trigger__c = true;
            QTB_CreditNoteTriggerHandler CNtrigger = new QTB_CreditNoteTriggerHandler();
            CNtrigger.bypass();
            CNtrigger.IsDisabled();*/
            //QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_CREDITNOTE);
            //QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass = true;
            blng__CreditNote__c creditNote2 = new blng__CreditNote__c();
            creditNote2.blng__Account__c = sitadAccountList[0].Id;
            creditNote2.QTB_On_Account_Credit__c = true;
            creditNote2.blng__CreditNoteDate__c = date.today();
            creditNote2.QTB_Reason_Code__c = 'Remarketing Credit'; 
            creditNote2.blng__Status__c = 'Draft';
            creditNote2.CurrencyIsoCode = 'USD';
            creditNote2.QTB_Purchase_Order__c =pOrder.id;
            creditNote2.blng__RelatedInvoice__c = parentInvoiceList[0].Id;
            creditNote2.QTB_Internal_PO_Notes__c = 'testdemo';
            creditNote2.blng__Status__c = 'Cancelled';
            creditNote2.QTB_Credit_Note_Type__c ='Credit Only';
            //creditNote2.QTB_PO_Number__c='12345';
            creditNote2.QTB_Site_Number__c='125432';
            //GitLab 29058 - Start
            creditNote2.QTB_Case_Number__c = '123456';
            //GitLab 29058 - End
            SBQQ.TriggerControl.disable();
            insert creditNote2;
            SBQQ.TriggerControl.enable();
            Map<id,blng__CreditNote__c> oldmap = new Map<id,blng__CreditNote__c>();
            oldmap.put(creditNote2.id,creditNote2);
            creditList.add(creditNote2); 
            //creditNote2.QTB_Reason_Code__c = 'Account Creation';
            // creditNote2.QTB_Reason_Code__c = 'Fair Market Value';
            // try{
            //   SBQQ.TriggerControl.disable();
            //   update creditNote2;  
              
            // }
            // Catch(Exception e){
            //     System.debug('Exception@@'+e.getMessage());
            // }
            
            QTB_CreditNoteHelper.autoUpdatePO(creditList);
            //Create CreditNoteLine for Account with CreditNote
            blng__CreditNoteLine__c cnl2 = new blng__CreditNoteLine__c();
            /*cnl2.QTB_Account__c = sitadAccountList[0].Id;
            cnl2.blng__CreditNote__c = creditNote2.id;
            cnl2.blng__Product__c = productList[0].Id;
            cnl2.blng__Subtotal__c = 3000; 
            cnl2.QTB*/
                
                cnl2.QTB_Account__c = sitadAccountList[0].Id;
                cnl2.blng__CreditNote__c = creditNote2.id;
                cnl2.QTB_Invoice__c = Invline[0].blng__Invoice__c;
                //cnl2.QTB_InvoiceLine__c = Invline[0].id;
                cnl2.blng__Product__c = productList[0].Id;                        
                cnl2.blng__CalculateTax__c=false;
                cnl2.blng__Subtotal__c = 0;  
                cnl2.QTB_Credit_Quantity__c = 1;
                cnl2.blng__TotalAmount__c = 10;
                crdlineFinal[0].QTB_Invoice__c = Invline[0].blng__Invoice__c;
            SBQQ.TriggerControl.disable();
            update crdlineFinal[0];
            SBQQ.TriggerControl.enable();
           // insert cnl2;
            creditMap.put(creditNote2.id,creditNote2);
            creditids.add(creditNote2.id);
           
            System.debug('testMethod5_creditNoteLineList5[0]@@'+creditNoteLineList5[0]);
            //QTB_CreditNoteHelper.calculateTax(creditNoteLineList5[0]);
            //QTB_CreditNoteHelper.buildTaxRateMap();
            //QTB_CreditNoteHelper.calculateIndividualTaxAmountsOnCreditNoteLines(creditNoteId);
            //QTB_CreditNoteHelper.updateFieldsForLegacyInvoiceOfPostedCNS(creditids);
            
            List<Account> acc=[select id from Account where QTB_Legal_Entity_Country__c='United States'];
            List<blng__CreditNote__c> CN=[select id,blng__TotalAmount__c,blng__Status__c from blng__CreditNote__c where blng__Account__c=:acc[0].id];
            Map<id,blng__CreditNote__c> varmap = new Map<id,blng__CreditNote__c>();
            for(blng__CreditNote__c cnl:CN){
                varmap.put(cnl.id,cnl);
            }
            if(varmap != null && creditList !=null)
            {
                QTB_CreditNoteHelper.CN_AutoUpdatePOBalance(creditList,varmap);
            }
            SBQQ.TriggerControl.disable();
            creditNote2.ApprovalStatus__c = 'Approved';
            creditNote2.blng__Status__c = 'Posted';
            QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass = true;
            update creditNote2;  
            QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass = false;
            SBQQ.TriggerControl.enable();
            List<blng__CreditNote__c> cnItems = new List<blng__CreditNote__c>();
            cnItems.add(creditNote2);
            QTB_CreditNoteHelper.CN_AutoUpdatePOBalance(cnItems,oldmap);
     //   }
         Test.stopTest();
        //system.debug('#######'+CN[0].blng__TotalAmount__c);
        
    }  @isTest
    static void testMethod6(){
         Test.startTest();
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        
        List<Account> acc=[select id from Account where QTB_Legal_Entity_Country__c='United States'];
        
        List<blng__CreditNote__c> CN=[select id,blng__TotalAmount__c,blng__Status__c,QTB_Purchase_Order__c from blng__CreditNote__c where blng__Account__c=:acc[0].id and blng__TotalAmount__c >0 and QTB_Purchase_Order__c != null];
        Map<id,blng__CreditNote__c> varmap=new Map<id,blng__CreditNote__c>();
        for(blng__CreditNote__c cnl:CN){
            varmap.put(cnl.id,cnl);
        }
        //system.debug('#################'+CN[0].blng__TotalAmount__c);
        try{
           QTB_CreditNoteHelper.CN_AutoUpdatePOBalance(CN,varmap); 
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        
        
         Test.stopTest();
    }
    
  

  /*  @isTest
    static void testMethod7(){
        Test.startTest();
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        List<Account> sitadAccountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        sitadAccountList[0].QTB_Legal_Entity_Country__c='United States';
        sitadAccountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        sitadAccountList[0].ShippingCity = 'New York';
        sitadAccountList[0].ShippingState = 'New York';
        sitadAccountList[0].ShippingPostalCode = '22131';
        sitadAccountList[0].ShippingCountry = 'United States';
        sitadAccountList[0].QTB_SITAD__c = true;
        update sitadAccountList;
        Contact con = new Contact();
            con.LastName = 'Custom Last Name:20 ';
            con.FirstName = 'Custom First Name ';
            con.email = 'some1@email.com';
            con.AccountId = sitadAccountList[0].Id;
            con.MailingCountry = 'United States';
            con.IM_Role__c = 'PO Contact';
            insert con;
 
        
        QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c(
                QTB_Billing_Account__c = sitadAccountList[0].Id,
                QTB_Status__c = 'Active',
                QTB_Start_Date__c = date.Today(),
                QTB_End_Date__c = date.today(),
                //QTB_PO_Type__c = 'Project',
                QTB_Customer_PO__c = 'QW2315',
                QTB_Amount__c = 10000,
                QTB_Service_Type__c = 'Mixed',
                QTB_PO_Type__c = 'Standard'
            );
            insert pOrder;
        
         List<blng__InvoiceLine__c> Invline=[select id,blng__Invoice__c, blng__Subtotal__c from blng__InvoiceLine__c where blng__TaxCountry__c = 'India'];
        List<blng__Invoice__c> parentInvoiceList = [SELECT Id FROM blng__Invoice__c WHERE Id =: Invline[0].blng__Invoice__c LIMIT 1];
        QTB_InvoiceTriggerHandler.skipTriggerExecutionTestClass = true;
        //List<blng__Invoice__c> parentInvoiceList = QTB_TestDataFactory.createInvoices(sitadAccountList);            
        parentInvoiceList[0].QTB_ReBill_Status__c = 'Usage Completed';
        parentInvoiceList[0].blng__InvoiceStatus__c = 'Posted';
        parentInvoiceList[0].QTB_PurchaseOrder__c = pOrder.id;
        update parentInvoiceList;
        
       
        
        QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass = true;
        blng__CreditNote__c creditNote2 = new blng__CreditNote__c();
        creditNote2.blng__Account__c = sitadAccountList[0].Id; 
        creditNote2.QTB_On_Account_Credit__c = true;
        creditNote2.blng__CreditNoteDate__c = date.today();
        creditNote2.QTB_Reason_Code__c = 'Remarketing Credit'; 
        creditNote2.blng__Status__c = 'Draft';
        creditNote2.CurrencyIsoCode = 'USD';
        creditNote2.QTB_Purchase_Order__c =pOrder.id;
        creditNote2.blng__RelatedInvoice__c = parentInvoiceList[0].Id;
        insert creditNote2;
        
        ID prodId = [SELECT Id,Name FROM Product2 WHERE Name = 'Test Product1'].Id;
        
        blng__CreditNoteLine__c cnl1 = new blng__CreditNoteLine__c();
        cnl1.QTB_Account__c = sitadAccountList[0].Id;
        cnl1.blng__CreditNote__c = creditNote2.id;
        cnl1.QTB_Invoice__c = parentInvoiceList[0].id;
        cnl1.QTB_InvoiceLine__c = Invline[0].id;
        cnl1.blng__CalculateTax__c=false;
        cnl1.blng__Subtotal__c = 0;  
        cnl1.QTB_Credit_Quantity__c = 1;
        cnl1.blng__TotalAmount__c = 0; 
        cnl1.blng__Product__c = prodId;
        insert cnl1; 
        
        Map<id,blng__CreditNote__c> oldmap = new Map<id,blng__CreditNote__c>();
        oldmap.put(creditNote2.id,creditNote2);
        
        creditNote2.ApprovalStatus__c = 'Approved';
        creditNote2.blng__Status__c = 'Posted';
        update creditNote2;  
        List<blng__CreditNote__c> cnItems = new List<blng__CreditNote__c>();
        cnItems.add(creditNote2);
        
        
        AccountTriggerHandler.skipTriggerExecutionTestClass  = false;
        QTB_InvoiceTriggerHandler.skipTriggerExecutionTestClass = false;
        QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass = false;
        
        QTB_CreditNoteHelper.CN_AutoUpdatePOBalance(cnItems,oldmap);


Test.stopTest();
    }*/
     @isTest
    static void testMethod7(){
        Test.startTest();
        
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        
        List<blng__CreditNote__c> creditNoteList =  [Select Id,blng__Status__c From blng__CreditNote__c];
        List<blng__CreditNoteLine__c> creditNoteLineList5 = [Select Id, blng__TaxTreatment__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c
                                                             From blng__CreditNoteLine__c];
        List<blng__CreditNoteLine__c> crdlineFinal = new List<blng__CreditNoteLine__c>();
        for(blng__CreditNoteLine__c cnl : creditNoteLineList5){
            blng__CreditNoteLine__c cnlObj = new blng__CreditNoteLine__c();
            cnlObj.Id = cnl.Id;
            cnlObj.blng__CalculateTax__c = true;
            crdlineFinal.add(cnlObj);
        }
        
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
            1,
            'Billing Account'
        );
       
        
        List<blng__InvoiceLine__c> Invline=[select id,blng__Invoice__c from blng__InvoiceLine__c where blng__TaxCountry__c = 'India'];
        System.debug('testMethod5_crdlineFinal1@@'+crdlineFinal); 
        //database.update(crdlineFinal);        
        System.debug('testMethod5_crdlineFinal2@@'+crdlineFinal);     
        
        blng__LegalEntity__c USEntity = [Select ID from blng__LegalEntity__c ];
        Set<Id> creditNoteId = new Set<Id>();
        Map<String, List<blng__TaxRate__c>> taxRatesMap = new Map<String, List<blng__TaxRate__c>>();
        
        for(blng__CreditNote__c  crd : creditNoteList){
            creditNoteId.add(crd.Id);
        }
         
        //Tax Rule
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;       
        
        //Tax Rate
        List<blng__TaxRate__c> taxRatesList = new List<blng__TaxRate__c>();
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
         database.insert(taxRate);        
        taxRatesList.add(taxRate);
        
        taxRatesMap.put(taxRate.blng__LegalEntity__c, taxRatesList);
        //QTB_CreditNoteHelper.taxRatesMap = taxRatesMap;
        
        List<Product2> productList = [Select Id,Name from Product2 where Name = 'Fair Market Value'];
        
        //SITAD Billing Account
        
        List<Account> sitadAccountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        sitadAccountList[0].QTB_Legal_Entity_Country__c='United States';
        sitadAccountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        sitadAccountList[0].ShippingCity = 'New York';
        sitadAccountList[0].ShippingState = 'New York';
        sitadAccountList[0].ShippingPostalCode = '22131';
        sitadAccountList[0].ShippingCountry = 'United States';
        sitadAccountList[0].QTB_SITAD__c = true;
        update sitadAccountList;
        
        Contact con = new Contact();
            con.LastName = 'Custom Last Name:20 ';
            con.FirstName = 'Custom First Name ';
            con.email = 'some1@email.com';
            con.AccountId = sitadAccountList[0].Id;
            con.MailingCountry = 'United States';
            con.IM_Role__c = 'PO Contact';
            insert con;
       set<Id> creditids=new set<id>();
         QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c(
                QTB_Billing_Account__c = sitadAccountList[0].Id,
                QTB_Status__c = 'Active',
                QTB_Start_Date__c = date.Today(),
                QTB_End_Date__c = date.today(),
                QTB_Customer_PO__c = 'QW2315',
                QTB_Amount__c = 10000,
                QTB_Service_Type__c = 'Mixed',
                QTB_PO_Type__c = 'Standard'
            );
            insert pOrder;
        
            QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_INVOICE);
            QTB_InvoiceTriggerHandler.skipTriggerExecutionTestClass = true;
            List<blng__Invoice__c> parentInvoiceList = QTB_TestDataFactory.createInvoices(testAccounts);
            
            parentInvoiceList[0].QTB_ReBill_Status__c = 'Usage Completed';
            parentInvoiceList[0].blng__InvoiceStatus__c = 'Posted';
            //parentInvoiceList[0].QTB_PurchaseOrder__c = pOrder.id;
            update parentInvoiceList;
            
            List<blng__CreditNote__c> creditList=new List<blng__CreditNote__c>();
            Map<id,blng__CreditNote__c> creditMap=new Map<id,blng__CreditNote__c>();
           
            QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass = true;
            blng__CreditNote__c creditNote2 = new blng__CreditNote__c();
            creditNote2.blng__Account__c = sitadAccountList[0].Id;
            creditNote2.QTB_On_Account_Credit__c = true;
            creditNote2.blng__CreditNoteDate__c = date.today();
            creditNote2.QTB_Reason_Code__c = 'Remarketing Credit'; 
            creditNote2.blng__Status__c = 'Draft';
            creditNote2.CurrencyIsoCode = 'USD';
            creditNote2.QTB_Internal_PO_Notes__c = 'testM7';
            creditNote2.QTB_Purchase_Order__c =pOrder.id;
            creditNote2.blng__RelatedInvoice__c = parentInvoiceList[0].Id;
            creditNote2.QTB_Site_Number__c='Site125432';
            SBQQ.TriggerControl.disable();
            insert creditNote2;
            SBQQ.TriggerControl.enable();
            Map<id,blng__CreditNote__c> oldmapN = new Map<id,blng__CreditNote__c>();
            oldmapN.put(creditNote2.id,creditNote2);
            creditList.add(creditNote2); 
            //creditNote2.QTB_Reason_Code__c = 'Account Creation';
            creditNote2.QTB_Reason_Code__c = 'Fair Market Value';
            try{
              SBQQ.TriggerControl.disable();
              update creditNote2;  
              SBQQ.TriggerControl.enable();
            }
            Catch(Exception e){
                System.debug('Exception@@'+e.getMessage());
            }
            
           
           /* blng__CreditNoteLine__c cnl2 = new blng__CreditNoteLine__c();
                          
                cnl2.QTB_Account__c = sitadAccountList[0].Id;
                cnl2.blng__CreditNote__c = creditNote2.id;
                cnl2.QTB_Invoice__c = Invline[0].blng__Invoice__c;
                //cnl2.QTB_InvoiceLine__c = Invline[0].id;
                cnl2.blng__Product__c = productList[0].Id;                        
                cnl2.blng__CalculateTax__c=false;
                cnl2.blng__Subtotal__c = 0;  
                cnl2.QTB_Credit_Quantity__c = 1;
                cnl2.blng__TotalAmount__c = 10;
                crdlineFinal[0].QTB_Invoice__c = Invline[0].blng__Invoice__c;
                update crdlineFinal[0]; */
           // insert cnl2;
           // creditMap.put(creditNote2.id,creditNote2);
            //creditids.add(creditNote2.id);
           
            //System.debug('testMethod5_creditNoteLineList5[0]@@'+creditNoteLineList5[0]);
           
            
            SBQQ.TriggerControl.disable();
            creditNote2.ApprovalStatus__c = 'Approved';
            creditNote2.blng__Status__c = 'Posted';
            
            update creditNote2;  
            QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass = false;
            SBQQ.TriggerControl.enable();
            List<blng__CreditNote__c> cnItems = new List<blng__CreditNote__c>();
            cnItems.add(creditNote2);
            QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass = false;
            QTB_CreditNoteHelper.CN_AutoUpdatePOBalance(cnItems,oldmapN);
         
         Test.stopTest();
        
    }
    
    
     @isTest
    static void testMethod8(){
        system.debug('*************==============');
     
        Test.startTest();
        
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        
        QTB_CreditNoteTriggerHandler.throwExplicitException = false;
        List<blng__CreditNoteLine__c> finalCreditNoteLineList = new List<blng__CreditNoteLine__c>();
        List<blng__CreditNote__c> finalCreditNoteList = new List<blng__CreditNote__c>();
        Map<Id, blng__CreditNote__c> mapOfNewCreditNotes = new Map<Id, blng__CreditNote__c>();
        Map<Id, blng__CreditNote__c> mapOfOldCreditNotes = new Map<Id, blng__CreditNote__c>();
        List<blng__CreditNoteLine__c> ListCredirLines = [Select Id, blng__Subtotal__c,blng__TaxTreatment__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c from blng__CreditNoteLine__c ];
       
        for(blng__CreditNoteLine__c cnl : ListCredirLines){
            blng__CreditNoteLine__c crdline = new blng__CreditNoteLine__c();
            crdline.Id = cnl.Id;
            crdline.blng__Subtotal__c = 10;
            finalCreditNoteLineList.add(crdline);
        }
       
        
      List <Account> AccList = [Select id,QTB_Data_Management__c,QTB_Records_Management__c,QTB_scan__c,QTB_shred__c,QTB_SITAD__c  from Account where ShippingCountry = 'United States'];
        system.debug('*************'+AccList);
        Set<Id> AccountId = new Set<Id> ();
        if(AccList.size()>0){
            for ( Account Accs : AccList)
            {
                AccountId.add(Accs.Id);
            }
        } 
        List<blng__CreditNote__c> creditNotes = [Select ID, Name, QTB_Country__c,QTB_IsReBill__c,blng__EffectiveTaxDate__c,blng__Status__c,blng__Account__c from blng__CreditNote__c where blng__Account__c =:AccList[0].id and blng__Status__c = 'Draft'];
        for(blng__CreditNote__c cn :creditNotes ){
            cn.blng__Notes__c = 'test'; 
            finalCreditNoteList.add(cn);
            mapOfOldCreditNotes.put(cn.id,cn);
        }
        
        for(blng__CreditNote__c cn :finalCreditNoteList){
            mapOfNewCreditNotes.put(cn.id,cn);
        }
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        
        Set<String> setOfUserIdOrCountires = new  Set<String>();
        setOfUserIdOrCountires.add('United States');
        setOfUserIdOrCountires.add('India');
        setOfUserIdOrCountires.add('Canada');
        setOfUserIdOrCountires.add(userList[0].id);
        Map<String, Id> abc = QTB_CreditNoteHelper.getApproverIds(setOfUserIdOrCountires);
        QTB_CreditNoteHelper.CN_CheckRestrictedFields(finalCreditNoteList,mapOfOldCreditNotes, 'blng__EffectiveTaxDate__c');
        QTB_CreditNoteHelper.autoUpdatePO(finalCreditNoteList);
        
        QTB_CreditNoteHelper.onAccountCreditNote(null,finalCreditNoteList,mapOfOldCreditNotes);
        
        try{
           QTB_CreditNoteHelper.onAccountCreditNote(AccountId,finalCreditNoteList,mapOfOldCreditNotes);
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        try{
            QTB_CreditNoteHelper.onAccountCreditNote(AccountId,finalCreditNoteList,null);
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        Test.stopTest();
    }
    
     @isTest
    static void testMethod811(){
        system.debug('*************==============');
     
        Test.startTest();
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        
        QTB_CreditNoteTriggerHandler.throwExplicitException = false;
        List<blng__CreditNoteLine__c> finalCreditNoteLineList = new List<blng__CreditNoteLine__c>();
        List<blng__CreditNote__c> finalCreditNoteList = new List<blng__CreditNote__c>();
        Map<Id, blng__CreditNote__c> mapOfNewCreditNotes = new Map<Id, blng__CreditNote__c>();
        Map<Id, blng__CreditNote__c> mapOfOldCreditNotes = new Map<Id, blng__CreditNote__c>();
        List<blng__CreditNoteLine__c> ListCredirLines = [Select Id, blng__Subtotal__c,blng__TaxTreatment__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c from blng__CreditNoteLine__c ];
       
        for(blng__CreditNoteLine__c cnl : ListCredirLines){
            blng__CreditNoteLine__c crdline = new blng__CreditNoteLine__c();
            crdline.Id = cnl.Id;
            crdline.blng__Subtotal__c = 10;
            finalCreditNoteLineList.add(crdline);
        }
       
        
      List <Account> AccList = [Select id,QTB_Data_Management__c,QTB_Records_Management__c,QTB_scan__c,QTB_shred__c,QTB_SITAD__c  from Account where ShippingCountry = 'United States'];
        system.debug('*************'+AccList);
        Set<Id> AccountId = new Set<Id> ();
        if(AccList.size()>0){
            for ( Account Accs : AccList)
            {
                AccountId.add(Accs.Id);
            }
        } 
         QTB_PurchaseOrder__c PO=new QTB_PurchaseOrder__c();
        PO.QTB_PO_Type__c ='Standard';
        PO.QTB_Customer_PO__c ='123';
        PO.QTB_Billing_Account__c =AccList[0].Id;
        PO.QTB_Amount__c =50000;
        PO.QTB_PO_Balance_Amount__c =4000;
        po.QTB_Service_Type__c = 'Mixed';   
        po.QTB_End_Date__c = system.today()+5;
        po.QTB_Start_Date__c = system.today();
        insert PO;
        List<blng__Invoice__c> parentInvoiceList = QTB_TestDataFactory.createInvoices(AccList);
        if(parentInvoiceList != null && !parentInvoiceList.isEmpty() ){
            //parentInvoiceList[0].QTB_PurchaseOrder__c = PO.Id;
            parentInvoiceList[0].blng__InvoiceStatus__c = 'Posted';
            update parentInvoiceList[0];
        } 
      
        
         List<blng__CreditNote__c> creditNotes1 = new List<blng__CreditNote__c>();
        blng__CreditNote__c creditNote = new blng__CreditNote__c();
        creditNote.blng__Account__c = AccList[0].Id;
        creditNote.blng__CreditNoteDate__c = date.today();
        creditNote.QTB_Reason_Code__c = 'Account Creation';
        creditNote.blng__Status__c = 'Draft';
        creditNote.CurrencyIsoCode = 'SGD';
       // creditNote.QTB_Manager_Approver__c = testApp1.Id;
      //  creditNote.QTB_VP_Approver__c = testApp2.Id;
      //  creditNote.QTB_SVP_Approver__c = testApp2.Id;
        creditNote.QTB_Credit_Note_Type__c = 'Split ReBill';
        creditNote.blng__Status__c = 'Draft';  
         if(parentInvoiceList != null && !parentInvoiceList.isEmpty() ){
             creditNote.blng__RelatedInvoice__c =  parentInvoiceList[0].Id; }
        creditNote.QTB_ReBill_Credit_Amount__c = 200; 
        creditNotes1.add(creditNote);
        
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        creditNote1.blng__Account__c = AccList[0].Id;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Account Creation';
        creditNote1.blng__Status__c = 'Draft';
        creditNote1.CurrencyIsoCode = 'SGD';
       // creditNote.QTB_Manager_Approver__c = testApp1.Id;
      //  creditNote.QTB_VP_Approver__c = testApp2.Id;
      //  creditNote.QTB_SVP_Approver__c = testApp2.Id;
        creditNote1.QTB_Credit_Note_Type__c = 'ON Account Credit';
        creditNote1.blng__Status__c = 'Draft';  
     if(parentInvoiceList != null && !parentInvoiceList.isEmpty() ){
             creditNote1.blng__RelatedInvoice__c =  parentInvoiceList[0].Id; }
        creditNote1.QTB_ReBill_Credit_Amount__c = 200; 
        creditNotes1.add(creditNote1);
        insert creditNotes1;
        
        
        List<blng__CreditNote__c> creditNotes = [Select ID, Name,blng__Notes__c,blng__RelatedInvoice__c, QTB_Country__c,QTB_IsReBill__c,blng__EffectiveTaxDate__c,blng__Status__c,blng__Account__c from blng__CreditNote__c where blng__Account__c =:AccList[0].id and blng__Status__c = 'Posted'];
        for(blng__CreditNote__c cn :creditNotes ){
            cn.blng__Notes__c = 'test'; 
           // cn.blng__RelatedInvoice__c = parentInvoiceList[0].Id;
            //cn.QTB_Purchase_Order__c = 
           // cn.blng__Status__c == 'Draft';
            //cn.QTB_Credit_Note_Type__c == 'Credit Only';
            finalCreditNoteList.add(cn);
            mapOfOldCreditNotes.put(cn.id,cn);
        }
        
        for(blng__CreditNote__c cn :finalCreditNoteList){
            cn.blng__EffectiveTaxDate__c = system.today();
            mapOfNewCreditNotes.put(cn.id,cn);
        }
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        
        Set<String> setOfUserIdOrCountires = new  Set<String>();
        setOfUserIdOrCountires.add('United States');
        setOfUserIdOrCountires.add('India');
        setOfUserIdOrCountires.add('Canada');
        setOfUserIdOrCountires.add(userList[0].id);
        Map<String, Id> abc = QTB_CreditNoteHelper.getApproverIds(setOfUserIdOrCountires);
        QTB_CreditNoteHelper.CN_CheckRestrictedFields(finalCreditNoteList,mapOfOldCreditNotes, 'blng__EffectiveTaxDate__c');
        //QTB_CreditNoteHelper.autoUpdatePO(finalCreditNoteList);
        
        QTB_CreditNoteHelper.onAccountCreditNote(null,finalCreditNoteList,mapOfOldCreditNotes);
        
        try{
           QTB_CreditNoteHelper.onAccountCreditNote(AccountId,finalCreditNoteList,mapOfOldCreditNotes);
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        try{
            QTB_CreditNoteHelper.onAccountCreditNote(AccountId,finalCreditNoteList,null);
        }
        Catch(Exception e){
            System.debug('Exception@@'+e.getMessage());            
        }
        Test.stopTest();
    }
    
     @isTest
    static void testMethod9() {
        Test.startTest();
        
            //  Metadata_Activation_Settings__c custSetting2 = new Metadata_Activation_Settings__c();
     // custSetting2.SObject_API_Name__c = 'QTB_Bill_Flow_Controller__c';
     // custSetting2.Disable_VR__c = true;
      //custSetting2.Disable_PB__c = true;
      //custSetting2.Disable_Trigger__c = true;
      // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
     // insert custSetting2;
        
        
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
            1,
            'Billing Account'
        );
        
         //Legal Entity
        blng__LegalEntity__c singaporeEntity = new blng__LegalEntity__c();
        singaporeEntity.Name = 'Test Legal Entity Singapore';
        singaporeEntity.blng__Active__c = true;
        singaporeEntity.blng__Country__c = 'Singapore';
        singaporeEntity.QTB_Type__c = 'Contract';
        singaporeEntity.QTB_Legal_Entity_Number__c = 45409;
        insert singaporeEntity; 
        
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
        singaporeFinancePeriod.blng__LegalEntity__c = singaporeEntity.id;
        singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert singaporeFinancePeriod;
        
        blng__LegalEntity__c USEntity= QTB_TestDataFactory.createLegalEntity('Singapore');
        testaccounts[0].QTB_Legal_Entity_Country__c='Singapore';
        testaccounts[0].SBQQ__TaxExempt__c = 'Yes';
        update testAccounts;
        List<product2> product = QTB_TestDataFactory.createProducts(1);  
        Group groupinfo = [SELECT id FROM Group WHERE Name = 'QTB VP India'  LIMIT 1  ];
        QTB_InvoiceTriggerHandler.skipTriggerExecutionTestClass = true;
        sbaa__Approver__c testApp1 = QTB_TestDataFactory.createApprover();
        testApp1.sbaa__User__c = UserInfo.getUserId();
        
        sbaa__Approver__c testApp2 = QTB_TestDataFactory.createApprover();
        testApp2.sbaa__GroupId__c = groupinfo.id;
        testApp2.QTB_Approver_Country__c = 'Singapore';
        testApp2.QTB_Approver_Level__c = 'VP';
        
        sbaa__Approver__c testApp3 = QTB_TestDataFactory.createApprover();
        testApp3.sbaa__GroupId__c = groupinfo.id;
        testApp3.QTB_Approver_Country__c = 'Singapore';
        testApp3.QTB_Approver_Level__c = 'SVP';
        
        sbaa__Approver__c testApp4 = QTB_TestDataFactory.createApprover();
        testApp4.sbaa__GroupId__c = groupinfo.id;
        testApp4.QTB_Approver_Country__c = 'Singapore';
        testApp4.QTB_Approver_Level__c = 'EVP';
        
        sbaa__Approver__c testApp5 = QTB_TestDataFactory.createApprover();
        testApp5.sbaa__GroupId__c = groupinfo.id;
        testApp5.QTB_Approver_Country__c = 'Singapore';
        testApp5.QTB_Approver_Level__c = 'CFO';
        
        update new List<sbaa__Approver__c>{ testApp1, testApp2,testApp3,testApp4,testApp5 };
            
            //Parent Invoice  
          List<blng__Invoice__c> parentInvoiceList = QTB_TestDataFactory.createInvoices(testAccounts);            
        List<blng__InvoiceLine__c> invoiceLineList1 = QTB_TestDataFactory.createInvoiceLine(3,parentInvoiceList,product);
        parentInvoiceList[0].QTB_ReBill_Status__c = 'Usage Completed';
        parentInvoiceList[0].blng__InvoiceStatus__c = 'Posted';    
        update parentInvoiceList;
        
        List<blng__Invoice__c> childInvoiceList = QTB_TestDataFactory.createInvoices(testAccounts);            
        List<blng__InvoiceLine__c> childInvoiceLineList1 = QTB_TestDataFactory.createInvoiceLine(3,parentInvoiceList,product);
        childInvoiceList[0].QTB_ReBill_Status__c = 'Usage Completed';
        childInvoiceList[0].blng__InvoiceStatus__c = 'Draft';  
        childInvoiceList[0].QTB_Parent_Invoice__c = parentInvoiceList[0].Id;
        update childInvoiceList;
        
        
        //Rebill Invoice
        List<blng__Invoice__c> rebillInvoiceList = QTB_TestDataFactory.createInvoices(testAccounts);
        rebillInvoiceList[0].QTB_Parent_Invoice__c = parentInvoiceList[0].id;
        rebillInvoiceList[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        rebillInvoiceList[0].blng__InvoiceStatus__c = 'Draft';        
        update rebillInvoiceList;
        
        //Rebill Invoice Lines
        List<blng__InvoiceLine__c> invoiceLineList = QTB_TestDataFactory.createInvoiceLine(3,rebillInvoiceList,product);
        
        
        
        blng__InvoiceScheduler__c singaporeSchedule = new blng__InvoiceScheduler__c();
        singaporeSchedule.Name = 'test for Singapore';
        singaporeSchedule.blng__Type__c = 'Once';
        singaporeSchedule.blng__InvoiceBatches__c = 'Singapore-1st';
        singaporeSchedule.CurrencyIsoCode = 'SGD';
        singaporeSchedule.blng__StartDateTime__c = System.today().adddays(2);
        singaporeSchedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        singaporeSchedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
        singaporeSchedule.QTB_Legal_Entity__c  = singaporeEntity.id;
        singaporeSchedule.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
        insert singaporeSchedule;
        
        //Invoice Run
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.blng__InvoiceScheduler__c = singaporeSchedule.id;
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        
        //Bill Flow Controller
        QTB_Bill_Flow_Controller__c bfc = new QTB_Bill_Flow_Controller__c();
        bfc.Name = 'Test';
        bfc.Execute_Pre_Bill_Run__c = true;
        bfc.QTB_PreBill_Run_Status__c = 'Completed';
        bfc.QTB_SubInvoiceLine_Creation__c = false;
        bfc.Execute_Post_Bill_Run__c = false;
        bfc.Invoice_Scheduler__c = singaporeSchedule.id;
        insert bfc;
       
       
        //bfc.QTB_SubInvoiceLine_Creation__c = false;
       // update bfc;
        //bfc.Execute_Post_Bill_Run__c = true;
       // update bfc;
        
        //rebillInvoiceList[0].blng__InvoiceDate__c = System.today();
        rebillInvoiceList[0].blng__InvoiceStatus__c = 'Posted';       
        rebillInvoiceList[0].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        update rebillInvoiceList[0];            
        QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass = true;
        // Create CreditNote
        List<blng__CreditNote__c> creditNotes = new List<blng__CreditNote__c>();
        blng__CreditNote__c creditNote = new blng__CreditNote__c();
        creditNote.blng__Account__c = testAccounts[0].Id;
        creditNote.blng__CreditNoteDate__c = date.today();
        creditNote.QTB_Reason_Code__c = 'Account Creation';
        creditNote.blng__Status__c = 'Draft';
        creditNote.CurrencyIsoCode = 'SGD';
        creditNote.QTB_Manager_Approver__c = testApp1.Id;
        creditNote.QTB_VP_Approver__c = testApp2.Id;
        creditNote.QTB_SVP_Approver__c = testApp2.Id;
        creditNote.QTB_Credit_Note_Type__c = 'Split ReBill';
        creditNote.blng__Status__c = 'Draft';  
        creditNote.blng__RelatedInvoice__c =  parentInvoiceList[0].Id;
        creditNote.QTB_ReBill_Credit_Amount__c = 200; 
        creditNotes.add(creditNote);
        insert creditNotes;
        creditNotes[0].blng__Status__c = 'Draft';
        creditNotes[0].ApprovalStatus__c='Draft';
        creditNotes[0].QTB_Internal_PO_Notes__c = 'testM9';
        creditNotes[0].QTB_IRM_to_Vertex_Tax_Request__c  ='Test';
        update creditNotes[0];
        
        AccountTriggerHandler.skipTriggerExecutionTestClass  = true;
        testAccounts[0].SBQQ__TaxExempt__c = 'Yes';
        update testAccounts[0];
        
        /*creditNotes[0].QTB_Credit_Note_Type__c = 'Credit Only';
        update creditNotes[0];*/
        Set<Id> InvListIds = new Set<ID>();
        InvListIds.add(parentInvoiceList[0].Id);
        
        Set<Id> CreditnoteIds = new Set<Id>();
        CreditnoteIds.add(creditNotes[0].id);
        
        //QTB_CreditNoteHelper.creditReBill(InvListIds,CreditnoteIds,'Insert',null);  
        QTB_CreditNoteHelper.creditReBill(InvListIds,CreditnoteIds,'Update',true); 
    //    QTB_CreditNoteHelper.testFunctionality();
        
        List<blng__CreditNote__c> creditNotes1 = new List<blng__CreditNote__c>();
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        creditNote1.blng__Account__c = testAccounts[0].Id;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Legacy Credit';
        creditNote1.blng__Status__c = 'Draft';
        creditNote1.CurrencyIsoCode = 'SGD';
        creditNote1.QTB_Manager_Approver__c = testApp1.Id;
        creditNote1.QTB_VP_Approver__c = testApp2.Id;
        creditNote1.QTB_SVP_Approver__c = testApp2.Id;
        creditNote1.QTB_Credit_Note_Type__c = 'ON Account Credit'; 
        creditNote1.blng__RelatedInvoice__c =  parentInvoiceList[0].Id;
        creditNote1.QTB_ReBill_Credit_Amount__c = 200; 
        insert creditNote1;
        
        creditNote1.ApprovalStatus__c = 'Approved';
        //creditNote1.blng__Status__c = 'Posted';
        update creditNote1;
        CreditnoteIds.add(creditNote1.Id);
        creditNotes1.add(creditNote);
        
        blng__CreditNote__c creditNote2 = new blng__CreditNote__c();
        creditNote2.blng__Account__c = testAccounts[0].Id;
        creditNote2.blng__CreditNoteDate__c = date.today();
        creditNote2.QTB_Reason_Code__c = 'Account Creation';
        creditNote2.blng__Status__c = 'Draft';
        creditNote2.CurrencyIsoCode = 'SGD';
        creditNote2.QTB_Manager_Approver__c = testApp1.Id;
        creditNote2.QTB_VP_Approver__c = testApp2.Id;
        creditNote2.QTB_SVP_Approver__c = testApp2.Id;
        creditNote2.QTB_Credit_Note_Type__c = 'Split ReBill'; 
        creditNote2.blng__RelatedInvoice__c =  parentInvoiceList[0].Id;
        creditNote2.QTB_ReBill_Credit_Amount__c = 200; 
        insert creditNote2;
        
        creditNote1.ApprovalStatus__c='Rejected';
        creditNote1.blng__Status__c = 'Cancelled';
        update creditNote2;
        CreditnoteIds.add(creditNote2.Id);
        //QTB_CreditNoteHelper.creditReBill(InvListIds,CreditnoteIds,'Update',true);
        //QTB_CreditNoteHelper.CoverageMethod();
        Test.stopTest();
    }
    
     /*  @isTest
        static void testMethod511(){
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        
        List<blng__CreditNote__c> creditNoteList =  [Select Id,blng__Status__c From blng__CreditNote__c];
        List<blng__CreditNoteLine__c> creditNoteLineList5 = [Select Id, blng__TaxTreatment__c,blng__TaxTreatment__r.blng__TaxLegalEntity__c
                                                             From blng__CreditNoteLine__c];
        List<blng__CreditNoteLine__c> crdlineFinal = new List<blng__CreditNoteLine__c>();
        for(blng__CreditNoteLine__c cnl : creditNoteLineList5){
            blng__CreditNoteLine__c cnlObj = new blng__CreditNoteLine__c();
            cnlObj.Id = cnl.Id;
            cnlObj.blng__CalculateTax__c = true;
            crdlineFinal.add(cnlObj);
        }
        
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
            1,
            'Billing Account'
        );*/
        /*
        QTB_PurchaseOrder__c PO=new QTB_PurchaseOrder__c();
        PO.QTB_PO_Type__c ='Standard';
        PO.QTB_Customer_PO__c ='123';
         PO.QTB_Billing_Account__c =testAccounts[0].Id;
        PO.QTB_Amount__c =50000;
        PO.QTB_PO_Balance_Amount__c =4000;
        po.QTB_Service_Type__c = 'Mixed';        
        insert PO;*/
        
        
        
      /*  List<blng__InvoiceLine__c> Invline=[select id,blng__Invoice__c from blng__InvoiceLine__c where blng__TaxCountry__c = 'India'];
        System.debug('testMethod5_crdlineFinal1@@'+crdlineFinal); 
        //database.update(crdlineFinal);        
        System.debug('testMethod5_crdlineFinal2@@'+crdlineFinal);     
        
        blng__LegalEntity__c USEntity = [Select ID from blng__LegalEntity__c ];
        Set<Id> creditNoteId = new Set<Id>();
        Map<String, List<blng__TaxRate__c>> taxRatesMap = new Map<String, List<blng__TaxRate__c>>();
        
        for(blng__CreditNote__c  crd : creditNoteList){
            creditNoteId.add(crd.Id);
        }
         
        //Tax Rule
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;       
        
        //Tax Rate
        List<blng__TaxRate__c> taxRatesList = new List<blng__TaxRate__c>();
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
         database.insert(taxRate);        
        taxRatesList.add(taxRate);
        
        taxRatesMap.put(taxRate.blng__LegalEntity__c, taxRatesList);
        //QTB_CreditNoteHelper.taxRatesMap = taxRatesMap;
        
        List<Product2> productList = [Select Id,Name from Product2 where Name = 'Fair Market Value'];
        
        //SITAD Billing Account
        
        List<Account> sitadAccountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        sitadAccountList[0].QTB_Legal_Entity_Country__c='United States';
        sitadAccountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        sitadAccountList[0].ShippingCity = 'New York';
        sitadAccountList[0].ShippingState = 'New York';
        sitadAccountList[0].ShippingPostalCode = '22131';
        sitadAccountList[0].ShippingCountry = 'United States';
        sitadAccountList[0].QTB_Data_Management__c = false;
        sitadAccountList[0].QTB_scan__c = false;
        sitadAccountList[0].QTB_Records_Management__c = false;
        sitadAccountList[0].QTB_SITAD__c = true;
        sitadAccountList[0].QTB_Shred__c = false;    
        update sitadAccountList;
        
        Contact con = new Contact();
            con.LastName = 'Custom Last Name:20 ';
            con.FirstName = 'Custom First Name ';
            con.email = 'some1@email.com';
            con.AccountId = sitadAccountList[0].Id;
            con.MailingCountry = 'United States';
            con.IM_Role__c = 'PO Contact';
            insert con;
       set<Id> creditids=new set<id>();
         QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c(
                QTB_Billing_Account__c = sitadAccountList[0].Id,
                QTB_Status__c = 'Active',
                QTB_Start_Date__c = date.Today(),
                QTB_End_Date__c = date.today(),
                //QTB_PO_Type__c = 'Project',
                QTB_Customer_PO__c = 'QW2315',
                QTB_Amount__c = 10000,
                QTB_Service_Type__c = 'Mixed',
                QTB_PO_Type__c = 'Standard'
            );
            insert pOrder;
        System.runAs(userList[1]) {
            QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_INVOICE);
            QTB_InvoiceTriggerHandler.skipTriggerExecutionTestClass = true;
            List<blng__Invoice__c> parentInvoiceList = QTB_TestDataFactory.createInvoices(testAccounts);            
            parentInvoiceList[0].QTB_ReBill_Status__c = 'Usage Completed';
            parentInvoiceList[0].blng__InvoiceStatus__c = 'Posted';
            //parentInvoiceList[0].QTB_PurchaseOrder__c = pOrder.id;
            
            update parentInvoiceList;
            
            List<blng__CreditNote__c> creditList=new List<blng__CreditNote__c>();
            Map<id,blng__CreditNote__c> creditMap=new Map<id,blng__CreditNote__c>();
            //Account with CreditNote */
            
           /*
            Metadata_Activation_Settings__c cs = new Metadata_Activation_Settings__c();
            cs.Disable_Trigger__c = true;
            QTB_CreditNoteTriggerHandler CNtrigger = new QTB_CreditNoteTriggerHandler();
            CNtrigger.bypass();
            CNtrigger.IsDisabled();*/
            //QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_CREDITNOTE);
            //QTB_CreditNoteTriggerHandler.skipTriggerExecutionTestClass = true;
          /*  blng__CreditNote__c creditNote2 = new blng__CreditNote__c();
            creditNote2.blng__Account__c = sitadAccountList[0].Id;
            creditNote2.QTB_On_Account_Credit__c = true;
            creditNote2.blng__CreditNoteDate__c = date.today();
            creditNote2.QTB_Reason_Code__c = 'Legacy Credit'; 
            creditNote2.blng__Status__c = 'Draft';
            creditNote2.CurrencyIsoCode = 'USD';
            creditNote2.QTB_Purchase_Order__c =pOrder.id;
            creditNote2.blng__RelatedInvoice__c = parentInvoiceList[0].Id;
            creditNote2.QTB_Internal_PO_Notes__c = 'testdemo';
            creditNote2.QTB_Commercial_Credit__c = false;
            //creditNote2.QTB_Country__c = 'United States';
            creditList.add(creditNote2);
            
            blng__CreditNote__c creditNote3 = new blng__CreditNote__c();
            creditNote3.blng__Account__c = sitadAccountList[0].Id;
            creditNote3.QTB_On_Account_Credit__c = false;
            creditNote3.blng__CreditNoteDate__c = date.today();
            creditNote3.QTB_Reason_Code__c = 'Remarketing Credit'; 
            creditNote3.blng__Status__c = 'Draft';
            creditNote3.CurrencyIsoCode = 'USD';
            creditNote3.QTB_Purchase_Order__c =pOrder.id;
            creditNote3.blng__RelatedInvoice__c = parentInvoiceList[0].Id;
            creditNote3.QTB_Internal_PO_Notes__c = 'testdemo';
            creditNote3.QTB_Commercial_Credit__c = false;
            //creditList.add(creditNote3);
            
            blng__CreditNote__c creditNote4 = new blng__CreditNote__c();
            creditNote4.blng__Account__c = sitadAccountList[0].Id;
            creditNote4.QTB_On_Account_Credit__c = false;
            creditNote4.blng__CreditNoteDate__c = date.today();
            creditNote4.QTB_Reason_Code__c = 'Legacy Credit'; 
            creditNote4.blng__Status__c = 'Draft';
            creditNote4.CurrencyIsoCode = 'USD';
            creditNote4.QTB_Purchase_Order__c =pOrder.id;
            creditNote4.blng__RelatedInvoice__c = parentInvoiceList[0].Id;
            creditNote4.QTB_Internal_PO_Notes__c = 'testdemo';
            creditNote4.QTB_Commercial_Credit__c = false;
            creditList.add(creditNote4);
        
            
            insert creditList;
            
        }
         Test.stopTest();
        
} */
    
   @isTest
    static void makeFieldsReadyOnlyForPosted11Test(){
        Test.startTest();
        QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
        sweCustomSettings.Name = 'hong kong';
        sweCustomSettings.QTB_Country__c = 'hong kong';
        sweCustomSettings.QTB_Next_Sequence_Number__c = '8000055205';
        insert sweCustomSettings; 
        
         List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
            1,
            'Billing Account'
        );
        
         //Legal Entity
        blng__LegalEntity__c singaporeEntity = new blng__LegalEntity__c();
        singaporeEntity.Name = 'Test Legal Entity Singapore';
        singaporeEntity.blng__Active__c = true;
        singaporeEntity.blng__Country__c = 'Singapore';
        singaporeEntity.QTB_Type__c = 'Contract';
        singaporeEntity.QTB_Legal_Entity_Number__c = 45409;
        insert singaporeEntity; 
        
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
        singaporeFinancePeriod.blng__LegalEntity__c = singaporeEntity.id;
        singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert singaporeFinancePeriod;
        
        blng__LegalEntity__c USEntity= QTB_TestDataFactory.createLegalEntity('Singapore');
        testaccounts[0].QTB_Legal_Entity_Country__c='Singapore';
        testaccounts[0].SBQQ__TaxExempt__c = 'No';
        update testAccounts;
        List<product2> product = QTB_TestDataFactory.createProducts(1);  
        Group groupinfo = [SELECT id FROM Group WHERE Name = 'QTB VP India'  LIMIT 1  ];
        
        sbaa__Approver__c testApp1 = QTB_TestDataFactory.createApprover();
        testApp1.sbaa__User__c = UserInfo.getUserId();
        
        sbaa__Approver__c testApp2 = QTB_TestDataFactory.createApprover();
        testApp2.sbaa__GroupId__c = groupinfo.id;
        testApp2.QTB_Approver_Country__c = 'Singapore';
        testApp2.QTB_Approver_Level__c = 'VP';
        
        sbaa__Approver__c testApp3 = QTB_TestDataFactory.createApprover();
        testApp3.sbaa__GroupId__c = groupinfo.id;
        testApp3.QTB_Approver_Country__c = 'Singapore';
        testApp3.QTB_Approver_Level__c = 'SVP';
        
        sbaa__Approver__c testApp4 = QTB_TestDataFactory.createApprover();
        testApp4.sbaa__GroupId__c = groupinfo.id;
        testApp4.QTB_Approver_Country__c = 'Singapore';
        testApp4.QTB_Approver_Level__c = 'EVP';
        
        sbaa__Approver__c testApp5 = QTB_TestDataFactory.createApprover();
        testApp5.sbaa__GroupId__c = groupinfo.id;
        testApp5.QTB_Approver_Country__c = 'Singapore';
        testApp5.QTB_Approver_Level__c = 'CFO';
        
        update new List<sbaa__Approver__c>{ testApp1, testApp2,testApp3,testApp4,testApp5 };
            
            //Parent Invoice  
          List<blng__Invoice__c> parentInvoiceList = QTB_TestDataFactory.createInvoices(testAccounts);            
        parentInvoiceList[0].QTB_ReBill_Status__c = 'Usage Completed';
        parentInvoiceList[0].blng__InvoiceStatus__c = 'Posted';    
        update parentInvoiceList;
        
        //Rebill Invoice
        List<blng__Invoice__c> rebillInvoiceList = QTB_TestDataFactory.createInvoices(testAccounts);
        rebillInvoiceList[0].QTB_Parent_Invoice__c = parentInvoiceList[0].id;
        rebillInvoiceList[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        rebillInvoiceList[0].blng__InvoiceStatus__c = 'Draft';
        rebillInvoiceList[0].QTB_transfered_to_invoice_presentment__c = system.now();        
        update rebillInvoiceList;
        
        //Rebill Invoice Lines
        List<blng__InvoiceLine__c> invoiceLineList = QTB_TestDataFactory.createInvoiceLine(3,rebillInvoiceList,product);
        
        //Invoice Schedular
       /* blng__InvoiceScheduler__c invSch = new blng__InvoiceScheduler__c();
        invSch.Name = 'Test123456789';
        invSch.blng__Type__c = 'Once';
        invSch.blng__InvoiceBatches__c = 'Rebill Run';
        invSch.CurrencyIsoCode = 'USD';
        invSch.blng__StartDateTime__c = System.now()+100;
        invSch.blng__InvoiceDate__c = system.today();
        invSch.blng__TargetDate__c = system.today();
        invSch.QTB_Parent_Invoice__c = parentInvoiceList[0].id;
        invSch.QTB_Invoice_Period__c =singaporeFinancePeriod.id;
        insert invSch; */
        
        blng__InvoiceScheduler__c singaporeSchedule = new blng__InvoiceScheduler__c();
        singaporeSchedule.Name = 'test for Singapore';
        singaporeSchedule.blng__Type__c = 'Once';
        singaporeSchedule.blng__InvoiceBatches__c = 'Singapore-1st';
        singaporeSchedule.CurrencyIsoCode = 'SGD';
        singaporeSchedule.blng__StartDateTime__c = System.today().adddays(2);
        singaporeSchedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        singaporeSchedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
        singaporeSchedule.QTB_Legal_Entity__c  = singaporeEntity.id;
        singaporeSchedule.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
        insert singaporeSchedule;
        
        //Invoice Run
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.blng__InvoiceScheduler__c = singaporeSchedule.id;
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        
        //Bill Flow Controller
        QTB_Bill_Flow_Controller__c bfc = new QTB_Bill_Flow_Controller__c();
        bfc.Name = 'Test';
        bfc.Execute_Pre_Bill_Run__c = true;
        bfc.Execute_Post_Bill_Run__c = false;
        bfc.QTB_PreBill_Run_Status__c = 'Completed';
        bfc.Invoice_Scheduler__c = singaporeSchedule.id;
        insert bfc;
        
        //rebillInvoiceList[0].blng__InvoiceDate__c = System.today();
        rebillInvoiceList[0].blng__InvoiceStatus__c = 'Posted';       
        rebillInvoiceList[0].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        update rebillInvoiceList[0];            
        
        // Create CreditNote
        List<blng__CreditNote__c> creditNotes = new List<blng__CreditNote__c>();
        blng__CreditNote__c creditNote = new blng__CreditNote__c();
        creditNote.blng__Account__c = testAccounts[0].Id;
        creditNote.blng__CreditNoteDate__c = date.today();
        creditNote.QTB_Reason_Code__c = 'Account Creation';
        creditNote.blng__Status__c = 'Draft';
        creditNote.CurrencyIsoCode = 'SGD';
        creditNote.QTB_Manager_Approver__c = testApp1.Id;
        creditNote.QTB_VP_Approver__c = testApp2.Id;
        creditNote.QTB_SVP_Approver__c = testApp2.Id;
        creditNote.blng__Status__c = 'Draft';  
        creditNote.blng__RelatedInvoice__c =  parentInvoiceList[0].Id;
        creditNote.QTB_ReBill_Credit_Amount__c = 200; 
        creditNotes.add(creditNote);
        insert creditNotes;
       /* List<blng__CreditNoteLine__c> creditNoteLineList = [SELECT ID,QTB_Account__c,blng__CreditNote__c,QTB_Invoice__c,QTB_InvoiceLine__c,blng__Product__c,blng__TaxTreatment__c,blng__Status__c FROM blng__CreditNoteLine__c];
        List<blng__CreditNote__c> creditNoteList = [SELECT ID,blng__Account__c,blng__CreditNoteDate__c,QTB_Reason_Code__c,blng__Status__c,CurrencyIsoCode,blng__RelatedInvoice__c,QTB_Rebill_Invoice__c,QTB_Purchase_Order__c,QTB_On_Account_Credit__c,QTB_Credit_Note_Type__c,QTB_Internal_PO_Notes__c FROM blng__CreditNote__c WHERE ID =: creditNoteLineList[0].blng__CreditNote__c];
        List<blng__Invoice__c> invoiceList = [Select ID,QTB_Start_Date_MRC__c,blng__InvoiceStatus__c From blng__Invoice__c WHERE ID =: creditNoteLineList[0].QTB_Invoice__c ];
        invoiceList[0].QTB_transfered_to_invoice_presentment__c = system.now();
        update invoiceList[0];*/
        try{
           creditNote.QTB_Oracle_Error__c = 'TEST';
            Database.update(creditNotes);    
        }catch(Exception e){
            system.debug(e.getMessage());
            system.assertEquals(true,e.getMessage().contains('We can not modify processed Credit Notes record if Transferred to Invoice Presentment.'));
        }
        Test.stopTest();
        
        
    } 
    
     
}