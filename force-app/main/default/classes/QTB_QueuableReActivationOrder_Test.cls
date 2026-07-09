@isTest(seealldata=false)
private class QTB_QueuableReActivationOrder_Test {
@testsetup
    static void testsetup() {
	List<User> userList = QTB_TestDataFactory.usrMethdLst(1);	
    System.runAs(userList[0]) {
			Test.startTest();
			QTB_Manage_Contract_Scheduler__c cust = new QTB_Manage_Contract_Scheduler__c();
        	cust.Name = 'FirstRecord';
        	cust.QTB_Scheduler_Hold_Time_In_Min__c = 5;
        	insert cust;
        	
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
        
            update product;
          
			Id pricebookId = Test.getStandardPricebookId();
			PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
				product[0]
			);
             
			List<account> accountList = QTB_TestDataFactory.createAccounts(1);
       
			List<opportunity> oppList = QTB_TestDataFactory.createOpps(
				accountList
			);
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
			quoteLinesList[0].SBQQ__ChargeType__c = 'Recurring';
			quoteLinesList[0].SBQQ__BillingType__c = 'Arrears';
			update quoteLinesList;
            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
				1,
				quoteList[0].Id,
				accountList[0].id
			);
         QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].id, quoteLinesList,standardPrice);
         List<Order>orders=[Select ID,name,status from Order Limit 1];  
        Set<Id> ids = new Set<Id>();
        for (Order acc : orders) 
{
    ids.add(acc.Id);
}
      System.enqueueJob(new QTB_QueuableReActivationOrder(ids));
     } 
    }
    
     @isTest 
    static void testMethod1(){ 
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) {
      Test.startTest();
         QTB_QueuableReActivationOrder.throwExplicitException =true;  
       QTB_QueuableReActivationOrder obj = new   QTB_QueuableReActivationOrder(null);
      Test.stopTest();
      try {
        obj.execute(null);
      } catch (Exception e) {
        System.assert('Script-thrown exception'!= e.getMessage());
      }
       
      }         
 
    }
}