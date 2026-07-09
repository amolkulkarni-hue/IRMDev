/*****************************************************************************************************
* Class: QTB_ControllerForRePostingButton_Test
* Author: Virtusa
* Purpose: 
* Requirement: 
* Change History: 8/30/2024
* Developer        Date           Description
**************************************************************************************************/

@isTest(seealldata=false)
private with sharing class QTB_ControllerForRePostingButton_Test {
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
        List<Account> accList = QTB_TestDataFactory.createAccounts(11); //insert 10 accounts
        for (Integer i = 0; i < accList.size(); i++) {
            accList[i].QTB_Hold_Invoice__c = false;
            accList[i].QTB_Contract_Entity__c = entityList[i].ID;
        }
        accList[0].BillingCountry = 'Norway';
        accList[1].BillingCountry = 'United Kingdom';
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
        update accList;
        List<blng__Invoice__c> invList = QTB_TestDataFactory.createInvoices(
            accList
        );
    
        List<blng__Invoice__c> invList1 = QTB_TestDataFactory.createInvoices(
            accList
        );
       Test.startTest();
        
        List<blng__Invoice__c> invList2 = QTB_TestDataFactory.createInvoices(
            accList
        );
      
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
        QTB_ControllerForRePostingButton.callReadyForIntBatch(inv[0].id);
        
        Test.stopTest();
    }
    static testMethod void testMethod1() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Test.startTest();
            QTB_ControllerForRePostingButton.throwExplicitException = true;
            
            
            Test.stopTest();
            System.assertEquals(true, QTB_ControllerForRePostingButton.throwExplicitException);
        }
    }
    static testMethod void testMethod2() {
       List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            Test.startTest();
            QTB_ControllerForRePostingButton.throwExplicitException = true;
            
            QTB_ControllerForRePostingButton.callReadyForIntBatch(null);
            
            Test.stopTest();
            System.assertEquals(true, QTB_ControllerForRePostingButton.throwExplicitException);
        }  
    }
}