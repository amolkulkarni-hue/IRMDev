/*****************************************************************************************************
* Class			: QTB_APICreateSalesOrderBatch_Test
* Author		: IRM/Virtusa
* Purpose	 	: To Cover all API related apex class testing 
: Provide Code Coverage for QTB_APICreateSalesOrderBatch
* Requirement	: Gitlab US #10331, #10329,12040 
* Developer                Date            Description
* -----------------------------------------------------------------------------------------------------
* Shailesh       		12/25/2022       Gitlab US #10331, #10329,12040
*******************************************************************************************************/
@isTest(seealldata=false)
public class QTB_APICreateSalesOrderBatch_Test {
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
        
        //Prepared CSV File Data
        string FileData = 'Subscription ID,Start Date,End Date,Contract Number,Account ID,Account Name,Product Line,Product Id,Product Code,Bill Code,Product Name,Billing Type,Subscription Consumption Schedule Name,Subscription Consumption Rate ID,Subscription Consumption Rate Name,API Lower Bound,API Upper Bound,Currency,API Price,New Price\n';
        string subData1 = '0017b00000yNFny'+',10/14/2022,10/13/2023,'+'FIN-22-00077605'+',0017b00000yNFny,Finland_SalesAccount1,Products,'+productList[0]+',01100-0341,01100-0341,Retrieval unregistered document add-on fee,Arrears,List,aI97b0000008QFl,'+'R-1234'+',1,10,EUR,10,11\n';
        FileData = FileData + subData1;
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
* Method Name: QTB_APICreateSalesOrderBatch_testmethod1
* Requirement: Gitlab US #10330
* Description: This test method provide code coverage for the QTB_APICreateSalesOrderBatch class
**********************************************************************************************************/  
    static testMethod void QTB_APICreateSalesOrderBatch_testmethod1(){   
        Set<String> successContractSet = new Set<String>();
        Set<String> failedContractSet = new Set<String>(); 
        List<Contract> contractList = [Select Id, Name,AccountId,SBQQ__Order__c From Contract limit 1];
      	List<QTB_Data_Holder__c> dataHolderAPIObjList = [Select id From QTB_Data_Holder__c ];
        List<Opportunity> OpportunityList = [Select Id From Opportunity Limit 1 ];
        
        
        Test.startTest();   
        for(Contract contr: contractList){
            successContractSet.add(contr.Name);
            failedContractSet.add(contr.Name);
        }       
          
        Set<Id> oppIdSet = new Set<Id>();
        oppIdSet.add(OpportunityList[0].Id);
        QTB_APICreateSalesOrderBatch obj1 = new QTB_APICreateSalesOrderBatch(successContractSet,failedContractSet,oppIdSet,dataHolderAPIObjList[0].Id);        
        obj1.wait(1);
        Database.executeBatch(obj1);        
        QTB_APICreateSalesOrderBatch.codeCoverage();
        QTB_APICreateSalesOrderBatch obj2 = new QTB_APICreateSalesOrderBatch(null,failedContractSet,oppIdSet,dataHolderAPIObjList[0].Id,1);
        Database.executeBatch(obj2); 
        
        QTB_APICreateSalesOrderBatch obj3 = new QTB_APICreateSalesOrderBatch(successContractSet,failedContractSet,oppIdSet,dataHolderAPIObjList[0].Id,1);
        Database.executeBatch(obj3);
        
        Database.BatchableContext bc;
        List<SBQQ__Quote__c> quoteList = [SElect Id,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name From SBQQ__Quote__c ];
        obj1.execute(bc,quoteList);
        Test.stopTest();
    }
   
    /*********************************************************************************************************
* Method Name: QTB_APICreateSalesOrderBatch_testmethod2
* Requirement: Gitlab US #10330
* Description: This test method provide code coverage for the QTB_APICreateSalesOrderBatch class
**********************************************************************************************************/      
    public static void QTB_APICreateSalesOrderBatch_testmethod2(){
        Set<String> successContractSet = new Set<String>();
        Set<String> failedContractSet = new Set<String>(); 
        List<QTB_Data_Holder__c> dataHolderAPIObjList = [Select id From QTB_Data_Holder__c ];
        QTB_APICreateSalesOrderBatch obj2 = new QTB_APICreateSalesOrderBatch(successContractSet,failedContractSet,null,dataHolderAPIObjList[0].Id);
        QTB_APICreateSalesOrderBatch.throwExplicitException = true;
        Database.executeBatch(obj2); 
    }
}