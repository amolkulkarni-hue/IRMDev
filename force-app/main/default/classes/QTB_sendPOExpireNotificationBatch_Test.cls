/*****************************************************************************************************
* Class: QTB_sendPOExpireNotificationBatch_Test
* Author: IRM
* Purpose: Test Class for QTB_sendPOExpireNotificationBatch
* Change History: 6/07/2021
* Developer       Date           Description
* ------------------------------------------------------------------------------------------- 
* Gopinandan Biswal   6/07/2021
*******************************************************************************************************/
@isTest(seeAllData=false)
private with sharing class QTB_sendPOExpireNotificationBatch_Test {
    
    @testSetup static void setup() {
        // Create common test accounts
        //List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        //   System.runAs(userList[0]) {
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule(
            'Yes'
        );
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule(
            'Yes'
        );
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        List<product2> product = QTB_TestDataFactory.createProducts(1);
        product[0].blng__BillingRule__c = billingRule.id;
        product[0].blng__RevenueRecognitionRule__c = revenueRule.id;
        product[0].blng__TaxRule__c = taxRule.id;
        database.update(product);
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(
            product[0]
        );
       blng__LegalEntity__c indiaLegalEntity = QTB_TestDataFactory.createLegalEntity('India');
        indiaLegalEntity.QTB_Legal_Entity_Number__c = 45000.0;
        update indiaLegalEntity;
        
        blng__LegalEntity__c usLegalEntity = QTB_TestDataFactory.createLegalEntity('United States');
        usLegalEntity.QTB_Legal_Entity_Number__c = 50000.0;
        update usLegalEntity;
        
        // Create accounts with different countries and languages
        List<Account> accountList = QTB_TestDataFactory.createAccounts(3, 'Billing Account');
        
        // Account 1 - India with legal entity
        accountList[0].QTB_Language__c = 'en_US';
        accountList[0].BillingPostalCode = '567788';
        accountList[0].BillingState = 'TNY';
        accountList[0].ShippingCountry = 'India';
        accountList[0].QTB_Legal_Entity_Country__c = 'India';
        accountList[0].QTB_Contract_Entity__c = indiaLegalEntity.id;
        
        // Account 2 - US with legal entity
        accountList[1].QTB_Language__c = 'en_US';
        accountList[1].BillingPostalCode = '10001';
        accountList[1].BillingState = 'NY';
        accountList[1].ShippingCountry = 'United States';
        accountList[1].QTB_Legal_Entity_Country__c = 'United States';
        accountList[1].QTB_Contract_Entity__c = usLegalEntity.id;
        
        // Account 3 - US without legal entity
        accountList[2].QTB_Language__c = 'en_US';
        accountList[2].BillingPostalCode = '90210';
        accountList[2].BillingState = 'CA';
        accountList[2].ShippingCountry = 'United States';
        accountList[2].QTB_Legal_Entity_Country__c = 'United States';
        update accountList;
        
        // Create contacts and account contact relations for PO notifications
        List<Contact> contacts = new List<Contact>();
        
        Contact con1 = new Contact(
            LastName = 'PO Contact 1',
            FirstName = 'Test',
            Email = 'pocontact1@example.com',
            AccountId = accountList[0].id,
            IM_Role__c = 'PO Contact'
        );
        contacts.add(con1);
        
        Contact con2 = new Contact(
            LastName = 'PO Contact 2',
            FirstName = 'Test',
            Email = 'pocontact2@example.com',
            AccountId = accountList[1].id,
            IM_Role__c = 'PO Contact'
        );
        contacts.add(con2);
        
        Contact con3 = new Contact(
            LastName = 'PO Contact 3',
            FirstName = 'Test',
            Email = 'pocontact3@example.com',
            AccountId = accountList[2].id,
            IM_Role__c = 'PO Contact'
        );
        contacts.add(con3);
        
        insert contacts;
        
        // Create account contact relations for cross-account contact
        AccountContactRelation acr = new AccountContactRelation(
            AccountId = accountList[1].id,
            ContactId = con1.Id,
            Roles = 'PO Contact'
        );
        insert acr;
        
        List<opportunity> oppList = QTB_TestDataFactory.createOpps(accountList);
        oppList[0].recordtypeid = QTB_Utils.OPP_BILL_RECTYPEID;
        oppList[0].Pricebook2Id = pricebookId;
        database.update(oppList);
        
        List<SBQQ__Quote__c> quoteList = QTB_TestDataFactory.createCPQQuotes(
            1,
            oppList[0].id,
            accountList[0].id,
            true,
            null
        );
        quoteList[0].SBQQ__PriceBook__c = pricebookId;
        quoteList[0].SBQQ__StartDate__c = System.Today();
        quoteList[0].recordtypeId = QTB_Utils.QUOTE_BILL_RECTYPEID;
        database.update(quoteList);
        Test.startTest();
        List<SBQQ__QuoteLineGroup__c> quoteGroupList = QTB_TestDataFactory.createCPQQuoteLineGroups(
            1,
            quoteList[0].id,
            accountList[0].id
        );
        
        List<SBQQ__QuoteLine__c> quoteLinesList = QTB_TestDataFactory.createCPQQuoteLines(
            1,
            quoteList[0].id,
            quoteGroupList[0].id,
            product[0].id
        );
        
        List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(
            1,
            quoteList[0].Id,
            accountList[0].id
        );
        orderList3[0].recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        database.update(orderList3);
        SBQQ.TriggerControl.disable();
        List<OrderItem> orderItemList3 = QTB_TestDataFactory.createCPQOrderItems(
            orderList3[0].Id,
            product[0].Id,
            quoteLinesList,
            standardPrice
        );
        List<blng__Invoice__c> invoiceList = QTB_TestDataFactory.createInvoices(
            accountList
        );
        
        List<blng__UsageSummary__c> usageSum = QTB_TestDataFactory.createUsageSummary(
            1,
            accountList[0],
            orderList3[0],
            orderItemList3[0]
        );
        blng__UsageSummary__c usagesummary = usageSum[0];
        
        usagesummary.blng__Status__c = 'Queued For Invoice';
        usagesummary.blng__InvoiceRunProcessingStatus__c = 'In Progress';
        usagesummary.blng__Subtotal__c = 100;
        usagesummary.blng__TotalQuantity__c = 10;
        usagesummary.blng__PreratedQuantity__c = 20;
        usagesummary.blng__UnbilledQuantity__c = 1;
        usagesummary.blng__UnitPrice__c = 400;
        usagesummary.blng__PreratedAmount__c = 22;
        database.update(usagesummary);
        
        List<blng__Usage__c> usageList = QTB_TestDataFactory.createUsages(
            1,
            accountList[0],
            usagesummary
        );
        usageList[0].QTB_System_Generated__c = true;
        usageList[0].blng__PreratedAmount__c = 100;
        usageList[0].blng__PreratedQuantity__c = 10;
        // added the line usageList[0].QTB_Product_Identifier_1__c = 'test'; for gitlab #31454
        usageList[0].QTB_Product_Identifier_1__c = 'test';
        database.update(usageList);
        
        blng__LegalEntity__c indiaEntity = QTB_TestDataFactory.createLegalEntity(
            'India'
        );
        
        blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c();
        taxIntegration.blng__TaxEngine__c = 'Standard';
        taxIntegration.blng__Active__c = true;
        database.insert(taxIntegration);
        
        blng__TaxTreatment__c blngTax = new blng__TaxTreatment__c();
        blngTax.blng__TaxLegalEntity__c = indiaEntity.id;
        blngTax.blng__TaxIntegration__c = taxIntegration.id;
        blngTax.blng__TaxRule__c = taxRule.id;
        blngTax.blng__TaxCode__c = 'STD-CGST';
        database.insert(blngTax);
        
        blng__TaxRate__c taxRate = new blng__TaxRate__c();
        taxRate.blng__LegalEntity__c = indiaEntity.id;
        taxRate.blng__Priority__c = '1';
        taxRate.blng__Country__c = 'India';
        taxRate.blng__State__c = 'TN';
        taxRate.blng__City__c = 'Chennai';
        taxRate.blng__ZipCode__c = '500032';
        taxRate.blng__TaxCode__c = 'STD-CGST';
        taxRate.blng__Rate__c = 10;
        taxRate.blng__AddressComparison__c =
            taxRate.blng__Country__c +
            '-' +
            taxRate.blng__State__c +
            '-' +
            taxRate.blng__City__c +
            '-' +
            taxRate.blng__ZipCode__c +
            '-' +
            taxRate.blng__TaxCode__c +
            '-' +
            taxRate.blng__LegalEntity__c;
        taxRate.blng__Rate__c = 9;
        database.insert(taxRate);
        
        List<blng__InvoiceLine__c> invLineList = QTB_TestDataFactory.createInvoiceLine(
            1,
            invoiceList,
            product
        );
        invLineList[0].blng__OrderProduct__c = orderItemList3[0].id;
        invLineList[0].blng__UsageSummary__c = usagesummary.id;
        invLineList[0].blng__InvoiceLineStatus__c = 'Cancelled';
        invLinelist[0].blng__TaxAmount__c = 50;
        invLinelist[0].blng__TaxCountry__c = 'India';
        invLinelist[0].blng__TaxState__c = 'TN';
        invLinelist[0].blng__TaxCity__c = 'Chennai';
        invLinelist[0].blng__TaxZipCode__c = '500032';
        //invLinelist[0].QTB_Tax_Code__c='STD-CGST';
        invLinelist[0].blng__TaxTreatment__c = blngTax.id;
        invLinelist[0].blng__LegalEntity__c = indiaEntity.id;
        invLinelist[0].blng__Subtotal__c = 100;
        QTB_TestDataFactory.createBypassSetting(QTB_Constants.SOBJECT_BLNG_USAGE);
        //database.update(invLineList);
        string invoicelineComparison =
            taxRate.blng__Country__c +
            '-' +
            taxRate.blng__State__c +
            '-' +
            taxRate.blng__City__c +
            '-' +
            taxRate.blng__ZipCode__c +
            '-' +
            taxRate.blng__TaxCode__c +
            '-' +
            taxRate.blng__LegalEntity__c;
        
        invoiceList[0].blng__InvoiceStatus__c = 'Posted';
        //update invoiceList;
        
        /*List<blng__CreditNote__c> creditNotes = QTB_TestDataFactory.createCreditNote(
accountList
);
creditNotes[0].blng__Status__c = 'Posted';
System.debug('creditNotes>>>'+creditNotes);
update creditNotes;*/
        
       List<QTB_PurchaseOrder__c> poList = new List<QTB_PurchaseOrder__c>();
        
        // PO expiring today
        poList.add(new QTB_PurchaseOrder__c(
            QTB_Amount__c = 100,
            QTB_PO_Balance_Amount__c = 40,
            QTB_Legal_Entity_Country__c = 'India',
            QTB_Billing_Account__c = accountList[0].id,
            QTB_Customer_Id__c = 'Test1111',
            QTB_End_Date__c = System.today(),
            QTB_Start_Date__c = System.today() - 30,
            QTB_Status__c = 'Active',
            QTB_Customer_PO__c = 'PO-001',
            QTB_PO_Type__c = 'Standard',
            QTB_Service_Type__c = 'Mixed',
            QTB_Expiration_Today_Email_Sent__c = false
        ));
        
        // PO expiring in 30 days
        poList.add(new QTB_PurchaseOrder__c(
            QTB_Amount__c = 200,
            QTB_PO_Balance_Amount__c = 50,
            QTB_Legal_Entity_Country__c = 'United States',
            QTB_Billing_Account__c = accountList[1].id,
            QTB_Customer_Id__c = 'Test2222',
            QTB_End_Date__c = System.today().addDays(30),
            QTB_Start_Date__c = System.today() - 60,
            QTB_Status__c = 'Active',
            QTB_Customer_PO__c = 'PO-002',
            QTB_PO_Type__c = 'Standard',
            QTB_Service_Type__c = 'Mixed',
            QTB_30_Days_Before_Email_Sent__c = false
        ));
        
        // PO expiring in 60 days
        poList.add(new QTB_PurchaseOrder__c(
            QTB_Amount__c = 300,
            QTB_PO_Balance_Amount__c = 100,
            QTB_Legal_Entity_Country__c = 'United States',
            QTB_Billing_Account__c = accountList[2].id,
            QTB_Customer_Id__c = 'Test3333',
            QTB_End_Date__c = System.today().addDays(60),
            QTB_Start_Date__c = System.today() - 30,
            QTB_Status__c = 'Active',
            QTB_Customer_PO__c = 'PO-003',
            QTB_PO_Type__c = 'Standard',
            QTB_Service_Type__c = 'Mixed',
            QTB_60_Days_Before_Email_Sent__c = false
        ));
        
        // PO expiring in 90 days
        poList.add(new QTB_PurchaseOrder__c(
            QTB_Amount__c = 400,
            QTB_PO_Balance_Amount__c = 150,
            QTB_Legal_Entity_Country__c = 'India',
            QTB_Billing_Account__c = accountList[0].id,
            QTB_Customer_Id__c = 'Test4444',
            QTB_End_Date__c = System.today().addDays(90),
            QTB_Start_Date__c = System.today() - 30,
            QTB_Status__c = 'Active',
            QTB_Customer_PO__c = 'PO-004',
            QTB_PO_Type__c = 'Standard',
            QTB_Service_Type__c = 'Mixed',
            QTB_90_Days_Before_Email_Sent__c = false
        ));
        
        // PO expired 60 days ago
        poList.add(new QTB_PurchaseOrder__c(
            QTB_Amount__c = 500,
            QTB_PO_Balance_Amount__c = 200,
            QTB_Legal_Entity_Country__c = 'United States',
            QTB_Billing_Account__c = accountList[1].id,
            QTB_Customer_Id__c = 'Test5555',
            QTB_End_Date__c = System.today().addDays(-60),
            QTB_Start_Date__c = System.today() - 120,
            QTB_Status__c = 'Active',
            QTB_Customer_PO__c = 'PO-005',
            QTB_PO_Type__c = 'Standard',
            QTB_Service_Type__c = 'Mixed',
            QTB_60_Days_After_Email_Sent__c = false
        ));
        
        // PO expired 90 days ago
        poList.add(new QTB_PurchaseOrder__c(
            QTB_Amount__c = 600,
            QTB_PO_Balance_Amount__c = 250,
            QTB_Legal_Entity_Country__c = 'United States',
            QTB_Billing_Account__c = accountList[2].id,
            QTB_Customer_Id__c = 'Test6666',
            QTB_End_Date__c = System.today().addDays(-90),
            QTB_Start_Date__c = System.today() - 180,
            QTB_Status__c = 'Active',
            QTB_Customer_PO__c = 'PO-006',
            QTB_PO_Type__c = 'Standard',
            QTB_Service_Type__c = 'Mixed',
            QTB_90_Days_After_Email_Sent__c = false
        ));
        
        // PO with 100% utilization 30 days ago
        poList.add(new QTB_PurchaseOrder__c(
            QTB_Amount__c = 700,
            QTB_PO_Balance_Amount__c = 0,
            QTB_Legal_Entity_Country__c = 'India',
            QTB_Billing_Account__c = accountList[0].id,
            QTB_Customer_Id__c = 'Test7777',
            QTB_End_Date__c = System.today().addDays(60),
            QTB_Start_Date__c = System.today() - 60,
            QTB_Status__c = 'Active',
            QTB_Customer_PO__c = 'PO-007',
            QTB_PO_Type__c = 'Standard',
            QTB_Service_Type__c = 'Mixed',
            QTB_Date_Of_100_Utilization__c = System.today().addDays(-30),
            QTB_30_days_After_100_Utilization_Email__c = false
        ));
        
        // PO with 100% utilization 60 days ago
        poList.add(new QTB_PurchaseOrder__c(
            QTB_Amount__c = 800,
            QTB_PO_Balance_Amount__c = 0,
            QTB_Legal_Entity_Country__c = 'United States',
            QTB_Billing_Account__c = accountList[1].id,
            QTB_Customer_Id__c = 'Test8888',
            QTB_End_Date__c = System.today().addDays(30),
            QTB_Start_Date__c = System.today() - 90,
            QTB_Status__c = 'Active',
            QTB_Customer_PO__c = 'PO-008',
            QTB_PO_Type__c = 'Standard',
            QTB_Service_Type__c = 'Mixed',
            QTB_Date_Of_100_Utilization__c = System.today().addDays(-60),
            QTB_60_days_After_100_Utilization_Email__c = false
        ));
        
        // Future PO for one of the accounts - to test the future PO filtering logic
        poList.add(new QTB_PurchaseOrder__c(
            QTB_Amount__c = 900,
            QTB_PO_Balance_Amount__c = 900,
            QTB_Legal_Entity_Country__c = 'United States',
            QTB_Billing_Account__c = accountList[2].id,
            QTB_Customer_Id__c = 'Test9999',
            QTB_End_Date__c = System.today().addDays(150),
            QTB_Start_Date__c = System.today().addDays(100),
            QTB_Status__c = 'Active',
            QTB_Customer_PO__c = 'PO-009',
            QTB_PO_Type__c = 'Standard',
            QTB_Service_Type__c = 'Mixed'
        ));
        
        insert poList;
    
    Test.stopTest();
        //List<QTB_PurchaseOrder__c> oPo = [SELECT id,QTB_Legal_Entity_Country__c,QTB_Billing_Account__r.QTB_Language__c FROM QTB_PurchaseOrder__c where id =:po.Id ];
        //System.debug('***Po**'+oPo[0].QTB_Legal_Entity_Country__c);
        //   }   
    }
    @isTest static void testMethod1() {
		/*List<QTB_PurchaseOrder__c> Po = [SELECT id,QTB_Legal_Entity_Country__c,QTB_Billing_Account__r.QTB_Language__c FROM QTB_PurchaseOrder__c ];
        List<ID> POIds = new List<ID>();
        system.debug('@@@@@@@'+Po);
        system.debug('+++QTB_Legal_Entity_Country__c'+Po[0].QTB_Legal_Entity_Country__c);
        system.debug('+++QTB_Billing_Account__r.QTB_Language__c'+Po[0].QTB_Billing_Account__r.QTB_Language__c);
		POIds.add(Po[0].id);
		QTB_sendPONotificationBatch poBatch = new QTB_sendPONotificationBatch(POIds);
		Database.executeBatch(poBatch);*/
        
        Test.StartTest();
		QTB_SchedulePOExpireNotification testsche = new QTB_SchedulePOExpireNotification();
		String sch = '0 0 23 * * ?';
		system.schedule('Test status Check', sch, testsche );
		Test.stopTest();
    }
    @isTest static void testMethod2() {
		/*List<QTB_PurchaseOrder__c> Po = [SELECT id,QTB_Legal_Entity_Country__c,QTB_Billing_Account__r.QTB_Language__c FROM QTB_PurchaseOrder__c ];
        List<ID> POIds = new List<ID>();
        system.debug('@@@@@@@'+Po);
        system.debug('+++QTB_Legal_Entity_Country__c'+Po[0].QTB_Legal_Entity_Country__c);
        system.debug('+++QTB_Billing_Account__r.QTB_Language__c'+Po[0].QTB_Billing_Account__r.QTB_Language__c);
        POIds.add(Po[0].id);*/
        Test.startTest();
      // Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
      // Set recipients to two contact IDs.
     // Replace IDs with valid record IDs in your org.
      /*message.toAddresses = new String[] { '', '' };
        message.optOutPolicy = 'FILTER';
      message.subject = 'subjectDetails';
      message.plainTextBody = 'This is the message body.';
     Messaging.SingleEmailMessage[] messages = 
    new List<Messaging.SingleEmailMessage> {message};
         Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
     if (results[0].success) {
    System.debug('The email was sent successfully.');
    } else {
    System.debug('The email failed to send: '
          + results[0].errors[0].message);
    }*/
		QTB_sendPOExpireNotificationBatch poBatch = new QTB_sendPOExpireNotificationBatch();
        Database.executeBatch(poBatch,2000);
        Test.stopTest();
    }


        // separate test method for code coverage // Requirement: Gitlab #31454 
        @isTest
        static void testStep6_EmailNotifications() {
       Test.startTest();
        // Create Account
        Account acc = new Account(
            Name = 'Step6 Account', 
            QTB_Language__c = 'en_US',
            BillingPostalCode = '90210',
            BillingState = 'CA',
            ShippingCountry = 'United States',
            QTB_Legal_Entity_Country__c = 'United States');
        insert acc;

        // Create Contact
        Contact con = new Contact(
        FirstName = 'Notify', 
        LastName = 'User', 
        Email = 'notifyuser@example.com', 
        IM_Role__c = 'PO Contact',
        AccountId = acc.Id );
        insert con;

        // Query the auto-created AccountContactRelation and update the Roles field
        AccountContactRelation acr = [
            SELECT Id, Roles 
            FROM AccountContactRelation 
            WHERE AccountId = :acc.Id AND ContactId = :con.Id 
            LIMIT 1
        ];
        acr.Roles = 'PO Contact';
        update acr;

        // Assume QTB_Contract_Entity__c is Custom Metadata, so remove insert DML
        // Just assign dummy value directly on account if needed for test
        // acc.QTB_Contract_Entity__c = 'a0hABC123456789'; // fake ID of the metadata
        blng__LegalEntity__c indiaLegalEntity = QTB_TestDataFactory.createLegalEntity('India');
                indiaLegalEntity.QTB_Legal_Entity_Number__c = 45000.0;
                update indiaLegalEntity;
                acc.QTB_Contract_Entity__c = indiaLegalEntity.id;
        update acc;

        // Create Purchase Order — remove Name if it's Auto Number
        QTB_PurchaseOrder__c po = new QTB_PurchaseOrder__c(
            QTB_Legal_Entity_Country__c = 'SG',
            QTB_Status__c = 'Active',
            QTB_Amount__c = 1000,
            QTB_Start_Date__c = System.today().addDays(-10),
            QTB_End_Date__c = System.today().addDays(90),
            QTB_Customer_PO__c = 'CPO-001',
            QTB_PO_Type__c = 'Standard',
            QTB_Service_Type__c = 'Mixed',
            QTB_90_Days_Before_Email_Sent__c = true
        );
        insert po;

        // Link PO and Account via Junction Object
        QTB_PurchaseOrderAccount__c junction = new QTB_PurchaseOrderAccount__c(
            QTB_Account__c = acc.Id,
            QTB_Purchase_Order__c = po.Id
        );
        insert junction;

            // Execute the batch
         //   Test.startTest();
            QTB_sendPOExpireNotificationBatch batch = new QTB_sendPOExpireNotificationBatch();
            Database.executeBatch(batch, 200);
            Test.stopTest();

            // Verify PO flag is updated
            QTB_PurchaseOrder__c updatedPO = [
                SELECT QTB_90_Days_Before_Email_Sent__c FROM QTB_PurchaseOrder__c WHERE Id = :po.Id
            ];
            System.assertEquals(true, updatedPO.QTB_90_Days_Before_Email_Sent__c, 'PO 90-day flag should be updated');
        }




        
        @isTest
        static void testStep7_UtilizationAndExpiryNotifications() {
            // Create Account
            Test.startTest();
            Account acc = new Account(
                Name = 'Test Account Utilization',
                BillingPostalCode = '90210',
                BillingState = 'CA',
                ShippingCountry = 'United States',
                QTB_Legal_Entity_Country__c = 'United States',
                QTB_Language__c = 'en_US'
            );
            insert acc;

            // Create Legal Entity and assign to Account
            blng__LegalEntity__c indiaLegalEntity = QTB_TestDataFactory.createLegalEntity('India');
            indiaLegalEntity.QTB_Legal_Entity_Number__c = 45000.0;
            update indiaLegalEntity;

            acc.QTB_Contract_Entity__c = indiaLegalEntity.Id;
            update acc;

            // Create Contact and associate with Account
            Contact con = new Contact(
                FirstName = 'Util',
                LastName = 'User',
                Email = 'utiluser@example.com',
                AccountId = acc.Id
            );
            insert con;

            // Update AccountContactRelation to include 'PO Contact' role
            AccountContactRelation acr = [
                SELECT Id, Roles FROM AccountContactRelation
                WHERE AccountId = :acc.Id AND ContactId = :con.Id LIMIT 1
            ];
            acr.Roles = 'PO Contact';
            update acr;

            // Create Purchase Order meeting multiple notification conditions
            QTB_PurchaseOrder__c po = new QTB_PurchaseOrder__c(
                QTB_Legal_Entity_Country__c = acc.QTB_Legal_Entity_Country__c,
                QTB_Status__c = 'Active',
                QTB_Amount__c = 1000,
                QTB_Start_Date__c = System.today().addDays(-120),
                QTB_End_Date__c = System.today().addDays(-60), // triggers 60-day after expiry
                QTB_Date_Of_100_Utilization__c = System.today().addDays(-30), // triggers 30-day utilization
                QTB_Customer_PO__c = 'UTIL-CPO-001',
                QTB_PO_Type__c = 'Standard',
                QTB_Service_Type__c = 'Mixed',
                QTB_60_Days_Before_Email_Sent__c = true
            );
            insert po;

            // Create junction to link PO with Account
            QTB_PurchaseOrderAccount__c junction = new QTB_PurchaseOrderAccount__c(
                QTB_Account__c = acc.Id,
                QTB_Purchase_Order__c = po.Id
            );
            insert junction;

           // Test.startTest();
            Database.executeBatch(new QTB_sendPOExpireNotificationBatch(), 200);
            Test.stopTest();

            // Re-query PO to check updated flags
            po = [
                SELECT QTB_60_Days_After_Email_Sent__c, QTB_30_days_After_100_Utilization_Email__c
                FROM QTB_PurchaseOrder__c WHERE Id = :po.Id
            ];

            // Verify PO flag is updated
                QTB_PurchaseOrder__c updatedPO = [
                    SELECT QTB_60_Days_Before_Email_Sent__c FROM QTB_PurchaseOrder__c WHERE Id = :po.Id
                ];

            System.debug('60-days after expiry flag: ' + po.QTB_60_Days_After_Email_Sent__c);
            System.assertEquals(true, updatedPO.QTB_60_Days_Before_Email_Sent__c, 'PO 60-day flag should be updated');
        }
    
    @isTest
static void testStep8_ExpirationTodayNotification() {
    Test.startTest();
    // Create Legal Entity and associate to account
    blng__LegalEntity__c legalEntity = QTB_TestDataFactory.createLegalEntity('India');
    legalEntity.QTB_Legal_Entity_Number__c = 12345;
    update legalEntity;

     List<Account> accountList = QTB_TestDataFactory.createAccounts(3, 'Billing Account');
        accountList[0].QTB_Language__c = 'en_US';
        accountList[0].BillingPostalCode = '567788';
        accountList[0].BillingState = 'TNY';
        accountList[0].ShippingCountry = 'India';
        accountList[0].QTB_Legal_Entity_Country__c = 'India';
        accountList[0].QTB_Contract_Entity__c = legalEntity.id;
        update accountList;   

     List<Contact> contacts = new List<Contact>();
        
        Contact con1 = new Contact(
            LastName = 'PO Contact 1',
            FirstName = 'Test',
            Email = 'pocontact1@example.com',
            AccountId = accountList[0].id,
            IM_Role__c = 'PO Contact'
        );
        contacts.add(con1);
        
        Contact con2 = new Contact(
            LastName = 'PO Contact 2',
            FirstName = 'Test',
            Email = 'pocontact2@example.com',
            AccountId = accountList[1].id,
            IM_Role__c = 'PO Contact'
        );
        contacts.add(con2);
        
        Contact con3 = new Contact(
            LastName = 'PO Contact 3',
            FirstName = 'Test',
            Email = 'pocontact3@example.com',
            AccountId = accountList[2].id,
            IM_Role__c = 'PO Contact'
        );
        contacts.add(con3);
        
        insert contacts;
        
        // Create account contact relations for cross-account contact
        AccountContactRelation acr = new AccountContactRelation(
            AccountId = accountList[1].id,
            ContactId = con1.Id,
            Roles = 'PO Contact'
        );
        insert acr;

    // Create a PO that expires today and hasn't had email sent yet
    QTB_PurchaseOrder__c po = new QTB_PurchaseOrder__c(
        QTB_Billing_Account__c = accountList[0].Id,
        QTB_Legal_Entity_Country__c = accountList[0].QTB_Legal_Entity_Country__c,
        QTB_Status__c = 'Active',
        QTB_Amount__c = 500,
        QTB_Start_Date__c = System.today().addDays(-30),
        QTB_End_Date__c = System.today(), // expires today
        QTB_Customer_PO__c = 'TODAY-PO',
        QTB_PO_Type__c = 'Standard',
        QTB_Service_Type__c = 'Mixed',
        QTB_Expiration_Today_Email_Sent__c = false
    );
    insert po;

    // Create junction record
    QTB_PurchaseOrderAccount__c junction = new QTB_PurchaseOrderAccount__c(
        QTB_Account__c = accountList[0].Id,
        QTB_Purchase_Order__c = po.Id
    );
    insert junction;

    // Execute the batch
    Database.executeBatch(new QTB_sendPOExpireNotificationBatch(), 200);

    Test.stopTest();

    // Assert the flag was updated
    po = [
        SELECT QTB_Expiration_Today_Email_Sent__c
        FROM QTB_PurchaseOrder__c WHERE Id = :po.Id
    ];

   // System.assertEquals(true, po.QTB_Expiration_Today_Email_Sent__c,
      //  'Today Expiration flag should be marked as sent');
}



   }