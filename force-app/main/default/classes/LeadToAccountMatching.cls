public without sharing class LeadToAccountMatching implements Queueable
{
    private static final String SALES_SITE_LEVEL = 'Sales (Site)';
    private static final String FUZZY_DUPLICATE_RULE_NAME = 'L2ACompanyNameFuzzyCountry';
    private static Set<Id> excludedCreatorIds = parseExcludedCreatorIds(Label.L2AMatchingExcludedCreatedByUsers);

    public static Boolean updatingLeads = false;

    private final Set<Id> leadIds;

    public LeadToAccountMatching (Set<Id> leadIds)
    {
        this.leadIds = leadIds;
    }

    public static void handleLeadTrigger (List<Lead> triggerList, Map<Id,Lead> oldMap)
    {
        Set<Id> leadIdsToQueue = new Set<Id>();

        for (Lead l : triggerList)
        {
            if (trigger.isInsert ||
                l.Related_Contact__c != oldMap.get(l.Id).Related_Contact__c ||
                l.Company != oldMap.get(l.Id).Company ||
                l.Country != oldMap.get(l.Id).Country ||
                l.Domain__c != oldMap.get(l.Id).Domain__c ||
                l.Email != oldMap.get(l.Id).Email)
            {
                leadIdsToQueue.add(l.Id);
            }
        }

        if (!leadIdsToQueue.isEmpty())
            System.enqueueJob(new LeadToAccountMatching(leadIdsToQueue));
    }

    public void execute (QueueableContext context)
    {
        if (leadIds.isEmpty())
            return;

        Map<Id,Lead> leadsById = new Map<Id,Lead>([
            SELECT Id, Company, Country, Domain__c, Related_Contact__c, Related_Account__c,
                Street, City, State, PostalCode
            FROM Lead
            WHERE Id IN :leadIds
        ]);

        if (leadsById.isEmpty())
            return;

        Set<Id> unresolvedLeadIds = new Set<Id>(leadsById.keySet());

        Map<Id,Account> matchesByLeadId = new Map<Id,Account>();

        matchRelatedContactAccounts(
            leadsById,
            unresolvedLeadIds,
            matchesByLeadId
        );

        matchExactNameAndCountry(
            leadsById,
            unresolvedLeadIds,
            matchesByLeadId
        );

        matchFuzzyNameAndCountry(
            leadsById,
            unresolvedLeadIds,
            matchesByLeadId
        );

        matchDomains(
            leadsById,
            unresolvedLeadIds,
            matchesByLeadId
        );

        updateMatchedLeads(leadsById,matchesByLeadId);
    }

    private static void matchRelatedContactAccounts (Map<Id,Lead> leadsById, Set<Id> unresolvedLeadIds, Map<Id,Account> matchesByLeadId)
    {
        Set<Id> contactIds = new Set<Id>();

        for (Id leadId : unresolvedLeadIds)
        {
            Id contactId = leadsById.get(leadId).Related_Contact__c;

            if (contactId != null)
                contactIds.add(contactId);
        }

        if (contactIds.isEmpty())
            return;

        Map<Id,Account> accountsByContactId = new Map<Id,Account>();
        for (Contact relatedContact : [
            SELECT Id, Account.Id, Account.ShippingStreet, Account.ShippingCity,
                Account.ShippingState, Account.ShippingPostalCode, Account.ShippingCountry,
                Account.IM_Hierarchy_Level__c, Account.CreatedById
            FROM Contact
            WHERE Id IN :contactIds
        ])
        {
            if (isQualifyingAccount(relatedContact.Account))
                accountsByContactId.put(relatedContact.Id,relatedContact.Account);
        }

        Set<Id> matchedLeadIds = new Set<Id>();

        for (Id leadId : unresolvedLeadIds)
        {
            Account relatedAccount = accountsByContactId.get(
                leadsById.get(leadId).Related_Contact__c
            );

            if (relatedAccount != null)
            {
                matchesByLeadId.put(leadId,relatedAccount);
                matchedLeadIds.add(leadId);
            }
        }

        unresolvedLeadIds.removeAll(matchedLeadIds);
    }

    private static void matchExactNameAndCountry (Map<Id,Lead> leadsById, Set<Id> unresolvedLeadIds, Map<Id,Account> matchesByLeadId)
    {
        if (unresolvedLeadIds.isEmpty())
            return;

        Set<String> companies = new Set<String>();
        Set<String> countries = new Set<String>();

        for (Id leadId : unresolvedLeadIds)
        {
            Lead leadRecord = leadsById.get(leadId);

            if (String.isNotBlank(leadRecord.Company) && String.isNotBlank(leadRecord.Country))
            {
                companies.add(leadRecord.Company);
                countries.add(leadRecord.Country);
            }
        }

        if (companies.isEmpty() || countries.isEmpty())
            return;

        Map<String,List<Account>> candidatesByNameAndCountry = new Map<String,List<Account>>();

        for (Account candidate : [
            SELECT Id, Name, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode,
                ShippingCountry, Primary_BDE__c, Enterprise_ISR__c, RIM_SDE__c,
                Information_Governance_Rep__c, DMS_Owner__c, IM_IMGA__c, Account_Domain__c,
                DnB_Web_Address__c, CreatedDate
            FROM Account
            WHERE IM_Hierarchy_Level__c = :SALES_SITE_LEVEL
                AND CreatedById NOT IN :excludedCreatorIds
                AND Name IN :companies
                AND ShippingCountry IN :countries
        ])
        {
            addCandidate(
                candidatesByNameAndCountry,
                compoundKey(candidate.Name,candidate.ShippingCountry),
                candidate
            );
        }

        matchFromCandidateMap(
            leadsById,
            unresolvedLeadIds,
            candidatesByNameAndCountry,
            true,
            matchesByLeadId
        );
    }

    private static void matchFuzzyNameAndCountry (Map<Id,Lead> leadsById, Set<Id> unresolvedLeadIds, Map<Id,Account> matchesByLeadId)
    {
        if (unresolvedLeadIds.isEmpty())
            return;

        Map<Id,Set<Id>> accountIdsByLeadId = new Map<Id,Set<Id>>();

        for (DuplicateRecordSet duplicateSet : [
            SELECT Id, (SELECT RecordId FROM DuplicateRecordItems)
            FROM DuplicateRecordSet
            WHERE DuplicateRule.DeveloperName = :FUZZY_DUPLICATE_RULE_NAME
                AND Id IN (
                    SELECT DuplicateRecordSetId
                    FROM DuplicateRecordItem
                    WHERE RecordId IN :unresolvedLeadIds
                )
        ])
        {
            Set<Id> leadIdsInSet = new Set<Id>();
            Set<Id> accountIdsInSet = new Set<Id>();

            for (DuplicateRecordItem item : duplicateSet.DuplicateRecordItems)
            {
                if (unresolvedLeadIds.contains(item.RecordId))
                    leadIdsInSet.add(item.RecordId);
                else if (item.RecordId.getSObjectType() == Account.SObjectType)
                    accountIdsInSet.add(item.RecordId);
            }

            if (accountIdsInSet.isEmpty())
                continue;

            for (Id leadId : leadIdsInSet)
            {
                if (!accountIdsByLeadId.containsKey(leadId))
                    accountIdsByLeadId.put(leadId,new Set<Id>());

                accountIdsByLeadId.get(leadId).addAll(accountIdsInSet);
            }
        }

        if (!accountIdsByLeadId.isEmpty())
        {
            matchFuzzyCandidateAccounts(
                leadsById,
                unresolvedLeadIds,
                matchesByLeadId,
                accountIdsByLeadId
            );
        }
    }

    @TestVisible
    private static void matchFuzzyCandidateAccounts (Map<Id,Lead> leadsById, Set<Id> unresolvedLeadIds, Map<Id,Account> matchesByLeadId, Map<Id,Set<Id>> accountIdsByLeadId)
    {
        Set<Id> candidateAccountIds = new Set<Id>();

        for (Set<Id> accountIds : accountIdsByLeadId.values())
            candidateAccountIds.addAll(accountIds);

        Map<Id,Account> qualifyingAccountsById = new Map<Id,Account>([
            SELECT Id, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode,
                ShippingCountry, Primary_BDE__c, Enterprise_ISR__c, RIM_SDE__c,
                Information_Governance_Rep__c, DMS_Owner__c, IM_IMGA__c, Account_Domain__c,
                DnB_Web_Address__c, CreatedDate
            FROM Account
            WHERE Id IN :candidateAccountIds
                AND IM_Hierarchy_Level__c = :SALES_SITE_LEVEL
                AND CreatedById NOT IN :excludedCreatorIds
        ]);

        Set<Id> matchedLeadIds = new Set<Id>();

        for (Id leadId : accountIdsByLeadId.keySet())
        {
            List<Account> candidates = new List<Account>();

            for (Id accountId : accountIdsByLeadId.get(leadId))
            {
                if (qualifyingAccountsById.containsKey(accountId))
                    candidates.add(qualifyingAccountsById.get(accountId));
            }

            Account bestMatch = chooseBestAccount(leadsById.get(leadId),candidates);

            if (bestMatch != null)
            {
                matchesByLeadId.put(leadId,bestMatch);
                matchedLeadIds.add(leadId);
            }
        }

        unresolvedLeadIds.removeAll(matchedLeadIds);
    }

    private static void matchDomains (Map<Id,Lead> leadsById, Set<Id> unresolvedLeadIds, Map<Id,Account> matchesByLeadId)
    {
        if (unresolvedLeadIds.isEmpty())
            return;

        Set<String> leadDomains = new Set<String>();

        for (Id leadId : unresolvedLeadIds)
        {
            String domain = leadsById.get(leadId).Domain__c;

            if (String.isNotBlank(domain))
                leadDomains.add(domain);
        }

        if (leadDomains.isEmpty())
            return;

        Map<String,List<Account>> candidatesByDomain = new Map<String,List<Account>>();

        for (Account candidate : [
            SELECT Id, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode,
                ShippingCountry, Primary_BDE__c, Enterprise_ISR__c, RIM_SDE__c,
                Information_Governance_Rep__c, DMS_Owner__c, IM_IMGA__c, Account_Domain__c,
                DnB_Web_Address__c, CreatedDate
            FROM Account
            WHERE IM_Hierarchy_Level__c = :SALES_SITE_LEVEL
                AND CreatedById NOT IN :excludedCreatorIds
                AND (Account_Domain__c IN :leadDomains OR DnB_Web_Address__c IN :leadDomains)
        ])
        {
            Set<String> candidateDomains = new Set<String>{
                normalize(candidate.Account_Domain__c),
                normalize(candidate.DnB_Web_Address__c)
            };

            candidateDomains.remove(null);

            for (String candidateDomain : candidateDomains)
                addCandidate(candidatesByDomain,candidateDomain,candidate);
        }

        matchFromCandidateMap(
            leadsById,
            unresolvedLeadIds,
            candidatesByDomain,
            false,
            matchesByLeadId
        );
    }

    private static void matchFromCandidateMap (Map<Id,Lead> leadsById, Set<Id> unresolvedLeadIds, Map<String,List<Account>> candidatesByKey, Boolean useNameAndCountryKey, Map<Id,Account> matchesByLeadId)
    {
        Set<Id> matchedLeadIds = new Set<Id>();

        for (Id leadId : unresolvedLeadIds)
        {
            Lead leadRecord = leadsById.get(leadId);

            Account bestMatch = chooseBestAccount(
                leadRecord,
                candidatesByKey.get(
                    useNameAndCountryKey
                    ? compoundKey(leadRecord.Company,leadRecord.Country)
                    : normalize(leadRecord.Domain__c)
                )
            );

            if (bestMatch != null)
            {
                matchesByLeadId.put(leadId,bestMatch);
                matchedLeadIds.add(leadId);
            }
        }

        unresolvedLeadIds.removeAll(matchedLeadIds);
    }

    @TestVisible
    private static Account chooseBestAccount (Lead leadRecord, List<Account> candidates)
    {
        if (candidates == null || candidates.isEmpty())
            return null;

        Account bestMatch;

        for (Account candidate : candidates)
        {
            if (bestMatch == null || isBetterMatch(leadRecord,candidate,bestMatch))
                bestMatch = candidate;
        }

        return bestMatch;
    }

    private static Boolean isBetterMatch (Lead leadRecord, Account candidate, Account currentBest)
    {
        Boolean candidateHasCoverage = hasActiveSalesCoverage(candidate);

        if (candidateHasCoverage != hasActiveSalesCoverage(currentBest))
            return candidateHasCoverage;

        Boolean candidateHasImga = String.isNotBlank(candidate.IM_IMGA__c);

        if (candidateHasImga != String.isNotBlank(currentBest.IM_IMGA__c))
            return candidateHasImga;

        Integer candidateDomainRank = domainRank(
            leadRecord.Domain__c,
            candidate.Account_Domain__c,
            candidate.DnB_Web_Address__c
        );

        Integer bestDomainRank = domainRank(
            leadRecord.Domain__c,
            currentBest.Account_Domain__c,
            currentBest.DnB_Web_Address__c
        );

        if (candidateDomainRank != bestDomainRank)
            return candidateDomainRank < bestDomainRank;

        if (candidate.CreatedDate != currentBest.CreatedDate)
            return candidate.CreatedDate < currentBest.CreatedDate;

        return false;
    }

    private static Boolean hasActiveSalesCoverage (Account accountRecord)
    {
        return accountRecord.Primary_BDE__c != null
            || accountRecord.Enterprise_ISR__c != null
            || accountRecord.RIM_SDE__c != null
            || accountRecord.Information_Governance_Rep__c != null
            || accountRecord.DMS_Owner__c != null;
    }

    @TestVisible
    private static Integer domainRank (String leadDomain, String accountDomain, String dnbWebAddress)
    {
        String normalizedLeadDomain = normalize(leadDomain);

        if (normalizedLeadDomain != null && normalizedLeadDomain == normalize(accountDomain))
            return 1;

        if (normalizedLeadDomain != null && normalizedLeadDomain == normalize(dnbWebAddress))
            return 2;

        return 3;
    }

    private static Boolean isQualifyingAccount (Account accountRecord)
    {
        return accountRecord != null &&
            accountRecord.IM_Hierarchy_Level__c == SALES_SITE_LEVEL &&
            !excludedCreatorIds.contains(accountRecord.CreatedById);
    }

    @TestVisible
    private static Set<Id> parseExcludedCreatorIds (String labelValue)
    {
        Set<Id> excludedCreatorIds = new Set<Id>();

        if (String.isBlank(labelValue))
            return excludedCreatorIds;

        for (String rawValue : labelValue.split(','))
        {
            String candidateValue = rawValue.trim();

            if (!String.isBlank(candidateValue))
            {
                try
                {
                    Id candidateId = (Id)candidateValue;

                    if (candidateId.getSObjectType() == User.SObjectType)
                        excludedCreatorIds.add(candidateId);
                }
                catch (Exception invalidId){}
            }
        }

        return excludedCreatorIds;
    }

    private static void addCandidate (Map<String,List<Account>> candidatesByKey, String key, Account candidate)
    {
        if (!candidatesByKey.containsKey(key))
            candidatesByKey.put(key,new List<Account>());

        candidatesByKey.get(key).add(candidate);
    }

    private static String compoundKey (String firstValue, String secondValue)
    {
        String firstKey = normalize(firstValue);
        String secondKey = normalize(secondValue);

        return firstKey != null && secondKey != null ? firstKey + '|' + secondKey : null;
    }

    private static String normalize (String value)
    {
        return String.isNotBlank(value) ? value.trim().toLowerCase() : null;
    }

    private static void updateMatchedLeads (Map<Id,Lead> leadsById, Map<Id,Account> matchesByLeadId)
    {
        List<Lead> leadsToUpdate = new List<Lead>();

        for (Id leadId : matchesByLeadId.keySet())
        {
            Lead l = leadsById.get(leadId);
            Account match = matchesByLeadId.get(leadId);

            if (l.Related_Account__c == match.Id
                && l.Street == match.ShippingStreet
                && l.City == match.ShippingCity
                && l.State == match.ShippingState
                && l.PostalCode == match.ShippingPostalCode
                && l.Country == match.ShippingCountry)
            {
                continue;
            }

            leadsToUpdate.add(new Lead(
                Id = leadId,
                Related_Account__c = match.Id,
                Street = match.ShippingStreet,
                City = match.ShippingCity,
                State = match.ShippingState,
                PostalCode = match.ShippingPostalCode,
                Country = match.ShippingCountry
            ));
        }

        if (!leadsToUpdate.isEmpty())
        {
            updatingLeads = true;
            try { update leadsToUpdate; }
            finally { updatingLeads = false; }
        }
    }
}