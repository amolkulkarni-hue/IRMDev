/*****************************************************************************************************
* Class: QTB_PostBillFlowController_Test 
* Author: Accenture
* Purpose: This is a test class for QTB_PostBillFlowController
* Change History: 26/3/2021
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture
*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_PostBillFlowController_Test {
    @isTest
    static void testMethod1(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[0]) {
            //Test.startTest();
            Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
			custSetting.SObject_API_Name__c = 'blng__UsageSummary__c;blng__Usage__c;SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__InvoiceScheduler__c';
      		custSetting.Disable_VR__c = true;
      		custSetting.Disable_PB__c = true;
      		custSetting.Disable_Trigger__c = true;
      		// custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      		insert custSetting;
            
            
            //custom settings
            QTB_CustomInvoiceNumber__c IndCustomSettings = new QTB_CustomInvoiceNumber__c();
            IndCustomSettings.Name = 'India';
            IndCustomSettings.QTB_Country__c = 'India';
            IndCustomSettings.QTB_Next_Sequence_Number__c = '2000000001';
            IndCustomSettings.QTB_Is_Running__c =false; 
            IndCustomSettings.QTB_Date_Time__c=system.today()-1;
            insert IndCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'Malaysia';
            sweCustomSettings.QTB_Country__c = 'Malaysia';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '2000000001';
            insert sweCustomSettings; 
            
            Id pricebookId = Test.getStandardPricebookId();
            List<product2> product = QTB_TestDataFactory.createProducts(1);
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
            List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
            accountList[0].QTB_Bill_Cycle_Day__c = 'India IRM-1st';
            accountList[0].QTB_Legal_Entity_Country__c='India';
            //accountList[0].CurrencyIsoCode = 'INR';
            update accountList;
            
            List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
            //oppList[0].recordtypeid = QTB_Utils.OPP_BILL_RECTYPEID;
            //oppList[0].Pricebook2Id = pricebookId;
            //database.update(oppList);
            
            List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
            quoteList[0].SBQQ__PriceBook__c = pricebookId;
            quoteList[0].SBQQ__StartDate__c = System.Today();
            //quoteList[0].recordtypeId = QTB_Utils.QUOTE_BILL_RECTYPEID;
            //database.update(quoteList);
            //Test.startTest();
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
            orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
            orderList3[0].blng__InvoiceBatch__c = 'India IRM-1st';
            //database.update(orderList3);
            SBQQ.TriggerControl.disable();
            List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].Id,quoteLinesList,standardPrice);
            List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
            List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0]);
            blng__UsageSummary__c usagesummary = usageSum[0];
            usagesummary.id = usageSum[0].id;
            usagesummary.blng__Status__c = 'New';
            usagesummary.blng__MatchingId__c = '0002449102100-0446';
            usagesummary.blng__SummaryStartDate__c = Date.valueOf('2021-08-01');
            usagesummary.blng__SummaryEndDate__c = Date.valueOf('2021-08-31');
            usagesummary.blng__NextBillingDate__c = Date.valueOf('2021-09-01');
            //usagesummary.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
            
            //database.update(usagesummary);
            
            List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
            usageList[0].blng__MatchingId__c = '0002449102100-0446';
            usageList[0].blng__Status__c = 'New';
            usageList[0].blng__StartDateTime__c = Date.valueOf('2021-08-01');
            usageList[0].blng__EndDateTime__c = Date.valueOf('2021-08-03');
            usageList[0].QTB_System_Generated__c = true;
            usageList[0].blng__PreratedAmount__c = 100;
            usageList[0].blng__PreratedQuantity__c = 10;
            usageList[0].QTB_Service_District__c = '44147';
            usageList[0].blng__UsageSummary__c = usageSum[0].id;
            usageList[0].blng__Order__c = orderList3[0].id;
            usageList[0].blng__OrderProduct__c = orderItemList3[0].id;          
            database.update(usageList);
            
            blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
            
            QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
            
            //Billing Finanace
            blng__FinanceBook__c indiaFinanceBook = new blng__FinanceBook__c();
            indiaFinanceBook.Name = 'Accounting Finance Book';
            indiaFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
            indiaFinanceBook.blng__Active__c = true;
            indiaFinanceBook.blng__PeriodType__c='Accounting';
            insert indiaFinanceBook;
            
            blng__FinancePeriod__c indiaFinancePeriod = new blng__FinancePeriod__c();
            indiaFinancePeriod.Name = 'india Mar 2024';
            indiaFinancePeriod.blng__FinanceBook__c = indiaFinanceBook.id;
            indiaFinancePeriod.blng__PeriodStartDate__c = system.today().toStartofMonth();
            indiaFinancePeriod.blng__PeriodEndDate__c = system.today().addMonths(1).toStartofMonth().addDays(-1);
            indiaFinancePeriod.blng__LegalEntity__c = indiaEntity.id;
            indiaFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
            insert indiaFinancePeriod;  
            
            Test.startTest();
            blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
            schedule.Name = 'test';
            schedule.blng__Type__c = 'Once';
            schedule.blng__InvoiceBatches__c = 'India IRM-1st';
            schedule.CurrencyIsoCode = 'INR';
            schedule.blng__StartDateTime__c = Datetime.newInstance(2023, 11, 22, 11, 00, 0);
            schedule.blng__InvoiceDate__c = Date.valueOf('2023-08-01');
            schedule.blng__TargetDate__c = Date.valueOf('2023-09-01');
            schedule.QTB_Invoice_Period__c = indiaFinancePeriod.id ;
            schedule.QTB_Legal_Entity__c = indiaEntity.id;
            
            insert schedule;
            
            blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
            invoiceRun.Name = 'test invoice';
            invoiceRun.blng__InvoiceScheduler__c = schedule.id;
            invoiceRun.blng__Status__c = 'Started';
            invoiceRun.blng__StartTime__c = System.now(); 
            invoiceRun.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
            invoiceRun.blng__TargetDate__c = Date.valueOf('2021-09-01');
            insert invoiceRun;
            
            invoiceRun.blng__Status__c = 'Completed';
            
            Update invoiceRun;
            
            /*blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
            invoiceRun.Name = 'test invoice';
            invoiceRun.blng__Status__c = 'Completed';
            invoiceRun.blng__TargetDate__c = System.today();
            insert invoiceRun;*/
            
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accountList[0].Id;
            invoice.blng__InvoiceStatus__c = 'Draft';
            invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.id;
            //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
            insert invoice;
            
            QTB_Bill_Flow_Controller__c postbillrunrecord = new QTB_Bill_Flow_Controller__c();
            postbillrunrecord.Invoice_Scheduler__c = schedule.id;
            postbillrunrecord.QTB_Rebill_Invoice__c = invoice.id;
            insert postbillrunrecord;
            
            QTB_PostBillFlowController postBill = new QTB_PostBillFlowController();
            QTB_PostBillFlowController.FlowInputs postbillFlowInputs = new QTB_PostBillFlowController.FlowInputs();
            postbillFlowInputs.invoiceBatches = 'India IRM-1st';
            postbillFlowInputs.postbillBatchRunRecordId =postbillrunrecord.id;
            List<QTB_PostBillFlowController.FlowInputs> flowInput = new List<QTB_PostBillFlowController.FlowInputs>{postbillFlowInputs};
                system.debug('flowInput '+flowInput);
                QTB_PostBillFlowController.runPostBillBatches(flowInput);
            
            try{
                Set<Id> testBillFlowRecordIds = new Set<Id>();
                testBillFlowRecordIds.add('dummyId1');
                QTB_PostBillFlowController.getInvoiceIds(testBillFlowRecordIds);
            }catch(exception e){
                QTB_ExceptionLogger.enable();
                //QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            }    
            Test.stopTest();
            System.assertEquals('India IRM-1st', postbillFlowInputs.invoiceBatches); 
        }
    }  
    
    @isTest
    static void testMethod12(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[0]) {
            //Test.startTest();
            Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
			custSetting.SObject_API_Name__c = 'blng__UsageSummary__c;blng__Usage__c;SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__InvoiceScheduler__c';
      		custSetting.Disable_VR__c = true;
      		custSetting.Disable_PB__c = true;
      		custSetting.Disable_Trigger__c = true;
      		// custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      		insert custSetting;
           //custom settings
            QTB_CustomInvoiceNumber__c IndCustomSettings = new QTB_CustomInvoiceNumber__c();
            IndCustomSettings.Name = 'India';
            IndCustomSettings.QTB_Country__c = 'India';
            IndCustomSettings.QTB_Next_Sequence_Number__c = '2000000001';
            IndCustomSettings.QTB_Is_Running__c =true; 
            insert IndCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'Malaysia';
            sweCustomSettings.QTB_Country__c = 'Malaysia';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '2000000001';
            insert sweCustomSettings; 
            
            Id pricebookId = Test.getStandardPricebookId();
            List<product2> product = QTB_TestDataFactory.createProducts(1);
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
            List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
            accountList[0].QTB_Bill_Cycle_Day__c = 'India IRM-1st';
            accountList[0].QTB_Legal_Entity_Country__c='India';
            //accountList[0].CurrencyIsoCode = 'INR';
            update accountList;
            
            List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
            //oppList[0].recordtypeid = QTB_Utils.OPP_BILL_RECTYPEID;
            //oppList[0].Pricebook2Id = pricebookId;
            //database.update(oppList);
            
            List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
            quoteList[0].SBQQ__PriceBook__c = pricebookId;
            quoteList[0].SBQQ__StartDate__c = System.Today();
            //quoteList[0].recordtypeId = QTB_Utils.QUOTE_BILL_RECTYPEID;
            //database.update(quoteList);
            //Test.startTest();
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
            orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
            orderList3[0].blng__InvoiceBatch__c = 'India IRM-1st';
            //database.update(orderList3);
            SBQQ.TriggerControl.disable();
            List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].Id,quoteLinesList,standardPrice);
            List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
            List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0]);
            blng__UsageSummary__c usagesummary = usageSum[0];
            usagesummary.id = usageSum[0].id;
            usagesummary.blng__Status__c = 'New';
            usagesummary.blng__MatchingId__c = '0002449102100-0446';
            usagesummary.blng__SummaryStartDate__c = Date.valueOf('2021-08-01');
            usagesummary.blng__SummaryEndDate__c = Date.valueOf('2021-08-31');
            usagesummary.blng__NextBillingDate__c = Date.valueOf('2021-09-01');
            //usagesummary.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
            
            //database.update(usagesummary);
            
            List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
            usageList[0].blng__MatchingId__c = '0002449102100-0446';
            usageList[0].blng__Status__c = 'New';
            usageList[0].blng__StartDateTime__c = Date.valueOf('2021-08-01');
            usageList[0].blng__EndDateTime__c = Date.valueOf('2021-08-03');
            usageList[0].QTB_System_Generated__c = true;
            usageList[0].blng__PreratedAmount__c = 100;
            usageList[0].blng__PreratedQuantity__c = 10;
            usageList[0].QTB_Service_District__c = '44147';
            usageList[0].blng__UsageSummary__c = usageSum[0].id;
            usageList[0].blng__Order__c = orderList3[0].id;
            usageList[0].blng__OrderProduct__c = orderItemList3[0].id;          
            database.update(usageList);
            
            blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
            
            QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
            
            //Billing Finanace
            blng__FinanceBook__c indiaFinanceBook = new blng__FinanceBook__c();
            indiaFinanceBook.Name = 'Accounting Finance Book';
            indiaFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
            indiaFinanceBook.blng__Active__c = true;
            indiaFinanceBook.blng__PeriodType__c='Accounting';
            insert indiaFinanceBook;
            
            blng__FinancePeriod__c indiaFinancePeriod = new blng__FinancePeriod__c();
            indiaFinancePeriod.Name = 'india Mar 2024';
            indiaFinancePeriod.blng__FinanceBook__c = indiaFinanceBook.id;
            indiaFinancePeriod.blng__PeriodStartDate__c = system.today().toStartofMonth();
            indiaFinancePeriod.blng__PeriodEndDate__c = system.today().addMonths(1).toStartofMonth().addDays(-1);
            indiaFinancePeriod.blng__LegalEntity__c = indiaEntity.id;
            indiaFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
            insert indiaFinancePeriod;  
            
            Test.startTest();
            blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
            schedule.Name = 'test';
            schedule.blng__Type__c = 'Once';
            schedule.blng__InvoiceBatches__c = 'India IRM-1st';
            schedule.CurrencyIsoCode = 'INR';
            schedule.blng__StartDateTime__c = Datetime.newInstance(2023, 11, 22, 11, 00, 0);
            schedule.blng__InvoiceDate__c = Date.valueOf('2023-08-01');
            schedule.blng__TargetDate__c = Date.valueOf('2023-09-01');
            schedule.QTB_Invoice_Period__c = indiaFinancePeriod.id ;
            schedule.QTB_Legal_Entity__c = indiaEntity.id;
            
            insert schedule;
            
            blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
            invoiceRun.Name = 'test invoice';
            invoiceRun.blng__InvoiceScheduler__c = schedule.id;
            invoiceRun.blng__Status__c = 'Started';
            invoiceRun.blng__StartTime__c = System.now(); 
            invoiceRun.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
            invoiceRun.blng__TargetDate__c = Date.valueOf('2021-09-01');
            insert invoiceRun;
            
            invoiceRun.blng__Status__c = 'Completed';
            
            Update invoiceRun;
            
            /*blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
            invoiceRun.Name = 'test invoice';
            invoiceRun.blng__Status__c = 'Completed';
            invoiceRun.blng__TargetDate__c = System.today();
            insert invoiceRun;*/
            
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accountList[0].Id;
            invoice.blng__InvoiceStatus__c = 'Draft';
            invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.id;
            //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
            insert invoice;
            
            QTB_Bill_Flow_Controller__c postbillrunrecord = new QTB_Bill_Flow_Controller__c();
            postbillrunrecord.Invoice_Scheduler__c = schedule.id;
            postbillrunrecord.QTB_Rebill_Invoice__c = invoice.id;
            insert postbillrunrecord;
            
            QTB_PostBillFlowController postBill = new QTB_PostBillFlowController();
            QTB_PostBillFlowController.FlowInputs postbillFlowInputs = new QTB_PostBillFlowController.FlowInputs();
            postbillFlowInputs.invoiceBatches = 'India IRM-1st';
            postbillFlowInputs.postbillBatchRunRecordId =postbillrunrecord.id;
            List<QTB_PostBillFlowController.FlowInputs> flowInput = new List<QTB_PostBillFlowController.FlowInputs>{postbillFlowInputs};
                system.debug('flowInput '+flowInput);
                QTB_PostBillFlowController.runPostBillBatches(flowInput);
            
            try{
                QTB_PostBillFlowController.getInvoiceIds(null);
                QTB_PostBillFlowController.throwExplicitException = true;
            }catch(exception e){
                QTB_ExceptionLogger.enable();
                //QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            }    
            Test.stopTest();
            System.assertEquals('India IRM-1st', postbillFlowInputs.invoiceBatches); 
        }
    } 
    
    @isTest
    static void testMethod2(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[0]) {
            //Test.startTest();
            Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
			custSetting.SObject_API_Name__c = 'blng__UsageSummary__c;blng__Usage__c;SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Order;blng__InvoiceLine__c;blng__CreditNoteLine__c;blng__InvoiceScheduler__c';
      		custSetting.Disable_VR__c = true;
      		custSetting.Disable_PB__c = true;
      		custSetting.Disable_Trigger__c = true;
      		// custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      		insert custSetting;
            //metaData
            QTB_Tax_Integration_Setting__mdt vertexData = new QTB_Tax_Integration_Setting__mdt();
            vertexData.Label = 'Vertex';
            vertexData.DeveloperName = 'Vertex_Integration';
            vertexData.QTB_Country__c = 'United States;Canada';
            vertexData.QTB_End_System__c = 'Vertex';
            
            //custom settings
            QTB_CustomInvoiceNumber__c IndCustomSettings = new QTB_CustomInvoiceNumber__c();
            IndCustomSettings.Name = 'United States';
            IndCustomSettings.QTB_Country__c = 'United States';
            IndCustomSettings.QTB_Next_Sequence_Number__c = '2000000001';
            IndCustomSettings.QTB_Is_Running__c =true;
            insert IndCustomSettings;
            QTB_CustomInvoiceNumber__c sweCustomSettings = new QTB_CustomInvoiceNumber__c();
            sweCustomSettings.Name = 'Malaysia';
            sweCustomSettings.QTB_Country__c = 'Malaysia';
            sweCustomSettings.QTB_Next_Sequence_Number__c = '2000000001';
            insert sweCustomSettings; 
            
            Id pricebookId = Test.getStandardPricebookId();
            List<product2> product = QTB_TestDataFactory.createProducts(1);
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
            List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
            accountList[0].QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM';
            accountList[0].QTB_Legal_Entity_Country__c='United States';
            //accountList[0].CurrencyIsoCode = 'INR';
            //accountList[0].IM_Hierarchy_Level__c = 'Sales (Site)';
            update accountList;
            
            List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
            //oppList[0].recordtypeid = QTB_Utils.OPP_BILL_RECTYPEID;
            //oppList[0].Pricebook2Id = pricebookId;
            //database.update(oppList);
            
            List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
            quoteList[0].SBQQ__PriceBook__c = pricebookId;
            quoteList[0].SBQQ__StartDate__c = System.Today();
            //quoteList[0].recordtypeId = QTB_Utils.QUOTE_BILL_RECTYPEID;
            //database.update(quoteList);
            //Test.startTest();
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
            orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
            orderList3[0].QTB_OrderCategory__c   = 'Rebill';
            orderList3[0].blng__InvoiceBatch__c = 'Rebill Run';
            //database.update(orderList3);
            SBQQ.TriggerControl.disable();
            List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].Id,quoteLinesList,standardPrice);
            List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
            List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0]);
            blng__UsageSummary__c usagesummary = usageSum[0];
            usagesummary.id = usageSum[0].id;
            usagesummary.blng__Status__c = 'New';
            usagesummary.blng__MatchingId__c = '0002449102100-0446';
            usagesummary.blng__SummaryStartDate__c = Date.valueOf('2021-08-01');
            usagesummary.blng__SummaryEndDate__c = Date.valueOf('2021-08-31');
            usagesummary.blng__NextBillingDate__c = Date.valueOf('2021-09-01');
            //usagesummary.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
            
            //database.update(usagesummary);
            
            List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
            usageList[0].blng__MatchingId__c = '0002449102100-0446';
            usageList[0].blng__Status__c = 'New';
            usageList[0].blng__StartDateTime__c = Date.valueOf('2021-08-01');
            usageList[0].blng__EndDateTime__c = Date.valueOf('2021-08-03');
            usageList[0].QTB_System_Generated__c = true;
            usageList[0].blng__PreratedAmount__c = 100;
            usageList[0].blng__PreratedQuantity__c = 10;
            usageList[0].QTB_Service_District__c = '44147';
            usageList[0].blng__UsageSummary__c = usageSum[0].id;
            usageList[0].blng__Order__c = orderList3[0].id;
            usageList[0].blng__OrderProduct__c = orderItemList3[0].id;          
            database.update(usageList);
            
            blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
            usaEntity.Name = 'Iron Mountain Information Management, LLC';
            usaEntity.blng__Active__c = true;
            usaEntity.blng__Country__c = 'United States';
            usaEntity.QTB_Type__c = 'Contract';
            insert usaEntity; 
            
            QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
            
            //Billing Finanace
            blng__FinanceBook__c finlandFinanceBook = new blng__FinanceBook__c();
            finlandFinanceBook.Name = 'Accounting Finance Book';
            finlandFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
            finlandFinanceBook.blng__Active__c = true;
            finlandFinanceBook.blng__PeriodType__c='Accounting';
            insert finlandFinanceBook;
            
            blng__FinancePeriod__c finlandFinancePeriod = new blng__FinancePeriod__c();
            finlandFinancePeriod.Name = 'United States Mar 2024';
            finlandFinancePeriod.blng__FinanceBook__c = finlandFinanceBook.id;
            finlandFinancePeriod.blng__PeriodStartDate__c = system.today().toStartofMonth();
            finlandFinancePeriod.blng__PeriodEndDate__c = system.today().addMonths(1).toStartofMonth().addDays(-1);
            finlandFinancePeriod.blng__LegalEntity__c = usaEntity.id;
            finlandFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
            insert finlandFinancePeriod;  
            Test.startTest();
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accountList[0].Id;
            invoice.blng__InvoiceStatus__c = 'Draft';
            invoice.QTB_Invoice_Type__c = 'ReBill';
            //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
            insert invoice;
            
            QTB_Bill_Flow_Controller__c postbillrunrecord = new QTB_Bill_Flow_Controller__c();
            postbillrunrecord.QTB_Rebill_Invoice__c = invoice.id;
            postbillrunrecord.Invoice_Scheduler__c = null;
            insert postbillrunrecord;
            
            QTB_PostBillFlowController postBill = new QTB_PostBillFlowController();
            QTB_PostBillFlowController.FlowInputs postbillFlowInputs = new QTB_PostBillFlowController.FlowInputs();
            postbillFlowInputs.invoiceBatches = 'Rebill Run';
            postbillFlowInputs.postbillBatchRunRecordId =postbillrunrecord.id;
            List<QTB_PostBillFlowController.FlowInputs> flowInput = new List<QTB_PostBillFlowController.FlowInputs>{postbillFlowInputs};
                QTB_PostBillFlowController.runPostBillBatches(flowInput);
            
            //List<QTB_Invoice_Batch_by_Bill_Cycle__mdt> mdt=[select id,Label, MasterLabel,QTB_Bill_Cycle_Day__c, QTB_Country__c, QTB_Invoice_Batch__c from QTB_Invoice_Batch_by_Bill_Cycle__mdt where QTB_Country__c='finland'];
            try{
                QTB_PostBillFlowController.runPostBillBatches(NULL);
            }catch(exception e){
                QTB_ExceptionLogger.enable();
                //QTB_ExceptionLogger.createLog(e.getLineNumber(),e.getStackTraceString(),e.getMessage(),e.getTypeName(),CLASSNAME);
            }
            Test.stopTest();
            System.assertEquals('Rebill Run', postbillFlowInputs.invoiceBatches); 
        }
    }  
    
}