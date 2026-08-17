trigger OLISyncTrigger on OpportunityLineItem (after delete) {
    Set<Id> oppIds = new Set<Id>();
    for (OpportunityLineItem oli : Trigger.old) {
        if (oli.OpportunityId != null) {
            oppIds.add(oli.OpportunityId);
        }
    }
    if (!oppIds.isEmpty()) {
        OPLSyncAction.syncOPLs(new List<Id>(oppIds));
    }
}