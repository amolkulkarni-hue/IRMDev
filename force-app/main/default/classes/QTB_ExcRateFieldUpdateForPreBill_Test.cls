/*****************************************************************************************************
* Class: QTB_ExcRateFieldUpdateForPreBill_Test
* Author: Virtusa
* Purpose: This is a test class for QTB_ExchangeRateFieldsUpdateForPreBill
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Virtusa    18/12.2024
*******************************************************************************************************/
@isTest(seealldata=false) 
private class QTB_ExcRateFieldUpdateForPreBill_Test {
    @testsetup
    private static void setup() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        Test.startTest();
        System.runAs(userList[0]) {
            SBQQ.TriggerControl.disable();
                 //Legal Entity
            blng__LegalEntity__c USEntity = new blng__LegalEntity__c();
            USEntity.Name = 'Test Legal Entity United States';
            USEntity.blng__Active__c = true;
            USEntity.blng__Country__c = 'United States';
            USEntity.QTB_Type__c = 'Contract';
            USEntity.QTB_Tax_Applicability__c = 'Flat Rate';
            USEntity.QTB_FX_Tax_Rate_Type__c = 'Corporate';
            
            //USEntity.QTB_Legal_Entity_Number__c = '45000';
            insert USEntity;
            
            List<Account> testAccount = QTB_TestDataFactory.createAccounts(
                1,
                'Standard Account'
            );
            testAccount[0].IM_Hierarchy_Level__c = 'Sales (Site)';
            testAccount[0].QTB_Contract_Entity__c = USEntity.id; 
            testAccount[0].CurrencyIsoCode='EUR';
            testAccount[0].QTB_Contract_Currency__c = 'INR';
            DATABASE.UPDATE(testAccount);
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
            
            /* List<opportunity> testOpp = QTB_TestDataFactory.createOpps(testAccount);
testOpp[0].recordtypeid = QTB_Utils.OPP_BILL_RECTYPEID;
testOpp[0].Pricebook2Id = pricebookId;
testOpp[0].Primary_Product_Line__c='Records Management';
database.update(testOpp); */
            IM_Country__c im = new IM_Country__c();
            im.Name = 'United States';
            im.CurrencyIsoCode = 'USD';
            im.Region__c = 'North America';
            im.AlternativeNames__c = 'United States';
            im.Iso31662Code__c ='US';
            im.Iso31663Code__c ='USA';        
            insert im;
            
            List<opportunity> testOpp =new  List<opportunity>();
            opportunity  op=New opportunity();
            op.recordtypeid= QTB_Utils.OPP_BILL_RECTYPEID;
            op.Pricebook2Id = pricebookId;
            op.Primary_Product_Line__c='Data Management';
            op.Name = 'Test';
            op.AccountId = testAccount[0].id;
            op.CloseDate = Date.today();
            op.StageName = '1 - Qualification';
            op.Amount = 500;
            //op.Primary_Product_Line__c ='Digital Solutions';
            //op.Is_InSight_being_proposed__c='DM SITAD';
            op.Billing_Country__c = im.Id;
            testOpp.add(op);
            
            database.insert(testOpp);
            
            testOpp[0].Pricebook2Id = pricebookId;
            database.update(testOpp);
            
            List<SBQQ__Quote__c> testquote = QTB_TestDataFactory.createCPQQuotes(
                1,
                testOpp[0].id,
                testAccount[0].id,
                true,
                null
            );
            System.debug('testquote@@'+testquote);
            /* testquote[0].SBQQ__PriceBook__c = pricebookId;
testquote[0].SBQQ__StartDate__c = System.Today();
database.update(testquote);*/
            
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
                1,
                testquote[0].id,
                testAccount[0].id
            );
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(
                1,
                testquote[0].id,
                quoteGroupList[0].id,
                product[0].id
            );
            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
                1,
                testquote[0].Id,
                testAccount[0].id
            );
            
            orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
            orderList3[0].QTB_OrderCategory__c = 'Rebill';
            orderList3[0].blng__InvoiceBatch__c = 'India-1st';
            update orderList3[0];
            
            List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(
                orderList3[0].Id,
                product[0].Id,
                quoteLinesList,                
                standardPrice
            );
            
            //creating usage summary
            List<blng__UsageSummary__c> usageSumList = new List<blng__UsageSummary__c>();
            List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(
                2,
                testAccount[0],
                orderList3[0],
                orderItemList3[0]
            );
            blng__UsageSummary__c usagesummary = usageSum[0];
            usagesummary.blng__Status__c = 'Queued For Invoice';
            usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
            usagesummary.blng__UnitPrice__c = 12;
            usagesummary.blng__TotalQuantity__c = 10;
            usagesummary.blng__NextBillingDate__c = System.now().date().addDays(-5);
            usagesummary.blng__PreratedAmount__c = 1000;
            usagesummary.blng__Subtotal__c = 1000;
            
            blng__UsageSummary__c usagesummary1 = usageSum[1];
            usagesummary1.blng__TotalQuantity__c = 10;
            usagesummary1.blng__PreratedAmount__c = 1000;
            usagesummary1.blng__Status__c = 'Queued For Invoice';
            usagesummary1.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
            usagesummary1.blng__MatchingId__c = '1234';
            usagesummary1.blng__Subtotal__c = 1000;
            usagesummary1.blng__UnitPrice__c = 10;
            usagesummary1.blng__NextBillingDate__c = System.now().date().addDays(-5);
            
            
            usageSumList.add(usagesummary);
            usageSumList.add(usagesummary1);
            update usageSumList;
            
            System.Assert(usageSum[0].blng__Status__c == 'Queued For Invoice');
            
            List<blng__Usage__c> usageListnew = new List<blng__Usage__c>();
            List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(
                2,
                testAccount[0],
                usagesummary
            );
            blng__Usage__c usage = usageList[0];
            usage.blng__PreratedAmount__c = 0;
            usage.blng__PreratedQuantity__c = 0;
            usage.blng__Quantity__c = 15;
            usage.QTB_Product_Identifier_1__c='123456';
            usage.QTB_Contracted_Currency_Amount__c = 100;
            usage.blng__UnitPrice__c = 1;
            usage.QTB_Actual_Rate__c = 1;
            usage.blng__OrderProduct__c = orderItemList3[0].id;
            usage.blng__Order__c = orderList3[0].id; 
            
            
            blng__Usage__c usage1 = usageList[1];
            usage1.blng__PreratedAmount__c = 10;
            usage1.QTB_Contracted_Currency_Amount__c = 100;
            usage1.blng__PreratedQuantity__c = 10;
            usage1.QTB_Product_Identifier_1__c='12345';
            usage1.blng__MatchingId__c = '1234';
            usage1.blng__Status__c = 'Processed';
            usage1.blng__UnitPrice__c = 5;
            usage1.QTB_Actual_Rate__c = 5;
            usage1.QTB_Price_Tier__c = 'Tier 1';
            
            usageListnew.add(usage);
            usageListnew.add(usage1);
            update usageListnew;
            
                  
            blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
            schedule.Name = 'test Story1211';
            schedule.blng__Type__c = 'Once';
            //schedule.blng__InvoiceBatches__c = 'United States-DM-1st-EOM Manual';
            schedule.CurrencyIsoCode = 'USD';
            schedule.blng__StartDateTime__c = System.now().addDays(5);
            schedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
            schedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
            schedule.QTB_Legal_Entity__c  = usEntity.id;
            insert schedule;
            
            blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
            invoiceRun.Name = 'test invoice';
            invoiceRun.blng__InvoiceScheduler__c = schedule.id;
            invoiceRun.blng__Status__c = 'Started';
            invoiceRun.blng__StartTime__c = System.now(); 
            invoiceRun.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
            invoiceRun.blng__TargetDate__c = Date.valueOf('2021-09-01');
            insert invoiceRun;
            
            QTB_Foreign_Exchange__c fe = new QTB_Foreign_Exchange__c();
            fe.QTB_Start_Date__c = System.today().addDays(-2);
            fe.QTB_End_Date__c = System.today().addDays(5);
            fe.QTB_Rate__c = 70;
            fe.QTB_Currency_To__c = 'EUR';
            fe.QTB_Currency_From__c = 'INR';
            fe.QTB_Tax_Rate_Type__c = 'Corporate';
            //fe.CurrencyIsoCode='EUR';
            insert fe;
            
            //BillFlowController
        QTB_Bill_Flow_Controller__c prebillrunrecord = new QTB_Bill_Flow_Controller__c();
        prebillrunrecord.Invoice_Scheduler__c = schedule.Id;
        insert prebillrunrecord;
            
            set<string> setstr = new set<string>{'India-1st'};
                List<string> lststr = new List<string>{'India-1st'};
        
        //preBill Inputs
        QTB_PreBillBatchFlowController.FlowInputs prebillInputs = new QTB_PreBillBatchFlowController.FlowInputs();
        prebillInputs.invoiceBatches = lststr[0];
        prebillInputs.targetDate = date.today();
        prebillInputs.prebillBatchRunRecordId = prebillrunrecord.Id; 
        prebillInputs.InvoiceDate = system.today();
            //setstr.add(prebillInputs.invBatch[0]);
            //lststr.add(prebillInputs.invBatch[0]);
        
        List<QTB_PreBillBatchFlowController.FlowInputs> flowInput = new List<QTB_PreBillBatchFlowController.FlowInputs>{prebillInputs};
        QTB_ExchangeRateFieldsUpdateForPreBill.runPreBillExchangeRateBatch(flowInput);
                
            
            List<blng__UsageSummary__c> lst =[Select id,blng__PreratedAmount__c,blng__UnitPrice__c,blng__TotalQuantity__c,blng__AppliedUnitPrice__c,blng__Account__r.QTB_Contract_Currency__c,blng__Order__r.blng__InvoiceBatch__c,blng__Account__c,blng__Subtotal__c,blng__OrderProduct__r.Product2Id,blng__SummaryStartDate__c,blng__SummaryEndDate__c,
            blng__MatchingId__c,(select id,QTB_Product_Identifier_1__c from blng__Usages__r),QTB_Contracted_Currency_Rate__c,blng__NextBillingDate__c,blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c,blng__MatchingAttribute__c,blng__Account__r.CurrencyIsoCode from blng__UsageSummary__c];
            
            QTB_ExchangeRateFieldsUpdateForPreBill invoiceBatch = new QTB_ExchangeRateFieldsUpdateForPreBill(setstr,prebillInputs.targetDate,flowInput);
            database.executeBatch(invoiceBatch,1);
            invoiceBatch.execute(null,lst);
        }
        Test.stopTest();
    }
    private static testMethod void testmethod1() {
        
        Test.startTest();
        QTB_ExchangeRateFieldsUpdateForPreBill.throwExplicitException = true;
        date trgetDate = date.today();
        set<string> setstr = new set<string>{'India-1st'};
        QTB_ExchangeRateFieldsUpdateForPreBill obj = new QTB_ExchangeRateFieldsUpdateForPreBill(setstr,trgetDate,null);
        obj.execute(null, null);
        
        Test.stopTest();
        System.assertEquals(true, QTB_ExchangeRateFieldsUpdateForPreBill.throwExplicitException);
    }
}