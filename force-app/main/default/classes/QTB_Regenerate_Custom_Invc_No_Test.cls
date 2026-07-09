/*****************************************************************************************************
* Class: QTB_Regenerate_Custom_Invc_No
* Author: Virtusa
* Purpose: Test Class for QTB_Regenerate_Custom_Invc_No_Test
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture   3/18/2020
*******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_Regenerate_Custom_Invc_No_Test {
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
        entityList.add(QTB_TestDataFactory.createLegalEntity('australia'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('new zealand'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('turkey'));
        for(blng__LegalEntity__c le :entityList){
            if(le.blng__Country__c == 'Thailand'){
                le.QTB_Tax_Applicability__c ='Product Based';
            }
            else{
                le.QTB_Tax_Applicability__c ='Flat Rate';
            }
        }
        update entityList;
        Market__c IndiaMarket = new Market__c(Name='Maharashtra-MH',QTB_State__c='Maharashtra',District_NAME__c='Maharashtra');
        Insert IndiaMarket;
        List<Account> accList = QTB_TestDataFactory.createAccounts(24); //insert 10 accounts
        for (Integer i = 0; i < accList.size(); i++) {
            accList[i].QTB_Hold_Invoice__c = false;
            accList[i].QTB_Contract_Entity__c = entityList[i].ID;
        }
        accList[0].BillingCountry = 'Norway';
        accList[1].BillingCountry = 'Sweden';
        accList[1].BillingPostalCode = '123 45';
        accList[1].ShippingPostalCode = '123 45';
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
        accList[11].BillingCountry = 'Belgium';
        accList[12].BillingCountry = 'Netherlands';
        accList[13].BillingCountry = 'Romania';
        accList[14].BillingCountry = 'Slovakia';
        accList[15].BillingCountry = 'Greece';
        accList[16].BillingCountry = 'Czech Republic';
        accList[17].BillingCountry = 'Hungary';
        accList[18].BillingCountry = 'Austria';
        accList[19].BillingCountry = 'Spain';
        accList[20].BillingCountry = 'Germany';
        accList[21].BillingCountry = 'australia';
        accList[22].BillingCountry = 'new zealand';
        accList[23].BillingCountry = 'turkey';
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
        //#28025
        rec18.Name = 'hungary;45000';
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
        //#28025
        rec21.Name = 'germany;45000';
        rec21.QTB_Country__c = 'germany';
        rec21.QTB_Next_Sequence_Number__c = '6000000001';
        invoiceNoList.add(rec21);
        //#28025
        QTB_CustomInvoiceNumber__c rec22 = new QTB_CustomInvoiceNumber__c();
        rec22.Name = 'united kingdom';
        rec22.QTB_Country__c = 'united kingdom';
        rec22.QTB_Next_Sequence_Number__c = '1100000001';
        invoiceNoList.add(rec22);
        //#28025
        QTB_CustomInvoiceNumber__c rec23 = new QTB_CustomInvoiceNumber__c();
        rec23.Name = 'Ireland';
        rec23.QTB_Country__c = 'Ireland';
        rec23.QTB_Next_Sequence_Number__c = '1100000001';
        invoiceNoList.add(rec23);
        
        QTB_CustomInvoiceNumber__c rec24 = new QTB_CustomInvoiceNumber__c();
        rec24.Name = 'australia';
        rec24.QTB_Country__c = 'australia';
        rec24.QTB_Next_Sequence_Number__c = '1200000001';
        invoiceNoList.add(rec24);
        
        QTB_CustomInvoiceNumber__c rec25 = new QTB_CustomInvoiceNumber__c();
        rec25.Name = 'new zealand';
        rec25.QTB_Country__c = 'new zealand';
        rec25.QTB_Next_Sequence_Number__c = '1400000001';
        invoiceNoList.add(rec25);
        
        QTB_CustomInvoiceNumber__c rec26 = new QTB_CustomInvoiceNumber__c();
        rec26.Name = 'turkey';
        rec26.QTB_Country__c = 'turkey';
        rec26.QTB_Next_Sequence_Number__c = '1500000001';
        invoiceNoList.add(rec26);
        
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
        blngInvoiceSchedular.blng__StartDateTime__c = system.now() + 1;
        blngInvoiceSchedular.blng__Type__c = 'Once';
        //  blngIn.blng__InvoiceDayOfMonth__c = '4';
        //  blngIn.blng__TargetDayOfMonth__c = '6';
        blngInvoiceSchedular.blng__ApexJobId__c = '12345678';
        blngInvoiceSchedular.blng__TargetDate__c = DATE.newInstance(2021, 1, 27);
        blngInvoiceSchedular.QTB_Legal_Entity__c = usaEntity.id;
        
        blngInvoiceSchedular.blng__StartDateTime__c = System.today().adddays(1);
        blngInvoiceSchedular.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        blngInvoiceSchedular.blng__TargetDate__c = Date.valueOf('2021-09-01');
        blngInvoiceSchedular.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
        insert blngInvoiceSchedular; 
        
        
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
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
        //invoiceLine1.QTB_HSN_Code__c = null;
        //insert invoiceLine;
        invlineupdateLst.add(invoiceLine1); 
        
        if(!invlineupdateLst.isEmpty()){
            //insert invlineupdateLst;
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
        
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,Null);
        
        
        Test.stopTest();
    }
    static testMethod void testMethod1() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Test.startTest();
            QTB_Regenerate_Custom_Invc_No.throwExplicitException = true;
            
            QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(null,null);
            
            
            Test.stopTest();
            System.assertEquals(true, QTB_Regenerate_Custom_Invc_No.throwExplicitException);
        }
    }
    static testMethod void testMethod2() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Sweden'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingPostalCode = '123 45';
        accList[0].ShippingPostalCode = '123 45';
        accList[0].BillingCountry = 'Sweden';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,Null);
        Test.stopTest();
    }
    static testMethod void testMethod3() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Finland'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Finland';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,Null);
        Test.stopTest();
    }
    static testMethod void testMethod4() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Denmark'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Denmark';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,Null);
        Test.stopTest();
    }
    static testMethod void testMethod5() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('India'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'India';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod6() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Thailand'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Thailand';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod7() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Taiwan'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Taiwan';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod8() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Malaysia'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Malaysia';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod9() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Hong Kong'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Hong Kong';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod10() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Singapore'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Singapore';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod11() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('France'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'France';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod12() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Belgium'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Belgium';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod13() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Netherlands'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Netherlands';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    // Cluster 3
    static testMethod void testMethod14() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Romania'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Romania';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod15() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Slovakia'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Slovakia';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod16() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Greece'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Greece';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod17() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Czech Republic'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Czech Republic';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod18() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Hungary'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Hungary';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod19() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Austria'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Austria';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod20() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Spain'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Spain';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    static testMethod void testMethod21() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Germany'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'Germany';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    // Cluster 3
    // #28025
    static testMethod void testMethod22() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('United Kingdom'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        //accList[0].BillingCountry = 'United Kingdom';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    //#28025
    static testMethod void testMethod23() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('Ireland'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        //accList[0].BillingCountry = 'United Kingdom';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    //30236
    static testMethod void testMethod24() {
        Test.startTest();
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Rebill Run';
        accountList[0].QTB_Legal_Entity_Country__c='India';
        accountList[0].QTB_Bill_Forward_Type__c='Advance';
        accountList[0].QTB_Billing_Frequency__c='Monthly';
        //accountList[0].CurrencyIsoCode = 'INR';
        update accountList;
        
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accountList);
        invList[0].QTB_Invoice_Type__c = 'Legacy Invoice';
        update invList;
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,null,accountList[0].id);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        update orderList3;
        
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
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
      System.debug('The following exception has occurred: ' + e);
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
        usagesummary.blng__Invoice__c = invList[0].id; 
        update usagesummary;
        
        List<blng__Usage__c> blngUsages = new List<blng__Usage__c>();
         try {
        blng__Usage__c usage = new blng__Usage__c();
        usage.blng__UsageSummary__c = usagesummary.id;
        usage.blng__Account__c = accountList[0].id;
        usage.blng__MatchingId__c = 'Legacy';
        usage.blng__EndDateTime__c = date.today() + 1;
        usage.blng__StartDateTime__c = date.today();
        usage.QTB_Source_Invoice_Reference__c = 'Test Legacy Invoice';
        usage.blng__MatchingAttribute__c = 'Legacy';
        blngUsages.add(usage);
        
    if (!blngUsages.isEmpty()) {
        insert blngUsages;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
        
        List<blng__InvoiceLine__c> invLineList = new List<blng__InvoiceLine__c>();
        try {
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
          invoiceLine.Name = p.name;
          invoiceLine.blng__Invoice__c = invList[0].Id;
          invoiceLine.blng__Product__c = p.Id;
          invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
          invoiceLine.blng__Quantity__c = 10;
          invoiceLine.blng__UnitPrice__c = 5;
          invoiceLine.blng__TaxPercentageApplied__c = 24;
          invoiceLine.blng__UsageSummary__c = usagesummary.id;
          //invoiceLine.blng__InvoiceLineStatus__c = QTB_Constants.INVOICELINE_STATUS_DRAFT;
          invLineList.add(invoiceLine);
          if (!invLineList.isEmpty()) {
        insert invLineList;
      }
            } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }  
        Map<Id,blng__Invoiceline__c> usageSummryToInvLineMap = new Map<Id,blng__Invoiceline__c>();
        for(blng__Invoiceline__c invLine :  invLineList){
            usageSummryToInvLineMap.put(invLine.blng__UsageSummary__c,invLine);    
        }
        system.debug('usageSummryToInvLineMap:'+usageSummryToInvLineMap);
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(invList,usageSummryToInvLineMap);
        Test.stopTest();
    }
    
    static testMethod void testMethod26() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('United States'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'United States';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    
    static testMethod void testMethod25() {
        Test.startTest();
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Bill_Cycle_Day__c = 'Rebill Run';
        accountList[0].QTB_Legal_Entity_Country__c='India';
        accountList[0].QTB_Bill_Forward_Type__c='Advance';
        accountList[0].QTB_Billing_Frequency__c='Monthly';
        //accountList[0].CurrencyIsoCode = 'INR';
        update accountList;
        
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(accountList);
        invList[0].QTB_Invoice_Type__c = 'Legacy Invoice';
        update invList;
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(invList,Null);
        Test.stopTest();
    }
    
    static testMethod void testMethod27() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('australia'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'australia';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    
    static testMethod void testMethod28() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('new zealand'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(1); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'new zealand';
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
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id=:invList[0].id];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
    
     static testMethod void testMethod29() {
        Test.startTest();
        List<blng__LegalEntity__c> entityList = new List<blng__LegalEntity__c>();
        //entityList.add(QTB_TestDataFactory.createLegalEntity('Norway'));
        entityList.add(QTB_TestDataFactory.createLegalEntity('turkey'));
        update entityList;
        
        List<Account> accList = QTB_TestDataFactory.createAccounts(2,'Billing Account'); //insert 10 accounts
        accList[0].QTB_Hold_Invoice__c = false;
        accList[0].QTB_Contract_Entity__c = entityList[0].ID;
        accList[0].BillingCountry = 'turkey';
        accList[0].QTB_Invoice_Delivery_Options__c = 'e-Fatura';
        accList[0].QTB_Legal_Entity_Country__c = 'turkey';
        accList[1].QTB_Hold_Invoice__c = false;
        accList[1].QTB_Contract_Entity__c = entityList[0].ID;
        accList[1].BillingCountry = 'turkey';
        accList[1].QTB_Invoice_Delivery_Options__c = 'e-Arşiv';
        accList[1].QTB_Legal_Entity_Country__c = 'turkey';
        update accList;
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(
            accList
        );
        invList[0].blng__TaxStatus__c = QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
        invList[0].QTB_Custom_Invoice_Number__c=null;
        invList[0].QTB_KID__c=null;
        invList[0].blng__InvoiceStatus__c='Draft';
        invList[0].QTB_Bill_Cycle_Day__c ='1';
        invList[1].blng__TaxStatus__c = QTB_Constants.INVOICE_TAXSTATUS_COMPLETED;
        invList[1].QTB_Custom_Invoice_Number__c=null;
        invList[1].QTB_KID__c=null;
        invList[1].blng__InvoiceStatus__c='Draft';
        invList[1].QTB_Bill_Cycle_Day__c ='1';
         Set<Id> invIds = new Set<Id>();
        for(blng__Invoice__c inv :invList){
            inv.QTB_Tax_Override_Amount__c = 10;
            invIds.add(inv.id);
        }
       
        
        update invList;
        List<blng__Invoice__c> inv = [select id,blng__Account__r.QTB_Legal_Entity_Country__c,blng__Account__r.QTB_Invoice_Delivery_Options__c,QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,QTB_HoldOptionForInvoice__c,blng__InvoiceStatus__c,blng__Account__r.QTB_Contract_Entity__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Transferred_To_Oracle__c,QTB_Bill_Cycle_Day__c,blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.BillingState,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,QTB_Transferred_to_Invoice_Compliance__c,blng__Order__c,blng__Order__r.QTB_OrderCategory__c  ,QTB_Invoice_Type__c,blng__Account__r.QTB_Contract_Entity__r.QTB_Tax_Applicability__c,recordTypeId,blng__Account__r.QTB_Market__r.QTB_State__c,(Select id,name,blng__OrderProduct__c,blng__OrderProduct__r.OrderId,blng__OrderProduct__r.Order.QTB_OrderCategory__c,QTB_HSN_Code__c,QTB_Tax_Override_Amount__c,QTB_Charge_Type__c from blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c where id IN:invIds];
        QTB_Regenerate_Custom_Invc_No.generateNewCustomInvoiceNumber(inv,null);
        Test.stopTest();
    }
}