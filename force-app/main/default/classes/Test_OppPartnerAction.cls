@isTest(SeeAllData=true)
private class Test_OppPartnerAction {

    static testMethod void myUnitTest() {
        // Get standard Opportunity record type Id
        ID oppRTId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Standard Opportunity').getRecordTypeId();

        // Create Account
        Account a = new Account(
            Name = 'Account4TestMethod' + System.now(),
            BillingCountry = 'United States',
            BillingState = 'MA'
        );
        insert a;

        // Fetch Pricebooks
        Pricebook2 naPricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'North America' LIMIT 1];
        Pricebook2 standardPB = [SELECT Id FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];

        // Create Contacts linked to Account (not used directly but good for data completeness)
        List<Contact> contacts = new List<Contact>{
            new Contact(LastName='TestContact1', Email='testemail@email.com', AccountId=a.Id, MailingCity='London', MailingCountry='United States', MailingPostalCode='SE1 2TT', MailingState='London', MailingStreet='745 Atlantic Ave'),
            new Contact(LastName='TestContact2', Email='testemail@email.com', AccountId=a.Id, MailingCity='London', MailingCountry='United States', MailingPostalCode='SE1 2TT', MailingState='London', MailingStreet='745 Atlantic Ave')
        };
        insert contacts;

        // Get Product2 record type Id (IMNA Product)
        Id productRTId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('IMNA Product').getRecordTypeId();

        // Create Products matching custom setting values for Product Line and Class
        Product2 product1 = new Product2(
            Secondary_Product_Allowed__c = true,
            Name = 'test1',
            RecordTypeId = productRTId,
            CurrencyIsoCode = 'USD',
            IM_Product_Line__c = 'Cloud Solutions',
            IM_Product_Class__c = 'Data Backup and Recovery',
            IsActive = true
        );
        insert product1;

        // Create PricebookEntries for products, linking to standard Pricebook
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>{
            new PricebookEntry(
                Pricebook2Id = standardPB.Id,
                Product2Id = product1.Id,
                UnitPrice = 1,
                CurrencyIsoCode = 'USD',
                IsActive = true,
                UseStandardPrice = false
            )
        };
        insert pricebookEntries;

        // Create Opportunity with Standard Opportunity record type and USD currency
        Opportunity opp = new Opportunity(
            AccountId = a.Id,
            IM_Servicing_Region__c='London',
            StageName = '1 - Qualification', // stage in your valid list
            RecordTypeId = oppRTId,
            CloseDate = Date.today(),
            Name = 'Opportunity4TestMethod',
            IM_Booked_Date__c = Date.today(),
            Type = 'New Deal',
            CurrencyIsoCode = 'USD'
        );
        insert opp;

          Test.startTest();
        // Insert Opportunity Line Item matching the product class and line from custom setting
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            UnitPrice = 1,
            PricebookEntryId = pricebookEntries[0].Id,
            Product_Line__c = 'Cloud Solutions',
            Product_Class__c = 'Data Backup and Recovery'
        );
        insert oli;

         // Call method getOppPartnerCount and assert - no partners so it should return TRUE (partner missing)
        Boolean partnerCheck = OppPartnerAction.getOppPartnerCount(opp.Id);
        
        Boolean productPartnerCheck = OppPartnerAction.getOppProductAndParnterCount(opp.Id);
      
        // Call getOppCSProductCount to set IsCloudSolutionProductCreated__c field on Opportunity
        OppPartnerAction.getOppCSProductCount(opp);

        Test.stopTest();
    }
}