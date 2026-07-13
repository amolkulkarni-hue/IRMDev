@isTest
private class LeadToAccountMatching_test
{
    private static final String SALES_SITE_LEVEL = 'Sales (Site)';
    private static final String COUNTRY_US = 'United States';

    @TestSetup
    static void createApprovedCountries()
    {
        insert new List<IM_Country__c>{
            new IM_Country__c(Name = COUNTRY_US,Active__c = true),
            new IM_Country__c(Name = 'Canada',Active__c = true)
        };
    }

    @isTest
    static void exactMatchPopulatesAccountAndShippingAddress()
    {
        System.runAs(createTestUser('exact'))
        {
            Account exactAccount = createSalesSite('Exact Company',COUNTRY_US);
            exactAccount.ShippingStreet = '100 Exact Street';
            exactAccount.ShippingCity = 'Boston';
            exactAccount.ShippingState = 'Massachusetts';
            exactAccount.ShippingPostalCode = '02108';
            update exactAccount;

            Lead leadRecord = newLead('Exact Company',COUNTRY_US,null);

            Test.startTest();
            insert leadRecord;

            System.assertEquals(Limits.getQueueableJobs(),1);
            Test.stopTest();

            Lead matchedLead = queryMatchedLead(leadRecord.Id);

            System.assertEquals(matchedLead.Related_Account__c,exactAccount.Id);
            System.assertEquals(matchedLead.Street,exactAccount.ShippingStreet);
            System.assertEquals(matchedLead.City,exactAccount.ShippingCity);
            System.assertEquals(matchedLead.State,exactAccount.ShippingState);
            System.assertEquals(matchedLead.PostalCode,exactAccount.ShippingPostalCode);
            System.assertEquals(matchedLead.Country,exactAccount.ShippingCountry);
        }
    }

    @isTest
    static void relatedContactAccountTakesPriority()
    {
        System.runAs(createTestUser('contact'))
        {
            Account contactAccount = createSalesSite('Contact Account',COUNTRY_US);
            contactAccount.ShippingCity = 'Chicago';
            update contactAccount;
            createSalesSite('Lead Company',COUNTRY_US);

            Contact relatedContact = new Contact(
                FirstName = 'Priority',
                LastName = 'Related Contact',
                AccountId = contactAccount.Id
            );
            insert relatedContact;

            Lead leadRecord = newLead('Lead Company',COUNTRY_US,null);
            leadRecord.Related_Contact__c = relatedContact.Id;

            Test.startTest();
            insert leadRecord;
            Test.stopTest();

            Lead matchedLead = queryMatchedLead(leadRecord.Id);

            System.assertEquals(matchedLead.Related_Account__c,contactAccount.Id);
            System.assertEquals(matchedLead.City,'Chicago');
        }
    }

    @isTest
    static void tiebreakersApplyInPriorityOrder()
    {
        User testUser = createTestUser('tie');

        System.assertEquals(
            LeadToAccountMatching.chooseBestAccount(
                leadWithDomain('priority-example.com'),
                new List<Account>{
                    comparisonAccount('No Coverage',null,null,null,null),
                    comparisonAccount('With Coverage',testUser.Id,null,null,null),
                    comparisonAccount(
                        'With IMGA',
                        testUser.Id,
                        'Priority IMGA',
                        'other-example.com',
                        null
                    ),
                    comparisonAccount(
                        'With Domain',
                        testUser.Id,
                        'Priority IMGA',
                        'priority-example.com',
                        null
                    )
                }
            ).Name,
            'With Domain'
        );
    }

