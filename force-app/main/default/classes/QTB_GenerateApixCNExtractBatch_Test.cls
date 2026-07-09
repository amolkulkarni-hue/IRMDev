/*****************************************************************************************************
* Class: QTB_GenerateApixCNExtractBatch_Test
* Purpose: This is a test class for QTB_GenerateApixCreditNoteExtractBatch apex code coverage
* Developer             Date
* -------------------------------------------------------------------------------------------
 *******************************************************************************************************/
@isTest(seeAllData=false)
private with sharing class QTB_GenerateApixCNExtractBatch_Test {
    @testSetup
    static void setup(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        //System.runAs(userList[0]) 
        {
            blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
            blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');            
            blng__LegalEntity__c DKEntity = QTB_TestDataFactory.createLegalEntity('Denmark');
            DKEntity.QTB_Bank_Name__c = 'Danske Bank';
            DKEntity.QTB_Account_Number__c = '1234567890';
            DKEntity.blng__Country__c = 'Denmark';
            DKEntity.QTB_IBAN__c = 'SWIFT';
            DKEntity.QTB_Swift_Code__c = 'DANSKE';
            update DKEntity;
            
            String recordType = 'Billing Account';
            id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
            IM_Country__c country3 =[select id, Active__C from IM_Country__c where Name='Denmark'];
            country3.Active__c=true;
            Update country3;
            
            //Account
            List<Account> accountList = new List<Account>();
            Account account = new Account();
            account.Name = 'TestAcc';
            account.RecordTypeId = recordTypeValue;
            account.QTB_Create_Parent_Billing_Account__c = true;
            account.BillingCountry = 'Denmark';
            account.BillingState = 'Assam';
            account.QTB_Language__c = 'en_US';
            account.QTB_Legal_Entity_Country__c='Denmark';
            account.QTB_Contract_Entity__c = DKEntity.id;
            //accountList[0].CurrencyIsoCode = 'DKK';
            account.QTB_Billing_Account_Invoice_Name__c = 'Billing Account';
            account.ShippingCity = 'DK';
            account.ShippingState = 'DK';
            account.ShippingPostalCode = '22131';
            account.ShippingCountry = 'Denmark';
            account.QTB_Bill_Cycle_Day__c = 'Denmark-26th';
            account.QTB_Language__c = 'en_US';
            account.QTB_EDI_Identifier__c = 'POGR';
            account.QTB_Data_Management__c = true;
            accountList.add(account);
            insert accountList;
            
            //Contact
            Contact con = new Contact();
            con.LastName = 'Custom LastName';
            con.FirstName = 'Custom FirstName ';
            con.email = 'aaa1@email.com';
            con.AccountId = accountList[0].Id;
            con.MailingCountry = 'United States';
            con.IM_Role__c = 'Billing';
            insert con;
            
            //Invoice
            list<blng__Invoice__c> invoiceList = new List<blng__Invoice__c>();
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = accountList[0].Id;
            invoice.blng__InvoiceStatus__c = 'Posted';
            invoice.blng__InvoiceDate__c = system.today();
            invoice.QTB_Last_Invoice_Sent__c = system.today();
            invoice.QTB_Custom_Invoice_Number__c = '1234567';
            invoiceList.add(invoice);
            insert invoiceList;
            
            SBQQ.TriggerControl.disable();
            List<product2> product = QTB_TestDataFactory.createProducts(2);
            product[0].blng__BillingRule__c = billingRule.id;
            product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
            product[0].blng__TaxRule__c = taxRule.id;
            product[0].QTB_Price_Schedule_Category__c = 'Storage';
            product[0].SBQQ__SubscriptionPricing__c = 'Fixed Price';
            product[0].SBQQ__HasConsumptionSchedule__c = true;
            
            product[1].blng__BillingRule__c = billingRule.id;
            product[1].blng__RevenueRecognitionRule__c = revenueRule.id;
            product[1].blng__TaxRule__c = taxRule.id;
            product[1].QTB_Price_Schedule_Category__c = 'Services';
            product[1].SBQQ__SubscriptionPricing__c = 'Fixed Price';
            product[1].SBQQ__HasConsumptionSchedule__c = true;
            database.update(product);
            
            list<SBQQ__Localization__c> localizationList = new list<SBQQ__Localization__c>();
            SBQQ__Localization__c loc = new SBQQ__Localization__c();
            loc.SBQQ__Product__c = product[0].id;
            loc.SBQQ__Language__c = accountList[0].QTB_Language__c;
            loc.SBQQ__Text__c = 'Product Name';
            loc.SBQQ__APIName__c = 'Name';
            localizationList.add(loc);
            
            SBQQ__Localization__c loc1 = new SBQQ__Localization__c();
            loc1.SBQQ__Product__c = product[0].id;
            loc1.SBQQ__Language__c = accountList[0].QTB_Language__c;
            loc1.SBQQ__Text__c = 'Product Name';
            loc1.SBQQ__APIName__c = 'Name';
            localizationList.add(loc1);
            insert localizationList;
            
            Id pricebookId = Test.getStandardPricebookId();
            
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
            PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(product[1]);
            
            List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
            //oppList[0].recordtypeid = QTB_Utils.OPP_BILL_RECTYPEID;
            oppList[0].Pricebook2Id = pricebookId;
            database.update(oppList);
            SBQQ.TriggerControl.disable();
            List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
            quoteList[0].SBQQ__PriceBook__c = pricebookId;
            quoteList[0].SBQQ__StartDate__c = System.Today();
            quoteList[0].recordtypeId = QTB_Utils.QUOTE_BILL_RECTYPEID;
            //database.update(quoteList);
            
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
            
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
            
            List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
            orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
            //database.update(orderList3);
            
            List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].Id,quoteLinesList,standardPrice);
            List<OrderItem> orderItemList4 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[1].Id,quoteLinesList,standardPrice1);
            SBQQ.TriggerControl.enable();
            List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0]);
            blng__UsageSummary__c usagesummary = usageSum[0];
            usagesummary.blng__Status__c = 'Queued For Invoice';
            usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
            usagesummary.blng__Subtotal__c = 100;
            usageSummary.blng__MatchingId__c = '1244';
            usagesummary.blng__TotalQuantity__c = 10;
            usagesummary.blng__PreratedQuantity__c = 20;
            usagesummary.blng__UnbilledQuantity__c = 1;
            usagesummary.blng__UnitPrice__c = 400;
            usagesummary.blng__PreratedAmount__c = 22;
            database.update(usagesummary);            
            //List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary);
            List<blng__Usage__c> usageList = new List<blng__Usage__c>();
            blng__Usage__c usageupdate = new blng__Usage__c();
            usageupdate.blng__UsageSummary__c = usagesummary.id;
            usageupdate.blng__Account__c = accountList[0].id;
            usageupdate.QTB_Department_Name__c = 'Dept Name';
            usageupdate.QTB_Level_1_Name__c = 'Lev1 Name';
            usageupdate.QTB_Level_1_Code__c = 'Lev1';
            usageupdate.QTB_Division_Name__c = 'Div Name';
            usageupdate.QTB_Invoice_Quantity__c = 10;
            usageupdate.blng__OrderProduct__c = orderItemList3[0].id;
            //usageupdate.blng__Quantity__c = 15.10;
            //usageupdate.blng__PreratedQuantity__c = 19.10;
            usageupdate.QTB_Division_Code__c = 'Div Code';
            usageupdate.QTB_Department_Code__c = 'Dep Code';
            usageupdate.QTB_Work_Order_ID__c = '12345';
            usageupdate.QTB_Custom_Invoice_Display__c = 'Product Name';
            usageupdate.QTB_Start_Date_MRC__c = system.today();
            usageupdate.QTB_End_Date_MRC__c = system.today()+5;
            usageupdate.QTB_Product_Identifier_1__c ='billUsage';
            usageupdate.QTB_Price_Tier__c = 'Tier 1';
            usageupdate.QTB_Term__c = '3';
            usageupdate.blng__StartDateTime__c = system.today();
            usageupdate.blng__EndDateTime__c = system.today()+5;
            usageupdate.blng__MatchingId__c = '1234';
            usageList.add(usageupdate);
            
            SBQQ.TriggerControl.disable();
            database.insert(usageList,false);
            SBQQ.TriggerControl.enable();
            
            system.debug('usageList insert >>> '+usageList);
            
            String invId = invoiceList[0].id;
            blng__InvoiceLine__c invoiceLine = new blng__InvoiceLine__c();
            invoiceLine.Name = 'prodName';
            invoiceLine.blng__Invoice__c = invId;
            invoiceLine.blng__InvoiceLineStatus__c = 'Initiated';
            invoiceLine.blng__Quantity__c = 10;
            invoiceLine.blng__UnitPrice__c = 5;
            invoiceLine.blng__StartDate__c = system.today();
            invoiceLine.blng__Subtotal__c = 100;
            invoiceLine.blng__UsageSummary__c = usagesummary.id;
            invoiceLine.blng__StartDate__c = system.today();
            invoiceLine.blng__EndDate__c = system.today()+30;
            invoiceLine.blng__TaxCountry__c = 'United States';
            // invoiceLine.QTB_Taxable_Amount__c = 10;
            //invoiceLine.blng__TotalAmount__c = 100;
            test.startTest();
            insert invoiceLine;
            system.debug('Test invoiceLine >>> '+invoiceLine);
            
            List<blng__CreditNote__c> ListCN = QTB_TestDataFactory.createCreditNote(accountList);
            ListCN[0].blng__Notes__c = 'Test';
            Update ListCN;
            test.stopTest();
            List<blng__CreditNoteLine__c> ListCredirLines = new List<blng__CreditNoteLine__c>();
            try {  
                blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
                cnl.QTB_Account__c = accountList[0].Id;
                cnl.blng__CreditNote__c = ListCN[0].id;
                cnl.QTB_Invoice__c =  invoiceList[0].id;
                cnl.QTB_InvoiceLine__c = invoiceLine.id;
                cnl.blng__Product__c = product[0].Id;
                cnl.QTB_Credit_Quantity__c = 10;
                cnl.blng__Subtotal__c = 100;
                ListCredirLines.add(cnl);
                
                if (!ListCredirLines.isEmpty()) {
                    SBQQ.TriggerControl.disable();
                    insert ListCredirLines;
                    SBQQ.triggerControl.enable();
                }
            } catch (Exception e) {
                System.debug('The following exception has occurred@@ ' + e.getLineNumber() + e.getMessage());
            }
            system.debug('Test ListCredirLines >>> '+ListCredirLines);
            
            
            System.assertEquals('prodName',invoiceLine.Name);  
        }
    }
    
    static testMethod void testmethod0(){
        Test.startTest();
        List<blng__CreditNote__c> ListCN=[select name,QTB_Last_Credit_Note_Sent__c,QTB_Custom_Invoice_Number__c,id,
                                          blng__Status__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Legal_Entity_Country__c from blng__CreditNote__c limit 10];  
        System.debug('country==='+ListCN[0].blng__Account__r.QTB_Legal_Entity_Country__c);
        ListCN[0].QTB_Tax_Override_Amount__c = 100.01;
        update ListCN[0];
        List<product2> pdt = [select id,Name,QTB_Price_Schedule_Category__c from product2 LIMIT 10];
        pdt[0].QTB_Price_Schedule_Category__c = ' ';
        pdt[0].Name = 'Test 1';
        update pdt;
        
        List<blng__Usage__c> us = [Select Id,QTB_Custom_Invoice_Display__c,blng__OrderProduct__c, blng__OrderProduct__r.Product2Id,
                                   blng__OrderProduct__r.Product2.Id, blng__OrderProduct__r.Product2.productCode,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c,
                                   QTB_Division_Code__c, QTB_Department_Code__c,QTB_Department_Name__c,blng__Account__r.QTB_Display_Custom_Product_Names__c,
                                   blng__Account__r.QTB_Language__c, QTB_Level_1_Name__c, QTB_Level_1_Code__c,QTB_Division_Name__c,QTB_Product_Identifier_1__c,
                                   QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c, QTB_Term__c, blng__UsageSummary__c, blng__UsageSummary__r.blng__UnitPrice__c, 
                                   blng__MatchingAttribute__c, blng__ErrorMessage__c, blng__UnitPrice__c, blng__Subtotal__c,QTB_Rated_Unit_Price__c,
                                   QTB_UsedforRerate__c, QTB_Service_District__c, QTB_Rated_Amount__c, QTB_Invoice_Quantity__c,QTB_Prerated_Unit_Price__c,
                                   blng__PreratedQuantity__c, blng__PreratedAmount__c, blng__Quantity__c,QTB_Price_Tier__c From blng__Usage__c limit 10];
        
        System.debug('Method 0 - US >>> '+us);
        PageReference pageRef = Page.QTB_Generate_Creditnote_Extract;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', ListCN[0].id);
        pageRef.getParameters().put('isUsageWithinLimit', 'true');
        QTB_Generate_Creditnote_Ctrl myCsvController = new QTB_Generate_Creditnote_Ctrl();
        QTB_Generate_Creditnote_Ctrl.generateFile(ListCN[0].id);
        QTB_Generate_Creditnote_Ctrl.getinvoicepresentment(ListCN[0].id);
        
        PageReference pageRef1 = Page.QTB_Generate_Creditnote_Extract;
        Test.setCurrentPage(pageRef1);
        pageRef1.getParameters().put('Id', ListCN[0].id);
        pageRef1.getParameters().put('isUsageWithinLimit', 'false');
        QTB_Generate_Creditnote_Ctrl myCsvController1 = new QTB_Generate_Creditnote_Ctrl();
        test.stopTest(); 
    }
    
    static testMethod void testmethod1(){
        Test.startTest();
        List<blng__CreditNote__c> ListCN=[select name,QTB_Last_Credit_Note_Sent__c,QTB_Custom_Invoice_Number__c,id,
                                          blng__Status__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Legal_Entity_Country__c from blng__CreditNote__c limit 10];  
        System.debug('country==='+ListCN[0].blng__Account__r.QTB_Legal_Entity_Country__c);
        PageReference pageRef = Page.QTB_Generate_Creditnote_Extract;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', ListCN[0].id);
        pageRef.getParameters().put('isUsageWithinLimit', 'true');
        QTB_Generate_Creditnote_Ctrl myCsvController = new QTB_Generate_Creditnote_Ctrl();
        QTB_Generate_Creditnote_Ctrl.generateFile(ListCN[0].id);
        QTB_Generate_Creditnote_Ctrl.getinvoicepresentment(ListCN[0].id);
        test.stopTest(); 
    }
    
    static testMethod void testmethod2(){
        Test.startTest();
        Account ac = [select id,QTB_Legal_Entity_Country__c from Account LIMIT 1];
        ac.QTB_Legal_Entity_Country__c='United States';
        ac.QTB_EDI_Identifier__c = 'POGR';
        update ac;
        
        List<blng__CreditNote__c> ListCN=[select name,QTB_Last_Credit_Note_Sent__c,QTB_Custom_Invoice_Number__c,id,
                                          blng__Status__c,blng__Account__r.BillingCountry,blng__Account__r.QTB_Legal_Entity_Country__c from blng__CreditNote__c limit 10];  
        System.debug('country==='+ListCN[0].blng__Account__r.QTB_Legal_Entity_Country__c);
        
        List<blng__Usage__c> usagesList = [Select Id,QTB_Custom_Invoice_Display__c,blng__OrderProduct__c, blng__OrderProduct__r.Product2Id,
                                           blng__OrderProduct__r.Product2.Id, blng__OrderProduct__r.Product2.productCode,blng__OrderProduct__r.product2.QTB_Price_Schedule_Category__c,
                                           QTB_Division_Code__c, QTB_Department_Code__c,QTB_Department_Name__c,blng__Account__r.QTB_Display_Custom_Product_Names__c,
                                           blng__Account__r.QTB_Language__c, QTB_Level_1_Name__c, QTB_Level_1_Code__c,QTB_Division_Name__c,QTB_Product_Identifier_1__c,
                                           QTB_Start_Date_MRC__c,QTB_End_Date_MRC__c, QTB_Term__c, blng__UsageSummary__c, blng__UsageSummary__r.blng__UnitPrice__c, 
                                           blng__MatchingAttribute__c, blng__ErrorMessage__c, blng__UnitPrice__c, blng__Subtotal__c,QTB_Rated_Unit_Price__c,
                                           QTB_UsedforRerate__c, QTB_Service_District__c, QTB_Rated_Amount__c, QTB_Invoice_Quantity__c,QTB_Prerated_Unit_Price__c,
                                           blng__PreratedQuantity__c, blng__PreratedAmount__c, blng__Quantity__c,QTB_Price_Tier__c From blng__Usage__c limit 10];
        usagesList[0].QTB_Price_Tier__c = 'None';
        update usagesList;
        System.debug('<< usagesList >>'+usagesList);
        PageReference pageRef = Page.QTB_Generate_Creditnote_Extract;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', ListCN[0].id);
        pageRef.getParameters().put('isUsageWithinLimit', 'false');
        QTB_Generate_Creditnote_Ctrl myCsvController = new QTB_Generate_Creditnote_Ctrl();
        QTB_Generate_Creditnote_Ctrl.generateFile(ListCN[0].id);
        QTB_Generate_Creditnote_Ctrl.getinvoicepresentment(ListCN[0].id);
        System.debug('creditNote id======='+ListCN[0].id);
        QTB_Generate_Creditnote_Ctrl.LineItems lineWrap = new QTB_Generate_Creditnote_Ctrl.LineItems();
        QTB_Generate_Creditnote_Ctrl.GroupWrapperCls grpWrap;
        QTB_Generate_Creditnote_Ctrl.GroupWrapperCls grpWrap1 = new QTB_Generate_Creditnote_Ctrl.GroupWrapperCls(usagesList[0],grpWrap);
        QTB_Generate_Creditnote_Ctrl.usagewrapper usgWrap = new QTB_Generate_Creditnote_Ctrl.usagewrapper();
        QTB_Generate_Creditnote_Ctrl.usageSubtotalWrapper usgSubWrap = new QTB_Generate_Creditnote_Ctrl.usageSubtotalWrapper();
        test.stopTest();       
    }
    
    static testMethod void testMethod3(){
        Test.startTest();
        List<Account> accountList = [Select ID from Account];
        List<Product2> productList = [Select Id From Product2];
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        creditNote1.blng__Account__c = accountList[0].Id;
        creditNote1.QTB_On_Account_Credit__c = true;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Legacy Credit';
        creditNote1.blng__Status__c = 'Draft';
        creditNote1.CurrencyIsoCode = 'DKK';
        creditNote1.QTB_PO_Number__c = '12345';
        creditNote1.QTB_Site_Number__c = '125432';
        insert creditNote1;
        
        blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
        cnl.QTB_Account__c = accountList[0].Id;
        cnl.blng__CreditNote__c = creditNote1.id;
        cnl.blng__Product__c = productList[0].Id;
        cnl.blng__Subtotal__c = 100;
        cnl.QTB_Credit_Quantity__c = 10;
        insert cnl;
        
        PageReference pageRef = Page.QTB_Generate_Creditnote_Extract;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', creditNote1.id);
        pageRef.getParameters().put('isUsageWithinLimit', 'true');
        QTB_Generate_Creditnote_Ctrl myCsvController = new QTB_Generate_Creditnote_Ctrl();
        QTB_Generate_Creditnote_Ctrl.generateFile(creditNote1.id);
        QTB_Generate_Creditnote_Ctrl.getinvoicepresentment(creditNote1.id);
        
        PageReference pageRef1 = Page.QTB_Generate_Creditnote_Extract;
        Test.setCurrentPage(pageRef1);
        pageRef1.getParameters().put('Id', creditNote1.id);
        pageRef1.getParameters().put('isUsageWithinLimit', 'false');
        QTB_Generate_Creditnote_Ctrl myCsvController1 = new QTB_Generate_Creditnote_Ctrl();
        Test.stopTest();
    }
    
    //Nordics country
    static testMethod void testMethod4(){
        Test.startTest();
        List<Account> accountList = [Select ID,QTB_Language__c from Account];
        List<Product2> productList = [Select Id From Product2];
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        creditNote1.blng__Account__c = accountList[0].Id;
        creditNote1.QTB_On_Account_Credit__c = true;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Legacy Credit';
        creditNote1.blng__Status__c = 'Draft';
        creditNote1.CurrencyIsoCode = 'DKK';
        creditNote1.QTB_PO_Number__c = '12345';
        creditNote1.QTB_Site_Number__c = '125432';
        insert creditNote1;
        
        blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
        cnl.QTB_Account__c = accountList[0].Id;
        cnl.blng__CreditNote__c = creditNote1.id;
        cnl.blng__Product__c = productList[0].Id;
        cnl.blng__Subtotal__c = 10;            
        cnl.blng__CalculateTax__c=false;
        cnl.blng__TotalAmount__c = 10;
        cnl.QTB_Credit_Quantity__c = 1;
        cnl.QTB_Custom_Invoice_Display__c = '123';
        cnl.QTB_Product_Identifier_1__c = 'test';
        insert cnl;        
        
        List<blng__CreditNote__c> crdNoteList = [SELECT Id, NAme,QTB_On_Account_Credit__c, blng__Account__c,blng__Account__r.QTB_Language__c,
                                                 blng__Account__r.QTB_EDI_Identifier__c
                                                 From blng__CreditNote__c where QTB_On_Account_Credit__c = true];
        System.debug('testMethod4_crdNoteList@@'+crdNoteList);
        AggregateResult[] creditLines = [SELECT CurrencyIsoCode currCode, sum(QTB_Credit_Quantity__c) qty,sum(QTB_Subtotal__c) subTotal, QTB_Invoice__r.QTB_Custom_Invoice_Number__c InvNum, 
                                         blng__Product__r.QTB_Price_Schedule_Category__c scheduleCategory, blng__Product__r.Name ProdName, sum(blng__InvoiceLine__r.QTB_Unit_Price__c) unitPrice,
                                         QTB_Product_Identifier_1__c productIdentifier,QTB_Custom_Invoice_Display__c CusInvDisplay  
                                         FROM blng__CreditNoteLine__c
                                         GROUP BY CurrencyIsoCode, blng__Product__r.QTB_Price_Schedule_Category__c,QTB_Product_Identifier_1__c,QTB_Custom_Invoice_Display__c,
                                         QTB_Invoice__r.QTB_Custom_Invoice_Number__c, blng__Product__r.Name]; 
         System.debug('testMethod4_creditLines@@'+creditLines);
        PageReference pageRef1 = Page.QTB_Generate_Creditnote_Extract;
        Test.setCurrentPage(pageRef1);
        pageRef1.getParameters().put('Id', creditNote1.id);
        pageRef1.getParameters().put('isUsageWithinLimit', 'false');
        
        QTB_GenerateApixCreditNoteExtractBatch batch = new QTB_GenerateApixCreditNoteExtractBatch(crdNoteList[0].id);
        Database.executebatch(batch,1);
        Test.stopTest();
    }
    
    static testMethod void testMethod5(){
        Test.startTest();
        Metadata_Activation_Settings__c cust = new Metadata_Activation_Settings__c();
        cust.SObject_API_Name__c = 'blng__CreditNoteLine__c;blng__CreditNote__c';
        cust.Disable_Trigger__c = true;
        insert cust;
        
        List<blng__Invoice__c> invoiceList = [Select id,Name,QTB_Custom_Invoice_Number__c from blng__Invoice__c];
        List<blng__InvoiceLine__c> invoiceLine = [Select Id,Name,blng__Subtotal__c,blng__TotalAmount__c,blng__UsageSummary__c,QTB_Unit_Price__c
                                                  from blng__InvoiceLine__c where blng__UsageSummary__c !=null];
        
        List<Account> accountList = [Select ID,QTB_Language__c,QTB_Legal_Entity_Country__c from Account];
        accountList[0].QTB_Legal_Entity_Country__c = 'United States';
        update accountList;
        List<Product2> productList = [Select Id,QTB_Price_Schedule_Category__c From Product2];
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        creditNote1.blng__Account__c = accountList[0].Id;
        creditNote1.QTB_On_Account_Credit__c = false;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Bankruptcy';
        creditNote1.blng__Status__c = 'Draft';
        creditNote1.CurrencyIsoCode = 'USD';
        insert creditNote1;
        
        blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
        cnl.QTB_Account__c = accountList[0].Id;
        cnl.blng__CreditNote__c = creditNote1.id;
        cnl.blng__Product__c = productList[0].Id;
        cnl.QTB_Invoice__c =  invoiceList[0].id;
        cnl.QTB_InvoiceLine__c = invoiceLine[0].id;
        cnl.blng__Subtotal__c = 10;            
        cnl.blng__CalculateTax__c=false;
        cnl.blng__TotalAmount__c = 10;
        cnl.QTB_Credit_Quantity__c = 1;
        cnl.QTB_Custom_Invoice_Display__c = '123';
        cnl.QTB_Product_Identifier_1__c = 'test';
        insert cnl;       
        
        List<blng__CreditNote__c> crdNoteList = [SELECT Id, NAme,blng__Account__c,blng__Account__r.QTB_Language__c,
                                                 blng__Account__r.QTB_EDI_Identifier__c,blng__Account__r.QTB_Legal_Entity_Country__c
                                                 From blng__CreditNote__c ];
        AggregateResult[] creditLines = [SELECT CurrencyIsoCode currCode, sum(QTB_Credit_Quantity__c) qty,sum(QTB_Subtotal__c) subTotal, QTB_Invoice__r.QTB_Custom_Invoice_Number__c InvNum, 
                                         blng__Product__r.QTB_Price_Schedule_Category__c scheduleCategory, blng__Product__r.Name ProdName, sum(blng__InvoiceLine__r.QTB_Unit_Price__c) unitPrice,
                                         QTB_Product_Identifier_1__c productIdentifier,QTB_Custom_Invoice_Display__c CusInvDisplay  
                                         FROM blng__CreditNoteLine__c
                                         GROUP BY CurrencyIsoCode, blng__Product__r.QTB_Price_Schedule_Category__c,QTB_Product_Identifier_1__c,QTB_Custom_Invoice_Display__c,
                                         QTB_Invoice__r.QTB_Custom_Invoice_Number__c, blng__Product__r.Name]; 
        
        PageReference pageRef1 = Page.QTB_Generate_Creditnote_Extract;
        Test.setCurrentPage(pageRef1);
        pageRef1.getParameters().put('Id', crdNoteList[0].id);
        pageRef1.getParameters().put('isUsageWithinLimit', 'false');
        
        QTB_GenerateApixCreditNoteExtractBatch batch = new QTB_GenerateApixCreditNoteExtractBatch(crdNoteList[0].id);
        Database.executebatch(batch,1);
        Test.stopTest();
    }
    
    static testMethod void testMethod6(){
        Test.startTest();
        Metadata_Activation_Settings__c cust = new Metadata_Activation_Settings__c();
        cust.SObject_API_Name__c = 'blng__CreditNoteLine__c;blng__CreditNote__c';
        cust.Disable_Trigger__c = true;
        insert cust;
        
        List<Account> accountList = [Select ID,QTB_Language__c from Account];
        List<Product2> productList = [Select Id From Product2];
        List<blng__Invoice__c> invoiceList = [Select id,Name,QTB_Custom_Invoice_Number__c from blng__Invoice__c];
        List<blng__InvoiceLine__c> invoiceLine = [Select Id,Name,blng__Subtotal__c,blng__TotalAmount__c,blng__UsageSummary__c from blng__InvoiceLine__c where blng__UsageSummary__c !=null];
        System.debug('invoiceLine@@'+invoiceLine);
        blng__CreditNote__c creditNote1 = new blng__CreditNote__c();
        creditNote1.blng__Account__c = accountList[0].Id;
        creditNote1.QTB_On_Account_Credit__c = false;
        creditNote1.blng__CreditNoteDate__c = date.today();
        creditNote1.QTB_Reason_Code__c = 'Legacy Credit';
        creditNote1.blng__Status__c = 'Draft';
        creditNote1.CurrencyIsoCode = 'DKK';
        insert creditNote1;
        
        blng__CreditNoteLine__c cnl = new blng__CreditNoteLine__c();
        cnl.QTB_Account__c = accountList[0].Id;
        cnl.blng__CreditNote__c = creditNote1.id;
        cnl.blng__Product__c = productList[0].Id;
        cnl.QTB_Invoice__c =  invoiceList[0].id;
        cnl.QTB_InvoiceLine__c = invoiceLine[0].id;
        cnl.blng__Subtotal__c = 10;            
        cnl.blng__CalculateTax__c=false;
        cnl.blng__TotalAmount__c = 10;
        cnl.QTB_Credit_Quantity__c = 1;
        insert cnl;       
        
        List<blng__CreditNote__c> crdNoteList = [SELECT Id, NAme,QTB_On_Account_Credit__c, blng__Account__c,blng__Account__r.QTB_Language__c,
                                                 blng__Account__r.QTB_EDI_Identifier__c,blng__Status__c
                                                 From blng__CreditNote__c ];
        
        List<blng__CreditNoteLine__c>  crdLine = [SELECT ID, Name,blng__CreditNote__c,blng__InvoiceLine__r.blng__UsageSummary__c,blng__Product__c
                                                  FROM blng__CreditNoteLine__c];
        QTB_GenerateApixCreditNoteExtractBatch batch = new QTB_GenerateApixCreditNoteExtractBatch(crdNoteList[0].id);
        Database.executebatch(batch,1);
        Test.stopTest();
    }
    
    static testMethod void testMethod7(){
        try{
            Test.startTest();
             List<blng__CreditNote__c> crdNoteList = [SELECT Id, NAme,QTB_On_Account_Credit__c, blng__Account__c,blng__Account__r.QTB_Language__c,
                                                 blng__Account__r.QTB_EDI_Identifier__c
                                                 From blng__CreditNote__c ];
            QTB_GenerateApixCreditNoteExtractBatch.throwExplicitException = true;
            QTB_GenerateApixCreditNoteExtractBatch batch = new QTB_GenerateApixCreditNoteExtractBatch(crdNoteList[0].Id);
            Database.executebatch(batch,1);
            Test.stopTest();
        }
        Catch(Exception e){
            System.debug('Exception@@');
        }
    }


}