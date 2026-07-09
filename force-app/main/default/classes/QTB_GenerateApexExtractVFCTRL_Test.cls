/*****************************************************************************************************
* Class: QTB_GenerateApexExtractVFCTRL_Test
* Purpose: This is a test class for apex code coverage
* Developer     Date           
* ------------------------------------------------------------------------------------------- 
*  Sriram      7/24/2020  
*  Shailesh    24/06/2024 -- Gitlab US#24329 -- refactored this test class and removed unnecessary piece of code and comments
*******************************************************************************************************/
@isTest
public class QTB_GenerateApexExtractVFCTRL_Test {
    
    static testmethod void testMethod1()
    {  
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
        p.SBQQ__ChargeType__c = 'Recurring';
        p.SBQQ__BillingType__c = 'Arrears';
        p.name = 'ProdName';
        product.add(p);
        sbqq.TriggerControl.disable();
        insert product;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        blng__LegalEntity__c indiaEntity= QTB_TestDataFactory.createLegalEntity('India');
        String recordType = 'Billing Account';
        id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        
        blng__LegalEntity__c USEntity= QTB_TestDataFactory.createLegalEntity('Denmark');
        //Account United States
        Account acc1 = new Account();
        acc1.Name='Nordea Bank Oyj';
        acc1.RecordTypeId = recordTypeValue;
        acc1.QTB_Legal_Entity_Country__c='Denmark';
        acc1.CurrencyIsoCode = 'USD';
        acc1.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        acc1.ShippingCity = 'New York';
        acc1.ShippingState = 'New York';
        acc1.ShippingPostalCode = '22131';
        acc1.ShippingCountry = 'United States';
        acc1.QTB_Contract_Entity__c= USEntity.id;
        acc1.QTB_Create_Parent_Billing_Account__c = true;
        insert acc1;
        
        List<Account> accountList = new List<Account>();
        //Account United States
        Account acc = new Account();
        acc.Name='Test IME Account US';
        acc.RecordTypeId = recordTypeValue;
        acc.QTB_Legal_Entity_Country__c='Denmark';
        acc.CurrencyIsoCode = 'USD';
        acc.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        acc.ShippingCity = 'New York';
        acc.ShippingState = 'New York';
        acc.ShippingPostalCode = '22131';
        acc.ShippingCountry = 'United States';
        acc.QTB_Contract_Entity__c= USEntity.id;
        acc.QTB_Invoice_Delivery_Options__c = 'Email';
        acc.QTB_Create_Parent_Billing_Account__c = false;
        acc.ParentId = acc1.Id;
        acc.ShippingStreet = 'NK';
        acc.IM_Hierarchy_Level__c = '';
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
        
        Contact con1 = new Contact();
        con1.LastName = 'Custom Last Name1 ';
        con1.FirstName = 'Custom First Name1 ';
        con1.email = 'test1@email.com';
        con1.MailingCountry = 'India';
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
        
        list<IM_Country__c> countryList = new list<IM_Country__c>();
        IM_Country__c cou = new IM_Country__c();
        cou.Name = 'Denmark';
        cou.Iso31662Code__c = 'Iso31662Code';
        cou.Active__c=true;
        countryList.add(cou);
        insert countryList;
        
        List<QTB_PurchaseOrder__c> poList = new List<QTB_PurchaseOrder__c>();
        QTB_PurchaseOrder__c po = new QTB_PurchaseOrder__c();
        po.QTB_Status__c = 'Active';
        po.QTB_Billing_Account__c = accountList[0].id;
        po.QTB_Customer_PO__c = '23456';
        po.QTB_Service_Type__c = 'Mixed';
        po.QTB_PO_Type__c = 'Standard';
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
        
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList3[0].SBQQ__PaymentTerm__c = 'Net 15';
        update orderList3;
        orderList3[0].recordtypeid=QTB_Utils.ORDER_BILL_RECTYPEID;
        
        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].Id,quoteLinesList,standardPrice);   
        
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
        String invId = invoiceList[0].id;
        
        list<SBQQ__Localization__c> localizationList = new list<SBQQ__Localization__c>();
        SBQQ__Localization__c loc = new SBQQ__Localization__c();
        loc.SBQQ__Product__c = product[0].id;
        loc.SBQQ__Language__c = accountList[0].QTB_Language__c;
        loc.SBQQ__Text__c = 'Product Name';
        loc.SBQQ__APIName__c = 'Name';
        localizationList.add(loc);
        insert localizationList;
        
        
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
            ProductId = product[0].Id
        );
        
        List<blng__UsageSummary__c> usageSum=QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0]);
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

        
        test.startTest();        
        blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
        invoiceLine.Name = 'prodName';
        invoiceLine.blng__Invoice__c = invId;
        invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine.blng__Quantity__c = 10;
        invoiceLine.blng__UnitPrice__c = 5;
        invoiceLine.blng__OrderProduct__c = orderItemList3[0].id;
        invoiceLine.blng__UsageSummary__c = usagesummary.id;
        invoiceLine.blng__StartDate__c = Date.newInstance(2022, 06, 09);
        invoiceLine.blng__Product__c = product[0].Id;
        invoiceLine.blng__TaxCountry__c = 'United States';
        insert invoiceLine;
        
        //Recurring InvoiceLine
        blng__InvoiceLine__c invoiceLine1 = new blng__InvoiceLine__c();
        invoiceLine1.Name = 'prodName';
        invoiceLine1.blng__Invoice__c = invId;
        invoiceLine1.blng__InvoiceLineStatus__c = 'Initiated';
        invoiceLine1.blng__Quantity__c = 10;
        invoiceLine1.blng__UnitPrice__c = 5;
        invoiceLine1.blng__OrderProduct__c = orderItemList3[0].id;
        //invoiceLine1.blng__ChargeType__c = 'Recurring';
        invoiceLine1.blng__Product__c = product[0].id ; // recurring product
        //invoiceLine1.blng__UsageSummary__c = usagesummary.id; 
        invoiceLine1.blng__StartDate__c = Date.newInstance(2022, 06, 09);
        invoiceLine1.blng__Subtotal__c = 125;
        invoiceLine.blng__Product__c = product[0].Id;

        List<blng__Usage__c> usageList = new list<blng__Usage__c>();
        blng__Usage__c usage = new blng__Usage__c();
        usage.blng__UsageSummary__c = usagesummary.id;
        usage.blng__Account__c = accountList[0].id;
        usage.blng__MatchingId__c = '111';
        usage.blng__EndDateTime__c = date.today() + 1;
        usage.blng__StartDateTime__c = date.today();
        
        //blng__Usage__c usageupdate=usageList[0];
        usage.QTB_Department_Name__c = 'Dept Name';
        usage.QTB_Level_1_Name__c = 'Lev1 Name';
        usage.QTB_Division_Name__c = 'Div Name';
        usage.blng__OrderProduct__c = orderItemList3[0].id;
        usage.blng__Quantity__c = 15.10;
        usage.blng__PreratedQuantity__c = 19.10;
        usage.QTB_Prerated_Unit_Price__c = 20;
        usage.QTB_Division_Code__c = 'Div Code';
        usage.QTB_Department_Code__c = 'Dep Code';
        usage.QTB_Work_Order_ID__c = '12345';
        usage.QTB_Start_Date_MRC__c = system.today();
        usage.QTB_End_Date_MRC__c = system.today()+5;
        usageList.add(usage);
        
        blng__Usage__c usageupdate1=new blng__Usage__c();
        usageupdate1.blng__UsageSummary__c = usagesummary.id;
        usageupdate1.blng__Account__c = accountList[0].id;
        usageupdate1.blng__MatchingId__c = '111';
        usageupdate1.blng__EndDateTime__c = date.today() + 1;
        usageupdate1.blng__StartDateTime__c = date.today();
        usageupdate1.QTB_Department_Name__c = 'Dept Name';
        usageupdate1.QTB_Level_1_Name__c = 'Lev1 Name';
        usageupdate1.QTB_Department_Code__c = 'Dep Code';
        usageupdate1.blng__Quantity__c = 15.10;
        usageupdate1.blng__OrderProduct__c = orderItemList3[0].id;
        usageupdate1.blng__PreratedQuantity__c = 19.10;
        usageupdate1.QTB_Prerated_Unit_Price__c = 20;
        usageupdate1.QTB_Work_Order_ID__c = '123456';
        usageupdate1.QTB_Start_Date_MRC__c = system.today();
        usageupdate1.QTB_End_Date_MRC__c = system.today()+5;
        usageupdate1.QTB_Product_Identifier_1__c = 'Test';
        usageupdate1.QTB_Term__c = '2';
        usageList.add(usageupdate1);
        
        blng__Usage__c usageupdate2=new blng__Usage__c();
        usageupdate2.blng__UsageSummary__c = usagesummary.id;
        usageupdate2.blng__Account__c = accountList[0].id;
        usageupdate2.blng__MatchingId__c = '111';
        usageupdate2.blng__EndDateTime__c = date.today() + 1;
        usageupdate2.blng__StartDateTime__c = date.today();
        usageupdate2.QTB_Department_Name__c = 'Dept Name';
        usageupdate2.QTB_Level_1_Name__c = 'Lev1 Name';
        usageupdate2.QTB_Level_1_Code__c = 'Lev1 Code';
        usageupdate2.QTB_Prerated_Unit_Price__c = 20;
        usageupdate2.QTB_Division_Name__c = 'Div Name';
        usageupdate2.blng__Quantity__c = 15.10;
        usageList.add(usageupdate2);
        
        blng__Usage__c usageupdate3=new blng__Usage__c();
        usageupdate3.blng__UsageSummary__c = usagesummary.id;
        usageupdate3.blng__Account__c = accountList[0].id;
        usageupdate3.blng__MatchingId__c = '111';
        usageupdate3.blng__EndDateTime__c = date.today() + 1;
        usageupdate3.blng__StartDateTime__c = date.today();
        usageupdate3.QTB_Level_1_Code__c = 'Lev1 Code';
        usageupdate3.QTB_Level_1_Name__c = 'Lev1 Name';
        usageupdate3.QTB_Prerated_Unit_Price__c = 20;
        usageupdate3.blng__Quantity__c = 15.10;
        usageList.add(usageupdate3);
        
        blng__Usage__c usageupdate4=new blng__Usage__c();
        usageupdate4.blng__UsageSummary__c = usagesummary.id;
        usageupdate4.blng__Account__c = accountList[0].id;
        usageupdate4.blng__MatchingId__c = '111';
        usageupdate4.blng__EndDateTime__c = date.today() + 1;
        usageupdate4.blng__StartDateTime__c = date.today();
        usageupdate4.blng__Quantity__c = 15.10;
        usageupdate4.QTB_Prerated_Unit_Price__c = 20;
        usageupdate4.blng__PreratedAmount__c = 20;
        usageList.add(usageupdate4);
        SBQQ.TriggerControl.disable();
        QTB_UsageTriggerHandler.disable();
        database.insert(usageList,false) ;
        
        system.Assert(invoiceLine.blng__InvoiceLineStatus__c=='Initiated');
        PageReference pageRef = Page.QTB_GenerateApexExtractVF;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id',invId);
        pageRef.getParameters().put('isUsageWithinLimit','true');//Gitlab #24329

        //calling apex class for code coverage
        QTB_GenerateApexExtractVFCTRL myController = new QTB_GenerateApexExtractVFCTRL();
        QTB_GenerateApexExtractVFCTRL.usagewrapper usgWrap = new  QTB_GenerateApexExtractVFCTRL.usagewrapper();
        usgWrap.header6 = '';
        usgWrap.usage_po = '';
        usgWrap.usagequantity = '';
        QTB_GenerateApexExtractVFCTRL.wrapper wrap = new QTB_GenerateApexExtractVFCTRL.wrapper();
        wrap.print_from_date='';
        wrap.original_invoice = '';
        wrap.orig_inv_dt = '';
        wrap.prior_adj_invoice ='';
        wrap.prior_inv_dt = '';
        wrap.Email_id = '';
        
        QTB_GenerateApexExtractVFCTRL.GroupWrapperCls grpWrap = new QTB_GenerateApexExtractVFCTRL.GroupWrapperCls(usageupdate1,null);
        QTB_Custom_Product_Name__c cutomerPrd = new QTB_Custom_Product_Name__c();
        cutomerPrd.Account__c = accountList[0].id;
        cutomerPrd.Product__c = product[0].id;
        cutomerPrd.Custom_Name__c = 'test';
        insert cutomerPrd;
        
        myController.mappingToUsage(null, null, invoiceList[0], null, null, null, null); 
        Date invoiceLineStartdate = System.today();
        Date invoiceLineEndDate = System.today();
        string ContactEmail = 'a@a.com';
        Map<String, String> accLanguage = new Map<String, String>(); 
        accLanguage.put('en_US', 'ENG');
        myController.mappingToTxt(invoiceList[0], null, ContactEmail, null, accLanguage, null, null, null, null, invoiceLineStartdate,invoiceLineEndDate);
        myController.mappingToTxt(null, null, null, null, null, null, null, null, null, null,null);//cover catch block
        Test.stopTest();
    }
    
    static testmethod void testMethod2()   //Story Git #7673 (Slalom)
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
        //blng__LegalEntity__c USEntity = [Select Id, Name From blng__LegalEntity__c where Name = 'Test Legal Entity United States' limit 1];
        List<Account> accList = new List<Account>();
        //Account United States
        Account acc = new Account();
        acc.Name='Test IME Account US';
        acc.RecordTypeId = recordTypeValue;
        acc.QTB_Legal_Entity_Country__c='United States';
        acc.CurrencyIsoCode = 'USD';
        acc.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
        acc.ShippingCity = 'New York';
        acc.ShippingState = 'New York';
        acc.ShippingPostalCode = '22131';
        acc.ShippingCountry = 'United States';
        acc.QTB_Contract_Entity__c= USEntity.id;
        acc.QTB_Create_Parent_Billing_Account__c = true;
        acc.QTB_Customer_Classification__c = 'Accounting';
        accList.add(acc);    
        insert accList;
        
        blng__InvoiceRun__c ir = new   blng__InvoiceRun__c();
        ir.name = 'This is Something Else';  ///not SITAD
        ir.blng__TargetDate__c = system.today();
        Insert ir;
        
        
        List<blng__Invoice__c> invoiceToReturn = new List<blng__Invoice__c>();
        try {
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accList[0].Id;
            //invoice.blng__InvoiceStatus__c = 'Posted';
            invoice.QTB_Purchase_Order__c = 'PONUMBER001';
            invoice.QTB_Site_Number__c = 'SiteNumber001';
            invoice.QTB_Last_Invoice_Sent__c = null;
            invoice.blng__InvoiceRunCreatedBy__c = ir.Id;
            invoice.CurrencyIsoCode = 'USD';
            invoice.blng__DueDate__c = Date.newInstance(2022, 03, 31);
            invoice.blng__InvoiceDate__c = Date.newInstance(2022, 03, 29);
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
        QTB_GenerateApexExtractVFCTRL myController = new QTB_GenerateApexExtractVFCTRL();
        QTB_GenerateApexExtractCTRL.getinvoicepresentment(invoiceToReturn[0].id);       
        QTB_GenerateApexExtractCTRL.getinvoicepresentment(null);
        QTB_GenerateApexExtractCTRL.getStatus(null);
        QTB_GenerateApexExtractCTRL.generateCSV(invoiceToReturn[0].id);
        QTB_GenerateApexExtractCTRL.generateTxt(invoiceToReturn[0].id,null);
        
         PageReference pageRef = Page.QTB_GenerateApexExtractVF;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id',invoiceToReturn[0].Id);
        pageRef.getParameters().put('isUsageWithinLimit','false');//Gitlab #24329
        Test.stopTest();
    }
}