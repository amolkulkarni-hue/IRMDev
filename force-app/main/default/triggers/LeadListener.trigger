trigger LeadListener on Lead (after insert, after update)
{
    if (trigger.isAfter && (trigger.isInsert || trigger.isUpdate))
    {
        if (!LeadToAccountMatching.updatingLeads)
            LeadToAccountMatching.handleLeadTrigger(trigger.new,trigger.oldMap);
    }
}