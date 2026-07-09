/*****************************************************************************************************
* Class: QTB_Batch_InvoiceUpdateForBoxSummaryTest
* Author: Virtusa
* Purpose: This is a test class for QTB_Batch_InvoiceUpdateForBoxSummary
* Requirement:
* Change History: 11/06/2024
* Developer				Date           Description
* -------------------------------------------------------------------------------------------
* Lokesh(Virtusa)        20/05/2024
*******************************************************************************************************/
@isTest
public class QTB_Batch_InvoiceUpdateForBoxSummaryTest {
 @testSetup()
    static void setup(){
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        QTB_Billing_Countries__c BillingCountries = new QTB_Billing_Countries__c();
        BillingCountries.Name = 'Singapore';
        BillingCountries.Legal_entity_country__c = 'Singapore' ;
        insert BillingCountries;
        
        //Product
        List<product2> product = QTB_TestDataFactory.createProducts(3);
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        database.update(product);
        
        //Pricebook
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        //Account
        List<Account> accountList = new List<Account>();
        ID StandardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
        Id recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
        for (Integer i = 0; i < 10; i++) {
            Account a = new Account();
            a.Name = (a.Name == null ? 'Test' : a.Name) + i;
            a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
            a.RecordTypeId = recordTypeValue;
            a.QTB_Create_Parent_Billing_Account__c = true;
            a.Name = 'Test Account';
            a.BillingCountry = 'Singapore';
            a.BillingPostalCode = '11209';
            a.BillingState = 'TN';
            a.Registration_Number__c = 'Reg';
            a.ShippingCountry = 'India';
            a.QTB_Legal_Entity_Country__c='Singapore';
            a.QTB_Split_Invoice_Flag__c = true;
            a.IM_Hierarchy_Level__c = 'Billing Account';
            accountList.add(a);
        }
        
        if (!accountList.isEmpty()) {
            insert accountList;
        }
        
        
        //Legal Entity
        blng__LegalEntity__c USEntity = new blng__LegalEntity__c();
        USEntity.Name = 'Test Legal Entity United States';
        USEntity.blng__Active__c = true;
        USEntity.blng__Country__c = 'United States';
        USEntity.QTB_Type__c = 'Contract';
        USEntity.QTB_Tax_Applicability__c = 'Flat Rate';
        //USEntity.QTB_Legal_Entity_Number__c = '45000';
        insert USEntity;
        
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';    
        im.Active__c = true;
        insert im;
        
        //opportunity
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].Pricebook2Id = pricebookId;
        //oppList[0].Legal_Entity__c = USEntity.id;
        oppList[0].Billing_Country__c = im.id;
        database.update(oppList);
        test.startTest();
        //Quote
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accountList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].QTB_IM_Legal_Entity__c = USEntity.id;
        quoteList[0].QTB_Opportunity_Billing_Country__c = 'United States';
        database.update(quoteList);
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1,quoteList[0].id,accountList[0].id);
        
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id);
        
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].Id,accountList[0].id);
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        
        database.update(orderList3);
        
        SBQQ.TriggerControl.disable();
        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(orderList3[0].Id,product[0].Id,quoteLinesList,standardPrice);
        orderItemList3[0].blng__HoldBilling__c = 'Yes';
        orderItemList3[0].blng__InvoiceGroupId__c = 'Non-Storage';
        update orderItemList3;
        Contact cont = new Contact();
        cont.LastName = 'test1 ';
        cont.FirstName = 'abc ';
        cont.email = 'so1@email.com';
        cont.AccountId = accountList[0].Id;
        cont.MailingCountry = 'United States';
        cont.IM_Role__c = 'PO Contact';
        insert cont;
        
        AccountContactRelation acr = new AccountContactRelation();
        acr.accountId = accountList[1].id;
        acr.ContactId = cont.Id;
        acr.Roles = 'PO Contact';
        insert acr;
        
        QTB_Box_Summary__c bs = new QTB_Box_Summary__c();
        bs.QTB_ServicePeriod__c = 'Mar-2024';
        //sbs.QTB_Customer_Number__c ='001';
        insert bs;
        system.debug('128   '+bs);
        //system.debug('12999    '+bs.QTB_Customer_Number__c);
        
        //Invoice
        List<blng__Invoice__c> invoiceList = new List<blng__Invoice__c>();
        for (Account acc : accountList) {
            blng__Invoice__c invoice = new blng__Invoice__c();
            invoice.blng__Account__c = acc.Id;
            invoice.blng__InvoiceStatus__c = 'Draft';
            invoice.QTB_Service_Start_Date__c = 
                invoice.blng__InvoiceDate__c = System.today()-10;
            invoice.QTB_Service_Type__c = 'Storage';
            //invoice.QTB_Custom_Invoice_Number__c = bs.QTB_Customer_Number__c;
            invoiceList.add(invoice);
            break;
        }
        if (!invoiceList.isEmpty()) {
            insert invoiceList;
        }
        system.debug('14666    '+invoiceList);
        List<blng__InvoiceLine__c> invLineList = QTB_TestDataFactory.createInvoiceLine(1,invoiceList,product);
        invLineList[0].blng__OrderProduct__c = orderItemList3[0].Id;
        invLineList[0].blng__TaxCountry__c = 'United States';
        //update invLineList;
        
        //Legal Entity
        blng__LegalEntity__c singaporeEntity = new blng__LegalEntity__c();
        singaporeEntity.Name = 'Test Legal Entity Singapore';
        singaporeEntity.blng__Active__c = true;
        singaporeEntity.blng__Country__c = 'Singapore';
        singaporeEntity.QTB_Type__c = 'Contract';
        // indiaEntity.QTB_Legal_Entity_Number__c = '45000';
        insert singaporeEntity; 
        
        //Billing Finanace
        blng__FinanceBook__c singaporeFinanceBook = new blng__FinanceBook__c();
        singaporeFinanceBook.Name = 'Accounting Finance Book';
        singaporeFinanceBook.blng__FinancePeriodDuration__c = 'Monthly';
        singaporeFinanceBook.blng__Active__c = true;
        singaporeFinanceBook.blng__PeriodType__c='Accounting';
        insert singaporeFinanceBook;
        
        
        blng__FinancePeriod__c singaporeFinancePeriod = new blng__FinancePeriod__c();
        singaporeFinancePeriod.Name = 'Mar-2024';
        singaporeFinancePeriod.blng__FinanceBook__c = singaporeFinanceBook.id;
        singaporeFinancePeriod.blng__PeriodStartDate__c = system.today().toStartofMonth();
        singaporeFinancePeriod.blng__PeriodEndDate__c = system.today().addMonths(1).toStartofMonth().addDays(-1);
        singaporeFinancePeriod.blng__LegalEntity__c = singaporeEntity.id;
        singaporeFinancePeriod.blng__PeriodStatus__c = 'Pending Open';
        insert singaporeFinancePeriod;        
        test.stopTest();
    }
    static testMethod void test1(){
        Test.startTest();   
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
         QTB_Batch_InvoiceUpdateForBoxSummary.throwExplicitException = true;
        try{
            QTB_Batch_InvoiceUpdateForBoxSummary obj = new QTB_Batch_InvoiceUpdateForBoxSummary();
            obj.execute(null,Null); 
            obj.finish(Null);
            
        }catch(exception e){
                System.debug('message--->'+e.getMessage());
                system.assertEquals('Script-thrown exception',e.getMessage());
            }
        Test.stopTest();
    }
    static testMethod void test2(){
        Test.startTest();
        List<User> userList = QTB_TestDataFactory.usrMethdLst(2);
        List<blng__Invoice__c> invMap = [Select id,QTB_Custom_Invoice_Number__c,QTB_Service_Start_Date__c,QTB_Service_End_Date__c,QTB_Service_Type__c,blng__Account__c,blng__Account__r.QTB_Split_Invoice_Flag__c
                                         from blng__invoice__c];
        Map<String,blng__Invoice__c> mapCustmInvcNumberInvc = new Map<String,blng__Invoice__c>();
        mapCustmInvcNumberInvc.put(invMap[0].QTB_Custom_Invoice_Number__c,invMap[0]);
        system.debug('20999    '+mapCustmInvcNumberInvc);
        Set<string> sp = new set<string>{'Mar-2024','Apr-2024'};
            
                   
        QTB_Batch_InvoiceUpdateForBoxSummary batch = new QTB_Batch_InvoiceUpdateForBoxSummary();
        Database.executeBatch(batch,20);
        test.stopTest();
        
    }
    
}