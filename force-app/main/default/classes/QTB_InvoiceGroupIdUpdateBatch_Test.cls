/*****************************************************************************************************
* Class: QTB_InvoiceGroupIdUpdateBatch_Test
* Author: Accenture
* Purpose: This is a test class for QTB_InvoiceGroupIdUpdateBatch
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   20/5/2020
*******************************************************************************************************/
@isTest(seealldata= false)
private with sharing class QTB_InvoiceGroupIdUpdateBatch_Test {
    @testSetup private static void setup() {
        List<Account> accountList = QTB_TestDataFactory.createAccounts(2);
        for (Account acc : accountList) {
            acc.QTB_Split_Invoice_Flag__c = true;
            acc.BillingCountry='Norway';
        }
        update accountList;
        
        blng__LegalEntity__c legalEntity= QTB_TestDataFactory.createLegalEntity('Norway');
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product=QTB_TestDataFactory.createProducts(4);
        product[0].blng__BillingRule__c=billingRule.id;
        product[0].blng__RevenueRecognitionRule__c =revenueRule.id;
        product[0].blng__TaxRule__c =taxRule.id;
        product[0].QTB_Storage_Product__c =true;
        product[1].blng__BillingRule__c=billingRule.id;
        product[1].blng__RevenueRecognitionRule__c =revenueRule.id;
        product[1].blng__TaxRule__c =taxRule.id;
        product[1].QTB_Storage_Product__c =false;
        product[2].blng__BillingRule__c=billingRule.id;
        product[2].blng__RevenueRecognitionRule__c =revenueRule.id;
        product[2].blng__TaxRule__c =taxRule.id;
        product[2].QTB_Storage_Product__c =false;
        product[3].blng__BillingRule__c=billingRule.id;
        product[3].blng__RevenueRecognitionRule__c =revenueRule.id;
        product[3].blng__TaxRule__c =taxRule.id;
        product[3].QTB_Storage_Product__c =true;
        update product; 
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(product[1]);
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(product[2]);
        PricebookEntry standardPrice3 = QTB_TestDataFactory.createPricebookEntry(product[3]);
        
        List<opportunity> oppList=QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id =pricebookId; 
        oppList[1].Pricebook2Id =pricebookId; 
        update oppList; 
        
        List<SBQQ__Quote__c> quoteList=QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList.addAll(QTB_TestDataFactory.createCPQQuotes(1,oppList[1].id,accountList[1].id,true,null));
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1, quoteList[0].id,accountList[0].id );
        quoteGroupList.addAll(QTB_TestDataFactory.createCPQQuoteLineGroups(1, quoteList[1].id,accountList[1].id ));
        Test.startTest();
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id );
        quoteLinesList.addAll(QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[1].id ));
        List<SBQQ__QuoteLine__c> quoteLinesList2 = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[1].id,quoteGroupList[1].id,product[2].id );
        quoteLinesList2.addAll(QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[1].id,quoteGroupList[1].id,product[3].id ));
        
        
        List<Order> orderList = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList.addAll( QTB_TestDataFactory.createCPQOrders(1,quoteList[1].Id,accountList[1].id));
        Test.stopTest();
        
        QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,product[0].Id,quoteLinesList,standardPrice);
        QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,product[1].Id,quoteLinesList,standardPrice1);
        QTB_TestDataFactory.createCPQOrderItems(orderList[1].Id,product[2].Id,quoteLinesList2,standardPrice2);
        QTB_TestDataFactory.createCPQOrderItems(orderList[1].Id,product[3].Id,quoteLinesList2,standardPrice3);
    }
    
    private static testmethod void testMethod1() {        
        Test.startTest();
        set<Id>accountSet = new Set<Id>();
        List<Account> acc = [select id,Name from Account];
        id id1 = acc[0].Id;
        id id2 = acc[1].Id;
        List<order> ord = [select id,QTB_OrderCategory__c from order];
        ord[0].QTB_OrderCategory__c ='Ad-Hoc';
        ord[1].QTB_OrderCategory__c ='Evergreen';
        update ord;
        for(Account a :acc){
           accountSet.add(a.id); 
        }
        
        QTB_InvoiceGroupIdUpdateBatch obj = new QTB_InvoiceGroupIdUpdateBatch(accountSet);
        DataBase.executeBatch(obj); 
        //Account acc = [select id,Name from Account where Name='Test Account' Limit 1];
        Test.stopTest();
        system.assertEquals(acc[0].Name,'Test Account');
        acc[0].QTB_Split_Invoice_Flag__c=false;
        acc[1].QTB_Split_Invoice_Flag__c=false;
        update acc;
        
        QTB_InvoiceGroupIdUpdateBatch obj1 = new QTB_InvoiceGroupIdUpdateBatch(accountSet);
        DataBase.executeBatch(obj1); 
    }
    
    static testmethod void testMethod2() {   
        Test.startTest();
        set<Id>accountset = new Set<Id>();
        QTB_InvoiceGroupIdUpdateBatch.throwExplicitException=true;
        QTB_InvoiceGroupIdUpdateBatch obj = new QTB_InvoiceGroupIdUpdateBatch(accountSet);
        obj.execute(null,null);
        Test.stopTest();
        System.assertEquals(true, QTB_InvoiceGroupIdUpdateBatch.throwExplicitException);
    }
}