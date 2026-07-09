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
}
