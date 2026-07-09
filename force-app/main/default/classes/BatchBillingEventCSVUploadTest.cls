@isTest
private class BatchBillingEventCSVUploadTest {
    @testSetup 
    public static void setupData()  {
        
        Account acc = new Account(Name = 'test');
        insert acc;
        
        pse__Region__c reg = new pse__Region__c(Name = 'testReg');
        insert reg;
        
        pse__Permission_control__c pc = new pse__Permission_control__c(
            pse__Billing__c = true,
            pse__Invoicing__c = true,
            pse__Region__c = reg.Id,
            pse__User__c = UserInfo.getUserId()
        );
        insert pc;
        
        pse__Practice__c prac = new pse__Practice__c(Name = 'testPrac');
        insert prac;

        // Create a mock user
        User testUser = new User(
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            LastName = 'user78',
            Email = 'testuser78@example.com',
            Alias = 'tuser',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            Country = 'USA',
            EmailEncodingKey = 'UTF-8'
        );
        insert testUser;
        
        Contact con = new Contact(
            FirstName = 'test',
            LastName = '78',
            AccountId = acc.Id,
            pse__Is_Resource__c = true,
            pse__Is_Resource_Active__c = true,
            pse__Region__c = reg.Id,
            CurrencyIsoCode = 'USD',
            Email = 'xyz@abc.com',
            pse__Salesforce_User__c = testUser.Id
        );
        insert con;
        
        pse__Proj__c pr = new pse__Proj__c(
            Name = 'test',
            pse__Account__c = acc.Id,
            Region_Custom__c = 'Asia Pacific',
            Billing_Country__c = 'United States',
            Service_State__c = 'Florida',
            Sub_Region__c = 'US East',
            Service_Address_1__c = 'abc def',
            Billing_Department__c = 'Master',
            Billing_Division__c = 'Master',
            Subscription_Billing__c = 'No',
            Billing_Account_ID__c = '123',
            Executive_Summary_and_Objective_1__c = 'test',
            CurrencyIsoCode = 'USD',
            pse__Project_Type__c = 'Digital Solutions',
            pse__Practice__c = prac.Id,
            Customer_Contact__c = con.Id,
            Service_City__c = 'Inverness',
            Service_Postal_Code__c = '123',
            pse__Billing_Type__c = 'Time and Materials',
            Billing_Preference__c = 'Standard',
            Contract_Type__c = 'Master Service Agreement',
            SOW_Language__c = 'English',
            pse__Project_Manager__c = con.Id,
            SOW_Created__c = true,
            IRM_Approved__c = true,
            pse__Amount__c = 5000,
            Customer_Signed_Date__c = System.today(),
            Actual_Start_Date__c = System.today()
        );
        insert pr;

        Date startDate = Date.newInstance(2001, 1, 1);
        Date endDate = Date.newInstance(2050, 12, 31);
        pse__Time_Period__c tp = new pse__Time_Period__c(
            Name = 'Perpetual',
            pse__Start_Date__c = startDate,
            pse__End_Date__c = endDate,
            pse__Type__c = 'Perpetual',
            CurrencyIsoCode = 'USD'
        );
        insert tp;

        // Insert Billing Event Batch
        pse__Billing_Event_Batch__c beb = new pse__Billing_Event_Batch__c(
            pse__Account__c = pr.pse__Account__c,
            pse__Time_Period__c = tp.Id
        );
        insert beb;

        // Insert Billing Event
        pse__Billing_Event__c billingEvent = new pse__Billing_Event__c(
            pse__Invoice_Date__c = Date.newInstance(2008, 10, 5),
            pse__Invoice_Number__c = '9MJ3477',
            pse__Invoiced__c = true
        );
        insert billingEvent;

        // Insert Billing Event Item
        pse__Billing_Event_Item__c billingEventItem = new pse__Billing_Event_Item__c(
            pse__Object_Id__c = 'testObjectId',
            pse__Billing_Event__c = billingEvent.Id
        );
        insert billingEventItem;

        // Insert required Bill Code
        pse__Milestone__c billCode = new pse__Milestone__c(
            Name = 'Test Bill Code',
            pse__Project__c = pr.Id,
            Unit_of_Measure__c = 'Cubic Foot',
            Units__c = 14,
            Contract_Rate__c = 13,
            Bill_Code_Rate_Cost__c = 12,
            pse__Target_Date__c = Date.newInstance(2030, 7, 30),
            CurrencyIsoCode = 'USD'
        );
        insert billCode;

        // Insert Milestone
        pse__Milestone__c milestone = new pse__Milestone__c(
            Name = 'test-M1',
            pse__Target_Date__c = Date.newInstance(2030, 7, 30),
            Unit_of_Measure__c = 'Cubic Foot',
            Units__c = 14,
            Contract_Rate__c = 13,
            CurrencyIsoCode = 'USD',
            Bill_Code_Rate_Cost__c = 12,
            Units_Complete__c = 11,
            pse__Project__c = pr.Id,
            //Bill_Code__c = billCode.Id,
            pse__Billing_Event_Item__c = billingEventItem.Id
        );
        insert milestone;
    }

    @isTest
    static void testBillingEventFieldsReturn() {
        pse__Billing_Event_Item__c be = [SELECT Id FROM pse__Billing_Event_Item__c LIMIT 1];
        
        List<BillingEventRecordUpdateWithCtrl.BillingEventFields> records = new List<BillingEventRecordUpdateWithCtrl.BillingEventFields>();
        
        BillingEventRecordUpdateWithCtrl.BillingEventFields record1 = new BillingEventRecordUpdateWithCtrl.BillingEventFields();
        record1.billingEventItemID = be.Id;
        record1.billingEventItemBillingEventInvoiceDate = String.valueOf(Date.newInstance(2008, 10, 5));
        record1.billingEventItemBillingEventInvoiceNumber = 'INV-001';
        records.add(record1);

        BatchBillingEventCSVUpload batchJob = new BatchBillingEventCSVUpload(records);

        Test.startTest();
        Database.executeBatch(batchJob);
        Test.stopTest();
    }
}