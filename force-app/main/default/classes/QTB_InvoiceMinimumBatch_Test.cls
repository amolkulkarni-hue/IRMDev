/*****************************************************************************************************
* Class: QTB_InvoiceMinimumBatch_Test
* Author: Accenture
* Purpose: Test Class for QTB_InvoiceMinimumBatch
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture   06/01/2020
*******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_InvoiceMinimumBatch_Test {
    @testSetup
    static void testdata() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<account> parentAccountList = QTB_TestDataFactory.createAccounts(
                1,
                'Billing Account'
            );
            parentAccountList[0].QTB_Legal_Entity_Country__c='Norway';
            database.update(parentAccountList);
            
            //Legal Entity
            blng__LegalEntity__c indiaEntity = new blng__LegalEntity__c();
            indiaEntity.Name = 'Test Legal Entity Norway';
            indiaEntity.blng__Active__c = true;
            indiaEntity.blng__Country__c = 'Norway';
            indiaEntity.QTB_Type__c = 'Contract';
           // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
            insert indiaEntity; 
            
            List<account> accountList = QTB_TestDataFactory.createAccounts(
                1,
                'Billing Account'
            );
            accountList[0].QTB_Invoice_Minimum_Charges__c = 1000;
            accountList[0].QTB_Invoice_Minimum_Start_Date__c = system.today() - 2;
            accountList[0].QTB_Apply_Invoice_Minimum_Charges__c = true;
            accountList[0].QTB_Records_Management__c = true;
            accountList[0].BillingCountry = 'Norway';
            accountList[0].QTB_Bill_Cycle_Day__c = 'Norway-26th';
            accountList[0].QTB_Hold_Billing__c = false;
            accountList[0].QTB_Create_Parent_Billing_Account__c = false;
            accountList[0].ParentId = parentAccountList[0].id;
            accountList[0].QTB_Legal_Entity_Country__c='Norway';
            accountList[0].QTB_Contract_Entity__c = indiaEntity.id; 
            accountList[0].QTB_Invoice_Delivery_Options__c = 'Email';
            database.update(accountList);
            
            blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
                'Yes'
            );
            blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
                'Yes'
            );
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            List<product2> product = QTB_TestDataFactory.createProducts(1);
            product[0].blng__BillingRule__c = billingRule.id;
            product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
            product[0].blng__TaxRule__c = taxRule.id;
            database.update(product);
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
                product[0]
            );
            
            //opportunity
      Test.startTest();
            List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
            oppList[0].Pricebook2Id = pricebookId;
            oppList[0].Legal_Entity__c = indiaEntity.id;
            database.update(oppList);
            
            //Quote
            List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
            quoteList[0].SBQQ__PriceBook__c = pricebookId;
            quoteList[0].SBQQ__StartDate__c = System.Today();
            quoteList[0].QTB_IM_Legal_Entity__c = indiaEntity.id;
            quoteList[0].QTB_Opportunity_Billing_Country__c = 'Norway';
            database.update(quoteList);
            
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
            quoteLinesList[0].SBQQ__PricebookEntryId__c = 'test';
            database.update(quoteLinesList);
            SBQQ.TriggerControl.disable();
            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
                1,
                quoteList[0].Id,
                accountList[0].id
            );
            orderList3[0].blng__InvoiceBatch__c = 'Norway-26th';
            orderList3[0].QTB_OrderCategory__c = 'Rebill';
            database.update(orderList3);
           
            List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(
                orderList3[0].Id,
                product[0].Id,
                quoteLinesList,
                standardPrice
            );
            orderItemList3[0].SBQQ__Activated__c = true;
            update orderItemList3[0];
            
            SBQQ.TriggerControl.enable();
          /*  blng__InvoiceScheduler__c blngInvoice = QTB_TestDataFactory.createInvoiceScheduler(
                'Norway-26th',
                'Once'
            ); */
            
            List<blng__UsageSummary__c> blngUsageSumm = new List<blng__UsageSummary__c>();
            blng__UsageSummary__c usage1 = new blng__UsageSummary__c();
            usage1.blng__Order__c = orderList3[0].id;
            usage1.blng__Account__c = accountList[0].id;
            usage1.blng__OrderProduct__c = orderItemList3[0].id;
            usage1.blng__Subtotal__c = 10;
            usage1.blng__MatchingId__c = '1234';
            
            usage1.blng__SummaryEndDate__c = DATE.newInstance(2021, 1, 26);
            usage1.blng__SummaryStartDate__c = DATE.newInstance(2021, 1, 1);
            usage1.blng__Status__c = 'Queued For Invoice';
            usage1.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
            blngUsageSumm.add(usage1);
            database.insert(blngUsageSumm);
            // adding invoices for the accounts inserted
            List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(
                accountList
            );
            
            /*blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c();
            ins.Name='Test sched Order '+orderList3[0].OrderNumber;
            ins.blng__Type__c='Once';
            ins.blng__InvoiceBatches__c = 'Rebill Run';
            ins.blng__StartDateTime__c = system.now()+1;
            ins.blng__TargetDate__c = system.today().addDays(2);
            insert ins; */
            
            blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
		usaEntity.Name = 'Test Legal Entity United States';
		usaEntity.blng__Active__c = true;
		usaEntity.blng__Country__c = 'Norway';
		usaEntity.QTB_Type__c = 'Contract';
		// indiaEntity.QTB_Legal_Entity_Number__c = '45000';
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
        
        //Invoice Scheduler
     /*   blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c();
        ins.Name = 'Rebill Run';
        ins.blng__Type__c = 'Once';
        ins.blng__StartDateTime__c = system.now()+1;
        ins.blng__TargetDate__c = system.today().addDays(2);
        ins.QTB_Parent_Invoice__c = invoiceList[0].Id;
		ins.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
        insert ins; */
        
        
    /*    blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c();
        ins.Name ='Test-' +'Norway-26th' +String.valueOf(Crypto.getRandomInteger());            
        ins.blng__InvoiceBatches__c = 'Norway-26th';
        ins.blng__StartDateTime__c = system.now() + 1;
        ins.blng__Type__c = 'Once';
        //  blngIn.blng__InvoiceDayOfMonth__c = '4';
        //  blngIn.blng__TargetDayOfMonth__c = '6';
        ins.blng__ApexJobId__c = '12345678';
        ins.blng__TargetDate__c = DATE.newInstance(2021, 1, 27);
        ins.QTB_Legal_Entity__c = usaEntity.id;
        ins.blng__StartDateTime__c = System.today().adddays(1);
        ins.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        ins.blng__TargetDate__c = Date.valueOf('2021-09-01');
        ins.QTB_Invoice_Period__c = singaporeFinancePeriod.id ;
        insert ins; */
            
            QTB_Bill_Flow_Controller__c preBill = new QTB_Bill_Flow_Controller__c();
            preBill.Name = 'Prebill For Rebill Invoice';// Hemnath -> Try to give the unique Name// Thinking to use the Invoice Schedular Name
            preBill.Execute_Pre_Bill_Run__c = true;
            preBill.QTB_Rebill_Order__c = orderList3[0].id;
         //   preBill.Invoice_Scheduler__c = ins.id;
            insert preBill;  
            Test.stopTest();
        }
       
    }
    
    static testMethod void testData1() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[1]) {
            List<Account> accList = [
                SELECT
                id,
                QTB_Records_Management__c,
                QTB_Minimum_Charges_Start_Date__c,
                QTB_Minimum_Storage_Charges__c,
                QTB_Hold_Billing__c,
                ParentId,
                QTB_Invoice_Minimum_Charges__c,
                QTB_Apply_Minimum_Storage_Charges__c,
                QTB_Bill_Cycle_Day__c,
                QTB_Customer_Number__c,
                CurrencyIsoCode
                FROM Account
                LIMIT 1
            ];
            QTB_Bill_Flow_Controller__c prebillrunrecord = [Select id from QTB_Bill_Flow_Controller__c limit 1];            
            QTB_InvoiceMinimumBatch obj = new QTB_InvoiceMinimumBatch('Norway-26th',null,prebillrunrecord.id);
            DataBase.executeBatch(obj);
            obj.execute(null, null);
            Date targetDate = system.today();
            QTB_InvoiceMinimumBatch obj1 = new QTB_InvoiceMinimumBatch('Rebill Run',targetDate,prebillrunrecord.id);
            Test.stopTest();
            System.assertEquals(
                false,
                QTB_InvoiceMinimumBatch.throwExplicitException
            );
        }
    }
  /*static testMethod void testMethod1() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[1]) {
            QTB_InvoiceMinimumBatch.throwExplicitException = true;
            QTB_Bill_Flow_Controller__c prebillrunrecord = new QTB_Bill_Flow_Controller__c();
            insert prebillrunrecord;
            QTB_InvoiceMinimumBatch obj = new QTB_InvoiceMinimumBatch(null,null,prebillrunrecord.id);
            DataBase.executeBatch(obj);
            obj.execute(null, null);
            Test.stopTest();
            System.assertEquals(true, QTB_InvoiceMinimumBatch.throwExplicitException);
        }
    } */
	
	private static testMethod void test2() {
		Test.startTest();
	    //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c= 'United States';
        update accountList;
			
		    List<Order> ordList = [
                SELECT
                id,Account.id,
                Account.QTB_Records_Management__c,
                Account.QTB_Minimum_Charges_Start_Date__c,
                Account.QTB_Minimum_Storage_Charges__c,
                Account.QTB_Hold_Billing__c,
                Account.ParentId,
                Account.QTB_Apply_Minimum_Storage_Charges__c,
                Account.QTB_Bill_Cycle_Day__c,
                Account.QTB_Customer_Number__c,
                Account.CurrencyIsoCode,bling_Legal_Entity__c
                FROM Order
                LIMIT 1
            ];
			
            //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
		
		blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
		usaEntity.Name = 'Test Legal Entity United States';
		usaEntity.blng__Active__c = true;
		usaEntity.blng__Country__c = 'United States';
		usaEntity.QTB_Type__c = 'Contract';
		// indiaEntity.QTB_Legal_Entity_Number__c = '45000';
		insert usaEntity;
		
		  //Invoice Scheduler
        blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c();
        ins.Name = 'Rebill Run';
        ins.blng__Type__c = 'Once';
        ins.blng__StartDateTime__c = system.now()+1;
        ins.blng__TargetDate__c = system.today().addDays(2);
        ins.QTB_Parent_Invoice__c = invoiceList[0].Id;
		ins.QTB_Legal_Entity__c = usaEntity.id ;
        ins.blng__InvoiceBatches__c = 'Rebill Run';
        insert ins;
        
        //BillFlowController
        QTB_Bill_Flow_Controller__c prebillrunrecord = new QTB_Bill_Flow_Controller__c();
        prebillrunrecord.Invoice_Scheduler__c = ins.Id;
        insert prebillrunrecord;
			string scheduleBatch = 'Rebill Run';
            string rebillType = 'Split';
           Date targetDate = system.today();
			QTB_InvoiceMinimumBatch obj = new QTB_InvoiceMinimumBatch(scheduleBatch,targetDate,prebillrunrecord.Id);
			DataBase.executeBatch(obj);
			obj.execute(null,null);
		//	obj.finish(null);
		/*	 Date targetDate = date.today();
            QTB_LateFeeCalculationBatch obj1 = new QTB_LateFeeCalculationBatch(scheduleBatch,null,prebillrunrecord.Id, rebillType);
			DataBase.executeBatch(obj1);
			obj1.execute(null,null);
			obj1.finish(null); */
			
			Test.stopTest();
		 
	}
}