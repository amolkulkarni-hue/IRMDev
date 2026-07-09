/*****************************************************************************************************
* Class: QTB_FuelSurchargesBatch_Test
* Purpose: Test Class for QTB_FuelSurchargesBatch
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Gopi       25/05/2021
*******************************************************************************************************/
@isTest(seeAlldata=false)
public class QTB_FuelSurchargesBatch_Test {
    @testSetup
    static void setup() {
       
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
            List<account> accountList = QTB_TestDataFactory.createAccounts(
                1,
                'Billing Account'
            );
            accountList[0].QTB_Minimum_Storage_Charges__c = 1000;
            accountList[0].QTB_Minimum_Charges_Start_Date__c = system.today() - 2;
            accountList[0].QTB_Apply_Minimum_Storage_Charges__c = true;
            accountList[0].QTB_Records_Management__c = true;
            accountList[0].BillingCountry = 'Norway';
            accountList[0].QTB_Bill_Cycle_Day__c = 'Norway-26th';
            accountList[0].QTB_Fuel_Surcharge_Exempt__c = False;
            accountList[0].QTB_Customer_District__c = 'Arizona';
            update accountList;
            
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
            product[0].QTB_Storage_Product__c = true;
            product[0].SBQQ__ChargeType__c = 'Usage';
            product[0].recordTypeId = QTB_Utils.GLOBAL_SALES_RECTYPEID;
            product[0].QTB_Fuel_Surcharge_Applicable__c = true;
            product[0].ProductCode = '123-111';
            product[0].QTB_Oracle_Product_Code__c = '123';
            product[0].QTB_Oracle_GL_Account_Code__c = '123';
            update product;
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
                product[0]
            );
            
            List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
            oppList[0].Pricebook2Id = pricebookId;
            update oppList;
            
            List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
                1,
                oppList[0].id,
                accountList[0].id,
                true,
                null
            );
            quoteList[0].SBQQ__PriceBook__c = pricebookId;
            quoteList[0].SBQQ__StartDate__c = System.Today();
            // update quoteList;
            
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
            update quoteLinesList;
            SBQQ.TriggerControl.disable();
            List<Order> orderList = QTB_TestDataFactory.createCPQOrders(
                1,
                quoteList[0].Id,
                accountList[0].id
            );
            orderList[0].blng__InvoiceBatch__c = 'Norway-26th';
            update orderList;
            
            List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(
                orderList[0].Id,
                product[0].Id,
                quoteLinesList,
                standardPrice
            );
            Test.startTest();
            blng__InvoiceScheduler__c blngInvoice = QTB_TestDataFactory.createInvoiceScheduler(
                'Norway-26th',
                'Once'
            );
            
            List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(
                1,
                accountList[0],
                orderList[0],
                orderItemList[0]
            );
            usageSum[0].blng__MatchingAttribute__c = orderList[0].OrderNumber;
            usageSum[0].blng__Subtotal__c = 310;
            usageSum[0].blng__Status__c = 'Queued For Invoice';
            usageSum[0].blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
            usageSum[0].QTB_Legal_Entity_Country__c = 'Norway';
            usageSum[0].blng__SummaryStartDate__c = System.today()-1;
            update usageSum;
            System.Assert(usageSum[0].blng__Status__c == 'Queued For Invoice');
            QTB_TestDataFactory.createProductDiscount(accountList[0], product[0]);
            QTB_TestDataFactory.createInvoices(accountList);
            
            IM_Country__c country = new IM_Country__c();
            country.Name = 'United States';
            insert country;
            
            QTB_Fuel_Surcharge_Config__c config = new QTB_Fuel_Surcharge_Config__c();
            config.Name = 'test';
            config.QTB_Surcharge__c = 10;
            config.QTB_IM_Country__c = country.id;
            config.QTB_From_Date__c = System.today()-10;
            config.QTB_To_Date__c = System.today()+90;
            insert config;
            
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
        
     /*   blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c();
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
          //  preBill.Invoice_Scheduler__c = ins.id;
            insert preBill;
            Test.stopTest();
            
        }
    }
    static testMethod void testStatus() {
        Test.startTest();        
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
            CurrencyIsoCode,
            QTB_Fuel_Surcharge_Exempt__c,
            QTB_Customer_District__c,
            QTB_Legal_Entity_Country__c
            FROM Account
            LIMIT 1
        ];
        
        QTB_Bill_Flow_Controller__c prebillrunrecord = [Select id From QTB_Bill_Flow_Controller__c limit 1 ];
        //System.assert(invoice.blng__Account__c == acc.id);
        QTB_FuelSurchargesBatch obj = new QTB_FuelSurchargesBatch('United States-DM-1st-EOM Manual',System.today(),prebillrunrecord.id);
        //QTB_FuelSurchargesBatch obj1 = new QTB_FuelSurchargesBatch('Rebill Run',System.today(),prebillrunrecord.id);
        //QTB_FuelSurchargesBatch obj2 = new QTB_FuelSurchargesBatch(null,null,prebillrunrecord.id);
        DataBase.executeBatch(obj);
        obj.execute(null, accList);
        Test.stopTest(); 
    }
}