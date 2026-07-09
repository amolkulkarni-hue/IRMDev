/*****************************************************************************************************
* Class         : QTB_APIAdvanceStorageBatch_Test
* Purpose       : This is a Test Class used to test QTB_APIAdvanceStorageBatch
* Requirement   : 
* Author        : TCS
* Developer                 Date                Description 
* ------------------------------------------------------------------------------------------- 
*  TCS               
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_APIAdvanceStorageBatch_Test {
    @testSetup
    static void setup() {
        string FileData = 'Subscription ID,Start Date,End Date,Contract: Contract Number,Contract: Account Name: Account ID,Account: API Account Name,Product: Product Line,Product Id,Product: Product Code,Product: Bill Code,Product: API Product Name,Product: Billing Type,Consumption Schedule: Consumption Schedule Name,Subscription Consumption Rate ID,Subscription Consumption Rate Name,API Lower Bound,API Upper Bound,Currency,API Price,New Price\n';
        FileData = FileData +'aIB7b0000004Gch,10/14/2022,10/13/2023,FIN-22-00101487,0017b00000yNFny,Finland_SalesAccount1,Products,01t2H000005WIoS,01100-0341,01100-0341,Retrieval unregistered document add-on fee,Arrears,Work Order Rate 01100-0341,aI97b0000008QFl,R-001900,1,51,EUR,4.98,5.976';
        ContentVersion contentVersionRegularAPI = new ContentVersion(
            Title          = 'a picture',
            PathOnClient   = 'RegularAPI.csv',
            VersionData    = Blob.valueOf(FileData),
            IsMajorVersion = true,
            Description = 'Regular API');
        insert contentVersionRegularAPI; 
        
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product = QTB_TestDataFactory.createProducts(2);
        product[0].SBQQ__SubscriptionTerm__c = 10;
        product[0].SBQQ__SubscriptionTerm__c = 4;
        product[0].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        product[0].ProductCode = '01100-1002';
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        update product[0];
        
        PricebookEntry standardpricebook = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        ConsumptionSchedule consumption = new ConsumptionSchedule();
        consumption.Name = 'dummy';
        consumption.RatingMethod = 'Tier';
        consumption.Type = 'Range';
        consumption.SBQQ__Category__c = 'Rates';
        consumption.BillingTerm = 10;
        consumption.BillingTermUnit = 'Month';
        insert consumption;
        
        ConsumptionRate conrate = new ConsumptionRate();
        conrate.ProcessingOrder = 1;
        conrate.PricingMethod = 'PerUnit';
        conrate.LowerBound = 1;
        conrate.Price = 100;
        conrate.ConsumptionScheduleId = consumption.Id;
        insert conrate;
        
        consumption.IsActive = true;
        update consumption;
        
        insert new ProductConsumptionSchedule(ConsumptionScheduleId = consumption.Id,ProductId = product[0].Id);
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].Billing_County__c = 'United States';
        update accountList[0];
        
        List<PriceBook2> testPriceBook = QTB_TestDataFactory.priceBookMethdLst(1,'Test Price book');        
        testPriceBook[0].isActive = true;
        testPriceBook[0].QTB_Country__c = accountList[0].Billing_County__c;
        update testPriceBook;
        
        //Legal Entity
        blng__LegalEntity__c indiaEntity = new blng__LegalEntity__c();
        indiaEntity.Name = 'Test Legal Entity United States';
        indiaEntity.blng__Active__c = true;
        indiaEntity.blng__Country__c = 'United States';
        indiaEntity.QTB_Type__c = 'Contract';
        //indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert indiaEntity;
        
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';        
        insert im;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = testPriceBook[0].Id;
        //oppList[0].Legal_Entity__c = indiaEntity.id;
        oppList[0].Billing_Country__c = im.id;
        database.update(oppList);
        
        accountList[0].QTB_Source_Opportunity__c = oppList[0].id;
        update accountList[0];
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = testPriceBook[0].Id;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].QTB_IM_Legal_Entity__c = indiaEntity.id;
        quoteList[0].QTB_Opportunity_Billing_Country__c = 'United States';
        database.update(quoteList);
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
        
        //Sales Order
        List<Order> salesOrderlist = QTB_TestDataFactory.createSalesOrders(1,quoteList[0].id,accountList[0].id,oppList[0].id);
        salesOrderlist[0].recordtypeid = QTB_Utils.ORDER_SALES_RECTYPEID;
        database.update(salesOrderlist);
        
        //Billing Order
        List<Order> orderlist = QTB_TestDataFactory.createSalesOrders(1,quoteList[0].id,accountList[0].id,oppList[0].id);
        orderList[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        orderList[0].QTB_Order_OriginatorId__c = salesOrderlist[0].Id;
        database.update(orderList);        
        
        SBQQ.TriggerControl.disable();
        System.debug('Test_orderlist@@'+orderlist);
        Test.startTest();
        List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,product[0].Id,quoteLinesList,standardpricebook);
        
        System.debug('Test_orderItemList@@'+orderItemList);
        
        SBQQ__OrderItemConsumptionSchedule__c ordCS = new SBQQ__OrderItemConsumptionSchedule__c();
        ordCS.SBQQ__BillingTermUnit__c = 'Month';
        ordCS.SBQQ__BillingTerm__c = 4;
        ordCS.SBQQ__Category__c = 'Rates';
        ordCS.SBQQ__RatingMethod__c = 'Tier';
        ordCS.SBQQ__Type__c = 'Range';
        ordCS.SBQQ__ConsumptionSchedule__c = consumption.Id;
        ordCS.blng__BillingRule__c = billingRule.Id;
        ordCS.blng__TaxRule__c = taxRule.Id;
        ordCS.blng__RevenueRecognitionRule__c = revenueRule.Id;
        ordCS.SBQQ__OrderItem__c = orderItemList[0].Id;
        insert ordCS;
        
        SBQQ__OrderItemConsumptionRate__c ordRate = new SBQQ__OrderItemConsumptionRate__c(
            Name = 'Test rate',
            SBQQ__ProcessingOrder__c = 1,
            SBQQ__PricingMethod__c = 'PerUnit',
            SBQQ__LowerBound__c = 1,
            SBQQ__Price__c = 100,
            SBQQ__OrderItemConsumptionSchedule__c = ordCS.Id
        );
        insert ordRate;
        
        List<Contract> contractList = QTB_TestDataFactory.createCPQContracts(
            1,
            orderList[0].id,
            accountList[0].id,
            quoteList[0].id
        );
        for (Contract con : contractList) {
            con.SBQQ__RenewalQuoted__c = true;
            con.SBQQ__RenewalForecast__c = false;
            con.SBQQ__Evergreen__c = false;
            con.StartDate = date.today();
            con.ContractTerm = 11;
            con.name = 'FIN-22-00101487';
            con.SBQQ__Opportunity__c = oppList[0].id;
            con.SBQQ__Order__c = salesOrderlist[0].Id;
            // con.RecordTypeId = contractSalesRecordTypeId;
            con.Status = 'Activated';
        }
        database.update(contractList, false);
        system.debug('@@contractList' +contractList);
        
        List<SBQQ__Subscription__c> subscriptionsList = QTB_TestDataFactory.createCPQSubscriptions(1,contractList[0].id,product[0].id);
        
        //Activating Consumption schedule after creation of consumption rate
        consumption.IsActive = true;
        update consumption;
        
        // Subscription Consumption Schedule
        SBQQ__SubscriptionConsumptionSchedule__c subsCSchedule = new SBQQ__SubscriptionConsumptionSchedule__c();
        subsCSchedule.Name = 'Test data';
        subsCSchedule.SBQQ__UnitOfMeasure__c = 'List';
        subsCSchedule.SBQQ__RatingMethod__c = 'Tier';
        subsCSchedule.SBQQ__ConsumptionSchedule__c = consumption.Id ;
        subsCSchedule.SBQQ__Category__c = 'Rates';
        subsCSchedule.SBQQ__Subscription__c = subscriptionsList[0].Id;
        subsCSchedule.SBQQ__BillingTerm__c = 1;
        subsCSchedule.SBQQ__BillingTermUnit__c = 'Month';
        subsCSchedule.SBQQ__Type__c = 'Range';
        insert subsCSchedule;
        
        SBQQ__SubscriptionConsumptionRate__c SubsRate = new SBQQ__SubscriptionConsumptionRate__c();
        SubsRate.Name = 'Test rate';
        SubsRate.SBQQ__ProcessingOrder__c = 1;
        SubsRate.SBQQ__LowerBound__c = 1;
        SubsRate.SBQQ__UpperBound__c = 51;
        SubsRate.SBQQ__Price__c = 300;
        SubsRate.SBQQ__PricingMethod__c = 'PerUnit';
        SubsRate.SBQQ__SubscriptionConsumptionSchedule__c = subsCSchedule.Id;
        insert SubsRate;
        SBQQ.TriggerControl.enable();
        Test.stopTest();
    }
    
    static testMethod void testmethod1(){
        test.startTest();
        List<ContentDocument> fileList = [SELECT Id,Title,ContentSize,FileType,Owner.Name,createdDate,Division,Description
                                          FROM ContentDocument ];
        List<QTB_APIUpliftCntrl.SubscriptionDataWrapper> wrapParentList = new List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>();
        List<Contract> contractList = [SELECT id,Name,SBQQ__Order__c, SBQQ__RenewalForecast__c, SBQQ__RenewalQuoted__c FROM Contract];
        List<SBQQ__Subscription__c> subscriptionList = [SELECT id,Name FROM SBQQ__Subscription__c];
        List<Product2> productList = [SELECT id,Name FROM Product2];
        List<SBQQ__SubscriptionConsumptionRate__c> Subsrate = [SELECT id,Name,SBQQ__LowerBound__c,SBQQ__UpperBound__c FROM SBQQ__SubscriptionConsumptionRate__c];
        
        QTB_APIUpliftCntrl.SubscriptionDataWrapper wrapParent = new QTB_APIUpliftCntrl.SubscriptionDataWrapper();
        wrapParent.subscriptionId = subscriptionList[0].id;
        wrapParent.contractName = contractList[0].Name;
        wrapParent.productId= String.valueOf((productList[0].id)).left(15);
        wrapParent.subscriptionCSRateId=Subsrate[0].id;
        wrapParent.subscriptionCSRateName=Subsrate[0].Name;
        wrapParent.subscriptionCSRateLowerBound=string.valueof(Subsrate[0].SBQQ__LowerBound__c);
        wrapParent.subscriptionCSRateUpperBound=string.valueof(Subsrate[0].SBQQ__UpperBound__c);
        wrapParent.oldPrice=4.98;
        wrapParent.newPrice=5.976; 
        wrapParentList.add(wrapParent);
        System.debug('wrapParent@@'+wrapParent);
        system.debug('+++++'+fileList);
        system.debug('+++++'+contractList);
        List<QTB_Data_Holder__c> dataHolderAPIObjList = new List<QTB_Data_Holder__c>();
        QTB_Data_Holder__c dataHolderObj = new QTB_Data_Holder__c();
        dataHolderObj.QTB_APIDocument_Id__c = fileList[0].id;
        dataHolderObj.QTB_APIStatus__c = 'New';
        dataHolderObj.QTB_APIType__c = 'Advance API';
        dataHolderObj.QTB_APIUploaded_By__c = fileList[0].Owner.Name;
        dataHolderObj.QTB_APIUploaded_Date__c =  fileList[0].createdDate.date();
        dataHolderObj.RecordTypeId = Schema.getGlobalDescribe().get('QTB_Data_Holder__c').getDescribe().getRecordTypeInfosByName().get('Uplift').getRecordTypeId();
        dataHolderAPIObjList.add(dataHolderObj);        
        if(dataHolderAPIObjList !=null && !dataHolderAPIObjList.isEmpty()){
            insert dataHolderAPIObjList;
            system.debug('dataHolderAPIObjList records'+dataHolderAPIObjList);
        }
        
        QTB_APIAdvanceStorageBatch obj = new QTB_APIAdvanceStorageBatch(wrapParentList,fileList[0].id);
        ID batchprocessid =  DataBase.executeBatch(obj);
        Test.stoptest();
    }
    static testMethod void testmethod2(){
        test.startTest();
		List<ContentDocument> fileList = [SELECT Id,Title,ContentSize,FileType,Owner.Name,createdDate,Division,Description
                                          FROM ContentDocument ];
        List<QTB_APIUpliftCntrl.SubscriptionDataWrapper> wrapParentList = new List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>();
        List<Contract> contractList = [SELECT id,Name, SBQQ__RenewalForecast__c, SBQQ__RenewalQuoted__c FROM Contract];
        List<SBQQ__Subscription__c> subscriptionList = [SELECT id,Name FROM SBQQ__Subscription__c];

        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        List<Product2> productList = [SELECT id,Name FROM Product2 where name ='Test Product 1'];
        productList[0].SBQQ__SubscriptionTerm__c = 11;
        productList[0].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        productList[0].ProductCode = '01100-1004';
        productList[0].blng__BillingRule__c = billingRule.id;
        productList[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        productList[0].blng__TaxRule__c = taxRule.id;
        update productList[0];

        List<SBQQ__SubscriptionConsumptionRate__c> Subsrate = [SELECT id,Name,SBQQ__LowerBound__c,SBQQ__UpperBound__c FROM SBQQ__SubscriptionConsumptionRate__c];
        
        QTB_APIUpliftCntrl.SubscriptionDataWrapper wrapParent = new QTB_APIUpliftCntrl.SubscriptionDataWrapper();
        wrapParent.subscriptionId = subscriptionList[0].id;
        wrapParent.contractName = contractList[0].Name;
        wrapParent.productId= String.valueOf((productList[0].id)).left(15);
        wrapParent.subscriptionCSRateId=Subsrate[0].id;
        wrapParent.subscriptionCSRateName=Subsrate[0].Name;
        wrapParent.subscriptionCSRateLowerBound=string.valueof(Subsrate[0].SBQQ__LowerBound__c);
        wrapParent.subscriptionCSRateUpperBound=string.valueof(Subsrate[0].SBQQ__UpperBound__c);
        wrapParent.oldPrice=4.98;
        wrapParent.newPrice=5.976; 
        wrapParentList.add(wrapParent);
        System.debug('wrapParent@@'+wrapParent);
        system.debug('+++++'+fileList);
        system.debug('+++++'+contractList);
        List<QTB_Data_Holder__c> dataHolderAPIObjList = new List<QTB_Data_Holder__c>();
        QTB_Data_Holder__c dataHolderObj = new QTB_Data_Holder__c();
        dataHolderObj.QTB_APIDocument_Id__c = fileList[0].id;
        dataHolderObj.QTB_APIStatus__c = 'New';
        dataHolderObj.QTB_APIType__c = 'Advance API';
        dataHolderObj.QTB_APIUploaded_By__c = fileList[0].Owner.Name;
        dataHolderObj.QTB_APIUploaded_Date__c =  fileList[0].createdDate.date();
        dataHolderObj.RecordTypeId = Schema.getGlobalDescribe().get('QTB_Data_Holder__c').getDescribe().getRecordTypeInfosByName().get('Uplift').getRecordTypeId();
        dataHolderAPIObjList.add(dataHolderObj);        
        if(dataHolderAPIObjList !=null && !dataHolderAPIObjList.isEmpty()){
            insert dataHolderAPIObjList;
            system.debug('dataHolderAPIObjList records'+dataHolderAPIObjList);
        }
        
        QTB_APIAdvanceStorageBatch obj = new QTB_APIAdvanceStorageBatch(null,fileList[0].id);
        ID batchprocessid =  DataBase.executeBatch(obj);
        Test.stoptest();
    }
}