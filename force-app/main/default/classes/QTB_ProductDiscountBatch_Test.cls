/*****************************************************************************************************
* Class: QTB_ProductDiscountBatch_Test
* Author: Accenture
* Purpose: Test Class for QTB_ProductDiscountBatch
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Accenture   06/01/2020
*******************************************************************************************************/
@isTest(seeAlldata=false)
private with sharing class QTB_ProductDiscountBatch_Test {
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
            //accountList[0].QTB_Legal_Entity_Country__c='Norway';
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
            product[0].SBQQ__ChargeType__c = 'Recurring';
            product[0].SBQQ__BillingType__c ='Advance';
            product[0].SBQQ__HasConsumptionSchedule__c = true;
            product[0].recordTypeId = QTB_Utils.GLOBAL_SALES_RECTYPEID;
            product[0].QTB_Oracle_Product_Code__c = '123';
            product[0].QTB_Oracle_GL_Account_Code__c='7';
            SBQQ.TriggerControl.disable();
            update product;
            SBQQ.TriggerControl.enable();
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
            update quoteList;
            
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
            update quoteLinesList[0];
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
            
            blng__InvoiceScheduler__c blngInvoice = QTB_TestDataFactory.createInvoiceScheduler(
                'Norway-26th',
                'Once'
            );
            
            Metadata_Activation_Settings__c cust = new Metadata_Activation_Settings__c();
            cust.SObject_API_Name__c = 'blng__UsageSummary__c';
            cust.Disable_Trigger__c = true;
            insert cust;     
            List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(
                1,
                accountList[0],
                orderList[0],
                orderItemList[0]
            );
            usageSum[0].blng__Subtotal__c = 310;
            usageSum[0].blng__Status__c = 'Queued For Invoice';
            usageSum[0].blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
            // usageSum[0].blng__Account__r.QTB_Hold_Billing__c = False ;
            // usageSum[0].blng__OrderProduct__r.SBQQ__Activated__c=True ;
            update usageSum[0];  
            
            
            
            
            System.Assert(usageSum[0].blng__Status__c == 'Queued For Invoice');
            QTB_Product_Billing_Discount__c prodt = QTB_TestDataFactory.createProductDiscount(accountList[0], product[0]);
            // prodt.QTB_Account__c=accountList[0].id;
            prodt.QTB_Product__c=product[0].id;
            prodt.QTB_Active__c = true;
            prodt.QTB_Discount__c = 10;
            prodt.QTB_Start_Date__c = system.today() ;
            prodt.QTB_End_Date__c = system.today() ;
            //    update prodt;
            
            
            /*    Metadata_Activation_Settings__c cust1 = new Metadata_Activation_Settings__c();
            cust1.SObject_API_Name__c = 'blng__Usage__c';
            cust1.Disable_Trigger__c = true;
            insert cust1; 
            
            List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(
            2,
            accountList[0],
            usageSum[0]
            ); */
            Test.startTest();  
            QTB_TestDataFactory.createInvoices(accountList);
            
        }
        Test.stopTest();
    }
    
    static testMethod void testStatus() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[1]) {
            Account acc = [
                SELECT id
                FROM Account
                WHERE Name = 'Test Account'
                LIMIT 1
            ];
            blng__Invoice__c invoice = [
                SELECT id, blng__Account__c
                FROM blng__Invoice__c
                WHERE blng__Account__c = :acc.id
                LIMIT 1
            ];
            List<blng__UsageSummary__c> usageSum=[
                Select id,blng__Order__r.blng__InvoiceBatch__c,blng__Account__c,blng__Subtotal__c,blng__OrderProduct__r.Product2Id,
                blng__SummaryStartDate__c,blng__SummaryEndDate__c,blng__MatchingId__c,blng__Account__r.CurrencyIsoCode from  blng__UsageSummary__c 
                Limit 1
            ];
            /* blng__Usage__c usa =[
            Select id,blng__MatchingId__c,blng__StartDateTime__c,blng__EndDateTime__c,blng__PreratedAmount__c,
            CurrencyIsoCode from  blng__Usage__c Limit 1];
            /* QTB_Product_Billing_Discount__c prod=[Select id,QTB_Account__c,QTB_Product__c from QTB_Product_Billing_Discount__c Limit 1 ];*/
            
            QTB_Bill_Flow_Controller__c prebillrunrecord = new QTB_Bill_Flow_Controller__c();
            insert prebillrunrecord;
            System.assert(invoice.blng__Account__c == acc.id);
            Date targetDate = date.today();
            
            QTB_ProductDiscountBatch obj = new QTB_ProductDiscountBatch('Norway-26th',targetDate,prebillrunrecord.id);
            DataBase.executeBatch(obj);
            obj.execute(null,usageSum);
            Test.stopTest();
        }
    }
    //cover catch
    static testMethod void testMethod1() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[1]) {
            QTB_ProductDiscountBatch.throwExplicitException = true;
            QTB_Bill_Flow_Controller__c prebillrunrecord = new QTB_Bill_Flow_Controller__c();
            insert prebillrunrecord;
            
            Date targetDate = date.today();
            QTB_ProductDiscountBatch obj = new QTB_ProductDiscountBatch('Norway-26th',targetDate,prebillrunrecord.id);
            DataBase.executeBatch(obj);
            obj.execute(null,null);
            Test.stopTest();
            System.assertEquals(
                true,
                QTB_ProductDiscountBatch.throwExplicitException
            );
        }
    }
}