/*****************************************************************************************************
* Class: QTB_SubInvoiceLineCreationBatch_Test
* Author: Virtusa
* Purpose: This is a test class for QTB_SubInvoiceLineCreationBatch
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Virtusa    25/04.2025
*******************************************************************************************************/
@isTest(seealldata=false) 
private class QTB_SubInvoiceLineCreationBatch_Test {
    @testsetup
    private static void setup() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        Test.startTest();
        System.runAs(userList[0]) {
            Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
            custSetting.SObject_API_Name__c = 'blng__Usage__c;Account;blng__InvoiceLine__c';
            custSetting.Disable_VR__c = true;
            custSetting.Disable_PB__c = true;
            custSetting.Disable_Trigger__c = true;
            // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
            insert custSetting;
            SBQQ.TriggerControl.disable();
            //Legal Entity
            blng__LegalEntity__c usEntity = new blng__LegalEntity__c();
            USEntity.Name = 'Test Legal Entity United States';
            USEntity.blng__Active__c = true;
            USEntity.blng__Country__c = 'United States';
            USEntity.QTB_Storage_Service_Period_Range__c = true;
            USEntity.QTB_Tax_Applicability__c = 'Product Based';
            USEntity.QTB_FX_Tax_Rate_Type__c = 'Corporate';
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
            product[0].QTB_Price_Schedule_Category__c = 'Storage';
            database.update(product);
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
                product[0]
            );
            
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
            
            List<blng__Usage__c> usageListnew = new List<blng__Usage__c>();
            List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(
                2,
                testAccount[0],
                usagesummary
            );
            blng__Usage__c usage = usageList[0];
            usage.blng__PreratedAmount__c = 100;
            usage.blng__PreratedQuantity__c = 10;
            usage.QTB_Contracted_Currency_Amount__c = 100;
            usage.QTB_Prerated_Unit_Price__c = 10;
            usage.blng__OrderProduct__c = orderItemList3[0].id;
            usage.blng__Order__c = orderList3[0].id;
            usage.QTB_Start_Date_MRC__c = date.today().addDays(-30);
            usage.QTB_End_Date_MRC__c= date.today();
            
            
            blng__Usage__c usage1 = usageList[1];
            usage1.blng__PreratedAmount__c = 100;
            usage1.blng__PreratedQuantity__c = 10;
            usage1.QTB_Contracted_Currency_Amount__c = 100;
            usage1.blng__PreratedQuantity__c = 10;
            usage1.blng__MatchingId__c = '1234';
            usage1.blng__Status__c = 'Processed';
            usage1.QTB_Prerated_Unit_Price__c = 5;
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
            
            List<blng__Invoice__c> invoiceList = new List<blng__Invoice__c>();
            for (Account acc : testAccount) {
                blng__Invoice__c invoice = new blng__Invoice__c();
                invoice.blng__Account__c = acc.Id;
                invoice.blng__InvoiceStatus__c = 'Draft';
                invoice.blng__InvoiceDate__c = System.today()-10;
                invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.Id;
                invoice.QTB_Tax_Override_Amount__c = 50;
                invoice.QTB_hasTieredLines__c = true;
                invoiceList.add(invoice);
                break;
            }
            if (!invoiceList.isEmpty()) {
                insert invoiceList;
            }
            
            List<blng__InvoiceLine__c> invLineList = QTB_TestDataFactory.createInvoiceLine(1,invoiceList,product);
            invLineList[0].blng__OrderProduct__c = orderItemList3[0].id;
            invLineList[0].blng__UsageSummary__c = usagesummary.id;
            invLineList[0].currencyISOCode = 'INR';
            invLineList[0].blng__InvoiceLineStatus__c = 'Draft';
            invLinelist[0].blng__TaxAmount__c = 50;
            invLineList[0].QTB_Tax_Override_Amount__c = 50;
            invLineList[0].blng__UnitPrice__c = 10;
            invLineList[0].blng__Quantity__c = 10;
            invLinelist[0].blng__TaxCountry__c = 'India';
            invLinelist[0].blng__TaxState__c = 'TN';
            invLinelist[0].blng__TaxCity__c = 'Chennai';
            invLinelist[0].blng__TaxZipCode__c = '500032';
            invLinelist[0].blng__TaxRule__c  = taxRule.id;
            invLinelist[0].blng__LegalEntity__c = USEntity.id;
            invLinelist[0].blng__Subtotal__c = 100;
            invLinelist[0].blng__TotalAmount__c = 150;
            database.update(invLineList[0]);
            //BillFlowController
            QTB_Bill_Flow_Controller__c billFlow = new QTB_Bill_Flow_Controller__c();
            billFlow.Invoice_Scheduler__c = schedule.Id;
            insert billFlow;
            
            //flow Inputs
			QTB_SubInvoiceLineCreationBatch.FlowInputs flwInputs = new QTB_SubInvoiceLineCreationBatch.FlowInputs();
            flwInputs.invoiceSchedulerId = schedule.Id;
            flwInputs.billFlowControllerId = billFlow.Id;
            
            List<QTB_SubInvoiceLineCreationBatch.FlowInputs> flowInput = new List<QTB_SubInvoiceLineCreationBatch.FlowInputs>{flwInputs};
            QTB_SubInvoiceLineCreationBatch.executeSubInvoiceLineCreationBatch(flowInput);
            
            List<blng__UsageSummary__c> lst =[Select id,blng__PreratedAmount__c,blng__UnitPrice__c,blng__TotalQuantity__c,blng__AppliedUnitPrice__c,blng__Account__r.QTB_Contract_Currency__c,blng__Order__r.blng__InvoiceBatch__c,blng__Account__c,blng__Subtotal__c,blng__OrderProduct__r.Product2Id,blng__SummaryStartDate__c,blng__SummaryEndDate__c,
                                              blng__MatchingId__c,QTB_Contracted_Currency_Rate__c,blng__NextBillingDate__c,blng__Account__r.QTB_Contract_Entity__r.QTB_FX_Tax_Rate_Type__c,blng__MatchingAttribute__c,blng__Account__r.CurrencyIsoCode from blng__UsageSummary__c];
            
        }
        Test.stopTest();
    }
    private static testMethod void testmethod1() {
        
        Test.startTest();
        QTB_SubInvoiceLineCreationBatch.throwExplicitException = true;
        QTB_Bill_Flow_Controller__c billFlow = [Select Id from QTB_Bill_Flow_Controller__c limit 1];
        blng__Invoice__c inv = [Select Id,blng__InvoiceStatus__c,QTB_Sublines_Added__c,blng__Account__r.QTB_Legal_Entity__r.QTB_Tax_Applicability__c,blng__Account__r.QTB_Legal_Entity__r.QTB_Storage_Service_Period_Range__c from blng__Invoice__c limit 1];
        QTB_SubInvoiceLineCreationBatch.FlowInputs flwInputs = new QTB_SubInvoiceLineCreationBatch.FlowInputs();
        flwInputs.rebillAdhocInvoiceId = inv.Id;
        flwInputs.billFlowControllerId = billFlow.Id;
        List<QTB_SubInvoiceLineCreationBatch.FlowInputs> flowInput = new List<QTB_SubInvoiceLineCreationBatch.FlowInputs>{flwInputs};
        QTB_SubInvoiceLineCreationBatch.executeSubInvoiceLineCreationBatch(flowInput);
        database.executeBatch(new QTB_SubInvoiceLineCreationBatch(flowInput),1);
        Test.stopTest();
        
    }
}