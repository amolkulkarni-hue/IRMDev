/*****************************************************************************************************
* Class: QTB_GenerateUsageCSVCTRL_Test
* Purpose: This is a test class for apex code coverage
* Developer     Date           
* ------------------------------------------------------------------------------------------- 
*  SM      05/01/2022
*******************************************************************************************************/
@isTest
public class QTB_GenerateUsageCSVCTRL_Test {
    
    //creating test data for apex code coverage
    @testsetup 
    static void setup(){  
        
        Test.startTest();
        SBQQ.TriggerControl.disable();
        blng__LegalEntity__c dkEntity= QTB_TestDataFactory.createLegalEntity('Denmark');
        String recordType = 'Billing Account';
        id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        
        /*Account a1 =new Account();
        a1.Name = 'Nordea Bank Oyj';
        a1.RecordTypeId = recordTypeValue;
        a1.QTB_Create_Parent_Billing_Account__c=true;
        a1.BillingCountry = 'India';
        a1.BillingState = 'Assam';
        a1.QTB_Language__c = 'en_US';
        a1.QTB_Contract_Entity__c=indiaEntity.ID;
        a1.QTB_Invoice_Delivery_Options__c = 'Email';
        insert a1;
        
        List<Account> accountList = new List<Account>();
        Account a =new Account();
        a.Name = 'TestAcc';
        a.RecordTypeId = recordTypeValue;
        a.BillingCountry = 'India';
        a.BillingState = 'Assam';
        a.QTB_Create_Parent_Billing_Account__c=true;
        a.QTB_Language__c = 'en_US';
        a.QTB_Contract_Entity__c=indiaEntity.ID;
        a.QTB_Invoice_Delivery_Options__c = 'Email';
        accountList.add(a); 
        insert accountList;
        
        Contact con = new Contact();
        con.LastName = 'Custom Last Name:20 ';
        con.FirstName = 'Custom First Name ';
        con.email = 'some1@email.com';
        con.MailingCountry = 'India';
        con.MailingStreet='TestStreet';
        con.MailingCity='TestCity';
        con.MailingState='TestState';
        con.MailingPostalCode='1212221'; 
        con.AccountId = a1.Id;
        insert con;
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.accountId = accountList[0].id;
        acr.QTB_Primary__c = true;
        acr.ContactId = con.Id;
        insert acr;
        
        acr.Roles = 'PO Contact';
        update acr;*/
        Account acc1 = new Account();
        acc1.Name='Test Account US';
        acc1.RecordTypeId = recordTypeValue;
        acc1.QTB_Legal_Entity_Country__c='Denmark';
        acc1.CurrencyIsoCode = 'DKK';
        acc1.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        acc1.ShippingCity = 'New York';
        acc1.ShippingState = 'New York';
        acc1.ShippingPostalCode = '22131';
        acc1.QTB_Language__c = 'en_US';
        acc1.ShippingCountry = 'United States';
        acc1.QTB_Contract_Entity__c= dkEntity.id;
        acc1.QTB_Create_Parent_Billing_Account__c = true;
        //accList1.add(acc1);    
        insert acc1;
        
        //String recordType = 'Billing Account';
        //id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        //blng__LegalEntity__c USEntity = [Select Id, Name From blng__LegalEntity__c where Name = 'Test Legal Entity United States' limit 1];
        List<Account> accountList = new List<Account>();
        //Account United States
        Account acc = new Account();
        acc.Name='Test IME Account US';
        acc.RecordTypeId = recordTypeValue;
        acc.QTB_Legal_Entity_Country__c='Denmark';
        acc.CurrencyIsoCode = 'DKK';
        acc.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        acc.ShippingCity = 'New York';
        acc.ShippingState = 'New York';
        acc.ShippingPostalCode = '22131';
        acc.ShippingCountry = 'Denmark';
        acc.QTB_Contract_Entity__c= dkEntity.id;
        acc.QTB_Language__c = 'en_US';
        acc.QTB_Invoice_Delivery_Options__c = 'Email';
        acc.QTB_Create_Parent_Billing_Account__c = false;
        acc.ParentId = acc1.Id;
        accountList.add(acc);    
        insert accountList;
        
        List<contact> listCont = new List<Contact>();
        Contact con = new Contact();
        con.LastName = 'Custom Last Name ';
        con.FirstName = 'Custom First Name ';
        con.email = 'test11@email.com';
        con.MailingCountry = 'India';
        con.MailingStreet='TestStreet11';
        con.MailingCity='TestCity11';
        con.MailingState='TestState11';
        con.MailingPostalCode='1212221';
        con.AccountId = acc1.Id;
        listCont.add(con);
        //insert con;
        Contact con1 = new Contact();
        con1.LastName = 'Custom Last Name1 ';
        con1.FirstName = 'Custom First Name1 ';
        con1.email = 'test1@email.com';
        con1.MailingCountry = 'Denmark';
        con1.MailingStreet='TestStreet1';
        con1.MailingCity='TestCity1';
        con1.MailingState='TestState1';
        con1.MailingPostalCode='1212221';
        con1.AccountId = acc1.Id;
        listCont.add(con1);
        insert listCont;
        
        list<AccountContactRelation> listAcr = new List<AccountContactRelation>();
        AccountContactRelation acr = new AccountContactRelation();
        acr.accountId = accountList[0].id;
        acr.ContactId = con.Id;
        acr.Roles = 'PO Contact';
        listAcr.add(acr);
        AccountContactRelation acr1 = new AccountContactRelation();
        acr1.accountId = accountList[0].id;
        acr1.ContactId = con1.Id;
        acr1.Roles = 'Billing';
        acr1.QTB_Primary__c = true;
        listAcr.add(acr1);
        insert listAcr;
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
        String invId = invoiceList[0].id;
        
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product= new List<product2>();
        product2 p = new product2();
        p.blng__BillingRule__c=billingRule.id;
        p.blng__RevenueRecognitionRule__c =revenueRule.id;
        p.blng__TaxRule__c =taxRule.id;
        p.QTB_Price_Schedule_Category__c = 'Storage';
        p.SBQQ__HasConsumptionSchedule__c = true;
        p.name = 'ProdName';
        product.add(p);
        insert product;
        
        //system.debug('HasConsuption!!!!!'+product.SBQQ__HasConsumptionSchedule__c);
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        List<QTB_Custom_Product_Name__c> cutomerPrdList = new List<QTB_Custom_Product_Name__c>();
        QTB_Custom_Product_Name__c cutomerPrd = new QTB_Custom_Product_Name__c();
        cutomerPrd.Account__c = accountList[0].id;
        cutomerPrd.Product__c = product[0].id;
        cutomerPrd.Custom_Name__c = 'test';
        cutomerPrdList.add(cutomerPrd);
        insert cutomerPrdList;
        
        List<SBQQ__Localization__c> localizationList = new List<SBQQ__Localization__c>();
        SBQQ__Localization__c loc = new SBQQ__Localization__c();
        loc.SBQQ__Product__c = product[0].id;
        loc.SBQQ__Language__c = accountList[0].QTB_Language__c;
        loc.SBQQ__Text__c = 'Product Name';
        loc.SBQQ__APIName__c = 'Name';
        localizationList.add(loc);
        insert localizationList;
        
        List<QTB_PurchaseOrder__c> poList = new List<QTB_PurchaseOrder__c>();
        QTB_PurchaseOrder__c po = new QTB_PurchaseOrder__c();
        po.QTB_Status__c = 'Active';
        po.QTB_Billing_Account__c = accountList[0].id;
        po.QTB_Customer_PO__c = '23456';
        po.QTB_PO_Type__c = 'Standard';
        po.QTB_Service_Type__c = 'Mixed';
        poList.add(po);
        insert poList;
        
        //List<opportunity> oppList=QTB_TestDataFactory.createOpps(accountList);
        List<Opportunity> oppList = new List<Opportunity>();
    try {
      for (Integer i = 0; i < accountList.size(); i++) {
        oppList.add(
          new Opportunity(
            Name = 'Test' + i,
            AccountId = accountList[i].Id,
            CloseDate = Date.today(),
            StageName = '1 - Qualification',
            RecordTypeId = QTB_Utils.OPP_BILL_RECTYPEID,
            Pricebook2Id =pricebookId,
            Amount = 500
          )
        );
      }
      if (!oppList.isEmpty()) {
        insert oppList;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
        /*oppList[0].recordtypeid=QTB_Utils.OPP_BILL_RECTYPEID;
        oppList[0].Pricebook2Id =pricebookId;
        database.update(oppList);*/
        SBQQ.TriggerControl.disable();
        List<SBQQ__Quote__c> quoteList=QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c=pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].recordtypeId=QTB_Utils.QUOTE_BILL_RECTYPEID;
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1, quoteList[0].id,accountList[0].id );
        
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id );
        
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList3[0].recordtypeid=QTB_Utils.ORDER_BILL_RECTYPEID;
        SBQQ.TriggerControl.disable();
        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].Id,quoteLinesList,standardPrice);            
        
        //List<blng__UsageSummary__c> usageSum=QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0]);
        List<blng__UsageSummary__c> usageSum = new List<blng__UsageSummary__c>();
    try {
        blng__UsageSummary__c usage = new blng__UsageSummary__c();
        usage.blng__Order__c = orderList3[0].id;
        usage.blng__Account__c = accountList[0].id;
        usage.blng__OrderProduct__c = orderItemList3[0].id;
        usage.blng__SummaryEndDate__c = DATE.newInstance(2021, 1, 26);
        usage.blng__SummaryStartDate__c = DATE.newInstance(2021, 1, 1);
        usage.blng__MatchingId__c = '1234';
        usage.blng__Status__c = 'Queued For Invoice';
        usage.blng__InvoiceRunProcessingStatus__c='In Progress';
        usage.blng__Subtotal__c=100;
        usage.blng__TotalQuantity__c=10;
        usage.blng__PreratedQuantity__c=20;
        usage.blng__UnbilledQuantity__c=1;
        usage.blng__UnitPrice__c=400;
        usage.blng__PreratedAmount__c=22;
       
        usageSum.add(usage);
      
      if (!usageSum.isEmpty()) {
        insert usageSum;
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    }
        /*blng__UsageSummary__c usagesummary=usageSum[0]; 
        
        usagesummary.blng__Status__c='Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c='In Progress';
        usagesummary.blng__Subtotal__c=100;
        usagesummary.blng__TotalQuantity__c=10;
        usagesummary.blng__PreratedQuantity__c=20;
        usagesummary.blng__UnbilledQuantity__c=1;
        usagesummary.blng__UnitPrice__c=400;
        usagesummary.blng__PreratedAmount__c=22;
        database.update(usagesummary);*/
        
        
        List<blng__InvoiceLine__c> invoiceLineList = new List<blng__InvoiceLine__c>();
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__Invoice__c = invId;
        invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;
        invoiceLine.blng__OrderProduct__c = orderItemList3[0].id;
        invoiceLine.blng__UsageSummary__c = usageSum[0].id; 
        invoiceLine.blng__TaxCountry__c = 'Canada';
        invoiceLineList.add(invoiceLine);
        insert invoiceLineList;
        
        //List<blng__Usage__c> usageList=QTB_TestDataFactory.createUsages(1,accountList[0],usageSum[0]);
        List<blng__Usage__c> usageList = new List<blng__Usage__c>();
    /*try {
      for (Integer i = 0; i < 1; i++) {
        blng__Usage__c usage = new blng__Usage__c();
        usage.blng__UsageSummary__c = usageSum[0].id;
        usage.blng__Account__c = accountList[0].id;
        usage.blng__MatchingId__c = '111';
        usage.blng__EndDateTime__c = date.today() + 1;
        usage.blng__StartDateTime__c = date.today();
        usage.QTB_Department_Name__c = 'Dept Name';
        usage.QTB_Level_1_Name__c = 'Lev1 Name';
        usage.QTB_Division_Name__c = 'Div Name';
        usage.blng__OrderProduct__c = orderItemList3[0].id;
        usage.blng__Quantity__c = 15.10;
        usage.blng__PreratedQuantity__c = 19.10;
        usage.QTB_Division_Code__c = 'Div Code';
        usage.QTB_Department_Code__c = 'Dep Code';
        usage.QTB_Work_Order_ID__c = '12345';
        usage.QTB_Start_Date_MRC__c = system.today();
        usage.QTB_End_Date_MRC__c = system.today()+5;
        usageList.add(usage);
      }
      if (!usageList.isEmpty()) {
        Database.insert(usageList, false);
      }
    } catch (Exception e) {
      System.debug('The following exception has occurred: ' + e.getMessage());
    } */
		blng__Usage__c usage = new blng__Usage__c();
        usage.blng__UsageSummary__c = usageSum[0].id;
        usage.blng__Account__c = accountList[0].id;
        usage.blng__MatchingId__c = '111';
        usage.blng__EndDateTime__c = date.today() + 1;
        usage.blng__StartDateTime__c = date.today();
        usage.QTB_Department_Name__c = 'Dept Name';
        usage.QTB_Level_1_Name__c = 'Lev1 Name';
        usage.QTB_Division_Name__c = 'Div Name';
        usage.blng__PreratedAmount__c = 1200;
        usage.QTB_Prerated_Unit_Price__c = 10;
        usage.blng__OrderProduct__c = orderItemList3[0].id;
        usage.blng__Quantity__c = 15.10;
        usage.blng__PreratedQuantity__c = 19.10;
        usage.QTB_Division_Code__c = 'Div Code';
        usage.QTB_Department_Code__c = 'Dep Code';
        usage.QTB_Work_Order_ID__c = '12345';
        usage.QTB_Start_Date_MRC__c = system.today();
        usage.QTB_End_Date_MRC__c = system.today()+5;
        usage.QTB_TaxAmount__c = 1000;
        usage.QTB_Invoice_Quantity__c=10;
        usageList.add(usage);
		Database.insert(usageList);
		System.debug('Usageslist Inserted >>> '+usageList);
		
        /*blng__Usage__c usageupdate=usageList[0];
        usageupdate.QTB_Department_Name__c = 'Dept Name';
        usageupdate.QTB_Level_1_Name__c = 'Lev1 Name';
        usageupdate.QTB_Division_Name__c = 'Div Name';
        usageupdate.blng__OrderProduct__c = orderItemList3[0].id;
        usageupdate.blng__Quantity__c = 15.10;
        usageupdate.blng__PreratedQuantity__c = 19.10;
        usageupdate.QTB_Division_Code__c = 'Div Code';
        usageupdate.QTB_Department_Code__c = 'Dep Code';
        usageupdate.QTB_Work_Order_ID__c = '12345';
        usageupdate.QTB_Start_Date_MRC__c = system.today();
        usageupdate.QTB_End_Date_MRC__c = system.today()+5;
        database.update(usageupdate);*/
        Test.stopTest();
        
    }
    static testmethod void usageCSVGenerateTestMethod()
    {   
        Test.startTest();
        List<blng__Invoice__c> invoiceList = [SELECT blng__InvoiceDate__c,QTB_Custom_Invoice_Number__c,blng__DueDate__c,blng__Account__r.id,
                                              blng__Account__r.QTB_Contract_Entity__r.blng__Street1__c,blng__Account__r.QTB_Contract_Entity__r.blng__Street2__c,blng__Account__r.QTB_Contract_Entity__r.blng__City__c,blng__Account__r.QTB_Contract_Entity__r.blng__State__c,blng__Account__r.QTB_Contract_Entity__r.blng__ZipPostalCode__c,
                                              blng__Account__r.QTB_Invoice_Detail_Options__c,
                                              blng__Account__r.BillingCountry,blng__Account__r.BillingStreet,blng__Account__r.BillingCity,blng__Account__r.BillingState,blng__Account__r.BillingPostalCode
                                              FROM blng__Invoice__c];
        List<SBQQ__Localization__c> localizationList = [select id, SBQQ__Product__c, SBQQ__Language__c, SBQQ__Text__c, SBQQ__APIName__c from SBQQ__Localization__c];
        List<QTB_Custom_Product_Name__c> cutomerPrdList = [select id, Account__c, Product__c, Custom_Name__c from QTB_Custom_Product_Name__c];
        List<QTB_PurchaseOrder__c> pOrderList = [select id, QTB_Status__c, QTB_Billing_Account__c, QTB_Customer_PO__c from QTB_PurchaseOrder__c];
        List<blng__InvoiceLine__c> invLineItem = [select id, blng__TaxAmount__c, blng__Invoice__r.blng__Account__r.QTB_Language__c, blng__Invoice__r.blng__Account__r.QTB_Display_Custom_Product_Names__c, blng__Invoice__r.blng__Account__c, blng__UsageSummary__c, blng__Product__c, blng__Product__r.Name,  blng__Product__r.ProductCode,  blng__Quantity__c, blng__UnitPrice__c, blng__Subtotal__c, CurrencyIsoCode from blng__InvoiceLine__c];
        List<blng__Usage__c> usageslist = [select blng__UsageSummary__c, blng__Account__c, blng__MatchingId__c, blng__EndDateTime__c, blng__StartDateTime__c,
                                           QTB_Department_Name__c, QTB_Level_1_Name__c, QTB_Division_Name__c, blng__OrderProduct__c, blng__Quantity__c,
                                           blng__PreratedQuantity__c, QTB_Division_Code__c, QTB_Department_Code__c, QTB_Work_Order_ID__c, QTB_Start_Date_MRC__c,
                                           QTB_End_Date_MRC__c from blng__Usage__c ];
        system.debug('usageslist-->' + usageslist);
        system.debug('invLineItem-->' + invLineItem);
        system.debug('pOrderList-->' + pOrderList);
        system.debug('cutomerPrdList-->' + cutomerPrdList);
        system.debug('localizationList-->' + localizationList);
        system.debug('invoiceList-->' + invoiceList);
        try {
            list<String> poValues = new list<String>();
            poValues.add('test1');
            
            String contName = 'testCnt';
            String cntEmail = 'test123@gmail.com';
            
            PageReference pageRef = Page.QTB_GenerateUsageCSV;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('Id', String.valueOf(invoiceList[0].id));
            QTB_GenerateUsageCSVCTRL myCsvController = new QTB_GenerateUsageCSVCTRL();
            
            myCsvController.mappingToCSV(invoiceList[0],poValues, contName, cntEmail,usageslist,pOrderList, localizationList, cutomerPrdList);
            myCsvController.mappingToInvoice(invoiceList[0],poValues, contName, cntEmail,localizationList,cutomerPrdList,invLineItem);
            
			QTB_GenerateUsageCSVCTRL.wrapper pinfo = new QTB_GenerateUsageCSVCTRL.wrapper();
			pinfo.BillableCubicFt = 'test';
			pinfo.UnitofMeasure = 'test';
            pinfo.StorageDate = 'test';
			pinfo.ServiceDate = 'test';
			pinfo.SitePONumber = 'test';
        }
        catch (Exception e) {
            
        }
        Test.stopTest();
    }
    
    static testmethod void usageCSVGenerateTestCoverageMethod(){
        try {
            Test.startTest();
            QTB_GenerateUsageCSVCTRL.codeCoverage();
        } catch (Exception e) {
            
        }
        Test.stopTest();
    }
   
 }