/*****************************************************************************************************
* @File Name:     QTB_S26_SendAccinfo_Test
* @Author:        Virtusa
* @Developer:     Suresh Uppala
* @Story Number : #471
* @Description :  Test Class for QTB_S26_SendAccinfo
* Version         Developer          Date               Description
*  1.0            Suresh U      	01/05/2021          Initial Creation 
*******************************************************************************************************/
@isTest
public class QTB_S26_SendAccinfo_Test {
    // Mock Callout class
    
    public class RestMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = '{"account":{[{"wmsId":"SKP","wmsAccountId":"suryaCA5","sfAccountId":"0010q00000ZgEEiAAN","region":"AMER","districtId":"ZZ","customerName":"Surya Customer Account"}],"users":[{"provider":"okta","isPrimary":false,"id":null,"email":"suryapvtcontact@mountain.com"}],"addresses":[{"addressType":"BILL","addressCode":"BILL"},{"addressType":"SHIP","addressCode":"SHIP"}],"bundle":{"purchaseOrderId":"8010q000000aY0NAAU","bundleTypeId":"01t0q000004yb4LAAQ","startDate":"2021-04-29 00:00:00","expiryDate":"2022-04-29 00:00:00","bundleOptions":[{"optionTypeId":"aHo0q00000003dVCAQ","optionSubTypeId":"aHo0q00000003dVCAQ","allowedCredits":100},{"optionTypeId":"aHo0q00000003dWCAQ","optionSubTypeId":"aHo0q00000003dWCAQ","allowedCredits":1}]}}}}';
            
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
    // creating account,customer account,product, order and calling the QTB_S26_SendAccinfo.Sierra26_SendAccData with positive scenario
    public testmethod static void SierraOrderInfo(){
        Test.setMock(HttpCalloutMock.class, new RestMock()); 
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(2, 'Standard Account');
        List<Contact>  testContact = QTB_TestDataFactory.createContacts(1);
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        List<product2> product=QTB_TestDataFactory.createProducts(1);
        product[0].ProductCode='MSC';
        //product[0].QTB_Account_Level_Charges__c=true;
        product[0].Family = 'Sierra26';   
        product[0].SBQQ__ConfigurationEvent__c = 'Always';
        product[0].SBQQ__ConfigurationType__c = 'Allowed';
        product[0].blng__BillingRule__c=billingRule.id;
        product[0].blng__RevenueRecognitionRule__c =revenueRule.id;
        product[0].blng__TaxRule__c =taxRule.id;
        update product;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        //create sales opp
        List<Opportunity> testOpportunity = QTB_TestDataFactory.createCPQOppsNew(testAccounts, 'CPQ Sales Opportunity');
        testOpportunity [0].Pricebook2Id =pricebookId; 
        testOpportunity [1].Pricebook2Id =pricebookId; 
        update testOpportunity ; 
        
        list<SBQQ__Quote__c> testQuote=QTB_TestDataFactory.createCPQQuotes(1,testOpportunity[0].id,testAccounts[0].id,true,null);
        testQuote[0].SBQQ__PriceBook__c=pricebookId; 
        update testQuote; 
         List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1, testQuote[0].id,testAccounts[0].id );
        system.debug('quoteGroupList>>>>'+quoteGroupList[0].Id);    
        List<SBQQ__QuoteLine__c>  testQuoteLines = new List<SBQQ__QuoteLine__c>();
        testQuoteLines = QTB_TestDataFactory.createCPQQuoteLines(1, testQuote[0].Id, quoteGroupList[0].id, product[0].id);
       system.debug('testQuoteLines>>>>'+testQuoteLines[0].Id);
        
        Order testOrder = new Order();
        testOrder.SBQQ__Quote__c =testQuote[0].Id;
        testOrder.AccountId =testAccounts[0].id;
        testOrder.blng__BillingDayOfMonth__c ='1';
         testOrder.EndDate = Date.today().addDays(30);
        testOrder.EffectiveDate =Date.today().addDays(5);
       
