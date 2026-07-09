/*****************************************************************************************************
* Class: QTB_BulkSubmitApprovalBatch_Test
* Author: Accenture
* Purpose: This is a test class for QTB_BulkSubmitApprovalBatch
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   28/01/2021
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_BulkSubmitApprovalBatch_Test {
   @testSetup
  static void setup(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        System.runAs(userList[0]) {
        Test.startTest();
        SBQQ.TriggerControl.disable();    
        List<Account> accList = QTB_TestDataFactory.createAccounts(1, 'Standard Account');
        accList[0].name = 'Account for Renewal Uplift';
        database.update(accList);
        
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product=QTB_TestDataFactory.createProducts(1);
        product[0].blng__BillingRule__c=billingRule.id;
        product[0].blng__RevenueRecognitionRule__c =revenueRule.id;
        product[0].blng__TaxRule__c =taxRule.id;
        database.update(product); 
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        IM_Country__c country = new IM_Country__c(Name = 'United States',Iso31662Code__c='US');
        database.insert(country);
        
       
        List<Opportunity> oppList = QTB_TestDataFactory.createOpps(accList);
        oppList[0].Pricebook2Id =pricebookId;
        oppList[0].billing_country__c = country.id;
        oppList[0].recordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
        oppList[0].Primary_Product_Line__c ='Records Management';
        
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c=pricebookId;
        quoteList[0].SBQQ__StartDate__c = date.parse('01/01/2020');
        quoteList[0].SBQQ__Status__c ='Draft';
        Test.stopTest();
         System.assertEquals('Records Management',oppList[0].Primary_Product_Line__c );

    }
    } 

 static testMethod void testmethod1(){
    List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
    System.runAs(userList[1]) { 
         List<SBQQ__Quote__c> quoteList =[Select id,SBQQ__Status__c  from SBQQ__Quote__c limit 1];
        Test.startTest();
        QTB_BulkSubmitApprovalBatch bulkbatch = new QTB_BulkSubmitApprovalBatch(new set<id>{quoteList[0].id});
        database.executeBatch(bulkbatch);
        Test.stopTest();
        System.assertEquals('Draft',quoteList[0].SBQQ__Status__c );
     }
    }
}