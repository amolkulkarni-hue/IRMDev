/*****************************************************************************************************
* Class: QTB_ExchangeRateFieldsUpdate_Test
* Author: Virtusa
* Purpose: This is a test class for QTB_ExchangeRateFieldsUpdateForPreBill
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Virtusa    18/12.2024
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_ExchangeRateFieldsUpdate_Test {
    @isTest
    private static void testMethod1() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        Test.startTest();
        System.runAs(userList[0]) {
            SBQQ.TriggerControl.disable();
            Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
            custSetting.SObject_API_Name__c = 'blng__UsageSummary__c;blng__Usage__c;SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__Invoice__c;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__InvoiceScheduler__c';
            custSetting.Disable_VR__c = true;
            custSetting.Disable_PB__c = true;
            custSetting.Disable_Trigger__c = true;
            // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
            insert custSetting;
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
            testAccount[0].QTB_Legal_Entity_Country__c = 'India';
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
            orderList3[0].QTB_OrderCategory__c = 'Evergreen';
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
            usagesummary.QTB_Contracted_Currency_Rate__c = 11;
            usagesummary.blng__NextBillingDate__c = System.now().date().addDays(-5);
            usagesummary.blng__PreratedAmount__c = 1000;
            usagesummary.blng__Subtotal__c = 1000;
            
            blng__UsageSummary__c usagesummary1 = usageSum[1];
            usagesummary1.blng__TotalQuantity__c = 10;
            usagesummary1.QTB_Contracted_Currency_Rate__c = 20;
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
            usage.blng__UnitPrice__c = 1;
            usage.blng__OrderProduct__c = orderItemList3[0].id;
            usage.blng__Order__c = orderList3[0].id; 
            usage.QTB_Contracted_Currency_Amount__c = 100;
            
            blng__Usage__c usage1 = usageList[1];
            usage1.blng__PreratedAmount__c = 10;
            usage1.blng__PreratedQuantity__c = 10;
            //usage1.blng__Quantity__c = 15;
            usage1.blng__MatchingId__c = '1234';
            usage1.QTB_Contracted_Currency_Amount__c = 100;
            usage1.blng__Status__c = 'Processed';
            usage1.blng__UnitPrice__c = 5;
            usage1.QTB_Price_Tier__c = 'Tier 1';
            
            usageListnew.add(usage);
            usageListnew.add(usage1);
            update usageListnew;
            
            
            blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
            schedule.Name = 'test IRM EXE';
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
            
            List<blng__Invoice__c> lstInvc = new List<blng__Invoice__c>();
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = testAccount[0].Id;
            invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.id;
            invoice.blng__InvoiceStatus__c = 'Draft';
            invoice.QTB_Tax_Override_Amount__c = 222;
            invoice.blng__InvoiceDate__c = System.today()-10;
            invoice.CurrencyIsoCode = 'EUR';
            lstInvc.add(invoice);
            insert invoice;
            
            blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
            invoiceLine.Name = product[0].Name;
            invoiceLine.blng__Invoice__c = invoice.Id;
            invoiceLine.blng__Product__c = product[0].Id;
            invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
            invoiceLine.blng__Quantity__c = 10;
            invoiceLine.blng__UnitPrice__c = 5;
            invoiceLine.blng__Subtotal__c = 100;
            invoiceLine.blng__TotalAmount__c = 200;
            invoiceLine.blng__OrderProduct__c = orderItemList3[0].id;
            invoiceLine.blng__UsageSummary__c = usagesummary.id;
            invoiceLine.blng__TaxPercentageApplied__c = 24;
            invoiceLine.blng__TaxStatus__c = 'Completed';
            insert invoiceLine;
            
            /*List<blng__InvoiceLine__c> invLineList = QTB_TestDataFactory.createInvoiceLine(
1,
lstInvc,
product
);
invLineList[0].blng__OrderProduct__c = orderItemList3[0].id;
invLineList[0].blng__UsageSummary__c = usagesummary.id;
//invLineList[0].blng__Subtotal__c =123;
testAccount[0].SBQQ__TaxExempt__c = 'No';
invLineList[0].blng__TaxStatus__c = 'Completed';
update invLineList;*/
            
            QTB_Foreign_Exchange__c fe = new QTB_Foreign_Exchange__c();
            fe.QTB_Start_Date__c = System.today();
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
            prebillrunrecord.QTB_Rebill_Invoice__c = invoice.Id;
            insert prebillrunrecord;
            
            set<string> setstr = new set<string>{'India-1st'};
                List<string> lststr = new List<string>{'India-1st'}; 
                    
                    //preBill Inputs
                    QTB_PostBillFlowController.flowInputs postbillInputs = new QTB_PostBillFlowController.flowInputs();
            
            postbillInputs.postbillBatchRunRecordId = prebillrunrecord.Id;
            postbillInputs.invoiceBatches = 'India-1st';
            
            List<blng__Invoice__c> lst = [SELECT Id,blng__Account__r.QTB_Legal_Entity_Country__c,QTB_Tax_Override_Amount__c,blng__Account__r.QTB_Contract_Currency__c,blng__Account__r.CurrencyIsoCode,blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c, CurrencyIsoCode from blng__Invoice__c where blng__InvoiceRunCreatedBy__r.blng__InvoiceScheduler__c =: schedule.id];
            
            List<QTB_PostBillFlowController.flowInputs> flowInput = new List<QTB_PostBillFlowController.flowInputs>{postbillInputs};
                QTB_ExchangeRateFieldsUpdate.runPostBillExchangeRateBatch(flowInput);
            
            QTB_ExchangeRateFieldsUpdate invoiceBatch = new QTB_ExchangeRateFieldsUpdate(flowInput);
            database.executeBatch(invoiceBatch,1);
            invoiceBatch.execute(null,lst);
        }
        Test.stopTest();
    }
    private static testMethod void testmethod2() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]){
            test.startTest();
            Metadata_Activation_Settings__c custSetting1 = new Metadata_Activation_Settings__c();
            custSetting1.SObject_API_Name__c = 'blng__UsageSummary__c;blng__Usage__c;SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__Invoice__c;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__InvoiceScheduler__c';
            custSetting1.Disable_VR__c = true;
            custSetting1.Disable_PB__c = true;
            custSetting1.Disable_Trigger__c = true;
            custSetting1.SetupOwnerId = UserInfo.getOrganizationId();
            insert custSetting1;
            QTB_ExchangeRateFieldsUpdateForPreBill.throwExplicitException = true;
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
            blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
            schedule.Name = 'test IRM EXE';
            schedule.blng__Type__c = 'Once';
            //schedule.blng__InvoiceBatches__c = 'United States-DM-1st-EOM Manual';
            schedule.CurrencyIsoCode = 'USD';
            schedule.blng__StartDateTime__c = System.now().addDays(5);
            schedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
            schedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
            schedule.QTB_Legal_Entity__c  = usEntity.id;
            insert schedule;
            set<id> st = new set<id>{schedule.id};
                set<id> st1 = new set<id>();
            List<QTB_PostBillFlowController.FlowInputs> lst = new List<QTB_PostBillFlowController.FlowInputs>();
            QTB_ExchangeRateFieldsUpdate invoiceBatch = new QTB_ExchangeRateFieldsUpdate(lst);
            database.executeBatch(invoiceBatch,1);
            invoiceBatch.execute(null,null);
            
            Test.stopTest();
            System.assertEquals(true, QTB_ExchangeRateFieldsUpdateForPreBill.throwExplicitException);
        }
    }
}