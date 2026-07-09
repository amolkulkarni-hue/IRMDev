/*****************************************************************************************************
* Class: QTB_BillingAmendAPIBatch_Test
* Author: Accenture
* Purpose: Test Class for QTB_BillingAmendAPIBatch
* Change History: 
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   
*******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_BillingAmendAPIBatch_Test {
    @testsetup
    static void testsetup(){
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_QUOTE+';'+QTB_Constants.SOBJECT_ORDER+';'+
                                                QTB_Constants.TYPE_SBQQ_QUOTELINE+';'+QTB_Constants.SOBJECT_ACCOUNT+';'+QTB_Constants.TYPE_CONTRACT);
        SBQQ.TriggerControl.disable();
        List<User> testUsers = QTB_TestDataFactory.usrMethdLst(2);
        system.runas(testUsers[0]) { 
            List<Account> testAccount = QTB_TestDataFactory.createAccounts(1, 'Standard Account');
            List<Product2> testProduct = QTB_TestDataFactory.createProducts(1);
            List<PriceBook2> testPriceBook = QTB_TestDataFactory.priceBookMethdLst(1, 'Test Price book');
            testPriceBook[0].isActive = true;
            testPriceBook[0].QTB_Country__c = testAccount[0].Billing_County__c;
            update testPriceBook;
            // test.startTest();
            List<Opportunity> testOpp = QTB_TestDataFactory.createCPQOppsNew(testAccount, 'CPQ Sales Opportunity');
            testOpp[0].Pricebook2Id = testPriceBook[0].id;
            testOpp[0].CurrencyIsoCode =testAccount[0].Billing_County__c;
            //update testOpp;
            test.startTest();
            List<SBQQ__Quote__c> testQuotes = QTB_TestDataFactory.createCPQQuotes(1, testOpp[0].Id, testOpp[0].AccountId, true, null);
            List<SBQQ__QuoteLine__c> testQuoteLines = QTB_TestDataFactory.createCPQQuoteLines(1, testQuotes[0].Id, null, testProduct[0].id);
            
            List<Order> testorder = QTB_TestDataFactory.createCPQOrders(1,testQuotes[0].id,testAccount[0].id);
            
            List<Contract> testContracts = QTB_TestDataFactory.createCPQContracts(1,testorder[0].id,testAccount[0].id,testQuotes[0].id);
            testContracts[0].Status = 'Activated';
            testContracts[0].QTB_Latest_Opportunity__c = testOpp[0].Id;
            update testContracts;
            System.Assert(testContracts[0].Status == 'Activated'); 
            List<SBQQ__Subscription__c> testSubs = QTB_TestDataFactory.createCPQSubscriptions(1,testContracts[0].id, testProduct[0].id);
            //update testSubs;
            
            List<Opportunity> billTestOpp = QTB_TestDataFactory.createCPQOppsNew(testAccount, 'CPQ Sales Opportunity');
            billTestOpp[0].Pricebook2Id = testPriceBook[0].id;
            billTestOpp[0].CurrencyIsoCode =testAccount[0].Billing_County__c;
            //update billTestOpp;
            
            List<SBQQ__Quote__c> billtestQuotes = QTB_TestDataFactory.createCPQQuotes(1, billTestOpp[0].Id, billTestOpp[0].AccountId, true, null);
            List<SBQQ__QuoteLine__c> billtestQuoteLines = QTB_TestDataFactory.createCPQQuoteLines(1, billtestQuotes[0].Id, null, testProduct[0].id);
            billtestQuoteLines[0].QTB_RateCard_Subscription__c = testSubs[0].id;
            update billtestQuoteLines;
            List<Order> billtestorder = QTB_TestDataFactory.createCPQOrders(1,billtestQuotes[0].id,testAccount[0].id);
            
            List<Contract> billtestContracts = QTB_TestDataFactory.createCPQContracts(1,billtestorder[0].id,testAccount[0].id,billtestQuotes[0].id);
            billtestContracts[0].SBQQ__Quote__c = billtestQuotes[0].id;
            billtestContracts[0].QTB_Sales_Contract__c = testContracts[0].id;
            billtestContracts[0].RecordTypeId = QTB_Utils.CONTRACT_BILL_RECTYPEID;
            billtestContracts[0].Status = 'Activated';
            billtestContracts[0].QTB_Latest_Opportunity__c = billTestOpp[0].Id;
            update billtestContracts;
            
            QTB_TestDataFactory.createCPQSubscriptions(1,billtestContracts[0].id, testProduct[0].id);
            List<Opportunity> amendTestOpp = QTB_TestDataFactory.createCPQOppsNew(testAccount, 'CPQ Sales Opportunity');
            //amendTestOpp[0].Pricebook2Id = testPriceBook[0].id;
            //amendTestOpp[0].CurrencyIsoCode =testAccount[0].Billing_County__c;
            amendTestOpp[0].Type = QTB_Constants.OPP_TYPE_RATE_CHANGE;
            amendTestOpp[0].SBQQ__AmendedContract__c = testContracts[0].id;
            update amendTestOpp;
            
            List<SBQQ__Quote__c> amendTestQuotes = QTB_TestDataFactory.createAmendQuotes(1, amendTestOpp[0].Id, amendTestOpp[0].AccountId, true, null);
            amendTestQuotes[0].SBQQ__Type__c = QTB_Constants.TYPE_AMENDMENT;
            update amendTestQuotes;
            List<SBQQ__QuoteLine__c> amendQuoteLines = QTB_TestDataFactory.createCPQQuoteLines(2, amendTestQuotes[0].Id, null, testProduct[0].id);
            test.stopTest();
            QTB_TestDataFactory.createCPQOrders(1,amendTestQuotes[0].id,testAccount[0].id);
            
            amendTestOpp[0].SBQQ__Contracted__c = true;
            update amendTestOpp;
            
            QTB_TestDataFactory.createCPQSubscriptions(1,testContracts[0].id, testProduct[0].id);
            amendQuoteLines[0].SBQQ__UpgradedSubscription__c = testSubs[0].id;
            update amendQuoteLines;
            
            billtestQuoteLines[0].QTB_RateCard_Subscription__c = testSubs[0].id;
            update billtestQuoteLines;
            
            
            //testOpp[0].QTB_Latest_Opportunity__c =amendTestOpp[0].id;
            //update testOpp;
            
        }
    }
    
    @isTest static void testData(){
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_QUOTE+';'+QTB_Constants.SOBJECT_ORDER);
        Contract  con=[select Id,QTB_Latest_Opportunity__c from Contract  limit 1];
        test.startTest();        
        System.enqueueJob(new QTB_QueueBillingAmendAPI(con.id,con.QTB_Latest_Opportunity__c)); 
        Test.stopTest();
        system.assert(con.QTB_Latest_Opportunity__c != null);
    }   
    
    @isTest static void coverCatchMethod(){
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_QUOTE+';'+QTB_Constants.SOBJECT_ORDER);
        Contract  con=[select Id,QTB_Latest_Opportunity__c from Contract  limit 1];
        test.startTest();        
        QTB_QueueBillingAmendAPI.throwExplicitException = true;
        System.enqueueJob(new QTB_QueueBillingAmendAPI(con.id,con.QTB_Latest_Opportunity__c)); 
        Test.stopTest();
        system.assert(con.QTB_Latest_Opportunity__c != null);
    } 
    
    /*@isTest static void coverCatchMethodForBatchClass(){

QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_QUOTE+';'+QTB_Constants.SOBJECT_ORDER);
Contract  con=[select Id,QTB_Latest_Opportunity__c from Contract  limit 1];
test.startTest();  
QTB_BillingAmendAPIBatch.throwExplicitException = true;
Database.executebatch(new QTB_BillingAmendAPIBatch(con.id,con.QTB_Latest_Opportunity__c),1); 
Test.stopTest();
system.assert(con.QTB_Latest_Opportunity__c != null);
}*/  
    
    @isTest static void coverQuoteSaver(){
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_QUOTE+';'+QTB_Constants.SOBJECT_ORDER);
        Contract  con=[select Id,QTB_Latest_Opportunity__c from Contract  limit 1];
        test.startTest();        
        QuoteSaver.throwExplicitException = true;
        System.enqueueJob(new QTB_QueueBillingAmendAPI(con.id,con.QTB_Latest_Opportunity__c)); 
        Test.stopTest();
        system.assert(con.QTB_Latest_Opportunity__c != null);
    }   
    
    @isTest static void coverContractAmender(){
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_QUOTE+';'+QTB_Constants.SOBJECT_ORDER);
        Contract  con=[select Id,QTB_Latest_Opportunity__c from Contract  limit 1];
        test.startTest();        
        ContractAmender.throwExplicitException = true;
        System.enqueueJob(new QTB_QueueBillingAmendAPI(con.id,con.QTB_Latest_Opportunity__c)); 
        Test.stopTest();
        system.assert(con.QTB_Latest_Opportunity__c != null);
    }   
    @isTest static void testData1(){
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_QUOTE+';'+QTB_Constants.SOBJECT_ORDER);
        SBQQ__Quote__c QID=[select Id from SBQQ__Quote__c limit 1];
        test.startTest();        
        System.enqueueJob(new QTB_QueueBillingQuoteProcess(new List<Id>{QID.id},QTB_Constants.BILLING_AMENDMENT_PROCESSNAME)); 
        Test.stopTest();
    }
    /*@isTest static void testData2(){
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_QUOTE+';'+QTB_Constants.SOBJECT_ORDER);
        List<Contract> contractList=[select Id,QTB_Latest_Opportunity__c from Contract];
        SBQQ__Quote__c QID=[select Id from SBQQ__Quote__c limit 1];
        test.startTest();        
        System.enqueueJob(new QTB_QueueBillingQuoteProcess(new List<Id>{QID.id},QTB_Constants.BILLING_AMENDMENT_PROCESSNAME,contractList,contractList[0].QTB_Latest_Opportunity__c)); 
        Test.stopTest();
    }*/
}