        testOrder.Status =QTB_Constants.DRAFT_STATUS;
        testOrder.Pricebook2Id =pricebookId;
        testOrder.blng__InvoiceBatch__c ='Denmark-26th';
        insert testOrder; 
        
       //  List<Order> testOrder =QTB_TestDataFactory.createCPQOrders(1,testQuote[0].id, testAccounts[0].id);
       
        system.debug('testOrder&&&&&&&&&&'+testOrder.Id);
        
      List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(testOrder.Id, product[0].Id, testQuoteLines, standardPrice);
        
        system.debug('orderItemList3>>>'+orderItemList3);
        system.debug('orderItemList3[0].Id>>>'+orderItemList3[0].Id);
       
        QTB_TestDataFactory.createCustomerAccount(1,testAccounts[0].id	);
         List<Contract> testContracts = QTB_TestDataFactory.createCPQContracts(1,testOrder.Id,testAccounts[0].id,testQuote[0].id);
        QTB_TestDataFactory.createCPQOppContactRoles(1,testOpportunity[0].Id,testContact[0].Id,'optyContactRole');
       List<SBQQ__ProductOption__c> CPQProductOptions = new List<SBQQ__ProductOption__c>();
         CPQProductOptions = QTB_TestDataFactory.createCPQProductOptions(2,testContracts[0].id,product[0].id);
        CPQProductOptions[0].QTB_S26_IncQuantity__c = 100;
        update CPQProductOptions;
          Exception_Log__c objExpL = new Exception_Log__c();
        objExpL.Error_Message__c ='The record inserted successfully';
        insert objExpL;
        Test.startTest();
        QTB_S26_SendAccinfo.Sierra26_SendAccData(testOrder.Id);
    
