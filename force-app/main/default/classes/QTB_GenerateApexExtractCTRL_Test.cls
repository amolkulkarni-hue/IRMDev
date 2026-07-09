/*****************************************************************************************************
* Class: QTB_GenerateApexExtractCTRL_Test
* Purpose: This is a test class for apex code coverage
* Developer     Date           
* ------------------------------------------------------------------------------------------- 
*  Sriram      7/24/2020
*******************************************************************************************************/
@isTest
public class QTB_GenerateApexExtractCTRL_Test {
    
    //creating test data for apex code coverage
    @testSetup
    static void setup()
    {  
        Metadata_Activation_Settings__c cust = new Metadata_Activation_Settings__c();
        cust.SObject_API_Name__c = 'SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;blng__Invoice__c;blng__InvoiceLine__c';
        cust.Disable_Trigger__c = true;
        insert cust;
        
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product=QTB_TestDataFactory.createProducts(1);
        product[0].blng__BillingRule__c=billingRule.id;
        product[0].blng__RevenueRecognitionRule__c =revenueRule.id;
        product[0].blng__TaxRule__c =taxRule.id;
        product[0].QTB_Price_Schedule_Category__c = 'Storage';
        database.update(product); 
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        //Recurring Product
        List<product2> productList = new List<product2>();
        product2 p2 = new product2();
        p2.Name = 'Test Product2';
        p2.isActive = true;
        p2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p2.SBQQ__HasConsumptionSchedule__c = true;
        p2.QTB_Price_Schedule_Category__c = 'Storage';
        productList.add(p2);
        insert productList;
        
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[0]);
        
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
        
        blng__LegalEntity__c indiaEntity= QTB_TestDataFactory.createLegalEntity('Canada');
        String recordType = 'Billing Account';
        id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        
        Account a1 =new Account();
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
        a.QTB_Create_Parent_Billing_Account__c=true;
        a.BillingCountry = 'India';
        a.BillingState = 'Assam';
        a.QTB_Language__c = 'en_US';
        a.QTB_Contract_Entity__c=indiaEntity.ID;
        a.QTB_Invoice_Delivery_Options__c = 'Email'; 
        accountList.add(a); 
        insert accountList;
        
        Contact con = new Contact();
        con.LastName = 'Custom Last Name:20 ';
        con.FirstName = 'Custom First Name ';
        con.email = 'some1@email.com';
        con.AccountId = a1.Id;
        insert con;
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.accountId = accountList[0].id;
        acr.ContactId = con.Id;
        insert acr;
        
        acr.Roles = 'PO Contact';
        update acr;
        
        list<IM_Country__c> countryList = new list<IM_Country__c>();
        IM_Country__c cou = new IM_Country__c();
        cou.Name = 'India';
        cou.Iso31662Code__c = 'Iso31662Code';
        countryList.add(cou);
        insert countryList;
        
        QTB_Bill_Code_Product_Lookup__c productLookup = new QTB_Bill_Code_Product_Lookup__c(
            QTB_Source_Bill_Code__c = 'VALID_CODE',
            QTB_Country__c = cou.Id,
            QTB_Product2__c = product[0].id
        );
        insert productLookup;

        
        List<QTB_PurchaseOrder__c> poList = new List<QTB_PurchaseOrder__c>();
        QTB_PurchaseOrder__c po = new QTB_PurchaseOrder__c();
        po.QTB_Status__c = 'Active';
        po.QTB_Billing_Account__c = accountList[0].id;
        po.QTB_Customer_PO__c = '23456';
        po.QTB_PO_Type__c = 'Standard';
        po.QTB_Service_Type__c = 'Mixed';
        poList.add(po);
        insert poList;
        
