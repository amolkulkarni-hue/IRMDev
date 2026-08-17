trigger LeadListener on Lead (before insert, after insert)
{
    if (trigger.isBefore && trigger.isInsert)
    {
        for (Lead l : trigger.new)
        {
            if (l.Related_Account__c != null)
                l.RelatedAccountMatchingComplete__c = true;
        }
    }

    if (trigger.isAfter && trigger.isInsert)
        LeadToAccountMatching.handleLeadTrigger(trigger.new);
}