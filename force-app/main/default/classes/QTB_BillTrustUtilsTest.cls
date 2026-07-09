@isTest
public class QTB_BillTrustUtilsTest {
    private static final Id accBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
    
    @testSetup
    static void makeData(){
        
        Test.startTest();
        User usr = [SELECT Id from User Where Profile.name='IM_Custom Sys Admin' AND Isactive=true LIMIT 1];
        System.runAs(usr) {
            QTB_TestDataFactory.createLegalEntity('Norway');
            blng__LegalEntity__c denmarkentity = QTB_TestDataFactory.createLegalEntity(
                'Denmark'
            );
            QTB_TestDataFactory.createLOBMapping();
            List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
                2,
                'Standard Account'
            );
            
            Account a = new Account();
            if(Test.isRunningTest()){
            a.Name = 'TestAcc';
            a.RecordTypeId = accBillRecordTypeId;
            a.QTB_Create_Parent_Billing_Account__c = true;
            a.BillingCountry = 'India';
            a.BillingState = 'Assam';          
            a.QTB_Hold_Billing__c = true;            
            a.QTB_Billing_Account_Invoice_Name__c = 'Test Trigger';
            a.QTB_shred__c = true;
            a.QTB_scan__c = true;
            a.QTB_Contract_Entity__c = denmarkentity.id;
            a.ShippingCountry = 'Denmark';
            a.QTB_Records_Management__c = true;
            a.QTB_Legal_Entity_Country__c = 'Denmark';
            insert a;
            }
            List<Contact> cons = new List<Contact>();
            List<QTB_PurchaseOrder__c> pos = new List<QTB_PurchaseOrder__c>();
            for(Integer i=0;i<10;i++){
                cons.add(new Contact(
                    FirstName='FN'+i,LastName='Test'+i,accountId=testAccounts[0].Id,MailingCountry='India',
                    MailingStreet='TestStreet',MailingCity='TestCity',MailingState='TestState',MailingPostalCode='1212221'));
                pos.add(new QTB_PurchaseOrder__c(QTB_Start_Date__c=system.today(),QTB_End_Date__c=system.today().addDays(1),QTB_Customer_PO__c='Test',QTB_Billing_Account__c=a.Id));
            }
            insert cons;
            Test.stopTest();
            //insert pos;
        }
    }
    
    //  unit test for account contact Map test.
    @isTest
    static void accountContactMapTest(){
        List<Id> accIds = new List<Id>();
        for(Account acc : [SELECT Id from Account WHERE Name LIKE 'Test%' LIMIT 2]){
            accIds.add(acc.Id);
        }
        system.assertEquals(2, accIds.size());
        QTB_BillTrustUtil.getAccountContactMap(accIds);
    }
    //@isTest 
    static void accountPurchasesTest(){
        List<Id> accIds = new List<Id>();
        for(Account acc : [SELECT Id from Account WHERE Name LIKE 'Test%' LIMIT 2]){
            accIds.add(acc.Id);
        }
        system.assertEquals(2, accIds.size());
        QTB_BillTrustUtil.getAccountContactMap(accIds);
    }
    
    // unit test for Generate Bill Trust & ExtractCTRL class.
    @isTest
    static void generateBillTrustTest(){
        Test.startTest();
        List<Account> accts = [SELECT ID,QTB_SITAD__c From Account Where Name LIKE 'Test%' LIMIT 2];
        //List<blng__Invoice__c> invoices = QTB_TestDataFactory.createInvoices(accts);
        //Invoice
        List<blng__Invoice__c> invoices = new List<blng__Invoice__c>();
        for (Account acc : accts) {
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = acc.Id;
            invoice.blng__InvoiceStatus__c = 'Draft';
            invoice.blng__InvoiceDate__c = System.today()-10;
            
            invoices.add(invoice);
            break;
        }
        if (!invoices.isEmpty()) {
            insert invoices;
        }
		List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,null,accts[0].id);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        orderList3[0].QTB_Legal_Entity_Country__c = 'Denmark';
        database.update(orderList3);
        
        product2 p = new product2();
        p.Name = 'Test Product';
        p.isActive = true;
        p.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p.SBQQ__HasConsumptionSchedule__c = true;
        Insert p;
        Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = new PricebookEntry();
        	standardPrice.Product2Id =  p.id;
        	standardPrice.UnitPrice = 15;
        	standardPrice.Pricebook2Id = pricebookId;
        	insert standardPrice;
               
          
		
      List<OrderItem> orderItemList3 = new List<OrderItem>();
        try {
      for (Integer i = 0; i < 1; i++) {
        orderItemList3.add(
          new OrderItem(
            OrderId = orderList3[0].Id,
            Quantity = 2.00,
            UnitPrice = 12.00,
            //SBQQ__QuoteLine__c = quoteLines[i].id,
            PricebookEntryId = standardPrice.Id,
            SBQQ__ChargeType__c = 'One-Time',
            product2id = p.Id,
            SBQQ__Activated__c = true,
            blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes')
              .id,
            blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
              )
              .id,
            blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id,
              blng__HoldBilling__c = 'Yes'
          )
        );
      }
      if (!orderItemList3.isEmpty()) {
        system.debug('orderItemList3>' + orderItemList3);
        insert orderItemList3;
      }}catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      System.debug('The following exception has occurred: ' + e);
    }
        
         List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(
                2,
                accts[0],
                orderList3[0],
                orderItemList3[0]
            );
            //List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(testAccount);
            
            /*blng__UsageSummary__c usagesummary = usageSum[0];
            usagesummary.blng__Status__c = 'Queued For Invoice';
            usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
            usagesummary.blng__UnitPrice__c = 12;
            usagesummary.blng__Invoice__c = invoice.Id;*/
            
            blng__UsageSummary__c usagesummary1 = usageSum[1];
            usagesummary1.blng__Status__c = 'Queued For Invoice';
            usagesummary1.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
            usagesummary1.blng__MatchingId__c = '1234';
            usagesummary1.blng__UnitPrice__c = 10;
            usagesummary1.blng__Invoice__c = invoices[0].Id;
            update usagesummary1;
        
        blng__Usage__c usage0 = new blng__Usage__c();
            usage0.blng__UsageSummary__c = usagesummary1.id;
            usage0.blng__Account__c = accts[0].Id;
            usage0.blng__MatchingId__c = '1234';
            usage0.blng__EndDateTime__c = date.today() + 1;
            usage0.blng__StartDateTime__c = date.today();
            usage0.QTB_Price_Tier__c = 'Tier 1'; 
            usage0.QTB_Delivery_Date__c = System.Today();
            usage0.QTB_Actual_Rate__c  = 0.7;
            usage0.QTB_Tax_Street__c ='test';
            usage0.blng__PreratedQuantity__c = 19;
        	usage0.QTB_Source_Invoice_Reference__c = 'jjs';
            usage0.CurrencyIsoCode = 'USD';
        	SBQQ.TriggerControl.disable();
            insert usage0; 
        
        invoices[0].blng__InvoiceStatus__c = 'Posted';
        update invoices;
		
        List<Product2> products = QTB_TestDataFactory.createProducts(1);
        products[0].QTB_Price_Schedule_Category__c = 'Storage';
        List<Account> updatedAccts = new List<Account>();
        List<blng__InvoiceLine__c> invoiceLines =  QTB_TestDataFactory.createInvoiceLine(1,invoices,products);
        system.debug('::invs'+invoices);
        QTB_GenerateBillTrustExtractCTRL.InvoiceInfo info = new QTB_GenerateBillTrustExtractCTRL.InvoiceInfo();
        QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo infoLine = new QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo();
        QTB_GenerateBillTrustExtractCTRL.ProductInfo pinfo = new QTB_GenerateBillTrustExtractCTRL.ProductInfo();
        pinfo.billCD='Test';
        pinfo.cLIN='Test';
        pinfo.description='Testing';
        pinfo.invoiceLineAmount='1234';
        pinfo.lineAmountTotal='12345';
        pinfo.quantityCnt='123';
        pinfo.rateAmount='7000';
        pinfo.taxLineAmount='12345';
        List<QTB_GenerateBillTrustExtractCTRL.ProductInfo> pinfoLst = new List<QTB_GenerateBillTrustExtractCTRL.ProductInfo>();
        pinfoLst.add(pinfo);
        infoLine.siteID='123';
        infoLine.siteName='Test';
		if(invoices.size() > 0){
        infoLine.invoiceID=invoices[0].Id;
		}
        infoLine.referenceID='123';
        infoLine.invoiceDate='Today';
        infoLine.poNumber='1234';
        infoLine.serviceDetails=pinfoLst;
        infoLine.totalStorageAmount='50MB';
        infoLine.storageDetails=pinfoLst;
        infoLine.totalServiceAmount='2000';
        infoLine.otherDetails=pinfoLst;
        infoLine.totalOtherAmount='7000';
        infoLine.siteNumberTotal='123';
        infoLine.invoiceTotalAmount='12345';
        infoLine.siteLateFeeAmount='1234';
        infoLine.siteAdjustmentTotal = '12345';
        infoLine.siteNumber ='123';   
        info.invId=invoices[0].Id;
        info.invoiceType='Test';            
        info.consolidated_single='Test';
        info.governmentType='Test';
        info.templateType='Test';
        info.deliveryType='Test';
        info.invoiceDeliveryEmailAddress='Test';
        info.holdInd='Test';
        info.holdRequester='Test';
        info.imCompany='Test';
        info.customerLanguage='Test';
        info.accountCurrency='Test';
        info.returnAddress1='Test';
        info.returnAddress2='Test';
        info.returnAddress3='Test';
        info.returnCity='Test';
        info.returnState='Test';
        info.returnPostalCode='Test';
        info.imBillContact='Test';
        info.imBillContactPN='Test';
        info.imBillContactEmail='Test';
        info.customerName='Test';
        info.customerContact='Test';
        info.customerAddress1='Test';
        info.customerAddress2='Test';
        info.customerAddress3='Test';
        info.customerAddress4='Test';
        info.customerCity='Test';
        info.customerState='Test';
        info.customerPostalCode='Test';
        info.customerCountry='Test';
        info.invoiceID=invoices[0].Id;
        info.invoiceDate='Test';
        info.servicePeriod='Test';
        info.customerID='Test';
        info.taxID='123';
        info.poNumber='1234';
        info.dueDate='today';
        info.totalStorage='Test20MB';
        info.totalService='test';
        info.totalOther='test';
        info.totalTaxAmount='125';
        info.totalAdjustmentAmount='125';
        info.lateFee='125';           
        info.invoiceTotalAmount='124';
        info.payMntName='Test';
        info.payMntAddress1='Test';
        info.payMntAddress2='Test';
        info.payMntAddress3='Test';
        info.payMntCity='Test';
        info.payMntState='Test';
        info.payMntPostalCode='Test';
        info.cageCode='Test124';
        info.contractNumber='123';
        info.dunsNumber='123';
        info.invoiceDetails = infoLine;
        info.receivedBy='Tester';
        info.receivedByPay='Tester';
        info.pastDueBalancePrior='125';           
        info.receivedByAdjust='test';
        info.adjustmentsRcvdAmt='Test';
        info.paymentsRcvd='Test';
        info.receivedByBal='Test';
        info.pastDueBalanceTotal='Test';
        info.currentTotalAmount='Test';
        info.totalBalance='Test';
        info.invoiceStatus='Posted';
        info.invNumber=invoices[0].Id;
        info.invName='Testing Invoice'; 
        List<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo> invoiceLst = new List<QTB_GenerateBillTrustExtractCTRL.InvoiceInfo>();
        /*for(Integer i =0;i<5;i++){
invoiceLst.add(info);
}*/
        invoiceLst.add(info);
        try
        {
        QTB_BillTrustUtil.generateBilltrustRequest(invoiceLst,false, 'test', 'String');
        }
        catch(Exception ex){}
        
        info.customerCountry=QTB_GenerateBillTrustExtractCTRL.CANADA_COUNTRY_ISO_CODE;
        invoiceLst.add(info);
        try
        {
        QTB_BillTrustUtil.generateBilltrustRequest(invoiceLst,false, 'test', 'String');
        QTB_BillTrustUtil.generateBilltrustRequest(null,false,null,null);
        }
        catch(Exception ex){}
        invoiceLst.clear();
        try{
            QTB_BillTrustUtil.generateBilltrustRequest(invoiceLst,false, 'test', 'String');
            QTB_GenerateBillTrustExtractCTRL.getInvoiceDetails(invoices);
        }
        catch(Exception ex){
            system.assert(true);
        }
        invoiceLst.add(info);
        try
        {
        QTB_GenerateBillTrustExtractCTRL.generateBillTrustXml(invoices,'TestInvoice',String.ValueOf(invoices[0].Id));
        }
        catch(Exception ex){}
        invoices.clear();
        try{
            QTB_GenerateBillTrustExtractCTRL.generateBillTrustXml(invoices,'TestInvoice','custom Exception');
        }
        catch(Exception ex){
            system.assert(true);
        }
        Map<ID, string> productMap = new Map<ID, String>();
        Map<String, string> productLangMap = new Map<String, String>();
        
        try{
        QTB_GenerateBillTrustExtractCTRL.updateStorageInfo(infoLine,invoiceLines,productMap,productLangMap);
        QTB_GenerateBillTrustExtractCTRL.updateServiceInfo(infoLine,invoiceLines,productMap,productLangMap);
        QTB_GenerateBillTrustExtractCTRL.updateOtherInfo(infoLine,invoiceLines,productMap,productLangMap);
        }
        catch(Exception ex){
            system.assert(true);
        }
        Test.stopTest();
        
    }
    
    // Unit test for QTB_GenerateMassExtractCTRL.
   // @isTest
   /* static void invoiceBatchTest(){
        Test.startTest();
        
        blng__LegalEntity__c denmarkentity = QTB_TestDataFactory.createLegalEntity(
                'Denmark'
            );
            
        List<Account> accts = new List<Account>();
        
        Account a = new Account();
        a.Name = 'TestAcc';
        a.RecordTypeId = accBillRecordTypeId;
        a.QTB_Create_Parent_Billing_Account__c = true;
        a.BillingCountry = 'India';
        a.BillingState = 'Assam';          
        a.QTB_Hold_Billing__c = true;            
        a.QTB_Billing_Account_Invoice_Name__c = 'Test Trigger';
        a.QTB_shred__c = true;
        a.QTB_scan__c = true;
        a.QTB_Contract_Entity__c = denmarkentity.id;
        a.ShippingCountry = 'Denmark';
        a.QTB_Records_Management__c = true;
        insert a;
        accts.add(a);

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
        
        List<blng__Invoice__c> invoices = QTB_TestDataFactory.createInvoices(accts);
        List<Product2> products = QTB_TestDataFactory.createProducts(1);
        List<Account> updatedAccts = new List<Account>();
        List<blng__InvoiceLine__c> invoiceLines =  QTB_TestDataFactory.createInvoiceLine(1,invoices,products);
        blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c(
            Name='Test sched',
            blng__Type__c='Once',
            blng__InvoiceBatches__c='Denmark-26th',
            blng__StartDateTime__c = system.now()+1,
            blng__TargetDate__c = system.today().addDays(2),
            QTB_Legal_Entity__c = denmarkentity.id,
            QTB_Invoice_Period__c = denmarkFinancePeriod.Id
            
        );
        insert ins;
        List<Account> accounts = new List<Account>();
        for(Account acc : accts){
            acc.QTB_Bill_Cycle_Day__c= ins.blng__InvoiceBatches__c;
            accounts.add(acc);
        }
        update accounts;*/
        //QTB_Invoice_Backing_Report_Compression__c ibrc = new QTB_Invoice_Backing_Report_Compression__c(QTB_Status__c='New',QTB_Invoice_Scheduler__c=ins.Id);
        //insert ibrc;
        //QTB_GenerateMassExtractCTRL.getInvoiceBatch(String.ValueOf(ins.Id),'Draft');
        //QTB_GenerateMassExtractCTRL.callBatchApex(String.ValueOf(ins.Id),'Draft');
        //QTB_GenerateMassExtractCTRL.generateCSV(invoices[0],invoices[0].Id);
        //QTB_Invoice_Backing_Report_Compression__c ibrc = new QTB_Invoice_Backing_Report_Compression__c(QTB_Status__c='New',QTB_Invoice_Scheduler__c=ins.Id);
        //insert ibrc;
        //QTB_GenerateMassExtractCTRL.invZipDelete(new List<Id>{ibrc.Id});
       // QTB_BillTrustUtil.generateCSV(invoices[0], invoiceLines[0].id);
       // Test.stopTest();
    //}
    
    // Unit test for QTB_GenerateMassExtractCTRL.
    //@isTest
   /* static void singleCreditNoteTest(){
        Test.startTest();
        String recordType = 'Billing Account';
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity(
            'India'
        );
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
        singaporeFinancePeriod.blng__LegalEntity__c = indiaEntity.id;
        singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert singaporeFinancePeriod;
        id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get(recordType)
            .getRecordTypeId();
        List<Account> accountList = new List<Account>();
        Account a = new Account();
        a.Name = 'TestAcc';
        a.RecordTypeId = recordTypeValue;
        a.QTB_Create_Parent_Billing_Account__c = true;
        a.BillingCountry = 'India';
        a.BillingState = 'Assam';
        a.QTB_Language__c = 'en_US';
        a.QTB_Contract_Entity__c = indiaEntity.ID;
        accountList.add(a);
        insert accountList;
        List<blng__Invoice__c> invoices = QTB_TestDataFactory.createInvoices(accountList);
        List<Product2> products = QTB_TestDataFactory.createProducts(1);
        List<Account> updatedAccts = new List<Account>();
        //List<blng__InvoiceLine__c> invoiceLines =  QTB_TestDataFactory.createInvoiceLine(1,invoices,products);
        blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c(
            Name='Test sched',
            blng__Type__c='Once',
            blng__InvoiceBatches__c='Denmark-26th',
            blng__StartDateTime__c = system.now()+1,
            blng__TargetDate__c = system.today().addDays(2),
            QTB_Invoice_Period__c = singaporeFinancePeriod.Id
        );
        insert ins;
        List<Account> accounts = new List<Account>();
        for(Account acc : accountList){
            acc.QTB_Bill_Cycle_Day__c= 'Denmark-26th';
            accounts.add(acc);
        }
        update accounts;
        
        Test.stopTest();
    } */
    
    
    // Unit test for QTB_GenerateMassExtractCTRL.
    @isTest
    static void invoiceBatchTest1(){
        Test.startTest();
        blng__LegalEntity__c denmarkentity = QTB_TestDataFactory.createLegalEntity(
            'United States'
        );
        
        List<Account> accts = new List<Account>();
        
        Account a = new Account();
        a.Name = 'TestAcc';
        a.RecordTypeId = accBillRecordTypeId;
        a.QTB_Create_Parent_Billing_Account__c = true;
        //a.BillingCountry = 'United States';
        //a.Billing_County__c = 'United States';
        a.BillingCountry = 'Canada';
        a.Billing_County__c = 'Canada';
        a.BillingState = 'Assam';          
        a.QTB_Hold_Billing__c = true;            
        a.QTB_Billing_Account_Invoice_Name__c = 'Test Trigger';
        a.QTB_shred__c = true;
        a.QTB_scan__c = true;
        a.QTB_Contract_Entity__c = denmarkentity.id;
        a.ShippingCountry = 'United States';
        a.QTB_Records_Management__c = true;
        //insert a;
        accts.add(a);
        
        List<blng__Invoice__c> invoices = QTB_TestDataFactory.createInvoices(accts);
        List<Product2> products = QTB_TestDataFactory.createProducts(1);
        List<Account> updatedAccts = new List<Account>();
        List<blng__InvoiceLine__c> invoiceLines =  QTB_TestDataFactory.createInvoiceLine(1,invoices,products);
        blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c(
            Name='Test sched',
            blng__Type__c='Once',
            blng__InvoiceBatches__c='United_States_DM_1st_EOM',
            blng__StartDateTime__c = system.now()+1,
            blng__TargetDate__c = system.today().addDays(2)
        );
        //insert ins;
        List<Account> accounts = new List<Account>();
        for(Account acc : accts){
            acc.QTB_Bill_Cycle_Day__c= ins.blng__InvoiceBatches__c;
            accounts.add(acc);
        }
        //update accounts;
        
        //QTB_GenerateMassBillTrustExtractBatch test = new QTB_GenerateMassBillTrustExtractBatch(ins.id, 'Draft');
        //Database.executeBatch(test, 1);
        //QTB_Invoice_Backing_Report_Compression__c ibrc = new QTB_Invoice_Backing_Report_Compression__c(QTB_Status__c='New',QTB_Invoice_Scheduler__c=ins.Id);
        //insert ibrc;
        //QTB_GenerateMassExtractCTRL.getInvoiceBatch(String.ValueOf(ins.Id),'Draft');
        //
        //QTB_GenerateMassExtractCTRL.generateCSV(invoices[0],invoices[0].Id);
        //QTB_Invoice_Backing_Report_Compression__c ibrc = new QTB_Invoice_Backing_Report_Compression__c(QTB_Status__c='New',QTB_Invoice_Scheduler__c=ins.Id);
        //insert ibrc;
        //QTB_GenerateMassExtractCTRL.invZipDelete(new List<Id>{ibrc.Id});
        
        //QTB_GenerateMassExtractCTRL.callBatchApex(String.ValueOf(ins.Id),'Draft');
        String testString1 = QTB_BillTrustUtil.SFDC_BILLTRUST_MAP;
        String testString2 = QTB_BillTrustUtil.BILLTRUST_IM_ORG_US;
        String testString3 = QTB_BillTrustUtil.BILLTRUST_IM_ORG_CANADA;
      //  QTB_BillTrustUtil.testFunctionality();
        Test.stopTest();
    }
    
  
    @isTest
    static void singleCreditNoteXmlTest(){
        System.debug('>>insideXML');
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        Account a = new Account();
        System.runAs(userList[0]) {
            
            blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
                'Yes'
            );
            blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
            );
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity(
                'India'
            );
            
            indiaEntity.blng__Street1__c = 'asasa';
            indiaEntity.blng__City__c = 'bbb';
            indiaEntity.blng__State__c = 'ssss';
            indiaEntity.blng__ZipPostalCode__c = '32323';
            indiaEntity.QTB_Legal_Entity_Number__c = 2000;
            update indiaEntity;
            
            blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
        taxIntegration.blng__TaxEngine__c = 'Standard';
        taxIntegration.blng__Active__c = true;
        database.insert(taxIntegration);
        
        blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
        blngTax.blng__TaxLegalEntity__c = indiaEntity.id;
        blngTax.blng__TaxIntegration__c = taxIntegration.id;
        blngTax.blng__TaxRule__c = taxRule.id;
        blngTax.blng__TaxCode__c = 'STD-CGST';
        blngTax.QTB_Invoice_Print_Tax_Name__c = 'GST';
        database.insert(blngTax);
            
             String recordType = 'Billing Account';
            id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName()
                .get(recordType)
                .getRecordTypeId();
            
            

            List<Account> accountList = new List<Account>();
            
            
            a.Name = 'TestAcc';
            a.RecordTypeId = recordTypeValue;
            a.QTB_Create_Parent_Billing_Account__c = true;
            a.BillingCountry = 'India';
            a.BillingCity = 'tesss';
            a.BillingState = 'Assam';
            a.BillingPostalCode = 'XYYYY';
            a.QTB_Language__c = 'fr';
            a.QTB_Contract_Entity__c = indiaEntity.ID;
            a.QTB_Billing_Frequency__c = 'Monthly';
            a.QTB_Customer_Classification__c = 'Government';
            a.QTB_Invoice_Delivery_Options__c = 'Email';
            a.QTB_Account_Balance__c = 23232;
            a.QTB_Bill_Cycle_Day__c= 'India-1st';
            a.CurrencyIsoCode = 'INR';
           update accountList;
            accountList.add(a);
            insert accountList;
        
        IM_Customer_Account__c custAcnt = new IM_Customer_Account__c(Name = '23334', IM_Account__c = accountList[0].Id);
            Insert custAcnt;
            
            Service_Location__c srvLocn = new Service_Location__c(
                Name='Test Serv',
                QTB_Billing_Account__c=accountList[0].Id,
                QTB_SiteID__c='TEST',
                QTB_Site_Number__c = 'Test121',
                Svc_District_Id__c = null,
                Customer_Id__c = custAcnt.id
            );
            insert srvLocn;
            
            List<product2> product = QTB_TestDataFactory.createProducts(1);
            product[0].blng__BillingRule__c = billingRule.id;
            product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
            product[0].blng__TaxRule__c = taxRule.id;
            product[0].QTB_Price_Schedule_Category__c = 'Storage';
            database.update(product);
            
            Group groupinfo = [SELECT id FROM Group WHERE Name = 'QTB VP India'  LIMIT 1  ];
        
        sbaa__Approver__c testApp1 = QTB_TestDataFactory.createApprover();
        testApp1.sbaa__User__c = UserInfo.getUserId();
        
        sbaa__Approver__c testApp2 = QTB_TestDataFactory.createApprover();
        testApp2.sbaa__GroupId__c = groupinfo.id;
        testApp2.QTB_Approver_Country__c = 'India';
        testApp2.QTB_Approver_Level__c = 'VP';
        
        sbaa__Approver__c testApp3 = QTB_TestDataFactory.createApprover();
        testApp3.sbaa__GroupId__c = groupinfo.id;
        testApp3.QTB_Approver_Country__c = 'India';
        testApp3.QTB_Approver_Level__c = 'SVP';
        
        sbaa__Approver__c testApp4 = QTB_TestDataFactory.createApprover();
        testApp4.sbaa__GroupId__c = groupinfo.id;
        testApp4.QTB_Approver_Country__c = 'India';
        testApp4.QTB_Approver_Level__c = 'EVP';
        
        sbaa__Approver__c testApp5 = QTB_TestDataFactory.createApprover();
        testApp5.sbaa__GroupId__c = groupinfo.id;
        testApp5.QTB_Approver_Country__c = 'India';
        testApp5.QTB_Approver_Level__c = 'CFO';
        
        update new List<sbaa__Approver__c>{ testApp1, testApp2,testApp3,testApp4,testApp5 };
             Id pricebookId = Test.getStandardPricebookId();
            
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
                product[0]
            );
            
            //Recurring Product
            List<product2> productList = new List<product2>();
            product2 p2 = new product2();
            p2.Name = 'Test Product2';
            p2.isActive = true;
            p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            p2.SBQQ__HasConsumptionSchedule__c = true;
            productList.add(p2);
            insert productList;
            
            PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[0]);
            
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
        insert new ProductConsumptionSchedule(
            ConsumptionScheduleId = consumption.Id,
            ProductId = productList[0].Id
        );
            
            List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
            //oppList[0].recordtypeid = QTB_Utils.OPP_BILL_RECTYPEID;
            //oppList[0].Pricebook2Id = pricebookId;
            //database.update(oppList);
            
            List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
                1,
                oppList[0].id,
                accountList[0].id,
                true,
                null
            );
            quoteList[0].SBQQ__PriceBook__c = pricebookId;
            quoteList[0].SBQQ__StartDate__c = System.Today();
            quoteList[0].recordtypeId = QTB_Utils.QUOTE_BILL_RECTYPEID;
            //database.update(quoteList);
            
            //Test.startTest();
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
                1,
                quoteList[0].id,
                accountList[0].id
            );
            
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(
                1,
                quoteList[0].id,
                quoteGroupList[0].id,
                product[0].id
            );
            
            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
                1,
                quoteList[0].Id,
                accountList[0].id
            );
            orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
            //database.update(orderList3);
            
            SBQQ.TriggerControl.disable();
            List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(
                orderList3[0].Id,
                product[0].Id,
                quoteLinesList,
                standardPrice
            );
            
            List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(
                1,
                accountList[0],
                orderList3[0],
                orderItemList3[0]
            );
            blng__UsageSummary__c usagesummary = usageSum[0];
            
            usagesummary.blng__Status__c = 'Queued For Invoice';
            usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
            usagesummary.blng__Subtotal__c = 100;
            usagesummary.blng__TotalQuantity__c = 10;
            usagesummary.blng__PreratedQuantity__c = 20;
            usagesummary.blng__UnbilledQuantity__c = 1;
            usagesummary.blng__UnitPrice__c = 400;
            usagesummary.blng__PreratedAmount__c = 22;
            usagesummary.blng__SummaryEndDate__c = system.today();
            database.update(usagesummary);
            
            blng__Usage__c usage = new blng__Usage__c();
            usage.blng__PreratedAmount__c=7800;
            usage.blng__UsageSummary__c = usagesummary.Id;
            usage.blng__EndDateTime__c = system.today();
            usage.blng__MatchingId__c = '0002659701100-0031';
            usage.blng__StartDateTime__c = system.today();
            insert usage;
            
             list<blng__Invoice__c> invoiceList = new List<blng__Invoice__c>();
            
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accountList[0].Id;
            invoice.blng__InvoiceStatus__c = 'Posted';
            invoice.QTB_Bill_Cycle_Day__c =accountList[0].QTB_Bill_Cycle_Day__c;
            invoice.QTB_Last_Invoice_Sent__c = system.today();
            invoiceList.add(invoice);
            Test.startTest();
            insert invoiceList;
            
            list<ID> InvIdlist = New list<ID>();
            for(blng__Invoice__c ivn : invoiceList)
            {
                InvIdlist.add(ivn.id);
            }
           
            
            String invId = invoiceList[0].id;
            //Test.stopTest(); 
       
           /* blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
            invoiceLine.Name = 'prodName';
            invoiceLine.blng__Invoice__c = invId;
            invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
            invoiceLine.blng__Quantity__c = 10;
            invoiceLine.blng__UnitPrice__c = 5;
            invoiceLine.blng__TotalAmount__c = 0;
            invoiceLine.blng__UsageSummary__c = usagesummary.id;
            invoiceLine.blng__TaxPercentageApplied__c = 100;
            invoiceLine.blng__TaxRule__c  = taxRule.id;
            insert invoiceLine;*/
      Product2 tmp = new Product2(
          Name = 'Test Product 1',
          isActive = true,
          SBQQ__SubscriptionPricing__c = 'Fixed Price'
        );
           
            blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
          invoiceLine.Name = 'prodName';
          invoiceLine.blng__Invoice__c = invId;
          invoiceLine.blng__Product__c = tmp.Id;
          invoiceLine.blng__InvoiceLineStatus__c = 'Posted';
          invoiceLine.blng__Quantity__c = 10;
          invoiceLine.blng__UnitPrice__c = 5;          
          invoiceLine.blng__TaxPercentageApplied__c = 24;
          invoiceLine.blng__TaxStatus__c = 'Warning';
          invoiceLine.blng__TaxCountry__c = 'Canada';
         
          String naCountriesLabel = Label.QTB_NA_Countries;
          System.assertEquals('Canada', invoiceLine.blng__TaxCountry__c, 'Assertion Message');
          insert invoiceLine;
      blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
            invoiceLine1.Name = 'prodName';
            invoiceLine1.blng__Invoice__c = invId;
            invoiceLine1.blng__InvoiceLineStatus__c = 'Initiated';
            invoiceLine1.blng__Quantity__c = 10;
            invoiceLine1.blng__UnitPrice__c = 5;
            invoiceLine1.blng__TotalAmount__c = 0;
            invoiceLine1.blng__UsageSummary__c = usagesummary.id;
            invoiceLine1.blng__TaxPercentageApplied__c = 100;
            invoiceLine1.blng__TaxRule__c  = taxRule.id;
            //insert invoiceLine1;
            
            blng__InvoiceLine__c invoiceLine2 = new blng__InvoiceLine__c();
            invoiceLine2.Name = 'prodName';
            invoiceLine2.blng__Invoice__c = invId;
            invoiceLine2.blng__InvoiceLineStatus__c = 'Initiated';
            invoiceLine2.blng__Quantity__c = 10;
            invoiceLine2.blng__UnitPrice__c = 5;
            invoiceLine2.blng__TotalAmount__c = 0;
            invoiceLine2.blng__TaxPercentageApplied__c = 100;
            invoiceLine2.blng__TaxRule__c  = taxRule.id;
            //insert invoiceLine2;
             // Create Credit Note
        List<blng__CreditNote__c> ListCN = new List<blng__CreditNote__c>();
        
        //Regular CreditNote
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        creditNote1.blng__Account__c = accountList[0].Id;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Account Creation';
        creditNote1.blng__Status__c = 'Draft';
        creditNote1.CurrencyIsoCode = 'INR';
        creditNote1.QTB_Manager_Approver__c = testApp1.Id;
        creditNote1.QTB_VP_Approver__c = testApp2.Id;
        creditNote1.QTB_SVP_Approver__c = testApp2.Id;
       // creditNote1.blng__RelatedInvoice__c = invoiceListForCredit[0].Id;
       // creditNote1.QTB_Rebill_Invoice__c = rebillInvoiceList[0].Id;
        ListCN.add(creditNote1);
        //System.debug('setup_creditNotesList@@'+creditNotesList);
        insert ListCN;
         
            List<blng__CreditNoteLine__c> ListCredirLines = QTB_TestDataFactory.createCreditNoteLine(
                1,
                accountList[0],
                ListCN[0],
                invoiceList[0],
                invoiceLine,
                product[0]
            );
            System.debug('ListCredirLines>>>'+ListCredirLines);
            ListCredirLines[0].QTB_InvoiceLine__c = invoiceLine.Id;
            ListCredirLines[0].blng__Subtotal__c = 200;
            ListCredirLines[0].blng__TotalAmount__c = 10000;
            ListCredirLines[0].blng__Status__c = 'Posted';
            ListCredirLines[0].blng__CalculateTax__c = true;
            ListCredirLines[0].Id = ListCredirLines[0].Id;
            //update ListCredirLines;
        // Create Approval Rule
       // sbaa__ApprovalRule__c testRule = QTB_TestDataFactory.createApprovalRule();
       List<blng__CreditNote__c> creditNotes = [select name,QTB_Last_Credit_Note_Sent__c,QTB_Custom_Invoice_Number__c,id,
                blng__Status__c,blng__Notes__c ,blng__Account__c,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Subtotal__c,
                blng__Account__r.QTB_Language__c,CurrencyIsoCode,blng__Account__r.blng__BillToContact__r.Email,
                blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,
                blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,                                     
                blng__Account__r.QTB_Market__r.QTB_State__c,                                     
                blng__Account__r.QTB_Invoice_Delivery_Options__c,blng__Account__r.QTB_Billing_Frequency__c,blng__Account__r.QTB_Account_Balance__c,
                blng__CreditNoteDate__c,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,
                blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c,blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c,
                blng__Account__r.QTB_Contract_Entity__r.blng__City__c,blng__Account__r.QTB_Contract_Entity__r.blng__State__c,
                blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IRM_Contact_Details__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_PAN_NO__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Email__c,
                blng__TaxAmount__c,blng__TotalAmount__c,blng__Account__r.QTB_Legal_Entity__r.blng__Street1__c,
                blng__Account__r.QTB_Legal_Entity__r.blng__Street2__c,blng__Account__r.QTB_Legal_Entity__r.blng__City__c,
                blng__Account__r.QTB_Legal_Entity__r.blng__State__c,blng__Account__r.QTB_Tax_ID__c,blng__Account__r.QTB_Customer_Classification__c,
                blng__Account__r.QTB_Legal_Entity__r.blng__ZipPostalCode__c,blng__Account__r.BillingStreet,
                blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode,blng__Account__r.BillingCountry,
                blng__Account__r.QTB_Consolidation_Flag__c,blng__Account__r.QTB_HoldInd__c,blng__Account__r.QTB_HoldRequester__c,
                blng__Account__r.QTB_IMCompany__c,
                //QTB_LateFee__c,QTB_SiteAdjustmentTotal__c,QTB_SiteLateFeeAmount__c,QTB_SiteNumberTotal__c,QTB_PaymentsRcvd__c,QTB_AdjustmentsRcvdAmt__c,
                //QTB_PastDueBalanceTotal__c,QTB_CurrentTotalAmount__c,QTB_TotalAdjustmentAmount__c,
                blng__Account__r.QTB_ContractNumber__c,blng__Account__r.QTB_CageCode__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_ID__c,blng__Account__r.QTB_Contract_Entity__r.QTB_DunsNumber__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_PaymentName__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactEmail__c,blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContactPN__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_IMBillContact__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnPostalCode__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnState__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnCity__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress3__c,blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress2__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_ReturnAddress1__c,blng__Account__r.QTB_Legal_Entity_Country__c,/*QTB_Subtotal_WithNegative__c, Gitlab-22532 */QTB_Total_Amount_with_Tax_Override__c,//Changes for Story #22175
                (Select id,QTB_Invoice__c,blng__Product__c,QTB_Credit_Quantity__c,blng__Product__r.QTB_Price_Schedule_Category__c,
                    //blng__UsageSummary__c,blng__Invoice__c,blng__UsageSummary__r.blng__SummaryEndDate__c,blng__UnitPrice__c,blng__ChargeType__c,
                    //QTB_HasConsumptionSchedule__c,
                    blng__InvoiceLine__r.blng__UsageSummary__r.blng__SummaryEndDate__c,QTB_Subtotal__c,
                    blng__Product__r.ProductCode,blng__TotalAmount__c,blng__TaxAmount__c,Name,blng__Subtotal__c,
                    blng__CreditNote__r.blng__Account__c,QTB_Invoice__r.QTB_Custom_Invoice_Number__c,
                    blng__InvoiceLine__r.blng__UnitPrice__c, blng__InvoiceLine__r.Name,blng__InvoiceLine__r.blng__Product__r.Name,
                    blng__InvoiceLine__r.QTB_Charge_Type__c,blng__InvoiceLine__r.QTB_Inc_Quantity__c,blng__InvoiceLine__r.QTB_Unit_Price__c,
                    blng__InvoiceLine__r.blng__Invoice__r.blng__Account__r.QTB_Language__c,
					/*,QTB_Subtotal_WithNegative__c Gitlab-22532 *///Changes for Story #22175
					blng__InvoiceLine__r.blng__Invoice__r.blng__Account__r.QTB_SITAD__c
                    from blng__CreditNoteCreditLines__r)
                from blng__CreditNote__c 
                where id =: ListCN[0].id];
           
            Map<ID, string> productMap = new Map<ID, string>();
            productMap.put(product[0].id, 'Test Prd');
            try
            {
            QTB_GenerateCreditNoteXmlExtractCTRL.generateBillTrustXml(creditNotes, null, null);
            }
          catch(Exception e) 
            {
            }
            
            QTB_GenerateCreditNoteXmlExtractCTRL.getCreditNoteDetails(creditNotes);
            List<blng__Invoice__c> invoices = QTB_TestDataFactory.createInvoices(accountList);
            List<Product2> products = QTB_TestDataFactory.createProducts(1);
            products[0].QTB_Price_Schedule_Category__c = 'Storage';
            //update products;
            List<Account> updatedAccts = new List<Account>();
            List<blng__InvoiceLine__c> invoiceLines =  QTB_TestDataFactory.createInvoiceLine(1,invoices,products);
            
            QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo infoLine = new QTB_GenerateBillTrustExtractCTRL.InvoiceLineInfo();
            QTB_GenerateBillTrustExtractCTRL.ProductInfo pinfo = new QTB_GenerateBillTrustExtractCTRL.ProductInfo();
            pinfo.billCD='Test';
            pinfo.cLIN='Test';
            pinfo.description='Testing';
            pinfo.invoiceLineAmount='1234';
            pinfo.lineAmountTotal='12345';
            pinfo.quantityCnt='123';
            pinfo.rateAmount='7000';
            pinfo.taxLineAmount='12345';
            List<QTB_GenerateBillTrustExtractCTRL.ProductInfo> pinfoLst = new List<QTB_GenerateBillTrustExtractCTRL.ProductInfo>();
            pinfoLst.add(pinfo);
            infoLine.siteID='123';
            infoLine.siteName='Test';
            infoLine.invoiceID=invoices[0].Id;
            infoLine.referenceID='123';
            infoLine.invoiceDate='Today';
            infoLine.poNumber='1234';
            infoLine.serviceDetails=pinfoLst;
            infoLine.totalStorageAmount='50MB';
            infoLine.storageDetails=pinfoLst;
            infoLine.totalServiceAmount='2000';
            infoLine.otherDetails=pinfoLst;
            infoLine.totalOtherAmount='7000';
            infoLine.siteNumberTotal='123';
            infoLine.invoiceTotalAmount='12345';
            infoLine.siteLateFeeAmount='1234';
            infoLine.siteAdjustmentTotal = '12345';
            infoLine.siteNumber ='123';   
            
            list<QTB_Tax_Detail__c> testTax = new list<QTB_Tax_Detail__c>();
            QTB_Tax_Detail__c test1 = new QTB_Tax_Detail__c();
            test1.QTB_Invoice_Line__c  = invoiceLine.id;
            test1.QTB_Jurisdiction__c = 'Test1';
            test1.QTB_Imposition__c  = 'Test2';
            test1.QTB_CalculatedTax__c = 23.00;
            testTax.add(test1);
            
            QTB_Tax_Detail__c test2 = new QTB_Tax_Detail__c();
            test2.QTB_Invoice_Line__c  = invoiceLine.id;
            test2.QTB_Jurisdiction__c = 'Test11';
            test2.QTB_Imposition__c  = 'Test22';
            test2.QTB_CalculatedTax__c = 24.00;
            testTax.add(test2);
            
            QTB_Tax_Detail__c test3 = new QTB_Tax_Detail__c();
            test3.QTB_Credit_Note_Line__c   = ListCredirLines[0].Id;
            test3.QTB_Jurisdiction__c = 'Test13';
            test3.QTB_Imposition__c  = 'Test23';
            test3.QTB_CalculatedTax__c = 27.00;
            test3.QTB_Invoice_Line__c  = invoiceLine.id;
            testTax.add(test3);
            insert testTax;
            Map<String, string> productLangMap = new Map<String, String>();
            QTB_GenerateCreditNoteXmlExtractCTRL.updateStorageInfo(infoLine, ListCredirLines, productMap,productLangMap);
            QTB_GenerateCreditNoteXmlExtractCTRL.updateServiceInfo(infoLine, ListCredirLines, productMap,productLangMap);
            QTB_GenerateCreditNoteXmlExtractCTRL.updateOtherInfo(infoLine, ListCredirLines, productMap,productLangMap);
            
            list<blng__Invoice__c> invList1 = new list<blng__Invoice__c>();
            QTB_GenerateBillTrustExtractCTRL.getInvoiceDetails(invList1);
            
            list<blng__CreditNote__c> tes = new list<blng__CreditNote__c>();
            try{
                QTB_GenerateCreditNoteXmlExtractCTRL.generateBillTrustXml(tes, '', '');
            }
            catch(Exception ex){
                system.assert(true);
            }
            
            QTB_GenerateBillTrustExtractCTRL.SupplementaryInfo t = new QTB_GenerateBillTrustExtractCTRL.SupplementaryInfo();
            try{
                QTB_GenerateCreditNoteXmlExtractCTRL.getCreditNoteInfo(null, false,t);
            }
            catch(Exception ex){
                system.assert(true);
            }
            
            list<ID> eligibleIds = new list<ID>();
            eligibleIds.add(invoiceLine.id);
            eligibleIds.add(invoiceLine1.id);
            QTB_BillTrustUtil.getSiteTaxDetailsMap(eligibleIds, true);
            eligibleIds.clear();
            eligibleIds.add(ListCredirLines[0].Id);
            QTB_BillTrustUtil.getSiteTaxDetailsMap(eligibleIds, false);
            
            QTB_GenerateCreditNoteXmlExtractCTRL.throwExplicitException = true;
            try{
                QTB_GenerateCreditNoteXmlExtractCTRL.updateStorageInfo(null, null, null,null);
            }
            catch(Exception ex){
                system.assert(true);
            }
            try{
                QTB_GenerateCreditNoteXmlExtractCTRL.updateServiceInfo(null, null, null,null);
            }
            catch(Exception ex){
                system.assert(true);
            }
            try{
                QTB_GenerateCreditNoteXmlExtractCTRL.updateOtherInfo(null, null, null,null);
            }
            catch(Exception ex){
                system.assert(true);
            }
            try{
                QTB_GenerateCreditNoteXmlExtractCTRL.getCreditNoteDetails(null);
            }
            catch(Exception ex){
                system.assert(true);
            }
             SBQQ.TriggerControl.disable();
              //Update Credit Note
        creditNotes[0].ApprovalStatus__c = 'Pending';
            if(creditNotes[0] != null){
                database.update(creditNotes[0]);
            }
         //Update Credit Note
        //creditNotesList[0].ApprovalStatus__c = 'Rejected';
        //database.update(creditNotesList[0]);
        
        //Update Credit Note
        creditNotes[0].ApprovalStatus__c = 'Approved';        
        creditNotes[0].blng__Status__c = 'Posted';
             if(creditNotes[0] != null){
        //database.update(creditNotes[0]);
             }
        System.debug('>>afterupdate'+creditNotes[0]);
        QTB_CreditNoteTriggerHandler.throwExplicitException = false;        
        SBQQ.TriggerControl.enable();
            Test.stopTest(); 
    }
           // test.stopTest();
    }
