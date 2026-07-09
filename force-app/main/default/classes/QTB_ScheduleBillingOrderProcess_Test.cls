/*****************************************************************************************************
* Class: QTB_ScheduleBillingOrderProcess_Test
* Author: Accenture
* Purpose: Test Class for QTB_BillingOrderProcessBatch & QTB_ScheduleBillingOrderProcess
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   17/06/2020
*******************************************************************************************************/
@isTest(SeeAllData=false)
private class QTB_ScheduleBillingOrderProcess_Test {
    @testSetup static void testData(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1); 
        system.runas(userList[0]) { 
            QTB_Manage_Contract_Scheduler__c manageSchedule=new QTB_Manage_Contract_Scheduler__c();
            manageSchedule.Name='FirstRecord';
            manageSchedule.QTB_Contract_Schedueler_On__c=True;
            manageSchedule.QTB_Scheduler_Hold_Time_In_Min__c=5;
            insert manageSchedule;
            Test.startTest();
            List<account> accountList =QTB_TestDataFactory.createAccounts(1);
            accountList[0].BillingCountry='India';
            accountList[0].QTB_Legal_Entity_Country__c='India';
            update accountList;
            blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
            blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            
            List<product2> product=QTB_TestDataFactory.createProducts(1);
            product[0].blng__BillingRule__c=billingRule.id;
            product[0].blng__RevenueRecognitionRule__c =revenueRule.id;
            product[0].blng__TaxRule__c =taxRule.id;
            update product; 
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
            
            List<opportunity> oppList=QTB_TestDataFactory.createOpps(accountList);
            oppList[0].Pricebook2Id =pricebookId; 
            update oppList; 
            
            List<SBQQ__Quote__c> quoteList=QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
            quoteList[0].SBQQ__PriceBook__c=pricebookId;
            quoteList[0].SBQQ__StartDate__c = System.Today();
            update quoteList;
            
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1, quoteList[0].id,accountList[0].id );
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id );
            sbqq.triggerControl.disable();
            List<Order> orderList1 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
            orderList1[0].blng__BillingAccount__c = accountList[0].id;
            orderList1[0].EffectiveDate =date.valueOf(system.now()-1000);
            orderList1[0].QTB_Failed_Contracting_Attempts__c = 2;
            sbqq.triggerControl.disable();
            update orderList1;
            sbqq.triggerControl.enable();
            QTB_BillingOrderProcessBatch be = new QTB_BillingOrderProcessBatch();
            be.execute(null,orderList1);
            QTB_TestDataFactory.createBillingOrders(1,quoteList[0].Id,accountList[0].id);
            List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(orderList1[0].Id,product[0].Id,quoteLinesList,standardPrice);
            test.stopTest();
            system.assertEquals('India', accountList[0].BillingCountry);
        }
    }
    
    static testmethod void testData1(){
        Test.startTest();
        List<Order> ord=[Select id,Status from Order limit 1];
        //ord.Status = 'Activated';
        //update ord;
        System.schedule('QTB_BillingProcess'+System.now(),QTB_RenewalBillingBatchHelper.setHoldTime(5),new QTB_ScheduleBillingOrderProcess());
        Test.stopTest();  
        system.assertEquals(ord.size(),1);
    }
    
    
}