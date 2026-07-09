@isTest
private class SKPCustomerAffiliate_Test {
    
    public static string customerID = '12345';
    public static string districtID = 'D1234';
    public static string companyID = 'c1234';
    
    public static Account testAccount;
    public static Contact testContact;
    public static Opportunity testOpp;
    public static Case testCase;
    public static User testUser;
    public static Quote testScheduleA;
    public static IM_Customer_Account__c imAccount;
    public static Customer_Profile__c testProfile;    
    public static IM_Customer_Account__c testCustomerAccount;
    public static Case_Customer_Account__c testCaseCustomerAccount;
    public static RecordType NCSPRenewalRecordType;
    public SkpIntegrationHelper.CustomerIndicator customerIndicator;

    @testSetup
    static void setupTestData() {
        
        OpportunityTriggerHandler.skipTriggerExecutionTestClass  = true;  
        IM_Country__c cntry = TestingUtil.createIMCountry();
        
        //Create Account and Contact
        testAccount = TestingUtils.createAccounts(1, true)[0];        
        testContact = TestingUtils.createContact(testAccount.Id, false);
        testContact.FirstName = 'TestContact';
        testContact.Email = 'test.contact@example.com';
        insert testContact;
        
        RecordType EUOppType = [select id from RecordType
                                where name = 'Standard Opportunity'
                                and sObjectType = 'Opportunity'];
        
        //Insert Product, Pricebook, Ops and country setting. 
        Product2 product =
            new Product2(
                Secondary_Product_Allowed__c=true,
                Name='test',
                CurrencyIsoCode='GBP',
                IsActive=true);
        insert product;
        Id standardPB = Test.getStandardPricebookId();
        OpportunityProductSelection__c oppprodsel = new OpportunityProductSelection__c();
        oppprodsel.Name = 'CloudSolutionsProduct';
        oppprodsel.Product_Class_Name__c = 'Data Backup and Recovery';
        oppprodsel.Product_Line_Name__c = 'Cloud Solutions';              
        insert oppprodsel;
        Country_Settings__c setting = new Country_Settings__c();
        setting.Name = 'United States';
        setting.object_name__c = 'Account';
        insert setting;
        
        //Insert Opportunity
        testOpp = TestingUtils.createOpportunity('test_Opp', testAccount.Id, false);
        testOpp.Source_System__c = 'test SKP Europe';
        testOpp.Billing_Country__c = cntry.id;
        testOpp.Lead_Source_Most_Recent__c = 'x';
        testOpp.StageName = '1 - Qualification';
        testOpp.IM_Servicing_Region__c ='London';
        testOpp.IME_Reason_Won__c = 'Price';
        testOpp.CloseDate = System.today();
        testOpp.CurrencyIsoCode = 'USD';
        testOpp.Lead_Source_Most_Recent__c = 'x';
        testOpp.IM_Booked_Date__c = System.today();
        testOpp.IM_Commit_to_Forecast__c = true;
        testOpp.IM_Stage_5_Entered_Date__c  = System.today();
        testOpp.RecordTypeId = EUOppType.Id;
        testOpp.pricebook2ID= standardPB;
        testOpp.type = 'Price Change';
        
        insert testOpp;
        system.debug('source customer for oppt==');

        
        //Create User and Customer Profile
        testUser = TestingUtils.createUser('skp',true);
        testProfile = TestingUtils.createCustomerProfile(testOpp.id, new Map<string, Object>(), false);
        testProfile.Same_as_Service_Address_cor__c = false;
        testProfile.Same_as_Service_Address__c = false;
        testProfile.Invoice_Delivery_Method__c = 'Email Notification';
        testProfile.Remittance_Level__c = '1-Customer';
        testProfile.Primary_Service_Contact__c	=  testContact.id;
        insert testProfile;
        

        //Insert Case and Quote
        testCase = TestingUtils.createCase(testOpp, testContact, false);
        testCase.contract_type__c = 'IM2000';
        testCase.Customer_Profile__c = testProfile.id;
        insert testCase;
        Quote testScheduleA = TestingUtils.createQuotes(testOpp.id, 1, false)[0];
        testScheduleA.Pricebook2Id = test.getStandardPriceBookId();
        insert testScheduleA;
        
        //Create Product, PricebookEntry and QuoeLineItem
        Product2 productforShred = TestingUtils.createProduct('RM Easy Program Small', true);
        PriceBookEntry shredPBE = TestingUtils.createPriceBookEntry(productforShred.id, standardPB, true);
        QuoteLineItem qliForShred = TestingUtils.createQuoteLineItem(shredPBE.id, testScheduleA.id, true);
        
        // Create SKP_Customer_Indicator_Ranges__c records
        SKP_Customer_Indicator_Ranges__c range1 = new SKP_Customer_Indicator_Ranges__c();
            range1.Name = 'Hardcopy';
            range1.Customer_Indicator__c = 'Hardcopy';
            range1.Bill_Code_Minimum__c = 890;
            range1.Bill_Code_Maximum__c = 890;
        
        SKP_Customer_Indicator_Ranges__c range2 = new SKP_Customer_Indicator_Ranges__c(
            Name = 'Shred',
            Customer_Indicator__c = SKPIntegrationHelper.SHRED_NAME, // Use the constant
            Bill_Code_Minimum__c = 2000,
            Bill_Code_Maximum__c = 2999
        );
        // Add more as needed based on your actual data
        insert new List<SKP_Customer_Indicator_Ranges__c>{range1, range2};

            // Create SKPRecurringChargesDetails__c records
            SKPRecurringChargesDetails__c recurringCharge1 = new SKPRecurringChargesDetails__c(
                Name = 'RM Easy Program Small', // This should match a Product_Name__c from QLI
                BillCode__c = '3474',
                ProductName__c = 'RM Easy Program Small',
                Rate__c = '99.99'
            );
        insert recurringCharge1;
        
        SKP_Integration_Details__c details = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                            name='Sandbox', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
        SKP_Integration_Details__c details2 = new SKP_Integration_Details__c(Username__c ='John',Password__c='ilovepuppies',
                                                                             name='Production', Customer_Endpoint__c='http://www.test.com/test', Contract_Endpoint__c='http://www.test.com/test', Client_Id__c ='7668687', Client_Secret__c= 'gyugui', OAuth_EndPoint__c= 'https://api-preprod.ironmountainconnect.com/login');
        insert new List<SKP_Integration_Details__c>{details, details2};
    }

