/*****************************************************************************************************
* Class   : QTB_ReCalculationQuote_Test
* Author  : Virtusa
* Purpose : This is a test class for QTB_ReCalculationQuote
* Change History:
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Virtusa     05/30/2022     
*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_ReCalculationQuote_Test {
    
    @testSetup
    static void testSetupData() {
        
        List<product2> product = QTB_TestDataFactory.createProducts(1);
        List<account> accountList = QTB_TestDataFactory.createAccounts(1);
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        
        SBQQ__Quote__c quote =  new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = oppList[0].id,
            SBQQ__Account__c = accountList[0].id,            
            SBQQ__Status__c = 'Draft',
            SBQQ__Type__c = 'Amendment',
            SBQQ__QuoteLanguage__c = 'English',
            SBQQ__ExpirationDate__c = date.today(),
            SBQQ__Primary__c = true,
            SBQQ__PrimaryContact__c = null,
            SBQQ__StartDate__c = date.today(),
            QTB_Trigger_Quote_Calculation__c = false
        );
        
        quoteList.add(quote);
        if(! quoteList.isEmpty()){
            insert quoteList;
        }
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
            1,
            quoteList[0].id,
            accountList[0].id
        );
        
        List<SBQQ__QuoteLine__c> quoteLinesList =  new  List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c quoteLine =  new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quoteList[0].id,
            QTB_Offered_for_free__c = true,
            SBQQ__Group__c = quoteGroupList[0].id,
            SBQQ__Product__c = product[0].id,
            SBQQ__AdditionalDiscountAmount__c = 20);     
        quoteLinesList.add(quoteLine);
        
        if(! quoteLinesList.isEmpty()){
            insert quoteLinesList;
        }
    }
    
    @isTest
    static void testMethod1(){
        List<Id> quoteIds = new List<Id>();        
        List<SBQQ__Quote__c> quoteList = [Select Id, QTB_Trigger_Quote_Calculation__c From SBQQ__Quote__c];
        for(integer i = 0 ; i < quoteList.size(); i++ ){
            quoteIds.add(quoteList[0].id);
        }
        QTB_RecalculationQuote.doQuoteReCalculation(quoteIds);//postive scenario
        QTB_RecalculationQuote.doQuoteReCalculationFuture(quoteIds);//postive scenario
    }
   
    @isTest
    static void testMethod2(){
        QTB_RecalculationQuote.doQuoteReCalculationFuture(null); //negative scenrio
    }
}