/**
 * IRM_FreddySummitEdgeContactTest
 * Verifies that Freddy (demo user) can create a Contact and link it to the
 * "Summit Edge" Account.
 *
 * Uses System.runAs(freddy) so the Contact insert executes under Freddy's
 * profile + permission set combination, matching the pattern established in
 * IRM_FreddyAccessTest.
 */
@IsTest
private class IRM_FreddySummitEdgeContactTest {

    @TestSetup
    static void setup() {
        IM_Country__c testCountry = new IM_Country__c(Name = 'United States');
        insert testCountry;
        insert new IM_Alternative_Country_Name__c(
            IM_Country__c = testCountry.Id, Alternative_Name__c = 'United States'
        );

        insert new Account(
            Name = 'Summit Edge',
            BillingCountry = 'United States', BillingState = 'NY', BillingPostalCode = '11209'
        );
    }

    private static User getFreddy() {
        return [SELECT Id FROM User WHERE Username = 'freddy.acevedo@ironmountain.com.prjprism26' LIMIT 1];
    }

    @IsTest
    static void test_freddy_createsContactLinkedToSummitEdge() {
        User freddy = getFreddy();
        Id summitEdgeId = [SELECT Id FROM Account WHERE Name = 'Summit Edge' LIMIT 1].Id;

        Contact c;
        System.runAs(freddy) {
            c = new Contact(
                FirstName = 'Demo', LastName = 'SummitEdgeContact',
                AccountId = summitEdgeId
            );

            Test.startTest();
            insert c;
            Test.stopTest();
        }

        Contact inserted = [SELECT AccountId, Account.Name FROM Contact WHERE Id = :c.Id];
        System.assertEquals(summitEdgeId, inserted.AccountId,
            'Contact should be linked to the Summit Edge Account. Got AccountId: ' + inserted.AccountId);
        System.assertEquals('Summit Edge', inserted.Account.Name,
            'Contact.Account.Name should be Summit Edge. Got: ' + inserted.Account.Name);
    }

    // Mirrors the Lightning "New Contact" action from the Account related list, which the
    // live UI blocks for Freddy with "The requested resource does not exist" (recordTypeId
    // matches Contact.CRM_Contact, the same one the failing browser URL used).
    @IsTest
    static void test_freddy_recordTypeAvailabilityMatchesLiveUIBehavior() {
        User freddy = getFreddy();
        Id summitEdgeId = [SELECT Id FROM Account WHERE Name = 'Summit Edge' LIMIT 1].Id;
        Id crmContactRTId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
            .get('CRM_Contact').getRecordTypeId();

        Boolean isAvailableToFreddy;
        Contact c;
        System.runAs(freddy) {
            isAvailableToFreddy = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
                .get('CRM_Contact').isAvailable();

            c = new Contact(
                FirstName = 'Demo', LastName = 'SummitEdgeContactRT',
                AccountId = summitEdgeId, RecordTypeId = crmContactRTId
            );

            Test.startTest();
            insert c;
            Test.stopTest();
        }

        System.assert(c.Id != null,
            'Apex DML let the insert through with RecordTypeId=CRM_Contact even though the ' +
            'live UI blocks the same action for Freddy — Apex insert does not enforce the ' +
            'UI-layer record-type-visibility check that useRecordTypeCheck=1 enforces. ' +
            'isAvailable() reported: ' + isAvailableToFreddy);
    }
}
