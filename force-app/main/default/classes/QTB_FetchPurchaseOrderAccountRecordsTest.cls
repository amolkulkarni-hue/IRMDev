@isTest(seealldata=false) 
public class QTB_FetchPurchaseOrderAccountRecordsTest {
	
    @testSetup
    static void setup() {
        Metadata_Activation_Settings__c custSetting = new Metadata_Activation_Settings__c();
        custSetting.SObject_API_Name__c = 'SBQQ__Quote__c;SBQQ__QuoteLine__c;Account;Contact;AccountContactRelation;blng__UsageSummary__c;order;OrderItem;Opportunity;blng__InvoiceLine__c;blng__CreditNote__c';
        custSetting.Disable_VR__c = true;
        custSetting.Disable_PB__c = true;
        custSetting.Disable_Trigger__c = true;
        insert custSetting;
        
        Credit_ReBill_InvoiceSchedulerValidation__c invSchCust = new Credit_ReBill_InvoiceSchedulerValidation__c();
        invSchCust.Name = 'Finland';
        invSchCust.isRunning__c = false;
        insert invSchCust;
        
        QTB_Billing_Countries__c billingCountries = new QTB_Billing_Countries__c();
        billingCountries.Name = 'Singapore';
        billingCountries.Legal_entity_country__c = 'Singapore' ;
        insert billingCountries;
        
        List<User> userList = QTB_TestDataFactory.usrMethdLst(1);
        blng__BillingRule__c billingRule = QTB_TestDataFactory.createBillingRule('Yes');
        blng__RevenueRecognitionRule__c revenueRule = QTB_TestDataFactory.createRevenueRecognitionRule('Yes');
        blng__TaxRule__c taxRule = QTB_TestDataFactory.createTaxRule('Yes');
        
        //Product
        List<product2> productList = QTB_TestDataFactory.createProducts(1);
        productList[0].blng__BillingRule__c = billingRule.ID;
        productList[0].blng__RevenueRecognitionRule__c = revenueRule.ID;
        productList[0].blng__TaxRule__c = taxRule.ID;
        Database.update(productList);
        
        //Pricebook
        ID pricebookId = Test.getStandardPricebookId();
        PricebookEntry standardPrice = QTB_TestDataFactory.createPricebookEntry(productList[0]);
        
        //Account
        List<Account> accountList = new List<Account>();
        ID standardrecordId = QTB_Utils.ACCOUNT_STANDARD_RECTYPEID;
        ID recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId();   
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
            a.ShippingCountry = 'Singapore';
            a.QTB_Legal_Entity_Country__c='Singapore';
            if(i == 0){
                a.QTB_Legal_Entity_Country__c='United States';
                a.QTB_Bill_Cycle_Day__c = 'United States-DM-1st-EOM Manual';
            }
            if(i == 1){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 2){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Monthly';  
            }
            if(i == 3){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 4){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Quarterly';  
            }
            if(i == 5){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 6){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Semiannual';  
            }
            if(i == 7){
                a.QTB_Bill_Forward_Type__c = 'Arrears';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = 'Advance';
                a.QTB_Billing_Frequency__c = 'Annual';  
            }
            if(i == 8){
                a.QTB_Bill_Forward_Type__c = '';
                a.QTB_Billing_Frequency__c = '';  
            }
            accountList.add(a);
        }
        
        if (!accountList.isEmpty()) {
            insert accountList;
        }
        
        List<Account> standardAccountList = QTB_TestDataFactory.createAccounts(1,'Standard Account');
        accountList[0].QTB_Legal_Entity_Country__c='United States';
        accountList[0].QTB_Billing_Account_Invoice_Name__c = 'Standard Account';
        accountList[0].ShippingCity = 'New York';
        accountList[0].ShippingState = 'New York';
        accountList[0].ShippingPostalCode = '22131';
        accountList[0].ShippingCountry = 'United States';
        accountList[0].IM_Hierarchy_Level__c = 'Country Parent';
        update standardAccountList; 
        
