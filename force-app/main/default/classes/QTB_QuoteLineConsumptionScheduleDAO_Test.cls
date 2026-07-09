@isTest
public class QTB_QuoteLineConsumptionScheduleDAO_Test {
    
    @isTest
    static void testMethod1 (){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
    Test.startTest();
    System.runAs(userList[0]) {
      List<account> accountList = QTB_TestDataFactory.createAccounts(1);
      accountList[0].BillingCountry = 'India';
      accountList[0].QTB_Legal_Entity_Country__c = 'India';
      update accountList;
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
      database.update(product);

      Id pricebookId = Test.getStandardPricebookId();
      PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
        product[0]
      );

      // Update the pricebook of opportunity
      List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
      oppList[0].Pricebook2Id = pricebookId;
      database.update(oppList);

      List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
        1,
        oppList[0].id,
        accountList[0].id,
        true,
        null
      );
      quoteList[0].SBQQ__PriceBook__c = pricebookId;
      quoteList[0].SBQQ__StartDate__c = System.Today();
      database.update(quoteList);

      

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
        try{
             QTB_QuoteLineConsumptionScheduleDAO.getQuoteLinesWithConsumptionSchedules('tset');
        }catch(exception e){
            
        }
         try{
             QTB_QuoteLineConsumptionScheduleDAO.getConsumptionScheduleByQuoteLine('tset');
        }catch(exception e){
            
        }
         try{
             QTB_QuoteLineConsumptionScheduleDAO.setSelectedConsumptionSchedule('quoteLinesList');
        }catch(exception e){
            
        }
    }
   
    }

}