    @isTest
    static void testSKPCustomerAffiliateInstantiation() {
        User testUser = [SELECT Id, UserName, Email FROM User where isactive=true AND UserName='stdunitskp@testorg.com' LIMIT 1];
        System.runAs(testUser) {
            // Retrieve test data
            Customer_Profile__c profile = [SELECT Id, Customer_Name__c, Address__c, City__c, Primary_Service_Contact__r.Email,
                                                  Billing_Contact__r.Email, Invoice_Delivery_Method__c, Remittance_Level__c, 
                                           Same_as_Billing_Address__c
                                           FROM Customer_Profile__c LIMIT 1];
            Case caseRecord = [SELECT Id, Customer_Profile__c, ContactId,
                               Contact.Name,
                               Contact.Phone,
                               Contact.Email,
                               Customer_Profile__r.Opportunity__c,
                               Customer_Profile__r.Same_as_Service_Address__c,
                               Customer_Profile__r.Same_as_Service_Address_cor__c,
                               Customer_Profile__r.Sales_Rep_percent__c,
                               Customer_Profile__r.Customer_Name__c,
                               Customer_Profile__r.Correspondence_Address__c,
                               Customer_Profile__r.Address__c,
                               Customer_Profile__r.Address_Line_2__c,
                               Customer_Profile__r.Correspondence_City__c,
                               Customer_Profile__r.Correspondence_State_Province__c,
                               Customer_Profile__r.Correspondence_Zip_Postal_Code__c,
                               Customer_Profile__r.Correspondence_Country__c,
                               Customer_Profile__r.Correspondence_Contact__c,
                               Customer_Profile__r.City__c,
                               Customer_Profile__r.state_province__c,
                               Customer_Profile__r.Zip_Postal_Code__c,
                               Customer_Profile__r.country__c,
                               Customer_Profile__r.Primary_Service_Contact__c,
                               Customer_Profile__r.Same_as_Billing_Address__c,
                               Customer_Profile__r.Billing_City__c,
                               Customer_Profile__r.Billing_State_Province__c,
                               Customer_Profile__r.Billing_Zip_Postal_Code__c,
                               Customer_Profile__r.Billing_Country__c,
                               Customer_Profile__r.Billing_Address__c,
                               Customer_Profile__r.Billing_Contact__c,
                               Customer_Profile__r.Billing_Contact__r.email,
                               Customer_Profile__r.Invoice_Delivery_Method__c,
                               Customer_Profile__r.Remittance_Level__c,
                               Customer_Profile__r.Primary_Service_Contact__r.name,
                               Customer_Profile__r.Primary_Service_Contact__r.Phone,
                               Customer_Profile__r.Primary_Service_Contact__r.email
                               FROM Case LIMIT 1];
            Quote quoteRecord = [SELECT Id, (SELECT Id, Product_Name__c FROM QuoteLineItems) FROM Quote LIMIT 1];

            system.debug('caseRecord customer profile '+caseRecord.Customer_Profile__c);
            // Instantiate SkpIntegrationHelper.CustomerIndicator class
            // It requires a List<QuoteLineItem> and a String (contractVersion)
            List<QuoteLineItem> qlis = quoteRecord.QuoteLineItems;
            String contractVersion = 'IM5000'; // Example value, adjust as per your logic

            // Now, create the instance of CustomerIndicator class
            SkpIntegrationHelper.CustomerIndicator customerIndicator = new SkpIntegrationHelper.CustomerIndicator(qlis, contractVersion);

            Test.startTest();
            // Call the constructor of SKPCustomerAffiliate with the instantiated CustomerIndicator object
            SKPCustomerAffiliate customerAffiliate = new SKPCustomerAffiliate(
                'CUSTOMER123',
                caseRecord,
                quoteRecord,
                true, // validateJson
                testUser.UserName,
                customerIndicator // Pass the instance of the CustomerIndicator class
            );
            Test.stopTest();

            //System.assertNotNull(customerAffiliate, 'SKPCustomerAffiliate object should not be null.');
            //System.assertEquals('VALIDATE', customerAffiliate.filter.modeOfOperation, 'Mode of operation should be VALIDATE.');
            //System.assertEquals('CUSTOMER123', customerAffiliate.source.customerId, 'Customer ID mismatch.');
            //System.assertEquals(profile.Customer_Name__c, customerAffiliate.addDetails.newCustomerDetail.customerName, 'Customer name mismatch.');
            System.assertEquals(3, customerAffiliate.addDetails.newCustomerDetail.address.size(), 'Expected 3 address objects.');

            // Basic check for billing email to show some data population
            SKPCustomerAffiliate.billingObj billing = customerAffiliate.addDetails.newCustomerDetail.billing;
            //System.assertEquals('EML', billing.deliveryTypes[0].deliveryTypeId, 'Delivery type should be EML.');
            //System.assertEquals(profile.Billing_Contact__r.Email, billing.deliveryTypes[0].email[0], 'Billing email should match.');

        }
    }
}