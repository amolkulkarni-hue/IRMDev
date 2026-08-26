trigger DuplicateRecordItemListener on DuplicateRecordItem (after insert)
{
    // Set<Id> duplicateRecordSetIds = new Set<Id>();

    // for (DuplicateRecordItem dri : trigger.new)
    // {
    //     if (dri.RecordId.getSObjectType() == Lead.SObjectType)
    //         duplicateRecordSetIds.add(dri.DuplicateRecordSetId);
    // }

    // if (!duplicateRecordSetIds.isEmpty())
    // {
    //     Map<Id,DuplicateRecordSet> duplicateRecordSetMap = new Map<Id,DuplicateRecordSet>([SELECT Id, DuplicateRule.DeveloperName FROM DuplicateRecordSet WHERE Id IN :duplicateRecordSetIds]);

    //     Set<Id> leadIds = new Set<Id>();

    //     for (DuplicateRecordItem dri : trigger.new)
    //     {
    //         if (duplicateRecordSetMap.get(dri.DuplicateRecordSetId).DuplicateRule.DeveloperName == LeadToAccountMatching.FUZZY_DUPLICATE_RULE_NAME)
    //             leadIds.add(dri.RecordId);
    //     }

    //     if (!leadIds.isEmpty())
    //         System.enqueueJob(new LeadToAccountMatching(leadIds));
    // }
}