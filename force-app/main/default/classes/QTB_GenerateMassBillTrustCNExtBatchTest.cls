@isTest
public class QTB_GenerateMassBillTrustCNExtBatchTest {
    private static final Id accBillRecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID;
    
    @testSetup
    static void prepareData(){
        User usr = [SELECT Id from User Where Profile.name='IM_Custom Sys Admin' AND Isactive=true LIMIT 1];
        System.runAs(usr) {
            //QTB_TestDataFactory.createLegalEntity('Norway');
            blng__LegalEntity__c denmarkentity = QTB_TestDataFactory.createLegalEntity(
                'Denmark'
            );
            QTB_TestDataFactory.createLOBMapping();
            List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
                2,
                'Standard Account'
            );
            Account a = new Account();
            a.Name = 'TestAcc';
            a.RecordTypeId = accBillRecordTypeId;
            a.QTB_Create_Parent_Billing_Account__c = true;
            a.BillingCountry = 'India';
            a.BillingState = 'Assam';          
            a.QTB_Hold_Billing__c = false;     
            a.QTB_Bill_Cycle_Day__c = 'Denmark-26th';
            a.QTB_Billing_Account_Invoice_Name__c = 'Test Trigger';
            a.QTB_shred__c = true;
            a.QTB_scan__c = true;
            a.QTB_Contract_Entity__c = denmarkentity.id;
            a.ShippingCountry = 'Denmark';
            a.QTB_Records_Management__c = true;
            a.QTB_Legal_Entity_Country__c = 'Denmark';
            insert a;
            List<Contact> cons = new List<Contact>();
            List<QTB_PurchaseOrder__c> pos = new List<QTB_PurchaseOrder__c>();
            for(Integer i=0;i<10;i++){
                cons.add(new Contact(LastName='Test'+i,accountId=testAccounts[0].Id));
                pos.add(new QTB_PurchaseOrder__c(QTB_Start_Date__c=system.today(),QTB_End_Date__c=system.today().addDays(1),QTB_Customer_PO__c='Test',QTB_Billing_Account__c=a.Id));
            }
            insert cons;
        }
    }
    
    @isTest
    static void invoiceBatchTest1(){
        Test.startTest();
        List<Account> accts = [SELECT ID From Account Where Name LIKE 'Test%' LIMIT 2];
        List<blng__Invoice__c> invoices = QTB_TestDataFactory.createInvoices(accts);
        List<Product2> products = QTB_TestDataFactory.createProducts(1);
        List<Account> updatedAccts = new List<Account>();
        List<blng__InvoiceLine__c> invoiceLines =  QTB_TestDataFactory.createInvoiceLine(1,invoices,products);
        List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accts);
        
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
        
 
        List<Account> accounts = new List<Account>();
        for(Account acc : accts){
           // acc.QTB_Bill_Cycle_Day__c= ins.blng__InvoiceBatches__c;
            acc.QTB_Legal_Entity_Country__c = 'Denmark';
            accounts.add(acc);
        }
        update accounts;
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
         system.debug('invschedular'+ins.Id);
        system.debug('invschedular'+ins.blng__InvoiceBatches__c);
        system.debug('@@@@@'+creditNotes);
        upsert creditNotes;
        List<blng__CreditNote__c> c = [SELECT Id,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Status__c,
                                       QTB_Last_Credit_Note_Sent__c FROM blng__CreditNote__c];
        system.debug('@@@@@'+c);
        try{
            Database.executeBatch(new QTB_GenerateMassBillTrustCNExtractBatch(ins.Id,'Draft',ins.blng__InvoiceBatches__c), 1);
        }
        catch(exception e){
        }
        Test.stopTest();
    }
    
    @isTest
    static void invoiceBatchTest2(){
        Test.startTest();
        List<Account> accts = [SELECT ID From Account Where Name LIKE 'Test%' LIMIT 2];
        List<blng__Invoice__c> invoices = QTB_TestDataFactory.createInvoices(accts);
        List<Product2> products = QTB_TestDataFactory.createProducts(1);
        List<blng__InvoiceLine__c> invoiceLines =  QTB_TestDataFactory.createInvoiceLine(1,invoices,products);
        List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accts);        
        blng__LegalEntity__c denmarkentity = QTB_TestDataFactory.createLegalEntity('Denmark');
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
            Name='Rebill Run',
            blng__Type__c='Once',
            blng__InvoiceBatches__c='Denmark-26th',
            blng__StartDateTime__c = system.now()+1,
            blng__TargetDate__c = system.today().addDays(2),
            QTB_Legal_Entity__c = denmarkentity.id,
            QTB_Invoice_Period__c = denmarkFinancePeriod.Id
        );
        insert ins;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Rebill Run';
        invoiceRun.blng__InvoiceScheduler__c = ins.id;
        invoiceRun.blng__Status__c = 'Started';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2021-09-01');
        insert invoiceRun;
        
        for( blng__Invoice__c invoice : invoices){
            invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        }
        //update invoices;
        
        List<Account> accounts = new List<Account>();
        for(Account acc : accts){
            acc.QTB_Bill_Cycle_Day__c= ins.blng__InvoiceBatches__c;
            acc.QTB_Legal_Entity_Country__c = 'Denmark';
            accounts.add(acc);
        }
        update accounts;
        system.debug('@@@@@'+creditNotes);
        upsert creditNotes;
        List<blng__CreditNote__c> c = [SELECT Id,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Status__c,
                                       QTB_Last_Credit_Note_Sent__c FROM blng__CreditNote__c];
        system.debug('@@@@@'+c);
        try{
            Database.executeBatch(new QTB_GenerateMassBillTrustCNExtractBatch(ins.Id, 'Draft',ins.blng__InvoiceBatches__c), 200);
        }
        catch(exception e){
        }
        Test.stopTest();
    }
    
    //To cover catch 
    static testMethod void testMethod2() {
        Test.startTest();
        List<Account> accts = [SELECT ID From Account Where Name LIKE 'Test%' LIMIT 2];
        List<blng__Invoice__c> invoices = QTB_TestDataFactory.createInvoices(accts);
        List<Product2> products = QTB_TestDataFactory.createProducts(1);
        List<Account> updatedAccts = new List<Account>();
        List<blng__InvoiceLine__c> invoiceLines =  QTB_TestDataFactory.createInvoiceLine(1,invoices,products);
        List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(accts);
        
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
        List<Account> accounts = new List<Account>();
        for(Account acc : accts){
            acc.QTB_Bill_Cycle_Day__c= ins.blng__InvoiceBatches__c;
            acc.QTB_Legal_Entity_Country__c = 'Denmark';
            accounts.add(acc);
        }
        update accounts;
        system.debug('@@@@@'+creditNotes);
        upsert creditNotes;
        List<blng__CreditNote__c> c = [SELECT Id,blng__Account__r.QTB_Bill_Cycle_Day__c,blng__Status__c,
                                       QTB_Last_Credit_Note_Sent__c FROM blng__CreditNote__c];
        QTB_GenerateMassBillTrustCNExtractBatch obj = new QTB_GenerateMassBillTrustCNExtractBatch(ins.Id, 'Draft',ins.blng__InvoiceBatches__c);
        Database.executeBatch(obj);
        Test.stopTest();
    }
}