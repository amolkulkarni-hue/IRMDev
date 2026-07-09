/*****************************************************************************************************
* Class: QTB_UsageBatch_Test
* Author: Accenture
* Purpose: Test Class for QTB_UsageBatch
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   17/6/2020
*******************************************************************************************************/
@isTest(seealldata= false)
private class QTB_UsageBatch_Test {
    private static Final String ERROR1 = QTB_Constants.USAGE_STATUS_WARNING_UNRATED;
    private static Final String ERROR2 =QTB_Constants.USAGE_STATUS_ERROR;
	@testsetup private static void setup() {
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1); 
        system.runas(userList[0]) { 
            List<Account> testAccount = QTB_TestDataFactory.createAccounts(1, 'Standard Account');
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
            sbqq.triggerControl.disable();
            List<opportunity> testOpp=QTB_TestDataFactory.createOpps(testAccount);
            testOpp[0].Pricebook2Id =pricebookId; 
            update testOpp; 
            
            List<SBQQ__Quote__c> testquote= QTB_TestDataFactory.createCPQQuotes(1,testOpp[0].id,testAccount[0].id,true,null);
            testquote[0].SBQQ__PriceBook__c=pricebookId;
            testquote[0].SBQQ__StartDate__c = System.Today();
            update testquote;
            
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,testquote[0].id, testAccount[0].id );
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,testquote[0].id,quoteGroupList[0].id,product[0].id );
            List<Order> orderList = QTB_TestDataFactory.createCPQOrders(1, testquote[0].Id,testAccount[0].id);
            List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,product[0].Id,quoteLinesList,standardPrice);
            
            //creating usage summary
            List<blng__UsageSummary__c> usageSum=QTB_TestDataFactory.createUsageSummary(1,testAccount[0],orderList[0],orderItemList[0]);
            blng__UsageSummary__c usagesummary=usageSum[0]; 
            usagesummary.blng__Status__c='Queued For Invoice';
            usagesummary.blng__InvoiceRunProcessingStatus__c='In Progress';
            usagesummary.blng__Subtotal__c=100;
            usagesummary.blng__TotalQuantity__c=10;
            usagesummary.blng__PreratedQuantity__c=20;
            usagesummary.blng__UnbilledQuantity__c=1;
            usagesummary.blng__UnitPrice__c=400;
            usagesummary.blng__PreratedAmount__c=22;
            update usagesummary;
            System.Assert(usageSum[0].blng__Status__c == 'Queued For Invoice');
            List<blng__Usage__c> usageList=QTB_TestDataFactory.createUsages(1,testAccount[0],usagesummary);
        }
        Test.stopTest();
    }
    
    private static testmethod void test() {        
        Test.startTest();
        List<blng__Usage__c> usg = [select id from blng__Usage__c Limit 1];
        System.assert(usg.size() ==1);
        QTB_UsageBatch obj = new QTB_UsageBatch();
        DataBase.executeBatch(obj);
        obj.execute(null,usg);
        Test.stopTest();
    }
    
    //cover catch
    static testmethod void testMethod1() {   
        Test.startTest();
        QTB_UsageBatch.throwExplicitException=true;
        QTB_UsageBatch obj = new QTB_UsageBatch();
       	obj.execute(null,null); 
        Test.stopTest();
        System.assertEquals(true, QTB_UsageBatch.throwExplicitException);
    }
    
    static testmethod void testMethod2() {
        Test.startTest();
        QTB_UsageBatchScheduler obj = new QTB_UsageBatchScheduler();
        String sch = '0 0 13 * * ?';
        String jobId=System.schedule('Schedule Usage Batch', sch,obj);
        Test.stopTest();
        system.assertNotEquals(jobId, null);
    }
    
}