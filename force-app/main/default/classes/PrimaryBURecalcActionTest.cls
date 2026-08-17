@IsTest
private class PrimaryBURecalcActionTest {

    @TestSetup
    static void setupTestData() {
        AccountTriggerHandler.skipTriggerExecutionTestClass = true;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
            .get('Standard Opportunity')
            .getRecordTypeId();

        IM_Country__c countryRec = new IM_Country__c(
            Name = 'United States',
            Iso31662Code__c = 'US',
            Iso31663Code__c = 'USA',
            Region__c = 'North America'
        );
        insert countryRec;

        IM_Alternative_Country_Name__c altCountry = new IM_Alternative_Country_Name__c(
            IM_Country__c = countryRec.Id,
            Alternative_Name__c = 'United States'
        );
        insert altCountry;

        Account acc = new Account(
            Name = 'Testaccount1' + System.currentTimeMillis(),
            BillingPostalCode = '11209',
            BillingCountry = 'United States',
            BillingState = 'NY'
        );
        insert acc;

        // Note: Set Business_Unit__c = 'RIM' and Multi_BU_Flag__c = true in setup
        // so that single/multi BU evaluations hit the red update assignment lines!
        Opportunity opp = new Opportunity(
            Name = 'Test Deal OPL',
            RecordTypeId = oppRecordTypeId,
            AccountId = acc.Id,
            Type = 'New Deal',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Billing_Country__c = countryRec.Id,
            Business_Unit__c = 'RIM',
            Primary_Product_Line__c = 'SITAD',
            Multi_BU_Flag__c = true,
            CurrencyIsoCode = 'USD',
            Amount = 1000,
            US_Federal_GSA_Pricing__c = 'No',
            Service_Address__Street__s = '632 Missouri Street',
            Service_Address__City__s = 'San Francisco',
            Service_Address__StateCode__s = 'CA',
            Service_Address__PostalCode__s = '94107',
            Service_Address__CountryCode__s = 'US',
            Budget_Validated__c = 'Yes',
            Business_Problem_Evidenced__c = 'Enhance Integration or System Connectivity',
            Customer_Outcome_Predefined__c = 'Work with Data Center Solutions',
            Impact_Consequences_Identified__c = 'Financial Cost or Waste',
            Decision_Process_Defined__c = true,
            Remarketing_Required__c = 'No',
            IM_Servicing_Region__c = 'New York'
        );
        insert opp;

        AccountTriggerHandler.skipTriggerExecutionTestClass = false;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass = false;
    }

    @IsTest
    static void testNullAndEmptyInputs() {
        Test.startTest();
        PrimaryBURecalcAction.recalculatePrimaryBU(null);
        PrimaryBURecalcAction.recalculatePrimaryBU(new List<Id>());
        PrimaryBURecalcAction.recalculatePrimaryBU(new List<Id>{ null });
        Test.stopTest();

        System.assert(true, 'Null and empty inputs should execute early return without exceptions');
    }

    @IsTest
    static void testSingleBUEvaluation() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        // Force Is_Primary__c = false explicitly to trigger Step D assignment
        Opportunity_Product_Line__c opl = new Opportunity_Product_Line__c(
            Opportunity__c = opp.Id,
            Business_Unit__c = 'Digital',
            EAA__c = 10000,
            Is_Active__c = true,
            Is_Primary__c = false
        );
        insert opl;

        Test.startTest();
        PrimaryBURecalcAction.recalculatePrimaryBU(new List<Id>{ opp.Id });
        Test.stopTest();

        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        Opportunity updatedOpp = [SELECT Business_Unit__c, Multi_BU_Flag__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Digital', updatedOpp.Business_Unit__c, 'Business Unit should be Digital');
        System.assertEquals(false, updatedOpp.Multi_BU_Flag__c, 'Multi-BU flag should be false for a single OPL');

        Opportunity_Product_Line__c resultOPL = [SELECT Is_Primary__c FROM Opportunity_Product_Line__c WHERE Id = :opl.Id];
        System.assertEquals(true, resultOPL.Is_Primary__c, 'Single active OPL must be marked as primary');
    }

    @IsTest
    static void testMultiBUEvaluation() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        // Set Is_Primary__c = true on non-winning record, false on winning record to force Step D assignments
        Opportunity_Product_Line__c oplDigital = new Opportunity_Product_Line__c(
            Opportunity__c = opp.Id,
            Business_Unit__c = 'Digital',
            EAA__c = 15000,
            Is_Active__c = true,
            Is_Primary__c = true
        );