    @isTest
    static void earliestCreatedDateBreaksRemainingTie()
    {
        System.runAs(createTestUser('oldest'))
        {
            Account olderAccount = salesSite('Oldest Company',COUNTRY_US);
            Account newerAccount = salesSite('Oldest Company',COUNTRY_US);
            insert new List<Account>{olderAccount,newerAccount};
            Test.setCreatedDate(olderAccount.Id,Datetime.now().addYears(-2));
            Test.setCreatedDate(newerAccount.Id,Datetime.now().addYears(-1));

            Lead leadRecord = newLead('Oldest Company',COUNTRY_US,null);

            Test.startTest();
            insert leadRecord;
            Test.stopTest();

            System.assertEquals(
                queryMatchedLead(leadRecord.Id).Related_Account__c,
                olderAccount.Id
            );
        }
    }

    @isTest
    static void accountDomainFallbackMatchesAndDoesNotRequeueItself()
    {
        System.runAs(createTestUser('domain'))
        {
            Account domainAccount = salesSite('Different Account Name','Canada');
            domainAccount.Website = 'https://www.domain-match-example.com/a-page';
            domainAccount.ShippingCity = 'Toronto';
            insert domainAccount;

            Lead leadRecord = newLead(
                'No Name Match',
                COUNTRY_US,
                'alice.smith@domain-match-example.com'
            );

            Test.startTest();
            insert leadRecord;
            Test.stopTest();

            Lead matchedLead = queryMatchedLead(leadRecord.Id);

            System.assertEquals(matchedLead.Related_Account__c,domainAccount.Id);
            System.assertEquals(matchedLead.Country,'Canada');
            System.assertEquals(matchedLead.City,'Toronto');
        }
    }

    @isTest
    static void fuzzyCandidatesAreQualifiedAndSelected()
    {
        System.runAs(createTestUser('fuzzy'))
        {
            Account fuzzyAccount = createSalesSite('Acme Corporation',COUNTRY_US);
            Lead leadRecord = newLead('Acme Corp',COUNTRY_US,null);
            insertWithoutMatching(new List<Lead>{leadRecord});

            Lead queriedLead = [
                SELECT Id, Domain__c
                FROM Lead
                WHERE Id = :leadRecord.Id
            ];
            Set<Id> unresolvedLeadIds = new Set<Id>{queriedLead.Id};
            Map<Id,Account> matchesByLeadId = new Map<Id,Account>();

            Test.startTest();
            LeadToAccountMatching.matchFuzzyCandidateAccounts(
                new Map<Id,Lead>{queriedLead.Id => queriedLead},
                unresolvedLeadIds,
                new Set<Id>(),
                matchesByLeadId,
                new Map<Id,Set<Id>>{
                    queriedLead.Id => new Set<Id>{fuzzyAccount.Id}
                }
            );
            Test.stopTest();

            System.assertEquals(matchesByLeadId.get(queriedLead.Id).Id,fuzzyAccount.Id);
            System.assertEquals(unresolvedLeadIds.size(),0);
        }
    }

    @isTest
    static void irrelevantUpdateDoesNotQueueAndNoMatchRetainsExistingAccount()
    {
        System.runAs(createTestUser('retain'))
        {
            Account existingAccount = createSalesSite('Existing Account',COUNTRY_US);
            Lead leadRecord = newLead('Original Company',COUNTRY_US,null);
            leadRecord.Related_Account__c = existingAccount.Id;
            insertWithoutMatching(new List<Lead>{leadRecord});

            Test.startTest();
            leadRecord.Title = 'Updated title';
            update leadRecord;

            System.assertEquals(Limits.getQueueableJobs(),0);

            leadRecord.Company = 'No Matching Company';
            update leadRecord;

            System.assertEquals(Limits.getQueueableJobs(),1);
            Test.stopTest();

            System.assertEquals(
                queryMatchedLead(leadRecord.Id).Related_Account__c,
                existingAccount.Id
            );
        }
    }

    @isTest
    static void bulkInsertUsesOneJobAndMatchesEveryLead()
    {
        System.runAs(createTestUser('bulk'))
        {
            createSalesSite('Bulk Company',COUNTRY_US);
            List<Lead> leads = new List<Lead>();
            for (Integer index = 0; index < 200; index++)
                leads.add(newLead('Bulk Company',COUNTRY_US,null));

            Test.startTest();
            insert leads;

            System.assertEquals(Limits.getQueueableJobs(),1);
            Test.stopTest();

            System.assertEquals(
                [
                    SELECT COUNT()
                    FROM Lead
                    WHERE Id IN :new Map<Id,Lead>(leads).keySet()
                        AND Related_Account__r.Name = 'Bulk Company'
                ],
                200
            );
        }
    }

