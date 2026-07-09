@isTest(seealldata=false)
private class QTB_CreateRebillOrder_Test {

    static testMethod void testMethod1() {
	List<User> userList = QTB_TestDataFactory.usrMethdLst(1);	
    System.runAs(userList[0]) {
			Test.startTest();
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
        	accountList[0].QTB_Legal_Entity_Country__c = 'India';
        	update accountList;
       
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
            
 List<orderitem>orderproduct = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].id, quoteLinesList,standardPrice);
      orderproduct[0].SBQQ__OrderedQuantity__c=1;
        try{update orderproduct;}
        catch(Exception e){
            
        }
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(
        accountList
      );
       
     
        
        List<blng__InvoiceLine__c> invLineList = QTB_TestDataFactory.createInvoiceLine(1,invoiceList,product);
         invLineList[0].blng__OrderProduct__c = orderproduct[0].id;
      /*   invLinelist[0].blng__Subtotal__c = 50;
		 invLinelist[0].blng__TotalAmount__c = 50; */
         database.update(invLineList);
       
  
   /*     List<blng__InvoiceLine__c> invLineList =  new List<blng__InvoiceLine__c>();
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
          invoiceLine.Name = product[0].Name;
          invoiceLine.blng__Invoice__c = invoiceList[0].Id;
          invoiceLine.blng__Product__c = product[0].Id;
          invoiceLine.blng__InvoiceLineStatus__c = 'Draft';
          invoiceLine.blng__Quantity__c = 10;
          invoiceLine.blng__UnitPrice__c = 5;
          invoiceLine.blng__TaxPercentageApplied__c = 24;
          invoiceLine.blng__TaxCountry__c = 'Canada';
        /*  invoiceLine.blng__OrderProduct__c = orderproduct[0].id;
          invoiceLine.blng__Subtotal__c = 50;
		  invoiceLine.blng__TotalAmount__c = 50; * /
         invLineList.add(invoiceLine);
       insert invLineList;*/
        
       blng__Invoice__c inv=[select id from blng__Invoice__c limit 1];
       try{ 
            QTB_CreateRebillOrder.createRebillOrder(inv.id);
       }
        catch(Exception e){
          
        }
     Test.stopTest();
     }
    }    
}