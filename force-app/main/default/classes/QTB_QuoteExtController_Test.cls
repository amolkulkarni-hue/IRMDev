/*****************************************************************************************************
* Class: QTB_QuoteExtController_Test
* Author: Accenture
* Purpose: Test Class for QTB_QuoteExtController
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   
*******************************************************************************************************/
@isTest(seeAllData=false)
private with sharing class QTB_QuoteExtController_Test {
    
    @TestSetup static void setupMethod() {
        Test.startTest();
        List<account> accountList =QTB_TestDataFactory.createAccounts(1);
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product=QTB_TestDataFactory.createProducts(1);
        product[0].blng__BillingRule__c=billingRule.id;
        product[0].blng__RevenueRecognitionRule__c =revenueRule.id;
        product[0].blng__TaxRule__c =taxRule.id;
        database.update(product); 
        
        List<opportunity> oppList=QTB_TestDataFactory.createOpps(accountList);
        database.update(oppList); 
        
        List<SBQQ__Quote__c> quoteList=QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__StartDate__c = System.Today();
        database.update(quoteList);
        Test.stopTest();
       
    }
    testMethod static void testSubmit(){
        Test.startTest();
        SBQQ__Quote__c testQuote = [Select id,SBQQ__Type__c from SBQQ__Quote__c limit 1];
        QTB_QuoteExtController con = new QTB_QuoteExtController(new ApexPages.StandardController(testQuote));
        con.onSubmit();
        con.onRecall();
        Test.stopTest();
        system.assertEquals('Standard',testQuote.SBQQ__Type__c);
    }
    testMethod static void testException(){
        Test.startTest();
        QTB_QuoteExtController.throwExplicitException = true;
        SBQQ__Quote__c testQuote = [Select id,SBQQ__Type__c from SBQQ__Quote__c limit 1];
        QTB_QuoteExtController con = new QTB_QuoteExtController(new ApexPages.StandardController(testQuote));
        con.onSubmit();
        con.onRecall();
        Test.stopTest();
        system.assertEquals(true, QTB_QuoteExtController.throwExplicitException);
    }
}