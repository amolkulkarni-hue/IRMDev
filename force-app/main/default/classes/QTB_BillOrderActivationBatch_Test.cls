@IsTest
private class QTB_BillOrderActivationBatch_Test {
    @TestSetup
    static void createTestData() {
        Profile customSysAdmin = [SELECT Id FROM Profile WHERE Name = 'IM_Custom Sys Admin'];
        // create user
        User billingUser = new User( 
            profileId = customSysAdmin.Id,
            LastName = 'last',
            Email = 'testuser@test.example.com',
            Username = 'Testuser@test.example.com' + Crypto.getRandomInteger(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Country = 'USA',
            MobilePhone = '+1 9999999999',
            Phone = '9999999999'
        );
        insert billingUser;
        PermissionSetLicense cpq = [
            SELECT Id, MasterLabel
            FROM PermissionSetLicense
            WHERE MasterLabel = 'Salesforce CPQ License'
        ];
        // assign cpq license
        insert new PermissionSetLicenseAssign(AssigneeId = billingUser.Id, PermissionSetLicenseId = cpq.Id);
        // assign billing user permission
        PermissionSet billingUserPermission = [SELECT Id, Name FROM PermissionSet WHERE Name = 'QTB_Billing_User'];
        insert new PermissionSetAssignment(AssigneeId = billingUser.id, PermissionSetId = billingUserPermission.Id);
        Test.startTest();
        System.runAs(billingUser) {
            IM_Country__c finland = new IM_Country__c(
                Iso31662Code__c = 'FI',
                Iso31663Code__c = 'FIN',
                Name = 'Finland',
                Region__c = 'Europe'
            );
            insert finland;
            insert new IM_Alternative_Country_Name__c(IM_Country__c = finland.Id, Alternative_Name__c = finland.Name);
            Account company = new Account(
                Name = 'Test Factory',
                BillingCountry = 'Finland',
                BillingPostalCode = '681000',
                ShippingCountry = 'Finland',
                RecordTypeId = QTB_Utils.ACCOUNT_BILL_RECTYPEID,
                QTB_Create_Parent_Billing_Account__c = true
            );
            insert company;
            blng__BillingRule__c billingRule = new blng__BillingRule__c(
                Name = 'Factory Billing Rule',
                blng__Active__c = true,
                blng__GenerateInvoices__c = 'Yes',
                blng__InitialBillingTrigger__c = 'Order Product Activation Date'
            );
            insert billingRule;
            blng__TaxRule__c taxRule = new blng__TaxRule__c(
                Name = 'Factory Tax Rule',
                blng__Active__c = true,
                blng__TaxableYesNo__c = 'Yes'
            );
            insert taxRule;
            blng__RevenueRecognitionRule__c revenueRule = new blng__RevenueRecognitionRule__c(
                Name = 'Test Recognition Rule',
                blng__Active__c = true,
                blng__CreateRevenueSchedule__c = 'Yes'
            );
            insert revenueRule;
            Product2 product = new Product2(
                Name = 'Rebill Product',
                isActive = true,
                SBQQ__SubscriptionPricing__c = 'Fixed Price',
                blng__BillingRule__c = billingRule.Id,
                blng__TaxRule__c = taxRule.Id,
                blng__RevenueRecognitionRule__c = revenueRule.Id
            );
            insert product;
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = product.Id,
                UnitPrice = 10,
                IsActive = true
            );
            insert pbe;
            // blng__LegalEntity__c legalEntity = new blng__LegalEntity__c(
            //  Name = 'Test Legal Entity Finland',
            //  blng__Active__c = true,
            //  blng__Country__c = 'Finland',
            //  QTB_Type__c = 'Contract',
            //  QTB_Legal_Entity_Number__c = 45000
            // );
            // insert legalEntity;
            // blng__TaxIntegration__c taxIntegration = new blng__TaxIntegration__c(
            //  blng__TaxEngine__c = 'Standard',
            //  blng__Active__c = true
            // );
            // insert taxIntegration;
            // blng__TaxTreatment__c taxTreatment = new blng__TaxTreatment__c(
            //  blng__TaxLegalEntity__c = legalEntity.Id,
            //  blng__TaxIntegration__c = taxIntegration.Id,
            //  blng__TaxRule__c = taxRule.id,
            //  blng__TaxCode__c = 'STD-CGST'
            // );
            // insert taxTreatment;
            Order order = new Order(
                AccountId = company.Id,
                blng__BillingDayOfMonth__c = '27',
                EffectiveDate = Date.today().addDays(-5),
                Status = QTB_Constants.DRAFT_STATUS,
                Pricebook2Id = Test.getStandardPricebookId(),
                blng__InvoiceBatch__c = 'Finland-26th',
                RecordTypeId = QTB_Utils.ORDER_BILL_RECTYPEID
            );
            insert order;
            // deactivating qtb trigger on order to prevent order activate automatically
            insert new Metadata_Activation_Settings__c(SObject_API_Name__c = 'Order', Disable_Trigger__c = true);
            OrderItem orderProduct = new OrderItem(
                OrderId = order.Id,
                Quantity = 1.00,
                UnitPrice = 10.00,
                PricebookEntryId = pbe.Id,
                SBQQ__ChargeType__c = 'One-Time',
                product2id = product.Id,
                SBQQ__Activated__c = true,
                SBQQ__OrderedQuantity__c = 1.00,
                blng__BillingRule__c = billingRule.Id,
                blng__RevenueRecognitionRule__c = revenueRule.Id,
                blng__TaxRule__c = taxRule.Id,
                QTB_Ready_Activation__c = true,
                SBQQ__ProductSubscriptionType__c = QTB_Constants.SUBSCRIPTION_TYPE_RENEWABLE,
                SBQQ__SubscriptionType__c = QTB_Constants.SUBSCRIPTION_TYPE_RENEWABLE,
                ServiceDate = Date.today().addDays(5),
                EndDate = System.today().addDays(126)
            );
            insert orderProduct;
        }
        Test.stopTest();
    }
    @IsTest
    static void testBillingOrderActivationPositive() {
        System.assertEquals(0, [SELECT COUNT() FROM Order WHERE Status = 'Activated'], 'Expected no activated order.');
        Order orderUnderTest = [
            SELECT Id, AccountId, Status, EffectiveDate, Pricebook2Id, blng__InvoiceBatch__c, blng__BillingDayOfMonth__c
            FROM Order
            LIMIT 1
        ];
        OrderItem orderItemUnderTest = [
            SELECT
                Id,
                Quantity,
                UnitPrice,
                PricebookEntryId,
                SBQQ__ChargeType__c,
                product2id,
                blng__BillingRule__c,
                blng__RevenueRecognitionRule__c,
                blng__TaxRule__c,
                SBQQ__ProductSubscriptionType__c,
                SBQQ__SubscriptionType__c

            FROM OrderItem
            WHERE OrderId = :orderUnderTest.Id
        ];
        Order clonedOrderUnderTest = orderUnderTest.clone();
        clonedOrderUnderTest.EffectiveDate = orderUnderTest.EffectiveDate.addDays(-360);
        insert clonedOrderUnderTest;
        orderUnderTest.QTB_PrevBillingOrder__c = clonedOrderUnderTest.Id;
        update orderUnderTest;
        OrderItem clonedOrderItem1UnderTest = orderItemUnderTest.clone();
        clonedOrderItem1UnderTest.OrderId = clonedOrderUnderTest.Id;
        OrderItem clonedOrderItem2UnderTest = clonedOrderItem1UnderTest.clone();
        clonedOrderItem2UnderTest.SBQQ__ProductSubscriptionType__c = QTB_Constants.SUBSCRIPTION_TYPE_EVERGREEN;
        clonedOrderItem2UnderTest.SBQQ__SubscriptionType__c = QTB_Constants.SUBSCRIPTION_TYPE_EVERGREEN;
        insert new List<OrderItem>{ clonedOrderItem1UnderTest, clonedOrderItem2UnderTest };
        User contextuser = [SELECT Id FROM User WHERE Email = 'testuser@test.example.com'];
        Test.startTest();
        System.runAs(contextuser) {
            Database.executeBatch(new QTB_BillOrderActivationBatch());
        }
        Test.stopTest();
        System.assertNotEquals(
            0,
            [SELECT COUNT() FROM Order WHERE Status = 'Activated'],
            'Expected an activated order.'
        );
    }
}