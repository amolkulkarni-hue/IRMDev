/*****************************************************************************************************
* Class			: QTB_InvoiceRun_Test
* Purpose		: This is a Test Class used to test QTB_InvoiceRunTrigger, QTB_InvoiceRunTriggerHandler, QTB_InvoiceRunHelper
* Requirement	: Gitlab #
* Author		: IRM/Virtusa
* Developer 	: Gopi/Shailesh
* Change History: 07/07/2021
* Developer       			Date            	Description 
* ------------------------------------------------------------------------------------------- 
*    
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_InvoiceRun_Test {
    
    @testSetup
    static void setup() {
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
      custSetting.SObject_API_Name__c = 'SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;AccountContactRelation;blng__Usage__c;blng__UsageSummary__c;order;OrderItem;Opportunity;blng__InvoiceLine__c;blng__CreditNote__c';
      custSetting.Disable_VR__c = true;
      custSetting.Disable_PB__c = true;
      custSetting.Disable_Trigger__c = true;
      // custSetting.SetupOwnerId = UserInfo.getOrganizationId();
      insert custSetting;
        // List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        // System.runAs(userList[0]) {
        Id pricebookId = Test.getStandardPricebookId();
        List<product2> product = QTB_TestDataFactory.createProducts(1);
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        //accountList[0].QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
        accountList[0].QTB_Legal_Entity_Country__c='United States';
        //accountList[0].CurrencyIsoCode = 'USD';
        update accountList;
        

           blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
		usaEntity.Name = 'Test Legal Entity United States';
		usaEntity.blng__Active__c = true;
		usaEntity.blng__Country__c = 'United States';
		usaEntity.QTB_Type__c = 'Contract';
		// indiaEntity.QTB_Legal_Entity_Number__c = '45000';
		insert usaEntity;        
		
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        //oppList[0].recordtypeid = QTB_Utils.OPP_BILL_RECTYPEID;
        oppList[0].Pricebook2Id = pricebookId;
        database.update(oppList);
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        //quoteList[0].recordtypeId = QTB_Utils.QUOTE_BILL_RECTYPEID;
        database.update(quoteList);
        Test.startTest();
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
		//orderList3[0].OrderNumber = '123';
       // orderList3[0].blng__InvoiceBatch__c = 'United States-DM-1st-EOM Manual';
	    orderList3[0].bling_Legal_Entity__c =  usaEntity.id ; 
        database.update(orderList3);
        SBQQ.TriggerControl.disable();
        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].Id,quoteLinesList,standardPrice);
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0]);
        blng__UsageSummary__c usagesummary = usageSum[0];
        
        usagesummary.blng__Status__c = 'New';
        usagesummary.blng__MatchingId__c = '0002449102100-0446';
        usagesummary.blng__SummaryStartDate__c = Date.valueOf('2021-08-01');
        usagesummary.blng__SummaryEndDate__c = Date.valueOf('2021-08-31');
        usagesummary.blng__NextBillingDate__c = Date.valueOf('2021-09-01');
        //usagesummary.blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
        
        database.update(usagesummary);
        
        List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
        usageList[0].blng__MatchingId__c = '0002449102100-0446';
        usageList[0].blng__Status__c = 'New';
        usageList[0].blng__StartDateTime__c = Date.valueOf('2021-08-01');
        usageList[0].blng__EndDateTime__c = Date.valueOf('2021-08-03');
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        usageList[0].QTB_Service_District__c = '44147';
        usageList[0].blng__UsageSummary__c = usageSum[0].id;
        usageList[0].blng__Order__c = orderList3[0].id;
        usageList[0].blng__OrderProduct__c = orderItemList3[0].id;          
        database.update(usageList);
        
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity('India');
        
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
        
	  
		
        
        blng__InvoiceScheduler__c schedule = new blng__InvoiceScheduler__c();
        schedule.Name = 'test';
        schedule.blng__Type__c = 'Once';
        //schedule.blng__InvoiceBatches__c = 'United States-DM-1st-EOM Manual';
        schedule.CurrencyIsoCode = 'USD';
        schedule.blng__StartDateTime__c = System.now();
        schedule.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        schedule.blng__TargetDate__c = Date.valueOf('2021-09-01');
		schedule.QTB_Legal_Entity__c = usaEntity.id ;
        
        insert schedule;
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'Rebill Invoice For Order '+orderList3[0].OrderNumber;
        invoiceRun.blng__InvoiceScheduler__c = schedule.id;
        invoiceRun.blng__Status__c = 'Started';
        invoiceRun.blng__StartTime__c = System.now(); 
        invoiceRun.blng__InvoiceDate__c = Date.valueOf('2021-08-01');
        invoiceRun.blng__TargetDate__c = Date.valueOf('2021-09-01');
        insert invoiceRun;
		
		blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[0].Id;
        invoice.blng__InvoiceStatus__c = 'Draft';
		invoice.blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        //invoice.RecordTypeId=QTB_Utils.INVOICE_DRAFT_RECTYPEID;
        insert invoice;
        Test.stopTest();
        //}
    }
    
    static testMethod void testMethod1(){
        List<blng__InvoiceRun__c> invoiceRunList = [Select id, Name,blng__Status__c,blng__TargetDate__c From blng__InvoiceRun__c where Name like 'Rebill Invoice For Order %' ];
        invoiceRunList[0].blng__Status__c = 'Completed with errors';
        update invoiceRunList;
        Map<Id, blng__InvoiceRun__c>invoiceRunOldMap = new Map<Id, blng__InvoiceRun__c>();
        for(blng__InvoiceRun__c run : invoiceRunList){
            invoiceRunOldMap.put(run.id,run); 
        }
        List<OrderItem> orderItemList = [SELECT Id, OrderId,blng__HoldBilling__c, Order.AccountId,Order.Account.QTB_Hold_Billing__c
                                         FROM OrderItem];
        List<QTB_Tax_Integration_Setting__mdt> mtd = [Select id,QTB_Country__c, QTB_End_System__c, QTB_Product_Line__c FROM QTB_Tax_Integration_Setting__mdt where Label = 'Vertex Integration'];
        QTB_InvoiceRunHelper.vertexTaxCallOut(invoiceRunList,invoiceRunOldMap);
     //   QTB_InvoiceRunHelper.updateInvoiceSchedulerCustomSettingFlag(invoiceRunList,invoiceRunOldMap);
    }
    
    static testMethod void testMethod2(){
        List<blng__InvoiceRun__c> invoiceRunList = [Select id, Name,blng__Status__c,blng__TargetDate__c From blng__InvoiceRun__c where Name like 'Rebill Invoice For Order %' ];
		List<Order> OrdersList = [SELECT Id,OrderNumber, QTB_Legal_Entity_Country__c FROM Order];
        Map<Id, blng__InvoiceRun__c>invoiceRunOldMap = new Map<Id, blng__InvoiceRun__c>();
        for(blng__InvoiceRun__c run : invoiceRunList){
            invoiceRunOldMap.put(run.id,run); 
        }        
        List<QTB_Tax_Integration_Setting__mdt> mtd = [Select id,QTB_Country__c, QTB_End_System__c, QTB_Product_Line__c FROM QTB_Tax_Integration_Setting__mdt where Label = 'Vertex Integration'];
        QTB_InvoiceRunHelper.vertexTaxCallOut(invoiceRunList,invoiceRunOldMap);
        QTB_InvoiceRunHelper.vertexTaxCallOut(null,null);
        QTB_InvoiceRunTriggerHandler.throwExplicitException = true;
		//QTB_InvoiceRunHelper.updateInvoiceSchedulerCustomSettingFlag(invoiceRunList,invoiceRunOldMap);        
    }
    static testMethod void testMethod3(){
        QTB_InvoiceRunTriggerHandler.throwExplicitException = true;
        try {            
            Test.startTest();      
            QTB_InvoiceRunHelper.vertexTaxCallOut(null, null);
            Test.stopTest();
        } catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }        
        try {
         //   QTB_InvoiceRunHelper.updateInvoiceSchedulerCustomSettingFlag(Null,Null);
        } catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }        
        try {
          //  QTB_InvoiceRunUtils.cancelInvoiceWithHoldBillingTrue(null);
        } catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }        
        try {
          //  QTB_InvoiceRunUtils.cancelInvoicesWithHoldBilling(Null,Null);
        } catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }
    }
     static testMethod void testMethod4(){
        List<blng__InvoiceRun__c> invoiceRunList = [Select id, Name,blng__Status__c,blng__TargetDate__c From blng__InvoiceRun__c where Name like 'Rebill Invoice For Order %' ];
		List<Order> OrdersList = [SELECT Id,OrderNumber, QTB_Legal_Entity_Country__c FROM Order];
        Map<Id, blng__InvoiceRun__c>invoiceRunOldMap = new Map<Id, blng__InvoiceRun__c>();
         set<id> invcRun = new set<id>();
        for(blng__InvoiceRun__c run : invoiceRunList){
            invoiceRunOldMap.put(run.id,run); 
            invcRun.add(run.id);
        }        
        List<QTB_Tax_Integration_Setting__mdt> mtd = [Select id,QTB_Country__c, QTB_End_System__c, QTB_Product_Line__c FROM QTB_Tax_Integration_Setting__mdt where Label = 'Vertex Integration'];    
		//QTB_InvoiceRunUtils.cancelInvoiceWithHoldBillingTrue(invcRun);        
    }
}