/*****************************************************************************************************
* Class: QTB_RenewalUpliftBatch_Test
* Author: Accenture
* Purpose: Test Class for QTB_RenewalUpliftBatch
* Change History: 6/19/2020
* Developer     Date           Description
* ------------------------------------------------------------------------------------------- 
* Accenture   6/10/2020
*******************************************************************************************************/
@isTest(seeAllData=false)
private with sharing class QTB_RenewalUpliftBatch_Test {
    @testSetup static void setup() {
        List<Account> accList = QTB_TestDataFactory.createAccounts(1, 'Standard Account');
        accList[0].name = 'Account for Renewal Uplift';
        database.update(accList);
        
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule= QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product=QTB_TestDataFactory.createProducts(1);
        product[0].blng__BillingRule__c=billingRule.id;
        product[0].blng__RevenueRecognitionRule__c =revenueRule.id;
        product[0].blng__TaxRule__c =taxRule.id;
        database.update(product); 
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
        
        IM_Country__c country = new IM_Country__c(Name = 'United States',Iso31662Code__c='US');
        database.insert(country);
               
        List<Opportunity> oppList = QTB_TestDataFactory.createOpps(accList);
        oppList[0].Pricebook2Id =pricebookId;
        oppList[0].billing_country__c = country.id;
        oppList[0].recordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
        oppList[0].Primary_Product_Line__c ='Records Management';
        
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(1,oppList[0].id,accList[0].id,true,null);
        quoteList[0].SBQQ__PriceBook__c=pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].SBQQ__Status__c ='Draft';
        
        update quoteList;
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(1, quoteList[0].id,accList[0].id );
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(1,quoteList[0].id,quoteGroupList[0].id,product[0].id );
        quoteList[0].SBQQ__Status__c ='Approved';
        
        update quoteList;
        
        List<Order> orderList = QTB_TestDataFactory.createCPQOrders(1,quoteList[0].id,accList[0].id);
        List<Contract> testContracts = QTB_TestDataFactory.createCPQContracts(1,orderList[0].id,accList[0].id,quoteList[0].id);
        testContracts[0].SBQQ__Quote__c = quoteList[0].id;
        database.update(testContracts);
        Test.startTest();
        List<Opportunity> testRenewalOpp = QTB_TestDataFactory.createCPQOppsNew(accList,'CPQ Sales Opportunity');
        testRenewalOpp[0].SBQQ__RenewedContract__c = testContracts[0].id;
        testRenewalOpp[0].QTB_Deferred_Renewal_Opportunity__c = True;
         testRenewalOpp[0].QTB_Original_Quote__c =quoteList[0].id;
        testRenewalOpp[0].billing_country__c = country.id;
        testRenewalOpp[0].Primary_Product_Line__c ='Records Management';
        database.update(testRenewalOpp);
        
        List<SBQQ__Quote__c> testRenewalQuotes = QTB_TestDataFactory.createRenewalQuotes(1, testRenewalOpp[0].Id, oppList[0].AccountId, false, null);
        
        testRenewalQuotes[0].SBQQ__Opportunity2__c = testRenewalOpp[0].id;
        testRenewalQuotes[0].SBQQ__Status__c = 'Draft';
        database.update(testRenewalQuotes);
        
        List<SBQQ__QuoteLineGroup__c> quoteGroupList4 = QTB_TestDataFactory.createCPQQuoteLineGroups(1, testRenewalQuotes[0].id,accList[0].id );
        List<SBQQ__QuoteLine__c> quoteLinesList4 = QTB_TestDataFactory.createCPQQuoteLines(1,testRenewalQuotes[0].id,quoteGroupList4[0].id,product[0].id );
        quoteLinesList4[0].SBQQ__ListPrice__c =10;
        database.update(quoteLinesList4);
        
        QTB_Bill_Code_Product_Lookup__c  billcode = new QTB_Bill_Code_Product_Lookup__c();
        billcode.QTB_Product2__c =product[0].id;
        billcode.QTB_Active__c= True;
        billcode.QTB_Primary__c= True;
        Billcode.QTB_Pricing_Bill_Code__c='201';
        Billcode.QTB_Country__c =country.id;
        Billcode.QTB_Source_Bill_Code__c='201';
        database.insert(billcode);
        
        IM_Customer_Account__c customerAccount = new IM_Customer_Account__c();
        customerAccount.name = 'test';
        customerAccount.Billing_Country__c=country.id;
        customerAccount.IM_Account__c=accList[0].id;
        database.insert(customerAccount);
        
        List<QTB_Customer_Billing_Account_Lookup__c> customerTableRecords = new List<QTB_Customer_Billing_Account_Lookup__c>();
        QTB_Customer_Billing_Account_Lookup__c customerTable = new QTB_Customer_Billing_Account_Lookup__c();
        customerTable.QTB_Pricefx_Customer_ID__c ='140AI';
        customerTable.QTB_Quote__c =quoteList[0].id;
        customerTable.QTB_Customer_Account__c=customerAccount.id;
        customerTable.QTB_Compound_Key__c='xyz';
        customerTableRecords.add(customerTable);
               
        QTB_Customer_Billing_Account_Lookup__c customerTable2 = new QTB_Customer_Billing_Account_Lookup__c();
        customerTable2.QTB_Pricefx_Customer_ID__c ='142ER';
        customerTable2.QTB_Quote__c =quoteList[0].id;
        customerTable2.QTB_Customer_Account__c=customerAccount.id;
        customerTable2.QTB_Compound_Key__c='test';
        customerTableRecords.add(customerTable2);
        database.insert(customerTableRecords);
        
        Test.stopTest();
        
    }
    
    static testmethod void test() { 
        Test.startTest();
        set<ID> contrIDset = new set<ID>();
        list<Account> accountList = [select id,name from account  limit 1];
        for(Contract con :[select id,name,AccountID from contract where AccountID =:accountList[0].id])
        {
            contrIDset.add(con.Id);
        }       
        QTB_RenewalUpliftBatch obj = new QTB_RenewalUpliftBatch(contrIDset);
        Test.setMock(HttpCalloutMock.class, new QTB_MockPricefxCalloutRenewal());
        DataBase.executeBatch(obj);
        Test.stopTest(); 
        System.assert(accountList.size()>0);
    }
    
    
}