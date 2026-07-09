/*****************************************************************************************************
* Class: QTB_OrderPluginTest
* Author: Virtusa
* Purpose: This is a test class for QTB_OrderPlugin
* Change History: 11/22/2021
* Developer     Date           Description
* -------------------------------------------------------------------------------------------
* Virtusa     11/22/2021       Git #6306 / #5837 
*******************************************************************************************************/
@isTest(seealldata=false)
private with sharing class QTB_OrderPluginTest {
    @TestSetup
    static void createData() {
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
       
        System.runAs(userList[0]) {
            List<account> accountList = QTB_TestDataFactory.createAccounts(1);
            accountList[0].BillingCountry = 'India';
            accountList[0].QTB_Legal_Entity_Country__c = 'United States';
            update accountList;
            blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
            blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
            blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
            
            //Creation -- Product Data
            List<product2> product = QTB_TestDataFactory.createProducts(1);
            product[0].blng__BillingRule__c = billingRule.id;
            product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
            product[0].blng__TaxRule__c = taxRule.id;
            database.update(product);
            
            //Creation -- Pricebook
            Id pricebookId = Test.getStandardPricebookId();
            PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(product[0]);
            
            // Update the pricebook of opportunity
            List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
            oppList[0].Pricebook2Id = pricebookId;
            database.update(oppList);
            
            //Creation -- Quote
            List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
                1,
                oppList[0].id,
                accountList[0].id,
                true,
                null
            );
            quoteList[0].SBQQ__PriceBook__c = pricebookId;
            quoteList[0].SBQQ__StartDate__c = System.Today();
            database.update(quoteList);
            
            //Creation -- QuoteLineGroup
            List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
                1,
                quoteList[0].id,
                accountList[0].id
            );
            
            //Creation -- QuoteLine
            List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(
                1,
                quoteList[0].id,
                quoteGroupList[0].id,
                product[0].id
            );
            SBQQ.Triggercontrol.Disable();
            List<Order> orderList1 = QTB_TestDataFactory.createCPQOrders(
                1,
                quoteList[0].Id,
                accountList[0].id
            );
            orderList1[0].blng__BillingAccount__c = accountList[0].id;
            orderList1[0].RecordTypeId = QTB_Utils.ORDER_SALES_RECTYPEID;
            orderList1[0].SBQQ__PriceCalcStatus__c = 'Not Needed';
            try{
                database.update(orderList1);
            }
            catch(Exception e){
                
            }
            orderList1[0].RecordTypeId = QTB_Utils.ORDER_BILL_RECTYPEID;
            try{
                database.update(orderList1);
            }
            catch(Exception e){
                
            }
            List<Order> orderList2 = QTB_TestDataFactory.createBillingOrders(
                1,
                quoteList[0].Id,
                accountList[0].id
            );
            
            List<OrderItem> orderItemList = QTB_TestDataFactory.createCPQOrderItems(
                orderList1[0].Id,
                product[0].Id,
                quoteLinesList,
                standardPrice
            );
            
            ID recTypeId =  DataFactory.getRecordTypeId('Case','NCSP: New Customer Setup');
            User owner1 = DataFactory.createUsers(1)[0];
            User currentUser = new User ( Id = UserInfo.getUserId() );
            
            //Creation of Contact
            Contact caseContact = new Contact(FirstName = 'Test', accountid = accountList[0].id,  LastName = 'User', MailingCountry = 'India');
            insert caseContact;
            
            //Creation of Case
            case testCase = new case();
            testCase.Status = 'New';
            testCase.RecordTypeId = recTypeId;
            testCase.Origin = 'Inside Sales'; 
            testCase.NCSP_Service_line__c= 'DB&R';
            testCase.Date_Paperwork_Received__c = system.today();
            testCase.Sales_Person_Name_Account_Manager__c = owner1.id;        
            testCase.Setup_Type__c = 'Standard';
            testCase.Contact = caseContact;
            testCase.Account = accountList[0];  
            testCase.NCSP_Opportunity__c = oppList[0].id;
            testCase.Contract_Status__c = 'Accepted';
            testCase.QTB_Billing_Start_Date__c = system.today();
            testCase.Case_Type__c = 'Government';
            testCase.Contract_Type__c = 'Affiliate Option 2';
            testCase.Rejection_Comments__c='testing';
            testCase.Primary_Contract_Rejection_Reason__c='testing';
            Test.startTest();
            insert testCase;
            
            Test.stopTest();
        }
    }
    
    //PositiveTesting
    static testMethod void testmethod1() {
        Test.startTest();
        try {   
             List<SBQQ__Quote__c> quoteList = [SELECT Id,SBQQ__Primary__c,SBQQ__StartDate__c,SBQQ__Opportunity2__c 
                                              FROM SBQQ__Quote__c ];
             QTB_OrderPlugin ordPlug = new QTB_OrderPlugin();
             ordPlug.getOrderStartDate(quoteList[0].id);
        }
        catch (NullPointerException e) {
            System.assertEquals('System.NullPointerException', e.getTypeName());
        }
        Test.stopTest();        
    }
}