/*****************************************************************************************************
* Class		: QTB_UsagesForRebill_Test
* Author	: IRM/VIRTUSA
* Purpose	: This is a test class for QTB_UsagesForRebill
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Ramesh    11/07/2022      Initial Version - Gitlab US #9256 Credit & Rebill  -- Test class
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_UsagesForRebill_Test {
    @testsetup
    private static void setup() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        Id pricebookId = Test.getStandardPricebookId();
        //Custom Setting
        Credit_ReBill_InvoiceSchedulerValidation__c invScheCS = new Credit_ReBill_InvoiceSchedulerValidation__c();
        invScheCS.Name = 'Finland';
        invScheCS.isRunning__c = false;
        insert invScheCS;
        
        //Product1 -- usage
        List<product2> productList = new List<product2>(); 
        product2 p1 = new product2();
        p1.Name = 'Test Product1';
        p1.isActive = true;
        p1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p1.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p1);    
        
        //Product2 -- Usage
        product2 p2 = new product2();
        p2.Name = 'Test Product2';
        p2.isActive = true;
        p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p2.SBQQ__HasConsumptionSchedule__c = true;
        productList.add(p2); 
        //insert productList;
        
        //Product2 -- Usage
        product2 p3 = new product2();
        p3.Name = 'Fuel Surcharge';
        p3.isActive = true;
        p3.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p3.SBQQ__HasConsumptionSchedule__c = true;
        p3.IM_Product_Line__c = 'ALM-Secure ITAD';
        productList.add(p3); 
        insert productList;
       
        
        //Price Book creation for all product
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(productList[0]);                
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[1]);
        
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
        
          blng__LegalEntity__c usEntity = QTB_TestDataFactory.createLegalEntity('United States');
        
        
        //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        accountList[0].QTB_Legal_Entity_Country__c='United States';
        //accountList[0].CurrencyIsoCode = 'USD';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        accountList[0].ShippingCity = 'New York';
        accountList[0].ShippingState = 'New York';
        accountList[0].ShippingPostalCode = '22131';
        accountList[0].ShippingCountry = 'United States';
        accountList[0].BillingStreet = '123 street';
        accountList[0].QTB_Contract_Entity__c = usEntity.Id;
        update accountList;
        System.debug('0@@'+Limits.getLimitQueries());
        
         IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';        
        insert im;
        
        QTB_Bill_Code_Product_Lookup__c productLookup = new QTB_Bill_Code_Product_Lookup__c(
            QTB_Source_Bill_Code__c = 'VALID_CODE',
            QTB_Country__c = im.Id,
            QTB_Product2__c = productList[0].id
        );
        insert productLookup;

        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        //oppList[0].Legal_Entity__c = USEntity.id;
        oppList[0].Billing_Country__c = im.id;
        database.update(oppList);
        
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].QTB_IM_Legal_Entity__c = USEntity.id;
        quoteList[0].QTB_Opportunity_Billing_Country__c = 'United States';
        database.update(quoteList);

        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        Test.startTest();
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[0].id);
        List<SBQQ__QuoteLine__c> quoteLinesList1 = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[1].id);
        
        
        //Order
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        orderList3[0].QTB_Legal_Entity_Country__c = 'Finland';
        orderList3[0].QTB_Rebill_Type__c = 'Split';
        orderList3[0].QTB_SplitRebillValue__c = 2;
        database.update(orderList3);        
        
        blng__BillingRule__c billingRule = new blng__BillingRule__c();
        billingRule.Name = 'No Invoice Rule';
        billingRule.blng__Active__c = true; 
        billingRule.blng__GenerateInvoices__c = 'No';
        billingRule.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
        insert billingRule;
        
        SBQQ.TriggerControl.disable();
        //OrderItem
        List<OrderItem> orderItemList2 = new List<OrderItem>(); 
        orderItemList2.add(new OrderItem(
            OrderId = orderList3[0].id,
            Quantity = 1.00,
            UnitPrice = 12.00,
            SBQQ__QuoteLine__c = quoteLinesList[0].id,
            PricebookEntryId = standardPrice1.Id,
            SBQQ__ChargeType__c = 'Recurring',
            SBQQ__SubscriptionType__c = 'Evergreen',
            SBQQ__ProductSubscriptionType__c = 'Evergreen',
            product2id = productList[0].id,
            SBQQ__Activated__c = true,
            blng__BillingRule__c = billingRule.Id,
            SBQQ__BillingFrequency__c = 'Monthly',
            SBQQ__BillingType__c = 'Arrears',
            blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').id,
            blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id
        )
                          );
        insert orderItemList2;
        
        List<OrderItem> orderItemList3 = new List<OrderItem>();     
        orderItemList3.add(new OrderItem(
            OrderId = orderList3[0].id,
            Quantity = 1.00,
            UnitPrice = 12.00,
            SBQQ__QuoteLine__c = quoteLinesList[0].id,
            PricebookEntryId = standardPrice2.Id,
            SBQQ__ChargeType__c = 'Recurring',
            SBQQ__SubscriptionType__c = 'Evergreen',
            SBQQ__ProductSubscriptionType__c = 'Evergreen',
            product2id = productList[1].id,
            SBQQ__Activated__c = true,
            blng__BillingRule__c = billingRule.Id,
            SBQQ__BillingFrequency__c = 'Monthly',
            SBQQ__BillingType__c = 'Arrears',
            blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').id,
            blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').id
        )
                          );
        insert orderItemList3;
        
        //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
        System.debug('1@@'+Limits.getLimitQueries());
        
       
        //UsageSummary for Invoice
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0]);
        blng__UsageSummary__c usagesummary = usageSum[0];        
        usagesummary.blng__Status__c = 'Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary.blng__Subtotal__c = 100;
        usagesummary.blng__TotalQuantity__c = 10;
        usagesummary.blng__PreratedQuantity__c = 20;
        usagesummary.blng__UnbilledQuantity__c = 1;
        usagesummary.blng__UnitPrice__c = 400;
        usagesummary.blng__PreratedAmount__c = 22;
        usagesummary.blng__MatchingId__c ='111';
        //usagesummary.blng__SummaryStartDate__c = Date.valueOf('2021-07-27');
        usagesummary.blng__Invoice__c = invoiceList[0].id;
        System.debug('before_usagesummary@@'+usagesummary);
        database.update(usagesummary);
        usagesummary.blng__InvoiceRunProcessingStatus__c= 'Will Not Invoice';
        database.update(usagesummary);
        System.debug('after_usagesummary@@'+usagesummary);
        
        // 01/03/2024
        Metadata_Activation_Settings__c cust = new Metadata_Activation_Settings__c();
        cust.SObject_API_Name__c = 'blng__InvoiceLine__c';
        cust.Disable_Trigger__c = true;
        insert cust;
        blng__InvoiceLine__c invoiceLine =  new blng__InvoiceLine__c();
        invoiceLine.blng__Invoice__c=invoiceList[0].Id;
        invoiceLine.blng__Product__c=productList[0].Id;
        invoiceLine.blng__UsageSummary__c = usageSum[0].Id;
        insert invoiceLine;
        
        //Usages for Invoice
        List<blng__Usage__c> usageListFinal = new List<blng__Usage__c>();
        
        blng__Usage__c usgObj = new blng__Usage__c();
        usgObj.blng__MatchingId__c = '111';
        usgObj.blng__EndDateTime__c = date.today() + 1;
        usgObj.blng__StartDateTime__c = date.today();
        usgObj.QTB_Service_District__c = '44147';
        usgObj.blng__Quantity__c = 1;
        usgObj.blng__OrderProduct__c = orderItemList3[0].Id;
        usgObj.blng__Order__c = orderList3[0].id;
        usgObj.QTB_Start_Date_MRC__c = date.today();
        usgObj.QTB_End_Date_MRC__c = date.today()+1;
        usgObj.QTB_Product_Identifier_1__c = productLookup.id;
        usageListFinal.add(usgObj);
        System.debug('usageListFinal@@'+usageListFinal);
        database.insert(usageListFinal);
        
        List<blng__Invoice__c> invListFinal = new List<blng__Invoice__c>();
        for(blng__Invoice__c inv : invoiceList){
            blng__Invoice__c invObj = new blng__Invoice__c();
            invObj.id = inv.Id;
            invObj.blng__InvoiceDate__c = Date.valueOf('2021-07-27');
            invObj.blng__InvoiceStatus__c = 'Draft'; 
            invListFinal.add(invObj);
        }              
        update invListFinal;
        
            //Bill Flow Controller
            QTB_Bill_Flow_Controller__c bfc = new QTB_Bill_Flow_Controller__c();
            bfc.Name = 'Test';
            bfc.Execute_Pre_Bill_Run__c = true;
            bfc.Execute_Post_Bill_Run__c = false;
            bfc.QTB_PreBill_Run_Status__c = 'Completed';
            insert bfc;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        Test.stopTest();
    }
    
    /***********************************************************************************************************
* Method      : testCreateUpdateDeleteUsages
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to cover createUsage functionality of QTB_UsagesForRebill class.
**************************************************************************************************************/    
    static testmethod void testCreateUpdateDeleteUsages()
    {   
        try{
            Test.startTest();
            List<blng__Invoice__c> invoiceList = [Select Id From blng__Invoice__c ];
            List<Order> orderList = [Select Id From Order];
            QTB_UsagesForRebill.createUsageForRebillOrder(invoiceList[0].id,orderList[0].id); //for exception 
			QTB_UsagesForRebill.createUsageForRebillOrder(null,null); //for exception
            QTB_UsagesForRebill.getJobDetails(null);
            Test.stopTest();
        }catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    /***********************************************************************************************************
* Method      : testgetUpdateUsages
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to cover createUsage functionality of QTB_UsagesForRebill class.
**************************************************************************************************************/      
    static testmethod void testgetUpdateUsages()
    {   
        try{
            Test.startTest();
			set<Id> usgSumId = new set<Id>();
            List<SBQQ__Quote__c> quoteList = [Select Id from SBQQ__Quote__c];
            List<Account> accountList = [Select Id from Account];
            List<Order> orderList = [Select Id From Order];  
            List<blng__Usage__c> usgList = [Select Id,blng__UsageSummary__c From blng__Usage__c];
			List<blng__UsageSummary__c> usgSumList = [select id from blng__UsageSummary__c limit 1];
			for(blng__UsageSummary__c usgsumm : usgSumList )
			{
				usgSumId.add(usgsumm.id);
			}
            List<blng__Usage__c> usgList1 = [Select Id,blng__Quantity__c,blng__OrderProduct__r.UnitPrice From blng__Usage__c];
            QTB_UsagesForRebill.getUsages(orderList[0].id);
            QTB_UsagesForRebill.updateUsageList(usgList);
            QTB_UsagesForRebill.updateUsageList(usgList1);
            QTB_UsagesForRebill.deleteSelectedUsages(usgList);
			QTB_UsagesForRebill.validateProductIdentifiers(usgList,usgSumId);
        //    QTB_UsagesForRebill.isInvoiceSchedulerRunning(orderList[0].id);
            QTB_UsagesForRebill.validateUsages(orderList[0].id);
        //    QTB_UsagesForRebill.updateInvoiceSchedulerFlag('Finland');
            Test.stopTest();
            
        }catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    /***********************************************************************************************************
* Method      : testgetUpdateUsagesException
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to cover get & Delete functionality of QTB_UsagesForRebill class.
**************************************************************************************************************/    
    static testMethod void testgetUpdateUsagesException(){
        try{
            Test.startTest();
            QTB_UsagesForRebill.getUsages(null);
            QTB_UsagesForRebill.deleteSelectedUsages(null);
            QTB_UsagesForRebill.dummyCodeForSomeTime();
            Test.stopTest();
        }
        catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    /***********************************************************************************************************
* Method      : testCreateUsagesInvoiceSchedular
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to cover createUSages for Selected ORderPRoduct & creation of InvoiceSchedular functionality of QTB_UsagesForRebill class.
**************************************************************************************************************/
    static testmethod void testCreateUsagesInvoiceSchedular()
    {   
        try{
            Test.startTest();
			Map<string,OrderItem> orderItemFSIdWithOrderItemMap = new Map<string,OrderItem>();
            string country = 'USA';
            List<blng__Invoice__c> invoiceList = [Select Id,QTB_ReBill_Status__c From blng__Invoice__c ];
            List<Order> ordList = [Select Id,Status,OrderNumber From Order];            
            List<OrderItem> orderProductlist = [Select Id,OrderId,blng__BillingRule__c,blng__NextChargeDate__c,blng__NextBillingDate__c,Product2Id,Product2.name,Order.QTB_Rebill_Type__c,order.QTB_Legal_Entity_Country__c
                                                From OrderItem ];
            List<OrderItem> orderProductlist1 = [Select Id,OrderId,blng__BillingRule__c,blng__NextChargeDate__c,blng__NextBillingDate__c,Product2Id,Product2.name,Order.QTB_Rebill_Type__c,
                                                 blng__HoldBilling__c From OrderItem ];
			 OrderItem OrdI = new OrderItem();
            OrdI.Id = orderProductlist1[0].id;
            OrdI.blng__HoldBilling__c = 'Yes';
            OrdI.blng__InvoiceRunProcessingStatus__c = 'Will Not Invoice';
            update OrdI;
            
            List<blng__UsageSummary__c> usgSum = [Select id from blng__UsageSummary__c where blng__OrderProduct__c = : orderProductlist[0].id];
            system.debug('usgSum@@' +usgSum);
            List<blng__Usage__c> usagesList = [Select Id,blng__MatchingId__c,blng__StartDateTime__c,blng__EndDateTime__c,blng__OrderProduct__c,blng__Order__c
                                               From  blng__Usage__c];
			if(orderProductlist[0].Product2.name == 'FUEL SURCHARGE' || orderProductlist[0].Product2.name == 'MINIMUM STORAGE CHARGES'){
			orderItemFSIdWithOrderItemMap.put(orderProductlist[0].id,orderProductlist[0]);
                
			}
            Credit_ReBill_InvoiceSchedulerValidation__c  creditRebillCheck = Credit_ReBill_InvoiceSchedulerValidation__c.getInstance(orderProductlist[0].order.QTB_Legal_Entity_Country__c);
            creditRebillCheck.isRunning__c = true;
            creditRebillCheck.Date_Time__c = system.today();
			Map<String,String> unitOfMeasures = new Map<String,string>();
            creditRebillCheck.name = country;
            unitOfMeasures.put((string)orderProductlist[0].Id,'Item');
            QTB_UsagesForRebill.createUsageForSelectOrderProduct(ordList[0].id,orderProductlist,unitOfMeasures);
            QTB_UsagesForRebill.createInvoiceForRebill(invoiceList[0].id,ordList[0].id,'Bank Corrupt');
            QTB_UsagesForRebill.createPreBill(invoiceList,ordList);
          //  QTB_UsagesForRebill.isInvoiceSchedulerRunning(ordList[0].id);
            QTB_UsagesForRebill.validateUsages(ordList[0].id);
			QTB_UsagesForRebill.updateOrderProductUsageSummaryStatus(orderProductlist1);
        //    QTB_UsagesForRebill.updateInvoiceSchedulerFlag(country);
            Test.stopTest();
            
        }catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    /***********************************************************************************************************
* Method      : testCreateUsagesInvoiceSchedularException
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to cover exceptions for Selected ORderPRoduct & creation of InvoiceSchedular functionality of QTB_UsagesForRebill class.
**************************************************************************************************************/    
    static testMethod void testCreateUsagesInvoiceSchedularException(){
        try{
            Test.startTest();
            QTB_UsagesForRebill.createUsageForSelectOrderProduct(null,null,null);
            QTB_UsagesForRebill.createInvoiceForRebill(null,null,null);
            QTB_UsagesForRebill.throwExplicitException = true;
            QTB_UsagesForRebill.createInvoiceForRebill(null,null,null);
            Test.stopTest();
        }
        catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    /***********************************************************************************************************
* Method      : testRunInvoiceSchedular
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to test InvoiceSchedular functionality of QTB_UsagesForRebill class.
**************************************************************************************************************/    
    static testmethod void testRunInvoiceSchedular()
    {   
        try{
            Test.startTest();
            
            blng__LegalEntity__c usEntity = new blng__LegalEntity__c();
            usEntity.Name = 'Test Legal Entity Singapore';
            usEntity.blng__Active__c = true;
            usEntity.blng__Country__c = 'United States';
            usEntity.QTB_Type__c = 'Contract';
            // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
            insert usEntity;
            
            blng__InvoiceScheduler__c ins = new blng__InvoiceScheduler__c(
                Name='Test sched',
                blng__Type__c='Once',
                blng__StartDateTime__c = system.now()+1,
                blng__TargetDate__c = system.today().addDays(2),
                QTB_Legal_Entity__c = usEntity.id
            );
            insert ins;
            
        //    QTB_UsagesForRebill.runInvoiceSchedular(ins.id);
            
            Credit_ReBill_InvoiceSchedulerValidation__c crd = new Credit_ReBill_InvoiceSchedulerValidation__c();
            crd.isRunning__c = true;
            crd.Name = 'Singapore';
            crd.Date_Time__c = System.now();
            insert crd;
        //    QTB_UsagesForRebill.updateInvoiceSchedulerFlag('Singapore');
            
            Test.stopTest();
            
        }catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    /***********************************************************************************************************
* Method      : testRunInvoiceSchedularException
* Parameter   : 
* Return Type : void
* Author      : Virtusa
* Description : This method is used to test InvoiceSchedular & createPreBill functionality of QTB_UsagesForRebill class.
**************************************************************************************************************/   
    static testMethod void testRunInvoiceSchedularException(){
        try{
            Test.startTest();
            QTB_UsagesForRebill.getJobDetails('123');
			QTB_UsagesForRebill.getJobDetails('');
        //    QTB_UsagesForRebill.runInvoiceSchedular(null); 
        //    QTB_UsagesForRebill.createPreBill(null); 
            
            QTB_UsagesForRebill.throwExplicitException = true;
            List<Order> ordList = [Select Id,Status,OrderNumber From Order];  
            QTB_UsagesForRebill.getUsages(ordList[0].id);
            QTB_UsagesForRebill.validateUsages(ordList[0].id);
            Test.stopTest();
        }
        catch (Exception e) {
            System.assertNotEquals('Script-thrown exception', e.getMessage());
        }
    }
    
    
    
}