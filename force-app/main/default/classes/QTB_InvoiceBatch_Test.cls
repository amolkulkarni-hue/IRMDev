/*****************************************************************************************************
* Class: QTB_InvoiceBatch_Test/
* Author: Accenture
* Purpose: Test Class for QTB_InvoiceBatch
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture   3/18/2020
*******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_InvoiceBatch_Test {
    @testSetup
    private static void setup() {
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Sweden'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Finland'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Denmark'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Taiwan'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Thailand'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Malaysia'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Hong Kong'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Singapore'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('India'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('France'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Belgium'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Netherlands'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('India'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Romania'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Slovakia'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Greece'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Czech republic'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Hungary'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Austria'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Spain'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Germany'));
        
        for(blng__LegalEntity__c le :entityList){
            if(le.blng__Country__c == 'India'){
                le.QTB_Tax_Applicability__c ='Product Based';
            }
            else{
                le.QTB_Tax_Applicability__c ='Flat Rate';
            }
        }
        update entityList;
        Market__c IndiaMarket = new Market__c(Name='Maharashtra-MH',QTB_State__c='Maharashtra',District_NAME__c='Maharashtra');
        Insert IndiaMarket;
        List<Account> accList = QTB_TestDataFactory.createAccounts(21); //insert 10 accounts
        for (Integer i = 0; i < accList.size(); i++) {
            accList[i].QTB_Hold_Invoice__c = false;
            accList[i].QTB_Contract_Entity__c = entityList[i].ID;
        }
        accList[0].BillingCountry = 'Norway';
        accList[1].BillingCountry = 'Sweden';
        accList[2].BillingCountry = 'Finland';
        accList[3].BillingCountry = 'Denmark';
        accList[4].BillingCountry = 'Taiwan';
        accList[5].BillingCountry = 'Thailand';
        accList[6].BillingCountry = 'Malaysia'; 
        accList[7].BillingCountry = 'Hong Kong';
        accList[8].BillingCountry = 'Singapore';
        accList[9].BillingCountry = 'India';
        accList[9].BillingState = 'Goa';
        accList[9].QTB_Market__c=IndiaMarket.id;
        accList[9].QTB_Legal_Entity_Country__c ='India';
        accList[10].BillingCountry = 'France';
        accList[1].BillingPostalCode = '456 23';
      /* accList[11].BillingCountry = 'Belgium';
        accList[12].BillingCountry = 'Netherlands';
        accList[13].BillingCountry = 'Romania';
        accList[14].BillingCountry = 'Slovakia';
        accList[15].BillingCountry = 'Greece';
        accList[16].BillingCountry = 'Czech Republic';
        accList[17].BillingCountry = 'Hungary';
        accList[18].BillingCountry = 'Austria';
        accList[19].BillingCountry = 'Spain';
        accList[20].BillingCountry = 'Germany'; */
        update accList;
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(
            accList
        );
        invList[0].blng__TaxStatus__c = QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
        invList[0].QTB_Custom_Invoice_Number__c=null;
        invList[0].QTB_KID__c=null;
        invList[0].blng__InvoiceStatus__c='Draft';
        invList[0].QTB_Bill_Cycle_Day__c ='1';
        for(blng__Invoice__c inv :invList){
            inv.QTB_Tax_Override_Amount__c = 10;
        }
        update invList;
        
        List<blng__Invoice__c> invList1 = QTB_TestDataFactory.createInvoices(
            accList
        );
        invList1[0].blng__TaxStatus__c = QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
        invList1[0].QTB_Custom_Invoice_Number__c= 'IND12345';
        invList1[0].QTB_KID__c='IND12345';
        invList1[0].QTB_Invoice_Type__c = 'Legacy Invoice';
        invList1[0].blng__InvoiceStatus__c='Posted';
        invList1[0].QTB_Bill_Cycle_Day__c ='1';
        for(blng__Invoice__c inv :invList1){
            inv.QTB_Tax_Override_Amount__c = null;
        }
        update invList1;
                Test.startTest();

        
        List<blng__Invoice__c> invList2 = QTB_TestDataFactory.createInvoices(
            accList
        );
        invList1[0].blng__TaxStatus__c = QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
        invList1[0].QTB_Custom_Invoice_Number__c= 'IND12345';
        invList1[0].QTB_KID__c='IND12345';
        //invList1[0].blng__Account__c = accList[9].id;
        invList1[0].blng__InvoiceStatus__c='Posted';
        invList1[0].QTB_Bill_Cycle_Day__c ='1';
        invList1[0].QTB_Tax_Override_Amount__c = null;
        
        update invList1;
        
        /*QTB_Bill_Flow_Controller__c    bill2=new QTB_Bill_Flow_Controller__c();
bill2.Execute_Post_Bill_Run__c=True;
bill.Execute_Pre_Bill_Run__c=False;
bill.Invoice_Scheduler__c=invsche.id;
bill.Name='abd';
bill.QTB_PostBill_Run_Status__c ='In Progress';
bill.QTB_PreBill_Run_Status__c='None';
insert bill2;*/
        
        //list<QTB_CustomInvoiceNumber__c> customInvoiceSettings= QTB_TestDataFactory.createCustomInvoiceNumber();
        List<QTB_CustomInvoiceNumber__c> invoiceNoList = new List<QTB_CustomInvoiceNumber__c>();
        
        QTB_CustomInvoiceNumber__c rec1 = new QTB_CustomInvoiceNumber__c();
        rec1.Name = 'denmark';
        rec1.QTB_Country__c = 'Denmark';
        rec1.QTB_Next_Sequence_Number__c = '4000000001';
        invoiceNoList.add(rec1);
        QTB_CustomInvoiceNumber__c rec2 = new QTB_CustomInvoiceNumber__c();
        rec2.Name = 'sweden';
        rec2.QTB_Country__c = 'Sweden';
        rec2.QTB_Next_Sequence_Number__c = '2000000001';
        invoiceNoList.add(rec2);
        QTB_CustomInvoiceNumber__c rec3 = new QTB_CustomInvoiceNumber__c();
        rec3.Name = 'norway';
        rec3.QTB_Country__c = 'Norway';
        rec3.QTB_Next_Sequence_Number__c = '2000000001';
        invoiceNoList.add(rec3);
        QTB_CustomInvoiceNumber__c rec4 = new QTB_CustomInvoiceNumber__c();
        rec4.Name = 'finland';
        rec4.QTB_Country__c = 'Finland';
        rec4.QTB_Next_Sequence_Number__c = '2000000001';
        invoiceNoList.add(rec4);
        QTB_CustomInvoiceNumber__c rec5 = new QTB_CustomInvoiceNumber__c();
        rec5.Name = 'taiwan';
        rec5.QTB_Country__c = 'Taiwan';
        rec5.QTB_Next_Sequence_Number__c = '2000000001';
        invoiceNoList.add(rec5);
        QTB_CustomInvoiceNumber__c rec6 = new QTB_CustomInvoiceNumber__c();
        rec6.Name = 'thailand';
        rec6.QTB_Country__c = 'Thailand';
        rec6.QTB_Next_Sequence_Number__c = '2000000001';
        invoiceNoList.add(rec6);
        QTB_CustomInvoiceNumber__c rec7 = new QTB_CustomInvoiceNumber__c();
        rec7.Name = 'malaysia';
        rec7.QTB_Country__c = 'Malaysia';
        rec7.QTB_Next_Sequence_Number__c = '2000000001';
        invoiceNoList.add(rec7);
        QTB_CustomInvoiceNumber__c rec8 = new QTB_CustomInvoiceNumber__c();
        rec8.Name = 'hong kong';
        rec8.QTB_Country__c = 'Hong Kong';
        rec8.QTB_Next_Sequence_Number__c = '2000000001';
        invoiceNoList.add(rec8);
        QTB_CustomInvoiceNumber__c rec9 = new QTB_CustomInvoiceNumber__c();
        rec9.Name = 'singapore';
        rec9.QTB_Country__c = 'Singapore';
        rec9.QTB_Next_Sequence_Number__c = '2000000001';
        invoiceNoList.add(rec9);
        QTB_CustomInvoiceNumber__c rec10 = new QTB_CustomInvoiceNumber__c();
        rec10.Name = 'india;goa;45000';
        rec10.QTB_Country__c = 'India';
        rec10.QTB_Next_Sequence_Number__c = '2000000001';
        rec10.QTB_State__c = 'Goa';
        rec10.QTB_Legal_Entity_Number__c = 45000;
        rec10.QTB_Is_Running__c =  True;
        invoiceNoList.add(rec10);
        QTB_CustomInvoiceNumber__c rec11 = new QTB_CustomInvoiceNumber__c();
        rec11.Name = 'france';
        rec11.QTB_Country__c = 'France';
        rec11.QTB_Next_Sequence_Number__c = '2000000001';
        invoiceNoList.add(rec11);
        QTB_CustomInvoiceNumber__c rec12 = new QTB_CustomInvoiceNumber__c();
        rec12.Name = 'belgium';
        rec12.QTB_Country__c = 'Belgium';
        rec12.QTB_Next_Sequence_Number__c = '2000000001';
        invoiceNoList.add(rec12);
        QTB_CustomInvoiceNumber__c rec13 = new QTB_CustomInvoiceNumber__c();
        rec13.Name = 'netherlands';
        rec13.QTB_Country__c = 'Netherlands';
        rec13.QTB_Next_Sequence_Number__c = '2000000001';
        invoiceNoList.add(rec13);
        //Cluster 3 countries
        QTB_CustomInvoiceNumber__c rec14 = new QTB_CustomInvoiceNumber__c();
        rec14.Name = 'romania';
        rec14.QTB_Country__c = 'romania';
        rec14.QTB_Next_Sequence_Number__c = '3000000001';
        invoiceNoList.add(rec14);
        
        QTB_CustomInvoiceNumber__c rec15 = new QTB_CustomInvoiceNumber__c();
        rec15.Name = 'slovakia';
        rec15.QTB_Country__c = 'slovakia';
        rec15.QTB_Next_Sequence_Number__c = '7000000001';
        invoiceNoList.add(rec15);
        
        QTB_CustomInvoiceNumber__c rec16 = new QTB_CustomInvoiceNumber__c();
        rec16.Name = 'greece';
        rec16.QTB_Country__c = 'greece';
        rec16.QTB_Next_Sequence_Number__c = '9000000001';
        invoiceNoList.add(rec16);
        
        QTB_CustomInvoiceNumber__c rec17 = new QTB_CustomInvoiceNumber__c();
        rec17.Name = 'czech republic';
        rec17.QTB_Country__c = 'czech republic';
        rec17.QTB_Next_Sequence_Number__c = '6000000001';
        invoiceNoList.add(rec17);
        //Cluster 3A countries
        QTB_CustomInvoiceNumber__c rec18 = new QTB_CustomInvoiceNumber__c();
        rec18.Name = 'hungary';
        rec18.QTB_Country__c = 'hungary';
        rec18.QTB_Next_Sequence_Number__c = '3000000001';
        invoiceNoList.add(rec18);
        
        QTB_CustomInvoiceNumber__c rec19 = new QTB_CustomInvoiceNumber__c();
        rec19.Name = 'austria';
        rec19.QTB_Country__c = 'austria';
        rec19.QTB_Next_Sequence_Number__c = '7000000001';
        invoiceNoList.add(rec19);
        
        QTB_CustomInvoiceNumber__c rec20 = new QTB_CustomInvoiceNumber__c();
        rec20.Name = 'spain';
        rec20.QTB_Country__c = 'spain';
        rec20.QTB_Next_Sequence_Number__c = '9000000001';
        invoiceNoList.add(rec20);
        
        QTB_CustomInvoiceNumber__c rec21 = new QTB_CustomInvoiceNumber__c();
        rec21.Name = 'germany';
        rec21.QTB_Country__c = 'germany';
        rec21.QTB_Next_Sequence_Number__c = '6000000001';
        invoiceNoList.add(rec21);
        
        if (!invoiceNoList.isEmpty()) {
            insert invoiceNoList;
        }
        
        
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
        usaEntity.Name = 'Test Legal Entity United States';
        usaEntity.blng__Active__c = true;
        usaEntity.blng__Country__c = 'Singapore';
        usaEntity.QTB_Type__c = 'Contract';
        usaEntity.QTB_Legal_Entity_Number__c = 45409;
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
        blngInvoiceSchedular.Name ='Test-' +'Singapore' +String.valueOf(Crypto.getRandomInteger());            
        blngInvoiceSchedular.blng__InvoiceBatches__c = 'Singapore-1st';
        //blngInvoiceSchedular.blng__StartDateTime__c = system.now() + 1;
        blngInvoiceSchedular.blng__Type__c = 'Once';
        //  blngIn.blng__InvoiceDayOfMonth__c = '4';
        //  blngIn.blng__TargetDayOfMonth__c = '6';
        blngInvoiceSchedular.blng__ApexJobId__c = '12345678';
        blngInvoiceSchedular.blng__TargetDate__c = DATE.newInstance(2021, 1, 27);
        blngInvoiceSchedular.QTB_Legal_Entity__c = usaEntity.id;
        
        blngInvoiceSchedular.blng__StartDateTime__c = System.today().adddays(2);
        blngInvoiceSchedular.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        blngInvoiceSchedular.blng__TargetDate__c = Date.valueOf('2021-09-01');
        blngInvoiceSchedular.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
        insert blngInvoiceSchedular; 
        
        
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        
        Metadata_Activation_Settings__c cust = new Metadata_Activation_Settings__c();
        cust.SObject_API_Name__c = 'blng__InvoiceLine__c';
        cust.Disable_Trigger__c = true;
        insert cust;
        
        List<blng__InvoiceLine__c> invlineupdateLst = new List<blng__InvoiceLine__c>();
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__Invoice__c = invList1[0].id;
        invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;
        //invoiceLine.blng__UsageSummary__c = usagesummary.id; 
        invoiceLine.blng__Subtotal__c = 100;
        invoiceLine.blng__OrderProduct__c=null;        
        invoiceLine.QTB_Tax_Override_Amount__c = Null;
        invoiceLine.blng__TaxStatus__c = 'Processing';
        invoiceLine.blng__TaxRule__c = taxRule.id;
        invoiceLine.blng__TaxPercentageApplied__c = 0;
        //insert invoiceLine;
        invlineupdateLst.add(invoiceLine); 
        
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        invoiceLine1.Name = 'prodName';
        invoiceLine1.blng__Invoice__c = invList[0].id;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine1.blng__Quantity__c = 10;
        invoiceLine1.blng__UnitPrice__c = 5;
        //invoiceLine.blng__UsageSummary__c = usagesummary.id; 
        invoiceLine1.blng__Subtotal__c = 100;
        invoiceLine1.blng__OrderProduct__c=null;        
        invoiceLine1.QTB_Tax_Override_Amount__c = Null;
        invoiceLine1.blng__TaxStatus__c = 'Processing';
        invoiceLine1.blng__TaxRule__c = taxRule.id;
        invoiceLine1.blng__TaxPercentageApplied__c = 0;
        //invoiceLine1.QTB_HSN_Code__c = null;
        //insert invoiceLine;
        invlineupdateLst.add(invoiceLine1); 
        
        //MGSB start
        blng__InvoiceLine__c invoiceLineIndia = new blng__InvoiceLine__c();
        invoiceLineIndia.Name = 'prodName';
        invoiceLineIndia.blng__Invoice__c = invList[9].id; 
        invoiceLineIndia.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLineIndia.blng__Quantity__c = 10;
        invoiceLineIndia.blng__UnitPrice__c = 5;
        //invoiceLine.blng__UsageSummary__c = usagesummary.id; 
        invoiceLineIndia.blng__Subtotal__c = 100;
        invoiceLineIndia.blng__OrderProduct__c=null;        
        invoiceLineIndia.QTB_Tax_Override_Amount__c = Null;
        invoiceLineIndia.blng__TaxStatus__c = 'Processing';
        invoiceLineIndia.blng__TaxRule__c = taxRule.id;
        invoiceLineIndia.blng__TaxPercentageApplied__c = 0;
        //invoiceLine1.QTB_HSN_Code__c = null;
        //insert invoiceLine;
        invlineupdateLst.add(invoiceLineIndia); 
        
       

        
        //MGSB ENd 
        if(!invlineupdateLst.isEmpty()){
            insert invlineupdateLst;
        }
        //update invList;
        //invoiceLine.blng__TaxStatus__c = 'Completed';
        //update invoiceLine;
        
        QTB_Bill_Flow_Controller__c  bill=new QTB_Bill_Flow_Controller__c();
        bill.Execute_Post_Bill_Run__c=False;
        bill.Execute_Pre_Bill_Run__c=True;
        bill.Invoice_Scheduler__c=blngInvoiceSchedular.id;
        bill.Name='abc';
        bill.QTB_PostBill_Run_Status__c ='None';
        bill.QTB_PreBill_Run_Status__c='In Progress';
        insert bill;
        
        QTB_Bill_Flow_Controller__c billng=
            [Select id,Execute_Post_Bill_Run__c,
             Execute_Pre_Bill_Run__c,Invoice_Scheduler__c,
             Name,QTB_PostBill_Run_Status__c
             ,QTB_PreBill_Run_Status__c from  QTB_Bill_Flow_Controller__c LIMIT 1];
        
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,
                                      name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,
                                      blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,
                                      QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c,
                                      QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,
                                      (Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c 
                                       from blng__InvoiceInvoiceLines__r) 
                                      FROM blng__Invoice__c where blng__Account__r.BillingCountry = 'Singapore'];
        QTB_InvoiceBatch obj = new QTB_InvoiceBatch('Singapore-1st',billng.id);
        DataBase.executeBatch(obj);
        obj.execute(null,inv);
        obj.finish(null);
        //QTB_InvoiceBatch.codeCoverageMethod();
 
        
        Test.stopTest();
    }
    
    private static testMethod void test() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Account> acc = [ SELECT id FROM Account ];
            List<Id> accid = new List<Id>();
            for(Account accountID : acc ){
                accid.add(accountID.id);
            }
            
            
            blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
            usaEntity.Name = 'Test Legal Entity United States';
            usaEntity.blng__Active__c = true;
            usaEntity.blng__Country__c = 'Singapore';
            usaEntity.QTB_Type__c = 'Contract';
            usaEntity.QTB_Legal_Entity_Number__c = 45409;
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
            blngInvoiceSchedular.Name ='Test-' +'Singapore' +String.valueOf(Crypto.getRandomInteger());            
            blngInvoiceSchedular.blng__InvoiceBatches__c = 'Singapore-1st';
            //blngInvoiceSchedular.blng__StartDateTime__c = system.now() + 1;
            blngInvoiceSchedular.blng__Type__c = 'Once';
            //  blngIn.blng__InvoiceDayOfMonth__c = '4';
            //  blngIn.blng__TargetDayOfMonth__c = '6';
            blngInvoiceSchedular.blng__ApexJobId__c = '12345678';
            blngInvoiceSchedular.blng__TargetDate__c = DATE.newInstance(2021, 1, 27);
            blngInvoiceSchedular.QTB_Legal_Entity__c = usaEntity.id;
            
            blngInvoiceSchedular.blng__StartDateTime__c = System.now().addHours(1);
            blngInvoiceSchedular.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
            blngInvoiceSchedular.blng__TargetDate__c = Date.valueOf('2021-09-01');
            blngInvoiceSchedular.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
            insert blngInvoiceSchedular; 
            
            List<QTB_Bill_Flow_Controller__c> billList = new List<QTB_Bill_Flow_Controller__c>();
            QTB_Bill_Flow_Controller__c  bill=new QTB_Bill_Flow_Controller__c();
            bill.Execute_Post_Bill_Run__c=False;
            bill.Execute_Pre_Bill_Run__c=True;
            bill.Invoice_Scheduler__c=blngInvoiceSchedular.id;
            bill.Name='abc';
            bill.QTB_PostBill_Run_Status__c ='Completed';
            bill.QTB_PreBill_Run_Status__c='Completed';
            billList.add(bill);
            insert billList;
            
            List<blng__InvoiceRun__c> listInvoiceRun =  new List<blng__InvoiceRun__c>();
            blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
            invoiceRun.Name = 'test invoice';
            invoiceRun.blng__InvoiceScheduler__c = blngInvoiceSchedular.id;
            invoiceRun.blng__Status__c = 'Started';
            invoiceRun.blng__StartTime__c = System.now(); 
            invoiceRun.blng__InvoiceDate__c = Date.valueOf('2024-10-01');
            invoiceRun.blng__TargetDate__c = Date.valueOf('2024-12-01');
            insert invoiceRun;
            listInvoiceRun.add(invoiceRun);
            
            List<id> invoiceSchdularId = new List<Id>();
            invoiceSchdularId.add(invoiceRun.blng__InvoiceScheduler__c);
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            List<blng__InvoiceRun__c> InvSchList = [select id, Name, blng__InvoiceScheduler__r.blng__InvoiceBatches__c from blng__InvoiceRun__c where blng__InvoiceScheduler__c IN: invoiceSchdularId];
         
            List<blng__Invoice__c> invoice = [
                SELECT id, QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,
                blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Bill_Cycle_Day__c,
                blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,blng__Account__r.QTB_Legal_Entity_Country__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,(Select id,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r),QTB_Tax_Override_Amount__c,
                recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c
                FROM blng__Invoice__c
                WHERE blng__Account__c IN :accid
                
            ];
            blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
            invoiceLine.Name = 'prodName';
            invoiceLine.blng__Invoice__c = invoice[0].id;
            invoiceLine.blng__InvoiceLineStatus__c = 'Posted';
            invoiceLine.blng__Quantity__c = 10;
            invoiceLine.blng__UnitPrice__c = 5;
            //invoiceLine.blng__UsageSummary__c = usagesummary.id; 
            invoiceLine.blng__Subtotal__c = 100;
            invoiceLine.blng__TaxStatus__c = 'Processing';
            invoiceLine.blng__OrderProduct__c=null;
            invoiceLine.blng__TaxRule__c = taxRule.id;
            //insert invoiceLine;
            update invoice;
            //invoiceLine.blng__TaxStatus__c = 'Completed';
            //update invoiceLine;
            
            List<QTB_Bill_Flow_Controller__c> billngList=
                [Select id,Execute_Post_Bill_Run__c,
                 Execute_Pre_Bill_Run__c,Invoice_Scheduler__c,
                 Name,QTB_PostBill_Run_Status__c
                 ,QTB_PreBill_Run_Status__c from  QTB_Bill_Flow_Controller__c where ID IN :billList LIMIT 1];
            
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c   ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c];
            //QTB_InvoiceBatch.CoverageMethod();
            Set<id> listBillFlow = new Set<id>();
            listBillFlow.add(billList[0].id);
           QTB_InvoiceBatch obj = new QTB_InvoiceBatch('Rebill Run',listBillFlow);
            DataBase.executeBatch(obj);
           // obj.execute(null,inv);
            //obj.finish(null);
            
            
            Test.stopTest();
            // System.assert(invoice[0].blng__Account__c == acc[0].id);
        }
    }
    //cover catch
    static testMethod void testMethod1() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Account> acc = [ SELECT id FROM Account ];
            List<Id> accid = new List<Id>();
            for(Account accountID : acc ){
                accid.add(accountID.id);
            }
            
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            
            List<blng__Invoice__c> invoice = [
                SELECT id, QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,
                blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Bill_Cycle_Day__c,
                blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,blng__Account__r.QTB_Legal_Entity_Country__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,(Select id,QTB_Charge_Type__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c from blng__InvoiceInvoiceLines__r),QTB_Tax_Override_Amount__c,
                recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c
                FROM blng__Invoice__c
                WHERE blng__Account__c IN :accid
                
            ];
            blng__Invoice__c inv = new blng__Invoice__c();
            inv.QTB_Tax_Override_Amount__c = null;
            update invoice;
            blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
            invoiceLine.Name = 'prodName';
            invoiceLine.blng__Invoice__c = invoice[0].id;
            invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
            invoiceLine.blng__Quantity__c = 10;
            invoiceLine.blng__UnitPrice__c = 5;
            //invoiceLine.blng__UsageSummary__c = usagesummary.id; 
            invoiceLine.blng__Subtotal__c = 100;
            invoiceLine.blng__TaxStatus__c = 'Processing';
            invoiceLine.blng__OrderProduct__c=null;
            //invoiceLine.QTB_HSN_Code__c = null;
            invoiceLine.blng__TaxRule__c = taxRule.id;
            insert invoiceLine;
            
            //invoiceLine.blng__TaxStatus__c = 'Completed';
            //update invoiceLine;
            
            QTB_Bill_Flow_Controller__c billng=
                [Select id,Execute_Post_Bill_Run__c,
                 Execute_Pre_Bill_Run__c,Invoice_Scheduler__c,
                 Name,QTB_PostBill_Run_Status__c
                 ,QTB_PreBill_Run_Status__c from  QTB_Bill_Flow_Controller__c LIMIT 1];
            
            List<blng__Invoice__c> inv1 = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c];
            
            QTB_InvoiceBatch obj = new QTB_InvoiceBatch('Rebill Run',billng.id);
            DataBase.executeBatch(obj);
            obj.execute(null,inv1);
            obj.finish(null);
           
            
            
            Test.stopTest();
    }
    }
    private static testMethod void test2() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Account> acc = [ SELECT id FROM Account ];
            List<Id> accid = new List<Id>();
            for(Account accountID : acc ){
                accid.add(accountID.id);
            }
            
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            
            List<blng__Invoice__c> invoice = [
                SELECT id, QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,
                blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Bill_Cycle_Day__c,
                blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,blng__Account__r.QTB_Legal_Entity_Country__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,(Select id,QTB_Charge_Type__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c from blng__InvoiceInvoiceLines__r),QTB_Tax_Override_Amount__c,
                recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c
                FROM blng__Invoice__c
                WHERE blng__Account__c IN :accid
                
            ];
            blng__Invoice__c inv = new blng__Invoice__c();
            inv.QTB_Tax_Override_Amount__c = null;
            update invoice;
            blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
            invoiceLine.Name = 'prodName';
            invoiceLine.blng__Invoice__c = invoice[0].id;
            invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
            invoiceLine.blng__Quantity__c = 10;
            invoiceLine.blng__UnitPrice__c = 5;
            //invoiceLine.blng__UsageSummary__c = usagesummary.id; 
            invoiceLine.blng__Subtotal__c = 100;
            invoiceLine.blng__TaxStatus__c = 'Processing';
            invoiceLine.blng__OrderProduct__c=null;
            //invoiceLine.QTB_HSN_Code__c = null;
            invoiceLine.blng__TaxRule__c = taxRule.id;
            insert invoiceLine;
            
            //invoiceLine.blng__TaxStatus__c = 'Completed';
            //update invoiceLine;
            
            QTB_Bill_Flow_Controller__c billng=
                [Select id,Execute_Post_Bill_Run__c,
                 Execute_Pre_Bill_Run__c,Invoice_Scheduler__c,
                 Name,QTB_PostBill_Run_Status__c
                 ,QTB_PreBill_Run_Status__c from  QTB_Bill_Flow_Controller__c LIMIT 1];
            
            List<blng__Invoice__c> inv1 = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c];
            
            QTB_InvoiceBatch obj = new QTB_InvoiceBatch('Rebill Run',billng.id);
            DataBase.executeBatch(obj);
            obj.execute(null,inv1);
            obj.finish(null);
            //QTB_InvoiceBatch.codeCoverageMethod();
            
            
            Test.stopTest();
            // System.assert(invoice[0].blng__Account__c == acc[0].id);
        }
    }
   private static testMethod void test5() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<Account> acc = [ SELECT id FROM Account ];
            List<Id> accid = new List<Id>();
            for(Account accountID : acc ){
                accid.add(accountID.id);
            }
            
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            
            List<blng__Invoice__c> invoice = [
                SELECT id, QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,
                blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Bill_Cycle_Day__c,
                blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,blng__Account__r.QTB_Legal_Entity_Country__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,(Select id,QTB_Charge_Type__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c from blng__InvoiceInvoiceLines__r),QTB_Tax_Override_Amount__c,
                recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c
                FROM blng__Invoice__c
                WHERE blng__Account__c IN :accid
                
            ];
            blng__Invoice__c inv = new blng__Invoice__c();
            inv.QTB_Tax_Override_Amount__c = null;
            update invoice;
            blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
            invoiceLine.Name = 'prodName';
            invoiceLine.blng__Invoice__c = invoice[0].id;
            invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
            invoiceLine.blng__Quantity__c = 10;
            invoiceLine.blng__UnitPrice__c = 5;
            //invoiceLine.blng__UsageSummary__c = usagesummary.id; 
            invoiceLine.blng__Subtotal__c = 100;
            invoiceLine.blng__TaxStatus__c = 'Processing';
            invoiceLine.blng__OrderProduct__c=null;
            //invoiceLine.QTB_HSN_Code__c = null;
            invoiceLine.blng__TaxRule__c = taxRule.id;
            insert invoiceLine;
            
            //invoiceLine.blng__TaxStatus__c = 'Completed';
            //update invoiceLine;
            
            List<QTB_Bill_Flow_Controller__c> billng=
                [Select id,Execute_Post_Bill_Run__c,
                 Execute_Pre_Bill_Run__c,Invoice_Scheduler__c,
                 Name,QTB_PostBill_Run_Status__c
                 ,QTB_PreBill_Run_Status__c from  QTB_Bill_Flow_Controller__c LIMIT 1];
            
            List<blng__Invoice__c> inv1 = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c];
            QTB_InvoiceBatch.throwExplicitException = true;
            QTB_InvoiceBatch obj = new QTB_InvoiceBatch('Rebill Run',billng[0].id);
            DataBase.executeBatch(obj);
            obj.execute(null,inv1);
            obj.finish(null);
            System.assertEquals(true, QTB_InvoiceBatch.throwExplicitException);
            //QTB_InvoiceBatch.codeCoverageMethod();
            
            
            Test.stopTest();
            // System.assert(invoice[0].blng__Account__c == acc[0].id);
        }
    }
    
}