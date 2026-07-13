trigger LeadListener on Lead (after insert, after update)
{
    if (!LeadToAccountMatching.updatingLeads && trigger.isAfter && (trigger.isInsert || trigger.isUpdate))
        LeadToAccountMatching.handleLeadTrigger(trigger.new,trigger.oldMap);
}