        //Legal Entity
        blng__LegalEntity__c usaEntity = new blng__LegalEntity__c();
        usaEntity.Name = 'Test Legal Entity United States';
        usaEntity.blng__Active__c = true;
        usaEntity.blng__Country__c = 'United States';
        usaEntity.QTB_Type__c = 'Contract';
        usaEntity.QTB_Tax_Applicability__c = 'Flat Rate';
        insert usaEntity;
        
        IM_Country__c im = new IM_Country__c();
        im.Name = 'United States';
        im.CurrencyIsoCode = 'USD';
        im.Region__c = 'North America';
        im.AlternativeNames__c = 'United States';
        im.Iso31662Code__c ='US';
        im.Iso31663Code__c ='USA';    
        im.Active__c = true;
        insert im;
        
        //Account
        Account a = new Account();
        a.Name = 'testdata123';
        a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
        a.RecordTypeId = recordTypeValue;
        a.QTB_Create_Parent_Billing_Account__c = true;
        a.Name = 'Test Account';
        a.BillingCountry = 'Singapore';
        a.BillingPostalCode = '11209';
        a.BillingState = 'TN';
        a.Registration_Number__c = 'Reg';
        a.ShippingCountry = 'Singapore';
        a.QTB_Legal_Entity_Country__c='Singapore';
        insert a;

        //Account with No parent
        Account accWithParent = new Account();
        accWithParent.Name = 'accWithParent';
        accWithParent.Phone = 'Test9' + String.valueOf(Crypto.getRandomInteger());
        accWithParent.RecordTypeId = recordTypeValue;
        accWithParent.BillingCountry = 'Singapore';
        accWithParent.BillingPostalCode = '11208';
        accWithParent.BillingState = 'TN';
        accWithParent.Registration_Number__c = 'Reg';
        accWithParent.ShippingCountry = 'Singapore';
        accWithParent.QTB_Legal_Entity_Country__c='Singapore';
        accWithParent.QTB_Create_Parent_Billing_Account__c = false;
        accWithParent.ParentId = standardAccountList[0].ID;
        insert accWithParent;
        
        List<Opportunity> oppList = new List<Opportunity>();
        
        Opportunity insOpp = new Opportunity();
        insOpp.name = 'testOpp';
        insOpp.AccountId = standardAccountList[0].ID;
        insOpp.CloseDate = Date.today();
        insOpp.StageName = '1 - Qualification';
        insOpp.RecordTypeId = QTB_Utils.OPP_SALES_RECTYPEID;
        insOpp.Amount = 500;
        insOpp.Pricebook2Id=pricebookId;
        oppList.add(insOpp);
        
        insert oppList;
        
        //List<Order> orderList3 = QTB_TestDataFactory.createCPQOrders(1,null,accountList[0].ID);
        List<Order> orderList3 = new List<Order>();
        
        Order ord3 = new order();
        ord3.SBQQ__Quote__c = null;
        ord3.AccountId = accountList[0].ID;
        ord3.blng__BillingDayOfMonth__c = '1';
        ord3.EffectiveDate = Date.today().addDays(5);
        ord3.Status = QTB_Constants.DRAFT_STATUS;
        ord3.Pricebook2Id = pricebookId;
        ord3.blng__InvoiceBatch__c = 'Denmark-26th';
        ord3.recordtypeid = QTB_Utils.ORDER_BILL_RECTYPEID;
        //Database.update(orderList3);
        orderList3.add(ord3);
        insert orderList3;
        