        Opportunity_Product_Line__c oplRIM = new Opportunity_Product_Line__c(
            Opportunity__c = opp.Id,
            Business_Unit__c = 'ALM',
            EAA__c = 30000,
            Is_Active__c = true,
            Is_Primary__c = false
        );

        insert new List<Opportunity_Product_Line__c>{ oplDigital, oplRIM };

        Test.startTest();
        PrimaryBURecalcAction.recalculatePrimaryBU(new List<Id>{ opp.Id });
        Test.stopTest();

        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        Opportunity updatedOpp = [SELECT Business_Unit__c, Multi_BU_Flag__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('ALM', updatedOpp.Business_Unit__c, 'Winning BU should be ALM due to highest EAA');
        System.assertEquals(true, updatedOpp.Multi_BU_Flag__c, 'Multi-BU flag should be true with 2 active BUs');

        Map<Id, Opportunity_Product_Line__c> oplMap = new Map<Id, Opportunity_Product_Line__c>(
            [SELECT Id, Is_Primary__c FROM Opportunity_Product_Line__c WHERE Opportunity__c = :opp.Id]
        );
        System.assertEquals(false, oplMap.get(oplDigital.Id).Is_Primary__c, 'Lower EAA record should be set to false');
        System.assertEquals(true, oplMap.get(oplRIM.Id).Is_Primary__c, 'Highest EAA record should be set to true');
    }

    @IsTest
    static void testNoActiveOPLsResetsOpportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        // Inactive line triggers the empty active OPL list branch
        Opportunity_Product_Line__c oplInactive = new Opportunity_Product_Line__c(
            Opportunity__c = opp.Id,
            Business_Unit__c = 'Digital',
            EAA__c = 10000,
            Is_Active__c = false
        );
        insert oplInactive;

        Test.startTest();
        PrimaryBURecalcAction.recalculatePrimaryBU(new List<Id>{ opp.Id });
        Test.stopTest();

        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        Opportunity updatedOpp = [SELECT Business_Unit__c, Multi_BU_Flag__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(null, updatedOpp.Business_Unit__c, 'Business Unit should reset to null when no active lines exist');
        System.assertEquals(false, updatedOpp.Multi_BU_Flag__c, 'Multi-BU flag should reset to false when no active lines exist');
    }

