@isTest
private class OPLSyncActionTest {

    private static final String ACTIVE_OPPORTUNITY_NAME = 'OPL sync active opportunity';
    private static final String LOCKED_OPPORTUNITY_NAME = 'OPL sync locked opportunity';
    
    // Product Names (for Product2 & PricebookEntry lookup)
    private static final String HARDWARE_PRODUCT_NAME = 'Hardware Product';
    private static final String SOFTWARE_PRODUCT_NAME = 'Software Product';
    
    // Valid Business Units for Opportunity_Product_Line__c
    private static final String BU_RIM = 'RIM';
    private static final String BU_ALM = 'ALM';

    @TestSetup
    static void setupTestData() {
        AccountTriggerHandler.skipTriggerExecutionTestClass = true;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        IM_Country__c country = new IM_Country__c(
            Name = 'United States',
            Iso31662Code__c = 'US',
            Iso31663Code__c = 'USA',
            Region__c = 'North America'
        );
        insert country;

        Account testAccount = new Account(
            Name = 'OPL Sync Test Account',
            BillingCountry = 'United States',
            BillingState = 'NY',
            BillingPostalCode = '11209'
        );
        insert testAccount;

        Id opportunityRecordTypeId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByName()
            .get('Standard Opportunity')
            .getRecordTypeId();

        // Stage set to 'Solutioning' so CPQ sync processes line items
        Opportunity openOpp = new Opportunity(
            Name = ACTIVE_OPPORTUNITY_NAME,
            AccountId = testAccount.Id,
            RecordTypeId = opportunityRecordTypeId,
            Type = 'New Deal',
            StageName = 'Solutioning',
            CloseDate = Date.today().addDays(30),
            Billing_Country__c = country.Id,
            CurrencyIsoCode = 'USD',
            US_Federal_GSA_Pricing__c = 'No',
            Budget_Validated__c = 'Yes',
            Decision_Process_Defined__c = true,
            Remarketing_Required__c = 'No',
            IM_Servicing_Region__c = 'New York'
        );

        Opportunity lockedOpp = new Opportunity(
            Name = LOCKED_OPPORTUNITY_NAME,
            AccountId = testAccount.Id,
            RecordTypeId = opportunityRecordTypeId,
            Type = 'New Deal',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Billing_Country__c = country.Id,
            CurrencyIsoCode = 'USD',
            US_Federal_GSA_Pricing__c = 'No',
            Budget_Validated__c = 'Yes',
            Decision_Process_Defined__c = true,
            Remarketing_Required__c = 'No',
            IM_Servicing_Region__c = 'New York'
        );
        insert new List<Opportunity>{ openOpp, lockedOpp };

        Product2 hwProduct = new Product2(
            Name = HARDWARE_PRODUCT_NAME,
            IsActive = true,
            IM_Product_Class__c = 'Data Management'
        );
        Product2 swProduct = new Product2(
            Name = SOFTWARE_PRODUCT_NAME,
            IsActive = true,
            IM_Product_Line__c = 'Fixed Asset Management'
        );
        insert new List<Product2>{ hwProduct, swProduct };

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry hwPbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = hwProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        PricebookEntry swPbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = swProduct.Id,
            UnitPrice = 200,
            IsActive = true
        );
        insert new List<PricebookEntry>{ hwPbe, swPbe };

