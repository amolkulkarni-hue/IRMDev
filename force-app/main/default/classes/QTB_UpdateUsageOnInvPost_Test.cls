/*****************************************************************************************************
* Class         : QTB_UpdateUsageOnInvPost_Test
* Purpose       : This is a Test Class used to test QTB_UpdateUsageOnInvPost
* Author        : IRM/Virtusa
* Developer     : Virtusa
* Change History: 26/04/2022
* Developer                 Date                Description 
* ------------------------------------------------------------------------------------------- 
*  Virtusa			26/04/2022          
*******************************************************************************************************/
@isTest(seealldata=false)
private class QTB_UpdateUsageOnInvPost_Test {
    @testSetup
    static void setup() {
         List<Metadata_Activation_Settings__c> custSettingList = new List<Metadata_Activation_Settings__c>();
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
        custSetting.SObject_API_Name__c = 'blng__Invoice__c;blng__InvoiceLine__c';
        custSetting.Disable_VR__c = true;
        custSetting.Disable_PB__c = true;
        custSetting.Disable_Trigger__c = true;
        custSettingList.add(custSetting);
        insert custSettingList;

        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        //System.runAs(userList[0]) {
        Id pricebookId = Test.getStandardPricebookId();
        
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
        
        //Product3  -- Bundle Header
        product2 p3 = new product2();
        p3.Name = 'Test Product3';
        p3.isActive = true;
        p3.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        p3.SBQQ__HasConsumptionSchedule__c = false;
        productList.add(p3);
        
        insert productList;
        
        //Price Book creation for all product
        PricebookEntry standardPrice1 = QTB_TestDataFactory.createPricebookEntry(productList[0]);                
        PricebookEntry standardPrice2 = QTB_TestDataFactory.createPricebookEntry(productList[1]);
        PricebookEntry standardPrice3 = QTB_TestDataFactory.createPricebookEntry(productList[2]);
        
       
        
        //Account
        List<Account> accountList = QTB_TestDataFactory.createAccounts(1,'Billing Account');
        
        System.debug('0@@'+Limits.getLimitQueries());
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        database.update(oppList);
        
        //Quote
        //List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        //quoteList[0].SBQQ__PriceBook__c = pricebookId;
        //quoteList[0].SBQQ__StartDate__c = System.Today();
        List<SBQQ__Quote__c> quoteList = NEW List<SBQQ__Quote__c>();
        SBQQ__Quote__c sbq = new SBQQ__Quote__c();
        sbq.SBQQ__Opportunity2__c = oppList[0].id;
        sbq.SBQQ__Account__c = accountList[0].id;
        sbq.SBQQ__Type__c = QTB_Constants.QUOTE_TYPE_STANDARD;
        sbq.SBQQ__Status__c = 'Draft';
        sbq.SBQQ__QuoteLanguage__c = 'English';
        sbq.SBQQ__ExpirationDate__c = date.today();
        sbq.SBQQ__Primary__c = true;
        sbq.SBQQ__PrimaryContact__c = null;
        sbq.SBQQ__StartDate__c = date.today();
        quoteList.add(sbq);
        insert quoteList;
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        update quoteList[0];
        
        //QuoteLineGroup
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        //QuoteLine
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[0].id);
        List<SBQQ__QuoteLine__c> quoteLinesList1 = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,productList[1].id);
        Test.startTest();
        //Order
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        database.update(orderList3);
        
        SBQQ.TriggerControl.disable();
        
        //OrderItem
        List<OrderItem> orderItemList2 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[0].Id,quoteLinesList,standardPrice1);
        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[1].Id,quoteLinesList,standardPrice2);
        List<OrderItem> orderItemList4 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,productList[1].Id,quoteLinesList1,standardPrice2);
        
        //Invoice
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(accountList);
        List<blng__Invoice__c> invoiceListForCredit = QTB_TestDataFactory.createInvoices(accountList);
        System.debug('1@@'+Limits.getLimitQueries());
        
         QTB_Bill_Code_Product_Lookup__c productLookup = new QTB_Bill_Code_Product_Lookup__c(
            QTB_Source_Bill_Code__c = 'VALID_CODE',
           // QTB_Country__c = im.Id,
            QTB_Product2__c = productList[0].id
        );
        insert productLookup;
       
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
        usageList[0].QTB_Product_Identifier_1__c =  productLookup.id;
        usageList[0].blng__OrderProduct__c = orderItemList3[0].id;          
        database.update(usageList);
        
        //Usage Summary for CreditNote
        List<blng__UsageSummary__c> usageSum1 = QTB_TestDataFactory.createUsageSummary(1,accountList[0],orderList3[0],orderItemList3[0]);
        blng__UsageSummary__c usagesummary1 = usageSum1[0];        
        usagesummary1.blng__Status__c = 'Queued For Invoice';
        usagesummary1.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary1.blng__Subtotal__c = 100;
        usagesummary1.blng__TotalQuantity__c = 10;
        usagesummary1.blng__PreratedQuantity__c = 20;
        usagesummary1.blng__UnbilledQuantity__c = 1;
        usagesummary1.blng__UnitPrice__c = 400;
        usagesummary1.blng__PreratedAmount__c = 22;
        usagesummary1.blng__SummaryStartDate__c = Date.valueOf('2021-07-27');
        usagesummary1.blng__Invoice__c = invoiceListForCredit[0].id;
        database.update(usagesummary1);        
        
        //Usage1 for CreditNote
        List<blng__Usage__c> usageList1 = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary1);
        usageList1[0].QTB_System_Generated__c = true;
        usageList1[0].blng__PreratedAmount__c = 100;
        usageList1[0].blng__PreratedQuantity__c = 10;
        usageList1[0].QTB_Service_District__c = '44147';
        usageList1[0].blng__Subtotal__c = 50;
        usageList1[0].QTB_Product_Identifier_1__c =  productLookup.id;
        usageList1[0].blng__OrderProduct__c = orderItemList3[0].id;          
        database.update(usageList1);
        
        //Usage2 for CreditNote
     /*   List<blng__Usage__c> usageList2 = QTB_TestDataFactory.createUsages(1,accountList[0],usagesummary1);
        usageList2[0].QTB_System_Generated__c = true;
        usageList2[0].blng__PreratedAmount__c = 100;
        usageList2[0].blng__PreratedQuantity__c = 10;
        usageList2[0].QTB_Service_District__c = '44147';
        usageList2[0].blng__Subtotal__c = 50;
        usageList2[0].QTB_Product_Identifier_1__c =  productLookup.id;
        usageList2[0].blng__OrderProduct__c = orderItemList3[0].id;          
        database.update(usageList2);
        System.debug('2@@'+Limits.getLimitQueries()); */
        
        invoiceList[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceList[0].blng__InvoiceStatus__c = 'Draft';        
        //update invoiceList[0];
        
        blng__LegalEntity__c SingaporeEntity = QTB_TestDataFactory.createLegalEntity('Singapore');
        
        blng__InvoiceRun__c  invoiceRun = new blng__InvoiceRun__c();
        invoiceRun.Name = 'test invoice';
        invoiceRun.blng__Status__c = 'Completed';
        invoiceRun.blng__TargetDate__c = System.today();
        insert invoiceRun;
        
        invoiceListForCredit[0].blng__InvoiceDate__c = Date.valueOf('2021-07-27');
        invoiceListForCredit[0].blng__InvoiceStatus__c = 'Posted';       
        invoiceListForCredit[0].blng__InvoiceRunCreatedBy__c = invoiceRun.id;
        //update invoiceListForCredit[0];
        
        
        
        blng__TaxRule__c taxRule = new blng__TaxRule__c();
        taxRule.Name = 'Standard tax Rule';
        taxRule.blng__Active__c = true;
        taxRule.blng__TaxableYesNo__c = 'Yes';
        insert taxRule;
        
        blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
        taxIntegration.blng__TaxEngine__c = 'Standard';
        taxIntegration.blng__Active__c = true;
        database.insert(taxIntegration);
        
        blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
        blngTax.blng__TaxLegalEntity__c = SingaporeEntity.id;
        blngTax.blng__TaxIntegration__c = taxIntegration.id;
        blngTax.blng__TaxRule__c = taxRule.id;
        blngTax.blng__TaxCode__c = 'STD-CGST';
        blngTax.QTB_Invoice_Print_Tax_Name__c = 'GST';
        database.insert(blngTax);
        
        System.debug('3@@'+Limits.getLimitQueries());
        List<blng__InvoiceLine__c> invLineList = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
        invLineList[0].blng__OrderProduct__c = orderItemList3[0].id;
        invLineList[0].blng__UsageSummary__c = usagesummary.id;
        invLineList[0].blng__InvoiceLineStatus__c = 'Draft';
        invLinelist[0].blng__TaxAmount__c = 50;
        invLinelist[0].blng__TaxCountry__c = 'India';
        invLinelist[0].blng__TaxState__c = 'TN';
        invLinelist[0].blng__TaxCity__c = 'Chennai';
        invLinelist[0].blng__TaxZipCode__c = '500032';
        invLinelist[0].blng__LegalEntity__c = SingaporeEntity.id;
        invLinelist[0].blng__Subtotal__c = 1000;
        invLinelist[0].blng__TaxRule__c = taxRule.id;
        invLinelist[0].blng__TaxTreatment__c = blngTax.id;
        invLinelist[0].blng__TotalAmount__c = 1000;
        //invLinelist[0].QTB_Inc_Quantity__c = 10;
        //invLinelist[0].QTB_Taxable_Amount__c = 10;
        update invLinelist[0];
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
        database.update(invLinelist[0]);
        usagesummary.blng__InvoiceLine__c = invLineList[0].id;
        database.update(usagesummary);
        
        usagesummary1.blng__InvoiceLine__c = invLineList[0].id;
        database.update(usagesummary1);
        System.debug('4@@'+Limits.getLimitQueries());
        List<blng__InvoiceLine__c> invLineList1 = QTB_TestDataFactory.createInvoiceLine(1,invoiceList,productList);
        /*invLineList1[0].blng__OrderProduct__c = orderItemList4[0].id;
        invLineList1[0].blng__Product__c =productList[0].id;
        invLineList1[0].blng__InvoiceLineStatus__c = 'Draft';
        invLineList1[0].blng__TaxAmount__c = 50;
        invLineList1[0].blng__TaxCountry__c = 'India';
        invLineList1[0].blng__TaxState__c = 'TN';
        invLineList1[0].blng__TaxCity__c = 'Mumbai';
        invLineList1[0].blng__TaxZipCode__c = '500032';
        invLineList1[0].blng__LegalEntity__c = SingaporeEntity.id;
        invLineList1[0].blng__Subtotal__c = 1000;
        invLineList1[0].blng__TaxRule__c = taxRule.id; */
        invLineList1[0].QTB_Inc_Quantity__c = 10;
        invLineList1[0].QTB_Taxable_Amount__c = 10; 
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
        database.update(invLineList1);
        
        List<blng__InvoiceLine__c> invLineListForCredit = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
        invLineListForCredit[0].blng__OrderProduct__c = orderItemList3[0].id;
        invLineListForCredit[0].blng__Product__c = productList[1].id;
        invLineListForCredit[0].blng__UsageSummary__c = usagesummary1.id;
        invLineListForCredit[0].blng__InvoiceLineStatus__c = 'Posted';
        invLineListForCredit[0].blng__TaxAmount__c = 50;
        invLineListForCredit[0].blng__TaxCountry__c = 'India';
        invLineListForCredit[0].blng__TaxState__c = 'TN';
        invLineListForCredit[0].blng__TaxCity__c = 'Chennai';
        invLineListForCredit[0].blng__TaxZipCode__c = '500032';
        invLineListForCredit[0].blng__LegalEntity__c = SingaporeEntity.id;
        invLineListForCredit[0].blng__Subtotal__c = 1000;
        invLineListForCredit[0].QTB_Inc_Quantity__c = 10;
        invLineListForCredit[0].blng__TaxRule__c = taxRule.id;
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
        database.update(invLineListForCredit);
        System.debug('5@@'+Limits.getLimitQueries());
        List<blng__InvoiceLine__c> invLineListForCredit1 = QTB_TestDataFactory.createInvoiceLine(1,invoiceListForCredit,productList);
        invLineListForCredit1[0].blng__OrderProduct__c = orderItemList4[0].id;
        invLineListForCredit1[0].blng__Product__c = productList[0].id;
        invLineListForCredit1[0].blng__UsageSummary__c = null;
        invLineListForCredit1[0].blng__InvoiceLineStatus__c = 'Posted';
        invLineListForCredit1[0].blng__TaxAmount__c = 50;        
        invLineListForCredit1[0].blng__TaxCountry__c = 'India';
        invLineListForCredit1[0].blng__TaxState__c = 'TN';
        invLineListForCredit1[0].blng__TaxCity__c = 'Chennai';
        invLineListForCredit1[0].blng__TaxZipCode__c = '500032';
        invLineListForCredit1[0].blng__LegalEntity__c = SingaporeEntity.id;
        invLineListForCredit1[0].blng__Subtotal__c = 1000;
        invLineListForCredit1[0].blng__TaxRule__c = taxRule.id;
        invLineListForCredit1[0].QTB_Inc_Quantity__c = 10;
        invLineListForCredit1[0].QTB_Taxable_Amount__c = 10;
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
        database.update(invLineListForCredit);
        
        usagesummary1.blng__InvoiceLine__c = invLineListForCredit[0].id;
        database.update(usagesummary1);        
        Test.stopTest();
    }
    
    //covering invoice 
    static testMethod void testmethodInvoice1() {
            List<blng__Invoice__c> invoiceList = [
                SELECT id, QTB_Custom_Invoice_Number__c,QTB_KID__c,blng__TaxStatus__c,QTB_InvoiceRecordType__c,name,blng__InvoiceStatus__c,blng__Account__r.Name,blng__Account__r.QTB_Contract_Entity__c,
                blng__Account__r.CurrencyIsoCode,blng__Account__r.ShippingCountry,blng__Account__r.QTB_Customer_Number__c,blng__Account__r.QTB_Contract_Entity__r.blng__Country__c,QTB_Bill_Cycle_Day__c,
                blng__Account__r.QTB_Hold_Invoice__c,blng__Account__r.ShippingState,blng__Account__r.QTB_Billing_Account_Invoice_Name__c,
                blng__Account__r.QTB_Contract_Entity__r.QTB_Legal_Entity_Number__c,recordTypeId,blng__InvoiceRunCreatedBy__c
                FROM blng__Invoice__c];
            
            Set<id> invId = new  Set<id>();
            for(blng__Invoice__c invoice : invoiceList){
                invId.add(invoice.Id);
            }
            Test.startTest();           
            QTB_UpdateUsageOnInvPost res = new QTB_UpdateUsageOnInvPost(invId);
            Database.executeBatch(res);
            
         // System.Assert(invLineList[0].blng__InvoiceLineStatus__c == 'Posted');
            
            Test.stopTest();
        } 
    //to cover Catch
    static testMethod void testMethod2() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        System.runAs(userList[1]) {
            Test.startTest();
            List<Account> testAccounts = QTB_TestDataFactory.createAccounts(
                1,
                'Standard Account'
            );
            List<blng__Invoice__c> InvoiceList1 = QTB_TestDataFactory.createInvoices(
                testAccounts
            );
            Set<Id> lstTopass2= new Set<Id>();
            lstTopass2.add(InvoiceList1[0].id);
            QTB_UpdateUsageOnInvPost.throwExplicitException = true;
            QTB_UpdateUsageOnInvPost obj = new QTB_UpdateUsageOnInvPost(lstTopass2);
            obj.execute(null, null);
            Test.stopTest();
            System.assertEquals(
                true,
                QTB_UpdateUsageOnInvPost.throwExplicitException
            );
        }
    }
    }