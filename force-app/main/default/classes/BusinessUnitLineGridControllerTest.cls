@IsTest
private class BusinessUnitLineGridControllerTest {

    @TestSetup
    static void setupTestData() {
        AccountTriggerHandler.skipTriggerExecutionTestClass = true;
        OpportunityTriggerHandler.skipTriggerExecutionTestClass = true;

        Id oppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
            .get('Standard Opportunity')
            .getRecordTypeId();

        insert new OpportunityProductSelection__c(
            Name = 'CloudSolutionsProduct',
            Product_Class_Name__c = 'Data Backup and Recovery',
            Product_Line_Name__c = 'Cloud Solutions'
        );

        IM_Country__c countryRec = new IM_Country__c();
        countryRec.Name = 'United States';
        countryRec.Iso31662Code__c = 'US';
        countryRec.Iso31663Code__c = 'USA';
        countryRec.Region__c = 'North America';
        insert countryRec;

        Account acc = new Account(
            Name = 'BU Grid Test Account' + System.currentTimeMillis(),
            BillingPostalCode = '11209',
            BillingCountry = 'United States',
            BillingState = 'NY'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'BU Grid Test Deal',
            RecordTypeId = oppRecordTypeId,
            AccountId = acc.Id,
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Billing_Country__c = countryRec.Id,
            Business_Unit__c = 'RIM',
            Type = 'New Deal'
        );
        insert opp;

        Opportunity_Product_Line__c line = new Opportunity_Product_Line__c(
            Opportunity__c = opp.Id,
            Business_Unit__c = 'RIM',
            EAA__c = 10000,
            Is_Active__c = true
        );
        insert line;
    }

    @IsTest
    static void testGetActiveLinesReturnsOnlyActiveLines() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<Opportunity_Product_Line__c> results = BusinessUnitLineGridController.getActiveLines(opp.Id);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return exactly the one active line');
        System.assertEquals('RIM', results[0].Business_Unit__c);
    }

    @IsTest
    static void testSaveDraftValuesUpdatesRecord() {
        Opportunity_Product_Line__c line = [SELECT Id FROM Opportunity_Product_Line__c LIMIT 1];

        List<Opportunity_Product_Line__c> draft = new List<Opportunity_Product_Line__c>{
            new Opportunity_Product_Line__c(Id = line.Id, EAA__c = 25000, Product_Family__c = 'Software')
        };

        Test.startTest();
        BusinessUnitLineGridController.saveDraftValues(JSON.serialize(draft));
        Test.stopTest();

        Opportunity_Product_Line__c updated = [SELECT EAA__c, Product_Family__c FROM Opportunity_Product_Line__c WHERE Id = :line.Id];
        System.assertEquals(25000, updated.EAA__c);
        System.assertEquals('Software', updated.Product_Family__c);
    }

    @IsTest
    static void testSaveDraftValuesRejectsNegativeEaa() {
        Opportunity_Product_Line__c line = [SELECT Id FROM Opportunity_Product_Line__c LIMIT 1];

        List<Opportunity_Product_Line__c> draft = new List<Opportunity_Product_Line__c>{
            new Opportunity_Product_Line__c(Id = line.Id, EAA__c = -500)
        };

        Boolean threwExpectedError = false;
        Test.startTest();
        try {
            BusinessUnitLineGridController.saveDraftValues(JSON.serialize(draft));
        } catch (AuraHandledException e) {
            threwExpectedError = true;
        }
        Test.stopTest();

        System.assertEquals(true, threwExpectedError, 'Negative EAA should be rejected');
    }
}
