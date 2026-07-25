public without sharing class LeadToAccountMatching implements Queueable
{
    private static final String SALES_SITE_LEVEL = 'Sales (Site)';
    private static final String FUZZY_DUPLICATE_RULE_NAME = 'L2ACompanyNameFuzzyCountry';
    private static final String LOG_PREFIX = 'LeadToAccountMatching | ';

    @TestVisible
    private static Set<Id> excludedCreatorIds = parseExcludedCreatorIds(Label.L2AMatchingExcludedCreatedByUsers);

    private final Set<Id> leadIds;

    public LeadToAccountMatching (Set<Id> leadIds)
    {
        this.leadIds = leadIds;
    }

    public static void handleLeadTrigger (List<Lead> triggerList)
    {
        Set<Id> leadIdsToQueue = new Set<Id>();

        for (Lead l : triggerList)
        {
            if (l.Related_Account__c == null)
                leadIdsToQueue.add(l.Id);
        }

        System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'trigger evaluated ' + triggerList.size() + ' Leads; queueing IDs ' + leadIdsToQueue);

        if (!leadIdsToQueue.isEmpty())
            System.enqueueJob(new LeadToAccountMatching(leadIdsToQueue),1);
    }

    public void execute (QueueableContext context)
    {
        System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'Queueable ' + context.getJobId() + ' started for Lead IDs ' + leadIds);

        Map<Id,Lead> leadsById = new Map<Id,Lead>([
            SELECT Id, Company, Country, Domain__c, Related_Contact__c,
                Related_Contact__r.Account.Id, Related_Contact__r.Account.BillingStreet,
                Related_Contact__r.Account.BillingCity, Related_Contact__r.Account.BillingState,
                Related_Contact__r.Account.BillingPostalCode, Related_Contact__r.Account.BillingCountry,
                Related_Contact__r.Account.IM_Hierarchy_Level__c, Related_Contact__r.Account.CreatedById
            FROM Lead
            WHERE Id IN :leadIds
                AND Related_Account__c = null
            WITH SYSTEM_MODE
        ]);

        if (leadsById.isEmpty())
        {
            System.debug(LoggingLevel.WARN,LOG_PREFIX + 'no queued Leads could be queried for IDs ' + leadIds);
            return;
        }

        System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'queried Leads ' + leadsById.values() + '; excluded creator IDs ' + excludedCreatorIds);

        Set<Id> unresolvedLeadIds = new Set<Id>(leadsById.keySet());

        Map<Id,Account> matchesByLeadId = new Map<Id,Account>();

        matchRelatedContactAccounts(
            leadsById,
            unresolvedLeadIds,
            matchesByLeadId
        );

        debugMatchingState('Related Contact',unresolvedLeadIds,matchesByLeadId);

        matchExactNameAndCountry(
            leadsById,
            unresolvedLeadIds,
            matchesByLeadId
        );

        debugMatchingState('exact name and country',unresolvedLeadIds,matchesByLeadId);

        matchFuzzyNameAndCountry(
            leadsById,
            unresolvedLeadIds,
            matchesByLeadId
        );

        debugMatchingState('fuzzy name and country',unresolvedLeadIds,matchesByLeadId);

        matchDomains(
            leadsById,
            unresolvedLeadIds,
            matchesByLeadId
        );

        debugMatchingState('domain',unresolvedLeadIds,matchesByLeadId);

        updateProcessedLeads(leadsById,matchesByLeadId);

        System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'Queueable ' + context.getJobId() + ' finished; unmatched Lead IDs ' + unresolvedLeadIds);
    }

    private static void matchRelatedContactAccounts (Map<Id,Lead> leadsById, Set<Id> unresolvedLeadIds, Map<Id,Account> matchesByLeadId)
    {
        for (Id leadId : unresolvedLeadIds)
        {
            Lead leadRecord = leadsById.get(leadId);
            Account relatedAccount = leadRecord.Related_Contact__r.Account;
            Boolean accountQualifies = isQualifyingAccount(relatedAccount);

            System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'Lead ' + leadId + ' has Related Contact ' + leadRecord.Related_Contact__c + ' with Account ' + leadRecord.Related_Contact__r.Account.Id + ' [hierarchy=' + leadRecord.Related_Contact__r.Account.IM_Hierarchy_Level__c + ', createdBy=' + leadRecord.Related_Contact__r.Account.CreatedById + ', qualifies=' + accountQualifies + ']');

            if (accountQualifies)
                matchesByLeadId.put(leadId,relatedAccount);
        }

        unresolvedLeadIds.removeAll(matchesByLeadId.keySet());
    }

    @TestVisible
    private static void matchExactNameAndCountry (Map<Id,Lead> leadsById, Set<Id> unresolvedLeadIds, Map<Id,Account> matchesByLeadId)
    {
        if (unresolvedLeadIds.isEmpty())
            return;

        Set<String> companies = new Set<String>();
        Set<String> countries = new Set<String>();

        for (Id leadId : unresolvedLeadIds)
        {
            Lead leadRecord = leadsById.get(leadId);
            companies.add(leadRecord.Company);

            if (String.isNotBlank(leadRecord.Country))
                countries.add(leadRecord.Country);
        }

        System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'exact-match inputs: companies ' + companies + '; countries ' + countries);

        if (countries.isEmpty())
            return;

        Map<String,List<Account>> candidatesByNameAndCountry = new Map<String,List<Account>>();

        for (Account candidate : [
            SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                BillingCountry, Primary_BDE__c, Enterprise_ISR__c, RIM_SDE__c,
                Information_Governance_Rep__c, DMS_Owner__c, IM_IMGA__c, Account_Domain__c,
                DnB_Web_Address__c, CreatedDate
            FROM Account
            WHERE IM_Hierarchy_Level__c = :SALES_SITE_LEVEL
                AND CreatedById NOT IN :excludedCreatorIds
                AND Name IN :companies
                AND BillingCountry IN :countries
            WITH SYSTEM_MODE
        ])
        {
            addCandidate(
                candidatesByNameAndCountry,
                compoundKey(candidate.Name,candidate.BillingCountry),
                candidate
            );
        }

        System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'exact-match candidate keys ' + candidatesByNameAndCountry.keySet());

        matchFromCandidateMap(
            leadsById,
            unresolvedLeadIds,
            candidatesByNameAndCountry,
            true,
            matchesByLeadId
        );
    }

    @TestVisible
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
            WITH SYSTEM_MODE
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

        System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'fuzzy candidate Account IDs by Lead ' + accountIdsByLeadId);

        if (accountIdsByLeadId.isEmpty())
            return;

        matchFuzzyCandidateAccounts(
            leadsById,
            unresolvedLeadIds,
            matchesByLeadId,
            accountIdsByLeadId
        );
    }

    @TestVisible
    private static void matchFuzzyCandidateAccounts (Map<Id,Lead> leadsById, Set<Id> unresolvedLeadIds, Map<Id,Account> matchesByLeadId, Map<Id,Set<Id>> accountIdsByLeadId)
    {
        Set<Id> candidateAccountIds = new Set<Id>();

        for (Set<Id> accountIds : accountIdsByLeadId.values())
            candidateAccountIds.addAll(accountIds);

        Map<Id,Account> qualifyingAccountsById = new Map<Id,Account>([
            SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                BillingCountry, Primary_BDE__c, Enterprise_ISR__c, RIM_SDE__c,
                Information_Governance_Rep__c, DMS_Owner__c, IM_IMGA__c, Account_Domain__c,
                DnB_Web_Address__c, CreatedDate
            FROM Account
            WHERE Id IN :candidateAccountIds
                AND IM_Hierarchy_Level__c = :SALES_SITE_LEVEL
                AND CreatedById NOT IN :excludedCreatorIds
            WITH SYSTEM_MODE
        ]);

        System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'qualifying fuzzy candidate Account IDs ' + qualifyingAccountsById.keySet());

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
                matchesByLeadId.put(leadId,bestMatch);
        }

        unresolvedLeadIds.removeAll(matchesByLeadId.keySet());
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

        System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'domain-match inputs ' + leadDomains);

        if (leadDomains.isEmpty())
            return;

        Map<String,List<Account>> candidatesByDomain = new Map<String,List<Account>>();

        for (Account candidate : [
            SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode,
                BillingCountry, Primary_BDE__c, Enterprise_ISR__c, RIM_SDE__c,
                Information_Governance_Rep__c, DMS_Owner__c, IM_IMGA__c, Account_Domain__c,
                DnB_Web_Address__c, CreatedDate
            FROM Account
            WHERE IM_Hierarchy_Level__c = :SALES_SITE_LEVEL
                AND CreatedById NOT IN :excludedCreatorIds
                AND (Account_Domain__c IN :leadDomains OR DnB_Web_Address__c IN :leadDomains)
            WITH SYSTEM_MODE
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

        System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'domain-match candidate keys ' + candidatesByDomain.keySet());

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
                matchesByLeadId.put(leadId,bestMatch);
        }

        unresolvedLeadIds.removeAll(matchesByLeadId.keySet());
    }

    @TestVisible
    private static Account chooseBestAccount (Lead leadRecord, List<Account> candidates)
    {
        if (candidates == null || candidates.isEmpty())
        {
            System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'Lead ' + leadRecord.Id + ' has no candidates');
            return null;
        }

        Account bestMatch;

        for (Account candidate : candidates)
        {
            if (bestMatch == null || isBetterMatch(leadRecord,candidate,bestMatch))
                bestMatch = candidate;
        }

        System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'Lead ' + leadRecord.Id + ' candidates ' + describeCandidates(leadRecord,candidates) + '; selected Account ' + bestMatch.Id);

        return bestMatch;
    }

    private static List<String> describeCandidates (Lead leadRecord, List<Account> candidates)
    {
        List<String> descriptions = new List<String>();

        for (Account candidate : candidates)
        {
            descriptions.add(
                candidate.Id + ' [coverage=' + hasActiveSalesCoverage(candidate)
                + ', imga=' + String.isNotBlank(candidate.IM_IMGA__c)
                + ', domainRank=' + domainRank(leadRecord.Domain__c,candidate.Account_Domain__c,candidate.DnB_Web_Address__c)
                + ', createdDate=' + candidate.CreatedDate + ']'
            );
        }

        return descriptions;
    }

    private static void debugMatchingState (String completedStage, Set<Id> unresolvedLeadIds, Map<Id,Account> matchesByLeadId)
    {
        Map<Id,Id> accountIdsByLeadId = new Map<Id,Id>();

        for (Id leadId : matchesByLeadId.keySet())
            accountIdsByLeadId.put(leadId,matchesByLeadId.get(leadId).Id);

        System.debug(LoggingLevel.DEBUG,LOG_PREFIX + completedStage + ' stage complete; Account IDs by Lead ' + accountIdsByLeadId + '; unresolved Lead IDs ' + unresolvedLeadIds);
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

        return candidate.CreatedDate < currentBest.CreatedDate;
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
        {
            System.debug(LoggingLevel.WARN,LOG_PREFIX + 'excluded-creator label is blank');
            return excludedCreatorIds;
        }

        for (String rawValue : labelValue.split(','))
        {
            String candidateValue = rawValue.trim();

            if (String.isBlank(candidateValue))
                continue;

            try
            {
                Id candidateId = (Id)candidateValue;

                if (candidateId.getSObjectType() == User.SObjectType)
                    excludedCreatorIds.add(candidateId);
                else
                    System.debug(LoggingLevel.WARN,LOG_PREFIX + 'ignored non-User excluded-creator ID ' + candidateValue);
            }
            catch (Exception invalidId) { System.debug(LoggingLevel.WARN,LOG_PREFIX + 'ignored invalid excluded-creator ID ' + candidateValue + ': ' + invalidId.getMessage()); }
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

    @TestVisible
    private static void updateProcessedLeads (Map<Id,Lead> leadsById, Map<Id,Account> matchesByLeadId)
    {
        List<Lead> leadsToUpdate = new List<Lead>();

        for (Id leadId : leadsById.keySet())
        {
            Account match = matchesByLeadId.get(leadId);

            Lead leadToUpdate = new Lead(
                Id = leadId,
                RelatedAccountMatchingComplete__c = true
            );

            if (match != null)
            {
                leadToUpdate.Related_Account__c = match.Id;
                leadToUpdate.Street = match.BillingStreet;
                leadToUpdate.City = match.BillingCity;
                leadToUpdate.State = match.BillingState;
                leadToUpdate.PostalCode = match.BillingPostalCode;
                leadToUpdate.Country = match.BillingCountry;
            }

            leadsToUpdate.add(leadToUpdate);
        }

        System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'prepared Lead updates ' + leadsToUpdate);

        List<Database.SaveResult> updateResults = Database.update(leadsToUpdate,false,AccessLevel.SYSTEM_MODE);

        Integer successfulUpdates = 0;

        for (Integer index = 0; index < updateResults.size(); index++)
        {
            Database.SaveResult updateResult = updateResults[index];

            if (updateResult.isSuccess())
                successfulUpdates++;
            else
            {
                for (Database.Error updateError : updateResult.getErrors())
                {
                    System.debug(
                        LoggingLevel.ERROR,
                        LOG_PREFIX + 'failed to update Lead ' + leadsToUpdate[index].Id
                            + ': ' + updateError.getStatusCode() + ' - ' + updateError.getMessage()
                            + '; fields ' + updateError.getFields()
                    );
                }
            }
        }

        System.debug(LoggingLevel.DEBUG,LOG_PREFIX + 'completed updates for ' + successfulUpdates + ' of ' + leadsToUpdate.size() + ' Leads');
    }
}