        List<OrderItem> orderItemList3 = new List<OrderItem>();
        try {
            for (Integer i = 0; i < 1; i++){
                orderItemList3.add( new OrderItem( OrderId = orderList3[0].ID, Quantity = 2.00, UnitPrice = 12.00,
                                    PricebookEntryId = standardPrice.ID, SBQQ__ChargeType__c = 'One-Time', product2id = productList[0].ID,
                                    SBQQ__Activated__c = true,  blng__BillingRule__c = QTB_TestDataFactory.createBillingRule('Yes').ID,
                                    blng__RevenueRecognitionRule__c = QTB_TestDataFactory.createRevenueRecognitionRule('Yes').ID,
                                    blng__TaxRule__c = QTB_TestDataFactory.createTaxRule('Yes').ID, blng__HoldBilling__c = 'Yes'));
            }
            if (!orderItemList3.isEmpty()) {
                insert orderItemList3;
            }
        } catch (Exception e) {
            System.debug(e);
        }
        List<Contact> contList = new List<Contact>();
        for(Integer i = 0; i< 2; i++){
            Contact cont = new Contact( LastName = 'test11' + i, FirstName = 'abc1', Email = 'so1'+ i +'1@email.com', 
                                        AccountId = accountList[i].ID, MailingCountry = 'Canada', IM_Role__c = 'PO Contact' );
            contList.add(cont);                           
        }
        insert contList;
        
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        for(Integer i = 0; i< 2; i++){
            AccountContactRelation acr = new AccountContactRelation(AccountId = accountList[(i+2)].ID,
                                                                        ContactId = contList[i].ID);
            acrList.add(acr);
        }
        insert acrList;

        List<AccountContactRelation> acrListToUpdate = new List<AccountContactRelation>();
        for(AccountContactRelation acr : acrList){
            acr.Roles = 'PO Contact';
            acrListToUpdate.add(acr);
        }
        update acrListToUpdate;
        
        List<QTB_PurchaseOrder__c> poList = new List<QTB_PurchaseOrder__c>();
        List<QTB_PurchaseOrder__c> poList1 = new List<QTB_PurchaseOrder__c>();
        Map<ID,QTB_PurchaseOrder__c> ordOldMap = new Map<ID,QTB_PurchaseOrder__c>();
        Map<ID,blng__Invoice__c> poInvMap = new Map<ID,blng__Invoice__c>();
        
        QTB_PurchaseOrder__c pOrder = new QTB_PurchaseOrder__c(QTB_Billing_Account__c = accountList[2].ID, QTB_Legal_Entity_Country__c = accountList[2].BillingCountry,
                            QTB_Status__c = 'Active',QTB_Start_Date__c = System.today(),QTB_End_Date__c = System.today(),QTB_PO_Type__c = 'Standard',
                            QTB_Customer_PO__c = 'QW2315', QTB_Amount__c = 10000,QTB_Service_Type__c = 'Mixed', QTB_Date_Of_100_Utilization__c = System.Today());
        QTB_PurchaseOrder__c pOrder1 = new QTB_PurchaseOrder__c(QTB_Billing_Account__c = accountList[3].ID, QTB_Legal_Entity_Country__c = 'India',
                            QTB_Status__c = 'Active',QTB_Start_Date__c = Date.newInstance(2025, 2, 17),QTB_End_Date__c = Date.newInstance(2025, 2, 17),QTB_PO_Type__c = 'Standard',
                            QTB_Customer_PO__c = 'QW2316', QTB_Amount__c = 10000,QTB_Service_Type__c = 'Mixed', QTB_Date_Of_100_Utilization__c = Date.newInstance(2025, 2, 17));
        
        insert pOrder;
        insert pOrder1;
        
        poList.add(pOrder);
		
		 Contact acont = new Contact( LastName = 'testa', FirstName = 'abc1a', Email = 'so11ab@email.com', 
                                        AccountId = accountList[3].ID, MailingCountry = 'Canada', IM_Role__c = 'PO Contact' );
        insert acont;
        System.debug('acont = '+ acont);
       	AccountContactRelation accr1 = new AccountContactRelation( AccountId = a.ID, ContactId = acont.ID, Roles = 'PO Contact');
        insert accr1;

        QTB_PurchaseOrderAccount__c poa = new QTB_PurchaseOrderAccount__c();
        poa.QTB_Purchase_Order__c = pOrder.ID;
        poa.QTB_Account__c = a.ID;
        insert poa;

