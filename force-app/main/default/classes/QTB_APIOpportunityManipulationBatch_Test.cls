/*****************************************************************************************************
* Class			: QTB_APIOpportunityManipulationBatch_Test
* Author		: IRM/Virtusa
* Purpose	 	: 
* Requirement	: Gitlab 
* Developer                Date            Description
* ------------------------------------------------------------------------------------------- 
* Pawan       		07/12/2021       
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_APIOpportunityManipulationBatch_Test {
    
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
        
        Id pricebookId = Test.getStandardPricebookId();
        
        blng__BillingRule__c renewoppproductbillingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c renewoppproductrevenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c renewoppproducttaxRule = QTB_TestDataFactory.createTaxRule('Yes');
        List<product2> renewoppproduct = QTB_TestDataFactory.createProducts(1);
        renewoppproduct[0].Name = 'Test Product Sample';
        renewoppproduct[0].SBQQ__SubscriptionTerm__c = 10;
        renewoppproduct[0].SBQQ__SubscriptionTerm__c = 4;
        renewoppproduct[0].SBQQ__SubscriptionPricing__c = 'Fixed Price';
        renewoppproduct[0].ProductCode = '01100-1000';
        renewoppproduct[0].blng__BillingRule__c = renewoppproductbillingRule.id;
        renewoppproduct[0].blng__RevenueRecognitionRule__c = renewoppproductrevenueRule.id;
        renewoppproduct[0].blng__TaxRule__c = renewoppproducttaxRule.id;
        update renewoppproduct[0];
        
        //Custom Setting: Adding SVStatus__c data 
        SVStatus__c sv = new SVStatus__c();
        sv.name = 'SVStatusPassed';
        sv.Amount__c = 0;
        sv.Stage__c = '2 - Solution Developed';
        sv.OpptType__c = 'Up-Sell/Lift,New Deal';
        insert sv;
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1);
        List<Opportunity> oppList = QTB_TestDataFactory.createCPQOppsNew(
            accountList,
            'CPQ Sales Opportunity'
        );
        oppList[0].stageName ='1 - Qualification';
        oppList[0].Primary_Product_Line__c = 'Records Management';
        oppList[0].IME_Reason_Won__c = 'Value';
        update oppList;
        opportunity opp = new opportunity(
            Name = 'Billing Opportunity',
            AccountId = accountList[0].Id,
            CloseDate = Date.today(),
            StageName = '1 - Qualification'
        );
        insert opp;
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
            1,
            oppList[0].id,
            oppList[0].accountId,
            true,
            null
        );
        quoteList[0].SBQQ__Status__c = QTB_Constants.APPROVED_STATUS;
        update quoteList;
        
        oppList[0].SBQQ__PrimaryQuote__c = quoteList[0].id;
        update oppList;
        Test.startTest();
        List<Order> testOrders = QTB_TestDataFactory.createCPQOrders(
            1,
            quoteList[0].id,
            accountList[0].id
        );
        List<Contract> testContracts = QTB_TestDataFactory.createCPQContracts(
            1,
            testOrders[0].id,
            accountList[0].id,
            quoteList[0].id
        );
        testContracts[0].SBQQ__Opportunity__c = oppList[0].Id;
        testContracts[0].RecordTypeId = QTB_Utils.CONTRACT_SALES_RECTYPEID;
        update testContracts;
        
        List<Opportunity> testRenewOpps = QTB_TestDataFactory.createRenewalOpps(
            accountList,
            testContracts[0].id,
            'CPQ Sales Opportunity'
        );
        testRenewOpps[0].stageName ='1 - Qualification';
        testRenewOpps[0].QTB_Deferred_Renewal_Opportunity__c = true;
        testRenewOpps[0].IME_Reason_Won__c = 'Value';
        update testRenewOpps;
        testRenewOpps[0].IM_Parent_Opportunity__c = oppList[0].id;
        testRenewOpps[0].SBQQ__RenewedContract__c = testContracts[0].Id;
        update testRenewOpps;
        
        PricebookEntry renewoppproductstandardpricebook = QTB_TestDataFactory.createPricebookEntry(renewoppproduct[0]);
        OpportunityLineItem oppProd = new OpportunityLineItem(Quantity = 12, PricebookEntryId = renewoppproductstandardpricebook.Id, OpportunityId =testRenewOpps[0].Id, unitPrice = 1,Product_Class__c ='Records Management',Product_Line__c='storage');
        insert oppProd;
        System.debug('Reached@@');
        Test.stopTest();
    }
    static testMethod void testmethod2(){
        Test.startTest();
        List<Contract> contractList = [SELECT id,Name, SBQQ__RenewalQuoted__c,SBQQ__RenewalOpportunity__c FROM Contract ];
        list<SBQQ__Quote__c> QtsList = [select id,SBQQ__Opportunity2__r.Name,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Order__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name from SBQQ__Quote__c where SBQQ__Quote__c.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.id = :contractList[0].id];
        list<opportunity> opptylist = [Select id,Name,SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.Name from opportunity where SBQQ__RenewedContract__r.id = :contractList[0].id];

        System.debug('opptylist[0].SBQQ__RenewedContract__r.Name'+opptylist[0].SBQQ__RenewedContract__r.Name);
        List<ContentDocument> fileList = [SELECT Id,Title,ContentSize,FileType,Owner.Name,createdDate,Division,Description
                                          FROM ContentDocument ]; 
        
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
        Set<String> SuccessContract  = new Set<String>();
        SuccessContract.add(opptylist[0].SBQQ__RenewedContract__r.Name);
        System.debug('SuccessContract'+SuccessContract);
        
        Set<String> FailContract  = new Set<String>();
        FailContract.add(opptylist[0].SBQQ__RenewedContract__r.Name);
        System.debug('FailContract'+FailContract);
        
        QTB_APIOpportunityManipulationBatch apiQuote = new QTB_APIOpportunityManipulationBatch(SuccessContract,FailContract,dataHolderAPIObjList[0].id);
        database.executeBatch(apiQuote);

        Test.stopTest();
    }
    
    
    static testMethod void testmethod3(){
        Test.startTest();
        
        List<Contract> contractList = [SELECT id,Name, SBQQ__RenewalQuoted__c,SBQQ__RenewalOpportunity__c FROM Contract ];
        list<SBQQ__Quote__c> QtsList = [select id,SBQQ__Opportunity2__r.Name,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Order__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name from SBQQ__Quote__c where SBQQ__Quote__c.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.id = :contractList[0].id];
        list<opportunity> opptylist = [Select id,Name,SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.Name,GSA_Eligibility__c,IME_Reason_Won__c,US_Federal_GSA_Pricing__c,RecordType.DeveloperName,StageName from opportunity where SBQQ__RenewedContract__r.id!=null LIMIT 1];
        System.debug('opptylist@@'+opptylist);
        opptylist[0].GSA_Eligibility__c = 'GSA Eligible';
        opptylist[0].IME_Reason_Won__c = 'Value';
        opptylist[0].US_Federal_GSA_Pricing__c = 'No';
        update opptylist[0];
        
        
        List<ContentDocument> fileList = [SELECT Id,Title,ContentSize,FileType,Owner.Name,createdDate,Division,Description
                                          FROM ContentDocument ]; 
        
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
        Set<String> SuccessContract  = new Set<String>();
        SuccessContract.add(opptylist[0].SBQQ__RenewedContract__r.Name);
        
        Set<String> FailContract  = new Set<String>();

        
        QTB_APIOpportunityManipulationBatch apiQuote = new QTB_APIOpportunityManipulationBatch(SuccessContract,FailContract,dataHolderAPIObjList[0].id);
        database.executeBatch(apiQuote);
        System.debug('FailContract@@'+FailContract);
        System.debug('SuccessContract@@'+SuccessContract);
        Test.stopTest();
    }
    static testMethod void testmethod4(){
        Test.startTest();
        List<Contract> contractList = [SELECT id,Name, SBQQ__RenewalQuoted__c,SBQQ__RenewalOpportunity__c FROM Contract ];
        list<SBQQ__Quote__c> QtsList = [select id,SBQQ__Opportunity2__r.Name,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Order__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name from SBQQ__Quote__c where SBQQ__Quote__c.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.id = :contractList[0].id];
        list<opportunity> opptylist = [Select id,Name,SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.Name from opportunity where SBQQ__RenewedContract__r.id = :contractList[0].id];
        List<ContentDocument> fileList = [SELECT Id,Title,ContentSize,FileType,Owner.Name,createdDate,Division,Description
                                          FROM ContentDocument ]; 
        
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
        Set<String> SuccessContract  = new Set<String>();
        
        Set<String> FailContract  = new Set<String>();
        FailContract.add(opptylist[0].SBQQ__RenewedContract__r.Name);
        
        QTB_APIOpportunityManipulationBatch apiQuote = new QTB_APIOpportunityManipulationBatch(SuccessContract,FailContract,dataHolderAPIObjList[0].id);
        database.executeBatch(apiQuote);
        Test.stopTest();
    }
    static testMethod void testmethod5(){
        Test.startTest();
        List<Contract> contractList = [SELECT id,Name, SBQQ__RenewalQuoted__c,SBQQ__RenewalOpportunity__c FROM Contract ];
        list<SBQQ__Quote__c> QtsList = [select id,SBQQ__Opportunity2__r.Name,SBQQ__Opportunity2__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Order__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__c,SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.Name from SBQQ__Quote__c where SBQQ__Quote__c.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.id = :contractList[0].id];
        list<opportunity> opptylist = [Select id,Name,SBQQ__RenewedContract__c,SBQQ__RenewedContract__r.Name from opportunity where SBQQ__RenewedContract__r.id = :contractList[0].id];
        List<ContentDocument> fileList = [SELECT Id,Title,ContentSize,FileType,Owner.Name,createdDate,Division,Description
                                          FROM ContentDocument ]; 
        
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
        Set<String> SuccessContract  = new Set<String>();
        
        Set<String> FailContract  = new Set<String>();
        FailContract.add(opptylist[0].SBQQ__RenewedContract__r.Name);
        
        QTB_APIOpportunityManipulationBatch apiQuote = new QTB_APIOpportunityManipulationBatch(SuccessContract,FailContract,dataHolderAPIObjList[0].id);
        QTB_APIOpportunityManipulationBatch.throwExplicitException = true;
        database.executeBatch(apiQuote);
        Test.stopTest();
    }
}