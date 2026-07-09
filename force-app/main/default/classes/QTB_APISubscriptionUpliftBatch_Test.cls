/*****************************************************************************************************
* Class      : QTB_APISubscriptionUpliftBatch_Test
* Author    : IRM/Virtusa
* Purpose     : To Cover all API related apex class testing 
: Provide Code Coverage for QTB_APISubscriptionUpliftBatch, QTB_APIRenewalOpptyQuoteCreationBatch
* Requirement  : Gitlab US #10331, #10329,12040 
* Developer                Date            Description
* -----------------------------------------------------------------------------------------------------
* Shailesh           12/25/2022       Gitlab US #10331, #10329,12040
*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_APISubscriptionUpliftBatch_Test {
    @testSetup
    static void setup() {
        Id pricebookId = Test.getStandardPricebookId();        
        
        List<product2> productList = new List<product2>();
        //Product1 -- usage
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        p1.ProductCode = '01100-0061';
        productList.add(p1);
        
        //Product2 -- usage
        product2 p2 = new product2();
        p2.Name = 'Test Product2';
        p2.isActive = true;
        p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p2.SBQQ__HasConsumptionSchedule__c = true;
        p2.ProductCode = '02100-0003';
        productList.add(p2);
        
        product2 p3 = new product2();
        p3.Name = 'Test Product3';
        p3.isActive = true;
        p3.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p3.SBQQ__HasConsumptionSchedule__c = true;
        p3.ProductCode = '02100-1234';
        productList.add(p3);
        
        //Product4 -- usage
        product2 p4 = new product2();
        p4.Name = 'Test Product4';
        p4.isActive = true;
        p4.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p4.SBQQ__HasConsumptionSchedule__c = true;
        p4.ProductCode = '01100-0587';
        productList.add(p4);
        
        insert productList;
        
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(productList[0]);
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[1]);
        PricebookEntry standardPrice3 = QTB_TestDataFactory.createPricebookEntry(productList[2]);
        PricebookEntry standardPrice4 = QTB_TestDataFactory.createPricebookEntry(productList[3]);
        
        //Consumption Schedule
        List<ConsumptionSchedule> conScheduleList = new List<ConsumptionSchedule>();
        
        //Consumption Schedule -- List        
        ConsumptionSchedule consumption1 = new ConsumptionSchedule();
        consumption1.Name = 'List';
        consumption1.RatingMethod = 'Tier';
        consumption1.Type = 'Range';
        consumption1.SBQQ__Category__c = 'Rates';
        consumption1.BillingTerm = 10;
        
        consumption1.BillingTermUnit = 'Month';
        conScheduleList.add(consumption1);
        
        //Consumption Schedule -- Range
        ConsumptionSchedule consumption2 = new ConsumptionSchedule();
        consumption2.Name = 'Range';
        consumption2.RatingMethod = 'Tier';
        consumption2.Type = 'Range';
        consumption2.SBQQ__Category__c = 'Rates';
        consumption2.BillingTerm = 10;
        consumption2.BillingTermUnit = 'Month';
        conScheduleList.add(consumption2);
        insert conScheduleList;
        
        //Consumption Schedule Rate
        List<ConsumptionRate> conRateList = new List<ConsumptionRate>();
        
        //CS Rate Tier - 1 for List
        ConsumptionRate conrate1 = new ConsumptionRate();
        conrate1.ProcessingOrder = 1;
        conrate1.PricingMethod = 'PerUnit';
        conrate1.LowerBound = 1;
        conRate1.UpperBound = 100;
        conrate1.Price = 100;
        conrate1.ConsumptionScheduleId = conScheduleList[0].Id;
        conRateList.add(conrate1);
        
        //CS Rate Tier - 1
        ConsumptionRate conRate2 = new ConsumptionRate();
        conRate2.ProcessingOrder = 1;
        conRate2.PricingMethod = 'PerUnit';
        conRate2.LowerBound = 1;
        conRate2.UpperBound = 100;
        conRate2.Price = 100;
        conRate2.ConsumptionScheduleId = conScheduleList[1].Id;
        conRateList.add(conRate2);
        
        //CS Rate Tier - 2
        ConsumptionRate conrate3 = new ConsumptionRate();
        conrate3.ProcessingOrder = 2;
        conrate3.PricingMethod = 'PerUnit';
        conrate3.LowerBound = 100;
        conrate3.UpperBound = 200;
        conrate3.Price = 50; 
        conrate3.ConsumptionScheduleId = conScheduleList[1].Id;
        conRateList.add(conrate3);
        insert conRateList;
        
        //Activating Consumption schedule after creation of consumption rate
        conScheduleList[0].IsActive = true;
        conScheduleList[1].IsActive = true;
        update conScheduleList;
        
        //ProductConsumptionSchedule
        insert new ProductConsumptionSchedule(ConsumptionScheduleId = conScheduleList[0].Id,ProductId = productList[0].Id);
        insert new ProductConsumptionSchedule(ConsumptionScheduleId = conScheduleList[1].Id,ProductId = productList[1].Id);
        
        //Standard Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Standard Account');        
        accountList[0].QTB_Minimum_Storage_Charges__c = 10000;
        accountList[0].QTB_Minimum_Charges_Start_Date__c = System.today();
        update accountList[0];
        
        //Legal Entity
        blng__LegalEntity__c finlandLegalEntity = new blng__LegalEntity__c();
        finlandLegalEntity.Name = 'Test Legal Entity United States';
        finlandLegalEntity.blng__Active__c = true;
        finlandLegalEntity.blng__Country__c = 'Finland';
        finlandLegalEntity.QTB_Type__c = 'Contract';
        //finlandLegalEntity.QTB_Legal_Entity_Number__c = '45000';
        insert finlandLegalEntity;
        
        IM_Country__c im = new IM_Country__c();
        im.Name = 'Finland1';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'Europe';
        im.AlternativeNames__c = 'Finland';
        im.Iso31662Code__c ='FI';
        im.Iso31663Code__c ='FIN';        
        //insert im;
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        oppList[0].Legal_Entity__c = finlandLegalEntity.id;
        // oppList[0].Billing_Country__c = im.id;
        database.update(oppList);
        
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].QTB_IM_Legal_Entity__c = finlandLegalEntity.id;
        quoteList[0].QTB_Opportunity_Billing_Country__c = 'Finland';
        database.update(quoteList);
        
        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList1 = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[0].id);
        List<SBQQ__QuoteLine__c> quoteLinesList2 = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[1].id);
        
        Test.startTest();
        //Sales Order
        List<Order> salesOrderList = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        salesOrderList[0].recordtypeid = QTB_Utils.ORDER_SALES_RECTYPEID;
        database.update(salesOrderList[0]);
        
        List<OrderItem> salesOrderItemList = QTB_TestDataFactory.createCPQOrderItems(salesOrderList[0].Id,productList[0].Id,quoteLinesList1,standardPrice1);
        
        //Account
        List<Account> billingAccountList = QTB_TestDataFactory.createAccounts(1,'Billing Account' );
        billingAccountList[0].QTB_Legal_Entity_Country__c='United States';
        billingAccountList[0].QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
        update billingAccountList;
        
        //Billing Order
        List<Order> billingOrderList = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,billingAccountList[0].id);
        
        //Billing OrderItem
        List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(billingOrderList[0].Id,productList[0].Id,quoteLinesList1,standardPrice1);
        
        billingOrderList[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        billingOrderList[0].QTB_Order_OriginatorId__c = salesOrderList[0].Id;
        //billingOrderList[0].status = 'Activated';
        database.update(billingOrderList[0]);
        
        //Contract1
        List<Contract> contractList = new List<Contract>();        
        contract con = new contract();
        con.AccountId = accountList[0].Id;
        con.SBQQ__Order__c = salesOrderList[0].id;
        con.SBQQ__Opportunity__c = oppList[0].Id;
        con.SBQQ__Quote__c = quoteList[0].Id;
        con.RecordTypeId =QTB_Utils.CONTRACT_SALES_RECTYPEID;
        con.Status  = 'Draft';
        con.StartDate = System.today();
        contractList.add(con);
        
        //Contract2
        contract con1 = new contract();
        con1.AccountId = accountList[0].Id;
        con1.SBQQ__Order__c = salesOrderList[0].id;
        con1.SBQQ__Opportunity__c = oppList[0].Id;
        con1.SBQQ__Quote__c = quoteList[0].Id;
        con1.RecordTypeId =QTB_Utils.CONTRACT_SALES_RECTYPEID;
        con1.Status  = 'Draft';
        con1.StartDate = System.today();
        contractList.add(con1);
        
        insert contractList;
        
        //   contractList[0].Status = 'Activated';
        // update contractList[0];
        
        //Subscription
        List<SBQQ__Subscription__c> subscriptionList = new List<SBQQ__Subscription__c>();
        
        //Subscription -- List
        SBQQ__Subscription__c subObj1 = new SBQQ__Subscription__c();
        subObj1.SBQQ__Product__c = productList[0].Id;
        subObj1.SBQQ__Contract__c = con.Id;
        subObj1.QTB_Quote_line_Consumption_Schedule_Name__c = 'List';
        subObj1.SBQQ__Quantity__c = 1;
        subObj1.SBQQ__RenewalPrice__c = null;
        subscriptionList.add(subObj1);
        
        //Subscription -- Range
        SBQQ__Subscription__c subObj2 = new SBQQ__Subscription__c();
        subObj2.SBQQ__Product__c = productList[1].Id;
        subObj2.SBQQ__Contract__c = con.Id;
        subObj2.QTB_Quote_line_Consumption_Schedule_Name__c = 'Range';
        subObj2.SBQQ__Quantity__c = 1;
        subObj2.SBQQ__RenewalPrice__c = null;
        subscriptionList.add(subObj2);     
        
        //Subscription -- Range
        SBQQ__Subscription__c subObj3 = new SBQQ__Subscription__c();
        subObj3.SBQQ__Product__c = productList[2].Id;
        subObj3.SBQQ__Contract__c = con.Id;
        subObj3.QTB_Quote_line_Consumption_Schedule_Name__c = 'Range';
        subObj3.SBQQ__Quantity__c = 1;
        subObj3.SBQQ__RenewalPrice__c = null;
        subscriptionList.add(subObj3);
        insert subscriptionList;
        
        //Subscription Consumption Schedule
        List<SBQQ__SubscriptionConsumptionSchedule__c> subCSList = new List<SBQQ__SubscriptionConsumptionSchedule__c>();
        
        //Subscription CS -- List
        SBQQ__SubscriptionConsumptionSchedule__c subCS1 = new SBQQ__SubscriptionConsumptionSchedule__c();
        subCS1.Name = 'List';
        subCS1.SBQQ__BillingTerm__c = 1;
        subCS1.SBQQ__BillingTermUnit__c = 'Month';
        subCS1.SBQQ__Subscription__c = subscriptionList[0].Id;
        subCS1.SBQQ__ConsumptionSchedule__c = conScheduleList[0].Id;
        subCS1.SBQQ__RatingMethod__c = 'Tier';
        subCS1.SBQQ__Category__c = 'Rates';
        subCS1.SBQQ__Type__c = 'Range';
        subCSList.add(subCS1);
        
        //Subscription CS -- Range
        SBQQ__SubscriptionConsumptionSchedule__c subCS2 = new SBQQ__SubscriptionConsumptionSchedule__c();
        subCS2.Name = 'Range';
        subCS2.SBQQ__BillingTerm__c = 1;
        subCS2.SBQQ__BillingTermUnit__c = 'Month';
        subCS2.SBQQ__Subscription__c = subscriptionList[1].Id;
        subCS2.SBQQ__ConsumptionSchedule__c = conScheduleList[1].Id;
        subCS2.SBQQ__RatingMethod__c = 'Tier';
        subCS2.SBQQ__Category__c = 'Rates';
        subCS2.SBQQ__Type__c = 'Range';
        subCSList.add(subCS2);
        
        SBQQ.TriggerControl.disable();
        insert subCSList;
        
        //Subscription Consumption Schedule Rates
        List<SBQQ__SubscriptionConsumptionRate__c> subCSRateList = new List<SBQQ__SubscriptionConsumptionRate__c>();
        
        //Subscription CS Rate -- List Rate
        SBQQ__SubscriptionConsumptionRate__c subCSRate = new SBQQ__SubscriptionConsumptionRate__c();
        subCSRate.Name = 'R-0001';
        subCSRate.SBQQ__ProcessingOrder__c = 1;
        subCSRate.SBQQ__LowerBound__c = 1;
        subCSRate.SBQQ__UpperBound__c = 10;
        subCSRate.SBQQ__Price__c = 10;
        subCSRate.SBQQ__SubscriptionConsumptionSchedule__c = subCSList[0].Id;
        subCSRate.SBQQ__PricingMethod__c= 'Per Unit';
        subCSRateList.add(subCSRate);
        
        //Subscription CS Rate -- Range Rate Tier 1
        SBQQ__SubscriptionConsumptionRate__c subCSRate1 = new SBQQ__SubscriptionConsumptionRate__c();
        subCSRate1.Name = 'R-0002';
        subCSRate1.SBQQ__ProcessingOrder__c = 1;
        subCSRate1.SBQQ__LowerBound__c = 1;
        subCSRate1.SBQQ__UpperBound__c = 10;
        subCSRate1.SBQQ__Price__c = 10;
        subCSRate1.SBQQ__SubscriptionConsumptionSchedule__c = subCSList[1].Id;
        subCSRate1.SBQQ__PricingMethod__c= 'Per Unit';
        subCSRateList.add(subCSRate1);
        
        //Subscription CS Rate -- Range Rate Tier 2
        SBQQ__SubscriptionConsumptionRate__c subCSRate2 = new SBQQ__SubscriptionConsumptionRate__c();
        subCSRate2.Name = 'R-0003'; 
        subCSRate2.SBQQ__ProcessingOrder__c = 2;
        subCSRate2.SBQQ__LowerBound__c = 10;
        subCSRate2.SBQQ__Price__c = 5;
        subCSRate2.SBQQ__SubscriptionConsumptionSchedule__c = subCSList[1].Id;
        subCSRate2.SBQQ__PricingMethod__c= 'Per Unit';
        subCSRateList.add(subCSRate2);
        insert subCSRateList;
        
        SBQQ.TriggerControl.enable();
        
        //Prepared CSV File Data
        string FileData = 'Subscription ID,Start Date,End Date,Contract Number,Account ID,Account Name,Product Line,Product Id,Product Code,Bill Code,Product Name,Billing Type,Subscription Consumption Schedule Name,Subscription Consumption Rate ID,Subscription Consumption Rate Name,API Lower Bound,API Upper Bound,Currency,API Price,New Price\n';
        string subData1 = subscriptionList[0].Id+',10/14/2022,10/13/2023,'+contractList[0].Name+',0017b00000yNFny,Finland_SalesAccount1,Products,'+productList[0]+',01100-0341,01100-0341,Retrieval unregistered document add-on fee,Arrears,List,aI97b0000008QFl,'+subCSRateList[0].Name+',1,10,EUR,10,11\n';
        string subData2 = subData1 + subscriptionList[1].Id+',10/14/2022,10/13/2023,'+contractList[0].Name+',0017b00000yNFny,Finland_SalesAccount1,Products,'+productList[1]+',01100-0341,01100-0341,Retrieval unregistered document add-on fee,Arrears,Range,aI97b0000008QFl,'+subCSRateList[1].Name+',1,10,EUR,10,11\n';
        string subData3 = subData2 + subscriptionList[1].Id+',10/14/2022,10/13/2023,'+contractList[0].Name+',0017b00000yNFny,Finland_SalesAccount1,Products,'+productList[1]+',01100-0341,01100-0341,Retrieval unregistered document add-on fee,Arrears,Range,aI97b0000008QFl,'+subCSRateList[2].Name+',10,,EUR,5,6\n';
        FileData = FileData + subData3;
        ContentVersion contentVersionRegularAPI = new ContentVersion(
            Title          = 'RegulaAPI',
            PathOnClient   = 'RegularAPI.csv',
            VersionData    = Blob.valueOf(FileData),
            IsMajorVersion = true,
            Description = 'Regular API');
        insert contentVersionRegularAPI;
        Test.stopTest();
        
        List<ContentDocument> fileList = [SELECT Id,Title,ContentSize,FileType,Owner.Name,createdDate,Division,Description
                                          FROM ContentDocument ];
        String upliftAPIRecordTypeID = Schema.getGlobalDescribe().get('QTB_Data_Holder__c').getDescribe().getRecordTypeInfosByName().get('Uplift').getRecordTypeId();
        
        List<QTB_Data_Holder__c> dataHolderAPIObjList = new List<QTB_Data_Holder__c>();
        QTB_Data_Holder__c dataHolderObj = new QTB_Data_Holder__c();
        dataHolderObj.QTB_APIDocument_Id__c = fileList[0].Id;
        dataHolderObj.QTB_APIStatus__c = 'New';
        dataHolderObj.QTB_APIType__c = 'Regular API';
        dataHolderObj.QTB_APIUploaded_By__c = UserInfo.getUserName();
        dataHolderObj.QTB_APIUploaded_Date__c =  System.today();
        dataHolderObj.RecordTypeId = upliftAPIRecordTypeID;
        dataHolderAPIObjList.add(dataHolderObj);
        if(dataHolderAPIObjList !=null && !dataHolderAPIObjList.isEmpty()){
            insert dataHolderAPIObjList;
        }
    }
    
    /*********************************************************************************************************
* Method Name: QTB_APISubscriptionUpliftBatch_testmethod1
* Requirement: Gitlab US #10330
* Description: This test method provide code coverage for the QTB_APISubscriptionUpliftBatch class
**********************************************************************************************************/      
    static testMethod void QTB_APISubscriptionUpliftBatch_testmethod1(){
        List<ContentDocument> fileList = [SELECT Id,Title,ContentSize,FileType,Owner.Name,createdDate,Division,Description
                                          FROM ContentDocument ]; 
        List<Contract> contractList = [SELECT id,Name,SBQQ__OpportunityPricebookId__c, SBQQ__RenewalForecast__c, SBQQ__RenewalQuoted__c FROM Contract ];       
        List<SBQQ__Subscription__c> subscriptionList = [SELECT id,Name,SBQQ__Product__c,CurrencyIsoCode,SBQQ__Contract__r.SBQQ__OpportunityPricebookId__c FROM SBQQ__Subscription__c];
        List<Product2> productList = [SELECT id,Name FROM Product2];
        List<SBQQ__SubscriptionConsumptionSchedule__c> ScScheduleList = [SELECT id,name,SBQQ__ConsumptionSchedule__c,CurrencyIsoCode from SBQQ__SubscriptionConsumptionSchedule__c];
        List<SBQQ__SubscriptionConsumptionRate__c> Subsrate = [SELECT id,Name,SBQQ__LowerBound__c,SBQQ__UpperBound__c FROM SBQQ__SubscriptionConsumptionRate__c];
        list<SBQQ__Quote__c> QtsList = [select id,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Order__c,
                                        SBQQ__Opportunity2__r.SBQQ__RenewedContract__c from SBQQ__Quote__c];
        List<Id> lstTopass= new List<Id>();
        lstTopass.add(QtsList[0].id);
        
        Map<Id,String> consumpScheduleIdWithCSRateNameMap = new Map<Id,String>();
        for(ConsumptionRate csRate : [SELECT Id, NAME,ConsumptionScheduleId 
                                      FROM ConsumptionRate 
                                       LIMIT 2]){
                                          consumpScheduleIdWithCSRateNameMap.put(csRate.ConsumptionScheduleId,csRate.Name);
                                      }
        Test.startTest();
        QTB_APIUpliftCntrl.saveFile(fileList[0].Id, 'Regular API');        
        QTB_APIUpliftCntrl.getUploadedData();
        QTB_APIUpliftCntrl.deleteCancelFile(fileList[0].Id);
        
        List<QTB_APIUpliftCntrl.SubscriptionDataWrapper> subDataWrapList = new List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>();
        QTB_APIUpliftCntrl.SubscriptionDataWrapper subDataWrapper = new QTB_APIUpliftCntrl.SubscriptionDataWrapper();
        subDataWrapper.contractName = contractList[0].Name;
        subDataWrapper.subscriptionId = subscriptionList[0].id;
        subDataWrapper.newPrice = 1.1;
        subDataWrapper.oldPrice = 1.1;
        subDataWrapper.productId = productList[0].id;
        subDataWrapper.subscriptionCSName = 'List';
        subDataWrapper.subscriptionCSRateId =Subsrate[0].id;
        subDataWrapper.subscriptionCSRateName = Subsrate[0].Name;
        subDataWrapper.subscriptionCSRateLowerBound=string.valueof(Subsrate[0].SBQQ__LowerBound__c);
        subDataWrapper.subscriptionCSRateUpperBound=string.valueof(Subsrate[0].SBQQ__UpperBound__c);
        subDataWrapper.oldPrice=4.98;
        subDataWrapper.newPrice=5.976;         
        subDataWrapList.add(subDataWrapper); 
        
        QTB_APIUpliftCntrl.SubscriptionDataWrapper subDataWrapper1 = new QTB_APIUpliftCntrl.SubscriptionDataWrapper();
        subDataWrapper1.contractName = contractList[0].Name;
        subDataWrapper1.subscriptionId = subscriptionList[1].id;
        subDataWrapper1.newPrice = 1.1;
        subDataWrapper1.oldPrice = 1.1;
        subDataWrapper1.productId = productList[1].id;
        subDataWrapper1.subscriptionCSName = 'Range';
        subDataWrapper1.subscriptionCSRateId =Subsrate[0].id;
        subDataWrapper1.subscriptionCSRateName = Subsrate[0].Name;
        subDataWrapper1.subscriptionCSRateLowerBound=string.valueof(Subsrate[0].SBQQ__LowerBound__c);
        // subDataWrapper1.subscriptionCSRateUpperBound=string.valueof(Subsrate[0].SBQQ__UpperBound__c);
        subDataWrapper1.oldPrice=4.98;
        subDataWrapper1.newPrice=5.976; 
        subDataWrapList.add(subDataWrapper1);    
        
        QTB_APIUpliftCntrl.SubscriptionDataWrapper subDataWrapper2 = new QTB_APIUpliftCntrl.SubscriptionDataWrapper();
        subDataWrapper2.contractName = 'abc';
        subDataWrapper2.subscriptionId = subscriptionList[1].id;
        subDataWrapper2.newPrice = 1.1;
        subDataWrapper2.oldPrice = 1.1;
        subDataWrapper2.productId = productList[2].id;
        subDataWrapper2.subscriptionCSName = 'List';
        subDataWrapper2.subscriptionCSRateId =Subsrate[0].id;
        subDataWrapper2.subscriptionCSRateName = Subsrate[0].Name;
        subDataWrapper2.subscriptionCSRateLowerBound=string.valueof(Subsrate[0].SBQQ__LowerBound__c);
        subDataWrapper2.subscriptionCSRateUpperBound=string.valueof(Subsrate[0].SBQQ__UpperBound__c);
        subDataWrapper2.oldPrice=4.98;
        subDataWrapper2.newPrice=5.976; 
        subDataWrapList.add(subDataWrapper2); 
        
        QTB_APISubscriptionUpliftBatch apiSub = new QTB_APISubscriptionUpliftBatch(subDataWrapList,fileList[0].Id);
        
       
        database.executeBatch(apiSub);
        
        
        Set<String> failedContractSet  = new Set<String>();     
        failedContractSet.add('TestRecord');
        QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet, 'ContractSubscription');
        QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet, 'Renew Oppty/Quote');
        QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet, 'Opportunity');
        QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet, 'Quote');
        QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet, 'SalesOrder');
        QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet, 'BillingOrder');
        QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(failedContractSet, 'xyz');     
        
        Set<String> contractNameSet = new Set<String>();
        contractNameSet.add(contractList[0].Name);
        
        Set<Id> productIdSet = new Set<Id>();
        productIdSet.add(productList[0].id);
        QTB_APISubscriptionUpliftBatch.revertSubscriptionTypeOfSubscription(contractNameSet,contractNameSet,productIdSet);
       // QTB_APISubscriptionUpliftBatch.revertProductSubtypeChanges(true);
       // QTB_APISubscriptionUpliftBatch.revertProductSubtypeChanges(false);
        QTB_APISubscriptionUpliftBatch.deleteSubCSWrtProductCS(contractNameSet);
        QTB_APISubscriptionUpliftBatch.createSubscriptionCSForMinimumsSubscription(subscriptionList);
        QTB_APISubscriptionUpliftBatch.createSubscriptionCSRate(ScScheduleList,consumpScheduleIdWithCSRateNameMap);
        
        QTB_APISubscriptionUpliftBatch apiSubUpliftBatch = new QTB_APISubscriptionUpliftBatch(subDataWrapList,fileList[0].Id);
        apiSubUpliftBatch.minimumProductCodeSet = new Set<String>{'01100-0061','02100-0003','02100-1234','01100-0587'};
        apiSubUpliftBatch.createMissingMinimumsForSubscription(subscriptionList);
        Test.stopTest();
    }
    