    @IsTest
    static void testFrozenStageExclusion() {
        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;
        AccountTriggerHandler.skipTriggerExecutionTestClass = true;

        Account testAcc = [SELECT Id FROM Account LIMIT 1];
        IM_Country__c testCountry = [SELECT Id FROM IM_Country__c LIMIT 1];
        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
            .get('Standard Opportunity')
            .getRecordTypeId();

        Opportunity frozenOpp = new Opportunity(
            Name = 'Frozen Opp Test',
            RecordTypeId = oppRecordTypeId,
            AccountId = testAcc.Id,
            Type = 'New Deal',
            StageName = 'Lost',
            IM_Lost_Comments__c = 'lost',
            IM_Reason_Lost__c = 'Duplicate',
            CloseDate = Date.today(),
            Billing_Country__c = testCountry.Id,
            Business_Unit__c = 'ALM',
            Primary_Product_Line__c = 'SITAD',
            Multi_BU_Flag__c = false,
            CurrencyIsoCode = 'USD',
            Amount = 1000,
            US_Federal_GSA_Pricing__c = 'No',
            Budget_Validated__c = 'Yes',
            Decision_Process_Defined__c = true,
            Remarketing_Required__c = 'No',
            IM_Servicing_Region__c = 'New York'
        );
        insert frozenOpp;

        Test.startTest();
        PrimaryBURecalcAction.recalculatePrimaryBU(new List<Id>{ frozenOpp.Id });
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Business_Unit__c FROM Opportunity WHERE Id = :frozenOpp.Id];
        System.assertEquals('ALM', updatedOpp.Business_Unit__c, 'Recalculation must be skipped for frozen stages');
    }

    @IsTest
    static void testNoOpExecution() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        Opportunity_Product_Line__c opl = new Opportunity_Product_Line__c(
            Opportunity__c = opp.Id,
            Business_Unit__c = 'Digital',
            EAA__c = 10000,
            Is_Active__c = true,
            Is_Primary__c = false
        );
        insert opl;

        // First run syncs data
        PrimaryBURecalcAction.recalculatePrimaryBU(new List<Id>{ opp.Id });

        Test.startTest();
        // Second run hits no-op branch (coverage for skipping redundant DML)
        PrimaryBURecalcAction.recalculatePrimaryBU(new List<Id>{ opp.Id });
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Business_Unit__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Digital', updatedOpp.Business_Unit__c, 'Business Unit should remain Digital');
    }

    @IsTest
    static void testWinnerPathWithOLIsSkipsAmountRollup() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        // Attach an OLI so native Salesforce owns Amount. This populates oliCountByOpp
        // (aggregate loop body) and drives hasNoOLIs = false, so EAA must NOT roll up to Amount.
        Id stdPbId = Test.getStandardPricebookId();
        Product2 prod = TestingUtils.createProduct('PBURecalc WinnerProd', true);
        PricebookEntry stdPbe = TestingUtils.createPriceBookEntry(prod.Id, stdPbId, true);
        update new Opportunity(Id = opp.Id, Pricebook2Id = stdPbId);
        OpportunityLineItem oli = TestingUtils.createOLI(stdPbe.Id, opp.Id, true);

        Decimal amountWithOli = [SELECT Amount FROM Opportunity WHERE Id = :opp.Id].Amount;

        Opportunity_Product_Line__c oplDigital = new Opportunity_Product_Line__c(
            Opportunity__c = opp.Id,
            Business_Unit__c = 'Digital',
            EAA__c = 20000,
            Is_Active__c = true,
            Is_Primary__c = false
        );
        Opportunity_Product_Line__c oplAlm = new Opportunity_Product_Line__c(
            Opportunity__c = opp.Id,
            Business_Unit__c = 'ALM',
            EAA__c = 50000,
            Is_Active__c = true,
            Is_Primary__c = false
        );
        insert new List<Opportunity_Product_Line__c>{ oplDigital, oplAlm };

        Test.startTest();
        PrimaryBURecalcAction.recalculatePrimaryBU(new List<Id>{ opp.Id });
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Business_Unit__c, Multi_BU_Flag__c, Amount FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('ALM', updatedOpp.Business_Unit__c, 'Winning BU should still stamp when OLIs exist');
        System.assertEquals(true, updatedOpp.Multi_BU_Flag__c, 'Multi-BU flag should be true with 2 active BUs');
        System.assertEquals(amountWithOli, updatedOpp.Amount,
            'Amount must remain the native OLI rollup and not be overwritten by EAA total when OLIs exist');

        Opportunity_Product_Line__c winner = [SELECT Is_Primary__c FROM Opportunity_Product_Line__c WHERE Id = :oplAlm.Id];
        System.assertEquals(true, winner.Is_Primary__c, 'Highest EAA record must be primary');
    }

    @IsTest
    static void testEmptyOPLsWithOLIsPreservesAmount() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        // OLI present but no active OPLs: BU/Multi-BU reset, but Amount is preserved
        // because native OLI rollup (hasNoOLIs = false) owns it.
        Id stdPbId = Test.getStandardPricebookId();
        Product2 prod = TestingUtils.createProduct('PBURecalc EmptyProd', true);
        PricebookEntry stdPbe = TestingUtils.createPriceBookEntry(prod.Id, stdPbId, true);
        update new Opportunity(Id = opp.Id, Pricebook2Id = stdPbId);
        OpportunityLineItem oli = TestingUtils.createOLI(stdPbe.Id, opp.Id, true);

        Decimal amountWithOli = [SELECT Amount FROM Opportunity WHERE Id = :opp.Id].Amount;

        Opportunity_Product_Line__c oplInactive = new Opportunity_Product_Line__c(
            Opportunity__c = opp.Id,
            Business_Unit__c = 'Digital',
            EAA__c = 10000,
            Is_Active__c = false
        );
        insert oplInactive;

        Test.startTest();
        PrimaryBURecalcAction.recalculatePrimaryBU(new List<Id>{ opp.Id });
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Business_Unit__c, Multi_BU_Flag__c, Amount FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(null, updatedOpp.Business_Unit__c, 'Business Unit should reset when no active lines exist');
        System.assertEquals(false, updatedOpp.Multi_BU_Flag__c, 'Multi-BU flag should reset when no active lines exist');
        System.assertEquals(amountWithOli, updatedOpp.Amount,
            'Amount must be preserved (native OLI rollup) even when all OPLs are inactive');
    }
}