/*****************************************************************************************************
 * Class: QTB_UtilsTest
 * Author: IRM/Virtusa
 * Change History: 09/12/2022
 * Purpose: This is a test class for QTB_Utils
 *******************************************************************************************************/
@isTest
Private class QTB_UtilsTest{
    
    static testMethod void UtilsTestmethod1() {
        QTB_Utils.getEmailIdList();
        QTB_Utils.sendErrorLogMail(null, null);        
    }
    
    static testMethod void UtilsTestmethod2() {
        Test.startTest();
        QTB_Utils.getEmailIdList();
        QTB_QueueRenewalBilling.throwExplicitException = true;
        QTB_Utils.getEmailIdList();
        Test.stopTest();
    }
    
    static testMethod void UtilsTestmethod3() {
        QTB_Utils.sendErrorLogMail(null, null);
        QTB_QueueRenewalBilling.throwExplicitException = true;
        QTB_Utils.sendErrorLogMail(null, null);
        Set<String> test = new Set<String>();
        test.add('test1');
        test.add('test2');
        QTB_Utils.sendErrorLogMail(test, 'test');       
    }
    
    static testMethod void UtilsTestmethod4() {
        Test.startTest();
        QTB_Utils.checkDigitforNorwayDenmark('108006871622001370');
        Test.stopTest();
    }
    
    static testMethod void UtilsTestmethod5() {
        Test.startTest();
        QTB_Utils.checkDigitforFinland('23233232322');
        Test.stopTest();
    }
    
    static testMethod void UtilsTestmethod6() {
        Test.startTest();
        blng__InvoiceScheduler__c invSch = new blng__InvoiceScheduler__c();
        invSch.blng__InvoiceBatches__c = 'United States-DM-1st-EOM Manual';
        invSch.Name='Test sched';
        invSch.blng__Type__c='Once';
        invSch.blng__TargetDate__c = System.today()+1;
        QTB_Utils.preBillBatches();
        Test.stopTest();
    }
    
    static testMethod void UtilsTestmethod7() {
        try {
          Test.startTest();
          QTB_Utils.responseGenerator(null, null, null);
          Test.stopTest();
        } catch (NullPointerException e) {
          System.assertEquals('System.NullPointerException', e.getTypeName());
        }
    }
    
    static testMethod void UtilsTestmethod8() {
        Test.startTest();
        List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
            2,
            'Standard Account'
        );
        //QTB_Sfdc_to_OS_Event__c sfdcOSObj = new QTB_Sfdc_to_OS_Event__c();      
        //sfdcOSObj.QTB_Account_ID__c = testAccounts[0].id;
        //insert sfdcOSObj;        
        
        Set<ID> idtest = new Set<ID>();
        idtest.add(testAccounts[0].id);
        //QTB_Utils.GetFieldMapMetadata('Account', 'QTB_Sfdc_to_OS_Event__c', 'SalesforceToOS');
        list<QTB_Utils.Mapping> mapList = new list<QTB_Utils.Mapping>();
        //QTB_Utils.Mapping test1 = new QTB_Utils.Mapping(testAccounts[0].id, sfdcOSObj);
        //QTB_Utils.Mapping test2 = new QTB_Utils.Mapping(testAccounts[0], sfdcOSObj);
        //QTB_Utils.Mapping test3 = new QTB_Utils.Mapping(testAccounts[0].id, sfdcOSObj.id);
        //mapList.add(test1);
        //mapList.add(test2);
       // mapList.add(test3);
        //QTB_Utils.fieldUpdate(idtest, mapList, 'Account', 'QTB_Sfdc_to_OS_Event__c', 'SalesforceToOS');
        Test.stopTest();        
    } 
    
    static testMethod void UtilsTestmethod9(){
        //Legal Entity
        blng__LegalEntity__c USEntity = new blng__LegalEntity__c();
        USEntity.Name = 'Test Legal Entity United States';
        USEntity.blng__Active__c = true;
        USEntity.blng__Country__c = 'United States';
        USEntity.QTB_Type__c = 'Contract';
        insert USEntity;
        
        //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(
            1,
            'Billing Account'
        );
        accountList[0].QTB_Contract_Entity__c = USEntity.id;
        accountList[0].QTB_Legal_Entity_Country__c='United States';
        accountList[0].QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
        accountList[0].ShippingCountry = 'United States';
        accountList[0].SBQQ__TaxExempt__c='Yes';
        update accountList;
        
        //Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        
        //Product1 -- usage
        List<product2> productList = new List<product2>();
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p1); 
        insert productList;
        
        //Price Book creation for all product
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(productList[0]);  
        
        //Consumption schedule
        ConsumptionSchedule consumption = new ConsumptionSchedule();
        consumption.Name = 'dummy';
        consumption.RatingMethod = 'Tier';
        consumption.Type = 'Range';
        consumption.SBQQ__Category__c = 'Rates';
        consumption.BillingTerm = 10;
        consumption.BillingTermUnit = 'Month';
        insert consumption;
        
        //Consumption Rate
        ConsumptionRate conrate = new ConsumptionRate();
        conrate.ProcessingOrder = 1;
        conrate.PricingMethod = 'PerUnit';
        conrate.LowerBound = 1;
        conrate.Price = 100;
        conrate.ConsumptionScheduleId = consumption.Id;
        insert conrate;
        
        //Activating Consumption schedule after creation of consumption rate
        consumption.IsActive = true;
        update consumption;
        
        //ProductConsumptionSchedule
        insert new ProductConsumptionSchedule(
            ConsumptionScheduleId = consumption.Id,
            ProductId = productList[0].Id
        );
        
        //IM Country
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';        
        insert im;
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        oppList[0].Legal_Entity__c = USEntity.id;
        oppList[0].Billing_Country__c = im.id;
        oppList[0].Primary_Product_Line__c = 'Records Management';
        database.update(oppList);
        
        //Original Quote
        List<SBQQ__Quote__c> OriginalquoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        OriginalquoteList[0].SBQQ__PriceBook__c = pricebookId;
        OriginalquoteList[0].SBQQ__StartDate__c = System.Today();
        OriginalquoteList[0].QTB_IM_Legal_Entity__c = USEntity.id;
        OriginalquoteList[0].QTB_Opportunity_Billing_Country__c = 'United States';
        database.update(OriginalquoteList);
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].QTB_IM_Legal_Entity__c = USEntity.id;
        quoteList[0].QTB_Opportunity_Billing_Country__c = 'United States';
        database.update(quoteList);
        
        oppList[0].QTB_Original_Quote__c = OriginalquoteList[0].id;
        database.update(oppList);
        
        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[0].id);
       
        Test.startTest();
        //Order
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        database.update(orderList3);
        
        SBQQ.TriggerControl.disable();
        
        //OrderItem
        List<OrderItem> orderItemList2 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[0].Id,quoteLinesList,standardPrice1);
        orderItemList2[0].SBQQ__ChargeType__c = 'Usage';
        update orderItemList2[0];
        
        Set<id> legalEntityId= new Set<Id>();
        legalEntityId.add(USEntity.id);
        
        Map<Id, Account> accMap = new Map<Id, Account>();
        accMap.put(accountList[0].id,accountList[0]); 
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'US Tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;
        
        blng__TaxIntegration__c txInt = new blng__TaxIntegration__c();
        txInt.Name = 'Test';
        txInt.blng__Active__c = true;
        txInt.blng__TaxEngine__c = 'Standard';
        txInt.blng__Default__c = true;
        insert txInt;
        
        blng__TaxTreatment__c trt = new blng__TaxTreatment__c();
        trt.Name = 'US Tax Treatment';
        trt.blng__Active__c = true;
        trt.blng__TaxLegalEntity__c = USEntity.Id;
        trt.QTB_Taxable__c = 'Yes';
        trt.blng__TaxRule__c = taxRule.id;
        trt.blng__TaxIntegration__c = txInt.Id;
        trt.QTB_TaxCountry__c = 'United States';
        insert trt;
        
        List<OrderItem> oItem1 = QTB_Utils.updateTaxTreatmentOrderProducts(legalEntityId,accMap,orderItemList2);        
        
        accountList[0].ShippingCountry = null;
        accountList[0].SBQQ__TaxExempt__c='No';
        update accountList;
        
        orderItemList2[0].UnitPrice = 0;
        orderItemList2[0].blng__BillableUnitPrice__c = 0;
        orderItemList2[0].SBQQ__ChargeType__c = 'Recurring';
         orderItemList2[0].SBQQ__BillingType__c = 'Arrears';
        update orderItemList2[0];
        List<OrderItem> oItem2 = QTB_Utils.updateTaxTreatmentOrderProducts(legalEntityId,accMap,orderItemList2); 
        
        SBQQ__Quote__c thisQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        String whereThis =' WHERE SBQQ__Quantity__c > 0 AND SBQQ__Quote__c IN (\'' +thisQuote.Id +'\')';
        QTB_Utils.publishPriceScheduleEvents(new Set<Id>{ thisQuote.Id },whereThis);
        
        Set<Id> accNewSet = new Set<Id>();
        accNewSet.add(accountList[0].id);
        String whereCond = ' where accountid in (\'' +accountList[0].id +'\') and Account.RecordTypeId=\'' +QTB_Utils.ACCOUNT_BILL_RECTYPEID +'\'';
        String whereCond1 = ' where id in (\'' +accountList[0].id +'\')';        
        string whereCond2 = ' where id != null';
        QTB_Utils.publishBillingAccountOracleOS(accNewSet, whereCond);
        QTB_Utils.publishBillingAccountOracleOS(accNewSet, whereCond2);
        QTB_Utils.publishPriceScheduleEvents(new Set<Id>{ thisQuote.Id }, whereCond2);
        QTB_Utils.publishBillingAccountEvent(accNewSet,whereCond1); 
        Test.getEventBus().deliver();
        
        Map<String, String> lobshortformMap = new Map<String, String>();
        lobshortformMap.put('Records Management','RM');
        string serviceEndPoint = 'https://www.google.com';
        
         IM_Customer_Account__c customerAccount = new IM_Customer_Account__c();
        customerAccount.name = 'test';
        customerAccount.Billing_Country__c= im.id;
        customerAccount.IM_Account__c = accountList[0].id;
        database.insert(customerAccount);
        
        List<QTB_Customer_Billing_Account_Lookup__c> customerTableRecords = new List<QTB_Customer_Billing_Account_Lookup__c>();
        QTB_Customer_Billing_Account_Lookup__c customerTable = new QTB_Customer_Billing_Account_Lookup__c();
        customerTable.QTB_Pricefx_Customer_ID__c ='140AI';
        customerTable.QTB_Quote__c = originalQuoteList[0].id;
        customerTable.QTB_Customer_Account__c= customerAccount.id;
        customerTable.QTB_Compound_Key__c='xyz';
        customerTableRecords.add(customerTable);
        insert customerTableRecords;
        
        SBQQ__Quote__c quoteLst = [SELECT Id,QTB_Opportunity_Product_Line__c,SBQQ__Opportunity2__r.QTB_Original_Quote__c, SBQQ__Opportunity2__r.Billing_Country__r.Iso31662Code__c
                                    FROM SBQQ__Quote__c where id =: originalQuoteList[0].id limit 1];
        QTB_Utils.responseGenerator(quoteLst, lobshortformMap, serviceEndPoint);
        Test.stopTest();
    }
}