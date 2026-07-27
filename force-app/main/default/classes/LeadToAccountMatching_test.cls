@isTest
private without sharing class LeadToAccountMatching_test
{
    private static final String SALES_SITE_LEVEL = 'Sales (Site)';
    private static final String COUNTRY_US = 'United States';

    @TestSetup
    static void createApprovedCountries()
    {
        List<IM_Country__c> countries = new List<IM_Country__c>{
            new IM_Country__c(Name = COUNTRY_US,Active__c = true),
            new IM_Country__c(Name = 'Canada',Active__c = true)
        };

        insert as system countries;

        insert as system new List<IM_Alternative_Country_Name__c>{
            new IM_Alternative_Country_Name__c(
                Alternative_Name__c = COUNTRY_US,
                IM_Country__c = countries[0].Id
            ),
            new IM_Alternative_Country_Name__c(
                Alternative_Name__c = 'Canada',
                IM_Country__c = countries[1].Id
            )
        };
    }

    @isTest
    static void exactMatchPopulatesAccountAndBillingAddress()
    {
        System.runAs(createTestUser('exact'))
        {
            Account exactAccount = createSalesSite('Exact Company',COUNTRY_US);
            exactAccount.BillingStreet = '100 Exact Street';
            exactAccount.BillingCity = 'Boston';
            exactAccount.BillingState = 'Massachusetts';
            exactAccount.BillingPostalCode = '02108';
            update as system exactAccount;

            Account domainAccount = salesSite('Domain Fallback Company','Canada');
            domainAccount.Website = 'https://exact-priority-example.com';
            insert as system domainAccount;

            Lead leadRecord = newLead(
                'Exact Company',
                COUNTRY_US,
                'exact@exact-priority-example.com'
            );

            leadRecord.Street = 'Old Street';
            leadRecord.City = 'Old City';
            leadRecord.State = 'Old State';
            leadRecord.PostalCode = '00000';

            Test.startTest();
            insert as system leadRecord;

            System.assertEquals(Limits.getQueueableJobs(),1);
            System.assertEquals(queryMatchedLead(leadRecord.Id).RelatedAccountMatchingComplete__c,false);

            Test.stopTest();

            Lead matchedLead = queryMatchedLead(leadRecord.Id);

            System.assertEquals(matchedLead.Related_Account__c,exactAccount.Id);
            System.assertEquals(matchedLead.Street,exactAccount.BillingStreet);
            System.assertEquals(matchedLead.City,exactAccount.BillingCity);
            System.assertEquals(matchedLead.State,exactAccount.BillingState);
            System.assertEquals(matchedLead.PostalCode,exactAccount.BillingPostalCode);
            System.assertEquals(matchedLead.Country,exactAccount.BillingCountry);
            System.assertEquals(matchedLead.RelatedAccountMatchingComplete__c,true);
        }
    }

    @isTest
    static void relatedContactAccountTakesPriority()
    {
        System.runAs(createTestUser('contact'))
        {
            Account contactAccount = createSalesSite('Contact Account',COUNTRY_US);
            contactAccount.BillingCity = 'Chicago';
            update as system contactAccount;

            createSalesSite('Lead Company',COUNTRY_US);

            Contact relatedContact = new Contact(
                FirstName = 'Priority',
                LastName = 'Related Contact',
                AccountId = contactAccount.Id
            );

            insert as system relatedContact;

            Lead leadRecord = newLead('Lead Company',COUNTRY_US,null);
            leadRecord.Related_Contact__c = relatedContact.Id;

            Test.startTest();
            insert as system leadRecord;
            Test.stopTest();

            Lead matchedLead = queryMatchedLead(leadRecord.Id);

            System.assertEquals(matchedLead.Related_Account__c,contactAccount.Id);
            System.assertEquals(matchedLead.City,'Chicago');
        }
    }

    @isTest
    static void unqualifiedRelatedContactAccountsFallThroughToExactMatching()
    {
        User excludedUser = createTestUser('contactExcluded');
        User matchingUser = createTestUser('contactFallback');
        Account excludedAccount;

        System.runAs(excludedUser)
        {
            excludedAccount = createSalesSite('Excluded Contact Company',COUNTRY_US);
        }

        System.runAs(matchingUser)
        {
            Account eligibleExcludedFallback = createSalesSite(
                'Excluded Contact Company',
                COUNTRY_US
            );

            Account nonSalesAccount = operationalAccount(
                'Non-Sales Contact Company',
                COUNTRY_US
            );

            insert as system nonSalesAccount;

            Account eligibleNonSalesFallback = createSalesSite(
                'Non-Sales Contact Company',
                COUNTRY_US
            );

            Account eligibleNoAccountFallback = createSalesSite(
                'No Account Contact Company',
                COUNTRY_US
            );

            Contact excludedContact = new Contact(
                FirstName = 'Excluded',
                LastName = 'Excluded Account Contact',
                AccountId = excludedAccount.Id
            );

            Contact nonSalesContact = new Contact(
                FirstName = 'Non-Sales',
                LastName = 'Non-Sales Account Contact',
                AccountId = nonSalesAccount.Id
            );

            Contact noAccountContact = new Contact(
                FirstName = 'No Account',
                LastName = 'No Account Contact'
            );

            insert as system new List<Contact>{
                excludedContact,
                nonSalesContact,
                noAccountContact
            };

            Lead excludedContactLead = newLead(
                'Excluded Contact Company',
                COUNTRY_US,
                null
            );

            excludedContactLead.Related_Contact__c = excludedContact.Id;

            Lead nonSalesContactLead = newLead(
                'Non-Sales Contact Company',
                COUNTRY_US,
                null
            );

            nonSalesContactLead.Related_Contact__c = nonSalesContact.Id;

            Lead noAccountContactLead = newLead(
                'No Account Contact Company',
                COUNTRY_US,
                null
            );

            noAccountContactLead.Related_Contact__c = noAccountContact.Id;

            LeadToAccountMatching.excludedCreatorIds = new Set<Id>{excludedUser.Id};

            Test.startTest();

            insert as system new List<Lead>{
                excludedContactLead,
                nonSalesContactLead,
                noAccountContactLead
            };

            System.assertEquals(Limits.getQueueableJobs(),1);

            Test.stopTest();

            Map<Id,Lead> matchedLeadsById = new Map<Id,Lead>([
                SELECT Related_Account__c
                FROM Lead
                WHERE Id IN :new Set<Id>{
                    excludedContactLead.Id,
                    nonSalesContactLead.Id,
                    noAccountContactLead.Id
                }
                WITH SYSTEM_MODE
            ]);

            System.assertEquals(
                matchedLeadsById.get(excludedContactLead.Id).Related_Account__c,
                eligibleExcludedFallback.Id
            );

            System.assertEquals(
                matchedLeadsById.get(nonSalesContactLead.Id).Related_Account__c,
                eligibleNonSalesFallback.Id
            );

            System.assertEquals(
                matchedLeadsById.get(noAccountContactLead.Id).Related_Account__c,
                eligibleNoAccountFallback.Id
            );
        }
    }

    @isTest
    static void tiebreakersApplyInPriorityOrder()
    {
        User testUser = createTestUser('tie');
        Lead leadRecord = leadWithDomain('priority-example.com');

        Account lowerPriorityAccount = comparisonAccount(
            'Lower Priority',
            'Lower Priority IMGA',
            'priority-example.com',
            null
        );

        for (String coverageField : new List<String>{
            'Primary_BDE__c',
            'Enterprise_ISR__c',
            'RIM_SDE__c',
            'Information_Governance_Rep__c',
            'DMS_Owner__c'
        })
        {
            Account coveredAccount = comparisonAccount(
                coverageField,
                null,
                null,
                null
            );

            coveredAccount.put(coverageField,testUser.Id);

            System.assertEquals(
                LeadToAccountMatching.chooseBestAccount(
                    leadRecord,
                    new List<Account>{lowerPriorityAccount,coveredAccount}
                ).Name,
                coverageField
            );
        }

        System.assertEquals(
            LeadToAccountMatching.chooseBestAccount(
                leadRecord,
                new List<Account>{
                    comparisonAccount(
                        'With IMGA',
                        'Priority IMGA',
                        null,
                        null
                    ),
                    comparisonAccount(
                        'With Domain',
                        null,
                        'priority-example.com',
                        null
                    )
                }
            ).Name,
            'With IMGA'
        );

        System.assertEquals(
            LeadToAccountMatching.chooseBestAccount(
                leadRecord,
                new List<Account>{
                    comparisonAccount(
                        'DNB Domain',
                        null,
                        null,
                        'priority-example.com'
                    ),
                    comparisonAccount(
                        'Account Domain',
                        null,
                        'priority-example.com',
                        null
                    )
                }
            ).Name,
            'Account Domain'
        );

        System.assertEquals(
            LeadToAccountMatching.chooseBestAccount(
                leadRecord,
                new List<Account>{
                    comparisonAccount('No Domain',null,null,null),
                    comparisonAccount(
                        'DNB Domain',
                        null,
                        null,
                        'priority-example.com'
                    )
                }
            ).Name,
            'DNB Domain'
        );

        System.assertEquals(
            LeadToAccountMatching.chooseBestAccount(leadRecord,null),
            null
        );

        System.assertEquals(
            LeadToAccountMatching.chooseBestAccount(
                leadRecord,
                new List<Account>{
                    comparisonAccount('First Equal',null,null,null),
                    comparisonAccount('Second Equal',null,null,null)
                }
            ).Name,
            'First Equal'
        );
    }

    @isTest
    static void earliestCreatedDateBreaksRemainingTie()
    {
        System.runAs(createTestUser('oldest'))
        {
            Account olderAccount = salesSite('Oldest Company',COUNTRY_US);
            Account newerAccount = salesSite('Oldest Company',COUNTRY_US);

            insert as system new List<Account>{olderAccount,newerAccount};

            Test.setCreatedDate(olderAccount.Id,Datetime.now().addYears(-2));
            Test.setCreatedDate(newerAccount.Id,Datetime.now().addYears(-1));

            Lead leadRecord = newLead('Oldest Company',COUNTRY_US,null);

            Test.startTest();
            insert as system leadRecord;
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
        User excludedUser = createTestUser('domainExcluded');
        User matchingUser = createTestUser('domain');
        Account excludedDomainAccount;

        insert as system new PermissionSetAssignment(
            AssigneeId = matchingUser.Id,
            PermissionSetId = [
                SELECT Id
                FROM PermissionSet
                WHERE Name = 'DnBConnect_Custom_Object_Field_Permissions'
                LIMIT 1
            ].Id
        );

        System.runAs(excludedUser)
        {
            excludedDomainAccount = salesSite('Excluded Domain Account','Canada');
            excludedDomainAccount.Website = 'https://domain-match-example.com';
            insert as system excludedDomainAccount;
        }

        System.runAs(matchingUser)
        {
            Account domainAccount = salesSite('Different Account Name','Canada');
            domainAccount.Website = 'https://www.domain-match-example.com/a-page';
            domainAccount.BillingCity = 'Toronto';
            insert as system domainAccount;

            Account nonSalesDomainAccount = operationalAccount(
                'Non-Sales Domain Account',
                'Canada'
            );

            nonSalesDomainAccount.Website = 'https://domain-match-example.com';
            insert as system nonSalesDomainAccount;

            DNBConnect__D_B_Connect_Company_Profile__c priorityDnbProfile =
                new DNBConnect__D_B_Connect_Company_Profile__c(
                    DNBConnect__DUNSNumber__c = '123456789'
                );

            priorityDnbProfile.put(
                'organization_website_address_domain_1__c',
                'domain-match-example.com'
            );

            DNBConnect__D_B_Connect_Company_Profile__c fallbackDnbProfile =
                new DNBConnect__D_B_Connect_Company_Profile__c(
                    DNBConnect__DUNSNumber__c = '987654321'
                );

            fallbackDnbProfile.put(
                'organization_website_address_domain_1__c',
                'dnb-only-example.com'
            );

            insert as system new List<DNBConnect__D_B_Connect_Company_Profile__c>{
                priorityDnbProfile,
                fallbackDnbProfile
            };

            Account priorityDnbAccount = salesSite('Priority DNB Account','Canada');
            priorityDnbAccount.BillingCity = 'Calgary';

            priorityDnbAccount.DNBConnect__D_B_Connect_Company_Profile__c =
                priorityDnbProfile.Id;

            Account fallbackDnbAccount = salesSite('Fallback DNB Account','Canada');
            fallbackDnbAccount.BillingCity = 'Vancouver';

            fallbackDnbAccount.DNBConnect__D_B_Connect_Company_Profile__c =
                fallbackDnbProfile.Id;

            insert as system new List<Account>{priorityDnbAccount,fallbackDnbAccount};

            priorityDnbAccount.Website = 'https://priority-dnb-nonmatch.example';
            fallbackDnbAccount.Website = 'https://fallback-dnb-nonmatch.example';
            update as system new List<Account>{priorityDnbAccount,fallbackDnbAccount};

            Map<Id,Account> queriedDnbAccountsById = new Map<Id,Account>([
                SELECT Account_Domain__c, DnB_Web_Address__c
                FROM Account
                WHERE Id IN :new Set<Id>{priorityDnbAccount.Id,fallbackDnbAccount.Id}
                WITH SYSTEM_MODE
            ]);

            System.assertEquals(
                LeadToAccountMatching.domainRank(
                    'domain-match-example.com',
                    queriedDnbAccountsById.get(priorityDnbAccount.Id).Account_Domain__c,
                    queriedDnbAccountsById.get(priorityDnbAccount.Id).DnB_Web_Address__c
                ),
                2
            );

            System.assertEquals(
                LeadToAccountMatching.domainRank(
                    'dnb-only-example.com',
                    queriedDnbAccountsById.get(fallbackDnbAccount.Id).Account_Domain__c,
                    queriedDnbAccountsById.get(fallbackDnbAccount.Id).DnB_Web_Address__c
                ),
                2
            );

            Test.setCreatedDate(excludedDomainAccount.Id,Datetime.now().addYears(-5));
            Test.setCreatedDate(nonSalesDomainAccount.Id,Datetime.now().addYears(-4));
            Test.setCreatedDate(priorityDnbAccount.Id,Datetime.now().addYears(-3));

            Lead accountDomainLead = newLead(
                'No Name Match',
                COUNTRY_US,
                'alice.smith@domain-match-example.com'
            );

            Lead dnbDomainLead = newLead(
                'No DNB Name Match',
                COUNTRY_US,
                'bob.jones@dnb-only-example.com'
            );

            LeadToAccountMatching.excludedCreatorIds = new Set<Id>{excludedUser.Id};

            Test.startTest();
            insert as system new List<Lead>{accountDomainLead,dnbDomainLead};

            System.assertEquals(Limits.getQueueableJobs(),1);

            Test.stopTest();

            Lead matchedAccountDomainLead = queryMatchedLead(accountDomainLead.Id);
            Lead matchedDnbDomainLead = queryMatchedLead(dnbDomainLead.Id);

            System.assertEquals(matchedAccountDomainLead.Related_Account__c,domainAccount.Id);
            System.assertEquals(matchedAccountDomainLead.Country,'Canada');
            System.assertEquals(matchedAccountDomainLead.City,'Toronto');
            System.assertEquals(matchedDnbDomainLead.Related_Account__c,fallbackDnbAccount.Id);
            System.assertEquals(matchedDnbDomainLead.Country,'Canada');
            System.assertEquals(matchedDnbDomainLead.City,'Vancouver');

            System.assertEquals(
                [
                    SELECT COUNT()
                    FROM AsyncApexJob
                    WHERE ApexClass.Name = 'LeadToAccountMatching'
                ],
                1
            );
        }
    }

    @isTest
    static void personalDomainsDoNotMatchOrInfluenceTiebreakers()
    {
        System.runAs(createTestUser('personalDomain'))
        {
            Account personalDomainAccount = salesSite(
                'Consumer Mailbox Record',
                'Canada'
            );

            personalDomainAccount.Website = 'https://gmail.com';
            insert as system personalDomainAccount;

            Lead leadRecord = newLead(
                'Unrelated Prospect Company',
                COUNTRY_US,
                'person@GMAIL.COM'
            );

            Test.startTest();
            insert as system leadRecord;
            Test.stopTest();

            Lead processedLead = queryMatchedLead(leadRecord.Id);

            System.assertEquals(processedLead.Related_Account__c,null);
            System.assertEquals(processedLead.RelatedAccountMatchingComplete__c,true);
            System.assertEquals(
                LeadToAccountMatching.domainRank(
                    ' GMAIL.COM ',
                    'gmail.com',
                    'gmail.com'
                ),
                3
            );

            System.assertEquals(
                LeadToAccountMatching.chooseBestAccount(
                    leadWithDomain('gmail.com'),
                    new List<Account>{
                        comparisonAccount('No Domain',null,null,null),
                        comparisonAccount('Personal Domain',null,'gmail.com',null)
                    }
                ).Name,
                'No Domain'
            );
        }
    }

    @isTest
    static void fuzzyCandidatesAreQualifiedAndSelected()
    {
        User excludedUser = createTestUser('fuzzyExcluded');
        User matchingUser = createTestUser('fuzzy');
        Account excludedFuzzyAccount;

        System.runAs(excludedUser)
        {
            excludedFuzzyAccount = createSalesSite('Acme Incorporated',COUNTRY_US);
        }

        System.runAs(matchingUser)
        {
            Account nonSalesFuzzyAccount = operationalAccount(
                'Acme Corporate',
                COUNTRY_US
            );

            insert as system nonSalesFuzzyAccount;

            Account fuzzyAccount = createSalesSite('Acme Corporation',COUNTRY_US);
            fuzzyAccount.BillingCity = 'Fuzzy City';
            fuzzyAccount.Primary_BDE__c = matchingUser.Id;
            update as system fuzzyAccount;

            Account domainAccount = salesSite('Domain Fallback Account','Canada');
            domainAccount.BillingCity = 'Domain City';
            domainAccount.Website = 'https://fuzzy-priority-example.com';
            insert as system domainAccount;

            Lead leadRecord = newLead(
                'Acme Corp',
                COUNTRY_US,
                'fuzzy@fuzzy-priority-example.com'
            );

            Lead unrelatedLead = newLead(
                'Unrelated Duplicate Lead',
                COUNTRY_US,
                null
            );

            LeadToAccountMatching.excludedCreatorIds = new Set<Id>{excludedUser.Id};

            insertWithoutMatching(new List<Lead>{leadRecord,unrelatedLead},domainAccount.Id);

            Id duplicateRuleId = [
                SELECT Id
                FROM DuplicateRule
                WHERE DeveloperName = 'L2ACompanyNameFuzzyCountry'
                LIMIT 1
            ].Id;

            DuplicateRecordSet duplicateSet = new DuplicateRecordSet(
                DuplicateRuleId = duplicateRuleId
            );

            insert as system duplicateSet;

            insert as system new List<DuplicateRecordItem>{
                new DuplicateRecordItem(
                    DuplicateRecordSetId = duplicateSet.Id,
                    RecordId = leadRecord.Id
                ),
                new DuplicateRecordItem(
                    DuplicateRecordSetId = duplicateSet.Id,
                    RecordId = excludedFuzzyAccount.Id
                ),
                new DuplicateRecordItem(
                    DuplicateRecordSetId = duplicateSet.Id,
                    RecordId = nonSalesFuzzyAccount.Id
                ),
                new DuplicateRecordItem(
                    DuplicateRecordSetId = duplicateSet.Id,
                    RecordId = fuzzyAccount.Id
                )
            };

            DuplicateRecordSet noAccountDuplicateSet = new DuplicateRecordSet(
                DuplicateRuleId = duplicateRuleId
            );

            insert as system noAccountDuplicateSet;

            insert as system new List<DuplicateRecordItem>{
                new DuplicateRecordItem(
                    DuplicateRecordSetId = noAccountDuplicateSet.Id,
                    RecordId = leadRecord.Id
                ),
                new DuplicateRecordItem(
                    DuplicateRecordSetId = noAccountDuplicateSet.Id,
                    RecordId = unrelatedLead.Id
                )
            };

            Lead queriedLead = [
                SELECT Id, Domain__c
                FROM Lead
                WHERE Id = :leadRecord.Id
                WITH SYSTEM_MODE
            ];

            Set<Id> unresolvedLeadIds = new Set<Id>{queriedLead.Id};
            Map<Id,Account> matchesByLeadId = new Map<Id,Account>();

            Test.startTest();

            LeadToAccountMatching.matchFuzzyNameAndCountry(
                new Map<Id,Lead>{queriedLead.Id => queriedLead},
                unresolvedLeadIds,
                matchesByLeadId
            );

            Test.stopTest();

            System.assertEquals(matchesByLeadId.get(queriedLead.Id).Id,fuzzyAccount.Id);
            System.assertEquals(unresolvedLeadIds.size(),0);
        }
    }

    @isTest
    static void existingRelatedAccountSkipsMatching()
    {
        System.runAs(createTestUser('retain'))
        {
            Account existingAccount = createSalesSite('Existing Account',COUNTRY_US);
            createSalesSite('Original Company',COUNTRY_US);

            Lead leadRecord = newLead('Original Company',COUNTRY_US,null);
            leadRecord.Related_Account__c = existingAccount.Id;
            leadRecord.Street = 'Retained Street';
            leadRecord.City = 'Retained City';
            leadRecord.State = 'Retained State';
            leadRecord.PostalCode = '12345';

            Test.startTest();
            insert as system leadRecord;

            System.assertEquals(Limits.getQueueableJobs(),0);
            System.assertEquals(queryMatchedLead(leadRecord.Id).RelatedAccountMatchingComplete__c,true);

            leadRecord.Company = 'No Matching Company';
            update as system leadRecord;

            System.assertEquals(Limits.getQueueableJobs(),0);

            Test.stopTest();

            Lead retainedLead = queryMatchedLead(leadRecord.Id);

            System.assertEquals(retainedLead.Related_Account__c,existingAccount.Id);
            System.assertEquals(retainedLead.Street,'Retained Street');
            System.assertEquals(retainedLead.City,'Retained City');
            System.assertEquals(retainedLead.State,'Retained State');
            System.assertEquals(retainedLead.PostalCode,'12345');
            System.assertEquals(retainedLead.Country,COUNTRY_US);
            System.assertEquals(retainedLead.RelatedAccountMatchingComplete__c,true);
        }
    }

    @isTest
    static void matchingInputUpdatesDoNotQueue()
    {
        System.runAs(createTestUser('inputUpdates'))
        {
            Account relatedAccount = createSalesSite('Updated Related Contact Account',COUNTRY_US);

            Contact relatedContact = new Contact(
                FirstName = 'Updated',
                LastName = 'Updated Related Contact',
                AccountId = relatedAccount.Id
            );

            insert as system relatedContact;

            Lead leadRecord = newLead(
                'Original Update Company',
                'Canada',
                'lead@original-update-example.com'
            );

            insertWithoutMatching(new List<Lead>{leadRecord},relatedAccount.Id);

            leadRecord.Related_Contact__c = relatedContact.Id;
            leadRecord.Company = 'Updated Input Company';
            leadRecord.Country = COUNTRY_US;
            leadRecord.Email = 'lead@updated-input-example.com';

            Test.startTest();
            update as system leadRecord;

            System.assertEquals(Limits.getQueueableJobs(),0);

            Test.stopTest();

            Lead unmatchedLead = queryMatchedLead(leadRecord.Id);

            System.assertEquals(unmatchedLead.Related_Account__c,null);
            System.assertEquals(unmatchedLead.RelatedAccountMatchingComplete__c,false);
        }
    }

    @isTest
    static void accountUpdatesDoNotQueueLeadMatching()
    {
        System.runAs(createTestUser('accountUpdate'))
        {
            Account accountRecord = createSalesSite('Account Update Company',COUNTRY_US);

            Test.startTest();
            accountRecord.BillingCity = 'Updated City';
            update as system accountRecord;
            Test.stopTest();

            System.assertEquals(
                [
                    SELECT COUNT()
                    FROM AsyncApexJob
                    WHERE ApexClass.Name = 'LeadToAccountMatching'
                ],
                0
            );
        }
    }

    @isTest
    static void deletedQueuedLeadIsIgnored()
    {
        System.runAs(createTestUser('deleted'))
        {
            Lead leadRecord = newLead('Deleted Lead Company',COUNTRY_US,null);

            Test.startTest();
            insert as system leadRecord;

            System.assertEquals(Limits.getQueueableJobs(),1);

            delete leadRecord;
            Test.stopTest();

            AsyncApexJob matchingJob = [
                SELECT Status, NumberOfErrors
                FROM AsyncApexJob
                WHERE ApexClass.Name = 'LeadToAccountMatching'
                LIMIT 1
            ];

            System.assertEquals(matchingJob.Status,'Completed');
            System.assertEquals(matchingJob.NumberOfErrors,0);
        }
    }

    @isTest
    static void blankCountrySkipsExactMatching()
    {
        Id leadId = (Id)'00Q000000000001';

        Set<Id> unresolvedLeadIds = new Set<Id>{leadId};
        Map<Id,Account> matchesByLeadId = new Map<Id,Account>();

        Test.startTest();

        LeadToAccountMatching.matchExactNameAndCountry(
            new Map<Id,Lead>{
                leadId => new Lead(
                    Id = leadId,
                    Company = 'Blank Country Company'
                )
            },
            unresolvedLeadIds,
            matchesByLeadId
        );

        Test.stopTest();

        System.assertEquals(unresolvedLeadIds,new Set<Id>{leadId});
        System.assertEquals(matchesByLeadId,new Map<Id,Account>());
    }

    @isTest
    static void failedLeadUpdateDoesNotRollbackSuccessfulLeads()
    {
        System.runAs(createTestUser('partialDml'))
        {
            Account setupAccount = createSalesSite('Partial DML Setup Account',COUNTRY_US);
            Lead successfulLead = newLead('Successful Partial DML Company',COUNTRY_US,null);
            Lead deletedLead = newLead('Deleted Partial DML Company',COUNTRY_US,null);
            insertWithoutMatching(new List<Lead>{successfulLead,deletedLead},setupAccount.Id);
            delete deletedLead;

            Test.startTest();

            LeadToAccountMatching.updateProcessedLeads(
                new Map<Id,Lead>{
                    successfulLead.Id => successfulLead,
                    deletedLead.Id => deletedLead
                },
                new Map<Id,Account>()
            );

            Test.stopTest();

            System.assertEquals(
                queryMatchedLead(successfulLead.Id).RelatedAccountMatchingComplete__c,
                true
            );
        }
    }

    @isTest
    static void bulkInsertUsesOneJobAndMatchesEveryLead()
    {
        System.runAs(createTestUser('bulk'))
        {
            List<Account> matchingAccounts = new List<Account>{
                salesSite('Bulk Alpha',COUNTRY_US),
                salesSite('Bulk Alpha','Canada'),
                salesSite('Bulk Beta',COUNTRY_US),
                salesSite('Bulk Beta','Canada')
            };

            insert as system matchingAccounts;

            Map<String,Id> accountIdsByPair = new Map<String,Id>{
                'Bulk Alpha|' + COUNTRY_US => matchingAccounts[0].Id,
                'Bulk Alpha|Canada' => matchingAccounts[1].Id,
                'Bulk Beta|' + COUNTRY_US => matchingAccounts[2].Id,
                'Bulk Beta|Canada' => matchingAccounts[3].Id
            };

            List<Lead> leads = new List<Lead>();

            for (Integer index = 0; index < 200; index++)
            {
                Integer pairIndex = Math.mod(index,4);

                leads.add(
                    newLead(
                        pairIndex < 2 ? 'Bulk Alpha' : 'Bulk Beta',
                        Math.mod(pairIndex,2) == 0 ? COUNTRY_US : 'Canada',
                        null
                    )
                );
            }

            Test.startTest();
            insert as system leads;

            System.assertEquals(Limits.getQueueableJobs(),1);

            Test.stopTest();

            Map<Id,Lead> matchedLeadsById = new Map<Id,Lead>([
                SELECT Related_Account__c
                FROM Lead
                WHERE Id IN :new Map<Id,Lead>(leads).keySet()
                WITH SYSTEM_MODE
            ]);

            System.assertEquals(matchedLeadsById.size(),200);

            for (Lead leadRecord : leads)
            {
                System.assertEquals(
                    matchedLeadsById.get(leadRecord.Id).Related_Account__c,
                    accountIdsByPair.get(leadRecord.Company + '|' + leadRecord.Country)
                );
            }

            System.assertEquals(
                [
                    SELECT COUNT()
                    FROM Lead
                    WHERE Id IN :new Map<Id,Lead>(leads).keySet()
                        AND RelatedAccountMatchingComplete__c = true
                    WITH SYSTEM_MODE
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

        System.assertEquals(
            LeadToAccountMatching.parseExcludedCreatorIds(null),
            new Set<Id>()
        );

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

        insert as system testUser;

        return testUser;
    }

    private static Account createSalesSite (String name, String country)
    {
        Account accountRecord = salesSite(name,country);
        insert as system accountRecord;

        return accountRecord;
    }

    private static Account salesSite (String name, String country)
    {
        return new Account(
            Name = name,
            BillingCountry = country,
            IM_Hierarchy_Level__c = SALES_SITE_LEVEL
        );
    }

    private static Account operationalAccount (String name, String country)
    {
        return new Account(
            Name = name,
            BillingStreet = '100 Operational Street',
            BillingCity = 'Operational City',
            BillingCountry = country,
            IM_Hierarchy_Level__c = 'Operational Account',
            RecordTypeId = [
                SELECT Id
                FROM RecordType
                WHERE SObjectType = 'Account'
                    AND DeveloperName = 'Operational_Account'
                LIMIT 1
            ].Id
        );
    }

    private static Lead newLead (String company, String country, String email)
    {
        return new Lead(
            LastName = company + ' Matching Test',
            Company = company,
            Status = 'New',
            Country = country,
            Email = email,
            Product_Interest__c = 'Data Centers'
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

    private static Account comparisonAccount (String name, String imga, String accountDomain, String dnbDomain)
    {
        return (Account) JSON.deserialize(
            JSON.serialize(new Map<String,Object>{
                'attributes' => new Map<String,Object>{'type' => 'Account'},
                'Name' => name,
                'IM_IMGA__c' => imga,
                'Account_Domain__c' => accountDomain,
                'DnB_Web_Address__c' => dnbDomain
            }),
            Account.class
        );
    }

    private static void insertWithoutMatching (List<Lead> leads, Id relatedAccountId)
    {
        for (Lead leadRecord : leads)
            leadRecord.Related_Account__c = relatedAccountId;

        insert as system leads;

        for (Lead leadRecord : leads)
        {
            leadRecord.Related_Account__c = null;
            leadRecord.RelatedAccountMatchingComplete__c = false;
        }

        update as system leads;
    }

    private static Lead queryMatchedLead (Id leadId)
    {
        return [
            SELECT Related_Account__c, RelatedAccountMatchingComplete__c,
                Street, City, State, PostalCode, Country
            FROM Lead
            WHERE Id = :leadId
            WITH SYSTEM_MODE
        ];
    }
}