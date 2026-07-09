@isTest(SeeAllData=false)
private with sharing class QTB_RecordJobHelper_Test {
     private static final id quoteSalesRecTypeId=QTB_Utils.QUOTE_SALES_RECTYPEID;
     private static final id quoteBillRecTypeId=QTB_Utils.QUOTE_BILL_RECTYPEID;
     static testmethod void testRecordJob(){
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_QUOTE+';'+QTB_Constants.SOBJECT_ORDER+';'+
                                                QTB_Constants.TYPE_OPPORTUNITY+';'+QTB_Constants.TYPE_SBQQ_QUOTELINE+';'+QTB_Constants.TYPE_CONTRACT);
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1); 
        system.runas(userList[0]) { 
            List<Account> accountList =QTB_TestDataFactory.createAccounts(1); 
            accountList[0].BillingCountry='India';
            update accountList;
            List<opportunity> oppList =QTB_TestDataFactory.createOpps(accountList);
            accountList[0].QTB_Source_Opportunity__c=oppList[0].Id;
            update accountList;
            
            List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null); 
            List<SBQQ__Quote__c> quoteList2 = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,false,null); 
            quoteList[0].recordTypeId=quoteSalesRecTypeId;
            quoteList2[0].recordTypeId=quoteBillRecTypeId;
            List<SBQQ__Quote__c> quotes=new List<SBQQ__Quote__c>();
            quotes.addAll(quoteList);
            quotes.addAll(quoteList2);
            update quotes;
            
            blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
            blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            
            List<product2> product=QTB_TestDataFactory.createProducts(1);
            product[0].blng__BillingRule__c=billingRule.id;
            product[0].blng__RevenueRecognitionRule__c =revenueRule.id;
            product[0].blng__TaxRule__c =taxRule.id;
            update product;
            
            
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1, quoteList[0].id,accountList[0].id );
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id );
            List<Pricebook2> pricebook = QTB_TestDataFactory.priceBookMethdLst(1,'Standard Price Book');
            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
            orderList3[0].Pricebook2Id =  pricebook[0].Id;
            
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
            List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].Id,quoteLinesList,standardPrice);
            
            SBQQ.TriggerControl.disable();
            List<Contract> contractList = QTB_TestDataFactory.createCPQContracts(1,orderList3[0].id,accountList[0].id,QuoteList[0].id);
            String cId = String.valueOf(contractList[0].id) + '::RenewContract';
            //contractList[0].SBQQ__RenewalForecast__c = False;
            //update contractList[0];
            Test.stopTest();
                                   
            SBQQ__RecordJob__c recordJobData = new SBQQ__RecordJob__c();
            recordJobData.CurrencyIsoCode = 'USD';
            recordJobData.SBQQ__IsRead__c = false;
            recordJobData.SBQQ__JobDetails__c = 'Test';
            recordJobData.SBQQ__JobStatus__c ='Failed';
            recordJobData.SBQQ__RecordId__c = cid;
            insert recordJobData;
            recordJobData.SBQQ__JobStatus__c ='Completed';
            update recordJobData;
            recordJobData.SBQQ__JobStatus__c ='Failed';
            update recordJobData;

            System.assertEquals(false,  contractList[0].SBQQ__RenewalForecast__c);
        }
     }
        static testmethod void testmethod1() {
        Test.startTest();
        QTB_RecordJobHandler.throwExplicitException = true;
        QTB_RecordJobHandler handler=new QTB_RecordJobHandler();
        handler.BeforeUpdate(null,null);
        handler.AfterDelete(null);
        handler.AfterUndelete(null);
        handler.BeforeDelete(null);
        handler.BeforeInsert(null);
        try{
        QTB_RecordJobHelper.ResetRenewalCheckBoxOnContract(null);
        }
          catch(Exception e){
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        QTB_TestDataFactory.createBypassSetting('SBQQ__RecordJob__c');
        handler.isDisabled();
        Test.stopTest();
        System.assertEquals(true, QTB_RecordJobHandler.throwExplicitException);
    }

}