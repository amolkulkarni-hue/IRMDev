/*****************************************************************************************************
* Test Class    : QTB_BatchableDocumentSendDeleteTest
* Author        : Accenture
* Purpose       : This is a test class for QTB_BatchableDocumentSendDelete
* Requirement   : 
* Change History: 01/22/2024
* Developer        Date           Description
* -------------------------------------------------------------------------------------------
*  Accenture      
*  Virtusa          01/22/2024      Refactor the class, added the comments
*******************************************************************************************************/
@isTest(seeAllData=false) 
Public class QTB_BatchableDocumentSendDeleteTest {
    
    static testmethod void methodBatchDocumentSendDelete() {
        //Document Send Lookup Queue object
        QTB_Documents_Send_Lookup_Queue__c docuLookUpObj = new QTB_Documents_Send_Lookup_Queue__c();
        docuLookUpObj.QTB_Status__c = 'New';
        insert docuLookUpObj;
        
        //Account
        //List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
        list<Account> updateAcc = new list<Account>();
        
        List<Account> accountList = new  List<Account>();
        Account acc1 = new Account();
        acc1.Name='Test Account US';
        acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
       // acc1.QTB_Legal_Entity_Country__c='Norway';
        acc1.CurrencyIsoCode = 'USD';
        acc1.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        acc1.ShippingCity = 'New York';
        acc1.ShippingState = 'New York';
        acc1.ShippingPostalCode = '22131';
       // acc1.ShippingCountry = 'Norway';
       // acc1.BillingCountry = 'Norway';
     //   acc1.QTB_Contract_Entity__c= legalEntity.id;
     //   acc1.QTB_Bill_Cycle_Day__c = 'Norway-26th';
        acc1.QTB_Language__c = 'en_US';
        acc1.QTB_Create_Parent_Billing_Account__c = true;
    acc1.IM_Hierarchy_Level__c = 'Billing Account';
        
        accountList.add(acc1);
        
        
        Account acc2 = new Account();
        acc2.Name='Test Account Denmark';
        acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();
       // acc2.QTB_Legal_Entity_Country__c='Denmark';
        acc2.CurrencyIsoCode = 'USD';
        acc2.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        acc2.ShippingCity = 'New York';
        acc2.ShippingState = 'New York';
        acc2.ShippingPostalCode = '22131';
      //  acc2.ShippingCountry = 'Denmark';
       // acc2.BillingCountry = 'Denmark';
     //   acc2.QTB_Contract_Entity__c= legalEntity.id;
     //   acc2.QTB_Bill_Cycle_Day__c = 'Denmark-26th';
        acc2.QTB_Language__c = 'en_US';
        acc2.QTB_Create_Parent_Billing_Account__c = true;
    acc2.IM_Hierarchy_Level__c = 'Billing Account';
        
        accountList.add(acc2);
        
        insert accountList;
            
            accountList[0].BillingCountry = 'Denmark';
            accountList[0].ShippingCountry = 'Denmark';
            accountList[0].QTB_Legal_Entity_Country__c = 'Denmark';
            accountList[0].QTB_Bill_Cycle_Day__c = 'Denmark-26th';
            updateAcc.add(accountList[0]);
        
        
            accountList[1].BillingCountry = 'Norway';
            accountList[1].ShippingCountry = 'Norway';
            accountList[1].QTB_Legal_Entity_Country__c = 'Norway';
            accountList[1].QTB_Bill_Cycle_Day__c = 'Norway-26th';
            updateAcc.add(accountList[1]); 
        
        update updateAcc;
        
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product = QTB_TestDataFactory.createProducts(1);
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        database.update(product);
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        //Opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
      //  oppList[0].recordtypeid = QTB_Utils.OPP_BILL_RECTYPEID;
        oppList[0].Pricebook2Id = pricebookId;
        database.update(oppList);
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].recordtypeId = QTB_Utils.QUOTE_BILL_RECTYPEID;
        database.update(quoteList);
        
        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
        
        Test.startTest();
        //Order
        List<Order> orderList = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        database.update(orderList);
        
        SBQQ.TriggerControl.disable();
        
        //OrderItem
        List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,product[0].Id,quoteLinesList,standardPrice);
        orderItemList[0].QTB_Payment_Term__c = '5';
        update orderItemList;
        
        //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
        
        //UsageSummary
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList[0],orderItemList[0]);        
        blng__UsageSummary__c usagesummary = usageSum[0];        
        usagesummary.blng__Status__c = 'Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary.blng__Subtotal__c = 100;
        usagesummary.blng__TotalQuantity__c = 10;
        usagesummary.blng__PreratedQuantity__c = 20;
        usagesummary.blng__UnbilledQuantity__c = 1;
        usagesummary.blng__UnitPrice__c = 400;
        usagesummary.blng__PreratedAmount__c = 22;
        database.update(usagesummary);
        
         IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';        
        insert im;
        
        QTB_Bill_Code_Product_Lookup__c productLookup = new QTB_Bill_Code_Product_Lookup__c(
            QTB_Source_Bill_Code__c = 'VALID_CODE',
            QTB_Country__c = im.Id,
            QTB_Product2__c = product[0].id
        );
        insert productLookup;
        
        //Usage
        List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        usageList[0].QTB_Product_Identifier_1__c = productLookup.id;
        database.update(usageList);
        invoiceList[0].blng__InvoiceStatus__c = 'Cancelled';
        update invoiceList;
        
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
        //InvoiceRun
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__InvoiceScheduler__c = blngInvoiceSchedular.id;
        invoiceRun.blng__Status__c = 'Started';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2021-09-01');
        insert invoiceRun;        
        
        //InvoiceLine
      /*  List<blng__InvoiceLine__c> invLineList = QTB_TestDataFactory.createInvoiceLine(1,invoiceList,product);
        invLineList[0].blng__OrderProduct__c = orderItemList[0].id;
        invLineList[0].blng__UsageSummary__c = usagesummary.id;
        invLineList[0].blng__Subtotal__c =123;
        invLineList[0].blng__TaxStatus__c = 'Completed';
        update invLineList;*/
        
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
          invoiceLine.Name = product[0].Name;
          invoiceLine.blng__Invoice__c = invoiceList[0].Id;
          invoiceLine.blng__Product__c = product[0].Id;
          invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
          invoiceLine.blng__Quantity__c = 10;
          invoiceLine.blng__UnitPrice__c = 5;
          invoiceLine.blng__TaxPercentageApplied__c = 24;
          invoiceLine.blng__OrderProduct__c = orderItemList[0].id;
        invoiceLine.blng__UsageSummary__c = usagesummary.id;
          invoiceLine.blng__Subtotal__c =123;
          invoiceLine.blng__TaxCountry__c = 'United States';
        invoiceLine.blng__TaxStatus__c = 'Completed';
          
          insert invoiceLine;
        
        
        List<blng__Invoice__c> invoiceQuery=[SELECT id,blng__InvoiceStatus__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Invoice__c.QTB_Bill_Cycle_Day__c
                                             FROM blng__Invoice__c];
        invoiceQuery[0].blng__InvoiceStatus__c='Posted';
        invoiceQuery[1].blng__InvoiceStatus__c='Posted';
        update invoiceQuery;
        
        List<blng__Invoice__c> invoiceQuery1=[SELECT id,blng__InvoiceStatus__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Invoice__c.QTB_Bill_Cycle_Day__c
                                             FROM blng__Invoice__c];
        
        for(blng__Invoice__c y :invoiceQuery1){
            system.debug('y.blng__InvoiceStatus__c '+y.blng__InvoiceStatus__c);
            system.debug('y.blng__InvoiceStatus__c '+y.blng__Account__r.QTB_Bill_Cycle_Day__c);
          //  system.debug('blng__Invoice__c.QTB_Bill_Cycle_Day__c '+y.blng__Invoice__c.QTB_Bill_Cycle_Day__c);
        }
                         
        
        //DocumentSendLookupQueue object with Delete status for Invoice
        QTB_Documents_Send_Lookup_Queue__c testInvice = new QTB_Documents_Send_Lookup_Queue__c();            
        testInvice.QTB_Status__c = 'Delete';
        testInvice.QTB_Invoice__c=invoiceList[0].id;
        insert testInvice;
        
        QTB_Documents_Send_Lookup_Queue__c testInvice1 = new QTB_Documents_Send_Lookup_Queue__c();            
        testInvice1.QTB_Status__c = 'Delete';
        testInvice1.QTB_Invoice__c = invoiceList[1].id;
        insert testInvice1;
        
        
        //DocumentSendLookupQueue object with Delete status for Invoice
        QTB_Documents_Send_Lookup_Queue__c docuLookUpObjInvoice = new QTB_Documents_Send_Lookup_Queue__c();
        docuLookUpObjInvoice.id = docuLookUpObj.id;
        docuLookUpObjInvoice.QTB_Invoice__c = invoiceQuery[0].id;
        update docuLookUpObjInvoice;
        
        //CreditNote
        List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accountList);
        blng__CreditNote__c crdObj = new blng__CreditNote__c();
        crdObj.Id = creditNotes[0].Id;
        crdObj.QTB_Credit_Note_Type__c = 'Credit Only';
        update crdObj;
        
        System.debug('creditNotes>>>>'+creditNotes);
        
        list<blng__CreditNote__c> crdNtUpdateInsert = new list<blng__CreditNote__c>();
        blng__CreditNote__c crdnIn = new blng__CreditNote__c();
        crdnIn.blng__Account__c = accountList[1].id;
        crdnIn.blng__CreditNoteDate__c = System.today();
        crdnIn.QTB_Reason_Code__c = 'Account Creation';
        crdnIn.blng__Status__c = 'Draft';
        crdnIn.QTB_Last_Invoice_Portal_Sent__c = null;
        crdNtUpdateInsert.add(crdnIn);
        insert crdNtUpdateInsert; 
        
        //CreditNoteLine
        List<blng__CreditNoteLine__c> ListCredirLines = QTB_TestDataFactory.createCreditNoteLine(1,accountList[0],crdNtUpdateInsert[0],invoiceList[0],invoiceLine,product[0]);
        System.debug('ListCredirLines@@'+ListCredirLines);
        
        list<blng__CreditNote__c> crdNtUpdate = new list<blng__CreditNote__c>();
        blng__CreditNote__c crdn = new blng__CreditNote__c();
        crdn.id = crdNtUpdateInsert[0].id;
        crdn.ApprovalStatus__c = 'Approved';
        crdn.blng__Status__c = 'Posted';
        crdn.QTB_Credit_Note_Type__c = 'Credit Only';
        crdNtUpdate.add(crdn);
        update crdNtUpdate;
        
        //DocumentSendLookupQueue object with Delete status for CreditNote
        QTB_Documents_Send_Lookup_Queue__c testcrdtnt = new QTB_Documents_Send_Lookup_Queue__c();            
        testcrdtnt.QTB_Status__c = 'Delete';
        testcrdtnt.QTB_Credit_Note__c=crdNtUpdateInsert[0].id;            
        insert testcrdtnt;
        
        //DocumentSendLookupQueue object with Delete status for CreditNote
        QTB_Documents_Send_Lookup_Queue__c docuLookUpObjCredit = new QTB_Documents_Send_Lookup_Queue__c();
        docuLookUpObjCredit.id = docuLookUpObj.id;
        docuLookUpObjCredit.QTB_Credit_Note__c = crdNtUpdate[0].id;
        update docuLookUpObjCredit;
        
        
        blng__LegalEntity__c denmarkentity = QTB_TestDataFactory.createLegalEntity(
            'Denmark'
        );
        denmarkentity.QTB_Legal_Entity_Number__c = 66506;
        update denmarkentity;
        
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
        denmarkFinancePeriod.blng__LegalEntity__c = denmarkentity.id;
        denmarkFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert denmarkFinancePeriod;
        
        blng__InvoiceScheduler__c newins = new blng__InvoiceScheduler__c();
        newins.Name ='Test-' +'Denmark-26th' +String.valueOf(Crypto.getRandomInteger());            
        newins.blng__InvoiceBatches__c = 'Denmark-26th';
        newins.blng__StartDateTime__c = system.now() + 1;
        newins.blng__Type__c = 'Once';
        //  blngIn.blng__InvoiceDayOfMonth__c = '4';
        //  blngIn.blng__TargetDayOfMonth__c = '6';
        newins.blng__ApexJobId__c = '145678';
        newins.blng__TargetDate__c = DATE.newInstance(2021, 1, 27);
        newins.QTB_Legal_Entity__c = denmarkentity.id;
        
        newins.blng__StartDateTime__c = System.today().adddays(5);
        newins.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        newins.blng__TargetDate__c = Date.valueOf('2021-09-01');
        newins.QTB_Invoice_Period__c = denmarkFinancePeriod.id ;
        insert newins;
        
        //InvoiceScheduler
        /*blng__InvoiceScheduler__c newins = new blng__InvoiceScheduler__c(
            Name='Test sched',
            blng__Type__c='Once',
            blng__InvoiceBatches__c='Denmark-26th',
            blng__StartDateTime__c = system.now()+1,
            blng__TargetDate__c = system.today().addDays(2)
        );
        insert newins;
        */
        //DocumentSendLookupQueue object with Delete status for InvoiceScheduler
        QTB_Documents_Send_Lookup_Queue__c newtest = new QTB_Documents_Send_Lookup_Queue__c();
        newtest.QTB_Status__c='Delete';
        newtest.QTB_Invoice_Scheduler__c = blngInvoiceSchedular.id;
        insert newtest;
        
        //DocumentSendLookupQueue object with Delete status for InvoiceScheduler
        QTB_Documents_Send_Lookup_Queue__c newtest1 = new QTB_Documents_Send_Lookup_Queue__c();
        newtest1.QTB_Status__c='Delete';
       // newtest1.QTB_Invoice__c = invoiceQuery[1].id;
        newtest1.QTB_Invoice_Scheduler__c = newins.id;
        insert newtest1;
        
        //Content Version
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Network.
        
        DateTime myDateTime = System.now();
        String formatted = myDateTime.format('ddMMMyyyyhhmmss');
        system.debug(formatted);
        conVer.PathOnClient = 'DM_S_BILLTRUST_TRANSACTION_.xml';
        conVer.Title = 'DM_S_BILLTRUST_TRANSACTION_.xml'; // Display name of the files
        
        conVer.VersionData = blob.valueOf('pageData');//File content
        insert conVer;
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        
        //Content Document
        list<ContentDocumentLink> contentDocList = new list<ContentDocumentLink>();
        ContentDocumentLink contentDoc = new ContentDocumentLink();
        contentDoc.ContentDocumentId = conDoc;
        contentDoc.LinkedEntityId = docuLookUpObjCredit.id; // We can use objectId,GroupId etc
        contentDoc.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        contentDoc.Visibility = 'AllUsers'; //AllUsers, InternalUsers, SharedUsers
        contentDocList.add(contentDoc);
        insert contentDocList;
        
        QTB_Documents_Send_Lookup_Queue__c docuLookUpObjUpdate = new QTB_Documents_Send_Lookup_Queue__c();
        docuLookUpObjUpdate.id = docuLookUpObj.id;
        docuLookUpObjUpdate.QTB_Status__c = 'Delete';
        update docuLookUpObjUpdate;
        
        QTB_BatchableDocumentSendDelete obj = new QTB_BatchableDocumentSendDelete();
        DataBase.executeBatch(obj);
        System.Test.stopTest();
    } 
    
     static testmethod void methodBatchDocumentSendDelete2() {
        
        //Document Send Lookup Queue object
        QTB_Documents_Send_Lookup_Queue__c docuLookUpObj = new QTB_Documents_Send_Lookup_Queue__c();
        docuLookUpObj.QTB_Status__c = 'New';
        insert docuLookUpObj;
        
        //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(2,'Billing Account');
        list<Account> updateAcc = new list<Account>();
        
            
            accountList[0].BillingCountry = 'Denmark';
            accountList[0].ShippingCountry = 'Denmark';
            accountList[0].QTB_Legal_Entity_Country__c = 'Denmark';
            accountList[0].QTB_Bill_Cycle_Day__c = 'Denmark-26th';
            updateAcc.add(accountList[0]);
        
        
            accountList[0].BillingCountry = 'Norway';
            accountList[1].ShippingCountry = 'Norway';
            accountList[1].QTB_Legal_Entity_Country__c = 'Norway';
            accountList[1].QTB_Bill_Cycle_Day__c = 'Norway-26th';
            updateAcc.add(accountList[1]);
        
        update updateAcc;
        
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product = QTB_TestDataFactory.createProducts(1);
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        database.update(product);
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        //Opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].recordtypeid = QTB_Utils.OPP_BILL_RECTYPEID;
        oppList[0].Pricebook2Id = pricebookId;
        database.update(oppList);
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].recordtypeId = QTB_Utils.QUOTE_BILL_RECTYPEID;
        database.update(quoteList);
        
        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
        
        Test.startTest();
        //Order
        List<Order> orderList = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        database.update(orderList);
        
        SBQQ.TriggerControl.disable();
        
        //OrderItem
        List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,product[0].Id,quoteLinesList,standardPrice);
        orderItemList[0].QTB_Payment_Term__c = '5';
        update orderItemList;
        
        //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
        
        //UsageSummary
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList[0],orderItemList[0]);        
        blng__UsageSummary__c usagesummary = usageSum[0];        
        usagesummary.blng__Status__c = 'Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary.blng__Subtotal__c = 100;
        usagesummary.blng__TotalQuantity__c = 10;
        usagesummary.blng__PreratedQuantity__c = 20;
        usagesummary.blng__UnbilledQuantity__c = 1;
        usagesummary.blng__UnitPrice__c = 400;
        usagesummary.blng__PreratedAmount__c = 22;
        database.update(usagesummary);
        
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';        
        insert im;
        
        QTB_Bill_Code_Product_Lookup__c productLookup = new QTB_Bill_Code_Product_Lookup__c(
            QTB_Source_Bill_Code__c = 'VALID_CODE',
            QTB_Country__c = im.Id,
            QTB_Product2__c = product[0].id
        );
        insert productLookup;
        
        //Usage
        List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        usageList[0].QTB_Product_Identifier_1__c = productLookup.id;
        database.update(usageList);
        invoiceList[0].blng__InvoiceStatus__c = 'Cancelled';
        update invoiceList;
        
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
        //InvoiceRun
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__InvoiceScheduler__c = blngInvoiceSchedular.id;
        invoiceRun.blng__Status__c = 'Started';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2021-09-01');
        insert invoiceRun;        
        
        //InvoiceLine
      /*  List<blng__InvoiceLine__c> invLineList = QTB_TestDataFactory.createInvoiceLine(1,invoiceList,product);
        invLineList[0].blng__OrderProduct__c = orderItemList[0].id;
        invLineList[0].blng__UsageSummary__c = usagesummary.id;
        invLineList[0].blng__Subtotal__c =123;
        invLineList[0].blng__TaxStatus__c = 'Completed';
        update invLineList;*/
        
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
          invoiceLine.Name = product[0].Name;
          invoiceLine.blng__Invoice__c = invoiceList[0].Id;
          invoiceLine.blng__Product__c = product[0].Id;
          invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
          invoiceLine.blng__Quantity__c = 10;
          invoiceLine.blng__UnitPrice__c = 5;
          invoiceLine.blng__TaxPercentageApplied__c = 24;
          invoiceLine.blng__OrderProduct__c = orderItemList[0].id;
        invoiceLine.blng__UsageSummary__c = usagesummary.id;
          invoiceLine.blng__Subtotal__c =123;
          invoiceLine.blng__TaxCountry__c = 'United States';
        invoiceLine.blng__TaxStatus__c = 'Completed';
          
          insert invoiceLine;
        
        
        List<blng__Invoice__c> invoiceQuery=[SELECT id,blng__InvoiceStatus__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Invoice__c.QTB_Bill_Cycle_Day__c
                                             FROM blng__Invoice__c];
        invoiceQuery[0].blng__InvoiceStatus__c='Posted';
        invoiceQuery[1].blng__InvoiceStatus__c='Posted';
        update invoiceQuery;
        
        List<blng__Invoice__c> invoiceQuery1=[SELECT id,blng__InvoiceStatus__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Invoice__c.QTB_Bill_Cycle_Day__c
                                             FROM blng__Invoice__c];
        
        for(blng__Invoice__c y :invoiceQuery1){
            system.debug('y.blng__InvoiceStatus__c '+y.blng__InvoiceStatus__c);
            system.debug('y.blng__InvoiceStatus__c '+y.blng__Account__r.QTB_Bill_Cycle_Day__c);
          //  system.debug('blng__Invoice__c.QTB_Bill_Cycle_Day__c '+y.blng__Invoice__c.QTB_Bill_Cycle_Day__c);
        }
                         
        
        //DocumentSendLookupQueue object with Delete status for Invoice
        QTB_Documents_Send_Lookup_Queue__c testInvice = new QTB_Documents_Send_Lookup_Queue__c();            
        testInvice.QTB_Status__c = 'Delete';
        //testInvice.QTB_Invoice__c=invoiceList[0].id;
        insert testInvice;
        
        QTB_Documents_Send_Lookup_Queue__c testInvice1 = new QTB_Documents_Send_Lookup_Queue__c();            
        testInvice1.QTB_Status__c = 'Delete';
       // testInvice1.QTB_Invoice__c = invoiceList[1].id;
        insert testInvice1;
        
        
              
        //CreditNote
        List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(updateAcc);
        blng__CreditNote__c crdObj = new blng__CreditNote__c();
        crdObj.Id = creditNotes[0].Id;
        crdObj.QTB_Credit_Note_Type__c = 'Credit Only';
        update crdObj;
        
        System.debug('creditNotes>>>>'+creditNotes);
        
        list<blng__CreditNote__c> crdNtUpdateInsert = new list<blng__CreditNote__c>();
        blng__CreditNote__c crdnIn = new blng__CreditNote__c();
        crdnIn.blng__Account__c = updateAcc[1].id;
        crdnIn.blng__CreditNoteDate__c = System.today();
        crdnIn.QTB_Reason_Code__c = 'Account Creation';
        crdnIn.blng__Status__c = 'Draft';
        crdnIn.QTB_Last_Invoice_Portal_Sent__c = null;
        crdNtUpdateInsert.add(crdnIn);
        insert crdNtUpdateInsert; 
        
        //CreditNoteLine
        List<blng__CreditNoteLine__c> ListCredirLines = QTB_TestDataFactory.createCreditNoteLine(1,updateAcc[0],crdNtUpdateInsert[0],invoiceList[0],invoiceLine,product[0]);
        System.debug('ListCredirLines@@'+ListCredirLines);
        
        list<blng__CreditNote__c> crdNtUpdate = new list<blng__CreditNote__c>();
        blng__CreditNote__c crdn = new blng__CreditNote__c();
        crdn.id = crdNtUpdateInsert[0].id;
        crdn.ApprovalStatus__c = 'Approved';
        crdn.blng__Status__c = 'Posted';
        crdn.QTB_Credit_Note_Type__c = 'Credit Only';
        crdNtUpdate.add(crdn);
        update crdNtUpdate;
        
        //DocumentSendLookupQueue object with Delete status for CreditNote
        QTB_Documents_Send_Lookup_Queue__c testcrdtnt = new QTB_Documents_Send_Lookup_Queue__c();            
        testcrdtnt.QTB_Status__c = 'Delete';
        testcrdtnt.QTB_Credit_Note__c=crdNtUpdateInsert[0].id;            
        insert testcrdtnt;
        
        //DocumentSendLookupQueue object with Delete status for CreditNote
        QTB_Documents_Send_Lookup_Queue__c docuLookUpObjCredit = new QTB_Documents_Send_Lookup_Queue__c();
        docuLookUpObjCredit.id = docuLookUpObj.id;
        docuLookUpObjCredit.QTB_Credit_Note__c = crdNtUpdate[0].id;
        update docuLookUpObjCredit;
        
        
        blng__LegalEntity__c denmarkentity = QTB_TestDataFactory.createLegalEntity(
            'Denmark'
        );
        denmarkentity.QTB_Legal_Entity_Number__c = 66506;
        update denmarkentity;
        
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
        denmarkFinancePeriod.blng__LegalEntity__c = denmarkentity.id;
        denmarkFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert denmarkFinancePeriod;
        
        blng__InvoiceScheduler__c newins = new blng__InvoiceScheduler__c();
        newins.Name ='Test-' +'Denmark-26th' +String.valueOf(Crypto.getRandomInteger());            
        newins.blng__InvoiceBatches__c = 'Denmark-26th';
        newins.blng__StartDateTime__c = system.now() + 1;
        newins.blng__Type__c = 'Once';
        //  blngIn.blng__InvoiceDayOfMonth__c = '4';
        //  blngIn.blng__TargetDayOfMonth__c = '6';
        newins.blng__ApexJobId__c = '145678';
        newins.blng__TargetDate__c = DATE.newInstance(2021, 1, 27);
        newins.QTB_Legal_Entity__c = denmarkentity.id;
        
        newins.blng__StartDateTime__c = System.today().adddays(5);
        newins.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        newins.blng__TargetDate__c = Date.valueOf('2021-09-01');
        newins.QTB_Invoice_Period__c = denmarkFinancePeriod.id ;
        insert newins;
        
        //InvoiceScheduler
        /*blng__InvoiceScheduler__c newins = new blng__InvoiceScheduler__c(
            Name='Test sched',
            blng__Type__c='Once',
            blng__InvoiceBatches__c='Denmark-26th',
            blng__StartDateTime__c = system.now()+1,
            blng__TargetDate__c = system.today().addDays(2)
        );
        insert newins;
        */
        //DocumentSendLookupQueue object with Delete status for InvoiceScheduler
        QTB_Documents_Send_Lookup_Queue__c newtest = new QTB_Documents_Send_Lookup_Queue__c();
        newtest.QTB_Status__c='Delete';
     //   newtest.QTB_Invoice_Scheduler__c = blngInvoiceSchedular.id;
        insert newtest;
        
        //DocumentSendLookupQueue object with Delete status for InvoiceScheduler
        QTB_Documents_Send_Lookup_Queue__c newtest1 = new QTB_Documents_Send_Lookup_Queue__c();
        newtest1.QTB_Status__c='Delete';
       // newtest1.QTB_Invoice__c = invoiceQuery[1].id;
        newtest1.QTB_Invoice_Scheduler__c = newins.id;
        insert newtest1;
        
        //Content Version
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Network.
        
        DateTime myDateTime = System.now();
        String formatted = myDateTime.format('ddMMMyyyyhhmmss');
        system.debug(formatted);
        conVer.PathOnClient = 'DM_S_BILLTRUST_TRANSACTION_.xml';
        conVer.Title = 'DM_S_BILLTRUST_TRANSACTION_.xml'; // Display name of the files
        
        conVer.VersionData = blob.valueOf('pageData');//File content
        insert conVer;
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        
        //Content Document
        list<ContentDocumentLink> contentDocList = new list<ContentDocumentLink>();
        ContentDocumentLink contentDoc = new ContentDocumentLink();
        contentDoc.ContentDocumentId = conDoc;
        contentDoc.LinkedEntityId = docuLookUpObjCredit.id; // We can use objectId,GroupId etc
        contentDoc.ShareType = 'I'; //V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        contentDoc.Visibility = 'AllUsers'; //AllUsers, InternalUsers, SharedUsers
        contentDocList.add(contentDoc);
        insert contentDocList;
        
        QTB_Documents_Send_Lookup_Queue__c docuLookUpObjUpdate = new QTB_Documents_Send_Lookup_Queue__c();
        docuLookUpObjUpdate.id = docuLookUpObj.id;
        docuLookUpObjUpdate.QTB_Status__c = 'Delete';
        update docuLookUpObjUpdate;
        
        QTB_BatchableDocumentSendDelete obj = new QTB_BatchableDocumentSendDelete();
        DataBase.executeBatch(obj);
        System.Test.stopTest();
    
     }
    
}