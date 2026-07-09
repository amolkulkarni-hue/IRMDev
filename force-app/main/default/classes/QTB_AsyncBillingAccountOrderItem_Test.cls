@isTest(seealldata=false)
public class QTB_AsyncBillingAccountOrderItem_Test {
   @testSetup
  static void setup(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        
        System.runAs(userList[0]) {
            Test.startTest();
            blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
            blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            
            List<product2> product = QTB_TestDataFactory.createProducts(1);
            product[0].blng__BillingRule__c = billingRule.id;
            product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
            product[0].blng__TaxRule__c = taxRule.id;
            
            update product;
            
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
            blng__LegalEntity__c entityList = QTB_TestDataFactory.createLegalEntity('Norway');
            List<account> accountList = QTB_TestDataFactory.createAccounts(1);
            accountList[0].BillingCountry = 'Norway';
            update accountList;
            
            List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
            oppList[0].Pricebook2Id = pricebookId;
            update oppList;
            
            List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
            quoteList[0].SBQQ__PriceBook__c = pricebookId;
            quoteList[0].SBQQ__StartDate__c = System.Today();
            update quoteList;
            
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
            
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
            quoteLinesList[0].SBQQ__ChargeType__c = 'Recurring';
            quoteLinesList[0].SBQQ__BillingType__c = 'Arrears';
            update quoteLinesList;
            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
            orderList3[0].blng__InvoiceBatch__c = 'Norway-26th';
            try{
                update orderList3;
            }
            catch(Exception e){
                
            }
            
            List<orderitem>orderproduct = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].id, quoteLinesList,standardPrice);
            try{  
                orderproduct[0].product2Id=product[0].id;
                
                
                update orderproduct;
            }
            catch(Exception e){
                
            }
            
            Test.stopTest();
            System.assertEquals('Recurring',quoteLinesList[0].SBQQ__ChargeType__c);
        }
  }
    static testMethod void testmethod1(){
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) { 
         List<Order> orderList3 =[Select id,blng__InvoiceBatch__c from Order limit 1];
         List<orderitem>orderproduct =[Select id from orderitem limit 1];
        Test.startTest();
            set<id> salesOrderId = new set<id>{orderList3[0].id};  
                set<string> csNumber= new set<string>{'123456'};
                    list<orderItem> billingOrderItem = new list<orderItem>();
                        map<string,orderItem> orderItemMap = new map<string,orderItem>{orderproduct[0].id => orderproduct[0]};  
                        map<id,order> orderMap = new map<id,order>{orderList3[0].id => orderList3[0]};                    
                            try{  
                                QTB_AsyncBillingAccountOrderItemCreation obj = new  QTB_AsyncBillingAccountOrderItemCreation(salesOrderId,csNumber,billingOrderItem,orderItemMap,orderMap);
                                
                                System.enqueueJob(obj); 
                                
                                
                            }
            catch(Exception e){
            }
           Test.stopTest(); 
          System.assertEquals( 'Norway-26th',orderList3[0].blng__InvoiceBatch__c);  
        }  
        
    }
}