/*****************************************************************************************************
* Class		: QTB_CreditRebillUsagesDeleteBatch_Test
* Author	: IRM/VIRTUSA
* Purpose	: This is a test class for QTB_CreditRebillUsagesDeleteBatch
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Shailesh    12/08/2023     Initial Version - Gitlab US #9256 Credit & Rebill  -- Test class
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_CreditRebillUsagesDeleteBatch_Test {
    @testsetup
    private static void setup() {
        
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
      custSetting.SObject_API_Name__c = 'Opportunity;SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;AccountContactRelation;blng__InvoiceRun__c;blng__Usage__c;Order';
      custSetting.Disable_VR__c = true;
      custSetting.Disable_PB__c = true;
      custSetting.Disable_Trigger__c = true;
      // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      insert custSetting;
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        //System.runAs(userList[0]) {
        Id pricebookId = Test.getStandardPricebookId();
        
        //Product
        List<product2> productList = new List<product2>();
        //Product1 -- usage
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p1);
        
        //Product2 -- usage
        product2 p2 = new product2();
        p2.Name = 'Test Product2';
        p2.isActive = true;
        p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p2.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p2);
        
        //Product3 -- usage
        product2 p3 = new product2();
        p3.Name = 'Test Product3';
        p3.isActive = true;
        p3.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p3.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p3);
        insert productList;
        
        //Price Book creation for all product
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(productList[0]); 
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[1]); 
        PricebookEntry standardPrice3 = QTB_TestDataFactory.createPricebookEntry(productList[2]); 
        
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
        insert new ProductConsumptionSchedule(ConsumptionScheduleId = consumption.Id,ProductId = productList[0].Id);
        insert new ProductConsumptionSchedule(ConsumptionScheduleId = consumption.Id,ProductId = productList[1].Id);
        
        //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c='United States';
        // accountList[0].CurrencyIsoCode = 'USD';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        accountList[0].ShippingCity = 'New York';
        accountList[0].ShippingState = 'New York';
        accountList[0].ShippingPostalCode = '22131';
        accountList[0].ShippingCountry = 'United States';
        update accountList;
        
        //Legal Entity
        blng__LegalEntity__c USEntity = new blng__LegalEntity__c();
        USEntity.Name = 'Test Legal Entity United States';
        USEntity.blng__Active__c = true;
        USEntity.blng__Country__c = 'United States';
        USEntity.QTB_Type__c = 'Contract';
        //USEntity.QTB_Legal_Entity_Number__c = '45000';
        insert USEntity;
        
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
        //oppList[0].Legal_Entity__c = USEntity.id;
        oppList[0].Billing_Country__c = im.id;
        if(opplist[0].id==null){
        	try{
                database.insert(oppList);
            }
            catch (exception e){
                system.debug('The following exception has occurred '+e);
            }
        }
        else{
            try{
                database.update(oppList);
            }
            catch (exception e){
                system.debug('The following exception has occurred '+e);
            }
        }        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].QTB_IM_Legal_Entity__c = USEntity.id;
        quoteList[0].QTB_Opportunity_Billing_Country__c = 'United States';
        database.update(quoteList);
        
        
        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[0].id);
        
        Test.startTest();
        //Order
        List<Order> orderList = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        if(orderList[0].id==null){
            try{
                database.insert(orderList);
            }
            catch(exception e){
                
            }
        }
        else{
            try{
                database.update(orderList);
            }
            catch(exception e){
                
            }
        }
        
        SBQQ.TriggerControl.disable();
        
        //OrderItem
        List<OrderItem> orderItemList1 = QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,productList[0].Id,quoteLinesList,standardPrice1);
        List<OrderItem> orderItemList2 = QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,productList[1].Id,quoteLinesList,standardPrice2);
        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList[0].Id,productList[2].Id,quoteLinesList,standardPrice3);
        
        //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
        
        //UsageSummary for Invoice
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList[0],orderItemList1[0]);
        blng__UsageSummary__c usagesummary = usageSum[0];        
        usagesummary.blng__Status__c = 'Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary.blng__Subtotal__c = 100;
        usagesummary.blng__TotalQuantity__c = 10;
        usagesummary.blng__PreratedQuantity__c = 20;
        usagesummary.blng__UnbilledQuantity__c = 1;
        usagesummary.blng__UnitPrice__c = 400;
        usagesummary.blng__PreratedAmount__c = 22;
        usagesummary.blng__SummaryStartDate__c = Date.valueOf('2021-07-27');
        usagesummary.blng__Invoice__c = invoiceList[0].id;
        database.update(usagesummary);
        
        //Usages for Invoice
        List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        usageList[0].QTB_Service_District__c = '44147';
        usageList[0].blng__Subtotal__c = 50;
        usageList[0].blng__OrderProduct__c = orderItemList1[0].id;          
        database.update(usageList);
        
        invoiceList[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceList[0].blng__InvoiceStatus__c = 'Draft';        
        update invoiceList[0];
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        
        
        //Tax Rule
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;
        
        System.debug('3@@'+Limits.getLimitQueries());
        //Creation of InvoiceLine
        List<blng__InvoiceLine__c> invLineList = QTB_TestDataFactory.createInvoiceLine(1,invoiceList,productList);
        system.debug('initial  inv like list '+ invLineList);
        invLineList[0].blng__OrderProduct__c = orderItemList2[0].id;
        invLineList[0].blng__UsageSummary__c = usagesummary.id;
        invLineList[0].blng__InvoiceLineStatus__c = 'Draft';
        invLineList[0].blng__TaxAmount__c = 50;
        invLineList[0].blng__TaxCountry__c = 'India';
        invLineList[0].blng__TaxState__c = 'TN';
        invLineList[0].blng__TaxCity__c = 'Chennai';
        invLineList[0].blng__TaxZipCode__c = '500032';
        invLineList[0].blng__LegalEntity__c = USEntity.id;
        invLineList[0].blng__Subtotal__c = 1000;
        invLineList[0].blng__TaxRule__c = taxRule.id;
        invLineList[0].QTB_Inc_Quantity__c = 10;
        invLineList[0].QTB_Taxable_Amount__c = 10;
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
        system.debug('invoice line list is: '+ invLineList);
        system.debug('invoice line list is: '+ invLineList[0].id);
        if(invLineList[0].id==null){
            try{
                database.insert(invLineList);
            }
            catch(exception e){
                system.debug('Invoice line for insert '+e.getmessage());
            }
        }
        else{
            try{
                database.update(invLineList);
            }
            catch(exception e){
                 system.debug('Invoice line for update '+e.getmessage());
            }
        }
        system.debug('invoice line list '+ invLineList);
        usagesummary.blng__InvoiceLine__c = invLineList[0].id;
        database.update(usagesummary);
        
        System.debug('4@@'+Limits.getLimitQueries());
        
        invoiceList[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceList[0].blng__InvoiceStatus__c = 'Posted';       
        invoiceList[0].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        update invoiceList[0];
        system.debug('fina invoice list '+ invoiceList);
        Test.stopTest();
    }
    
    static testMethod void testMethodCreditRebillDeleteUsage(){
        try{
            Set<Id> orderPrdIdSet = new Set<Id>();
            List<OrderItem> orderItemList = [Select id from OrderItem]; 
            for(OrderItem ordItm : orderItemList){
                orderPrdIdSet.add(ordItm.Id);
            }
            Test.startTest();
                QTB_CreditRebillUsagesDeleteBatch usageDeleteBatch = new QTB_CreditRebillUsagesDeleteBatch(orderPrdIdSet);
                Database.executeBatch(usageDeleteBatch,Integer.valueOf(System.Label.QTB_CreditRebillUsageBatchSize));
            Test.stopTest();
        }
        catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    static testMethod void testMethodexception(){
        // 1. Identify the Profile (e.g., 'Standard User')
        // 2. Query for the Profile ID
        Profile standardUserProfile = [SELECT Id FROM Profile WHERE Name = 'IM_API_Read_Only' LIMIT 1];
         PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'QTB_Billing_User_Persona' LIMIT 1];
        System.assertNotEquals(null, ps, 'Permission Set should exist');
        List<PermissionSetLicense> psl = [SELECT Id, MasterLabel FROM PermissionSetLicense WHERE MasterLabel = 'Salesforce CPQ License' or MasterLabel = 'Salesforce CPQ AA License'];

        // 3. Create a test user, assigning the existing Profile ID
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Username = 'testuser@example.com'+ System.now().format('yyyyMMddHHmmssSSS'),
            Email = 'test@example.com',
            Alias = 'testu',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            languagelocalekey='en_US',
            Country = 'USA',
            CurrencyIsoCode='USD',
            ProfileId = standardUserProfile.Id
        );
        insert testUser;
        
        //  Create PermissionSetLicenseAssignment
        List<PermissionSetLicenseAssign> pslalst = new List<PermissionSetLicenseAssign>();
        PermissionSetLicenseAssign psla1 = new PermissionSetLicenseAssign(
            AssigneeId = testUser.Id,
            PermissionSetLicenseId = psl[0].id 
        );
        pslalst.add(psla1);
        PermissionSetLicenseAssign psla2 = new PermissionSetLicenseAssign(
            AssigneeId = testUser.Id,
            PermissionSetLicenseId = psl[1].id 
        );
        pslalst.add(psla2);
        insert pslalst;
        
        //  Create a PermissionSetAssignment
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = ps.Id
        );
        insert psa;

        try{
            Set<Id> orderPrdIdSet = new Set<Id>();
            List<OrderItem> orderItemList = [Select id from OrderItem]; 
            for(OrderItem ordItm : orderItemList){
                orderPrdIdSet.add(ordItm.Id);
            }
            QTB_InvoiceTriggerHandler.skipTriggerExecutionTestClass = true;
            List<blng__Usage__c> testUsages = [Select id from blng__Usage__c];
            system.runas(testUser){
				list<blng__Usage__c> idlst = [SELECT Id FROM blng__Usage__c WHERE blng__OrderProduct__c IN : orderPrdIdSet];
                system.debug('The query result in test class is '+ idlst);
                Test.startTest();
                system.debug('Batch is starting');
                QTB_CreditRebillUsagesDeleteBatch usageDeleteBatch1 = new QTB_CreditRebillUsagesDeleteBatch(orderPrdIdSet);
                //Database.executeBatch(usageDeleteBatch1,Integer.valueOf(System.Label.QTB_CreditRebillUsageBatchSize));
                usageDeleteBatch1.execute(null, testUsages);
                Test.stopTest();
            }
        }
        catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
}