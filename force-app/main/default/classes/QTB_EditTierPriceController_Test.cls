/*****************************************************************************************************
* Class: QTB_EditTierPriceController_Test
* Author: Accenture
* Purpose: Test Class for QTB_EditTierPriceControllerExtension
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   
* Accenture		1/7/2021		disbaled SBQQ triggers to limit calculations in the context
*******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_EditTierPriceController_Test {
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
        
        SBQQ.TriggerControl.disable();
        List<SBQQ__Quote__c> quoteList=QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__StartDate__c = System.Today();
        database.update(quoteList);
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1, quoteList[0].id,accountList[0].id );
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id );
        quotelinesList[0].QTB_First_Tier_Price__c =6.597;
        quotelinesList[0].QTB_Second_Tier_Price__c =9.649;
        quotelinesList[0].QTB_First_Tier_Breakpoint__c = 4;
        update quotelinesList;        
        Test.stopTest();
    }
    testMethod static void test1(){
        SBQQ__Quote__c testQuote = [Select id,SBQQ__Type__c from SBQQ__Quote__c limit 1];
        SBQQ__Quoteline__c testquoteline = [select id from SBQQ__quoteline__c limit 1];
        PageReference  pageRef = page.QTB_EditTierPrice;
        pageRef.getParameters().put('qid',string.valueof(testQuote.id));
        pageRef.getParameters().put('id',string.valueof(testquoteline.id));
        Test.startTest();
        Test.setCurrentPage(pageRef);
        QTB_EditTierPriceControllerExtension con = new QTB_EditTierPriceControllerExtension();
        SBQQ.TriggerControl.disable();
        con.cancel();
        con.save();
        Test.stopTest();
    }
    
    
}