        Test.stopTest();
      
    }
    
    // creating account,customer account,product, order and calling the QTB_S26_SendAccinfo.Sierra26_SendAccData with negative scenario
    public testmethod static void SierraOrderInfo2(){
        Test.setMock(HttpCalloutMock.class, new RestMock()); 
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(2, 'Standard Account');
        List<Contact>  testContact = QTB_TestDataFactory.createContacts(1);
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        List<product2> product=QTB_TestDataFactory.createProducts(1);
        product[0].ProductCode='MSC';
        //product[0].QTB_Account_Level_Charges__c=true;
        product[0].Family = 'Sierra26';   
        product[0].SBQQ__ConfigurationEvent__c = 'Always';
        product[0].SBQQ__ConfigurationType__c = 'Allowed';
        product[0].blng__BillingRule__c=billingRule.id;
        product[0].blng__RevenueRecognitionRule__c =revenueRule.id;
        product[0].blng__TaxRule__c =taxRule.id;
        update product;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        //create sales opp
        List<Opportunity> testOpportunity = QTB_TestDataFactory.createCPQOppsNew(testAccounts, 'CPQ Sales Opportunity');
        testOpportunity [0].Pricebook2Id =pricebookId; 
        testOpportunity [1].Pricebook2Id =pricebookId; 
        update testOpportunity ; 
        
        list<SBQQ__Quote__c> testQuote=QTB_TestDataFactory.createCPQQuotes(1,testOpportunity[0].id,testAccounts[0].id,true,null);
        testQuote[0].SBQQ__PriceBook__c=pricebookId; 
        update testQuote; 
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1, testQuote[0].id,testAccounts[0].id );
        system.debug('quoteGroupList>>>>'+quoteGroupList[0].Id);    
        List<SBQQ__QuoteLine__c>  testQuoteLines = new List<SBQQ__QuoteLine__c>();
        testQuoteLines = QTB_TestDataFactory.createCPQQuoteLines(1, testQuote[0].Id, quoteGroupList[0].id, product[0].id);
        system.debug('testQuoteLines>>>>'+testQuoteLines[0].Id);
        
        Order testOrder = new Order();
        testOrder.SBQQ__Quote__c =testQuote[0].Id;
        testOrder.AccountId =testAccounts[0].id;
        testOrder.blng__BillingDayOfMonth__c ='1';
        testOrder.EffectiveDate =Date.today().addDays(5);
        // testOrder.EndDate = Date.today().addDays(30);
        testOrder.Status =QTB_Constants.DRAFT_STATUS;
        testOrder.Pricebook2Id =pricebookId;
        testOrder.blng__InvoiceBatch__c ='Denmark-26th';
        insert testOrder; 
        system.debug('testOrder&&&&&&&&&&'+testOrder.Id);
        
        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(testOrder.Id, product[0].Id, testQuoteLines, standardPrice);
        
        system.debug('orderItemList3>>>'+orderItemList3);
        system.debug('orderItemList3[0].Id>>>'+orderItemList3[0].Id);
        
        QTB_TestDataFactory.createCustomerAccount(1,testAccounts[0].id	);
        List<Contract> testContracts = QTB_TestDataFactory.createCPQContracts(1,testOrder.Id,testAccounts[0].id,testQuote[0].id);
        QTB_TestDataFactory.createCPQOppContactRoles(1,testOpportunity[0].Id,testContact[0].Id,'optyContactRole');
        List<SBQQ__ProductOption__c> CPQProductOptions = new List<SBQQ__ProductOption__c>();
        CPQProductOptions = QTB_TestDataFactory.createCPQProductOptions(2,testContracts[0].id,product[0].id);
        CPQProductOptions[0].QTB_S26_IncQuantity__c = 100;
        update CPQProductOptions;
        Exception_Log__c objExpL = new Exception_Log__c();
        objExpL.Error_Message__c ='The record inserted successfully';
        insert objExpL;
        Test.startTest();
        QTB_S26_SendAccinfo.Sierra26_SendAccData(testOrder.Id);
        
        Test.stopTest();
        
    }
     public testmethod static void SierraOrderInfo3(){
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(2, 'Standard Account');
        List<Contact>  testContact = QTB_TestDataFactory.createContacts(1);
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        List<product2> product=QTB_TestDataFactory.createProducts(1);
        product[0].ProductCode='MSC';
        //product[0].QTB_Account_Level_Charges__c=true;
        product[0].Family = 'Sierra26';   
        product[0].SBQQ__ConfigurationEvent__c = 'Always';
        product[0].SBQQ__ConfigurationType__c = 'Allowed';
        product[0].blng__BillingRule__c=billingRule.id;
        product[0].blng__RevenueRecognitionRule__c =revenueRule.id;
        product[0].blng__TaxRule__c =taxRule.id;
        update product;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        //create sales opp
        List<Opportunity> testOpportunity = QTB_TestDataFactory.createCPQOppsNew(testAccounts, 'CPQ Sales Opportunity');
        testOpportunity [0].Pricebook2Id =pricebookId; 
        testOpportunity [1].Pricebook2Id =pricebookId; 
        update testOpportunity ; 
        
        list<SBQQ__Quote__c> testQuote=QTB_TestDataFactory.createCPQQuotes(1,testOpportunity[0].id,testAccounts[0].id,true,null);
        testQuote[0].SBQQ__PriceBook__c=pricebookId; 
        update testQuote; 
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1, testQuote[0].id,testAccounts[0].id );
        system.debug('quoteGroupList>>>>'+quoteGroupList[0].Id);    
        List<SBQQ__QuoteLine__c>  testQuoteLines = new List<SBQQ__QuoteLine__c>();
        testQuoteLines = QTB_TestDataFactory.createCPQQuoteLines(1, testQuote[0].Id, quoteGroupList[0].id, product[0].id);
        system.debug('testQuoteLines>>>>'+testQuoteLines[0].Id);
        
       List<Order> listOrder = QTB_TestDataFactory.createCPQOrders(1,testQuote[0].id,testAccounts[0].id); 
        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(listOrder[0].Id, product[0].Id, testQuoteLines, standardPrice);
        
        system.debug('orderItemList3>>>'+orderItemList3);
       
        Test.startTest();
        QTB_OrderTriggerHandler qtborder = new QTB_OrderTriggerHandler();
        qtborder.AfterInsert(listOrder);
        Test.stopTest();
        
    }
        
}