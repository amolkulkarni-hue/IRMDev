/*****************************************************************************************************
* Class: QTB_QuoteStatusUpdateBatch_Test
* Author: Accenture
* Purpose: This is a test class for QTB_QuoteStatusUpdateBatch
* Change History: 6/1/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture    4/30
*******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_QuoteStatusUpdateBatch_Test {
    @testSetup static void setup() {
        Test.startTest();
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(1, 'Standard Account');
        List<Opportunity> testOpportunity = QTB_TestDataFactory.createCPQOppsNew(testAccounts, 'CPQ Sales Opportunity');
        List<SBQQ__Quote__c> testQuotes = QTB_TestDataFactory.createCPQQuotes(1, testOpportunity[0].id, testAccounts[0].id, true, null);
        testQuotes[0].SBQQ__Status__c = QTB_Constants.APPROVED_STATUS;
        testQuotes[0].QTB_Pricing_Expiration_Date__c = Date.today();
        database.update(testQuotes,false);
        Test.stopTest();
    }
    
    static testmethod void testStatus() {   
        QTB_QuoteStatusUpdateBatch obj = new QTB_QuoteStatusUpdateBatch();
        Test.startTest();
        DataBase.executeBatch(obj); 
        Test.stopTest();
        Account acc = [select id from Account where Name='Test Account' Limit 1];
        Opportunity opp = [select id, RecordTypeId From Opportunity where RecordType.Name= 'CPQ Sales Opportunity'];
        SBQQ__Quote__c quote = [SELECT Id,SBQQ__Status__c from SBQQ__Quote__c where SBQQ__Opportunity2__c =:opp.id ];
        System.assertEquals('Expired',quote .SBQQ__Status__c);
    }
    
        //cover catch
    static testmethod void testMethod1() {   
        Test.startTest();
        QTB_QuoteStatusUpdateBatch.throwExplicitException=true;
        QTB_QuoteStatusUpdateBatch obj = new QTB_QuoteStatusUpdateBatch();
       	DataBase.executeBatch(obj); 
        Test.stopTest();
        System.assertEquals(true, QTB_QuoteStatusUpdateBatch.throwExplicitException);
    }
}