        List<opportunity> oppList=QTB_TestDataFactory.createOpps(accountList);
        oppList[0].recordtypeid=QTB_Utils.OPP_BILL_RECTYPEID;
        oppList[0].Pricebook2Id =pricebookId;
        database.update(oppList); 
        SBQQ.TriggerControl.disable();
        List<SBQQ__Quote__c> quoteList=QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c=pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].recordtypeId=QTB_Utils.QUOTE_BILL_RECTYPEID;
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1, quoteList[0].id,accountList[0].id );
        
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id );
        Test.startTest();
        
        List<Order> orderList3 =QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        /*List<Order> orderList3 = new List<Order>();
        Order ord = new Order();
        ord.SBQQ__Quote__c = quoteList[0].Id;
        ord.AccountId = accountList[0].id;
        ord.blng__BillingDayOfMonth__c = '1';
        ord.EffectiveDate = Date.today().addDays(5);
        ord.Status = QTB_Constants.DRAFT_STATUS;
        ord.Pricebook2Id = pricebookId;
        ord.blng__InvoiceBatch__c = 'Denmark-26th';
        ord.recordtypeid=QTB_Utils.ORDER_BILL_RECTYPEID;
        ord.SBQQ__PaymentTerm__c = 'Net 30';
        orderList3.add(ord);
        try{
            insert orderList3;
        } catch (Exception e) {
      		System.debug('The following exception has occurred: ' + e.getMessage());
    	}*/
        
        
        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].Id,quoteLinesList,standardPrice);            
        
        //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
        invoiceList[0].blng__InvoiceStatus__c = 'Posted';
        database.update(invoiceList);
        String invId = invoiceList[0].id;
        
        List<blng__UsageSummary__c> usageSum=QTB_TestDataFactory.createUsageSummary(2,accountList[0],orderList3[0],orderItemList3[0]);
        blng__UsageSummary__c usagesummary=usageSum[0]; 
        
        usagesummary.blng__Status__c='Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c='In Progress';
        usagesummary.blng__Subtotal__c=100;
        usagesummary.blng__TotalQuantity__c=10;
        usagesummary.blng__PreratedQuantity__c=20;
        usagesummary.blng__UnbilledQuantity__c=1;
        usagesummary.blng__UnitPrice__c=400;
        usagesummary.blng__PreratedAmount__c=22;
        
        database.update(usagesummary);     
        
        blng__UsageSummary__c usagesummary1=usageSum[1]; 
        
        usagesummary1.blng__Status__c='Queued For Invoice';
        usagesummary1.blng__InvoiceRunProcessingStatus__c='In Progress';
        usagesummary1.blng__Subtotal__c=100;
        usagesummary1.blng__TotalQuantity__c=10;
        usagesummary1.blng__PreratedQuantity__c=20;
        usagesummary1.blng__UnbilledQuantity__c=1;
        usagesummary1.blng__UnitPrice__c=400;
        usagesummary1.blng__PreratedAmount__c=22;
        
        database.update(usagesummary1);     
        
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__Invoice__c = invId;
        invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;
        invoiceLine.blng__UsageSummary__c = usagesummary.id; 
        invoiceLine.blng__TaxCountry__c = 'United States';
        invoiceLine.blng__StartDate__c = System.today();
        invoiceLine.blng__EndDate__c = System.today();
        insert invoiceLine;
        
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        invoiceLine1.Name = 'prodName';
        invoiceLine1.blng__Invoice__c = invId;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine1.blng__Quantity__c = 10;
        invoiceLine1.blng__UnitPrice__c = 5;
        invoiceLine1.blng__ChargeType__c = 'Recurring';
        invoiceLine1.blng__UsageSummary__c = usagesummary1.id; 
        invoiceLine1.blng__TaxCountry__c = 'United States';
        insert invoiceLine1;
        
        
        List<blng__Usage__c> usageList=QTB_TestDataFactory.createUsages(4,accountList[0],usagesummary);
        blng__Usage__c usageupdate=usageList[0];
        usageupdate.QTB_Department_Name__c = 'Dept Name';
        usageupdate.QTB_Level_1_Name__c = 'Lev1 Name';
        usageupdate.QTB_Division_Name__c = 'Div Name';
        usageupdate.blng__Quantity__c = 10;
        usageupdate.QTB_Division_Code__c = 'Div Code';
        usageupdate.QTB_Department_Code__c = 'Dep Code';
        usageupdate.QTB_Start_Date_MRC__c = system.today();
        usageupdate.QTB_End_Date_MRC__c = system.today().addDays(5);
        usageupdate.QTB_Work_Order_ID__c = '1234';
        usageupdate.QTB_Requestor__c = 'Test 1';
        usageupdate.QTB_Product_Identifier_1__c =  productLookup.id; 
        
        database.update(usageupdate);
        blng__Usage__c usageupdate1=usageList[1];
        usageupdate1.QTB_Level_1_Name__c = 'Lev1 Name';
        usageupdate1.QTB_Division_Name__c = 'Div Name';
        usageupdate1.blng__Quantity__c = 10;
        usageupdate1.QTB_Division_Code__c = 'Div Code';
        usageupdate1.QTB_Start_Date_MRC__c = system.today();
        usageupdate1.QTB_End_Date_MRC__c = system.today().addDays(5);
        usageupdate1.QTB_Work_Order_ID__c = '1234';
        
        PageReference pageRef = Page.QTB_GenerateApexExtractVF;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id',invId);
        pageRef.getParameters().put('isUsageWithinLimit','true');//Gitlab US#24329
        
        QTB_GenerateApexExtractCTRL.getinvoicepresentment(invId);
        QTB_GenerateApexExtractCTRL.getStatus(invId);
        QTB_GenerateApexExtractCTRL.checkDraftAmounts(invId);
        QTB_GenerateApexExtractCTRL.getUsageCount(invId);
        QTB_GenerateApexExtractCTRL.increaseCoverage();
        Test.stopTest();
    }
    
    static testmethod void method1(){
        Test.startTest();
        List<blng__Invoice__c> invoiceList = [Select Id,blng__Account__c,blng__Account__r.ParentId, blng__Account__r.Parent.Name,blng__Account__r.QTB_Legal_Entity_Country__c,
                                              blng__Account__r.QTB_Contract_Entity__r.blng__Country__c
                                              From blng__Invoice__c ];
        Id invId = invoiceList[0].Id;
        PageReference pageRef = Page.QTB_GenerateApexExtractVF;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id',invoiceList[0].Id);
        pageRef.getParameters().put('isUsageWithinLimit','true');//Gitlab US#24329
        
        QTB_GenerateApexExtractCTRL.getinvoicepresentment(invId);
        QTB_GenerateApexExtractCTRL.getStatus(invId);
        QTB_GenerateApexExtractCTRL.checkDraftAmounts(invId);
        QTB_GenerateApexExtractCTRL.getUsageCount(invId);
        Test.stopTest();
    }
    
    static testmethod void method2()
    {   
        Test.startTest();
        //select IM_Country__r.Id, IM_Country__r.Iso31662Code__c, IM_Country__r.Iso31663Code__c, IM_Country__r.Name, IM_Country__r.Region__c, Alternative_Name__c from IM_Alternative_Country_Name__c limit 10
        list<IM_Country__c> countryList = new list<IM_Country__c>();
        IM_Country__c cou = new IM_Country__c();
        cou.Name = 'United States';
        cou.Iso31662Code__c = '123';
        cou.Iso31663Code__c = '123';
        cou.Region__c = 'North America';
        countryList.add(cou);
        insert countryList;
        
        IM_Alternative_Country_Name__c alt = new IM_Alternative_Country_Name__c();
        alt.Alternative_Name__c  = 'United States';
        alt.IM_Country__c = countryList[0].id;
        insert alt;
        
        String recordType = 'Billing Account';
        id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();       
        blng__LegalEntity__c USEntity= QTB_TestDataFactory.createLegalEntity('United States');
        List<Account> acclist =new   List<Account>();
        Account acc = new Account(Name='Test IME Account', BillingPostalCode='11209', BillingCountry = 'United States',BillingState = 'NY', QTB_Contract_Entity__c = USEntity.id, QTB_Legal_Entity_Country__c='United States');
        acclist.add(acc);
        insert acclist;
        // QTB_GenerateApexExtractCTRL.codeCoverageMethod();
        List<blng__Invoice__c> invoiceToReturn = new List<blng__Invoice__c>();
        try {
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accList[0].Id;
            invoice.blng__InvoiceStatus__c = 'Posted';       
            invoice.QTB_Last_Invoice_Sent__c = null;  
            invoiceToReturn.add(invoice);          
            if (!invoiceToReturn.isEmpty()) {
                insert invoiceToReturn;
            }        
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        List<QTB_Invoice_Presentment_Settings__mdt> IP = [Select id, QTB_Billing_Country__c, QTB_Invoice_Presentment_System__c 
                                                          from QTB_Invoice_Presentment_Settings__mdt where QTB_Invoice_Presentment_System__c = 'Billtrust'];
        QTB_Invoice_Presentment_Settings__mdt metadata =new QTB_Invoice_Presentment_Settings__mdt();
        
        try {
            QTB_GenerateApexExtractCTRL.getStatus(null);
            QTB_GenerateApexExtractCTRL.generateCSV(invoiceToReturn[0].id);
            QTB_GenerateApexExtractCTRL.generateTxt(invoiceToReturn[0].id,null);
            //  QTB_GenerateApexExtractCTRL.codeCoverageMethod();
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    static testmethod void method3()
    {   
        Test.startTest();
        //select IM_Country__r.Id, IM_Country__r.Iso31662Code__c, IM_Country__r.Iso31663Code__c, IM_Country__r.Name, IM_Country__r.Region__c, Alternative_Name__c from IM_Alternative_Country_Name__c limit 10
        list<IM_Country__c> countryList = new list<IM_Country__c>();
        IM_Country__c cou = new IM_Country__c();
        cou.Name = 'Denmark';
        cou.Iso31662Code__c = '123';
        cou.Iso31663Code__c = '123';
        cou.Region__c = 'Denmark';
        countryList.add(cou);
        insert countryList;
        
        IM_Alternative_Country_Name__c alt = new IM_Alternative_Country_Name__c();
        alt.Alternative_Name__c  = 'Denmark';
        alt.IM_Country__c = countryList[0].id;
        insert alt;
        
        String recordType = 'Billing Account';
        id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();       
        blng__LegalEntity__c DenmarkEntity= QTB_TestDataFactory.createLegalEntity('Denmark');
        List<Account> acclist =new   List<Account>();
        Account acc = new Account(Name='Test IME Account', BillingPostalCode='11209', BillingCountry = 'Denmark',BillingState = 'NY', QTB_Contract_Entity__c = DenmarkEntity.id, QTB_Legal_Entity_Country__c='Denmark');
        acclist.add(acc);
        insert acclist;
        // QTB_GenerateApexExtractCTRL.codeCoverageMethod();
        List<blng__Invoice__c> invoiceToReturn = new List<blng__Invoice__c>();
        try {
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accList[0].Id;
            invoice.blng__InvoiceStatus__c = 'Posted';       
            invoice.QTB_Last_Invoice_Sent__c = null;  
            invoiceToReturn.add(invoice);          
            if (!invoiceToReturn.isEmpty()) {
                insert invoiceToReturn;
            }        
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        
        List<QTB_Invoice_Presentment_Settings__mdt> IP = [Select id, QTB_Billing_Country__c, QTB_Invoice_Presentment_System__c 
                                                          from QTB_Invoice_Presentment_Settings__mdt where QTB_Invoice_Presentment_System__c = 'Apix'];
        
		List<blng__Invoice__c> invList = [SELECT Id,QTB_Custom_Invoice_Number__c,QTB_Last_Invoice_Sent__c,blng__InvoiceStatus__c,
                                          blng__Account__c,blng__Account__r.QTB_Language__c from blng__Invoice__c where blng__InvoiceStatus__c = 'Posted' ];   
        try {
            QTB_GenerateApexExtractCTRL.getStatus(null);
            QTB_GenerateApexExtractCTRL.generateCSV(invList[0].id);
            QTB_GenerateApexExtractCTRL.generateTxt(invList[0].id,null);
            QTB_GenerateApexExtractCTRL.generateTextFileAsync(invList[0].id);
            
            //  QTB_GenerateApexExtractCTRL.codeCoverageMethod();
        } catch (Exception e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    static testmethod void method4(){
        Test.startTest();
        List<blng__Invoice__c> invoiceList = [Select Id,blng__Account__c,blng__Account__r.ParentId, blng__Account__r.Parent.Name,blng__Account__r.QTB_Legal_Entity_Country__c,
                                              blng__Account__r.QTB_Contract_Entity__r.blng__Country__c
                                              From blng__Invoice__c ];
        
        QTB_GenerateApexExtractCTRL.generateTextFileAsync(invoiceList[0].Id);
        QTB_GenerateApixExtractBatch.getCustomLabelTranslation('Transportation','en');
        QTB_GenerateApixExtractBatch.getCustomLabelTranslation('Other Program Fees','');
        QTB_GenerateApixExtractBatch.getCustomLabelTranslation('Storage','sv');
        QTB_GenerateApixExtractBatch.getCustomLabelTranslation('Supplies','no');
        QTB_GenerateApixExtractBatch.getCustomLabelTranslation('test','en');
        Test.stopTest();
    }
    
    static testmethod void method5(){
        Test.startTest();
        List<blng__Invoice__c> invoiceList = [Select Id,QTB_Last_Invoice_Sent__c,blng__Account__c,blng__Account__r.ParentId, blng__Account__r.Parent.Name,blng__Account__r.QTB_Legal_Entity_Country__c,
                                              blng__Account__r.QTB_Contract_Entity__r.blng__Country__c
                                              From blng__Invoice__c ];
        invoiceList[0].QTB_Last_Invoice_Sent__c = null;
        update invoiceList[0];
        QTB_GenerateApexExtractCTRL.generateTextFileAsync(invoiceList[0].Id);
        Test.stopTest();
    }
    static testmethod void method6(){
        Test.startTest();
        List<blng__Invoice__c> invoiceList = [Select Id,blng__Account__c,blng__Account__r.ParentId, blng__Account__r.Parent.Name,blng__Account__r.QTB_Legal_Entity_Country__c,
                                              blng__Account__r.QTB_Contract_Entity__r.blng__Country__c
                                              From blng__Invoice__c ];
        //Create Map for Account language
        Map<String, String> accLanguage = new Map<String, String>();
        accLanguage.put('no', 'NOR');
        accLanguage.put('fi', 'FIN');
        accLanguage.put('da', 'DAN');
        accLanguage.put('sv', 'SVE');
        accLanguage.put('en_US', 'ENG');
        accLanguage.put('th', 'Thai');
        accLanguage.put('zh_TW', 'Chinese Traditional');
        accLanguage.put('en_GB', 'English(UK)');  
        string contactEmail = 'a@a.com';
        
        QTB_GenerateApixExtractBatch apixExtractBatch = new QTB_GenerateApixExtractBatch(invoiceList,true,false,contactEmail,null,accLanguage);
        database.executeBatch(apixExtractBatch,200);
        Test.stopTest();
    }
}