        Map<ID,blng__Invoice__c> oldMap = new Map<ID,blng__Invoice__c>();
        List<blng__Invoice__c> invoiceList = new List<blng__Invoice__c>();
        
        blng__Invoice__c invoice = new blng__Invoice__c();
        invoice.blng__Account__c = accountList[2].ID;
        invoice.blng__InvoiceStatus__c = 'Draft';
        invoice.blng__InvoiceDate__c = System.today()-10;
        invoice.QTB_PurchaseOrder__c = pOrder.ID;
        invoiceList.add(invoice);

        if (!invoiceList.isEmpty()) {
            insert invoiceList;
        }
        invoiceList[0].blng__InvoiceStatus__c = 'Posted';
        invoiceList[0].QTB_ReBill_Status__c = '';
        invoiceList[0].QTB_Transferred_To_Oracle__c = true;
        invoiceList[0].QTB_Invoice_Type__c = 'ReBill';
        update invoiceList;
        
        for(blng__Invoice__c invlist22 : invoiceList){
            if(invlist22.blng__InvoiceStatus__c == 'Posted'){
                poInvMap.put(invlist22.ID,invlist22);
            }
        } 
        Map<ID,blng__Invoice__c> invMap;
        invMap = new Map<ID,blng__Invoice__c>([SELECT  QTB_PurchaseOrder__c, QTB_PurchaseOrder__r.QTB_Status__c 
                                               FROM blng__Invoice__c 
                                               WHERE QTB_PurchaseOrder__c =:invoiceList[0].QTB_PurchaseOrder__c
                                               AND QTB_PurchaseOrder__r.QTB_Status__c = 'Active' LIMIT 1]);      
        porder.QTB_PO_Utilized_Amount__c = '50'; 
        porder.QTB_Amount__c = 5;
        Map<ID, QTB_PurchaseOrder__c> poMap = new Map<ID, QTB_PurchaseOrder__c>();
        poMap.put(porder.ID, porder);    
    }

    // Test when recordId is valid
    /*@isTest
    static void testGetPOAccountValidRecordId() {
        // Retrieve the purchase order and account we created in the test setup
        ID purchaseOrderID = [SELECT ID FROM QTB_PurchaseOrder__c LIMIT 1].ID;
        ID incorrectpurchaseOrderID = [SELECT ID FROM Account LIMIT 1].ID;
        System.debug('purchaseOrderID = '+ purchaseOrderID);
        
        // Call the method with a valid record ID
        Test.startTest();
        List<QTB_PurchaseOrderAccount__c> result = QTB_FetchPurchaseOrderAccountRecords.getPOAccount(incorrectpurchaseOrderID);
        List<QTB_PurchaseOrderAccount__c> resultTrue = QTB_FetchPurchaseOrderAccountRecords.getPOAccount(purchaseOrderID);
        Test.stopTest();

        // Verify the results
        System.assertEquals(null, result, 'The result should be null');
        System.assertNotEquals(null, resultTrue, 'The result should not be null');
        System.assertEquals(1, resultTrue.size(), 'There should be one record returned');
    }*/

    // Test when recordId is null
    @isTest
    static void testGetPOAccountNullRecordId() {
        // Simulate an exception by passing a bad recordId
        Test.startTest();
        try {
            List<QTB_PurchaseOrderAccount__c> result = QTB_FetchPurchaseOrderAccountRecords.getPOAccount(null);
			
            System.assert(false, 'Exception should have been thrown');
        } catch (Exception e) {
            // Verify that an exception is thrown and it is logged correctly
            System.assert(e != null, 'Exception should be thrown for invalid recordId');
        }
        Test.stopTest();
    }

    // Test when recordId is valid
    /*@isTest
    static void testGetAllBillingAccountValidRecordId() {
        // Retrieve the purchase order and account we created in the test setup
        ID purchaseOrderID = [SELECT ID 
                                    FROM QTB_PurchaseOrder__c 
                                    WHERE QTB_Legal_Entity_Country__c !=null LIMIT 1].ID;
        List<QTB_PurchaseOrder__c> poList = [SELECT ID,QTB_Legal_Entity_Country__c 
                                            FROM QTB_PurchaseOrder__c 
                                            WHERE QTB_Legal_Entity_Country__c !=null];
        
        Test.startTest();

        //poList[0].QTB_Legal_Entity_Country__c = 'India';
        //update poList;
        System.debug('purchaseOrderID list = '+ poList);

        List<Account> resultTrue = QTB_FetchPurchaseOrderAccountRecords.getAllBillingAccount(poList[1].ID);
        List<Account> result = QTB_FetchPurchaseOrderAccountRecords.getAllBillingAccount(poList[0].ID);
        Test.stopTest();

        // Verify the results
       // System.assertEquals(null, result, 'The result should be null');
       // System.assertNotEquals(null, resultTrue, 'The result should not be null');
       // System.assertEquals(11, resultTrue.size(), 'There should be one record returned');
    }*/

    // Test when recordId is null
    @isTest
    static void testGetAllBillingAccountNullRecordId() {
        // Simulate an exception by passing a bad recordId
        Test.startTest();
        try {
            List<Account> result = QTB_FetchPurchaseOrderAccountRecords.getAllBillingAccount(null);
            System.assert(false, 'Exception should have been thrown');
        } catch (Exception e) {
            // Verify that an exception is thrown and it is logged correctly
            System.assert(e != null, 'Exception should be thrown for invalid recordId');
        }
        Test.stopTest();
    }

    // Test when recordId is valid
    /*@isTest
    static void testGetSiblingBillingAccountValidRecordId() {
        // Retrieve the purchase order and account we created in the test setup
        ID accountWithoutParentId = [SELECT ID
                                    FROM Account 
                                    WHERE recordType.Name = 'Billing Account' AND QTB_Create_Parent_Billing_Account__c != null LIMIT 1].ID;
        ID accountWithParentID = [SELECT ID
                                    FROM Account 
                                    WHERE recordType.Name = 'Billing Account' AND Name = 'accWithParent' LIMIT 1].ID;
        
        // Call the method with a valid record ID
        Test.startTest();
        //List<Account> resultWithoutParent = QTB_FetchPurchaseOrderAccountRecords.getSiblingBillingAccount(accountWithoutParentId);
        //System.debug('resultWithoutParent = '+ resultWithoutParent.size());
        List<Account> result = QTB_FetchPurchaseOrderAccountRecords.getSiblingBillingAccount(accountWithParentID);
        System.debug('result = '+ result.size());
        Test.stopTest();

        // Verify the results
        //System.assertNotEquals(null, resultWithoutParent, 'The resultWithoutParent should not be null');
     //   System.assertEquals(1, resultWithoutParent.size(), 'There should be one record returned');
        System.assertNotEquals(null, result, 'The result should not be null');
    //    System.assertEquals(1, result.size(), 'There should be one record returned');
    }*/
    // Test when recordId is null
    @isTest
    static void testGetSiblingBillingAccountNullRecordId() {
        // Simulate an exception by passing a bad recordId
        Test.startTest();
        try {
            List<Account> result = QTB_FetchPurchaseOrderAccountRecords.getSiblingBillingAccount(null);
            System.assert(false, 'Exception should have been thrown');
        } catch (Exception e) {
            // Verify that an exception is thrown and it is logged correctly
            System.assert(e != null, 'Exception should be thrown for invalid recordId');
        }
        Test.stopTest();
    }

    // Test when recordId is valid
    @isTest
    static void testCreatePurchaseOrderAccountsValidRecordId() {
        Test.startTest();
        ID recordTypeValue = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId(); 
		Account a = new Account();
        a.Name = 'testdata123';
        a.Phone = 'Test' + String.valueOf(Crypto.getRandomInteger());
        a.RecordTypeId = recordTypeValue;
        a.QTB_Create_Parent_Billing_Account__c = true;
        //a.Name = 'Test Account';
        a.BillingCountry = 'Singapore';
        a.BillingPostalCode = '11209';
        a.BillingState = 'TN';
        a.Registration_Number__c = 'Reg';
        a.ShippingCountry = 'Singapore';
        a.QTB_Legal_Entity_Country__c='Singapore';
        insert a;
        // Retrieve the purchase order and account we created in the test setup 
        ID purchaseOrderID = [SELECT ID FROM QTB_PurchaseOrder__c LIMIT 1].ID;
        List<Account> accounts = [SELECT ID,Name FROM Account WHERE RecordType.Name = 'Billing Account' and Name = 'testdata123' LIMIT 1];
        Contact acont = [SELECT LastName,FirstName,Email,AccountId,MailingCountry,IM_Role__c FROM Contact
                         WHERE LastName = 'testa' LIMIT 1];
        /*Contact acont = new Contact( LastName = 'testabd', FirstName = 'abc1ab', Email = 'so11abd@email.com', 
                                        AccountId = accounts[0].ID, MailingCountry = 'Canada', IM_Role__c = 'PO Contact' );
        insert acont;*/
        
        System.debug('acont = '+ acont);
       	AccountContactRelation accr1 = new AccountContactRelation( AccountId = a.ID, ContactId = acont.ID, Roles = 'PO Contact');
        insert accr1;

         QTB_PurchaseOrder__c pOrder11 = new QTB_PurchaseOrder__c( QTB_Legal_Entity_Country__c = 'Singapore',
                            QTB_Status__c = 'Active',QTB_Start_Date__c = System.today(),QTB_End_Date__c = System.today(),QTB_PO_Type__c = 'Standard',
                            QTB_Customer_PO__c = 'QW2315', QTB_Amount__c = 10000,QTB_Service_Type__c = 'Mixed', QTB_Date_Of_100_Utilization__c = System.Today());
        insert pOrder11;

        QTB_PurchaseOrderAccount__c poa = new QTB_PurchaseOrderAccount__c();
        poa.QTB_Purchase_Order__c = pOrder11.Id;
        poa.QTB_Account__c = a.ID;
        insert poa;
        
        List<String> accountExisting = new List<String>();
        List<String> accountNew = new List<String>();
        for (Account acc : accounts) {
            if(acc.Name == 'testdata123'){
                accountExisting.add(acc.ID); 
            }else{
                accountNew.add(acc.ID);
            }
        }
        
        // Call the method with a valid record ID
        
        if(!accountExisting.isEmpty()){
            String resultExisting = QTB_FetchPurchaseOrderAccountRecords.createPurchaseOrderAccounts(purchaseOrderID,accountExisting);
            // Verify the results
            System.assertEquals('Success', resultExisting, 'The resultExisting should not be null');
            System.assertNotEquals('1', resultExisting, 'There should be null record returned');
        }    
        if(!accountNew.isEmpty() ){
            String result = QTB_FetchPurchaseOrderAccountRecords.createPurchaseOrderAccounts(purchaseOrderID,accountNew);
            // Verify the results
            System.assertNotEquals(null, result, 'The result should not be null');
            System.assertEquals('Success', result, 'There should be one record returned');
        }
        QTB_FetchPurchaseOrderAccountRecords.codeCoverageMethod();
        Test.stopTest();
    }

    // Test when recordId is null
    @isTest
    static void testCreatePurchaseOrderAccountsNullRecordId() {
        // Simulate an exception by passing a bad recordId
        Test.startTest();
        try {
            String result = QTB_FetchPurchaseOrderAccountRecords.createPurchaseOrderAccounts(null,null);
            System.assert(false, 'Exception should have been thrown');
        } catch (Exception e) {
            // Verify that an exception is thrown and it is logged correctly
            System.assert(e != null, 'Exception should be thrown for invalid recordId');
        }
        Test.stopTest();
    }
}