/*********************************************************************************************************
* Method Name: QTB_APISubscriptionUpliftBatch_testmethod2
* Requirement: Gitlab US #10330
* Description: This test method provide code coverage for the QTB_APISubscriptionUpliftBatch class
**********************************************************************************************************/      
    static testMethod void QTB_APISubscriptionUpliftBatch_testmethod2(){
        List<ContentDocument> fileList = [SELECT Id,Title,ContentSize,FileType,Owner.Name,createdDate,Division,Description
                                          FROM ContentDocument ]; 
        List<Contract> contractList = [SELECT id,Name, SBQQ__RenewalForecast__c, SBQQ__RenewalQuoted__c FROM Contract ];
        List<SBQQ__Subscription__c> subscriptionList = [SELECT id,Name FROM SBQQ__Subscription__c];
        List<Product2> productList = [SELECT id,Name FROM Product2];
        List<SBQQ__SubscriptionConsumptionSchedule__c> ScScheduleList = [SELECT id,name from SBQQ__SubscriptionConsumptionSchedule__c];
        List<SBQQ__SubscriptionConsumptionRate__c> Subsrate = [SELECT id,Name,SBQQ__LowerBound__c,SBQQ__UpperBound__c FROM SBQQ__SubscriptionConsumptionRate__c];
        list<SBQQ__Quote__c> QtsList = [select id,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Order__c,
                                        SBQQ__Opportunity2__r.SBQQ__RenewedContract__c from SBQQ__Quote__c];
        List<Id> lstTopass= new List<Id>();
        lstTopass.add(QtsList[0].id);
       
        Test.startTest();
        QTB_APIUpliftCntrl.saveFile(fileList[0].Id, 'Regular API');        
        QTB_APIUpliftCntrl.getUploadedData();
        QTB_APIUpliftCntrl.deleteCancelFile(fileList[0].Id);
        
        List<QTB_APIUpliftCntrl.SubscriptionDataWrapper> subDataWrapList = new List<QTB_APIUpliftCntrl.SubscriptionDataWrapper>();
        QTB_APIUpliftCntrl.SubscriptionDataWrapper subDataWrapper = new QTB_APIUpliftCntrl.SubscriptionDataWrapper();
        subDataWrapper.contractName = contractList[0].Name;
        subDataWrapper.subscriptionId = subscriptionList[0].id;
        subDataWrapper.newPrice = 1.1;
        subDataWrapper.oldPrice = 1.1;
        subDataWrapper.productId = productList[0].id;
        subDataWrapper.subscriptionCSName = 'List';
        subDataWrapper.subscriptionCSRateId =Subsrate[0].id;
        subDataWrapper.subscriptionCSRateName = Subsrate[0].Name;
        subDataWrapper.subscriptionCSRateLowerBound=string.valueof(Subsrate[0].SBQQ__LowerBound__c);
        subDataWrapper.subscriptionCSRateUpperBound=string.valueof(Subsrate[0].SBQQ__UpperBound__c);
        subDataWrapper.oldPrice=4.98;
        subDataWrapper.newPrice=5.976; 
        
        subDataWrapList.add(subDataWrapper);  
        
        //insert dataHolder record
        List<QTB_Data_Holder__c> dataHolderAPIObjList = new List<QTB_Data_Holder__c>();
        QTB_Data_Holder__c dataHolderObj = new QTB_Data_Holder__c();
        dataHolderObj.QTB_APIDocument_Id__c = fileList[0].id;
        dataHolderObj.QTB_APIStatus__c = 'New';
        dataHolderObj.QTB_APIType__c = 'API';
        dataHolderObj.QTB_APIUploaded_By__c = fileList[0].Owner.Name;
        dataHolderObj.QTB_APIUploaded_Date__c =  fileList[0].createdDate.date();
        dataHolderObj.RecordTypeId = Schema.getGlobalDescribe().get('QTB_Data_Holder__c').getDescribe().getRecordTypeInfosByName().get('Uplift').getRecordTypeId();
        dataHolderAPIObjList.add(dataHolderObj);        
        if(dataHolderAPIObjList !=null && !dataHolderAPIObjList.isEmpty()){
            insert dataHolderAPIObjList;
            system.debug('dataHolderAPIObjList records'+dataHolderAPIObjList);
        }
        
        QTB_APISubscriptionUpliftBatch apiSub = new QTB_APISubscriptionUpliftBatch(subDataWrapList,fileList[0].Id);
        Set<String> SendEmailString  = new Set<String>();     
        SendEmailString.add('TestRecord');
        QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(SendEmailString, 'Opportunity');
        QTB_APISubscriptionUpliftBatch.sendEmailForFailedAPIContract(SendEmailString, 'Quote');
        
       
        database.executeBatch(apiSub);
        Test.stopTest();
    }
    
    /*********************************************************************************************************
* Method Name: QTB_APIRenewalOpptyQuoteCreationBatch_testmethod1
* Requirement: Gitlab US #10330
* Description: This test method provide code coverage for the QTB_APIRenewalOpptyQuoteCreationBatch class
**********************************************************************************************************/    
    static testMethod void QTB_APIRenewalOpptyQuoteCreationBatch_testmethod1(){
        Set<String> successContractSet = new Set<String>();
        Set<String> failedContractSet = new Set<String>();
        List<Contract> contractList = [Select Id, Name,AccountId,SBQQ__RenewalQuoted__c  From Contract];
        List<QTB_Data_Holder__c> dataHolderAPIObjList = [Select id From QTB_Data_Holder__c ];
        for(Contract contr: contractList){
            successContractSet.add(contr.Name);
            failedContractSet.add(contr.Name);
        }        
        Test.startTest();
        List<Product2> prdList = [Select Id from Product2];
        Set<Id> productToUpdateSet = new Set<Id>();
        productToUpdateSet.add(prdList[0].Id);
        QTB_APIRenewalOpptyQuoteCreationBatch obj1 = new QTB_APIRenewalOpptyQuoteCreationBatch(successContractSet,failedContractSet,productToUpdateSet,dataHolderAPIObjList[0].Id);
        QTB_APIRenewalOpptyQuoteCreationBatch obj2 = new QTB_APIRenewalOpptyQuoteCreationBatch(successContractSet,failedContractSet,productToUpdateSet,dataHolderAPIObjList[0].Id,1);
        Database.executeBatch(obj1);    
        Database.executeBatch(obj2); 
        Database.BatchableContext bc;
        obj1.execute(bc,contractList);
        Test.stopTest();
    }
    
    /*********************************************************************************************************
* Method Name: QTB_APIRenewalOpptyQuoteCreationBatch_testmethod2
* Requirement: Gitlab US #10330
* Description: This test method provide code coverage for the QTB_APIRenewalOpptyQuoteCreationBatch class
**********************************************************************************************************/     
    static testMethod void QTB_APIRenewalOpptyQuoteCreationBatch_testmethod2(){        
        Set<String> successContractSet = new Set<String>();
        Set<String> failedContractSet = new Set<String>(); 
        List<Contract> contractList = [Select Id, Name,AccountId,SBQQ__RenewalQuoted__c From Contract];
        List<QTB_Data_Holder__c> dataHolderAPIObjList = [Select id From QTB_Data_Holder__c ];
        for(Contract contr: contractList){
            //successContractSet.add(contr.Name);
            failedContractSet.add(contr.Name);
        }       
        List<Product2> prdList = [Select Id from Product2];
        Set<Id> productToUpdateSet = new Set<Id>();
        productToUpdateSet.add(prdList[0].Id);
        
        Test.startTest();
        QTB_APIRenewalOpptyQuoteCreationBatch obj1 = new QTB_APIRenewalOpptyQuoteCreationBatch(successContractSet,failedContractSet,productToUpdateSet,dataHolderAPIObjList[0].Id);
        obj1.wait(100);
        Database.executeBatch(obj1,1);
        
        QTB_APIRenewalOpptyQuoteCreationBatch obj2 = new QTB_APIRenewalOpptyQuoteCreationBatch(successContractSet,failedContractSet,productToUpdateSet,dataHolderAPIObjList[0].Id);
        QTB_APIRenewalOpptyQuoteCreationBatch.throwExplicitException = true; 
        Database.executeBatch(obj2);    
        Test.stopTest();
    }
    
     /*********************************************************************************************************
* Method Name: QTB_APIRenewalOpptyQuoteCreationBatch_testmethod2
* Requirement: Gitlab US #10330
* Description: This test method provide code coverage for the QTB_APIRenewalOpptyQuoteCreationBatch class
**********************************************************************************************************/     
    static testMethod void QTB_APIRenewalOpptyQuoteCreationBatch_testmethod3(){        
        Set<String> successContractSet = new Set<String>();
        Set<String> failedContractSet = new Set<String>(); 
        List<Contract> contractList = [Select Id, Name,AccountId,SBQQ__RenewalQuoted__c From Contract];
        List<QTB_Data_Holder__c> dataHolderAPIObjList = [Select id From QTB_Data_Holder__c ];
        for(Contract contr: contractList){
            //successContractSet.add(contr.Name);
            failedContractSet.add(contr.Name);
        }       
         List<Product2> prdList = [Select Id from Product2];
        Set<Id> productToUpdateSet = new Set<Id>();
        productToUpdateSet.add(prdList[0].Id);
        
        Test.startTest();
        QTB_APIRenewalOpptyQuoteCreationBatch obj1 = new QTB_APIRenewalOpptyQuoteCreationBatch(successContractSet,failedContractSet,productToUpdateSet,dataHolderAPIObjList[0].Id);
        Database.executeBatch(obj1,1);            
        Test.stopTest();
    }
}