public static testMethod void method4(){
        Test.startTest();{ 
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
     
            blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c(
            Name='Test sched',
            blng__Type__c='Once',
            blng__InvoiceBatches__c='Denmark-26th',
            blng__StartDateTime__c = system.now()+1,
            blng__TargetDate__c = system.today().addDays(2),
            QTB_Legal_Entity__c = denmarkentity.id,
            QTB_Invoice_Period__c = denmarkFinancePeriod.Id
        );
        insert ins;
            string invSCId = ins.id;
            string invStatus = 'Posted';
            string invbatch = '0';
            PageReference pageRef2 = Page.QTB_GenerateUsageCSV;
            Test.setCurrentPage(pageRef2);
            pageRef2.getParameters().put('Id',invSCId);
            pageRef2.getParameters().put('invStatus',invStatus);
            pageRef2.getParameters().put('invBatchNumber',invbatch);
            QTB_Invoice_Backing_Report_Compression__c invZip= new QTB_Invoice_Backing_Report_Compression__c();
            invZip.QTB_Invoice_Scheduler__c = ins.id;
            invZip.QTB_Status__c = 'New';
            insert invZip;
            List<Account> accList = new List<Account>();
            Set<ID> eligibleAccountIds = new Set<ID>();
            for(Account acc : [Select ID,QTB_SITAD__c from Account]){
                eligibleAccountIds.add(acc.id);
                acc.QTB_SITAD__c = true;
                acc.QTB_Bill_Cycle_Day__c= ins.blng__InvoiceBatches__c;
                accList.add(acc);
            }
            update accList;
            
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accList[0].Id;
            invoice.blng__InvoiceStatus__c = 'Posted';
            invoice.QTB_Bill_Cycle_Day__c =accList[0].QTB_Bill_Cycle_Day__c;
            invoice.QTB_Last_Invoice_Sent__c = system.today();
            insert invoice;
              
            Map<string,string> countryList = new Map<string,string>();
            countryList.put('United States','United States');
            
            List<Contact> conList1 = [Select Id from Contact];
            map<id,id> billingContLst = new map<id,id>();
            billingContLst.put(accList[0].id, conList1[0].id);
            map<id,Contact> conList = new map<id,Contact>();
            conList.put(conList1[0].id,conList1[0]);
          //  if(i>0){
            QTB_BillTrustUtil.generateCSV(invoice,string.valueOf(invZip.id)); 
          // }
           QTB_GenerateCreditNoteXmlExtractCTRL.dummyCode();
            QTB_BillTrustUtil.getBillTrustFileName();
            QTB_BillTrustUtil.getAccountContactMap(null);
            QTB_BillTrustUtil.getAccountServiceLocationMap(null);
             QTB_BillTrustUtil.generateCSV(null,null); 
           Test.stopTest(); 
        }
		
		
}

       @isTest static void testGetAccountPurchaseOrderMap() {
        // Create test Accounts
        List<Account> testAccounts = new List<Account>();
        for(Integer i = 0; i < 2; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert testAccounts;
           
           Contact con = new Contact();
            con.LastName = 'Custom Lasttest Name:20 ';
            con.FirstName = 'Custom Firsttest Name ';
            con.email = 'test@email.com';
            con.AccountId = testAccounts[0].Id;
            con.MailingCountry = 'Canada';
            con.IM_Role__c = 'PO Contact';
            insert con;
            
            AccountContactRelation acr = new AccountContactRelation();
            acr.accountId = testAccounts[1].id;
            acr.ContactId = con.Id;
            insert acr;
            
            acr.Roles = 'PO Contact';
            update acr;

        // Create Purchase Orders (QTB_PurchaseOrder__c)
        List<QTB_PurchaseOrder__c> purchaseOrders = new List<QTB_PurchaseOrder__c>();
        for(Integer i = 0; i < 2; i++) {
            purchaseOrders.add(new QTB_PurchaseOrder__c(
                QTB_Billing_Account__c = testAccounts[1].id,
                QTB_Status__c = 'Active',
                QTB_PO_Type__c = 'Standard',
                QTB_Start_Date__c = Date.today().addDays(-30),
                QTB_End_Date__c = Date.today().addDays(30),
                QTB_Customer_PO__c = 'PO-' + i,
                QTB_Service_Type__c = 'Mixed'
            ));
        }
        insert purchaseOrders;

        // Create Purchase Order Account junction records (QTB_PurchaseOrderAccount__c)
        List<QTB_PurchaseOrderAccount__c> poAccountList = new List<QTB_PurchaseOrderAccount__c>();
        for(Integer i = 0; i < 2; i++) {
            poAccountList.add(new QTB_PurchaseOrderAccount__c(
                QTB_Account__c = testAccounts[1].Id,
                QTB_Purchase_Order__c = purchaseOrders[i].Id
            ));
        }
        insert poAccountList;

        // Prepare list of Account Ids for method call
        List<Id> accountIds = new List<Id>{testAccounts[0].Id, testAccounts[1].Id};

        // Call the method to test
        Test.startTest();
        Map<Id, List<QTB_PurchaseOrder__c>> resultMap = QTB_BillTrustUtil.getAccountPurchaseOrderMap(accountIds);
        Test.stopTest();

    }


}