        AccountTriggerHandler.skipTriggerExecutionTestClass = false;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass = false;
    }

    @isTest
    static void shouldNotCreateOPLs_WhenInputIsNullOrEmpty() {
        Test.startTest();
        OPLSyncAction.syncOPLs(null);
        OPLSyncAction.syncOPLs(new List<Id>());
        Test.stopTest();

        Assert.areEqual(0, [SELECT Count() FROM Opportunity_Product_Line__c],
            'No OPLs should be created for null or empty input');
    }

    @isTest
    static void shouldNotCreateOPLs_WhenOpportunityIsInLockedStage() {
        Opportunity lockedOpp = [
            SELECT Id
            FROM Opportunity
            WHERE Name = :LOCKED_OPPORTUNITY_NAME
            LIMIT 1
        ];

        Test.startTest();
        OPLSyncAction.syncOPLs(new List<Id>{ lockedOpp.Id });
        Test.stopTest();

        Assert.areEqual(0, [SELECT Count() FROM Opportunity_Product_Line__c],
            'OPL sync should skip opportunities in a locked stage');
    }

    @isTest
    static void shouldCreateOPLsAndLinkOLIs_WhenActiveBusinessUnitsExist() {
        bypassLegacyOpportunityAutomation();
        Opportunity openOpp = getActiveOpportunity();
        PricebookEntry hwPbe = getPricebookEntry(HARDWARE_PRODUCT_NAME);
        PricebookEntry swPbe = getPricebookEntry(SOFTWARE_PRODUCT_NAME);

        OpportunityLineItem oli1 = createLineItem(openOpp.Id, hwPbe.Id, BU_RIM, 2, 100);
        OpportunityLineItem oli2 = createLineItem(openOpp.Id, swPbe.Id, BU_ALM, 1, 500);
        insert new List<OpportunityLineItem>{ oli1, oli2 };

        Test.startTest();
        OPLSyncAction.syncOPLs(new List<Id>{ openOpp.Id });
        Test.stopTest();

        List<Opportunity_Product_Line__c> opls = [
            SELECT Id, Business_Unit__c, EAA__c, EAA_Source__c, Is_Active__c
            FROM Opportunity_Product_Line__c 
            WHERE Opportunity__c = :openOpp.Id
        ];
        Assert.areEqual(2, opls.size(), 'One OPL should be created for each active business unit');

        Map<String, Opportunity_Product_Line__c> oplByBU = new Map<String, Opportunity_Product_Line__c>();
        for (Opportunity_Product_Line__c opl : opls) {
            oplByBU.put(opl.Business_Unit__c, opl);
        }

        Opportunity_Product_Line__c rimOpl = oplByBU.get(BU_RIM);
        Assert.isNotNull(rimOpl, 'A RIM OPL should be created');
        Assert.areEqual(200, rimOpl.EAA__c, 'RIM EAA should equal the sum of RIM OLIs');
        Assert.areEqual('CPQ Derived', rimOpl.EAA_Source__c, 'RIM OPL should identify its source');
        Assert.isTrue(rimOpl.Is_Active__c, 'RIM OPL should be active');

        Opportunity_Product_Line__c almOpl = oplByBU.get(BU_ALM);
        Assert.isNotNull(almOpl, 'An ALM OPL should be created');
        Assert.areEqual(500, almOpl.EAA__c, 'ALM EAA should equal the sum of ALM OLIs');
        Assert.isTrue(almOpl.Is_Active__c, 'ALM OPL should be active');

        OpportunityLineItem updatedOli1 = [
            SELECT Opportunity_Product_Line__c
            FROM OpportunityLineItem
            WHERE Id = :oli1.Id
        ];
        Assert.areEqual(rimOpl.Id, updatedOli1.Opportunity_Product_Line__c,
            'The RIM OLI should point to its corresponding OPL');
    }

    @isTest
    static void shouldUpdateExistingOPL_WhenBusinessUnitEAAChanges() {
        bypassLegacyOpportunityAutomation();
        Opportunity openOpp = getActiveOpportunity();
        PricebookEntry hwPbe = getPricebookEntry(HARDWARE_PRODUCT_NAME);

        OpportunityLineItem firstOli = createLineItem(
            openOpp.Id, hwPbe.Id, BU_RIM, 1, 100
        );
        insert firstOli;
        OPLSyncAction.syncOPLs(new List<Id>{ openOpp.Id });

        Opportunity_Product_Line__c initialOpl = [
            SELECT Id, EAA__c
            FROM Opportunity_Product_Line__c
            WHERE Opportunity__c = :openOpp.Id AND Business_Unit__c = :BU_RIM
        ];
        Assert.areEqual(100, initialOpl.EAA__c, 'The initial RIM EAA should equal the first OLI total');

        OpportunityLineItem secondOli = createLineItem(
            openOpp.Id, hwPbe.Id, BU_RIM, 2, 100
        );
        insert secondOli;

        Test.startTest();
        OPLSyncAction.syncOPLs(new List<Id>{ openOpp.Id });
        Test.stopTest();

        Opportunity_Product_Line__c updatedOpl = [
            SELECT Id, EAA__c
            FROM Opportunity_Product_Line__c
            WHERE Opportunity__c = :openOpp.Id AND Business_Unit__c = :BU_RIM
        ];
        Assert.areEqual(initialOpl.Id, updatedOpl.Id, 'The existing RIM OPL should be updated, not duplicated');
        Assert.areEqual(300, updatedOpl.EAA__c, 'RIM EAA should include both line-item totals');
    }

    @isTest
    static void shouldDeactivateOPL_WhenAllBusinessUnitOLIsAreRemoved() {
        bypassLegacyOpportunityAutomation();
        Opportunity openOpp = getActiveOpportunity();
        PricebookEntry hwPbe = getPricebookEntry(HARDWARE_PRODUCT_NAME);

        OpportunityLineItem oli = createLineItem(
            openOpp.Id, hwPbe.Id, BU_RIM, 1, 300
        );
        insert oli;
        OPLSyncAction.syncOPLs(new List<Id>{ openOpp.Id });

        Opportunity_Product_Line__c initialOpl = [
            SELECT Id, Is_Active__c, EAA__c 
            FROM Opportunity_Product_Line__c 
            WHERE Opportunity__c = :openOpp.Id AND Business_Unit__c = :BU_RIM
        ];
        Assert.isTrue(initialOpl.Is_Active__c, 'The OPL should be active while a matching OLI exists');

        delete oli;

        Test.startTest();
        OPLSyncAction.syncOPLs(new List<Id>{ openOpp.Id });
        Test.stopTest();

        Opportunity_Product_Line__c deactivatedOpl = [
            SELECT Id, Is_Active__c, EAA__c 
            FROM Opportunity_Product_Line__c 
            WHERE Id = :initialOpl.Id
        ];
        Assert.isFalse(deactivatedOpl.Is_Active__c,
            'The OPL should be inactive when no matching OLIs remain');
        Assert.areEqual(0, deactivatedOpl.EAA__c, 'EAA should reset to zero upon deactivation');
    }

    @isTest
    static void shouldDeactivateOPLViaTrigger_WhenOLIIsDeleted() {
        bypassLegacyOpportunityAutomation();
        Opportunity openOpp = getActiveOpportunity();
        PricebookEntry hwPbe = getPricebookEntry(HARDWARE_PRODUCT_NAME);

        OpportunityLineItem oli = createLineItem(
            openOpp.Id, hwPbe.Id, BU_RIM, 1, 300
        );
        insert oli;

        OPLSyncAction.syncOPLs(new List<Id>{ openOpp.Id });

        Opportunity_Product_Line__c initialOpl = [
            SELECT Id, Is_Active__c 
            FROM Opportunity_Product_Line__c 
            WHERE Opportunity__c = :openOpp.Id AND Business_Unit__c = :BU_RIM
        ];
        Assert.isTrue(initialOpl.Is_Active__c, 'OPL record should be active before deletion');

        Test.startTest();
        delete oli;
        Test.stopTest();

        Opportunity_Product_Line__c deactivatedOpl = [
            SELECT Id, Is_Active__c, EAA__c 
            FROM Opportunity_Product_Line__c 
            WHERE Id = :initialOpl.Id
        ];
        Assert.isFalse(deactivatedOpl.Is_Active__c,
            'OLISyncTrigger should automatically deactivate OPL upon OLI deletion');
        Assert.areEqual(0, deactivatedOpl.EAA__c, 'EAA should reset to zero');
    }

    private static Opportunity getActiveOpportunity() {
        return [
            SELECT Id
            FROM Opportunity
            WHERE Name = :ACTIVE_OPPORTUNITY_NAME
            LIMIT 1
        ];
    }

    private static void bypassLegacyOpportunityAutomation() {
        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;
    }

    private static PricebookEntry getPricebookEntry(String productName) {
        return [
            SELECT Id
            FROM PricebookEntry
            WHERE Product2.Name = :productName
            LIMIT 1
        ];
    }

    private static OpportunityLineItem createLineItem(
        Id opportunityId,
        Id pricebookEntryId,
        String businessUnit,
        Decimal quantity,
        Decimal unitPrice
    ) {
        return new OpportunityLineItem(
            OpportunityId = opportunityId,
            PricebookEntryId = pricebookEntryId,
            Product_Business_Unit__c = businessUnit,
            Quantity = quantity,
            UnitPrice = unitPrice
        );
    }
}