    @isTest
    static void exclusionParsingAndDomainRanksAreDefensive()
    {
        User testUser = createTestUser('parse');

        System.assertEquals(
            LeadToAccountMatching.parseExcludedCreatorIds(
                '  ' + testUser.Id + ', invalid, 001000000000000AAA, , ' + testUser.Id + '  '
            ),
            new Set<Id>{testUser.Id}
        );
        System.assertEquals(LeadToAccountMatching.parseExcludedCreatorIds(null).size(),0);
        System.assertEquals(
            LeadToAccountMatching.domainRank(
                ' Example.COM ',
                'example.com',
                'other.example'
            ),
            1
        );
        System.assertEquals(
            LeadToAccountMatching.domainRank(
                'example.com',
                'other.example',
                'EXAMPLE.COM'
            ),
            2
        );
        System.assertEquals(
            LeadToAccountMatching.domainRank(
                'example.com',
                'other.example',
                null
            ),
            3
        );
    }

    private static User createTestUser (String uniqueValue)
    {
        String uniqueUsername = 'l2a.' + uniqueValue + '.' + Datetime.now().getTime()
            + '@stackology-tests.invalid';
        User testUser = new User(
            Alias = uniqueValue.left(8),
            Country = COUNTRY_US,
            Email = uniqueUsername,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = uniqueValue + ' Matching User',
            LocaleSidKey = 'en_US',
            ProfileId = [
                SELECT Id
                FROM Profile
                WHERE Name = 'System Administrator'
                LIMIT 1
            ].Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUsername
        );
        insert testUser;

        return testUser;
    }

    private static Account createSalesSite (String name, String country)
    {
        Account accountRecord = salesSite(name,country);
        insert accountRecord;

        return accountRecord;
    }

    private static Account salesSite (String name, String country)
    {
        return new Account(
            Name = name,
            ShippingCountry = country,
            IM_Hierarchy_Level__c = SALES_SITE_LEVEL
        );
    }

    private static Lead newLead (String company, String country, String email)
    {
        return new Lead(
            LastName = company + ' Matching Test',
            Company = company,
            Status = 'New',
            Country = country,
            Email = email
        );
    }

    private static Lead leadWithDomain (String domain)
    {
        return (Lead) JSON.deserialize(
            JSON.serialize(new Map<String,Object>{
                'attributes' => new Map<String,Object>{'type' => 'Lead'},
                'Domain__c' => domain
            }),
            Lead.class
        );
    }

    private static Account comparisonAccount (String name, Id coverageUserId, String imga, String accountDomain, String dnbDomain)
    {
        Map<String,Object> values = new Map<String,Object>{
            'attributes' => new Map<String,Object>{'type' => 'Account'},
            'Name' => name,
            'IM_IMGA__c' => imga,
            'Account_Domain__c' => accountDomain,
            'DnB_Web_Address__c' => dnbDomain
        };
        if (coverageUserId != null)
            values.put('Primary_BDE__c',coverageUserId);

        return (Account) JSON.deserialize(JSON.serialize(values),Account.class);
    }

    private static void insertWithoutMatching (List<Lead> leads)
    {
        LeadToAccountMatching.suppressEnqueue = true;
        try
        {
            insert leads;
        }
        finally
        {
            LeadToAccountMatching.suppressEnqueue = false;
            LeadToAccountMatching.queuedLeadIds.clear();
        }
    }

    private static Lead queryMatchedLead (Id leadId)
    {
        return [
            SELECT Related_Account__c, Street, City, State, PostalCode, Country
            FROM Lead
            WHERE Id = :leadId
        ];
    }
}